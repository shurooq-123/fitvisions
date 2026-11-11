const {before, after, test} = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, setDoc, getDoc, getDocs, collection, query, where, updateDoc, serverTimestamp, writeBatch} = require('firebase/firestore');
const {ref, uploadBytes, getBytes} = require('firebase/storage');
let env, alice, bob, admin, guest;
const profile = (uid, role='user') => ({uid, email:`${uid}@example.com`, firstName:'Test', lastName:'User', phone:'91234567', role, createdAt:serverTimestamp()});
const identity = uid => ({uid, email:`${uid}@example.com`});
before(async () => {
  env = await initializeTestEnvironment({projectId:'demo-fitvisions',
    firestore:{host:'127.0.0.1',port:8085,rules:fs.readFileSync(path.join(__dirname,'../../firestore.rules'),'utf8')},
    storage:{host:'127.0.0.1',port:9195,rules:fs.readFileSync(path.join(__dirname,'../../storage.rules'),'utf8')},
  });
  alice = env.authenticatedContext('alice',{email:'alice@example.com'});
  bob = env.authenticatedContext('bob',{email:'bob@example.com'});
  admin = env.authenticatedContext('admin',{email:'admin@example.com'});
  guest = env.unauthenticatedContext();
  await env.withSecurityRulesDisabled(async ctx => {
    for (const uid of ['alice','bob','admin']) await setDoc(doc(ctx.firestore(),'users',uid),profile(uid,uid==='admin'?'admin':'user'));
    await setDoc(doc(ctx.firestore(),'plans','basic'),{name:'Basic',price:3,duration:'1 Month',features:'Preview'});
  });
});
after(async () => { if(env) await env.cleanup(); });

