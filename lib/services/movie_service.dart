import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/tmdb_movie.dart';

class MovieService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // TMDB API Configuration
  static const String tmdbApiKey = '1ad1467e0efdccd58c70659f4bc3c982';
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  // ========== FIREBASE METHODS (Your existing code) ==========

  /// Add a new movie (Admin only)
  Future<Map<String, dynamic>> addMovie({
    required String title,
    required String description,
    required String genre,
    required String year,
    required String addedBy,
    double rating = 0.0,
    String? posterUrl,
    String? trailerUrl,
  }) async {
    try {
      await _firestore.collection('movies').add({
        'title': title,
        'description': description,
        'genre': genre,
        'year': year,
        'rating': rating,
        'posterUrl': posterUrl,
        'trailerUrl': trailerUrl,
        'addedBy': addedBy,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Movie added successfully'};
    } catch (e) {
      print('Add movie error: $e');
      return {'success': false, 'message': 'Failed to add movie'};
    }
  }

  /// Get all movies
  Stream<QuerySnapshot> getAllMovies() {
    return _firestore
        .collection('movies')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Search movies
  Future<List<Map<String, dynamic>>> searchMovies(String query) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('movies')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      print('Search movies error: $e');
      return [];
    }
  }

  /// Update movie (Admin only)
  Future<Map<String, dynamic>> updateMovie(
      String movieId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('movies').doc(movieId).update(updates);
      return {'success': true, 'message': 'Movie updated successfully'};
    } catch (e) {
      print('Update movie error: $e');
      return {'success': false, 'message': 'Failed to update movie'};
    }
  }

  /// Delete movie (Admin only)
  Future<Map<String, dynamic>> deleteMovie(String movieId) async {
    try {
      await _firestore.collection('movies').doc(movieId).delete();
      return {'success': true, 'message': 'Movie deleted successfully'};
    } catch (e) {
      print('Delete movie error: $e');
      return {'success': false, 'message': 'Failed to delete movie'};
    }
  }

  /// Get movie by ID
  Future<Map<String, dynamic>?> getMovieById(String movieId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('movies').doc(movieId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    } catch (e) {
      print('Get movie error: $e');
      return null;
    }
  }

  // ========== TMDB API METHODS ==========

  /// Get popular movies from TMDB
  Future<List<TMDBMovie>> getTMDBPopularMovies() async {
    try {
      final response = await http.get(
        Uri.parse('$tmdbBaseUrl/movie/popular?api_key=$tmdbApiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<TMDBMovie> movies = [];

        for (var item in data['results']) {
          movies.add(TMDBMovie.fromJson(item));
        }

        return movies;
      } else {
        throw Exception('Failed to load movies');
      }
    } catch (e) {
      print('TMDB popular movies error: $e');
      return [];
    }
  }

  /// Get trending movies from TMDB (trending this week)
  Future<List<TMDBMovie>> getTMDBTrendingMovies() async {
    try {
      final response = await http.get(
        Uri.parse('$tmdbBaseUrl/trending/movie/week?api_key=$tmdbApiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<TMDBMovie> movies = [];

        for (var item in data['results']) {
          movies.add(TMDBMovie.fromJson(item));
        }

        return movies;
      } else {
        throw Exception('Failed to load trending movies');
      }
    } catch (e) {
      print('TMDB trending movies error: $e');
      return [];
    }
  }

  /// Get top rated movies from TMDB
  Future<List<TMDBMovie>> getTMDBTopRatedMovies() async {
    try {
      final response = await http.get(
        Uri.parse('$tmdbBaseUrl/movie/top_rated?api_key=$tmdbApiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<TMDBMovie> movies = [];

        for (var item in data['results']) {
          movies.add(TMDBMovie.fromJson(item));
        }

        return movies;
      } else {
        throw Exception('Failed to load top rated movies');
      }
    } catch (e) {
      print('TMDB top rated movies error: $e');
      return [];
    }
  }

  /// Get upcoming movies from TMDB
  Future<List<TMDBMovie>> getTMDBUpcomingMovies() async {
    try {
      final response = await http.get(
        Uri.parse('$tmdbBaseUrl/movie/upcoming?api_key=$tmdbApiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<TMDBMovie> movies = [];

        for (var item in data['results']) {
          movies.add(TMDBMovie.fromJson(item));
        }

        return movies;
      } else {
        throw Exception('Failed to load upcoming movies');
      }
    } catch (e) {
      print('TMDB upcoming movies error: $e');
      return [];
    }
  }

  /// Search movies on TMDB
  Future<List<TMDBMovie>> searchTMDBMovies(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$tmdbBaseUrl/search/movie?api_key=$tmdbApiKey&query=$query'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<TMDBMovie> movies = [];

        for (var item in data['results']) {
          movies.add(TMDBMovie.fromJson(item));
        }

        return movies;
      } else {
        throw Exception('Failed to search movies');
      }
    } catch (e) {
      print('TMDB search error: $e');
      return [];
    }
  }

  /// Get movie details from TMDB
  Future<TMDBMovie?> getTMDBMovieDetails(int movieId) async {
    try {
      final response = await http.get(
        Uri.parse('$tmdbBaseUrl/movie/$movieId?api_key=$tmdbApiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TMDBMovie.fromJson(data);
      }
      return null;
    } catch (e) {
      print('TMDB movie details error: $e');
      return null;
    }
  }

  /// Get full poster URL from TMDB
  static String getTMDBPosterUrl(String? posterPath) {
    if (posterPath == null || posterPath.isEmpty) {
      return 'https://via.placeholder.com/500x750?text=No+Poster';
    }
    return '$imageBaseUrl$posterPath';
  }
}