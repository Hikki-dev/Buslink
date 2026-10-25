import 'layout/admin_shell.dart';
import 'admin_dashboard.dart';
import '../../utils/bl_colors.dart';
import '../widgets/bl_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:google_fonts/google_fonts.dart';

import '../../controllers/trip_controller.dart';
import '../../utils/app_theme.dart';
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
  Widget build(BuildContext context) =>
      AdminShell(selected: 7, child: _buildPage(context));

  Widget _buildPage(BuildContext context) {
    final controller = Provider.of<TripController>(context, listen: false);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final search = TextField(
      controller: _searchController,
      onChanged: (v) => setState(() => _searchQuery = v),
      style: const TextStyle(fontSize: 17),
      decoration: InputDecoration(
        hintText: 'Search by email or name...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: const Color(0xFFF5F3F4),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: BL.hairline, width: 1.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: BL.hairline, width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: BL.crimson, width: 2)),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar:
          isDesktop ? null : const AdminBottomNav(selectedIndex: 1),
      body: Column(
        children: [
          if (!isDesktop)
            const BlHeader(title: 'User Management', showBack: false),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(isDesktop ? 36 : 16,
                  isDesktop ? 32 : 16, isDesktop ? 36 : 16, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (isDesktop)
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('User Management',
                                style: TextStyle(
                                    fontSize: 34, fontWeight: FontWeight.w800)),
                            SizedBox(height: 4),
                            Text('Manage roles and permissions for all users',
                                style:
                                    TextStyle(fontSize: 17, color: BL.muted)),
                          ],
                        ),
                      SizedBox(
                        height: 56,
                        child: FilledButton(
                          onPressed: () => _showAddUserDialog(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: BL.crimson,
                            padding: const EdgeInsets.symmetric(horizontal: 26),
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 18,
                                fontWeight: FontWeight.w800),
                          ),
                          child: const Text('Add User'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: search),
                  const SizedBox(height: 18),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: controller.getAllUsers(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: BL.crimson)));
                      }
                      if (snapshot.hasError) {
                        return const BlEmpty(
                            icon: Icons.cloud_off,
                            title: 'We could not load the users',
                            message: 'Check the connection and try again.');
                      }
                      final q = _searchQuery.trim().toLowerCase();
                      final users = (snapshot.data ?? []).where((u) {
                        final email =
                            (u['email'] ?? '').toString().toLowerCase();
                        final name =
                            (u['displayName'] ?? '').toString().toLowerCase();
                        return email.contains(q) || name.contains(q);
                      }).toList();
                      if (users.isEmpty) {
                        return Column(children: [
                          const BlEmpty(
                              icon: Icons.person_search,
                              title: 'No users found'),
                          OutlinedButton(
                            onPressed: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AdminDashboard())),
                            child: const Text('Back to Dashboard'),
                          ),
                        ]);
                      }
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: BL.hairline),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(children: [
                          Container(
                            color: const Color(0xFFF5F3F4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: const Row(children: [
                              Expanded(
                                  flex: 5,
                                  child: Text('User',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: BL.muted))),
                              Expanded(
                                  flex: 2,
                                  child: Text('Role',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: BL.muted))),
                              Expanded(
                                  flex: 3,
                                  child: Text('Actions',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: BL.muted))),
                            ]),
                          ),
                          for (final u in users) _buildUserRow(context, u),
                        ]),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRow(BuildContext context, Map<String, dynamic> user) {
    final String role = (user['role'] ?? 'customer').toString();
    final String email = (user['email'] ?? 'No Email').toString();
    var name = (user['displayName'] ?? '').toString();
    if (name.isEmpty || name == 'Unknown User') {
      final raw = email.contains('@') ? email.split('@')[0] : '';
      name = raw.isEmpty
          ? 'Unknown User'
          : raw[0].toUpperCase() + raw.substring(1);
    }
    final uid = (user['uid'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFEDE6E7)))),
      child: Row(children: [
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              Text(email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, color: BL.muted)),
            ],
          ),
        ),
        Expanded(flex: 2, child: _buildRoleBadge(context, role)),
        Expanded(
          flex: 3,
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            SizedBox(
              height: 44,
              child: OutlinedButton(
                onPressed: () => _showEditUserDialog(context, uid, name, role),
                style: OutlinedButton.styleFrom(
                  foregroundColor: BL.ink,
                  side: const BorderSide(color: BL.ink, width: 1.5),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
                child: const Text('Edit User'),
              ),
            ),
            SizedBox(
              height: 44,
              child: OutlinedButton(
                onPressed: () => _confirmDeleteUser(context, uid, name),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFA3281C),
                  side: const BorderSide(color: Color(0xFFA3281C), width: 1.5),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
                child: const Text('Delete'),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildRoleBadge(BuildContext context, String role) {
    final (label, bg, fg) = switch (role.toLowerCase()) {
      'admin' => ('Admin', const Color(0xFFFBE3E4), BL.crimsonDark),
      'conductor' => (
          'Conductor',
          const Color(0xFFFFF1DB),
          const Color(0xFF7A4300)
        ),
      _ => ('Customer', const Color(0xFFE9EDF2), const Color(0xFF3A444F)),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Text(label,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: fg)),
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
                                fontFamily: 'Outfit',
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
                  fontFamily: 'Outfit',
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
