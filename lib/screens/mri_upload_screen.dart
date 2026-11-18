import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart' as camera;
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/prediction_store.dart';
import '../database/database_helper.dart';
import 'home_screen.dart';
import 'result_screen.dart';

class MriUploadScreen extends StatefulWidget {
  const MriUploadScreen({super.key});

  @override
  State<MriUploadScreen> createState() => _MriUploadScreenState();
}

class _MriUploadScreenState extends State<MriUploadScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker picker = ImagePicker();

  File? selectedImage;
  XFile? selectedXFile;
  Uint8List? selectedImageBytes;

  Map<String, dynamic> patientDetails = {};
  bool _patientDetailsLoaded = false;

  bool isPickingImage = false;
  ImageSource? pickingImageSource;
  bool isAnalyzing = false;

  late final AnimationController _scannerController;

  @override
  void initState() {
    super.initState();

    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_patientDetailsLoaded) {
      final arguments = ModalRoute.of(context)?.settings.arguments;

      if (arguments is Map) {
        patientDetails = Map<String, dynamic>.from(arguments);
      }

      _patientDetailsLoaded = true;
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  // COMPRESS IMAGE ONLY FOR SCAN HISTORY
  Future<Uint8List> compressHistoryImage(Uint8List originalBytes) async {
    final decoded = img.decodeImage(originalBytes);

    if (decoded == null) {
      throw Exception('Unable to decode MRI image.');
    }

    final longestSide = decoded.width > decoded.height
        ? decoded.width
        : decoded.height;

    img.Image resized = decoded;

    // Resize only if image is larger than 1600 pixels.
    if (longestSide > 1600) {
      final ratio = 1600 / longestSide;

      resized = img.copyResize(
        decoded,
        width: (decoded.width * ratio).round(),
        height: (decoded.height * ratio).round(),
      );
    }

    // Compress as JPEG for smaller History storage.
    final compressed = img.encodeJpg(resized, quality: 82);

    debugPrint(
      'Original image: '
      '${(originalBytes.length / 1024 / 1024).toStringAsFixed(2)} MB',
    );

    debugPrint(
      'History image: '
      '${(compressed.length / 1024 / 1024).toStringAsFixed(2)} MB',
    );

    return Uint8List.fromList(compressed);
  }

  String getPredictionLabel(Map<String, dynamic> data) {
    final possibleKeys = [
      'tumor_type',
      'argmax_type',
      'predicted_class',
      'class_name',
      'prediction',
    ];

    for (final key in possibleKeys) {
      final value = data[key]?.toString().trim();

      if (value != null &&
          value.isNotEmpty &&
          value.toLowerCase() != 'unknown' &&
          value.toLowerCase() != 'null') {
        return value;
      }
    }

    return 'Unknown';
  }

  // PICK MRI IMAGE
  Future<void> pickMRIImage(ImageSource source) async {
    try {
      setState(() {
        isPickingImage = true;
        pickingImageSource = source;
      });

      final XFile? image = kIsWeb && source == ImageSource.camera
          ? await showDialog<XFile>(
              context: context,
              barrierDismissible: false,
              builder: (_) => const _WebCameraCaptureDialog(),
            )
          : await picker.pickImage(source: source, imageQuality: 90);

      if (!mounted) return;

      if (image != null) {
        final bytes = await image.readAsBytes();

        setState(() {
          selectedXFile = image;
          selectedImageBytes = bytes;
          selectedImage = kIsWeb ? null : File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Image Picker Error: $e');

      if (mounted) {
        showMessage('Unable to select image. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          isPickingImage = false;
          pickingImageSource = null;
        });
      }
    }
  }

  // REMOVE SELECTED IMAGE
  void removeImage() {
    setState(() {
      selectedImage = null;
      selectedXFile = null;
      selectedImageBytes = null;
    });
  }

  // SHOW MESSAGE
  void showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          content: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  // ANALYZE MRI AND SAVE RESULT
  Future<void> analyzeMRI() async {
    if (selectedXFile == null || selectedImageBytes == null) {
      showMessage('Please select an MRI image first.');
      return;
    }

    setState(() {
      isAnalyzing = true;
    });

    _scannerController.repeat();

    try {
      // STEP 1: SEND ORIGINAL MRI TO AI API
      final predictionData = await ApiService.predictMRI(selectedXFile!);

      if (!mounted) return;

      // STEP 2: GET LOGGED-IN USER ID
      final prefs = await SharedPreferences.getInstance();

      final userId = prefs.getInt('current_user_id');

      if (userId == null) {
        throw Exception('User session not found. Please login again.');
      }

      // STEP 3: COMPRESS IMAGE FOR HISTORY
      final historyImageBytes = await compressHistoryImage(selectedImageBytes!);

      // STEP 4: SAVE COMPRESSED IMAGE
      File? savedImage;
      String savedImagePath;

      if (kIsWeb) {
        savedImagePath = 'scan_${DateTime.now().microsecondsSinceEpoch}.jpg';
      } else {
        final directory = await getApplicationDocumentsDirectory();

        final destinationPath =
            '${directory.path}/scan_${DateTime.now().microsecondsSinceEpoch}.jpg';

        savedImage = await File(
          destinationPath,
        ).writeAsBytes(historyImageBytes, flush: true);

        savedImagePath = savedImage.path;
      }

      // STEP 5: GET PREDICTION NAME
      final prediction = getPredictionLabel(predictionData);

      // STEP 6: GET CONFIDENCE
      final confidence =
          ((predictionData['tumor_probability'] as num?)?.toDouble() ?? 0.0) *
          100;

      // STEP 7: GET CLASS PROBABILITIES
      String? probabilities;

      if (predictionData['probabilities_pct'] != null) {
        probabilities = jsonEncode(predictionData['probabilities_pct']);
      }

      // STEP 8: CONVERT RESPONSE TO JSON
      final predictionJson = jsonEncode(predictionData);

      // STEP 9: SAVE COMPRESSED IMAGE IN SQLITE
      await DatabaseHelper.instance.insertScanHistory(
        userId: userId,
        imagePath: savedImagePath,
        prediction: prediction,
        confidence: confidence,
        probabilities: probabilities,
        predictionData: predictionJson,
        patientDetails: jsonEncode(patientDetails),
        imageData: kIsWeb ? historyImageBytes : null,
      );

      if (!mounted) return;

      // STEP 10: STORE LATEST PREDICTION
      PredictionStore.latestImage = savedImage;

      PredictionStore.latestPredictionData = Map<String, dynamic>.from(
        predictionData,
      );

      // STEP 11: STOP SCANNER
      _scannerController.stop();
      _scannerController.reset();

      setState(() {
        isAnalyzing = false;
      });

      // STEP 12: OPEN RESULT SCREEN
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            mriImage: savedImage,

            // Original image bytes for current result screen.
            mriImageBytes: selectedImageBytes,

            predictionData: predictionData,
            patientDetails: patientDetails,
          ),
          settings: RouteSettings(arguments: patientDetails),
        ),
      );
    } catch (e) {
      debugPrint('MRI Analysis Error: $e');

      if (mounted) {
        showMessage('Analysis failed. Please try again.');
      }
    } finally {
      _scannerController.stop();
      _scannerController.reset();

      if (mounted && isAnalyzing) {
        setState(() {
          isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  _headerButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Image.asset(
                    'assets/images/brain_logo.png',
                    height: 42,
                    width: 42,
                    fit: BoxFit.contain,
                    errorBuilder: _imageError,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NeuroScan AI',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'MRI Scan Analysis',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  _headerButton(
                    icon: Icons.home_outlined,
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white12, height: 1),

            // MAIN CONTENT
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),

                    // UPLOAD CARD
                    _glassCard(
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/brain_logo.png',
                            height: 90,
                            errorBuilder: _imageError,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Upload MRI Image',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 22),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: isPickingImage || isAnalyzing
                                      ? null
                                      : () => pickMRIImage(ImageSource.gallery),
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Gallery'),
                                  style: _sourceButtonStyle(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: isPickingImage || isAnalyzing
                                      ? null
                                      : () => pickMRIImage(ImageSource.camera),
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Camera'),
                                  style: _sourceButtonStyle(),
                                ),
                              ),
                            ],
                          ),

                          if (isPickingImage) ...[
                            const SizedBox(height: 16),
                            const CircularProgressIndicator(),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // SELECTED IMAGE PREVIEW
                    _glassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selected MRI Image',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),

                          if (selectedImageBytes != null)
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 260,
                                    child: kIsWeb
                                        ? Image.memory(
                                            selectedImageBytes!,
                                            fit: BoxFit.contain,
                                            errorBuilder: _imageError,
                                          )
                                        : Image.file(
                                            File(selectedImage!.path),
                                            fit: BoxFit.contain,
                                            errorBuilder: _imageError,
                                          ),
                                  ),
                                ),

                                if (isAnalyzing)
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        color: Colors.black.withValues(
                                          alpha: 0.35,
                                        ),
                                        child: AnimatedBuilder(
                                          animation: _scannerController,
                                          builder: (context, child) {
                                            return Align(
                                              alignment: Alignment(
                                                0,
                                                -1 +
                                                    (_scannerController.value *
                                                        2),
                                              ),
                                              child: Container(
                                                height: 3,
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  color: Colors.cyanAccent,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.cyanAccent
                                                          .withValues(
                                                            alpha: 0.8,
                                                          ),
                                                      blurRadius: 12,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),

                                if (!isAnalyzing)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      onPressed: removeImage,
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.black
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          else
                            Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_outlined,
                                    size: 48,
                                    color: Colors.white38,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'No MRI image selected',
                                    style: TextStyle(color: Colors.white60),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ANALYZE BUTTON
                    SizedBox(
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              HomeScreen.primary.withValues(alpha: 0.82),
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
                              color: HomeScreen.primary.withValues(alpha: 0.25),
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
                          onPressed:
                              selectedImageBytes == null ||
                                  isAnalyzing ||
                                  isPickingImage
                              ? null
                              : analyzeMRI,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            disabledBackgroundColor: Colors.transparent,
                            disabledForegroundColor: Colors.white,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17),
                            ),
                          ),
                          child: isAnalyzing
                              ? const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Analyzing MRI...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Analyze MRI',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                          ),
                        ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _sourceButtonStyle() => OutlinedButton.styleFrom(
    foregroundColor: HomeScreen.primary,
    side: BorderSide(color: HomeScreen.primary.withValues(alpha: 0.42)),
    backgroundColor: HomeScreen.primary.withValues(alpha: 0.07),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
  );

  // IMAGE ERROR WIDGET
  Widget _imageError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return const Center(
      child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 40),
    );
  }

  // HEADER BUTTON
  Widget _headerButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 21),
      ),
    );
  }

  // GLASS CARD
  Widget _glassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }
}

