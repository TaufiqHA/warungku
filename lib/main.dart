import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/config/app_constants.dart';
import 'app/config/app_theme.dart';
import 'app/observers/app_bloc_observer.dart';
import 'app/routes/app_router.dart';
import 'core/network/api_client.dart';
import 'core/storage/local_storage_service.dart';
import 'core/storage/secure_storage_service.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale formatting Bahasa Indonesia
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi BLoC Observer
  Bloc.observer = AppBlocObserver();

  // Inisialisasi Hive Local Storage
  await LocalStorageService.init();

  // Inisialisasi Core Services & Repositories
  final secureStorage = SecureStorageService();
  late final AuthBloc authBloc;

  final apiClient = ApiClient(
    secureStorage: secureStorage,
    onUnauthorized: () {
      authBloc.add(const AuthLogoutEvent());
    },
  );

  final authRemoteDataSource = AuthRemoteDataSourceImpl(apiClient: apiClient);
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: authRemoteDataSource,
    secureStorage: secureStorage,
  );

  authBloc = AuthBloc(authRepository: authRepository);

  final router = AppRouter.createRouter(authBloc);

  runApp(
    WarungKuApp(
      authBloc: authBloc,
      router: router,
    ),
  );
}

class WarungKuApp extends StatelessWidget {
  final AuthBloc authBloc;
  final GoRouter router;

  const WarungKuApp({
    super.key,
    required this.authBloc,
    required this.router,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
  }
}
