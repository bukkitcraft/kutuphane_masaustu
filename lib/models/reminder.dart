class Reminder {
  final int? id;
  final String title;
  final String type; // Tür (Toplantı, Görev, Ödeme, vb.)
  final String location; // Hatırlatma yeri
  final DateTime recordDate; // Kayıt tarihi
  final DateTime reminderDate; // Hatırlatma tarihi (yıl, ay, gün, saat, dakika)
  final String? description;
  final bool isCompleted;
  final DateTime? createdAt;

  Reminder({
    this.id,
    required this.title,
    required this.type,
    required this.location,
    required this.recordDate,
    required this.reminderDate,
    this.description,
    this.isCompleted = false,
    this.createdAt,
  });

  Reminder copyWith({
    int? id,
    String? title,
    String? type,
    String? location,
    DateTime? recordDate,
    DateTime? reminderDate,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      location: location ?? this.location,
      recordDate: recordDate ?? this.recordDate,
      reminderDate: reminderDate ?? this.reminderDate,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get formattedRecordDate {
    return '${recordDate.day.toString().padLeft(2, '0')}.${recordDate.month.toString().padLeft(2, '0')}.${recordDate.year}';
  }

  String get formattedReminderDate {
    return '${reminderDate.day.toString().padLeft(2, '0')}.${reminderDate.month.toString().padLeft(2, '0')}.${reminderDate.year} ${reminderDate.hour.toString().padLeft(2, '0')}:${reminderDate.minute.toString().padLeft(2, '0')}';
  }

  bool get isOverdue {
    return DateTime.now().isAfter(reminderDate) && !isCompleted;
  }

  bool get isDue {
    final now = DateTime.now();
    final diff = reminderDate.difference(now);
    return diff.inMinutes >= 0 && diff.inMinutes <= 60 && !isCompleted;
  }
}

