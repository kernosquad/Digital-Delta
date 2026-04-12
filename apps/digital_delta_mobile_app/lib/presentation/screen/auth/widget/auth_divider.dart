import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../theme/color.dart';

class AuthDivider extends StatelessWidget {
  final String label;

  const AuthDivider({super.key, this.label = 'or continue with'});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.borderDefault)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.secondaryTextDefault,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.borderDefault)),
      ],
    );
  }
}
