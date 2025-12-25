import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/book_sale.dart';
import '../models/book.dart';
import '../models/member.dart';
import '../models/income.dart';
import '../services/book_sale_service.dart';
import '../services/book_service.dart';
import '../services/member_service.dart';
import '../services/income_service.dart';

class BookSalesScreen extends StatefulWidget {
  const BookSalesScreen({super.key});

  @override
  State<BookSalesScreen> createState() => _BookSalesScreenState();
}

class _BookSalesScreenState extends State<BookSalesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final BookSaleService _saleService = BookSaleService();
  final BookService _bookService = BookService();
  final MemberService _memberService = MemberService();
  final IncomeService _incomeService = IncomeService();
  String _searchQuery = '';
  bool _isLoading = true;

  List<BookSale> _salesList = [];
  List<Book> _booksList = [];
  List<Member> _membersList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final sales = await _saleService.getAll();
      final books = await _bookService.getAll();
      final members = await _memberService.getAll();
      setState(() {
        _salesList = sales;
        _booksList = books;
        _membersList = members;
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

  List<BookSale> get _filteredList {
    if (_searchQuery.isEmpty) return _salesList;
    return _salesList.where((sale) {
      return sale.bookTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          sale.saleNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (sale.customerName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (sale.bookIsbn?.contains(_searchQuery) ?? false);
    }).toList();
  }

  String _generateSaleNo() {
    final now = DateTime.now();
    return 'SAT-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${_salesList.length + 1}';
  }

  void _showAddEditSaleDialog([BookSale? sale]) async {
    final isEdit = sale != null;
    final saleData = sale; // Non-nullable olarak kullanmak için
    Book? selectedBook;
    Member? selectedMember;
    
    // Düzenleme modunda, mevcut kitap ve üye bilgilerini yükle
    if (isEdit && saleData != null) {
      // Kitabı bul
      selectedBook = _booksList.firstWhere(
        (b) => b.id == saleData.bookId,
        orElse: () => _booksList.isNotEmpty ? _booksList.first : throw Exception('Kitap bulunamadı'),
      );
      // Üyeyi bul (varsa)
      if (saleData.memberId != null) {
        try {
          selectedMember = _membersList.firstWhere((m) => m.id == saleData.memberId);
        } catch (_) {
          selectedMember = null;
        }
      }
    }
    final quantityController = TextEditingController(text: sale?.quantity.toString() ?? '1');
    final unitPriceController = TextEditingController(text: sale?.unitPrice.toStringAsFixed(2) ?? '');
    final discountController = TextEditingController(text: sale?.discount.toStringAsFixed(2) ?? '0');
    final customerNameController = TextEditingController(text: sale?.customerName ?? '');
    final customerPhoneController = TextEditingController(text: sale?.customerPhone ?? '');
    final customerEmailController = TextEditingController(text: sale?.customerEmail ?? '');
    final customerAddressController = TextEditingController(text: sale?.customerAddress ?? '');
    final notesController = TextEditingController(text: sale?.notes ?? '');
    String? selectedPaymentMethod = sale?.paymentMethod;
    
    // Düzenleme modunda, üye bilgilerini doldur
    if (isEdit && selectedMember != null) {
      customerNameController.text = '${selectedMember.name} ${selectedMember.surname}';
      customerPhoneController.text = selectedMember.phone;
      customerEmailController.text = selectedMember.email ?? '';
      customerAddressController.text = selectedMember.address ?? '';
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
                  color: const Color(0xFF8D6E63).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shopping_cart_rounded,
                  color: Color(0xFF8D6E63),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isEdit ? 'Satış Düzenle' : 'Yeni Kitap Satışı',
                style: const TextStyle(
                  color: Color(0xFF3E2723),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 600,
            height: 700,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kitap Seçimi
                  _booksList.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.grey),
                              SizedBox(width: 8),
                              Text(
                                'Kitap yükleniyor...',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : DropdownButtonFormField<Book>(
                          initialValue: selectedBook,
                          decoration: InputDecoration(
                            labelText: 'Kitap *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.book_rounded),
                            helperText: !isEdit && _booksList.where((b) => b.isActive && b.availableCopies > 0).isEmpty
                                ? 'Satılabilir kitap bulunamadı'
                                : null,
                          ),
                          items: _booksList
                              .where((b) => b.isActive && b.availableCopies > 0)
                              .map((book) => DropdownMenuItem(
                                    value: book,
                                    child: Text(
                                      '${book.title}${book.authorName != null ? ' - ${book.authorName}' : ''} (Stok: ${book.availableCopies})',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: (book) {
                            setDialogState(() {
                              selectedBook = book;
                              if (book != null && unitPriceController.text.isEmpty) {
                                // Varsayılan fiyat önerisi (isteğe bağlı)
                              }
                            });
                          },
                        ),
                  const SizedBox(height: 16),
                  
                  // Miktar ve Fiyat
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: quantityController,
                          decoration: InputDecoration(
                            labelText: 'Miktar *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.numbers_rounded),
                            helperText: selectedBook != null 
                              ? 'Mevcut stok: ${selectedBook!.availableCopies}'
                              : null,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          onChanged: (_) {
                            setDialogState(() {
                              // Miktar değiştiğinde stok kontrolü yap
                              final quantity = int.tryParse(quantityController.text) ?? 0;
                              if (selectedBook != null && quantity > selectedBook!.availableCopies) {
                                // Miktar mevcut stoktan fazla ise, mevcut stoğa eşitle
                                quantityController.text = selectedBook!.availableCopies.toString();
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: unitPriceController,
                          decoration: InputDecoration(
                            labelText: 'Birim Fiyat (₺) *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.attach_money_rounded),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) {
                            setDialogState(() {
                              // Miktar değiştiğinde stok kontrolü yap
                              final quantity = int.tryParse(quantityController.text) ?? 0;
                              if (selectedBook != null && quantity > selectedBook!.availableCopies) {
                                // Miktar mevcut stoktan fazla ise, mevcut stoğa eşitle
                                quantityController.text = selectedBook!.availableCopies.toString();
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // İndirim
                  TextFormField(
                    controller: discountController,
                    decoration: InputDecoration(
                      labelText: 'İndirim (₺)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.discount_rounded),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 16),
                  
                  // Toplam Hesaplama
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8D6E63).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Toplam Tutar:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _calculateTotal(quantityController.text, unitPriceController.text, discountController.text),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8D6E63),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Müşteri Bilgileri
                  const Text(
                    'Müşteri Bilgileri',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Üye Seçimi
                  DropdownButtonFormField<Member>(
                    initialValue: selectedMember,
                    decoration: InputDecoration(
                      labelText: 'Üyeden Seç (Opsiyonel)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.people_rounded),
                      helperText: 'Üye seçerseniz bilgiler otomatik doldurulur',
                    ),
                    items: _membersList
                        .where((m) => m.isActive)
                        .map((member) => DropdownMenuItem(
                              value: member,
                              child: Text('${member.name} ${member.surname} (${member.memberNo})'),
                            ))
                        .toList(),
                    onChanged: (member) {
                      setDialogState(() {
                        selectedMember = member;
                        if (member != null) {
                          customerNameController.text = '${member.name} ${member.surname}';
                          customerPhoneController.text = member.phone;
                          customerEmailController.text = member.email ?? '';
                          customerAddressController.text = member.address ?? '';
                        } else {
                          customerNameController.clear();
                          customerPhoneController.clear();
                          customerEmailController.clear();
                          customerAddressController.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: customerNameController,
                    decoration: InputDecoration(
                      labelText: 'Müşteri Adı',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.person_rounded),
                    ),
                    readOnly: selectedMember != null,
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: customerPhoneController,
                          decoration: InputDecoration(
                            labelText: 'Telefon',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.phone_rounded),
                          ),
                          keyboardType: TextInputType.phone,
                          readOnly: selectedMember != null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: customerEmailController,
                          decoration: InputDecoration(
                            labelText: 'E-posta',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.email_rounded),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          readOnly: selectedMember != null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: customerAddressController,
                    decoration: InputDecoration(
                      labelText: 'Adres',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.location_on_rounded),
                    ),
                    maxLines: 2,
                    readOnly: selectedMember != null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Ödeme Yöntemi
                  DropdownButtonFormField<String>(
                    initialValue: selectedPaymentMethod,
                    decoration: InputDecoration(
                      labelText: 'Ödeme Yöntemi',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.payment_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Nakit', child: Text('Nakit')),
                      DropdownMenuItem(value: 'Kredi Kartı', child: Text('Kredi Kartı')),
                      DropdownMenuItem(value: 'Banka Havalesi', child: Text('Banka Havalesi')),
                      DropdownMenuItem(value: 'Çek', child: Text('Çek')),
                      DropdownMenuItem(value: 'Diğer', child: Text('Diğer')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedPaymentMethod = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Notlar
                  TextFormField(
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText: 'Notlar',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.note_rounded),
                    ),
                    maxLines: 3,
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
                if (selectedBook == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lütfen bir kitap seçin'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final quantity = int.tryParse(quantityController.text) ?? 1;
                if (quantity < 1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Miktar en az 1 olmalıdır'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (selectedBook!.availableCopies < quantity) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Yeterli stok yok. Mevcut stok: ${selectedBook!.availableCopies}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final unitPrice = double.tryParse(unitPriceController.text) ?? 0;
                if (unitPrice <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lütfen geçerli bir birim fiyat girin'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final discount = double.tryParse(discountController.text) ?? 0;
                final totalAmount = unitPrice * quantity;
                final finalAmount = totalAmount - discount;

                if (finalAmount < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('İndirim toplam tutardan fazla olamaz'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  // Düzenleme modunda eski stok bilgilerini al
                  int oldQuantity = 0;
                  int? oldBookId;
                  if (isEdit && saleData != null) {
                    oldQuantity = saleData.quantity;
                    oldBookId = saleData.bookId;
                  }
                  
                  final updatedSale = BookSale(
                    id: sale?.id,
                    saleNo: sale?.saleNo ?? _generateSaleNo(),
                    bookId: selectedBook!.id!,
                    bookTitle: selectedBook!.title,
                    bookIsbn: selectedBook!.isbn,
                    bookAuthor: selectedBook!.authorName,
                    quantity: quantity,
                    unitPrice: unitPrice,
                    totalAmount: totalAmount,
                    discount: discount,
                    finalAmount: finalAmount,
                    customerName: customerNameController.text.isEmpty ? null : customerNameController.text,
                    customerPhone: customerPhoneController.text.isEmpty ? null : customerPhoneController.text,
                    customerEmail: customerEmailController.text.isEmpty ? null : customerEmailController.text,
                    customerAddress: customerAddressController.text.isEmpty ? null : customerAddressController.text,
                    memberId: selectedMember?.id,
                    saleDate: sale?.saleDate ?? DateTime.now(),
                    paymentMethod: selectedPaymentMethod,
                    notes: notesController.text.isEmpty ? null : notesController.text,
                    createdBy: sale?.createdBy,
                  );

                  if (isEdit) {
                    await _saleService.update(updatedSale);
                    
                    // Eski kitabın stokunu geri ekle
                    if (oldBookId != null && oldBookId != selectedBook!.id) {
                      final oldBook = _booksList.firstWhere((b) => b.id == oldBookId);
                      await _bookService.update(oldBook.copyWith(
                        availableCopies: oldBook.availableCopies + oldQuantity,
                      ));
                    } else if (oldBookId == selectedBook!.id) {
                      // Aynı kitap, sadece miktar farkını hesapla
                      final quantityDiff = oldQuantity - quantity;
                      if (quantityDiff != 0) {
                        final currentBook = _booksList.firstWhere((b) => b.id == selectedBook!.id);
                        await _bookService.update(currentBook.copyWith(
                          availableCopies: currentBook.availableCopies + quantityDiff,
                        ));
                      }
                    }
                  } else {
                    await _saleService.insert(updatedSale);
                    
                    // Kitap stokunu güncelle
                    final updatedBook = selectedBook!.copyWith(
                      availableCopies: selectedBook!.availableCopies - quantity,
                      borrowedCopies: selectedBook!.borrowedCopies,
                    );
                    await _bookService.update(updatedBook);
                  }

                  // Gelir kaydını güncelle veya ekle
                  if (isEdit && saleData != null) {
                    // Düzenleme modunda, ilgili gelir kaydını bul ve güncelle
                    final allIncomes = await _incomeService.getAll();
                    final relatedIncome = allIncomes.firstWhere(
                      (inc) => inc.referenceNo == saleData.saleNo && inc.category == 'Kitap Satışı',
                      orElse: () => throw Exception('İlgili gelir kaydı bulunamadı'),
                    );
                    final updatedIncome = Income(
                      id: relatedIncome.id,
                      incomeNo: relatedIncome.incomeNo,
                      title: 'Kitap Satışı - ${selectedBook!.title}',
                      description: '$quantity adet ${selectedBook!.title} satışı${selectedMember != null ? ' (Üye: ${selectedMember!.name} ${selectedMember!.surname})' : ''}',
                      amount: finalAmount,
                      category: 'Kitap Satışı',
                      incomeDate: relatedIncome.incomeDate,
                      payerName: customerNameController.text.isEmpty ? null : customerNameController.text,
                      payerPhone: customerPhoneController.text.isEmpty ? null : customerPhoneController.text,
                      payerEmail: customerEmailController.text.isEmpty ? null : customerEmailController.text,
                      paymentMethod: selectedPaymentMethod,
                      referenceNo: updatedSale.saleNo,
                      notes: notesController.text.isEmpty ? null : notesController.text,
                      relatedMemberId: selectedMember?.id,
                      relatedEscrowId: relatedIncome.relatedEscrowId,
                      createdBy: relatedIncome.createdBy,
                    );
                    await _incomeService.update(updatedIncome);
                  } else {
                    // Yeni ekleme modunda gelir kaydı ekle
                    final year = DateTime.now().year;
                    final incomeList = await _incomeService.getAll();
                    final incomeNo = 'GEL-$year-${(incomeList.length + 1).toString().padLeft(4, '0')}';
                    final income = Income(
                      incomeNo: incomeNo,
                      title: 'Kitap Satışı - ${selectedBook!.title}',
                      description: '$quantity adet ${selectedBook!.title} satışı${selectedMember != null ? ' (Üye: ${selectedMember!.name} ${selectedMember!.surname})' : ''}',
                      amount: finalAmount,
                      category: 'Kitap Satışı',
                      incomeDate: DateTime.now(),
                      payerName: customerNameController.text.isEmpty ? null : customerNameController.text,
                      payerPhone: customerPhoneController.text.isEmpty ? null : customerPhoneController.text,
                      payerEmail: customerEmailController.text.isEmpty ? null : customerEmailController.text,
                      paymentMethod: selectedPaymentMethod,
                      referenceNo: updatedSale.saleNo,
                      notes: notesController.text.isEmpty ? null : notesController.text,
                      relatedMemberId: selectedMember?.id,
                    );
                    await _incomeService.insert(income);
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit ? 'Satış başarıyla güncellendi' : 'Satış başarıyla kaydedildi'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Satış kaydedilirken hata oluştu: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8D6E63),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Satış Yap'),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateTotal(String quantity, String unitPrice, String discount) {
    final qty = int.tryParse(quantity) ?? 0;
    final price = double.tryParse(unitPrice) ?? 0;
    final disc = double.tryParse(discount) ?? 0;
    final total = (qty * price) - disc;
    return '${total.toStringAsFixed(2)} ₺';
  }

  void _showSaleDetailDialog(BookSale sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Satış Detayı: ${sale.saleNo}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(Icons.book, 'Kitap', sale.bookTitle),
              if (sale.bookAuthor != null)
                _buildDetailRow(Icons.person, 'Yazar', sale.bookAuthor!),
              if (sale.bookIsbn != null)
                _buildDetailRow(Icons.numbers, 'ISBN', sale.bookIsbn!),
              _buildDetailRow(Icons.numbers, 'Miktar', '${sale.quantity} adet'),
              _buildDetailRow(Icons.attach_money, 'Birim Fiyat', '${sale.unitPrice.toStringAsFixed(2)} ₺'),
              _buildDetailRow(Icons.attach_money, 'Toplam Tutar', '${sale.totalAmount.toStringAsFixed(2)} ₺'),
              if (sale.discount > 0)
                _buildDetailRow(Icons.discount, 'İndirim', '${sale.discount.toStringAsFixed(2)} ₺'),
              _buildDetailRow(Icons.attach_money, 'Final Tutar', '${sale.finalAmount.toStringAsFixed(2)} ₺', isHighlight: true),
              _buildDetailRow(Icons.calendar_today, 'Satış Tarihi', sale.formattedSaleDate),
              if (sale.customerName != null && sale.customerName!.isNotEmpty) ...[
                const Divider(height: 24),
                const Text(
                  'Müşteri Bilgileri',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8D6E63),
                  ),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.person, 'Müşteri Adı', sale.customerName!),
                if (sale.customerPhone != null && sale.customerPhone!.isNotEmpty)
                  _buildDetailRow(Icons.phone, 'Telefon', sale.customerPhone!),
                if (sale.customerEmail != null && sale.customerEmail!.isNotEmpty)
                  _buildDetailRow(Icons.email, 'E-posta', sale.customerEmail!),
                if (sale.customerAddress != null && sale.customerAddress!.isNotEmpty)
                  _buildDetailRow(Icons.location_on, 'Adres', sale.customerAddress!),
              ],
              if (sale.paymentMethod != null && sale.paymentMethod!.isNotEmpty) ...[
                const Divider(height: 24),
                _buildDetailRow(Icons.payment, 'Ödeme Yöntemi', sale.paymentMethod!),
              ],
              if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                const Divider(height: 24),
                _buildDetailRow(Icons.note, 'Notlar', sale.notes!),
              ],
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
              _showAddEditSaleDialog(sale);
            },
            child: const Text('Düzenle'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isHighlight = false}) {
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
                  style: TextStyle(
                    fontSize: 14,
                    color: isHighlight ? const Color(0xFF8D6E63) : const Color(0xFF3E2723),
                    fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BookSale sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Satışı Sil'),
        content: Text('${sale.saleNo} numaralı satışı silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _saleService.delete(sale.id!);
                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Satış başarıyla silindi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Satış silinirken hata oluştu: $e'),
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
                    color: const Color(0xFF8D6E63).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_rounded,
                    size: 32,
                    color: Color(0xFF8D6E63),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kitap Satışları',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E2723),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Elindeki kitapları satışa çıkarın ve satış geçmişini takip edin',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditSaleDialog(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Yeni Satış'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8D6E63),
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
            
            // Search and Stats
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Kitap adı, satış no, müşteri adı veya ISBN ile ara...',
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
                ),
                const SizedBox(width: 16),
                FutureBuilder<double>(
                  future: _saleService.getTotalSalesAmount(),
                  builder: (context, snapshot) {
                    final total = snapshot.data ?? 0.0;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8D6E63),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Toplam Satış',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${total.toStringAsFixed(2)} ₺',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Sales List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Henüz satış kaydı yok',
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
                                  color: const Color(0xFF8D6E63).withValues(alpha: 0.1),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(flex: 2, child: _buildHeaderText('Satış No')),
                                    Expanded(flex: 3, child: _buildHeaderText('Kitap')),
                                    Expanded(flex: 2, child: _buildHeaderText('Müşteri')),
                                    Expanded(flex: 1, child: _buildHeaderText('Miktar')),
                                    Expanded(flex: 1, child: _buildHeaderText('Birim Fiyat')),
                                    Expanded(flex: 1, child: _buildHeaderText('Toplam')),
                                    Expanded(flex: 1, child: _buildHeaderText('Tarih')),
                                    const SizedBox(width: 120),
                                  ],
                                ),
                              ),
                              // Table Body
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _filteredList.length,
                                  itemBuilder: (context, index) {
                                    final sale = _filteredList[index];
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
                                          onTap: () => _showSaleDetailDialog(sale),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              children: [
                                                Expanded(flex: 2, child: Text(sale.saleNo, style: const TextStyle(fontWeight: FontWeight.w500))),
                                                Expanded(flex: 3, child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(sale.bookTitle, style: const TextStyle(fontWeight: FontWeight.w500)),
                                                    if (sale.bookAuthor != null)
                                                      Text(sale.bookAuthor!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                                  ],
                                                )),
                                                Expanded(flex: 2, child: Text(sale.customerName ?? '-', style: TextStyle(color: Colors.grey[700]))),
                                                Expanded(flex: 1, child: Text('${sale.quantity}')),
                                                Expanded(flex: 1, child: Text('${sale.unitPrice.toStringAsFixed(2)} ₺')),
                                                Expanded(flex: 1, child: Text('${sale.finalAmount.toStringAsFixed(2)} ₺', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8D6E63)))),
                                                Expanded(flex: 1, child: Text(sale.formattedSaleDate)),
                                                SizedBox(
                                                  width: 120,
                                                  child: Row(
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(Icons.delete_rounded, size: 18),
                                                        color: Colors.red,
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                                        onPressed: () => _showDeleteDialog(sale),
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

  Widget _buildHeaderText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF3E2723),
      ),
    );
  }
}

