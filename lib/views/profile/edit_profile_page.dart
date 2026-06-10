import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import '../../data/database/database_helper.dart';
import 'package:open_filex/open_filex.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String? _username;
  bool _isLoading = true;
  Map<String, dynamic> _userProfile = {};

  String? _selectedGender;
  String? _selectedEducation;
  List<String> _selectedSkills = [];
  File? _cvFile;
  String? _existingCvPath;
  bool _cvDeleted = false;

  File? _profileImageFile;
  String? _existingProfileImagePath;

  final List<String> _genderOptions = ['Laki-laki', 'Perempuan'];
  final List<String> _educationOptions = ['SMA/SMK', 'D3', 'S1', 'S2', 'S3'];
  final List<String> _allSkills = [
    'IT Jobs',
    'Engineering Jobs',
    'Sales Jobs',
    'Customer Services',
    'Healthcare & Nursing',
    'Teaching Jobs',
    'Accounting & Finance',
    'Legal Jobs',
    'Marketing Jobs',
    'HR Jobs',
    'Admin Jobs',
  ];

  // Warna tema 
  static const Color _primary    = Color(0xFF5C7EA8);
  static const Color _accent     = Color(0xFF7FA3C8);
  static const Color _cardBg     = Color(0xFFFFFFFF);
  static const Color _scaffoldBg = Color(0xFFEEF1F5);
  static const Color _textPrimary   = Color(0xFF1A2B3C);
  static const Color _textSecondary = Color(0xFF6B7C8D);


  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context as BuildContext).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _username = prefs.getString('logged_username');

      if (_username != null) {
        final userData = await _dbHelper.getUserByUsername(_username!);
        if (mounted) {
          setState(() {
            _userProfile = userData ?? {};

            _nameController.text = _userProfile['full_name'] ?? '';
            _emailController.text = _userProfile['email'] ?? '';
            _bioController.text = _userProfile['bio'] ?? '';

            final gender = _userProfile['gender'];
            _selectedGender =
                (gender != null && gender.toString().isNotEmpty) ? gender : null;

            final education = _userProfile['education'];
            _selectedEducation =
                (education != null && education.toString().isNotEmpty)
                    ? education
                    : null;

            final skillsStr = _userProfile['skills'];
            _selectedSkills =
                (skillsStr != null && skillsStr.toString().isNotEmpty)
                    ? skillsStr.toString().split(',')
                    : [];

            final cvPath = _userProfile['cv_path'];
            if (cvPath != null && cvPath.toString().isNotEmpty) {
              final file = File(cvPath.toString());
              if (file.existsSync()) {
                _existingCvPath = cvPath.toString();
                _cvFile = file;
              } else {
                _existingCvPath = null;
                _cvFile = null;
              }
            } else {
              _existingCvPath = null;
              _cvFile = null;
            }

            final profileImage = _userProfile['profile_image'];
            if (profileImage != null && profileImage.toString().isNotEmpty) {
              final file = File(profileImage.toString());
              if (file.existsSync()) {
                _existingProfileImagePath = profileImage.toString();
                _profileImageFile = file;
              } else {
                _existingProfileImagePath = null;
                _profileImageFile = null;
              }
            } else {
              _existingProfileImagePath = null;
              _profileImageFile = null;
            }

            _cvDeleted = false;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Error loading data', backgroundColor: Colors.red);
      }
    }
  }

  Future<void> _pickProfileImage() async {
    if (!mounted) return;

    final BuildContext currentContext = this.context;
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: currentContext,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Pilih Foto Profil',
              style: TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: _primary),
              title: Text('Kamera', style: TextStyle(color: _textPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: _primary),
              title: Text('Galeri', style: TextStyle(color: _textPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (picked != null && mounted) {
        setState(() {
          _profileImageFile = File(picked.path);
          _existingProfileImagePath = null;
        });
        _showSnackBar('Foto berhasil dipilih', backgroundColor: Colors.green);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showSnackBar('Gagal memilih foto: $e', backgroundColor: Colors.red);
    }
  }

  Future<String?> _saveProfileImageToLocal(File file) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'profile_${_username}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = join(directory.path, fileName);
      await file.copy(path);
      return path;
    } catch (e) {
      debugPrint('Error saving profile image: $e');
      return null;
    }
  }

  Future<void> _pickCV() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null && mounted) {
        setState(() {
          _cvFile = File(result.files.single.path!);
          _existingCvPath = null;
          _cvDeleted = false;
        });
        _showSnackBar('CV berhasil dipilih', backgroundColor: Colors.green);
      }
    } catch (e) {
      _showSnackBar('Gagal memilih file PDF', backgroundColor: Colors.red);
    }
  }

  Future<void> _openCV() async {
    final filePath = _cvFile?.path ?? _existingCvPath;

    if (filePath == null || filePath.isEmpty) {
      _showSnackBar('Belum ada CV yang diupload', backgroundColor: Colors.orange);
      return;
    }

    final file = File(filePath);
    if (!await file.exists()) {
      _showSnackBar('File CV tidak ditemukan', backgroundColor: Colors.orange);
      return;
    }

    try {
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        _showSnackBar('Gagal membuka file: ${result.message}',
            backgroundColor: Colors.red);
      }
    } catch (e) {
      _showSnackBar('Tidak dapat membuka file CV: $e', backgroundColor: Colors.red);
    }
  }

  Future<void> _deleteCV() async {
    if (!mounted) return;

    final bool? confirmDelete = await showDialog<bool>(
      context: this.context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: _cardBg,
          title: Text('Hapus CV', style: TextStyle(color: _textPrimary)),
          content: Text(
            'Apakah Anda yakin ingin menghapus file CV ini?',
            style: TextStyle(color: _textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('Batal', style: TextStyle(color: _textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmDelete != true || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final pathToDelete = _cvFile?.path ?? _existingCvPath;
      if (pathToDelete != null && pathToDelete.isNotEmpty) {
        final file = File(pathToDelete);
        if (await file.exists()) await file.delete();
      }

      if (_username != null) {
        await _dbHelper.updateUserProfileFull(
          _username!,
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          gender: _selectedGender,
          education: _selectedEducation,
          skills: _selectedSkills,
          cvPath: null,
          bio: _bioController.text.trim(),
          newPassword: _passwordController.text.isNotEmpty
              ? _passwordController.text
              : null,
        );
      }

      if (mounted) {
        setState(() {
          _cvFile = null;
          _existingCvPath = null;
          _cvDeleted = true;
          _isLoading = false;
        });
        _showSnackBar('CV berhasil dihapus', backgroundColor: Colors.green);
      }
    } catch (e) {
      debugPrint('Error deleting CV: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Gagal menghapus CV: $e', backgroundColor: Colors.red);
      }
    }
  }

  Future<String?> _saveFileToLocal(File file, String type) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${type}_${_username}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final path = join(directory.path, fileName);
      await file.copy(path);
      return path;
    } catch (e) {
      debugPrint('Error saving file: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Nama lengkap tidak boleh kosong');
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      _showSnackBar('Email tidak boleh kosong');
      return;
    }
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      String? savedProfileImagePath = _existingProfileImagePath;
      if (_profileImageFile != null &&
          _profileImageFile!.path != _existingProfileImagePath &&
          await _profileImageFile!.exists()) {
        savedProfileImagePath =
            await _saveProfileImageToLocal(_profileImageFile!);
      }

      String? savedCvPath;
      if (_cvDeleted) {
        savedCvPath = null;
      } else if (_cvFile != null &&
          _cvFile!.path != _existingCvPath &&
          await _cvFile!.exists()) {
        savedCvPath = await _saveFileToLocal(_cvFile!, 'cv');
      } else {
        savedCvPath = _existingCvPath;
      }

      await _dbHelper.updateUserProfileFull(
        _username!,
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        gender: _selectedGender,
        education: _selectedEducation,
        skills: _selectedSkills,
        cvPath: savedCvPath,
        bio: _bioController.text.trim(),
        profileImagePath: savedProfileImagePath,
        newPassword: _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
      );

      if (mounted) {
        _showSnackBar('Profil berhasil diperbarui', backgroundColor: Colors.green);
        await _loadUserData();
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        _showSnackBar('Gagal menyimpan: $e', backgroundColor: Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Widget _buildAvatar() {
    final hasImage =
        _profileImageFile != null || _existingProfileImagePath != null;
    final imageFile = _profileImageFile ??
        (_existingProfileImagePath != null
            ? File(_existingProfileImagePath!)
            : null);

    return GestureDetector(
      onTap: _pickProfileImage,
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: ClipOval(
              child: hasImage && imageFile != null
                  ? Image.file(
                      imageFile,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _defaultAvatar(),
                    )
                  : _defaultAvatar(),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _primary,
                shape: BoxShape.circle,
                border: Border.all(color: _scaffoldBg, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      width: 100,
      height: 100,
      color: _primary,
      child: const Icon(Icons.person_outline_rounded,
          size: 50, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasCV = !_cvDeleted &&
        (_cvFile != null ||
            (_existingCvPath != null && _existingCvPath!.isNotEmpty));

    return Scaffold(
      backgroundColor: _scaffoldBg,
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildAvatar(),
                  const SizedBox(height: 8),
                  Text('Tap untuk ganti foto',
                      style: TextStyle(color: _textSecondary, fontSize: 12)),
                  const SizedBox(height: 24),

                  // Nama Lengkap
                  TextField(
                    controller: _nameController,
                    style: TextStyle(color: _textPrimary),
                    decoration: _inputDecoration('Nama Lengkap', Icons.person),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextField(
                    controller: _emailController,
                    style: TextStyle(color: _textPrimary),
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration('Email', Icons.email),
                  ),
                  const SizedBox(height: 16),

                  // Dropdown Gender
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    hint: Text('Pilih Jenis Kelamin',
                        style: TextStyle(color: _textSecondary)),
                    dropdownColor: Colors.white,
                    style: TextStyle(color: _textPrimary),
                    decoration:
                        _inputDecoration('Jenis Kelamin', Icons.person_outline),
                    items: _genderOptions
                        .map((g) =>
                            DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (value) {
                      if (mounted) setState(() => _selectedGender = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Dropdown Education
                  DropdownButtonFormField<String>(
                    value: _selectedEducation,
                    hint: Text('Pilih Pendidikan Terakhir',
                        style: TextStyle(color: _textSecondary)),
                    dropdownColor: Colors.white,
                    style: TextStyle(color: _textPrimary),
                    decoration:
                        _inputDecoration('Pendidikan Terakhir', Icons.school),
                    items: _educationOptions
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      if (mounted) setState(() => _selectedEducation = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Skill Chips
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.code, color: _primary, size: 20),
                            const SizedBox(width: 8),
                            Text('Skill / Keahlian',
                                style: TextStyle(
                                    color: _textPrimary,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _allSkills.map((skill) {
                            final isSelected = _selectedSkills.contains(skill);
                            return FilterChip(
                              label: Text(skill,
                                  style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : _textSecondary)),
                              backgroundColor: const Color(0xFFF0F4F8),
                              selectedColor: _primary,
                              selected: isSelected,
                              onSelected: (selected) {
                                if (!mounted) return;
                                setState(() {
                                  if (selected) {
                                    _selectedSkills.add(skill);
                                  } else {
                                    _selectedSkills.remove(skill);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CV Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.picture_as_pdf,
                                color: _primary, size: 20),
                            const SizedBox(width: 8),
                            Text('Curriculum Vitae (CV)',
                                style: TextStyle(
                                    color: _textPrimary,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickCV,
                              icon: const Icon(Icons.upload_file, size: 18),
                              label: const Text('Pilih File PDF'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary.withOpacity(0.1),
                                foregroundColor: _primary,
                                elevation: 0,
                              ),
                            ),
                            if (hasCV) ...[
                              ElevatedButton.icon(
                                onPressed: _openCV,
                                icon: const Icon(Icons.visibility, size: 18),
                                label: const Text('Lihat'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _accent.withOpacity(0.1),
                                  foregroundColor: _accent,
                                  elevation: 0,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _deleteCV,
                                icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18),
                                label: const Text('Hapus'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.withOpacity(0.1),
                                  foregroundColor: Colors.red,
                                  elevation: 0,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (hasCV)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              'CV terupload: ${_cvFile != null ? _cvFile!.path.split('/').last : (_existingCvPath?.split('/').last ?? 'CV.pdf')}',
                              style: TextStyle(
                                  color: _textSecondary, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bio
                  TextField(
                    controller: _bioController,
                    style: TextStyle(color: _textPrimary),
                    maxLines: 4,
                    decoration:
                        _inputDecoration('Tentang Saya', Icons.description),
                  ),
                  const SizedBox(height: 16),

                  // Password Baru
                  TextField(
                    controller: _passwordController,
                    style: TextStyle(color: _textPrimary),
                    obscureText: true,
                    decoration: _inputDecoration(
                        'Password Baru (opsional)', Icons.lock),
                  ),
                  const SizedBox(height: 32),

                  // Tombol Simpan
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _textSecondary),
      prefixIcon: Icon(icon, color: _primary),
      filled: true,
      fillColor: _cardBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
      ),
    );
  }
}