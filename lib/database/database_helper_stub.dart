// Web için stub - SQLite çalışmaz
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init();

  Future<dynamic> get database async {
    throw UnsupportedError('SQLite is not supported on web platform. Please use Windows desktop.');
  }

  Future<void> close() async {
    // Web'de hiçbir şey yapmaz
  }
}

