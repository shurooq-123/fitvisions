const test=require('node:test');const assert=require('node:assert/strict');
const {addMonths,duration,active}=require('../policy');
const stamp=s=>({toDate:()=>new Date(s)});
test('leap year and non-leap month ends',()=>{
 assert.equal(addMonths(new Date('2024-01-31T12:30:00Z'),1).toISOString(),'2024-02-29T12:30:00.000Z');
 assert.equal(addMonths(new Date('2026-08-31T00:00:00Z'),6).toISOString(),'2027-02-28T00:00:00.000Z');
});
test('purchased duration is independent of price edits',()=>{assert.equal(duration({durationMonths:6,amount:15}),6);});
test('expires at exact boundary and rejects cancelled access',()=>{
 const record={createdAt:stamp('2026-01-31T12:00:00Z'),durationMonths:1,status:'demo_active'};
 assert.ok(active(record,new Date('2026-02-28T11:59:59Z')));
 assert.equal(!!active(record,new Date('2026-02-28T12:00:00Z')),false);
 assert.equal(!!active({...record,status:'cancelled'},new Date('2026-02-01')),false);
});
test('invalid durations cannot activate',()=>{for(const n of [0,-1,1.5,121])assert.throws(()=>addMonths(new Date(),n));});
