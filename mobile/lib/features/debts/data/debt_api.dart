import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/document_summary.dart';
import '../../../core/models/payment.dart';
import '../../../core/network/dio_client.dart';
import '../domain/debt.dart';
import '../domain/debt_page.dart';
import '../domain/debt_timeline.dart';
import '../domain/promise_to_pay.dart';

final debtApiProvider = Provider<DebtApi>((ref) => DebtApi(ref.read(dioProvider)));

/// Thin wrapper around `GET/POST /debts*` — mirrors
/// `App\Http\Controllers\DebtController`, `PaymentController::index`,
/// `DocumentController::forDebt`, `PromiseToPayController::store`, and
/// `CollectionCaseController::store` exactly.
class DebtApi {
  final Dio _dio;

  const DebtApi(this._dio);

  Future<DebtPage> list({
    required int page,
    int perPage = 20,
    String? customerId,
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    final response = await _dio.get('debts', queryParameters: {
      'page': page,
      'perPage': perPage,
      'customer_id': ?customerId,
      'status': ?status,
      'dateFrom': ?dateFrom,
      'dateTo': ?dateTo,
    });
    return DebtPage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Debt> show(String id) async {
    final response = await _dio.get('debts/$id');
    return Debt.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<Payment>> payments(String debtId) async {
    final response = await _dio.get('debts/$debtId/payments');
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => Payment.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<DocumentSummary>> documents(String debtId) async {
    final response = await _dio.get('debts/$debtId/documents');
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => DocumentSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DebtTimeline> timeline(String debtId) async {
    final response = await _dio.get('debts/$debtId/timeline');
    return DebtTimeline.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Payment> recordPayment({
    required String debtId,
    required String amount,
    required String paymentDate,
    String? paymentMethod,
    String? referenceNotes,
  }) async {
    final response = await _dio.post('debts/$debtId/payments', data: {
      'amount': amount,
      'payment_date': paymentDate,
      'payment_method': ?paymentMethod,
      'reference_notes': ?referenceNotes,
    });
    return Payment.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<PromiseToPay> promiseToPay({required String debtId, required String promisedDate}) async {
    final response = await _dio.post('debts/$debtId/promise-to-pay', data: {
      'promised_date': promisedDate,
    });
    return PromiseToPay.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// `EscalateDebtRequest` takes no fields — opening a case is a bare
  /// confirm-and-submit action.
  Future<void> openCase(String debtId) async {
    await _dio.post('debts/$debtId/collection-cases');
  }
}
