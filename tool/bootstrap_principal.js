const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

function parseArgs(argv) {
  const args = {};
  for (let index = 0; index < argv.length; index += 1) {
    const current = argv[index];
    if (!current.startsWith('--')) {
      continue;
    }
    const key = current.slice(2);
    const next = argv[index + 1];
    if (!next || next.startsWith('--')) {
      args[key] = 'true';
      continue;
    }
    args[key] = next;
    index += 1;
  }
  return args;
}

function requireArg(args, key, label) {
  const value = (args[key] || '').trim();
  if (!value) {
    throw new Error(`${label} is required. Pass --${key} "<value>"`);
  }
  return value;
}

function validatePassword(password) {
  if (password.length < 8 || password.length > 16) {
    throw new Error('Password must be between 8 and 16 characters.');
  }
  if (!/[A-Z]/.test(password)) {
    throw new Error('Password must contain at least one uppercase letter.');
  }
  if (!/[a-z]/.test(password)) {
    throw new Error('Password must contain at least one lowercase letter.');
  }
  if (!/[0-9]/.test(password)) {
    throw new Error('Password must contain at least one digit.');
  }
  if (!/[!@#$%^&*(),.?":{}|<>]/.test(password)) {
    throw new Error('Password must contain at least one special character.');
  }
}

function resolveServiceAccount(filePath) {
  const absolutePath = path.resolve(process.cwd(), filePath);
  if (!fs.existsSync(absolutePath)) {
    throw new Error(`Service account file not found: ${absolutePath}`);
  }
  const raw = fs.readFileSync(absolutePath, 'utf8');
  return JSON.parse(raw);
}

async function getUserByEmailOrNull(auth, email) {
  try {
    return await auth.getUserByEmail(email);
  } catch (error) {
    if (error && error.code === 'auth/user-not-found') {
      return null;
    }
    throw error;
  }
}

async function ensureOnlyOnePrincipal(db, targetUid) {
  const snapshot = await db.collection('principals').get();
  const conflicting = snapshot.docs.filter((doc) => doc.id !== targetUid);

  if (conflicting.length > 0) {
    const ids = conflicting.map((doc) => doc.id).join(', ');
    throw new Error(
      `Another principal document already exists. Remove or verify it first: ${ids}`,
    );
  }

  return snapshot.docs.find((doc) => doc.id === targetUid) || null;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const serviceAccountPath = requireArg(
    args,
    'service-account',
    'Service account path',
  );
  const email = requireArg(args, 'email', 'Principal email').toLowerCase();
  const password = requireArg(args, 'password', 'Principal password');
  const name = requireArg(args, 'name', 'Principal name');
  const phone = (args.phone || '').trim();

  validatePassword(password);

  const serviceAccount = resolveServiceAccount(serviceAccountPath);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  const auth = admin.auth();
  const db = admin.firestore();

  let userRecord = await getUserByEmailOrNull(auth, email);
  const userAlreadyExisted = userRecord != null;

  if (!userRecord) {
    userRecord = await auth.createUser({
      email,
      password,
      displayName: name,
    });
  } else {
    userRecord = await auth.updateUser(userRecord.uid, {
      password,
      displayName: name,
    });
  }

  const existingPrincipalDoc = await ensureOnlyOnePrincipal(db, userRecord.uid);
  const now = new Date().toISOString();
  const createdAt = existingPrincipalDoc?.get('createdAt') || now;

  const payload = {
    uid: userRecord.uid,
    authUid: userRecord.uid,
    email,
    name,
    role: 'Principal',
    phone,
    imagePath: '',
    className: '',
    section: '',
    subject: '',
    createdAt,
    updatedAt: now,
  };

  await db.collection('principals').doc(userRecord.uid).set(payload, {
    merge: true,
  });
  await auth.setCustomUserClaims(userRecord.uid, {
    role: 'principal',
    isPrincipal: true,
  });

  console.log('');
  console.log('Principal bootstrap completed successfully.');
  console.log(`Project: ${serviceAccount.project_id}`);
  console.log(`Auth user: ${userAlreadyExisted ? 'updated' : 'created'}`);
  console.log(`UID: ${userRecord.uid}`);
  console.log(`Email: ${email}`);
  console.log('Firestore document: principals/<uid>');
  console.log('');
  console.log('Use these credentials in the app principal login screen:');
  console.log(`Email: ${email}`);
  console.log(`Password: ${password}`);
}

main().catch((error) => {
  console.error('');
  console.error('Principal bootstrap failed.');
  console.error(error.message || error);
  process.exitCode = 1;
});
