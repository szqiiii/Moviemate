import 'package:flutter/material.dart';

class SearchTab extends StatefulWidget {
  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _searchController = TextEditingController();
  
  final List<Map<String, dynamic>> searchResults = [
    {'title': 'The Dark Knight', 'genre': 'Action, Crime', 'year': '2008', 'rating': 4.9},
    {'title': 'Interstellar', 'genre': 'Sci-Fi, Drama', 'year': '2014', 'rating': 4.8},
    {'title': 'Parasite', 'genre': 'Thriller, Drama', 'year': '2019', 'rating': 4.7},
    {'title': 'The Matrix', 'genre': 'Sci-Fi, Action', 'year': '1999', 'rating': 4.6},
    {'title': 'Forrest Gump', 'genre': 'Drama, Romance', 'year': '1994', 'rating': 4.8},
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
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF2A2F4A),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Search movies...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    prefixIcon: Icon(Icons.search, color: Color(0xFFE535AB), size: 24),
                    suffixIcon: Icon(Icons.mic, color: Color(0xFFE535AB), size: 24),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),
              
              SizedBox(height: 20),
              
              // Filter Chips
              Row(
                children: [
                  _buildFilterChip('All', true),
                  SizedBox(width: 12),
                  _buildFilterChip('Movies', false),
                  SizedBox(width: 12),
                  _buildFilterChip('TV Shows', false),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(0xFF2A2F4A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.tune, color: Color(0xFFE535AB), size: 20),
                  ),
                ],
              ),
              
              SizedBox(height: 24),
              
              // Search Results
              Text(
                'Search Results',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              SizedBox(height: 16),
              
              Expanded(
                child: ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (ctx, idx) {
                    final movie = searchResults[idx];
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
                      child: ListTile(
                        contentPadding: EdgeInsets.all(12),
                        leading: Container(
                          width: 60,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [Color(0xFFE535AB), Color(0xFF9D4EDD)],
                            ),
                          ),
                          child: Icon(Icons.movie, color: Colors.white, size: 30),
                        ),
                        title: Text(
                          movie['title'],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${movie['genre']} • ${movie['year']}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.star, color: Colors.amber, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    movie['rating'].toString(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Color(0xFFE535AB) : Color(0xFF2A2F4A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}