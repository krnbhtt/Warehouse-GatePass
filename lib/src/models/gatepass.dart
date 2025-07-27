import 'package:uuid/uuid.dart';

/// Represents a gatepass entity in the system
class Gatepass {

  /// Creates a new gatepass instance
  Gatepass({
    String? id,
    required this.serialNumber,
    required this.dateTime,
    required this.companyId,
    required this.warehouseId,
    required this.invoiceNumber,
    required this.partyName,
    required this.vehicleNumber,
    required this.quantity,
    required this.quantityUnit,
    required this.productGrade,
    required this.createdBy,
    this.approvedBy,
    this.approverName,
    this.isPrinted = false,
    this.isSynced = false,
  }) : id = id ?? const Uuid().v4();

  /// Creates a gatepass from a map representation
  factory Gatepass.fromMap(Map<String, dynamic> map) {
    return Gatepass(
      id: map['id'],
      serialNumber: map['serialNumber'],
      dateTime: DateTime.parse(map['dateTime']),
      companyId: map['companyId'],
      warehouseId: map['warehouseId'],
      invoiceNumber: map['invoiceNumber'],
      partyName: map['partyName'],
      vehicleNumber: map['vehicleNumber'],
      quantity: map['quantity'],
      quantityUnit: map['quantityUnit'] ?? 'MT',
      productGrade: map['productGrade'],
      createdBy: map['createdBy'],
      approvedBy: map['approvedBy'],
      approverName: map['approverName'],
      isPrinted: map['isPrinted'] == 1,
      isSynced: map['isSynced'] == 1,
    );
  }
  /// Unique identifier for the gatepass
  final String id;
  /// Serial number of the gatepass
  final String serialNumber;
  /// Date and time of the gatepass
  final DateTime dateTime;
  /// ID of the associated company
  final int companyId;
  /// ID of the associated warehouse
  final int warehouseId;
  /// Invoice number
  final String invoiceNumber;
  /// Name of the party/client
  final String partyName;
  /// Vehicle number
  final String vehicleNumber;
  /// Quantity of goods
  final double quantity;
  /// Unit of quantity (MT or Bags)
  final String quantityUnit;
  /// Product grade
  final String productGrade;
  /// User who created the gatepass
  final String createdBy;
  /// Person who approved the gatepass
  final String? approvedBy;
  /// Name of the approver
  final String? approverName;
  /// Whether the gatepass has been printed
  final bool isPrinted;
  /// Whether the gatepass has been synced
  final bool isSynced;

  /// Converts the gatepass to a map representation
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serialNumber': serialNumber,
      'dateTime': dateTime.toIso8601String(),
      'companyId': companyId,
      'warehouseId': warehouseId,
      'invoiceNumber': invoiceNumber,
      'partyName': partyName,
      'vehicleNumber': vehicleNumber,
      'quantity': quantity,
      'quantityUnit': quantityUnit,
      'productGrade': productGrade,
      'createdBy': createdBy,
      'approvedBy': approvedBy,
      'approverName': approverName,
      'isPrinted': isPrinted ? 1 : 0,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  /// Creates a copy of this gatepass with the given fields replaced
  Gatepass copyWith({
    String? id,
    String? serialNumber,
    DateTime? dateTime,
    int? companyId,
    int? warehouseId,
    String? invoiceNumber,
    String? partyName,
    String? vehicleNumber,
    double? quantity,
    String? quantityUnit,
    String? productGrade,
    String? createdBy,
    String? approvedBy,
    String? approverName,
    bool? isPrinted,
    bool? isSynced,
  }) {
    return Gatepass(
      id: id ?? this.id,
      serialNumber: serialNumber ?? this.serialNumber,
      dateTime: dateTime ?? this.dateTime,
      companyId: companyId ?? this.companyId,
      warehouseId: warehouseId ?? this.warehouseId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      partyName: partyName ?? this.partyName,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      quantity: quantity ?? this.quantity,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      productGrade: productGrade ?? this.productGrade,
      createdBy: createdBy ?? this.createdBy,
      approvedBy: approvedBy ?? this.approvedBy,
      approverName: approverName ?? this.approverName,
      isPrinted: isPrinted ?? this.isPrinted,
      isSynced: isSynced ?? this.isSynced,
    );
  }
} 