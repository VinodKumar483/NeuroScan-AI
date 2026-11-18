import 'package:flutter/material.dart';

import 'feature_card.dart';
import '../screens/history_screen.dart';

class FeatureSection extends StatelessWidget {
  final VoidCallback onMriUploadTap;
  final VoidCallback onPredictionResultTap;

  const FeatureSection({
    super.key,
    required this.onMriUploadTap,
    required this.onPredictionResultTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CORE FEATURES',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 18),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.76,

          children: [
            // 1. MRI Upload
            GestureDetector(
              onTap: onMriUploadTap,
              child: const FeatureCard(
                icon: Icons.upload_file_rounded,
                title: 'MRI Upload',
                description: 'Upload brain MRI images for analysis.',
              ),
            ),

            // 2. Tumor Detection
            GestureDetector(
              onTap: onMriUploadTap,
              child: const FeatureCard(
                icon: Icons.psychology_rounded,
                title: 'Tumor Detection',
                description: 'Detect and classify brain tumor categories.',
              ),
            ),

            // 3. Prediction Result
            GestureDetector(
              onTap: onPredictionResultTap,
              child: const FeatureCard(
                icon: Icons.analytics_rounded,
                title: 'Prediction Result',
                description: 'View prediction and confidence percentage.',
              ),
            ),

            // 4. Prediction History
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoryScreen(),
                  ),
                );
              },
              child: const FeatureCard(
                icon: Icons.history_rounded,
                title: 'Prediction History',
                description: 'View your previous prediction records.',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
