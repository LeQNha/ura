import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_button.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/auth_header.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authViewModelProvider.notifier)
        .sendPasswordResetEmail(_emailController.text.trim());

    if (!mounted) return;

    if (success) {
      setState(() => _emailSent = true);
    } else {
      final error = ref.read(authViewModelProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error?.toString() ?? 'Có lỗi xảy ra')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(
              icon: _emailSent
                  ? Icons.mark_email_read_outlined
                  : Icons.lock_reset_outlined,
              title: _emailSent ? 'Đã gửi email!' : 'Quên mật khẩu?',
              subtitle: _emailSent
                  ? 'Hãy kiểm tra hộp thư để tiếp tục.'
                  : 'Nhập email của bạn, chúng tôi sẽ gửi link đặt lại mật khẩu.',
              showBack: true,
            ),
            AuthFormCard(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _emailSent
                    ? _buildSuccessView(context)
                    : _buildFormView(isLoading),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildFormView(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('form'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              if (!isLoading) _handleSubmit();
            },
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập email';
              }
              if (!value.contains('@')) {
                return 'Email không hợp lệ';
              }
              return null;
            },
          ),
          const SizedBox(height: 22),
          GradientButton(
            label: 'Gửi link đặt lại mật khẩu',
            isLoading: isLoading,
            onPressed: isLoading ? null : _handleSubmit,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('success'),
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withOpacity(0.12),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: const Icon(Icons.check_rounded,
              size: 44, color: AppColors.success),
        ),
        const SizedBox(height: 16),
        Text(
          'Kiểm tra hộp thư của\n${_emailController.text.trim()}\nđể đặt lại mật khẩu.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
        const SizedBox(height: 18),
        TextButton(
          onPressed: () => setState(() => _emailSent = false),
          child: const Text('Gửi lại với email khác'),
        ),
      ],
    );
  }
}
