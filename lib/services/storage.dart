import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  static Future<int> loadHiScore() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt('hiscore') ?? 0;
  }

  static Future<void> saveHiScore(int v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('hiscore', v);
  }
}
