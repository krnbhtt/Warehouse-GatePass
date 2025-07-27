/// Represents a company entity in the system
class Company {
  /// Creates a new company instance
  Company({
    this.id,
    required this.name,
    this.address,
    this.isActive = true,
  });

  /// Creates a company from a map representation
  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id'] as int?,
      name: map['name'] as String,
      address: map['address'] as String?,
      isActive: map['isActive'] == 1,
    );
  }

  /// Unique identifier for the company
  final int? id;
  /// Name of the company
  final String name;
  /// Address of the company
  final String? address;
  /// Whether the company is active
  final bool isActive;

  /// Converts the company to a map representation
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'isActive': isActive ? 1 : 0,
    };
  }

  /// Creates a copy of this company with the given fields replaced
  Company copyWith({
    int? id,
    String? name,
    String? address,
    bool? isActive,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
    );
  }
} 