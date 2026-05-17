// Conditional import: Web'de stub, desktop'ta gerçek implementasyon
export 'database_helper_stub.dart'
    if (dart.library.io) 'database_helper_io.dart';

