import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Uploads audio files directly to Cloudinary using the app's existing
/// UNSIGNED upload preset (divine_increase_featured). Unsigned uploads
/// don't need an API secret in the app, which is what makes this safe to
/// do straight from the client.
class CloudinaryService {
  static const _cloudName = 'bvhy7swc';
  static const _uploadPreset = 'divine_increase_featured';

  /// Uploads an audio file and returns its secure URL, or null on failure.
  static Future<String?> uploadAudio(File file) => _upload(file, resourceType: 'video');

  /// Uploads an image file and returns its secure URL, or null on failure.
  static Future<String?> uploadImage(File file) => _upload(file, resourceType: 'image');

  static Future<String?> _upload(File file, {required String resourceType}) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    if (response.statusCode != 200) return null;
    final body = await response.stream.bytesToString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    return data['secure_url'] as String?;
  }
}
