/// Represents a party/client entity in the system
class Party {

  /// Creates a new party instance
  Party({
    required this.name,
  });

  /// Creates a party from a map representation
  factory Party.fromMap(Map<String, dynamic> map) {
    return Party(
      name: map['name'],
    );
  }
  /// Name of the party/client
  final String name;

  /// Converts the party to a map representation
  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }
} 