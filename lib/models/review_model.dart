import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String movieId;
  final String movieTitle;
  final String userId;
  final String username;
  final double rating;
  final String review;
  final DateTime? createdAt;

  ReviewModel({
    required this.id,
    required this.movieId,
    required this.movieTitle,
    required this.userId,
    required this.username,
    required this.rating,
    required this.review,
    this.createdAt,
  });

  // Convert Firestore document to ReviewModel
  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      id: id,
      movieId: map['movieId'] ?? '',
      movieTitle: map['movieTitle'] ?? '',
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      review: map['review'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert ReviewModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'movieId': movieId,
      'movieTitle': movieTitle,
      'userId': userId,
      'username': username,
      'rating': rating,
      'review': review,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}