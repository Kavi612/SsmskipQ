import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';

class ManagerProfileScreen extends StatelessWidget {
  const ManagerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user as ManagerUser?;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          Text('Name', style: TextStyle(color: Colors.grey[600])),
          Text(user?.name ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Text('Manager ID', style: TextStyle(color: Colors.grey[600])),
          Text(user?.managerId ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await auth.logout();
                if (context.mounted) context.go('/');
              },
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }
}
