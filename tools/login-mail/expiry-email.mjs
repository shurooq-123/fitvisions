import {firebaseAccessToken} from './recovery.mjs';
import {listDocuments, decode, reminderFor, saveNotice} from './notification-worker.mjs';
const base='https://firestore.googleapis.com/v1/projects/fitvisions-33e6d/databases/(default)/documents';
let busy=false;
export function expiryMail(records,now=new Date()) {
 const due=reminderFor(records,now);
 if(!due || due.expired || due.period.end-now>2*86400000)return null;
 const days=Math.ceil((due.period.end-now)/86400000);
 const end=due.period.end.toLocaleString('en-GB',{timeZone:'Asia/Muscat'});
 return {id:`expiry_email_2d_${due.record.id}`,title:'تذكير بانتهاء الاشتراك | Subscription expiry reminder',body:`متبقٍ ${days} يوم على انتهاء اشتراكك في FitVisions. ينتهي بتاريخ ${end} (توقيت عُمان).\n\nYour FitVisions subscription expires in ${days} day(s), on ${end} (Oman time).`};
}
export async function deliverExpiryEmails(transport,sender,{getToken=firebaseAccessToken,list=listDocuments}={}) {
 if(busy || !transport)return;busy=true;
 try {
  const token=await getToken();
  const request=async(path,options={})=>fetch(`${base}/${path}`,{...options,headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json'},signal:AbortSignal.timeout(15000)});
  const groups=new Map();
  for(const doc of await list('payments',token)) {
   const r={...decode(doc.fields),id:doc.name.split('/').at(-1)};
   if(!r.uid)continue;if(!groups.has(r.uid))groups.set(r.uid,[]);groups.get(r.uid).push(r);
  }
  for(const [uid,records] of groups) {
   const notice=expiryMail(records);if(!notice)continue;
   const existing=await request(`notifications/${notice.id}`);
   if(existing.ok && (await existing.json()).fields?.emailSent?.booleanValue)continue;
   if(!existing.ok && existing.status!==404)throw Error('Reminder status unavailable');
   const userResponse=await request(`users/${encodeURIComponent(uid)}`);if(!userResponse.ok)continue;
   const user=decode((await userResponse.json()).fields);
   if(user.archived===true || typeof user.email!=='string' || !/^[^\s@,<>]+@[^\s@,<>]+\.[^\s@,<>]+$/.test(user.email))continue;
   await saveNotice(notice.id,uid,{title:notice.title,body:notice.body},'subscription',token);
   const result=await transport.sendMail({from:{name:'FitVisions',address:sender},to:user.email,subject:notice.title,text:notice.body});
   if(!result.accepted?.length)throw Error('Reminder email not accepted');
   const saved=await request(`notifications/${notice.id}?updateMask.fieldPaths=emailSent`,{method:'PATCH',body:JSON.stringify({fields:{emailSent:{booleanValue:true}}})});
   if(!saved.ok)throw Error('Reminder delivery status not saved');
  }
 } finally {busy=false;}
}
