import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import '../theme/app_colors.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> scanHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  // CONVERT DATABASE IMAGE DATA TO UINT8LIST
  Uint8List? getImageBytes(dynamic imageData) {
    if (imageData == null) return null;

    if (imageData is Uint8List) {
      return imageData;
    }

    if (imageData is List<int>) {
      return Uint8List.fromList(imageData);
    }

    return null;
  }

  // LOAD CURRENT USER'S SCAN HISTORY
  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('current_user_id');

      if (userId == null) {
        if (!mounted) return;

        setState(() {
          scanHistory = [];
          isLoading = false;
        });

        return;
      }

      final result = await DatabaseHelper.instance.getScanHistoryByUser(userId);

      if (!mounted) return;

      setState(() {
        scanHistory = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading history: $e')));
    }
  }

  // OPEN THE EXACT SAVED SCAN RESULT
  Future<void> openScanResult(Map<String, dynamic> scan) async {
    try {
      final imagePath = scan['image_path']?.toString() ?? '';

      // GET IMAGE BYTES FROM DATABASE
      final imageBytes = getImageBytes(scan['image_data']);

      File? imageFile;

      if (kIsWeb) {
        // WEB: Check saved image bytes instead of using File.
        if (imageBytes == null || imageBytes.isEmpty) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Original MRI image is not available.'),
            ),
          );

          return;
        }
      } else {
        // ANDROID / IOS: Use saved image file.
        imageFile = File(imagePath);

        if (imagePath.isEmpty || !await imageFile.exists()) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Original MRI image is not available.'),
            ),
          );

          return;
        }
      }

      final prediction = scan['prediction']?.toString() ?? 'Unknown';

      final confidence =
          ((scan['confidence'] as num?)?.toDouble() ?? 0.0) / 100.0;

      Map<String, dynamic> predictionData = {};

      // GET COMPLETE SAVED PREDICTION DATA
      final savedData = scan['prediction_data'];

      if (savedData != null && savedData.toString().isNotEmpty) {
        final decoded = jsonDecode(savedData.toString());

        if (decoded is Map) {
          predictionData = Map<String, dynamic>.from(decoded);
        }
      }

      // FALLBACK FOR OLDER SCANS
      if (predictionData.isEmpty) {
        Map<String, dynamic> probabilities = {};

        final savedProbabilities = scan['probabilities'];

        if (savedProbabilities != null &&
            savedProbabilities.toString().isNotEmpty) {
          try {
            final decoded = jsonDecode(savedProbabilities.toString());

            if (decoded is Map) {
              probabilities = Map<String, dynamic>.from(decoded);
            }
          } catch (_) {
            probabilities = {};
          }
        }

        predictionData = {
          'tumor_type': prediction,
          'argmax_type': prediction,
          'tumor_detected': prediction.toLowerCase() != 'no tumor',
          'tumor_probability': confidence,
          'probabilities_pct': probabilities,
          'tumor_area_pct': 0.0,
        };
      }

      Map<String, dynamic> patientDetails = {};
      final savedPatientDetails = scan['patient_details'];
      if (savedPatientDetails != null &&
          savedPatientDetails.toString().isNotEmpty) {
        try {
          final decodedPatientDetails = jsonDecode(
            savedPatientDetails.toString(),
          );
          if (decodedPatientDetails is Map) {
            patientDetails = Map<String, dynamic>.from(decodedPatientDetails);
          }
        } catch (_) {
          patientDetails = {};
        }
      }

      if (!mounted) return;

      // OPEN RESULT SCREEN WITH THIS SCAN'S DATA
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            mriImage: imageFile,
            mriImageBytes: imageBytes,
            predictionData: predictionData,
            patientDetails: patientDetails,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to open scan result: $e')));
    }
  }

  // FORMAT DATE
  String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateString;
    }
  }

  // FORMAT TIME
  String formatTime(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';

      return '$hour:$minute $period';
    } catch (_) {
      return '';
    }
  }

  // PREDICTION COLOR
  Color getPredictionColor(String prediction) {
    switch (prediction.toLowerCase()) {
      case 'glioma':
        return const Color(0xFFFF5252);
      case 'meningioma':
        return const Color(0xFFFFA726);
      case 'pituitary':
        return const Color(0xFF42A5F5);
      case 'no tumor':
        return const Color(0xFF4CAF50);
      default:
        return AppColors.primary;
    }
  }

  // CONFIRM DELETE
  Future<bool> confirmDelete(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // DELETE ONE SCAN
  Future<void> deleteScan(int scanId) async {
    final confirmed = await confirmDelete(
      'Delete Scan?',
      'Are you sure you want to delete this scan from history?',
    );

    if (!confirmed) return;

    try {
      await DatabaseHelper.instance.deleteScanHistory(scanId);
      await loadHistory();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to delete scan: $e')));
    }
  }

  // DELETE ALL SCANS OF CURRENT USER
  Future<void> deleteAllHistory() async {
    if (scanHistory.isEmpty) return;

    final confirmed = await confirmDelete(
      'Delete All History?',
      'This will permanently delete all your scan history. Continue?',
    );

    if (!confirmed) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('current_user_id');

      if (userId == null) return;

      await DatabaseHelper.instance.deleteAllScanHistoryByUser(userId);
      await loadHistory();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All scan history deleted')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to delete history: $e')));
    }
  }

  // BUILD MRI IMAGE FOR HISTORY CARD
  Widget buildHistoryImage(Map<String, dynamic> scan) {
    final imagePath = scan['image_path']?.toString() ?? '';
    final imageBytes = getImageBytes(scan['image_data']);

    Widget imageWidget;

    if (kIsWeb) {
      imageWidget = imageBytes != null && imageBytes.isNotEmpty
          ? Image.memory(
              imageBytes,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.image_search,
                  color: AppColors.primary,
                  size: 30,
                );
              },
            )
          : const Icon(Icons.image_search, color: AppColors.primary, size: 30);
    } else {
      imageWidget = imagePath.isNotEmpty
          ? Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.image_search,
                  color: AppColors.primary,
                  size: 30,
                );
              },
            )
          : const Icon(Icons.image_search, color: AppColors.primary, size: 30);
    }

    return Container(
      height: 58,
      width: 58,
      color: AppColors.primary.withValues(alpha: 0.12),
      child: imageWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scan History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (scanHistory.isNotEmpty)
            IconButton(
              tooltip: 'Delete All History',
              onPressed: deleteAllHistory,
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOTAL SCANS CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.history,
                        color: AppColors.primary,
                        size: 29,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total MRI Scans',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${scanHistory.length} Scans',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Scans',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (scanHistory.isNotEmpty)
                    Text(
                      '${scanHistory.length} Records',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 15),

              // HISTORY LIST
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : scanHistory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 65,
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              'No Scan History Found',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 7),
                            const Text(
                              'Your MRI scans will appear here.',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: loadHistory,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: scanHistory.length,
                          itemBuilder: (context, index) {
                            final scan = scanHistory[index];

                            final prediction =
                                scan['prediction']?.toString() ?? 'Unknown';

                            final createdAt =
                                scan['created_at']?.toString() ?? '';

                            final confidence =
                                (scan['confidence'] as num?)?.toDouble() ?? 0.0;

                            final scanId = scan['id'] as int;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(18),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () => openScanResult(scan),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // MRI IMAGE
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          child: buildHistoryImage(scan),
                                        ),

                                        const SizedBox(width: 14),

                                        // SCAN DETAILS
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                prediction,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 7),
                                              Text(
                                                '${formatDate(createdAt)}  •  ${formatTime(createdAt)}',
                                                style: const TextStyle(
                                                  color: Colors.white60,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              const SizedBox(height: 7),
                                              Text(
                                                'Confidence: ${confidence.toStringAsFixed(2)}%',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              const Text(
                                                'Tap to view result',
                                                style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // STATUS AND DELETE
                                        Column(
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              color: getPredictionColor(
                                                prediction,
                                              ),
                                              size: 22,
                                            ),
                                            const SizedBox(height: 8),
                                            IconButton(
                                              tooltip: 'Delete Scan',
                                              onPressed: () =>
                                                  deleteScan(scanId),
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.redAccent,
                                                size: 22,
                                              ),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(
                                                minWidth: 32,
                                                minHeight: 32,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
