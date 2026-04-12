import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../theme/color.dart';

class SocialLoginSection extends StatelessWidget {
  final VoidCallback? onGoogleTap;

  const SocialLoginSection({super.key, this.onGoogleTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: OutlinedButton.icon(
        onPressed: onGoogleTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.borderDefault),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        icon: Icon(Icons.g_mobiledata, size: 24.sp),
        label: Text(
          'Continue with Google',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryTextDefault,
          ),
        ),
      ),
    );
  }
}
