import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../screens/student/student_auth_form.dart';

class StudentLoginScreen extends StatelessWidget {
  const StudentLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (auth.isStudent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/student');
      });
    }
    if (auth.isManager) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/manager');
      });
    }

    return Scaffold(
      body: StudentAuthForm(
        onManagerTap: () => context.go('/manager/login'),
      ),
    );
  }
}
