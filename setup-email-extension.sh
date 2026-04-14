#!/bin/bash

# Firebase Email Extension Setup Script
# This script automates the Firebase Email Extension installation

echo "🚀 Firebase Email Extension Setup"
echo "=================================="
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null
then
    echo "❌ Firebase CLI not found!"
    echo "Install it with: npm install -g firebase-tools"
    exit 1
fi

echo "✅ Firebase CLI found"
echo ""

# Login to Firebase
echo "📝 Logging in to Firebase..."
firebase login

echo ""
echo "🔧 Installing Firebase Email Extension..."
echo ""

# Install extension with configuration
firebase ext:install firebase/firestore-send-email \
  --params SMTP_CONNECTION_URI="smtp://rehmanali.pk60@gmail.com:ibohbtlvlwjziphw@smtp.gmail.com:587" \
  --params DEFAULT_FROM="rehmanali.pk60@gmail.com" \
  --params DEFAULT_REPLY_TO="rehmanali.pk60@gmail.com" \
  --params MAIL_COLLECTION="mail"

echo ""
echo "📤 Deploying Firestore rules..."
firebase deploy --only firestore:rules

echo ""
echo "📤 Deploying extension..."
firebase deploy --only extensions

echo ""
echo "✅ Setup Complete!"
echo ""
echo "📋 Next Steps:"
echo "1. Test email sending by adding a document to 'mail' collection"
echo "2. Check Firebase Console → Extensions → Email for logs"
echo "3. Run your Flutter app: flutter run"
echo ""
echo "🧪 Test Email Command:"
echo "firebase firestore:write mail/test '{\"to\":[\"your-email@gmail.com\"],\"message\":{\"subject\":\"Test\",\"text\":\"Test email\"}}'"
echo ""
