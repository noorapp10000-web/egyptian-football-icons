import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'core/theme.dart';
import 'screens/app_shell.dart';
import 'services/firebase_service.dart';
import 'widgets/brand_mark.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Friendly fallback instead of the default grey error box in release builds.
  ErrorWidget.builder = (details) => Container(
    padding: const EdgeInsets.all(16),
    alignment: Alignment.center,
    color: kBackground,
    child: const Text(
      'تعذر عرض هذا الجزء الآن، حاول تحديث الصفحة',
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.white70, fontSize: 13),
    ),
  );

  // Required before using DateFormat with an explicit locale, otherwise
  // formatting throws and the screen turns into an error box.
  await initializeDateFormatting('ar');
  await initializeDateFormatting('en');
  Intl.defaultLocale = 'ar';

  await FirebaseService.initialize();
  runApp(const MasrawyFanApp());
}

class MasrawyFanApp extends StatelessWidget {
  const MasrawyFanApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ALMASRY SC',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    locale: const Locale('ar'),
    builder: (context, child) => Directionality(
      textDirection: TextDirection.rtl,
      child: child ?? const SizedBox.shrink(),
    ),
    home: const SplashGate(),
  );
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool ready = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => ready = true);
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 450),
    child: ready ? const AppShell() : const SplashScreen(),
  );
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBackground,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          BrandMark(size: 132),
          SizedBox(height: 22),
          Text(
            'ALMASRY SC',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'النادي المصري البورسعيدي',
            style: TextStyle(color: kPrimary, fontSize: 13),
          ),
          SizedBox(height: 26),
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ],
      ),
    ),
  );
}
