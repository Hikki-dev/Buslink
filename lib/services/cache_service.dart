import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;

  /// Initialize the cache service. Call this in main() or AppBootstrapper.
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // --- KEYS ---
  static const String keyThemeMode = 'app_theme_mode';
  static const String keyLanguage = 'app_language';
  static const String keyUserProfile = 'cached_user_profile';
  static const String keyHomeDestinations = 'cached_home_destinations';

  // --- GENERIC GETTERS/SETTERS ---

  Future<void> setString(String key, String value) async {
    await _initIfNeeded();
    await _prefs!.setString(key, value);
  }

  String? getString(String key) {
    if (_prefs == null) return null;
    return _prefs!.getString(key);
  }

  Future<void> setJson(String key, Map<String, dynamic> json) async {
    await _initIfNeeded();
    await _prefs!.setString(key, jsonEncode(json));
  }

  Map<String, dynamic>? getJson(String key) {
    if (_prefs == null) return null;
    final String? val = _prefs!.getString(key);
    if (val == null) return null;
    try {
      return jsonDecode(val) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<void> _initIfNeeded() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // --- SPECIFIC CACHE METHODS ---

  // 1. Theme
  String getThemeMode() => getString(keyThemeMode) ?? 'system';
  Future<void> saveThemeMode(String mode) => setString(keyThemeMode, mode);

  // 2. Language
  String getLanguage() => getString(keyLanguage) ?? 'en';
  Future<void> saveLanguage(String lang) => setString(keyLanguage, lang);

  // 3. User Profile
  Map<String, dynamic>? getUserProfile() => getJson(keyUserProfile);
  Future<void> saveUserProfile(Map<String, dynamic> profile) =>
      setJson(keyUserProfile, profile);
  Future<void> clearUserProfile() async {
    await _initIfNeeded();
    await _prefs!.remove(keyUserProfile);
  }

  // 4. Home Destinations
  List<Map<String, dynamic>>? getHomeDestinations() {
    final listJson = getJson(keyHomeDestinations);
    if (listJson == null || !listJson.containsKey('data')) return null;

    final List<dynamic> list = listJson['data'];
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> saveHomeDestinations(List<Map<String, dynamic>> destinations) =>
      setJson(keyHomeDestinations, {'data': destinations});

  // 5. Cities Cache (with Expiry)
  static const String keyCities = 'cached_cities_list';

  List<String>? getCachedCities() {
    final data = getJson(keyCities);
    if (data == null) return null;

    // Check Expiry (24 hours)
    final int? timestamp = data['ts'];
    if (timestamp == null) return null;

    final diff = DateTime.now().millisecondsSinceEpoch - timestamp;
    if (diff > 86400000) return null; // Expired

    return (data['list'] as List).cast<String>();
  }

  Future<void> saveCities(List<String> cities) => setJson(
      keyCities, {'ts': DateTime.now().millisecondsSinceEpoch, 'list': cities});
}
