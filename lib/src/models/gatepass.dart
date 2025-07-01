import 'package:uuid/uuid.dart';

class Gatepass {

  Gatepass({
    String? id,
    required this.serialNumber,
    required this.dateTime,
    required this.warehouseId,
    required this.invoiceNumber,
    required this.partyName,
    required this.gstNumber,
    required this.address,
    required this.vehicleNumber,
    required this.quantity,
    required this.productGrade,
    required this.createdBy,
    this.isPrinted = false,
    this.isSynced = false,
  }) : id = id ?? const Uuid().v4();

  factory Gatepass.fromMap(Map<String, dynamic> map) {
    return Gatepass(
      id: map['id'],
      serialNumber: map['serialNumber'],
      dateTime: DateTime.parse(map['dateTime']),
      warehouseId: map['warehouseId'],
      invoiceNumber: map['invoiceNumber'],
      partyName: map['partyName'],
      gstNumber: map['gstNumber'],
      address: map['address'],
      vehicleNumber: map['vehicleNumber'],
      quantity: map['quantity'],
      productGrade: map['productGrade'],
      createdBy: map['createdBy'],
      isPrinted: map['isPrinted'] == 1,
      isSynced: map['isSynced'] == 1,
    );
  }
  final String id;
  final String serialNumber;
  final DateTime dateTime;
  final int warehouseId;
  final String invoiceNumber;
  final String partyName;
  final String gstNumber;
  final String address;
  final String vehicleNumber;
  final double quantity;
  final String productGrade;
  final String createdBy;
  final bool isPrinted;
  final bool isSynced;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serialNumber': serialNumber,
      'dateTime': dateTime.toIso8601String(),
      'warehouseId': warehouseId,
      'invoiceNumber': invoiceNumber,
      'partyName': partyName,
      'gstNumber': gstNumber,
      'address': address,
      'vehicleNumber': vehicleNumber,
      'quantity': quantity,
      'productGrade': productGrade,
      'createdBy': createdBy,
      'isPrinted': isPrinted ? 1 : 0,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  Gatepass copyWith({
    String? id,
    String? serialNumber,
    DateTime? dateTime,
    int? warehouseId,
    String? invoiceNumber,
    String? partyName,
    String? gstNumber,
    String? address,
    String? vehicleNumber,
    double? quantity,
    String? productGrade,
    String? createdBy,
    bool? isPrinted,
    bool? isSynced,
  }) {
    return Gatepass(
      id: id ?? this.id,
      serialNumber: serialNumber ?? this.serialNumber,
      dateTime: dateTime ?? this.dateTime,
      warehouseId: warehouseId ?? this.warehouseId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      partyName: partyName ?? this.partyName,
      gstNumber: gstNumber ?? this.gstNumber,
      address: address ?? this.address,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      quantity: quantity ?? this.quantity,
      productGrade: productGrade ?? this.productGrade,
      createdBy: createdBy ?? this.createdBy,
      isPrinted: isPrinted ?? this.isPrinted,
      isSynced: isSynced ?? this.isSynced,
    );
  }
} 