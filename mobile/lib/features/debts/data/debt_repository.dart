import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/payment.dart';
import '../../../core/network/api_exception.dart';
import '../../cases/domain/collection_case.dart';
import '../domain/debt.dart';
import '../../../core/models/document_summary.dart';
import '../domain/debt_page.dart';
import '../domain/debt_save_result.dart';
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

  Future<List<DocumentSummary>> fetchDocuments(String debtId) => _guard(() => _api.documents(debtId));

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

  Future<CollectionCase> openCase(String debtId) => _guard(() => _api.openCase(debtId));

  Future<DebtSaveResult> createDebt({
    required String customerId,
    required String amount,
    required String dueDate,
    String? notes,
  }) =>
      _guard(() => _api.store(customerId: customerId, amount: amount, dueDate: dueDate, notes: notes));

  Future<Debt> updateDebt({required String debtId, required String dueDate, String? notes}) =>
      _guard(() => _api.update(debtId: debtId, dueDate: dueDate, notes: notes));

  Future<DocumentSummary> generateStatement(String debtId) => _guard(() => _api.generateStatement(debtId));

  Future<Debt> logWhatsAppReminder({required String debtId, String? details}) =>
      _guard(() => _api.logWhatsAppReminder(debtId: debtId, details: details));

  Future<Debt> logSmsReminder({required String debtId, String? details}) =>
      _guard(() => _api.logSmsReminder(debtId: debtId, details: details));

  Future<Debt> logCallReminder({required String debtId, String? details}) =>
      _guard(() => _api.logCallReminder(debtId: debtId, details: details));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
