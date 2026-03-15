import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

import '../../../data/datasources/auth_local_datasource.dart';
import '../../../data/models/user_model.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late final ApiClient _api;
  List<UserModel> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _api = ApiClient(AuthLocalDatasource());
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/users/');
      setState(() {
        _users = (res['users'] as List).map((e) => UserModel.fromJson(e)).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showUserDialog({UserModel? user}) {
    final nameCtrl = TextEditingController(text: user?.fullName ?? '');
    final userCtrl = TextEditingController(text: user?.username ?? '');
    final passCtrl = TextEditingController();
    String role = user?.role ?? 'salesperson';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(user == null ? 'Add User' : 'Edit User'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (user == null)
                  TextFormField(
                    controller: userCtrl,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (v.trim().length < 3) return 'At least 3 characters';
                      return null;
                    },
                  ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: user == null
                        ? 'Password'
                        : 'New Password (leave blank to keep)',
                  ),
                  validator: (v) {
                    if (user == null && (v == null || v.isEmpty)) {
                      return 'Password required';
                    }
                    if (v != null && v.isNotEmpty && v.length < 6) {
                      return 'At least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(
                        value: 'manager', child: Text('Manager')),
                    DropdownMenuItem(
                        value: 'salesperson', child: Text('Sales Person')),
                  ],
                  onChanged: (v) => setS(() => role = v!),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  if (user == null) {
                    await _api.post('/users/', {
                      'username': userCtrl.text.trim(),
                      'password': passCtrl.text,
                      'full_name': nameCtrl.text.trim(),
                      'role': role,
                    });
                  } else {
                    final body = <String, dynamic>{
                      'full_name': nameCtrl.text.trim(),
                      'role': role,
                    };
                    if (passCtrl.text.isNotEmpty) body['password'] = passCtrl.text;
                    await _api.put('/users/${user.id}', body);
                  }
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  _load();
                } catch (e) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: AppTheme.error),
                  );
                }
              },
              child: Text(user == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _users.length,
                    itemBuilder: (_, i) {
                final u = _users[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: u.isManager
                          ? AppTheme.primary
                          : AppTheme.accent,
                      child: Text(
                        u.username[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(u.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('@${u.username}'),
                        Chip(
                          label: Text(
                              u.isManager ? 'Manager' : 'Sales Person',
                              style: const TextStyle(fontSize: 10)),
                          backgroundColor: u.isManager
                              ? AppTheme.primary.withValues(alpha: 0.1)
                              : AppTheme.accent.withValues(alpha: 0.1),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: u.isActive
                        ? IconButton(
                            icon: const Icon(Icons.edit, color: AppTheme.primary),
                            onPressed: () => _showUserDialog(user: u),
                          )
                        : const Chip(
                            label: Text('Inactive',
                                style: TextStyle(fontSize: 10)),
                            backgroundColor: Color(0xFFFFCDD2),
                          ),
                  ),
                );
              },
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'users_fab',
        onPressed: () => _showUserDialog(),
        backgroundColor: const Color(0xFFD4AA00),
        foregroundColor: Colors.black87,
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
      ),
    );
  }
}
