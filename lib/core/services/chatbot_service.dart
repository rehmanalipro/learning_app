import 'package:get/get.dart';

class ChatbotService extends GetxService {
  static final List<_HelpTopic> _topics = [
    _HelpTopic(
      keywords: [
        'attendance',
        'present',
        'absent',
        'mark attendance',
        'teacher attendance',
        'hazri',
        'attendance lag',
        'how to mark',
        'check attendance',
      ],
      answer:
          '📋 **Attendance Management**\n\n'
          '**For Teachers:**\n'
          '1. Open "Attendance" from dashboard\n'
          '2. Select your class and section\n'
          '3. Mark each student as Present/Absent\n'
          '4. Click "Save" to submit\n\n'
          '**For Students:**\n'
          '• View your attendance history\n'
          '• Submit attendance request (if enabled)\n'
          '• Receive notifications when marked\n\n'
          '**For Principal:**\n'
          '• View all classes attendance\n'
          '• Mark attendance for any class',
      category: 'Attendance',
    ),
    _HelpTopic(
      keywords: [
        'homework',
        'assignment',
        'submit homework',
        'solution',
        'pdf',
        'home work',
        'homework submit',
        'create homework',
        'upload homework',
      ],
      answer:
          '📚 **Homework Management**\n\n'
          '**For Teachers:**\n'
          '1. Open "Homework" from dashboard\n'
          '2. Click "Create Assignment"\n'
          '3. Fill in title, details, due date\n'
          '4. Upload PDF (optional)\n'
          '5. Submit to class\n'
          '6. Review student submissions\n\n'
          '**For Students:**\n'
          '1. Open "Homework" section\n'
          '2. View assigned homework\n'
          '3. Click "Submit Solution"\n'
          '4. Write answer or upload PDF\n'
          '5. Submit before due date\n\n'
          '**Features:**\n'
          '• PDF upload support\n'
          '• Due date tracking\n'
          '• Teacher feedback',
      category: 'Homework',
    ),
    _HelpTopic(
      keywords: [
        'result',
        'marks',
        'grade',
        'exam result',
        'natija',
        'number',
        'score',
        'enter marks',
        'view result',
      ],
      answer:
          '📊 **Result Management**\n\n'
          '**For Teachers:**\n'
          '1. Open "Result" from dashboard\n'
          '2. Select class, term, exam type\n'
          '3. Enter marks for each student\n'
          '4. Set max marks for subject\n'
          '5. Click "Save Results"\n\n'
          '**For Students:**\n'
          '1. Open "Result" section\n'
          '2. View your marks by term\n'
          '3. See subject-wise scores\n'
          '4. Check total and percentage\n\n'
          '**For Principal:**\n'
          '• View all classes results\n'
          '• Edit any student marks\n'
          '• Generate reports\n\n'
          '**Note:** Results appear after teacher saves them.',
      category: 'Results',
    ),
    _HelpTopic(
      keywords: [
        'quiz',
        'mcq',
        'test',
        'create quiz',
        'attempt quiz',
        'quize',
        'question',
        'answer',
      ],
      answer:
          '🎯 **Quiz System**\n\n'
          '**For Teachers:**\n'
          '1. Open "Quiz" from dashboard\n'
          '2. Click "Create Quiz"\n'
          '3. Enter question text\n'
          '4. Add 4 options (A, B, C, D)\n'
          '5. Mark correct answer\n'
          '6. Save quiz\n\n'
          '**For Students:**\n'
          '1. Open "Quiz" section\n'
          '2. View available quizzes\n'
          '3. Select a quiz to attempt\n'
          '4. Choose your answer\n'
          '5. Submit to see instant result\n\n'
          '**Features:**\n'
          '• Multiple choice questions\n'
          '• Instant scoring\n'
          '• Attempt history\n'
          '• Class-specific quizzes',
      category: 'Quiz',
    ),
    _HelpTopic(
      keywords: [
        'exam',
        'routine',
        'schedule',
        'date sheet',
        'datesheet',
        'exam routine',
        'paper',
        'timetable',
        'exam date',
      ],
      answer:
          '📅 **Exam Schedule**\n\n'
          '**For Teachers/Principal:**\n'
          '1. Open "Exam Routine"\n'
          '2. Click "Add Schedule"\n'
          '3. Select class and section\n'
          '4. Enter subject and date\n'
          '5. Add time, room, seat info\n'
          '6. Upload date sheet PDF (optional)\n'
          '7. Save schedule\n\n'
          '**For Students:**\n'
          '1. Open "Exam Routine"\n'
          '2. View your class schedule\n'
          '3. See exam dates and times\n'
          '4. Check room and seat numbers\n'
          '5. Download date sheet PDF\n\n'
          '**Information Included:**\n'
          '• Subject name\n'
          '• Date and time\n'
          '• Room and seat number\n'
          '• Shift details',
      category: 'Exam',
    ),
    _HelpTopic(
      keywords: [
        'notice',
        'event',
        'announcement',
        'post notice',
        'elan',
        'notification',
        'news',
        'update',
      ],
      answer:
          '📢 **Notice & Events**\n\n'
          '**For Principal:**\n'
          '1. Open "Notice & Events"\n'
          '2. Click "Create Notice"\n'
          '3. Choose scope (School-wide/Class)\n'
          '4. Enter title and description\n'
          '5. Select category (Notice/Event/Holiday)\n'
          '6. Publish to students\n\n'
          '**For Teachers:**\n'
          '1. Create class-specific notices\n'
          '2. Share important updates\n'
          '3. Announce class events\n\n'
          '**For Students:**\n'
          '1. View all notices on home screen\n'
          '2. See unread count badge\n'
          '3. Get popup notifications\n'
          '4. Filter by category\n\n'
          '**Categories:**\n'
          '• General Notice\n'
          '• School Event\n'
          '• Holiday Announcement\n'
          '• Important Update',
      category: 'Notice',
    ),
    _HelpTopic(
      keywords: [
        'profile',
        'photo',
        'name',
        'email',
        'phone',
        'my profile',
        'edit profile',
        'update profile',
        'change photo',
      ],
      answer:
          '👤 **Profile Management**\n\n'
          '**How to Update Profile:**\n'
          '1. Open drawer menu (☰)\n'
          '2. Tap "My Profile"\n'
          '3. Click "Edit Profile"\n'
          '4. Update your information:\n'
          '   • Name\n'
          '   • Email\n'
          '   • Phone number\n'
          '   • Profile photo\n'
          '5. Click "Save Changes"\n\n'
          '**To Change Photo:**\n'
          '1. Tap on profile picture\n'
          '2. Choose "Camera" or "Gallery"\n'
          '3. Select/capture photo\n'
          '4. Crop if needed\n'
          '5. Save\n\n'
          '**Note:** Some fields like class, section, and role cannot be changed by users.',
      category: 'Profile',
    ),
    _HelpTopic(
      keywords: [
        'password',
        'change password',
        'forgot password',
        'reset',
        'password bhool gaya',
        'reset password',
        'new password',
      ],
      answer:
          '🔐 **Password Management**\n\n'
          '**Change Password (Logged In):**\n'
          '1. Open drawer menu (☰)\n'
          '2. Tap "Change Password"\n'
          '3. Enter current password\n'
          '4. Enter new password\n'
          '5. Confirm new password\n'
          '6. Click "Update Password"\n\n'
          '**Forgot Password (Not Logged In):**\n'
          '1. Go to Login screen\n'
          '2. Click "Forgot Password?"\n'
          '3. Enter your email\n'
          '4. Verify OTP code\n'
          '5. Set new password\n'
          '6. Login with new password\n\n'
          '**Password Requirements:**\n'
          '• Minimum 6 characters\n'
          '• Mix of letters and numbers recommended\n'
          '• Keep it secure and memorable',
      category: 'Security',
    ),
    _HelpTopic(
      keywords: [
        'dark mode',
        'light mode',
        'theme',
        'settings',
        'mode',
        'theme change',
        'appearance',
        'dark theme',
      ],
      answer:
          '🎨 **Settings & Preferences**\n\n'
          '**Change Theme:**\n'
          '1. Open drawer menu (☰)\n'
          '2. Tap "Settings"\n'
          '3. Find "Theme" section\n'
          '4. Choose:\n'
          '   • Light Mode\n'
          '   • Dark Mode\n'
          '   • System Default\n\n'
          '**Notification Settings:**\n'
          '1. Go to Settings\n'
          '2. Toggle "Enable Notifications"\n'
          '3. Choose notification types\n\n'
          '**Other Settings:**\n'
          '• Language preferences\n'
          '• App version info\n'
          '• About school\n'
          '• Emergency contacts\n\n'
          '**Note:** Settings are saved automatically.',
      category: 'Settings',
    ),
    _HelpTopic(
      keywords: [
        'login',
        'register',
        'signup',
        'sign in',
        'log in',
        'otp',
        'account',
        'create account',
        'new account',
      ],
      answer:
          '🔑 **Login & Registration**\n\n'
          '**For New Users (Register):**\n'
          '1. Open app and select role\n'
          '2. Click "Register"\n'
          '3. Fill in details:\n'
          '   • Name, Email, Phone\n'
          '   • Class/Section (for students/teachers)\n'
          '   • Admission No (for students)\n'
          '4. Verify OTP code\n'
          '5. Set password\n'
          '6. Complete registration\n\n'
          '**For Existing Users (Login):**\n'
          '1. Select your role\n'
          '2. Enter email/user ID\n'
          '3. Enter password\n'
          '4. Click "Login"\n\n'
          '**OTP Verification:**\n'
          '• Check email for 4-digit code\n'
          '• Enter code within 10 minutes\n'
          '• Request new code if expired\n\n'
          '**Note:** Student accounts are created by Principal.',
      category: 'Authentication',
    ),
    _HelpTopic(
      keywords: [
        'role',
        'student',
        'teacher',
        'principal',
        'admin',
        'kirdar',
        'user type',
        'access',
      ],
      answer:
          '👥 **User Roles & Permissions**\n\n'
          '**Student Role:**\n'
          '• View attendance history\n'
          '• Submit homework\n'
          '• Check results\n'
          '• Attempt quizzes\n'
          '• View exam schedule\n'
          '• Read notices\n'
          '• Update own profile\n\n'
          '**Teacher Role:**\n'
          '• Mark attendance for class\n'
          '• Create homework assignments\n'
          '• Enter student results\n'
          '• Create quizzes\n'
          '• Upload exam schedules\n'
          '• Post class notices\n'
          '• View student submissions\n\n'
          '**Principal Role:**\n'
          '• All teacher permissions\n'
          '• Create student accounts\n'
          '• Manage teacher accounts\n'
          '• View all classes data\n'
          '• Post school-wide notices\n'
          '• Full administrative access\n\n'
          '**Note:** Roles are assigned during registration.',
      category: 'Roles',
    ),
  ];

  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _addWelcomeMessage();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    messages.add(ChatMessage(text: text, isUser: true));
    isLoading.value = true;

