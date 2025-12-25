import 'package:flutter/material.dart';
import '../models/escrow.dart';
import '../models/member.dart';
import '../models/book.dart';
import '../services/escrow_service.dart';
import '../services/member_service.dart';
import '../services/book_service.dart';

class EscrowScreen extends StatefulWidget {
  const EscrowScreen({super.key});

  @override
  State<EscrowScreen> createState() => _EscrowScreenState();
}

class _EscrowScreenState extends State<EscrowScreen> {
  final TextEditingController _searchController = TextEditingController();
  final EscrowService _escrowService = EscrowService();
  final MemberService _memberService = MemberService();
  final BookService _bookService = BookService();
  String _searchQuery = '';
  String _selectedFilter = 'Tümü';
  String _selectedStatus = 'Tümü';
  bool _isLoading = true;

  List<Member> _members = [];
  List<Book> _books = [];
  List<Escrow> _escrowList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _escrowService.getAll(),
        _memberService.getAll(),
        _bookService.getAll(),
      ]);
      setState(() {
        _escrowList = results[0] as List<Escrow>;
        _members = results[1] as List<Member>;
        _books = results[2] as List<Book>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veriler yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Escrow> get _filteredList {
    return _escrowList.where((e) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          e.bookTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.memberName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.escrowNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (e.bookIsbn?.contains(_searchQuery) ?? false);

      final matchesFilter =
          _selectedFilter == 'Tümü' || e.status == _selectedFilter;

      final matchesStatus =
          _selectedStatus == 'Tümü' ||
          (_selectedStatus == 'Aktif' && e.status == 'Ödünçte') ||
          (_selectedStatus == 'Tamamlanan' && e.status == 'İade Edildi') ||
          (_selectedStatus == 'Gecikmiş' && e.status == 'Gecikmiş');

      return matchesSearch && matchesFilter && matchesStatus;
    }).toList();
  }

  Future<String> _generateEscrowNo() async {
    final year = DateTime.now().year;
    final escrows = await _escrowService.getAll();
    final count = escrows.length + 1;
    return 'EMN-$year-${count.toString().padLeft(3, '0')}';
  }

  void _showAddEditDialog([Escrow? escrow]) {
    final isEdit = escrow != null;
    final notesController = TextEditingController(text: escrow?.notes ?? '');

    int? selectedMemberId = escrow?.memberId;
    int? selectedBookId = escrow?.bookId;
    DateTime? selectedBorrowDate = escrow?.borrowDate ?? DateTime.now();
    DateTime? selectedDueDate =
        escrow?.dueDate ?? DateTime.now().add(const Duration(days: 30));
    String selectedStatus = escrow?.status ?? 'Ödünçte';

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
                  color: const Color(0xFF795548).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isEdit ? Icons.edit_rounded : Icons.add_rounded,
                  color: const Color(0xFF795548),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isEdit ? 'Emanet Düzenle' : 'Yeni Emanet Ekle',
                style: const TextStyle(
                  color: Color(0xFF3E2723),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 550,
            height: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Üye Seçimi
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF8F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD7CCC8)),
                    ),
                    child: DropdownButtonFormField<int>(
                      initialValue: selectedMemberId,
                      decoration: const InputDecoration(
                        labelText: 'Üye',
                        prefixIcon: Icon(
                          Icons.person_outline_rounded,
                          color: Color(0xFF8D6E63),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      items: _members.map((m) {
                        return DropdownMenuItem(
                          value: m.id,
                          child: Text('${m.fullName} (${m.memberNo})'),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setDialogState(() => selectedMemberId = value),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Kitap Seçimi
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF8F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD7CCC8)),
                    ),
                    child: DropdownButtonFormField<int>(
                      initialValue: selectedBookId,
                      decoration: const InputDecoration(
                        labelText: 'Kitap',
                        prefixIcon: Icon(
                          Icons.book_outlined,
                          color: Color(0xFF8D6E63),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      items: _books
                          .where((b) => b.isAvailable || b.id == selectedBookId)
                          .map((b) {
                            return DropdownMenuItem(
                              value: b.id,
                              child: Text(
                                '${b.title}${b.authorName != null ? ' - ${b.authorName}' : ''}',
                              ),
                            );
                          })
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => selectedBookId = value),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tarihler
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedBorrowDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null) {
                              setDialogState(() {
                                selectedBorrowDate = date;
                                if (selectedDueDate != null &&
                                    selectedDueDate!.isBefore(date)) {
                                  selectedDueDate = date.add(
                                    const Duration(days: 30),
                                  );
                                }
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF8F5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFD7CCC8),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  color: Color(0xFF8D6E63),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  selectedBorrowDate != null
                                      ? 'Ödünç: ${selectedBorrowDate!.day.toString().padLeft(2, '0')}.${selectedBorrowDate!.month.toString().padLeft(2, '0')}.${selectedBorrowDate!.year}'
                                      : 'Ödünç Tarihi',
                                  style: TextStyle(
                                    color: selectedBorrowDate != null
                                        ? const Color(0xFF3E2723)
                                        : const Color(0xFF8D6E63),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate:
                                  selectedDueDate ??
                                  DateTime.now().add(const Duration(days: 30)),
                              firstDate: selectedBorrowDate ?? DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null) {
                              setDialogState(() => selectedDueDate = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF8F5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFD7CCC8),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.event_outlined,
                                  color: Color(0xFF8D6E63),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  selectedDueDate != null
                                      ? 'İade: ${selectedDueDate!.day.toString().padLeft(2, '0')}.${selectedDueDate!.month.toString().padLeft(2, '0')}.${selectedDueDate!.year}'
                                      : 'İade Tarihi',
                                  style: TextStyle(
                                    color: selectedDueDate != null
                                        ? const Color(0xFF3E2723)
                                        : const Color(0xFF8D6E63),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Durum
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF8F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD7CCC8)),
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Durum',
                        prefixIcon: Icon(
                          Icons.info_outlined,
                          color: Color(0xFF8D6E63),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      items: ['Ödünçte', 'İade Edildi', 'Gecikmiş'].map((s) {
                        return DropdownMenuItem(value: s, child: Text(s));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedStatus = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Notlar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF8F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD7CCC8)),
                    ),
                    child: TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notlar',
                        prefixIcon: Icon(
                          Icons.notes_outlined,
                          color: Color(0xFF8D6E63),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'İptal',
                style: TextStyle(color: Color(0xFF8D6E63)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedMemberId == null || selectedBookId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Üye ve kitap seçimi zorunludur'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final member = _members.firstWhere(
                  (m) => m.id == selectedMemberId,
                );
                final book = _books.firstWhere((b) => b.id == selectedBookId);

                final newEscrow = Escrow(
                  id: escrow?.id,
                  escrowNo: escrow?.escrowNo ?? await _generateEscrowNo(),
                  bookId: selectedBookId!,
                  bookTitle: book.title,
                  bookIsbn: book.isbn,
                  bookCoverUrl: book.coverImageUrl,
                  memberId: selectedMemberId!,
                  memberName: member.fullName,
                  memberNo: member.memberNo,
                  borrowDate: selectedBorrowDate!,
                  dueDate: selectedDueDate!,
                  returnDate: selectedStatus == 'İade Edildi'
                      ? (escrow?.returnDate ?? DateTime.now())
                      : null,
                  status: selectedStatus,
                  notes: notesController.text.isNotEmpty
                      ? notesController.text
                      : null,
                  personnelId: 1,
                  personnelName: 'Ahmet Yılmaz',
                );

                try {
                  if (isEdit) {
                    await _escrowService.update(newEscrow);
                  } else {
                    await _escrowService.insert(newEscrow);
                    // Kitap kopya sayılarını güncelle
                    await _bookService.updateCopies(
                      book.id!,
                      book.availableCopies - 1,
                      book.borrowedCopies + 1,
                    );
                    // Üye ödünç kitap sayısını güncelle
                    await _memberService.updateBorrowedCount(
                      member.id!,
                      member.borrowedBooksCount + 1,
                    );
                  }
                  Navigator.pop(context);
                  _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEdit ? 'Emanet güncellendi' : 'Emanet eklendi',
                        ),
                        backgroundColor: const Color(0xFF795548),
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
                backgroundColor: const Color(0xFF795548),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(isEdit ? 'Güncelle' : 'Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReturnDialog(Escrow escrow) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Kitap İade Et',
              style: TextStyle(
                color: Color(0xFF3E2723),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${escrow.bookTitle}" kitabını iade etmek istediğinize emin misiniz?',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Üye: ${escrow.memberName}'),
                  Text('Ödünç Tarihi: ${escrow.formattedBorrowDate}'),
                  Text('İade Tarihi: ${escrow.formattedDueDate}'),
                  if (escrow.isOverdue) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Gecikme: ${escrow.daysOverdue} gün',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'İptal',
              style: TextStyle(color: Color(0xFF8D6E63)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final returnDate = DateTime.now();
                await _escrowService.returnBook(escrow.id!, returnDate);
                
                // Kitap kopya sayılarını güncelle
                final book = await _bookService.getById(escrow.bookId);
                if (book != null) {
                  await _bookService.updateCopies(
                    book.id!,
                    book.availableCopies + 1,
                    book.borrowedCopies - 1,
                  );
                }
                
                // Üye ödünç kitap sayısını güncelle
                final member = await _memberService.getById(escrow.memberId);
                if (member != null) {
                  await _memberService.updateBorrowedCount(
                    member.id!,
                    member.borrowedBooksCount > 0 
                        ? member.borrowedBooksCount - 1 
                        : 0,
                  );
                }
                
                Navigator.pop(context);
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kitap iade edildi'),
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
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('İade Et'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Escrow escrow) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Emanet Sil',
              style: TextStyle(
                color: Color(0xFF3E2723),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          '"${escrow.escrowNo}" numaralı emaneti silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'İptal',
              style: TextStyle(color: Color(0xFF8D6E63)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _escrowService.delete(escrow.id!);
                Navigator.pop(context);
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Emanet silindi'),
                      backgroundColor: Colors.red,
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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(Escrow escrow) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            maxWidth: 550,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getStatusColor(escrow.status),
                      _getStatusColor(escrow.status).withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 3,
                        ),
                        image:
                            escrow.bookCoverUrl != null &&
                                escrow.bookCoverUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(escrow.bookCoverUrl!),
                                fit: BoxFit.cover,
                                onError: (_, __) {},
                              )
                            : null,
                      ),
                      child:
                          escrow.bookCoverUrl == null ||
                              escrow.bookCoverUrl!.isEmpty
                          ? const Icon(
                              Icons.book_rounded,
                              color: Colors.white,
                              size: 40,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            escrow.bookTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  escrow.escrowNo,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  escrow.status,
                                  style: TextStyle(
                                    color: _getStatusColor(escrow.status),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Stats Row
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: Colors.grey.shade100),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                      'Ödünç',
                      escrow.formattedBorrowDate,
                      Icons.calendar_today_outlined,
                    ),
                    _buildStatItem(
                      'İade',
                      escrow.formattedDueDate,
                      Icons.event_outlined,
                    ),
                    if (escrow.isOverdue)
                      _buildStatItem(
                        'Gecikme',
                        '${escrow.daysOverdue} gün',
                        Icons.warning_rounded,
                        Colors.red,
                      )
                    else if (escrow.status == 'Ödünçte')
                      _buildStatItem(
                        'Kalan',
                        '${escrow.remainingDays} gün',
                        Icons.timer_outlined,
                        Colors.green,
                      ),
                  ],
                ),
              ),
              // Scrollable Details
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        Icons.person_outlined,
                        'Üye',
                        '${escrow.memberName} (${escrow.memberNo})',
                      ),
                      if (escrow.bookIsbn != null)
                        _buildDetailRow(
                          Icons.qr_code_outlined,
                          'ISBN',
                          escrow.bookIsbn!,
                        ),
                      _buildDetailRow(
                        Icons.calendar_today_outlined,
                        'Ödünç Tarihi',
                        escrow.formattedBorrowDate,
                      ),
                      _buildDetailRow(
                        Icons.event_outlined,
                        'İade Tarihi',
                        escrow.formattedDueDate,
                      ),
                      if (escrow.returnDate != null)
                        _buildDetailRow(
                          Icons.check_circle_outlined,
                          'İade Edildi',
                          escrow.formattedReturnDate,
                        ),
                      if (escrow.personnelName != null)
                        _buildDetailRow(
                          Icons.badge_outlined,
                          'Personel',
                          escrow.personnelName!,
                        ),
                      if (escrow.fineAmount != null &&
                          escrow.fineAmount! > 0) ...[
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          Icons.payments_outlined,
                          'Ceza',
                          '₺${escrow.fineAmount!.toStringAsFixed(2)}',
                          isWarning: true,
                        ),
                        if (escrow.fineReason != null)
                          _buildDetailRow(
                            Icons.info_outlined,
                            'Ceza Nedeni',
                            escrow.fineReason!,
                            isWarning: true,
                          ),
                      ],
                      if (escrow.notes != null && escrow.notes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          Icons.notes_outlined,
                          'Notlar',
                          escrow.notes!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Row(
                  children: [
                    if (escrow.status == 'Ödünçte')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showReturnDialog(escrow);
                          },
                          icon: const Icon(
                            Icons.check_circle_outlined,
                            size: 18,
                          ),
                          label: const Text('İade Et'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    if (escrow.status == 'Ödünçte') const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddEditDialog(escrow);
                        },
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Düzenle'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF795548),
                          side: const BorderSide(color: Color(0xFF795548)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF795548),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Kapat'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon, [
    Color? color,
  ]) {
    return Column(
      children: [
        Icon(icon, color: color ?? const Color(0xFF795548), size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color ?? const Color(0xFF3E2723),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool isWarning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isWarning
                  ? Colors.red.withValues(alpha: 0.1)
                  : const Color(0xFF795548).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isWarning ? Colors.red : const Color(0xFF795548),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: isWarning ? Colors.red : const Color(0xFF3E2723),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Ödünçte':
        return const Color(0xFF1976D2);
      case 'İade Edildi':
        return Colors.green;
      case 'Gecikmiş':
        return Colors.red;
      default:
        return const Color(0xFF795548);
    }
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
                    color: const Color(0xFF795548).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.swap_horiz_rounded,
                    size: 32,
                    color: Color(0xFF795548),
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emanet İşlemleri',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                    Text(
                      'Kitap ödünç alma ve iade işlemleri',
                      style: TextStyle(fontSize: 14, color: Color(0xFF8D6E63)),
                    ),
                  ],
                ),
                const Spacer(),
                // Stats Cards
                _buildStatsCard(
                  'Toplam',
                  _escrowList.length.toString(),
                  Icons.library_books_outlined,
                  const Color(0xFF795548),
                ),
                const SizedBox(width: 12),
                _buildStatsCard(
                  'Ödünçte',
                  _escrowList
                      .where((e) => e.status == 'Ödünçte')
                      .length
                      .toString(),
                  Icons.book_outlined,
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildStatsCard(
                  'Gecikmiş',
                  _escrowList
                      .where((e) => e.status == 'Gecikmiş')
                      .length
                      .toString(),
                  Icons.warning_rounded,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Main Content
            Expanded(
              child: Container(
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
                    // Toolbar
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          // Search
                          Expanded(
                            flex: 3,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF8F5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFD7CCC8),
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) =>
                                    setState(() => _searchQuery = value),
                                decoration: const InputDecoration(
                                  hintText:
                                      'Emanet ara (kitap, üye, numara)...',
                                  hintStyle: TextStyle(
                                    color: Color(0xFFBDBDBD),
                                  ),
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
                          // Filter by Status
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF8F5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFD7CCC8),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedFilter,
                                items:
                                    [
                                      'Tümü',
                                      'Ödünçte',
                                      'İade Edildi',
                                      'Gecikmiş',
                                    ].map((s) {
                                      return DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      );
                                    }).toList(),
                                onChanged: (value) =>
                                    setState(() => _selectedFilter = value!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Filter by Type
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF8F5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFD7CCC8),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedStatus,
                                items:
                                    [
                                      'Tümü',
                                      'Aktif',
                                      'Tamamlanan',
                                      'Gecikmiş',
                                    ].map((s) {
                                      return DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      );
                                    }).toList(),
                                onChanged: (value) =>
                                    setState(() => _selectedStatus = value!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Add Button
                          ElevatedButton.icon(
                            onPressed: () => _showAddEditDialog(),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Yeni Emanet'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF795548),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      color: const Color(0xFFFAF8F5),
                      child: const Row(
                        children: [
                          SizedBox(width: 60), // Kitap kapak
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Kitap Bilgileri',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5D4037),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Üye Bilgileri',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5D4037),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Ödünç Tarihi',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5D4037),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'İade Tarihi',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5D4037),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Durum',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5D4037),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: Text(
                              'İşlemler',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5D4037),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    // Table Body
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredList.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.library_books_outlined,
                                        size: 64,
                                        color: Colors.grey.shade300,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchQuery.isEmpty
                                            ? 'Henüz emanet eklenmemiş'
                                            : 'Sonuç bulunamadı',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: _filteredList.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                color: Color(0xFFEEEEEE),
                              ),
                              itemBuilder: (context, index) =>
                                  _buildEscrowRow(_filteredList[index]),
                            ),
                    ),
                    // Footer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFAF8F5),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Gösterilen: ${_filteredList.length} / ${_escrowList.length} emanet',
                            style: const TextStyle(
                              color: Color(0xFF8D6E63),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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

  Widget _buildStatsCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
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
                value,
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

  Widget _buildEscrowRow(Escrow escrow) {
    final statusColor = _getStatusColor(escrow.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDetailDialog(escrow),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Kitap Kapak
              Container(
                width: 50,
                height: 70,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                  image:
                      escrow.bookCoverUrl != null &&
                          escrow.bookCoverUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(escrow.bookCoverUrl!),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        )
                      : null,
                ),
                child:
                    escrow.bookCoverUrl == null || escrow.bookCoverUrl!.isEmpty
                    ? Icon(Icons.book_outlined, color: statusColor, size: 28)
                    : null,
              ),
              const SizedBox(width: 12),
              // Kitap Bilgileri
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      escrow.bookTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3E2723),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.qr_code_outlined,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          escrow.escrowNo,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Üye Bilgileri
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      escrow.memberName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      escrow.memberNo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Ödünç Tarihi
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      escrow.formattedBorrowDate,
                      style: const TextStyle(color: Color(0xFF5D4037)),
                    ),
                  ],
                ),
              ),
              // İade Tarihi
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      escrow.formattedDueDate,
                      style: TextStyle(
                        color: escrow.isOverdue
                            ? Colors.red
                            : const Color(0xFF5D4037),
                        fontWeight: escrow.isOverdue
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    if (escrow.isOverdue)
                      Text(
                        '${escrow.daysOverdue} gün gecikme',
                        style: const TextStyle(fontSize: 11, color: Colors.red),
                      )
                    else if (escrow.status == 'Ödünçte' &&
                        escrow.remainingDays > 0)
                      Text(
                        '${escrow.remainingDays} gün kaldı',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade700,
                        ),
                      ),
                  ],
                ),
              ),
              // Durum
              Expanded(
                flex: 1,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          escrow.status,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // İşlemler
              SizedBox(
                width: 120,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_rounded, size: 20),
                      color: const Color(0xFF8D6E63),
                      onPressed: () => _showDetailDialog(escrow),
                      tooltip: 'Detay',
                    ),
                    if (escrow.status == 'Ödünçte')
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 20,
                        ),
                        color: Colors.green,
                        onPressed: () => _showReturnDialog(escrow),
                        tooltip: 'İade Et',
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 20),
                        color: const Color(0xFF795548),
                        onPressed: () => _showAddEditDialog(escrow),
                        tooltip: 'Düzenle',
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      color: Colors.red.shade400,
                      onPressed: () => _showDeleteDialog(escrow),
                      tooltip: 'Sil',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
