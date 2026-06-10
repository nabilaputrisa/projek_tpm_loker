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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerHighest,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _isEditing ? 'Edit Jadwal' : 'Tambah Jadwal',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme: IconThemeData(color: cs.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderIllustration(cs),
              const SizedBox(height: 24),
              _buildSectionLabel(cs, 'Informasi Posisi'),
              const SizedBox(height: 12),
              _buildTextField(
                cs,
                controller: _jobTitleController,
                hint: 'Posisi yang dilamar',
                icon: Icons.work_outline,
                validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                cs,
                controller: _companyController,
                hint: 'Nama perusahaan',
                icon: Icons.business_outlined,
                validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              _buildSectionLabel(cs, 'Waktu Interview'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildPickerTile(
                      cs,
                      icon: Icons.calendar_today_outlined,
                      label: _selectedDate != null
                          ? DateFormat('d MMM yyyy', 'id_ID').format(_selectedDate!)
                          : 'Pilih Tanggal',
                      onTap: _pickDate,
                      filled: _selectedDate != null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPickerTile(
                      cs,
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
                    style: TextStyle(color: cs.error, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 24),
              _buildSectionLabel(cs, 'Catatan (Opsional)'),
              const SizedBox(height: 12),
              _buildTextField(
                cs,
                controller: _notesController,
                hint: 'Tambahkan catatan, lokasi, atau persiapan...',
                icon: Icons.notes_outlined,
                maxLines: 4,
              ),
              const SizedBox(height: 36),
              _buildSubmitButton(cs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIllustration(ColorScheme cs) {
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: cs.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: cs.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(Icons.event_note, color: cs.onPrimary, size: 32),
      ),
    );
  }

  Widget _buildSectionLabel(ColorScheme cs, String label) {
    return Text(
      label,
      style: TextStyle(
        color: cs.onSurface,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    );
  }

  Widget _buildTextField(
    ColorScheme cs, {
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
      style: TextStyle(color: cs.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
        prefixIcon: maxLines == 1 ? Icon(icon, color: cs.primary, size: 20) : null,
        filled: true,
        fillColor: cs.surface,
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
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.error, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPickerTile(
    ColorScheme cs, {
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
          color: filled ? cs.primary.withOpacity(0.08) : cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: filled ? Border.all(color: cs.primary.withOpacity(0.4), width: 1.5) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: filled ? cs.primary : cs.onSurfaceVariant, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: filled ? cs.primary : cs.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: filled ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ColorScheme cs) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          disabledBackgroundColor: cs.primary.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: cs.onPrimary, strokeWidth: 2.5),
              )
            : Text(
                _isEditing ? 'SIMPAN PERUBAHAN' : 'TAMBAH JADWAL',
                style: TextStyle(
                  color: cs.onPrimary,
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
    final cs = Theme.of(context).colorScheme;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: cs.primary,
            onPrimary: cs.onPrimary,
            surface: cs.surface,
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
    final cs = Theme.of(context).colorScheme;
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: cs.primary,
            onPrimary: cs.onPrimary,
            surface: cs.surface,
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
    final isDateTimeValid = _selectedDate != null && _selectedTime != null;
    final cs = Theme.of(context).colorScheme;

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
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        interviewDateTime: interviewDateTime,
      );
    } else {
      success = await provider.addInterview(
        jobTitle: _jobTitleController.text.trim(),
        companyName: _companyController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        interviewDateTime: interviewDateTime,
      );
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Jadwal berhasil diperbarui' : 'Jadwal berhasil ditambahkan'),
          backgroundColor: cs.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Terjadi kesalahan'),
          backgroundColor: cs.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      provider.clearError();
    }
  }
}