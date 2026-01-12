import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String email;
  String displayName;
  String photoUrl;
  Timestamp? createdAt;
  String? fcmToken;

  UserModel({
    required this.email,
    required this.displayName,
    required this.photoUrl,
    this.createdAt,
    this.fcmToken,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'fcmToken': fcmToken,
    };
  }

  // Create from Firestore Document
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      createdAt: json['createdAt'],
      fcmToken: json['fcmToken'],
    );
  }
}