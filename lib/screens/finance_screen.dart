import 'package:flutter/material.dart';
import '../models/income.dart';
import '../models/expense.dart';
import '../models/check.dart';
import '../models/promissory_note.dart';
import '../models/personnel.dart';
import '../models/company.dart';
import '../services/income_service.dart';
import '../services/expense_service.dart';
import '../services/check_service.dart';
import '../services/promissory_note_service.dart';
import '../services/personnel_service.dart';
import '../services/company_service.dart';

class FinanceScreen extends StatefulWidget {
  final int? initialTab;
  final String? initialTransactionType;
  final String? initialCategory;
  final Personnel? personnel;
  
  const FinanceScreen({
    super.key,
    this.initialTab,
    this.initialTransactionType,
    this.initialCategory,
    this.personnel,
  });

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final IncomeService _incomeService = IncomeService();
  final ExpenseService _expenseService = ExpenseService();
  final CheckService _checkService = CheckService();
  final PromissoryNoteService _promissoryNoteService = PromissoryNoteService();
  final CompanyService _companyService = CompanyService();
  
  String _selectedTransactionType = 'Gelir'; // Gelir veya Gider

  // Income
  List<Income> _incomes = [];
  bool _isLoadingIncomes = true;
  final TextEditingController _incomeSearchController = TextEditingController();
  String _incomeSearchQuery = '';

  // Expense
  List<Expense> _expenses = [];
  bool _isLoadingExpenses = true;
  final TextEditingController _expenseSearchController = TextEditingController();
  String _expenseSearchQuery = '';

  // Check
  List<Check> _checks = [];
  bool _isLoadingChecks = true;
  final TextEditingController _checkSearchController = TextEditingController();
  String _checkSearchQuery = '';

  // Promissory Note
  List<PromissoryNote> _promissoryNotes = [];
  bool _isLoadingNotes = true;
  final TextEditingController _noteSearchController = TextEditingController();
  String _noteSearchQuery = '';

  // Çek/Senet Filtreleme
  final TextEditingController _companySearchController = TextEditingController();
  final TextEditingController _documentNoSearchController = TextEditingController();
  final TextEditingController _detailedSearchController = TextEditingController();
  String _documentTypeFilter = 'Tümü'; // Çek, Senet, Tümü
  String _statusFilter = 'Tümü'; // Ödendi, Ödenmedi, Tümü
  DateTime? _paymentDateStart;
  DateTime? _paymentDateEnd;
  dynamic _selectedDocument; // Seçili çek veya senet
  List<Company> _companies = [];
  Company? _selectedCompany; // Seçili firma

  @override
  void initState() {
    super.initState();
    if (widget.initialTransactionType != null) {
      _selectedTransactionType = widget.initialTransactionType!;
    }
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab ?? 0,
    );
    _loadAllData();
    
