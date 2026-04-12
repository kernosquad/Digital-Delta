import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/datasource/local/source/auth_local_data_source.dart';
import '../../../di/cache_module.dart';
import '../../theme/color.dart';
import '../../util/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      final isLoggedIn = getIt<AuthLocalDataSource>().isLoggedIn();
      Navigator.pushReplacementNamed(
        context,
        isLoggedIn ? Routes.main : Routes.onboarding,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo/digital_delta_logo.png',
                width: 120.w,
                height: 120.h,
              ),
              SizedBox(height: 16.h),
              Text(
                'Digital Delta',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryTextDefault,
                  fontFamily: 'SFProDisplay',
                ),
              ),
                SizedBox(height: 8.h),
              Text(
                textAlign: TextAlign.center,
                'Resilient Logistics & Mesh Triage Engine for Disaster Response',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.primaryTextDefault,
                  fontFamily: 'SFProDisplay',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
