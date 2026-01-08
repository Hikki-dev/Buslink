import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:google_fonts/google_fonts.dart';

import '../../controllers/trip_controller.dart';
import '../../utils/app_theme.dart';
import 'layout/admin_navbar.dart';
import 'layout/admin_footer.dart';
import 'layout/admin_bottom_nav.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(builder: (context, constraints) {
      final isDesktop = constraints.maxWidth > 800;
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        bottomNavigationBar: isDesktop
            ? null
            : const AdminBottomNav(selectedIndex: 1), // Index 1 for Roles
        body: Column(
          children: [
            if (isDesktop) const AdminNavBar(selectedIndex: 3), // Desktop Nav
            if (!isDesktop)
              const AdminNavBar(selectedIndex: 3), // Mobile Header
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    vertical: isDesktop ? 40 : 20,
                    horizontal: isDesktop ? 24 : 16),
                child: Column(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(isDesktop ? 32 : 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            if (isDesktop)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHeaderTitle(isDark),
                                  Row(
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () =>
                                            _showAddUserDialog(context),
                                        icon: const Icon(Icons.add),
                                        label: const Text("Add User"),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.primaryColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 16)),
                                      ),
                                      const SizedBox(width: 16),
                                      _buildSearchBar(isDark),
                                    ],
                                  ),
                                ],
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildHeaderTitle(isDark),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                          child: _buildSearchBar(isDark,
                                              fullWidth: true)),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () =>
                                            _showAddUserDialog(context),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.primaryColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.all(16)),
                                        child: const Icon(Icons.add),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            const SizedBox(height: 32),
                            const Divider(),
                            const SizedBox(height: 16),

                            // User List Stream
                            StreamBuilder<List<Map<String, dynamic>>>(
                              stream: controller.getAllUsers(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                      child: CircularProgressIndicator(
                                          color: isDark
                                              ? Colors.white
                                              : AppTheme.primaryColor));
                                }
                                if (snapshot.hasError) {
                                  return Center(
                                      child: Padding(
                                    padding: const EdgeInsets.all(40.0),
                                    child: SelectableText(
                                        "Error loading users:\n${snapshot.error}",
                                        textAlign: TextAlign.center,
                                        style:
                                            const TextStyle(color: Colors.red)),
                                  ));
                                }
                                if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return Center(
                                      child: Padding(
                                    padding: const EdgeInsets.all(40.0),
                                    child: Text("No users found",
                                        style: TextStyle(
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.grey)),
                                  ));
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

                                return ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: users.length,
                                  separatorBuilder: (context, index) => Divider(
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.grey.shade100),
                                  itemBuilder: (context, index) {
                                    final user = users[index];
                                    return _buildUserRow(context, user, isDark);
                                  },
                                );
                              },
                            ),
                          ],
                        ),
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

  Widget _buildHeaderTitle(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back,
                  color: isDark ? Colors.white : Colors.black),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: "Back to Dashboard",
            ),
            const SizedBox(width: 8),
            Text(
              "User Management",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.darkText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 48.0),
          child: Text(
            "Manage roles and permissions for all users",
            style: TextStyle(
              fontFamily: 'Inter',
              color: isDark ? Colors.white70 : Colors.grey.shade500,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isDark, {bool fullWidth = false}) {
    return SizedBox(
      width: fullWidth ? double.infinity : 300,
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() => _searchQuery = val);
        },
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: "Search by email or name...",
          hintStyle:
              TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade400),
          prefixIcon:
              Icon(Icons.search, color: isDark ? Colors.white70 : Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? Colors.white24 : Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? Colors.white24 : Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryColor),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildUserRow(
      BuildContext context, Map<String, dynamic> user, bool isDark) {
    final String role = user['role'] ?? 'customer';
    final String email = user['email'] ?? 'No Email';
    String name = user['displayName'] ?? '';
    // Fix: Derive name from email if missing or explicit "Unknown User" default
    if (name.isEmpty || name == 'Unknown User') {
      if (email.contains('@')) {
        final rawName = email.split('@')[0];
        // Capitalize first letter
        if (rawName.isNotEmpty) {
          name = rawName[0].toUpperCase() + rawName.substring(1);
        } else {
          name = rawName;
        }
      } else {
        name = 'Unknown User';
      }
    }
    final String uid = user['uid'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 24.0, horizontal: 8), // Increased vertical padding
      child: Row(
        children: [
          CircleAvatar(
            radius: 24, // Slightly larger avatar
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),
          const SizedBox(width: 16), // Reduced gap
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // prevent expansion
              children: [
                Text(
                  name,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14, // Slightly smaller
                      color: isDark ? Colors.white : Colors.black87),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  email,
                  style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey.shade500,
                      fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1, // Single line for email
                ),
              ],
            ),
          ),
          // Role Badge: Flexible to avoid taking too much space
          Flexible(
            flex: 2,
            fit: FlexFit.tight, // Force it to take space but allow shrink
            child: _buildRoleBadge(role),
          ),
          // Actions: Wrap in Row with minimal size
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(), // tight
                icon: Icon(Icons.edit_outlined,
                    size: 20,
                    color: isDark ? Colors.white70 : Colors.grey.shade600),
                tooltip: "Edit User",
                onPressed: () => _showEditUserDialog(context, uid, name, role),
              ),
              const SizedBox(width: 8),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(), // tight
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: Colors.red),
                tooltip: "Delete User Profile",
                onPressed: () => _confirmDeleteUser(context, uid, name),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color bg;
    Color text;
    String label = role.toUpperCase();

    switch (role.toLowerCase()) {
      case 'admin':
        bg = Colors.red.shade100;
        text = Colors.red.shade800;
        break;
      case 'conductor':
        bg = Colors.blue.shade100;
        text = Colors.blue.shade800;
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
        ),
        child: Text(
          label,
          style:
              TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, String uid, String currentName,
      String currentRole) {
    final controller = Provider.of<TripController>(context, listen: false);
    final nameCtrl = TextEditingController(text: currentName);
    String selectedRole = currentRole;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Edit User Profile"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration:
                        const InputDecoration(labelText: "Display Name"),
                  ),
                  const SizedBox(height: 16),
                  // Role Selection
                  const Text("Role:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildRadioTile(context, "Customer", "customer", selectedRole,
                      (v) => setState(() => selectedRole = v!)),
                  _buildRadioTile(context, "Conductor", "conductor",
                      selectedRole, (v) => setState(() => selectedRole = v!)),
                  _buildRadioTile(context, "Admin", "admin", selectedRole,
                      (v) => setState(() => selectedRole = v!)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await controller.updateUserProfile(
                          uid, nameCtrl.text.trim(), selectedRole);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("User profile updated!")),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Update failed: $e")),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white),
                  child: const Text("Save Changes"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final controller = Provider.of<TripController>(context, listen: false);
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String role = 'customer';
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text("Create New User"),
          content: Container(
            width: 400,
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                              child: Text(
                            "Creates a NEW login in Firebase Auth + Database Profile.",
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: Colors
                                    .black87), // Creating user info always dark on light bg
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameCtrl,
                      decoration:
                          const InputDecoration(labelText: "Display Name"),
                      validator: (v) => v!.isEmpty ? "Name is required" : null,
                    ),
                    TextFormField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: "Email"),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Email is required";
                        if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                            .hasMatch(v)) {
                          return "Enter a valid email address";
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: passwordCtrl,
                      decoration:
                          const InputDecoration(labelText: "Initial Password"),
                      obscureText: true,
                      validator: (v) => (v == null || v.length < 6)
                          ? "Password must be at least 6 chars"
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: const InputDecoration(labelText: "Role"),
                      items: ['customer', 'conductor', 'admin']
                          .map((r) => DropdownMenuItem(
                              value: r, child: Text(r.toUpperCase())))
                          .toList(),
                      onChanged: (v) => setState(() => role = v!),
                    ),
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() => isLoading = true);
                        try {
                          await controller.registerUserAsAdmin(
                            email: emailCtrl.text.trim(),
                            password: passwordCtrl.text.trim(),
                            displayName: nameCtrl.text.trim(),
                            role: role,
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "User account created successfully!")));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text("Failed to create user: $e")));
                          }
                        } finally {
                          if (context.mounted) {
                            setState(() => isLoading = false);
                          }
                        }
                      }
                    },
              child: const Text("Create User"),
            )
          ],
        );
      }),
    );
  }

  void _confirmDeleteUser(BuildContext context, String uid, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete User Profile?"),
        content: Text(
            "Are you sure you want to delete the profile for $name? This does NOT delete their text auth login, only their app data."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await Provider.of<TripController>(context, listen: false)
                    .deleteUserProfile(uid);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("User profile deleted.")));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Delete failed: $e")));
                }
              }
            },
            child: const Text("Delete"),
          )
        ],
      ),
    );
  }

  Widget _buildRadioTile(BuildContext context, String label, String value,
      String groupValue, Function(String?) onChanged) {
    final bool isSelected = value == groupValue;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppTheme.primaryColor : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isDark
                      ? Colors.white
                      : (isSelected ? Colors.black : Colors.grey.shade700),
                )),
          ],
        ),
      ),
    );
  }
}
