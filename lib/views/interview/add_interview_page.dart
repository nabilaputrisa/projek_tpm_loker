import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/interview_model.dart';
import '../../providers/interview_provider.dart';

class AddInterviewPage extends StatefulWidget {
  final InterviewModel? interview;

  const AddInterviewPage({super.key, this.interview});

  @override
  State<AddInterviewPage> createState() => _AddInterviewPageState();
}

class _AddInterviewPageState extends State<AddInterviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _jobTitleController = TextEditingController();
  final _companyController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  static const Color _primaryBlue = Color(0xFF2F80ED);
  static const Color _bgColor = Color(0xFFEAF2FB);
  static const Color _darkText = Color(0xFF1A2E44);
  static const Color _subtleText = Color(0xFF7A92A8);

  bool get _isEditing => widget.interview != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final iv = widget.interview!;
      _jobTitleController.text = iv.jobTitle;
      _companyController.text = iv.companyName;
      _notesController.text = iv.notes ?? '';
      _selectedDate = iv.interviewDateTime;
      _selectedTime = TimeOfDay.fromDateTime(iv.interviewDateTime);
    }
  }

  @override
  void dispose() {
    _jobTitleController.dispose();
    _companyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _isEditing ? 'Edit Jadwal' : 'Tambah Jadwal',
          style: const TextStyle(
            color: _darkText,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: _darkText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderIllustration(),
              const SizedBox(height: 24),
              _buildSectionLabel('Informasi Posisi'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _jobTitleController,
                hint: 'Posisi yang dilamar',
                icon: Icons.work_outline,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _companyController,
                hint: 'Nama perusahaan',
                icon: Icons.business_outlined,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              _buildSectionLabel('Waktu Interview'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildPickerTile(
                      icon: Icons.calendar_today_outlined,
                      label: _selectedDate != null
                          ? DateFormat('d MMM yyyy', 'id_ID')
                              .format(_selectedDate!)
                          : 'Pilih Tanggal',
                      onTap: _pickDate,
                      filled: _selectedDate != null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPickerTile(
                      icon: Icons.access_time,
                      label: _selectedTime != null
                          ? _selectedTime!.format(context)
                          : 'Pilih Waktu',
                      onTap: _pickTime,
                      filled: _selectedTime != null,
                    ),
                  ),
                ],
              ),
              if (_selectedDate == null || _selectedTime == null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    _isLoading ? 'Tanggal & waktu wajib dipilih' : '',
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 24),
              _buildSectionLabel('Catatan (Opsional)'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _notesController,
                hint: 'Tambahkan catatan, lokasi, atau persiapan...',
                icon: Icons.notes_outlined,
                maxLines: 4,
              ),
              const SizedBox(height: 36),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIllustration() {
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: _primaryBlue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _primaryBlue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.event_note, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: _darkText,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      style: const TextStyle(color: _darkText, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _subtleText, fontSize: 14),
        prefixIcon: maxLines == 1
            ? Icon(icon, color: _primaryBlue, size: 20)
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: maxLines > 1 ? 16 : 0,
          vertical: maxLines > 1 ? 14 : 0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPickerTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool filled,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: filled ? _primaryBlue.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: filled
              ? Border.all(color: _primaryBlue.withOpacity(0.4), width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Icon(icon,
                color: filled ? _primaryBlue : _subtleText, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: filled ? _primaryBlue : _subtleText,
                  fontSize: 13,
                  fontWeight:
                      filled ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          disabledBackgroundColor: _primaryBlue.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                _isEditing ? 'SIMPAN PERUBAHAN' : 'TAMBAH JADWAL',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.8,
                ),
              ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _primaryBlue,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _primaryBlue,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submit() async {
    final isFormValid = _formKey.currentState!.validate();
    final isDateTimeValid =
        _selectedDate != null && _selectedTime != null;

    if (!isFormValid || !isDateTimeValid) {
      setState(() => _isLoading = true);
      await Future.delayed(Duration.zero);
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    final interviewDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final provider = context.read<InterviewProvider>();
    bool success;

    if (_isEditing) {
      success = await provider.updateInterview(
        id: widget.interview!.id!,
        jobTitle: _jobTitleController.text.trim(),
        companyName: _companyController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        interviewDateTime: interviewDateTime,
      );
    } else {
      success = await provider.addInterview(
        jobTitle: _jobTitleController.text.trim(),
        companyName: _companyController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        interviewDateTime: interviewDateTime,
      );
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Jadwal berhasil diperbarui'
                : 'Jadwal berhasil ditambahkan',
          ),
          backgroundColor: _primaryBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Terjadi kesalahan'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      provider.clearError();
    }
  }
}