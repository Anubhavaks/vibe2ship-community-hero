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
  
  // 1. Replaced GoogleMapController with the free MapController
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

    // 2. Updated the camera animation logic for OpenStreetMap
    if (result != null && result['gamified_quest'] != null) {
      double lat = result['gamified_quest']['latitude'] ?? 28.9846;
      double lng = result['gamified_quest']['longitude'] ?? 77.7059;
      // Tell the map to jump to the new coordinates
      _mapController.move(LatLng(lat, lng), 15.5);
    }
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
            // IMAGE VIEW
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

              // 3. The fully updated OpenStreetMap widget
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
                    mapController: _mapController, // Attach the controller
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
                        userAgentPackageName: 'com.vibe2ship.communityhero', // Good practice for OSM
                      ),
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: LatLng(
                              _analysisResult!['gamified_quest']['latitude'] ?? 28.9846,
                              _analysisResult!['gamified_quest']['longitude'] ?? 77.7059,
                            ),
                            color: Colors.indigo.withOpacity(0.2),
                            borderStrokeWidth: 2,
                            borderColor: Colors.indigo,
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
                            child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Card(
                color: Colors.amber[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Task: ${_analysisResult!['gamified_quest']['objective']}", style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text("Reward Allocation: +${_analysisResult!['gamified_quest']['reward_points']} Points", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}