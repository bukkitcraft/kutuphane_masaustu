// Desktop platformlar için (Windows, Linux, macOS)
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kutuphane.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Desktop için veritabanı dizinini oluştur
    String directory;
    if (Platform.isWindows) {
      directory = path.join(Platform.environment['APPDATA'] ?? '', 'KutuphaneMasaustu');
    } else if (Platform.isLinux) {
      directory = path.join(Platform.environment['HOME'] ?? '', '.kutuphane_masaustu');
    } else if (Platform.isMacOS) {
      directory = path.join(Platform.environment['HOME'] ?? '', 'Library', 'Application Support', 'KutuphaneMasaustu');
    } else {
      directory = path.current;
    }

    // Dizini oluştur
    final dir = Directory(directory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final dbPath = path.join(directory, filePath);

    return await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 11,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Kitap Satışları Tablosu ekle
      await db.execute('''
        CREATE TABLE IF NOT EXISTS book_sales (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sale_no TEXT NOT NULL UNIQUE,
          book_id INTEGER NOT NULL,
          book_title TEXT NOT NULL,
          book_isbn TEXT,
          book_author TEXT,
          quantity INTEGER NOT NULL DEFAULT 1,
          unit_price REAL NOT NULL,
          total_amount REAL NOT NULL,
          discount REAL DEFAULT 0,
          final_amount REAL NOT NULL,
          customer_name TEXT,
          customer_phone TEXT,
          customer_email TEXT,
          customer_address TEXT,
          member_id INTEGER,
          sale_date TEXT NOT NULL,
          payment_method TEXT,
          notes TEXT,
          created_by TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (book_id) REFERENCES books (id),
          FOREIGN KEY (member_id) REFERENCES members (id)
        )
      ''');
      
      // İndeksler
      await db.execute('CREATE INDEX IF NOT EXISTS idx_book_sales_book ON book_sales(book_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_book_sales_date ON book_sales(sale_date)');
    }

    if (oldVersion < 3) {
      // Personel tablosuna TC kimlik sütunu ekle
      await db.execute('ALTER TABLE personnel ADD COLUMN tc_no TEXT');
    }

    if (oldVersion < 4) {
      // Personel tablosuna doğum tarihi sütunu ekle
      try {
        await db.execute('ALTER TABLE personnel ADD COLUMN birth_date TEXT');
      } catch (_) {
        // Sütun zaten varsa hata verme
      }
    }

    if (oldVersion < 5) {
      // Personel tablosuna hesap no ve IBAN sütunları ekle
      try {
        await db.execute('ALTER TABLE personnel ADD COLUMN account_no TEXT');
        await db.execute('ALTER TABLE personnel ADD COLUMN iban TEXT');
      } catch (_) {
        // Sütun zaten varsa hata verme
      }
    }

    if (oldVersion < 6) {
      // Çekler tablosuna IBAN sütunu ekle
      try {
        await db.execute('ALTER TABLE checks ADD COLUMN iban TEXT');
      } catch (_) {
        // Sütun zaten varsa hata verme
      }
    }

    if (oldVersion < 7) {
      // Kullanıcılar tablosunu ekle
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL,
          role TEXT NOT NULL,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      
      // İndeks ekle
      await db.execute('CREATE INDEX IF NOT EXISTS idx_users_username ON users(username)');
      
      // Admin kullanıcısını ekle (eğer yoksa)
      try {
        await db.insert('users', {
          'username': 'admin',
          'password': '202cb962ac59075b964b07152d234b70', // MD5 hash of "123"
          'role': 'admin',
        });
      } catch (_) {
        // Kullanıcı zaten varsa hata verme
      }
    }

    if (oldVersion < 8) {
      // Kullanıcılar tablosuna allowed_menus sütunu ekle
      // Önce sütunun var olup olmadığını kontrol et
      try {
        // SQLite'da sütunun varlığını kontrol etmek için PRAGMA table_info kullan
        final tableInfo = await db.rawQuery('PRAGMA table_info(users)');
        final columnExists = tableInfo.any((column) => column['name'] == 'allowed_menus');
        
        if (!columnExists) {
          await db.execute('ALTER TABLE users ADD COLUMN allowed_menus TEXT');
        }
      } catch (e) {
        // Hata durumunda logla ama devam et
        print('Warning: Could not add allowed_menus column: $e');
        // Yine de sütunu eklemeyi dene (SQLite bazen hata verir ama sütun zaten varsa sorun olmaz)
        try {
          await db.execute('ALTER TABLE users ADD COLUMN allowed_menus TEXT');
        } catch (_) {
          // İkinci denemede de hata verirse, sütun muhtemelen zaten var
        }
      }
    }

    if (oldVersion < 9) {
      // Hatırlatmalar tablosunu ekle
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS reminders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            type TEXT NOT NULL,
            location TEXT NOT NULL,
            record_date TEXT NOT NULL,
            reminder_date TEXT NOT NULL,
            description TEXT,
            is_completed INTEGER DEFAULT 0,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        
        // İndeksler
        await db.execute('CREATE INDEX IF NOT EXISTS idx_reminders_date ON reminders(reminder_date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_reminders_completed ON reminders(is_completed)');
      } catch (e) {
        // Hata durumunda logla ama devam et
        print('Warning: Could not create reminders table: $e');
      }
    }

    if (oldVersion < 10) {
      // Personnel tablosundaki NULL account_no ve iban değerlerini doldur
      try {
        // Önce mevcut NULL kayıtları kontrol et ve güncelle
        final nullRecords = await db.rawQuery(
          'SELECT id FROM personnel WHERE account_no IS NULL OR iban IS NULL'
        );
        
        int counter = 1001001;
        for (var record in nullRecords) {
          final id = record['id'] as int;
          await db.update(
            'personnel',
            {
              'account_no': '1001${counter.toString().padLeft(4, '0')}',
              'iban': 'TR330006100519786457841${(300 + id).toString().padLeft(3, '0')}',
            },
            where: 'id = ?',
            whereArgs: [id],
          );
          counter++;
        }
      } catch (e) {
        // Hata durumunda logla ama devam et
        print('Warning: Could not update NULL account_no/iban values: $e');
      }
    }

    if (oldVersion < 11) {
      // Çek ve Senet tablolarına direction kolonu ekle
      try {
        await db.execute('ALTER TABLE checks ADD COLUMN direction TEXT DEFAULT "Alınacak"');
        await db.execute('ALTER TABLE promissory_notes ADD COLUMN direction TEXT DEFAULT "Alınacak"');
      } catch (e) {
        // Hata durumunda logla ama devam et
        print('Warning: Could not add direction column: $e');
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Departmanlar Tablosu
    await db.execute('''
      CREATE TABLE departments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        color_code TEXT,
        books_count INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Personel Tablosu
    await db.execute('''
      CREATE TABLE personnel (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        surname TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT NOT NULL,
      tc_no TEXT,
        department_id INTEGER,
        department_name TEXT,
        start_date TEXT,
        birth_date TEXT,
        is_active INTEGER DEFAULT 1,
        salary REAL,
        address TEXT,
        image_url TEXT,
        account_no TEXT NOT NULL,
        iban TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (department_id) REFERENCES departments (id)
      )
    ''');

    // Üyeler Tablosu
    await db.execute('''
      CREATE TABLE members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        member_no TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        surname TEXT NOT NULL,
        tc_no TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        address TEXT,
        birth_date TEXT,
        gender TEXT,
        member_type TEXT NOT NULL,
        registration_date TEXT NOT NULL,
        expiry_date TEXT,
        is_active INTEGER DEFAULT 1,
        image_url TEXT,
        notes TEXT,
        borrowed_books_count INTEGER DEFAULT 0,
        total_borrowed_books INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Yazarlar Tablosu
    await db.execute('''
      CREATE TABLE authors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        surname TEXT NOT NULL,
        biography TEXT,
        birth_date TEXT,
        death_date TEXT,
        nationality TEXT,
        image_url TEXT,
        books_count INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Kitap Türleri Tablosu
    await db.execute('''
      CREATE TABLE book_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        color_code TEXT,
        books_count INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Firmalar Tablosu
    await db.execute('''
      CREATE TABLE companies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        tax_number TEXT,
        tax_office TEXT,
        phone TEXT,
        email TEXT,
        address TEXT,
        city TEXT,
        country TEXT,
        website TEXT,
        contact_person TEXT,
        contact_phone TEXT,
        contact_email TEXT,
        company_type TEXT NOT NULL,
        registration_date TEXT,
        is_active INTEGER DEFAULT 1,
        notes TEXT,
        books_count INTEGER DEFAULT 0,
        image_url TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Kitaplar Tablosu
    await db.execute('''
      CREATE TABLE books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        isbn TEXT NOT NULL,
        title TEXT NOT NULL,
        subtitle TEXT,
        author_id INTEGER,
        author_name TEXT,
        category_id INTEGER,
        category_name TEXT,
        publisher_id INTEGER,
        publisher_name TEXT,
        publication_year INTEGER,
        page_count INTEGER,
        language TEXT,
        description TEXT,
        cover_image_url TEXT,
        total_copies INTEGER DEFAULT 1,
        available_copies INTEGER DEFAULT 1,
        borrowed_copies INTEGER DEFAULT 0,
        location TEXT,
        added_date TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (author_id) REFERENCES authors (id),
        FOREIGN KEY (category_id) REFERENCES book_categories (id),
        FOREIGN KEY (publisher_id) REFERENCES companies (id)
      )
    ''');

    // Emanetler Tablosu
    await db.execute('''
      CREATE TABLE escrows (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        escrow_no TEXT NOT NULL UNIQUE,
        book_id INTEGER NOT NULL,
        book_title TEXT NOT NULL,
        book_isbn TEXT,
        book_cover_url TEXT,
        member_id INTEGER NOT NULL,
        member_name TEXT NOT NULL,
        member_no TEXT NOT NULL,
        borrow_date TEXT NOT NULL,
        due_date TEXT NOT NULL,
        return_date TEXT,
        status TEXT NOT NULL,
        notes TEXT,
        personnel_id INTEGER,
        personnel_name TEXT,
        fine_amount REAL,
        fine_reason TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (book_id) REFERENCES books (id),
        FOREIGN KEY (member_id) REFERENCES members (id),
        FOREIGN KEY (personnel_id) REFERENCES personnel (id)
      )
    ''');

    // Gelirler Tablosu
    await db.execute('''
      CREATE TABLE incomes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        income_no TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        description TEXT,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        income_date TEXT NOT NULL,
        payer_name TEXT,
        payer_phone TEXT,
        payer_email TEXT,
        payment_method TEXT,
        reference_no TEXT,
        notes TEXT,
        related_member_id INTEGER,
        related_escrow_id INTEGER,
        created_by TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (related_member_id) REFERENCES members (id),
        FOREIGN KEY (related_escrow_id) REFERENCES escrows (id)
      )
    ''');

    // Giderler Tablosu
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        expense_no TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        description TEXT,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        expense_date TEXT NOT NULL,
        payee_name TEXT,
        payee_phone TEXT,
        payee_email TEXT,
        payment_method TEXT,
        reference_no TEXT,
        invoice_no TEXT,
        notes TEXT,
        related_company_id INTEGER,
        created_by TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (related_company_id) REFERENCES companies (id)
      )
    ''');

    // Çekler Tablosu
    await db.execute('''
      CREATE TABLE checks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        check_no TEXT NOT NULL UNIQUE,
        bank_name TEXT NOT NULL,
        account_no TEXT NOT NULL,
        iban TEXT,
        check_number TEXT NOT NULL,
        amount REAL NOT NULL,
        issue_date TEXT NOT NULL,
        due_date TEXT NOT NULL,
        drawer_name TEXT,
        drawer_phone TEXT,
        drawer_email TEXT,
        status TEXT NOT NULL,
        collection_date TEXT,
        collection_method TEXT,
        notes TEXT,
        related_income_id INTEGER,
        related_expense_id INTEGER,
        created_by TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (related_income_id) REFERENCES incomes (id),
        FOREIGN KEY (related_expense_id) REFERENCES expenses (id)
      )
    ''');

    // Senetler Tablosu
    await db.execute('''
      CREATE TABLE promissory_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        note_no TEXT NOT NULL UNIQUE,
        debtor_name TEXT NOT NULL,
        debtor_phone TEXT,
        debtor_email TEXT,
        debtor_address TEXT,
        debtor_tc_no TEXT,
        amount REAL NOT NULL,
        issue_date TEXT NOT NULL,
        due_date TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL,
        payment_date TEXT,
        payment_method TEXT,
        payment_reference TEXT,
        notes TEXT,
        related_income_id INTEGER,
        related_expense_id INTEGER,
        created_by TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (related_income_id) REFERENCES incomes (id),
        FOREIGN KEY (related_expense_id) REFERENCES expenses (id)
      )
    ''');

    // Kitap Satışları Tablosu
    await db.execute('''
      CREATE TABLE book_sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_no TEXT NOT NULL UNIQUE,
        book_id INTEGER NOT NULL,
        book_title TEXT NOT NULL,
        book_isbn TEXT,
        book_author TEXT,
        quantity INTEGER NOT NULL DEFAULT 1,
        unit_price REAL NOT NULL,
        total_amount REAL NOT NULL,
        discount REAL DEFAULT 0,
        final_amount REAL NOT NULL,
        customer_name TEXT,
          customer_phone TEXT,
          customer_email TEXT,
          customer_address TEXT,
          member_id INTEGER,
          sale_date TEXT NOT NULL,
          payment_method TEXT,
          notes TEXT,
          created_by TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (book_id) REFERENCES books (id),
          FOREIGN KEY (member_id) REFERENCES members (id)
        )
      ''');

    // Kullanıcılar Tablosu
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        allowed_menus TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Hatırlatmalar Tablosu
    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        location TEXT NOT NULL,
        record_date TEXT NOT NULL,
        reminder_date TEXT NOT NULL,
        description TEXT,
        is_completed INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // İndeksler
    await db.execute('CREATE INDEX idx_personnel_department ON personnel(department_id)');
    await db.execute('CREATE INDEX idx_books_author ON books(author_id)');
    await db.execute('CREATE INDEX idx_books_category ON books(category_id)');
    await db.execute('CREATE INDEX idx_escrows_book ON escrows(book_id)');
    await db.execute('CREATE INDEX idx_escrows_member ON escrows(member_id)');
    await db.execute('CREATE INDEX idx_escrows_status ON escrows(status)');
    await db.execute('CREATE INDEX idx_incomes_category ON incomes(category)');
    await db.execute('CREATE INDEX idx_incomes_date ON incomes(income_date)');
    await db.execute('CREATE INDEX idx_expenses_category ON expenses(category)');
    await db.execute('CREATE INDEX idx_expenses_date ON expenses(expense_date)');
    await db.execute('CREATE INDEX idx_checks_status ON checks(status)');
    await db.execute('CREATE INDEX idx_checks_due_date ON checks(due_date)');
    await db.execute('CREATE INDEX idx_promissory_notes_status ON promissory_notes(status)');
    await db.execute('CREATE INDEX idx_promissory_notes_due_date ON promissory_notes(due_date)');
    await db.execute('CREATE INDEX idx_book_sales_book ON book_sales(book_id)');
    await db.execute('CREATE INDEX idx_book_sales_date ON book_sales(sale_date)');
    await db.execute('CREATE INDEX idx_users_username ON users(username)');
    await db.execute('CREATE INDEX idx_reminders_date ON reminders(reminder_date)');
    await db.execute('CREATE INDEX idx_reminders_completed ON reminders(is_completed)');

    // Başlangıç verilerini ekle
    await _insertInitialData(db);
  }

  Future<void> _insertInitialData(Database db) async {
    // Departmanları ekle
    await db.insert('departments', {
      'name': 'İnsan Kaynakları',
      'description': 'Personel yönetimi ve işe alım süreçleri',
      'color_code': '#FF6B6B',
      'books_count': 0,
    });
    
    await db.insert('departments', {
      'name': 'Muhasebe',
      'description': 'Mali işler ve muhasebe kayıtları',
      'color_code': '#4ECDC4',
      'books_count': 0,
    });
    
    await db.insert('departments', {
      'name': 'Kütüphane Hizmetleri',
      'description': 'Kitap ödünç verme ve kütüphane işlemleri',
      'color_code': '#45B7D1',
      'books_count': 0,
    });
    
    await db.insert('departments', {
      'name': 'Bilgi İşlem',
      'description': 'Sistem yönetimi ve teknik destek',
      'color_code': '#96CEB4',
      'books_count': 0,
    });
    
    await db.insert('departments', {
      'name': 'Satın Alma',
      'description': 'Kitap ve malzeme satın alma işlemleri',
      'color_code': '#FFEAA7',
      'books_count': 0,
    });

    // Personel verilerini ekle
    // Önce departman ID'lerini al
    final departments = await db.query('departments');
    
    int getDeptId(String name) {
      return departments.firstWhere((d) => d['name'] == name)['id'] as int;
    }
    
    await db.insert('personnel', {
      'name': 'Ahmet',
      'surname': 'Yılmaz',
      'phone': '0532 123 4567',
      'email': 'ahmet.yilmaz@kutuphane.gov.tr',
      'tc_no': '12345678901',
      'department_id': getDeptId('İnsan Kaynakları'),
      'department_name': 'İnsan Kaynakları',
      'start_date': DateTime(2020, 1, 15).toIso8601String(),
      'is_active': 1,
      'salary': 25000.0,
      'address': 'Ankara, Çankaya',
      'account_no': '1001001',
      'iban': 'TR330006100519786457841326',
    });
    
    await db.insert('personnel', {
      'name': 'Ayşe',
      'surname': 'Demir',
      'phone': '0533 234 5678',
      'email': 'ayse.demir@kutuphane.gov.tr',
      'tc_no': '23456789012',
      'department_id': getDeptId('Muhasebe'),
      'department_name': 'Muhasebe',
      'start_date': DateTime(2019, 3, 1).toIso8601String(),
      'is_active': 1,
      'salary': 28000.0,
      'address': 'İstanbul, Kadıköy',
      'account_no': '1001002',
      'iban': 'TR330006100519786457841327',
    });
    
    await db.insert('personnel', {
      'name': 'Mehmet',
      'surname': 'Kaya',
      'phone': '0534 345 6789',
      'email': 'mehmet.kaya@kutuphane.gov.tr',
      'tc_no': '34567890123',
      'department_id': getDeptId('Kütüphane Hizmetleri'),
      'department_name': 'Kütüphane Hizmetleri',
      'start_date': DateTime(2021, 6, 10).toIso8601String(),
      'is_active': 1,
      'salary': 22000.0,
      'address': 'İzmir, Konak',
      'account_no': '1001003',
      'iban': 'TR330006100519786457841328',
    });
    
    await db.insert('personnel', {
      'name': 'Zeynep',
      'surname': 'Şahin',
      'phone': '0535 456 7890',
      'email': 'zeynep.sahin@kutuphane.gov.tr',
      'tc_no': '45678901234',
      'department_id': getDeptId('Kütüphane Hizmetleri'),
      'department_name': 'Kütüphane Hizmetleri',
      'start_date': DateTime(2022, 2, 20).toIso8601String(),
      'is_active': 1,
      'salary': 21000.0,
      'address': 'Ankara, Yenimahalle',
      'account_no': '1001004',
      'iban': 'TR330006100519786457841329',
    });
    
    await db.insert('personnel', {
      'name': 'Can',
      'surname': 'Özkan',
      'phone': '0536 567 8901',
      'email': 'can.ozkan@kutuphane.gov.tr',
      'tc_no': '56789012345',
      'department_id': getDeptId('Bilgi İşlem'),
      'department_name': 'Bilgi İşlem',
      'start_date': DateTime(2020, 9, 5).toIso8601String(),
      'is_active': 1,
      'salary': 30000.0,
      'address': 'İstanbul, Beşiktaş',
      'account_no': '1001005',
      'iban': 'TR330006100519786457841330',
    });
    
    await db.insert('personnel', {
      'name': 'Elif',
      'surname': 'Arslan',
      'phone': '0537 678 9012',
      'email': 'elif.arslan@kutuphane.gov.tr',
      'tc_no': '67890123456',
      'department_id': getDeptId('Satın Alma'),
      'department_name': 'Satın Alma',
      'start_date': DateTime(2021, 11, 15).toIso8601String(),
      'is_active': 1,
      'salary': 24000.0,
      'address': 'Bursa, Nilüfer',
      'account_no': '1001006',
      'iban': 'TR330006100519786457841331',
    });
    
    await db.insert('personnel', {
      'name': 'Burak',
      'surname': 'Çelik',
      'phone': '0538 789 0123',
      'email': 'burak.celik@kutuphane.gov.tr',
      'tc_no': '78901234567',
      'department_id': getDeptId('Muhasebe'),
      'department_name': 'Muhasebe',
      'start_date': DateTime(2023, 1, 10).toIso8601String(),
      'is_active': 1,
      'salary': 23000.0,
      'address': 'Ankara, Mamak',
      'account_no': '1001007',
      'iban': 'TR330006100519786457841332',
    });
    
    await db.insert('personnel', {
      'name': 'Selin',
      'surname': 'Yıldız',
      'phone': '0539 890 1234',
      'email': 'selin.yildiz@kutuphane.gov.tr',
      'tc_no': '89012345678',
      'department_id': getDeptId('İnsan Kaynakları'),
      'department_name': 'İnsan Kaynakları',
      'start_date': DateTime(2022, 7, 1).toIso8601String(),
      'is_active': 1,
      'salary': 26000.0,
      'address': 'İstanbul, Şişli',
      'account_no': '1001008',
      'iban': 'TR330006100519786457841333',
    });

    // Admin kullanıcısını ekle (şifre: 123, MD5 hash: 202cb962ac59075b964b07152d234b70)
    await db.insert('users', {
      'username': 'admin',
      'password': '202cb962ac59075b964b07152d234b70', // MD5 hash of "123"
      'role': 'admin',
    });
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Veritabanı yolunu al
  Future<String> getDatabasePath() async {
    String directory;
    if (Platform.isWindows) {
      directory = path.join(Platform.environment['APPDATA'] ?? '', 'KutuphaneMasaustu');
    } else if (Platform.isLinux) {
      directory = path.join(Platform.environment['HOME'] ?? '', '.kutuphane_masaustu');
    } else if (Platform.isMacOS) {
      directory = path.join(Platform.environment['HOME'] ?? '', 'Library', 'Application Support', 'KutuphaneMasaustu');
    } else {
      directory = path.current;
    }
    return path.join(directory, 'kutuphane.db');
  }
}

