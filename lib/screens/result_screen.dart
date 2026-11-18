import 'dart:convert';
import 'dart:io';
import 'mri_upload_screen.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ResultScreen extends StatelessWidget {
  static const Color background = Color(0xFF03132D);
  static const Color cardColor = Color(0xFF0D2440);
  static const Color primary = Color(0xFF19D8F4);
  static const Color secondaryText = Color(0xFF91A4B8);

  final File? mriImage;
  final Uint8List? mriImageBytes;
  final Map<String, dynamic> predictionData;
  final Map<String, dynamic> patientDetails;

  const ResultScreen({
    super.key,
    this.mriImage,
    this.mriImageBytes,
    required this.predictionData,
    this.patientDetails = const {},
  });

  @override
  Widget build(BuildContext context) {
    final String tumorType =
        predictionData['tumor_type']?.toString() ?? 'Unknown';

    final routeArguments = ModalRoute.of(context)?.settings.arguments;
    final resolvedPatientDetails = this.patientDetails.isNotEmpty
        ? this.patientDetails
        : routeArguments is Map
        ? Map<String, dynamic>.from(routeArguments)
        : <String, dynamic>{};

    final bool tumorDetected = predictionData['tumor_detected'] == true;

    final double confidence =
        ((predictionData['tumor_probability'] as num?)?.toDouble() ?? 0.0) *
        100;

    final double tumorArea =
        (predictionData['tumor_area_pct'] as num?)?.toDouble() ?? 0.0;

    final Map<String, dynamic> probabilities =
        predictionData['probabilities_pct'] is Map
        ? Map<String, dynamic>.from(predictionData['probabilities_pct'])
        : {};

    Uint8List? predictionImageBytes;

    try {
      final String? encodedImage = predictionData['prediction_image']
          ?.toString();

      if (encodedImage != null && encodedImage.isNotEmpty) {
        predictionImageBytes = base64Decode(encodedImage);
      }
    } catch (e) {
      debugPrint('Prediction image decoding error: $e');
    }

    final Color statusColor = tumorDetected
        ? const Color(0xFFFF6B75)
        : const Color(0xFF43D9A3);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReportHeading(),

                    const SizedBox(height: 22),

                    _buildPatientDetailsCard(resolvedPatientDetails),

                    const SizedBox(height: 22),

                    _buildStatusCard(
                      tumorDetected: tumorDetected,
                      tumorType: tumorType,
                      statusColor: statusColor,
                    ),

                    const SizedBox(height: 28),

                    _buildSectionTitle(
                      'MRI Comparison',
                      '',
                      Icons.compare_rounded,
                    ),

                    const SizedBox(height: 12),

                    _buildComparisonCard(
                      context,
                      originalImage: kIsWeb
                          ? (mriImageBytes != null
                                ? Image.memory(
                                    mriImageBytes!,
                                    fit: BoxFit.contain,
                                  )
                                : null)
                          : (mriImage != null
                                ? Image.file(mriImage!, fit: BoxFit.contain)
                                : null),
                      predictionImageBytes: predictionImageBytes,
                    ),

                    const SizedBox(height: 26),

                    _buildSectionTitle(
                      'Prediction Analytics',
                      '',
                      Icons.analytics_outlined,
                      showIcon: false,
                    ),

                    const SizedBox(height: 12),

                    _buildAnalyticsCard(
                      tumorType: tumorType,
                      confidence: confidence,
                      tumorArea: tumorArea,
                      statusColor: statusColor,
                    ),

                    const SizedBox(height: 16),

                    _buildProbabilityCard(probabilities),

                    const SizedBox(height: 22),

                    // NEW PDF BUTTON
                    _buildPdfButton(
                      context,
                      patientDetails: resolvedPatientDetails,
                      tumorType: tumorType,
                      tumorDetected: tumorDetected,
                      confidence: confidence,
                      tumorArea: tumorArea,
                      probabilities: probabilities,
                      predictionImageBytes: predictionImageBytes,
                    ),

                    const SizedBox(height: 14),

                    _buildAnalyzeButton(
                      context,
                      patientDetails: resolvedPatientDetails,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HEADER
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(
          bottom: BorderSide(color: primary.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'NeuroScan AI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // REPORT HEADING
  Widget _buildReportHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prediction Report',
          style: TextStyle(
            color: Colors.white,
            fontSize: 29,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.7,
          ),
        ),
      ],
    );
  }

  // PATIENT DETAILS CARD
  Widget _buildPatientDetailsCard(Map<String, dynamic> details) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primary.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          const Row(
            children: [
              Icon(Icons.person_outline_rounded, color: primary, size: 23),
              SizedBox(width: 10),
              Text(
                'Patient Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _patientDetailRow(
            'Patient Name',
            details['name']?.toString() ?? 'Not available',
          ),
          _patientDetailRow(
            'Age',
            details['age']?.toString() ?? 'Not available',
          ),
          _patientDetailRow(
            'Gender',
            details['gender']?.toString() ?? 'Not available',
          ),
          _patientDetailRow(
            'MRI Scan Date',
            details['scanDate']?.toString() ?? 'Not available',
          ),
            ],
          ),
        ),
      ),
    );
  }

  // PATIENT DETAIL ROW
  Widget _patientDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: secondaryText, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // STATUS CARD
  Widget _buildStatusCard({
    required bool tumorDetected,
    required String tumorType,
    required Color statusColor,
  }) {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              statusColor.withValues(alpha: 0.6),
              statusColor,
              statusColor.withValues(alpha: 0.35),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.25),
              blurRadius: 28,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cardColor,
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                tumorDetected ? 'Tumor Detected' : 'No Tumor Detected',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Classification\n${_formatLabel(tumorType)}',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // SECTION TITLE
  Widget _buildSectionTitle(
    String title,
    String subtitle,
    IconData icon, {
    bool showIcon = true,
  }) {
    return Row(
      children: [
        if (showIcon) ...[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primary, size: 20),
          ),
          const SizedBox(width: 11),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: secondaryText, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  } // SIDE-BY-SIDE MRI COMPARISON

  Widget _buildComparisonCard(
    BuildContext context, {
    required Widget? originalImage,
    required Uint8List? predictionImageBytes,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(color: primary.withValues(alpha: 0.05), blurRadius: 18),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildComparisonPanel(
              label: 'ORIGINAL MRI',
              child: originalImage,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _buildComparisonPanel(
              label: 'AI PREDICTION',
              child: predictionImageBytes == null
                  ? null
                  : GestureDetector(
                      onTap: () => _openFullScreenImage(
                        context,
                        predictionImageBytes,
                        'AI Prediction Visualization',
                      ),
                      child: Image.memory(
                        predictionImageBytes,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white38,
                              size: 30,
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // COMPARISON PANEL
  Widget _buildComparisonPanel({
    required String label,
    required Widget? child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: primary,
              fontSize: 9,
              letterSpacing: 0.6,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 9),
        Container(
          height: 185,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: background.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child:
                child ??
                const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.white38,
                    size: 32,
                  ),
                ),
          ),
        ),
        if (label == 'AI PREDICTION') ...[
          const SizedBox(height: 7),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.zoom_in_rounded, color: secondaryText, size: 13),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Tap to zoom',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: secondaryText, fontSize: 9),
                ),
              ),
            ],
          ),
        ] else
          const SizedBox(height: 20),
      ],
    );
  }

  // OPEN FULL SCREEN IMAGE
  void _openFullScreenImage(
    BuildContext context,
    Uint8List imageBytes,
    String title,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            FullScreenImageViewer(imageBytes: imageBytes, title: title),
      ),
    );
  }

  // ANALYTICS CARD
  Widget _buildAnalyticsCard({
    required String tumorType,
    required double confidence,
    required double tumorArea,
    required Color statusColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _metricItem(
                  'CLASSIFICATION',
                  _formatLabel(tumorType),
                  primary,
                ),
              ),
              Container(width: 1, height: 55, color: Colors.white12),
              Expanded(
                child: _metricItem(
                  'TUMOR AREA',
                  '${tumorArea.toStringAsFixed(2)}%',
                  const Color(0xFFB28AFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Divider(color: Colors.white12),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Model Prediction Score',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${confidence.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: (confidence / 100).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }

  // METRIC ITEM
  Widget _metricItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: secondaryText,
              fontSize: 9,
              letterSpacing: 1,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // CLASS PROBABILITIES CARD
  Widget _buildProbabilityCard(Map<String, dynamic> probabilities) {
    final entries = probabilities.entries.toList()
      ..sort((a, b) {
        final aValue = (a.value as num).toDouble();
        final bValue = (b.value as num).toDouble();
        return bValue.compareTo(aValue);
      });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: primary, size: 22),
              SizedBox(width: 9),
              Text(
                'Class Probabilities',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (entries.isEmpty)
            const Text(
              'Probability information unavailable',
              style: TextStyle(color: secondaryText),
            )
          else ...[
            for (var i = 0; i < entries.length; i += 2) ...[
              if (i > 0) const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _probabilityBadge(
                      _formatLabel(entries[i].key),
                      (entries[i].value as num).toDouble().clamp(0.0, 100.0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (i + 1 < entries.length)
                    Expanded(
                      child: _probabilityBadge(
                        _formatLabel(entries[i + 1].key),
                        (entries[i + 1].value as num)
                            .toDouble()
                            .clamp(0.0, 100.0),
                      ),
                    )
                  else
                    const Spacer(),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  } // PDF REPORT BUTTON

  Widget _probabilityBadge(String label, double value) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cardColor,
          border: Border.all(color: primary.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.1),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: value / 100,
                strokeWidth: 4,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(primary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${value.toStringAsFixed(2)}%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  Widget _buildPdfButton(
    BuildContext context, {
    required Map<String, dynamic> patientDetails,
    required String tumorType,
    required bool tumorDetected,
    required double confidence,
    required double tumorArea,
    required Map<String, dynamic> probabilities,
    required Uint8List? predictionImageBytes,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: () async {
          try {
            await _generatePdfReport(
              patientDetails: patientDetails,
              tumorType: tumorType,
              tumorDetected: tumorDetected,
              confidence: confidence,
              tumorArea: tumorArea,
              probabilities: probabilities,
              predictionImageBytes: predictionImageBytes,
            );
          } catch (e, stackTrace) {
            debugPrint('PDF generation error: $e');
            debugPrintStack(stackTrace: stackTrace);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PDF report could not be generated.'),
                ),
              );
            }
          }
        },
        child: const Text(
          'Download Report',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // GENERATE PDF REPORT
  Future<void> _generatePdfReport({
    required Map<String, dynamic> patientDetails,
    required String tumorType,
    required bool tumorDetected,
    required double confidence,
    required double tumorArea,
    required Map<String, dynamic> probabilities,
    required Uint8List? predictionImageBytes,
  }) async {
    Uint8List? originalImageBytes;

    if (kIsWeb) {
      originalImageBytes = mriImageBytes;
    } else if (mriImage != null) {
      originalImageBytes = await mriImage!.readAsBytes();
    }

    final pdf = pw.Document();

    final pw.MemoryImage? originalPdfImage = originalImageBytes == null
        ? null
        : pw.MemoryImage(originalImageBytes);

    final pw.MemoryImage? predictionPdfImage = predictionImageBytes == null
        ? null
        : pw.MemoryImage(predictionImageBytes);

    final String patientName =
        patientDetails['name']?.toString().trim().isNotEmpty == true
        ? patientDetails['name'].toString()
        : 'Not available';

    final String patientAge =
        patientDetails['age']?.toString() ?? 'Not available';

    final String patientGender =
        patientDetails['gender']?.toString() ?? 'Not available';

    final String scanDate =
        patientDetails['scanDate']?.toString() ?? 'Not available';

    final String status = tumorDetected
        ? 'Tumor Detected'
        : 'No Tumor Detected';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context pdfContext) {
          return [
            pw.Center(
              child: pw.Text(
                'NeuroScan AI',
                style: pw.TextStyle(
                  fontSize: 25,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF087E99),
                ),
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Center(
              child: pw.Text(
                'BRAIN MRI ANALYSIS REPORT',
                style: pw.TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  color: PdfColors.grey700,
                ),
              ),
            ),
            pw.SizedBox(height: 18),
            pw.Divider(),

            // PATIENT DETAILS
            pw.Text(
              'Patient Details',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            _pdfDetailRow('Patient Name', patientName),
            _pdfDetailRow('Age', patientAge),
            _pdfDetailRow('Gender', patientGender),
            _pdfDetailRow('MRI Scan Date', scanDate),
            _pdfDetailRow(
              'Report Generated',
              DateTime.now().toString().substring(0, 19),
            ),

            pw.SizedBox(height: 14),
            pw.Divider(),

            // AI ANALYSIS
            pw.Text(
              'AI Analysis Result',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            _pdfDetailRow('Detection Status', status),
            _pdfDetailRow('Classification', _formatLabel(tumorType)),
            _pdfDetailRow(
              'Model Prediction Score',
              '${confidence.toStringAsFixed(2)}%',
            ),
            _pdfDetailRow('Tumor Area', '${tumorArea.toStringAsFixed(2)}%'),

            pw.SizedBox(height: 14),
            pw.Divider(),

            // MRI IMAGES
            pw.Text(
              'MRI Image Comparison',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),

            if (originalPdfImage != null) ...[
              pw.Text(
                'Original MRI',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Image(
                  originalPdfImage,
                  height: 220,
                  fit: pw.BoxFit.contain,
                ),
              ),
              pw.SizedBox(height: 12),
            ] else
              pw.Text('Original MRI image is not available.'),

            if (predictionPdfImage != null) ...[
              pw.Text(
                'AI Prediction Visualization',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Image(
                  predictionPdfImage,
                  height: 220,
                  fit: pw.BoxFit.contain,
                ),
              ),
              pw.SizedBox(height: 12),
            ] else
              pw.Text('AI prediction image is not available.'),

            pw.Divider(),

            // CLASS PROBABILITIES
            pw.Text(
              'Class Probabilities',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),

            if (probabilities.isEmpty)
              pw.Text('Probability information is unavailable.')
            else
              ...probabilities.entries.map((entry) {
                final num numericValue = entry.value is num
                    ? entry.value as num
                    : num.tryParse(entry.value.toString()) ?? 0;

                return _pdfDetailRow(
                  _formatLabel(entry.key),
                  '${numericValue.toStringAsFixed(2)}%',
                );
              }),

            pw.SizedBox(height: 18),
            pw.Divider(),

            // DISCLAIMER
            pw.Text(
              'Important Disclaimer',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.red800,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'This report is generated by an AI-assisted system for '
              'informational and educational purposes only. It is not a '
              'definitive medical diagnosis and must not replace professional '
              'radiological assessment or advice from a qualified healthcare '
              'professional.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
            ),
            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.Text(
                'Generated by NeuroScan AI',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ];
        },
      ),
    );

    final Uint8List pdfBytes = await pdf.save();

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'NeuroScan_AI_Report.pdf',
    );
  }

  // PDF DETAIL ROW
  pw.Widget _pdfDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            flex: 3,
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  // ANALYZE ANOTHER MRI BUTTON
  Widget _buildAnalyzeButton(
    BuildContext context, {
    required Map<String, dynamic> patientDetails,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
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
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const MriUploadScreen(),
                settings: RouteSettings(arguments: patientDetails),
              ),
              (route) => route.isFirst,
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
            'Analyze Another MRI',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // FORMAT LABEL
  String _formatLabel(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

// FULL SCREEN IMAGE VIEWER
class FullScreenImageViewer extends StatelessWidget {
  final Uint8List imageBytes;
  final String title;

  const FullScreenImageViewer({
    super.key,
    required this.imageBytes,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ResultScreen.background,
      appBar: AppBar(
        backgroundColor: ResultScreen.cardColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close image',
          ),
        ],
      ),
      body: SizedBox.expand(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5,
          panEnabled: true,
          scaleEnabled: true,
          child: Center(
            child: Image.memory(
              imageBytes,
              fit: BoxFit.contain,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return const Text(
                  'Unable to load image',
                  style: TextStyle(color: Colors.white70),
                );
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Pinch to zoom • Drag to explore • Tap close to return',
            textAlign: TextAlign.center,
            style: TextStyle(color: ResultScreen.secondaryText, fontSize: 11),
          ),
        ),
      ),
    );
  }
}
