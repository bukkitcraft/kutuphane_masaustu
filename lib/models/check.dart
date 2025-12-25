class Check {
  final int? id;
  final String checkNo;
  final String bankName;
  final String accountNo;
  final String? iban; // IBAN bilgisi
  final String checkNumber; // Çek numarası
  final double amount;
  final DateTime issueDate;
  final DateTime dueDate;
  final String? drawerName; // Keşideci adı
  final String? drawerPhone;
  final String? drawerEmail;
  final String status; // Beklemede, Tahsil Edildi, İptal, Protesto
  final String direction; // Alınacak, Verilecek
  final DateTime? collectionDate;
  final String? collectionMethod;
  final String? notes;
  final int? relatedIncomeId;
  final int? relatedExpenseId;
  final String? createdBy;

  Check({
    this.id,
    required this.checkNo,
    required this.bankName,
    required this.accountNo,
    this.iban,
    required this.checkNumber,
    required this.amount,
    required this.issueDate,
    required this.dueDate,
    this.drawerName,
    this.drawerPhone,
    this.drawerEmail,
    required this.status,
    this.direction = 'Alınacak',
    this.collectionDate,
    this.collectionMethod,
    this.notes,
    this.relatedIncomeId,
    this.relatedExpenseId,
    this.createdBy,
  });

  Check copyWith({
    int? id,
    String? checkNo,
    String? bankName,
    String? accountNo,
    String? iban,
    String? checkNumber,
    double? amount,
    DateTime? issueDate,
    DateTime? dueDate,
    String? drawerName,
    String? drawerPhone,
    String? drawerEmail,
    String? status,
    String? direction,
    DateTime? collectionDate,
    String? collectionMethod,
    String? notes,
    int? relatedIncomeId,
    int? relatedExpenseId,
    String? createdBy,
  }) {
    return Check(
      id: id ?? this.id,
      checkNo: checkNo ?? this.checkNo,
      bankName: bankName ?? this.bankName,
      accountNo: accountNo ?? this.accountNo,
      iban: iban ?? this.iban,
      checkNumber: checkNumber ?? this.checkNumber,
      amount: amount ?? this.amount,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      drawerName: drawerName ?? this.drawerName,
      drawerPhone: drawerPhone ?? this.drawerPhone,
      drawerEmail: drawerEmail ?? this.drawerEmail,
      status: status ?? this.status,
      direction: direction ?? this.direction,
      collectionDate: collectionDate ?? this.collectionDate,
      collectionMethod: collectionMethod ?? this.collectionMethod,
      notes: notes ?? this.notes,
      relatedIncomeId: relatedIncomeId ?? this.relatedIncomeId,
      relatedExpenseId: relatedExpenseId ?? this.relatedExpenseId,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  String get formattedIssueDate {
    return '${issueDate.day.toString().padLeft(2, '0')}.${issueDate.month.toString().padLeft(2, '0')}.${issueDate.year}';
  }

  String get formattedDueDate {
    return '${dueDate.day.toString().padLeft(2, '0')}.${dueDate.month.toString().padLeft(2, '0')}.${dueDate.year}';
  }

  String get formattedAmount {
    return '₺${amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  int get daysUntilDue {
    final now = DateTime.now();
    if (dueDate.isBefore(now)) return 0;
    return dueDate.difference(now).inDays;
  }

  bool get isOverdue => dueDate.isBefore(DateTime.now()) && status == 'Beklemede';
}

