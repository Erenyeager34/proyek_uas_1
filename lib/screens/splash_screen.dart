import 'dart:async';
import 'package:flutter/material.dart';
import 'package:proyek_uas_1/main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animasi muncul perlahan (Fade-In)
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _animController.forward();

    // Pindah otomatis ke halaman utama setelah 2.5 detik
    Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Ikon Daun Herbal Sesuai Proposal Jamuku
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  size: 80,
                  color: Color(0xFF69F0AE),
                ),
              ),
              const SizedBox(height: 24),
              // Nama Aplikasi
              const Text(
                'Jamuku',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              // Slogan Proposal
              const Text(
                'Jamu dicatat rapi, usaha makin terpantau',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const Spacer(),
              // Indikator Loading Bawah
              const CircularProgressIndicator(
                color: Color(0xFF69F0AE),
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              const Text(
                'Memuat data usaha...',
                style: TextStyle(fontSize: 12, color: Colors.white60),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
