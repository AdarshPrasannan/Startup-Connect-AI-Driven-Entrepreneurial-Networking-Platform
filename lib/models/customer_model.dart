import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:startup_corner/models/user_model.dart';

class Project {
  final String title;
  final String description;
  final String link;
  final String imageUrl;
  final String mobileNumber;

  Project({
    required this.title,
    required this.description,
    required this.link,
    required this.imageUrl,
    required this.mobileNumber,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      link: json['link'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'link': link,
      'imageUrl': imageUrl,
      'mobileNumber': mobileNumber,
    };
  }
}

class Idea {
  final String description;
  final String report;
  final String status;
  final int vote; // Vote count
  final List<String> voters; // List of voters
  final List<Timestamp> voteTimestamps; // List of vote timestamps

  Idea({
    required this.description,
    required this.report,
    required this.status,
    required this.vote,
    required this.voters,
    this.voteTimestamps = const [], // Default to empty list
  });

  factory Idea.fromJson(Map<String, dynamic> json) {
    return Idea(
      description: json['description'],
      report: json['report'],
      status: json['status'],
      vote: json['vote'] ?? 0,
      voters: List<String>.from(json['voters'] ?? []),
      voteTimestamps: (json['voteTimestamps'] as List<dynamic>?)
              ?.map((t) => t as Timestamp)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'report': report,
      'status': status,
      'vote': vote,
      'voters': voters,
      'voteTimestamps': voteTimestamps,
    };
  }
}

class Customer extends UserModel {
  final List<Project> projects;
  final List<Idea> ideas;
  final List<String> meetings;
  final List<Idea> thoughts;
  final String phoneNumber;

  Customer({
    required String id,
    required String name,
    required String email,
    required String profilePicture,
    required String bio,
    required String verified, // Added verified parameter
    required this.projects,
    required this.ideas,
    required this.meetings,
    required this.thoughts,
    required this.phoneNumber,
  }) : super(
          id: id,
          name: name,
          email: email,
          role: 'customer',
          profilePicture: profilePicture,
          bio: bio,
          verified: verified, // Pass verified to super
        );

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profilePicture: json['profilePicture'] ?? '',
      bio: json['bio'] ?? '',
      verified: json['verified'] ?? '',
      projects: (json['projects'] as List<dynamic>?)
              ?.map((project) => Project.fromJson(project as Map<String, dynamic>))
              .toList() ?? [],
      ideas: (json['ideas'] as List<dynamic>?)
              ?.map((idea) => Idea.fromJson(idea as Map<String, dynamic>))
              .toList() ?? [],
      thoughts: (json['thoughts'] as List<dynamic>?)
              ?.map((thought) => Idea.fromJson(thought as Map<String, dynamic>))
              .toList() ?? [],
      meetings: List<String>.from(json['meetings'] ?? []),
      phoneNumber: json['phoneNumber'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final data = super.toJson();
    data['projects'] = projects.map((project) => project.toJson()).toList();
    data['ideas'] = ideas.map((idea) => idea.toJson()).toList();
    data['thoughts'] = thoughts.map((thought) => thought.toJson()).toList();
    data['meetings'] = meetings;
    data['phoneNumber'] = phoneNumber;
    return data; // 'verified' is already included via super.toJson()
  }

  factory Customer.fromMap(Map<String, dynamic> map) => Customer.fromJson(map);

  Map<String, dynamic> toMap() => toJson();
}