// ======================================================
// WEB CAMERA CAPTURE DIALOG
// ======================================================

class _WebCameraCaptureDialog extends StatefulWidget {
  const _WebCameraCaptureDialog();

  @override
  State<_WebCameraCaptureDialog> createState() =>
      _WebCameraCaptureDialogState();
}

class _WebCameraCaptureDialogState extends State<_WebCameraCaptureDialog> {
  camera.CameraController? controller;
  bool isInitializing = true;
  String? cameraError;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    try {
      final cameras = await camera.availableCameras();

      if (cameras.isEmpty) {
        throw Exception('No camera found.');
      }

      final selectedCamera = cameras.firstWhere(
        (c) => c.lensDirection == camera.CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      controller = camera.CameraController(
        selectedCamera,
        camera.ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller!.initialize();

      if (!mounted) return;

      setState(() {
        isInitializing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cameraError = e.toString();
        isInitializing = false;
      });
    }
  }

  Future<void> captureImage() async {
    if (controller == null || !controller!.value.isInitialized) {
      return;
    }

    try {
      final image = await controller!.takePicture();

      if (!mounted) return;

      Navigator.pop(context, image);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cameraError = 'Unable to capture image: $e';
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      title: const Text(
        'Capture MRI Image',
        style: TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 400,
        child: isInitializing
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            : cameraError != null
            ? Text(
                cameraError!,
                style: const TextStyle(color: Colors.redAccent),
              )
            : controller != null && controller!.value.isInitialized
            ? AspectRatio(
                aspectRatio: controller!.value.aspectRatio,
                child: camera.CameraPreview(controller!),
              )
            : const Text(
                'Camera is not available.',
                style: TextStyle(color: Colors.white),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: isInitializing || cameraError != null || controller == null
              ? null
              : captureImage,
          icon: const Icon(Icons.camera_alt),
          label: const Text('Capture'),
        ),
      ],
    );
  }
}
