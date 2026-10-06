class ApiResponse<T> {
  const ApiResponse({required this.data, this.message});

  final T data;
  final String? message;

  static ApiResponse<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Object? json) fromData,
  ) {
    return ApiResponse<T>(
      data: fromData(json['data']),
      message: json['message'] as String?,
    );
  }
}
