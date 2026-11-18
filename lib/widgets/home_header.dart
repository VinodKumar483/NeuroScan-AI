import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../screens/profile_screen.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
          ),
          child: const Icon(
            Icons.psychology_alt,
            color: AppColors.primary,
            size: 30,
          ),
        ),

        const SizedBox(width: 12),

        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NeuroScan AI',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'BRAIN MRI ANALYSIS',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),

        const Spacer(),

        // Profile Button
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
          child: Container(
            height: 43,
            width: 43,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.primary,
              size: 25,
            ),
          ),
        ),
      ],
    );
  }
}
