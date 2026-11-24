import {test} from 'node:test';import assert from 'node:assert/strict';
import {expiryMail,deliverExpiryEmails} from './expiry-email.mjs';
test('expiry email starts at 48 hours, includes days and ignores expired/superseded subscriptions',()=>{
 const r={id:'one',uid:'u',createdAt:'2026-01-01T08:00:00Z',durationMonths:1,status:'paid'};
 assert.equal(expiryMail([r],new Date('2026-01-30T07:59:59Z')),null);
 const msg=expiryMail([r],new Date('2026-01-30T08:00:00Z'));
 assert.match(msg.body,/2 day/);assert.equal(msg.id,'expiry_email_2d_one');
 assert.equal(expiryMail([r],new Date('2026-02-01T08:00:00Z')),null);
 assert.equal(expiryMail([r,{...r,id:'renewed',createdAt:'2026-01-29T08:00:00Z'}],new Date('2026-01-30T08:00:00Z')),null);
});
test('email goes to account email once and persists delivery receipt',async()=>{
 const previous=globalThis.fetch;let deliveries=0;let saved={};
 const now=new Date();const end=new Date(now.getTime()+86400000);
 const document={name:'x/documents/payments/pay1',fields:{uid:{stringValue:'u'},createdAt:{timestampValue:new Date(now.getTime()-86400000*20).toISOString()},expiresAt:{timestampValue:end.toISOString()},durationMonths:{integerValue:'1'},status:{stringValue:'paid'}}};
 globalThis.fetch=async(url,opts={})=>{
  if(url.includes('/users/'))return Response.json({fields:{email:{stringValue:'registered@example.com'}}});
  if(opts.method==='PATCH'){saved={...saved,...JSON.parse(opts.body).fields};return Response.json({fields:saved});}
  return Object.keys(saved).length?Response.json({fields:saved}):new Response('{}',{status:404});
 };
 try {
  const transport={sendMail:async m=>{assert.equal(m.to,'registered@example.com');assert.match(m.text,/1 day/);deliveries++;return {accepted:[m.to]};}};
  const dependencies={getToken:async()=> 'test',list:async()=>[document]};
  await deliverExpiryEmails(transport,'sender@example.com',dependencies);
  await deliverExpiryEmails(transport,'sender@example.com',dependencies);
  assert.equal(deliveries,1);assert.equal(saved.emailSent.booleanValue,true);
 }finally{globalThis.fetch=previous;}
});
