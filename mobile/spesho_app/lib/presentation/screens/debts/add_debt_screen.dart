import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/debt_provider.dart';
import '../../providers/product_provider.dart';
import '../../../domain/entities/product_entity.dart';

class AddDebtScreen extends StatefulWidget {
  const AddDebtScreen({super.key});
  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _qtyCtrl   = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _noteCtrl  = TextEditingController();
  DateTime _date   = DateTime.now();
  ProductEntity? _product;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts(includeStock: true);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _qtyCtrl.dispose();  _priceCtrl.dispose(); _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product')));
      return;
    }
    setState(() => _saving = true);
    final ok = await context.read<DebtProvider>().createDebt(
      customerName:  _nameCtrl.text.trim(),
      customerPhone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      productId:     _product!.id,
      quantity:      double.parse(_qtyCtrl.text),
      unitPrice:     double.parse(_priceCtrl.text),
      note:          _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      date:          DateFormat('yyyy-MM-dd').format(_date),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context, true);
    } else {
      final err = context.read<DebtProvider>().error ?? 'Failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppTheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().products;
    return Scaffold(
      appBar: AppBar(title: const Text('New Credit Sale')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Customer Name *', prefixIcon: Icon(Icons.person)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone (optional)', prefixIcon: Icon(Icons.phone)),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ProductEntity>(
              value: _product,
              decoration: const InputDecoration(labelText: 'Product *', prefixIcon: Icon(Icons.inventory_2)),
              items: products.map((p) => DropdownMenuItem(
                value: p,
                child: Text('${p.name} (stock: ${p.currentStock?.toStringAsFixed(0) ?? '?'})'),
              )).toList(),
              onChanged: (p) {
                setState(() {
                  _product = p;
                  if (p != null) _priceCtrl.text = p.unitPrice.toStringAsFixed(2);
                });
              },
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _qtyCtrl,
                  decoration: const InputDecoration(labelText: 'Quantity (kg) *'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Must be > 0';
                    if (_product != null && n > (_product!.currentStock ?? 0)) {
                      return 'Exceeds stock (${_product!.currentStock?.toStringAsFixed(0)})';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _priceCtrl,
                  decoration: const InputDecoration(labelText: 'Unit Price *'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    return (n == null || n <= 0) ? 'Must be > 0' : null;
                  },
                ),
              ),
            ]),
            const SizedBox(height: 12),
            // Total preview
            if (_qtyCtrl.text.isNotEmpty && _priceCtrl.text.isNotEmpty)
              Builder(builder: (_) {
                final qty = double.tryParse(_qtyCtrl.text) ?? 0;
                final price = double.tryParse(_priceCtrl.text) ?? 0;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Total Credit Amount', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      'TZS ${NumberFormat('#,##0.00').format(qty * price)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary),
                    ),
                  ]),
                );
              }),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final dt = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (dt != null) setState(() => _date = dt);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date', prefixIcon: Icon(Icons.calendar_today)),
                child: Text(DateFormat('dd MMM yyyy').format(_date)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Note (optional)', prefixIcon: Icon(Icons.note)),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _saving ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Record Credit Sale'),
                onPressed: _saving ? null : _submit,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
