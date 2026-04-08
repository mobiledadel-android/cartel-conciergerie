import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrez un numéro valide')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.sendOtp(
        phoneNumber: phone,
        onCodeSent: (verificationId) {
          if (mounted) {
            setState(() => _isLoading = false);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OtpScreen(
                  phoneNumber: phone,
                  verificationId: verificationId,
                ),
              ),
            );
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error)),
            );
          }
        },
        onAutoVerified: () async {
          if (!mounted) return;
          setState(() => _isLoading = false);
          final isComplete = await _authService.isProfileComplete();
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => isComplete
                  ? const _GoHome()
                  : const _GoCompleteProfile(),
            ),
            (route) => false,
          );
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 30),

              // Logo
              Image.asset(
                'assets/images/cartel_logo.png',
                height: 220,
              ),
              const SizedBox(height: 16),

              // Titre
              Text(
                'Bienvenue',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Connectez-vous avec votre numéro\nde téléphone',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 24),

              // Champ téléphone
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                decoration: InputDecoration(
                  prefixIcon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🇬🇦', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        const Text(
                          '+241',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 1,
                          height: 24,
                          color: AppColors.divider,
                        ),
                      ],
                    ),
                  ),
                  hintText: 'XX XX XX XX',
                ),
              ),
              const SizedBox(height: 24),

              // Bouton connexion
              ElevatedButton(
                onPressed: _isLoading ? null : _sendOtp,
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Recevoir le code'),
              ),
              const SizedBox(height: 24),

              // Conditions
              Text(
                'En continuant, vous acceptez nos\nconditions d\'utilisation',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Wrappers pour navigation post auto-vérification
class _GoHome extends StatelessWidget {
  const _GoHome();
  @override
  Widget build(BuildContext context) {
    // Import circulaire évité — on redirige dans le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/home');
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _GoCompleteProfile extends StatelessWidget {
  const _GoCompleteProfile();
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/complete-profile');
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
