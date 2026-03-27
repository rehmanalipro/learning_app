import 'dart:convert';

import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_result.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  Future<ApiResult> post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final json = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResult.success(json);
      }
      return ApiResult.failure(json['message'] ?? 'Server error');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }
}
