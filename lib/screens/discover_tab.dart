// screens/discover_tab.dart
import 'package:flutter/material.dart';

class DiscoverTab extends StatelessWidget {
  final List<Map<String, dynamic>> trendingMovies = [
    {'title': 'The Shawshank Redemption', 'rating': 4.8, 'color': Color(0xFF8B7355)},
    {'title': 'The Godfather', 'rating': 4.7, 'color': Color(0xFF2C2C3E)},
    {'title': 'Inception', 'rating': 4.6, 'color': Color(0xFFD81B60)},
    {'title': 'Pulp Fiction', 'rating': 4.5, 'color': Color(0xFFFFA726)},
  ];

  final List<Map<String, dynamic>> recentlyWatched = [
    {'title': 'The Shawshank Redemption', 'rating': 4.8, 'color': Color(0xFF8B7355)},
    {'title': 'The Godfather', 'rating': 4.7, 'color': Color(0xFF2C2C3E)},
    {'title': 'Inception', 'rating': 4.6, 'color': Color(0xFFD81B60)},
  ];

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
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
          children: [
            // Trending Now Section
            Row(
              children: [
                Icon(Icons.local_fire_department, color: Color(0xFFE535AB), size: 24),
                SizedBox(width: 8),
                Text(
                  "Trending Now",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Trending Movies Grid
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: trendingMovies.length,
                itemBuilder: (ctx, idx) {
                  final movie = trendingMovies[idx];
                  
                  return Container(
                    width: 160,
                    margin: EdgeInsets.only(right: 16),
                    child: Stack(
                      children: [
                        Container(
                          height: 220,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: movie['color'],
                            boxShadow: [
                              BoxShadow(
                                color: movie['color'].withOpacity(0.4),
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              idx == 0 ? Icons.movie_creation :
                              idx == 1 ? Icons.movie_filter :
                              idx == 2 ? Icons.theaters :
                              Icons.local_movies,
                              size: 60,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  movie['rating'].toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            SizedBox(height: 32),
            
            // Recently Watched Section
            Row(
              children: [
                Icon(Icons.history, color: Color(0xFFE535AB), size: 24),
                SizedBox(width: 8),
                Text(
                  "Recently Watched",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Recently Watched Grid
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recentlyWatched.length,
                itemBuilder: (ctx, idx) {
                  final movie = recentlyWatched[idx];
                  
                  return Container(
                    width: 160,
                    margin: EdgeInsets.only(right: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Container(
                              height: 220,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: movie['color'],
                                boxShadow: [
                                  BoxShadow(
                                    color: movie['color'].withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  idx == 0 ? Icons.movie_creation :
                                  idx == 1 ? Icons.movie_filter :
                                  Icons.theaters,
                                  size: 60,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      movie['rating'].toString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}