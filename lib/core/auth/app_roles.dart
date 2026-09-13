class AppRoles {
  static const String owner = 'OWNER';
  static const String adminToko = 'ADMIN_TOKO';
  static const String adminKantor = 'ADMIN_KANTOR';

  static bool isValidRole(String? role) {
    if (role == null) return false;
    final r = role.toUpperCase();
    return r == owner || r == adminToko || r == adminKantor;
  }

  static String getDisplayName(String? role) {
    switch (role?.toUpperCase()) {
      case owner:
        return 'Owner';
      case adminToko:
        return 'Admin Toko';
      case adminKantor:
        return 'Admin Kantor';
      default:
        return 'Pengguna';
    }
  }
}
