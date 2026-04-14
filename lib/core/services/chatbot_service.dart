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
      ],
      urduAnswer:
          'Attendance feature mein teacher apni class ke students ki bulk hazri mark karta hai. Teacher dashboard se Attendance kholen, class select karein, students ko Present ya Absent mark karein aur save kar dein. Student apni attendance history sirf dekh sakta hai.',
      englishAnswer:
          'In Attendance, the teacher marks class attendance in bulk. Open Attendance from the teacher dashboard, choose the class, mark each student as Present or Absent, then save. Students can only view their attendance history.',
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
      ],
      urduAnswer:
          'Homework ke liye teacher apni class ko assignment deta hai. Student homework section se task open karta hai, apni PDF file select karta hai aur submit karta hai. Teacher submitted solutions dekh sakta hai.',
      englishAnswer:
          'For Homework, the teacher creates an assignment for the class. The student opens the homework item, picks a PDF file, and submits it. The teacher can then review submitted solutions.',
    ),
    _HelpTopic(
      keywords: ['result', 'marks', 'grade', 'exam result', 'natija', 'number'],
      urduAnswer:
          'Result module mein teacher class ke students ke marks enter karta hai. Save hone ke baad student apna result screen par dekh sakta hai. Agar result show na ho to dobara refresh karein ya teacher se marks confirm karein.',
      englishAnswer:
          'In the Result module, the teacher enters marks for students. After saving, students can view their result on the result screen. If results are missing, refresh and confirm the marks were entered by the teacher.',
    ),
    _HelpTopic(
      keywords: ['quiz', 'mcq', 'test', 'create quiz', 'attempt quiz', 'quize'],
      urduAnswer:
          'Quiz feature mein teacher naya quiz banata hai aur student usay attempt karta hai. Student submit karte hi instant result dekh leta hai. Quiz create karne ke liye teacher quiz screen par ja kar title, questions aur answers add kare.',
      englishAnswer:
          'In Quiz, the teacher creates a quiz and the student attempts it. The student gets an instant result after submission. To create one, the teacher opens the quiz screen and adds the title, questions, and answers.',
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
      ],
      urduAnswer:
          'Exam Schedule mein teacher ya principal class ke exams ka timetable publish kar sakta hai. Student exam routine screen se dates aur subjects dekh sakta hai.',
      englishAnswer:
          'In Exam Schedule, the teacher or principal can publish the exam timetable for a class. Students can open the exam routine screen to view dates and subjects.',
    ),
    _HelpTopic(
      keywords: ['notice', 'event', 'announcement', 'post notice', 'elan'],
      urduAnswer:
          'Notices aur events ke liye principal school-wide updates share karta hai, jab ke teacher class-specific information de sakta hai. Related notice section ya home screen par updates nazar aayengi.',
      englishAnswer:
          'For notices and events, the principal can share school-wide updates and the teacher can share class-specific information. Users will see these updates in the relevant notice area or home screen.',
    ),
    _HelpTopic(
      keywords: ['profile', 'photo', 'name', 'email', 'phone', 'my profile'],
      urduAnswer:
          'Profile section mein aap apna naam, email, phone number aur photo update kar sakte hain. Drawer se My Profile kholen, changes karein aur save kar dein.',
      englishAnswer:
          'In the Profile section, you can update your name, email, phone number, and photo. Open My Profile from the drawer, make your changes, and save them.',
    ),
    _HelpTopic(
      keywords: [
        'password',
        'change password',
        'forgot password',
        'reset',
        'password bhool gaya',
      ],
      urduAnswer:
          'Password change karne ke liye drawer mein Change Password option use karein. Agar login na ho raha ho to Forgot Password ya OTP flow use karke account recover karein.',
      englishAnswer:
          'To change your password, use the Change Password option from the drawer. If you cannot log in, use the Forgot Password or OTP flow to recover the account.',
    ),
    _HelpTopic(
      keywords: [
        'dark mode',
        'light mode',
        'theme',
        'settings',
        'mode',
        'theme change',
      ],
      urduAnswer:
          'Dark aur Light mode change karne ke liye drawer se Settings kholen. Wahan se apni pasand ka theme select kar sakte hain.',
      englishAnswer:
          'To switch between Dark and Light mode, open Settings from the drawer and choose the theme you prefer.',
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
      ],
      urduAnswer:
          'Naya account banane ke liye Register screen use karein. Existing user Login screen se sign in kar sakta hai, aur OTP screen verification mein help karti hai.',
      englishAnswer:
          'Use the Register screen to create a new account. Existing users can sign in from the Login screen, and the OTP screen helps with verification.',
    ),
    _HelpTopic(
      keywords: ['role', 'student', 'teacher', 'principal', 'admin', 'kirdar'],
      urduAnswer:
          'Is app mein teen main roles hain: Student, Teacher aur Principal. Student apni information aur tasks dekhta hai, Teacher class management karta hai, aur Principal school-level controls aur updates manage karta hai.',
      englishAnswer:
          'This app mainly supports three roles: Student, Teacher, and Principal. Students view their own tasks and data, teachers manage class activities, and principals handle school-level controls and updates.',
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
            'Assalam o Alaikum! Main is app ka free assistant hun. Attendance, homework, result, quiz, exam schedule, profile, login ya settings ke baray mein pooch sakte hain.',
        isUser: false,
      ),
    );
  }

  String _generateReply(String text) {
    final normalized = text.toLowerCase().trim();
    final isUrdu = _looksLikeUrdu(text);

    if (_isGreeting(normalized)) {
      return isUrdu
          ? 'Walaikum Salam! Main sirf is app ke features samjhane ke liye hun. Aap attendance, homework, result, quiz, profile ya login ke baray mein pooch sakte hain.'
          : 'Hello! I am here to explain this app only. You can ask about attendance, homework, results, quiz, profile, or login.';
    }

    if (_asksAboutCapabilities(normalized)) {
      return isUrdu
          ? 'Main is app ke baray mein madad karta hun: attendance, homework, quiz, result, exam schedule, notices, profile, password aur settings. Aap simple sawal likhein, main step by step guide dunga.'
          : 'I can help with this app only: attendance, homework, quiz, results, exam schedule, notices, profile, password, and settings. Ask a simple question and I will guide you step by step.';
    }

    for (final topic in _topics) {
      if (topic.matches(normalized)) {
        return isUrdu ? topic.urduAnswer : topic.englishAnswer;
      }
    }

    return isUrdu
        ? 'Main sirf is school app ke features ke baray mein jawab deta hun. Aap attendance, homework, result, quiz, exam schedule, notices, profile, password ya settings ke baray mein pooch sakte hain.'
        : 'I only answer questions about this school app. You can ask about attendance, homework, results, quiz, exam schedule, notices, profile, password, or settings.';
  }

  bool _looksLikeUrdu(String text) {
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(text)) {
      return true;
    }

    final normalized = text.toLowerCase();
    const romanUrduHints = [
      'kaise',
      'kahan',
      'kya',
      'kyun',
      'mein',
      'main',
      'madad',
      'dekhen',
      'dekho',
      'hota',
      'hoti',
      'hun',
      'hai',
      'karna',
      'karni',
      'chahiye',
    ];

    return romanUrduHints.any(normalized.contains);
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
      'kya kar sakte',
      'madad',
      'kis bare mein',
      'kon si cheezein',
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
  final String urduAnswer;
  final String englishAnswer;

  const _HelpTopic({
    required this.keywords,
    required this.urduAnswer,
    required this.englishAnswer,
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
