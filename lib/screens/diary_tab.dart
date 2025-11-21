// screens/diary_tab.dart
import 'package:flutter/material.dart';

class DiaryTab extends StatelessWidget {
  final List<Map<String, dynamic>> recentActivity = [
    {'title': 'The Shawshank Redemption', 'date': '20/11/2025', 'rating': 5},
    {'title': 'The Godfather', 'date': '19/11/2025', 'rating': 5},
    {'title': 'Inception', 'date': '18/11/2025', 'rating': 4},
    {'title': 'Pulp Fiction', 'date': '17/11/2025', 'rating': 5},
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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
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
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFE535AB), Color(0xFF9D4EDD)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFE535AB).withOpacity(0.4),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                ],
              ),
              
              SizedBox(height: 24),
              
              // Statistics Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Movies',
                      '42',
                      Icons.movie_outlined,
                      Color(0xFFE535AB),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Reviews',
                      '17',
                      Icons.rate_review_outlined,
                      Color(0xFF9D4EDD),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 24),
              
              // Recent Activity
              Row(
                children: [
                  Icon(Icons.history, color: Color(0xFFE535AB), size: 22),
                  SizedBox(width: 8),
                  Text(
                    "Recent Activity",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              Expanded(
                child: ListView.builder(
                  itemCount: recentActivity.length,
                  itemBuilder: (ctx, idx) {
                    final item = recentActivity[idx];
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
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
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFE535AB), Color(0xFF9D4EDD)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.movie_creation,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  item['date'],
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: List.generate(
                              item['rating'],
                              (starIdx) => Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                            ),
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
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}