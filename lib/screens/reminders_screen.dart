import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../services/reminder_service.dart';
import 'dart:async';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final ReminderService _reminderService = ReminderService();
  List<Reminder> _reminders = [];
  List<Reminder> _filteredReminders = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Timer? _reminderCheckTimer;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadReminders();
    _startReminderChecker();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _reminderCheckTimer?.cancel();
    _refreshTimer?.cancel();
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
        onTap: () => _showAddEditReminderDialog(reminder),
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

