import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeProvider extends GetxController {
  static const _currentRoleKey = 'current_role';
  static const _studentModeKey = 'theme_mode_student';
  static const _teacherModeKey = 'theme_mode_teacher';
  static const _principalModeKey = 'theme_mode_principal';

  final RxString currentRole = 'student'.obs;
  final RxMap<String, ThemeMode> _themeModes = <String, ThemeMode>{
    'student': ThemeMode.light,
    'teacher': ThemeMode.light,
    'principal': ThemeMode.light,
  }.obs;
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    currentRole.value = _prefs.getString(_currentRoleKey) ?? 'student';
    _themeModes['student'] = _decodeMode(_prefs.getString(_studentModeKey));
    _themeModes['teacher'] = _decodeMode(_prefs.getString(_teacherModeKey));
    _themeModes['principal'] = _decodeMode(
      _prefs.getString(_principalModeKey),
    );
  }

  ThemeMode modeFor(String role) {
    return _themeModes[role.toLowerCase()] ?? ThemeMode.light;
  }

  void setCurrentRole(String role) {
    currentRole.value = role.toLowerCase();
    _themeModes.putIfAbsent(currentRole.value, () => ThemeMode.light);
    _prefs.setString(_currentRoleKey, currentRole.value);
  }

  void setModeForRole(String role, ThemeMode mode) {
    final roleKey = role.toLowerCase();
    _themeModes[roleKey] = mode;
    _prefs.setString(_modeKeyFor(roleKey), mode.name);
    if (currentRole.value == roleKey) {
      currentRole.refresh();
    }
  }

  bool isDarkModeFor(String role) {
    return modeFor(role) == ThemeMode.dark;
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

  ThemeMode _decodeMode(String? value) {
    return value == ThemeMode.dark.name ? ThemeMode.dark : ThemeMode.light;
  }
}
