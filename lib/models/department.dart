class Department {
  final int? id;
  final String name;
  final String? description;
  final String? colorCode;
  final int personnelCount;

  Department({
    this.id,
    required this.name,
    this.description,
    this.colorCode,
    this.personnelCount = 0,
  });

  Department copyWith({
    int? id,
    String? name,
    String? description,
    String? colorCode,
    int? personnelCount,
  }) {
    return Department(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorCode: colorCode ?? this.colorCode,
      personnelCount: personnelCount ?? this.personnelCount,
    );
  }
}

