import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/payment.dart';
import '../../../core/network/api_exception.dart';
import '../domain/debt.dart';
import '../domain/debt_document.dart';
import '../domain/debt_page.dart';
import '../domain/debt_timeline.dart';
import '../domain/promise_to_pay.dart';
import 'debt_api.dart';

final debtRepositoryProvider = Provider<DebtRepository>((ref) => DebtRepository(ref.read(debtApiProvider)));

/// Translates raw Dio failures into `ApiException` — same pattern as
/// every other repository in the app. No caching, no calculation beyond
/// what `Debt.daysOverdue()` already does client-side on real fields.
class DebtRepository {
  final DebtApi _api;

  const DebtRepository(this._api);

  Future<DebtPage> fetchDebts({
    required int page,
    String? customerId,
    String? status,
    String? dateFrom,
    String? dateTo,
  }) =>
      _guard(() => _api.list(
            page: page,
            customerId: customerId,
            status: status,
            dateFrom: dateFrom,
            dateTo: dateTo,
          ));

  Future<Debt> fetchDebt(String id) => _guard(() => _api.show(id));

  Future<List<Payment>> fetchPayments(String debtId) => _guard(() => _api.payments(debtId));

  Future<List<DebtDocument>> fetchDocuments(String debtId) => _guard(() => _api.documents(debtId));

  Future<DebtTimeline> fetchTimeline(String debtId) => _guard(() => _api.timeline(debtId));

  Future<Payment> recordPayment({
    required String debtId,
    required String amount,
    required String paymentDate,
    String? paymentMethod,
    String? referenceNotes,
  }) =>
      _guard(() => _api.recordPayment(
            debtId: debtId,
            amount: amount,
            paymentDate: paymentDate,
            paymentMethod: paymentMethod,
            referenceNotes: referenceNotes,
          ));

  Future<PromiseToPay> promiseToPay({required String debtId, required String promisedDate}) =>
      _guard(() => _api.promiseToPay(debtId: debtId, promisedDate: promisedDate));

  Future<void> openCase(String debtId) => _guard(() => _api.openCase(debtId));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
