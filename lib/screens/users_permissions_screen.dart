import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class UsersPermissionsScreen extends StatefulWidget {
  final User? currentUser;
  const UsersPermissionsScreen({super.key, this.currentUser});

  @override
  State<UsersPermissionsScreen> createState() => _UsersPermissionsScreenState();
}

class _UsersPermissionsScreenState extends State<UsersPermissionsScreen> {
  final UserService _userService = UserService();
  List<User> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userService.getAll();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kullanıcılar yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<User> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) {
      return user.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.role.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _showAddEditUserDialog([User? user]) {
    final isEdit = user != null;
    final usernameController = TextEditingController(text: user?.username ?? '');
    final passwordController = TextEditingController();
    String selectedRole = user?.role ?? 'user';
    final roles = ['admin', 'user', 'moderator'];
    
    // Menü izinleri
    final allMenus = [
      {'id': 'personnel', 'title': 'Personel', 'icon': Icons.badge_rounded},
      {'id': 'members', 'title': 'Müşteri/Üyeler', 'icon': Icons.groups_rounded},
      {'id': 'escrow', 'title': 'Emanet', 'icon': Icons.swap_horiz_rounded},
      {'id': 'books', 'title': 'Kitaplar', 'icon': Icons.auto_stories_rounded},
      {'id': 'companies', 'title': 'Firmalar', 'icon': Icons.business_rounded},
      {'id': 'finance', 'title': 'Muhasebe/Finans', 'icon': Icons.account_balance_wallet_rounded},
      {'id': 'book_sales', 'title': 'Kitap Satışları', 'icon': Icons.shopping_cart_rounded},
      {'id': 'reports', 'title': 'Raporlar', 'icon': Icons.assessment_rounded},
      {'id': 'reminders', 'title': 'Hatırlatmalar', 'icon': Icons.notifications_rounded},
    ];
    
    // Mevcut izinleri yükle
    List<String> selectedMenus = [];
    if (isEdit) {
      final currentUser = user; // isEdit true ise user null olamaz
      if (currentUser.role == 'admin') {
        // Admin ise tüm menüleri seçili yap
        selectedMenus = allMenus.map((m) => m['id'] as String).toList();
      } else {
        selectedMenus = currentUser.getAllowedMenusList();
      }
    } else {
      // Yeni kullanıcı için varsayılan olarak tüm menüleri seç
      selectedMenus = allMenus.map((m) => m['id'] as String).toList();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFB71C1C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Color(0xFFB71C1C),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isEdit ? 'Kullanıcı Düzenle' : 'Yeni Kullanıcı',
                style: const TextStyle(
                  color: Color(0xFF3E2723),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: 'Kullanıcı Adı *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.person_rounded),
                    ),
                    enabled: !isEdit, // Düzenleme modunda kullanıcı adı değiştirilemez
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: isEdit ? 'Yeni Şifre (Boş bırakılırsa değişmez)' : 'Şifre *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.lock_rounded),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Yetki Seviyesi *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.security_rounded),
                    ),
                    items: roles.map((role) {
                      String roleName;
                      IconData roleIcon;
                      Color roleColor;
                      
                      switch (role) {
                        case 'admin':
                          roleName = 'Yönetici';
                          roleIcon = Icons.admin_panel_settings_rounded;
                          roleColor = const Color(0xFFB71C1C);
                          break;
                        case 'moderator':
                          roleName = 'Moderatör';
                          roleIcon = Icons.verified_user_rounded;
                          roleColor = const Color(0xFF1976D2);
                          break;
                        default:
                          roleName = 'Kullanıcı';
                          roleIcon = Icons.person_rounded;
                          roleColor = const Color(0xFF616161);
                      }
                      
                      return DropdownMenuItem(
                        value: role,
                        child: Row(
                          children: [
                            Icon(roleIcon, size: 20, color: roleColor),
                            const SizedBox(width: 8),
                            Text(roleName),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedRole = value!;
                        // Admin seçilirse tüm menüleri otomatik seç
                        if (value == 'admin') {
                          selectedMenus = allMenus.map((m) => m['id'] as String).toList();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Menü İzinleri
                  const Text(
                    'Menü İzinleri',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E2723),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: allMenus.map((menu) {
                        final menuId = menu['id'] as String;
                        final isSelected = selectedMenus.contains(menuId);
                        return CheckboxListTile(
                          title: Row(
                            children: [
                              Icon(menu['icon'] as IconData, size: 20, color: const Color(0xFF8D6E63)),
                              const SizedBox(width: 8),
                              Text(menu['title'] as String),
                            ],
                          ),
                          value: isSelected,
                          onChanged: selectedRole == 'admin' 
                              ? null // Admin için tüm menüler zorunlu
                              : (value) {
                                  setDialogState(() {
                                    if (value == true) {
                                      if (!selectedMenus.contains(menuId)) {
                                        selectedMenus.add(menuId);
                                      }
                                    } else {
                                      selectedMenus.remove(menuId);
                                    }
                                  });
                                },
                          activeColor: const Color(0xFF8D6E63),
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      }).toList(),
                    ),
                  ),
                  if (selectedRole == 'admin')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Yönetici rolü tüm menülere erişim hakkına sahiptir.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (usernameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lütfen kullanıcı adı girin'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (!isEdit && passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lütfen şifre girin'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  // Menü izinlerini JSON string'e çevir
                  final allowedMenusJson = selectedRole == 'admin' 
                      ? null // Admin için null (tüm menülere erişim)
                      : selectedMenus.join(','); // Virgülle ayrılmış string
                  
                  if (isEdit) {
                    // Düzenleme
                    final updatedUser = user.copyWith(
                      role: selectedRole,
                      password: passwordController.text.isEmpty 
                          ? user.password // Şifre değişmedi
                          : passwordController.text, // Yeni şifre
                      allowedMenus: allowedMenusJson,
                    );
                    await _userService.update(updatedUser);
                  } else {
                    // Yeni kullanıcı
                    final newUser = User(
                      username: usernameController.text.trim(),
                      password: passwordController.text,
                      role: selectedRole,
                      allowedMenus: allowedMenusJson,
                    );
                    await _userService.insert(newUser);
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    _loadUsers();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit ? 'Kullanıcı güncellendi' : 'Kullanıcı eklendi'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                foregroundColor: Colors.white,
              ),
              child: Text(isEdit ? 'Kaydet' : 'Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(User user) {
    if (user.username == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin kullanıcısı silinemez!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Sil'),
        content: Text('${user.username} kullanıcısını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _userService.delete(user.id!);
                if (mounted) {
                  Navigator.pop(context);
                  _loadUsers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kullanıcı silindi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Kullanıcı silinirken hata oluştu: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB71C1C).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 32,
                    color: Color(0xFFB71C1C),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kullanıcı Yetkileri',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E2723),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Kullanıcı yetki seviyelerini yönetin',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditUserDialog(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Yeni Kullanıcı'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Search
            TextField(
              decoration: InputDecoration(
                hintText: 'Kullanıcı adı veya yetki seviyesi ile ara...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 24),
            
            // Users List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline_rounded,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Kullanıcı bulunamadı',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Table Header
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB71C1C).withValues(alpha: 0.1),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Expanded(flex: 2, child: Text('Kullanıcı Adı', style: TextStyle(fontWeight: FontWeight.bold))),
                                    Expanded(flex: 2, child: Text('Yetki Seviyesi', style: TextStyle(fontWeight: FontWeight.bold))),
                                    Expanded(flex: 1, child: Text('Oluşturulma', style: TextStyle(fontWeight: FontWeight.bold))),
                                    SizedBox(width: 120),
                                  ],
                                ),
                              ),
                              // Table Body
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _filteredUsers.length,
                                  itemBuilder: (context, index) {
                                    final user = _filteredUsers[index];
                                    String roleName;
                                    IconData roleIcon;
                                    Color roleColor;
                                    
                                    switch (user.role) {
                                      case 'admin':
                                        roleName = 'Yönetici';
                                        roleIcon = Icons.admin_panel_settings_rounded;
                                        roleColor = const Color(0xFFB71C1C);
                                        break;
                                      case 'moderator':
                                        roleName = 'Moderatör';
                                        roleIcon = Icons.verified_user_rounded;
                                        roleColor = const Color(0xFF1976D2);
                                        break;
                                      default:
                                        roleName = 'Kullanıcı';
                                        roleIcon = Icons.person_rounded;
                                        roleColor = const Color(0xFF616161);
                                    }
                                    
                                    return Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey[200]!,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 2,
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.person_rounded, color: Colors.grey[600], size: 20),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        user.username,
                                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Row(
                                                    children: [
                                                      Icon(roleIcon, color: roleColor, size: 20),
                                                      const SizedBox(width: 8),
                                                      Text(roleName, style: TextStyle(color: roleColor)),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    user.createdAt != null
                                                        ? '${user.createdAt!.day.toString().padLeft(2, '0')}.${user.createdAt!.month.toString().padLeft(2, '0')}.${user.createdAt!.year}'
                                                        : '-',
                                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 120,
                                                  child: Row(
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(Icons.edit_rounded, size: 18),
                                                        color: const Color(0xFF1976D2),
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                                        onPressed: () => _showAddEditUserDialog(user),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.delete_rounded, size: 18),
                                                        color: Colors.red,
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                                        onPressed: () => _showDeleteDialog(user),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

