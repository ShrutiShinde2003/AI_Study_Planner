import 'package:study_planner/AI/GEMINI_API_KEY.dart';

class FlutterDotenv {
  static Future<void> load() async {
    await GEMINI_API_KEY.load();
  }

  static String? get(String key) {
    return GEMINI_API_KEY.env[key];
  }
}

class GEMINI_API_KEY {
  static var env;

  static load() {}
}
