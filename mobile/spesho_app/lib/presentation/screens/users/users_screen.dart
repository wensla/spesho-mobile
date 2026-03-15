import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/user_avatar.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';

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
    final isSuperAdmin = context.read<AuthProvider>().isSuperAdmin;
    // Normalise legacy role value
    String role = (user?.role == 'salesperson') ? 'seller' : (user?.role ?? 'seller');
    String? gender = user?.gender;
    // Super admin can assign manager or seller; manager can only assign seller
    final roleOptions = isSuperAdmin
        ? const [
            DropdownMenuItem(value: 'manager', child: Text('Manager')),
            DropdownMenuItem(value: 'seller',  child: Text('Seller')),
          ]
        : const [
            DropdownMenuItem(value: 'seller', child: Text('Seller')),
          ];
    if (!isSuperAdmin) role = 'seller';
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
                // ignore: deprecated_member_use
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: roleOptions,
                  onChanged: (v) => setS(() => role = v!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String?>(
                  value: gender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: null,     child: Text('Not specified')),
                    DropdownMenuItem(value: 'male',   child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                  ],
                  onChanged: (v) => setS(() => gender = v),
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
                      'gender': gender,
                    });
                  } else {
                    final body = <String, dynamic>{
                      'full_name': nameCtrl.text.trim(),
                      'role': role,
                      'gender': gender,
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
                    leading: UserAvatar(
                      username: u.username,
                      displayName: u.displayName,
                      gender: u.gender,
                      radius: 22,
                      showRing: true,
                      ringColor: u.isSuperAdmin
                          ? AppTheme.error
                          : u.isManager
                              ? AppTheme.primary
                              : AppTheme.accent,
                    ),
                    title: Text(u.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('@${u.username}'),
                        if (u.isSeller && u.shopName != null)
                          Row(children: [
                            Icon(Icons.store_rounded, size: 12, color: Colors.grey[500]),
                            const SizedBox(width: 3),
                            Text(u.shopName!,
                                style: TextStyle(fontSize: 12, color: Colors.grey[700],
                                    fontWeight: FontWeight.w500)),
                            if (u.shopLocation != null) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.location_on_rounded, size: 12, color: Colors.grey[400]),
                              const SizedBox(width: 2),
                              Text(u.shopLocation!,
                                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                            ],
                          ])
                        else
                          Chip(
                            label: Text(u.roleLabel,
                                style: const TextStyle(fontSize: 10)),
                            backgroundColor: u.isSuperAdmin
                                ? AppTheme.error.withValues(alpha: 0.1)
                                : u.isManager
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
