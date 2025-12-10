import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/movie_service.dart';
import '../services/auth_service.dart';
import '../models/tmdb_movie.dart';

class AdminMoviesScreen extends StatefulWidget {
  @override
  State<AdminMoviesScreen> createState() => _AdminMoviesScreenState();
}

class _AdminMoviesScreenState extends State<AdminMoviesScreen> {
  final MovieService _movieService = MovieService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  List<TMDBMovie> _tmdbSearchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Search TMDB movies to add
  Future<void> _searchTMDBMovies(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _tmdbSearchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _movieService.searchTMDBMovies(query);
      setState(() {
        _tmdbSearchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      print('TMDB search error: $e');
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching movies: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show dialog to search and add movie from TMDB
  void _showAddMovieFromTMDBDialog() {
    _searchController.clear();
    setState(() {
      _tmdbSearchResults = [];
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Color(0xFF2A2F4A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Add Movie from TMDB', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Container(
            width: double.maxFinite,
            height: 500,
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  style: TextStyle(color: Colors.white),
                  onChanged: (value) {
                    if (value.isEmpty) {
                      setDialogState(() {
                        _tmdbSearchResults = [];
                      });
                    }
                  },
                  onSubmitted: (value) async {
                    await _searchTMDBMovies(value);
                    setDialogState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Search movies on TMDB...',
                    hintStyle: TextStyle(color: Colors.white54),
                    prefixIcon: Icon(Icons.search, color: Color(0xFFE535AB)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                              setDialogState(() {
                                _tmdbSearchResults = [];
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Color(0xFF0A0E27),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Search Results
                Expanded(
                  child: _isSearching
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE535AB)),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Searching TMDB...',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ],
                          ),
                        )
                      : _tmdbSearchResults.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.movie_outlined, color: Colors.white30, size: 64),
                                  SizedBox(height: 16),
                                  Text(
                                    'Search for movies to add',
                                    style: TextStyle(color: Colors.white54, fontSize: 16),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Press Enter to search',
                                    style: TextStyle(color: Colors.white38, fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _tmdbSearchResults.length,
                              itemBuilder: (ctx, idx) {
                                final movie = _tmdbSearchResults[idx];
                                return Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF0A0E27),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.all(8),
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: MovieService.getTMDBPosterUrl(movie.posterPath),
                                        width: 50,
                                        height: 75,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          color: Color(0xFF1A1F3A),
                                          child: Icon(Icons.movie, color: Colors.white54, size: 24),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          color: Color(0xFF1A1F3A),
                                          child: Icon(Icons.movie, color: Colors.white54, size: 24),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      movie.title,
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      '${movie.releaseDate?.split('-')[0] ?? 'N/A'} • ⭐ ${movie.voteAverage.toStringAsFixed(1)}',
                                      style: TextStyle(color: Colors.white54, fontSize: 12),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(Icons.add_circle, color: Color(0xFFE535AB), size: 28),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _addMovieFromTMDB(movie);
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }

  // Add movie from TMDB to Firebase
  Future<void> _addMovieFromTMDB(TMDBMovie movie) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    try {
      // Check if movie already exists in Firebase
      final existingMovies = await _firestore
          .collection('movies')
          .where('title', isEqualTo: movie.title)
          .where('year', isEqualTo: movie.releaseDate?.split('-')[0] ?? 'Unknown')
          .get();

      if (existingMovies.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Movie already exists in database'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Add movie to Firebase
      await _firestore.collection('movies').add({
        'title': movie.title,
        'description': movie.overview ?? 'No description available',
        'genre': 'Various', // You can map genreIds to genre names if needed
        'year': movie.releaseDate?.split('-')[0] ?? 'Unknown',
        'rating': (movie.voteAverage / 2).toDouble(), // Convert 10-point to 5-point scale
        'posterUrl': movie.posterPath,
        'addedBy': currentUser?.uid ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'tmdbId': movie.id,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Movie "${movie.title}" added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error adding movie: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add movie: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show manual add dialog
  void _showManualAddDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final genreController = TextEditingController();
    final yearController = TextEditingController();
    final ratingController = TextEditingController();
    final posterUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2A2F4A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add Movie Manually', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(titleController, 'Title', Icons.movie),
              SizedBox(height: 16),
              _buildTextField(descriptionController, 'Description', Icons.description, maxLines: 3),
              SizedBox(height: 16),
              _buildTextField(genreController, 'Genre', Icons.category),
              SizedBox(height: 16),
              _buildTextField(yearController, 'Year', Icons.calendar_today),
              SizedBox(height: 16),
              _buildTextField(ratingController, 'Rating (0-5)', Icons.star, keyboardType: TextInputType.number),
              SizedBox(height: 16),
              _buildTextField(posterUrlController, 'Poster Path (optional)', Icons.image),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE535AB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Title and description are required'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              final authService = Provider.of<AuthService>(context, listen: false);
              final currentUser = authService.currentUser;

              try {
                await _firestore.collection('movies').add({
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'genre': genreController.text.trim().isNotEmpty ? genreController.text.trim() : 'Unknown',
                  'year': yearController.text.trim().isNotEmpty ? yearController.text.trim() : 'Unknown',
                  'rating': double.tryParse(ratingController.text) ?? 0.0,
                  'posterUrl': posterUrlController.text.trim().isNotEmpty ? posterUrlController.text.trim() : null,
                  'addedBy': currentUser?.uid ?? '',
                  'createdAt': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Movie added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                print('Error adding movie: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to add movie: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Add Movie', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Show edit dialog
  void _showEditDialog(String movieId, Map<String, dynamic> currentData) {
    final titleController = TextEditingController(text: currentData['title'] ?? '');
    final descriptionController = TextEditingController(text: currentData['description'] ?? '');
    final genreController = TextEditingController(text: currentData['genre'] ?? '');
    final yearController = TextEditingController(text: currentData['year'] ?? '');
    final ratingController = TextEditingController(text: currentData['rating']?.toString() ?? '');
    final posterUrlController = TextEditingController(text: currentData['posterUrl'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2A2F4A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Movie', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(titleController, 'Title', Icons.movie),
              SizedBox(height: 16),
              _buildTextField(descriptionController, 'Description', Icons.description, maxLines: 3),
              SizedBox(height: 16),
              _buildTextField(genreController, 'Genre', Icons.category),
              SizedBox(height: 16),
              _buildTextField(yearController, 'Year', Icons.calendar_today),
              SizedBox(height: 16),
              _buildTextField(ratingController, 'Rating (0-5)', Icons.star, keyboardType: TextInputType.number),
              SizedBox(height: 16),
              _buildTextField(posterUrlController, 'Poster Path', Icons.image),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE535AB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Title and description are required'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                await _firestore.collection('movies').doc(movieId).update({
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'genre': genreController.text.trim().isNotEmpty ? genreController.text.trim() : 'Unknown',
                  'year': yearController.text.trim().isNotEmpty ? yearController.text.trim() : 'Unknown',
                  'rating': double.tryParse(ratingController.text) ?? 0.0,
                  'posterUrl': posterUrlController.text.trim().isNotEmpty ? posterUrlController.text.trim() : null,
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Movie updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                print('Error updating movie: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update movie: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Show delete dialog
  void _showDeleteDialog(String movieId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2A2F4A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Delete Movie', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$title"?\n\nThis action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              try {
                await _firestore.collection('movies').doc(movieId).delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Movie deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                print('Error deleting movie: $e');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete movie: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: Colors.white),
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Color(0xFFE535AB)),
        filled: true,
        fillColor: Color(0xFF0A0E27),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE535AB), width: 2),
        ),
      ),
    );
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
          'Manage Movies',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.add_circle, color: Color(0xFFE535AB), size: 28),
            color: Color(0xFF2A2F4A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'tmdb') {
                _showAddMovieFromTMDBDialog();
              } else {
                _showManualAddDialog();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'tmdb',
                child: Row(
                  children: [
                    Icon(Icons.cloud_download, color: Color(0xFFE535AB)),
                    SizedBox(width: 12),
                    Text('Add from TMDB', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'manual',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Color(0xFF9D4EDD)),
                    SizedBox(width: 12),
                    Text('Add Manually', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(width: 8),
        ],
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
          stream: _firestore.collection('movies').snapshots(),
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
                      'Error loading movies',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
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
                    Icon(Icons.movie_outlined, color: Colors.white30, size: 80),
                    SizedBox(height: 16),
                    Text(
                      'No movies yet',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add your first movie to get started',
                      style: TextStyle(color: Colors.white38, fontSize: 14),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showAddMovieFromTMDBDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFE535AB),
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(Icons.add, color: Colors.white),
                      label: Text('Add First Movie', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            }

            final docs = snapshot.data!.docs;

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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.movie, color: Colors.white, size: 32),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${docs.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Total Movies',
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

                // Movies List
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final movie = doc.data() as Map<String, dynamic>;
                      final movieId = doc.id;
                      final posterPath = movie['posterUrl'];

                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
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
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
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
                                  child: posterPath != null && posterPath.toString().isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: MovieService.getTMDBPosterUrl(posterPath),
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Color(0xFFE535AB), Color(0xFF9D4EDD)],
                                              ),
                                            ),
                                            child: Icon(Icons.movie, color: Colors.white, size: 30),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Color(0xFFE535AB), Color(0xFF9D4EDD)],
                                              ),
                                            ),
                                            child: Icon(Icons.movie, color: Colors.white, size: 30),
                                          ),
                                        )
                                      : Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Color(0xFFE535AB), Color(0xFF9D4EDD)],
                                            ),
                                          ),
                                          child: Icon(Icons.movie, color: Colors.white, size: 30),
                                        ),
                                ),
                              ),
                              SizedBox(width: 16),
                              
                              // Movie Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      movie['title'] ?? 'Untitled',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '${movie['genre'] ?? 'Unknown'} • ${movie['year'] ?? 'N/A'}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 13,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.star, color: Colors.amber, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          '${movie['rating'] ?? 0.0}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Action Buttons
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Color(0xFFE535AB), size: 22),
                                    onPressed: () => _showEditDialog(movieId, movie),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red, size: 22),
                                    onPressed: () => _showDeleteDialog(movieId, movie['title']),
                                  ),
                                ],
                              ),
                            ],
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
}