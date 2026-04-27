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
      home: EmergencyScreen(),
    );
  }
}

class EmergencyScreen extends StatefulWidget {
  @override
  _EmergencyScreenState createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  String status = "Resolved";
  String message = "";
  String location = "";

  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    connectSocket();
  }

  void connectSocket() {
    socket = IO.io("http://192.168.0.103", <String, dynamic>{
      "transports": ["websocket"],
    });

    socket.onConnect((_) {
      print("Connected to server");
    });

    socket.on("emergency-update", (data) {
      setState(() {
        status = data["status"];
        message = data["message"];
        location = data["location"];
      });
    });
  }

  Future<void> sendEmergency() async {
    await http.post(
      Uri.parse("http://192.168.0.103/report-emergency"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "message": "Emergency! Immediate help needed",
        "location": "Room 101",
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Emergency System")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Status: $status", style: TextStyle(fontSize: 20)),
          Text("Message: $message"),
          Text("Location: $location"),

          SizedBox(height: 30),

          ElevatedButton(
            onPressed: sendEmergency,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: EdgeInsets.all(20),
            ),
            child: Text("PANIC BUTTON"),
          ),
        ],
      ),
    );
  }
}