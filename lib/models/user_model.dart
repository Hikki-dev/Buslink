import 'package:cloud_firestore/cloud_firestore.dart';

/// User Role Enum
enum UserRole { passenger, admin, conductor }

/// User Model for authentication and profile
class AppUser {
  final String uid;
  final String phone;
  final String name;
  final String? nic; // National Identity Card (for recovery)
  final UserRole role;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.phone,
    required this.name,
    this.nic,
    this.role = UserRole.passenger,
    required this.createdAt,
  });

  /// Check if user is admin or conductor
  bool get isStaff => role == UserRole.admin || role == UserRole.conductor;

  /// Convert Firestore document to User
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AppUser(
      uid: doc.id,
      phone: data['phone'] ?? '',
      name: data['name'] ?? '',
      nic: data['nic'],
      role: _parseRole(data['role'] ?? 'passenger'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert User to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'phone': phone,
      'name': name,
      'nic': nic,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Parse role string to enum
  static UserRole _parseRole(String roleStr) {
    return UserRole.values.firstWhere(
      (e) => e.name == roleStr,
      orElse: () => UserRole.passenger,
    );
  }
}
