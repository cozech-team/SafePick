import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    final result = await _authService.signInWithGoogle();

    setState(() => _isLoading = false);

    if (result != null && mounted) {
      // Success! Navigate to Home (You can implement HomeScreen next)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Successfully signed in!')));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign-in failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Logo Placeholder
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.security_rounded,
                  size: 40,
                  color: AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'SafePick',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Protecting your ingredient choices.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ),
              const Spacer(),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    _buildGoogleButton(),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Learn more about our privacy policy',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: _handleGoogleSignIn,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
                height: 24,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.login, size: 24),
              ),
              const SizedBox(width: 12),
              const Flexible(
                child: Text(
                  'Continue with Google',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
