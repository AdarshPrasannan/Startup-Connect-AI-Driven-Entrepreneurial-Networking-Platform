import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:startup_corner/screens/dashboard/customer/submissions_screen.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

class SuccessScorePredictionScreen extends StatefulWidget {
  const SuccessScorePredictionScreen({super.key});

  @override
  State<SuccessScorePredictionScreen> createState() =>
      _SuccessScorePredictionScreenState();
}

class _SuccessScorePredictionScreenState
    extends State<SuccessScorePredictionScreen> {
  Interpreter? _interpreter;
  double? _successScore;
  String? _analysisReport;
  final _descriptionController = TextEditingController();
  bool isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String _userId;

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUser?.uid ?? "";
  }

  Future<void> initializeInterpreter() async {
    try {
      _interpreter ??= await Interpreter.fromAsset('assets/model.tflite');
      debugPrint('Interpreter initialized');
    } catch (e) {
      debugPrint('Cant load model, $e');
    }
  }

  List<double> _preprocessInput(String geminiOutput) {
    Map<String, int> countryMap = {'USA': 0, 'UK': 1, 'India': 2, 'Germany': 3};
    Map<String, int> industryMap = {
      'Tech': 0,
      'Health': 1,
      'Finance': 2,
      'Retail': 3
    };
    double meanFoundedYear = 2012.0;
    double stdFoundedYear = 5.0;
    List<String> inputs = geminiOutput.split(',');
    if (inputs.length != 3) {
      throw Exception('Invalid Gemini output format');
    }
    String countryStr = inputs[0].trim();
    String industryStr = inputs[1].trim();
    String foundedYearStr = inputs[2].trim();
    double country = countryMap[countryStr]?.toDouble() ?? 0.0;
    double industry = industryMap[industryStr]?.toDouble() ?? 0.0;
    double foundedYear = double.tryParse(foundedYearStr) ?? 2020.0;
    foundedYear = (foundedYear - meanFoundedYear) / stdFoundedYear;
    return [country, industry, foundedYear];
  }

  Future<void> _predict() async {
    await initializeInterpreter();

    String description = _descriptionController.text;
    if (description.isEmpty) {
      setState(() {
        _successScore = null;
        _analysisReport = null;
      });
      return;
    }

    debugPrint('Asking Gemini!');
    try {
      final geminiResponse = await Gemini.instance.prompt(parts: [
        Part.text(
            '''From the below given text, extract these inputs: country, industry, foundedYear. If any input is missing, infer it from the user description. The text is - "$description". Give only these three values comma-separated. if any value is missing you generate that randomly'''),
      ]);

      String? geminiOutput = geminiResponse?.output;
      if (geminiOutput == null || geminiOutput.isEmpty) {
        setState(() {
          _successScore = null;
          _analysisReport = null;
        });
        return;
      }

      debugPrint('Gemini output: $geminiOutput');

      final input = _preprocessInput(geminiOutput);
      final inputTensor = [input];
      final outputTensor = List.filled(1 * 1, 0).reshape([1, 1]);
      _interpreter?.run(inputTensor, outputTensor);
      debugPrint(
          'Predicted Success Score: ${outputTensor[0][0].toStringAsFixed(2)}');

      final geminiReport = await Gemini.instance.prompt(parts: [
        Part.text('''Generate an idea analysis report:
            1. Description: $description
            2. ML model assigns score: ${outputTensor[0][0].toStringAsFixed(2)} out of 10 for this idea.
            3. without any special character like astericks.
            4. No need of ML model specification just create a report.'''),
      ]);

      setState(() {
        _successScore = outputTensor[0][0];
        _analysisReport = geminiReport?.output!.replaceAll('*', '') ?? "";
      });
    } catch (e) {
      debugPrint('Error with Gemini or inference: $e');
      setState(() {
        _successScore = null;
        _analysisReport = 'Error generating report: $e';
      });
    }
  }

  void _submitForVerification() async {
    if (isLoading == true) return;
    setState(() {
      isLoading = true;
    });
    if (_analysisReport == null || _successScore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No report to submit!')),
      );
      return;
    }

    try {
      await _firestore.collection('customers').doc(_userId).update({
        'ideas': FieldValue.arrayUnion([
          {
            'description': _descriptionController.text,
            'report': _analysisReport,
            'status': 'pending',
          }
        ])
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted for verification!')),
      );

      setState(() {
        _descriptionController.clear();
        _successScore = null;
        _analysisReport = null;
      });
    } catch (e) {
      debugPrint('Error submitting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error submitting report!')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create startup success report.'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb), // Idea icon
            tooltip: 'View My Ideas',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => IdeasScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your startup idea description:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'e.g., A tech startup founded in 2020 in the USA',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _predict,
                  child: const Text('Analyze'),
                ),
              ),
              const SizedBox(height: 20),
              _successScore == null
                  ? const Center(
                      child: Text(
                        'Enter your startup idea and press Analyze',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : _buildResultSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    final success = _successScore!;
    final failure = 10.0 - success;

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: success,
                  color: Colors.green,
                  title: '${success.toStringAsFixed(1)}',
                  radius: 100,
                  titleStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  value: failure,
                  color: Colors.red,
                  title: '${failure.toStringAsFixed(1)}',
                  radius: 100,
                  titleStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.circle, color: Colors.green),
            SizedBox(width: 5),
            Text('Success Score'),
            SizedBox(width: 20),
            Icon(Icons.circle, color: Colors.red),
            SizedBox(width: 5),
            Text('Failure Score'),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Analysis Report:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          child: Text(
            _analysisReport ?? 'No report available',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _descriptionController.clear();
                  _successScore = null;
                  _analysisReport = null;
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Discard',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _submitForVerification();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: isLoading
                  ? SizedBox(
                      width: 20, // Adjust the size as needed
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2, // Adjust the thickness
                      ),
                    )
                  : const Text('Submit for Verification',
                      style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _interpreter?.close();
    _descriptionController.dispose();
    super.dispose();
  }
}

extension ListExtension on List<double> {
  List<List<double>> reshape(List<int> shape) {
    assert(shape[0] * shape[1] == length, 'Invalid shape for reshape');
    final List<List<double>> result = [];
    for (int i = 0; i < shape[0]; i++) {
      result.add(sublist(i * shape[1], (i + 1) * shape[1]));
    }
    return result;
  }
}
