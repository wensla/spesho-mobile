import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../domain/entities/product_entity.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts(includeStock: true);
    });
  }

  static const _ungaSizes = [5, 10, 25];

  static const _ungaWords    = ['dona', 'sembe', 'ngano', 'mtama', 'muhogo', 'unga'];
  static const _mcheleWords  = ['mchele'];
  static const _maharageWords = ['maharage'];

  static String? _validateCategoryName(String? v, String category) {
    if (v == null || v.trim().isEmpty) return 'Weka jina la bidhaa';
    final name = v.toLowerCase().trim();
    final hasUnga     = _ungaWords.any((w) => name.contains(w));
    final hasMchele   = _mcheleWords.any((w) => name.contains(w));
    final hasMaharage = _maharageWords.any((w) => name.contains(w));
    if (category == 'unga'     && (hasMchele || hasMaharage)) return 'Sii jamii ya hapa';
    if (category == 'mchele'   && (hasUnga   || hasMaharage)) return 'Sii jamii ya hapa';
    if (category == 'maharage' && (hasUnga   || hasMchele))   return 'Sii jamii ya hapa';
    return null;
  }

  static const _categories = [
    ('unga', 'Jamii ya Unga'),
    ('mchele', 'Jamii ya Mchele'),
    ('maharage', 'Jamii ya Maharage'),
  ];

  void _showProductDialog({ProductEntity? product}) {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final priceCtrl =
        TextEditingController(text: product?.unitPrice.toString() ?? '');
    String selectedCategory = product?.category ?? 'unga';
    int selectedPackageSize = product?.packageSize ?? 5;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final isUnga = selectedCategory == 'unga';
          final sizeLabel = isUnga ? '${selectedPackageSize}kg' : '1kg';
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(product == null ? 'Add Product' : 'Edit Product'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // Category selector
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Jamii ya Bidhaa',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: _categories.map((cat) {
                      final selected = selectedCategory == cat.$1;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: GestureDetector(
                            onTap: () => setDlgState(() {
                              selectedCategory = cat.$1;
                              selectedPackageSize = cat.$1 == 'unga' ? 5 : 1;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: selected ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.3)),
                              ),
                              child: Text(cat.$2.replaceFirst('Jamii ya ', ''),
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11,
                                    color: selected ? Colors.white : AppTheme.primary),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Jina la Bidhaa'),
                    validator: (v) => _validateCategoryName(v, selectedCategory),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: 'Bei ya $sizeLabel (TZS)', prefixText: 'TZS '),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Weka bei';
                      final p = double.tryParse(v);
                      if (p == null) return 'Bei si sahihi';
                      if (p <= 0) return 'Bei lazima iwe zaidi ya sifuri';
                      return null;
                    },
                  ),
                  // Package size only for unga
                  if (isUnga) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Ukubwa wa Mfuko',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: _ungaSizes.map((size) {
                        final selected = selectedPackageSize == size;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () => setDlgState(() => selectedPackageSize = size),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: selected ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.3)),
                                ),
                                child: Text('${size}kg', textAlign: TextAlign.center,
                                    style: TextStyle(fontWeight: FontWeight.bold,
                                        color: selected ? Colors.white : AppTheme.primary)),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ]),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final name = nameCtrl.text.trim();
                  final price = double.parse(priceCtrl.text.trim());
                  final pkgSize = isUnga ? selectedPackageSize : 1;
                  final prov = context.read<ProductProvider>();
                  bool ok;
                  if (product == null) {
                    ok = await prov.createProduct(name, price, packageSize: pkgSize, category: selectedCategory);
                  } else {
                    ok = await prov.updateProduct(product.id,
                        name: name, price: price, packageSize: pkgSize, category: selectedCategory);
                  }
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (!ok && ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(prov.error ?? 'Failed'), backgroundColor: AppTheme.error),
                    );
                  }
                },
                child: Text(product == null ? 'Add' : 'Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(ProductEntity product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "${product.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final pProvider = context.read<ProductProvider>();
              final ok = await pProvider.deleteProduct(product.id);
              if (!ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(pProvider.error ?? 'Failed'),
                      backgroundColor: AppTheme.error),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProductProvider>();
    final auth = context.watch<AuthProvider>();
    final canManage = auth.isManager || auth.isSuperAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<ProductProvider>().loadProducts(includeStock: true),
          ),
        ],
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : prov.products.isEmpty
              ? const Center(child: Text('No products found'))
              : Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: prov.products.length,
                  itemBuilder: (_, i) {
                    final p = prov.products[i];
                    final stock = p.currentStock ?? 0;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                          child: Text(
                              p.category == 'mchele' ? '🍚' : p.category == 'maharage' ? '🫘' : '🌾',
                              style: const TextStyle(fontSize: 18)),
                        ),
                        title: Text(p.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${p.packageSize}kg: TZS ${FormatUtils.currency(p.unitPrice)}  •  TZS ${FormatUtils.currency(p.unitPrice / p.packageSize)}/kg'),
                            Text(
                              'Stock: ${FormatUtils.number(stock)} kg',
                              style: TextStyle(
                                color: stock <= 0
                                    ? AppTheme.error
                                    : AppTheme.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: canManage
                            ? PopupMenuButton(
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                      value: 'edit',
                                      child: ListTile(
                                          leading: Icon(Icons.edit),
                                          title: Text('Edit'))),
                                  const PopupMenuItem(
                                      value: 'delete',
                                      child: ListTile(
                                          leading: Icon(Icons.delete,
                                              color: AppTheme.error),
                                          title: Text('Delete',
                                              style: TextStyle(
                                                  color: AppTheme.error)))),
                                ],
                                onSelected: (val) {
                                  if (val == 'edit') _showProductDialog(product: p);
                                  if (val == 'delete') _confirmDelete(p);
                                },
                              )
                            : null,
                      ),
                    );
                  },
                ),
                  ),
                ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              heroTag: 'products_fab',
              onPressed: () => _showProductDialog(),
              backgroundColor: const Color(0xFFD4AA00),
              foregroundColor: Colors.black87,
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            )
          : null,
    );
  }
}
