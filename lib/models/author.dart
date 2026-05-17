class Author {
  final int? id;
  final String name;
  final String surname;
  final String? biography;
  final DateTime? birthDate;
  final DateTime? deathDate;
  final String? nationality;
  final String? imageUrl;
  final int booksCount;

  Author({
    this.id,
    required this.name,
    required this.surname,
    this.biography,
    this.birthDate,
    this.deathDate,
    this.nationality,
    this.imageUrl,
    this.booksCount = 0,
  });

  Author copyWith({
    int? id,
    String? name,
    String? surname,
    String? biography,
    DateTime? birthDate,
    DateTime? deathDate,
    String? nationality,
    String? imageUrl,
    int? booksCount,
  }) {
    return Author(
      id: id ?? this.id,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      biography: biography ?? this.biography,
      birthDate: birthDate ?? this.birthDate,
      deathDate: deathDate ?? this.deathDate,
      nationality: nationality ?? this.nationality,
      imageUrl: imageUrl ?? this.imageUrl,
      booksCount: booksCount ?? this.booksCount,
    );
  }

  String get fullName => '$name $surname';

  String get formattedBirthDate {
    if (birthDate == null) return 'Belirtilmemiş';
    return '${birthDate!.day.toString().padLeft(2, '0')}.${birthDate!.month.toString().padLeft(2, '0')}.${birthDate!.year}';
  }

  String get formattedDeathDate {
    if (deathDate == null) return 'Yaşıyor';
    return '${deathDate!.day.toString().padLeft(2, '0')}.${deathDate!.month.toString().padLeft(2, '0')}.${deathDate!.year}';
  }

  int? get age {
    if (birthDate == null) return null;
    final endDate = deathDate ?? DateTime.now();
    return endDate.year - birthDate!.year - (endDate.month < birthDate!.month || (endDate.month == birthDate!.month && endDate.day < birthDate!.day) ? 1 : 0);
  }
}

