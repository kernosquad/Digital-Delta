import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/color.dart';
import '../../util/routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _pulseController;
  late final AnimationController _bgController;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      title: 'Offline-First\nDisaster Response',
      description:
          'Coordinate relief logistics without internet. Digital Delta works even when networks fail.',
      icon: Icons.cloud_off_rounded,
      accentColor: Color(0xFF00BCD4),
      tagline: 'ZERO CONNECTIVITY REQUIRED',
    ),
    _OnboardingData(
      title: 'Secure Device\nAuthentication',
      description:
          'Military-grade encryption and time-based OTP keep your device secure offline.',
      icon: Icons.security_rounded,
      accentColor: AppColors.primarySurfaceLight,
      tagline: 'MILITARY-GRADE SECURITY',
    ),
    _OnboardingData(
      title: 'Multi-Modal\nRoute Optimization',
      description:
          'AI-powered routing across trucks, boats, and drones to reach every location.',
      icon: Icons.route_rounded,
      accentColor: AppColors.warningSurfaceDefault,
      tagline: 'AI-POWERED LOGISTICS',
    ),
    _OnboardingData(
      title: 'Mesh Network\nCoordination',
      description:
          'Devices sync automatically via Bluetooth mesh when internet is unavailable.',
      icon: Icons.hub_rounded,
      accentColor: Color(0xFFCE93D8),
      tagline: 'AUTONOMOUS MESH SYNC',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) => CustomPaint(
              size: Size(1.sw, 1.sh),
              painter: _TacticalGridPainter(
                progress: _bgController.value,
                accentColor: page.accentColor,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 16.h,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _DeltaBadge(accentColor: page.accentColor),
                          SizedBox(width: 10.w),
                          Text(
                            'DIGITAL DELTA',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ],
                      ),
                      if (_currentPage < _pages.length - 1)
                        GestureDetector(
                          onTap: () => _pageController.animateToPage(
                            _pages.length - 1,
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeInOutCubic,
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 7.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.white60,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (_, i) => _PageContent(
                      data: _pages[i],
                      pulseController: _pulseController,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 36.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOutCubic,
                            margin: EdgeInsets.symmetric(horizontal: 3.w),
                            width: _currentPage == i ? 28.w : 7.w,
                            height: 7.h,
                            decoration: BoxDecoration(
                              color: _currentPage == i
                                  ? page.accentColor
                                  : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 28.h),
                      if (_currentPage == _pages.length - 1) ...[
                        _ActionButton(
                          label: 'Get Started',
                          color: page.accentColor,
                          onPressed: () => Navigator.pushReplacementNamed(
                            context,
                            Routes.register,
                          ),
                          icon: Icons.rocket_launch_rounded,
                          iconAtEnd: false,
                        ),
                        SizedBox(height: 12.h),
                        SizedBox(
                          width: double.infinity,
                          height: 52.h,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pushReplacementNamed(
                              context,
                              Routes.login,
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                              foregroundColor: Colors.white70,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                            ),
                            child: Text(
                              'I Already Have an Account',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ] else
                        _ActionButton(
                          label: 'Next',
                          color: page.accentColor,
                          onPressed: () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOutCubic,
                          ),
                          icon: Icons.arrow_forward_rounded,
                          iconAtEnd: true,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final _OnboardingData data;
  final AnimationController pulseController;

  const _PageContent({required this.data, required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 220.h,
            width: 220.w,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ...[0.0, 0.33, 0.66].map(
                  (offset) => AnimatedBuilder(
                    animation: pulseController,
                    builder: (_, __) {
                      final t = (pulseController.value + offset) % 1.0;
                      return Opacity(
                        opacity: (1 - t) * 0.45,
                        child: Container(
                          width: (72 + t * 130).w,
                          height: (72 + t * 130).h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: data.accentColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  width: 112.w,
                  height: 112.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        data.accentColor.withValues(alpha: 0.25),
                        data.accentColor.withValues(alpha: 0.05),
                      ],
                    ),
                    border: Border.all(
                      color: data.accentColor.withValues(alpha: 0.55),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: data.accentColor.withValues(alpha: 0.3),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(data.icon, size: 52.sp, color: data.accentColor),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: data.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: data.accentColor.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              data.tagline,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: data.accentColor,
                letterSpacing: 1.8,
              ),
            ),
          ),
          SizedBox(height: 28.h),
          Text(
            data.title,
            style: TextStyle(
              fontSize: 34.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          Text(
            data.description,
            style: TextStyle(
              fontSize: 15.sp,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.65,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  final Color accentColor;
  const _DeltaBadge({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34.w,
      height: 34.h,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: accentColor.withValues(alpha: 0.4)),
      ),
      child: Center(
        child: Text(
          '△',
          style: TextStyle(
            fontSize: 17.sp,
            color: accentColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final IconData icon;
  final bool iconAtEnd;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
    required this.icon,
    required this.iconAtEnd,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!iconAtEnd) ...[Icon(icon, size: 20.sp), SizedBox(width: 8.w)],
            Text(
              label,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            if (iconAtEnd) ...[SizedBox(width: 8.w), Icon(icon, size: 20.sp)],
          ],
        ),
      ),
    );
  }
}

class _TacticalGridPainter extends CustomPainter {
  final double progress;
  final Color accentColor;

  const _TacticalGridPainter({
    required this.progress,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const spacing = 36.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final orb1 = Paint()
      ..color = accentColor.withValues(alpha: 0.07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.12),
      170.0 + math.sin(progress * 2 * math.pi) * 20,
      orb1,
    );

    final orb2 = Paint()
      ..color = AppColors.primarySurfaceDark.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.82),
      150.0 + math.cos(progress * 2 * math.pi) * 15,
      orb2,
    );
  }

  @override
  bool shouldRepaint(_TacticalGridPainter old) =>
      old.progress != progress || old.accentColor != accentColor;
}

class _OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final String tagline;

  const _OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.tagline,
  });
}
