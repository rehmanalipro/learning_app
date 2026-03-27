import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import '../routes/app_pages.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  String get role => (Get.arguments as String?) ?? 'Student';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'PK', dialCode: '+92');
  String _phoneString = '';
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

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

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _choosePhotoSource() {
    Get.bottomSheet(
      Container(
        color: Colors.white,
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFF1E88E5),
              ),
              title: const Text('Gallery'),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF1E88E5)),
              title: const Text('Camera'),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
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

  void _onSignup() {
    if (_nameController.text.isEmpty ||
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

    Get.toNamed(AppRoutes.otp, arguments: role);
  }

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() {
      setState(() {});
    });
  }

  void _useSamePassword() {
    setState(() {
      _confirmController.text = _passwordController.text;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned(
            left: -width * 0.35,
            top: -210,
            child: Container(
              width: width * 1.7,
              height: 280,
              decoration: const BoxDecoration(
                color: Color(0xFF00BFA5),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(260),
                  bottomLeft: Radius.circular(260),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _choosePhotoSource,
                      child: Container(
                        width: 118,
                        height: 118,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFF00BFA5),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: _selectedImage == null
                            ? const Center(
                                child: Icon(
                                  Icons.add_a_photo,
                                  size: 34,
                                  color: Color(0xFF1E88E5),
                                ),
                              )
                            : ClipOval(
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '$role Sign Up',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E88E5),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Create your account with your details',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: AnimatedPadding(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      padding: EdgeInsets.only(bottom: keyboardInset),
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: Column(
                          children: [
                            _TextField(
                              controller: _nameController,
                              label: 'Full Name',
                            ),
                            const SizedBox(height: 12),
                            _TextField(
                              controller: _emailController,
                              label: 'Email',
                              keyboard: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: InternationalPhoneNumberInput(
                                onInputChanged: (PhoneNumber number) {
                                  setState(() {
                                    _phoneNumber = number;
                                    _phoneString = number.phoneNumber ?? '';
                                  });
                                },
                                onInputValidated: (bool value) {},
                                selectorConfig: const SelectorConfig(
                                  selectorType:
                                      PhoneInputSelectorType.BOTTOM_SHEET,
                                  showFlags: true,
                                  setSelectorButtonAsPrefixIcon: true,
                                  leadingPadding: 12,
                                  trailingSpace: false,
                                ),
                                ignoreBlank: false,
                                autoValidateMode:
                                    AutovalidateMode.onUserInteraction,
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
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                selectorTextStyle: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                                inputDecoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 18,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                textFieldController: null,
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      signed: false,
                                      decimal: false,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _TextField(
                              controller: _passwordController,
                              label: 'Password',
                              obscure: true,
                              focusNode: _passwordFocusNode,
                              onChanged: _checkPassword,
                            ),
                            if (_showPasswordHints) ...[
                              const SizedBox(height: 6),
                              _criteriaRow('Minimum 8 characters', _minLength),
                              _criteriaRow('Uppercase letter', _hasUpper),
                              _criteriaRow('Lowercase letter', _hasLower),
                              _criteriaRow('Number', _hasDigit),
                              _criteriaRow('Special character', _hasSpecial),
                            ],
                            const SizedBox(height: 12),
                            _TextField(
                              controller: _confirmController,
                              label: 'Confirm Password',
                              obscure: true,
                              errorText: _isConfirmPasswordMismatch
                                  ? 'Password must be same as above'
                                  : null,
                              onChanged: (_) => setState(() {}),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _passwordController.text.isEmpty
                                    ? null
                                    : _useSamePassword,
                                child: const Text('Same as above'),
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _onSignup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E88E5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Sign Up',

                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Already have an account? '),
                                GestureDetector(
                                  onTap: () => Get.toNamed(
                                    AppRoutes.login,
                                    arguments: role,
                                  ),
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                      color: Color(0xFF1E88E5),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType keyboard;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final String? errorText;

  const _TextField({
    required this.controller,
    required this.label,
    this.obscure = false,
    this.keyboard = TextInputType.text,
    this.onChanged,
    this.focusNode,
    this.errorText,
  });

  @override
  State<_TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<_TextField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: _isObscured,
      keyboardType: widget.keyboard,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        suffixIcon: widget.obscure
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _isObscured = !_isObscured;
                  });
                },
                icon: Icon(
                  _isObscured ? Icons.visibility_off : Icons.visibility,
                ),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
