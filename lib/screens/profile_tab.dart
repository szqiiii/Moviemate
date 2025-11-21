import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ProfileTab extends StatefulWidget {
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool notificationsEnabled = true;

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
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Header
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Color(0xFF2A2F4A),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFE535AB), Color(0xFF9D4EDD)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFE535AB).withOpacity(0.4),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Steffi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '@stefflovesmovie',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn('42', 'Movies'),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        _buildStatColumn('17', 'Reviews'),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        _buildStatColumn('128', 'Followers'),
                      ],
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Settings Section
              _buildSectionTitle('Settings'),
              
              SizedBox(height: 12),
              
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF2A2F4A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      trailing: Switch(
                        value: notificationsEnabled,
                        onChanged: (val) {
                          setState(() => notificationsEnabled = val);
                        },
                        activeColor: Color(0xFFE535AB),
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark Mode',
                      trailing: Icon(
                        Icons.chevron_right,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.language_outlined,
                      title: 'Language',
                      trailing: Icon(
                        Icons.chevron_right,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Account Section
              _buildSectionTitle('Account'),
              
              SizedBox(height: 12),
              
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF2A2F4A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.person_outline,
                      title: 'Edit Profile',
                      trailing: Icon(
                        Icons.chevron_right,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.lock_outline,
                      title: 'Privacy & Security',
                      trailing: Icon(
                        Icons.chevron_right,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Support Section
              _buildSectionTitle('Support'),
              
              SizedBox(height: 12),
              
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF2A2F4A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      trailing: Icon(
                        Icons.chevron_right,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.info_outline,
                      title: 'About',
                      trailing: Icon(
                        Icons.chevron_right,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Logout Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color(0xFF2A2F4A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      await AuthService().logout();
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: Colors.red, size: 22),
                          SizedBox(width: 12),
                          Text(
                            'Log Out',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFE535AB).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Color(0xFFE535AB), size: 22),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        color: Colors.white.withOpacity(0.1),
        height: 1,
      ),
    );
  }
}