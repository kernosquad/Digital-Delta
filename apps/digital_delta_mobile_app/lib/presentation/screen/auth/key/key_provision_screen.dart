import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../common/widget/custom_button.dart';
import '../../../common/widget/custom_form_field.dart';
import '../../../theme/color.dart';
import '../../../util/routes.dart';
import '../../../util/toaster.dart';
import '../notifier/provider.dart';
import '../state/auth_ui_state.dart';
import '../widget/auth_header.dart';

class KeyProvisionScreen extends ConsumerStatefulWidget {
  const KeyProvisionScreen({super.key});

  @override
  ConsumerState<KeyProvisionScreen> createState() => _KeyProvisionScreenState();
}

class _KeyProvisionScreenState extends ConsumerState<KeyProvisionScreen> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  String? _provisionedKeyId;
  String? _expiresAt;

  void _setupListeners() {
    ref.listen<AuthUiState>(authNotifierProvider, (previous, current) {
      current.maybeWhen(
        success: () {
          Toaster.showSuccess(context, 'Key provisioned successfully!');
        },
        error: (message) {
          Toaster.showError(context, message);
        },
        orElse: () {},
      );
    });
  }

  Future<void> _handleProvisionKey() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      final result = await ref
          .read(authNotifierProvider.notifier)
          .provisionKey(
            deviceId: values['deviceId'] as String,
            publicKey: values['publicKey'] as String,
            keyType: values['keyType'] as String,
          );

      if (result != null) {
        setState(() {
          _provisionedKeyId = result.keyId;
          _expiresAt = result.expiresAt;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _setupListeners();

    final isLoading = ref
        .watch(authNotifierProvider)
        .maybeWhen(loading: () => true, orElse: () => false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Device Security Setup'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                const AuthHeader(
                  title: 'Set Up Your Security Key',
                  subtitle:
                      'Register a key to enable secure device communication',
                ),
                SizedBox(height: 40.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.colorBackground,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.key_rounded,
                        size: 48.sp,
                        color: AppColors.primarySurfaceDefault,
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Text(
                          'Security keys allow your device to communicate securely, even without internet.',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.secondaryTextDefault,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),
                CustomFormField(
                  name: 'deviceId',
                  label: 'Device ID',
                  hint: 'Enter device identifier',
                  keyboardType: TextInputType.text,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.minLength(3),
                  ]),
                ),
                SizedBox(height: 16.h),
                FormBuilderDropdown<String>(
                  name: 'keyType',
                  decoration: InputDecoration(
                    labelText: 'Key Type',
                    hintText: 'Select key type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'rsa', child: Text('Standard (RSA)')),
                    DropdownMenuItem(value: 'ed25519', child: Text('Fast & Secure')),
                    DropdownMenuItem(
                      value: 'ecdsa',
                      child: Text('Compact (ECDSA P-256)'),
                    ),
                  ],
                  validator: FormBuilderValidators.required(),
                  initialValue: 'rsa',
                ),
                SizedBox(height: 16.h),
                CustomFormField(
                  name: 'publicKey',
                  label: 'Public Key',
                  hint: 'Paste your public key (PEM format)',
                  keyboardType: TextInputType.multiline,
                  maxLines: 8,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.minLength(100),
                  ]),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Tip: You can generate a key pair using OpenSSL or your device\'s secure enclave.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.secondaryTextDefault,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 32.h),
                CustomButton(
                  label: 'Register Security Key',
                  onPressed: _handleProvisionKey,
                  isLoading: isLoading,
                ),
                if (_provisionedKeyId != null) ...[
                  SizedBox(height: 32.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurfaceDefault.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: AppColors.primarySurfaceDefault,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primarySurfaceDefault,
                              size: 24.sp,
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              'Key Provisioned Successfully',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryTextDefault,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        _InfoRow(label: 'Key ID', value: _provisionedKeyId!),
                        SizedBox(height: 8.h),
                        _InfoRow(
                          label: 'Expires At',
                          value: _expiresAt ?? 'Never',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  CustomButton(
                    label: 'Done',
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, Routes.main);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100.w,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextDefault,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryTextDefault,
            ),
          ),
        ),
      ],
    );
  }
}
