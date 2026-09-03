import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors & Dark Theme Palette
  static const Color background = Color(0xFF0F172A); // Deep Slate Dark
  static const Color surface = Color(0xFF1E293B);    // Card Surface Dark
  static const Color surfaceLight = Color(0xFF334155);
  static const Color border = Color(0xFF475569);

  static const Color primary = Color(0xFFDC2626);   // Emergency Crimson Red
  static const Color primaryGlow = Color(0xFFEF4444);
  static const Color accentBlue = Color(0xFF2563EB); // Action Blue
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Priority Badges Colors
  static const Color priorityHigh = Color(0xFFEF4444);   // 🔴 Red
  static const Color priorityMedium = Color(0xFFF97316); // 🟠 Orange
  static const Color priorityLow = Color(0xFF10B981);    // 🟢 Green

  // Status Colors
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusAccepted = Color(0xFF3B82F6);
  static const Color statusResponding = Color(0xFF8B5CF6);
  static const Color statusRescued = Color(0xFF10B981);
}

class AppCategories {
  static const String medical = "Medical Emergency";
  static const String flood = "Flood Rescue";
  static const String fire = "Fire";
  static const String foodWater = "Food / Water";
  static const String shelter = "Shelter";
  static const String general = "General Emergency";

  static const List<String> allCategories = [
    medical,
    flood,
    fire,
    foodWater,
    shelter,
    general,
  ];
}

class AppPriorities {
  static const String high = "HIGH";
  static const String medium = "MEDIUM";
  static const String low = "LOW";
}

class AppConstants {
  static const String appName = "DisasterMesh";
  static const String appTagline = "Offline Emergency Communication System";
  static const int defaultTTL = 5;
  static const String serviceId = "com.disastermesh.p2p";
}
