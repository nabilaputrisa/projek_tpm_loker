import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import '../../data/database/database_helper.dart';
import 'package:open_filex/open_filex.dart';

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

  String? _username;
  bool _isLoading = true;
  Map<String, dynamic> _userProfile = {};

  String? _selectedGender;
  String? _selectedEducation;
  List<String> _selectedSkills = [];
  File? _cvFile;
  String? _existingCvPath;

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

            // Set text controllers dengan nilai yang ada atau kosong
            _nameController.text = _userProfile['full_name'] ?? '';
            _emailController.text = _userProfile['email'] ?? '';
            _bioController.text = _userProfile['bio'] ?? '';

            // PERBAIKAN: Set dropdown values dengan null safety
            final gender = _userProfile['gender'];
            _selectedGender = (gender != null && gender.isNotEmpty)
                ? gender
                : null;

            final education = _userProfile['education'];
            _selectedEducation = (education != null && education.isNotEmpty)
                ? education
                : null;

            // Set skills
            final skillsStr = _userProfile['skills'];
            if (skillsStr != null && skillsStr.isNotEmpty) {
              _selectedSkills = skillsStr.split(',');
            } else {
              _selectedSkills = [];
            }

            // Set CV
            _existingCvPath = _userProfile['cv_path'];
            if (_existingCvPath != null && _existingCvPath!.isNotEmpty) {
              final file = File(_existingCvPath!);
              if (file.existsSync()) {
                _cvFile = file;
              } else {
                _existingCvPath = null;
                _cvFile = null;
              }
            } else {
              _existingCvPath = null;
              _cvFile = null;
            }

            _isLoading = false;
          });
        }
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Error loading data', backgroundColor: Colors.red);
      }
    }
  }

  Future<void> _pickCV() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && mounted) {
        setState(() {
          _cvFile = File(result.files.single.path!);
        });
        _showSnackBar('CV berhasil dipilih', backgroundColor: Colors.green);
      }
    } catch (e) {
      _showSnackBar('Gagal memilih file PDF', backgroundColor: Colors.red);
    }
  }

  Future<void> _openCV() async {
    String? filePath;

    if (_cvFile != null && await _cvFile!.exists()) {
      filePath = _cvFile!.path;
    } else if (_existingCvPath != null && _existingCvPath!.isNotEmpty) {
      filePath = _existingCvPath;
    }

    if (filePath == null) {
      _showSnackBar(
        'Belum ada CV yang diupload',
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        _showSnackBar(
          'Gagal membuka file: ${result.message}',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar(
        'Tidak dapat membuka file CV: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _deleteCV() async {
    if (!mounted) return;

    final bool? confirmDelete = await showDialog<bool>(
      context: context as BuildContext,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A24),
          title: const Text('Hapus CV', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Apakah Anda yakin ingin menghapus file CV ini?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmDelete != true) return;

    setState(() => _isLoading = true);

    try {
      // Hapus file fisik
      final pathToDelete = _cvFile?.path ?? _existingCvPath;
      if (pathToDelete != null && pathToDelete.isNotEmpty) {
        final file = File(pathToDelete);
        if (await file.exists()) {
          await file.delete();
          print('✅ File CV deleted: $pathToDelete');
        }
      }

      // Update database
      if (_username != null) {
        await _dbHelper.updateUserProfileFull(
          _username!,
          cvPath: null, // Set ke null
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          gender: _selectedGender,
          education: _selectedEducation,
          skills: _selectedSkills,
          bio: _bioController.text.trim(),
          newPassword: _passwordController.text.isNotEmpty
              ? _passwordController.text
              : null,
        );
        print('✅ Database updated');
      }

      // Reset state
      setState(() {
        _cvFile = null;
        _existingCvPath = null;
      });

      _showSnackBar('✓ CV berhasil dihapus', backgroundColor: Colors.green);
      await _loadUserData();
    } catch (e) {
      print('Error deleting CV: $e');
      _showSnackBar('Gagal menghapus CV: $e', backgroundColor: Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
      print('File saved to: $path');
      return path;
    } catch (e) {
      print('Error saving file: $e');
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
      String? savedCvPath = _existingCvPath;

      if (_cvFile != null && _existingCvPath != _cvFile?.path) {
        savedCvPath = await _saveFileToLocal(_cvFile!, 'cv');
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
        newPassword: _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
      );

      if (mounted) {
        _showSnackBar(
          '✓ Profil berhasil diperbarui',
          backgroundColor: Colors.green,
        );
        await _loadUserData();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal menyimpan: $e', backgroundColor: Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  @override
  Widget build(BuildContext context) {
    final hasCV =
        _cvFile != null ||
        (_existingCvPath != null && _existingCvPath!.isNotEmpty);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white70,
          ),
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
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Avatar
                  GestureDetector(
                    onTap: () {
                      _showSnackBar(
                        'Fitur foto profil segera hadir',
                        backgroundColor: Colors.orange,
                      );
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap untuk ganti foto',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 24),

                  // Nama Lengkap
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Nama Lengkap', Icons.person),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration('Email', Icons.email),
                  ),
                  const SizedBox(height: 16),

                  // PERBAIKAN: Dropdown Gender dengan HINT
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    hint: const Text(
                      'Pilih Jenis Kelamin',
                      style: TextStyle(color: Colors.white54),
                    ),
                    dropdownColor: const Color(0xFF1A1A24),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      'Jenis Kelamin',
                      Icons.person_outline,
                    ),
                    items: _genderOptions.map((gender) {
                      return DropdownMenuItem(
                        value: gender,
                        child: Text(gender),
                      );
                    }).toList(),
                    onChanged: (value) => mounted
                        ? setState(() => _selectedGender = value)
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // PERBAIKAN: Dropdown Education dengan HINT
                  DropdownButtonFormField<String>(
                    value: _selectedEducation,
                    hint: const Text(
                      'Pilih Pendidikan Terakhir',
                      style: TextStyle(color: Colors.white54),
                    ),
                    dropdownColor: const Color(0xFF1A1A24),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      'Pendidikan Terakhir',
                      Icons.school,
                    ),
                    items: _educationOptions.map((edu) {
                      return DropdownMenuItem(value: edu, child: Text(edu));
                    }).toList(),
                    onChanged: (value) => mounted
                        ? setState(() => _selectedEducation = value)
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Skill Chips
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.code,
                              color: Color(0xFF6C63FF),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Skill / Keahlian',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _allSkills.map((skill) {
                            final isSelected = _selectedSkills.contains(skill);
                            return FilterChip(
                              label: Text(
                                skill,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white70,
                                ),
                              ),
                              backgroundColor: const Color(0xFF2A2A3A),
                              selectedColor: const Color(0xFF6C63FF),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (mounted) {
                                  setState(() {
                                    if (selected) {
                                      _selectedSkills.add(skill);
                                    } else {
                                      _selectedSkills.remove(skill);
                                    }
                                  });
                                }
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
                      color: const Color(0xFF1A1A24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.picture_as_pdf,
                              color: Color(0xFF6C63FF),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Curriculum Vitae (CV)',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
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
                                backgroundColor: const Color(
                                  0xFF6C63FF,
                                ).withOpacity(0.2),
                                foregroundColor: const Color(0xFF6C63FF),
                              ),
                            ),
                            if (hasCV) ...[
                              ElevatedButton.icon(
                                onPressed: _openCV,
                                icon: const Icon(Icons.visibility, size: 18),
                                label: const Text('Lihat'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(
                                    0xFF00D4AA,
                                  ).withOpacity(0.2),
                                  foregroundColor: const Color(0xFF00D4AA),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _deleteCV,
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                ),
                                label: const Text('Hapus'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.withOpacity(0.2),
                                  foregroundColor: Colors.red,
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
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
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
                    style: const TextStyle(color: Colors.white),
                    maxLines: 4,
                    decoration: _inputDecoration(
                      'Tentang Saya',
                      Icons.description,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password Baru
                  TextField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.white),
                    obscureText: true,
                    decoration: _inputDecoration(
                      'Password Baru (opsional)',
                      Icons.lock,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tombol Simpan
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
      filled: true,
      fillColor: const Color(0xFF1A1A24),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6C63FF)),
      ),
    );
  }
}
