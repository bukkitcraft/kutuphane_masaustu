class PromissoryNote {
  final int? id;
  final String noteNo;
  final String debtorName; // Borçlu adı
  final String? debtorPhone;
  final String? debtorEmail;
  final String? debtorAddress;
  final String? debtorTcNo;
  final double amount;
  final DateTime issueDate;
  final DateTime dueDate;
  final String? description;
  final String status; // Beklemede, Ödendi, İptal, Protesto
  final String direction; // Alınacak, Verilecek
  final DateTime? paymentDate;
  final String? paymentMethod;
  final String? paymentReference;
  final String? notes;
  final int? relatedIncomeId;
  final int? relatedExpenseId;
  final String? createdBy;

  PromissoryNote({
    this.id,
    required this.noteNo,
    required this.debtorName,
    this.debtorPhone,
    this.debtorEmail,
    this.debtorAddress,
    this.debtorTcNo,
    required this.amount,
    required this.issueDate,
    required this.dueDate,
    this.description,
    required this.status,
    this.direction = 'Alınacak',
    this.paymentDate,
    this.paymentMethod,
    this.paymentReference,
    this.notes,
    this.relatedIncomeId,
    this.relatedExpenseId,
    this.createdBy,
  });

  PromissoryNote copyWith({
    int? id,
    String? noteNo,
    String? debtorName,
    String? debtorPhone,
    String? debtorEmail,
    String? debtorAddress,
    String? debtorTcNo,
    double? amount,
    DateTime? issueDate,
    DateTime? dueDate,
    String? description,
    String? status,
    String? direction,
    DateTime? paymentDate,
    String? paymentMethod,
    String? paymentReference,
    String? notes,
    int? relatedIncomeId,
    int? relatedExpenseId,
    String? createdBy,
  }) {
    return PromissoryNote(
      id: id ?? this.id,
      noteNo: noteNo ?? this.noteNo,
      debtorName: debtorName ?? this.debtorName,
      debtorPhone: debtorPhone ?? this.debtorPhone,
      debtorEmail: debtorEmail ?? this.debtorEmail,
      debtorAddress: debtorAddress ?? this.debtorAddress,
      debtorTcNo: debtorTcNo ?? this.debtorTcNo,
      amount: amount ?? this.amount,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      description: description ?? this.description,
      status: status ?? this.status,
      direction: direction ?? this.direction,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
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

