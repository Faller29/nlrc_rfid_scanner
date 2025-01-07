import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nlrc_rfid_scanner/assets/themeData.dart';
import 'package:nlrc_rfid_scanner/backend/data/fetch_data.dart';
import 'package:nlrc_rfid_scanner/backend/data/file_reader.dart';
import 'package:nlrc_rfid_scanner/main.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class ScannedModal extends StatefulWidget {
  final String rfidData;
  final DateTime timestamp;
  final Map<String, dynamic> userData;
  final VoidCallback? onRemoveNotification;

  const ScannedModal({
    Key? key,
    required this.rfidData,
    required this.timestamp,
    required this.userData,
    this.onRemoveNotification,
  }) : super(key: key);

  @override
  _ScannedModalState createState() => _ScannedModalState();
}

class _ScannedModalState extends State<ScannedModal> {
  String? _selectedJobType;
  final List<String> _jobTypes = ['Office', 'On the Business'];

  bool _isTimeInRecorded = false; // Flag to check if Time In is recorded
  DateTime? _timeIn;
  bool isLoading = false;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  DateTime givenTime = DateTime.now().subtract(Duration(minutes: 2));
  @override
  Widget build(BuildContext context) {
    // Check for matching RFID in attendance list
    final matchedAttendance = attendance.firstWhere(
        (entry) => entry['name'] == widget.userData['name'],
        orElse: () => {});
    print(widget.userData['name']);

    String? timeIn = matchedAttendance['timeIn'];
    String? timeOut = matchedAttendance['timeOut'];

    if (timeIn != null && timeIn.isNotEmpty) {
      // Display the timeIn if it exists and disable the dropdown button
      _selectedJobType = null; // Optionally disable job type selection
    } else {
      timeIn = '--:-- --';
      timeOut = '--:-- --';
    }
    if (timeOut == null || timeIn.isEmpty) {
      timeOut = '--:-- --';
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Center(
            child: Card(
              color: Color.fromARGB(255, 234, 235, 250),
              margin: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.25,
                  vertical: MediaQuery.of(context).size.height * 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 10,
              child: Shimmer(
                interval: Duration(seconds: 2),
                colorOpacity: 0.5,
                child: Stack(
                  children: [
                    Positioned(
                      right: 0,
                      child: Image.asset(
                        'lib/assets/images/modalBG.png',
                        fit: BoxFit.cover,
                        height: 400,
                        width: MediaQuery.sizeOf(context).width / 2,
                        opacity: const AlwaysStoppedAnimation(.1),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Image.asset(
                                  'lib/assets/images/NLRCnbg.png',
                                  fit: BoxFit.cover,
                                  height: 70,
                                  width: 70,
                                ),
                                const Column(
                                  children: [
                                    Text(
                                      'REPUBLIKA NG PILIPINAS',
                                      style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'NATIONAL LABOR RELATIONS COMMISSION',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'EMPLOYEE IDENTIFICATION CARD',
                                      style: TextStyle(
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                Image.asset(
                                  'lib/assets/images/bagongPilipinas.png',
                                  fit: BoxFit.cover,
                                  height: 70,
                                  width: 70,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.black54,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        20,
                                      ),
                                      color:
                                          Colors.blueAccent.withOpacity(0.2)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: widget.userData['imagePath'] !=
                                                null &&
                                            File(widget.userData['imagePath']!)
                                                .existsSync()
                                        ? Image.file(
                                            File(widget.userData['imagePath']!),
                                            width: 150,
                                            height: 150,
                                            fit: BoxFit.fill,
                                          )
                                        : Container(
                                            width: 150,
                                            height: 150,
                                            child: Image.asset(
                                              'lib/assets/images/NLRC-WHITE.png', // Default image asset
                                              width: 150,
                                              height: 150,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      widget.rfidData,
                                      style: const TextStyle(
                                        color: Colors.blueGrey,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Name:',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18),
                                            ),
                                            const Text(
                                              'Position:',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18),
                                            ),
                                            const Text(
                                              'Office:',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18),
                                            ),
                                            SizedBox(
                                              height: 15,
                                            ),
                                            const Text(
                                              'Time in:',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.green),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              /* _formatTimestamp(timeIn) */ timeIn
                                                  .toString(),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.green),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          width: 20,
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget.userData['name'] ??
                                                  'Unknown',
                                              style: TextStyle(
                                                  color: Colors.blueGrey,
                                                  fontSize: 18),
                                            ),
                                            Text(
                                              widget.userData['position'] ??
                                                  'Unknown',
                                              style: TextStyle(
                                                  color: Colors.blueGrey,
                                                  fontSize: 18),
                                            ),
                                            Text(
                                              widget.userData['office'] ??
                                                  'Unknown',
                                              style: TextStyle(
                                                  color: Colors.blueGrey,
                                                  fontSize: 18),
                                            ),
                                            SizedBox(
                                              height: 15,
                                            ),
                                            const Text(
                                              'Time out:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.red,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              timeOut.toString(),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.redAccent),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                          if (matchedAttendance == null ||
                              matchedAttendance.isEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Field type:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  DropdownButton<String>(
                                    value: _selectedJobType,
                                    focusColor: Colors.transparent,
                                    icon: Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.black,
                                    ),
                                    underline: Container(),
                                    items: _jobTypes.map((String type) {
                                      return DropdownMenuItem<String>(
                                        value: type,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12.0, horizontal: 16.0),
                                          child: Text(type),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedJobType = newValue;
                                      });
                                    },
                                    hint: const Text(
                                      'Select job type',
                                      style: TextStyle(
                                          color: Color.fromARGB(255, 116, 1, 1),
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(); // Close modal
                                },
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.greenAccent),
                                onPressed: () async {
                                  if (_selectedJobType == null &&
                                      timeIn == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      snackBarFailed(
                                          'Please select Job Field', context),
                                    );
                                  } else {
                                    if (widget.onRemoveNotification != null) {
                                      widget
                                          .onRemoveNotification!(); // Remove notification
                                    }
                                    setState(() {
                                      Timer(Duration(seconds: 30), () {
                                        if (mounted) {
                                          setState(() {
                                            print('done');
                                            isLoading = false;
                                          });
                                        }
                                      });

                                      isLoading = true;
                                    });

                                    await _saveAttendance(); // Save attendance to Firestore

                                    setState(() {
                                      isLoading = false;
                                    });
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: const Text(
                                  'Submit',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Color.fromARGB(255, 37, 26, 196).withOpacity(0.3),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                    ),
                    Text(
                      'Saving Attendance',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<ScaffoldFeatureController<SnackBar, SnackBarClosedReason>>
      _saveAttendance() async {
    try {
      final userId = widget.rfidData; // Assuming RFID is unique to the user
      final today = widget.timestamp; // Use the timestamp passed to the modal
      final monthYear =
          DateFormat('MMM_yyyy').format(today); // Get current month and year
      final day = DateFormat('dd').format(today); // Get the day

      // Reference to the day's attendance document
      final attendanceRef = firestore
          .collection('attendances')
          .doc(monthYear) // Collection for the current month/year
          .collection(day) // Subcollection for the current day
          .doc(userId); // Document for the specific user (RFID)

      final attendanceDoc = await attendanceRef.get();

      if (!attendanceDoc.exists) {
        // First scan, save as Time In
        await attendanceRef.set({
          'name': widget.userData['name'],
          'officeType': _selectedJobType, //widget.userData['office'],
          'timeIn': widget.timestamp, // Use the timestamp passed to the modal
          'timeOut': null,
        });

        await fetchAttendance();
        attendance = await loadAttendance();
      } else {
        // If Time In exists, check Time Out before updating
        final data = attendanceDoc.data();
        final timeIn = (data?['timeIn'] as Timestamp?)?.toDate();
        final timeOut = (data?['timeOut'] as Timestamp?)?.toDate();

        // Check if Time Out already exists
        if (timeOut != null) {
          // Show a Snackbar and prevent overwriting

          return ScaffoldMessenger.of(context).showSnackBar(
            snackBarFailed(
              'Time Out has already been recorded.',
              context,
            ),
          ); // Prevent overwriting Time Out
        }

        // Otherwise, check the time difference constraint before updating Time Out
        final newTimeOut =
            widget.timestamp; // Assuming current timestamp is Time Out

        if (timeIn != null) {
          final workedDuration = newTimeOut.difference(timeIn);

          // Check if workedDuration is greater than 30 minutes
          if (workedDuration.inMinutes < 60) {
            // Show a Snackbar if the difference is less than 30 minutes

            return ScaffoldMessenger.of(context).showSnackBar(
              snackBarFailed(
                'Time Out cannot be recorded before 30 minutes of work.',
                context,
              ),
            ); // Prevent Time Out
          }

          final workedHours = workedDuration.inHours +
              (workedDuration.inMinutes.remainder(60) / 60);

          // Update the Time Out for the day
          await attendanceRef.update({
            'timeOut': newTimeOut,
          });

          // Now update the total hours in a separate collection
          final totalHoursRef = firestore
              .collection('attendances')
              .doc(monthYear) // Document for the month
              .collection('total_hours') // Separate collection for total hours
              .doc(userId); // Document for the user (RFID)

          // Check if the totalHours document exists for the user
          final totalHoursDoc = await totalHoursRef.get();

          if (totalHoursDoc.exists) {
            // If exists, increment the total hours for that user in the month
            await totalHoursRef.update({
              'totalHours': FieldValue.increment(workedHours),
            });
          } else {
            // If it doesn't exist, create the document with the worked hours
            await totalHoursRef.set({
              'totalHours': workedHours,
            });
          }
          await fetchAttendance();
          attendance = await loadAttendance();
        }
      }
    } catch (e) {
      debugPrint('Error saving attendance: $e');
    }

    return ScaffoldMessenger.of(context).showSnackBar(
      snackBarSuccess(
        'Attendance saved.',
        context,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final DateFormat formatter = DateFormat('hh:mm a');
    return formatter.format(timestamp);
  }
}
