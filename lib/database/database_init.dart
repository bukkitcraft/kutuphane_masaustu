// Conditional import: Web'de boş, desktop'ta sqflite_common_ffi
import 'database_init_stub.dart'
    if (dart.library.io) 'database_init_io.dart' as impl;

void initDatabase() {
  impl.initDatabase();
}

