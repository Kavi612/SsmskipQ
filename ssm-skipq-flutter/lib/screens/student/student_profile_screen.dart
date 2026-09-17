import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_scaffold.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _registerNumberController = TextEditingController();
  final _departmentController = TextEditingController();
  String? _academicStream;
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _registerNumberController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  void _initialize(StudentUser? user) {
    if (_initialized || user == null) return;
    _registerNumberController.text = user.registerNumber;
    _departmentController.text = user.department;
    _academicStream = user.academicStream.isEmpty ? null : user.academicStream;
    _initialized = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().updateStudentProfile(
            registerNumber: _registerNumberController.text.trim(),
            department: _departmentController.text.trim(),
            academicStream: _academicStream ?? '',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    } catch (error) {
      if (mounted) {
        final auth = context.read<AuthProvider>();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.messageFromError(error, fallback: 'Unable to update profile'))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user as StudentUser?;
    _initialize(user);

    return AppScaffold(
      title: 'Profile',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppTheme.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.name ?? 'Student', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(user?.mobile ?? '', style: const TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _registerNumberController,
                      decoration: const InputDecoration(labelText: 'Register number'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _departmentController,
                      decoration: const InputDecoration(labelText: 'Department'),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _academicStream,
                      decoration: const InputDecoration(labelText: 'Academic stream'),
                      items: const [
                        DropdownMenuItem(
                          value: 'Engineering',
                          child: Text('Engineering'),
                        ),
                        DropdownMenuItem(
                          value: 'Arts & Science',
                          child: Text('Arts & Science'),
                        ),
                      ],
                      onChanged: (value) => setState(() => _academicStream = value),
                      validator: (value) => value == null
                          ? 'Select an academic stream'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: Text(_saving ? 'SAVING...' : 'SAVE PROFILE'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: AppTheme.bgSubtle,
              surfaceTintColor: Colors.transparent,
              child: ListTile(
                leading: Icon(Icons.account_circle_outlined, color: AppTheme.textMuted),
                title: Text('Google sign-in coming soon'),
                subtitle: Text('Your mobile login remains active for now.'),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () async {
                await auth.logout();
                if (context.mounted) context.go('/');
              },
              child: const Text('LOG OUT'),
            ),
          ],
        ),
      ),
    );
  }
}
