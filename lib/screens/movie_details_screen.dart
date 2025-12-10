// screens/movie_details_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tmdb_movie.dart';
import '../services/movie_service.dart';

class MovieDetailsScreen extends StatefulWidget {
  final TMDBMovie movie;

  const MovieDetailsScreen({Key? key, required this.movie}) : super(key: key);

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _reviewController = TextEditingController();
  
  bool isWatched = false;
  bool isWatchlist = false;
  int selectedRating = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkWatchedStatus();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _checkWatchedStatus() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore
          .collection('user_movies')
          .doc('${user.uid}_${widget.movie.id}')
          .get();

      if (doc.exists) {
        setState(() {
          isWatched = doc.data()?['watched'] ?? false;
          isWatchlist = doc.data()?['inWatchlist'] ?? false; // FIXED: Changed from 'watchlist' to 'inWatchlist'
          selectedRating = doc.data()?['rating'] ?? 0;
          _reviewController.text = doc.data()?['review'] ?? '';
        });
      }
    } catch (e) {
      print('Error checking watched status: $e');
    }
  }

  Future<void> _saveMovieData() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please login first')),
      );
      return;
    }

    if (selectedRating == 0 && !isWatched) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please rate the movie or mark as watched')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore.collection('user_movies').doc('${user.uid}_${widget.movie.id}').set({
        'userId': user.uid,
        'movieId': widget.movie.id.toString(),
        'movieTitle': widget.movie.title,
        'posterPath': widget.movie.posterPath,
        'overview': widget.movie.overview ?? '',
        'rating': selectedRating,
        'review': _reviewController.text.trim(),
        'watched': isWatched || selectedRating > 0,
        'inWatchlist': isWatchlist, // FIXED: Changed from 'watchlist' to 'inWatchlist'
        'releaseDate': widget.movie.releaseDate,
        'voteAverage': widget.movie.voteAverage,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        if (selectedRating > 0) {
          isWatched = true;
        }
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Movie saved successfully!'),
          backgroundColor: Color(0xFFE535AB),
        ),
      );

      await Future.delayed(Duration(milliseconds: 500));
      Navigator.pop(context, {'saved': true});
    } catch (e) {
      print('Error saving movie data: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save movie data')),
      );
    }
  }

  Future<void> _toggleWatchlist() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      isWatchlist = !isWatchlist;
    });

    try {
      await _firestore.collection('user_movies').doc('${user.uid}_${widget.movie.id}').set({
        'userId': user.uid,
        'movieId': widget.movie.id.toString(),
        'movieTitle': widget.movie.title,
        'posterPath': widget.movie.posterPath,
        'overview': widget.movie.overview ?? '',
        'watched': isWatched,
        'inWatchlist': isWatchlist, // FIXED: Changed from 'watchlist' to 'inWatchlist'
        'releaseDate': widget.movie.releaseDate,
        'voteAverage': widget.movie.voteAverage,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isWatchlist ? 'Added to watchlist' : 'Removed from watchlist'),
          backgroundColor: Color(0xFFE535AB),
        ),
      );
    } catch (e) {
      print('Error toggling watchlist: $e');
      setState(() {
        isWatchlist = !isWatchlist; // Revert on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update watchlist')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E27),
      body: CustomScrollView(
        slivers: [
          // App Bar with Backdrop
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Color(0xFF0A0E27),
            leading: IconButton(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: MovieService.getTMDBPosterUrl(
                      widget.movie.backdropPath ?? widget.movie.posterPath,
                    ),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Color(0xFF1A1F3A),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE535AB)),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Color(0xFF1A1F3A),
                      child: Icon(Icons.movie, color: Colors.white54, size: 60),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0xFF0A0E27).withOpacity(0.7),
                          Color(0xFF0A0E27),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.movie.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 12),

                  // Year and Genre
                  Row(
                    children: [
                      Text(
                        widget.movie.releaseDate?.split('-')[0] ?? 'N/A',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 16),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFE535AB), Color(0xFF9D4EDD)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Movie',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // TMDB Rating
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 24),
                      SizedBox(width: 8),
                      Text(
                        '${widget.movie.voteAverage.toStringAsFixed(1)} / 10',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '(TMDB)',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Watched and Watchlist Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              isWatched = !isWatched;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isWatched ? Color(0xFFE535AB) : Color(0xFF2A2F4A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isWatched ? Color(0xFFE535AB) : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isWatched ? Icons.check_circle : Icons.circle_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Watched',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _toggleWatchlist,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isWatchlist ? Color(0xFF9D4EDD) : Color(0xFF2A2F4A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isWatchlist ? Color(0xFF9D4EDD) : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isWatchlist ? Icons.bookmark : Icons.bookmark_border,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Watchlist',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 32),

                  // Rate this movie
                  Text(
                    'Rate this movie',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    'Tap stars to rate (optional)',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),

                  SizedBox(height: 16),

                  // Star Rating with counter
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedRating = index + 1;
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(
                              index < selectedRating ? Icons.star : Icons.star_border,
                              color: index < selectedRating
                                  ? Colors.amber
                                  : Colors.white.withOpacity(0.3),
                              size: 40,
                            ),
                          ),
                        );
                      }),
                      SizedBox(width: 12),
                      if (selectedRating > 0)
                        Text(
                          '$selectedRating/5',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Add written review section
                  Text(
                    'Write a review (optional)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  SizedBox(height: 12),

                  TextField(
                    controller: _reviewController,
                    maxLines: 4,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Share your thoughts about this movie...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                      filled: true,
                      fillColor: Color(0xFF2A2F4A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Save Button
                  GestureDetector(
                    onTap: _isLoading ? null : _saveMovieData,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFE535AB), Color(0xFF9D4EDD)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFE535AB).withOpacity(0.4),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Save to Diary',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),

                  SizedBox(height: 32),

                  // Synopsis
                  Text(
                    'Synopsis',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 12),

                  Text(
                    widget.movie.overview ?? 'No synopsis available.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),

                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}