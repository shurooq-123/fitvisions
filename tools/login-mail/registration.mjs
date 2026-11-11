import { randomBytes } from 'node:crypto';
import { resolveMx, lookup } from 'node:dns/promises';
import { firebaseAccessToken, registrationSignInLink } from './recovery.mjs';

const collection = 'https://firestore.googleapis.com/v1/projects/fitvisions-33e6d/databases/(default)/documents/registrationDecisions';
const confirmationPage = 'https://fitvisions-33e6d-confirm.web.app/';
const lifetime = 15 * 60 * 1000;
const requests = new Map();

export async function acceptsMailDomain(email) {
  const domain = email.split('@')[1];
  try {
    const records = await resolveMx(domain);
    if (records.length) return records.some(({exchange}) => exchange && exchange !== '.');
  } catch (error) {
    if (error.code === 'ENOTFOUND') return false;
    if (error.code !== 'ENODATA') return true;
  }
  try {
    await lookup(domain);
    return true;
  } catch (error) {
    return error.code !== 'ENOTFOUND' && error.code !== 'ENODATA';
  }
}

async function firestore(id, method, fields) {
  const token = await firebaseAccessToken();
  const url = new URL(`${collection}/${id}`);
  if (method === 'PATCH') url.searchParams.set('currentDocument.exists', 'false');
  const response = await fetch(url, {
    method,
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: fields ? JSON.stringify({ fields }) : undefined,
    signal: AbortSignal.timeout(8000),
  });
  if (method === 'GET' && response.status === 404) return null;
  if (!response.ok) throw new Error('Could not access registration confirmation');
  return response.json();
}

function actionUrl(id, proof, decision) {
  const url = new URL(confirmationPage);
  url.hash = new URLSearchParams({id, proof, decision}).toString();
  return url.href;
}

export async function prepareRegistration(email, requestId) {
  const signInLink = await registrationSignInLink(email, requestId);
  const id = randomBytes(16).toString('hex');
  const yes = randomBytes(24).toString('hex');
  const no = randomBytes(24).toString('hex');
  const expires = Date.now() + lifetime;
  await firestore(id, 'PATCH', {
    yesProof: {stringValue: yes},
    noProof: {stringValue: no},
    decision: {stringValue: 'pending'},
    expiresAt: {timestampValue: new Date(expires).toISOString()},
  });
  requests.set(requestId, {id, signInLink, expires});
  setTimeout(() => {
    requests.delete(requestId);
    firestore(id, 'DELETE').catch(() => {});
  }, lifetime).unref();
  return {
    yes: actionUrl(id, yes, 'approved'),
    no: actionUrl(id, no, 'declined'),
  };
}

export async function registrationStatus(requestId) {
  const entry = requests.get(requestId);
  if (!entry || entry.expires <= Date.now()) return {status: 'expired'};
  const document = await firestore(entry.id, 'GET');
  const status = document?.fields?.decision?.stringValue ?? 'expired';
  return status === 'approved' ? {status, link: entry.signInLink} : {status};
}
