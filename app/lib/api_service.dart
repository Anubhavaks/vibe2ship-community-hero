import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CivicApiService {
  // 10.0.2.2 is a special IP that lets the Android Emulator talk to your laptop's localhost (127.0.0.1)
  final String baseUrl = "http://10.0.2.2:8000"; 

  Future<Map<String, dynamic>?> submitReport(File imageFile, String locationRaw) async {
    final url = Uri.parse('$baseUrl/api/v1/report');
    
    // Create a multipart request to handle files and text data simultaneously
    var request = http.MultipartRequest('POST', url);

    // Attach the text input
    request.fields['raw_location'] = locationRaw;

    // Attach the image file
    var multipartFile = await http.MultipartFile.fromPath(
      'image', 
      imageFile.path,
    );
    request.files.add(multipartFile);

    try {
      print("Sending payload to CivicAgent Core...");
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // The backend returns a stringified JSON schema from Gemini.
        // We decode it twice because it's double-serialized by response.text.
        final String rawString = jsonDecode(response.body);
        return jsonDecode(rawString) as Map<String, dynamic>;
      } else {
        print("Backend Error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Network Error talking to backend: $e");
      return null;
    }
  }
}