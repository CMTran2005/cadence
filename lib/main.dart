import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/constants/app_colors.dart';
import 'core/services/settings_service.dart';
import 'core/theme/app_theme.dart';
import 'features/analytics/presentation/analytics_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/subscriptions/presentation/subscriptions_screen.dart';
import 'features/transactions/presentation/transactions_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService.instance.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const CadenceApp());
}

class CadenceApp extends StatelessWidget {
  const CadenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SettingsService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Cadence',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getTheme(SettingsService.instance.themeBackground),
          home: const MainNavigationShell(),
        );
      },
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  void _navigateToIndex(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = SettingsService.instance.themeBackground;

    final screens = [
      DashboardScreen(
        onNavigateToSubscriptions: () => _navigateToIndex(1),
        onNavigateToTransactions: () => _navigateToIndex(2),
      ),
      const SubscriptionsScreen(),
      const TransactionsScreen(),
      const AnalyticsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: currentTheme.surface,
          border: Border(top: BorderSide(color: currentTheme.border, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: Colors.transparent,
          indicatorColor: currentTheme.surfaceElevated,
          surfaceTintColor: Colors.transparent,
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, size: 22, color: AppColors.textTertiary),
              selectedIcon: Icon(Icons.home_rounded, size: 22, color: AppColors.textPrimary),
              label: 'Tổng quan',
            ),
            NavigationDestination(
              icon: Icon(Icons.repeat_outlined, size: 22, color: AppColors.textTertiary),
              selectedIcon: Icon(Icons.repeat_rounded, size: 22, color: AppColors.textPrimary),
              label: 'Gói định kỳ',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined, size: 22, color: AppColors.textTertiary),
              selectedIcon: Icon(Icons.receipt_long_rounded, size: 22, color: AppColors.textPrimary),
              label: 'Sổ thu chi',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined, size: 22, color: AppColors.textTertiary),
              selectedIcon: Icon(Icons.bar_chart_rounded, size: 22, color: AppColors.textPrimary),
              label: 'Phân tích',
            ),
          ],
        ),
      ),
    );
  }
}
