import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'data/datasources/auth_local_datasource.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/product_repository.dart';
import 'data/repositories/stock_repository.dart';
import 'data/repositories/sales_repository.dart';
import 'data/repositories/dashboard_repository.dart';
import 'data/repositories/debt_repository.dart';
import 'data/repositories/daily_sales_repository.dart';
import 'data/repositories/shop_repository.dart';
import 'presentation/providers/daily_sales_provider.dart';
import 'presentation/providers/shop_provider.dart';
import 'domain/usecases/shop_usecases.dart';
import 'domain/usecases/auth_usecases.dart';
import 'domain/usecases/product_usecases.dart';
import 'domain/usecases/sales_usecases.dart';
import 'domain/usecases/stock_usecases.dart';
import 'domain/usecases/dashboard_usecases.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/product_provider.dart';
import 'presentation/providers/stock_provider.dart';
import 'presentation/providers/sales_provider.dart';
import 'presentation/providers/dashboard_provider.dart';
import 'presentation/providers/debt_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/home_shell.dart';

void main() {
  runApp(const SpeshoApp());
}

class SpeshoApp extends StatelessWidget {
  const SpeshoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authLocal = AuthLocalDatasource();
    final apiClient = ApiClient(authLocal);

    final authRepo = AuthRepository(apiClient, authLocal);
    final productRepo = ProductRepository(apiClient);
    final stockRepo = StockRepository(apiClient);
    final salesRepo = SalesRepository(apiClient);
    final dashboardRepo = DashboardRepository(apiClient);
    final debtRepo         = DebtRepository(apiClient);
    final dailySalesRepo   = DailySalesRepository(apiClient);
    final shopRepo         = ShopRepository(apiClient);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthUseCases(authRepo))..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(ProductUseCases(productRepo)),
        ),
        ChangeNotifierProvider(
          create: (_) => StockProvider(StockUseCases(stockRepo)),
        ),
        ChangeNotifierProvider(
          create: (_) => SalesProvider(SalesUseCases(salesRepo)),
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(DashboardUseCases(dashboardRepo), dashboardRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => DebtProvider(debtRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => DailySalesProvider(dailySalesRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => ShopProvider(ShopUseCases(shopRepo)),
        ),
      ],
      child: MaterialApp(
        title: 'Spesho',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const HomeShell(),
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    _navigate();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    Navigator.pushReplacementNamed(context, auth.isLoggedIn ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF131921), Color(0xFF1A56DB), Color(0xFF131921)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Column(
                    children: [
                      // Logo container
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                        ),
                        child: const Icon(Icons.grain_rounded, size: 54, color: Colors.white),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'SPESHO',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.5)),
                        ),
                        child: const Text(
                          'Grain Stock & Sales Management',
                          style: TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 2),
              // Bottom loading bar
              FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(48, 0, 48, 48),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
                          minHeight: 3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Powered by Spesho v1.0',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
