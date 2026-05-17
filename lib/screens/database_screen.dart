import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../database/database_helper.dart';

class DatabaseScreen extends StatefulWidget {
  const DatabaseScreen({super.key});

  @override
  State<DatabaseScreen> createState() => _DatabaseScreenState();
}

class _DatabaseScreenState extends State<DatabaseScreen> {
  bool _isBackingUp = false;
  bool _isRestoring = false;

  Future<String> _getDownloadsPath() async {
    String downloadsPath;
    
    if (Platform.isWindows) {
      // Windows'ta Downloads klasörünü bul
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null && userProfile.isNotEmpty) {
        downloadsPath = path.join(userProfile, 'Downloads');
      } else {
        // Alternatif yol
        final homeDrive = Platform.environment['HOMEDRIVE'];
        final homePath = Platform.environment['HOMEPATH'];
        if (homeDrive != null && homePath != null) {
          downloadsPath = path.join(homeDrive, homePath, 'Downloads');
        } else {
          throw Exception('Downloads klasörü bulunamadı');
        }
      }
    } else if (Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        downloadsPath = path.join(home, 'Downloads');
      } else {
        throw Exception('Downloads klasörü bulunamadı');
      }
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        downloadsPath = path.join(home, 'Downloads');
      } else {
        throw Exception('Downloads klasörü bulunamadı');
      }
    } else {
      downloadsPath = path.current;
    }

    // Downloads klasörünün varlığını kontrol et, yoksa oluştur
    final downloadsDir = Directory(downloadsPath);
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    return downloadsPath;
  }

  Future<void> _backupDatabase() async {
    setState(() => _isBackingUp = true);

    try {
      // Mevcut veritabanı yolunu al
      final dbHelper = DatabaseHelper.instance;
      final dbPath = await dbHelper.getDatabasePath();
      final sourceFile = File(dbPath);

      if (!await sourceFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Veritabanı dosyası bulunamadı'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isBackingUp = false);
        return;
      }

      // Downloads klasörünü al
      final downloadsPath = await _getDownloadsPath();

      // Yedek klasörü oluştur
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final backupFolderName = 'Kutuphane_Yedek_$timestamp';
      final backupFolderPath = path.join(downloadsPath, backupFolderName);
      final backupFolder = Directory(backupFolderPath);
      
      if (!await backupFolder.exists()) {
        await backupFolder.create(recursive: true);
      }

      // Yedek dosya adını oluştur
      final backupFileName = 'kutuphane.db';
      final backupPath = path.join(backupFolderPath, backupFileName);

      // Dosyayı kopyala
      await sourceFile.copy(backupPath);

      if (mounted) {
        // Başarı dialogu göster
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Veritabanı Yedeklendi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E2723),
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Veritabanı yedeği başarıyla oluşturuldu.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFD7CCC8),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Yedek Konumu:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8D6E63),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        path.join('İndirilenler', backupFolderName, backupFileName),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF3E2723),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yedekleme hatası: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBackingUp = false);
      }
    }
  }

  Future<bool> _validateDatabaseStructure(File dbFile) async {
    try {
      // Geçici bir veritabanı bağlantısı oluştur
      final db = await databaseFactoryFfi.openDatabase(dbFile.path);

      // Gerekli tabloları kontrol et
      final requiredTables = [
        'books',
        'members',
        'personnel',
        'escrows',
        'authors',
        'book_categories',
        'departments',
        'companies',
        'incomes',
        'expenses',
        'checks',
        'promissory_notes',
        'book_sales',
        'users',
        'reminders',
      ];

      for (final tableName in requiredTables) {
        final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [tableName],
        );
        if (result.isEmpty) {
          await db.close();
          return false;
        }
      }

      await db.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _restoreDatabase() async {
    setState(() => _isRestoring = true);

    try {
      // Dosya seçiciyi aç
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
        dialogTitle: 'Veritabanı Yedeğini Seçin',
      );

      if (result == null || result.files.single.path == null) {
        setState(() => _isRestoring = false);
        return;
      }

      final selectedFile = File(result.files.single.path!);

      if (!await selectedFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Seçilen dosya bulunamadı'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isRestoring = false);
        return;
      }

      // Veritabanı yapısını doğrula
      final isValid = await _validateDatabaseStructure(selectedFile);

      if (!isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Seçilen dosya geçerli bir veritabanı yedeği değil. Gerekli tablolar bulunamadı.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        setState(() => _isRestoring = false);
        return;
      }

      // Onay dialogu göster
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Veritabanını Geri Yükle'),
          content: const Text(
            'Mevcut veritabanı silinecek ve seçilen yedek ile değiştirilecektir. '
            'Bu işlem geri alınamaz. Devam etmek istediğinize emin misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Evet, Geri Yükle'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        setState(() => _isRestoring = false);
        return;
      }

      // Mevcut veritabanını kapat
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.close();

      // Mevcut veritabanı dosyasını al
      final dbPath = await dbHelper.getDatabasePath();
      final currentDbFile = File(dbPath);

      // Mevcut veritabanını yedekle (güvenlik için)
      if (await currentDbFile.exists()) {
        final backupPath = '${dbPath}.backup_${DateTime.now().millisecondsSinceEpoch}';
        await currentDbFile.copy(backupPath);
      }

      // Eski veritabanını sil
      if (await currentDbFile.exists()) {
        await currentDbFile.delete();
      }

      // Yeni veritabanını kopyala
      await selectedFile.copy(dbPath);

      // Veritabanını yeniden başlat
      await dbHelper.database;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veritabanı başarıyla geri yüklendi. Lütfen uygulamayı yeniden başlatın.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Geri yükleme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxHeight < 700;
          final padding = isSmallScreen ? 16.0 : 32.0;
          final cardPadding = isSmallScreen ? 20.0 : 40.0;
          
          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.storage_rounded,
                        size: 32,
                        color: Color(0xFF6A1B9A),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Veritabanı Yönetimi',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 22 : 28,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF3E2723),
                            ),
                          ),
                          Text(
                            'Veritabanı yedekleme ve geri yükleme işlemleri',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: const Color(0xFF8D6E63),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 20 : 40),

                // Main Content
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.brown.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(cardPadding),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Backup Card
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.backup_rounded,
                                  size: isSmallScreen ? 48 : 64,
                                  color: const Color(0xFF4CAF50),
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 16),
                                Text(
                                  'Veritabanını Yedekle',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 18 : 22,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF3E2723),
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 6 : 8),
                                Text(
                                  'Mevcut veritabanınızın yedeğini bilgisayarınızın İndirilenler klasörüne kaydeder.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    color: const Color(0xFF8D6E63),
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 16 : 24),
                                ElevatedButton.icon(
                                  onPressed: _isBackingUp || _isRestoring
                                      ? null
                                      : _backupDatabase,
                                  icon: _isBackingUp
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.download_rounded),
                                  label: Text(_isBackingUp ? 'Yedekleniyor...' : 'Yedekle'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4CAF50),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 24 : 32,
                                      vertical: isSmallScreen ? 12 : 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 20 : 32),
                          // Restore Card
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.restore_rounded,
                                  size: isSmallScreen ? 48 : 64,
                                  color: const Color(0xFF2196F3),
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 16),
                                Text(
                                  'Veritabanını Geri Yükle',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 18 : 22,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF3E2723),
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 6 : 8),
                                Text(
                                  'Daha önce oluşturduğunuz bir yedeği seçerek veritabanınızı geri yükleyin. '
                                  'Mevcut veritabanı silinecek ve yedek ile değiştirilecektir.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    color: const Color(0xFF8D6E63),
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 6 : 8),
                                Container(
                                  padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.orange.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.orange,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Önemli: Geri yükleme işlemi öncesinde mutlaka yedek alın!',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 11 : 12,
                                            color: Colors.orange,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 16 : 24),
                                ElevatedButton.icon(
                                  onPressed: _isBackingUp || _isRestoring
                                      ? null
                                      : _restoreDatabase,
                                  icon: _isRestoring
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.upload_rounded),
                                  label: Text(_isRestoring ? 'Geri Yükleniyor...' : 'Geri Yükle'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2196F3),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 24 : 32,
                                      vertical: isSmallScreen ? 12 : 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

