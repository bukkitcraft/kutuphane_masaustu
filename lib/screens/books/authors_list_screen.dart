import 'package:flutter/material.dart';
import 'dart:io';
import '../../models/author.dart';
import '../../models/book.dart';
import '../../services/author_service.dart';
import '../../services/book_service.dart';

class AuthorsListScreen extends StatefulWidget {
  const AuthorsListScreen({super.key});

  @override
  State<AuthorsListScreen> createState() => _AuthorsListScreenState();
}

class _AuthorsListScreenState extends State<AuthorsListScreen> {
  final AuthorService _authorService = AuthorService();
  final BookService _bookService = BookService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Author> _authorList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAuthors();
  }

  Future<void> _loadAuthors() async {
    setState(() => _isLoading = true);
    try {
      final authors = await _authorService.getAll();
      setState(() {
        _authorList = authors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Author> get _filteredList {
    if (_searchQuery.isEmpty) return _authorList;
    return _authorList.where((a) {
      final query = _searchQuery.toLowerCase();
      return a.fullName.toLowerCase().contains(query) ||
          (a.nationality?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void _showAddEditDialog([Author? author]) {
    final isEdit = author != null;
    final nameController = TextEditingController(text: author?.name ?? '');
    final surnameController = TextEditingController(
      text: author?.surname ?? '',
    );
    final biographyController = TextEditingController(
      text: author?.biography ?? '',
    );
    final imageUrlController = TextEditingController(
      text: author?.imageUrl ?? '',
    );

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
                  isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
                  color: const Color(0xFF8D6E63),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isEdit ? 'Yazar Düzenle' : 'Yeni Yazar Ekle',
                style: const TextStyle(
                  color: Color(0xFF3E2723),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            height: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Profil Resmi
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF8D6E63,
                            ).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(
                                0xFF8D6E63,
                              ).withValues(alpha: 0.3),
                              width: 3,
                            ),
                            image: imageUrlController.text.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(
                                      imageUrlController.text,
                                    ),
                                    fit: BoxFit.cover,
                                    onError: (_, __) {},
                                  )
                                : null,
                          ),
                          child: imageUrlController.text.isEmpty
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 50,
                                  color: const Color(
                                    0xFF8D6E63,
                                  ).withValues(alpha: 0.5),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 300,
                          child: TextField(
                            controller: imageUrlController,
                            style: const TextStyle(fontSize: 11),
                            onChanged: (_) => setDialogState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Resim URL',
                              hintStyle: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
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
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: nameController,
                          label: 'Ad',
                          icon: Icons.person_outline_rounded,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: surnameController,
                          label: 'Soyad',
                          icon: Icons.person_outline_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: biographyController,
                    label: 'Biyografi',
                    icon: Icons.description_outlined,
                    maxLines: 4,
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
                if (nameController.text.isEmpty ||
                    surnameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ad ve soyad zorunludur'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final newAuthor = Author(
                  id: author?.id,
                  name: nameController.text,
                  surname: surnameController.text,
                  nationality: author?.nationality,
                  birthDate: author?.birthDate,
                  deathDate: author?.deathDate,
                  biography: biographyController.text.isNotEmpty
                      ? biographyController.text
                      : null,
                  imageUrl: imageUrlController.text.isNotEmpty
                      ? imageUrlController.text
                      : null,
                  booksCount: author?.booksCount ?? 0,
                );

                try {
                  if (isEdit) {
                    await _authorService.update(newAuthor);
                  } else {
                    await _authorService.insert(newAuthor);
                  }
                  await _loadAuthors();
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEdit ? 'Yazar güncellendi' : 'Yazar eklendi',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
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

  void _showAuthorBooksDialog(Author author) async {
    // Yazarın kitaplarını yükle
    List<Book> authorBooks = [];
    bool isLoading = true;

    try {
      authorBooks = await _bookService.getByAuthor(author.id!);
      isLoading = false;
    } catch (e) {
      isLoading = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kitaplar yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                Icons.library_books_rounded,
                color: Color(0xFF8D6E63),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author.fullName,
                    style: const TextStyle(
                      color: Color(0xFF3E2723),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    '${authorBooks.length} kitap',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 600,
          height: 500,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : authorBooks.isEmpty
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
                            'Bu yazara ait kitap bulunmamaktadır',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: authorBooks.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final book = authorBooks[index];
                        return ListTile(
                          leading: Container(
                            width: 50,
                            height: 70,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8D6E63).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF8D6E63).withValues(alpha: 0.2),
                              ),
                              image: book.coverImageUrl != null &&
                                      book.coverImageUrl!.isNotEmpty
                                  ? DecorationImage(
                                      image: book.coverImageUrl!.startsWith('http://') ||
                                              book.coverImageUrl!.startsWith('https://')
                                          ? NetworkImage(book.coverImageUrl!)
                                          : FileImage(File(book.coverImageUrl!)) as ImageProvider,
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
                          title: Text(
                            book.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3E2723),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (book.subtitle != null) ...[
                                Text(
                                  book.subtitle!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
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
                                    const SizedBox(width: 12),
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
                                ],
                              ),
                            ],
                          ),
                          trailing: Container(
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
                            child: Text(
                              '${book.availableCopies}/${book.totalCopies}',
                              style: TextStyle(
                                fontSize: 12,
                                color: book.isAvailable ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Kapat',
              style: TextStyle(color: Color(0xFF8D6E63)),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Author author) {
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
              'Yazar Sil',
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
              '${author.fullName} adlı yazarı silmek istediğinize emin misiniz?',
            ),
            if (author.booksCount > 0) ...[
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
                        'Bu yazara ait ${author.booksCount} kitap bulunmaktadır!',
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
                await _authorService.delete(author.id!);
                await _loadAuthors();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Yazar silindi'),
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
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
                        hintText: 'Yazar ara...',
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
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditDialog(),
                  icon: const Icon(Icons.person_add_rounded),
                  label: const Text('Yeni Yazar'),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: const Color(0xFFFAF8F5),
            child: const Row(
              children: [
                SizedBox(width: 60),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Yazar',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Biyografi',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Kitap Sayısı',
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
          Expanded(
            child: _filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search_rounded,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Henüz yazar eklenmemiş'
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
                        _buildAuthorRow(_filteredList[index]),
                  ),
          ),
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
                  'Gösterilen: ${_filteredList.length} / ${_authorList.length} yazar',
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

  Widget _buildAuthorRow(Author author) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAuthorBooksDialog(author),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF8D6E63).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  image: author.imageUrl != null && author.imageUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(author.imageUrl!),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        )
                      : null,
                ),
                child: author.imageUrl == null || author.imageUrl!.isEmpty
                    ? Center(
                        child: Text(
                          author.name[0].toUpperCase() +
                              author.surname[0].toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF8D6E63),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  author.biography ?? '-',
                  style: const TextStyle(
                    color: Color(0xFF5D4037),
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8D6E63).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${author.booksCount} kitap',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8D6E63),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      color: const Color(0xFF8D6E63),
                      onPressed: () => _showAddEditDialog(author),
                      tooltip: 'Düzenle',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      color: Colors.red.shade400,
                      onPressed: () => _showDeleteDialog(author),
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
