import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import 'auth_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      // Dio joins baseUrl + path by plain concatenation, not URI
      // resolution — without a trailing slash here, "…/api/v1" + "login"
      // (endpoint paths are deliberately bare, no leading slash) becomes
      // "…/api/v1login". Normalized here so it's correct regardless of
      // whether API_BASE_URL is passed with or without one.
      baseUrl: Env.apiBaseUrl.endsWith('/') ? Env.apiBaseUrl : '${Env.apiBaseUrl}/',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
    ),
  );

  dio.interceptors.add(AuthInterceptor(ref));

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  return dio;
});
