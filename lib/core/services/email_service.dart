import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

/// Free SMTP Email Service - No Firebase Extension Required!
/// Uses Gmail SMTP directly from Flutter app
class EmailService {
  // Your Gmail credentials
  static const String _username = 'rehmanali.pk60@gmail.com';
  static const String _password = 'ibohbtlvlwjziphw'; // App password
  
  /// Send OTP email
  static Future<bool> sendOtpEmail({
    required String toEmail,
    required String otp,
    required String mode, // 'signup' | 'forgotPassword'
  }) async {
    try {
      // Configure Gmail SMTP
      final smtpServer = gmail(_username, _password);
      
      // Create email message
      final message = Message()
        ..from = Address(_username, 'School Management System')
        ..recipients.add(toEmail)
        ..subject = mode == 'forgotPassword'
            ? 'Password Reset - School Management System'
            : 'Email Verification - School Management System'
        ..html = _buildOtpEmailHtml(otp, mode);
      
      // Send email
      final sendReport = await send(message, smtpServer);
      print('✅ Email sent: ${sendReport.toString()}');
      return true;
      
    } catch (e) {
      print('❌ Email sending failed: $e');
      return false;
    }
  }
  
  /// Send credentials email (for student/teacher account creation)
  static Future<bool> sendCredentialsEmail({
    required String toEmail,
    required String userName,
    required String userId,
    required String password,
    required String role,
  }) async {
    try {
      final smtpServer = gmail(_username, _password);
      
      final message = Message()
        ..from = Address(_username, 'School Management System')
        ..recipients.add(toEmail)
        ..subject = 'Your $role Account Credentials - School Management System'
        ..html = _buildCredentialsEmailHtml(
          userName: userName,
          userId: userId,
          password: password,
          role: role,
        );
      
      final sendReport = await send(message, smtpServer);
      print('✅ Credentials email sent: ${sendReport.toString()}');
      return true;
      
    } catch (e) {
      print('❌ Credentials email failed: $e');
      return false;
    }
  }
  
  /// Build OTP email HTML
  static String _buildOtpEmailHtml(String otp, String mode) {
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { 
            font-family: Arial, sans-serif; 
            background: #f5f5f5; 
            padding: 20px; 
            margin: 0;
          }
          .container { 
            max-width: 600px; 
            margin: 0 auto; 
            background: white; 
            padding: 40px; 
            border-radius: 12px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
          }
          .header { 
            text-align: center; 
            color: #1E56CF; 
            margin-bottom: 30px; 
          }
          .header h1 {
            margin: 0;
            font-size: 28px;
          }
          .otp-box { 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 30px; 
            text-align: center; 
            border-radius: 12px; 
            margin: 30px 0;
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
          }
          .otp-code { 
            font-size: 42px; 
            font-weight: bold; 
            letter-spacing: 16px; 
            color: white;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.2);
          }
          .info-text {
            color: #333;
            line-height: 1.6;
            margin: 20px 0;
          }
          .warning {
            background: #fff3cd;
            border-left: 4px solid #ffc107;
            padding: 15px;
            margin: 20px 0;
            border-radius: 4px;
          }
          .footer { 
            text-align: center; 
            color: #666; 
            font-size: 12px; 
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #eee;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🔐 Verification Code</h1>
          </div>
          
          <p class="info-text">Your verification code is:</p>
          
          <div class="otp-box">
            <div class="otp-code">$otp</div>
          </div>
          
          <p class="info-text">
            Enter this code in the app to complete your ${mode == 'forgotPassword' ? 'password reset' : 'email verification'}.
          </p>
          
          <div class="warning">
            <strong>⏰ Important:</strong> This code will expire in <strong>10 minutes</strong>.
          </div>
          
          <p class="info-text">
            If you didn't request this code, please ignore this email or contact support if you have concerns.
          </p>
          
          <div class="footer">
            <p><strong>School Management System</strong></p>
            <p>This is an automated email, please do not reply.</p>
            <p style="margin-top: 10px; color: #999;">
              © ${DateTime.now().year} School Management System. All rights reserved.
            </p>
          </div>
        </div>
      </body>
      </html>
    ''';
  }
  
  /// Build credentials email HTML
  static String _buildCredentialsEmailHtml({
    required String userName,
    required String userId,
    required String password,
    required String role,
  }) {
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { 
            font-family: Arial, sans-serif; 
            background: #f5f5f5; 
            padding: 20px; 
          }
          .container { 
            max-width: 600px; 
            margin: 0 auto; 
            background: white; 
            padding: 40px; 
            border-radius: 12px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
          }
          .header { 
            text-align: center; 
            color: #1E56CF; 
            margin-bottom: 30px; 
          }
          .credentials-box {
            background: #f8f9fa;
            padding: 25px;
            border-radius: 8px;
            margin: 20px 0;
            border: 2px solid #1E56CF;
          }
          .credential-row {
            margin: 15px 0;
            padding: 10px;
            background: white;
            border-radius: 4px;
          }
          .label {
            color: #666;
            font-size: 12px;
            text-transform: uppercase;
            margin-bottom: 5px;
          }
          .value {
            color: #1E56CF;
            font-size: 18px;
            font-weight: bold;
            font-family: monospace;
          }
          .footer { 
            text-align: center; 
            color: #666; 
            font-size: 12px; 
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #eee;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🎓 Welcome to School Management System</h1>
          </div>
          
          <p>Dear <strong>$userName</strong>,</p>
          
          <p>Your $role account has been created successfully. Here are your login credentials:</p>
          
          <div class="credentials-box">
            <div class="credential-row">
              <div class="label">User ID</div>
              <div class="value">$userId</div>
            </div>
            <div class="credential-row">
              <div class="label">Password</div>
              <div class="value">$password</div>
            </div>
            <div class="credential-row">
              <div class="label">Role</div>
              <div class="value">$role</div>
            </div>
          </div>
          
          <p><strong>⚠️ Important:</strong></p>
          <ul>
            <li>Keep these credentials secure</li>
            <li>Change your password after first login</li>
            <li>Do not share your credentials with anyone</li>
          </ul>
          
          <p>You can now login to the School Management System app using these credentials.</p>
          
          <div class="footer">
            <p><strong>School Management System</strong></p>
            <p>This is an automated email, please do not reply.</p>
          </div>
        </div>
      </body>
      </html>
    ''';
  }
}
