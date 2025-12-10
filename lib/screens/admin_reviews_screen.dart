import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/movie_service.dart';

class AdminReviewsScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showDeleteDialog(BuildContext context, String documentId, String movieTitle, String username) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2A2F4A),
        title: Text('Delete Review', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete the review by "$username" for "$movieTitle"?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firestore.collection('user_movies').doc(documentId).delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Review deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting review: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showReviewDetails(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Color(0xFF2A2F4A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(maxWidth: 400, maxHeight: 600),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.rate_review, color: Color(0xFFE535AB), size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Review Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(color: Colors.white24, height: 32),
              
              // Movie Poster & Title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data['posterPath'] != null && data['posterPath'].toString().isNotEmpty)
                    Container(
                      width: 80,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: MovieService.getTMDBPosterUrl(data['posterPath']),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Color(0xFF1A1F3A),
                            child: Icon(Icons.movie, color: Colors.white54),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Color(0xFF1A1F3A),
                            child: Icon(Icons.movie, color: Colors.white54),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['movieTitle'] ?? 'Unknown Movie',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Reviewed by: ${data['username'] ?? 'Anonymous'}',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 18),
                            SizedBox(width: 4),
                            Text(
                              '${data['rating'] ?? 0}/5',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 24),
              
              // Review Text
              if (data['review'] != null && data['review'].toString().isNotEmpty) ...[
                Text(
                  'Review:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF1A1F3A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    data['review'],
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              
              SizedBox(height: 16),
              
              // Timestamp
              if (data['updatedAt'] != null)
                Text(
                  'Reviewed on: ${_formatDate((data['updatedAt'] as Timestamp).toDate())}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: Color(0xFF0A0E27),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'User Reviews',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A)],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('user_movies')
              .where('rating', isGreaterThan: 0)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE535AB)),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Error loading reviews',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.rate_review, color: Colors.white30, size: 80),
                    SizedBox(height: 16),
                    Text(
                      'No reviews yet',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'User reviews will appear here',
                      style: TextStyle(color: Colors.white38, fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            // Sort by most recent
            final docs = snapshot.data!.docs.toList();
            docs.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTime = aData['updatedAt'] as Timestamp?;
              final bTime = bData['updatedAt'] as Timestamp?;
              
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              
              return bTime.compareTo(aTime);
            });

            return Column(
              children: [
                // Stats Header
                Container(
                  margin: EdgeInsets.all(20),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE535AB), Color(0xFF9D4EDD)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFE535AB).withOpacity(0.3),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${docs.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Total Reviews',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 24),
                              SizedBox(width: 4),
                              Text(
                                _calculateAverageRating(docs).toStringAsFixed(1),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Average Rating',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Reviews List
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final documentId = doc.id;

                      final movieTitle = data['movieTitle'] ?? 'Unknown Movie';
                      final username = data['username'] ?? 'Anonymous';
                      final rating = data['rating'] ?? 0;
                      final review = data['review'] ?? '';
                      final posterPath = data['posterPath'] ?? '';
                      final timestamp = data['updatedAt'] as Timestamp?;
                      final date = timestamp != null 
                          ? _formatDate(timestamp.toDate())
                          : 'Recently';

                      return Container(
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Color(0xFF2A2F4A),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showReviewDetails(context, data),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Movie Poster
                                  Container(
                                    width: 60,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: posterPath.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: MovieService.getTMDBPosterUrl(posterPath),
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Container(
                                                color: Color(0xFF1A1F3A),
                                                child: Icon(
                                                  Icons.movie,
                                                  color: Colors.white54,
                                                  size: 30,
                                                ),
                                              ),
                                              errorWidget: (context, url, error) => Container(
                                                color: Color(0xFF1A1F3A),
                                                child: Icon(
                                                  Icons.movie,
                                                  color: Colors.white54,
                                                  size: 30,
                                                ),
                                              ),
                                            )
                                          : Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [Color(0xFFE535AB), Color(0xFF9D4EDD)],
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.movie_creation,
                                                color: Colors.white,
                                                size: 30,
                                              ),
                                            ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  
                                  // Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Movie Title
                                        Text(
                                          movieTitle,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4),
                                        
                                        // Username
                                        Row(
                                          children: [
                                            Icon(Icons.person, color: Color(0xFFE535AB), size: 14),
                                            SizedBox(width: 4),
                                            Text(
                                              username,
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.6),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        
                                        // Rating Stars
                                        Row(
                                          children: [
                                            ...List.generate(
                                              rating is int ? rating : (rating as double).toInt(),
                                              (starIdx) => Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                                size: 16,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              '($rating/5)',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.6),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        // Review Preview
                                        if (review.isNotEmpty) ...[
                                          SizedBox(height: 8),
                                          Text(
                                            review,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.7),
                                              fontSize: 13,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        
                                        SizedBox(height: 8),
                                        
                                        // Date
                                        Text(
                                          date,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.4),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Delete Button
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, color: Colors.red, size: 22),
                                    onPressed: () => _showDeleteDialog(
                                      context,
                                      documentId,
                                      movieTitle,
                                      username,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  double _calculateAverageRating(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) return 0.0;
    
    double total = 0;
    int count = 0;
    
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final rating = data['rating'];
      if (rating != null && rating > 0) {
        total += (rating is int ? rating.toDouble() : rating as double);
        count++;
      }
    }
    
    return count > 0 ? total / count : 0.0;
  }
}