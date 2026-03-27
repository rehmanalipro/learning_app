class ApiResult<T> {
  final bool success;
  final T? data;
  final String? message;

  ApiResult({required this.success, this.data, this.message});

  factory ApiResult.success(T data) => ApiResult(success: true, data: data);

  factory ApiResult.failure(String message) =>
      ApiResult(success: false, message: message);
}
