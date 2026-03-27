import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends GetxController {
  final AuthService _authService = AuthService();
  Rxn<UserModel> user = Rxn<UserModel>();
  RxBool isLoading = false.obs;

  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      user.value = await _authService.login(email, password);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      isLoading.value = true;
      user.value = await _authService.register(name, email, password);
    } finally {
      isLoading.value = false;
    }
  }
}
