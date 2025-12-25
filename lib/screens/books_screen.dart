import 'package:flutter/material.dart';
import 'books/books_list_screen.dart';
import 'books/authors_list_screen.dart';
import 'books/categories_list_screen.dart';
import '../services/book_service.dart';
import '../services/author_service.dart';
import '../services/book_category_service.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BookService _bookService = BookService();
  final AuthorService _authorService = AuthorService();
  final BookCategoryService _categoryService = BookCategoryService();
  
  int _bookCount = 0;
  int _authorCount = 0;
  int _categoryCount = 0;
  bool _isLoadingCounts = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCounts();
    
    // Tab değiştiğinde sayıları yenile
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadCounts();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCounts() async {
    setState(() => _isLoadingCounts = true);
    try {
      final books = await _bookService.getAll();
      final authors = await _authorService.getAll();
      final categories = await _categoryService.getAll();
      
      if (mounted) {
        setState(() {
          _bookCount = books.length;
          _authorCount = authors.length;
          _categoryCount = categories.length;
          _isLoadingCounts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCounts = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: Column(
        children: [
          // Header with Tabs
          Container(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8D6E63).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_stories_rounded,
                        size: 32,
                        color: Color(0xFF8D6E63),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Kitap Yönetimi',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E2723),
                          ),
                        ),
                        Text(
                          'Kitaplar, yazarlar ve türler',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8D6E63),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Sayılar
                    if (!_isLoadingCounts)
                      Row(
                        children: [
                          _buildCountChip(
                            icon: Icons.menu_book_rounded,
                            label: 'Kitap',
                            count: _bookCount,
                            color: const Color(0xFF1976D2),
                          ),
                          const SizedBox(width: 12),
                          _buildCountChip(
                            icon: Icons.person_rounded,
                            label: 'Yazar',
                            count: _authorCount,
                            color: const Color(0xFF388E3C),
                          ),
                          const SizedBox(width: 12),
                          _buildCountChip(
                            icon: Icons.category_rounded,
                            label: 'Kategori',
                            count: _categoryCount,
                            color: const Color(0xFF7B1FA2),
                          ),
                        ],
                      )
                    else
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                // Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.brown.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xFF8D6E63),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF8D6E63),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.menu_book_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('Kitaplar'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('Yazarlar'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.category_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('Kitap Türleri'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Tab Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: TabBarView(
                controller: _tabController,
                children: const [
                  BooksListScreen(),
                  AuthorsListScreen(),
                  CategoriesListScreen(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountChip({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
