class Escrow {
  final int? id;
  final String escrowNo;
  final int bookId;
  final String bookTitle;
  final String? bookIsbn;
  final String? bookCoverUrl;
  final int memberId;
  final String memberName;
  final String memberNo;
  final DateTime borrowDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final String status; // Ödünçte, İade Edildi, Gecikmiş
  final String? notes;
  final int? personnelId;
  final String? personnelName;
  final double? fineAmount;
  final String? fineReason;

  Escrow({
    this.id,
    required this.escrowNo,
    required this.bookId,
    required this.bookTitle,
    this.bookIsbn,
    this.bookCoverUrl,
    required this.memberId,
    required this.memberName,
    required this.memberNo,
    required this.borrowDate,
    required this.dueDate,
    this.returnDate,
    required this.status,
    this.notes,
    this.personnelId,
    this.personnelName,
    this.fineAmount,
    this.fineReason,
  });

  Escrow copyWith({
    int? id,
    String? escrowNo,
    int? bookId,
    String? bookTitle,
    String? bookIsbn,
    String? bookCoverUrl,
    int? memberId,
    String? memberName,
    String? memberNo,
    DateTime? borrowDate,
    DateTime? dueDate,
    DateTime? returnDate,
    String? status,
    String? notes,
    int? personnelId,
    String? personnelName,
    double? fineAmount,
    String? fineReason,
  }) {
    return Escrow(
      id: id ?? this.id,
      escrowNo: escrowNo ?? this.escrowNo,
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      bookIsbn: bookIsbn ?? this.bookIsbn,
      bookCoverUrl: bookCoverUrl ?? this.bookCoverUrl,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      memberNo: memberNo ?? this.memberNo,
      borrowDate: borrowDate ?? this.borrowDate,
      dueDate: dueDate ?? this.dueDate,
      returnDate: returnDate ?? this.returnDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      personnelId: personnelId ?? this.personnelId,
      personnelName: personnelName ?? this.personnelName,
      fineAmount: fineAmount ?? this.fineAmount,
      fineReason: fineReason ?? this.fineReason,
    );
  }

  String get formattedBorrowDate {
    return '${borrowDate.day.toString().padLeft(2, '0')}.${borrowDate.month.toString().padLeft(2, '0')}.${borrowDate.year}';
  }

  String get formattedDueDate {
    return '${dueDate.day.toString().padLeft(2, '0')}.${dueDate.month.toString().padLeft(2, '0')}.${dueDate.year}';
  }

  String get formattedReturnDate {
    if (returnDate == null) return '-';
    return '${returnDate!.day.toString().padLeft(2, '0')}.${returnDate!.month.toString().padLeft(2, '0')}.${returnDate!.year}';
  }

  int get daysOverdue {
    if (status == 'İade Edildi' || returnDate != null) return 0;
    final now = DateTime.now();
    if (dueDate.isBefore(now)) {
      return now.difference(dueDate).inDays;
    }
    return 0;
  }

  bool get isOverdue => daysOverdue > 0 && status == 'Ödünçte';

  int get remainingDays {
    if (status == 'İade Edildi' || returnDate != null) return 0;
    final now = DateTime.now();
    if (dueDate.isAfter(now)) {
      return dueDate.difference(now).inDays;
    }
    return 0;
  }
}

