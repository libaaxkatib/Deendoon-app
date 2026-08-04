import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../domain/search_results.dart';
import 'search_api.dart';

final searchRepositoryProvider =
    Provider<SearchRepository>((ref) => SearchRepository(ref.read(searchApiProvider)));

class SearchRepository {
  final SearchApi _api;
  const SearchRepository(this._api);

  Future<SearchResults> search(String query) => _guard(() => _api.search(query));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
