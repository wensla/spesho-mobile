import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../../../data/models/user_model.dart';
import '../../../domain/entities/shop_entity.dart';

class ShopsScreen extends StatefulWidget {
  const ShopsScreen({super.key});

  @override
  State<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends State<ShopsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopProvider>().loadShops().then((_) => _animCtrl.forward());
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _showShopDialog({ShopEntity? shop}) {
    final isSuperAdmin = context.read<AuthProvider>().isSuperAdmin;
    final nameCtrl = TextEditingController(text: shop?.name ?? '');
    final locationCtrl = TextEditingController(text: shop?.location ?? '');
    final addressCtrl = TextEditingController(text: shop?.address ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => _ShopDialog(
        shop: shop,
        isSuperAdmin: isSuperAdmin,
        nameCtrl: nameCtrl,
        locationCtrl: locationCtrl,
        addressCtrl: addressCtrl,
        formKey: formKey,
        onSave: (ownerId) async {
          final prov = context.read<ShopProvider>();
          bool ok;
          if (shop == null) {
            ok = await prov.createShop(
              nameCtrl.text.trim(),
              location: locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim(),
              address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
              ownerId: ownerId,
            );
          } else {
            ok = await prov.updateShop(
              shop.id,
              name: nameCtrl.text.trim(),
              location: locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim(),
              address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
              ownerId: ownerId,
            );
          }
          if (ok) {
            _animCtrl.reset();
            _animCtrl.forward();
          } else if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(prov.error ?? 'Failed'), backgroundColor: AppTheme.error),
            );
          }
        },
      ),
    );
  }

  void _confirmToggle(ShopEntity shop) {
    final deactivate = shop.isActive;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(deactivate ? 'Deactivate Shop' : 'Activate Shop'),
        content: Text(
          deactivate
              ? 'Deactivate "${shop.name}"? Data will be preserved.'
              : 'Activate "${shop.name}"?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: deactivate ? AppTheme.warning : AppTheme.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<ShopProvider>().updateShop(shop.id, isActive: !shop.isActive);
            },
            child: Text(deactivate ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ShopProvider>();
    final auth = context.watch<AuthProvider>();
    final isSuperAdmin = auth.isSuperAdmin;
    final isManager = auth.isManager;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shops'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _animCtrl.reset();
              context.read<ShopProvider>().loadShops().then((_) => _animCtrl.forward());
            },
          ),
        ],
      ),
      body: prov.loading
          ? _buildShimmer()
          : prov.shops.isEmpty
              ? _buildEmpty(isManager)
              : _buildList(prov.shops, isSuperAdmin, isManager),
      floatingActionButton: (isSuperAdmin || isManager)
          ? FloatingActionButton.extended(
              heroTag: 'shops_fab',
              onPressed: () => _showShopDialog(),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_business_rounded),
              label: const Text('Add Shop', style: TextStyle(fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  Widget _buildList(List<ShopEntity> shops, bool isSuperAdmin, bool isManager) {
    // Super admin: group by owner — only show shops that have a manager owner
    if (isSuperAdmin) {
      final Map<String, List<ShopEntity>> grouped = {};
      for (final s in shops) {
        if (s.ownerName == null || s.ownerName!.isEmpty) continue; // skip unassigned
        grouped.putIfAbsent(s.ownerName!, () => []).add(s);
      }
      final owners = grouped.keys.toList()..sort();
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: owners.length,
            itemBuilder: (_, gi) {
              final owner = owners[gi];
              final ownerShops = grouped[owner]!;
              return _OwnerGroup(
                ownerName: owner,
                shops: ownerShops,
                index: gi,
                animCtrl: _animCtrl,
                onEdit: (s) => _showShopDialog(shop: s),
                onToggle: _confirmToggle,
                isSuperAdmin: true,
              );
            },
          ),
        ),
      );
    }

    // Manager: flat list of their own shops
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: shops.length,
          itemBuilder: (_, i) => _AnimatedShopCard(
            shop: shops[i],
            index: i,
            animCtrl: _animCtrl,
            onEdit: () => _showShopDialog(shop: shops[i]),
            onToggle: () => _confirmToggle(shops[i]),
            canManage: true,
            isSuperAdmin: false,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isManager) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary.withValues(alpha: 0.15), AppTheme.primary.withValues(alpha: 0.05)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.store_rounded, size: 44, color: AppTheme.primary.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 20),
        const Text('No shops yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          isManager ? 'Tap "+ Add Shop" to create your first shop'
              : 'No shops with assigned managers yet',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      ]),
    );
  }

  Widget _buildShimmer() {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          itemBuilder: (_, __) => _ShimmerCard(),
        ),
      ),
    );
  }
}