test('owner profile access, no guest access or cross-user listing', async () => {
  await assertSucceeds(getDoc(doc(alice.firestore(),'users','alice')));
  await assertFails(getDoc(doc(guest.firestore(),'users','alice')));
  await assertFails(getDoc(doc(bob.firestore(),'users','alice')));
  await assertFails(getDocs(collection(alice.firestore(),'users')));
  await assertSucceeds(getDocs(collection(admin.firestore(),'users')));
});
test('email choice requires the matching secret and can only be recorded once', async () => {
  await env.withSecurityRulesDisabled(async ctx => {
    const db=ctx.firestore();
    for (const id of ['approve','decline','expired']) {
      await setDoc(doc(db,'registrationDecisions',id),{
        decision:'pending', yesProof:'yes-secret', noProof:'no-secret',
        expiresAt:new Date(Date.now()+(id==='expired'?-60000:60000)),
      });
    }
  });
  const db=guest.firestore();
  const approve=doc(db,'registrationDecisions','approve');
  await assertFails(getDoc(approve));
  await assertFails(updateDoc(approve,{decision:'approved',submittedProof:'no-secret'}));
  await assertFails(updateDoc(approve,{decision:'approved',submittedProof:'yes-secret',extra:true}));
  await assertSucceeds(updateDoc(approve,{decision:'approved',submittedProof:'yes-secret'}));
  await assertFails(updateDoc(approve,{decision:'declined',submittedProof:'no-secret'}));
  await assertSucceeds(updateDoc(doc(db,'registrationDecisions','decline'),{
    decision:'declined',submittedProof:'no-secret',
  }));
  await assertFails(updateDoc(doc(db,'registrationDecisions','expired'),{
    decision:'approved',submittedProof:'yes-secret',
  }));
});
test('only a verified email can create its own non-admin profile', async () => {
  const ctx=env.authenticatedContext('new',{email:'new@example.com'});
  const verified=env.authenticatedContext('new',{email:'new@example.com',email_verified:true});
  const db=verified.firestore();
  const user=doc(db,'users','new');
  await assertFails(setDoc(doc(ctx.firestore(),'users','new'),{...profile('new'),requiresEmailVerification:true}));
  await assertFails(setDoc(user,profile('new')));
  await assertFails(setDoc(user,{...profile('new','admin'),requiresEmailVerification:true}));
  await assertSucceeds(setDoc(user,{...profile('new'),requiresEmailVerification:true}));
  await assertSucceeds(getDoc(user));
  await assertFails(updateDoc(user,{role:'admin'}));
  await assertFails(updateDoc(user,{requiresEmailVerification:false}));
  await assertFails(getDoc(doc(ctx.firestore(),'plans','basic')));
  await assertSucceeds(getDoc(doc(db,'plans','basic')));
});
test('measurement and history batch saves atomically with owner isolation',async()=>{
  const db=alice.firestore(),batch=writeBatch(db);
  batch.set(doc(db,'measurements','alice'),{...identity('alice'),measurementType:'bodyOnly',height:'170',weight:'65',chest:'90',waist:'75',hip:'95',imageStorage:'local_only',updatedAt:serverTimestamp()});
  batch.set(doc(db,'history','measurement'),{...identity('alice'),title:'Measurements saved',createdAt:serverTimestamp()});
  await assertSucceeds(batch.commit());
  await assertSucceeds(getDoc(doc(db,'measurements','alice')));
  await assertFails(getDoc(doc(bob.firestore(),'measurements','alice')));
  await assertSucceeds(getDocs(query(collection(db,'history'),where('uid','==','alice'))));
  await assertFails(getDocs(collection(db,'history')));
  await assertSucceeds(getDocs(query(collection(admin.firestore(),'history'),where('uid','==','alice'))));
  await assertFails(getDocs(query(collection(bob.firestore(),'history'),where('uid','==','alice'))));
});
test('uploads metadata is private and cannot impersonate another user',async()=>{
  const data={...identity('alice'),clothImagePath:'gs://test/users/alice/cloth/x.jpg',imageStorage:'firebase_storage',updatedAt:serverTimestamp()};
  await assertSucceeds(setDoc(doc(alice.firestore(),'user_uploads','alice'),data));
  await assertFails(setDoc(doc(bob.firestore(),'user_uploads','alice'),data));
  await assertFails(getDoc(doc(bob.firestore(),'user_uploads','alice')));
});
test('feedback rating and owner are checked, admin can read',async()=>{
  const data={...identity('alice'),message:'Helpful',rating:5,createdAt:serverTimestamp()};
  await assertSucceeds(setDoc(doc(alice.firestore(),'feedback','one'),data));
  await assertFails(setDoc(doc(alice.firestore(),'feedback','bad'),{...data,rating:9}));
  await assertSucceeds(getDocs(collection(admin.firestore(),'feedback')));
  await assertFails(getDoc(doc(bob.firestore(),'feedback','one')));
});
test('plans are readable by members and writable only by admins',async()=>{
  await assertSucceeds(getDocs(collection(alice.firestore(),'plans')));
  await assertFails(updateDoc(doc(alice.firestore(),'plans','basic'),{price:0}));
  await assertSucceeds(updateDoc(doc(admin.firestore(),'plans','basic'),{features:'Updated',updatedAt:serverTimestamp()}));
});
test('subscription uses catalog price and cannot self-activate',async()=>{
  const data={...identity('alice'),planId:'basic',plan:'Basic',price:3,status:'selected',createdAt:serverTimestamp()};
  await assertFails(setDoc(doc(alice.firestore(),'subscriptions','tampered'),{...data,price:0}));
  await assertSucceeds(setDoc(doc(alice.firestore(),'subscriptions','sub'),data));
  await assertFails(updateDoc(doc(alice.firestore(),'subscriptions','sub'),{status:'active'}));
});
test('payment requests cannot claim paid, change amount, or store card details',async()=>{
  const db=alice.firestore();
  await assertSucceeds(getDoc(doc(db,'payments','sub')));
  const data={...identity('alice'),subscriptionId:'sub',planId:'basic',plan:'Basic',amount:3,status:'pending',createdAt:serverTimestamp()};
  await assertFails(setDoc(doc(db,'payments','forged'),{...data,status:'paid'}));
  await assertFails(setDoc(doc(db,'payments','cheap'),{...data,amount:0}));
  await assertFails(setDoc(doc(db,'payments','card'),{...data,cvv:'123'}));
  await assertSucceeds(setDoc(doc(db,'payments','sub'),data));
  await assertFails(updateDoc(doc(db,'payments','sub'),{status:'paid'}));
  await assertFails(getDoc(doc(bob.firestore(),'payments','sub')));
  await assertSucceeds(getDocs(collection(admin.firestore(),'payments')));
});
test('cloud image access is private and rejects non-image files',async()=>{
  const imagePath='users/alice/cloth/test.jpg';
  await assertSucceeds(uploadBytes(ref(alice.storage(),imagePath),new Uint8Array([1,2,3]),{contentType:'image/jpeg'}));
  await assertSucceeds(getBytes(ref(alice.storage(),imagePath)));
  await assertFails(getBytes(ref(bob.storage(),imagePath)));
  await assertFails(uploadBytes(ref(alice.storage(),'users/alice/cloth/test.txt'),new Uint8Array([1]),{contentType:'text/plain'}));
  await assertFails(uploadBytes(ref(bob.storage(),'users/alice/cloth/forged.jpg'),new Uint8Array([1]),{contentType:'image/jpeg'}));
});
test('generation previews remain private to owner and admin', async()=>{
 const payload={...identity('alice'),title:'Generated Avatar',kind:'avatar',previewBase64:'aGVsbG8=',createdAt:serverTimestamp()};
 await assertSucceeds(setDoc(doc(alice.firestore(),'history','preview'),payload));
 await assertSucceeds(getDoc(doc(admin.firestore(),'history','preview')));
 await assertFails(getDoc(doc(bob.firestore(),'history','preview')));
 await assertFails(getDoc(doc(guest.firestore(),'history','preview')));
 await assertFails(setDoc(doc(bob.firestore(),'history','spoof'),payload));
 await assertFails(setDoc(doc(alice.firestore(),'history','oversize'),{...payload,previewBase64:'a'.repeat(700001)}));
 await assertFails(setDoc(doc(alice.firestore(),'history','bad-kind'),{...payload,kind:'admin'}));
});
