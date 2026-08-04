import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/search_results.dart';

final searchApiProvider = Provider<SearchApi>((ref) => SearchApi(ref.read(dioProvider)));

class SearchApi {
  final Dio _dio;
  const SearchApi(this._dio);

  Future<SearchResults> search(String query) async {
    final response = await _dio.get('search', queryParameters: {'q': query});
    return SearchResults.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
