import 'dart:convert';

class Party {

  Party({
    required this.name,
    required this.gstNumber,
    required this.addresses,
  });

  factory Party.fromMap(Map<String, dynamic> map) {
    return Party(
      name: map['name'],
      gstNumber: map['gstNumber'],
      addresses: List<String>.from(jsonDecode(map['addresses'])),
    );
  }
  final String name;
  final String gstNumber;
  final List<String> addresses;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'gstNumber': gstNumber,
      'addresses': jsonEncode(addresses),
    };
  }
} 