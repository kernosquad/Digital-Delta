import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../common/widget/custom_button.dart';
import '../../theme/color.dart';
import '../../util/routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      title: 'Offline-First\nDisaster Response',
      description:
          'Coordinate relief logistics without internet. Digital Delta works even when networks fail.',
      icon: Icons.cloud_off_rounded,
      color: AppColors.nodeCommand,
      accentColor: Color(0xFF00BCD4),
    ),
    _OnboardingPage(
      title: 'Secure Device\nAuthentication',
      description:
          'Military-grade encryption and time-based OTP keep your device secure offline.',
      icon: Icons.security_rounded,
      color: AppColors.primarySurfaceDark,
      accentColor: AppColors.primarySurfaceLight,
    ),
    _OnboardingPage(
      title: 'Multi-Modal\nRoute Optimization',
      description:
          'AI-powered routing across trucks, boats, and drones to reach every location.',
      icon: Icons.route_rounded,
      color: Color(0xFFE65100),
      accentColor: AppColors.warningSurfaceDefault,
    ),
    _OnboardingPage(
      title: 'Mesh Network\nCoordination',
      description:
          'Devices sync automatically via Bluetooth mesh when internet is unavailable.',
      icon: Icons.hub_rounded,
      color: AppColors.nodeDroneBase,
      accentColor: AppColors.nodeDroneBase,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = _pages[_currentPage];
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              currentPage.color,
              currentPage.color.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar with skip button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo
                    Text(
                      'Digital Delta',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    
                    // Skip button
                    if (_currentPage < _pages.length - 1)
                      TextButton(
                        onPressed: () {
                          _pageController.animateToPage(
                            _pages.length - 1,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
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
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Padding(
                      padding: EdgeInsets.all(32.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon in circular container
                          Container(
                            height: 200.h,
                            width: 200.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                            child: Icon(
                              page.icon,
                              size: 100.sp,
                              color: page.accentColor,
                            ),
                          ),
                          SizedBox(height: 48.h),
                          
                          // Title
                          Text(
                            page.title,
                            style: TextStyle(
                              fontSize: 32.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20.h),
                          
                          // Description
                          Text(
                            page.description,
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.white.withOpacity(0.9),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                child: Column(
                  children: [
                    // Page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: EdgeInsets.symmetric(horizontal: 4.w),
                          width: _currentPage == index ? 24.w : 8.w,
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? currentPage.accentColor
                                : Colors.white30,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 32.h),
                    
                    // CTA buttons
                    if (_currentPage == _pages.length - 1) ...[
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          label: 'Get Started',
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, Routes.register),
                          backgroundColor: currentPage.accentColor,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          label: 'I Already Have an Account',
                          isOutlined: true,
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, Routes.login),
                        ),
                      ),
                    ] else
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          label: 'Next',
                          onPressed: () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                          backgroundColor: currentPage.accentColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color accentColor;

  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.accentColor,
  });
}
