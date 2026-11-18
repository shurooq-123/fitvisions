import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {firebaseAccessToken} from './recovery.mjs';

const project='fitvisions-33e6d';
const base=`https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents`;
const startedAt=Date.now();
export function decode(fields={}) {
 return Object.fromEntries(Object.entries(fields).map(([k,v])=>[k,
  v.stringValue ?? (v.integerValue!==undefined?Number(v.integerValue):v.doubleValue) ?? v.booleanValue ?? v.timestampValue ?? null]));
}
export function addMonths(start,count) {
 const offset=4*60*60*1000; // Subscription calendar: Asia/Muscat.
 const d=new Date(new Date(start).getTime()+offset);const day=d.getUTCDate();d.setUTCDate(1);d.setUTCMonth(d.getUTCMonth()+count);
 const end=new Date(Date.UTC(d.getUTCFullYear(),d.getUTCMonth()+1,0)).getUTCDate();d.setUTCDate(Math.min(day,end));return new Date(d.getTime()-offset);
}
export function period(record) {
 const months=Number(record.durationMonths) || (Number(record.amount)===7?6:Number(record.amount)===3?1:0);
 const start=new Date(record.startsAt || record.createdAt);
 if(!['pending','demo_active','paid'].includes(record.status)|| !Number.isInteger(months)||months<1||months>120||!Number.isFinite(start.getTime()))return null;
 const end=record.expiresAt?new Date(record.expiresAt):addMonths(start,months);
 if(!Number.isFinite(end.getTime()))return null;
 return {start,end,months};
}
export function reminderFor(records,now=new Date()) {
 const candidates=records.map(r=>({record:r,period:period(r)})).filter(x=>x.period).sort((a,b)=>b.period.end-a.period.end);
 const latest=candidates[0];
 if(!latest || latest.period.start>now || latest.period.end-now>3*86400000)return null;
 return {...latest,expired:latest.period.end<=now};
}
export function paymentNotice(record,renewal=false) {
 const p=period(record);if(!p)throw Error('Invalid payment period');
 const demo=record.status!=='paid';
 return {
  title:renewal?'تجديد الاشتراك | Subscription renewed':'تأكيد الدفع | Payment confirmation',
  body:`${renewal?'تم تجديد الاشتراك':'تم تسجيل الدفع'}: ${record.amount} ريال عماني، ${p.months} شهر.\n${demo?'دفع تجريبي؛ لم يُخصم مال حقيقي.':''}\n\n${renewal?'Subscription renewed':'Payment recorded'}: ${record.amount} OMR, ${p.months} month(s).\n${demo?'Demo payment; no real charge.':''}`,
 };
}
function fields(data) {
 return Object.fromEntries(Object.entries(data).map(([k,v])=>[k,typeof v==='boolean'?{booleanValue:v}: {stringValue:String(v)}]));
}
async function api(path,token,method='GET',body) {
 const r=await fetch(`${base}${path.startsWith(':')?'':'/'}${path}`,{method,headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json'},body:body?JSON.stringify(body):undefined,signal:AbortSignal.timeout(15000)});
 if(!r.ok) {const e=new Error(`Firestore ${r.status}`);e.status=r.status;throw e;}
 return r.status===204?{}:r.json();
}
export async function listDocuments(path,token) {
 const result=[];let page;
 do {const data=await api(`${path}?pageSize=100${page?`&pageToken=${encodeURIComponent(page)}`:''}`,token);result.push(...(data.documents??[]));page=data.nextPageToken;}while(page);
 return result;
}
async function patch(path,token,data) {
 const mask=Object.keys(data).map(k=>`updateMask.fieldPaths=${encodeURIComponent(k)}`).join('&');
 return api(`${path}?${mask}`,token,'PATCH',{fields:fields(data)});
}
export async function saveNotice(id,uid,message,kind,token,push=true) {
 try {
  await api(`notifications/${id}?currentDocument.exists=false`,token,'PATCH',{fields:{...fields({uid,...message,kind,read:false,pushPending:push}),createdAt:{timestampValue:new Date().toISOString()}}});
  return true;
 } catch(e) {
  if(e.status!==409 && e.status!==412)throw e;
  const existing=decode((await api(`notifications/${id}`,token)).fields);
  if(existing.uid!==uid)throw Error('Notification owner mismatch');
  // Preserve read status and completed delivery while adding the push channel.
  if(push && existing.pushPending===undefined && existing.pushSent!==true) await patch(`notifications/${id}`,token,{pushPending:true});
  return false;
 }
}
export async function deliverPush(doc,token) {
 const data=decode(doc.fields);const uid=data.uid;const id=doc.name.split('/').at(-1);
 if(!uid || !data.pushPending)return {sent:0};
 const user=decode((await api(`users/${encodeURIComponent(uid)}`,token)).fields);
 if(user.archived===true){await patch(`notifications/${id}`,token,{pushPending:false});return {sent:0};}
 const devices=await listDocuments(`users/${encodeURIComponent(uid)}/devices`,token);
 let sent=0,failed=0,accepted=0;
 for(const device of devices) {
  const deviceToken=decode(device.fields).token;if(!deviceToken)continue;
  const receipt='device_'+createHash('sha256').update(deviceToken).digest('hex').slice(0,24);
  if(data[receipt]===true){accepted++;continue;}
  const response=await fetch(`https://fcm.googleapis.com/v1/projects/${project}/messages:send`,{
   method:'POST',headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json'},signal:AbortSignal.timeout(15000),
   body:JSON.stringify({message:{token:deviceToken,
    notification:{title:data.title,body:data.body},
    data:{uid,notificationId:id},
    android:{priority:'HIGH',notification:{tag:id,sound:'default'}},apns:{payload:{aps:{sound:'default'}}}}})});
  if(response.ok){sent++;accepted++;await patch(`notifications/${id}`,token,{[receipt]:true});}
  else {
   const error=await response.json();
   const unregistered=error.error?.details?.some(d=>d.errorCode==='UNREGISTERED');
   if(unregistered){await api(device.name.split('/documents/')[1],token,'DELETE');}
   else {failed++;console.log(`Push not accepted: HTTP ${response.status}, ${error.error?.status??'unknown'}`);}
  }
 }
 if(accepted>0 && failed===0)await patch(`notifications/${id}`,token,{pushPending:false,pushSent:true});
 return {sent,failed,devices:devices.length};
}
let busy=false;
const handledPayments=new Set(), handledReminders=new Set();
let paymentCache=[];
let refreshed=0;
let lastPoll=startedAt-300000;
async function queryDocuments(collection,field,op,value,token) {
 const data=await api(':runQuery',token,'POST',{structuredQuery:{from:[{collectionId:collection}],where:{fieldFilter:{field:{fieldPath:field},op,value}}}});
 return data.filter(x=>x.document).map(x=>x.document);
}

export async function tick() {
 if(busy)return;busy=true;
 try {
  const token=await firebaseAccessToken();
  const now=Date.now();
  const documents=now-refreshed>3600000 ? await listDocuments('payments',token) : await queryDocuments('payments','createdAt','GREATER_THAN_OR_EQUAL',{timestampValue:new Date(lastPoll-30000).toISOString()},token);
  if(now-refreshed>3600000){paymentCache=[];refreshed=now;}
  for(const doc of documents){const record={...decode(doc.fields),id:doc.name.split('/').at(-1)};paymentCache=paymentCache.filter(x=>x.id!==record.id);if(period(record))paymentCache.push(record);}
  lastPoll=now;
  const payments=paymentCache;
  const groups=new Map();
  for(const r of payments){if(!groups.has(r.uid))groups.set(r.uid,[]);groups.get(r.uid).push(r);}
  for(const [uid,records] of groups){
   const due=reminderFor(records);
   const dueId=due?`${due.expired?'expired':'reminder'}_${due.record.id}`:null;
   const fresh=records.filter(r=>new Date(r.createdAt).getTime()>=startedAt-300000 && !handledPayments.has(r.id));
   if(!fresh.length && (!dueId || handledReminders.has(dueId)))continue;
   const user=decode((await api(`users/${encodeURIComponent(uid)}`,token)).fields);if(user.archived===true)continue;
   records.sort((a,b)=>new Date(a.createdAt)-new Date(b.createdAt));
   for(let i=0;i<records.length;i++){
    const r=records[i];
    // Do not deliver a flood of historical confirmations when starting the worker.
    if(new Date(r.createdAt).getTime()<startedAt-300000 || handledPayments.has(r.id))continue;
    await saveNotice(`payment_${r.id}`,uid,paymentNotice(r,i>0),'payment',token);
    if(i>0)await saveNotice(`renewal_${r.id}`,uid,paymentNotice(r,true),'subscription',token);
    handledPayments.add(r.id);
   }
   if(due && due.period.end.getTime()>=startedAt-86400000){
    const date=due.period.end.toISOString().slice(0,10);
    const id=`${due.expired?'expired':'reminder'}_${due.record.id}`;
    const message=due.expired?{title:'انتهى الاشتراك | Subscription expired',body:'انتهى اشتراكك. جدده لمتابعة التعديل والتحميل.\n\nYour subscription has expired. Renew to continue editing and downloading.'}:{title:'تذكير بانتهاء الاشتراك | Subscription expiry reminder',body:`ينتهي اشتراكك بتاريخ ${date}.\n\nYour subscription expires on ${date}.`};
    await saveNotice(id,uid,message,'subscription',token);
    handledReminders.add(id);
   }
  }
  const notices=await queryDocuments('notifications','pushPending','EQUAL',{booleanValue:true},token);
  let accepted=0;
  for(const doc of notices){const data=decode(doc.fields);if(data.pushPending===true)accepted+=(await deliverPush(doc,token)).sent;}
  console.log(`Notification check completed. Push messages accepted: ${accepted}.`);
 }catch(e){console.log(`Notification check failed: ${e.message}`);}finally{busy=false;}
}
if(process.argv[1] && fileURLToPath(import.meta.url)===process.argv[1]){
 await tick();setInterval(tick,30000);
 console.log('Local notification worker running; keep this laptop awake for scheduled reminders.');
}

// Run from the project root after Firebase CLI login:
// $env:FITVISIONS_FIREBASE_CLI_LIB=(Resolve-Path tools/firebase-tests/node_modules/firebase-tools/lib).Path
// node tools/login-mail/notification-worker.mjs
