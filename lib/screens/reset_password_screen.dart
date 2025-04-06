import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../routes.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _resetSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.resetPassword(_emailController.text.trim());

    if (success && mounted) {
      setState(() => _resetSent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _resetSent ? _buildSuccessMessage() : _buildResetForm(authService),
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
        const SizedBox(height: 24),
        const Text('Password Reset Email Sent', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Text("Check your inbox for a reset link.", textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
          child: const Text('BACK TO LOGIN'),
        ),
      ],
    );
  }

  Widget _buildResetForm(AuthService authService) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_reset, size: 80, color: Colors.blue),
          const SizedBox(height: 24),
          const Text('Reset Your Password', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          if (authService.errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.red.withAlpha(25), borderRadius: BorderRadius.circular(8)),
              child: Text(authService.errorMessage!, style: TextStyle(color: Colors.red[700])),
            ),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
            keyboardType: TextInputType.emailAddress,
            validator: (value) =>
                value == null || value.isEmpty ? 'Please enter your email' : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: authService.isLoading ? null : _resetPassword,
            child: authService.isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('SEND RESET LINK'),
          ),
        ],
      ),
    );
  }
}
