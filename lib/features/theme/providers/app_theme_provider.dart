import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeProvider extends GetxController {
  static const _currentRoleKey = 'current_role';
  static const _currentUserIdKey = 'current_user_id';
  static const _activeModeKey = 'theme_mode_active';
  static const _activeNotificationsKey = 'notifications_active';
  static const _studentModeKey = 'theme_mode_student';
  static const _teacherModeKey = 'theme_mode_teacher';
  static const _principalModeKey = 'theme_mode_principal';

  final RxString currentRole = 'student'.obs;
  final RxString currentUserId = ''.obs;
  final Rx<ThemeMode> currentMode = ThemeMode.light.obs;
  final RxBool notificationsEnabled = true.obs;
  final RxMap<String, ThemeMode> _themeModes = <String, ThemeMode>{
    'student': ThemeMode.light,
    'teacher': ThemeMode.light,
    'principal': ThemeMode.light,
  }.obs;
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    currentRole.value = _prefs.getString(_currentRoleKey) ?? 'student';
    currentUserId.value = _prefs.getString(_currentUserIdKey) ?? '';
    _themeModes['student'] = _decodeMode(_prefs.getString(_studentModeKey));
    _themeModes['teacher'] = _decodeMode(_prefs.getString(_teacherModeKey));
    _themeModes['principal'] = _decodeMode(
      _prefs.getString(_principalModeKey),
    );
    currentMode.value = _decodeMode(_prefs.getString(_activeModeKey));
    notificationsEnabled.value =
        _prefs.getBool(_activeNotificationsKey) ?? true;
  }

  ThemeMode modeFor(String role) {
    return _themeModes[role.toLowerCase()] ?? ThemeMode.light;
  }

  void setCurrentRole(String role) {
    currentRole.value = role.toLowerCase();
    _themeModes.putIfAbsent(currentRole.value, () => ThemeMode.light);
    _prefs.setString(_currentRoleKey, currentRole.value);
  }

  void setCurrentSession({
    required String role,
    required String userId,
  }) {
    final normalizedRole = role.toLowerCase();
    currentRole.value = normalizedRole;
    currentUserId.value = userId;
    _themeModes.putIfAbsent(normalizedRole, () => ThemeMode.light);
    _prefs.setString(_currentRoleKey, normalizedRole);
    _prefs.setString(_currentUserIdKey, userId);
    currentMode.value = modeForUser(userId, fallbackRole: normalizedRole);
    notificationsEnabled.value = notificationsEnabledForUser(userId);
    _prefs.setString(_activeModeKey, currentMode.value.name);
    _prefs.setBool(_activeNotificationsKey, notificationsEnabled.value);
  }

  void setModeForRole(String role, ThemeMode mode) {
    final roleKey = role.toLowerCase();
    _themeModes[roleKey] = mode;
    _prefs.setString(_modeKeyFor(roleKey), mode.name);
    currentMode.value = mode;
    _prefs.setString(_activeModeKey, mode.name);
  }

  void setModeForCurrentUser(ThemeMode mode) {
    final userId = currentUserId.value;
    if (userId.isEmpty) {
      setModeForRole(currentRole.value, mode);
      return;
    }
    currentMode.value = mode;
    _prefs.setString(_modeKeyForUser(userId), mode.name);
    _prefs.setString(_activeModeKey, mode.name);
  }

  bool isDarkModeFor(String role) {
    return modeFor(role) == ThemeMode.dark;
  }

  bool get isDarkModeForCurrentUser => currentMode.value == ThemeMode.dark;

  bool notificationsEnabledForUser(String userId) {
    return _prefs.getBool(_notificationsKeyForUser(userId)) ?? true;
  }

  void setNotificationsForCurrentUser(bool enabled) {
    final userId = currentUserId.value;
    notificationsEnabled.value = enabled;
    _prefs.setBool(_activeNotificationsKey, enabled);
    if (userId.isNotEmpty) {
      _prefs.setBool(_notificationsKeyForUser(userId), enabled);
    }
  }

  ThemeMode modeForUser(String userId, {String? fallbackRole}) {
    final userMode = _prefs.getString(_modeKeyForUser(userId));
    if (userMode != null) {
      return _decodeMode(userMode);
    }
    if (fallbackRole != null) {
      return modeFor(fallbackRole);
    }
    return ThemeMode.light;
  }

  String _modeKeyFor(String role) {
    switch (role) {
      case 'teacher':
        return _teacherModeKey;
      case 'principal':
        return _principalModeKey;
      case 'student':
      default:
        return _studentModeKey;
    }
  }

  String _modeKeyForUser(String userId) => 'theme_mode_user_$userId';

  String _notificationsKeyForUser(String userId) =>
      'notifications_user_$userId';

  ThemeMode _decodeMode(String? value) {
    return value == ThemeMode.dark.name ? ThemeMode.dark : ThemeMode.light;
  }
}
