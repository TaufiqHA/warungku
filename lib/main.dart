import 'package:flutter/material.dart';
import 'screens/dashboard/admin_kantor_dashboard_screen.dart';
import 'screens/dashboard/admin_toko_dashboard_screen.dart';
import 'screens/dashboard/dashboard_dispatcher.dart';
import 'screens/dashboard/owner_dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/report/monthly_report_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WarungkuApp());
}

class WarungkuApp extends StatelessWidget {
  const WarungkuApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F766E); // Teal / Emerald elegan & profesional

    return MaterialApp(
      title: 'Warungku',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          surface: Colors.white,
          surfaceContainerLowest: const Color(0xFFF8FAFC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardDispatcher(),
        '/dashboard/admin-toko': (context) => const AdminTokoDashboardScreen(),
        '/dashboard/owner': (context) => const OwnerDashboardScreen(),
        '/dashboard/admin-kantor': (context) => const AdminKantorDashboardScreen(),
        '/report/monthly': (context) => const MonthlyReportScreen(),
        '/monthly_report': (context) => const MonthlyReportScreen(),
      },
    );
  }
}
