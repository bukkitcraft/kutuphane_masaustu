// Desktop platformlar için (Windows, Linux, macOS)
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void initDatabase() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

