import {test} from 'node:test';
import assert from 'node:assert/strict';
import {eventMessage, deliverEvent} from './event-notifications.mjs';
test('Avatar notification is bilingual',()=>{const m=eventMessage('generation',{kind:'avatar'});assert.match(m.text,/الأفتار/);assert.match(m.text,/avatar/);});
test('Payment uses stored amount and months, including custom plans',()=>{const m=eventMessage('payment',{amount:7,durationMonths:6,status:'pending',plan:'Premium'});assert.match(m.text,/7.000 OMR/);assert.match(m.text,/6 month/);assert.match(m.text,/6 شهر/);assert.match(m.text,/No real money/);const custom=eventMessage('payment',{amount:12,durationMonths:3,status:'paid',plan:'Custom'});assert.match(custom.text,/3 month/);assert.doesNotMatch(custom.text,/No real money/);});
test('Invalid records cannot generate confirmation',()=>{assert.throws(()=>eventMessage('payment',{amount:'abc',durationMonths:1,status:'pending'}));assert.throws(()=>eventMessage('payment',{amount:3,durationMonths:0,status:'pending'}));assert.throws(()=>eventMessage('payment',{amount:3,durationMonths:1,status:'cancelled'}));assert.throws(()=>eventMessage('generation',{kind:'subscription'}));});

test('Rejects cross-account records before email or privileged access', async()=>{
 const original=globalThis.fetch;
 globalThis.fetch=async url=>new Response(JSON.stringify({fields:url.includes('/users/')?{email:{stringValue:'alice@example.com'}}:{uid:{stringValue:'bob'},email:{stringValue:'bob@example.com'}}}),{status:200});
 try {const r=await deliverEvent({kind:'generation',id:'other'}, {sub:'alice',email:'alice@example.com'},'user-token',{sendMail:()=>{throw Error('Must not send')}},'sender',()=>{throw Error('Must not elevate')}); assert.equal(r.status,403);} finally {globalThis.fetch=original;}
});
test('Uses registered email and sends a saved event only once across retries',async()=>{
 const original=globalThis.fetch;let saved=null,sends=0;
 globalThis.fetch=async(url,options)=>{
  let fields;
  if(url.includes('/users/'))fields={email:{stringValue:'alice@example.com'}};
  else if(url.includes('/history/'))fields={uid:{stringValue:'alice'},email:{stringValue:'alice@example.com'},kind:{stringValue:'avatar'}};
  else {
   if(options.method==='PATCH'){const incoming=JSON.parse(options.body).fields;saved={...saved,...incoming};}
   if(!saved)return new Response('{}',{status:404});
   fields=saved;
  }
  return new Response(JSON.stringify({fields}),{status:200});
 };
 try {
  const transport={sendMail:async mail=>{assert.equal(mail.to,'alice@example.com');sends++;return {accepted:[mail.to]}}};
  const send=()=>deliverEvent({kind:'generation',id:'alice_1',email:'attacker@example.com'}, {sub:'alice',email:'alice@example.com'},'token',transport,'sender',async()=>'admin-token');
  assert.equal((await send()).status,200);assert.equal((await send()).status,200);assert.equal(sends,1);assert.equal(saved.read.booleanValue,false);assert.equal(saved.emailSent.booleanValue,true);
 }finally{globalThis.fetch=original;}
});
