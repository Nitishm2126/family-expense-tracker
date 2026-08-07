import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_providers.dart';

class PasswordScreen extends ConsumerStatefulWidget {
  const PasswordScreen({super.key});

  @override
  ConsumerState<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends ConsumerState<PasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available = await ref.read(authServiceProvider).isBiometricAvailable;
    if (mounted) setState(() => _biometricAvailable = available);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    FocusScope.of(context).unfocus();
    ref.read(authControllerProvider.notifier).login(_passwordController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.primaryGradient),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.lock_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 28),
              Text('Welcome Back', style: AppTextStyles.displayLarge(
                  Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 8),
              Text(
                'Enter the family password to continue to ${AppConstants.appName}',
                style: AppTextStyles.body(
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 36),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  autofocus: true,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Password is required' : null,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'Family password',
                    prefixIcon: const Icon(Icons.key_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: null, // Forgot password intentionally disabled
                  child: Text(
                    'Forgot password? Ask a family member',
                    style: AppTextStyles.caption(
                        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Login',
                isLoading: authState.isLoading,
                onPressed: _submit,
              ),
              if (_biometricAvailable) ...[
                const SizedBox(height: 20),
                Center(
                  child: TextButton.icon(
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).loginWithBiometrics(),
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: const Text('Use fingerprint instead'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

