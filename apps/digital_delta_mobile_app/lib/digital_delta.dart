import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:toastification/toastification.dart';

import 'presentation/connectivity/widget/connectivity_listener.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/util/routes.dart';

class DigitalDeltaApp extends StatelessWidget {
  const DigitalDeltaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: false,
      builder: (_, __) => ProviderScope(
        child: ToastificationWrapper(
          child: MaterialApp(
            title: 'Digital Delta',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            initialRoute: Routes.splash,
            onGenerateRoute: Routes.generateRoutes,
            builder: (context, child) =>
                ConnectivityListener(child: child ?? const SizedBox.shrink()),
          ),
        ),
      ),
    );
  }
}
