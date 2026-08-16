/// Mirrors `App\Http\Resources\UserResource` exactly — `{id, name, email,
/// phone}`, no role field is exposed by the backend today. `phone` is
/// nullable because accounts registered before the phone field existed
/// have none.
class User {
  final String id;
  final String name;
  final String email;
  final String? phone;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'].toString(),
    name: json['name'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
  };
}
