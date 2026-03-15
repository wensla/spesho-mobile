import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/shop_entity.dart';

class ShopsScreen extends StatefulWidget {
  const ShopsScreen({super.key});

  @override
  State<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends State<ShopsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopProvider>().loadShops();
    });
  }

  void _showShopDialog({ShopEntity? shop}) {
    final nameCtrl = TextEditingController(text: shop?.name ?? '');
    final locationCtrl = TextEditingController(text: shop?.location ?? '');
    final addressCtrl = TextEditingController(text: shop?.address ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(shop == null ? 'Add Shop' : 'Edit Shop'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Shop Name *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter shop name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: locationCtrl,
                decoration: const InputDecoration(labelText: 'Location / Region'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Address'),
                maxLines: 2,
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final prov = context.read<ShopProvider>();
              bool ok;
              if (shop == null) {
                ok = await prov.createShop(
                  nameCtrl.text.trim(),
                  location: locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim(),
                  address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                );
              } else {
                ok = await prov.updateShop(
                  shop.id,
                  name: nameCtrl.text.trim(),
                  location: locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim(),
                  address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                );
              }
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!ok && ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(prov.error ?? 'Failed'), backgroundColor: AppTheme.error),
                );
              }
            },
            child: Text(shop == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDeactivate(ShopEntity shop) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Shop'),
        content: Text('Deactivate "${shop.name}"? Data will be preserved.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<ShopProvider>().updateShop(shop.id, isActive: false);
            },
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ShopProvider>();
    final isSuperAdmin = context.watch<AuthProvider>().isSuperAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shops'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ShopProvider>().loadShops(),
          ),
        ],
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : prov.shops.isEmpty
              ? const Center(child: Text('No shops found'))
              : Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: prov.shops.length,
                      itemBuilder: (_, i) {
                        final s = prov.shops[i];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: s.isActive
                                  ? AppTheme.primary.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              child: Icon(
                                Icons.store_rounded,
                                color: s.isActive ? AppTheme.primary : Colors.grey,
                              ),
                            ),
                            title: Text(s.name,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (s.location != null && s.location!.isNotEmpty)
                                  Text(s.location!),
                                if (s.address != null && s.address!.isNotEmpty)
                                  Text(s.address!,
                                      style: const TextStyle(fontSize: 11)),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (s.isActive ? AppTheme.success : Colors.grey)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    s.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: s.isActive ? AppTheme.success : Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (isSuperAdmin)
                                  PopupMenuButton(
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: ListTile(
                                          leading: Icon(Icons.edit),
                                          title: Text('Edit'),
                                        ),
                                      ),
                                      if (s.isActive)
                                        const PopupMenuItem(
                                          value: 'deactivate',
                                          child: ListTile(
                                            leading: Icon(Icons.block, color: AppTheme.warning),
                                            title: Text('Deactivate',
                                                style: TextStyle(color: AppTheme.warning)),
                                          ),
                                        ),
                                      if (!s.isActive)
                                        const PopupMenuItem(
                                          value: 'activate',
                                          child: ListTile(
                                            leading: Icon(Icons.check_circle, color: AppTheme.success),
                                            title: Text('Activate',
                                                style: TextStyle(color: AppTheme.success)),
                                          ),
                                        ),
                                    ],
                                    onSelected: (val) {
                                      if (val == 'edit') _showShopDialog(shop: s);
                                      if (val == 'deactivate') _confirmDeactivate(s);
                                      if (val == 'activate') {
                                        context.read<ShopProvider>().updateShop(s.id, isActive: true);
                                      }
                                    },
                                  ),
                              ],
                            ),
                            isThreeLine: (s.location?.isNotEmpty == true || s.address?.isNotEmpty == true),
                          ),
                        );
                      },
                    ),
                  ),
                ),
      floatingActionButton: isSuperAdmin
          ? FloatingActionButton.extended(
              heroTag: 'shops_fab',
              onPressed: () => _showShopDialog(),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Shop'),
            )
          : null,
    );
  }
}
