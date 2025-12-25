import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../models/personnel.dart';
import '../../models/department.dart';
import '../../services/personnel_service.dart';
import '../../services/department_service.dart';
import '../finance_screen.dart';

class PersonnelListScreen extends StatefulWidget {
  const PersonnelListScreen({super.key});

  @override
  State<PersonnelListScreen> createState() => _PersonnelListScreenState();
}

class _PersonnelListScreenState extends State<PersonnelListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PersonnelService _personnelService = PersonnelService();
  final DepartmentService _departmentService = DepartmentService();
  final List<Color> _departmentColors = const [
    Color(0xFF2E7D32), // deep green
    Color(0xFF43A047), // green tone
    Color(0xFF1565C0), // deep blue
    Color(0xFF1E88E5), // blue tone
    Color(0xFFF9A825), // warm yellow
    Color(0xFFFBC02D), // yellow tone
    Color(0xFFC62828), // deep red
    Color(0xFFD32F2F), // red tone
  ];
  String _searchQuery = '';
  bool _isLoading = true;

  List<Department> _departments = [];
  List<Personnel> _personnelList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final departments = await _departmentService.getAll();
      final personnel = await _personnelService.getAll();
      final updatedDepartments = _mergeDepartmentCounts(departments, personnel);
      setState(() {
        _departments = updatedDepartments;
        _personnelList = personnel;
      });
      await _persistDepartmentCounts(updatedDepartments);
      setState(() => _isLoading = false);
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
      final results = await _personnelService.search(_searchQuery);
      setState(() {
        _personnelList = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Arama hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Personnel> get _filteredList => _personnelList;

  bool _isValidPhone(String value) => value.length == 11;

  bool _isValidTc(String value) {
    if (value.length != 11) return false;
    final lastDigit = int.tryParse(value[value.length - 1]);
    if (lastDigit == null) return false;
    return lastDigit.isEven;
  }

  String _formatPhone(String value) => value.isEmpty ? '-' : '+$value';

  String _formatTc(String? value) => (value == null || value.isEmpty) ? '-' : value;

  List<Department> _mergeDepartmentCounts(
    List<Department> departments,
    List<Personnel> personnel,
  ) {
    final counts = <int, int>{};
    for (final person in personnel) {
      final deptId = person.departmentId;
      if (deptId != null) {
        counts[deptId] = (counts[deptId] ?? 0) + 1;
      }
    }

    return departments
        .map(
          (d) => d.copyWith(
            personnelCount: counts[d.id] ?? 0,
          ),
        )
        .toList();
  }

  Future<void> _persistDepartmentCounts(List<Department> departments) async {
    final updates = departments.where((d) => d.id != null).map(
          (d) => _departmentService.updatePersonnelCount(
            d.id!,
            d.personnelCount,
          ),
        );
    await Future.wait(updates);
  }

  Department? _findDepartment(int? departmentId) {
    if (departmentId == null) return null;
    for (final department in _departments) {
      if (department.id == departmentId) return department;
    }
    return null;
  }

  Color _getDepartmentColor(int? departmentId) {
    final department = _findDepartment(departmentId);
    final storedColor = department != null ? _parseColor(department.colorCode) : null;
    if (storedColor != null) return storedColor;
    if (departmentId != null) {
      return _departmentColors[departmentId % _departmentColors.length];
    }
    return _departmentColors.first;
  }

  Color? _parseColor(String? code) {
    if (code == null || code.isEmpty) return null;
    try {
      final normalized = code.startsWith('0x') ? code : '0x${code.replaceFirst('#', '')}';
      return Color(int.parse(normalized));
    } catch (_) {
      return null;
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

  void _showAddEditDialog([Personnel? personnel]) {
    final isEdit = personnel != null;
    final nameController = TextEditingController(text: personnel?.name ?? '');
    final surnameController = TextEditingController(
      text: personnel?.surname ?? '',
    );
    final phoneController = TextEditingController(text: personnel?.phone ?? '');
    final emailController = TextEditingController(text: personnel?.email ?? '');
    final tcController = TextEditingController(text: personnel?.tcNo ?? '');
    final salaryController = TextEditingController(
      text: personnel?.salary?.toStringAsFixed(0) ?? '',
    );
    final addressController = TextEditingController(
      text: personnel?.address ?? '',
    );
    final imageUrlController = TextEditingController(
      text: personnel?.imageUrl ?? '',
    );
    final accountNoController = TextEditingController(
      text: personnel?.accountNo ?? '',
    );
    final ibanController = TextEditingController(
      text: (personnel?.iban ?? '').replaceFirst('TR12', ''),
    );
    int? selectedDepartmentId = personnel?.departmentId;
    DateTime? selectedBirthDate = personnel?.birthDate;
    File? selectedImageFile;
    String? dialogError;

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
                  color: const Color(0xFF5D4037).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
                  color: const Color(0xFF5D4037),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isEdit ? 'Personel Düzenle' : 'Yeni Personel Ekle',
                style: const TextStyle(
                  color: Color(0xFF3E2723),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 550,
            height: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dialogError != null)
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
                              dialogError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Profil Resmi
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF5D4037,
                                ).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(
                                    0xFF5D4037,
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
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.person_rounded,
                                          size: 40,
                                          color: const Color(
                                            0xFF5D4037,
                                          ).withValues(alpha: 0.5),
                                        ),
                                      ],
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
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
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
                              icon: const Icon(Icons.image_outlined, size: 18),
                              label: const Text('Resim Seç'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5D4037),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () {
                                setDialogState(() {
                                  imageUrlController.clear();
                                  selectedImageFile = null;
                                });
                              },
                              child: const Text('Temizle'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 300,
                          child: _buildTextField(
                            controller: imageUrlController,
                            label: 'Veya Resim URL (opsiyonel)',
                            icon: Icons.link_outlined,
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                setDialogState(() {
                                  selectedImageFile = null;
                                });
                              }
                              setDialogState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  // TC Kimlik ve Doğum Tarihi
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: tcController,
                          label: 'TC Kimlik',
                          icon: Icons.badge_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedBirthDate ?? DateTime(1990, 1, 1),
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
                              border: Border.all(color: const Color(0xFFD7CCC8)),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  color: Color(0xFF8D6E63),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  selectedBirthDate != null
                                      ? '${selectedBirthDate!.day.toString().padLeft(2, '0')}.${selectedBirthDate!.month.toString().padLeft(2, '0')}.${selectedBirthDate!.year}'
                                      : 'Doğum Tarihi (Opsiyonel)',
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
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Maaş ve Departman
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: salaryController,
                          label: 'Maaş (₺)',
                          icon: Icons.payments_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
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
                          child: DropdownButtonFormField<int>(
                            initialValue: selectedDepartmentId,
                            decoration: const InputDecoration(
                              labelText: 'Departman',
                              prefixIcon: Icon(
                                Icons.account_tree_outlined,
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
                            items: _departments.map((d) {
                              return DropdownMenuItem(
                                value: d.id,
                                child: Text(d.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                selectedDepartmentId = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Adres
                  _buildTextField(
                    controller: addressController,
                    label: 'Adres',
                    icon: Icons.location_on_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  // Finansal Bilgiler Başlığı
                  const Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF5D4037), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Finansal Bilgiler',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E2723),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Hesap No
                  _buildTextField(
                    controller: accountNoController,
                    label: 'Hesap No *',
                    icon: Icons.account_box_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // IBAN
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
                        child: _buildTextField(
                          controller: ibanController,
                          label: 'IBAN * (12 haneli)',
                          icon: Icons.account_balance_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(12),
                          ],
                        ),
                      ),
                    ],
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
                  setDialogState(() {
                    dialogError = 'Ad ve soyad alanları zorunludur';
                  });
                  return;
                }

                if (!_isValidPhone(phoneController.text)) {
                  setDialogState(() {
                    dialogError = 'Telefon 11 haneli olmalıdır (yalnızca rakam).';
                  });
                  return;
                }

                // Hesap no validasyonu (7-10 basamak)
                if (accountNoController.text.trim().isEmpty) {
                  setDialogState(() {
                    dialogError = 'Hesap no zorunludur';
                  });
                  return;
                }
                if (accountNoController.text.trim().length < 7 || accountNoController.text.trim().length > 10) {
                  setDialogState(() {
                    dialogError = 'Hesap no 7-10 basamaklı olmalıdır';
                  });
                  return;
                }

                // IBAN validasyonu (12 basamak)
                if (ibanController.text.trim().isEmpty) {
                  setDialogState(() {
                    dialogError = 'IBAN zorunludur';
                  });
                  return;
                }
                if (ibanController.text.trim().length != 12) {
                  setDialogState(() {
                    dialogError = 'IBAN 12 haneli olmalıdır';
                  });
                  return;
                }

                if (tcController.text.isNotEmpty &&
                    !_isValidTc(tcController.text)) {
                  setDialogState(() {
                    dialogError =
                        'TC kimlik 11 haneli olmalı ve son hane 0,2,4,6 veya 8 olmalıdır.';
                  });
                  return;
                }

                setDialogState(() => dialogError = null);

                final departmentName = _departments
                    .where((d) => d.id == selectedDepartmentId)
                    .map((d) => d.name)
                    .firstOrNull;

                // Resim URL'i: Dosya seçildiyse path, yoksa URL kullan
                String? finalImageUrl;
                if (selectedImageFile != null) {
                  finalImageUrl = selectedImageFile!.path;
                } else if (imageUrlController.text.isNotEmpty) {
                  finalImageUrl = imageUrlController.text;
                }

                final newPersonnel = Personnel(
                  id: personnel?.id,
                  name: nameController.text,
                  surname: surnameController.text,
                  phone: phoneController.text,
                  email: emailController.text,
                  tcNo: tcController.text.isNotEmpty ? tcController.text : null,
                  departmentId: selectedDepartmentId,
                  departmentName: departmentName,
                  startDate: personnel?.startDate ?? DateTime.now(),
                  birthDate: selectedBirthDate,
                  isActive: true,
                  salary: double.tryParse(salaryController.text),
                  address: addressController.text.isNotEmpty
                      ? addressController.text
                      : null,
                  imageUrl: finalImageUrl,
                  accountNo: accountNoController.text.trim(),
                  iban: 'TR12${ibanController.text.trim()}',
                );

                try {
                  if (isEdit) {
                    await _personnelService.update(newPersonnel);
                  } else {
                    await _personnelService.insert(newPersonnel);
                  }
                  await _loadData();
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEdit ? 'Personel güncellendi' : 'Personel eklendi',
                        ),
                        backgroundColor: const Color(0xFF5D4037),
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
                backgroundColor: const Color(0xFF5D4037),
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
    Function(String)? onChanged,
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
        onChanged: onChanged,
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

  void _showDeleteDialog(Personnel personnel) {
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
              'Personel Sil',
              style: TextStyle(
                color: Color(0xFF3E2723),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          '${personnel.fullName} adlı personeli silmek istediğinize emin misiniz?',
          style: const TextStyle(fontSize: 16),
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
                await _personnelService.delete(personnel.id!);
                await _loadData();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Personel silindi'),
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

  void _showDetailDialog(Personnel personnel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 450,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF5D4037), Color(0xFF4E342E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 3,
                        ),
                        image: _getImageProvider(personnel.imageUrl) != null
                            ? DecorationImage(
                                image: _getImageProvider(personnel.imageUrl)!,
                                fit: BoxFit.cover,
                                onError: (_, __) {},
                              )
                            : null,
                      ),
                      child:
                          personnel.imageUrl == null ||
                              personnel.imageUrl!.isEmpty
                          ? Center(
                              child: Text(
                                personnel.name[0].toUpperCase() +
                                    personnel.surname[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
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
                            personnel.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
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
                              personnel.departmentName ?? 'Belirtilmemiş',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Details - Scrollable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDetailRow(
                        Icons.email_outlined,
                        'E-posta',
                        personnel.email,
                      ),
                      _buildDetailRow(
                        Icons.phone_outlined,
                        'Telefon',
                        _formatPhone(personnel.phone),
                      ),
                      if (personnel.tcNo != null && personnel.tcNo!.isNotEmpty)
                        _buildDetailRow(
                          Icons.badge_outlined,
                          'TC Kimlik',
                          _formatTc(personnel.tcNo),
                        ),
                      _buildDetailRow(
                        Icons.payments_outlined,
                        'Maaş',
                        personnel.formattedSalary,
                      ),
                      _buildDetailRow(
                        Icons.location_on_outlined,
                        'Adres',
                        personnel.address ?? 'Belirtilmemiş',
                      ),
                      _buildDetailRow(
                        Icons.calendar_today_outlined,
                        'İşe Başlama',
                        personnel.startDate != null
                            ? '${personnel.startDate!.day.toString().padLeft(2, '0')}.${personnel.startDate!.month.toString().padLeft(2, '0')}.${personnel.startDate!.year}'
                            : 'Belirtilmemiş',
                      ),
                      _buildDetailRow(
                        Icons.account_box_outlined,
                        'Hesap No',
                        personnel.accountNo,
                      ),
                      _buildDetailRow(
                        Icons.account_balance_outlined,
                        'IBAN',
                        personnel.iban,
                      ),
                    ],
                  ),
                ),
              ),
              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showAddEditDialog(personnel);
                            },
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            label: const Text('Düzenle'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF5D4037),
                              side: const BorderSide(color: Color(0xFF5D4037)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _navigateToSalaryPayment(context, personnel);
                            },
                            icon: const Icon(Icons.payments_rounded, size: 18),
                            label: const Text('Maaş Ödeme'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5D4037),
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

  void _navigateToSalaryPayment(BuildContext context, Personnel personnel) {
    // Ana ekrana dön ve finans ekranını açmak için callback kullan
    // HomeScreen'e navigation yapılamaz çünkü iç içe widget'lar var
    // Bunun yerine, direkt FinanceScreen'i açalım ama bu daha karmaşık
    // En iyi çözüm: GlobalKey kullanmak veya Navigator.push ile açmak
    
    // Home screen'deki index'i değiştirmek için bir yöntem bulmamız lazım
    // Şimdilik sadece FinanceScreen'i açalım
    Navigator.of(context, rootNavigator: false).push(
      MaterialPageRoute(
        builder: (context) => FinanceScreen(
          initialTab: 0,
          initialTransactionType: 'Gider',
          initialCategory: 'Maaş',
          personnel: personnel,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF5D4037).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF5D4037)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
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

  @override
  Widget build(BuildContext context) {
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
                // Search
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
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                        _performSearch();
                      },
                      decoration: const InputDecoration(
                        hintText: 'Personel ara...',
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
                // Add Button
                ElevatedButton.icon(
                  onPressed: () => _showAddEditDialog(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Yeni Personel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D4037),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: const Color(0xFFFAF8F5),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Ad Soyad',
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
                  flex: 1,
                  child: Text(
                    'Maaş',
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
                    'Departman',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5D4037),
                    ),
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
                              ? 'Henüz personel eklenmemiş'
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
                    itemBuilder: (context, index) {
                      final personnel = _filteredList[index];
                      return _buildPersonnelRow(personnel);
                    },
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
                  'Toplam ${_filteredList.length} personel',
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

  Widget _buildPersonnelRow(Personnel personnel) {
    final departmentColor = _getDepartmentColor(personnel.departmentId);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDetailDialog(personnel),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Ad Soyad with Avatar
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    // Avatar with image support
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5D4037).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        image: _getImageProvider(personnel.imageUrl) != null
                            ? DecorationImage(
                                image: _getImageProvider(personnel.imageUrl)!,
                                fit: BoxFit.cover,
                                onError: (_, __) {},
                              )
                            : null,
                      ),
                      child:
                          personnel.imageUrl == null ||
                              personnel.imageUrl!.isEmpty
                          ? Center(
                              child: Text(
                                personnel.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF5D4037),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            personnel.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3E2723),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (personnel.isActive)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Aktif',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // İletişim (E-posta + Telefon)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            personnel.email,
                            style: const TextStyle(
                              color: Color(0xFF5D4037),
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: Color(0xFF8D6E63),
                        ),
                        const SizedBox(width: 4),
                        Text(
                      _formatPhone(personnel.phone),
                          style: const TextStyle(
                            color: Color(0xFF5D4037),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Maaş
              Expanded(
                flex: 1,
                child: Text(
                  personnel.formattedSalary,
                  style: const TextStyle(
                    color: Color(0xFF5D4037),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Adres
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Color(0xFF8D6E63),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        personnel.address ?? 'Belirtilmemiş',
                        style: TextStyle(
                          color: personnel.address != null
                              ? const Color(0xFF5D4037)
                              : Colors.grey,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Departman
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: departmentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    personnel.departmentName ?? '-',
                    style: TextStyle(
                      fontSize: 12,
                      color: departmentColor,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
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
                      onPressed: () => _showDetailDialog(personnel),
                      tooltip: 'Detay',
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      color: const Color(0xFF5D4037),
                      onPressed: () => _showAddEditDialog(personnel),
                      tooltip: 'Düzenle',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      color: Colors.red.shade400,
                      onPressed: () => _showDeleteDialog(personnel),
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
