// Donation Screen — EPS Payment Gateway integration
//
// Allows users to donate to humanitarian relief causes using the
// EPS Bangladesh payment gateway (eps_pg_flutter package).
//
// Flow:
//   1. User picks a cause and sets an amount (preset or custom).
//   2. User fills donor name + email.
//   3. App calls EpsPGController.initializePayment → gets paymentUrl.
//   4. EpsPGWebView opens for the actual checkout.
//   5. On return, verifyTransaction confirms the payment.

import 'package:eps_pg_flutter/eps_pg_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/color.dart';
import '../auth/notifier/user_profile_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Donation causes
// ─────────────────────────────────────────────────────────────────────────────

class _Cause {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String raised; // display only
  final String goal;

  const _Cause({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.raised,
    required this.goal,
  });
}

const _causes = [
  _Cause(
    id: 'flood_relief',
    title: 'Flood Relief',
    description:
        'Emergency supplies and evacuation support for flood-affected communities.',
    icon: Icons.water_damage_outlined,
    color: Color(0xFF1565C0),
    raised: '৳42,800',
    goal: '৳100,000',
  ),
  _Cause(
    id: 'medical_aid',
    title: 'Medical Aid',
    description:
        'Field medical kits, medications, and mobile clinic deployments.',
    icon: Icons.medical_services_outlined,
    color: Color(0xFFD32F2F),
    raised: '৳28,300',
    goal: '৳75,000',
  ),
  _Cause(
    id: 'food_supply',
    title: 'Food Supply',
    description: 'Dry food packages and nutrition kits for displaced families.',
    icon: Icons.rice_bowl_outlined,
    color: Color(0xFF388E3C),
    raised: '৳61,500',
    goal: '৳80,000',
  ),
  _Cause(
    id: 'emergency_shelter',
    title: 'Emergency Shelter',
    description:
        'Temporary shelters, tarpaulins, and bedding for crisis zones.',
    icon: Icons.home_outlined,
    color: Color(0xFFF57C00),
    raised: '৳19,200',
    goal: '৳60,000',
  ),
];

const _presetAmounts = [500, 1000, 2000, 5000];

