import 'package:dio/dio.dart';

class ErrorHandler {
  static String formatDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Check backend server reachability.';
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        final detail = error.response?.data?['detail'] ?? error.response?.data?['message'];
        if (detail != null) return '$detail (HTTP $status)';

        if (status == 400) return 'Invalid request syntax or parameters (HTTP 400).';
        if (status == 401) return 'Session expired or invalid credentials (HTTP 401).';
        if (status == 403) return 'Access forbidden. Operator permission required (HTTP 403).';
        if (status == 404) return 'Requested endpoint or resource not found on server (HTTP 404).';
        if (status == 500) return 'Internal FastAPI server exception (HTTP 500).';
        return 'Server responded with error code HTTP $status.';
      case DioExceptionType.connectionError:
        return 'Failed to reach FastAPI backend. Verify server is running on port 8000.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      default:
        return error.message ?? 'An unexpected network error occurred.';
    }
  }

  static String formatGeneralError(dynamic error) {
    if (error is DioException) return formatDioError(error);
    return error.toString();
  }
}

