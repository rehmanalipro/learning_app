import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import '../../../core/theme/app_theme_helper.dart';
import '../../../routes/app_routes.dart';
import '../../auth/providers/firebase_auth_provider.dart';
import '../../theme/providers/app_theme_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuthProvider _authProvider = Get.find<FirebaseAuthProvider>();
  final AppThemeProvider _appThemeProvider = Get.find<AppThemeProvider>();

  String get role {
    final args = Get.arguments;
    if (args is String && args.isNotEmpty) return args;
    if (args is Map<String, dynamic>) {
      final mappedRole = args['role'] as String?;
      if (mappedRole != null && mappedRole.isNotEmpty) return mappedRole;
    }
    return 'Student';
  }

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _admissionNoController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _programController = TextEditingController();
  final TextEditingController _rollNumberController = TextEditingController();
  final TextEditingController _teacherSubjectController =
      TextEditingController();
  final List<String> _classes = const [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
  ];
  final List<String> _sections = const ['A', 'B', 'C'];
  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'PK', dialCode: '+92');
  String _phoneString = '';
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  String _selectedClass = '3';
  String _selectedSection = 'A';

  bool _hasUpper = false;
  bool _hasLower = false;
  bool _hasDigit = false;
  bool _hasSpecial = false;
  bool _minLength = false;

  bool get _isPasswordValid =>
      _hasUpper && _hasLower && _hasDigit && _hasSpecial && _minLength;

  bool get _showPasswordHints =>
      _passwordFocusNode.hasFocus ||
      (_passwordController.text.isNotEmpty && !_isPasswordValid);

  bool get _isConfirmPasswordMismatch =>
      _confirmController.text.isNotEmpty &&
      _confirmController.text != _passwordController.text;

  Future<void> _pickDateOfBirth() async {
    final initialDate =
        DateTime.tryParse(_dateOfBirthController.text.trim()) ??
        DateTime(2015, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1990, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(picked);
  }

  void _checkPassword(String value) {
    setState(() {
      _hasUpper = value.contains(RegExp(r'[A-Z]'));
      _hasLower = value.contains(RegExp(r'[a-z]'));
      _hasDigit = value.contains(RegExp(r'[0-9]'));
      _hasSpecial = value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
      _minLength = value.length >= 8;
    });
  }

  Widget _criteriaRow(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isValid ? Colors.green : Colors.grey,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(color: isValid ? Colors.green : Colors.grey),
        ),
      ],
    );
  }

  Future<void> _onSignup() async {
    final roleLower = role.toLowerCase();

    if (roleLower == 'student') {
      Get.snackbar(
        'Student signup disabled',
        'Student account principal admission module se create hota hai.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (roleLower == 'teacher') {
      Get.snackbar(
        'Teacher signup disabled',
        'Teacher account principal management module se create hota hai.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (roleLower == 'principal') {
      Get.snackbar(
        'Principal signup disabled',
        'Principal account ab app se self-signup nahi kare ga. Sirf existing principal login kare ga.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if ((roleLower != 'student' && _nameController.text.isEmpty) ||
        _emailController.text.isEmpty ||
        _phoneString.isEmpty ||
        _passwordController.text.isEmpty) {
      Get.snackbar(
        'Validation',
        'Please fill all fields',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      Get.snackbar(
        'Validation',
        'Password and confirm password do not match',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (!(_hasUpper && _hasLower && _hasDigit && _hasSpecial && _minLength)) {
      Get.snackbar(
        'Validation',
        'Password does not meet requirements',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (roleLower == 'teacher' &&
        (_selectedClass.isEmpty ||
            _selectedSection.isEmpty ||
            _teacherSubjectController.text.trim().isEmpty)) {
      Get.snackbar(
        'Validation',
        'Please fill class, section, and subject fields',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (roleLower == 'student' &&
        (_admissionNoController.text.trim().isEmpty ||
            _dateOfBirthController.text.trim().isEmpty)) {
      Get.snackbar(
        'Validation',
        'Please enter admission number and date of birth',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final email = _emailController.text.trim();
    final displayName = roleLower == 'student'
        ? ''
        : _nameController.text.trim();
    final phone = _phoneString;
    final selectedClass = roleLower == 'teacher' ? _selectedClass : null;
    final selectedSection = roleLower == 'teacher' ? _selectedSection : null;
    const String? programName = null;
    const String? rollNumber = null;
    final subject = roleLower == 'teacher'
        ? _teacherSubjectController.text.trim()
        : null;
    final admissionNo = roleLower == 'student'
        ? _admissionNoController.text.trim()
        : null;
    final dateOfBirth = roleLower == 'student'
        ? _dateOfBirthController.text.trim()
        : null;

    final ok = await _authProvider.signUp(
      email: email,
      password: _passwordController.text,
      name: displayName,
      role: role,
      phone: phone,
      rollNumber: rollNumber,
      className: selectedClass,
      section: selectedSection,
      subject: subject,
      programName: programName,
      imagePath: null,
      admissionNo: admissionNo,
      dateOfBirth: dateOfBirth,
    );

    if (!ok) {
      Get.snackbar(
        'Signup failed',
        _authProvider.errorMessage.value.isEmpty
            ? 'Unable to create account. Please try again.'
            : _authProvider.errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final currentUid =
        _authProvider.currentUser.value?.uid ??
        _authProvider.firebaseService.currentUser?.uid;
    if (currentUid != null && currentUid.isNotEmpty) {
      _appThemeProvider.setCurrentRole(role);
    } else {
      _appThemeProvider.setCurrentRole(role);
    }

    Get.offAllNamed(
      AppRoutes.otp,
      arguments: {'email': email, 'mode': 'signup', 'role': role},
    );
  }

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _admissionNoController.dispose();
    _dateOfBirthController.dispose();
    _programController.dispose();
    _rollNumberController.dispose();
    _teacherSubjectController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  bool _agreedToTerms = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final roleLower = role.toLowerCase();

    if (roleLower == 'student') {
      return Scaffold(
        backgroundColor: palette.scaffold,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: palette.softCard,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.admin_panel_settings_outlined,
                          color: palette.primary,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Student Signup Disabled',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: palette.text,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Ab student account principal admission form se banta hai. Principal aap ko generated User ID aur password dega. Aap seedha login screen se sign in karein.',
                        style: TextStyle(
                          color: palette.subtext,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Get.offNamed(
                            AppRoutes.login,
                            arguments: {'role': 'Student'},
                          ),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Back to Student Login'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (roleLower == 'teacher') {
      return Scaffold(
        backgroundColor: palette.scaffold,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: palette.softCard,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.badge_outlined,
                          color: palette.primary,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Teacher Signup Disabled',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: palette.text,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Ab teacher account principal create kare ga. Principal teacher ka form fill kare ga aur generated user ID ya email aur password provide kare ga.',
                        style: TextStyle(
                          color: palette.subtext,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Get.offNamed(
                            AppRoutes.login,
                            arguments: {'role': 'Teacher'},
                          ),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Back to Teacher Login'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (roleLower == 'principal') {
      return Scaffold(
        backgroundColor: palette.scaffold,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: palette.softCard,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.verified_user_outlined,
                          color: palette.primary,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Principal Signup Disabled',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: palette.text,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Production security ke liye principal self-signup band kar di gayi hai. Principal portal mein sirf existing approved principal account login kare ga.',
                        style: TextStyle(
                          color: palette.subtext,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Agar principal login abhi tak setup nahi hua to Firebase Auth aur Firestore mein principal account ek dafa manually create karna hoga.',
                        style: TextStyle(
                          color: palette.subtext,
                          fontSize: 13,
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Get.offNamed(
                            AppRoutes.login,
                            arguments: {'role': 'Principal'},
                          ),
                          icon: const Icon(Icons.lock_open_outlined),
                          label: const Text('Back to Principal Login'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: palette.scaffold,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: palette.text,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Join School App and get started',
                          style: TextStyle(
                            color: palette.subtext,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  if (role.toLowerCase() != 'student') ...[
                    _FieldLabel('Display Name'),
                    const SizedBox(height: 6),
                    _IconField(
                      controller: _nameController,
                      hint: 'Enter your full name',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 14),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: palette.softCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: palette.border),
                      ),
                      child: Text(
                        'Student account signup principal ke banaye hue admission record se link hoga. Name, class, section aur roll number isi master record se auto-fill honge.',
                        style: TextStyle(color: palette.text, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Email
                  _FieldLabel('Email Address'),
                  const SizedBox(height: 6),
                  _IconField(
                    controller: _emailController,
                    hint: 'Enter your email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),

                  // Student fields
                  if (role.toLowerCase() == 'student') ...[
                    _FieldLabel('Admission Number'),
                    const SizedBox(height: 6),
                    _IconField(
                      controller: _admissionNoController,
                      hint: 'Enter admission number assigned by principal',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 14),
                    _FieldLabel('Date of Birth'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _dateOfBirthController,
                      readOnly: true,
                      onTap: _pickDateOfBirth,
                      decoration: InputDecoration(
                        hintText: 'Select date of birth',
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                        filled: true,
                        fillColor: palette.surfaceAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: palette.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: palette.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Teacher fields
                  if (role.toLowerCase() == 'teacher') ...[
                    _FieldLabel('Class'),
                    const SizedBox(height: 6),
                    _DropdownField(
                      label: 'Class',
                      value: _selectedClass,
                      items: _classes,
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedClass = v);
                      },
                    ),
                    const SizedBox(height: 14),
                    _FieldLabel('Section'),
                    const SizedBox(height: 6),
                    _DropdownField(
                      label: 'Section',
                      value: _selectedSection,
                      items: _sections,
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedSection = v);
                      },
                    ),
                    const SizedBox(height: 14),
                    _FieldLabel('Subject'),
                    const SizedBox(height: 6),
                    _IconField(
                      controller: _teacherSubjectController,
                      hint: 'Enter your subject',
                      icon: Icons.menu_book_outlined,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Phone
                  _FieldLabel('Phone Number'),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: palette.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: palette.border),
                    ),
                    child: InternationalPhoneNumberInput(
                      onInputChanged: (PhoneNumber number) {
                        setState(() {
                          _phoneNumber = number;
                          _phoneString = number.phoneNumber ?? '';
                        });
                      },
                      onInputValidated: (bool value) {},
                      selectorConfig: const SelectorConfig(
                        selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                        showFlags: true,
                        setSelectorButtonAsPrefixIcon: true,
                        leadingPadding: 12,
                        trailingSpace: false,
                      ),
                      ignoreBlank: false,
                      autoValidateMode: AutovalidateMode.onUserInteraction,
                      initialValue: _phoneNumber,
                      formatInput: true,
                      autoFocusSearch: true,
                      searchBoxDecoration: InputDecoration(
                        hintText: 'Search country',
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      selectorTextStyle: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      inputDecoration: InputDecoration(
                        hintText: 'Phone number',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 18,
                        ),
                        border: InputBorder.none,
                      ),
                      textFieldController: null,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: false,
                        decimal: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Password
                  _FieldLabel('Password'),
                  const SizedBox(height: 6),
                  _IconField(
                    controller: _passwordController,
                    hint: 'Enter your password',
                    icon: Icons.lock_outline,
                    obscure: true,
                    focusNode: _passwordFocusNode,
                    onChanged: _checkPassword,
                  ),
                  if (_showPasswordHints) ...[
                    const SizedBox(height: 8),
                    _criteriaRow('Minimum 8 characters', _minLength),
                    _criteriaRow('Uppercase letter', _hasUpper),
                    _criteriaRow('Lowercase letter', _hasLower),
                    _criteriaRow('Number', _hasDigit),
                    _criteriaRow('Special character', _hasSpecial),
                  ],
                  const SizedBox(height: 14),

                  // Confirm Password
                  _FieldLabel('Confirm Password'),
                  const SizedBox(height: 6),
                  _IconField(
                    controller: _confirmController,
                    hint: 'Confirm your password',
                    icon: Icons.lock_outline,
                    obscure: true,
                    errorText: _isConfirmPasswordMismatch
                        ? 'Passwords do not match'
                        : null,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),

                  // Terms checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _agreedToTerms,
                          onChanged: (v) =>
                              setState(() => _agreedToTerms = v ?? false),
                          activeColor: palette.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Wrap(
                          children: [
                            Text(
                              'I agree to the ',
                              style: TextStyle(
                                color: palette.subtext,
                                fontSize: 13,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: Text(
                                'Terms of Service',
                                style: TextStyle(
                                  color: palette.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              ' and ',
                              style: TextStyle(
                                color: palette.subtext,
                                fontSize: 13,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: Text(
                                'Privacy Policy',
                                style: TextStyle(
                                  color: palette.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sign Up button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Obx(
                      () => ElevatedButton(
                        onPressed:
                            (_authProvider.isLoading.value || !_agreedToTerms)
                            ? null
                            : _onSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _agreedToTerms
                              ? palette.primary
                              : palette.border,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _authProvider.isLoading.value
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(color: palette.subtext),
                        ),
                        GestureDetector(
                          onTap: () =>
                              Get.toNamed(AppRoutes.login, arguments: role),
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              color: palette.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
      ),
    );
  }
}

class _IconField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final String? errorText;

  const _IconField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.focusNode,
    this.errorText,
  });

  @override
  State<_IconField> createState() => _IconFieldState();
}

class _IconFieldState extends State<_IconField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: palette.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.errorText != null ? Colors.red : palette.border,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            obscureText: _isObscured,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(color: palette.subtext),
              prefixIcon: Icon(widget.icon, color: palette.subtext, size: 20),
              suffixIcon: widget.obscure
                  ? IconButton(
                      onPressed: () =>
                          setState(() => _isObscured = !_isObscured),
                      icon: Icon(
                        _isObscured
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: palette.subtext,
                        size: 20,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: palette.subtext),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
