import '../models/member.dart';
import '../database/database_helper.dart';

class MemberService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Ekle
  Future<int> insert(Member member) async {
    final db = await _dbHelper.database;
    return await db.insert('members', _toMap(member));
  }

  // Tümünü Getir
  Future<List<Member>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('members', orderBy: 'created_at DESC');
    return maps.map((map) => _fromMap(map)).toList();
  }

  // ID ile Getir
  Future<Member?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('members', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  // Üye No ile Getir
  Future<Member?> getByMemberNo(String memberNo) async {
    final db = await _dbHelper.database;
    final maps = await db.query('members', where: 'member_no = ?', whereArgs: [memberNo]);
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  // Güncelle
  Future<int> update(Member member) async {
    final db = await _dbHelper.database;
    return await db.update(
      'members',
      _toMap(member),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  // Sil
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('members', where: 'id = ?', whereArgs: [id]);
  }

  // Ara
  Future<List<Member>> search(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'members',
      where: 'name LIKE ? OR surname LIKE ? OR member_no LIKE ? OR email LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  // Ödünç kitap sayısını güncelle
  Future<void> updateBorrowedCount(int memberId, int count) async {
    final db = await _dbHelper.database;
    await db.update(
      'members',
      {'borrowed_books_count': count},
      where: 'id = ?',
      whereArgs: [memberId],
    );
  }

  Map<String, dynamic> _toMap(Member member) {
    return {
      'id': member.id,
      'member_no': member.memberNo,
      'name': member.name,
      'surname': member.surname,
      'tc_no': member.tcNo,
      'phone': member.phone,
      'email': member.email,
      'address': member.address,
      'birth_date': member.birthDate?.toIso8601String(),
      'gender': member.gender,
      'member_type': member.memberType,
      'registration_date': member.registrationDate.toIso8601String(),
      'expiry_date': member.expiryDate?.toIso8601String(),
      'is_active': member.isActive ? 1 : 0,
      'image_url': member.imageUrl,
      'notes': member.notes,
      'borrowed_books_count': member.borrowedBooksCount,
      'total_borrowed_books': member.totalBorrowedBooks,
    };
  }

  Member _fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'] as int?,
      memberNo: map['member_no'] as String,
      name: map['name'] as String,
      surname: map['surname'] as String,
      tcNo: map['tc_no'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      address: map['address'] as String?,
      birthDate: map['birth_date'] != null ? DateTime.parse(map['birth_date'] as String) : null,
      gender: map['gender'] as String?,
      memberType: map['member_type'] as String,
      registrationDate: DateTime.parse(map['registration_date'] as String),
      expiryDate: map['expiry_date'] != null ? DateTime.parse(map['expiry_date'] as String) : null,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      imageUrl: map['image_url'] as String?,
      notes: map['notes'] as String?,
      borrowedBooksCount: map['borrowed_books_count'] as int? ?? 0,
      totalBorrowedBooks: map['total_borrowed_books'] as int? ?? 0,
    );
  }
}

