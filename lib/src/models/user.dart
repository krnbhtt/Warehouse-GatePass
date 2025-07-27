/// Represents a user entity in the system
class User {
  /// Creates a new user instance
  User({
    this.id,
    required this.username,
    required this.password,
    required this.role,
    this.warehouseId,
    this.isActive = true,
  });

  /// Creates a user from a map representation
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

  /// Unique identifier for the user
  final int? id;
  /// Username for login
  final String username;
  /// Password for authentication
  final String password;
  /// Role of the user (admin/user)
  final String role;
  /// ID of the associated warehouse
  final int? warehouseId;
  /// Whether the user is active
  final bool isActive;

  /// Returns true if the user has admin role
  bool get isAdmin => role.toLowerCase() == 'admin';

  /// Converts the user to a map representation
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

  /// Creates a copy of this user with the given fields replaced
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