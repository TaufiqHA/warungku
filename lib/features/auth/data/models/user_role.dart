/// Peran pengguna dalam sistem POS & Manajemen Warung
enum UserRole {
  owner('Owner'),
  adminToko('Admin Toko'),
  adminKantor('Admin Kantor');

  final String displayName;
  const UserRole(this.displayName);

  /// Konversi string backend ('OWNER', 'ADMIN_TOKO', 'ADMIN_KANTOR') ke enum UserRole
  static UserRole fromString(String? value) {
    if (value == null) return UserRole.adminToko;
    final normalized = value.trim().toUpperCase().replaceAll(' ', '_');
    switch (normalized) {
      case 'OWNER':
        return UserRole.owner;
      case 'ADMIN_KANTOR':
        return UserRole.adminKantor;
      case 'ADMIN_TOKO':
      default:
        return UserRole.adminToko;
    }
  }

  /// Nilai string untuk dikirimkan ke backend API ('OWNER', 'ADMIN_TOKO', 'ADMIN_KANTOR')
  String toJsonValue() {
    switch (this) {
      case UserRole.owner:
        return 'OWNER';
      case UserRole.adminKantor:
        return 'ADMIN_KANTOR';
      case UserRole.adminToko:
        return 'ADMIN_TOKO';
    }
  }

  bool get isOwner => this == UserRole.owner;
  bool get isAdminToko => this == UserRole.adminToko;
  bool get isAdminKantor => this == UserRole.adminKantor;
}