    // Eğer maaş ödeme için geldiyse, gider dialogunu aç
    if (widget.initialCategory != null && widget.initialCategory == 'Maaş') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddEditExpenseDialog(initialCategory: 'Maaş', personnel: widget.personnel);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _incomeSearchController.dispose();
    _expenseSearchController.dispose();
    _checkSearchController.dispose();
    _noteSearchController.dispose();
    _companySearchController.dispose();
    _documentNoSearchController.dispose();
    _detailedSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadIncomes(),
      _loadExpenses(),
      _loadChecks(),
      _loadPromissoryNotes(),
      _loadCompanies(),
    ]);
  }

  Future<void> _loadCompanies() async {
    try {
      final companies = await _companyService.getAll();
      setState(() {
        _companies = companies;
      });
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  Future<void> _loadIncomes() async {
    setState(() => _isLoadingIncomes = true);
    try {
      final incomes = await _incomeService.getAll();
      setState(() {
        _incomes = incomes;
        _isLoadingIncomes = false;
      });
    } catch (e) {
      setState(() => _isLoadingIncomes = false);
    }
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoadingExpenses = true);
    try {
      final expenses = await _expenseService.getAll();
      setState(() {
        _expenses = expenses;
        _isLoadingExpenses = false;
      });
    } catch (e) {
      setState(() => _isLoadingExpenses = false);
    }
  }

  Future<void> _loadChecks() async {
    setState(() => _isLoadingChecks = true);
    try {
      final checks = await _checkService.getAll();
      setState(() {
        _checks = checks;
        _isLoadingChecks = false;
      });
    } catch (e) {
      setState(() => _isLoadingChecks = false);
    }
  }

  Future<void> _loadPromissoryNotes() async {
    setState(() => _isLoadingNotes = true);
    try {
      final notes = await _promissoryNoteService.getAll();
      setState(() {
        _promissoryNotes = notes;
        _isLoadingNotes = false;
      });
    } catch (e) {
      setState(() => _isLoadingNotes = false);
    }
  }

  List<Income> get _filteredIncomes {
    if (_incomeSearchQuery.isEmpty) return _incomes;
    return _incomes.where((i) {
      return i.title.toLowerCase().contains(_incomeSearchQuery.toLowerCase()) ||
          i.incomeNo.toLowerCase().contains(_incomeSearchQuery.toLowerCase()) ||
          (i.payerName?.toLowerCase().contains(_incomeSearchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  List<Expense> get _filteredExpenses {
    if (_expenseSearchQuery.isEmpty) return _expenses;
    return _expenses.where((e) {
      return e.title.toLowerCase().contains(_expenseSearchQuery.toLowerCase()) ||
          e.expenseNo.toLowerCase().contains(_expenseSearchQuery.toLowerCase()) ||
          (e.payeeName?.toLowerCase().contains(_expenseSearchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  List<Check> get _filteredChecks {
    if (_checkSearchQuery.isEmpty) return _checks;
    return _checks.where((c) {
      return c.checkNo.toLowerCase().contains(_checkSearchQuery.toLowerCase()) ||
          c.bankName.toLowerCase().contains(_checkSearchQuery.toLowerCase()) ||
          (c.drawerName?.toLowerCase().contains(_checkSearchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  List<PromissoryNote> get _filteredNotes {
    if (_noteSearchQuery.isEmpty) return _promissoryNotes;
    return _promissoryNotes.where((n) {
      return n.noteNo.toLowerCase().contains(_noteSearchQuery.toLowerCase()) ||
          n.debtorName.toLowerCase().contains(_noteSearchQuery.toLowerCase());
    }).toList();
  }

  // Birleştirilmiş çek/senet listesi (tablo için)
  List<Map<String, dynamic>> get _combinedDocuments {
    final List<Map<String, dynamic>> combined = [];
    
    // Çekleri ekle
    for (var check in _checks) {
      combined.add({
        'type': 'Çek',
        'id': check.id,
        'no': check.checkNo,
        'issueDate': check.issueDate,
        'dueDate': check.dueDate,
        'company': check.drawerName ?? '',
        'amount': check.amount,
        'status': check.status,
        'description': check.notes ?? '',
        'direction': check.direction,
        'data': check,
      });
    }
    
    // Senetleri ekle
    for (var note in _promissoryNotes) {
      combined.add({
        'type': 'Senet',
        'id': note.id,
        'no': note.noteNo,
        'issueDate': note.issueDate,
        'dueDate': note.dueDate,
        'company': note.debtorName,
        'amount': note.amount,
        'status': note.status,
        'description': note.description ?? '',
        'direction': note.direction,
        'data': note,
      });
    }
    
    return combined;
  }

  // Filtrelenmiş birleştirilmiş liste
  List<Map<String, dynamic>> get _filteredCombinedDocuments {
    var filtered = _combinedDocuments;
    
    // Tür filtresi
    if (_documentTypeFilter != 'Tümü') {
      filtered = filtered.where((doc) => doc['type'] == _documentTypeFilter).toList();
    }
    
    // Durum filtresi
    if (_statusFilter == 'Ödendi') {
      filtered = filtered.where((doc) => doc['status'] == 'Ödendi' || doc['status'] == 'Tahsil Edildi').toList();
    } else if (_statusFilter == 'Ödenmedi') {
      filtered = filtered.where((doc) => doc['status'] == 'Beklemede').toList();
    }
    
    // Seçili firma filtresi
    if (_selectedCompany != null) {
      filtered = filtered.where((doc) => 
        (doc['company'] as String).toLowerCase() == _selectedCompany!.name.toLowerCase()
      ).toList();
    } else if (_companySearchController.text.isNotEmpty) {
      // Firma arama
      final query = _companySearchController.text.toLowerCase();
      filtered = filtered.where((doc) => 
        (doc['company'] as String).toLowerCase().contains(query)
      ).toList();
    }
    
    // Çek/Senet No arama
    if (_documentNoSearchController.text.isNotEmpty) {
      final query = _documentNoSearchController.text.toLowerCase();
      filtered = filtered.where((doc) => 
        (doc['no'] as String).toLowerCase().contains(query)
      ).toList();
    }
    
    // Detaylı arama
    if (_detailedSearchController.text.isNotEmpty) {
      final query = _detailedSearchController.text.toLowerCase();
      filtered = filtered.where((doc) => 
        (doc['company'] as String).toLowerCase().contains(query) ||
        (doc['no'] as String).toLowerCase().contains(query) ||
        (doc['description'] as String).toLowerCase().contains(query)
      ).toList();
    }
    
    // Tarih aralığı filtresi
    if (_paymentDateStart != null || _paymentDateEnd != null) {
      filtered = filtered.where((doc) {
        final dueDate = doc['dueDate'] as DateTime;
        if (_paymentDateStart != null && dueDate.isBefore(_paymentDateStart!)) return false;
        if (_paymentDateEnd != null && dueDate.isAfter(_paymentDateEnd!)) return false;
        return true;
      }).toList();
    }
    
    // ID'ye göre sırala (en yeni önce)
    filtered.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
    
    return filtered;
  }

  double get _totalIncome {
    return _incomes.fold(0.0, (sum, income) => sum + income.amount);
  }

  double get _totalExpense {
    return _expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double get _totalCheck {
    return _checks.where((c) => c.status == 'Beklemede').fold(0.0, (sum, check) => sum + check.amount);
  }

  double get _totalNote {
    return _promissoryNotes.where((n) => n.status == 'Beklemede').fold(0.0, (sum, note) => sum + note.amount);
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
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 32,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Finans Yönetimi',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                    Text(
                      'Gelir, gider, çek ve senet işlemleri',
                      style: TextStyle(fontSize: 14, color: Color(0xFF8D6E63)),
                    ),
                  ],
                ),
                const Spacer(),
                // Stats Cards
                _buildStatCard('Gelir', _totalIncome, Icons.trending_up, Colors.green),
                const SizedBox(width: 12),
                _buildStatCard('Gider', _totalExpense, Icons.trending_down, Colors.red),
                const SizedBox(width: 12),
                _buildStatCard('Çek', _totalCheck, Icons.receipt_long, Colors.blue),
                const SizedBox(width: 12),
                _buildStatCard('Senet', _totalNote, Icons.description, Colors.orange),
              ],
            ),
            const SizedBox(height: 24),

            // Tabs
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF2E7D32),
                unselectedLabelColor: const Color(0xFF8D6E63),
                indicatorColor: const Color(0xFF2E7D32),
                indicatorWeight: 3,
                onTap: (index) {
                  // Tab değiştiğinde dialog'u kapat (eğer açıksa)
                },
                tabs: const [
                  Tab(text: 'Gelir / Gider', icon: Icon(Icons.account_balance)),
                  Tab(text: 'Çek / Senet', icon: Icon(Icons.receipt_long)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTransactionTab(), // Gelir/Gider
                  _buildDocumentTab(), // Çek/Senet
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, double value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '₺${value.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTab() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Type Selector
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD7CCC8)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTypeButton('Gelir', Colors.green, Icons.trending_up),
                      _buildTypeButton('Gider', Colors.red, Icons.trending_down),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF8F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD7CCC8)),
                    ),
                    child: TextField(
                      controller: _selectedTransactionType == 'Gelir' 
                          ? _incomeSearchController 
                          : _expenseSearchController,
                      onChanged: (value) => setState(() {
                        if (_selectedTransactionType == 'Gelir') {
                          _incomeSearchQuery = value;
                        } else {
                          _expenseSearchQuery = value;
                        }
                      }),
                      decoration: InputDecoration(
                        hintText: _selectedTransactionType == 'Gelir' 
                            ? 'Gelir ara...' 
                            : 'Gider ara...',
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8D6E63)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_selectedTransactionType == 'Gelir') {
                      _showAddEditIncomeDialog();
                    } else {
                      _showAddEditExpenseDialog();
                    }
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: Text('Yeni $_selectedTransactionType'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedTransactionType == 'Gelir' ? Colors.green : Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedTransactionType == 'Gelir'
                ? (_isLoadingIncomes
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredIncomes.isEmpty
                        ? const Center(child: Text('Gelir kaydı bulunamadı'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _filteredIncomes.length,
                            itemBuilder: (context, index) {
                              final income = _filteredIncomes[index];
                              return _buildIncomeCard(income);
                            },
                          ))
                : (_isLoadingExpenses
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredExpenses.isEmpty
                        ? const Center(child: Text('Gider kaydı bulunamadı'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _filteredExpenses.length,
                            itemBuilder: (context, index) {
                              final expense = _filteredExpenses[index];
                              return _buildExpenseCard(expense);
                            },
                          )),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String type, Color color, IconData icon) {
    final isSelected = _selectedTransactionType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedTransactionType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : color),
            const SizedBox(width: 8),
            Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTab() {
    final filteredDocs = _filteredCombinedDocuments;
    final isLoading = _isLoadingChecks || _isLoadingNotes;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Üst toolbar - Arama ve Butonlar
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // İlk satır: Arama ve butonlar
                Row(
                  children: [
                    // Firma seçimi
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF8F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD7CCC8)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Company?>(
                            value: _selectedCompany,
                            hint: const Text('Firma Seçiniz (Tüm Firmalar)', style: TextStyle(color: Color(0xFF8D6E63))),
                            isExpanded: true,
                            icon: const Icon(Icons.business, color: Color(0xFF8D6E63)),
                            items: [
                              const DropdownMenuItem<Company?>(
                                value: null,
                                child: Text('Tüm Firmalar'),
                              ),
                              ..._companies.map((company) => DropdownMenuItem<Company?>(
                                value: company,
                                child: Text(company.name),
                              )),
                            ],
                            onChanged: (value) => setState(() {
                              _selectedCompany = value;
                              if (value != null) {
                                _companySearchController.text = value.name;
                              } else {
                                _companySearchController.clear();
                              }
                            }),
                          ),
                        ),
                      ),
                    ),
                    if (_selectedCompany != null) const SizedBox(width: 8),
                    if (_selectedCompany != null)
                      IconButton(
                        onPressed: () => setState(() {
                          _selectedCompany = null;
                          _companySearchController.clear();
                        }),
                        icon: const Icon(Icons.clear),
                        tooltip: 'Firma filtresini temizle',
                        color: Colors.red,
                      ),
                    const SizedBox(width: 12),
                    // Arama kutusu
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF8F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD7CCC8)),
                        ),
                        child: TextField(
                          controller: _detailedSearchController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Firma, Çek/Senet No veya açıklama ile ara...',
                            hintStyle: TextStyle(color: Color(0xFFBDBDBD)),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: Color(0xFF8D6E63),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Çek/Senet Yaz butonu
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_documentTypeFilter == 'Çek' || _documentTypeFilter == 'Tümü') {
                          _showAddEditCheckDialog(null, _selectedCompany);
                        } else {
                          _showAddEditPromissoryNoteDialog(null, _selectedCompany);
                        }
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Çek/Senet Yaz'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B4513),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                    if (_selectedDocument != null) const SizedBox(width: 8),
                    if (_selectedDocument != null)
                      ElevatedButton.icon(
                        onPressed: () => _paySelectedDocument(),
                        icon: const Icon(Icons.payment),
                        label: const Text('Seçiliyi Öde'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                    if (_selectedDocument != null) const SizedBox(width: 8),
                    if (_selectedDocument != null)
                      ElevatedButton.icon(
                        onPressed: () => _deleteSelectedDocument(),
                        icon: const Icon(Icons.delete),
                        label: const Text('Sil'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Filtre butonları
                Row(
                  children: [
                    // Tür seçimi
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF8F5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD7CCC8)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildFilterChip('Çek', 'Çek', Colors.blue),
                          _buildFilterChip('Senet', 'Senet', Colors.orange),
                          _buildFilterChip('Tümü', 'Tümü', Colors.grey),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Durum filtreleri
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _statusFilter = 'Ödendi'),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Ödenenleri Göster'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _statusFilter == 'Ödendi' ? Colors.green : Colors.green.shade100,
                        foregroundColor: _statusFilter == 'Ödendi' ? Colors.white : Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _statusFilter = 'Ödenmedi'),
                      icon: const Icon(Icons.pending, size: 18),
                      label: const Text('Ödenecekleri Göster'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _statusFilter == 'Ödenmedi' ? Colors.orange : Colors.orange.shade100,
                        foregroundColor: _statusFilter == 'Ödenmedi' ? Colors.white : Colors.orange.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _statusFilter = 'Tümü'),
                      icon: const Icon(Icons.list, size: 18),
                      label: const Text('Tümünü Göster'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _statusFilter == 'Tümü' ? Colors.blue : Colors.blue.shade100,
                        foregroundColor: _statusFilter == 'Tümü' ? Colors.white : Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Tablo
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredDocs.isEmpty
                    ? const Center(child: Text('Kayıt bulunamadı'))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth,
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: DataTable(
                                  headingRowColor: MaterialStateProperty.all(const Color(0xFFFAF8F5)),
                                  columnSpacing: 20,
                                  horizontalMargin: 20,
                                  columns: const [
                                    DataColumn(label: Text('No', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Türü', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Yön', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Yazma Tarihi', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Ödeme Tarihi', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Firma', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Tutar', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Durum', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Açıklama', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                  rows: filteredDocs.map((doc) {
                              final isSelected = _selectedDocument != null && 
                                  _selectedDocument['id'] == doc['id'] && 
                                  _selectedDocument['type'] == doc['type'];
                              final direction = doc['data'] is Check 
                                  ? (doc['data'] as Check).direction
                                  : (doc['data'] as PromissoryNote).direction;
                              return DataRow(
                                selected: isSelected,
                                color: MaterialStateProperty.all(
                                  isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
                                ),
                                cells: [
                                  DataCell(Text('${doc['id']}')),
                                  DataCell(Text(doc['type'])),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: direction == 'Alınacak' 
                                            ? Colors.blue.withValues(alpha: 0.2)
                                            : Colors.red.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        direction,
                                        style: TextStyle(
                                          color: direction == 'Alınacak' 
                                              ? Colors.blue.shade700
                                              : Colors.red.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(_formatDate(doc['issueDate'] as DateTime))),
                                  DataCell(Text(_formatDate(doc['dueDate'] as DateTime))),
                                  DataCell(Text(doc['company'])),
                                  DataCell(Text('₺${(doc['amount'] as double).toStringAsFixed(2)}')),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: doc['status'] == 'Ödendi' || doc['status'] == 'Tahsil Edildi'
                                            ? Colors.green.withValues(alpha: 0.2)
                                            : Colors.orange.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        doc['status'],
                                        style: TextStyle(
                                          color: doc['status'] == 'Ödendi' || doc['status'] == 'Tahsil Edildi'
                                              ? Colors.green.shade700
                                              : Colors.orange.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 200,
                                      child: Text(
                                        doc['description'],
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                  ),
                                ],
                                onSelectChanged: (selected) {
                                  if (selected != null && selected) {
                                    setState(() {
                                      _selectedDocument = doc;
                                    });
                                  }
                                },
                              );
                            }).toList(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, Color color) {
    final isSelected = _documentTypeFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _documentTypeFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Future<void> _paySelectedDocument() async {
    if (_selectedDocument == null) return;
    
    final type = _selectedDocument!['type'] as String;
    final data = _selectedDocument!['data'];
    
    if (type == 'Çek') {
      final check = data as Check;
      final updatedCheck = check.copyWith(
        status: 'Tahsil Edildi',
        collectionDate: DateTime.now(),
      );
      await _checkService.update(updatedCheck);
    } else {
      final note = data as PromissoryNote;
      final updatedNote = note.copyWith(
        status: 'Ödendi',
        paymentDate: DateTime.now(),
      );
      await _promissoryNoteService.update(updatedNote);
    }
    
    setState(() {
      _selectedDocument = null;
      _loadChecks();
      _loadPromissoryNotes();
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ödeme işlemi tamamlandı')),
      );
    }
  }

  Future<void> _deleteSelectedDocument() async {
    if (_selectedDocument == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Silme Onayı'),
        content: const Text('Bu kaydı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final type = _selectedDocument!['type'] as String;
      final id = _selectedDocument!['id'] as int;
      
      if (type == 'Çek') {
        await _checkService.delete(id);
      } else {
        await _promissoryNoteService.delete(id);
      }
      
      setState(() {
        _selectedDocument = null;
        _loadChecks();
        _loadPromissoryNotes();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt silindi')),
        );
      }
    }
  }


  Widget _buildIncomeCard(Income income) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          child: const Icon(Icons.trending_up, color: Colors.green),
        ),
        title: Text(income.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${income.formattedDate} • ${income.category}'),
        trailing: Text(
          income.formattedAmount,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        onTap: () => _showIncomeDetailDialog(income),
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          child: const Icon(Icons.trending_down, color: Colors.red),
        ),
        title: Text(expense.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${expense.formattedDate} • ${expense.category}'),
        trailing: Text(
          expense.formattedAmount,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
        ),
        onTap: () => _showExpenseDetailDialog(expense),
      ),
    );
  }

  Widget _buildCheckCard(Check check) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: check.isOverdue
              ? Colors.red.withValues(alpha: 0.1)
              : Colors.blue.withValues(alpha: 0.1),
          child: Icon(
            check.isOverdue ? Icons.warning : Icons.receipt_long,
            color: check.isOverdue ? Colors.red : Colors.blue,
          ),
        ),
        title: Text('${check.bankName} - ${check.checkNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Vade: ${check.formattedDueDate} • ${check.status}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              check.formattedAmount,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (check.isOverdue)
              const Text('Gecikmiş!', style: TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ),
        onTap: () => _showCheckDetailDialog(check),
      ),
    );
  }

  Widget _buildPromissoryNoteCard(PromissoryNote note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: note.isOverdue
              ? Colors.red.withValues(alpha: 0.1)
              : Colors.orange.withValues(alpha: 0.1),
          child: Icon(
            note.isOverdue ? Icons.warning : Icons.description,
            color: note.isOverdue ? Colors.red : Colors.orange,
          ),
        ),
        title: Text(note.debtorName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Vade: ${note.formattedDueDate} • ${note.status}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              note.formattedAmount,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (note.isOverdue)
              const Text('Gecikmiş!', style: TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ),
        onTap: () => _showPromissoryNoteDetailDialog(note),
      ),
    );
  }

  // Dialog methods - Document type selection removed, now directly calling based on _selectedDocumentType

  Future<void> _showAddEditIncomeDialog([Income? income]) async {
    final isEdit = income != null;
    final titleController = TextEditingController(text: income?.title ?? '');
    final amountController = TextEditingController(text: income?.amount.toStringAsFixed(2) ?? '');
    final descriptionController = TextEditingController(text: income?.description ?? '');
    String selectedCategory = income?.category ?? 'Kitap Satışı';
    final categories = ['Kitap Satışı', 'Üyelik Ücreti', 'Ceza', 'Diğer'];
    DateTime selectedDate = income?.incomeDate ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Gelir Düzenle' : 'Yeni Gelir Ekle'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Başlık *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Tutar *'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (value) => setDialogState(() => selectedCategory = value!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Açıklama'),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: Text('Tarih: ${selectedDate.day}.${selectedDate.month}.${selectedDate.year}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setDialogState(() => selectedDate = date);
                      }
                    },
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
                if (titleController.text.isEmpty || amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Başlık ve tutar zorunludur')),
                  );
                  return;
                }
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Geçerli bir tutar giriniz')),
                  );
                  return;
                }
                final updatedIncome = Income(
                  id: income?.id,
                  incomeNo: income?.incomeNo ?? 'GEL-${DateTime.now().year}-${(_incomes.length + 1).toString().padLeft(4, '0')}',
                  title: titleController.text,
                  description: descriptionController.text.isEmpty ? null : descriptionController.text,
                  amount: amount,
                  category: selectedCategory,
                  incomeDate: selectedDate,
                  payerName: income?.payerName,
                  payerPhone: income?.payerPhone,
                  payerEmail: income?.payerEmail,
                  paymentMethod: income?.paymentMethod,
                  referenceNo: income?.referenceNo,
                  notes: income?.notes,
                  relatedMemberId: income?.relatedMemberId,
                  relatedEscrowId: income?.relatedEscrowId,
                  createdBy: income?.createdBy,
                );
                if (isEdit) {
                  await _incomeService.update(updatedIncome);
                } else {
                  await _incomeService.insert(updatedIncome);
                }
                Navigator.pop(context);
                _loadIncomes();
              },
              child: Text(isEdit ? 'Kaydet' : 'Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddEditExpenseDialog({String? initialCategory, Personnel? personnel, Expense? expense}) async {
    final isEdit = expense != null;
    final titleController = TextEditingController(text: expense?.title ?? '');
    final amountController = TextEditingController(text: expense?.amount.toStringAsFixed(2) ?? '');
    final descriptionController = TextEditingController(text: expense?.description ?? '');
    
    // Maaş kategorisinde ve düzenleme modunda, payeeName ile personel bul
    Personnel? relatedPersonnel;
    if (isEdit && expense.category == 'Maaş') {
      final payeeName = expense.payeeName;
      if (payeeName != null && payeeName.isNotEmpty) {
        final personnelServiceForSearch = PersonnelService();
        final allPersonnel = await personnelServiceForSearch.getAll();
        // PayeeName'i personel adı soyadı ile eşleştir
        try {
          relatedPersonnel = allPersonnel.firstWhere(
            (p) => '${p.name} ${p.surname}' == payeeName,
          );
        } catch (_) {
          // Tam eşleşme bulunamadı, kısmi eşleşme dene
          try {
            relatedPersonnel = allPersonnel.firstWhere(
              (p) => payeeName.contains(p.name) || payeeName.contains(p.surname),
            );
          } catch (_) {
            // Eşleşme bulunamadı, null kalacak
            relatedPersonnel = null;
          }
        }
      }
    }
    
    final finalPersonnel = personnel ?? relatedPersonnel;
    final accountNoController = TextEditingController(text: finalPersonnel?.accountNo ?? '');
    final ibanController = TextEditingController(
      text: finalPersonnel?.iban != null ? finalPersonnel!.iban.replaceFirst('TR12', '') : '',
    );
    String selectedCategory = expense?.category ?? initialCategory ?? 'Kira';
    final categories = ['Kira', 'Maaş', 'Kırtasiye', 'Kitap Alımı', 'Bakım', 'Diğer'];
    DateTime selectedDate = expense?.expenseDate ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Gider Düzenle' : 'Yeni Gider Ekle'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Başlık *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Tutar *'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (value) => setDialogState(() => selectedCategory = value!),
                  ),
                  const SizedBox(height: 12),
                  // Maaş kategorisi seçiliyse hesap no ve IBAN alanları
                  if (selectedCategory == 'Maaş') ...[
                    TextField(
                      controller: accountNoController,
                      decoration: const InputDecoration(
                        labelText: 'Hesap No',
                        prefixIcon: Icon(Icons.account_box_outlined),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Text(
                              'TR12',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: ibanController,
                            decoration: const InputDecoration(
                              labelText: 'IBAN',
                              prefixIcon: Icon(Icons.account_balance_outlined),
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Açıklama'),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: Text('Tarih: ${selectedDate.day}.${selectedDate.month}.${selectedDate.year}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setDialogState(() => selectedDate = date);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Dialog'u kapat
                // Eğer personnel parametresi varsa, finans ekranından da çık (personel ekranına dön)
                if (personnel != null) {
                  Navigator.pop(context);
                }
              },
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Başlık ve tutar zorunludur')),
                  );
                  return;
                }
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Geçerli bir tutar giriniz')),
                  );
                  return;
                }
                final updatedExpense = Expense(
                  id: expense?.id,
                  expenseNo: expense?.expenseNo ?? 'GID-${DateTime.now().year}-${(_expenses.length + 1).toString().padLeft(4, '0')}',
                  title: titleController.text,
                  description: descriptionController.text.isEmpty ? null : descriptionController.text,
                  amount: amount,
                  category: selectedCategory,
                  expenseDate: selectedDate,
                  payeeName: expense?.payeeName,
                  payeePhone: expense?.payeePhone,
                  payeeEmail: expense?.payeeEmail,
                  paymentMethod: expense?.paymentMethod,
                  referenceNo: expense?.referenceNo,
                  invoiceNo: expense?.invoiceNo,
                  notes: expense?.notes,
                  relatedCompanyId: expense?.relatedCompanyId,
                  createdBy: expense?.createdBy,
                );
                if (isEdit) {
                  await _expenseService.update(updatedExpense);
                } else {
                  await _expenseService.insert(updatedExpense);
                }
                Navigator.pop(context); // Dialog'u kapat
                // Eğer personnel parametresi varsa ve yeni ekleme ise, finans ekranından da çık (personel ekranına dön)
                if (personnel != null && !isEdit) {
                  Navigator.pop(context);
                }
                _loadExpenses();
              },
              child: Text(isEdit ? 'Kaydet' : 'Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddEditCheckDialog([Check? check, Company? company]) async {
    final isEdit = check != null;
    final bankNameController = TextEditingController(text: check?.bankName ?? '');
    final accountNoController = TextEditingController(text: check?.accountNo ?? '');
    final ibanController = TextEditingController(text: check?.iban ?? '');
    final checkNumberController = TextEditingController(text: check?.checkNumber ?? '');
    final amountController = TextEditingController(text: check?.amount.toStringAsFixed(2) ?? '');
    final drawerNameController = TextEditingController(
      text: check?.drawerName ?? company?.name ?? '',
    );
    final PersonnelService personnelService = PersonnelService();
    List<Personnel> personnelList = [];
    int? selectedPersonnelId;
    Company? selectedCompany = company ?? (check?.drawerName != null && _companies.isNotEmpty
        ? _companies.firstWhere(
            (c) => c.name.toLowerCase() == check!.drawerName!.toLowerCase(),
            orElse: () => _companies.first,
          )
        : null);
    String selectedDirection = check?.direction ?? 'Alınacak';
    DateTime issueDate = check?.issueDate ?? DateTime.now();
    DateTime dueDate = check?.dueDate ?? DateTime.now().add(const Duration(days: 30));

    // Personel listesini yükle
    personnelList = await personnelService.getAll();

    await showDialog(
      context: context,
      builder: (context) {
        String dialogSelectedDirection = selectedDirection;
        DateTime dialogIssueDate = issueDate;
        DateTime dialogDueDate = dueDate;
        int? dialogSelectedPersonnelId = selectedPersonnelId;
        Company? dialogSelectedCompany = selectedCompany;
        
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(isEdit ? 'Çek Düzenle' : 'Yeni Çek Ekle'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Firma seçimi
                  DropdownButtonFormField<Company?>(
                    value: dialogSelectedCompany,
                    decoration: const InputDecoration(
                      labelText: 'Firma *',
                      prefixIcon: Icon(Icons.business),
                    ),
                    items: [
                      const DropdownMenuItem<Company?>(
                        value: null,
                        child: Text('Firma Seçiniz'),
                      ),
                      ..._companies.map((company) => DropdownMenuItem<Company?>(
                        value: company,
                        child: Text(company.name),
                      )),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        dialogSelectedCompany = value;
                        if (value != null) {
                          drawerNameController.text = value.name;
                        } else {
                          drawerNameController.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bankNameController,
                    decoration: const InputDecoration(labelText: 'Banka Adı *'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Personel (Opsiyonel)',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Personel Seçiniz'),
                      ),
                      ...personnelList.map((personnel) => DropdownMenuItem<int>(
                        value: personnel.id,
                        child: Text('${personnel.name} ${personnel.surname}'),
                      )),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        dialogSelectedPersonnelId = value;
                        if (value != null) {
                          final selectedPersonnel = personnelList.firstWhere((p) => p.id == value);
                          accountNoController.text = selectedPersonnel.accountNo;
                          // IBAN'ı otomatik doldur
                          ibanController.text = selectedPersonnel.iban;
                        } else {
                          accountNoController.clear();
                          ibanController.clear();
                        }
                      });
                    },
                    value: dialogSelectedPersonnelId,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: accountNoController,
                    decoration: const InputDecoration(
                      labelText: 'Hesap No *',
                      hintText: 'Personel seçilirse otomatik doldurulur',
                      prefixIcon: Icon(Icons.account_box_outlined),
                    ),
                    readOnly: selectedPersonnelId != null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF8F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD7CCC8)),
                          ),
                          child: const Text(
                            'TR12',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5D4037),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: ibanController,
                          decoration: const InputDecoration(
                            labelText: 'IBAN',
                            hintText: 'Personel seçilirse otomatik doldurulur',
                            prefixIcon: Icon(Icons.account_balance_outlined),
                          ),
                          readOnly: selectedPersonnelId != null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: checkNumberController,
                    decoration: const InputDecoration(labelText: 'Çek Numarası *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Tutar *'),
                  ),
                  const SizedBox(height: 12),
                  // Firma seçimi (manuel giriş için opsiyonel)
                  TextField(
                    controller: drawerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Keşideci Adı / Firma',
                      hintText: 'Firma seçilirse otomatik doldurulur',
                    ),
                    readOnly: dialogSelectedCompany != null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: dialogSelectedDirection,
                    decoration: const InputDecoration(labelText: 'Yön *'),
                    items: const [
                      DropdownMenuItem(value: 'Alınacak', child: Text('Alınacak')),
                      DropdownMenuItem(value: 'Verilecek', child: Text('Verilecek')),
                    ],
                    onChanged: (value) => setDialogState(() => dialogSelectedDirection = value!),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: Text('Keşide Tarihi: ${issueDate.day}.${issueDate.month}.${issueDate.year}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: issueDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setDialogState(() => issueDate = date);
                      }
                    },
                  ),
                  ListTile(
                    title: Text('Vade Tarihi: ${dueDate.day}.${dueDate.month}.${dueDate.year}'),
                    trailing: const Icon(Icons.event),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: dueDate,
                        firstDate: issueDate,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setDialogState(() => dueDate = date);
                      }
                    },
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
                if (bankNameController.text.isEmpty || 
                    accountNoController.text.isEmpty || 
                    checkNumberController.text.isEmpty ||
                    amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Zorunlu alanları doldurunuz')),
                  );
                  return;
                }
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Geçerli bir tutar giriniz')),
                  );
                  return;
                }
                final updatedCheck = Check(
                  id: check?.id,
                  checkNo: check?.checkNo ?? 'CEK-${DateTime.now().year}-${(_checks.length + 1).toString().padLeft(4, '0')}',
                  bankName: bankNameController.text,
                  accountNo: accountNoController.text,
                  iban: ibanController.text.isEmpty ? null : ibanController.text,
                  checkNumber: checkNumberController.text,
                  amount: amount,
                  issueDate: dialogIssueDate,
                  dueDate: dialogDueDate,
                  drawerName: dialogSelectedCompany != null ? dialogSelectedCompany!.name : (drawerNameController.text.isEmpty ? null : drawerNameController.text),
                  drawerPhone: check?.drawerPhone ?? dialogSelectedCompany?.phone,
                  drawerEmail: check?.drawerEmail ?? dialogSelectedCompany?.email,
                  status: check?.status ?? 'Beklemede',
                  direction: dialogSelectedDirection,
                  collectionDate: check?.collectionDate,
                  collectionMethod: check?.collectionMethod,
                  notes: check?.notes,
                  relatedIncomeId: check?.relatedIncomeId,
                  relatedExpenseId: check?.relatedExpenseId,
                  createdBy: check?.createdBy,
                );
                if (isEdit) {
                  await _checkService.update(updatedCheck);
                } else {
                  await _checkService.insert(updatedCheck);
                }
                Navigator.pop(context);
                _loadChecks();
              },
              child: Text(isEdit ? 'Kaydet' : 'Ekle'),
            ),
          ],
        ),
      );
      }
    );
  }

  Future<void> _showAddEditPromissoryNoteDialog([PromissoryNote? note, Company? company]) async {
    final isEdit = note != null;
    final debtorNameController = TextEditingController(
      text: note?.debtorName ?? company?.name ?? '',
    );
    final amountController = TextEditingController(text: note?.amount.toStringAsFixed(2) ?? '');
    final descriptionController = TextEditingController(text: note?.description ?? '');
    Company? selectedCompany = company ?? (note?.debtorName != null && _companies.isNotEmpty
        ? _companies.firstWhere(
            (c) => c.name.toLowerCase() == note!.debtorName.toLowerCase(),
            orElse: () => _companies.first,
          )
        : null);
    String selectedDirection = note?.direction ?? 'Alınacak';
    DateTime issueDate = note?.issueDate ?? DateTime.now();
    DateTime dueDate = note?.dueDate ?? DateTime.now().add(const Duration(days: 30));

    await showDialog(
      context: context,
      builder: (context) {
        String dialogSelectedDirection = selectedDirection;
        DateTime dialogIssueDate = issueDate;
        DateTime dialogDueDate = dueDate;
        Company? dialogSelectedCompany = selectedCompany;
        
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Senet Düzenle' : 'Yeni Senet Ekle'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Firma seçimi
                  DropdownButtonFormField<Company?>(
                    value: dialogSelectedCompany,
                    decoration: const InputDecoration(
                      labelText: 'Firma *',
                      prefixIcon: Icon(Icons.business),
                    ),
                    items: [
                      const DropdownMenuItem<Company?>(
                        value: null,
                        child: Text('Firma Seçiniz'),
                      ),
                      ..._companies.map((company) => DropdownMenuItem<Company?>(
                        value: company,
                        child: Text(company.name),
                      )),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        dialogSelectedCompany = value;
                        if (value != null) {
                          debtorNameController.text = value.name;
                        } else {
                          debtorNameController.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: debtorNameController,
                    decoration: const InputDecoration(
                      labelText: 'Borçlu Adı *',
                      hintText: 'Firma seçilirse otomatik doldurulur',
                    ),
                    readOnly: dialogSelectedCompany != null,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Tutar *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Açıklama'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: dialogSelectedDirection,
                    decoration: const InputDecoration(labelText: 'Yön *'),
                    items: const [
                      DropdownMenuItem(value: 'Alınacak', child: Text('Alınacak')),
                      DropdownMenuItem(value: 'Verilecek', child: Text('Verilecek')),
                    ],
                    onChanged: (value) => setDialogState(() => dialogSelectedDirection = value!),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: Text('Keşide Tarihi: ${dialogIssueDate.day}.${dialogIssueDate.month}.${dialogIssueDate.year}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: dialogIssueDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setDialogState(() => dialogIssueDate = date);
                      }
                    },
                  ),
                  ListTile(
                    title: Text('Vade Tarihi: ${dialogDueDate.day}.${dialogDueDate.month}.${dialogDueDate.year}'),
                    trailing: const Icon(Icons.event),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: dialogDueDate,
                        firstDate: dialogIssueDate,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setDialogState(() => dialogDueDate = date);
                      }
                    },
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
                if (debtorNameController.text.isEmpty || amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Borçlu adı ve tutar zorunludur')),
                  );
                  return;
                }
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Geçerli bir tutar giriniz')),
                  );
                  return;
                }
                final updatedNote = PromissoryNote(
                  id: note?.id,
                  noteNo: note?.noteNo ?? 'SNT-${DateTime.now().year}-${(_promissoryNotes.length + 1).toString().padLeft(4, '0')}',
                  debtorName: dialogSelectedCompany?.name ?? debtorNameController.text,
                  amount: amount,
                  issueDate: dialogIssueDate,
                  dueDate: dialogDueDate,
                  description: descriptionController.text.isEmpty ? null : descriptionController.text,
                  debtorPhone: note?.debtorPhone ?? dialogSelectedCompany?.phone,
                  debtorEmail: note?.debtorEmail ?? dialogSelectedCompany?.email,
                  debtorAddress: note?.debtorAddress ?? dialogSelectedCompany?.fullAddress,
                  debtorTcNo: note?.debtorTcNo,
                  status: note?.status ?? 'Beklemede',
                  direction: dialogSelectedDirection,
                  paymentDate: note?.paymentDate,
                  paymentMethod: note?.paymentMethod,
                  paymentReference: note?.paymentReference,
                  notes: note?.notes,
                  relatedIncomeId: note?.relatedIncomeId,
                  relatedExpenseId: note?.relatedExpenseId,
                  createdBy: note?.createdBy,
                );
                if (isEdit) {
                  await _promissoryNoteService.update(updatedNote);
                } else {
                  await _promissoryNoteService.insert(updatedNote);
                }
                Navigator.pop(context);
                _loadPromissoryNotes();
              },
              child: Text(isEdit ? 'Kaydet' : 'Ekle'),
            ),
          ],
        ),
      );
      }
    );
  }

  void _showIncomeDetailDialog(Income income) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(income.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(Icons.category, 'Kategori', income.category),
              _buildDetailRow(Icons.attach_money, 'Tutar', income.formattedAmount),
              _buildDetailRow(Icons.calendar_today, 'Tarih', income.formattedDate),
              if (income.payerName != null && income.payerName!.isNotEmpty)
                _buildDetailRow(Icons.person, 'Ödeyen', income.payerName!),
              if (income.description != null && income.description!.isNotEmpty)
                _buildDetailRow(Icons.description, 'Açıklama', income.description!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showAddEditIncomeDialog(income);
            },
            child: const Text('Düzenle'),
          ),
        ],
      ),
    );
  }

  void _showExpenseDetailDialog(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(expense.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(Icons.category, 'Kategori', expense.category),
              _buildDetailRow(Icons.attach_money, 'Tutar', expense.formattedAmount),
              _buildDetailRow(Icons.calendar_today, 'Tarih', expense.formattedDate),
              if (expense.payeeName != null && expense.payeeName!.isNotEmpty)
                _buildDetailRow(Icons.person, 'Alacaklı / Ödeme Yapılan', expense.payeeName!),
              if (expense.description != null && expense.description!.isNotEmpty)
                _buildDetailRow(Icons.description, 'Açıklama', expense.description!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showAddEditExpenseDialog(expense: expense);
            },
            child: const Text('Düzenle'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF8D6E63)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8D6E63),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF3E2723),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCheckDetailDialog(Check check) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Çek: ${check.checkNumber}'),
        content: Text('Banka: ${check.bankName}\nTutar: ${check.formattedAmount}\nVade: ${check.formattedDueDate}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showAddEditCheckDialog(check);
            },
            child: const Text('Düzenle'),
          ),
        ],
      ),
    );
  }

  void _showPromissoryNoteDetailDialog(PromissoryNote note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Senet: ${note.noteNo}'),
        content: Text('Borçlu: ${note.debtorName}\nTutar: ${note.formattedAmount}\nVade: ${note.formattedDueDate}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showAddEditPromissoryNoteDialog(note);
            },
            child: const Text('Düzenle'),
          ),
        ],
      ),
    );
  }
}

