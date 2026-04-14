# Principal Bootstrap

Use this script to create or repair the one trusted principal account without
manually editing Firestore rows.

## What It Does

- creates the Firebase Auth principal user if missing
- updates the same user if the email already exists
- creates or updates `principals/<uid>` in Firestore
- refuses to continue if another principal document already exists
- sets a custom claim for future admin enforcement

## Before You Run It

1. Open Firebase Console for project `learning-app-d35be`
2. Go to `Project settings > Service accounts`
3. Click `Generate new private key`
4. Save the JSON file somewhere safe on your machine
5. Never commit that JSON file into git

## Install Tool Dependency

```powershell
cd tool
npm install
```

## Run The Bootstrap

```powershell
cd tool
npm run bootstrap:principal -- --service-account "C:\path\to\serviceAccountKey.json" --email "principal@school.com" --password "Admin@123" --name "Principal"
```

Optional:

- `--phone "+923001234567"`

## What Gets Created

- Firebase Auth user with the email/password you pass
- Firestore document: `principals/<same-auth-uid>`

The script creates the `principals` collection automatically if it does not
exist yet, so you do not need to create it manually in Firebase Console.

## After That

1. Deploy Firestore rules
2. Open the app
3. Choose `Principal`
4. Sign in with the same email and password

## Deploy Rules

```powershell
firebase login
firebase use learning-app-d35be
firebase deploy --only firestore:rules,storage
```
