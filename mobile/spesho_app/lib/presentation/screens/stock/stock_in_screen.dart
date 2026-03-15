import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/stock_provider.dart';
import '../../providers/product_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/product_entity.dart';


class StockInScreen extends StatefulWidget {
  const StockInScreen({super.key});

  @override
  State<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends State<StockInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  ProductEntity? _selectedProduct;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  int get _packageSize => _selectedProduct?.packageSize ?? 1;

  double get _totalKg {
    final packages = double.tryParse(_quantityCtrl.text) ?? 0;
    return packages * _packageSize;
  }

  double get _total {
    final packages = double.tryParse(_quantityCtrl.text) ?? 0;
    final p = double.tryParse(_priceCtrl.text) ?? 0;
    return packages * p;
  }

  Future<void> _pickDate() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (dt != null) setState(() => _selectedDate = dt);
  }

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

    final packages = double.parse(_quantityCtrl.text);
    final ok = await prov.stockIn(
      productId: _selectedProduct!.id,
      quantity: packages * _packageSize,
      unitPrice: double.parse(_priceCtrl.text),
      note: _noteCtrl.text.trim(),
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prov.successMessage ?? 'Stock added successfully'),
          backgroundColor: AppTheme.success,
        ),
      );
      _formKey.currentState!.reset();
      setState(() {
        _selectedProduct = null;
        _selectedDate = DateTime.now();
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

    return Scaffold(
      appBar: AppBar(title: const Text('Stock In')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
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
                          child: Text('${p.name}  (${p.packageSize}kg/package)'),
                        )).toList(),
                    onChanged: (p) {
                      setState(() {
                        _selectedProduct = p;
                        if (p != null) _priceCtrl.text = p.unitPrice.toString();
                      });
                    },
                    validator: (v) => v == null ? 'Select product' : null,
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 8),

            // Quantity & price
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  TextFormField(
                    controller: _quantityCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _selectedProduct == null
                          ? 'No. of packages'
                          : 'No. of packages (${_packageSize}kg each)',
                      prefixIcon: const Icon(Icons.add_box),
                      suffixText: 'packages',
                      suffixStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter quantity';
                      final q = double.tryParse(v);
                      if (q == null || q <= 0) return 'Invalid quantity';
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_totalKg > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${_quantityCtrl.text} packages × ${_packageSize}kg = ${_totalKg.toStringAsFixed(0)} kg',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Package Price (TZS)',
                      prefixText: 'TZS ',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter price';
                      final p = double.tryParse(v);
                      if (p == null) return 'Invalid price';
                      if (p <= 0) return 'Price must be greater than zero';
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  // Auto-calculated total
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          'TZS ${_total.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 8),

            // Date & note
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                      prefixIcon: Icon(Icons.note),
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
                    : const Icon(Icons.add),
                label: const Text('RECORD STOCK IN'),
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
