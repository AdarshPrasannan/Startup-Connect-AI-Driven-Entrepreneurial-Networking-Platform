class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String profilePicture;
  final String bio;
  final String verified; // Added verified attribute

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.profilePicture,
    required this.bio,
    required this.verified, // Added to constructor
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'profilePicture': profilePicture,
      'bio': bio,
      'verified': verified, // Added to JSON
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      profilePicture: json['profilePicture'],
      bio: json['bio'],
      verified: json['verified'], 
    );
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel.fromJson(map);
  }
}