import 'dart:convert';
import 'dart:io';
import 'package:nlrc_rfid_scanner/backend/data/announcement_backend.dart';
import 'package:nlrc_rfid_scanner/backend/data/fetch_attendance.dart';
import 'package:nlrc_rfid_scanner/backend/data/file_reader.dart';
import 'package:path_provider/path_provider.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nlrc_rfid_scanner/backend/data/fetch_data.dart';
import 'package:nlrc_rfid_scanner/screens/homepage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

//List<Map<String, dynamic>> localUsers = [];
List<Map<String, dynamic>> users = [];
List<Map<String, dynamic>> attendance = [];
Map<String, dynamic>? adminData = {};
Map<String, dynamic> announcement = {};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  //await fetchUsers();

  await checkConnectivity();

  runApp(const MyApp());
}

Future<void> checkConnectivity() async {
  final result = await InternetAddress.lookup('example.com');
  if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
    await fetchDataAndGenerateDartFile();
    await fetchAttendance();
    await fetchAdminLogin();
    await fetchAnnouncements();

    await fetchUsers();
    await fetchLoggedUsers();
    await fetchAttendanceData();
    deleteExpiredAnnouncements();
  }
  //announcement = (await loadAnnouncements())!;
  print(announcement);
  users = await loadUsers();
  attendance = await loadAttendance();
  adminData = await loadAdmin();
}

/* Future<void> fetchUsers() async {
  // Simulating fetching users from Firebase Firestore
  final snapshot = await FirebaseFirestore.instance.collection('users').get();
  localUsers = snapshot.docs.map((doc) {
    return {
      'rfid': doc['rfid'],
      'name': doc['name'],
      'position': doc['position'],
    };
  }).toList();
} */

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]);

    return MaterialApp(
      title: 'NLRC Attendance System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'readexPro',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}
