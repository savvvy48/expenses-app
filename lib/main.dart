import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/people_provider.dart';
import 'providers/budget_provider.dart';
import 'screens/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => PeopleProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
      ],
      child: const DailyExpensesApp(),
    ),
  );
}

class DailyExpensesApp extends StatefulWidget {
  const DailyExpensesApp({super.key});

  @override
  State<DailyExpensesApp> createState() => _DailyExpensesAppState();
}

class _DailyExpensesAppState extends State<DailyExpensesApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initProviders();
  }

  Future<void> _initProviders() async {
    final expProv = context.read<ExpenseProvider>();
    final peopleProv = context.read<PeopleProvider>();
    final budgetProv = context.read<BudgetProvider>();
    await expProv.init();
    await peopleProv.init();
    await budgetProv.init();
    if (mounted) setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // AnimatedTheme for smooth dark mode transition
    return MaterialApp(
      title: 'Daily Expenses',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      builder: (context, child) {
        return AnimatedTheme(
          data: Theme.of(context),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          child: child ?? const SizedBox(),
        );
      },
      home: _initialized ? const AppShell() : const _SplashScreen(),
    );
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();
  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _scale = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    boxShadow: AppColors.sharpShadow(isDark),
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: 24),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
