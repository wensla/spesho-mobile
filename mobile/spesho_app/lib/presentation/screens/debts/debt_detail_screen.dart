import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/debt_provider.dart';
import '../../../domain/entities/debt_entity.dart';

class DebtDetailScreen extends StatefulWidget {
  final int debtId;
  const DebtDetailScreen({super.key, required this.debtId});
  @override
  State<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends State<DebtDetailScreen> {
  DebtEntity? _debt;
  List<DebtPaymentEntity> _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await context.read<DebtProvider>().getDebt(widget.debtId);
    if (!mounted) return;
    setState(() {
      _debt     = result?['debt'];
      _payments = List<DebtPaymentEntity>.from(result?['payments'] ?? []);
      _loading  = false;
    });
  }

  Future<void> _showPaymentDialog() async {
    final amtCtrl  = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime date  = DateTime.now();
    final fmt = NumberFormat('#,##0.00');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Record Payment'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            if (_debt != null)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Outstanding Balance', style: TextStyle(fontSize: 13)),
                  Text('TZS ${fmt.format(_debt!.balance)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.error)),
                ]),
              ),
            TextField(
              controller: amtCtrl,
              decoration: const InputDecoration(labelText: 'Amount Paid *', prefixIcon: Icon(Icons.payments)),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () async {
                final dt = await showDatePicker(
                  context: ctx,
                  initialDate: date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (dt != null) setDlg(() => date = dt);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date', prefixIcon: Icon(Icons.calendar_today)),
                child: Text(DateFormat('dd MMM yyyy').format(date)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Note (optional)', prefixIcon: Icon(Icons.note)),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(amtCtrl.text);
                if (amt == null || amt <= 0) return;
                Navigator.pop(ctx);
                final ok = await context.read<DebtProvider>().recordPayment(
                  widget.debtId, amt,
                  note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                  date: DateFormat('yyyy-MM-dd').format(date),
                );
                if (!mounted) return;
                if (ok) {
                  _load();
                } else {
                  final err = context.read<DebtProvider>().error ?? 'Failed';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err), backgroundColor: AppTheme.error));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendSmsReminder() async {
    if (_debt == null) return;
    final phone = _debt!.customerPhone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mdaiwaji hana namba ya simu')),
      );
      return;
    }
    final fmt = NumberFormat('#,##0.00');
    final msg = Uri.encodeComponent(
      'Habari ${_debt!.customerName}, deni lako ni TZS ${fmt.format(_debt!.balance)}. '
      'Tafadhali lipa haraka iwezekanavyo. Asante - Spesho.',
    );
    final uri = Uri.parse('sms:$phone?body=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Haiwezekani kufungua SMS')),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':    return Colors.green;
      case 'partial': return Colors.orange;
      default:        return AppTheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_debt == null) return const Scaffold(body: Center(child: Text('Debt not found')));

    final d = _debt!;
    final pct = d.totalAmount > 0 ? (d.amountPaid / d.totalAmount).clamp(0.0, 1.0) : 0.0;
    final sc  = _statusColor(d.status);

    return Scaffold(
      appBar: AppBar(
        title: Text(d.customerName),
        actions: [
          if (d.customerPhone != null)
            IconButton(
              icon: const Icon(Icons.sms_rounded, color: Colors.white),
              tooltip: 'Tuma ukumbusho wa SMS',
              onPressed: _sendSmsReminder,
            ),
          if (d.status != 'paid')
            TextButton.icon(
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Payment', style: TextStyle(color: Colors.white)),
              onPressed: _showPaymentDialog,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Status card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(d.customerName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: sc.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(d.status.toUpperCase(),
                          style: TextStyle(fontSize: 11, color: sc, fontWeight: FontWeight.bold)),
                    ),
                  ]),
                  if (d.customerPhone != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.phone, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(d.customerPhone!, style: const TextStyle(color: Colors.grey)),
                    ]),
                  ],
                  const Divider(height: 20),
                  if (d.quantity != null)
                    Row(children: [
                      const Icon(Icons.inventory_2, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text('${NumberFormat('#,##0.##').format(d.quantity!)} kg of ${d.productName ?? '-'}'),
                    ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text('Credit date: ${d.date}'),
                  ]),
                  if (d.note != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.note, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(child: Text(d.note!)),
                    ]),
                  ],
                  const Divider(height: 20),
                  Row(children: [
                    Expanded(child: _AmtRow('Total', 'TZS ${fmt.format(d.totalAmount)}', Colors.black87)),
                    Expanded(child: _AmtRow('Paid',  'TZS ${fmt.format(d.amountPaid)}',  Colors.green)),
                    Expanded(child: _AmtRow('Balance','TZS ${fmt.format(d.balance)}',    sc)),
                  ]),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(sc),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${(pct * 100).toStringAsFixed(1)}% paid',
                      style: TextStyle(fontSize: 12, color: sc)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            // Payment history
            const Text('Payment History',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            const SizedBox(height: 8),
            if (_payments.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('No payments recorded yet',
                      style: TextStyle(color: Colors.grey))),
                ),
              )
            else
              ...List.generate(_payments.length, (i) {
                final p = _payments[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.withValues(alpha: 0.15),
                      child: const Icon(Icons.payments, color: Colors.green, size: 20),
                    ),
                    title: Text('TZS ${fmt.format(p.amount)}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(p.note != null ? '${p.paymentDate}  •  ${p.note}' : p.paymentDate),
                    trailing: Text('#${i + 1}', style: const TextStyle(color: Colors.grey)),
                  ),
                );
              }),
            const SizedBox(height: 80),
          ]),
        ),
      ),
      floatingActionButton: d.status != 'paid'
          ? FloatingActionButton.extended(
              onPressed: _showPaymentDialog,
              icon: const Icon(Icons.add),
              label: const Text('Record Payment'),
            )
          : null,
    );
  }
}

class _AmtRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _AmtRow(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    const SizedBox(height: 2),
    Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        textAlign: TextAlign.center),
  ]);
}
