import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

/// State Management BLoC untuk alur autentikasi dan manajemen sesi
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(const AuthInitialState()) {
    on<AuthCheckSessionEvent>(_onCheckSession);
    on<AuthLoginEvent>(_onLogin);
    on<AuthLogoutEvent>(_onLogout);
  }

  Future<void> _onCheckSession(
    AuthCheckSessionEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      final token = await authRepository.getSavedToken();
      final user = await authRepository.getSavedUser();

      if (token != null && token.isNotEmpty && user != null) {
        emit(AuthAuthenticatedState(user: user, token: token));
      } else {
        emit(const AuthUnauthenticatedState());
      }
    } catch (_) {
      emit(const AuthUnauthenticatedState());
    }
  }

  Future<void> _onLogin(
    AuthLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      final response = await authRepository.login(event.request);
      emit(AuthAuthenticatedState(
        user: response.user,
        token: response.token,
      ));
    } on ApiException catch (e) {
      emit(AuthFailureState(e.message));
    } catch (e) {
      emit(AuthFailureState('Terjadi kesalahan tidak terduga: ${e.toString()}'));
    }
  }

  Future<void> _onLogout(
    AuthLogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      await authRepository.logout();
    } catch (_) {
      // Abaikan error saat proses pembersihan logout
    }
    emit(const AuthUnauthenticatedState(message: 'Anda telah berhasil keluar.'));
  }
}
