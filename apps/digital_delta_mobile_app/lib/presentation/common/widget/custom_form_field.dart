import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/color.dart';

class CustomFormField extends StatelessWidget {
  final String name;
  final String label;
  final String? hint;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int? maxLines;
  final TextInputAction textInputAction;
  final ValueChanged<String?>? onChanged;

  const CustomFormField({
    super.key,
    required this.name,
    required this.label,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryTextDefault,
          ),
        ),
        SizedBox(height: 8.h),
        FormBuilderTextField(
          name: name,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          maxLines: maxLines,
          validator: validator,
          onChanged: onChanged,
          style: TextStyle(
            color: AppColors.primaryTextDefault,
            fontSize: 14.sp,
          ),
          decoration: InputDecoration(
            hintText: hint ?? label,
            labelStyle: TextStyle(
              color: AppColors.primaryTextDefault,
              fontSize: 14.sp,
            ),
            hintStyle: TextStyle(
              color: AppColors.secondaryTextDefault,
              fontSize: 14.sp,
            ),
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.h,
            ),
          ),
        ),
      ],
    );
  }
}
