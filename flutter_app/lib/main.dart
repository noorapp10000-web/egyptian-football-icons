import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'screens/app_shell.dart';
import 'services/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  runApp(const MasrawyFanApp());
}

class MasrawyFanApp extends StatelessWidget {
  const MasrawyFanApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Masrawy Fan',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    locale: const Locale('ar'),
    builder: (context, child) => Directionality(
      textDirection: TextDirection.rtl,
      child: child ?? const SizedBox.shrink(),
    ),
    home: const AppShell(),
  );
}
