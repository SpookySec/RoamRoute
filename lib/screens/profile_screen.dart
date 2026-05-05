import 'package:flutter/material.dart';
import '../theme/duo_theme.dart';
import '../widgets/duo_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PROFILE')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            DuoCard(
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: DuoColors.duoBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Traveler',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: DuoColors.duoTextMain,
                          ),
                        ),
                        Text(
                          'Level 1 Explorer',
                          style: TextStyle(
                            color: DuoColors.duoGray,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: DuoCard(
                    color: Colors.white,
                    child: Column(
                      children: [
                        const Icon(Icons.local_fire_department, color: DuoColors.duoOrange, size: 32),
                        const SizedBox(height: 8),
                        const Text('3', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                        const Text('DAY STREAK', style: TextStyle(color: DuoColors.duoGray, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DuoCard(
                    child: Column(
                      children: [
                        const Icon(Icons.stars, color: DuoColors.duoBlue, size: 32),
                        const SizedBox(height: 8),
                        const Text('120', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                        const Text('TOTAL XP', style: TextStyle(color: DuoColors.duoGray, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'ACHIEVEMENTS',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: DuoColors.duoTextMain,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildAchievement(
              icon: Icons.map,
              color: DuoColors.duoGreen,
              title: 'First Voyage',
              description: 'Complete your first trip.',
              progress: 0.5,
            ),
            const SizedBox(height: 16),
            _buildAchievement(
              icon: Icons.camera_alt,
              color: DuoColors.duoBlue,
              title: 'Memory Maker',
              description: 'Capture 5 moments.',
              progress: 0.8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievement({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required double progress,
  }) {
    return DuoCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                Text(description, style: const TextStyle(color: DuoColors.duoGray, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: DuoColors.duoCardBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
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
