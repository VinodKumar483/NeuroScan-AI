import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiService {
  static const String baseUrl = 'https://curvy-sheath-consoling.ngrok-free.dev';

  static Future<Map<String, dynamic>> predictMRI(XFile image) async {
    try {
      debugPrint('MRI API: Preparing image...');

      // Read image bytes (Android + Chrome compatible)
      final Uint8List imageBytes = await image.readAsBytes();

      if (imageBytes.isEmpty) {
        throw Exception('Selected image is empty.');
      }

      debugPrint('MRI API: Image size = ${imageBytes.length} bytes');

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/predict'),
      );

      request.headers['ngrok-skip-browser-warning'] = 'true';

      // Attach image using bytes instead of file path
      request.files.add(
        http.MultipartFile.fromBytes('image', imageBytes, filename: image.name),
      );

      debugPrint('MRI API: Sending request...');

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 180),
      );

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('MRI API: HTTP Status = ${response.statusCode}');

      debugPrint('MRI API: Response = ${response.body}');

      // Decode JSON response
      final dynamic decodedData;

      try {
        decodedData = jsonDecode(response.body);
      } catch (_) {
        throw Exception(
          'Server returned an invalid response. '
          'Check Flask API and ngrok connection.',
        );
      }

      if (decodedData is! Map) {
        throw Exception('Invalid API response format.');
      }

      final Map<String, dynamic> data = Map<String, dynamic>.from(decodedData);

      // Check HTTP response
      if (response.statusCode != 200) {
        throw Exception(
          data['message']?.toString() ?? 'Server error: ${response.statusCode}',
        );
      }

      // Check API status
      if (data['status'] != 'success') {
        throw Exception(
          data['message']?.toString() ?? 'MRI prediction failed.',
        );
      }

      // Check prediction field
      debugPrint('MRI API: Tumor type = ${data['tumor_type']}');

      debugPrint('MRI API: Prediction keys = ${data.keys.toList()}');

      return data;
    } catch (e) {
      debugPrint('MRI API ERROR: $e');

      throw Exception('API Error: $e');
    }
  }

  // DECODE PREDICTION IMAGE
  static Uint8List decodePredictionImage(String base64Image) {
    return base64Decode(base64Image);
  }
}
