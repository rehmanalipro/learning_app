import 'dart:math';

import 'package:get/get.dart';

import 'firebase_service.dart';
import 'email_service.dart';

/// Stores and verifies 4-digit OTPs in Firestore collection `email_otps`.
/// Each document: { otp, email, mode, createdAt, expiresAt }
class OtpService extends GetxService {
  static const _collection = 'email_otps';
  static const _expiryMinutes = 10;

  final FirebaseService _firebaseService = FirebaseService();

  @override
  void onInit() {
    super.onInit();
    _firebaseService.initialize();
  }

  /// Generates a 4-digit OTP, saves it to Firestore, sends email, and returns it.
  /// Uses Firebase Email Extension to send OTP via email.
  /// In production, ensure Firebase Extension is installed and configured.
  Future<String> generateAndSaveOtp({
    required String email,
    required String mode, // 'signup' | 'forgotPassword' | 'changePassword'
  }) async {
    final otp = _generateOtp();
    final now = DateTime.now();
    final docId = '${email.replaceAll('@', '_').replaceAll('.', '_')}_$mode';

    // Save OTP to Firestore
    await _firebaseService.firestore.collection(_collection).doc(docId).set({
      'otp': otp,
      'email': email,
      'mode': mode,
      'createdAt': now.toIso8601String(),
      'expiresAt': now.add(const Duration(minutes: _expiryMinutes)).toIso8601String(),
      'verified': false,
    });

    // Send OTP via email (Firebase Extension)
    await _sendOtpEmail(email: email, otp: otp, mode: mode);

    return otp;
  }

  /// Sends OTP email via direct SMTP (no Firebase Extension needed).
  /// Uses EmailService for free email sending.
  Future<void> _sendOtpEmail({
    required String email,
    required String otp,
    required String mode,
  }) async {
    try {
      // Import at top: import '../services/email_service.dart';
      // Use direct SMTP email service (100% free, no Firebase Extension)
      final success = await EmailService.sendOtpEmail(
        toEmail: email,
        otp: otp,
        mode: mode,
      );
      
      if (success) {
        // ignore: avoid_print
        print('[OTP Service] ✅ Email sent successfully to $email');
      } else {
        // ignore: avoid_print
        print('[OTP Service] ⚠️ Email sending failed, but OTP saved in Firestore');
      }
    } catch (e) {
      // Log error but don't fail - OTP is still saved in Firestore
      // In development, OTP will be shown in snackbar
      // ignore: avoid_print
      print('[OTP Service] Email sending error: $e');
    }
  }

  /// Verifies the OTP. Returns true if valid and not expired.
  Future<bool> verifyOtp({
    required String email,
    required String otp,
    required String mode,
  }) async {
    final docId = '${email.replaceAll('@', '_').replaceAll('.', '_')}_$mode';
    final doc = await _firebaseService.firestore
        .collection(_collection)
        .doc(docId)
        .get();

    if (!doc.exists) return false;
    final data = doc.data()!;

    final storedOtp = data['otp'] as String? ?? '';
    final expiresAt = DateTime.tryParse(data['expiresAt'] as String? ?? '');
    final verified = data['verified'] as bool? ?? false;

    if (verified) return false; // already used
    if (expiresAt == null || DateTime.now().isAfter(expiresAt)) return false;
    if (storedOtp != otp) return false;

    // Mark as verified
    await _firebaseService.firestore
        .collection(_collection)
        .doc(docId)
        .update({'verified': true});

    return true;
  }

  /// Deletes the OTP document after use.
  Future<void> deleteOtp({required String email, required String mode}) async {
    final docId = '${email.replaceAll('@', '_').replaceAll('.', '_')}_$mode';
    try {
      await _firebaseService.firestore
          .collection(_collection)
          .doc(docId)
          .delete();
    } catch (_) {}
  }

  String _generateOtp() {
    final rng = Random.secure();
    return List.generate(4, (_) => rng.nextInt(10)).join();
  }
}
