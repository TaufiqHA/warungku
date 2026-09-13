import 'package:flutter/material.dart';
import '../../../data/models/auth_model.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_dialog.dart';
import '../../../widgets/app_text_field.dart';

class ProfilTab extends StatefulWidget {
  final VoidCallback? onLogout;

  const ProfilTab({
    super.key,
    this.onLogout,
  });

  @override
  State<ProfilTab> createState() => _ProfilTabState();
}

class _ProfilTabState extends State<ProfilTab> {
  final _authService = AuthService();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _warungFormKey = GlobalKey<FormState>();
  final _warungNameController = TextEditingController();
  final _warungAddressController = TextEditingController();
  final _warungEmailController = TextEditingController();

  UserModel? _user;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSavingWarung = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _warungNameController.dispose();
    _warungAddressController.dispose();
    _warungEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final profile = await _authService.getProfile();
    final warung = await _authService.getWarungSettings();

    if (mounted) {
      setState(() {
        _user = profile;
        _nameController.text = profile?.name ?? '';
        _warungNameController.text = warung['name'] ?? 'WARUNGKU';
        _warungAddressController.text = warung['address'] ?? 'Jl. Raya Utama No. 1';
        _warungEmailController.text = warung['email'] ?? 'info@warungku.com';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleUpdateProfile() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _authService.updateProfile(name: _nameController.text);
      await _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _handleUpdateWarungSettings() async {
    FocusScope.of(context).unfocus();
    if (!_warungFormKey.currentState!.validate()) return;

    setState(() => _isSavingWarung = true);
    try {
      await _authService.updateWarungSettings(
        name: _warungNameController.text,
        address: _warungAddressController.text,
        email: _warungEmailController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil warung berhasil disimpan'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingWarung = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await AppDialog.showConfirmation(
      context: context,
      title: 'Keluar Aplikasi',
      message: 'Apakah Anda yakin ingin keluar dari sesi ini?',
      confirmText: 'Keluar',
      isDestructive: true,
    );

    if (confirm == true) {
      await _authService.logout();
      if (widget.onLogout != null) {
        widget.onLogout!();
      } else if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwner = _user?.role.toUpperCase() == 'OWNER';

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Kartu Identitas Akun
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.person_rounded,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _user?.name.isNotEmpty == true ? _user!.name : 'Admin Toko',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _user?.email ?? '-',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              AppBadge.role(_user?.role.isNotEmpty == true ? _user!.role : 'ADMIN_TOKO'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Formulir Ubah Nama
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ubah Nama Akun',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Nama Lengkap',
                  controller: _nameController,
                  prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Simpan Nama',
                  isLoading: _isSaving,
                  height: 42,
                  onPressed: _handleUpdateProfile,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 3. Formulir Profil Warung (Khusus Role Owner)
        if (isOwner) ...[
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _warungFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.store_mall_directory_rounded, color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Profil Warung',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Nama Warung',
                    controller: _warungNameController,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Nama warung wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Alamat Warung',
                    controller: _warungAddressController,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Alamat wajib diisi';
                      if (v.trim().length > 100) return 'Maksimal 100 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Email Kontak',
                    controller: _warungEmailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Email kontak wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Reset',
                          isPrimary: false,
                          height: 42,
                          onPressed: _loadProfile,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppButton(
                          text: 'Simpan Profil',
                          isLoading: _isSavingWarung,
                          height: 42,
                          onPressed: _handleUpdateWarungSettings,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 4. Tombol Logout
        AppCard(
          padding: EdgeInsets.zero,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _handleLogout,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.logout_rounded, color: theme.colorScheme.error, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Keluar',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
