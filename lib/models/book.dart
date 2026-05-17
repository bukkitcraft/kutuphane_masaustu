class Book {
  final int? id;
  final String isbn;
  final String title;
  final String? subtitle;
  final int? authorId;
  final String? authorName;
  final int? categoryId;
  final String? categoryName;
  final int? publisherId;
  final String? publisherName;
  final int? publicationYear;
  final int? pageCount;
  final String? language;
  final String? description;
  final String? coverImageUrl;
  final int totalCopies;
  final int availableCopies;
  final int borrowedCopies;
  final String? location;
  final DateTime? addedDate;
  final bool isActive;

  Book({
    this.id,
    required this.isbn,
    required this.title,
    this.subtitle,
    this.authorId,
    this.authorName,
    this.categoryId,
    this.categoryName,
    this.publisherId,
    this.publisherName,
    this.publicationYear,
    this.pageCount,
    this.language,
    this.description,
    this.coverImageUrl,
    this.totalCopies = 1,
    this.availableCopies = 1,
    this.borrowedCopies = 0,
    this.location,
    this.addedDate,
    this.isActive = true,
  });

  Book copyWith({
    int? id,
    String? isbn,
    String? title,
    String? subtitle,
    int? authorId,
    String? authorName,
    int? categoryId,
    String? categoryName,
    int? publisherId,
    String? publisherName,
    int? publicationYear,
    int? pageCount,
    String? language,
    String? description,
    String? coverImageUrl,
    int? totalCopies,
    int? availableCopies,
    int? borrowedCopies,
    String? location,
    DateTime? addedDate,
    bool? isActive,
  }) {
    return Book(
      id: id ?? this.id,
      isbn: isbn ?? this.isbn,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      publisherId: publisherId ?? this.publisherId,
      publisherName: publisherName ?? this.publisherName,
      publicationYear: publicationYear ?? this.publicationYear,
      pageCount: pageCount ?? this.pageCount,
      language: language ?? this.language,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      totalCopies: totalCopies ?? this.totalCopies,
      availableCopies: availableCopies ?? this.availableCopies,
      borrowedCopies: borrowedCopies ?? this.borrowedCopies,
      location: location ?? this.location,
      addedDate: addedDate ?? this.addedDate,
      isActive: isActive ?? this.isActive,
    );
  }

  String get formattedAddedDate {
    if (addedDate == null) return 'Belirtilmemiş';
    return '${addedDate!.day.toString().padLeft(2, '0')}.${addedDate!.month.toString().padLeft(2, '0')}.${addedDate!.year}';
  }

  bool get isAvailable => availableCopies > 0 && isActive;
}

