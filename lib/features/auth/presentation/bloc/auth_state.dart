import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// State inisial sebelum pengecekan sesi
class AuthInitialState extends AuthState {
  const AuthInitialState();
}

/// State loading saat proses otentikasi/pengecekan sesi berjalan
class AuthLoadingState extends AuthState {
  const AuthLoadingState();
}

/// State sukses terotentikasi (memiliki user & token aktif)
class AuthAuthenticatedState extends AuthState {
  final UserModel user;
  final String token;

  const AuthAuthenticatedState({
    required this.user,
    required this.token,
  });

  @override
  List<Object?> get props => [user, token];
}

/// State belum login atau sesi berakhir
class AuthUnauthenticatedState extends AuthState {
  final String? message;

  const AuthUnauthenticatedState({this.message});

  @override
  List<Object?> get props => [message];
}

/// State kegagalan saat proses login
class AuthFailureState extends AuthState {
  final String errorMessage;

  const AuthFailureState(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
