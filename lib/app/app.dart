import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../services/sound_service.dart';
import 'routes.dart';
import 'theme.dart';

/// Root application widget.
class EklavyasAimApp extends ConsumerStatefulWidget {
  const EklavyasAimApp({super.key});

  @override
  ConsumerState<EklavyasAimApp> createState() => _EklavyasAimAppState();
}

class _EklavyasAimAppState extends ConsumerState<EklavyasAimApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final backgrounded = state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached;
    SoundService().setBackgrounded(backgrounded);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}
