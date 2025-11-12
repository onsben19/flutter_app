import 'package:shared_preferences/shared_preferences.dart';

class SessionUser {
  final int id;
  final String email;
  final String name;
  const SessionUser({required this.id, required this.email, required this.name});
}

class SessionService {
  static const _kId = 'session_user_id';
  static const _kEmail = 'session_user_email';
  static const _kName = 'session_user_name';

  /// Save after successful login
  static Future<void> saveLoggedInUser({
    required int id,
    required String email,
    required String name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kId, id);
    await prefs.setString(_kEmail, email);
    await prefs.setString(_kName, name);
  }

  /// Read on app start / any screen
  static Future<SessionUser?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_kId);
    final email = prefs.getString(_kEmail);
    final name = prefs.getString(_kName);
    if (id == null || email == null || name == null) return null;
    return SessionUser(id: id, email: email, name: name);
  }

  /// Clear on logout
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kId);
    await prefs.remove(_kEmail);
    await prefs.remove(_kName);
  }
}
