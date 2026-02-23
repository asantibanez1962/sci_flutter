import 'package:shared_preferences/shared_preferences.dart';
import '../models/tab_item.dart';

class TabPersistence {
  static const String key = "openTabs";

  // Guardar lista completa de IDs
  static Future<void> saveTabs(List<TabItem> tabs) async {
    final prefs = await SharedPreferences.getInstance();

    // Guardar solo las pestañas que sí son cerrables
    final ids = tabs
        .where((t) => t.closable)
        .map((t) => t.id)
        .toList();

    await prefs.setStringList(key, ids);
  }

  // Cargar lista completa de IDs
  static Future<List<String>> loadTabIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? [];
  }
}