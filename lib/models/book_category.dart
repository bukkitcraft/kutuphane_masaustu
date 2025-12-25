class BookCategory {
  final int? id;
  final String name;
  final String? description;
  final String? colorCode;
  final int booksCount;

  BookCategory({
    this.id,
    required this.name,
    this.description,
    this.colorCode,
    this.booksCount = 0,
  });

  BookCategory copyWith({
    int? id,
    String? name,
    String? description,
    String? colorCode,
    int? booksCount,
  }) {
    return BookCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorCode: colorCode ?? this.colorCode,
      booksCount: booksCount ?? this.booksCount,
    );
  }
}

