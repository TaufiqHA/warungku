import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/config/app_constants.dart';
import 'app/config/app_theme.dart';
import 'app/observers/app_bloc_observer.dart';
import 'app/routes/app_router.dart';
import 'core/storage/local_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale formatting Bahasa Indonesia
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi BLoC Observer
  Bloc.observer = AppBlocObserver();

  // Inisialisasi Hive Local Storage
  await LocalStorageService.init();

  runApp(const WarungKuApp());
}

class WarungKuApp extends StatelessWidget {
  const WarungKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
