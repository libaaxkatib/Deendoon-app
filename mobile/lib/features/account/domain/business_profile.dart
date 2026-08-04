/// Mirrors `App\Http\Resources\CompanyProfileResource` exactly — the real
/// field shape returned by `GET/PUT /admin/settings/company-profile`
/// (FR-068). That endpoint is gated by the backend's `admin-only` Gate,
/// which the Business Owner's account satisfies under the current
/// one-account-per-tenant model (Business Owner == role `admin`, per the
/// RBAC Architecture Amendment) — real and reachable, not a stub.
class BusinessProfile {
  final String id;
  final String businessName;
  final String? logoPath;
  final String? address;
  final String? contactEmail;
  final String? contactPhone;

  const BusinessProfile({
    required this.id,
    required this.businessName,
    required this.logoPath,
    required this.address,
    required this.contactEmail,
    required this.contactPhone,
  });

  factory BusinessProfile.fromJson(Map<String, dynamic> json) => BusinessProfile(
        id: json['id'].toString(),
        businessName: json['business_name'] as String,
        logoPath: json['logo_path'] as String?,
        address: json['address'] as String?,
        contactEmail: json['contact_email'] as String?,
        contactPhone: json['contact_phone'] as String?,
      );
}
