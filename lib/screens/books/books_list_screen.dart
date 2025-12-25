import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../models/book.dart';
import '../../models/author.dart';
import '../../models/book_category.dart';
import '../../models/company.dart';
import '../../services/book_service.dart';
import '../../services/author_service.dart';
import '../../services/book_category_service.dart';
import '../../services/company_service.dart';

class BooksListScreen extends StatefulWidget {
  const BooksListScreen({super.key});

  @override
  State<BooksListScreen> createState() => _BooksListScreenState();
}

class _BooksListScreenState extends State<BooksListScreen> {
  final BookService _bookService = BookService();
  final AuthorService _authorService = AuthorService();
  final BookCategoryService _categoryService = BookCategoryService();
  final CompanyService _companyService = CompanyService();

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Tümü';

  List<Book> _bookList = [];
  List<Author> _authors = [];
  List<BookCategory> _categories = [];
  List<Company> _companies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final books = await _bookService.getAll();
      final authors = await _authorService.getAll();
      final categories = await _categoryService.getAll();
      final companies = await _companyService.getAll();

      if (mounted) {
        setState(() {
          _bookList = books;
          _authors = authors;
          _categories = categories;
          _companies = companies.where((c) => c.companyType == 'Yayınevi').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Book> get _filteredList {
    return _bookList.where((b) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          b.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.isbn.contains(_searchQuery) ||
          (b.authorName?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);

      final matchesFilter =
          _selectedFilter == 'Tümü' ||
          (_selectedFilter == 'Stokda Var' && b.isAvailable) ||
          (_selectedFilter == 'Stokda Yok' &&
              (b.availableCopies == 0 || !b.isActive));

      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _showAddEditDialog([Book? book]) {
    final isEdit = book != null;
    final isbnController = TextEditingController(text: book?.isbn ?? '');
    final titleController = TextEditingController(text: book?.title ?? '');
    final subtitleController = TextEditingController(
      text: book?.subtitle ?? '',
    );
    final yearController = TextEditingController(
      text: book?.publicationYear?.toString() ?? '',
    );
    final pageController = TextEditingController(
      text: book?.pageCount?.toString() ?? '',
    );
    final languageController = TextEditingController(
      text: book?.language ?? 'Türkçe',
    );
    final totalCopiesController = TextEditingController(
      text: book?.totalCopies.toString() ?? '1',
    );
    final availableCopiesController = TextEditingController(
      text: book?.availableCopies.toString() ?? (book?.totalCopies.toString() ?? '1'),
    );
    final locationController = TextEditingController(
      text: book?.location ?? '',
    );
    final descriptionController = TextEditingController(
      text: book?.description ?? '',
    );
    final imageUrlController = TextEditingController(
      text: book?.coverImageUrl ?? '',
    );

    int? selectedAuthorId = book?.authorId;
    int? selectedCategoryId = book?.categoryId;
    int? selectedPublisherId = book?.publisherId;
    bool isActive = book?.isActive ?? true;
    File? selectedImageFile;

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
                child: Icon(
                  isEdit ? Icons.edit_rounded : Icons.add_rounded,
                  color: const Color(0xFF8D6E63),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isEdit ? 'Kitap Düzenle' : 'Yeni Kitap Ekle',
                style: const TextStyle(
                  color: Color(0xFF3E2723),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 600,
            height: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Kapak Resmi ve Temel Bilgiler
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kapak Resmi
                      Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF8D6E63,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF8D6E63,
                                    ).withValues(alpha: 0.3),
                                  ),
                                  image: selectedImageFile != null
                                      ? DecorationImage(
                                          image: FileImage(selectedImageFile!),
                                          fit: BoxFit.cover,
                                        )
                                      : imageUrlController.text.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(
                                                imageUrlController.text,
                                              ),
                                              fit: BoxFit.cover,
                                              onError: (_, __) {},
                                            )
                                          : null,
                                ),
                                child: selectedImageFile == null &&
                                        imageUrlController.text.isEmpty
                                    ? const Icon(
                                        Icons.book_outlined,
                                        size: 50,
                                        color: Color(0xFF8D6E63),
                                      )
                                    : null,
                              ),
                              if (selectedImageFile != null)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      setDialogState(() {
                                        selectedImageFile = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 150,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final result = await FilePicker.platform.pickFiles(
                                  type: FileType.image,
                                  allowMultiple: false,
                                );
                                if (result != null && result.files.single.path != null) {
                                  setDialogState(() {
                                    selectedImageFile = File(result.files.single.path!);
                                    imageUrlController.clear();
                                  });
                                }
                              },
                              icon: const Icon(Icons.image_outlined, size: 14),
                              label: const Text(
                                'Resim Seç',
                                style: TextStyle(fontSize: 11),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8D6E63),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 150,
                            child: TextField(
                              controller: imageUrlController,
                              style: const TextStyle(fontSize: 11),
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  setDialogState(() {
                                    selectedImageFile = null;
                                  });
                                }
                                setDialogState(() {});
                              },
                              decoration: InputDecoration(
                                hintText: 'Veya Kapak URL',
                                hintStyle: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade400,
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD7CCC8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Durum
                      Expanded(
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: isbnController,
                              label: 'ISBN (13 haneli)',
                              icon: Icons.qr_code_outlined,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(13),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Text(
                                  'Durum:',
                                  style: TextStyle(color: Color(0xFF5D4037)),
                                ),
                                const SizedBox(width: 12),
                                Switch(
                                  value: isActive,
                                  onChanged: (value) =>
                                      setDialogState(() => isActive = value),
                                  activeThumbColor: const Color(0xFF8D6E63),
                                ),
                                Text(
                                  isActive ? 'Stokda Var' : 'Stokda Yok',
                                  style: TextStyle(
                                    color: isActive ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Kitap Bilgileri
                  const Text(
                    'Kitap Bilgileri',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: titleController,
                    label: 'Kitap Adı',
                    icon: Icons.title,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: subtitleController,
                    label: 'Alt Başlık (Opsiyonel)',
                    icon: Icons.subtitles_outlined,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF8F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD7CCC8)),
                          ),
                          child: DropdownButtonFormField<int>(
                            initialValue: selectedAuthorId,
                            decoration: const InputDecoration(
                              labelText: 'Yazar',
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
                            items: _authors.map((a) {
                              return DropdownMenuItem(
                                value: a.id,
                                child: Text(a.fullName),
                              );
                            }).toList(),
                            onChanged: (value) =>
                                setDialogState(() => selectedAuthorId = value),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF8F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD7CCC8)),
                          ),
                          child: DropdownButtonFormField<int>(
                            initialValue: selectedCategoryId,
                            decoration: const InputDecoration(
                              labelText: 'Kategori',
                              prefixIcon: Icon(
                                Icons.category_outlined,
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
                            items: _categories.map((c) {
                              return DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              );
                            }).toList(),
                            onChanged: (value) => setDialogState(
                              () => selectedCategoryId = value,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Yayın Bilgileri
                  const Text(
                    'Yayın Bilgileri',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF8F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD7CCC8)),
                          ),
                          child: DropdownButtonFormField<int?>(
                            initialValue: selectedPublisherId,
                            decoration: const InputDecoration(
                              labelText: 'Yayınevi',
                              prefixIcon: Icon(
                                Icons.business_outlined,
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
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Seçiniz'),
                              ),
                              ..._companies.map((company) {
                                return DropdownMenuItem<int?>(
                                  value: company.id,
                                  child: Text(company.name),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setDialogState(() => selectedPublisherId = value);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: yearController,
                          label: 'Yayın Yılı',
                          icon: Icons.calendar_today_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: pageController,
                          label: 'Sayfa Sayısı',
                          icon: Icons.menu_book_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: languageController,
                          label: 'Dil',
                          icon: Icons.language_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Kopya ve Konum Bilgileri
                  const Text(
                    'Kopya Bilgileri',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: totalCopiesController,
                          label: 'Toplam Stok',
                          icon: Icons.inventory_2_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) {
                            // Toplam stok değiştiğinde elde olan kopya sayısını kontrol et
                            final total = int.tryParse(value) ?? 0;
                            final available = int.tryParse(availableCopiesController.text) ?? 0;
                            if (available > total && total > 0) {
                              setDialogState(() {
                                availableCopiesController.text = total.toString();
                              });
                            }
                            setDialogState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: availableCopiesController,
                          label: 'Elde Olan Kopya',
                          icon: Icons.library_books_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) {
                            setDialogState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: locationController,
                          label: 'Raf Konumu',
                          icon: Icons.location_on_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: descriptionController,
                    label: 'Açıklama',
                    icon: Icons.description_outlined,
                    maxLines: 3,
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
                if (titleController.text.isEmpty ||
                    isbnController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kitap adı ve ISBN zorunludur'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (isbnController.text.length != 13) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ISBN 13 haneli olmalıdır'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Stok validasyonu
                final totalCopies = int.tryParse(totalCopiesController.text) ?? 1;
                final availableCopies = int.tryParse(availableCopiesController.text) ?? totalCopies;
                
                if (availableCopies > totalCopies) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Elde olan kopya sayısı toplam stok sayısını geçemez'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (totalCopies < 1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Toplam stok en az 1 olmalıdır'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final authorName = _authors
                    .where((a) => a.id == selectedAuthorId)
                    .map((a) => a.fullName)
                    .firstOrNull;
                final categoryName = _categories
                    .where((c) => c.id == selectedCategoryId)
                    .map((c) => c.name)
                    .firstOrNull;
                final publisherName = selectedPublisherId != null
                    ? _companies
                        .where((c) => c.id == selectedPublisherId)
                        .map((c) => c.name)
                        .firstOrNull
                    : null;

                // Resim URL'i: Dosya seçildiyse path, yoksa URL kullan
                String? finalImageUrl;
                if (selectedImageFile != null) {
                  finalImageUrl = selectedImageFile!.path;
                } else if (imageUrlController.text.isNotEmpty) {
                  finalImageUrl = imageUrlController.text;
                }

                final newBook = Book(
                  id: book?.id,
                  isbn: isbnController.text,
                  title: titleController.text,
                  subtitle: subtitleController.text.isNotEmpty
                      ? subtitleController.text
                      : null,
                  authorId: selectedAuthorId,
                  authorName: authorName,
                  categoryId: selectedCategoryId,
                  categoryName: categoryName,
                  publisherId: selectedPublisherId,
                  publisherName: publisherName,
                  publicationYear: int.tryParse(yearController.text),
                  pageCount: int.tryParse(pageController.text),
                  language: languageController.text,
                  description: descriptionController.text.isNotEmpty
                      ? descriptionController.text
                      : null,
                  coverImageUrl: finalImageUrl,
                  totalCopies: totalCopies,
                  availableCopies: availableCopies,
                  borrowedCopies: book?.borrowedCopies ?? 0,
                  location: locationController.text.isNotEmpty
                      ? locationController.text
                      : null,
                  addedDate: book?.addedDate ?? DateTime.now(),
                  isActive: isActive,
                );

                try {
                  int? oldAuthorId;
                  int? oldCategoryId;
                  int? oldPublisherId;
                  if (isEdit) {
                    // Eski yazar, kategori ve yayınevi ID'lerini al
                    oldAuthorId = book.authorId;
                    oldCategoryId = book.categoryId;
                    oldPublisherId = book.publisherId;
                    await _bookService.update(newBook);
                  } else {
                    await _bookService.insert(newBook);
                  }

                  // Yazar kitap sayacını güncelle
                  if (selectedAuthorId != null) {
                    final authorBooks = await _bookService.getByAuthor(selectedAuthorId!);
                    await _authorService.updateBooksCount(selectedAuthorId!, authorBooks.length);
                  }

                  // Eğer yazar değiştirildiyse eski yazarın sayacını da güncelle
                  if (isEdit && oldAuthorId != null && oldAuthorId != selectedAuthorId) {
                    final oldAuthorBooks = await _bookService.getByAuthor(oldAuthorId);
                    await _authorService.updateBooksCount(oldAuthorId, oldAuthorBooks.length);
                  }

                  // Kategori kitap sayacını güncelle
                  if (selectedCategoryId != null) {
                    final categoryBooks = await _bookService.getByCategory(selectedCategoryId!);
                    await _categoryService.updateBooksCount(selectedCategoryId!, categoryBooks.length);
                  }

                  // Eğer kategori değiştirildiyse eski kategorinin sayacını da güncelle
                  if (isEdit && oldCategoryId != null && oldCategoryId != selectedCategoryId) {
                    final oldCategoryBooks = await _bookService.getByCategory(oldCategoryId);
                    await _categoryService.updateBooksCount(oldCategoryId, oldCategoryBooks.length);
                  }

                  // Yayınevi kitap sayacını güncelle
                  if (selectedPublisherId != null) {
                    final publisherBooks = await _bookService.getByPublisher(selectedPublisherId!);
                    await _companyService.updateBooksCount(selectedPublisherId!, publisherBooks.length);
                  }

                  // Eğer yayınevi değiştirildiyse eski yayınevinin sayacını da güncelle
                  if (isEdit && oldPublisherId != null && oldPublisherId != selectedPublisherId) {
                    final oldPublisherBooks = await _bookService.getByPublisher(oldPublisherId);
                    await _companyService.updateBooksCount(oldPublisherId, oldPublisherBooks.length);
                  }

                  await _loadData();
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEdit ? 'Kitap güncellendi' : 'Kitap eklendi',
                        ),
                        backgroundColor: const Color(0xFF8D6E63),
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
                backgroundColor: const Color(0xFF8D6E63),
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

  ImageProvider? _getImageProvider(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    
    // Eğer URL ise (http:// veya https:// ile başlıyorsa) NetworkImage kullan
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return NetworkImage(imageUrl);
    }
    
    // Aksi halde dosya yolu olarak kabul et ve FileImage kullan
    try {
      final file = File(imageUrl);
      return FileImage(file);
    } catch (_) {
      // Dosya yolu geçersizse null döndür
      return null;
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD7CCC8)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF8D6E63)),
          prefixIcon: Icon(icon, color: const Color(0xFF8D6E63)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(Book book) {
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
              'Kitap Sil',
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
              '"${book.title}" adlı kitabı silmek istediğinize emin misiniz?',
            ),
            if (book.borrowedCopies > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bu kitaptan ${book.borrowedCopies} adet ödünçte!',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                // Silmeden önce yazar, kategori ve yayınevi ID'lerini al
                final authorId = book.authorId;
                final categoryId = book.categoryId;
                final publisherId = book.publisherId;

                await _bookService.delete(book.id!);

                // Yazar kitap sayacını güncelle
                if (authorId != null) {
                  final authorBooks = await _bookService.getByAuthor(authorId);
                  await _authorService.updateBooksCount(authorId, authorBooks.length);
                }

                // Kategori kitap sayacını güncelle
                if (categoryId != null) {
                  final categoryBooks = await _bookService.getByCategory(categoryId);
                  await _categoryService.updateBooksCount(categoryId, categoryBooks.length);
                }

                // Yayınevi kitap sayacını güncelle
                if (publisherId != null) {
                  final publisherBooks = await _bookService.getByPublisher(publisherId);
                  await _companyService.updateBooksCount(publisherId, publisherBooks.length);
                }

                await _loadData();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kitap silindi'),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
          // Toolbar
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF8F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD7CCC8)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: const InputDecoration(
                        hintText: 'Kitap ara (ad, ISBN, yazar)...',
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD7CCC8)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      items: ['Tümü', 'Stokda Var', 'Stokda Yok'].map((f) {
                        return DropdownMenuItem(value: f, child: Text(f));
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedFilter = value!),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditDialog(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Yeni Kitap'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8D6E63),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: const Color(0xFFFAF8F5),
            child: const Row(
              children: [
                SizedBox(width: 60), // Kapak resmi
                Expanded(
                  flex: 3,
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
                    'Yazar',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Kategori',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Kopya',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5D4037),
                    ),
                    textAlign: TextAlign.center,
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
                  width: 100,
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
            child: _filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Henüz kitap eklenmemiş'
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
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    itemBuilder: (context, index) =>
                        _buildBookRow(_filteredList[index]),
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
                  'Gösterilen: ${_filteredList.length} / ${_bookList.length} kitap',
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
    );
  }

  Widget _buildBookRow(Book book) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Kapak Resmi
              Container(
                width: 50,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF8D6E63).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF8D6E63).withValues(alpha: 0.2),
                  ),
                  image: _getImageProvider(book.coverImageUrl) != null
                      ? DecorationImage(
                          image: _getImageProvider(book.coverImageUrl)!,
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        )
                      : null,
                ),
                child: book.coverImageUrl == null || book.coverImageUrl!.isEmpty
                    ? const Icon(
                        Icons.book_outlined,
                        color: Color(0xFF8D6E63),
                        size: 24,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Kitap Bilgileri
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3E2723),
                        fontSize: 15,
                      ),
                    ),
                    if (book.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        book.subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.qr_code_outlined,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          book.isbn,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (book.publicationYear != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            book.publicationYear.toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        if (book.categoryName != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.category_outlined,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            book.categoryName!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Yazar
              Expanded(
                flex: 2,
                child: Text(
                  book.authorName ?? '-',
                  style: const TextStyle(color: Color(0xFF5D4037)),
                ),
              ),
              // Kategori
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8D6E63).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    book.categoryName ?? '-',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8D6E63),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              // Kopya
              Expanded(
                flex: 1,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${book.availableCopies}/${book.totalCopies}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                      if (book.borrowedCopies > 0)
                        Text(
                          '${book.borrowedCopies} ödünç',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Durum
              Expanded(
                flex: 1,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: book.isAvailable
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: book.isAvailable ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            book.isAvailable ? 'Stokda Var' : 'Stokda Yok',
                            style: TextStyle(
                              fontSize: 11,
                              color: book.isAvailable ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // İşlemler
              SizedBox(
                width: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      color: const Color(0xFF8D6E63),
                      onPressed: () => _showAddEditDialog(book),
                      tooltip: 'Düzenle',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      color: Colors.red.shade400,
                      onPressed: () => _showDeleteDialog(book),
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
