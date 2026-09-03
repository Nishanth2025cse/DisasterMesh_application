import 'package:flutter/material.dart';
import '../utils/constants.dart';

class SosButton extends StatefulWidget {
  final VoidCallback onPressed;

  const SosButton({super.key, required this.onPressed});

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: GestureDetector(
            onTap: widget.onPressed,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFFFF3B30),
                    Color(0xFFDC2626),
                    Color(0xFF991B1B),
                  ],
                  stops: [0.3, 0.7, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGlow.withOpacity(0.55),
                    blurRadius: 30 * _pulseAnimation.value,
                    spreadRadius: 8 * _pulseAnimation.value,
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 3,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    "🔴",
                    style: TextStyle(fontSize: 32),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "SOS",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  Text(
                    "EMERGENCY",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
