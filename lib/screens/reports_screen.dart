import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/book_service.dart';
import '../services/author_service.dart';
import '../services/book_category_service.dart';
import '../services/member_service.dart';
import '../services/personnel_service.dart';
import '../services/escrow_service.dart';
import '../services/income_service.dart';
import '../services/expense_service.dart';
import '../services/book_sale_service.dart';
import '../services/company_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final BookService _bookService = BookService();
  final AuthorService _authorService = AuthorService();
  final BookCategoryService _categoryService = BookCategoryService();
  final MemberService _memberService = MemberService();
  final PersonnelService _personnelService = PersonnelService();
  final EscrowService _escrowService = EscrowService();
  final IncomeService _incomeService = IncomeService();
  final ExpenseService _expenseService = ExpenseService();
  final BookSaleService _bookSaleService = BookSaleService();
  final CompanyService _companyService = CompanyService();

  bool _isLoading = true;
  
  // İstatistikler
  int _totalBooks = 0;
  int _totalAuthors = 0;
  int _totalCategories = 0;
  int _totalMembers = 0;
  int _totalPersonnel = 0;
  int _totalCompanies = 0;
  int _activeEscrows = 0;
  int _returnedEscrows = 0;
  int _overdueEscrows = 0;
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _totalBookSales = 0;
  int _totalBookSalesCount = 0;
  int _availableBooks = 0;
  int _borrowedBooks = 0;
  int _activeMembers = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    
    try {
      // Kitap istatistikleri
      final books = await _bookService.getAll();
      _totalBooks = books.length;
      _availableBooks = books.fold(0, (sum, book) => sum + (book.availableCopies));
      _borrowedBooks = books.fold(0, (sum, book) => sum + (book.totalCopies - book.availableCopies));
      
      // Yazar ve kategori
      final authors = await _authorService.getAll();
      _totalAuthors = authors.length;
      
      final categories = await _categoryService.getAll();
      _totalCategories = categories.length;
      
      // Üye istatistikleri
      final members = await _memberService.getAll();
      _totalMembers = members.length;
      _activeMembers = members.where((m) => m.isActive).length;
      
      // Personel istatistikleri
      final personnel = await _personnelService.getAll();
      _totalPersonnel = personnel.length;
      
      // Firma istatistikleri
      final companies = await _companyService.getAll();
      _totalCompanies = companies.length;
      
      // Emanet istatistikleri
      final escrows = await _escrowService.getAll();
      _activeEscrows = escrows.where((e) => e.status == 'Ödünçte').length;
      _returnedEscrows = escrows.where((e) => e.status == 'İade Edildi').length;
      final now = DateTime.now();
      _overdueEscrows = escrows.where((e) {
        if (e.status != 'Ödünçte') return false;
        return e.dueDate.isBefore(now);
      }).length;
      
      // Finans istatistikleri
      final incomes = await _incomeService.getAll();
      _totalIncome = incomes.fold(0.0, (sum, income) => sum + income.amount);
      
      final expenses = await _expenseService.getAll();
      _totalExpense = expenses.fold(0.0, (sum, expense) => sum + expense.amount);
      
      // Kitap satış istatistikleri
      final sales = await _bookSaleService.getAll();
      _totalBookSalesCount = sales.length;
      _totalBookSales = sales.fold(0.0, (sum, sale) => sum + sale.finalAmount);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İstatistikler yüklenirken hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.assessment_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Raporlar ve İstatistikler',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3E2723),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Sistem geneli detaylı istatistikler ve grafikler',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Genel İstatistikler
                    _buildSectionTitle('Genel İstatistikler'),
                    const SizedBox(height: 16),
                    _buildGeneralStatsGrid(),
                    const SizedBox(height: 32),
                    
                    // Kitap İstatistikleri
                    _buildSectionTitle('Kitap İstatistikleri'),
                    const SizedBox(height: 16),
                    _buildBookStats(),
                    const SizedBox(height: 32),
                    
                    // Üye ve Personel İstatistikleri
                    _buildSectionTitle('Üye ve Personel'),
                    const SizedBox(height: 16),
                    _buildMemberPersonnelStats(),
                    const SizedBox(height: 32),
                    
                    // Emanet İstatistikleri
                    _buildSectionTitle('Emanet İstatistikleri'),
                    const SizedBox(height: 16),
                    _buildEscrowStats(),
                    const SizedBox(height: 32),
                    
                    // Finans İstatistikleri
                    _buildSectionTitle('Finans İstatistikleri'),
                    const SizedBox(height: 16),
                    _buildFinanceStats(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF3E2723),
      ),
    );
  }

  Widget _buildGeneralStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Toplam Kitap', _totalBooks.toString(), Icons.auto_stories_rounded, const Color(0xFF8D6E63)),
        _buildStatCard('Toplam Yazar', _totalAuthors.toString(), Icons.person_rounded, const Color(0xFF6D4C41)),
        _buildStatCard('Toplam Kategori', _totalCategories.toString(), Icons.category_rounded, const Color(0xFF795548)),
        _buildStatCard('Toplam Üye', _totalMembers.toString(), Icons.groups_rounded, const Color(0xFF5D4037)),
        _buildStatCard('Toplam Personel', _totalPersonnel.toString(), Icons.badge_rounded, const Color(0xFF4E342E)),
        _buildStatCard('Toplam Firma', _totalCompanies.toString(), Icons.business_rounded, const Color(0xFF3E2723)),
        _buildStatCard('Aktif Emanet', _activeEscrows.toString(), Icons.swap_horiz_rounded, const Color(0xFF2E7D32)),
        _buildStatCard('Kitap Satışı', _totalBookSalesCount.toString(), Icons.shopping_cart_rounded, const Color(0xFFD2691E)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Mevcut Kopyalar',
            _availableBooks.toString(),
            Icons.inventory_2_rounded,
            const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Ödünç Verilen',
            _borrowedBooks.toString(),
            Icons.library_books_rounded,
            const Color(0xFF2196F3),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Stok Durumu',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E2723),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: _availableBooks.toDouble(),
                          color: const Color(0xFF4CAF50),
                          title: 'Mevcut',
                          radius: 50,
                        ),
                        PieChartSectionData(
                          value: _borrowedBooks.toDouble(),
                          color: const Color(0xFF2196F3),
                          title: 'Ödünç',
                          radius: 50,
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberPersonnelStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Aktif Üyeler',
            _activeMembers.toString(),
            Icons.check_circle_rounded,
            const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Pasif Üyeler',
            (_totalMembers - _activeMembers).toString(),
            Icons.cancel_rounded,
            const Color(0xFFF44336),
          ),
        ),
      ],
    );
  }

  Widget _buildEscrowStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Aktif Emanet',
            _activeEscrows.toString(),
            Icons.swap_horiz_rounded,
            const Color(0xFF2196F3),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'İade Edilen',
            _returnedEscrows.toString(),
            Icons.check_circle_rounded,
            const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Geciken',
            _overdueEscrows.toString(),
            Icons.warning_rounded,
            const Color(0xFFFF9800),
          ),
        ),
      ],
    );
  }

  Widget _buildFinanceStats() {
    final netProfit = _totalIncome + _totalBookSales - _totalExpense;
    final profitColor = netProfit >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Toplam Gelir',
                NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(_totalIncome + _totalBookSales),
                Icons.trending_up_rounded,
                const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Toplam Gider',
                NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(_totalExpense),
                Icons.trending_down_rounded,
                const Color(0xFFF44336),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Net Kar/Zarar',
                NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(netProfit),
                netProfit >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                profitColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gelir - Gider Karşılaştırması',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E2723),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (_totalIncome + _totalBookSales + _totalExpense) * 1.2,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            switch (value.toInt()) {
                              case 0:
                                return const Text('Gelir', style: TextStyle(color: Colors.grey, fontSize: 12));
                              case 1:
                                return const Text('Gider', style: TextStyle(color: Colors.grey, fontSize: 12));
                              default:
                                return const Text('');
                            }
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: _totalIncome + _totalBookSales,
                            color: const Color(0xFF4CAF50),
                            width: 40,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: _totalExpense,
                            color: const Color(0xFFF44336),
                            width: 40,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

