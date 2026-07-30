import '../../../core/models/document_summary.dart';

/// One page of `GET /documents`, mirroring the controller's pagination
/// envelope exactly (`current_page`, `per_page`, `total`, `last_page`).
/// Unlike `DebtPage`/`ReminderPage`, this is NOT a real SQL-level paginated
/// query server-side — `DocumentController::index()` fetches every
/// matching row per type for the tenant, combines and sorts them, then
/// slices the combined collection in memory before returning this page.
/// Functionally identical from the client's point of view (same envelope,
/// same semantics for `hasMore`), just worth knowing if total document
/// counts ever get large enough to matter for backend performance.
class DocumentPage {
  final List<DocumentSummary> documents;
  final int currentPage;
  final int lastPage;
  final int total;

  const DocumentPage({
    required this.documents,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory DocumentPage.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>;
    final items = json['documents'] as List<dynamic>;
    return DocumentPage(
      documents: items.map((e) => DocumentSummary.fromJson(e as Map<String, dynamic>)).toList(),
      currentPage: pagination['current_page'] as int,
      lastPage: pagination['last_page'] as int,
      total: pagination['total'] as int,
    );
  }
}
