class Personnel {
  final int? id;
  final String name;
  final String surname;
  final String phone;
  final String email;
  final String? tcNo;
  final int? departmentId;
  final String? departmentName;
  final DateTime? startDate;
  final DateTime? birthDate;
  final bool isActive;
  final double? salary;
  final String? address;
  final String? imageUrl;
  final String accountNo; // Hesap No (zorunlu, 7-10 basamaklı sayı)
  final String iban; // IBAN (zorunlu, TR12 + 12 haneli sayı)

  Personnel({
    this.id,
    required this.name,
    required this.surname,
    required this.phone,
    required this.email,
    this.tcNo,
    this.departmentId,
    this.departmentName,
    this.startDate,
    this.birthDate,
    this.isActive = true,
    this.salary,
    this.address,
    this.imageUrl,
    required this.accountNo,
    required this.iban,
  });

  Personnel copyWith({
    int? id,
    String? name,
    String? surname,
    String? phone,
    String? email,
    String? tcNo,
    int? departmentId,
    String? departmentName,
    DateTime? startDate,
    DateTime? birthDate,
    bool? isActive,
    double? salary,
    String? address,
    String? imageUrl,
    String? accountNo,
    String? iban,
  }) {
    return Personnel(
      id: id ?? this.id,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      tcNo: tcNo ?? this.tcNo,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      startDate: startDate ?? this.startDate,
      birthDate: birthDate ?? this.birthDate,
      isActive: isActive ?? this.isActive,
      salary: salary ?? this.salary,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      accountNo: accountNo ?? this.accountNo,
      iban: iban ?? this.iban,
    );
  }

  String get fullName => '$name $surname';
  
  String get formattedSalary {
    if (salary == null) return 'Belirtilmemiş';
    return '₺${salary!.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }
}

