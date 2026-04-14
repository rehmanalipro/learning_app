import 'package:get/get.dart';

/// Single source of truth for a logged-in teacher's (or student's) class context.
///
/// Populated after login via [loadFromUserData] and cleared on logout via [clear].
class ClassBindingService extends GetxService {
  final RxString className = ''.obs;
  final RxString section = ''.obs;
  final RxString subject = ''.obs;

  /// Populates [className], [section], and [subject] from a Firestore user document.
  void loadFromUserData(Map<String, dynamic> userData) {
    className.value = (userData['className'] as String?) ?? '';
    section.value = (userData['section'] as String?) ?? '';
    subject.value = (userData['subject'] as String?) ?? '';
  }

  /// Resets all fields — call this on logout.
  void clear() {
    className.value = '';
    section.value = '';
    subject.value = '';
  }
}
