const {initializeApp} = require('firebase-admin/app');
const {getFirestore, FieldValue, Timestamp} = require('firebase-admin/firestore');
const {getAuth} = require('firebase-admin/auth');
const {getMessaging} = require('firebase-admin/messaging');
const {onDocumentCreated} = require('firebase-functions/v2/firestore');
const {onCall,HttpsError} = require('firebase-functions/v2/https');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const {addMonths,duration,endOf,active,archiveRestriction} = require('./policy');
initializeApp(); const db = getFirestore();
function notice(uid,title,body,kind) {return {uid,title,body,kind,read:false,createdAt:FieldValue.serverTimestamp()};}

// Prototype payments remain explicitly demo entitlements; this is not a bank charge.
exports.activateDemoSubscription = onDocumentCreated('payments/{id}',async event => {
  const ref = event.data.ref;
  await db.runTransaction(async tx => {
    const current = await tx.get(ref); const payment=current.data();
    if (!payment || payment.status !== 'pending') return;
    const subRef=db.doc(`subscriptions/${payment.subscriptionId}`);
    const userRef=db.doc(`users/${payment.uid}`);
    const subDoc=await tx.get(subRef); const userDoc=await tx.get(userRef); const sub=subDoc.data();
    if (!sub || !userDoc.exists || userDoc.data().archived || sub.uid !== payment.uid || sub.price !== payment.amount || !duration(sub)) throw new Error('Invalid subscription snapshot');
    const now=payment.createdAt?.toDate() ?? new Date();
    const existing=userDoc.data().subscriptionExpiresAt?.toDate();
    const start=existing && existing > now ? existing : now;
    const end=addMonths(start,duration(sub));
    const dates={startsAt:Timestamp.fromDate(start),expiresAt:Timestamp.fromDate(end)};
    tx.update(ref,{...dates,status:'demo_active',durationMonths:duration(sub),plan:sub.plan,amount:sub.price});
    tx.update(subRef,{...dates,status:'demo_active',registeredAt:payment.createdAt});
    tx.update(userRef,{subscriptionExpiresAt:dates.expiresAt});
    tx.set(db.doc(`notifications/payment_${event.params.id}`),notice(payment.uid,existing && existing > now ? 'Subscription renewed' : 'Subscription activated',`${sub.plan}: ${sub.price} OMR. Valid until ${end.toISOString().slice(0,10)}. Demo payment; no money charged.`,'payment'));
  });
});
exports.activityNotice=onDocumentCreated('history/{id}',async event=>{
  const data=event.data.data();
  if (!data.uid || !['avatar','clothes'].includes(data.kind)) return;
  await db.runTransaction(async tx => {const ref=db.doc(`notifications/generated_${event.params.id}`); if((await tx.get(ref)).exists)return; tx.set(ref,notice(data.uid,'Your design is ready','Your generated result has been saved to History.','generation'));});
});
exports.deliverNotification=onDocumentCreated('notifications/{id}',async event=>{
  const n=event.data.data();
  const devices=await db.collection(`users/${n.uid}/devices`).get();
  const docs=devices.docs;
  for(let i=0;i<docs.length;i+=500) {
    const chunk=docs.slice(i,i+500); if(!chunk.length)continue;
    const result=await getMessaging().sendEachForMulticast({tokens:chunk.map(d=>d.data().token),notification:{title:n.title,body:n.body},data:{uid:n.uid,notificationId:event.params.id},android:{priority:'high'},apns:{payload:{aps:{sound:'default'}}}});
    await Promise.all(result.responses.map((r,j)=>!r.success && ['messaging/registration-token-not-registered','messaging/invalid-registration-token'].includes(r.error?.code) ? chunk[j].ref.delete():Promise.resolve()));
  }
});
exports.subscriptionReminders=onSchedule({schedule:'every 60 minutes',timeZone:'Asia/Muscat'},async()=>{
  const now=new Date(); const soon=new Date(now.getTime()+3*86400000);
  const records=await db.collection('payments').where('expiresAt','<=',Timestamp.fromDate(soon)).get();
  for(const doc of records.docs) {
    const r=doc.data(); if(!['paid','demo_active'].includes(r.status))continue;
    const end=endOf(r); if(!end)continue;
    const user=(await db.doc(`users/${r.uid}`).get()).data();
    if(user?.subscriptionExpiresAt?.toDate() > end)continue;
    const expired=end<=now; const id=`${expired?'expired':'reminder'}_${doc.id}`;
    await db.runTransaction(async tx=>{
      const ref=db.doc(`notifications/${id}`);if((await tx.get(ref)).exists)return;
      tx.set(ref,notice(r.uid,expired?'Subscription expired':'Subscription expiry reminder',expired?'Your subscription has expired. Renew to edit and download designs.':`Your subscription expires on ${end.toISOString().slice(0,10)}.`,'subscription'));
    });
  }
});
exports.archiveUser=onCall(async request=>{
  const caller=request.auth?.uid;const uid=request.data?.uid;
  if(!caller)throw new HttpsError('unauthenticated','Please sign in.');
  if(typeof uid!=='string'||uid===caller||uid.includes('/'))throw new HttpsError('invalid-argument','You cannot archive this account.');
  const callerProfile=(await db.doc(`users/${caller}`).get()).data();
  if(callerProfile?.role!=='admin'||callerProfile.archived===true)throw new HttpsError('permission-denied','Administrator access required.');
  const userRef=db.doc(`users/${uid}`);
  await db.runTransaction(async tx=>{
    const target=await tx.get(userRef);
    const payments=await tx.get(db.collection('payments').where('uid','==',uid));
    if(!target.exists)throw new HttpsError('not-found','Account not found.');
    const restriction=archiveRestriction(target.data(),payments.docs.map(d=>d.data()));
    if(restriction)throw new HttpsError('failed-precondition',restriction);
    tx.update(userRef,{archived:true,archivedAt:FieldValue.serverTimestamp()});
  });
  await getAuth().updateUser(uid,{disabled:true});
  await getAuth().revokeRefreshTokens(uid);
  const devices=await db.collection(`users/${uid}/devices`).get();
  await Promise.all(devices.docs.map(d=>d.ref.delete()));
  return {archived:true};
});
