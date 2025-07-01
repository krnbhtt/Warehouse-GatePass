import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  factory SessionService() => _instance;
  SessionService._internal();
  static final SessionService _instance = SessionService._internal();

  static const String _lastActivityKey = 'last_activity';
  static const int _sessionTimeoutMinutes = 60;
  Timer? _sessionTimer;
  DateTime? _lastActivity;

  Future<void> updateLastActivity() async {
    _lastActivity = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastActivityKey, _lastActivity!.toIso8601String());
    _startSessionTimer();
  }

  Future<bool> isSessionValid() async {
    if (_lastActivity == null) {
      final prefs = await SharedPreferences.getInstance();
      final lastActivityStr = prefs.getString(_lastActivityKey);
      if (lastActivityStr == null) return false;
      _lastActivity = DateTime.parse(lastActivityStr);
    }

    final difference = DateTime.now().difference(_lastActivity!);
    return difference.inMinutes < _sessionTimeoutMinutes;
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(const Duration(minutes: _sessionTimeoutMinutes), () {
      // Session expired
      _lastActivity = null;
    });
  }

  Future<void> clearSession() async {
    _sessionTimer?.cancel();
    _lastActivity = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastActivityKey);
  }
} 