import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String email;
  String displayName;
  String photoUrl;
  Timestamp? createdAt;

  UserModel({
    required this.email,
    required this.displayName,
    required this.photoUrl,
    this.createdAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  // Create from Firestore Document
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      createdAt: json['createdAt'],
    );
  }


}