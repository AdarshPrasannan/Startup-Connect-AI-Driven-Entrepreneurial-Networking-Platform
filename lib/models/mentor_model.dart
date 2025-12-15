import 'package:startup_corner/models/user_model.dart';

class Mentor extends UserModel {
  final List<String> expertise;
  final List<String> meetings;
  final String verified; // Added verified attribute

  Mentor({
    required String id,
    required String name,
    required String email,
    required String profilePicture,
    required String bio,
    required this.expertise,
    required this.meetings,
    required this.verified, // Added to constructor
  }) : super(
          id: id,
          name: name,
          email: email,
          role: 'mentor',
          profilePicture: profilePicture,
          bio: bio,
          verified: verified, // Pass verified to super
        );

  factory Mentor.fromJson(Map<String, dynamic> json) {
    return Mentor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profilePicture: json['profilePicture'] ?? '',
      bio: json['bio'] ?? '',
      expertise: List<String>.from(json['expertise'] ?? []),
      meetings: List<String>.from(json['meetings'] ?? []),
      verified: json['verified'] ?? '', // Added verified parsing with default false
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['expertise'] = expertise;
    json['meetings'] = meetings;
    json['verified'] = verified; // Added verified to JSON
    return json;
  }

  factory Mentor.fromMap(Map<String, dynamic> map) => Mentor.fromJson(map);

  Map<String, dynamic> toMap() => toJson();
}