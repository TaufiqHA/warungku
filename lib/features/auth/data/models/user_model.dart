import 'package:equatable/equatable.dart';
import 'user_role.dart';

/// Data Transfer Object untuk profil akun pengguna
class UserModel extends Equatable {
  final String id;
  final String name;
  final String username;
  final String email;
  final UserRole role;
  final String status;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.role,
    this.status = 'ACTIVE',
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['nama']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: UserRole.fromString(json['role']?.toString()),
      status: json['status']?.toString() ?? 'ACTIVE',
      avatarUrl: json['avatarUrl']?.toString() ?? json['avatar_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'role': role.toJsonValue(),
      'status': status,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    UserRole? role,
    String? status,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  List<Object?> get props => [id, name, username, email, role, status, avatarUrl];
}
