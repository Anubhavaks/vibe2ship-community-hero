import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'api_service.dart';

void main() {
  runApp(MaterialApp(
    theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
    home: CommunityHeroScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class CommunityHeroScreen extends StatefulWidget {
  @override
  _CommunityHeroScreenState createState() => _CommunityHeroScreenState();
}

class _CommunityHeroScreenState extends State<CommunityHeroScreen> {
  File? _selectedImage;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  
  // NEW: State variables for the gamification loop
  bool _isQuestVerified = false;
  bool _isVerifyingQuest = false;
  
  final MapController _mapController = MapController();
  final _locationController = TextEditingController(text: "Near the main entry square, Sector 4");
  final CivicApiService _apiService = CivicApiService();
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _analysisResult = null;
        _isQuestVerified = false; // Reset verification state on new image
      });
    }
  }

  Future<void> _analyzeWithCivicAgent() async {
    if (_selectedImage == null) return;

    setState(() => _isAnalyzing = true);

    final result = await _apiService.submitReport(
      _selectedImage!,
      _locationController.text,
    );

    setState(() {
      _analysisResult = result;
      _isAnalyzing = false;
    });

    if (result != null && result['gamified_quest'] != null) {
      double lat = result['gamified_quest']['latitude'] ?? 28.9846;
      double lng = result['gamified_quest']['longitude'] ?? 77.7059;
      _mapController.move(LatLng(lat, lng), 15.5);
    }
  }

  // NEW: Method to simulate a citizen verifying the quest
  Future<void> _simulateQuestVerification() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    
    if (pickedFile != null) {
      setState(() => _isVerifyingQuest = true);
      
      // Simulate AI cross-referencing the new photo (looks great in a demo)
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isQuestVerified = true;
        _isVerifyingQuest = false;
      });

      _showRewardDialog();
    }
  }

  // NEW: The Wallet Credit Reward Popup
  void _showRewardDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.stars, color: Colors.amber, size: 28),
              SizedBox(width: 8),
              Text("Quest Verified!"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Telemetry confirmed via secondary geotagged photo submission.",
                style: TextStyle(color: Colors.grey[800]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Wallet Credit Issued:",
                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green[900]),
                    ),
                    Text(
                      "+${_analysisResult!['gamified_quest']['reward_points']} PTS",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Claim Rewards", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛡️ CivicAgent Core Map'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 40, color: Colors.grey[600]),
                          const SizedBox(height: 10),
                          const Text("Upload Infrastructure Incident Evidence", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Camera"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Gallery"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Hyperlocal Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on, color: Colors.teal),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: (_selectedImage == null || _isAnalyzing) ? null : _analyzeWithCivicAgent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isAnalyzing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Deploy Autonomous AI Evaluation", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),

            if (_analysisResult != null) ...[
              const SizedBox(height: 20),
              const Divider(thickness: 2),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(_analysisResult!['category'] ?? "Civic Hazard"),
                    backgroundColor: Colors.teal[50],
                  ),
                  Text(
                    "Severity: ${_analysisResult!['severity_score']}/10",
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: (_analysisResult!['severity_score'] ?? 5) >= 7 ? Colors.red[700] : Colors.orange[700]
                    ),
                  )
                ],
              ),
              const SizedBox(height: 8),

              Text(
                _analysisResult!['public_tracker']['title'] ?? "",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _analysisResult!['public_tracker']['rationale'] ?? "",
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
              const SizedBox(height: 16),

              Text(
                "🗺️ ${_analysisResult!['gamified_quest']['quest_title'] ?? 'Verification Quest Location'}",
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              const SizedBox(height: 8),
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo[100]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(
                        _analysisResult!['gamified_quest']['latitude'] ?? 28.9846,
                        _analysisResult!['gamified_quest']['longitude'] ?? 77.7059,
                      ),
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.vibe2ship.communityhero',
                      ),
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: LatLng(
                              _analysisResult!['gamified_quest']['latitude'] ?? 28.9846,
                              _analysisResult!['gamified_quest']['longitude'] ?? 77.7059,
                            ),
                            // NEW: Map circle turns green when verified
                            color: _isQuestVerified ? Colors.green.withOpacity(0.2) : Colors.indigo.withOpacity(0.2),
                            borderStrokeWidth: 2,
                            borderColor: _isQuestVerified ? Colors.green : Colors.indigo,
                            useRadiusInMeter: true,
                            radius: (_analysisResult!['gamified_quest']['radius_meters'] as num).toDouble(),
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              _analysisResult!['gamified_quest']['latitude'] ?? 28.9846,
                              _analysisResult!['gamified_quest']['longitude'] ?? 77.7059,
                            ),
                            width: 40,
                            height: 40,
                            // NEW: Map marker turns green when verified
                            child: Icon(Icons.location_on, color: _isQuestVerified ? Colors.green : Colors.red, size: 40),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Card(
                // NEW: Card turns green when verified
                color: _isQuestVerified ? Colors.green[50] : Colors.amber[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Task: ${_analysisResult!['gamified_quest']['objective']}", style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(
                        _isQuestVerified ? "Status: Quest Completed Successfully ✓" : "Reward Allocation: +${_analysisResult!['gamified_quest']['reward_points']} Points", 
                        style: TextStyle(fontWeight: FontWeight.bold, color: _isQuestVerified ? Colors.green[800] : Colors.green)
                      ),
                    ],
                  ),
                ),
              ),
              
              // NEW: The Verification Button!
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: (_isVerifyingQuest || _isQuestVerified) ? null : _simulateQuestVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isQuestVerified ? Colors.grey : Colors.indigo[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: _isVerifyingQuest 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(_isQuestVerified ? Icons.check_circle : Icons.camera_alt),
                label: Text(
                  _isVerifyingQuest 
                      ? "Analyzing Telemetry..." 
                      : _isQuestVerified ? "Quest Objective Cleared" : "Verify Objective (Snap Photo)",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
            ]
          ],
        ),
      ),
    );
  }
}