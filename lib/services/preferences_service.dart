import 'package:shared_preferences/shared_preferences.dart';  // Fix the import path

class PreferencesService {
  static const String _termsAcceptedKey = 'terms_accepted';

  static Future<bool> hasAcceptedTerms() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_termsAcceptedKey) ?? false;
  }

  static Future<void> setTermsAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_termsAcceptedKey, true);
  }
} 