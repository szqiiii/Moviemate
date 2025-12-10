import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add a review
  Future<Map<String, dynamic>> addReview({
    required String movieId,
    required String movieTitle,
    required String userId,
    required String username,
    required double rating,
    required String review,
  }) async {
    try {
      await _firestore.collection('reviews').add({
        'movieId': movieId,
        'movieTitle': movieTitle,
        'userId': userId,
        'username': username,
        'rating': rating,
        'review': review,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Review added successfully'};
    } catch (e) {
      print('Add review error: $e');
      return {'success': false, 'message': 'Failed to add review'};
    }
  }

  /// Get reviews for a movie
  Stream<QuerySnapshot> getMovieReviews(String movieId) {
    return _firestore
        .collection('reviews')
        .where('movieId', isEqualTo: movieId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get user reviews
  Stream<QuerySnapshot> getUserReviews(String userId) {
    return _firestore
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Update review
  Future<Map<String, dynamic>> updateReview(
      String reviewId, double rating, String review) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'rating': rating,
        'review': review,
      });
      return {'success': true, 'message': 'Review updated successfully'};
    } catch (e) {
      print('Update review error: $e');
      return {'success': false, 'message': 'Failed to update review'};
    }
  }

  /// Delete review
  Future<Map<String, dynamic>> deleteReview(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).delete();
      return {'success': true, 'message': 'Review deleted successfully'};
    } catch (e) {
      print('Delete review error: $e');
      return {'success': false, 'message': 'Failed to delete review'};
    }
  }

  /// Get all reviews (Admin only)
  Stream<QuerySnapshot> getAllReviews() {
    return _firestore
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}