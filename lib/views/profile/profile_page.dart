import 'dart:io';
import 'package:flutter/material.dart';
import 'package:projektpm/views/profile/feedback_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database/database_helper.dart';
import 'edit_profile_page.dart';
import 'applied_jobs_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _floatController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;

  String? _currentUsername;
  bool _isLoading = true;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Map<String, dynamic> _userProfile = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();

    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('logged_username');

    if (username != null) {
      final userData = await _dbHelper.getUserByUsername(username);
      if (mounted) {
        setState(() {
          _currentUsername = username;
          _userProfile = userData ?? {};
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        title: const Text('Konfirmasi Logout',
            style: TextStyle(color: Colors.white)),
        content: const Text('Apakah Anda yakin ingin keluar?',
            style: TextStyle(color: Colors.white70)),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('logged_username');
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
            child:
                const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  // Widget avatar — tampilkan foto jika ada, fallback ke gradient icon
  Widget _buildAvatar() {
    final profileImagePath = _userProfile['profile_image'];
    final hasImage = profileImagePath != null &&
        profileImagePath.toString().isNotEmpty &&
        File(profileImagePath.toString()).existsSync();

    final avatarChild = hasImage
        ? ClipOval(
            child: Image.file(
              File(profileImagePath.toString()),
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _defaultAvatarChild(),
            ),
          )
        : _defaultAvatarChild();

    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _floatAnimation.value),
        child: child,
      ),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (_, child) => Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        ),
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: hasImage
                ? null
                : const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: avatarChild,
        ),
      ),
    );
  }

  Widget _defaultAvatarChild() {
    return const Icon(
      Icons.person_outline_rounded,
      size: 48,
      color: Colors.white,
    );
  }

  // Chip kecil untuk gender, education, skills
  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName = _userProfile['full_name']?.toString() ?? '';
    final email = _userProfile['email']?.toString() ?? '';
    final gender = _userProfile['gender']?.toString() ?? '';
    final education = _userProfile['education']?.toString() ?? '';
    final skillsStr = _userProfile['skills']?.toString() ?? '';
    final bio = _userProfile['bio']?.toString() ?? '';
    final cvPath = _userProfile['cv_path']?.toString() ?? '';

    final skills = skillsStr.isNotEmpty ? skillsStr.split(',') : <String>[];
    final hasCV = cvPath.isNotEmpty && File(cvPath).existsSync();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  // Avatar
                  _buildAvatar(),
                  const SizedBox(height: 20),

                  // Username
                  Text(
                    _currentUsername ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  // Full Name
                  if (fullName.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      fullName,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14),
                    ),
                  ],

                  // Email
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 13),
                    ),
                  ],

                  // Gender & Education chips
                  if (gender.isNotEmpty || education.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        if (gender.isNotEmpty)
                          _buildInfoChip(gender, const Color(0xFF6C63FF)),
                        if (education.isNotEmpty)
                          _buildInfoChip(
                              education, const Color(0xFF00D4AA)),
                      ],
                    ),
                  ],

                  // Bio
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        bio,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],

                  // Skills
                  if (skills.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: skills
                            .map((s) => _buildInfoChip(
                                s.trim(), Colors.orange))
                            .toList(),
                      ),
                    ),
                  ],

                  // CV badge
                  if (hasCV) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.green.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.picture_as_pdf,
                              color: Colors.green, size: 14),
                          SizedBox(width: 6),
                          Text('CV Tersedia',
                              style: TextStyle(
                                  color: Colors.green, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Menu Items
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A24),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        // Edit Profile
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.person_outline,
                                color: Color(0xFF6C63FF), size: 22),
                          ),
                          title: const Text('Edit Profile',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16)),
                          subtitle: Text(
                            'Ubah nama, email, dan password',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right,
                              color: Colors.white54),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const EditProfilePage()),
                            ).then((_) => _loadUserData());
                          },
                        ),

                        const Divider(height: 1, color: Colors.white12),

                        // Riwayat Lamaran
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF00D4AA).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.history,
                                color: Color(0xFF00D4AA), size: 22),
                          ),
                          title: const Text('Riwayat Lamaran',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16)),
                          subtitle: Text(
                            'Lihat pekerjaan yang sudah dilamar',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right,
                              color: Colors.white54),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AppliedJobsPage()),
                          ),
                        ),

                        const Divider(height: 1, color: Colors.white12),

                        // Feedback
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF00D4AA).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.feedback_outlined,
                                color: Color(0xFF00D4AA), size: 22),
                          ),
                          title: const Text('Feedback TPM',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16)),
                          subtitle: Text(
                            'Beri masukan untuk mata kuliah TPM',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right,
                              color: Colors.white54),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const FeedbackPage()),
                          ),
                        ),

                        const Divider(height: 1, color: Colors.white12),

                        // Logout
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.logout,
                                color: Colors.red, size: 22),
                          ),
                          title: const Text('Logout',
                              style: TextStyle(
                                  color: Colors.red, fontSize: 16)),
                          subtitle: Text(
                            'Keluar dari aplikasi',
                            style: TextStyle(
                                color: Colors.red.withOpacity(0.5),
                                fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right,
                              color: Colors.red),
                          onTap: _showLogoutDialog,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}