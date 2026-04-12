import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'color.dart';

class AppTextTheme {
  AppTextTheme._();

  static TextTheme get textTheme {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.primaryTextDefault,
        fontFamily: 'SFProDisplay',
      ),
      displayMedium: TextStyle(
        fontSize: 45.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.primaryTextDefault,
        fontFamily: 'SFProDisplay',
      ),
      displaySmall: TextStyle(
        fontSize: 36.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.primaryTextDefault,
        fontFamily: 'SFProDisplay',
      ),
      headlineLarge: TextStyle(
        fontSize: 32.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryTextDefault,
        fontFamily: 'SFProDisplay',
      ),
      headlineMedium: TextStyle(
        fontSize: 28.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryTextDefault,
        fontFamily: 'SFProDisplay',
      ),
      headlineSmall: TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryTextDefault,
        fontFamily: 'SFProDisplay',
      ),
      titleLarge: TextStyle(
        fontSize: 22.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryTextDefault,
        fontFamily: 'SFProDisplay',
      ),
      titleMedium: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.primaryTextDefault,
        fontFamily: 'SFProDisplay',
      ),
      titleSmall: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.primaryTextDefault,
        fontFamily: 'SFProDisplay',
      ),
      bodyLarge: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.primaryTextDefault,
        fontFamily: 'SFProDisplay',
      ),
      bodyMedium: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.primaryTextDefault,
        fontFamily: 'SFProDisplay',
      ),
      bodySmall: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.secondaryTextDefault,
        fontFamily: 'SFProDisplay',
      ),
      labelLarge: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryTextDefault,
        fontFamily: 'SFProDisplay',
      ),
      labelMedium: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.primaryTextDefault,
        fontFamily: 'SFProDisplay',
      ),
      labelSmall: TextStyle(
        fontSize: 11.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.secondaryTextDefault,
        fontFamily: 'SFProDisplay',
      ),
    );
  }
}
