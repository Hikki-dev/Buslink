import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

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

    return LayoutBuilder(builder: (context, constraints) {
      final isDesktop = constraints.maxWidth > 800;
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
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
                          color: Colors.white,
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
                                  _buildHeaderTitle(),
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
                                      _buildSearchBar(),
                                    ],
                                  ),
                                ],
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildHeaderTitle(),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                          child:
                                              _buildSearchBar(fullWidth: true)),
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
                                  return const Center(
                                      child: CircularProgressIndicator());
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
                                  return const Center(
                                      child: Padding(
                                    padding: EdgeInsets.all(40.0),
                                    child: Text("No users found"),
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
                                  separatorBuilder: (context, index) =>
                                      Divider(color: Colors.grey.shade100),
                                  itemBuilder: (context, index) {
                                    final user = users[index];
                                    return _buildUserRow(context, user);
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

  Widget _buildHeaderTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: "Back to Dashboard",
            ),
            const SizedBox(width: 8),
            Text(
              "User Management",
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 48.0),
          child: Text(
            "Manage roles and permissions for all users",
            style: GoogleFonts.inter(
              color: Colors.grey.shade500,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar({bool fullWidth = false}) {
    return SizedBox(
      width: fullWidth ? double.infinity : 300,
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() => _searchQuery = val);
        },
        decoration: InputDecoration(
          hintText: "Search by email or name...",
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                  color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text(email,
                    style:
                        TextStyle(color: Colors.grey.shade500, fontSize: 14)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildRoleBadge(role),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: Colors.grey.shade600),
            tooltip: "Edit User",
            onPressed: () => _showEditUserDialog(context, uid, name, role),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: "Delete User Profile",
            onPressed: () => _confirmDeleteUser(context, uid, name),
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
      case 'manager':
        bg = Colors.purple.shade100;
        text = Colors.purple.shade800;
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
                  const Text("Role:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
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
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    controller.updateUserProfile(
                        uid, nameCtrl.text.trim(), selectedRole);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("User profile updated!")),
                    );
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
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(
                                  "Creates a NEW login in Firebase Auth + Database Profile.",
                                  style: GoogleFonts.inter(fontSize: 12))),
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
                      value: role,
                      decoration: const InputDecoration(labelText: "Role"),
                      items: ['customer', 'conductor', 'manager', 'admin']
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
            onPressed: () {
              Provider.of<TripController>(context, listen: false)
                  .deleteUserProfile(uid);
              Navigator.pop(ctx);
            },
            child: const Text("Delete"),
          )
        ],
      ),
    );
  }

  Widget _buildRadioTile(String label, String value, String groupValue,
      Function(String?) onChanged) {
    final bool isSelected = value == groupValue;
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
