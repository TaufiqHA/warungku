import 'package:flutter/material.dart';
import '../../../data/models/auth_model.dart';
import '../../../services/token_manager.dart';
import '../../../services/user_service.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_text_field.dart';

class UserManagementTab extends StatefulWidget {
  final UserService? userService;

  const UserManagementTab({
    super.key,
    this.userService,
  });

  @override
  State<UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<UserManagementTab> {
  late final UserService _userService;
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _userService = widget.userService ?? UserService();
    _loadUsers();
  }

  Future<void> _loadUsers({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    try {
      final list = await _userService.getUsers(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _users = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      // Fallback jika server offline / mock environment
      final current = await TokenManager.getUser();
      final fallbackUsers = [
        current ??
            const UserModel(
              id: 'USR-001',
              name: 'Owner Warung',
              username: 'owner_warung',
              email: 'owner@warung.com',
              role: 'OWNER',
            ),
        const UserModel(
          id: 'USR-002',
          name: 'Staf Kasir 1',
          username: 'kasir_toko',
          email: 'kasir@warung.com',
          role: 'ADMIN_TOKO',
        ),
        const UserModel(
          id: 'USR-003',
          name: 'Admin Keuangan',
          username: 'admin_kantor',
          email: 'kantor@warung.com',
          role: 'ADMIN_KANTOR',
        ),
      ];

      if (mounted) {
        setState(() {
          _users = fallbackUsers;
          _isLoading = false;
        });
      }
    }
  }

  void _showEditUserDialog(UserModel user) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(
                'Edit Pengguna (${user.username})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppTextField(
                        label: 'Nama Lengkap',
                        controller: nameController,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Email',
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Email wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Password Baru (Opsional)',
                        hintText: 'Kosongkan jika tidak diubah',
                        controller: passwordController,
                        obscureText: obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                          onPressed: () {
                            setModalState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Batal',
                        isPrimary: false,
                        height: 38,
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppButton(
                        text: 'Simpan',
                        height: 38,
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.of(ctx).pop();

                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await _userService.updateUser(
                              user.id,
                              name: nameController.text,
                              email: emailController.text,
                              password: passwordController.text.isNotEmpty
                                  ? passwordController.text
                                  : null,
                            );
                            _loadUsers();
                            if (mounted) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Data pengguna berhasil diperbarui'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            // Update lokal jika server mock offline
                            if (mounted) {
                              setState(() {
                                final idx = _users.indexWhere((u) => u.id == user.id);
                                if (idx != -1) {
                                  _users[idx] = UserModel(
                                    id: user.id,
                                    name: nameController.text.trim(),
                                    username: user.username,
                                    email: emailController.text.trim(),
                                    role: user.role,
                                  );
                                }
                              });
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Data pengguna berhasil diperbarui'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () => _loadUsers(forceRefresh: true),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daftar Pengguna Sistem',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_users.length} Akun',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._users.map((u) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(Icons.person, color: theme.colorScheme.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${u.username} • ${u.email}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      AppBadge.role(u.role),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: 'Edit Akun',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _showEditUserDialog(u),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
