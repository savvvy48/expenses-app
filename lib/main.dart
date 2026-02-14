import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_durations.dart';
import 'core/data/hive_expense_repository.dart';
import 'core/data/hive_people_repository.dart';
import 'core/data/migration_helper.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/widgets/shimmer_loading.dart';
import 'providers/expense_provider.dart';
import 'providers/people_provider.dart';
import 'providers/budget_provider.dart';
import 'screens/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Initialize repositories
  final expenseRepo = HiveExpenseRepository();
  final peopleRepo = HivePeopleRepository();

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
        ChangeNotifierProvider(create: (_) => ExpenseProvider(expenseRepo)),
        ChangeNotifierProvider(create: (_) => PeopleProvider(peopleRepo)),
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
    
    // Run initializations with a max timeout to prevent infinite splash
    await Future.any([
      Future.wait([
        MigrationHelper.checkAndMigrate(),
        expProv.init(),
        peopleProv.init(),
        budgetProv.init(),
        // Ensure splash shows for at least a moment to prevent flicker
        Future.delayed(AppDurations.splashMin),
      ]),
      // Safety timeout — proceed even if init hangs
      Future.delayed(AppDurations.splashMax),
    ]);
    
    if (mounted) setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // AnimatedTheme for smooth dark mode transition
    return MaterialApp(
      title: 'SavvySpend',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
      ],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      builder: (context, child) {
        // Sync system UI overlay with current theme
        final isDark = Theme.of(context).brightness == Brightness.dark;
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: isDark ? AppColors.darkBg : AppColors.lightBg,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ));

        return AnimatedTheme(
          data: Theme.of(context),
          duration: AppDurations.themeTransition,
          curve: Curves.easeInOut,
          child: child ?? const SizedBox(),
        );
      },
      home: _initialized ? const AppShell() : const _SplashScreen(),
    );
  }
}



class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: const ShimmerLoading.rectangular(
          height: 24,
          width: 150,
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: ShimmerLoading.circular(size: 32),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
             SizedBox(height: 16),
            // Header Balance Card
             ShimmerCard(height: 180),
             SizedBox(height: 24),
             
            // List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 ShimmerLoading.rectangular(height: 20, width: 100),
                 ShimmerLoading.rectangular(height: 20, width: 60),
              ],
            ),
             SizedBox(height: 16),
            
            // Transaction List
            Expanded(
              child: ShimmerList(itemCount: 6),
            ),
          ],
        ),
      ),
    );
  }
}
