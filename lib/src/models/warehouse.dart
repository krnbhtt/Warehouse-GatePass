/// Represents a warehouse entity in the system
class Warehouse {
  /// Creates a new warehouse instance
  Warehouse({
    this.id,
    required this.name,
    required this.address,
    this.companyId,
    this.isActive = true,
  });

  /// Creates a warehouse from a map representation
  factory Warehouse.fromMap(Map<String, dynamic> map) {
    return Warehouse(
      id: map['id'] as int?,
      name: map['name'] as String,
      address: map['address'] as String,
      companyId: map['companyId'] as int?,
      isActive: map['isActive'] == 1,
    );
  }

  /// Unique identifier for the warehouse
  final int? id;
  /// Name of the warehouse
  final String name;
  /// Address of the warehouse
  final String address;
  /// ID of the associated company
  final int? companyId;
  /// Whether the warehouse is active
  final bool isActive;

  /// Converts the warehouse to a map representation
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'companyId': companyId,
      'isActive': isActive ? 1 : 0,
    };
  }

  /// Creates a copy of this warehouse with the given fields replaced
  Warehouse copyWith({
    int? id,
    String? name,
    String? address,
    int? companyId,
    bool? isActive,
  }) {
    return Warehouse(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      companyId: companyId ?? this.companyId,
      isActive: isActive ?? this.isActive,
    );
  }
} 