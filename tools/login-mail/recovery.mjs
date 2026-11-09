import {createRequire} from 'node:module';
import {join} from 'node:path';

const require = createRequire(import.meta.url);
const project = 'fitvisions-33e6d';
const origin = `https://${project}.firebaseapp.com`;

// Local development only. The OAuth credential stays in the laptop process.
export async function recoveryLink(email) {
  const lib = process.env.FITVISIONS_FIREBASE_CLI_LIB;
  if (!lib) throw new Error('Firebase CLI is unavailable');
  const {getGlobalDefaultAccount, getAccessToken} = require(join(lib, 'auth.js'));
  const scopes = require(join(lib, 'scopes.js'));
  const account = getGlobalDefaultAccount();
  if (!account?.tokens?.refresh_token) throw new Error('Firebase CLI is signed out');
  const token = await getAccessToken(account.tokens.refresh_token, [
    scopes.EMAIL, scopes.OPENID, scopes.CLOUD_PROJECTS_READONLY,
    scopes.FIREBASE_PLATFORM, scopes.CLOUD_PLATFORM,
  ]);
  const response = await fetch(
    `https://identitytoolkit.googleapis.com/v1/projects/${project}/accounts:sendOobCode`, {
      method: 'POST',
      headers: {Authorization: `Bearer ${token.access_token}`, 'Content-Type': 'application/json'},
      body: JSON.stringify({
        email, requestType: 'PASSWORD_RESET', returnOobLink: true,
        continueUrl: `${origin}/login`,
      }),
      signal: AbortSignal.timeout(12000),
    },
  );
  const data = await response.json();
  if (!response.ok) {
    if (['EMAIL_NOT_FOUND', 'USER_DISABLED'].includes(data.error?.message)) return null;
    throw new Error('Firebase could not issue a reset link');
  }
  const action = new URL(data.oobLink);
  const code = action.searchParams.get('oobCode');
  if (action.origin !== origin || action.pathname !== '/__/auth/action' ||
      action.searchParams.get('mode') !== 'resetPassword' || !code) {
    throw new Error('Unexpected Firebase action link');
  }
  const page = new URL('/reset-password?v=2', origin);
  page.hash = new URLSearchParams({mode: 'resetPassword', oobCode: code}).toString();
  return page.href;
}
