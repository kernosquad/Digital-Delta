import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../core/security/device_service.dart';
import '../../../../di/cache_module.dart';
import '../../../common/widget/custom_form_field.dart';
import '../../../theme/color.dart';
import '../../../util/routes.dart';
import '../../../util/toaster.dart';
import '../notifier/provider.dart';
import '../state/auth_ui_state.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  bool _obscurePassword = true;
  String? _deviceId;
  bool _isOnline = true;

  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    _loadDeviceInfo();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceInfo() async {
    final deviceService = getIt<DeviceService>();
    final deviceId = await deviceService.getDeviceId();
    setState(() => _deviceId = deviceId);
  }

  void _setupListeners() {
    ref.listen<AuthUiState>(authNotifierProvider, (_, current) {
      current.maybeWhen(
        success: () => Navigator.pushReplacementNamed(context, Routes.otpSetup),
        error: (message) => Toaster.showError(context, message),
        orElse: () {},
      );
    });
  }

  Future<void> _handleRegister() async {
    if (!_isOnline) {
      Toaster.showError(
        context,
        'Registration requires internet connection. Please connect and try again.',
      );
      return;
    }
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      await ref
          .read(authNotifierProvider.notifier)
          .register(
            name: values['name'] as String,
            email: values['email'] as String,
            password: values['password'] as String,
            role: values['role'] as String,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    _setupListeners();

    final isLoading = ref
        .watch(authNotifierProvider)
        .maybeWhen(loading: () => true, orElse: () => false);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) => CustomPaint(
              size: Size(1.sw, 1.sh),
              painter: _RegisterBgPainter(progress: _bgController.value),
            ),
          ),
          Column(
            children: [
              _RegisterHeader(),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.colorBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28.r),
                      topRight: Radius.circular(28.r),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 32.h),
                    child: FormBuilder(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 40.w,
                              height: 4.h,
                              decoration: BoxDecoration(
                                color: AppColors.borderDefault,
                                borderRadius: BorderRadius.circular(2.r),
                              ),
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryTextDefault,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Fill in your details to join Digital Delta',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: AppColors.secondaryTextDefault,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          CustomFormField(
                            name: 'name',
                            label: 'Full Name',
                            hint: 'Enter your full name',
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              size: 20.sp,
                              color: AppColors.secondaryTextDefault,
                            ),
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                              FormBuilderValidators.minLength(3),
                            ]),
                          ),
                          SizedBox(height: 16.h),
                          CustomFormField(
                            name: 'email',
                            label: 'Email',
                            hint: 'Enter your email',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icon(
                              Icons.mail_outline_rounded,
                              size: 20.sp,
                              color: AppColors.secondaryTextDefault,
                            ),
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                              FormBuilderValidators.email(),
                            ]),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Role',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryTextDefault,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          FormBuilderDropdown<String>(
                            name: 'role',
                            initialValue: 'field_volunteer',
                            decoration: InputDecoration(
                              hintText: 'Select your role',
                              prefixIcon: Icon(
                                Icons.badge_outlined,
                                size: 20.sp,
                                color: AppColors.secondaryTextDefault,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: const BorderSide(
                                  color: AppColors.borderDefault,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: const BorderSide(
                                  color: AppColors.borderDefault,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: const BorderSide(
                                  color: AppColors.primarySurfaceDefault,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 14.h,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'field_volunteer',
                                child: Text('Field Volunteer'),
                              ),
                              DropdownMenuItem(
                                value: 'supply_manager',
                                child: Text('Supply Manager'),
                              ),
                              DropdownMenuItem(
                                value: 'drone_operator',
                                child: Text('Drone Operator'),
                              ),
                              DropdownMenuItem(
                                value: 'camp_commander',
                                child: Text('Camp Commander'),
                              ),
                              DropdownMenuItem(
                                value: 'sync_admin',
                                child: Text('Data Sync Manager'),
                              ),
                            ],
                            validator: FormBuilderValidators.required(),
                          ),
                          SizedBox(height: 16.h),
                          CustomFormField(
                            name: 'password',
                            label: 'Password',
                            hint: 'Create a strong password',
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            prefixIcon: Icon(
                              Icons.key_outlined,
                              size: 20.sp,
                              color: AppColors.secondaryTextDefault,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20.sp,
                              ),
                            ),
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                              FormBuilderValidators.minLength(8),
                            ]),
                          ),
                          SizedBox(height: 16.h),
                          _InfoBanner(
                            icon: Icons.wifi_off_rounded,
                            message:
                                'Registration requires an internet connection',
                            color: AppColors.infoText,
                            bgColor: AppColors.infoSurface,
                            borderColor: AppColors.infoBorder,
                          ),
                          if (_deviceId != null) ...[
                            SizedBox(height: 10.h),
                            _DeviceChip(deviceId: _deviceId!),
                          ],
                          SizedBox(height: 24.h),
                          SizedBox(
                            width: double.infinity,
                            height: 52.h,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppColors.primarySurfaceDefault,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                              ),
                              child: isLoading
                                  ? SizedBox(
                                      width: 20.w,
                                      height: 20.h,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  color: AppColors.secondaryTextDefault,
                                  fontSize: 14.sp,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacementNamed(
                                  context,
                                  Routes.login,
                                ),
                                child: Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: AppColors.primarySurfaceDefault,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── sub-widgets ──────────────────────────────────────────────────────────────

class _RegisterHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 210.h,
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30.w,
                    height: 30.h,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurfaceDefault.withValues(
                        alpha: 0.2,
                      ),
                      borderRadius: BorderRadius.circular(7.r),
                      border: Border.all(
                        color: AppColors.primarySurfaceDefault.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '△',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.primarySurfaceLight,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'DIGITAL DELTA',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 2.2,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              Container(
                width: 60.w,
                height: 60.h,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primarySurfaceDefault.withValues(alpha: 0.4),
                      AppColors.primarySurfaceDefault.withValues(alpha: 0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primarySurfaceDefault.withValues(
                      alpha: 0.5,
                    ),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primarySurfaceDefault.withValues(
                        alpha: 0.25,
                      ),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person_add_outlined,
                  size: 28.sp,
                  color: AppColors.primarySurfaceLight,
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                'Join the Mission',
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Create your Digital Delta account',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final Color bgColor;
  final Color borderColor;

  const _InfoBanner({
    required this.icon,
    required this.message,
    required this.color,
    required this.bgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12.sp, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceChip extends StatelessWidget {
  final String deviceId;
  const _DeviceChip({required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.primarySurfaceDefault.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: AppColors.primarySurfaceDefault.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.smartphone_rounded,
            size: 15.sp,
            color: AppColors.primarySurfaceDefault,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Device: ${deviceId.substring(0, 8)}...',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.secondaryTextDefault,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppColors.primarySurfaceTint,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              'LINKED',
              style: TextStyle(
                fontSize: 9.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primarySurfaceDark,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterBgPainter extends CustomPainter {
  final double progress;
  const _RegisterBgPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const spacing = 36.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height * 0.55), linePaint);
    }
    for (double y = 0; y <= size.height * 0.55; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final orb = Paint()
      ..color = AppColors.primarySurfaceDefault.withValues(alpha: 0.09)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.08),
      120.0 + math.cos(progress * 2 * math.pi) * 15,
      orb,
    );

    final orb2 = Paint()
      ..color = const Color(0xFF00BCD4).withValues(alpha: 0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.18),
      100.0 + math.sin(progress * 2 * math.pi) * 12,
      orb2,
    );
  }

  @override
  bool shouldRepaint(_RegisterBgPainter old) => old.progress != progress;
}
