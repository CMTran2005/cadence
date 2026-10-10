import 'package:flutter/material.dart';

class SubscriptionPreset {
  final String name;
  final double defaultAmount;
  final String billingCycle; // MONTHLY, YEARLY
  final String category;
  final IconData icon;
  final Color brandColor;

  const SubscriptionPreset({
    required this.name,
    required this.defaultAmount,
    this.billingCycle = 'MONTHLY',
    required this.category,
    required this.icon,
    required this.brandColor,
  });
}

class SubscriptionPresets {
  static const List<SubscriptionPreset> popular = [
    SubscriptionPreset(
      name: 'Netflix',
      defaultAmount: 260000,
      category: 'entertainment',
      icon: Icons.movie_outlined,
      brandColor: Color(0xFFE50914),
    ),
    SubscriptionPreset(
      name: 'Spotify',
      defaultAmount: 59000,
      category: 'entertainment',
      icon: Icons.music_note_rounded,
      brandColor: Color(0xFF1DB954),
    ),
    SubscriptionPreset(
      name: 'YouTube Premium',
      defaultAmount: 79000,
      category: 'entertainment',
      icon: Icons.play_circle_outline_rounded,
      brandColor: Color(0xFFFF0000),
    ),
    SubscriptionPreset(
      name: 'Apple iCloud (50GB)',
      defaultAmount: 19000,
      category: 'subscriptions',
      icon: Icons.cloud_outlined,
      brandColor: Color(0xFF007AFF),
    ),
    SubscriptionPreset(
      name: 'ChatGPT Plus',
      defaultAmount: 500000,
      category: 'subscriptions',
      icon: Icons.smart_toy_outlined,
      brandColor: Color(0xFF10A37F),
    ),
    SubscriptionPreset(
      name: 'Internet Gia Đình (Viettel/VNPT)',
      defaultAmount: 220000,
      category: 'bills',
      icon: Icons.wifi_rounded,
      brandColor: Color(0xFF0077B6),
    ),
    SubscriptionPreset(
      name: 'Gói Cước 4G/5G Di Động',
      defaultAmount: 120000,
      category: 'bills',
      icon: Icons.cell_tower_rounded,
      brandColor: Color(0xFFEE0033),
    ),
    SubscriptionPreset(
      name: 'Tiền Trọ / Chung Cư',
      defaultAmount: 3500000,
      category: 'bills',
      icon: Icons.home_work_outlined,
      brandColor: Color(0xFF6366F1),
    ),
    SubscriptionPreset(
      name: 'Thẻ Tập Gym / Yoga',
      defaultAmount: 450000,
      category: 'health',
      icon: Icons.fitness_center_rounded,
      brandColor: Color(0xFFF59E0B),
    ),
  ];
}
