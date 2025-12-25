class Income {
  final int? id;
  final String incomeNo;
  final String title;
  final String? description;
  final double amount;
  final String category; // Kitap Satışı, Üyelik Ücreti, Ceza, Diğer
  final DateTime incomeDate;
  final String? payerName;
  final String? payerPhone;
  final String? payerEmail;
  final String? paymentMethod; // Nakit, Kredi Kartı, Banka Transferi, Çek
  final String? referenceNo;
  final String? notes;
  final int? relatedMemberId;
  final int? relatedEscrowId;
  final String? createdBy;

  Income({
    this.id,
    required this.incomeNo,
    required this.title,
    this.description,
    required this.amount,
    required this.category,
    required this.incomeDate,
    this.payerName,
    this.payerPhone,
    this.payerEmail,
    this.paymentMethod,
    this.referenceNo,
    this.notes,
    this.relatedMemberId,
    this.relatedEscrowId,
    this.createdBy,
  });

  Income copyWith({
    int? id,
    String? incomeNo,
    String? title,
    String? description,
    double? amount,
    String? category,
    DateTime? incomeDate,
    String? payerName,
    String? payerPhone,
    String? payerEmail,
    String? paymentMethod,
    String? referenceNo,
    String? notes,
    int? relatedMemberId,
    int? relatedEscrowId,
    String? createdBy,
  }) {
    return Income(
      id: id ?? this.id,
      incomeNo: incomeNo ?? this.incomeNo,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      incomeDate: incomeDate ?? this.incomeDate,
      payerName: payerName ?? this.payerName,
      payerPhone: payerPhone ?? this.payerPhone,
      payerEmail: payerEmail ?? this.payerEmail,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      referenceNo: referenceNo ?? this.referenceNo,
      notes: notes ?? this.notes,
      relatedMemberId: relatedMemberId ?? this.relatedMemberId,
      relatedEscrowId: relatedEscrowId ?? this.relatedEscrowId,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  String get formattedDate {
    return '${incomeDate.day.toString().padLeft(2, '0')}.${incomeDate.month.toString().padLeft(2, '0')}.${incomeDate.year}';
  }

  String get formattedAmount {
    return '₺${amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }
}

