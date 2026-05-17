import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../models/member.dart';
import '../models/escrow.dart';
import '../services/reminder_service.dart';
import '../services/escrow_service.dart';
import '../services/member_service.dart';
import 'dart:async';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final ReminderService _reminderService = ReminderService();
  final EscrowService _escrowService = EscrowService();
  final MemberService _memberService = MemberService();
  List<Reminder> _reminders = [];
  List<Reminder> _filteredReminders = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Timer? _reminderCheckTimer;
  Timer? _refreshTimer;
  Timer? _escrowCheckTimer;

  @override
  void initState() {
    super.initState();
    _loadReminders();
    _startReminderChecker();
    _startAutoRefresh();
    _checkEscrowReminders();
    _startEscrowChecker();
  }

  @override
  void dispose() {
    _reminderCheckTimer?.cancel();
    _refreshTimer?.cancel();
    _escrowCheckTimer?.cancel();
    super.dispose();
  }

  void _startReminderChecker() {
    // Her dakika hatırlatmaları kontrol et
    _reminderCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkDueReminders();
    });
  }

  void _startAutoRefresh() {
    // Her 30 saniyede bir listeyi yenile
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadReminders();
      }
    });
  }

  void _startEscrowChecker() {
    // Her gün emanetleri kontrol et ve 3 gün kalanlar için hatırlatma oluştur
    _escrowCheckTimer = Timer.periodic(const Duration(hours: 24), (timer) {
      _checkEscrowReminders();
    });
  }

  Future<void> _checkEscrowReminders() async {
    try {
      final escrows = await _escrowService.getByStatus('Ödünçte');
      final allReminders = await _reminderService.getAll();
      
      for (final escrow in escrows) {
        final remainingDays = escrow.remainingDays;
        
        // 3 gün veya daha az kalan emanetler için hatırlatma kontrolü
        if (remainingDays > 0 && remainingDays <= 3) {
          // Bu emanet için zaten hatırlatma var mı kontrol et (daha spesifik kontrol)
          final existingReminder = allReminders.firstWhere(
            (r) => r.title.contains(escrow.bookTitle) && 
                   r.title.contains(escrow.memberName) &&
                   r.type == 'Emanet İade' &&
                   !r.isCompleted,
            orElse: () => Reminder(
              id: -1,
              title: '',
              type: '',
              location: '',
              recordDate: DateTime.now(),
              reminderDate: DateTime.now(),
            ),
          );
          
          // Eğer hatırlatma yoksa oluştur
          if (existingReminder.id == -1) {
            // Hatırlatma bugün oluşturulmalı
            final reminderDate = DateTime.now();
            String dayText = '';
            if (remainingDays == 1) {
              dayText = '1 gün kaldı';
            } else if (remainingDays == 2) {
              dayText = '2 gün kaldı';
            } else if (remainingDays == 3) {
              dayText = '3 gün kaldı';
            }
            
            final reminder = Reminder(
              title: 'Kitap İade Hatırlatması: ${escrow.bookTitle} - ${escrow.memberName}',
              type: 'Emanet İade',
              location: 'Emanet İşlemleri',
              recordDate: DateTime.now(),
              reminderDate: reminderDate,
              description: '${escrow.memberName} (${escrow.memberNo}) adlı üyenin "${escrow.bookTitle}" kitabı ${escrow.dueDate.day}.${escrow.dueDate.month}.${escrow.dueDate.year} tarihinde iade edilmesi gerekiyor. ($dayText)',
            );
            await _reminderService.insert(reminder);
          }
        }
      }
      
      // Hatırlatmaları yenile
      if (mounted) {
        _loadReminders();
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  Future<void> _checkDueReminders() async {
    try {
      final dueReminders = await _reminderService.getDueReminders();
      if (dueReminders.isNotEmpty && mounted) {
        for (final reminder in dueReminders) {
          _showReminderDialog(reminder);
        }
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  void _showReminderDialog(Reminder reminder) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.notifications_active_rounded, color: Colors.orange[700], size: 32),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Hatırlatma!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reminder.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Zaman: ${reminder.formattedReminderDate}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            if (reminder.description != null && reminder.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                reminder.description!,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _reminderService.markAsCompleted(reminder.id!);
              _loadReminders();
            },
            child: const Text('Tamamlandı'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }


  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    try {
      final reminders = await _reminderService.getAll();
      setState(() {
        _reminders = reminders;
        _applyFilter();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hatırlatmalar yüklenirken hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredReminders = _reminders;
    } else {
      _filteredReminders = _reminders.where((reminder) {
        return reminder.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (reminder.description != null && reminder.description!.toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_rounded,
                    color: Color(0xFFFF9800),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hatırlatmalar',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E2723),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Önemli tarihleri ve görevleri takip edin',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditReminderDialog(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Yeni Hatırlatma'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilter();
                });
              },
              decoration: InputDecoration(
                hintText: 'Hatırlatma başlığı veya açıklama ile ara...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
              ),
            ),
          ),

          // Reminders List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredReminders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off_rounded,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Henüz hatırlatma eklenmemiş'
                                  : 'Arama sonucu bulunamadı',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadReminders,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredReminders.length,
                          itemBuilder: (context, index) {
                            final reminder = _filteredReminders[index];
                            return _buildReminderCard(reminder);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    final isOverdue = reminder.isOverdue;
    final isDue = reminder.isDue;
    final isCompleted = reminder.isCompleted;

    Color cardColor = Colors.white;
    if (isCompleted) {
      cardColor = Colors.grey[100]!;
    } else if (isOverdue) {
      cardColor = Colors.red[50]!;
    } else if (isDue) {
      cardColor = Colors.orange[50]!;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardColor,
      child: InkWell(
        onTap: () => _showReminderDetailDialog(reminder),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.grey[300]
                      : isOverdue
                          ? Colors.red[100]
                          : isDue
                              ? Colors.orange[100]
                              : Colors.blue[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : isOverdue
                          ? Icons.error_rounded
                          : isDue
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_rounded,
                  color: isCompleted
                      ? Colors.grey[600]
                      : isOverdue
                          ? Colors.red[700]
                          : isDue
                              ? Colors.orange[700]
                              : Colors.blue[700],
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            reminder.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: isCompleted ? Colors.grey : Colors.black87,
                            ),
                          ),
                        ),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Tamamlandı',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildInfoItem(
                        Icons.calendar_today_rounded, reminder.formattedRecordDate),
                    const SizedBox(height: 4),
                    _buildInfoItem(
                        Icons.access_time_rounded, reminder.formattedReminderDate,
                        isImportant: true),
                  ],
                ),
              ),
              // Actions
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      isCompleted ? Icons.undo_rounded : Icons.check_rounded,
                      color: isCompleted ? Colors.blue : Colors.green,
                    ),
                    onPressed: () {
                      if (isCompleted) {
                        _reminderService.update(reminder.copyWith(isCompleted: false));
                      } else {
                        _reminderService.markAsCompleted(reminder.id!);
                      }
                      _loadReminders();
                    },
                    tooltip: isCompleted ? 'Geri Al' : 'Tamamlandı İşaretle',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_rounded, color: Colors.red),
                    onPressed: () => _showDeleteDialog(reminder),
                    tooltip: 'Sil',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, {bool isImportant = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isImportant ? Colors.orange[700] : Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isImportant ? Colors.orange[700] : Colors.grey[700],
              fontWeight: isImportant ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showReminderDetailDialog(Reminder reminder) async {
    Member? relatedMember;
    Escrow? relatedEscrow;
    
    // Eğer hatırlatma "Emanet İade" tipindeyse, üye bilgilerini bul
    if (reminder.type == 'Emanet İade' && reminder.description != null) {
      try {
        // Description'dan üye numarasını çıkar
        // Format: "Mustafa Yılmaz (UYE-2024-0001) adlı üyenin..."
        final description = reminder.description!;
        final memberNoMatch = RegExp(r'\(([A-Z0-9-]+)\)').firstMatch(description);
        if (memberNoMatch != null) {
          final memberNo = memberNoMatch.group(1);
          if (memberNo != null) {
            relatedMember = await _memberService.getByMemberNo(memberNo);
          }
        }
        
        // Eğer üye numarası bulunamazsa, title'dan üye adını çıkarıp arama yap
        if (relatedMember == null && reminder.title.contains(' - ')) {
          final parts = reminder.title.split(' - ');
          if (parts.length >= 2) {
            final memberName = parts[1].trim();
            final allMembers = await _memberService.getAll();
            // İsim ve soyisim ile eşleştir
            final nameParts = memberName.split(' ');
            if (nameParts.length >= 2) {
              try {
                relatedMember = allMembers.firstWhere(
                  (m) => m.name.toLowerCase() == nameParts[0].toLowerCase() &&
                         m.surname.toLowerCase() == nameParts[1].toLowerCase(),
                );
              } catch (_) {
                // Eşleşme bulunamadı
              }
            }
          }
        }
        
        // Emanet bilgisini bul
        if (relatedMember != null) {
          final escrows = await _escrowService.getByMember(relatedMember.id!);
          // Title'dan kitap adını çıkar
          String? bookTitle;
          if (reminder.title.contains('Kitap İade Hatırlatması: ')) {
            final titlePart = reminder.title.split('Kitap İade Hatırlatması: ')[1];
            if (titlePart.contains(' - ')) {
              bookTitle = titlePart.split(' - ')[0].trim();
            }
          }
          
          // En son ödünç alınan ve iade edilmemiş olanı bul
          if (bookTitle != null) {
            try {
              relatedEscrow = escrows.firstWhere(
                (e) => e.status == 'Ödünçte' && e.bookTitle == bookTitle,
              );
            } catch (_) {
              // Eşleşen emanet bulunamadı, en son ödünç alınanı al
              if (escrows.isNotEmpty) {
                relatedEscrow = escrows.firstWhere(
                  (e) => e.status == 'Ödünçte',
                  orElse: () => escrows.first,
                );
              }
            }
          } else if (escrows.isNotEmpty) {
            // Kitap adı bulunamazsa, en son ödünç alınanı al
            relatedEscrow = escrows.firstWhere(
              (e) => e.status == 'Ödünçte',
              orElse: () => escrows.first,
            );
          }
        }
      } catch (e) {
        // Hata durumunda sessizce devam et
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            maxWidth: 600,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF9800),
                      const Color(0xFFFF9800).withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reminder.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            reminder.formattedReminderDate,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hatırlatma Bilgileri
                      const Text(
                        'Hatırlatma Bilgileri',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E2723),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.category_outlined,
                        'Tür',
                        reminder.type,
                      ),
                      _buildDetailRow(
                        Icons.location_on_outlined,
                        'Konum',
                        reminder.location,
                      ),
                      _buildDetailRow(
                        Icons.calendar_today_outlined,
                        'Kayıt Tarihi',
                        reminder.formattedRecordDate,
                      ),
                      if (reminder.description != null && reminder.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          Icons.description_outlined,
                          'Açıklama',
                          reminder.description!,
                        ),
                      ],
                      
                      // Üye Bilgileri (Emanet İade hatırlatmaları için)
                      if (reminder.type == 'Emanet İade' && relatedMember != null) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text(
                          'Üye Bilgileri',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E2723),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF8F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD7CCC8)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8D6E63).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        relatedMember.name[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF8D6E63),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${relatedMember.name} ${relatedMember.surname}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF3E2723),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Üye No: ${relatedMember.memberNo}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildDetailRow(
                                Icons.phone_outlined,
                                'Telefon',
                                relatedMember.phone,
                              ),
                              if (relatedMember.email != null && relatedMember.email!.isNotEmpty)
                                _buildDetailRow(
                                  Icons.email_outlined,
                                  'E-posta',
                                  relatedMember.email!,
                                ),
                              if (relatedMember.address != null && relatedMember.address!.isNotEmpty)
                                _buildDetailRow(
                                  Icons.location_on_outlined,
                                  'Adres',
                                  relatedMember.address!,
                                ),
                              if (relatedEscrow != null) ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 12),
                                const Text(
                                  'Emanet Bilgileri',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF5D4037),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildDetailRow(
                                  Icons.book_outlined,
                                  'Kitap',
                                  relatedEscrow.bookTitle,
                                ),
                                _buildDetailRow(
                                  Icons.calendar_today_outlined,
                                  'Ödünç Tarihi',
                                  relatedEscrow.formattedBorrowDate,
                                ),
                                _buildDetailRow(
                                  Icons.event_outlined,
                                  'İade Tarihi',
                                  relatedEscrow.formattedDueDate,
                                ),
                                if (relatedEscrow.remainingDays > 0)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: relatedEscrow.remainingDays <= 3
                                          ? Colors.orange.withValues(alpha: 0.1)
                                          : Colors.green.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: relatedEscrow.remainingDays <= 3
                                            ? Colors.orange
                                            : Colors.green,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.timer_outlined,
                                          color: relatedEscrow.remainingDays <= 3
                                              ? Colors.orange
                                              : Colors.green,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${relatedEscrow.remainingDays} gün kaldı',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: relatedEscrow.remainingDays <= 3
                                                ? Colors.orange
                                                : Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddEditReminderDialog(reminder);
                        },
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Düzenle'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF9800),
                          side: const BorderSide(color: Color(0xFFFF9800)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9800),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Kapat'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFFFF9800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF3E2723),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEditReminderDialog([Reminder? reminder]) {
    final isEdit = reminder != null;
    final titleController = TextEditingController(text: reminder?.title ?? '');
    final descriptionController = TextEditingController(text: reminder?.description ?? '');
    
    // Tür ve yer kaldırıldı, varsayılan değerler kullanılacak
    String selectedType = reminder?.type ?? 'Genel';
    String selectedLocation = reminder?.location ?? '';
    
    DateTime recordDate = reminder?.recordDate ?? DateTime.now();
    DateTime reminderDate = reminder?.reminderDate ?? DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.notifications_rounded, color: Color(0xFFFF9800)),
              ),
              const SizedBox(width: 12),
              Text(
                isEdit ? 'Hatırlatma Düzenle' : 'Yeni Hatırlatma',
                style: const TextStyle(
                  color: Color(0xFF3E2723),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Başlık *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.title_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Kayıt Tarihi
                  ListTile(
                    title: const Text('Kayıt Tarihi'),
                    subtitle: Text(DateFormat('dd.MM.yyyy').format(recordDate)),
                    leading: const Icon(Icons.calendar_today_rounded),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: recordDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          locale: const Locale('tr', 'TR'),
                          builder: (context, child) {
                            return Localizations.override(
                              context: context,
                              locale: const Locale('tr', 'TR'),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setDialogState(() {
                            recordDate = picked;
                          });
                        }
                      },
                    ),
                  ),
                  // Hatırlatma Tarihi ve Saati
                  const SizedBox(height: 8),
                  const Text(
                    'Hatırlatma Tarihi ve Saati *',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: Text(DateFormat('dd.MM.yyyy').format(reminderDate)),
                          leading: const Icon(Icons.calendar_today_rounded),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_rounded),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: reminderDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                                locale: const Locale('tr', 'TR'),
                                builder: (context, child) {
                                  return Localizations.override(
                                    context: context,
                                    locale: const Locale('tr', 'TR'),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  reminderDate = DateTime(
                                    picked.year,
                                    picked.month,
                                    picked.day,
                                    reminderDate.hour,
                                    reminderDate.minute,
                                  );
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: Text('${reminderDate.hour.toString().padLeft(2, '0')}:${reminderDate.minute.toString().padLeft(2, '0')}'),
                          leading: const Icon(Icons.access_time_rounded),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_rounded),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(reminderDate),
                                builder: (context, child) {
                                  return Localizations.override(
                                    context: context,
                                    locale: const Locale('tr', 'TR'),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  reminderDate = DateTime(
                                    reminderDate.year,
                                    reminderDate.month,
                                    reminderDate.day,
                                    picked.hour,
                                    picked.minute,
                                  );
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Açıklama',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.description_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lütfen başlık girin'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final existingReminder = isEdit ? reminder : null;
                  final reminderToSave = Reminder(
                    id: existingReminder?.id,
                    title: titleController.text.trim(),
                    type: selectedType,
                    location: selectedLocation,
                    recordDate: recordDate,
                    reminderDate: reminderDate,
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    isCompleted: existingReminder?.isCompleted ?? false,
                    createdAt: existingReminder?.createdAt ?? DateTime.now(),
                  );

                  if (isEdit) {
                    await _reminderService.update(reminderToSave);
                  } else {
                    await _reminderService.insert(reminderToSave);
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    _loadReminders();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
              ),
              child: Text(isEdit ? 'Güncelle' : 'Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(Reminder reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hatırlatmayı Sil'),
        content: Text('${reminder.title} hatırlatmasını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _reminderService.delete(reminder.id!);
              if (mounted) {
                Navigator.pop(context);
                _loadReminders();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

