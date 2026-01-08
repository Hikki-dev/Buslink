import 'package:flutter/material.dart';

import 'refunds/admin_refund_list.dart';

class AdminRefundManagementScreen extends StatelessWidget {
  const AdminRefundManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrapper to keep naming consistent if we want to add tabs later
    return const AdminRefundListScreen();
  }
}
