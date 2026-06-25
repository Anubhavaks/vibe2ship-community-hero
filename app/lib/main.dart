import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'api_service.dart';

void main() {
  runApp(MaterialApp(
    theme: ThemeData(
      primarySwatch: Colors.teal,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
    ),
    home: CommunityHeroScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class CommunityHeroScreen extends StatefulWidget {
  @override
  _CommunityHeroScreenState createState() => _CommunityHeroScreenState();
}

class _CommunityHeroScreenState extends State<CommunityHeroScreen> {
  File? _selectedMedia;
  bool _isVideo = false;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  
  bool _isQuestVerified = false;
  bool _isVerifyingQuest = false;
  
  final MapController _mapController = MapController();
  final _locationController = TextEditingController(text: "Near the main entry square, Sector 4");
  final CivicApiService _apiService = CivicApiService();
  final ImagePicker _picker = ImagePicker();

  // Simulated Global Data Platform Feed (Real-Time Tracking)
  final List<Map<String, dynamic>> _simulatedFeed = [
    {
      "id": "CIVIC-2026-102B",
      "title": "High-Voltage Insulation Decay - Sector 2",
      "category": "Electrical / Public Safety",
      "severity": 9,
      "status": "In Progress",
      "icon": Icons.bolt,
      "color": Colors.red
    },
    {
      "id": "CIVIC-2026-095C",
      "title": "Asphalt Sub-base Failure (Sinkhole) - Main Crossing",
      "category": "Potholes & Roads",
      "severity": 7,
      "status": "Resolved",
      "icon": Icons.add_road,
      "color": Colors.green
    },
    {
      "id": "CIVIC-2026-114F",
      "title": "Hydraulic Grid Valve Leakage - Sector 9 Block A",
      "category": "Water Infrastructure",
      "severity": 6,
      "status": "Reported",
      "icon": Icons.water_drop,
      "color": Colors.orange
    }
  ];

  Future<void> _pickMedia(ImageSource source, bool isVideoPick) async {
    XFile? pickedFile;
    if (isVideoPick) {
      pickedFile = await _picker.pickVideo(source: source);
    } else {
      pickedFile = await _picker.pickImage(source: source);
    }

    if (pickedFile != null) {
      setState(() {
        _selectedMedia = File(pickedFile!.path);
        _isVideo = isVideoPick;
        _analysisResult = null;
        _isQuestVerified = false;
      });
    }
  }

  Future<void> _analyzeWithCivicAgent() async {
    if (_selectedMedia == null) return;

    setState(() => _isAnalyzing = true);

    final result = await _apiService.submitReport(
      _selectedMedia!,
      _locationController.text,
    );

    setState(() {
      _analysisResult = result;
      _isAnalyzing = false;
    });

    if (result != null && result['analysis'] != null) {
      double lat = result['analysis']['latitude'] ?? 28.9846;
      double lng = result['analysis']['longitude'] ?? 77.7059;
      _mapController.move(LatLng(lat, lng), 15.5);
      
      // Inject newly generated AI telemetry automatically into the Tracking Feed layer
      _simulatedFeed.insert(0, {
        "id": result['issue_id'] ?? "CIVIC-894A",
        "title": result['analysis']['explanation'] ?? "Active Local Incident",
        "category": result['analysis']['category'] ?? "Civic Hazard",
        "severity": result['analysis']['severity'] ?? 5,
        "status": "Reported",
        "icon": Icons.analytics,
        "color": Colors.orange
      });
    }
  }

  Future<void> _simulateQuestVerification() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() => _isVerifyingQuest = true);
      
      String currentId = _analysisResult!['issue_id'] ?? "";
      await _apiService.verifyIssueViaQuest(currentId);
      
      setState(() {
        _isQuestVerified = true;
        _isVerifyingQuest = false;
        if (_simulatedFeed.isNotEmpty) {
          _simulatedFeed[0]["status"] = "Verified";
          _simulatedFeed[0]["color"] = Colors.blue;
        }
      });
      _showRewardDialog();
    }
  }

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
              Text("Telemetry verified via secondary crowdsourced photo verification loop.", style: TextStyle(color: Colors.grey[800])),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Wallet Credit Issued:", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green[900])),
                    Text("+${_analysisResult!['analysis']['reward_points'] ?? 150} PTS", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
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
    return DefaultTabController(
      length: 3, 
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🛡️ CivicHero AI Core'),
          backgroundColor: Colors.teal[700],
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.add_a_photo), text: "Report Hub"),
              Tab(icon: Icon(Icons.playlist_add_check_circle), text: "Live Tracker"),
              Tab(icon: Icon(Icons.bar_chart), text: "Impact Dash"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildReportHubTab(),
            _buildLiveTrackerTab(),
            _buildImpactDashboardTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildReportHubTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            child: Container(
              height: 180,
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
              child: _selectedMedia != null
                  ? Center(
                      child: _isVideo
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.video_file, size: 50, color: Colors.teal[700]),
                                const SizedBox(height: 8),
                                Text("Video Input Compressed: ${_selectedMedia!.path.split('/').last}", style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(_selectedMedia!, fit: BoxFit.cover, width: double.infinity),
                            ),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload, size: 40, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("Upload Image/Video Infrastructure Evidence", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickMedia(ImageSource.camera, false),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Photo"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickMedia(ImageSource.camera, true),
                  icon: const Icon(Icons.videocam),
                  label: const Text("Video"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickMedia(ImageSource.gallery, false),
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
              labelText: 'Hyperlocal Context String',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on, color: Colors.teal),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: (_selectedMedia == null || _isAnalyzing) ? null : _analyzeWithCivicAgent,
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
            
            if (_analysisResult!['duplicate_detection']['is_duplicate'] == true)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50], 
                  border: Border.all(color: Colors.amber.shade700), 
                  borderRadius: BorderRadius.circular(8)
                ),
                child: Row(
                  children: [
                    Icon(Icons.layers, color: Colors.amber[800]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Duplicate Alert: This issue matches an active case within 100m. Merged into Master Track ID: ${_analysisResult!['duplicate_detection']['master_issue']}",
                        style: TextStyle(color: Colors.amber[900], fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _analysisResult!['analysis']['category'], 
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: (_analysisResult!['analysis']['severity'] >= 7) ? Colors.red : Colors.orange, 
                            borderRadius: BorderRadius.circular(12)
                          ),
                          child: Text(
                            "Severity: ${_analysisResult!['analysis']['severity']}/10", 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
                          ),
                        )
                      ],
                    ),
                    const Divider(height: 24),
                    
                    Text("Assigned Department:", style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    const SizedBox(height: 2),
                    Text("🏛️ ${_analysisResult!['analysis']['department']}", style: TextStyle(color: Colors.teal[900], fontSize: 15, fontWeight: FontWeight.bold)),
                    
                    const SizedBox(height: 16),
                    Text("AI Diagnostic Confidence:", style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _analysisResult!['analysis']['confidence'] / 100,
                              backgroundColor: Colors.grey[200],
                              color: Colors.teal[600],
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text("${_analysisResult!['analysis']['confidence']}%", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    Text("Risk Summary:", style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(_analysisResult!['analysis']['risk_summary'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    
                    const SizedBox(height: 8),
                    Text("Explanation:", style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(_analysisResult!['analysis']['explanation'], style: TextStyle(color: Colors.grey[800], fontSize: 13, height: 1.3)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              "🗺️ ${_analysisResult!['analysis']['quest_title']}",
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 8),
            Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.shade100),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(
                      _analysisResult!['analysis']['latitude'] ?? 28.9846,
                      _analysisResult!['analysis']['longitude'] ?? 77.7059,
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
                            _analysisResult!['analysis']['latitude'] ?? 28.9846,
                            _analysisResult!['analysis']['longitude'] ?? 77.7059,
                          ),
                          color: _isQuestVerified ? Colors.green.withOpacity(0.15) : Colors.indigo.withOpacity(0.15),
                          borderStrokeWidth: 2,
                          borderColor: _isQuestVerified ? Colors.green : Colors.indigo,
                          useRadiusInMeter: true,
                          radius: (_analysisResult!['analysis']['radius_meters'] as num).toDouble(),
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            _analysisResult!['analysis']['latitude'] ?? 28.9846,
                            _analysisResult!['analysis']['longitude'] ?? 77.7059,
                          ),
                          width: 40,
                          height: 40,
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
              color: _isQuestVerified ? Colors.green[50] : Colors.amber[50],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Task: ${_analysisResult!['analysis']['quest_objective']}", style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      _isQuestVerified ? "Status: Verified & Tracked ✓" : "Reward Allocation: +50 Points", 
                      style: TextStyle(fontWeight: FontWeight.bold, color: _isQuestVerified ? Colors.green[800] : Colors.green, fontSize: 13)
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: (_isVerifyingQuest || _isQuestVerified) ? null : _simulateQuestVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isQuestVerified ? Colors.grey : Colors.indigo[700], 
                foregroundColor: Colors.white, 
                padding: const EdgeInsets.symmetric(vertical: 14)
              ),
              icon: _isVerifyingQuest 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : Icon(_isQuestVerified ? Icons.check_circle : Icons.camera_alt),
              label: Text(_isVerifyingQuest ? "Updating Transaction..." : _isQuestVerified ? "Quest Objective Cleared" : "Verify Objective (Snap Photo)"),
            ),
            const SizedBox(height: 24),
          ]
        ],
      ),
    );
  }

  Widget _buildLiveTrackerTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _simulatedFeed.length,
      itemBuilder: (context, index) {
        final item = _simulatedFeed[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal[50],
              child: Icon(item['icon'], color: Colors.teal[800]),
            ),
            title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text("Domain: ${item['category']}", style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 2),
                Text("Priority Level: ${item['severity']}/10", style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold, fontSize: 11)),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: item['color'].withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Text(
                item['status'],
                style: TextStyle(color: item['color'], fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImpactDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("📈 Municipal Impact Metrics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricCard("${_simulatedFeed.length + 140}", "Total Incidents logged", Icons.analytics, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard("1,842", "Quests Completed", Icons.stars, Colors.amber)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricCard("84.6%", "Resolution Rate", Icons.speed, Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard("4.2 hrs", "Avg Routing Velocity", Icons.bolt, Colors.purple)),
            ],
          ),
          const SizedBox(height: 24),
          const Text("🏆 Community Hero Leaderboard", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
          const SizedBox(height: 12),
          _buildLeaderboardRow(1, "Anubhav Kumar Singh", "4,850 PTS", true),
          _buildLeaderboardRow(2, "Rohan Sharma", "3,920 PTS", false),
          _buildLeaderboardRow(3, "Priya Verma", "3,410 PTS", false),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String value, String label, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardRow(int rank, String name, String points, bool isUser) {
    return Card(
      color: isUser ? Colors.teal[50] : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Text("#$rank", style: TextStyle(fontWeight: FontWeight.bold, color: rank == 1 ? Colors.amber[800] : Colors.grey)),
        title: Text(name, style: TextStyle(fontWeight: isUser ? FontWeight.bold : FontWeight.normal)),
        trailing: Text(points, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
      ),
    );
  }
}