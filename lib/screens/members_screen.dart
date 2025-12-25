import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/member.dart';
import '../services/member_service.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MemberService _memberService = MemberService();
  String _searchQuery = '';
  String _selectedFilter = 'Tümü';
  String _selectedStatus = 'Tümü';
  bool _isLoading = true;

  final List<String> _memberTypes = [
    'Öğrenci',
    'Öğretmen',
    'Personel',
    'Dış Üye',
  ];
  final List<String> _genderTypes = ['Erkek', 'Kadın'];

  List<Member> _memberList = [];
  String? _dialogError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final members = await _memberService.getAll();
      setState(() {
        _memberList = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veri yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _performSearch() async {
    if (_searchQuery.isEmpty) {
      await _loadData();
      return;
    }
    setState(() => _isLoading = true);
    try {
      final results = await _memberService.search(_searchQuery);
      setState(() {
        _memberList = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Member> get _filteredList {
    return _memberList.where((m) {
      // Search filter
      final matchesSearch =
          _searchQuery.isEmpty ||
          m.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.memberNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.phone.contains(_searchQuery) ||
          (m.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);

      // Type filter
      final matchesType =
          _selectedFilter == 'Tümü' || m.memberType == _selectedFilter;

      // Status filter
      final matchesStatus =
          _selectedStatus == 'Tümü' ||
          (_selectedStatus == 'Aktif' && m.isActive) ||
          (_selectedStatus == 'Pasif' && !m.isActive);

      return matchesSearch && matchesType && matchesStatus;
    }).toList();
  }

  String _generateMemberNo() {
    final year = DateTime.now().year;
    final count = _memberList.length + 1;
    return 'UYE-$year-${count.toString().padLeft(3, '0')}';
  }

  bool _isValidPhone(String value) => value.length == 11;

  bool _isValidTc(String value) {
    if (value.length != 11) return false;
    final last = int.tryParse(value[value.length - 1]);
    if (last == null) return false;
    return last.isEven;
  }

  void _showAddEditDialog([Member? member]) {
    final isEdit = member != null;
    final memberNoController = TextEditingController(
      text: member?.memberNo ?? _generateMemberNo(),
    );
    final nameController = TextEditingController(text: member?.name ?? '');
    final surnameController = TextEditingController(
      text: member?.surname ?? '',
    );
    final tcNoController = TextEditingController(text: member?.tcNo ?? '');
    final phoneController = TextEditingController(text: member?.phone ?? '');
    final emailController = TextEditingController(text: member?.email ?? '');
    final addressController = TextEditingController(
      text: member?.address ?? '',
    );
    final imageUrlController = TextEditingController(
      text: member?.imageUrl ?? '',
    );
    final notesController = TextEditingController(text: member?.notes ?? '');

    String? selectedGender = member?.gender;
    String selectedMemberType = member?.memberType ?? 'Öğrenci';
    DateTime? selectedBirthDate = member?.birthDate;
    DateTime? selectedExpiryDate = member?.expiryDate;
    bool isActive = member?.isActive ?? true;
    File? selectedImageFile;

    _dialogError = null;

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
                  color: const Color(0xFF6D4C41).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
                  color: const Color(0xFF6D4C41),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isEdit ? 'Üye Düzenle' : 'Yeni Üye Ekle',
                style: const TextStyle(
                  color: Color(0xFF3E2723),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 650,
            height: 550,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_dialogError != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _dialogError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Profil Resmi ve Üye No
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profil Resmi
                      Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF6D4C41,
                                  ).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(
                                      0xFF6D4C41,
                                    ).withValues(alpha: 0.3),
                                    width: 3,
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
                                    ? Icon(
                                        Icons.person_rounded,
                                        size: 50,
                                        color: const Color(
                                          0xFF6D4C41,
                                        ).withValues(alpha: 0.5),
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
                                backgroundColor: const Color(0xFF6D4C41),
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
                                hintText: 'Veya Resim URL',
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
                      const SizedBox(width: 24),
                      // Üye No ve Durum
                      Expanded(
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: memberNoController,
                              label: 'Üye No',
                              icon: Icons.badge_outlined,
                              enabled: false, // Her zaman readonly, otomatik oluşturuluyor
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
                                  activeThumbColor: const Color(0xFF6D4C41),
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
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Kişisel Bilgiler Başlığı
                  const Text(
                    'Kişisel Bilgiler',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Ad Soyad
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
                  const SizedBox(height: 12),

                  // TC ve Cinsiyet
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildTextField(
                          controller: tcNoController,
                          label: 'TC Kimlik No',
                          icon: Icons.credit_card_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
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
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedGender,
                            decoration: const InputDecoration(
                              labelText: 'Cinsiyet',
                              prefixIcon: Icon(
                                Icons.wc_outlined,
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
                            items: _genderTypes.map((g) {
                              return DropdownMenuItem(value: g, child: Text(g));
                            }).toList(),
                            onChanged: (value) =>
                                setDialogState(() => selectedGender = value),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Doğum Tarihi ve Üye Tipi
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedBirthDate ?? DateTime(2000),
                              firstDate: DateTime(1940),
                              lastDate: DateTime.now(),
                              locale: const Locale('tr', 'TR'),
                              builder: (context, child) {
                                return Localizations.override(
                                  context: context,
                                  locale: const Locale('tr', 'TR'),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      
                                    ),
                                    child: child!,
                                  ),
                                );
                              },
                            );
                            if (date != null) {
                              setDialogState(() => selectedBirthDate = date);
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
                                  Icons.cake_outlined,
                                  color: Color(0xFF8D6E63),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  selectedBirthDate != null
                                      ? '${selectedBirthDate!.day.toString().padLeft(2, '0')}.${selectedBirthDate!.month.toString().padLeft(2, '0')}.${selectedBirthDate!.year}'
                                      : 'Doğum Tarihi',
                                  style: TextStyle(
                                    color: selectedBirthDate != null
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
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF8F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD7CCC8)),
                          ),
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedMemberType,
                            decoration: const InputDecoration(
                              labelText: 'Üye Tipi',
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
                            items: _memberTypes.map((t) {
                              return DropdownMenuItem(value: t, child: Text(t));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(
                                  () => selectedMemberType = value,
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // İletişim Bilgileri Başlığı
                  const Text(
                    'İletişim Bilgileri',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Telefon ve E-posta
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: phoneController,
                          label: 'Telefon',
                          icon: Icons.phone_outlined,
                          prefixText: '+',
                          keyboardType: TextInputType.phone,
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

                  // Adres
                  _buildTextField(
                    controller: addressController,
                    label: 'Adres',
                    icon: Icons.location_on_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),

                  // Üyelik Bilgileri Başlığı
                  const Text(
                    'Üyelik Bilgileri',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Üyelik Bitiş Tarihi
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                            selectedExpiryDate ??
                            DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
                        locale: const Locale('tr', 'TR'),
                        builder: (context, child) {
                          return Localizations.override(
                            context: context,
                            locale: const Locale('tr', 'TR'),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                
                              ),
                              child: child!,
                            ),
                          );
                        },
                      );
                      if (date != null) {
                        setDialogState(() => selectedExpiryDate = date);
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
                        border: Border.all(color: const Color(0xFFD7CCC8)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.event_outlined,
                            color: Color(0xFF8D6E63),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            selectedExpiryDate != null
                                ? 'Bitiş: ${selectedExpiryDate!.day.toString().padLeft(2, '0')}.${selectedExpiryDate!.month.toString().padLeft(2, '0')}.${selectedExpiryDate!.year}'
                                : 'Üyelik Bitiş Tarihi (Opsiyonel)',
                            style: TextStyle(
                              color: selectedExpiryDate != null
                                  ? const Color(0xFF3E2723)
                                  : const Color(0xFF8D6E63),
                            ),
                          ),
                          const Spacer(),
                          if (selectedExpiryDate != null)
                            GestureDetector(
                              onTap: () => setDialogState(
                                () => selectedExpiryDate = null,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Notlar
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
                if (nameController.text.isEmpty ||
                    surnameController.text.isEmpty) {
                  setDialogState(
                    () => _dialogError = 'Ad ve soyad zorunludur',
                  );
                  return;
                }
                if (!_isValidTc(tcNoController.text)) {
                  setDialogState(() => _dialogError =
                      'TC kimlik 11 haneli olmalı ve son hane 0,2,4,6 veya 8 olmalıdır.');
                  return;
                }
                if (!_isValidPhone(phoneController.text)) {
                  setDialogState(
                    () => _dialogError = 'Telefon 11 haneli olmalıdır (yalnızca rakam).',
                  );
                  return;
                }

                setDialogState(() => _dialogError = null);

                // Resim URL'i: Dosya seçildiyse path, yoksa URL kullan
                String? finalImageUrl;
                if (selectedImageFile != null) {
                  finalImageUrl = selectedImageFile!.path;
                } else if (imageUrlController.text.isNotEmpty) {
                  finalImageUrl = imageUrlController.text;
                }

                final newMember = Member(
                  id: member?.id,
                  memberNo: memberNoController.text,
                  name: nameController.text,
                  surname: surnameController.text,
                  tcNo: tcNoController.text,
                  phone: phoneController.text,
                  email: emailController.text.isNotEmpty
                      ? emailController.text
                      : null,
                  address: addressController.text.isNotEmpty
                      ? addressController.text
                      : null,
                  birthDate: selectedBirthDate,
                  gender: selectedGender,
                  memberType: selectedMemberType,
                  registrationDate: member?.registrationDate ?? DateTime.now(),
                  expiryDate: selectedExpiryDate,
                  isActive: isActive,
                  imageUrl: finalImageUrl,
                  notes: notesController.text.isNotEmpty
                      ? notesController.text
                      : null,
                  borrowedBooksCount: member?.borrowedBooksCount ?? 0,
                  totalBorrowedBooks: member?.totalBorrowedBooks ?? 0,
                );

                try {
                  if (isEdit) {
                    await _memberService.update(newMember);
                  } else {
                    await _memberService.insert(newMember);
                  }
                  await _loadData();
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEdit ? 'Üye güncellendi' : 'Üye eklendi',
                        ),
                        backgroundColor: const Color(0xFF6D4C41),
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
                backgroundColor: const Color(0xFF6D4C41),
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
    bool enabled = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFFAF8F5) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD7CCC8)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        enabled: enabled,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF8D6E63)),
          prefixIcon: Icon(icon, color: const Color(0xFF8D6E63)),
          prefixText: prefixText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(Member member) {
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
              'Üye Sil',
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
              '${member.fullName} adlı üyeyi silmek istediğinize emin misiniz?',
            ),
            if (member.borrowedBooksCount > 0) ...[
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
                        'Bu üyede ${member.borrowedBooksCount} adet ödünç kitap bulunmaktadır!',
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
                await _memberService.delete(member.id!);
                await _loadData();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Üye silindi'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Silme hatası: $e'),
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

  void _showDetailDialog(Member member) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            maxWidth: 500,
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
                      _getMemberTypeColor(member.memberType),
                      _getMemberTypeColor(
                        member.memberType,
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
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 3,
                        ),
                        image: _getImageProvider(member.imageUrl) != null
                            ? DecorationImage(
                                image: _getImageProvider(member.imageUrl)!,
                                fit: BoxFit.cover,
                                onError: (_, __) {},
                              )
                            : null,
                      ),
                      child: member.imageUrl == null || member.imageUrl!.isEmpty
                          ? Center(
                              child: Text(
                                member.name[0].toUpperCase() +
                                    member.surname[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.fullName,
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
                                  member.memberNo,
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
                                  color: member.isActive
                                      ? Colors.green
                                      : Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  member.isActive ? 'Aktif' : 'Pasif',
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
                      'Ödünç',
                      member.borrowedBooksCount.toString(),
                      Icons.book_outlined,
                    ),
                    _buildStatItem(
                      'Toplam',
                      member.totalBorrowedBooks.toString(),
                      Icons.library_books_outlined,
                    ),
                    _buildStatItem(
                      'Tür',
                      member.memberType,
                      Icons.category_outlined,
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
                        Icons.credit_card_outlined,
                        'TC Kimlik',
                        member.maskedTcNo,
                      ),
                      _buildDetailRow(
                        Icons.phone_outlined,
                        'Telefon',
                        member.phone,
                      ),
                      _buildDetailRow(
                        Icons.email_outlined,
                        'E-posta',
                        member.email ?? 'Belirtilmemiş',
                      ),
                      _buildDetailRow(
                        Icons.location_on_outlined,
                        'Adres',
                        member.address ?? 'Belirtilmemiş',
                      ),
                      _buildDetailRow(
                        Icons.cake_outlined,
                        'Doğum Tarihi',
                        member.formattedBirthDate,
                      ),
                      _buildDetailRow(
                        Icons.calendar_today_outlined,
                        'Kayıt Tarihi',
                        member.formattedRegistrationDate,
                      ),
                      _buildDetailRow(
                        Icons.event_outlined,
                        'Üyelik Bitiş',
                        member.formattedExpiryDate,
                        isWarning: member.isExpired,
                      ),
                    ],
                  ),
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddEditDialog(member);
                        },
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Düzenle'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6D4C41),
                          side: const BorderSide(color: Color(0xFF6D4C41)),
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
                          backgroundColor: const Color(0xFF6D4C41),
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

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF6D4C41), size: 24),
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
                  : const Color(0xFF6D4C41).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isWarning ? Colors.red : const Color(0xFF6D4C41),
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

  Color _getMemberTypeColor(String type) {
    switch (type) {
      case 'Öğrenci':
        return const Color(0xFF1976D2);
      case 'Öğretmen':
        return const Color(0xFF388E3C);
      case 'Personel':
        return const Color(0xFF7B1FA2);
      case 'Dış Üye':
        return const Color(0xFFE64A19);
      default:
        return const Color(0xFF6D4C41);
    }
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
                    color: const Color(0xFF6D4C41).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    size: 32,
                    color: Color(0xFF6D4C41),
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Üye Yönetimi',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                    Text(
                      'Kütüphane üyelerini yönetin',
                      style: TextStyle(fontSize: 14, color: Color(0xFF8D6E63)),
                    ),
                  ],
                ),
                const Spacer(),
                // Stats Cards
                _buildStatsCard(
                  'Toplam Üye',
                  _memberList.length.toString(),
                  Icons.people_rounded,
                  const Color(0xFF6D4C41),
                ),
                const SizedBox(width: 12),
                _buildStatsCard(
                  'Aktif',
                  _memberList.where((m) => m.isActive).length.toString(),
                  Icons.check_circle_outline,
                  Colors.green,
                ),
                const SizedBox(width: 12),
                _buildStatsCard(
                  'Ödünç Kitap',
                  _memberList
                      .fold(0, (sum, m) => sum + m.borrowedBooksCount)
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
                                onChanged: (value) {
                                  setState(() => _searchQuery = value);
                                  _performSearch();
                                },
                                decoration: const InputDecoration(
                                  hintText:
                                      'Üye ara (ad, numara, telefon, e-posta)...',
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
                                items: ['Tümü', ..._memberTypes].map((t) {
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
                            icon: const Icon(Icons.person_add_rounded),
                            label: const Text('Yeni Üye'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6D4C41),
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
                          SizedBox(width: 50), // Avatar space
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
                              'Üye Tipi',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5D4037),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Ödünç',
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
                                    Icons.person_search_rounded,
                                    size: 64,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'Henüz üye eklenmemiş'
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
                                  _buildMemberRow(_filteredList[index]),
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
                            'Gösterilen: ${_filteredList.length} / ${_memberList.length} üye',
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

  Widget _buildMemberRow(Member member) {
    final typeColor = _getMemberTypeColor(member.memberType);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDetailDialog(member),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  image: _getImageProvider(member.imageUrl) != null
                      ? DecorationImage(
                          image: _getImageProvider(member.imageUrl)!,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: member.imageUrl == null || member.imageUrl!.isEmpty
                    ? Center(
                        child: Text(
                          member.name[0].toUpperCase(),
                          style: TextStyle(
                            color: typeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Üye Bilgileri
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member.memberNo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // İletişim
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: Color(0xFF8D6E63),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          member.phone,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                      ],
                    ),
                    if (member.email != null) ...[
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
                              member.email!,
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
                        member.address ?? 'Belirtilmemiş',
                        style: TextStyle(
                          fontSize: 12,
                          color: member.address != null
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
              // Üye Tipi
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
                    member.memberType,
                    style: TextStyle(
                      fontSize: 12,
                      color: typeColor,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              // Ödünç Kitap
              Expanded(
                flex: 1,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: member.borrowedBooksCount > 0
                          ? Colors.blue.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${member.borrowedBooksCount} kitap',
                      style: TextStyle(
                        fontSize: 12,
                        color: member.borrowedBooksCount > 0
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
                      color: member.isActive
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
                            color: member.isActive ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          member.isActive ? 'Aktif' : 'Pasif',
                          style: TextStyle(
                            fontSize: 12,
                            color: member.isActive ? Colors.green : Colors.red,
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
                      onPressed: () => _showDetailDialog(member),
                      tooltip: 'Detay',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      color: const Color(0xFF6D4C41),
                      onPressed: () => _showAddEditDialog(member),
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
                      onPressed: () => _showDeleteDialog(member),
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
}