// ── Shop dialog (with manager picker for super admin) ────────────────────────

class _ShopDialog extends StatefulWidget {
  final ShopEntity? shop;
  final bool isSuperAdmin;
  final TextEditingController nameCtrl;
  final TextEditingController locationCtrl;
  final TextEditingController addressCtrl;
  final GlobalKey<FormState> formKey;
  final void Function(int? ownerId) onSave;

  const _ShopDialog({
    required this.shop,
    required this.isSuperAdmin,
    required this.nameCtrl,
    required this.locationCtrl,
    required this.addressCtrl,
    required this.formKey,
    required this.onSave,
  });

  @override
  State<_ShopDialog> createState() => _ShopDialogState();
}

class _ShopDialogState extends State<_ShopDialog> {
  List<UserModel> _managers = [];
  int? _selectedManagerId;
  bool _loadingManagers = false;

  @override
  void initState() {
    super.initState();
    if (widget.isSuperAdmin) _loadManagers();
  }

  Future<void> _loadManagers() async {
    setState(() => _loadingManagers = true);
    try {
      final api = ApiClient(AuthLocalDatasource());
      final res = await api.get('/users/');
      final all = (res['users'] as List).map((e) => UserModel.fromJson(e)).toList();
      setState(() {
        _managers = all.where((u) => u.role == 'manager' && u.isActive).toList();
        // Pre-select current owner if editing
        if (widget.shop?.ownerId != null) {
          _selectedManagerId = widget.shop!.ownerId;
        }
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingManagers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(shop == null ? Icons.add_business_rounded : Icons.edit_rounded,
              color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Text(shop == null ? 'Add New Shop' : 'Edit Shop',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ]),
      content: SingleChildScrollView(
        child: Form(
          key: widget.formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: widget.nameCtrl,
              decoration: InputDecoration(
                labelText: 'Shop Name *',
                prefixIcon: const Icon(Icons.store_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter shop name' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: widget.locationCtrl,
              decoration: InputDecoration(
                labelText: 'Location / Region',
                prefixIcon: const Icon(Icons.location_on_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: widget.addressCtrl,
              decoration: InputDecoration(
                labelText: 'Address',
                prefixIcon: const Icon(Icons.map_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              maxLines: 2,
            ),
            // Manager assignment — super admin only
            if (widget.isSuperAdmin) ...[
              const SizedBox(height: 14),
              _loadingManagers
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    )
                  : DropdownButtonFormField<int?>(
                      initialValue: _selectedManagerId,
                      decoration: InputDecoration(
                        labelText: 'Assign Manager (Owner) *',
                        prefixIcon: const Icon(Icons.person_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('— Select manager —',
                              style: TextStyle(color: Colors.grey)),
                        ),
                        ..._managers.map((m) => DropdownMenuItem<int?>(
                              value: m.id,
                              child: Text(m.displayName),
                            )),
                      ],
                      validator: (v) => v == null ? 'Select a manager' : null,
                      onChanged: (v) => setState(() => _selectedManagerId = v),
                    ),
            ],
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: Icon(shop == null ? Icons.add : Icons.save_rounded, size: 16),
          label: Text(shop == null ? 'Add Shop' : 'Save'),
          onPressed: () async {
            if (!widget.formKey.currentState!.validate()) return;
            Navigator.pop(context);
            widget.onSave(_selectedManagerId);
          },
        ),
      ],
    );
  }
}

// ── Grouped section for super admin ─────────────────────────────────────────

class _OwnerGroup extends StatelessWidget {
  final String ownerName;
  final List<ShopEntity> shops;
  final int index;
  final AnimationController animCtrl;
  final void Function(ShopEntity) onEdit;
  final void Function(ShopEntity) onToggle;
  final bool isSuperAdmin;

  const _OwnerGroup({
    required this.ownerName,
    required this.shops,
    required this.index,
    required this.animCtrl,
    required this.onEdit,
    required this.onToggle,
    required this.isSuperAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6, left: 4),
        child: Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
            child: Text(ownerName[0].toUpperCase(),
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Text(ownerName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${shops.length} shop${shops.length != 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
      ...shops.asMap().entries.map((e) => _AnimatedShopCard(
        shop: e.value,
        index: index * 10 + e.key,
        animCtrl: animCtrl,
        onEdit: () => onEdit(e.value),
        onToggle: () => onToggle(e.value),
        canManage: true,
        isSuperAdmin: isSuperAdmin,
      )),
      const SizedBox(height: 4),
    ]);
  }
}

// ── Animated shop card ───────────────────────────────────────────────────────

class _AnimatedShopCard extends StatelessWidget {
  final ShopEntity shop;
  final int index;
  final AnimationController animCtrl;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final bool canManage;
  final bool isSuperAdmin;

  const _AnimatedShopCard({
    required this.shop,
    required this.index,
    required this.animCtrl,
    required this.onEdit,
    required this.onToggle,
    required this.canManage,
    required this.isSuperAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final delay = (index * 0.08).clamp(0.0, 0.7);
    final anim = CurvedAnimation(
      parent: animCtrl,
      curve: Interval(delay, (delay + 0.4).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, 24 * (1 - anim.value)),
        child: Opacity(opacity: anim.value, child: child),
      ),
      child: _ShopCard(
        shop: shop,
        onEdit: onEdit,
        onToggle: onToggle,
        canManage: canManage,
        isSuperAdmin: isSuperAdmin,
      ),
    );
  }
}

class _ShopCard extends StatefulWidget {
  final ShopEntity shop;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final bool canManage;
  final bool isSuperAdmin;

  const _ShopCard({
    required this.shop,
    required this.onEdit,
    required this.onToggle,
    required this.canManage,
    required this.isSuperAdmin,
  });

  @override
  State<_ShopCard> createState() => _ShopCardState();
}

class _ShopCardState extends State<_ShopCard> {
  bool _hovered = false;

  // Unique gradient per shop id
  static const _gradients = [
    [Color(0xFF1A56DB), Color(0xFF3B82F6)],
    [Color(0xFF059669), Color(0xFF34D399)],
    [Color(0xFFD97706), Color(0xFFFBBF24)],
    [Color(0xFF7C3AED), Color(0xFFA78BFA)],
    [Color(0xFFDC2626), Color(0xFFF87171)],
    [Color(0xFF0891B2), Color(0xFF22D3EE)],
  ];

  List<Color> get _cardGradient => _gradients[widget.shop.id % _gradients.length];

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _cardGradient[0].withValues(alpha: _hovered ? 0.20 : 0.08),
              blurRadius: _hovered ? 20 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // Left accent bar with gradient
              Container(
                width: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _cardGradient,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Shop icon
              Container(
                width: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_cardGradient[0].withValues(alpha: 0.10), Colors.white],
                    begin: Alignment.centerLeft, end: Alignment.centerRight,
                  ),
                ),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: _cardGradient),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: _cardGradient[0].withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: const Icon(Icons.store_rounded, color: Colors.white, size: 20),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(
                        child: Text(widget.shop.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                      _StatusBadge(isActive: widget.shop.isActive),
                    ]),
                    if (widget.shop.location?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.location_on_rounded, size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 3),
                        Text(widget.shop.location!,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ]),
                    ],
                    if (widget.shop.address?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(widget.shop.address!,
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ]),
                ),
              ),
              // Actions
              if (widget.canManage)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: Colors.grey[500]),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (val) {
                      if (val == 'edit') widget.onEdit();
                      if (val == 'toggle') widget.onToggle();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          Icon(Icons.edit_rounded, size: 18, color: AppTheme.primary),
                          SizedBox(width: 10),
                          Text('Edit Shop'),
                        ]),
                      ),
                      if (widget.isSuperAdmin)
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(children: [
                            Icon(
                              widget.shop.isActive ? Icons.block_rounded : Icons.check_circle_rounded,
                              size: 18,
                              color: widget.shop.isActive ? AppTheme.warning : AppTheme.success,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              widget.shop.isActive ? 'Deactivate' : 'Activate',
                              style: TextStyle(color: widget.shop.isActive ? AppTheme.warning : AppTheme.success),
                            ),
                          ]),
                        ),
                    ],
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isActive ? AppTheme.success : Colors.grey).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isActive ? AppTheme.success : Colors.grey).withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.success : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          isActive ? 'Active' : 'Inactive',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isActive ? AppTheme.success : Colors.grey,
          ),
        ),
      ]),
    );
  }
}

// ── Shimmer loading card ─────────────────────────────────────────────────────

class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final shimmerColor = Color.lerp(Colors.grey[200], Colors.grey[300], _anim.value)!;
        return Container(
          height: 72,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
          ),
          child: Row(children: [
            Container(width: 6, decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)),
            )),
            const SizedBox(width: 16),
            Container(width: 40, height: 40, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(10))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(height: 14, width: 140, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 8),
              Container(height: 11, width: 90, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4))),
            ])),
            Container(width: 55, height: 22, margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(20))),
          ]),
        );
      },
    );
  }
}
