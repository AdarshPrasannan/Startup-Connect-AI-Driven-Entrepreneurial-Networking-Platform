import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:startup_corner/models/customer_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:startup_corner/screens/dashboard/customer/portfolio_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('customers').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No projects found"));
          }

          List<Map<String, dynamic>> allProjects = [];

          snapshot.data!.docs.forEach((doc) {
            Customer customer =
                Customer.fromJson(doc.data() as Map<String, dynamic>);
            for (var project in customer.projects) {
              allProjects.add({
                'project': project,
                'ownerName': customer.name,
                'ownerEmail': customer.email,
              });
            }
          });

          // Reverse the list to show the latest projects first
          allProjects = allProjects.reversed.toList();

          return ListView.builder(
            itemCount: allProjects.length,
            itemBuilder: (context, index) {
              var projectData = allProjects[index];
              Project project = projectData['project'];
              String ownerName = projectData['ownerName'];
              String ownerEmail = projectData['ownerEmail'];

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail Image
                      if (project.imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            project.imageUrl,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 150,
                                color: Colors.grey[300],
                                child: const Center(
                                    child: Text("Image not available")),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 12),

                      // Owner Info with Avatar
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue[800],
                            child: Text(
                              ownerName[0],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ownerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                ownerEmail,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Project Title
                      Text(
                        project.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Project Description
                      Text(
                        project.description,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black54),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),

                      // Mobile Number (Contact Info)
                      InkWell(
                        onTap: () async {
                          final phone = project.mobileNumber;
                          if (phone.isNotEmpty) {
                            final sanitizedPhone =
                                phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                            final uri = Uri.parse('tel:$sanitizedPhone');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            } 
                          }
                        },
                        child: Row(
                          children: [
                            Icon(Icons.phone,
                                color: Colors.blue[800], size: 20),
                            const SizedBox(width: 5),
                            Text(
                              project.mobileNumber.isNotEmpty
                                  ? project.mobileNumber
                                  : "No contact provided",
                              style: TextStyle(
                                fontSize: 14,
                                color: project.mobileNumber.isNotEmpty
                                    ? Colors.blue[800]
                                    : Colors.grey[700],
                                decoration: project.mobileNumber.isNotEmpty
                                    ? TextDecoration.underline
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Project Link
                      InkWell(
                        onTap: () async {
                          final url = project.link;
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Could not open link")),
                            );
                          }
                        },
                        child: Row(
                          children: [
                            Icon(Icons.link, color: Colors.blue[800], size: 20),
                            const SizedBox(width: 5),
                            Text(
                              "Open Project",
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PortfolioScreen()),
          );
        },
        backgroundColor: Colors.blue[800],
        elevation: 6.0,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}
