import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/account/data/business_profile_api.dart';
import 'package:mobile/features/account/data/business_profile_repository.dart';
import 'package:mobile/features/account/domain/business_profile.dart';
import 'package:mocktail/mocktail.dart';

class _MockBusinessProfileApi extends Mock implements BusinessProfileApi {}

const _profile = BusinessProfile(
  id: '1',
  businessName: 'Somali Builders',
  logoPath: null,
  address: '123 Main St',
  contactEmail: 'owner@example.com',
  contactPhone: '+252612345678',
);

void main() {
  late _MockBusinessProfileApi mockApi;
  late BusinessProfileRepository repository;

  setUp(() {
    mockApi = _MockBusinessProfileApi();
    repository = BusinessProfileRepository(mockApi);
  });

  test('fetchBusinessProfile returns the profile straight through', () async {
    when(() => mockApi.fetch()).thenAnswer((_) async => _profile);

    final result = await repository.fetchBusinessProfile();

    expect(result, _profile);
  });

  test('fetchBusinessProfile throws ApiException on failure', () async {
    when(() => mockApi.fetch()).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: 'admin/settings/company-profile'),
        response: Response(
          requestOptions: RequestOptions(
            path: 'admin/settings/company-profile',
          ),
          statusCode: 401,
          data: {
            'success': false,
            'message': 'Unauthenticated.',
            'data': null,
            'errors': null,
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(
      () => repository.fetchBusinessProfile(),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
      ),
    );
  });

  test('updateBusinessProfile delegates every field to the api', () async {
    when(
      () => mockApi.update(
        businessName: 'Somali Builders',
        address: '123 Main St',
        contactEmail: 'owner@example.com',
        contactPhone: '+252612345678',
        logo: null,
      ),
    ).thenAnswer((_) async => _profile);

    final result = await repository.updateBusinessProfile(
      businessName: 'Somali Builders',
      address: '123 Main St',
      contactEmail: 'owner@example.com',
      contactPhone: '+252612345678',
    );

    expect(result, _profile);
    verify(
      () => mockApi.update(
        businessName: 'Somali Builders',
        address: '123 Main St',
        contactEmail: 'owner@example.com',
        contactPhone: '+252612345678',
        logo: null,
      ),
    ).called(1);
  });

  test(
    'updateBusinessProfile surfaces field validation errors via ApiException',
    () async {
      when(
        () => mockApi.update(
          businessName: '',
          address: null,
          contactEmail: 'not-an-email',
          contactPhone: null,
          logo: null,
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: 'admin/settings/company-profile',
          ),
          response: Response(
            requestOptions: RequestOptions(
              path: 'admin/settings/company-profile',
            ),
            statusCode: 422,
            data: {
              'success': false,
              'message': 'The given data was invalid.',
              'data': null,
              'errors': {
                'business_name': ['The business name field is required.'],
                'contact_email': [
                  'The contact email must be a valid email address.',
                ],
              },
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => repository.updateBusinessProfile(
          businessName: '',
          contactEmail: 'not-an-email',
        ),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 422),
        ),
      );
    },
  );
}
