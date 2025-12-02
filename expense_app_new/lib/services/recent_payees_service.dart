import 'package:shared_preferences/shared_preferences.dart';

class RecentPayeesService {
  static const String _key = 'recent_payees';
  static const int _maxPayees = 5;

  static Future<List<String>> getPayees() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> addPayee(String vpa) async {
    if (vpa.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    List<String> payees = prefs.getStringList(_key) ?? [];
    
    // Remove if exists (to move to top)
    payees.remove(vpa);
    
    // Add to top
    payees.insert(0, vpa);
    
    // Keep max limit
    if (payees.length > _maxPayees) {
      payees = payees.sublist(0, _maxPayees);
    }
    
    await prefs.setStringList(_key, payees);
  }
}
