import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/trip_controller.dart';
import '../../utils/app_theme.dart';
import 'layout/admin_navbar.dart';
import 'layout/admin_footer.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context, listen: false);

    return LayoutBuilder(builder: (context, constraints) {
      final isDesktop = constraints.maxWidth > 900;
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Column(
          children: [
            const AdminNavBar(selectedIndex: 3), // Index 3 for Roles
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    vertical: isDesktop ? 40 : 20,
                    horizontal: isDesktop ? 40 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row
                          if (isDesktop)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildHeaderTitle(),
                                _buildSearchBar(),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeaderTitle(),
                                const SizedBox(height: 20),
                                _buildSearchBar(fullWidth: true),
                              ],
                            ),

                          const SizedBox(height: 30),

                          // User List Container
                          Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  )
                                ]),
                            clipBehavior: Clip.antiAlias,
                            child: StreamBuilder<List<Map<String, dynamic>>>(
                              stream: controller.getAllUsers(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: Padding(
                                    padding: EdgeInsets.all(40.0),
                                    child: CircularProgressIndicator(),
                                  ));
                                }
                                if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return _buildEmptyState();
                                }

                                // Filter
                                final users = snapshot.data!.where((u) {
                                  final email = (u['email'] ?? "")
                                      .toString()
                                      .toLowerCase();
                                  final name = (u['displayName'] ?? "")
                                      .toString()
                                      .toLowerCase();
                                  final q = _searchQuery.toLowerCase();
                                  return email.contains(q) || name.contains(q);
                                }).toList();

                                if (users.isEmpty) return _buildEmptyState();

                                return ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: users.length,
                                  separatorBuilder: (context, index) => Divider(
                                      height: 1, color: Colors.grey.shade100),
                                  itemBuilder: (context, index) {
                                    final user = users[index];
                                    return _buildUserRow(context, user);
                                  },
                                );
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                    const AdminFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // Extension for Row to fix 'items' param error above, but Row uses children.
  // Wait, I made a mistake in the previous logic block 'items: [...]'. fixing inline.

  Widget _buildHeaderTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "User Management",
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Manage roles and access for all users",
          style: GoogleFonts.inter(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar({bool fullWidth = false}) {
    return SizedBox(
      width: fullWidth ? double.infinity : 320,
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() => _searchQuery = val);
        },
        decoration: InputDecoration(
          hintText: "Search users...",
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildUserRow(BuildContext context, Map<String, dynamic> user) {
    final String role = user['role'] ?? 'customer';
    final String email = user['email'] ?? 'No Email';
    final String name = user['displayName'] ?? 'Unknown User';
    final String uid = user['uid'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _getRoleColor(role).withValues(alpha: 0.1),
            foregroundColor: _getRoleColor(role),
            radius: 24,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600, fontSize: 16)),
                Text(email,
                    style: GoogleFonts.inter(
                        color: Colors.grey.shade500, fontSize: 14)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildRoleBadge(role),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: Colors.grey.shade400),
            tooltip: "Edit Role",
            onPressed: () => _showEditRoleDialog(context, uid, name, role),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'manager':
        return Colors.purple;
      case 'conductor':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRoleBadge(String role) {
    Color bg;
    Color text;
    String label = role.toUpperCase();

    switch (role.toLowerCase()) {
      case 'admin':
        bg = Colors.red.shade50;
        text = Colors.red.shade700;
        break;
      case 'manager':
        bg = Colors.purple.shade50;
        text = Colors.purple.shade700;
        break;
      case 'conductor':
        bg = Colors.blue.shade50;
        text = Colors.blue.shade700;
        break;
      default:
        bg = Colors.grey.shade100;
        text = Colors.grey.shade600;
        label = "CUSTOMER";
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: bg == Colors.grey.shade100
                    ? Colors.transparent
                    : text.withValues(alpha: 0.2))),
        child: Text(
          label,
          style: GoogleFonts.inter(
              color: text, fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.person_off_outlined,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text("No users found",
                style: GoogleFonts.inter(color: Colors.grey.shade500))
          ],
        ),
      ),
    );
  }

  void _showEditRoleDialog(
      BuildContext context, String uid, String name, String currentRole) {
    final controller = Provider.of<TripController>(context, listen: false);
    String selectedRole = currentRole;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text("Edit Role",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Assign a role to $name",
                      style: GoogleFonts.inter(color: Colors.grey)),
                  const SizedBox(height: 20),
                  _buildRadioTile("Customer", "customer", selectedRole,
                      (v) => setState(() => selectedRole = v!)),
                  _buildRadioTile("Conductor", "conductor", selectedRole,
                      (v) => setState(() => selectedRole = v!)),
                  _buildRadioTile("Manager", "manager", selectedRole,
                      (v) => setState(() => selectedRole = v!)),
                  _buildRadioTile("Admin", "admin", selectedRole,
                      (v) => setState(() => selectedRole = v!)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel",
                      style: GoogleFonts.inter(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    controller.updateUserRole(uid, selectedRole);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Role updated to $selectedRole")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  child: const Text("Save Changes"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRadioTile(String label, String value, String groupValue,
      Function(String?) onChanged) {
    final bool isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color:
                    isSelected ? AppTheme.primaryColor : Colors.grey.shade200)),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(label,
                style: GoogleFonts.inter(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.black : Colors.grey.shade700,
                )),
          ],
        ),
      ),
    );
  }
}
