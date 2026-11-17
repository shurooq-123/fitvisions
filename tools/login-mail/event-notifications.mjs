import {firebaseAccessToken} from './recovery.mjs';
const base = 'https://firestore.googleapis.com/v1/projects/fitvisions-33e6d/databases/(default)/documents';
const busy = new Set();
const value = field => field?.stringValue ?? field?.integerValue ?? field?.doubleValue;
export function eventMessage(kind, record) {
  if (kind === 'generation') {
    if (!['avatar', 'clothes'].includes(record.kind)) throw new Error('Invalid generation');
    const avatar = record.kind === 'avatar';
    return {title: avatar ? 'تم إنشاء الأفتار | Avatar created' : 'تم إنشاء التصميم | Design created',
      text: avatar ? 'تم إنشاء الأفتار الخاص بك في FitVisions بنجاح. يمكنك مشاهدته في الهيستوري.\n\nYour FitVisions avatar has been created successfully. You can view it in History.' :
        'تم إنشاء تصميم الملابس في FitVisions بنجاح.\n\nYour FitVisions clothing design has been created successfully.'};
  }
  const amount = Number(record.amount), months = Number(record.durationMonths);
  if (!['pending','demo_active','paid'].includes(record.status) || !Number.isFinite(amount) || amount <= 0 || !Number.isInteger(months) || months < 1 || months > 120) throw new Error('Invalid payment');
  const demo = record.status !== 'paid';
  return {title: 'تأكيد الدفع والاشتراك | Payment and subscription',
    text: `تم تسجيل ${demo ? 'عملية الدفع التجريبية' : 'عملية الدفع'} في FitVisions.\nالخطة: ${record.plan}\nقيمة الدفع: ${amount.toFixed(3)} ريال عماني\nمدة الاشتراك: ${months} شهر\n${demo ? 'هذه عملية تجريبية؛ لم يتم خصم مبلغ حقيقي.' : ''}\n\n${demo ? 'Demo payment' : 'Payment'} recorded in FitVisions.\nPlan: ${record.plan}\nAmount: ${amount.toFixed(3)} OMR\nSubscription duration: ${months} month(s).\n${demo ? 'No real money was charged.' : ''}`};
}
async function request(path, token, method = 'GET', body) {
  const r = await fetch(`${base}/${path}`, {method, headers: {Authorization: `Bearer ${token}`, 'Content-Type':'application/json'},
    body: body ? JSON.stringify(body) : undefined, signal: AbortSignal.timeout(10000)});
  return r;
}
export async function deliverEvent(input, claims, token, transport, sender, accessToken = firebaseAccessToken) {
  const {kind,id} = input;
  if (!['generation','payment'].includes(kind) || typeof id !== 'string' || !/^[A-Za-z0-9_-]{1,200}$/.test(id)) return {status:400};
  const profile = await request(`users/${claims.sub}`,token);
  if (!profile.ok) return {status:403};
  const pf = (await profile.json()).fields;
  if (pf.archived?.booleanValue || value(pf.email) !== claims.email) return {status:403};
  const source = await request(`${kind === 'generation' ? 'history' : 'payments'}/${id}`,token);
  if (!source.ok) return {status:403};
  const fields = (await source.json()).fields;
  const record = Object.fromEntries(Object.entries(fields).map(([k,v]) => [k,value(v)]));
  if (record.uid !== claims.sub || record.email !== claims.email) return {status:403};
  const message = eventMessage(kind, record);
  const eventId = `${kind === 'generation' ? 'generated' : 'payment'}_${id}`;
  if (busy.has(eventId)) return {status:409};
  busy.add(eventId);
  try {
    const admin = await accessToken();
    const path = `notifications/${eventId}`;
    let notification = await request(path,admin);
    if (notification.status === 404) {
      const fields = {uid:{stringValue:claims.sub}, title:{stringValue:message.title},
        body:{stringValue:message.text},kind:{stringValue:kind},read:{booleanValue:false},
        createdAt:{timestampValue:new Date().toISOString()}};
      const created = await request(`${path}?currentDocument.exists=false`, admin, 'PATCH', {fields});
      if (!created.ok && created.status !== 409) throw new Error('Notification persistence failed');
      notification = await request(path,admin);
    }
    if (!notification.ok) throw new Error('Notification read failed');
    if ((await notification.json()).fields?.emailSent?.booleanValue) return {status:200};
    if (!transport) return {status:503};
    const result = await transport.sendMail({from:{name:'FitVisions',address:sender},to:claims.email,
      subject:`FitVisions — ${message.title}`,text:message.text});
    if (!result.accepted?.length) throw new Error('Email not accepted');
    const saved = await request(`${path}?updateMask.fieldPaths=emailSent`,admin,'PATCH',{fields:{emailSent:{booleanValue:true}}});
    if (!saved.ok) throw new Error('Email status persistence failed');
    return {status:200};
  } finally {busy.delete(eventId);}
}
