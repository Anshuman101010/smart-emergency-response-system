import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: EmergencyScreen(),
    );
  }
}

class EmergencyScreen extends StatefulWidget {
  @override
  _EmergencyScreenState createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  String status = "SAFE";
  String message = "No active alerts";
  String location = "-";
  bool isConnected = false;

  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    connectSocket();
  }

  void connectSocket() {
    try {
      // Fixed Socket.IO configuration - use proper OptionBuilder syntax
      socket = IO.io(
        "http://localhost:5000",
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .build(),
      );

      socket.onConnect((_) {
        print("✅ Connected to backend");
        setState(() {
          isConnected = true;
        });
      });

      socket.onDisconnect((_) {
        print("❌ Disconnected from backend");
        setState(() {
          isConnected = false;
        });
      });

      socket.on("emergency-update", (data) {
        print("📡 Received emergency update: $data");
        setState(() {
          status = data["status"] ?? "UNKNOWN";
          message = data["message"] ?? "No message";
          location = data["location"] ?? "-";
        });

        // Show alert popup
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("🚨 EMERGENCY ALERT"),
            content: Text("${data["message"]}\nLocation: ${data["location"]}"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          ),
        );
      });

      socket.onError((error) {
        print("⚠️ Socket Error: $error");
      });

      socket.connect();
    } catch (e) {
      print("❌ Socket connection error: $e");
    }
  }

  Future<void> sendEmergency(String emergencyType) async {
    try {
      final uri = Uri.parse("http://localhost:5000/report-emergency");
      final payload = {
        "type": emergencyType,
        "message": "Emergency Alert: $emergencyType",
        "location": "Room 101",
        "timestamp": DateTime.now().toIso8601String(),
      };

      print("📤 Sending emergency: $payload");

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw "Request timeout",
      );

      if (response.statusCode == 200) {
        print("✅ Emergency reported successfully");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ $emergencyType reported!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print("❌ Failed to report emergency: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Failed to report emergency"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("❌ Error sending emergency: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildEmergencyButton(String title, Color color, String type) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: () => sendEmergency(type),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: status == "Active" ? Colors.red[50] : Colors.blue[50],
      appBar: AppBar(
        title: Text("Emergency Response System"),
        backgroundColor: Colors.black,
        elevation: 5,
        actions: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Row(
                children: [
                  Icon(
                    isConnected ? Icons.cloud_done : Icons.cloud_off,
                    color: isConnected ? Colors.green : Colors.red,
                  ),
                  SizedBox(width: 8),
                  Text(
                    isConnected ? "Connected" : "Disconnected",
                    style: TextStyle(
                      color: isConnected ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            
            // Status Section
            Container(
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    status == "Active" ? Icons.warning : Icons.check_circle,
                    size: 80,
                    color: status == "Active" ? Colors.red : Colors.green,
                  ),
                  SizedBox(height: 15),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: status == "Active" ? Colors.red : Colors.green,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Message: $message",
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Location: $location",
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Emergency Types Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Select Emergency Type",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(height: 15),

            // Emergency Buttons Grid
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Row 1: Fire, Medical, Police
                  Row(
                    children: [
                      buildEmergencyButton("🔥\nFire", Colors.orange[700]!, "FIRE"),
                      buildEmergencyButton("🏥\nMedical\nEmergency", Colors.red[700]!, "MEDICAL"),
                      buildEmergencyButton("🚔\nPolice\nEmergency", Colors.blue[700]!, "POLICE"),
                    ],
                  ),

                  SizedBox(height: 10),

                  // Row 2: Staff Assist, Other
                  Row(
                    children: [
                      buildEmergencyButton("👥\nStaff\nAssist", Colors.purple[700]!, "STAFF_ASSIST"),
                      buildEmergencyButton("⚠️\nOther\nEmergency", Colors.amber[900]!, "OTHER"),
                      Expanded(
                        child: SizedBox(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Manual Entry Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: () {
                  // Show connection status
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isConnected
                            ? "✅ Connected to backend"
                            : "❌ Not connected to backend",
                      ),
                      backgroundColor: isConnected ? Colors.green : Colors.red,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  padding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Check Connection Status",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}