// ─────────────────────────────────────────────────────────────────────────────
// EPS credentials
// Sandbox testbox credentials are used by default.
// Swap environment → EpsPGEnvironment.live and supply real credentials
// from the EPS Merchant Panel before going to production.
// ─────────────────────────────────────────────────────────────────────────────
final _epsInit = EpsPGInitialization(
  userName: 'Epsdemo@gmail.com',
  password: 'Epsdemo258@',
  hashKey: 'FHZxyzeps56789gfhg678ygu876o=',
  merchantId: '29e86e70-0ac6-45eb-ba04-9fcb0aaed12a',
  storeId: 'd44e705f-9e3a-41de-98b1-1674631637da',
  environment: EpsPGEnvironment.testbox, // ← change to .live for production
);

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class DonationScreen extends ConsumerStatefulWidget {
  const DonationScreen({super.key});

  @override
  ConsumerState<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends ConsumerState<DonationScreen>
    with SingleTickerProviderStateMixin {
  int _selectedCauseIndex = 0;
  int? _selectedPreset = 1000;
  final _customCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isCustom = false;
  bool _loading = false;
  bool _profilePrefilled = false;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    // Try to prefill from already-cached profile on screen open
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _tryPrefillFromProfile(),
    );
  }

  void _tryPrefillFromProfile() {
    if (!mounted || _profilePrefilled) return;
    ref.read(refreshableUserProfileProvider).whenData((user) {
      if (user != null) {
        _profilePrefilled = true;
        _nameCtrl.text = user.name;
        _emailCtrl.text = user.email;
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _customCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  double get _amount {
    if (_isCustom) {
      return double.tryParse(_customCtrl.text.trim()) ?? 0;
    }
    return (_selectedPreset ?? 0).toDouble();
  }

  Future<void> _startPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_amount < 10) {
      _showSnack('Minimum donation is ৳10', isError: true);
      return;
    }

    setState(() => _loading = true);

    final txId = DateTime.now().millisecondsSinceEpoch.toString();
    final cause = _causes[_selectedCauseIndex];

    try {
      final controller = EpsPGController(initializer: _epsInit);
      final request = EpsPGPaymentRequest(
        merchantId: _epsInit.merchantId,
        storeId: _epsInit.storeId,
        customerOrderId: 'ORD-$txId',
        merchantTransactionId: txId,
        totalAmount: _amount,
        successUrl: 'https://digitaldelta.app/donation/success',
        failUrl: 'https://digitaldelta.app/donation/fail',
        cancelUrl: 'https://digitaldelta.app/donation/cancel',
        customerName: _nameCtrl.text.trim(),
        customerEmail: _emailCtrl.text.trim(),
        customerAddress: 'Bangladesh',
        customerCity: 'Dhaka',
        customerPostcode: '1212',
        customerCountry: 'BD',
        customerPhone: '01700000000',
        productName: 'Donation: ${cause.title}',
      );

      final response = await controller.initializePayment(request);

      if (!mounted) return;
      setState(() => _loading = false);

      if (response.paymentUrl != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EpsPGWebView(
              url: response.paymentUrl!,
              onPaymentFinished: (status) async {
                Navigator.pop(context);
                await _verifyAndShow(controller, txId, status);
              },
            ),
          ),
        );
      } else {
        _showSnack(
          'Could not start payment: ${response.message ?? 'Unknown error'}',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showSnack('Payment error: $e', isError: true);
      }
    }
  }

  Future<void> _verifyAndShow(
    EpsPGController controller,
    String txId,
    String gatewayStatus,
  ) async {
    if (gatewayStatus == 'CANCELLED') {
      _showSnack('Payment cancelled.', isError: false);
      return;
    }
    if (gatewayStatus == 'FAILED') {
      _showSnack('Payment failed. Please try again.', isError: true);
      return;
    }

    // Verify with EPS backend
    try {
      final status = await controller.verifyTransaction(txId);
      if (!mounted) return;
      if (status.status == 'Successful') {
        _showSuccessDialog(
          status.totalAmount?.toStringAsFixed(0) ?? _amount.toStringAsFixed(0),
        );
      } else {
        _showSnack(
          'Payment could not be verified: ${status.errorMessage ?? 'Unknown error'}',
          isError: true,
        );
      }
    } catch (_) {
      // Fallback: trust the gateway callback status
      if (gatewayStatus == 'SUCCESS') {
        _showSuccessDialog(_amount.toStringAsFixed(0));
      }
    }
  }

  void _showSuccessDialog(String amount) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SuccessDialog(
        amount: amount,
        cause: _causes[_selectedCauseIndex].title,
        onDone: () {
          Navigator.of(context).pop(); // close dialog
          Navigator.of(context).pop(); // go back to home
        },
      ),
    );
  }

  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? AppColors.dangerSurfaceDefault
            : AppColors.statusOnline,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If profile was still loading when screen opened, prefill once data arrives
    ref.listen(refreshableUserProfileProvider, (_, next) {
      if (_profilePrefilled) return;
      next.whenData((user) {
        if (user != null && mounted) {
          _profilePrefilled = true;
          _nameCtrl.text = user.name;
          _emailCtrl.text = user.email;
          setState(() {});
        }
      });
    });

    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primaryTextDefault,
        title: Text(
          'Donate to Relief',
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryTextDefault,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            // ── Sandbox banner ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: const Color(0xFFFFF3CD),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                child: Row(
                  children: [
                    const Icon(
                      Icons.science_outlined,
                      color: Color(0xFF856404),
                      size: 18,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'EPS Sandbox — real payment gateway, no money is charged. '
                        'Switch to EpsPGEnvironment.live for production.',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xFF856404),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Hero ────────────────────────────────────────────────────────
            SliverToBoxAdapter(child: _DonationHero(pulseAnim: _pulseAnim)),

            // ── Choose cause ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Choose a cause'),
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 170.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: _causes.length,
                  separatorBuilder: (_, __) => SizedBox(width: 12.w),
                  itemBuilder: (_, i) => _CauseCard(
                    cause: _causes[i],
                    selected: _selectedCauseIndex == i,
                    onTap: () => setState(() => _selectedCauseIndex = i),
                  ),
                ),
              ),
            ),

            // ── Amount ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Select amount (BDT)'),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 10.h,
                      children: [
                        ..._presetAmounts.map(
                          (amt) => _AmountChip(
                            label: '৳$amt',
                            selected: !_isCustom && _selectedPreset == amt,
                            onTap: () => setState(() {
                              _isCustom = false;
                              _selectedPreset = amt;
                            }),
                          ),
                        ),
                        _AmountChip(
                          label: 'Custom',
                          selected: _isCustom,
                          onTap: () => setState(() => _isCustom = true),
                        ),
                      ],
                    ),
                    if (_isCustom) ...[
                      SizedBox(height: 12.h),
                      TextFormField(
                        controller: _customCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Enter amount',
                          prefixText: '৳ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 14.h,
                          ),
                        ),
                        validator: (v) {
                          if (_isCustom) {
                            final n = double.tryParse(v ?? '');
                            if (n == null || n < 10)
                              return 'Enter at least ৳10';
                          }
                          return null;
                        },
                      ),
                    ],
                    SizedBox(height: 24.h),
                    Row(
                      children: [
                        Expanded(child: _sectionLabel('Donor information')),
                        if (_profilePrefilled)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.statusOnline.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_pin_outlined,
                                  size: 12.sp,
                                  color: AppColors.statusOnline,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'From your profile',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.statusOnline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(color: AppColors.primaryTextDefault),
                      decoration: InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 14.h,
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                    ),
                    SizedBox(height: 12.h),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: AppColors.primaryTextDefault),
                      decoration: InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 14.h,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Email is required';
                        if (!RegExp(
                          r'^[^@]+@[^@]+\.[^@]+',
                        ).hasMatch(v.trim())) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24.h),

                    // ── Impact summary ───────────────────────────────────
                    _ImpactSummary(
                      amount: _amount,
                      cause: _causes[_selectedCauseIndex],
                    ),

                    SizedBox(height: 24.h),

                    // ── Pay button ───────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54.h,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _startPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primarySurfaceDefault,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          elevation: 4,
                          shadowColor: AppColors.primarySurfaceDefault
                              .withValues(alpha: 0.4),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.lock_outline, size: 18),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Donate ৳${_amount.toStringAsFixed(0)} Securely',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    SizedBox(height: 12.h),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            size: 13.sp,
                            color: AppColors.secondaryTextDefault,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Secured by EPS Payment Gateway',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.secondaryTextDefault,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 15.sp,
      fontWeight: FontWeight.w700,
      color: AppColors.primaryTextDefault,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero banner
