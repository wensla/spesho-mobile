import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/stock_provider.dart';
import '../../providers/product_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../domain/entities/product_entity.dart';

class StockAdjustScreen extends StatefulWidget {
  const StockAdjustScreen({super.key});

  @override
  State<StockAdjustScreen> createState() => _StockAdjustScreenState();
}

class _StockAdjustScreenState extends State<StockAdjustScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newQtyCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  ProductEntity? _selectedProduct;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pp = context.read<ProductProvider>();
      if (pp.products.isEmpty) pp.loadProducts(includeStock: true);
      context.read<StockProvider>().loadBalances();
    });
  }

  @override
  void dispose() {
    _newQtyCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  double get _currentStock {
    if (_selectedProduct == null) return 0;
    final sp = context.read<StockProvider>();
    final bal = sp.balances.where((b) => b.productId == _selectedProduct!.id);
    return bal.isEmpty ? 0 : bal.first.currentStock;
  }

  double get _newQty => double.tryParse(_newQtyCtrl.text) ?? -1;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a product'), backgroundColor: AppTheme.error),
      );
      return;
    }

    final prov = context.read<StockProvider>();
    prov.clearMessages();

    final ok = await prov.stockAdjust(
      productId: _selectedProduct!.id,
      newQuantity: _newQty,
      reason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prov.successMessage ?? 'Stock adjusted successfully'),
          backgroundColor: AppTheme.success,
        ),
      );
      _formKey.currentState!.reset();
      setState(() {
        _selectedProduct = null;
        _newQtyCtrl.clear();
        _reasonCtrl.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(prov.error ?? 'Failed'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().products;
    final stockProv = context.watch<StockProvider>();

    final currentKg = _selectedProduct != null ? _currentStock : null;
    final newKg = _newQty >= 0 ? _newQty : null;
    final delta = (currentKg != null && newKg != null) ? newKg - currentKg : null;
    final isIncrease = delta != null && delta >= 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Stock Adjustment')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline, color: Colors.amber, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Use this to correct stock count discrepancies. Enter the actual current quantity on hand.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),

                // Product selector
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Product', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<ProductEntity>(
                        // ignore: deprecated_member_use
                        value: _selectedProduct,
                        isExpanded: true,
                        hint: const Text('Select product'),
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.grain)),
                        items: products.map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.name),
                        )).toList(),
                        onChanged: (p) => setState(() {
                          _selectedProduct = p;
                          _newQtyCtrl.clear();
                        }),
                        validator: (v) => v == null ? 'Select product' : null,
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 8),

                // Current stock display
                if (_selectedProduct != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.inventory_2_rounded, color: AppTheme.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Current Stock', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          Text(
                            '${FormatUtils.number(currentKg!)} kg',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                        ]),
                      ]),
                    ),
                  ),
                if (_selectedProduct != null) const SizedBox(height: 8),

                // New quantity input
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      TextFormField(
                        controller: _newQtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'New Quantity (kg)',
                          prefixIcon: Icon(Icons.edit_rounded),
                          suffixText: 'kg',
                          suffixStyle: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter new quantity';
                          final q = double.tryParse(v);
                          if (q == null) return 'Invalid number';
                          if (q < 0) return 'Cannot be negative';
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),

                      // Delta indicator
                      if (delta != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                          decoration: BoxDecoration(
                            color: isIncrease
                                ? AppTheme.success.withValues(alpha: 0.08)
                                : AppTheme.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isIncrease
                                  ? AppTheme.success.withValues(alpha: 0.3)
                                  : AppTheme.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isIncrease ? 'Increase' : 'Decrease',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isIncrease ? AppTheme.success : AppTheme.error,
                                ),
                              ),
                              Text(
                                '${isIncrease ? "+" : ""}${FormatUtils.number(delta)} kg',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isIncrease ? AppTheme.success : AppTheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _reasonCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Reason (optional)',
                          prefixIcon: Icon(Icons.notes_rounded),
                          hintText: 'e.g. Physical count, damaged goods, theft...',
                        ),
                        maxLines: 2,
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: stockProv.loading ? null : _submit,
                    icon: stockProv.loading
                        ? const SizedBox(
                            height: 18, width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87))
                        : const Icon(Icons.tune_rounded),
                    label: const Text('APPLY ADJUSTMENT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AA00),
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
