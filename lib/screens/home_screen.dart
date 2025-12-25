import 'package:flutter/material.dart';
import 'personnel_screen.dart';
import 'members_screen.dart';
import 'escrow_screen.dart';
import 'books_screen.dart';
import 'companies_screen.dart';
import 'finance_screen.dart';
import 'book_sales_screen.dart';
import 'users_permissions_screen.dart';
import 'reports_screen.dart';
import 'reminders_screen.dart';
import 'login_screen.dart';
import '../models/user.dart';
import '../services/reminder_service.dart';
import '../models/reminder.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  final User? currentUser;
  const HomeScreen({super.key, this.currentUser});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late List<MenuItemData> _menuItems;
  Timer? _reminderTimer;
  final ReminderService _reminderService = ReminderService();

  @override
  void initState() {
    super.initState();
    _buildMenuItems();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _startReminderCheck();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _reminderTimer?.cancel();
    super.dispose();
  }

  void _startReminderCheck() {
    _reminderTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      try {
        final dueReminders = await _reminderService.getDueReminders();
        if (dueReminders.isNotEmpty && mounted) {
          for (final reminder in dueReminders) {
            if (mounted) {
              _showReminderDialog(reminder);
            }
          }
        }
      } catch (e) {
        // Hata durumunda sessizce devam et
      }
    });
  }

  void _showReminderDialog(Reminder reminder) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.notifications_active_rounded, color: Colors.orange[700], size: 32),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Hatırlatma!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reminder.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (reminder.description != null && reminder.description!.isNotEmpty) ...[
              Text(
                reminder.description!,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Zaman: ${reminder.formattedReminderDate}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _reminderService.update(reminder.copyWith(isCompleted: true));
            },
            child: const Text('Tamamlandı'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _buildMenuItems() {
    // Tüm menüler
    final allMenuItems = [
      MenuItemData(title: 'Ana Sayfa', icon: Icons.home_rounded, color: const Color(0xFF8B4513), menuId: 'home'),
      MenuItemData(title: 'Personel', icon: Icons.badge_rounded, color: const Color(0xFF5D4037), menuId: 'personnel'),
      MenuItemData(title: 'Müşteri/Üyeler', icon: Icons.groups_rounded, color: const Color(0xFF6D4C41), menuId: 'members'),
      MenuItemData(title: 'Emanet', icon: Icons.swap_horiz_rounded, color: const Color(0xFF795548), menuId: 'escrow'),
      MenuItemData(title: 'Kitaplar', icon: Icons.auto_stories_rounded, color: const Color(0xFF8D6E63), menuId: 'books'),
      MenuItemData(title: 'Firmalar', icon: Icons.business_rounded, color: const Color(0xFFA1887F), menuId: 'companies'),
      MenuItemData(title: 'Muhasebe/Finans', icon: Icons.account_balance_wallet_rounded, color: const Color(0xFF2E7D32), menuId: 'finance'),
      MenuItemData(title: 'Kitap Satışları', icon: Icons.shopping_cart_rounded, color: const Color(0xFFD2691E), menuId: 'book_sales'),
      MenuItemData(title: 'Raporlar', icon: Icons.assessment_rounded, color: const Color(0xFF2196F3), menuId: 'reports'),
      MenuItemData(title: 'Hatırlatmalar', icon: Icons.notifications_rounded, color: const Color(0xFFFF9800), menuId: 'reminders'),
    ];
    
    // Kullanıcının izin verilen menüleri
    List<String> allowedMenus = [];
    if (widget.currentUser != null) {
      allowedMenus = widget.currentUser!.getAllowedMenusList();
    }
    
    // Ana Sayfa her zaman erişilebilir
    _menuItems = [allMenuItems[0]]; // Ana Sayfa
    
    // Diğer menüleri kullanıcı izinlerine göre filtrele
    for (int i = 1; i < allMenuItems.length; i++) {
      final menu = allMenuItems[i];
      // Admin ise veya menü izin listesindeyse ekle
      if (widget.currentUser?.role == 'admin' || allowedMenus.contains(menu.menuId)) {
        _menuItems.add(menu);
      }
    }
    
    // Admin ise Yetkiler menüsünü ekle
    if (widget.currentUser?.role == 'admin') {
      _menuItems.add(
        MenuItemData(
          title: 'Yetkiler',
          icon: Icons.admin_panel_settings_rounded,
          color: const Color(0xFFB71C1C),
          menuId: 'permissions',
        ),
      );
    }
  }

  void _onItemSelected(int index) {
    if (_selectedIndex != index) {
      _animationController.reset();
      setState(() {
        _selectedIndex = index;
      });
      _animationController.forward();
    }
  }

  Widget _getScreen(int index) {
    // Seçili menüyü al
    if (index >= _menuItems.length) {
      return _buildDashboard();
    }
    
    final selectedMenu = _menuItems[index];
    
    // Menü ID'sine göre ekranı döndür
    switch (selectedMenu.menuId) {
      case 'home':
        return _buildDashboard();
      case 'personnel':
        return const PersonnelScreen();
      case 'members':
        return const MembersScreen();
      case 'escrow':
        return const EscrowScreen();
      case 'books':
        return const BooksScreen();
      case 'companies':
        return const CompaniesScreen();
      case 'finance':
        return const FinanceScreen();
      case 'book_sales':
        return const BookSalesScreen();
      case 'reports':
        return const ReportsScreen();
      case 'reminders':
        return const RemindersScreen();
      case 'permissions':
        // Yetkiler ekranı (sadece admin için)
        if (widget.currentUser?.role == 'admin') {
          return UsersPermissionsScreen(currentUser: widget.currentUser);
        }
        return _buildDashboard();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B4513), Color(0xFF5D4037)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B4513).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.local_library_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 24),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kütüphane Masaüstü',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Hoş geldiniz! Aşağıdaki menülerden işlem yapabilirsiniz.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          // Menu Title
          const Text(
            'Hızlı Erişim',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3E2723),
            ),
          ),
          const SizedBox(height: 24),
          
          // Menu Grid - Scrollable
          LayoutBuilder(
            builder: (context, constraints) {
              final itemCount = _menuItems.length - 1; // Exclude "Ana Sayfa"
              final spacing = 16.0;
              final cardWidth = (constraints.maxWidth - (spacing * 2)) / 3;
              final cardHeight = 140.0; // Sabit yükseklik
              final aspectRatio = cardWidth / cardHeight;
              
              return GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: aspectRatio,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: List.generate(
                  itemCount,
                  (index) {
                    final item = _menuItems[index + 1];
                    return _buildMenuCard(item, index + 1);
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 32), // Alt boşluk
        ],
      ),
    );
  }

  Widget _buildMenuCard(MenuItemData item, int index) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 300 + (index * 100)),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: GestureDetector(
          onTap: () => _onItemSelected(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: item.color.withValues(alpha: 0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: item.color.withValues(alpha: 0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
                child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _onItemSelected(index),
                hoverColor: item.color.withValues(alpha: 0.05),
                splashColor: item.color.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                item.color,
                                item.color.withValues(alpha: 0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: item.color.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            item.icon,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: item.color,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Navigation
          Container(
            width: 240,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3E2723), Color(0xFF4E342E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                // Logo Section
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.local_library_rounded,
                          size: 48,
                          color: Color(0xFFFFD54F),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'KÜTÜPHANE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            'MASAÜSTÜ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const Divider(
                  color: Colors.white24,
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                ),
                
                const SizedBox(height: 16),
                
                // Navigation Items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final item = _menuItems[index];
                      final isSelected = _selectedIndex == index;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _onItemSelected(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(
                                        color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 24,
                                    color: isSelected 
                                        ? const Color(0xFFFFD54F)
                                        : Colors.white70,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected 
                                            ? FontWeight.w600 
                                            : FontWeight.normal,
                                        color: isSelected 
                                            ? const Color(0xFFFFD54F)
                                            : Colors.white70,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFFD54F),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Footer
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    '© 2026 Kütüphane Masaüstü',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: Stack(
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _getScreen(_selectedIndex),
                ),
                // Çıkış Butonu - Sağ Alt Köşe
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Çıkış Yap'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Sistemden çıkmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Dialog'u kapat
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false, // Tüm önceki route'ları temizle
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}

class MenuItemData {
  final String title;
  final IconData icon;
  final Color color;
  final String menuId; // Menü ID'si (izin kontrolü için)

  MenuItemData({
    required this.title,
    required this.icon,
    required this.color,
    required this.menuId,
  });
}
