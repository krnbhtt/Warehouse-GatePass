import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/party.dart';
import '../models/warehouse.dart';
import 'database_service.dart';

class SyncService {
  final DatabaseService _dbService = DatabaseService();
  final String _baseUrl = 'https://api.yourcompany.com'; // Replace with your API URL

  Future<void> syncGatepasses() async {
    try {
      // Get unsynced gatepasses
      final gatepasses = await _dbService.getGatepasses(isSynced: false);
      
      for (final gatepass in gatepasses) {
        final response = await http.post(
          Uri.parse('$_baseUrl/gatepasses'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(gatepass.toMap()),
        );

        if (response.statusCode == 200) {
          // Update local gatepass as synced
          await _dbService.updateGatepass(
            gatepass.copyWith(isSynced: true),
          );
        } else {
          throw Exception('Failed to sync gatepass: ${response.body}');
        }
      }
    } catch (e) {
      throw Exception('Sync failed: $e');
    }
  }

  Future<void> syncParties() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/parties'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> partiesJson = jsonDecode(response.body);
        for (final partyJson in partiesJson) {
          final party = Party.fromMap(partyJson);
          await _dbService.insertParty(party);
        }
      } else {
        throw Exception('Failed to sync parties: ${response.body}');
      }
    } catch (e) {
      throw Exception('Sync failed: $e');
    }
  }

  Future<void> syncWarehouses() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/warehouses'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> warehousesJson = jsonDecode(response.body);
        for (final warehouseJson in warehousesJson) {
          final warehouse = Warehouse.fromMap(warehouseJson);
          await _dbService.insertWarehouse(warehouse);
        }
      } else {
        throw Exception('Failed to sync warehouses: ${response.body}');
      }
    } catch (e) {
      throw Exception('Sync failed: $e');
    }
  }

  Future<void> syncAll() async {
    await syncWarehouses();
    await syncParties();
    await syncGatepasses();
  }
} 