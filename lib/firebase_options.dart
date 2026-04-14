import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for all platforms.
///
/// Android: Already configured with real credentials.
///
/// iOS/macOS: Run the following to auto-generate:
///   flutterfire configure --project=learning-app-d35be
///
/// Web: Register a Web app in Firebase Console, then paste credentials below.
class DefaultFirebaseOptions {
  // ── Shared project info (same for all platforms) ──────────────────────────
  static const _projectId = 'learning-app-d35be';
  static const _messagingSenderId = '697771868102';
  static const _storageBucket = 'learning-app-d35be.firebasestorage.app';

  // ── Web credentials ───────────────────────────────────────────────────────
  // NOTE: Firebase Console → Project Settings → Add App → Web
  // Paste the config values below after registering the web app.
  static const _webApiKey = 'YOUR_WEB_API_KEY';
  static const _webAppId = 'YOUR_WEB_APP_ID';

  // ── iOS credentials ───────────────────────────────────────────────────────
  // NOTE: Firebase Console → Project Settings → Add App → iOS
  // Bundle ID: com.example.learningApp
  // Download GoogleService-Info.plist → ios/Runner/GoogleService-Info.plist
  // Then paste the values below.
  static const _iosApiKey = 'YOUR_IOS_API_KEY';
  static const _iosAppId = 'YOUR_IOS_APP_ID';
  static const _iosBundleId = 'com.example.learningApp';

  // ── macOS credentials ─────────────────────────────────────────────────────
  // NOTE: Firebase Console → Project Settings → Add App → macOS
  // Bundle ID: com.example.learningApp
  // Download GoogleService-Info.plist → macos/Runner/GoogleService-Info.plist
  // Then paste the values below.
  static const _macosApiKey = 'YOUR_MACOS_API_KEY';
  static const _macosAppId = 'YOUR_MACOS_APP_ID';

  // ─────────────────────────────────────────────────────────────────────────

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      _assertConfigured(_webApiKey, 'Web');
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        _assertConfigured(_iosApiKey, 'iOS');
        return ios;
      case TargetPlatform.macOS:
        _assertConfigured(_macosApiKey, 'macOS');
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'Firebase has not been configured for Windows. '
          'Run: flutterfire configure --project=$_projectId',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Firebase has not been configured for Linux. '
          'Run: flutterfire configure --project=$_projectId',
        );
      default:
        throw UnsupportedError(
          'Firebase is not supported on this platform.',
        );
    }
  }

  /// Throws a clear error when a platform still has placeholder credentials.
  static void _assertConfigured(String value, String platform) {
    if (value.startsWith('YOUR_')) {
      throw UnsupportedError(
        'Firebase is not configured for $platform yet.\n'
        'See lib/firebase_options.dart for setup instructions.',
      );
    }
  }

  // ── Android (configured) ──────────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDCx21PwHkOVxJPT6PQuFbEH3uALVTRQYs',
    appId: '1:$_messagingSenderId:android:8a8bc04c6387450ae4bcc7',
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
  );

  // ── Web (needs setup) ─────────────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: _webApiKey,
    appId: _webAppId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    authDomain: '$_projectId.firebaseapp.com',
    storageBucket: _storageBucket,
  );

  // ── iOS (needs setup) ─────────────────────────────────────────────────────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: _iosApiKey,
    appId: _iosAppId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
    iosBundleId: _iosBundleId,
  );

  // ── macOS (needs setup) ───────────────────────────────────────────────────
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: _macosApiKey,
    appId: _macosAppId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
    iosBundleId: _iosBundleId,
  );
}
