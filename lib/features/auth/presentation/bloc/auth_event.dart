import 'package:equatable/equatable.dart';
import '../../data/models/login_request.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event pengecekan sesi login saat aplikasi dibuka
class AuthCheckSessionEvent extends AuthEvent {
  const AuthCheckSessionEvent();
}

/// Event submit login akun pengguna
class AuthLoginEvent extends AuthEvent {
  final LoginRequest request;

  const AuthLoginEvent(this.request);

  @override
  List<Object?> get props => [request];
}

/// Event logout akun pengguna
class AuthLogoutEvent extends AuthEvent {
  const AuthLogoutEvent();
}
