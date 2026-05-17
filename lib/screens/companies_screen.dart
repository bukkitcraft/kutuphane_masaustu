import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/company.dart';
import '../models/book.dart';
import '../models/expense.dart';
import '../models/author.dart';
import '../models/book_category.dart';
import '../services/company_service.dart';
import '../services/book_service.dart';
import '../services/expense_service.dart';
import '../services/author_service.dart';
import '../services/book_category_service.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CompanyService _companyService = CompanyService();
  final BookService _bookService = BookService();
  final ExpenseService _expenseService = ExpenseService();
  final AuthorService _authorService = AuthorService();
  final BookCategoryService _categoryService = BookCategoryService();
  String _searchQuery = '';
  String _selectedFilter = 'Tümü';
  String _selectedStatus = 'Tümü';
  bool _isLoading = true;

  final List<String> _companyTypes = ['Yayınevi', 'Tedarikçi', 'Diğer'];

  List<Company> _companyList = [];
  
  ImageProvider _getImageProvider(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        return NetworkImage(imageUrl);
      } else if (File(imageUrl).existsSync()) {
        return FileImage(File(imageUrl));
      }
    }
    return const AssetImage('assets/images/default_company.png');
  }
  
  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    setState(() => _isLoading = true);
    try {
      final companies = await _companyService.getAll();
      setState(() {
        _companyList = companies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Firmalar yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Company> get _filteredList {
    return _companyList.where((c) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (c.taxNumber?.contains(_searchQuery) ?? false) ||
          (c.phone?.contains(_searchQuery) ?? false) ||
          (c.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);

      final matchesType =
          _selectedFilter == 'Tümü' || c.companyType == _selectedFilter;

      final matchesStatus =
          _selectedStatus == 'Tümü' ||
          (_selectedStatus == 'Aktif' && c.isActive) ||
          (_selectedStatus == 'Pasif' && !c.isActive);

      return matchesSearch && matchesType && matchesStatus;
    }).toList();
  }

  void _showAddEditDialog([Company? company]) {
    final isEdit = company != null;
    final nameController = TextEditingController(text: company?.name ?? '');
    final taxNumberController = TextEditingController(
      text: company?.taxNumber ?? '',
    );
    final taxOfficeController = TextEditingController(
      text: company?.taxOffice ?? '',
    );
    final phoneController = TextEditingController(text: company?.phone ?? '');
    final emailController = TextEditingController(text: company?.email ?? '');
    final addressController = TextEditingController(
      text: company?.address ?? '',
    );
    final cityController = TextEditingController(text: company?.city ?? '');
    final countryController = TextEditingController(
      text: company?.country ?? 'Türkiye',
    );
    final websiteController = TextEditingController(
      text: company?.website ?? '',
    );
    final contactPersonController = TextEditingController(
      text: company?.contactPerson ?? '',
    );
    final contactPhoneController = TextEditingController(
      text: company?.contactPhone ?? '',
    );
    final contactEmailController = TextEditingController(
      text: company?.contactEmail ?? '',
    );
    final notesController = TextEditingController(text: company?.notes ?? '');
    final imageUrlController = TextEditingController(
      text: company?.imageUrl ?? '',
    );

    String selectedCompanyType = company?.companyType ?? 'Yayınevi';
    bool isActive = company?.isActive ?? true;
    File? selectedImageFile;
    
    // Eğer düzenleme modundaysak ve imageUrl bir dosya yolu ise, File nesnesi oluştur
    if (company?.imageUrl != null && !company!.imageUrl!.startsWith('http')) {
      try {
        selectedImageFile = File(company.imageUrl!);
        if (!selectedImageFile.existsSync()) {
          selectedImageFile = null;
        }
      } catch (_) {
        selectedImageFile = null;
      }
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
                  color: const Color(0xFFA1887F).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isEdit ? Icons.edit_rounded : Icons.add_business_rounded,
                  color: const Color(0xFFA1887F),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isEdit ? 'Firma Düzenle' : 'Yeni Firma Ekle',
                style: const TextStyle(
                  color: Color(0xFF3E2723),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 650,
            height: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo ve Temel Bilgiler
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFA1887F,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(
                                  0xFFA1887F,
                                ).withValues(alpha: 0.3),
                              ),
                              image: selectedImageFile != null
                                  ? DecorationImage(
                                      image: FileImage(selectedImageFile!),
                                      fit: BoxFit.cover,
                                    )
                                  : (imageUrlController.text.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(
                                            imageUrlController.text,
                                          ),
                                          fit: BoxFit.cover,
                                          onError: (_, __) {},
                                        )
                                      : null),
                            ),
                            child: selectedImageFile == null && imageUrlController.text.isEmpty
                                ? const Icon(
                                    Icons.business_rounded,
                                    size: 50,
                                    color: Color(0xFFA1887F),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  FilePickerResult? result = await FilePicker.platform.pickFiles(
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
                                icon: const Icon(Icons.upload_file, size: 14),
                                label: const Text('Resim Seç', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8D6E63),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                              if (selectedImageFile != null || imageUrlController.text.isNotEmpty)
                                const SizedBox(width: 8),
                              if (selectedImageFile != null || imageUrlController.text.isNotEmpty)
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setDialogState(() {
                                      selectedImageFile = null;
                                      imageUrlController.clear();
                                    });
                                  },
                                  icon: const Icon(Icons.clear, size: 14),
                                  label: const Text('Temizle', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
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
                                hintText: 'Veya Logo URL',
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
                      const SizedBox(width: 16),
                      // Firma Adı ve Durum
                      Expanded(
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: nameController,
                              label: 'Firma Adı',
                              icon: Icons.business_rounded,
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
                                  activeThumbColor: const Color(0xFFA1887F),
                                ),
                                Text(
                                  isActive ? 'Aktif' : 'Pasif',
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

                  // Firma Bilgileri
                  const Text(
                    'Firma Bilgileri',
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
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedCompanyType,
                            decoration: const InputDecoration(
                              labelText: 'Firma Tipi',
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
                            items: _companyTypes.map((t) {
                              return DropdownMenuItem(value: t, child: Text(t));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(
                                  () => selectedCompanyType = value,
                                );
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: taxNumberController,
                          label: 'Vergi No',
                          icon: Icons.receipt_long_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: taxOfficeController,
                    label: 'Vergi Dairesi',
                    icon: Icons.account_balance_outlined,
                  ),
                  const SizedBox(height: 16),

                  // İletişim Bilgileri
                  const Text(
                    'İletişim Bilgileri',
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
                          controller: phoneController,
                          label: 'Telefon',
                          icon: Icons.phone_outlined,
                          prefixText: '+',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: emailController,
                          label: 'E-posta',
                          icon: Icons.email_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: websiteController,
                    label: 'Web Sitesi',
                    icon: Icons.language_outlined,
                  ),
                  const SizedBox(height: 16),

                  // Adres Bilgileri
                  const Text(
                    'Adres Bilgileri',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: addressController,
                    label: 'Adres',
                    icon: Icons.location_on_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: cityController,
                          label: 'Şehir',
                          icon: Icons.location_city_outlined,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: countryController,
                          label: 'Ülke',
                          icon: Icons.flag_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // İletişim Kişisi
                  const Text(
                    'İletişim Kişisi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: contactPersonController,
                    label: 'İletişim Kişisi',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: contactPhoneController,
                          label: 'İletişim Telefonu',
                          icon: Icons.phone_outlined,
                          prefixText: '+',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: contactEmailController,
                          label: 'İletişim E-postası',
                          icon: Icons.email_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: notesController,
                    label: 'Notlar',
                    icon: Icons.notes_outlined,
                    maxLines: 2,
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
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Firma adı zorunludur'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final newCompany = Company(
                  id: company?.id,
                  name: nameController.text,
                  taxNumber: taxNumberController.text.isNotEmpty
                      ? taxNumberController.text
                      : null,
                  taxOffice: taxOfficeController.text.isNotEmpty
                      ? taxOfficeController.text
                      : null,
                  phone: phoneController.text.isNotEmpty
                      ? phoneController.text
                      : null,
                  email: emailController.text.isNotEmpty
                      ? emailController.text
                      : null,
                  address: addressController.text.isNotEmpty
                      ? addressController.text
                      : null,
                  city: cityController.text.isNotEmpty
                      ? cityController.text
                      : null,
                  country: countryController.text.isNotEmpty
                      ? countryController.text
                      : null,
                  website: websiteController.text.isNotEmpty
                      ? websiteController.text
                      : null,
                  contactPerson: contactPersonController.text.isNotEmpty
                      ? contactPersonController.text
                      : null,
                  contactPhone: contactPhoneController.text.isNotEmpty
                      ? contactPhoneController.text
                      : null,
                  contactEmail: contactEmailController.text.isNotEmpty
                      ? contactEmailController.text
                      : null,
                  companyType: selectedCompanyType,
                  registrationDate: company?.registrationDate ?? DateTime.now(),
                  isActive: isActive,
                  notes: notesController.text.isNotEmpty
                      ? notesController.text
                      : null,
                  imageUrl: selectedImageFile?.path ?? (imageUrlController.text.isNotEmpty
                      ? imageUrlController.text
                      : null),
                  booksCount: company?.booksCount ?? 0,
                );

                try {
                  if (isEdit) {
                    await _companyService.update(newCompany);
                  } else {
                    await _companyService.insert(newCompany);
                  }
                  Navigator.pop(context);
                  _loadCompanies();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEdit ? 'Firma güncellendi' : 'Firma eklendi',
                        ),
                        backgroundColor: const Color(0xFFA1887F),
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
                backgroundColor: const Color(0xFFA1887F),
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
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
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
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF8D6E63)),
          prefixIcon: Icon(icon, color: const Color(0xFF8D6E63)),
          prefixText: prefixText,
          prefixStyle: const TextStyle(color: Color(0xFF8D6E63)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(Company company) {
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
              'Firma Sil',
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
              '"${company.name}" firmasını silmek istediğinize emin misiniz?',
            ),
            if (company.booksCount > 0) ...[
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
                        'Bu firmaya ait ${company.booksCount} kitap bulunmaktadır!',
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
                await _companyService.delete(company.id!);
                Navigator.pop(context);
                _loadCompanies();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Firma silindi'),
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

  void _showDetailDialog(Company company) {
    int selectedTab = 0;
    DateTime? dateStart;
    DateTime? dateEnd;
    List<Expense> companyExpenses = [];
    bool isLoadingExpenses = false;
    List<Book> companyBooks = [];
    bool isLoadingBooks = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
              maxWidth: 800,
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
                      _getCompanyTypeColor(company.companyType),
                      _getCompanyTypeColor(
                        company.companyType,
                      ).withValues(alpha: 0.8),
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
                            company.imageUrl != null &&
                                company.imageUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(company.imageUrl!),
                                fit: BoxFit.cover,
                                onError: (_, __) {},
                              )
                            : null,
                      ),
                      child:
                          company.imageUrl == null || company.imageUrl!.isEmpty
                          ? const Icon(
                              Icons.business_rounded,
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
                            company.name,
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
                                  company.companyType,
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
                                  color: company.isActive
                                      ? Colors.green
                                      : Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  company.isActive ? 'Aktif' : 'Pasif',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
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
                      'Kitap',
                      company.booksCount.toString(),
                      Icons.book_outlined,
                    ),
                    _buildStatItem(
                      'Kayıt',
                      company.formattedRegistrationDate,
                      Icons.calendar_today_outlined,
                    ),
                  ],
                ),
              ),
              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setDialogState(() => selectedTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedTab == 0
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: selectedTab == 0
                                    ? const Color(0xFFA1887F)
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Bilgiler',
                                style: TextStyle(
                                  fontWeight: selectedTab == 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: selectedTab == 0
                                      ? const Color(0xFFA1887F)
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          setDialogState(() {
                            selectedTab = 1;
                            isLoadingExpenses = true;
                          });
                          final expenses = await _loadCompanyExpenses(company.id, dateStart, dateEnd);
                          setDialogState(() {
                            companyExpenses = expenses;
                            isLoadingExpenses = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedTab == 1
                                ? Colors.white
                                : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: selectedTab == 1
                                    ? Colors.transparent
                                    : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.payment_outlined,
                                color: selectedTab == 1
                                    ? const Color(0xFFA1887F)
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ödemeler',
                                style: TextStyle(
                                  fontWeight: selectedTab == 1
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: selectedTab == 1
                                      ? const Color(0xFFA1887F)
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          setDialogState(() {
                            selectedTab = 2;
                            isLoadingBooks = true;
                          });
                          if (company.id != null) {
                            final books = await _bookService.getByPublisher(company.id!);
                            setDialogState(() {
                              companyBooks = books;
                              isLoadingBooks = false;
                            });
                          } else {
                            setDialogState(() {
                              isLoadingBooks = false;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedTab == 2
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                color: selectedTab == 2
                                    ? const Color(0xFFA1887F)
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Firmadan Alınan Ürünler',
                                style: TextStyle(
                                  fontWeight: selectedTab == 2
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: selectedTab == 2
                                      ? const Color(0xFFA1887F)
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: selectedTab == 0
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Column(
                          children: [
                            if (company.taxNumber != null)
                              _buildDetailRow(
                                Icons.receipt_long_outlined,
                                'Vergi No',
                                company.taxNumber!,
                              ),
                            if (company.taxOffice != null)
                              _buildDetailRow(
                                Icons.account_balance_outlined,
                                'Vergi Dairesi',
                                company.taxOffice!,
                              ),
                            _buildDetailRow(
                              Icons.phone_outlined,
                              'Telefon',
                              company.phone ?? 'Belirtilmemiş',
                            ),
                            _buildDetailRow(
                              Icons.email_outlined,
                              'E-posta',
                              company.email ?? 'Belirtilmemiş',
                            ),
                            if (company.website != null)
                              _buildDetailRow(
                                Icons.language_outlined,
                                'Web Sitesi',
                                company.website!,
                              ),
                            _buildDetailRow(
                              Icons.location_on_outlined,
                              'Adres',
                              company.fullAddress,
                            ),
                            if (company.contactPerson != null) ...[
                              const SizedBox(height: 8),
                              const Divider(),
                              const SizedBox(height: 8),
                              _buildDetailRow(
                                Icons.person_outlined,
                                'İletişim Kişisi',
                                company.contactPerson!,
                              ),
                              if (company.contactPhone != null)
                                _buildDetailRow(
                                  Icons.phone_outlined,
                                  'İletişim Telefonu',
                                  company.contactPhone!,
                                ),
                              if (company.contactEmail != null)
                                _buildDetailRow(
                                  Icons.email_outlined,
                                  'İletişim E-postası',
                                  company.contactEmail!,
                                ),
                            ],
                            if (company.notes != null &&
                                company.notes!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Divider(),
                              const SizedBox(height: 8),
                              _buildDetailRow(
                                Icons.notes_outlined,
                                'Notlar',
                                company.notes!,
                              ),
                            ],
                          ],
                        ),
                      )
                    : selectedTab == 1
                        ? _buildExpensesTab(
                            company,
                            dateStart,
                            dateEnd,
                            companyExpenses,
                            isLoadingExpenses,
                            (start, end) async {
                              setDialogState(() {
                                dateStart = start;
                                dateEnd = end;
                                isLoadingExpenses = true;
                              });
                              final expenses = await _loadCompanyExpenses(company.id, start, end);
                              setDialogState(() {
                                companyExpenses = expenses;
                                isLoadingExpenses = false;
                              });
                            },
                            setDialogState,
                          )
                        : _buildBooksTab(company, companyBooks, isLoadingBooks),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Column(
                  children: [
                    // Firmaya Ödeme Yap butonu
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showPaymentDialog(company);
                        },
                        icon: const Icon(Icons.payment_rounded, size: 20),
                        label: const Text('Firmaya Ödeme Yap'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showAddEditDialog(company);
                            },
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            label: const Text('Düzenle'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFA1887F),
                              side: const BorderSide(color: Color(0xFFA1887F)),
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
                              backgroundColor: const Color(0xFFA1887F),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
        ),
    );
  }

  Future<List<Expense>> _loadCompanyExpenses(
    int? companyId,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    if (companyId == null) return [];
    
    try {
      final allExpenses = await _expenseService.getAll();
      var filtered = allExpenses.where((e) => e.relatedCompanyId == companyId).toList();
      
      if (startDate != null || endDate != null) {
        filtered = filtered.where((e) {
          if (startDate != null && e.expenseDate.isBefore(startDate)) return false;
          if (endDate != null && e.expenseDate.isAfter(endDate.add(const Duration(days: 1)))) return false;
          return true;
        }).toList();
      }
      
      return filtered;
    } catch (e) {
      return [];
    }
  }

  Widget _buildExpensesTab(
    Company company,
    DateTime? dateStart,
    DateTime? dateEnd,
    List<Expense> expenses,
    bool isLoading,
    Function(DateTime?, DateTime?) onDateFilterChanged,
    StateSetter setDialogState,
  ) {
    return Column(
      children: [
        // Tarih Filtreleri
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF8F5),
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: dateStart ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      onDateFilterChanged(date, dateEnd);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD7CCC8)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: Color(0xFF8D6E63)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dateStart != null
                                ? '${dateStart.day.toString().padLeft(2, '0')}.${dateStart.month.toString().padLeft(2, '0')}.${dateStart.year}'
                                : 'Başlangıç Tarihi',
                            style: TextStyle(
                              color: dateStart != null
                                  ? const Color(0xFF3E2723)
                                  : const Color(0xFF8D6E63),
                            ),
                          ),
                        ),
                        if (dateStart != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => onDateFilterChanged(null, dateEnd),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: dateEnd ?? DateTime.now(),
                      firstDate: dateStart ?? DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      onDateFilterChanged(dateStart, date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD7CCC8)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event, size: 18, color: Color(0xFF8D6E63)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dateEnd != null
                                ? '${dateEnd.day.toString().padLeft(2, '0')}.${dateEnd.month.toString().padLeft(2, '0')}.${dateEnd.year}'
                                : 'Bitiş Tarihi',
                            style: TextStyle(
                              color: dateEnd != null
                                  ? const Color(0xFF3E2723)
                                  : const Color(0xFF8D6E63),
                            ),
                          ),
                        ),
                        if (dateEnd != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => onDateFilterChanged(dateStart, null),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Ödemeler Listesi
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : expenses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.payment_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            dateStart != null || dateEnd != null
                                ? 'Seçili tarih aralığında ödeme bulunamadı'
                                : 'Bu firmaya ait ödeme bulunamadı',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final expense = expenses[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.payment_rounded,
                                color: Color(0xFF2E7D32),
                                size: 24,
                              ),
                            ),
                            title: Text(
                              expense.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      expense.formattedDate,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8D6E63).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        expense.category,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF8D6E63),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (expense.description != null &&
                                    expense.description!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    expense.description!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (expense.paymentMethod != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.payment,
                                        size: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        expense.paymentMethod!,
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
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  expense.formattedAmount,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                                if (expense.invoiceNo != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Fatura: ${expense.invoiceNo}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
        // Toplam
        if (!isLoading && expenses.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8F5),
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Toplam:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                ),
                Text(
                  '₺${expenses.fold<double>(0, (sum, e) => sum + e.amount).toStringAsFixed(2).replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                    (Match m) => '${m[1]}.',
                  )}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFA1887F), size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF3E2723),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildBooksTab(Company company, List<Book> books, bool isLoading) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF8F5),
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                color: const Color(0xFF8D6E63),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Firmadan Alınan Ürünler (${books.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E2723),
                ),
              ),
            ],
          ),
        ),
        // Kitaplar Listesi
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : books.isEmpty
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
                            'Bu firmadan henüz ürün alınmamış',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        final book = books[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
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
                                        image: _getImageProvider(book.coverImageUrl),
                                        fit: BoxFit.cover,
                                        onError: (_, __) {},
                                      )
                                    : null,
                              ),
                              child: book.coverImageUrl == null ||
                                      book.coverImageUrl!.isEmpty
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
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                if (book.authorName != null) ...[
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        size: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        book.authorName!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                Row(
                                  children: [
                                    Icon(
                                      Icons.qr_code_outlined,
                                      size: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      book.isbn,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: book.isAvailable
                                            ? Colors.green.withValues(alpha: 0.1)
                                            : Colors.red.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        book.isAvailable ? 'Stokda Var' : 'Stokda Yok',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: book.isAvailable
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (book.publicationYear != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Yayın Yılı: ${book.publicationYear}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8D6E63).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${book.availableCopies}/${book.totalCopies}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF8D6E63),
                                    ),
                                  ),
                                ),
                                if (book.borrowedCopies > 0) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '${book.borrowedCopies} ödünç',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFA1887F).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFFA1887F)),
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
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF3E2723),
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

  Color _getCompanyTypeColor(String type) {
    switch (type) {
      case 'Yayınevi':
        return const Color(0xFF1976D2);
      case 'Tedarikçi':
        return const Color(0xFF388E3C);
      case 'Diğer':
        return const Color(0xFF7B1FA2);
      default:
        return const Color(0xFFA1887F);
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
                    color: const Color(0xFFA1887F).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business_rounded,
                    size: 32,
                    color: Color(0xFFA1887F),
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Firma Yönetimi',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                    Text(
                      'Yayınevi ve tedarikçileri yönetin',
                      style: TextStyle(fontSize: 14, color: Color(0xFF8D6E63)),
                    ),
                  ],
                ),
                const Spacer(),
                // Stats Cards
                _buildStatsCard(
                  'Toplam Firma',
                  _companyList.length.toString(),
                  Icons.business_rounded,
                  const Color(0xFFA1887F),
                ),
                const SizedBox(width: 12),
                _buildStatsCard(
                  'Aktif',
                  _companyList.where((c) => c.isActive).length.toString(),
                  Icons.check_circle_outline,
                  Colors.green,
                ),
                const SizedBox(width: 12),
                _buildStatsCard(
                  'Kitap',
                  _companyList
                      .fold(0, (sum, c) => sum + c.booksCount)
                      .toString(),
                  Icons.book_outlined,
                  Colors.blue,
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
                                      'Firma ara (ad, vergi no, telefon, e-posta)...',
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
                                value: _selectedFilter,
                                items: ['Tümü', ..._companyTypes].map((t) {
                                  return DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  );
                                }).toList(),
                                onChanged: (value) =>
                                    setState(() => _selectedFilter = value!),
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
                                value: _selectedStatus,
                                items: ['Tümü', 'Aktif', 'Pasif'].map((s) {
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
                            label: const Text('Yeni Firma'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA1887F),
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
                          SizedBox(width: 60), // Logo space
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Firma Bilgileri',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5D4037),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'İletişim',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5D4037),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Adres',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5D4037),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Tip',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5D4037),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Kitap',
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
                                        Icons.business_outlined,
                                        size: 64,
                                        color: Colors.grey.shade300,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchQuery.isEmpty
                                            ? 'Henüz firma eklenmemiş'
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
                                  _buildCompanyRow(_filteredList[index]),
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
                            'Gösterilen: ${_filteredList.length} / ${_companyList.length} firma',
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

  Widget _buildCompanyRow(Company company) {
    final typeColor = _getCompanyTypeColor(company.companyType);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDetailDialog(company),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Logo
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: typeColor.withValues(alpha: 0.2)),
                  image: company.imageUrl != null && company.imageUrl!.isNotEmpty
                      ? DecorationImage(
                          image: _getImageProvider(company.imageUrl!),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        )
                      : null,
                ),
                child: company.imageUrl == null || company.imageUrl!.isEmpty
                    ? Icon(Icons.business_rounded, color: typeColor, size: 28)
                    : null,
              ),
              const SizedBox(width: 12),
              // Firma Bilgileri
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                    if (company.taxNumber != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Vergi No: ${company.taxNumber}',
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
              // İletişim
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (company.phone != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: Color(0xFF8D6E63),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              company.phone!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF5D4037),
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (company.email != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            size: 14,
                            color: Color(0xFF8D6E63),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              company.email!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF5D4037),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Adres
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Color(0xFF8D6E63),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        company.fullAddress,
                        style: TextStyle(
                          fontSize: 12,
                          color: company.address != null
                              ? const Color(0xFF5D4037)
                              : Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Tip
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    company.companyType,
                    style: TextStyle(
                      fontSize: 12,
                      color: typeColor,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              // Kitap Sayısı
              Expanded(
                flex: 1,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: company.booksCount > 0
                          ? Colors.blue.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${company.booksCount} kitap',
                      style: TextStyle(
                        fontSize: 12,
                        color: company.booksCount > 0
                            ? Colors.blue
                            : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
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
                      color: company.isActive
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: company.isActive ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          company.isActive ? 'Aktif' : 'Pasif',
                          style: TextStyle(
                            fontSize: 12,
                            color: company.isActive ? Colors.green : Colors.red,
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_rounded, size: 18),
                      color: const Color(0xFF8D6E63),
                      onPressed: () => _showDetailDialog(company),
                      tooltip: 'Detay',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      color: const Color(0xFFA1887F),
                      onPressed: () => _showAddEditDialog(company),
                      tooltip: 'Düzenle',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      color: Colors.red.shade400,
                      onPressed: () => _showDeleteDialog(company),
                      tooltip: 'Sil',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
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

  void _showPaymentDialog(Company company) async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final invoiceNoController = TextEditingController();
    final notesController = TextEditingController();
    
    // Kitap bilgileri için controller'lar
    final bookIsbnController = TextEditingController();
    final bookTitleController = TextEditingController();
    final bookQuantityController = TextEditingController(text: '1');
    
    String selectedCategory = 'Kitap Alımı';
    String selectedPaymentMethod = 'Banka Transferi';
    DateTime selectedDate = DateTime.now();
    
    // Kitap bilgileri için değişkenler
    int? selectedAuthorId;
    int? selectedCategoryId;
    List<Author> authors = [];
    List<BookCategory> categories = [];
    
    // Yazarları ve kategorileri yükle
    try {
      authors = await _authorService.getAll();
      categories = await _categoryService.getAll();
    } catch (e) {
      // Hata durumunda boş liste
    }
    
    // quantityController değiştiğinde bookQuantityController'ı güncelle
    quantityController.addListener(() {
      if (selectedCategory == 'Kitap Alımı' && quantityController.text.isNotEmpty) {
        bookQuantityController.text = quantityController.text;
      }
    });
    
    final expenseCategories = ['Kitap Alımı', 'Kırtasiye', 'Bakım', 'Diğer'];
    final paymentMethods = ['Nakit', 'Kredi Kartı', 'Banka Transferi', 'Çek'];
    
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
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.payment_rounded,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Firmaya Ödeme Yap',
                      style: TextStyle(
                        color: Color(0xFF3E2723),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      company.name,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8D6E63),
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Firma Bilgileri
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF8F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD7CCC8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Firma Bilgileri',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (company.phone != null)
                          _buildPaymentInfoRow(Icons.phone_outlined, 'Telefon', company.phone!),
                        if (company.email != null)
                          _buildPaymentInfoRow(Icons.email_outlined, 'E-posta', company.email!),
                        if (company.taxNumber != null)
                          _buildPaymentInfoRow(Icons.receipt_long_outlined, 'Vergi No', company.taxNumber!),
                        if (company.address != null)
                          _buildPaymentInfoRow(Icons.location_on_outlined, 'Adres', company.fullAddress),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Kategori
                  const Text(
                    'Kategori *',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF8F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD7CCC8)),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.category_outlined, color: Color(0xFF8D6E63)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: expenseCategories.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedCategory = value;
                            // Kategori değiştiğinde kitap adedini güncelle
                            if (value == 'Kitap Alımı' && quantityController.text.isNotEmpty) {
                              bookQuantityController.text = quantityController.text;
                            }
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Başlık
                  _buildPaymentTextField(
                    controller: titleController,
                    label: 'Ödeme Başlığı *',
                    icon: Icons.title,
                    hint: 'Örn: Kitap alımı, Kırtasiye malzemeleri',
                  ),
                  const SizedBox(height: 16),
                  
                  // Kitap Bilgileri (Sadece Kitap Alımı kategorisinde göster)
                  if (selectedCategory == 'Kitap Alımı') ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.book_outlined,
                                color: Color(0xFF2196F3),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Kitap Bilgileri',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildPaymentTextField(
                            controller: bookIsbnController,
                            label: 'ISBN (13 haneli) *',
                            icon: Icons.qr_code_outlined,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(13),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildPaymentTextField(
                            controller: bookTitleController,
                            label: 'Kitap Adı *',
                            icon: Icons.title,
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
                                    value: selectedAuthorId,
                                    decoration: const InputDecoration(
                                      labelText: 'Yazar (Opsiyonel)',
                                      prefixIcon: Icon(Icons.person_outline, color: Color(0xFF8D6E63)),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    items: [
                                      const DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text('Seçiniz'),
                                      ),
                                      ...authors.map((a) {
                                        return DropdownMenuItem<int?>(
                                          value: a.id,
                                          child: Text(a.fullName),
                                        );
                                      }),
                                    ],
                                    onChanged: (value) {
                                      setDialogState(() => selectedAuthorId = value);
                                    },
                                  ),
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
                                  child: DropdownButtonFormField<int?>(
                                    value: selectedCategoryId,
                                    decoration: const InputDecoration(
                                      labelText: 'Kategori (Opsiyonel)',
                                      prefixIcon: Icon(Icons.category_outlined, color: Color(0xFF8D6E63)),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    items: [
                                      const DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text('Seçiniz'),
                                      ),
                                      ...categories.map((c) {
                                        return DropdownMenuItem<int?>(
                                          value: c.id,
                                          child: Text(c.name),
                                        );
                                      }),
                                    ],
                                    onChanged: (value) {
                                      setDialogState(() => selectedCategoryId = value);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildPaymentTextField(
                            controller: bookQuantityController,
                            label: 'Kitap Adedi *',
                            icon: Icons.numbers,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Kitap bilgileri girildiğinde, ödeme kaydedildikten sonra kitap otomatik olarak "Firmadan Alınan Ürünler" listesine eklenecektir.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Miktar ve Tutar
                  Row(
                    children: [
                      Expanded(
                        child: _buildPaymentTextField(
                          controller: quantityController,
                          label: 'Miktar',
                          icon: Icons.numbers,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPaymentTextField(
                          controller: amountController,
                          label: 'Tutar (₺) *',
                          icon: Icons.attach_money,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Açıklama
                  _buildPaymentTextField(
                    controller: descriptionController,
                    label: 'Açıklama',
                    icon: Icons.description_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  
                  // Ödeme Yöntemi
                  const Text(
                    'Ödeme Yöntemi *',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF8F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD7CCC8)),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedPaymentMethod,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.payment, color: Color(0xFF8D6E63)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: paymentMethods.map((p) {
                        return DropdownMenuItem(value: p, child: Text(p));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedPaymentMethod = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Fatura No
                  _buildPaymentTextField(
                    controller: invoiceNoController,
                    label: 'Fatura No (Opsiyonel)',
                    icon: Icons.receipt_long_outlined,
                  ),
                  const SizedBox(height: 16),
                  
                  // Tarih
                  ListTile(
                    title: const Text('Ödeme Tarihi'),
                    subtitle: Text(
                      '${selectedDate.day.toString().padLeft(2, '0')}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.year}',
                    ),
                    leading: const Icon(Icons.calendar_today_outlined),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      onPressed: () async {
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
                  ),
                  const SizedBox(height: 16),
                  
                  // Notlar
                  _buildPaymentTextField(
                    controller: notesController,
                    label: 'Notlar',
                    icon: Icons.notes_outlined,
                    maxLines: 2,
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
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lütfen ödeme başlığı girin'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lütfen geçerli bir tutar girin'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                try {
                  // Expense numarası oluştur
                  final allExpenses = await _expenseService.getAll();
                  final now = DateTime.now();
                  final expenseCounter = allExpenses.length + 1;
                  final expenseNo = 'GID-${now.year}-${expenseCounter.toString().padLeft(4, '0')}';
                  
                  // Miktar bilgisini başlığa ekle
                  String finalTitle = titleController.text.trim();
                  final quantity = quantityController.text.trim();
                  if (quantity.isNotEmpty && quantity != '1') {
                    finalTitle = '$finalTitle (Miktar: $quantity)';
                  }
                  
                  final expense = Expense(
                    expenseNo: expenseNo,
                    title: finalTitle,
                    description: descriptionController.text.trim().isEmpty
                        ? '${company.name} firmasına yapılan ödeme'
                        : descriptionController.text.trim(),
                    amount: amount,
                    category: selectedCategory,
                    expenseDate: selectedDate,
                    payeeName: company.name,
                    payeePhone: company.phone,
                    payeeEmail: company.email,
                    paymentMethod: selectedPaymentMethod,
                    invoiceNo: invoiceNoController.text.trim().isEmpty
                        ? null
                        : invoiceNoController.text.trim(),
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                    relatedCompanyId: company.id,
                  );
                  
                  await _expenseService.insert(expense);
                  
                  // Eğer kategori "Kitap Alımı" ise ve kitap bilgileri girilmişse, kitabı kaydet
                  if (selectedCategory == 'Kitap Alımı' && 
                      bookIsbnController.text.trim().isNotEmpty &&
                      bookTitleController.text.trim().isNotEmpty) {
                    try {
                      // ISBN kontrolü
                      if (bookIsbnController.text.trim().length != 13) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ISBN 13 haneli olmalıdır'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      } else {
                        // Kitap adedi
                        final bookQuantity = int.tryParse(bookQuantityController.text.trim()) ?? 1;
                        if (bookQuantity < 1) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kitap adedi en az 1 olmalıdır'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        } else {
                          // Yazar ve kategori isimlerini al
                          String? authorName;
                          if (selectedAuthorId != null) {
                            try {
                              final author = authors.firstWhere((a) => a.id == selectedAuthorId);
                              authorName = author.fullName;
                            } catch (e) {
                              // Yazar bulunamadı, null bırak
                            }
                          }
                          
                          String? categoryName;
                          if (selectedCategoryId != null) {
                            try {
                              final category = categories.firstWhere((c) => c.id == selectedCategoryId);
                              categoryName = category.name;
                            } catch (e) {
                              // Kategori bulunamadı, null bırak
                            }
                          }
                          
                          // Kitabı oluştur
                          final newBook = Book(
                            isbn: bookIsbnController.text.trim(),
                            title: bookTitleController.text.trim(),
                            authorId: selectedAuthorId,
                            authorName: authorName,
                            categoryId: selectedCategoryId,
                            categoryName: categoryName,
                            publisherId: company.id,
                            publisherName: company.name,
                            totalCopies: bookQuantity,
                            availableCopies: bookQuantity,
                            borrowedCopies: 0,
                            addedDate: selectedDate,
                            isActive: true,
                            language: 'Türkçe',
                          );
                          
                          await _bookService.insert(newBook);
                          
                          // Yazar kitap sayacını güncelle
                          if (selectedAuthorId != null) {
                            final authorBooks = await _bookService.getByAuthor(selectedAuthorId!);
                            await _authorService.updateBooksCount(selectedAuthorId!, authorBooks.length);
                          }
                          
                          // Kategori kitap sayacını güncelle
                          if (selectedCategoryId != null) {
                            final categoryBooks = await _bookService.getByCategory(selectedCategoryId!);
                            await _categoryService.updateBooksCount(selectedCategoryId!, categoryBooks.length);
                          }
                          
                          // Yayınevi kitap sayacını güncelle
                          if (company.id != null) {
                            final publisherBooks = await _bookService.getByPublisher(company.id!);
                            await _companyService.updateBooksCount(company.id!, publisherBooks.length);
                          }
                        }
                      }
                    } catch (e) {
                      // Kitap kaydetme hatası - ödeme zaten kaydedildi, sadece uyarı ver
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Ödeme kaydedildi ancak kitap eklenirken hata oluştu: $e'),
                            backgroundColor: Colors.orange,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                    }
                  }
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          selectedCategory == 'Kitap Alımı' && 
                          bookIsbnController.text.trim().isNotEmpty &&
                          bookTitleController.text.trim().isNotEmpty
                              ? 'Ödeme kaydedildi ve kitap "Firmadan Alınan Ürünler" listesine eklendi'
                              : '${company.name} firmasına ödeme kaydedildi'
                        ),
                        backgroundColor: const Color(0xFF2E7D32),
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
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Ödeme Yap'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF8D6E63)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5D4037),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF3E2723),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? hint,
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
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
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
}
