import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class StorageService {
  // If rzw01w9m is your Cloud Name, keep it here.
  // If rzw01w9m is your Upload Preset, swap these two values!
  final String cloudName = 'rzw01w9m'; 
  final String uploadPreset = 'ml_default1'; // You need an unsigned upload preset!

  /// Uploads a product image file to Cloudinary and returns its secure URL.
  Future<String> uploadProductImage(File file) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);
        
        // Return the secure URL provided by Cloudinary
        return jsonResponse['secure_url'];
      } else {
        final error = await response.stream.bytesToString();
        throw Exception('Failed to upload image. Status code: ${response.statusCode}, Error: $error');
      }
    } catch (e) {
      throw Exception('Failed to upload image to Cloudinary: ${e.toString()}');
    }
  }
}
