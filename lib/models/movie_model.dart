import 'package:cloud_firestore/cloud_firestore.dart';

class MovieModel {
  final String id;
  final String title;
  final String description;
  final String genre;
  final String year;
  final double rating;
  final String? posterUrl;
  final String? trailerUrl;
  final String addedBy; // userId who added it
  final DateTime? createdAt;

  MovieModel({
    required this.id,
    required this.title,
    required this.description,
    required this.genre,
    required this.year,
    this.rating = 0.0,
    this.posterUrl,
    this.trailerUrl,
    required this.addedBy,
    this.createdAt,
  });

  // Convert Firestore document to MovieModel
  factory MovieModel.fromMap(Map<String, dynamic> map, String id) {
    return MovieModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      genre: map['genre'] ?? '',
      year: map['year'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      posterUrl: map['posterUrl'],
      trailerUrl: map['trailerUrl'],
      addedBy: map['addedBy'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert MovieModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'genre': genre,
      'year': year,
      'rating': rating,
      'posterUrl': posterUrl,
      'trailerUrl': trailerUrl,
      'addedBy': addedBy,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  MovieModel copyWith({
    String? title,
    String? description,
    String? genre,
    String? year,
    double? rating,
    String? posterUrl,
    String? trailerUrl,
  }) {
    return MovieModel(
      id: this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      rating: rating ?? this.rating,
      posterUrl: posterUrl ?? this.posterUrl,
      trailerUrl: trailerUrl ?? this.trailerUrl,
      addedBy: this.addedBy,
      createdAt: this.createdAt,
    );
  }
}