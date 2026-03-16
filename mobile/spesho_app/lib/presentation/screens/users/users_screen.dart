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
  late final bool _isSuperAdmin;
  List<UserModel> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _api = ApiClient(AuthLocalDatasource());
    _isSuperAdmin = context.read<AuthProvider>().isSuperAdmin;
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
    String? gender = user?.gender;
    final formKey = GlobalKey<FormState>();

    // SRS: super admin registers managers, manager registers sellers
    final fixedRole = _isSuperAdmin ? 'manager' : 'seller';
    final roleLabel = _isSuperAdmin ? 'Manager' : 'Seller';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Row(children: [
            Icon(user == null ? Icons.person_add : Icons.edit,
                color: AppTheme.primary, size: 22),
            const SizedBox(width: 8),
            Text(user == null ? 'Register $roleLabel' : 'Edit $roleLabel'),
          ]),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Role badge (read-only display)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (_isSuperAdmin ? AppTheme.primary : AppTheme.accent)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Icon(Icons.admin_panel_settings_outlined,
                        size: 16,
                        color: _isSuperAdmin ? AppTheme.primary : AppTheme.accent),
                    const SizedBox(width: 6),
                    Text('Role: $roleLabel',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _isSuperAdmin ? AppTheme.primary : AppTheme.accent,
                        )),
                  ]),
                ),
                const SizedBox(height: 12),
                if (user == null) ...[
                  TextFormField(
                    controller: userCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (v.trim().length < 3) return 'At least 3 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: user == null
                        ? 'Password'
                        : 'New Password (leave blank to keep)',
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  validator: (v) {
                    if (user == null && (v == null || v.isEmpty)) return 'Password required';
                    if (v != null && v.isNotEmpty && v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String?>(
                  initialValue: gender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Not specified')),
                    DropdownMenuItem(value: 'male', child: Text('Male')),
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
                      'role': fixedRole,
                      'gender': gender,
                    });
                  } else {
                    final body = <String, dynamic>{
                      'full_name': nameCtrl.text.trim(),
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
              child: Text(user == null ? 'Register' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  // SRS 3.1 — Super Admin: Activate / Deactivate manager accounts
  Future<void> _toggleActive(UserModel u) async {
    final activate = !u.isActive;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(activate ? 'Activate Manager?' : 'Deactivate Manager?'),
        content: Text(activate
            ? '${u.displayName} will be able to log in again.'
            : '${u.displayName} will not be able to log in.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: activate ? Colors.green : Colors.orange,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(activate ? 'Activate' : 'Deactivate',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _api.post('/users/${u.id}/toggle-active', {});
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  // SRS 3.2 — Manager: Remove seller
  Future<void> _deleteSeller(UserModel u) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Seller?'),
        content: Text('Remove "${u.displayName}" from your team?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _api.delete('/users/${u.id}');
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isSuperAdmin ? 'Managers' : 'My Sellers';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      _isSuperAdmin
                          ? 'No managers yet.\nTap + to register a manager.'
                          : 'No sellers yet.\nTap + to register a seller.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500], fontSize: 15),
                    ),
                  ]),
                )
              : Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 90),
                      itemCount: _users.length,
                      itemBuilder: (_, i) {
                        final u = _users[i];
                        final roleColor =
                            u.isManager ? AppTheme.primary : AppTheme.accent;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            contentPadding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                            leading: Stack(children: [
                              UserAvatar(
                                username: u.username,
                                displayName: u.displayName,
                                gender: u.gender,
                                radius: 24,
                                showRing: true,
                                ringColor: roleColor,
                              ),
                              if (!u.isActive)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.block,
                                        size: 12, color: Colors.red),
                                  ),
                                ),
                            ]),
                            title: Row(children: [
                              Expanded(
                                child: Text(u.displayName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: u.isActive ? null : Colors.grey,
                                    )),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (u.isActive ? roleColor : Colors.red)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  u.isActive ? u.roleLabel : 'Inactive',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: u.isActive
                                          ? roleColor
                                          : Colors.red[400]),
                                ),
                              ),
                            ]),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('@${u.username}',
                                    style: TextStyle(
                                        color: u.isActive
                                            ? AppTheme.textSecondary
                                            : Colors.grey[400])),
                                if (!u.isManager && u.shopName != null)
                                  Row(children: [
                                    Icon(Icons.store_rounded,
                                        size: 12, color: Colors.grey[500]),
                                    const SizedBox(width: 3),
                                    Text(u.shopName!,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w500)),
                                    if (u.shopLocation != null) ...[
                                      const SizedBox(width: 6),
                                      Icon(Icons.location_on_rounded,
                                          size: 12, color: Colors.grey[400]),
                                      const SizedBox(width: 2),
                                      Text(u.shopLocation!,
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500])),
                                    ],
                                  ]),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      color: AppTheme.primary),
                                  tooltip: 'Edit',
                                  onPressed: () => _showUserDialog(user: u),
                                ),
                                // SRS 3.1: Super Admin activate/deactivate
                                if (_isSuperAdmin)
                                  IconButton(
                                    icon: Icon(
                                      u.isActive
                                          ? Icons.person_off_outlined
                                          : Icons.person_outlined,
                                      color: u.isActive
                                          ? Colors.orange
                                          : Colors.green,
                                    ),
                                    tooltip: u.isActive ? 'Deactivate' : 'Activate',
                                    onPressed: () => _toggleActive(u),
                                  ),
                                // SRS 3.2: Manager remove seller
                                if (!_isSuperAdmin)
                                  IconButton(
                                    icon: const Icon(
                                        Icons.person_remove_outlined,
                                        color: Colors.red),
                                    tooltip: 'Remove Seller',
                                    onPressed: () => _deleteSeller(u),
                                  ),
                              ],
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
        label: Text(_isSuperAdmin ? 'Register Manager' : 'Register Seller'),
      ),
    );
  }
}
