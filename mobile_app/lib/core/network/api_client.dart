import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../storage/secure_storage_service.dart';

class ApiClient {
  static ApiClient? _instance;
  late Dio dio;

  ApiClient._internal() {
    _initDio();
  }

  static ApiClient get instance {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  void _initDio() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 8),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  void updateBaseUrl(String newUrl) {
    ApiConfig.baseUrl = newUrl.replaceAll(RegExp(r'/$'), '');
    dio.options.baseUrl = ApiConfig.baseUrl;
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) =>
      dio.get<T>(path, queryParameters: queryParameters);

  Future<Response<T>> post<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters}) =>
      dio.post<T>(path, data: data, queryParameters: queryParameters);

  Future<Response<T>> patch<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters}) =>
      dio.patch<T>(path, data: data, queryParameters: queryParameters);

  Future<Response<T>> delete<T>(String path, {dynamic data}) =>
      dio.delete<T>(path, data: data);
}
