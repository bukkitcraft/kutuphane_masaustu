class User {
  final int? id;
  final String username;
  final String password; // Hash'lenmiş olarak saklanacak
  final String role; // 'admin', 'user', vb.
  final String? allowedMenus; // JSON string: ['personnel', 'members', ...]
  final DateTime? createdAt;

  User({
    this.id,
    required this.username,
    required this.password,
    required this.role,
    this.allowedMenus,
    this.createdAt,
  });

  // İzin verilen menüleri liste olarak döndür
  List<String> getAllowedMenusList() {
    // Admin ise tüm menülere erişim
    if (role == 'admin') {
      return _getAllMenuIds();
    }
    
    if (allowedMenus == null || allowedMenus!.isEmpty) {
      return [];
    }
    
    try {
      // Virgülle ayrılmış string'i parse et
      return allowedMenus!.split(',').where((e) => e.isNotEmpty).toList();
    } catch (_) {
      // Parse hatası durumunda boş liste döndür
      return [];
    }
  }

  // Tüm menü ID'lerini döndür
  static List<String> _getAllMenuIds() {
    return ['home', 'personnel', 'members', 'escrow', 'books', 'companies', 'finance', 'book_sales', 'reports', 'reminders', 'permissions'];
  }

  User copyWith({
    int? id,
    String? username,
    String? password,
    String? role,
    String? allowedMenus,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      allowedMenus: allowedMenus ?? this.allowedMenus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

