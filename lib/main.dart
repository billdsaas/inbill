import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'core/theme/app_theme.dart';
import 'presentation/viewmodels/app_viewmodel.dart';
import 'presentation/screens/app_shell.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite FFI for desktop
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Ensure app data directory exists
  final appDir = await getApplicationDocumentsDirectory();
  final dbDir = Directory(p.join(appDir.path, 'inbill'));
  if (!await dbDir.exists()) {
    await dbDir.create(recursive: true);
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppViewModel()..init(),
      child: const InbillApp(),
    ),
  );
}

class InbillApp extends StatelessWidget {
  const InbillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppViewModel>(
      builder: (context, vm, _) {
        return MaterialApp(
          title: 'Inbill',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          locale: vm.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('ta'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: _buildHome(vm),
        );
      },
    );
  }

  Widget _buildHome(AppViewModel vm) {
    if (vm.loading) {
      return const Scaffold(
        backgroundColor: AppColors.bgPage,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'I',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 64,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
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
      );
    }

    if (!vm.hasBusinesses) {
      return const OnboardingScreen();
    }

    return const AppShell();
  }
}