// ─────────────────────────────────────────────────────────────────────────────

class _DonationHero extends StatelessWidget {
  final Animation<double> pulseAnim;

  const _DonationHero({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF0288D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Decorative circles
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 28.h),
            child: Column(
              children: [
                ScaleTransition(
                  scale: pulseAnim,
                  child: Container(
                    width: 70.w,
                    height: 70.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.volunteer_activism,
                      size: 36.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Make a Difference Today',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Your donation directly funds field operations, medical aid, and emergency relief missions in disaster zones.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatBadge(label: 'Donors', value: '1,240+'),
                    _StatBadge(label: 'Raised', value: '৳1.5M+'),
                    _StatBadge(label: 'Missions', value: '86'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;

  const _StatBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cause card
// ─────────────────────────────────────────────────────────────────────────────

class _CauseCard extends StatelessWidget {
  final _Cause cause;
  final bool selected;
  final VoidCallback onTap;

  const _CauseCard({
    required this.cause,
    required this.selected,
    required this.onTap,
  });

  double get _progress {
    final raised =
        double.tryParse(cause.raised.replaceAll(RegExp(r'[৳,]'), '')) ?? 0;
    final goal =
        double.tryParse(cause.goal.replaceAll(RegExp(r'[৳,]'), '')) ?? 1;
    return (raised / goal).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 180.w,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: selected ? cause.color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: selected ? cause.color : AppColors.borderDefault,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: cause.color.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: cause.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(cause.icon, size: 20.sp, color: cause.color),
                ),
                const Spacer(),
                if (selected)
                  Icon(Icons.check_circle, color: cause.color, size: 18.sp),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              cause.title,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTextDefault,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              cause.description,
              style: TextStyle(
                fontSize: 10.sp,
                color: AppColors.secondaryTextDefault,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: AppColors.borderDefault,
                color: cause.color,
                minHeight: 5.h,
              ),
            ),
            SizedBox(height: 5.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  cause.raised,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: cause.color,
                  ),
                ),
                Text(
                  cause.goal,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.secondaryTextDefault,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Amount chip
// ─────────────────────────────────────────────────────────────────────────────

class _AmountChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AmountChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurfaceDefault : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected
                ? AppColors.primarySurfaceDefault
                : AppColors.borderDefault,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primarySurfaceDefault.withValues(
                      alpha: 0.3,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.primaryTextDefault,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Impact summary
// ─────────────────────────────────────────────────────────────────────────────

class _ImpactSummary extends StatelessWidget {
  final double amount;
  final _Cause cause;

  const _ImpactSummary({required this.amount, required this.cause});

  String _impactText() {
    if (amount <= 0) return 'Your donation will directly support this cause.';
    if (amount >= 5000) {
      return 'Provides emergency supplies for an entire family for a week.';
    }
    if (amount >= 2000) {
      return 'Covers 3 days of meals and basic necessities for a displaced person.';
    }
    if (amount >= 1000) {
      return 'Delivers a basic emergency kit to a family in the field.';
    }
    return 'Contributes to mission logistics and field support costs.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cause.color.withValues(alpha: 0.06),
            cause.color.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cause.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: cause.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(cause.icon, size: 22.sp, color: cause.color),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Impact',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTextDefault,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _impactText(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.secondaryTextDefault,
                    height: 1.4,
                  ),
                ),
                if (amount > 0) ...[
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: cause.color,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      'Donating ৳${amount.toStringAsFixed(0)} to ${cause.title}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Success dialog
// ─────────────────────────────────────────────────────────────────────────────

class _SuccessDialog extends StatelessWidget {
  final String amount;
  final String cause;
  final VoidCallback onDone;

  const _SuccessDialog({
    required this.amount,
    required this.cause,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Padding(
        padding: EdgeInsets.all(28.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.w,
              height: 72.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.statusOnline.withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 42.sp,
                color: AppColors.statusOnline,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Thank You! 🙏',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryTextDefault,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'Your donation of ৳$amount to\n$cause has been received.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.secondaryTextDefault,
                height: 1.5,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Every taka helps us reach more people in need.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.secondaryTextDefault,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primarySurfaceDefault,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  'Back to Home',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
