class Company {
  final int? id;
  final String name;
  final String? taxNumber;
  final String? taxOffice;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? country;
  final String? website;
  final String? contactPerson;
  final String? contactPhone;
  final String? contactEmail;
  final String companyType; // Yayınevi, Tedarikçi, Diğer
  final DateTime? registrationDate;
  final bool isActive;
  final String? notes;
  final int booksCount;
  final String? imageUrl;

  Company({
    this.id,
    required this.name,
    this.taxNumber,
    this.taxOffice,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.country,
    this.website,
    this.contactPerson,
    this.contactPhone,
    this.contactEmail,
    required this.companyType,
    this.registrationDate,
    this.isActive = true,
    this.notes,
    this.booksCount = 0,
    this.imageUrl,
  });

  Company copyWith({
    int? id,
    String? name,
    String? taxNumber,
    String? taxOffice,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? country,
    String? website,
    String? contactPerson,
    String? contactPhone,
    String? contactEmail,
    String? companyType,
    DateTime? registrationDate,
    bool? isActive,
    String? notes,
    int? booksCount,
    String? imageUrl,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      taxNumber: taxNumber ?? this.taxNumber,
      taxOffice: taxOffice ?? this.taxOffice,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      website: website ?? this.website,
      contactPerson: contactPerson ?? this.contactPerson,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      companyType: companyType ?? this.companyType,
      registrationDate: registrationDate ?? this.registrationDate,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      booksCount: booksCount ?? this.booksCount,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  String get formattedRegistrationDate {
    if (registrationDate == null) return 'Belirtilmemiş';
    return '${registrationDate!.day.toString().padLeft(2, '0')}.${registrationDate!.month.toString().padLeft(2, '0')}.${registrationDate!.year}';
  }

  String get fullAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.isEmpty ? 'Belirtilmemiş' : parts.join(', ');
  }
}

