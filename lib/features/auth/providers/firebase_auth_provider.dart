import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/fcm_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/otp_service.dart';
import '../../admission/services/student_profile_service.dart';
import '../../admission/models/student_profile_model.dart';
import '../../teacher/models/teacher_profile_model.dart';
import '../../teacher/services/teacher_profile_service.dart';

class GeneratedStudentCredentials {
  final String userId;
  final String password;
  final String email;

  const GeneratedStudentCredentials({
    required this.userId,
    required this.password,
    required this.email,
  });
}

class GeneratedTeacherCredentials {
  final String userId;
  final String password;
  final String email;

  const GeneratedTeacherCredentials({
    required this.userId,
    required this.password,
    required this.email,
  });
}

class FirebaseAuthProvider extends GetxController {
  late final FirebaseService _firebaseService;
  late final StudentProfileService _studentProfileService;
  late final TeacherProfileService _teacherProfileService;

  FirebaseService get firebaseService => _firebaseService;

  final Rx<User?> currentUser = Rx<User?>(null);
  final RxBool isLoading = RxBool(false);
  final RxString errorMessage = RxString('');

  Map<String, dynamic>? _cachedCurrentUserData;
  String? _cachedCurrentUserUid;

  @override
  void onInit() {
    super.onInit();
    _firebaseService = FirebaseService();
    _firebaseService.initialize();
    _studentProfileService = Get.find<StudentProfileService>();
    _teacherProfileService = Get.find<TeacherProfileService>();
    try {
      currentUser.bindStream(_firebaseService.auth.authStateChanges());
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
    String? rollNumber,
    String? className,
    String? section,
    String? subject,
    String? programName,
    String? imagePath,
    String? admissionNo,
    String? dateOfBirth,
  }) async {
    UserCredential? userCredential;
    try {
      isLoading(true);
      errorMessage('');

      final roleLower = role.toLowerCase();
      if (roleLower == 'principal' || roleLower == 'teacher') {
        errorMessage.value = roleLower == 'principal'
            ? 'Principal self-signup disabled hai. Sirf existing principal login kar sakta hai.'
            : 'Teacher self-signup disabled hai. Teacher account principal create kare ga.';
        return false;
      }
      var resolvedName = name.trim();
      var resolvedPhone = phone?.trim();
      var resolvedRollNumber = rollNumber?.trim();
      var resolvedClassName = className?.trim();
      var resolvedSection = section?.trim();
      var resolvedProgramName = programName?.trim();
      var resolvedAdmissionNo = admissionNo?.trim();
      var resolvedDateOfBirth = dateOfBirth?.trim();
      String? linkedStudentProfileId;

      if (roleLower == 'student') {
        if ((resolvedAdmissionNo ?? '').isEmpty ||
            (resolvedDateOfBirth ?? '').isEmpty) {
          errorMessage.value =
              'Admission number and date of birth are required.';
          return false;
        }

        final matchedProfile = await _studentProfileService
            .findForAdmissionLink(
              admissionNo: resolvedAdmissionNo!,
              dateOfBirth: resolvedDateOfBirth!,
            );

        if (matchedProfile == null) {
          errorMessage.value =
              'Admission record not found. Please contact the principal.';
          return false;
        }

        if (matchedProfile.status.toLowerCase() != 'active') {
          errorMessage.value =
              'This admission record is inactive. Please contact the principal.';
          return false;
        }

        if (matchedProfile.linkedUserUid.trim().isNotEmpty) {
          errorMessage.value =
              'This admission record is already linked to another account.';
          return false;
        }

        linkedStudentProfileId = matchedProfile.id;
        resolvedName = matchedProfile.fullName;
        resolvedPhone = matchedProfile.phone.trim().isEmpty
            ? resolvedPhone
            : matchedProfile.phone.trim();
        resolvedRollNumber = matchedProfile.rollNumber.trim();
        resolvedClassName = matchedProfile.className.trim();
        resolvedSection = matchedProfile.section.trim();
        resolvedProgramName = matchedProfile.programName.trim();
        resolvedAdmissionNo = matchedProfile.admissionNo.trim();
        resolvedDateOfBirth = matchedProfile.dateOfBirth.trim();
      }

      userCredential = await _firebaseService.signUpWithEmail(email, password);

      if (userCredential != null) {
        // Save user data to Firestore
        await _firebaseService.createUser(userCredential.user!.uid, {
          'uid': userCredential.user!.uid,
          'authUid': userCredential.user!.uid,
          'email': email,
          'name': resolvedName,
          'role': role,
          'phone': resolvedPhone,
          'rollNumber': resolvedRollNumber,
          'className': resolvedClassName,
          'section': resolvedSection,
          'subject': subject,
          'programName': resolvedProgramName,
          'admissionNo': resolvedAdmissionNo,
          'dateOfBirth': resolvedDateOfBirth,
          'linkedStudentProfileId': linkedStudentProfileId,
          'imagePath': imagePath,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        if (linkedStudentProfileId != null &&
            linkedStudentProfileId.isNotEmpty) {
          await _studentProfileService.linkStudentAccount(
            profileId: linkedStudentProfileId,
            uid: userCredential.user!.uid,
            email: email,
            generatedUserId: '',
            issuedAt: DateTime.now().toIso8601String(),
          );
        }
        currentUser.value = userCredential.user;
        _cacheCurrentUserData({
          'uid': userCredential.user!.uid,
          'authUid': userCredential.user!.uid,
          'email': email,
          'name': resolvedName,
          'role': role,
          'phone': resolvedPhone,
          'rollNumber': resolvedRollNumber,
          'className': resolvedClassName,
          'section': resolvedSection,
          'subject': subject,
          'programName': resolvedProgramName,
          'admissionNo': resolvedAdmissionNo,
          'dateOfBirth': resolvedDateOfBirth,
          'linkedStudentProfileId': linkedStudentProfileId,
          'imagePath': imagePath,
        }, uid: userCredential.user!.uid);
        return true;
      }
      return false;
    } catch (e) {
      final createdUser = userCredential?.user;
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {
          try {
            await _firebaseService.signOut();
          } catch (_) {}
        }
      }
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
    String? roleHint,
  }) async {
    try {
      isLoading(true);
      errorMessage('');

      final resolvedEmail = await resolveLoginIdentifier(
        email,
        roleHint: roleHint,
      );

      final userCredential = await _firebaseService.signInWithEmail(
        resolvedEmail,
        password,
      );

      if (userCredential != null) {
        final normalizedRole = (roleHint ?? '').trim().toLowerCase();
        if (normalizedRole == 'principal') {
          final isTrustedPrincipal = await _firebaseService
              .isTrustedPrincipalUid(userCredential.user!.uid);
          if (!isTrustedPrincipal) {
            await _firebaseService.signOut();
            currentUser.value = null;
            errorMessage.value =
                'Only the authorized principal account can access this portal.';
            return false;
          }
        }
        if (normalizedRole == 'teacher') {
          final collection = await _firebaseService.findUserCollection(
            userCredential.user!.uid,
            roleHint: 'Teacher',
          );
          if (collection != _firebaseService.collectionForRole('Teacher')) {
            await _firebaseService.signOut();
            currentUser.value = null;
            errorMessage.value =
                'Only principal-issued teacher accounts can access this portal.';
            return false;
          }
        }
        currentUser.value = userCredential.user;
        await loadCurrentUserData(roleHint: roleHint, forceRefresh: true);
        return true;
      }
      return false;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading(false);
    }
  }

  Map<String, dynamic>? peekCurrentUserData({String? roleHint}) {
    final user = currentUser.value ?? _firebaseService.currentUser;
    if (user == null) return null;
    if (_cachedCurrentUserUid != user.uid || _cachedCurrentUserData == null) {
      return null;
    }

    final cached = Map<String, dynamic>.from(_cachedCurrentUserData!);
    final normalizedRoleHint = (roleHint ?? '').trim().toLowerCase();
    final cachedRole = (cached['role'] as String? ?? '').trim().toLowerCase();
    if (normalizedRoleHint.isNotEmpty &&
        cachedRole.isNotEmpty &&
        cachedRole != normalizedRoleHint) {
      return null;
    }
    return cached;
  }

  Future<Map<String, dynamic>?> loadCurrentUserData({
    String? roleHint,
    bool forceRefresh = false,
  }) async {
    final user = currentUser.value ?? _firebaseService.currentUser;
    if (user == null) {
      _clearCurrentUserDataCache();
      return null;
    }

    if (!forceRefresh) {
      final cached = peekCurrentUserData(roleHint: roleHint);
      if (cached != null) return cached;
    }

    final userData = await _firebaseService.getUserData(
      user.uid,
      roleHint: roleHint,
    );
    if (userData == null) return null;

    final role = (userData['role'] as String? ?? '').trim().toLowerCase();
    final collection = await _firebaseService.findUserCollection(
      user.uid,
      roleHint: roleHint,
    );
    if (role == 'principal' &&
        collection != _firebaseService.collectionForRole('Principal')) {
      _clearCurrentUserDataCache();
      return null;
    }
    if (role == 'teacher' &&
        collection != _firebaseService.collectionForRole('Teacher')) {
      _clearCurrentUserDataCache();
      return null;
    }
    _cacheCurrentUserData(userData, uid: user.uid);
    return userData;
  }

  Future<void> signOut({
    String? role,
    String? className,
    String? section,
  }) async {
    try {
      // FCM topics se unsubscribe karo logout se pehle
      if (role != null) {
        try {
          await Get.find<FcmService>().unsubscribeAll(
            role: role,
            className: className,
            section: section,
          );
        } catch (_) {}
      }
      await _firebaseService.signOut();
      currentUser.value = null;
      errorMessage('');
      _clearCurrentUserDataCache();
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }

  Future<bool> resetPassword(String email, {String? roleHint}) async {
    try {
      isLoading(true);
      errorMessage('');
      final resolvedEmail = await resolveLoginIdentifier(
        email,
        roleHint: roleHint,
      );
      await _firebaseService.sendPasswordResetEmail(resolvedEmail);
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading(false);
    }
  }

  bool get isAuthenticated => currentUser.value != null;

  void _cacheCurrentUserData(Map<String, dynamic>? userData, {String? uid}) {
    final resolvedUid =
        uid ?? currentUser.value?.uid ?? _firebaseService.currentUser?.uid;
    if (resolvedUid == null || userData == null) {
      _clearCurrentUserDataCache();
      return;
    }
    _cachedCurrentUserUid = resolvedUid;
    _cachedCurrentUserData = Map<String, dynamic>.from(userData);
  }

  void _clearCurrentUserDataCache() {
    _cachedCurrentUserUid = null;
    _cachedCurrentUserData = null;
  }

  Future<String> resolveLoginIdentifier(
    String identifier, {
    String? roleHint,
  }) async {
    final normalized = identifier.trim();
    if (normalized.isEmpty) {
      throw 'User ID or email is required.';
    }
    final normalizedRole = (roleHint ?? '').trim().toLowerCase();
    if (normalizedRole == 'principal') {
      if (!normalized.contains('@')) {
        throw 'Principal login ke liye real email address use karein.';
      }
      return normalized.toLowerCase();
    }
    if (normalized.contains('@')) {
      return normalized;
    }

    final snapshot = await _firebaseService.firestore
        .collection('login_directory')
        .doc(normalized.toLowerCase())
        .get();

    if (!snapshot.exists || snapshot.data() == null) {
      throw 'No account found for this user ID.';
    }

    final mappedEmail = snapshot.data()!['email'] as String? ?? '';
    if (mappedEmail.trim().isEmpty) {
      throw 'This account does not have a valid email.';
    }
    return mappedEmail.trim();
  }

  Future<GeneratedStudentCredentials> provisionStudentAccount({
    required StudentProfileModel profile,
  }) async {
    final studentEmail = profile.studentEmail.trim().toLowerCase();
    if (studentEmail.isEmpty) {
      throw 'Student email is required before creating login credentials.';
    }
    if (profile.linkedUserUid.trim().isNotEmpty) {
      throw 'This student already has a linked account.';
    }

    final generatedUserId = await _generateUniqueStudentUserId(profile);
    final generatedPassword = _generateStrongPassword();

    final userCredential = await _firebaseService.signUpWithEmailAsManagedUser(
      studentEmail,
      generatedPassword,
    );
    final createdUser = userCredential?.user;
    if (createdUser == null) {
      throw 'Student account could not be created.';
    }

    final now = DateTime.now().toIso8601String();
    await _firebaseService.createUser(createdUser.uid, {
      'uid': createdUser.uid,
      'authUid': createdUser.uid,
      'email': studentEmail,
      'userId': generatedUserId,
      'userIdSearchKey': generatedUserId.toLowerCase(),
      'consoleLabel':
          '${profile.fullName} | Roll ${profile.rollNumber} | $generatedUserId',
      'name': profile.fullName,
      'role': 'Student',
      'gender': profile.gender,
      'phone': profile.phone,
      'rollNumber': profile.rollNumber,
      'className': profile.className,
      'section': profile.section,
      'programName': profile.programName,
      'admissionNo': profile.admissionNo,
      'dateOfBirth': profile.dateOfBirth,
      'studentProfileId': profile.id,
      'linkedStudentProfileId': profile.id,
      'status': profile.status,
      'imagePath': '',
      'createdAt': now,
      'updatedAt': now,
    }, documentId: generatedUserId);

    await _firebaseService.firestore
        .collection('login_directory')
        .doc(generatedUserId.toLowerCase())
        .set({
          'email': studentEmail,
          'userId': generatedUserId,
          'uid': createdUser.uid,
          'accountDocId': generatedUserId,
          'displayLabel':
              '${profile.fullName} | Roll ${profile.rollNumber} | $generatedUserId',
          'role': 'Student',
          'createdAt': now,
          'updatedAt': now,
        });

    await _studentProfileService.linkStudentAccount(
      profileId: profile.id,
      uid: createdUser.uid,
      email: studentEmail,
      generatedUserId: generatedUserId,
      issuedAt: now,
    );

    return GeneratedStudentCredentials(
      userId: generatedUserId,
      password: generatedPassword,
      email: studentEmail,
    );
  }

  Future<GeneratedTeacherCredentials> provisionTeacherAccount({
    required TeacherProfileModel profile,
  }) async {
    final teacherEmail = profile.teacherEmail.trim().toLowerCase();
    if (teacherEmail.isEmpty) {
      throw 'Teacher email is required before creating login credentials.';
    }
    if (profile.linkedUserUid.trim().isNotEmpty) {
      throw 'This teacher already has a linked account.';
    }

    final generatedUserId = await _generateUniqueTeacherUserId(profile);
    final generatedPassword = _generateStrongPassword();

    final userCredential = await _firebaseService.signUpWithEmailAsManagedUser(
      teacherEmail,
      generatedPassword,
    );
    final createdUser = userCredential?.user;
    if (createdUser == null) {
      throw 'Teacher account could not be created.';
    }

    final now = DateTime.now().toIso8601String();
    await _firebaseService.createUser(createdUser.uid, {
      'uid': createdUser.uid,
      'authUid': createdUser.uid,
      'email': teacherEmail,
      'userId': generatedUserId,
      'userIdSearchKey': generatedUserId.toLowerCase(),
      'consoleLabel':
          '${profile.fullName} | ${profile.employeeId} | $generatedUserId',
      'name': profile.fullName,
      'role': 'Teacher',
      'phone': profile.phone,
      'className': profile.className,
      'section': profile.section,
      'subject': profile.subject,
      'department': profile.department,
      'employeeId': profile.employeeId,
      'teacherProfileId': profile.id,
      'linkedTeacherProfileId': profile.id,
      'status': profile.status,
      'isClassTeacher': profile.isClassTeacher,
      'imagePath': '',
      'createdAt': now,
      'updatedAt': now,
    }, documentId: generatedUserId);

    await _firebaseService.firestore
        .collection('login_directory')
        .doc(generatedUserId.toLowerCase())
        .set({
          'email': teacherEmail,
          'userId': generatedUserId,
          'uid': createdUser.uid,
          'accountDocId': generatedUserId,
          'displayLabel':
              '${profile.fullName} | ${profile.employeeId} | $generatedUserId',
          'role': 'Teacher',
          'createdAt': now,
          'updatedAt': now,
        });

    await _teacherProfileService.linkTeacherAccount(
      profileId: profile.id,
      uid: createdUser.uid,
      email: teacherEmail,
      generatedUserId: generatedUserId,
      issuedAt: now,
    );

    return GeneratedTeacherCredentials(
      userId: generatedUserId,
      password: generatedPassword,
      email: teacherEmail,
    );
  }

  Future<String> _generateUniqueStudentUserId(
    StudentProfileModel profile,
  ) async {
    final namePart = _slugPart(profile.fullName, maxLength: 8);
    final classPart =
        'c${profile.className.trim()}${profile.section.trim().toLowerCase()}';
    final programPart = _slugPart(profile.programName, maxLength: 4);
    final rollPart = _slugPart(profile.rollNumber, maxLength: 4);

    final baseParts = <String>[
      if (namePart.isNotEmpty) namePart,
      classPart,
      if (programPart.isNotEmpty) programPart,
      if (rollPart.isNotEmpty) rollPart,
    ];
    final base = baseParts.join('_').replaceAll(RegExp(r'_+'), '_');

    for (var suffix = 0; suffix < 500; suffix++) {
      final candidate = suffix == 0 ? base : '${base}_$suffix';
      final isFree = await _isStudentUserIdAvailable(candidate);
      if (isFree) return candidate;
    }
    throw 'Unable to generate a unique student user ID.';
  }

  Future<bool> _isStudentUserIdAvailable(String userId) async {
    final searchKey = userId.toLowerCase();

    final loginDirectory = await _firebaseService.firestore
        .collection('login_directory')
        .doc(searchKey)
        .get();
    if (loginDirectory.exists) return false;

    final studentsSnapshot = await _firebaseService.firestore
        .collection('students')
        .where('userIdSearchKey', isEqualTo: searchKey)
        .limit(1)
        .get();
    if (studentsSnapshot.docs.isNotEmpty) return false;

    final profilesSnapshot = await _firebaseService.firestore
        .collection('student_profiles')
        .where('generatedUserId', isEqualTo: userId)
        .limit(1)
        .get();
    return profilesSnapshot.docs.isEmpty;
  }

  Future<String> _generateUniqueTeacherUserId(
    TeacherProfileModel profile,
  ) async {
    final namePart = _slugPart(profile.fullName, maxLength: 8);
    final classPart =
        't${profile.className.trim()}${profile.section.trim().toLowerCase()}';
    final subjectPart = _slugPart(profile.subject, maxLength: 4);
    final employeePart = _slugPart(profile.employeeId, maxLength: 4);

    final baseParts = <String>[
      if (namePart.isNotEmpty) namePart,
      classPart,
      if (subjectPart.isNotEmpty) subjectPart,
      if (employeePart.isNotEmpty) employeePart,
    ];
    final base = baseParts.join('_').replaceAll(RegExp(r'_+'), '_');

    for (var suffix = 0; suffix < 500; suffix++) {
      final candidate = suffix == 0 ? base : '${base}_$suffix';
      final isFree = await _isTeacherUserIdAvailable(candidate);
      if (isFree) return candidate;
    }
    throw 'Unable to generate a unique teacher user ID.';
  }

  Future<bool> _isTeacherUserIdAvailable(String userId) async {
    final searchKey = userId.toLowerCase();

    final loginDirectory = await _firebaseService.firestore
        .collection('login_directory')
        .doc(searchKey)
        .get();
    if (loginDirectory.exists) return false;

    final teachersSnapshot = await _firebaseService.firestore
        .collection('teachers')
        .where('userIdSearchKey', isEqualTo: searchKey)
        .limit(1)
        .get();
    if (teachersSnapshot.docs.isNotEmpty) return false;

    final profilesSnapshot = await _firebaseService.firestore
        .collection('teacher_profiles')
        .where('generatedUserId', isEqualTo: userId)
        .limit(1)
        .get();
    return profilesSnapshot.docs.isEmpty;
  }

  String _slugPart(String value, {required int maxLength}) {
    final normalized = value.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '',
    );
    if (normalized.isEmpty) return '';
    return normalized.length <= maxLength
        ? normalized
        : normalized.substring(0, maxLength);
  }

  String _generateStrongPassword() {
    const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    const lower = 'abcdefghijkmnopqrstuvwxyz';
    const digits = '23456789';
    const special = '@#\$%&*!';
    const all = '$upper$lower$digits$special';

    final seed = DateTime.now().microsecondsSinceEpoch.toString();
    final chars = <String>[
      upper[seed.codeUnitAt(0) % upper.length],
      lower[seed.codeUnitAt(1) % lower.length],
      digits[seed.codeUnitAt(2) % digits.length],
      special[seed.codeUnitAt(3) % special.length],
    ];

    for (var i = 4; i < 12; i++) {
      chars.add(all[seed.codeUnitAt(i % seed.length) % all.length]);
    }

    return chars.reversed.join();
  }

  /// Generates OTP, saves to Firestore, returns the code.
  /// In production: wire to Firebase Email Extension to send the email.
  Future<String> sendEmailOtp({
    required String email,
    required String mode,
  }) async {
    final otpService = Get.find<OtpService>();
    return otpService.generateAndSaveOtp(email: email, mode: mode);
  }

  /// Verifies OTP entered by user.
  Future<bool> verifyEmailOtp({
    required String email,
    required String otp,
    required String mode,
  }) async {
    final otpService = Get.find<OtpService>();
    return otpService.verifyOtp(email: email, otp: otp, mode: mode);
  }

  /// Changes password for the currently logged-in user.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      isLoading(true);
      errorMessage('');
      final user = _firebaseService.currentUser;
      if (user == null || user.email == null) {
        errorMessage.value = 'No user is currently signed in.';
        return false;
      }
      // Re-authenticate first
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = e.message ?? 'Failed to change password.';
      return false;
    } catch (e) {
      errorMessage.value = 'Failed to change password.';
      return false;
    } finally {
      isLoading(false);
    }
  }
}
