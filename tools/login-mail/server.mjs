import http from 'node:http';
import {randomBytes} from 'node:crypto';
import {writeFile, readFile} from 'node:fs/promises';
import nodemailer from 'nodemailer';
import {createRemoteJWKSet, jwtVerify} from 'jose';
import {recoveryLink} from './recovery.mjs';
import {acceptsMailDomain, prepareRegistration, registrationStatus} from './registration.mjs';

const project = 'fitvisions-33e6d';
const firebaseConfig = JSON.parse(await readFile('android/app/google-services.json','utf8'));
const apiKey = firebaseConfig.client[0].api_key[0].current_key;
const origin = 'http://127.0.0.1:8789';
const setupPath = '/setup/' + randomBytes(24).toString('hex');
const keys = createRemoteJWKSet(new URL('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'));
let transport, sender, configuring = false;
const sent = new Map();
const pending = new Set();
const recentRecovery = new Map();
let recoveryWindow = 0;
let recoveryRequests = 0;
function reply(res, status, value) {
  res.writeHead(status, {'Content-Type':'application/json', 'Cache-Control':'no-store'});
  res.end(JSON.stringify(value));
}
async function body(req) {
  const chunks = []; let size = 0;
  for await (const chunk of req) {
    size += chunk.length;
    if (size > 12000) throw new Error('oversize');
    chunks.push(chunk);
  }
  return JSON.parse(Buffer.concat(chunks).toString());
}
const server = http.createServer(async (req, res) => {
  try {
    if (req.headers.host !== '127.0.0.1:8789') return reply(res,403,{error:'Forbidden'});
    if (req.url === setupPath && req.method === 'GET') {
      res.writeHead(200, {'Content-Type':'text/html; charset=utf-8','Cache-Control':'no-store','Referrer-Policy':'no-referrer','X-Frame-Options':'DENY'});
      return res.end(`<!doctype html><html lang="ar" dir="rtl"><meta charset="utf-8"><title>بريد FitVisions</title><body style="font:18px sans-serif;max-width:600px;margin:50px auto;background:#ced1c6"><h1>ربط بريد إشعارات تسجيل الدخول</h1><p>أدخلي بريد Gmail المُرسل وApp Password المكوّنة من 16 حرفًا. لا تدخلي كلمة مرور حساب Google العادية.</p><p>البيانات تبقى في ذاكرة خادم اللابتوب فقط. يلزم تشغيله واتصال USB لاستقبال طلبات الهاتف.</p><form><input id="email" type="email" required placeholder="Sender Gmail" style="padding:12px;width:90%"><input id="secret" type="password" autocomplete="off" required placeholder="App Password" style="padding:12px;width:90%;margin-top:12px"><button style="padding:12px;margin-top:12px">ربط البريد</button></form><p id="status"></p><script>document.querySelector('form').onsubmit=async e=>{e.preventDefault();const p=document.getElementById('secret');const b=document.querySelector('button');b.disabled=true;document.getElementById('status').textContent='جارٍ التحقق…';try{const r=await fetch(location.pathname,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:document.getElementById('email').value,password:p.value})});p.value='';document.getElementById('status').textContent=r.ok?'تم التحقق من بريد المرسل وربطه. جرّبي تسجيل الدخول في التطبيق.':({400:'أدخلي عنوان Gmail وApp Password من 16 حرفًا.',401:'Gmail رفض بيانات الدخول. أنشئي App Password لحساب Gmail نفسه.',403:'الصفحة مشغولة أو مفتوحة من عنوان مختلف. افتحي صفحة الربط الجديدة.',404:'هذه صفحة ربط قديمة. افتحي الصفحة الجديدة.',502:'تعذّر الاتصال بخادم Gmail. حاولي مرة ثانية.'}[r.status] || 'تعذّر الربط. افتحي صفحة الإعداد الجديدة.');}catch{document.getElementById('status').textContent='تعذر الاتصال بالخادم.';}finally{b.disabled=false;}};</script></body></html>`);
    }
    if (req.url === setupPath && req.method === 'POST') {
      if (req.headers.origin !== origin || configuring) return reply(res,403,{error:'Forbidden'});
      configuring = true;
      try {
        const data = await body(req);
        const email = String(data.email || '').trim();
        const pass = String(data.password || '').replace(/\s/g,'');
        if (!/^[^\s@]+@gmail\.com$/i.test(email) || !/^[a-zA-Z]{16}$/.test(pass)) return reply(res,400,{error:'Invalid settings'});
        const candidate = nodemailer.createTransport({service:'gmail',auth:{user:email,pass},connectionTimeout:10000,socketTimeout:20000});
        try {
          await candidate.verify();
        } catch (error) {
          candidate.close();
          const rejected = error.code === 'EAUTH';
          console.log(rejected ? 'Sender SMTP credentials rejected.' : 'Sender SMTP connection failed.');
          return reply(res,rejected ? 401 : 502,{error:'Could not verify sender.'});
        }
        transport?.close(); transport = candidate; sender = email;
        console.log('Sender SMTP authentication verified.');
        return reply(res,200,{ready:true});
      } finally { configuring = false; }
    }
    if (req.url === '/status' && req.method === 'GET') return reply(res,200,{ready:!!transport});
    if (req.url === '/register-status' && req.method === 'POST') {
      if (req.headers.origin) return reply(res,403,{error:'Forbidden'});
      const {requestId} = await body(req);
      if (typeof requestId !== 'string' || !/^[a-f0-9]{32}$/.test(requestId)) {
        return reply(res,400,{error:'Invalid request'});
      }
      return reply(res,200,await registrationStatus(requestId));
    }
    if (['/forgot-password','/register-confirmation'].includes(req.url) && req.method === 'POST') {
      if (req.headers.origin) return reply(res,403,{error:'Forbidden'});
      if (!transport) return reply(res,503,{error:'Sender email is not connected yet.'});
      const input = await body(req);
      const registration = req.url === '/register-confirmation';
      const requestId = input?.requestId;
      const email = typeof input?.email === 'string' ? input.email.trim().toLowerCase() : '';
      if (email.length > 254 || !/^[^\s@,<>]+@[^\s@,<>]+\.[^\s@,<>]+$/.test(email) ||
          (registration && (typeof requestId !== 'string' || !/^[a-f0-9]{32}$/.test(requestId)))) {
        return reply(res,400,{error:'Invalid email.'});
      }
      const now = Date.now();
      if (now - recoveryWindow >= 3600000) {
        recoveryWindow = now;
        recoveryRequests = 0;
      }
      for (const [address, expires] of recentRecovery) {
        if (expires <= now) recentRecovery.delete(address);
      }
      const key = registration ? `registration:${email}` : email;
      if (recentRecovery.has(key)) {
        return registration ? reply(res,429,{error:'Please wait before requesting another link.'}) : reply(res,202,{accepted:true});
      }
      if (recoveryRequests >= 20) return reply(res,429,{error:'Too many reset requests.'});
      recoveryRequests++;
      recentRecovery.set(key, now + 60000);
      try {
        if (registration) {
          if (!await acceptsMailDomain(email)) {
            recentRecovery.delete(key);
            return reply(res,422,{error:'Email domain does not accept mail.'});
          }
          const {yes,no} = await prepareRegistration(email, requestId);
          const href = link => link.replaceAll('&', '&amp;').replaceAll('"', '&quot;');
          const result = await transport.sendMail({
            from: {name:'FitVisions', address:sender},
            to: {address:email},
            subject: 'FitVisions — Did you register?',
            text: `Did you request a FitVisions account?\n\nYes, it’s me: ${yes}\n\nNo: ${no}`,
            html: `<p>Did you request a FitVisions account?</p><p><a href="${href(yes)}">Yes, it’s me</a></p><p><a href="${href(no)}">No</a></p>`,
          });
          if (!result.accepted?.length) throw new Error('Registration email not accepted');
          console.log('Registration confirmation email accepted by SMTP.');
          return reply(res,202,{accepted:true});
        }
        const link = await recoveryLink(email);
        if (link) {
          const result = await transport.sendMail({
            from: {name:'FitVisions', address:sender},
            to: {address:email},
            subject: 'FitVisions — Reset your password',
            text: `Open this link to choose a different password for your FitVisions account:\n\n${link}\n\nIf you did not request a reset, you can ignore this message.`,
          });
          if (!result.accepted?.length) throw new Error('not accepted');
          console.log('Password reset email accepted by SMTP.');
        }
        return reply(res,202,{accepted:true});
      } catch (error) {
        recentRecovery.delete(key);
        if (registration && error.responseCode === 550 &&
            /\b5\.1\.1\b/.test(error.response || '')) {
          return reply(res,422,{error:'Email address does not exist.'});
        }
        throw error;
      }
    }
    if (!['/login','/registration','/password-changed'].includes(req.url) || req.method !== 'POST') return reply(res,404,{error:'Not found'});
    if (!transport) return reply(res,503,{error:'Sender email is not connected yet.'});
    if (req.headers.origin) return reply(res,403,{error:'Forbidden'});
    const token = (req.headers.authorization || '').replace(/^Bearer /,'');
    let claims;
    try {
      ({payload:claims} = await jwtVerify(token, keys, {algorithms:['RS256'],audience:project,issuer:`https://securetoken.google.com/${project}`}));
    } catch { return reply(res,401,{error:'Sign in again.'}); }
    const now = Math.floor(Date.now()/1000);
    if (!claims.sub || !claims.email || !Number.isInteger(claims.auth_time) || now - claims.auth_time > 300 || claims.auth_time > now + 30) return reply(res,401,{error:'A recent login is required.'});
    // Read the role under the caller's own Firestore rules, never trust a client email or role.
    const profile = await fetch(`https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents/users/${encodeURIComponent(claims.sub)}`,{headers:{Authorization:`Bearer ${token}`},signal:AbortSignal.timeout(10000)});
    if (!profile.ok) return reply(res,403,{error:'Account profile could not be verified.'});
    const fields = (await profile.json()).fields;
    const role = fields?.role?.stringValue;
    if (!['user','admin'].includes(role)) return reply(res,403,{error:'Invalid account role.'});
    const registration = req.url === '/registration';
    const passwordChanged = req.url === '/password-changed';
    let passwordUpdatedAt;
    if (passwordChanged) {
      const lookup = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=${apiKey}`, {
        method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({idToken:token}),signal:AbortSignal.timeout(10000)
      });
      if (!lookup.ok) return reply(res,401,{error:'Could not verify password change.'});
      const account = (await lookup.json()).users?.[0];
      passwordUpdatedAt = Number(account?.passwordUpdatedAt);
      if (account?.localId !== claims.sub || !Number.isFinite(passwordUpdatedAt) || now-passwordUpdatedAt/1000 > 300 || passwordUpdatedAt/1000 > now+30) return reply(res,403,{error:'No recent password change.'});
    }
    const created = Date.parse(fields?.createdAt?.timestampValue || '') / 1000;
    if (registration && (!Number.isFinite(created) || now-created > 300 || created > now+30)) return reply(res,403,{error:'A newly registered account is required.'});
    for (const [key, expires] of sent) if (expires < now) sent.delete(key);
    const event = passwordChanged ? `password:${claims.sub}:${passwordUpdatedAt}` : registration ? `registration:${claims.sub}` : `login:${claims.sub}:${claims.auth_time}`;
    if (sent.has(event)) return reply(res,200,{accepted:true});
    if (pending.has(event)) return reply(res,409,{error:'Notification is being sent.'});
    pending.add(event);
    try {
      const result = await transport.sendMail({
        from:{name:'FitVisions',address:sender},to:claims.email,
        subject:passwordChanged ? 'FitVisions — تغيير كلمة المرور | Password changed' : registration ? 'FitVisions — إنشاء الحساب | Account created' : 'FitVisions — تسجيل الدخول | Successful login',
        text:passwordChanged
          ? 'تم تغيير كلمة المرور لحسابك في FitVisions بنجاح.\n\nYour FitVisions account password has been changed successfully.'
          : registration
            ? 'تم إنشاء حسابك في FitVisions بنجاح.\n\nYour FitVisions account has been created successfully.'
            : 'تم تسجيل الدخول إلى حسابك في FitVisions بنجاح.\n\nYou have successfully signed in to your FitVisions account.',
      });
      if (!result.accepted?.length) throw new Error('not accepted');
      sent.set(event, now+600);
      console.log('Login notification accepted by SMTP.');
      return reply(res,200,{accepted:true});
    } finally { pending.delete(event); }
  } catch { return reply(res,502,{error:'Email service could not complete the request. Try again later.'}); }
});
server.requestTimeout = 30000;
server.listen(8789,'127.0.0.1',async()=>{
  await writeFile('build/mail-setup-url.txt',origin+setupPath);
  console.log('Local login email server ready; awaiting sender setup.');
});
