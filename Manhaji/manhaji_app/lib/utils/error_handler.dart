import 'package:dio/dio.dart';
import '../constants/strings.dart';
import '../services/api_service.dart';

/// Centralized error-to-Arabic-message conversion.
///
/// Previously every provider (auth, learning, report, teacher, admin) rolled
/// its own `_extractError` helper — some ignored `DioException` entirely.
/// Providers should call [extractError] and expose the result as their error
/// state, so users see a consistent and translated message regardless of which
/// screen they're on.
///
/// [ApiService] now throws [ApiException] with already-translated copy, so we
/// just pass it through. Legacy [DioException] paths (e.g. direct Dio usage
/// in refresh-token flow) still get mapped here.
String extractError(Object error) {
  if (error is ApiException) {
    return error.message;
  }
  if (error is DioException) {
    return _fromDio(error);
  }
  return AppStrings.errorGeneric;
}

String _fromDio(DioException e) {
  final data = e.response?.data;
  if (data is Map) {
    final message = data['message'];
    if (message is String && message.isNotEmpty) {
      return message;
    }
  }

  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return AppStrings.errorTimeout;
    case DioExceptionType.connectionError:
      return AppStrings.errorConnection;
    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
    case DioExceptionType.badResponse:
    case DioExceptionType.unknown:
      return AppStrings.errorGeneric;
  }
}
