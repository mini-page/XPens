import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:http/http.dart' as http;

// ── Result ────────────────────────────────────────────────────────────────────

/// Fields extracted from an AI product-identification response.
class ProductScanResult {
  const ProductScanResult({
    required this.name,
    this.category,
    this.price,
  });

  /// Product / item name (always non-empty on success).
  final String name;

  /// Best-guess expense category (e.g. "Groceries", "Electronics").
  final String? category;

  /// Estimated price in the user's local currency, if visible in the image.
  final double? price;
}

// ── Error ─────────────────────────────────────────────────────────────────────

enum AiProductError { noNetwork, unrecognised, apiError }

class AiProductException implements Exception {
  const AiProductException(this.error);

  final AiProductError error;

  String get message {
    switch (error) {
      case AiProductError.noNetwork:
        return 'No internet connection. Please check your network and try again.';
      case AiProductError.unrecognised:
        return "Couldn't identify this product. Try a clearer, closer photo.";
      case AiProductError.apiError:
        return 'AI service error. Verify your API key in Settings → AI Features.';
    }
  }
}

// ── Service ───────────────────────────────────────────────────────────────────

/// Sends a product image (and an optional barcode hint) to the Gemini Vision
/// API and parses the structured response into a [ProductScanResult].
///
/// Throws [AiProductException] on every failure path so callers can map the
/// typed error to a user-friendly message.
class AiProductService {
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  static const _timeout = Duration(seconds: 15);

  /// Identifies a product from an image file on disk.
  ///
  /// - [imagePath]  Absolute path to a JPEG/PNG image file.
  /// - [apiKey]     Gemini API key from [AppPreferencesModel.aiApiKey].
  /// - [modelId]    Gemini model identifier (e.g. `'gemini-2.0-flash'`).
  /// - [barcodeHint] Raw barcode/QR value detected in the same image, if any.
  static Future<ProductScanResult> identifyProduct({
    required String imagePath,
    required String apiKey,
    required String modelId,
    String? barcodeHint,
  }) async {
    // ── Build prompt ────────────────────────────────────────────────────────
    final barcodeClue = barcodeHint != null && barcodeHint.isNotEmpty
        ? ' The barcode/QR value detected in the image is: "$barcodeHint".'
        : '';

    final prompt =
        'This is a product or receipt photo.$barcodeClue '
        'Extract: product name, the best matching expense category from this list '
        '(Groceries, Food & Dining, Shopping, Electronics, Health, Transport, '
        'Entertainment, Bills & Utilities, Education, Other), '
        'and the price in the local currency if clearly visible. '
        'Respond ONLY with a compact JSON object — no markdown, no extra text:\n'
        '{"name":"<product name>","category":"<category>","price":<number or null>}';

    // ── Read image ──────────────────────────────────────────────────────────
    final Uint8List imageBytes;
    try {
      imageBytes = await File(imagePath).readAsBytes();
    } catch (_) {
      throw const AiProductException(AiProductError.unrecognised);
    }

    final extension = imagePath.split('.').last.toLowerCase();
    final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';

    // ── Build request body ──────────────────────────────────────────────────
    final body = jsonEncode(<String, dynamic>{
      'contents': <Map<String, dynamic>>[
        {
          'parts': <Map<String, dynamic>>[
            {
              'inlineData': {
                'mimeType': mimeType,
                'data': base64Encode(imageBytes),
              },
            },
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': <String, dynamic>{
        'temperature': 0.1,
        'maxOutputTokens': 256,
      },
    });

    final uri = Uri.parse('$_baseUrl/$modelId:generateContent?key=$apiKey');

    // ── HTTP call ───────────────────────────────────────────────────────────
    try {
      final response = await http
          .post(
            uri,
            headers: <String, String>{'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return _parseResponse(response.body);
      }

      // 400 / 403 typically means bad API key or model not available.
      if (response.statusCode == 400 || response.statusCode == 403) {
        throw const AiProductException(AiProductError.apiError);
      }

      throw const AiProductException(AiProductError.unrecognised);
    } on AiProductException {
      rethrow;
    } on SocketException {
      throw const AiProductException(AiProductError.noNetwork);
    } on TimeoutException {
      throw const AiProductException(AiProductError.noNetwork);
    } catch (e, st) {
      assert(() {
        dev.log('AiProductService.identifyProduct failed: $e', stackTrace: st);
        return true;
      }());
      throw const AiProductException(AiProductError.unrecognised);
    }
  }

  // ── Response parser ────────────────────────────────────────────────────────

  static ProductScanResult _parseResponse(String responseBody) {
    try {
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw const AiProductException(AiProductError.unrecognised);
      }

      final content =
          (candidates.first as Map<String, dynamic>)['content']
              as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      final text = (parts?.first as Map<String, dynamic>?)?['text'] as String?;

      if (text == null || text.trim().isEmpty) {
        throw const AiProductException(AiProductError.unrecognised);
      }

      // Extract the first JSON object from the text (handles markdown fences).
      final jsonMatch = RegExp(r'\{[^{}]+\}').firstMatch(text);
      if (jsonMatch == null) {
        throw const AiProductException(AiProductError.unrecognised);
      }

      final parsed =
          jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;

      final name = (parsed['name'] as String? ?? '').trim();
      if (name.isEmpty) {
        throw const AiProductException(AiProductError.unrecognised);
      }

      final category = parsed['category'] as String?;

      double? price;
      final priceRaw = parsed['price'];
      if (priceRaw is num) {
        price = priceRaw.toDouble();
      } else if (priceRaw is String) {
        price = double.tryParse(priceRaw);
      }

      return ProductScanResult(name: name, category: category, price: price);
    } on AiProductException {
      rethrow;
    } catch (_) {
      throw const AiProductException(AiProductError.unrecognised);
    }
  }
}
