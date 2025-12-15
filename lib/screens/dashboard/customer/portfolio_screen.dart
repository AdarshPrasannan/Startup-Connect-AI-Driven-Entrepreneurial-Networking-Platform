import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:startup_corner/api/auth_api.dart';
import 'package:startup_corner/models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _mobileNumberController =
      TextEditingController(); // New controller for mobile number

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String _userId;
  UserModel? _user;
  File? _thumbnailImage;
  bool _isUploading = false;

  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _linkFocus = FocusNode();
  final FocusNode _mobileNumberFocus =
      FocusNode(); // New focus node for mobile number

  final String pinataApiKey = 'f738ba804af4d54087a9';
  final String pinataSecretApiKey =
      'a7ba5c1f30f4db1fd64a56d4c2f1d61c90dd1085f48df5296182390f2d18625c';
  final String pinataBaseUrl = 'https://api.pinata.cloud/pinning/pinFileToIPFS';

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUser?.uid ?? "";
    _fetchUser();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    _mobileNumberController.dispose(); // Dispose new controller
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    _linkFocus.dispose();
    _mobileNumberFocus.dispose(); // Dispose new focus node
    super.dispose();
  }

  void _fetchUser() async {
    try {
      final authAPI = AuthAPI();
      final user = await authAPI.readCurrentUser();
      setState(() {
        _user = user;
      });
    } catch (e) {
      debugPrint('$e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _thumbnailImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImageToPinata() async {
    if (_thumbnailImage == null) return '';

    try {
      setState(() => _isUploading = true);

      var request = http.MultipartRequest('POST', Uri.parse(pinataBaseUrl));
      request.headers['pinata_api_key'] = pinataApiKey;
      request.headers['pinata_secret_api_key'] = pinataSecretApiKey;

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        _thumbnailImage!.path,
        filename: '${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(responseData);
        String cid = jsonResponse['IpfsHash'];
        return 'https://gateway.pinata.cloud/ipfs/$cid';
      } else {
        throw Exception('Failed to upload to Pinata: $responseData');
      }
    } catch (e) {
      debugPrint('Error uploading image to Pinata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image: $e")),
      );
      return '';
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _addProject() async {
    if (_titleController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty &&
        _linkController.text.isNotEmpty &&
        _mobileNumberController.text.isNotEmpty) {
      // Added mobile number check
      try {
        setState(() => _isUploading = true);
        final imageUrl = await _uploadImageToPinata();

        await _firestore.collection('customers').doc(_userId).update({
          'projects': FieldValue.arrayUnion([
            {
              'title': _titleController.text,
              'description': _descriptionController.text,
              'link': _linkController.text,
              'imageUrl': imageUrl,
              'mobileNumber':
                  _mobileNumberController.text, // Add mobile number to project
            }
          ])
        });

        _titleController.clear();
        _descriptionController.clear();
        _linkController.clear();
        _mobileNumberController.clear(); // Clear mobile number field
        setState(() => _thumbnailImage = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Project added successfully!")),
        );
      } catch (e) {
        debugPrint("Error adding project: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add project: $e")),
        );
      } finally {
        setState(() => _isUploading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields")),
      );
    }
  }

  Future<void> _removeProject(Map<String, dynamic> project) async {
    try {
      await _firestore.collection('customers').doc(_userId).update({
        'projects': FieldValue.arrayRemove([project])
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Project removed successfully!")),
      );
    } catch (e) {
      debugPrint("Error removing project: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to remove project: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Startup Connect',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        automaticallyImplyLeading: false,
      ),
      resizeToAvoidBottomInset: true,
      body: _user == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.manual,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome, ${_user!.name}",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Add a New Project",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _titleController,
                              focusNode: _titleFocus,
                              decoration: InputDecoration(
                                labelText: "Project Title",
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _descriptionController,
                              focusNode: _descriptionFocus,
                              decoration: InputDecoration(
                                labelText: "Project Description",
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _linkController,
                              focusNode: _linkFocus,
                              decoration: InputDecoration(
                                labelText: "Project Link",
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _mobileNumberController,
                              focusNode: _mobileNumberFocus,
                              decoration: InputDecoration(
                                labelText: "Contact Number",
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              keyboardType: TextInputType
                                  .phone, // Set keyboard to phone type
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                height: 100,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: _thumbnailImage == null
                                    ? Center(
                                        child: Text(
                                          "Tap to upload thumbnail",
                                          style: TextStyle(
                                              color: Colors.grey[600]),
                                        ),
                                      )
                                    : Image.file(
                                        _thumbnailImage!,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _isUploading
                                ? Center(child: CircularProgressIndicator())
                                : ElevatedButton(
                                    onPressed: _addProject,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[800],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Add Project",
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 16),
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    StreamBuilder<DocumentSnapshot>(
                      stream: _firestore
                          .collection('customers')
                          .doc(_userId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData ||
                            snapshot.data?.data() == null) {
                          return const Center(
                              child: Text("No projects added yet"));
                        }

                        List projects = snapshot.data!['projects'] ?? [];

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: projects.length,
                          itemBuilder: (context, index) {
                            final project = projects[index];

                            return Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (project['imageUrl'] != null &&
                                        project['imageUrl'].isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          project['imageUrl'],
                                          height: 150,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              height: 150,
                                              color: Colors.grey[300],
                                              child: Center(
                                                  child: Text(
                                                      "Image not available")),
                                            );
                                          },
                                        ),
                                      ),
                                    const SizedBox(height: 12),
                                    Text(
                                      project['title'],
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      project['description'],
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700]),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.phone,
                                            color: Colors.blue[800], size: 20),
                                        const SizedBox(width: 5),
                                        Text(
                                          project['mobileNumber'] ??
                                              'No contact provided',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700]),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        InkWell(
                                          onTap: () async {
                                            final url = project['link'];
                                            if (await canLaunchUrl(
                                                Uri.parse(url))) {
                                              await launchUrl(Uri.parse(url));
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        "Could not open link")),
                                              );
                                            }
                                          },
                                          child: Row(
                                            children: [
                                              Icon(Icons.link,
                                                  color: Colors.blue[800]),
                                              const SizedBox(width: 5),
                                              Text(
                                                "Open Project",
                                                style: TextStyle(
                                                  color: Colors.blue[800],
                                                  fontWeight: FontWeight.w500,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete,
                                              color: Colors.red[600]),
                                          onPressed: () =>
                                              _removeProject(project),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
