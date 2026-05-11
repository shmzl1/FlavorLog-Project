class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;
  final String? requestId;
  final String? timestamp;

  ApiResponse({
    required this.code,
    required this.message,
    this.data,
    this.requestId,
    this.timestamp,
  });

  bool get isSuccess => code == 0;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic raw)? fromData,
  ) {
    return ApiResponse<T>(
      code: json['code'] as int? ?? -1,
      message: json['message'] as String? ?? '',
      data: fromData == null ? json['data'] as T? : fromData(json['data']),
      requestId: json['request_id'] as String?,
      timestamp: json['timestamp'] as String?,
    );
  }
}