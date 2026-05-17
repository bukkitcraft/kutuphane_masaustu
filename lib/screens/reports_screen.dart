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
import '../models/expense.dart';
import '../models/member.dart';
import '../models/escrow.dart';

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
  DateTime _selectedReadersMonth = DateTime.now();
  List<_ReaderStat> _allTimeTopReaders = [];
  List<_ReaderStat> _selectedMonthTopReaders = [];
  List<Member> _membersCache = [];
  List<Escrow> _escrowsCache = [];
  
  // Günlük harcama
  DateTime _selectedDate = DateTime.now();
  List<Expense> _dailyExpenses = [];
  double _dailyTotalExpense = 0;
  bool _isLoadingDailyExpenses = false;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    _loadDailyExpenses();
  }

  Future<void> _loadStatistics() async {
    if (!mounted) return;
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
      _membersCache = members;
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
      _escrowsCache = escrows;
      _activeEscrows = escrows.where((e) => e.status == 'Ödünçte').length;
      _returnedEscrows = escrows.where((e) => e.status == 'İade Edildi').length;
      final now = DateTime.now();
      _overdueEscrows = escrows.where((e) {
        if (e.status != 'Ödünçte') return false;
        return e.dueDate.isBefore(now);
      }).length;
      _calculateTopReaders(members, escrows);
      
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

                    // Okuma Liderleri
                    _buildSectionTitle('En Cok Kitap Okuyanlar'),
                    const SizedBox(height: 16),
                    _buildTopReadersSection(),
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
                    
                    // Günlük Harcamalar
                    _buildSectionTitle('Günlük Harcamalar'),
                    const SizedBox(height: 16),
                    _buildDailyExpenses(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  void _calculateTopReaders(List<Member> members, List<Escrow> escrows) {
    final memberNameById = <int, String>{
      for (final m in members)
        if (m.id != null) m.id!: m.fullName,
    };

    final allTimeCountByMember = <int, int>{};
    final monthCountByMember = <int, int>{};

    for (final escrow in escrows) {
      allTimeCountByMember.update(
        escrow.memberId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );

      final sameMonth =
          escrow.borrowDate.year == _selectedReadersMonth.year &&
          escrow.borrowDate.month == _selectedReadersMonth.month;
      if (sameMonth) {
        monthCountByMember.update(
          escrow.memberId,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }

    List<_ReaderStat> toSortedList(Map<int, int> counts) {
      final result = counts.entries
          .map(
            (entry) => _ReaderStat(
              memberId: entry.key,
              memberName:
                  memberNameById[entry.key] ?? 'Uye #${entry.key}',
              booksReadCount: entry.value,
            ),
          )
          .toList();
      result.sort((a, b) => b.booksReadCount.compareTo(a.booksReadCount));
      return result;
    }

    _allTimeTopReaders = toSortedList(allTimeCountByMember);
    _selectedMonthTopReaders = toSortedList(monthCountByMember);
  }

  Widget _buildTopReadersSection() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, color: Color(0xFF8D6E63)),
              const SizedBox(width: 8),
              const Text(
                'Kitap Okuma Listeleri',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E2723),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  final pickedMonth = await _showMonthYearPicker(_selectedReadersMonth);
                  if (pickedMonth != null) {
                    setState(() {
                      _selectedReadersMonth = pickedMonth;
                      // Sadece ilgili listeleri guncelle; tum sayfayi reload etme.
                      _calculateTopReaders(_membersCache, _escrowsCache);
                    });
                  }
                },
                icon: const Icon(Icons.calendar_month_rounded),
                label: Text(
                  'Ay: ${DateFormat('MMMM yyyy', 'tr_TR').format(_selectedReadersMonth)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildReadersListCard(
                  title: 'Tüm Zamanlar',
                  list: _allTimeTopReaders,
                  emptyText: 'Henüz emanet kaydı yok',
                  accentColor: const Color(0xFF6D4C41),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildReadersListCard(
                  title:
                      '${DateFormat('MMMM yyyy', 'tr_TR').format(_selectedReadersMonth)}',
                  list: _selectedMonthTopReaders,
                  emptyText: 'Bu ay emanet kaydı yok',
                  accentColor: const Color(0xFF2196F3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadersListCard({
    required String title,
    required List<_ReaderStat> list,
    required String emptyText,
    required Color accentColor,
  }) {
    final topList = list.take(10).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: accentColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          if (topList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                emptyText,
                style: const TextStyle(color: Colors.grey),
              ),
            )
          else
            ...topList.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final reader = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$index',
                        style: TextStyle(
                          fontSize: 12,
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reader.memberName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF3E2723),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${reader.booksReadCount} kitap',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<DateTime?> _showMonthYearPicker(DateTime initialMonth) async {
    int selectedYear = initialMonth.year;
    int selectedMonth = initialMonth.month;
    final currentYear = DateTime.now().year;
    final years = List<int>.generate(currentYear - 2019, (i) => 2020 + i);
    const monthNames = <String>[
      'Ocak',
      'Subat',
      'Mart',
      'Nisan',
      'Mayis',
      'Haziran',
      'Temmuz',
      'Agustos',
      'Eylul',
      'Ekim',
      'Kasim',
      'Aralik',
    ];

    return showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ay ve Yıl Seç'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedYear,
                decoration: const InputDecoration(labelText: 'Yıl'),
                items: years
                    .map((y) => DropdownMenuItem<int>(value: y, child: Text('$y')))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedYear = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: selectedMonth,
                decoration: const InputDecoration(labelText: 'Ay'),
                items: List.generate(
                  12,
                  (index) => DropdownMenuItem<int>(
                    value: index + 1,
                    child: Text(monthNames[index]),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedMonth = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, DateTime(selectedYear, selectedMonth));
              },
              child: const Text('Seç'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _loadDailyExpenses() async {
    setState(() => _isLoadingDailyExpenses = true);
    try {
      final allExpenses = await _expenseService.getAll();
      final selectedDateStart = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final selectedDateEnd = selectedDateStart.add(const Duration(days: 1));
      
      _dailyExpenses = allExpenses.where((expense) {
        return expense.expenseDate.isAfter(selectedDateStart) && 
               expense.expenseDate.isBefore(selectedDateEnd);
      }).toList();
      
      _dailyTotalExpense = _dailyExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Günlük harcamalar yüklenirken hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingDailyExpenses = false);
      }
    }
  }
  
  Widget _buildDailyExpenses() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarih Seçici ve Toplam
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                      _loadDailyExpenses();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF8F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD7CCC8)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xFF8D6E63)),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('dd.MM.yyyy').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF3E2723),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down, color: Color(0xFF8D6E63)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF44336).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF44336).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Günlük Toplam',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8D6E63),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(_dailyTotalExpense),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF44336),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Harcama Listesi
          if (_isLoadingDailyExpenses)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_dailyExpenses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${DateFormat('dd.MM.yyyy').format(_selectedDate)} tarihinde harcama kaydı bulunamadı',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                // Başlık satırı
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Başlık',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Kategori',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Ödeme',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Tutar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF5D4037),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Harcama listesi
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _dailyExpenses.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final expense = _dailyExpenses[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  expense.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: Color(0xFF3E2723),
                                  ),
                                ),
                                if (expense.description != null && expense.description!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    expense.description!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (expense.payeeName != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        size: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        expense.payeeName!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8D6E63).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                expense.category,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF8D6E63),
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              expense.paymentMethod ?? '-',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(expense.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFFF44336),
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
        ],
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

class _ReaderStat {
  final int _memberId;
  final String memberName;
  final int booksReadCount;

  const _ReaderStat({
    required int memberId,
    required this.memberName,
    required this.booksReadCount,
  }) : _memberId = memberId;
}

