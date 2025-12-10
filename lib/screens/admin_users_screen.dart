import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AdminUsersScreen extends StatefulWidget {
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  bool loading = true;
  String searchQuery = '';
  String filterRole = 'all'; // all, admin, user
  String filterStatus = 'all'; // all, active, disabled

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => loading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final allUsers = await authService.getAllUsers();
      
      setState(() {
        users = allUsers;
        _applyFilters();
        loading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading users'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _applyFilters() {
    filteredUsers = users.where((user) {
      // Search filter
      final matchesSearch = searchQuery.isEmpty ||
          (user['username'] ?? '').toLowerCase().contains(searchQuery.toLowerCase()) ||
          (user['email'] ?? '').toLowerCase().contains(searchQuery.toLowerCase());
      
      // Role filter
      final matchesRole = filterRole == 'all' || user['role'] == filterRole;
      
      // Status filter
      final isDisabled = user['disabled'] == true;
      final matchesStatus = filterStatus == 'all' ||
          (filterStatus == 'active' && !isDisabled) ||
          (filterStatus == 'disabled' && isDisabled);
      
      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }

  Future<void> _changeUserRole(String userId, String currentRole) async {
    final newRole = currentRole == 'admin' ? 'user' : 'admin';
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1F3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Change User Role', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change role from:',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                _buildRoleBadge(currentRole),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: Color(0xFFE535AB), size: 20),
                SizedBox(width: 8),
                _buildRoleBadge(newRole),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will change the user\'s permissions immediately.',
                      style: TextStyle(color: Colors.amber, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE535AB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Change Role'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.updateUserRole(userId, newRole);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );

      if (result['success']) {
        _loadUsers();
      }
    }
  }

  Future<void> _toggleUserStatus(String userId, String username, bool currentlyDisabled) async {
    final action = currentlyDisabled ? 'activate' : 'deactivate';
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1F3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '${action == 'activate' ? 'Activate' : 'Deactivate'} Account',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to $action this account?',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF2A2F4A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Username: $username',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'User ID: ${userId.substring(0, 10)}...',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (action == 'deactivate' ? Colors.red : Colors.green).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (action == 'deactivate' ? Colors.red : Colors.green).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    action == 'deactivate' ? Icons.lock : Icons.lock_open,
                    color: action == 'deactivate' ? Colors.red : Colors.green,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      action == 'deactivate'
                          ? 'User will not be able to login'
                          : 'User will be able to login again',
                      style: TextStyle(
                        color: action == 'deactivate' ? Colors.red : Colors.green,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'deactivate' ? Colors.red : Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(action == 'activate' ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('users').doc(userId).update({
          'disabled': !currentlyDisabled,
          'disabledAt': !currentlyDisabled ? FieldValue.serverTimestamp() : null,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account ${action}d successfully'),
            backgroundColor: action == 'activate' ? Colors.green : Colors.orange,
          ),
        );

        _loadUsers();
      } catch (e) {
        print('Error toggling user status: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to $action account'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showUserDetails(Map<String, dynamic> user) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Color(0xFF1A1F3A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile header
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFE535AB), Color(0xFF9D4EDD)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                (user['username'] ?? 'U')[0].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            user['username'] ?? 'Unknown',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          _buildRoleBadge(user['role'] ?? 'user'),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Account details
                    _buildDetailSection('Account Details', [
                      _buildDetailRow(Icons.email, 'Email', user['email'] ?? 'N/A'),
                      _buildDetailRow(Icons.fingerprint, 'User ID', user['uid'] ?? 'N/A'),
                      _buildDetailRow(
                        Icons.access_time,
                        'Created',
                        user['createdAt'] != null
                            ? _formatTimestamp(user['createdAt'])
                            : 'Unknown',
                      ),
                      if (user['disabled'] == true)
                        _buildDetailRow(
                          Icons.lock,
                          'Status',
                          'DISABLED',
                          valueColor: Colors.red,
                        )
                      else
                        _buildDetailRow(
                          Icons.check_circle,
                          'Status',
                          'ACTIVE',
                          valueColor: Colors.green,
                        ),
                    ]),
                    
                    SizedBox(height: 24),
                    
                    // Action buttons
                    _buildDetailSection('Actions', []),
                    SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _changeUserRole(user['uid'], user['role']);
                            },
                            icon: Icon(Icons.swap_horiz, size: 20),
                            label: Text('Change Role'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Color(0xFFE535AB),
                              side: BorderSide(color: Color(0xFFE535AB)),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _toggleUserStatus(
                                user['uid'],
                                user['username'],
                                user['disabled'] == true,
                              );
                            },
                            icon: Icon(
                              user['disabled'] == true ? Icons.lock_open : Icons.lock,
                              size: 20,
                            ),
                            label: Text(user['disabled'] == true ? 'Activate' : 'Deactivate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: user['disabled'] == true
                                  ? Colors.green
                                  : Colors.orange,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  Widget _buildRoleBadge(String role) {
    final isAdmin = role == 'admin';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAdmin
            ? Color(0xFFE535AB).withOpacity(0.2)
            : Color(0xFF9D4EDD).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAdmin ? Color(0xFFE535AB) : Color(0xFF9D4EDD),
        ),
      ),
      child: Text(
        isAdmin ? 'ADMIN' : 'USER',
        style: TextStyle(
          color: isAdmin ? Color(0xFFE535AB) : Color(0xFF9D4EDD),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFFE535AB), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
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
          'Manage Users',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadUsers,
          ),
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
        child: Column(
          children: [
            // Search and filters
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // Search bar
                  TextField(
                    style: TextStyle(color: Colors.white),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                        _applyFilters();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      hintStyle: TextStyle(color: Colors.white54),
                      prefixIcon: Icon(Icons.search, color: Color(0xFFE535AB)),
                      filled: true,
                      fillColor: Color(0xFF2A2F4A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Filter chips
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('All', filterRole == 'all', () {
                                setState(() {
                                  filterRole = 'all';
                                  _applyFilters();
                                });
                              }),
                              SizedBox(width: 8),
                              _buildFilterChip('Admins', filterRole == 'admin', () {
                                setState(() {
                                  filterRole = 'admin';
                                  _applyFilters();
                                });
                              }),
                              SizedBox(width: 8),
                              _buildFilterChip('Users', filterRole == 'user', () {
                                setState(() {
                                  filterRole = 'user';
                                  _applyFilters();
                                });
                              }),
                              SizedBox(width: 16),
                              _buildFilterChip('Active', filterStatus == 'active', () {
                                setState(() {
                                  filterStatus = filterStatus == 'active' ? 'all' : 'active';
                                  _applyFilters();
                                });
                              }, color: Colors.green),
                              SizedBox(width: 8),
                              _buildFilterChip('Disabled', filterStatus == 'disabled', () {
                                setState(() {
                                  filterStatus = filterStatus == 'disabled' ? 'all' : 'disabled';
                                  _applyFilters();
                                });
                              }, color: Colors.red),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // User count
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${filteredUsers.length} user${filteredUsers.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
            
            // Users list
            Expanded(
              child: loading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE535AB)),
                      ),
                    )
                  : filteredUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.white24),
                              SizedBox(height: 16),
                              Text(
                                'No users found',
                                style: TextStyle(color: Colors.white54, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            final isAdmin = user['role'] == 'admin';
                            final isDisabled = user['disabled'] == true;
                            
                            return Container(
                              margin: EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Color(0xFF2A2F4A),
                                borderRadius: BorderRadius.circular(12),
                                border: isDisabled
                                    ? Border.all(color: Colors.red.withOpacity(0.3))
                                    : null,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _showUserDetails(user),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Stack(
                                          children: [
                                            Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [Color(0xFFE535AB), Color(0xFF9D4EDD)],
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  (user['username'] ?? 'U')[0].toUpperCase(),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (isDisabled)
                                              Positioned(
                                                bottom: 0,
                                                right: 0,
                                                child: Container(
                                                  padding: EdgeInsets.all(2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.lock,
                                                    size: 12,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      user['username'] ?? 'Unknown',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (isDisabled) ...[
                                                    SizedBox(width: 8),
                                                    Container(
                                                      padding: EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red.withOpacity(0.2),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        'DISABLED',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                user['email'] ?? '',
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.6),
                                                  fontSize: 13,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        _buildRoleBadge(user['role'] ?? 'user'),
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons.chevron_right,
                                          color: Colors.white54,
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
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? Color(0xFFE535AB))
              : Color(0xFF2A2F4A),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}