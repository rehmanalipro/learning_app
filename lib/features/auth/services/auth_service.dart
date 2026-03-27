import '../../auth/models/user_model.dart';

class AuthService {
  Future<UserModel> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    return UserModel(id: '1', name: 'Demo User', email: email);
  }

  Future<UserModel> register(String name, String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    return UserModel(id: '1', name: name, email: email);
  }
}
