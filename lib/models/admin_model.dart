import 'package:startup_corner/models/user_model.dart';

// New Meeting class to structure meeting data
class Meeting {
  final String link;
  final DateTime dateTime;
  final List<String> participants; // List of participant IDs

  Meeting({
    required this.link,
    required this.dateTime,
    required this.participants,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      link: json['link'] ?? '',
      dateTime: json['dateTime'] != null 
          ? DateTime.parse(json['dateTime']) 
          : DateTime.now(), // Default to current time if null
      participants: List<String>.from(json['participants'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'link': link,
      'dateTime': dateTime.toIso8601String(),
      'participants': participants,
    };
  }
}

class Admin extends UserModel {
  final String password;
  final List<Meeting> meetings;

  Admin({
    required String id,
    required String name,
    required String email,
    required String profilePicture,
    required String bio,
    required this.password,
    required this.meetings,
  }) : super(
          id: id,
          name: name,
          email: email,
          role: 'admin',
          profilePicture: profilePicture,
          bio: bio,
          verified: 'approved',
        );

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profilePicture: json['profilePicture'] ?? '',
      bio: json['bio'] ?? '',
      password: json['password'] ?? '',
      meetings: (json['meetings'] as List<dynamic>?)
              ?.map((meeting) => Meeting.fromJson(meeting as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final data = super.toJson();
    data['password'] = password;
    data['meetings'] = meetings.map((meeting) => meeting.toJson()).toList();
    return data; // 'verified' is included via super.toJson() as true
  }

  factory Admin.fromMap(Map<String, dynamic> map) => Admin.fromJson(map);

  @override
  Map<String, dynamic> toMap() => toJson();
}