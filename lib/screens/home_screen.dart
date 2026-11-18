import 'package:flutter/material.dart';

import 'patient_details_screen.dart';
import 'mri_upload_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // NeuroScan AI Theme
  static const Color background = Color(0xFF03132D);
  static const Color cardColor = Color(0xFF0D2440);
  static const Color primary = Color(0xFF19D8F4);
  static const Color secondaryText = Color(0xFFB8C8D8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),

              const SizedBox(height: 35),

              _buildHeroSection(),

              const SizedBox(height: 25),

              _buildUploadButton(context),

              const SizedBox(height: 35),

              _buildInformationSection(),
            ],
          ),
        ),
      ),
    );
  }

  // App Header
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: Image.asset(
            'assets/images/brain_logo.png',
            fit: BoxFit.contain,
          ),
        ),

        const SizedBox(width: 12),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NeuroScan AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 3),
            ],
          ),
        ),

        // History Button
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            );
          },
          tooltip: 'Scan History',
          style: IconButton.styleFrom(
            backgroundColor: cardColor,
            fixedSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: primary.withValues(alpha: 0.15)),
            ),
          ),
          icon: const Icon(Icons.history_rounded, color: primary, size: 23),
        ),

        const SizedBox(width: 8),

        // Profile Button
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
          tooltip: 'Profile',
          style: IconButton.styleFrom(
            backgroundColor: cardColor,
            fixedSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: primary.withValues(alpha: 0.15)),
            ),
          ),
          icon: const Icon(Icons.person_rounded, color: primary, size: 24),
        ),
      ],
    );
  }

  // Main Hero Section
  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF102A49), Color(0xFF0D2440), Color(0xFF132B49)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Brain MRI\nAnalysis',
            style: TextStyle(
              color: Colors.white,
              fontSize: 35,
              height: 1.18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.8,
            ),
          ),

          const Text(
            'Detection and Classification of Brain Tumor\nUsing MRI Analysis',
            style: TextStyle(
              color: secondaryText,
              fontSize: 13,
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 25),

          // Circular Brain MRI Image
          Center(
            child: Container(
              width: 191,
              height: 191,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF8AF4FF), primary, Color(0xFF168CBF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.42),
                    blurRadius: 28,
                    spreadRadius: 3,
                  ),
                  BoxShadow(
                    color: const Color(0xFF168CBF).withValues(alpha: 0.2),
                    blurRadius: 42,
                    spreadRadius: 7,
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF102A49),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/tumor1.jpeg',
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Upload MRI Button
  Widget _buildUploadButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary.withValues(alpha: 0.82),
              const Color(0xFF168CBF).withValues(alpha: 0.72),
              const Color(0xFF0D2440).withValues(alpha: 0.94),
            ],
          ),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.42),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.25),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 7),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () async {
            // Open Patient Details Form
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PatientDetailsScreen(),
              ),
            );

            // Stop if user closes the form
            if (!context.mounted || result == null) {
              return;
            }

            // Open Existing MRI Upload Screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MriUploadScreen(),
                settings: RouteSettings(arguments: result),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
            ),
          ),
          child: const Text(
            'Upload MRI Scan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // How It Works Section
  Widget _buildInformationSection() {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How It Works',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 22),

          _StepItem(title: 'Upload MRI Scan'),

          SizedBox(height: 20),

          _StepItem(title: 'Image Preprocessing'),

          SizedBox(height: 20),

          _StepItem(title: 'AI Detection & Classification'),

          SizedBox(height: 20),

          _StepItem(title: 'View Analysis Report'),
        ],
      ),
    );
  }
}

// Reusable How It Works Step
class _StepItem extends StatelessWidget {
  final String title;

  const _StepItem({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: HomeScreen.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: HomeScreen.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(
            Icons.arrow_forward_rounded,
            color: HomeScreen.primary,
            size: 21,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
