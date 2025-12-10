class UserModel {
  final String uid;
  final String username;
  final String email;
  final String role; // 'admin' or 'user'
  final int totalMovies;
  final int totalReviews;
  final int followers;
  final DateTime? createdAt;
  final String? profileImageUrl;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.role = 'user',
    this.totalMovies = 0,
    this.totalReviews = 0,
    this.followers = 0,
    this.createdAt,
    this.profileImageUrl,
  });

  // Check if user is admin
  bool get isAdmin => role == 'admin';

  // Convert Firestore document to UserModel
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      totalMovies: map['totalMovies'] ?? 0,
      totalReviews: map['totalReviews'] ?? 0,
      followers: map['followers'] ?? 0,
      profileImageUrl: map['profileImageUrl'],
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'].seconds * 1000)
          : null,
    );
  }

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'role': role,
      'totalMovies': totalMovies,
      'totalReviews': totalReviews,
      'followers': followers,
      'profileImageUrl': profileImageUrl,
    };
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? username,
    String? email,
    String? role,
    int? totalMovies,
    int? totalReviews,
    int? followers,
    String? profileImageUrl,
  }) {
    return UserModel(
      uid: this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      totalMovies: totalMovies ?? this.totalMovies,
      totalReviews: totalReviews ?? this.totalReviews,
      followers: followers ?? this.followers,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: this.createdAt,
    );
  }
}