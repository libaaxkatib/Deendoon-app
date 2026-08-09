import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/document_summary.dart';
import '../../../core/models/payment.dart';
import '../../../core/network/dio_client.dart';
import '../../cases/domain/collection_case.dart';
import '../domain/credit_limit_warning.dart';
import '../domain/debt.dart';
import '../domain/debt_page.dart';
import '../domain/debt_save_result.dart';
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

  /// Debt Detail's "Promise to Pay History" (mobile Item 11).
  Future<List<PromiseToPay>> promiseToPayHistory(String debtId) async {
    final response = await _dio.get('debts/$debtId/promise-to-pay');
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => PromiseToPay.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Standalone `GET /promises-to-pay/{id}` (mobile Item 14) — resolves a
  /// Reminder's `related_entity_type == 'promise_to_pay'` to its real
  /// Promise (and, via `debt_id`, its Customer) instead of a generic
  /// "Promise to Pay" label.
  Future<PromiseToPay> showPromiseToPay(String id) async {
    final response = await _dio.get('promises-to-pay/$id');
    return PromiseToPay.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Debt Detail's "Related Case" (mobile Item 12) —
  /// `CollectionCaseController::forDebt`. A 404 (no case yet) is a real,
  /// expected state, handled by the repository, not here.
  Future<CollectionCase> relatedCase(String debtId) async {
    final response = await _dio.get('debts/$debtId/collection-case');
    return CollectionCase.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// `EscalateDebtRequest` takes no fields — opening a case is a bare
  /// confirm-and-submit action. Returns the created case (the `store()`
  /// response already includes it via `CollectionCaseResource`) so callers
  /// can deep-link straight to it rather than falling back to the Case List.
  Future<CollectionCase> openCase(String debtId) async {
    final response = await _dio.post('debts/$debtId/collection-cases');
    return CollectionCase.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// `POST /customers/{customer}/debts` (`StoreDebtRequest`: `amount`,
  /// `due_date`, `notes`). Attaches a `CREDIT_LIMIT_EXCEEDED` warning
  /// (BRL-023) when applicable — informational, the debt is still created.
  Future<DebtSaveResult> store({
    required String customerId,
    required String amount,
    required String dueDate,
    String? notes,
  }) async {
    final response = await _dio.post('customers/$customerId/debts', data: {
      'amount': amount,
      'due_date': dueDate,
      'notes': notes,
    });
    final data = response.data['data'] as Map<String, dynamic>;
    return (
      debt: Debt.fromJson(data['debt'] as Map<String, dynamic>),
      warning: data['warning'] != null ? CreditLimitWarning.fromJson(data['warning'] as Map<String, dynamic>) : null,
    );
  }

  /// `PUT /debts/{debt}` (`UpdateDebtRequest`: `due_date`, `notes` only —
  /// FR-020, `amount` is deliberately immutable after creation).
  Future<Debt> update({required String debtId, required String dueDate, String? notes}) async {
    final response = await _dio.put('debts/$debtId', data: {
      'due_date': dueDate,
      'notes': notes,
    });
    return Debt.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// `POST /debts/{debt}/statements` (`GenerateStatementRequest` — bare, no
  /// fields) — the per-debt Statement of Account, distinct from
  /// `CustomerApi.generateStatement`'s per-customer equivalent.
  Future<DocumentSummary> generateStatement(String debtId) async {
    final response = await _dio.post('debts/$debtId/statements');
    return DocumentSummary.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// FR-030 Manual Reminder — `POST /debts/{debt}/reminders/whatsapp`
  /// (`SendManualReminderRequest`: `details` optional). Records that a
  /// WhatsApp reminder was sent (actual provider delivery is out of
  /// scope) and feeds the Follow-up Timeline's `whatsapp_reminder` stage.
  Future<Debt> logWhatsAppReminder({required String debtId, String? details}) async {
    final response = await _dio.post('debts/$debtId/reminders/whatsapp', data: {'details': details});
    return Debt.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// `POST /debts/{debt}/reminders/sms` — same contract as
  /// [logWhatsAppReminder], feeds the `sms_reminder` timeline stage.
  Future<Debt> logSmsReminder({required String debtId, String? details}) async {
    final response = await _dio.post('debts/$debtId/reminders/sms', data: {'details': details});
    return Debt.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// `POST /debts/{debt}/reminders/call` (`LogCallRequest`: `details`
  /// optional — FR-030 A1, a call with no answer/outcome is still a valid
  /// recordable attempt). Feeds the `phone_call` timeline stage.
  Future<Debt> logCallReminder({required String debtId, String? details}) async {
    final response = await _dio.post('debts/$debtId/reminders/call', data: {'details': details});
    return Debt.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
