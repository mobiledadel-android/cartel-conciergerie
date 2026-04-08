import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import 'complete_profile_screen.dart';
import '../home/home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _authService = AuthService();
  String _otpCode = '';
  bool _isLoading = false;

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) return;

    setState(() => _isLoading = true);
    try {
      await _authService.verifyOtp(_otpCode);
      if (!mounted) return;

      final isComplete = await _authService.isProfileComplete();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              isComplete ? const HomeScreen() : const CompleteProfileScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Code invalide : ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    _authService.sendOtp(
      phoneNumber: widget.phoneNumber,
      onCodeSent: (verificationId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Code renvoyé !')),
          );
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Icône
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sms_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Vérification',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Entrez le code envoyé au\n+241 ${widget.phoneNumber}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 40),

              // Champs OTP
              MaterialPinField(
                length: 6,
                theme: MaterialPinTheme(
                  shape: MaterialPinShape.outlined,
                  cellSize: const Size(48, 56),
                  borderRadius: BorderRadius.circular(12),
                  borderColor: AppColors.divider,
                  focusedBorderColor: AppColors.primary,
                  filledBorderColor: AppColors.accent,
                ),
                onChanged: (value) => _otpCode = value,
                onCompleted: (_) => _verifyOtp(),
              ),
              const SizedBox(height: 24),

              // Bouton vérifier
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Vérifier'),
              ),
              const SizedBox(height: 16),

              // Renvoyer le code
              TextButton(
                onPressed: _resendOtp,
                child: const Text(
                  'Renvoyer le code',
                  style: TextStyle(color: AppColors.accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
