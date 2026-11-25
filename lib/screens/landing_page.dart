import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';
import 'registration_screen.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  Future<void> _downloadApk(BuildContext context) async {
    final Uri url = Uri.parse("http://10.132.116.236:8000/DisasterMesh-App.apk");
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Downloading... $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Navigation Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.9),
                border: Border(bottom: BorderSide(color: AppColors.primary.withOpacity(0.2))),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 40,
                    height: 40,
                    errorBuilder: (_, __, ___) => const Icon(Icons.shield_rounded, color: AppColors.primaryGlow, size: 36),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "DisasterMesh",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _downloadApk(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text(
                      "DOWNLOAD APK",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            // Hero Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 60, vertical: isMobile ? 40 : 80),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    AppColors.primary.withOpacity(0.18),
                    AppColors.background,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                      border: Border.all(color: AppColors.primaryGlow, width: 2),
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: isMobile ? 80 : 120,
                      height: isMobile ? 80 : 120,
                      errorBuilder: (_, __, ___) => const Icon(Icons.cell_tower_rounded, color: AppColors.primaryGlow, size: 80),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    "OFFLINE EMERGENCY MESH NETWORK",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.primaryGlow,
                      fontWeight: FontWeight.w800,
                      fontSize: isMobile ? 12 : 14,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "DisasterMesh Mobile Application",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: isMobile ? 28 : 44,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Text(
                      "Empowering off-grid disaster communications. Send 1-tap emergency SOS signals, record voice alerts, and relay peer-to-peer mesh data when cellular towers & internet fail.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: isMobile ? 14 : 17,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Hero CTA Buttons
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _downloadApk(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 8,
                          shadowColor: AppColors.primary.withOpacity(0.5),
                        ),
                        icon: const Icon(Icons.download_rounded, size: 24),
                        label: const Text(
                          "DOWNLOAD MOBILE APP (APK)",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.primaryGlow, width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.exit_to_app_rounded, size: 24, color: AppColors.primaryGlow),
                        label: const Text(
                          "LAUNCH EMERGENCY APP",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Features Grid
            Container(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 60, vertical: 60),
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                children: [
                  const Text(
                    "Key Application Features",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Built specifically for zero-infrastructure emergency scenarios",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 40),
                  GridView.count(
                    crossAxisCount: isMobile ? 1 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: isMobile ? 1.8 : 2.2,
                    children: [
                      _buildFeatureCard(
                        icon: Icons.sos_rounded,
                        title: "1-Tap Offline SOS Signal",
                        description: "Generate instant emergency alerts capturing real-time GPS location and medical priority offline.",
                      ),
                      _buildFeatureCard(
                        icon: Icons.hub_rounded,
                        title: "P2P Mesh Network Relay",
                        description: "Relay emergency messages device-to-device over Bluetooth & Wi-Fi Direct without internet.",
                      ),
                      _buildFeatureCard(
                        icon: Icons.mic_rounded,
                        title: "Voice Emergency Recognition",
                        description: "Hands-free voice SOS recognition powered by offline Speech-to-Text AI classification.",
                      ),
                      _buildFeatureCard(
                        icon: Icons.local_hospital_rounded,
                        title: "Rescue Dashboard",
                        description: "First responder dashboard prioritizing rescue tasks by CRITICAL, HIGH, and MEDIUM severity.",
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom Download Banner Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 60, vertical: 50),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.primary, width: 1)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.android_rounded, color: AppColors.primaryGlow, size: 50),
                  const SizedBox(height: 16),
                  const Text(
                    "Get DisasterMesh on Your Phone Today",
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Android 7.0 and above supported • Native APK (91 MB)",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _downloadApk(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 20),
                    label: const Text(
                      "DOWNLOAD DISASTERMESH APK",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({required IconData icon, required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryGlow, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
