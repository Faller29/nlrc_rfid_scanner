import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:pdf/pdf.dart'; // For PDF generation
import 'package:pdf/widgets.dart' as pw; // PDF Widgets
import 'package:printing/printing.dart'; // For printing PDFs
import 'package:flutter/services.dart'; // For loading images
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportPage extends StatefulWidget {
  @override
  _ReportPage createState() => _ReportPage();
}

class _ReportPage extends State<ReportPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  DateTime selectedDate = DateTime.now();
  DateTimeRange? selectedDateRange;

  void adjustDate(int days) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: days));
    });
  }

  Future<void> pickDateRange() async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000), // Allow going back to the year 1900
      lastDate: DateTime.now(), // Up to the current date
      initialDateRange: selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
    );

    if (pickedRange != null) {
      setState(() {
        selectedDateRange = pickedRange;
      });
    }
  }

  Future<List<Map<String, String>>> fetchAttendanceData1() async {
    try {
      if (selectedDateRange == null) return [];
      Map<String, Map<String, dynamic>> combinedData = {};

      DateTime currentDate = selectedDateRange!.start;
      while (currentDate.isBefore(selectedDateRange!.end) ||
          currentDate.isAtSameMomentAs(selectedDateRange!.end)) {
        String yearMonth =
            DateFormat('MMM_yyyy').format(currentDate); // e.g., Dec_2024
        String day = DateFormat('dd').format(currentDate); // e.g., 12

        CollectionReference dayCollection =
            firestore.collection('attendances').doc(yearMonth).collection(day);

        QuerySnapshot snapshot = await dayCollection.get();

        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String id = doc.id;
          String name = data['name'] ?? '';

          if (!combinedData.containsKey(id)) {
            combinedData[id] = {
              'name': name,
              'totalHours': 0,
            };
          }

          DateTime? timeIn =
              data['timeIn'] != null ? data['timeIn'].toDate() : null;
          DateTime? timeOut =
              data['timeOut'] != null ? data['timeOut'].toDate() : null;
          combinedData[id]!['totalHours'] +=
              _calculateTotalMinutes(timeIn, timeOut);
        }

        currentDate = currentDate.add(Duration(days: 1));
      }

      return combinedData.entries.map((entry) {
        int totalMinutes = entry.value['totalHours'] as int;
        int hours = totalMinutes ~/ 60;
        int minutes = totalMinutes % 60;

        // Determine the correct singular or plural form for hours and minutes
        String hourText = hours == 1 ? 'hour' : 'hours';
        String minuteText = minutes == 1 ? 'minute' : 'minutes';

        return {
          'name': entry.value['name'] as String,
          'totalHours':
              '${hours > 0 ? '$hours $hourText ' : ''}${minutes > 0 ? '$minutes $minuteText' : ''}'
                  .trim(),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching attendance data: $e');
      return [];
    }
  }

  int _calculateTotalMinutes(DateTime? timeIn, DateTime? timeOut) {
    if (timeIn == null || timeOut == null) return 0;
    try {
      Duration diff = timeOut.difference(timeIn);
      return diff.inMinutes;
    } catch (e) {
      debugPrint('Error calculating total minutes: $e');
      return 0;
    }
  }

  Future<void> pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<List<Map<String, String>>> fetchAttendanceData() async {
    try {
      String yearMonth =
          DateFormat('MMM_yyyy').format(selectedDate); // e.g., Dec_2024
      String day = DateFormat('dd').format(selectedDate); // e.g., 12

      CollectionReference dayCollection =
          firestore.collection('attendances').doc(yearMonth).collection(day);

      QuerySnapshot snapshot = await dayCollection.get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        DateTime? timeIn =
            data['timeIn'] != null ? (data['timeIn']).toDate() : null;
        DateTime? timeOut =
            data['timeOut'] != null ? (data['timeOut']).toDate() : null;

        int totalMinutes = _calculateTotalMinutes(timeIn, timeOut);
        int hours = totalMinutes ~/ 60;
        int minutes = totalMinutes % 60;

        // Determine the correct singular or plural form for hours and minutes
        String hourText = hours == 1 ? 'hour' : 'hours';
        String minuteText = minutes == 1 ? 'minute' : 'minutes';

        return {
          'name': (data['name'] ?? '').toString(),
          'timeIn': timeIn != null ? DateFormat('hh:mm a').format(timeIn) : '',
          'timeOut':
              timeOut != null ? DateFormat('hh:mm a').format(timeOut) : '',
          'totalHours':
              '${hours > 0 ? '$hours $hourText ' : ''}${minutes > 0 ? '$minutes $minuteText' : ''}'
                  .trim(),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching attendance data: $e');
      return [];
    }
  }

  String _calculateTotalHours(DateTime? timeIn, DateTime? timeOut) {
    if (timeIn == null || timeOut == null) return '';
    try {
      Duration diff = timeOut.difference(timeIn);
      int hours = diff.inHours;
      int minutes = diff.inMinutes % 60;
      return '${hours}h ${minutes}m';
    } catch (e) {
      debugPrint('Error calculating total hours: $e');
      return '';
    }
  }

  Future<void> generateAndPrintPDF() async {
    final pdf = pw.Document();
    final ByteData imageData =
        await rootBundle.load('lib/assets/images/NLRC-WHITE.png');
    final Uint8List imageBytes = imageData.buffer.asUint8List();

    final logo = pw.MemoryImage(imageBytes);
    final String currentDate = DateFormat('MMMM d, y').format(selectedDate);

    final attendanceData = await fetchAttendanceData();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(
                    logo,
                    width: 75,
                    height: 75,
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'National Labor Relations Commission',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        currentDate,
                        style: const pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(width: 50),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'PERFORMANCE ANALYSIS',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['Name', 'Time In', 'Time Out', 'Total Hours'],
                data: attendanceData.map((employee) {
                  return [
                    employee['name'] ?? '',
                    employee['timeIn'] ?? '',
                    employee['timeOut'] ?? '',
                    employee['totalHours'] ?? '',
                  ];
                }).toList(),
                border: pw.TableBorder.all(color: PdfColors.blue, width: 1),
                cellAlignment: pw.Alignment.center,
                headerStyle: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue,
                ),
                cellStyle: const pw.TextStyle(
                  fontSize: 10,
                ),
                cellPadding: const pw.EdgeInsets.all(8),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime currentDate = DateTime.now();
    final bool isForwardDisabled =
        selectedDate.add(Duration(days: 1)).isAfter(currentDate);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: FutureBuilder<List<List<Map<String, String>>>>(
        future: Future.wait([fetchAttendanceData1(), fetchAttendanceData()]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error fetching data'));
          } else {
            final attendanceData1 = snapshot.data?[0] ?? [];
            final attendanceData = snapshot.data?[1] ?? [];
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(0, 12, 0, 12),
                          child: Text(
                            'REPORT ANALYSIS',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(55, 71, 79, 1),
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 33,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor:
                                const Color.fromRGBO(69, 90, 100, 1),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: pickDateRange,
                          child: const Text(
                            'SELECT RANGE',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 5.0),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Color.fromRGBO(69, 90, 100, 1),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              selectedDateRange = null; // Reset the range
                            });
                          },
                          child: const Text(
                            'RESET TO DEFAULT VIEW',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Color.fromRGBO(69, 90, 100, 1),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 36,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: generateAndPrintPDF,
                        child: const Text(
                          'GENERATE',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(
                    color: Color.fromRGBO(55, 71, 79, 1),
                    thickness: 3,
                  ),
                  if (selectedDateRange != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Selected Range: ${DateFormat.yMMMd().format(selectedDateRange!.start)} - ${DateFormat.yMMMd().format(selectedDateRange!.end)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    if (attendanceData1.isEmpty)
                      Expanded(
                        child: Center(
                          child: const Text(
                            'No records found for this date range',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: Table(
                          border: TableBorder.all(color: Colors.grey, width: 1),
                          columnWidths: const {
                            0: FlexColumnWidth(2),
                            1: FlexColumnWidth(3),
                          },
                          children: [
                            TableRow(
                              decoration: const BoxDecoration(
                                color: Colors.blueGrey,
                              ),
                              children: const [
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Name',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Total Hours',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                            ...attendanceData1.map((employee) {
                              return TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      employee['name'] ?? '',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      employee['totalHours'] ?? '',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => adjustDate(-1),
                        ),
                        TextButton(
                          onPressed: pickDate,
                          child: Text(
                            DateFormat('MMMM d, y').format(selectedDate),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(55, 71, 79, 1),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed:
                              isForwardDisabled ? null : () => adjustDate(1),
                        ),
                      ],
                    ),
                    if (attendanceData.isEmpty)
                      Expanded(
                        child: Center(
                          child: const Text(
                            'No records found for this date',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: Table(
                          border: TableBorder.all(color: Colors.grey, width: 1),
                          columnWidths: const {
                            0: FlexColumnWidth(2),
                            1: FlexColumnWidth(3),
                            2: FlexColumnWidth(3),
                            3: FlexColumnWidth(2),
                          },
                          children: [
                            TableRow(
                              decoration: const BoxDecoration(
                                color: Colors.blueGrey,
                              ),
                              children: const [
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Name',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Time In',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Time Out',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Total Hours',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                            ...attendanceData.map((employee) {
                              return TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      employee['name'] ?? '',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      employee['timeIn'] ?? '',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      employee['timeOut'] ?? '',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      employee['totalHours'] ?? '',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
