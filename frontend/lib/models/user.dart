class User {
  final int id;
  final String email;
  final String username;
  final String fullName;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'full_name': fullName,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
