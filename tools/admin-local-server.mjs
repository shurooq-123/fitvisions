import http from 'node:http';
import {createRequire} from 'node:module';
import {firebaseAccessToken} from './login-mail/recovery.mjs';
const require=createRequire(new URL('../functions/package.json',import.meta.url));
const {initializeApp}=require('firebase-admin/app');
const {Firestore,FieldValue}=require('@google-cloud/firestore');
const {GoogleAuth,OAuth2Client}=require('google-auth-library');
const {getAuth}=require('firebase-admin/auth');
const {archiveRestriction}=require('./policy');
initializeApp({projectId:'fitvisions-33e6d',credential:{getAccessToken:async()=>({access_token:await firebaseAccessToken(),expires_in:300})}});
const oauth=new OAuth2Client();
oauth.refreshHandler=async()=>({access_token:await firebaseAccessToken(),expiry_date:Date.now()+300000});
const db=new Firestore({projectId:'fitvisions-33e6d',auth:new GoogleAuth({authClient:oauth})}),auth=getAuth();
http.createServer(async(req,res)=>{
 const reply=(status,error)=>{res.writeHead(status,{'Content-Type':'application/json'});res.end(JSON.stringify(error?{error}:{archived:true}));};
 if(req.url!=='/archive' || req.method!=='POST' || req.headers.origin)return reply(403,'Forbidden');
 try {
  let claims;try {claims=await auth.verifyIdToken((req.headers.authorization??'').replace(/^Bearer /,''),true);}catch{return reply(401,'Please sign in again.');}
  let body='';for await(const chunk of req){body+=chunk;if(body.length>1024)return reply(400,'Invalid request');}
  const {uid}=JSON.parse(body);
  if(typeof uid!=='string'||!uid||uid.includes('/')||uid===claims.uid)return reply(400,'You cannot archive this account.');
  await db.runTransaction(async tx=>{
   const caller=await tx.get(db.doc(`users/${claims.uid}`));
   if(caller.data()?.role!=='admin'||caller.data()?.archived)throw Error('Administrator access required.');
   const target=await tx.get(db.doc(`users/${uid}`));
   const payments=await tx.get(db.collection('payments').where('uid','==',uid));
   const restriction=archiveRestriction(target.data(),payments.docs.map(d=>d.data()));
   if(restriction)throw Error(restriction);
   tx.update(target.ref,{archived:true,archivedAt:FieldValue.serverTimestamp()});
  });
  await auth.updateUser(uid,{disabled:true});await auth.revokeRefreshTokens(uid);
  const devices=await db.collection(`users/${uid}/devices`).get();
  await Promise.all(devices.docs.map(d=>d.ref.delete()));
  reply(200);
 }catch(e){const safe=['Administrator access required.','Account not found.','Administrator accounts cannot be archived here.','This user has an active subscription. Wait until it expires.'];reply(409,safe.includes(e.message)?e.message:'Could not complete account archival. Retry to finish safely.');}
}).listen(8790,'127.0.0.1',()=>console.log('Local admin service ready on 8790.'));
