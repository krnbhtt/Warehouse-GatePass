class ApiConfig {
  static const String baseUrl = 'https://api.example.com'; // Replace with your actual API base URL
  
  static String get warehousesEndpoint => '$baseUrl/warehouses';
  static String get gatepassesEndpoint => '$baseUrl/gatepasses';
  static String get syncEndpoint => '$baseUrl/sync';
} 