class Warehouse {
  Warehouse({
    this.id,
    required this.name,
    required this.address,
    this.isActive = true,
  });

  factory Warehouse.fromMap(Map<String, dynamic> map) {
    return Warehouse(
      id: map['id'] as int?,
      name: map['name'] as String,
      address: map['address'] as String,
      isActive: map['isActive'] == 1,
    );
  }

  final int? id;
  final String name;
  final String address;
  final bool isActive;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'isActive': isActive ? 1 : 0,
    };
  }

  Warehouse copyWith({
    int? id,
    String? name,
    String? address,
    bool? isActive,
  }) {
    return Warehouse(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
    );
  }
} 