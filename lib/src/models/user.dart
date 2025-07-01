class User {
  User({
    this.id,
    required this.username,
    required this.password,
    required this.role,
    this.warehouseId,
    this.isActive = true,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      password: map['password'] as String,
      role: map['role'] as String,
      warehouseId: map['warehouseId'] as int?,
      isActive: map['isActive'] == 1,
    );
  }

  final int? id;
  final String username;
  final String password;
  final String role;
  final int? warehouseId;
  final bool isActive;

  bool get isAdmin => role.toLowerCase() == 'admin';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'role': role,
      'warehouseId': warehouseId,
      'isActive': isActive ? 1 : 0,
    };
  }

  User copyWith({
    int? id,
    String? username,
    String? password,
    String? role,
    int? warehouseId,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      warehouseId: warehouseId ?? this.warehouseId,
      isActive: isActive ?? this.isActive,
    );
  }
} 