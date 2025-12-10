// screens/discover_tab.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/movie_service.dart';
import '../models/tmdb_movie.dart';
import 'movie_details_screen.dart';

class DiscoverTab extends StatefulWidget {
  @override
  State<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<DiscoverTab> {
  final MovieService _movieService = MovieService();
  
  List<TMDBMovie> _trendingMovies = [];
  List<TMDBMovie> _allMovies = [];
  
  bool _isLoading = true;
  String _selectedCategory = 'Popular';

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    try {
      final movies = await _movieService.getTMDBPopularMovies();
      setState(() {
        _trendingMovies = movies;
        _allMovies = movies;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading movies: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      // You can add different filtering logic here
      // For now, we'll just update the selected category
    });
  }

  Widget _buildCategoryChip(String label, {required bool isSelected}) {
    return GestureDetector(
      onTap: () => _filterByCategory(label),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Color(0xFFE535AB), Color(0xFF9D4EDD)],
                )
              : null,
          color: isSelected ? null : Color(0xFF2A2F4A),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFFE535AB).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMovieGrid(List<TMDBMovie> movies) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.55,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: movies.length,
      itemBuilder: (ctx, idx) {
        final movie = movies[idx];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MovieDetailsScreen(movie: movie),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Movie Poster
              Expanded(
                child: Container(
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
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: MovieService.getTMDBPosterUrl(movie.posterPath),
                          fit: BoxFit.cover,
                          width: double.infinity,
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
                            child: Icon(
                              Icons.movie,
                              color: Colors.white54,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                      // Rating Badge
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 10),
                              SizedBox(width: 2),
                              Text(
                                movie.voteAverage.toStringAsFixed(1),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8),
              // Movie Title
              Text(
                movie.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2),
              // Release Year
              Text(
                movie.releaseDate?.split('-')[0] ?? 'N/A',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE535AB)),
                ),
              )
            : Column(
                children: [
                  // Header Section
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          'Discover',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 20),

                        // Category Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildCategoryChip(
                                'Trending',
                                isSelected: _selectedCategory == 'Trending',
                              ),
                              SizedBox(width: 12),
                              _buildCategoryChip(
                                'Popular',
                                isSelected: _selectedCategory == 'Popular',
                              ),
                              SizedBox(width: 12),
                              _buildCategoryChip(
                                'Top Rated',
                                isSelected: _selectedCategory == 'Top Rated',
                              ),
                              SizedBox(width: 12),
                              _buildCategoryChip(
                                'Upcoming',
                                isSelected: _selectedCategory == 'Upcoming',
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 20),

                        // Section Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'All Movies',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            DropdownButton<String>(
                              value: _selectedCategory,
                              dropdownColor: Color(0xFF2A2F4A),
                              icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                              underline: SizedBox(),
                              style: TextStyle(color: Colors.white, fontSize: 14),
                              items: ['Popular', 'Top Rated', 'Trending', 'Upcoming']
                                  .map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  _filterByCategory(newValue);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Movies Grid
                  Expanded(
                    child: _allMovies.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.movie_outlined,
                                  size: 80,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No movies available',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              _buildMovieGrid(_allMovies),
                              SizedBox(height: 20),
                            ],
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}