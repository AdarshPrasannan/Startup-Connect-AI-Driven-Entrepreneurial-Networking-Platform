import 'package:startup_corner/models/user_model.dart';

class Investor extends UserModel {
  final double investmentBudget;
  final List<String> meetings;
  final String verified; // Added verified attribute

  Investor({
    required String id,
    required String name,
    required String email,
    required String profilePicture,
    required String bio,
    required this.investmentBudget,
    required this.meetings,
    required this.verified, // Added to constructor
  }) : super(
          id: id,
          name: name,
          email: email,
          role: 'investor',
          profilePicture: profilePicture,
          bio: bio,
          verified: verified, // Pass verified to super
        );

  factory Investor.fromJson(Map<String, dynamic> json) {
    return Investor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profilePicture: json['profilePicture'] ?? '',
      bio: json['bio'] ?? '',
      investmentBudget: (json['investmentBudget'] ?? 0.0).toDouble(),
      meetings: List<String>.from(json['meetings'] ?? []),
      verified: json['verified'] ?? '', // Added verified parsing with default false
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['investmentBudget'] = investmentBudget;
    json['meetings'] = meetings;
    json['verified'] = verified; // Added verified to JSON
    return json;
  }

  factory Investor.fromMap(Map<String, dynamic> map) => Investor.fromJson(map);

  Map<String, dynamic> toMap() => toJson();
}