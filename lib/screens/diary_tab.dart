// screens/diary_tab.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/movie_service.dart';

class DiaryTab extends StatefulWidget {
  const DiaryTab({Key? key}) : super(key: key);

  @override
  State<DiaryTab> createState() => _DiaryTabState();
}

class _DiaryTabState extends State<DiaryTab> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0E27),
              Color(0xFF1A1F3A),
            ],
          ),
        ),
        child: Center(
          child: Text(
            'Please login to view your diary',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A0E27),
            Color(0xFF1A1F3A),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "My Diary",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Your movie journey",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Color(0xFF2A2F4A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE535AB), Color(0xFF9D4EDD)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bookmark_border, size: 18),
                        SizedBox(width: 6),
                        Text('Watchlist'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, size: 18),
                        SizedBox(width: 6),
                        Text('Watched'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Watchlist Tab
                  _buildMoviesList(user.uid, isWatchlist: true),
                  // Watched Tab
                  _buildMoviesList(user.uid, isWatchlist: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoviesList(String userId, {required bool isWatchlist}) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('user_movies')
          .where('userId', isEqualTo: userId)
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
                Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red.withOpacity(0.5),
                ),
                SizedBox(height: 16),
                Text(
                  'Error loading movies',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return Center(
            child: Text(
              'No data available',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        // Filter documents based on watchlist or watched status
        final allDocs = snapshot.data!.docs;
        
        final filteredDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          
          if (isWatchlist) {
            // For watchlist: inWatchlist must be true
            return data['inWatchlist'] == true;
          } else {
            // For watched: watched must be true
            return data['watched'] == true;
          }
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isWatchlist ? Icons.bookmark_border : Icons.movie_outlined,
                  size: 80,
                  color: Colors.white.withOpacity(0.3),
                ),
                SizedBox(height: 16),
                Text(
                  isWatchlist ? 'No movies in watchlist' : 'No movies watched yet',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  isWatchlist 
                      ? 'Add movies to watch later!'
                      : 'Start watching and rating movies!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        // Sort by updatedAt manually
        filteredDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['updatedAt'] as Timestamp?;
          final bTime = bData['updatedAt'] as Timestamp?;
          
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          
          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 20),
          itemCount: filteredDocs.length,
          itemBuilder: (ctx, idx) {
            final doc = filteredDocs[idx];
            final data = doc.data() as Map<String, dynamic>;
            
            return _buildMovieCard(data, doc.id);
          },
        );
      },
    );
  }

  Widget _buildMovieCard(Map<String, dynamic> data, String docId) {
    final title = data['movieTitle'] ?? data['title'] ?? 'Unknown Movie';
    final posterPath = data['posterPath'] ?? '';
    final rating = data['rating'] ?? 0;
    final review = data['review'] ?? '';
    final overview = data['overview'] ?? '';
    final timestamp = data['updatedAt'] as Timestamp?;
    final date = timestamp != null 
        ? _formatDate(timestamp.toDate())
        : 'Recently';

    return GestureDetector(
      onTap: () {
        _showMovieDetails(data, docId);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(16),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Movie Poster
            Container(
              width: 80,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: posterPath.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: MovieService.getTMDBPosterUrl(posterPath),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFE535AB), Color(0xFF9D4EDD)],
                            ),
                          ),
                          child: Icon(
                            Icons.movie_creation,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFE535AB), Color(0xFF9D4EDD)],
                            ),
                          ),
                          child: Icon(
                            Icons.movie_creation,
                            color: Colors.white,
                            size: 32,
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
                          size: 32,
                        ),
                      ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),
                  // Date
                  Text(
                    date,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 8),
                  // Rating Stars
                  if (rating > 0)
                    Row(
                      children: List.generate(
                        5,
                        (starIdx) => Icon(
                          starIdx < (rating is int ? rating : (rating as double).toInt())
                              ? Icons.star
                              : Icons.star_border,
                          color: starIdx < (rating is int ? rating : (rating as double).toInt())
                              ? Colors.amber
                              : Colors.white38,
                          size: 18,
                        ),
                      ),
                    ),
                  if (rating > 0) SizedBox(height: 8),
                  // Review preview
                  if (review.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF1A1F3A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        review,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMovieDetails(Map<String, dynamic> data, String docId) {
    final title = data['movieTitle'] ?? data['title'] ?? 'Unknown Movie';
    final posterPath = data['posterPath'] ?? '';
    final rating = data['rating'] ?? 0;
    final review = data['review'] ?? '';
    final overview = data['overview'] ?? 'No synopsis available';
    final releaseDate = data['releaseDate'] ?? '';
    final voteAverage = data['voteAverage'] ?? 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Color(0xFF1A1F3A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            padding: EdgeInsets.all(20),
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white38,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Movie Poster and Title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: posterPath.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: MovieService.getTMDBPosterUrl(posterPath),
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                color: Color(0xFF2A2F4A),
                                child: Icon(Icons.movie, color: Colors.white54),
                              ),
                            )
                          : Container(
                              color: Color(0xFF2A2F4A),
                              child: Icon(Icons.movie, color: Colors.white54, size: 50),
                            ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        if (releaseDate.isNotEmpty)
                          Text(
                            releaseDate.split('-')[0],
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            SizedBox(width: 4),
                            Text(
                              voteAverage.toStringAsFixed(1),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              ' / 10',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
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
              
              // Your Rating
              if (rating > 0) ...[
                Text(
                  'Your Rating',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: List.generate(
                    5,
                    (starIdx) => Icon(
                      starIdx < (rating is int ? rating : (rating as double).toInt())
                          ? Icons.star
                          : Icons.star_border,
                      color: starIdx < (rating is int ? rating : (rating as double).toInt())
                          ? Colors.amber
                          : Colors.white38,
                      size: 28,
                    ),
                  ),
                ),
                SizedBox(height: 24),
              ],
              
              // Your Review
              if (review.isNotEmpty) ...[
                Text(
                  'Your Review',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF0A0E27),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    review,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: 24),
              ],
              
              // Synopsis
              Text(
                'Synopsis',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                overview,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}