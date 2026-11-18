import {test} from 'node:test';
import assert from 'node:assert/strict';
import {addMonths,period,reminderFor,paymentNotice,deliverPush} from './notification-worker.mjs';
test('Oman midnight month boundary is clamped in local calendar',()=>{
 assert.equal(addMonths('2026-01-30T20:00:00Z',1).toISOString(),'2026-02-27T20:00:00.000Z');
});
test('Calendar durations clamp month end, preserve time and leap years',()=>{
 assert.equal(addMonths('2026-01-31T08:30:00Z',1).toISOString(),'2026-02-28T08:30:00.000Z');
 assert.equal(addMonths('2024-01-31T08:30:00Z',1).toISOString(),'2024-02-29T08:30:00.000Z');
});
test('Reminders use latest entitlement, suppress superseded expiry and distinguish expiry',()=>{
 const a={id:'a',createdAt:'2026-01-01T08:00:00Z',durationMonths:1,status:'paid'};
 const b={id:'b',createdAt:'2026-01-20T08:00:00Z',durationMonths:6,status:'paid'};
 assert.equal(reminderFor([a,b],new Date('2026-01-30T08:00:00Z')),null);
 assert.equal(reminderFor([a],new Date('2026-01-30T08:00:00Z')).expired,false);
 assert.equal(reminderFor([a],new Date('2026-02-01T08:00:00Z')).expired,true);
 assert.equal(period({...a,status:'cancelled'}),null);
});
test('Renewal notification contains snapshot amount and months with demo disclosure',()=>{
 const n=paymentNotice({amount:7,durationMonths:6,createdAt:'2026-01-01',status:'pending'},true);
 assert.match(n.title,/renewed/);assert.match(n.body,/7 OMR, 6 month/);assert.match(n.body,/no real charge/);
});
test('FCM payload includes OS notification for background and retry receipt prevents duplicates',async()=>{
 const original=globalThis.fetch;let sends=0;let saved={};
 const doc={name:'projects/p/databases/(default)/documents/notifications/n',fields:{uid:{stringValue:'u'},title:{stringValue:'Payment'},body:{stringValue:'3 OMR'},pushPending:{booleanValue:true}}};
 globalThis.fetch=async(url,options)=>{
  if(url.includes('fcm.googleapis.com')){const payload=JSON.parse(options.body);assert.equal(payload.message.notification.title,'Payment');assert.equal(payload.message.data.uid,'u');assert.equal(payload.message.android.priority,'HIGH');sends++;return new Response('{}');}
  if(url.includes('/devices?'))return Response.json({documents:[{name:'x/documents/users/u/devices/t',fields:{token:{stringValue:'device-token'}}}]});
  if(options.method==='PATCH'){saved={...saved,...JSON.parse(options.body).fields};return Response.json({fields:saved});}
  return Response.json({fields:{archived:{booleanValue:false}}});
 };
 try {assert.equal((await deliverPush(doc,'test')).sent,1);await deliverPush({...doc,fields:{...doc.fields,...saved}},'test');assert.equal(sends,1);assert.equal(saved.pushSent.booleanValue,true);}finally{globalThis.fetch=original;}
});
