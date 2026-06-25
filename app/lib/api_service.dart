import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CivicApiService {
  // 10.0.2.2 points to your laptop's localhost from the Android Emulator
  final String baseUrl = "http://10.0.2.2:8000"; 

  // 1. Live Submit & Duplicate Engine Handshake
  Future<Map<String, dynamic>?> submitReport(File mediaFile, String locationRaw) async {
    final url = Uri.parse('$baseUrl/api/v1/report');
    var request = http.MultipartRequest('POST', url);

    request.fields['raw_location'] = locationRaw;
    var multipartFile = await http.MultipartFile.fromPath(
      'image', 
      mediaFile.path,
    );
    request.files.add(multipartFile);

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Raw stringified JSON schema returned by FastAPI
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print("Backend Error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Network Error reporting incident: $e");
      return null;
    }
  }

  // 2. Real-Time Verification Action Write Loop
  Future<bool> verifyIssueViaQuest(String issueId) async {
    final url = Uri.parse('$baseUrl/api/v1/verify/$issueId');
    
    try {
      final response = await http.post(url);
      return response.statusCode == 200;
    } catch (e) {
      print("Network Error checking verification status: $e");
      return false;
    }
  }

  // 3. Live Dashboard Stats & Tracking Feed Sync Ingestion
  Future<Map<String, dynamic>?> fetchLiveDashboardData() async {
    final url = Uri.parse('$baseUrl/api/v1/dashboard');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("Network Error reading platform stats: $e");
      return null;
    }
  }
}