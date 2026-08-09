/// Mirrors `App\Http\Resources\ReferenceDataResource` exactly. Used to
/// source the Reason for Transfer / Requested Services multi-selects on
/// Professional Collection Request submission (FR-072, BRL-078) from the
/// tenant's own configured Reference Data — never a hardcoded list.
/// `GET admin/reference-data/{category}` returns every row regardless of
/// `isActive`; callers must filter to active values themselves.
class ReferenceDataItem {
  final String id;
  final String category;
  final String valueLabel;
  final int sortOrder;
  final bool isActive;

  const ReferenceDataItem({
    required this.id,
    required this.category,
    required this.valueLabel,
    required this.sortOrder,
    required this.isActive,
  });

  factory ReferenceDataItem.fromJson(Map<String, dynamic> json) => ReferenceDataItem(
        id: json['id'].toString(),
        category: json['category'] as String,
        valueLabel: json['value_label'] as String,
        sortOrder: json['sort_order'] as int,
        isActive: json['is_active'] as bool,
      );
}
