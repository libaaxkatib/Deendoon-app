import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/dio_client.dart';

void main() {
  test(
    'connectTimeout and receiveTimeout are 45s (Mobile Fix #6, raised from 30s)',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final dio = container.read(dioProvider);

      expect(dio.options.connectTimeout, const Duration(seconds: 45));
      expect(dio.options.receiveTimeout, const Duration(seconds: 45));
    },
  );
}
