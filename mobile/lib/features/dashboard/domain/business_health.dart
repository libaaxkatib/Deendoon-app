/// Mirrors `BusinessHealthService::calculate()` exactly (§4.1). `score` is
/// `null` whenever `status` is `neutral_baseline` — currently the only
/// status the backend can return, since two of its three formula inputs
/// (Collection Performance / DD-032, Outstanding Exposure normalization)
/// are still unresolved and the service returns the neutral baseline
/// rather than a partial or invented score (`Business_Health_Engine_v1.0.md`).
/// `healthy`/`needs_attention`/`at_risk` are real, future-ready states,
/// not dead code — they activate automatically once those two backend
/// decisions are made, with no Flutter change required.
class BusinessHealth {
  final String status;
  final int? score;

  const BusinessHealth({required this.status, required this.score});

  factory BusinessHealth.fromJson(Map<String, dynamic> json) => BusinessHealth(
        status: json['status'] as String,
        score: json['score'] as int?,
      );
}
