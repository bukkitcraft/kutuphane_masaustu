class Member {
  final int? id;
  final String memberNo;
  final String name;
  final String surname;
  final String tcNo;
  final String phone;
  final String? email;
  final String? address;
  final DateTime? birthDate;
  final String? gender;
  final String memberType; // Öğrenci, Öğretmen, Personel, Dış Üye
  final DateTime registrationDate;
  final DateTime? expiryDate;
  final bool isActive;
  final String? imageUrl;
  final String? notes;
  final int borrowedBooksCount;
  final int totalBorrowedBooks;

  Member({
    this.id,
    required this.memberNo,
    required this.name,
    required this.surname,
    required this.tcNo,
    required this.phone,
    this.email,
    this.address,
    this.birthDate,
    this.gender,
    required this.memberType,
    required this.registrationDate,
    this.expiryDate,
    this.isActive = true,
    this.imageUrl,
    this.notes,
    this.borrowedBooksCount = 0,
    this.totalBorrowedBooks = 0,
  });

  Member copyWith({
    int? id,
    String? memberNo,
    String? name,
    String? surname,
    String? tcNo,
    String? phone,
    String? email,
    String? address,
    DateTime? birthDate,
    String? gender,
    String? memberType,
    DateTime? registrationDate,
    DateTime? expiryDate,
    bool? isActive,
    String? imageUrl,
    String? notes,
    int? borrowedBooksCount,
    int? totalBorrowedBooks,
  }) {
    return Member(
      id: id ?? this.id,
      memberNo: memberNo ?? this.memberNo,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      tcNo: tcNo ?? this.tcNo,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      memberType: memberType ?? this.memberType,
      registrationDate: registrationDate ?? this.registrationDate,
      expiryDate: expiryDate ?? this.expiryDate,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
      borrowedBooksCount: borrowedBooksCount ?? this.borrowedBooksCount,
      totalBorrowedBooks: totalBorrowedBooks ?? this.totalBorrowedBooks,
    );
  }

  String get fullName => '$name $surname';

  String get formattedBirthDate {
    if (birthDate == null) return 'Belirtilmemiş';
    return '${birthDate!.day.toString().padLeft(2, '0')}.${birthDate!.month.toString().padLeft(2, '0')}.${birthDate!.year}';
  }

  String get formattedRegistrationDate {
    return '${registrationDate.day.toString().padLeft(2, '0')}.${registrationDate.month.toString().padLeft(2, '0')}.${registrationDate.year}';
  }

  String get formattedExpiryDate {
    if (expiryDate == null) return 'Süresiz';
    return '${expiryDate!.day.toString().padLeft(2, '0')}.${expiryDate!.month.toString().padLeft(2, '0')}.${expiryDate!.year}';
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  String get maskedTcNo {
    if (tcNo.length != 11) return tcNo;
    return '${tcNo.substring(0, 3)}****${tcNo.substring(7)}';
  }
}