    try {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      final reply = _generateReply(text);
      messages.add(ChatMessage(text: reply, isUser: false));
    } catch (e) {
      // ignore: avoid_print
      print('[Chatbot Error] $e');
      messages.add(
        ChatMessage(
          text:
              'I can help with app features like attendance, homework, quiz, results, profile, and login.',
          isUser: false,
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void clearChat() {
    messages.clear();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    messages.add(
      ChatMessage(
        text:
            '👋 **Welcome to School App Assistant!**\n\n'
            'I can help you with:\n'
            '• Attendance management\n'
            '• Homework & assignments\n'
            '• Results & grades\n'
            '• Quizzes & tests\n'
            '• Exam schedules\n'
            '• Notices & events\n'
            '• Profile settings\n'
            '• Login & registration\n\n'
            'Ask me anything about these features!',
        isUser: false,
      ),
    );
  }

  String _generateReply(String text) {
    final normalized = text.toLowerCase().trim();

    if (_isGreeting(normalized)) {
      return '👋 **Hello!**\n\n'
          'I\'m your School App Assistant. I can help you understand how to use different features of this app.\n\n'
          '**Popular Topics:**\n'
          '• How to mark attendance?\n'
          '• How to submit homework?\n'
          '• How to check results?\n'
          '• How to create a quiz?\n'
          '• How to view exam schedule?\n\n'
          'What would you like to know?';
    }

    if (_asksAboutCapabilities(normalized)) {
      return '🎯 **I Can Help You With:**\n\n'
          '**Academic Features:**\n'
          '• Attendance Management\n'
          '• Homework & Assignments\n'
          '• Results & Grades\n'
          '• Quizzes & Tests\n'
          '• Exam Schedules\n\n'
          '**Communication:**\n'
          '• Notices & Events\n'
          '• Announcements\n\n'
          '**Account Management:**\n'
          '• Profile Settings\n'
          '• Password Management\n'
          '• Login & Registration\n\n'
          '**App Settings:**\n'
          '• Theme (Dark/Light Mode)\n'
          '• Notifications\n'
          '• Preferences\n\n'
          'Just ask me about any feature!';
    }

    for (final topic in _topics) {
      if (topic.matches(normalized)) {
        return topic.answer;
      }
    }

    return '❓ **I didn\'t quite understand that.**\n\n'
        'I can only answer questions about this School Management App.\n\n'
        '**Try asking about:**\n'
        '• "How to mark attendance?"\n'
        '• "How to submit homework?"\n'
        '• "How to check results?"\n'
        '• "How to create a quiz?"\n'
        '• "How to change password?"\n'
        '• "How to change theme?"\n\n'
        'Or type "help" to see all available topics.';
  }

  bool _isGreeting(String text) {
    const greetings = [
      'hi',
      'hello',
      'hey',
      'salam',
      'assalam',
      'asalam',
      'aoa',
      'salaam',
      'walikum',
    ];

    return greetings.any(text.contains);
  }

  bool _asksAboutCapabilities(String text) {
    const prompts = [
      'what can you do',
      'help',
      'features',
      'how can you help',
      'capabilities',
      'what do you know',
      'topics',
      'menu',
    ];

    return prompts.any(text.contains);
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  ChatMessage({required this.text, required this.isUser, DateTime? time})
    : time = time ?? DateTime.now();
}

class _HelpTopic {
  final List<String> keywords;
  final String answer;
  final String category;

  const _HelpTopic({
    required this.keywords,
    required this.answer,
    required this.category,
  });

  bool matches(String text) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) {
        return true;
      }
    }
    return false;
  }
}
