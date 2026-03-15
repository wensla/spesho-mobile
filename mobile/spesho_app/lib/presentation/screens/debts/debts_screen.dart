import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/debt_provider.dart';
import '../../../domain/entities/debt_entity.dart';
import 'debt_detail_screen.dart';
import 'debt_reports_screen.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});
  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  String? _filterStatus;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DebtProvider>().loadDebts();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showQuickPaymentDialog() async {
    final prov = context.read<DebtProvider>();
    // Load all unpaid debts for selection
    await prov.loadDebts(status: null);
    if (!mounted) return;

    final unpaidDebts = prov.debts.where((d) => d.status != 'paid').toList();
    if (unpaidDebts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hakuna madeni yanayosubiri malipo')),
      );
      return;
    }

    DebtEntity? selectedDebt;
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final debtorSearchCtrl = TextEditingController();
    DateTime date = DateTime.now();
    final fmt = NumberFormat('#,##0.00');
    List<DebtEntity> filtered = List.from(unpaidDebts);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Record Payment'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Debtor search field
              TextField(
                controller: debtorSearchCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tafuta mdaiwa *',
                  prefixIcon: Icon(Icons.person_search),
                  hintText: 'Andika jina...',
                ),
                onChanged: (q) {
                  setDlg(() {
                    filtered = unpaidDebts
                        .where((d) => d.customerName.toLowerCase().contains(q.toLowerCase()))
                        .toList();
                    if (selectedDebt != null &&
                        !filtered.any((d) => d.id == selectedDebt!.id)) {
                      selectedDebt = null;
                    }
                  });
                },
              ),
              // Debtor list (shown when no selection yet or searching)
              if (selectedDebt == null) ...[
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: filtered.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Hakuna mdaiwa aliyepatikana',
                              style: TextStyle(color: Colors.grey)),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final d = filtered[i];
                            final sc = d.status == 'partial' ? Colors.orange : AppTheme.error;
                            return ListTile(
                              dense: true,
                              title: Text(d.customerName,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('Deni: TZS ${fmt.format(d.balance)}',
                                  style: TextStyle(color: sc, fontSize: 12)),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: sc.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(d.status.toUpperCase(),
                                    style: TextStyle(fontSize: 9, color: sc, fontWeight: FontWeight.bold)),
                              ),
                              onTap: () => setDlg(() {
                                selectedDebt = d;
                                debtorSearchCtrl.text = d.customerName;
                              }),
                            );
                          },
                        ),
                ),
              ],
              // Selected debtor balance display
              if (selectedDebt != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(selectedDebt!.customerName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const Text('Outstanding Balance', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ]),
                    Row(children: [
                      Text('TZS ${fmt.format(selectedDebt!.balance)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.error)),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => setDlg(() {
                          selectedDebt = null;
                          debtorSearchCtrl.clear();
                          filtered = List.from(unpaidDebts);
                        }),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ]),
                  ]),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amtCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Amount Paid *',
                    prefixIcon: Icon(Icons.payments),
                  ),
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
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(DateFormat('dd MMM yyyy').format(date)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    prefixIcon: Icon(Icons.note),
                  ),
                ),
              ],
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedDebt == null
                  ? null
                  : () async {
                      final amt = double.tryParse(amtCtrl.text);
                      if (amt == null || amt <= 0) return;
                      Navigator.pop(ctx);
                      final ok = await prov.recordPayment(
                        selectedDebt!.id, amt,
                        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                        date: DateFormat('yyyy-MM-dd').format(date),
                      );
                      if (!mounted) return;
                      if (ok) {
                        prov.loadDebts(status: _filterStatus);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Malipo ya ${selectedDebt!.customerName} yamehifadhiwa'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        final err = prov.error ?? 'Failed';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(err), backgroundColor: AppTheme.error),
                        );
                      }
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debts & Credit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Debt Reports',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DebtReportsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQuickPaymentDialog,
        icon: const Icon(Icons.add),
        label: const Text('Record Payment'),
      ),
      body: Consumer<DebtProvider>(
        builder: (_, prov, __) {
          if (prov.loading && prov.debts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () => prov.loadDebts(
              status: _filterStatus,
              customer: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  children: [
                    // Summary cards
                    if (prov.summary != null) _SummaryBar(prov.summary!),
                    // Search + filter
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Search customer...',
                              prefixIcon: Icon(Icons.search),
                              isDense: true,
                            ),
                            onSubmitted: (_) => prov.loadDebts(
                              status: _filterStatus,
                              customer: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String?>(
                          value: _filterStatus,
                          hint: const Text('All'),
                          items: const [
                            DropdownMenuItem(value: null,       child: Text('All')),
                            DropdownMenuItem(value: 'pending',  child: Text('Pending')),
                            DropdownMenuItem(value: 'partial',  child: Text('Partial')),
                            DropdownMenuItem(value: 'paid',     child: Text('Paid')),
                          ],
                          onChanged: (v) {
                            setState(() => _filterStatus = v);
                            prov.loadDebts(status: v, customer: _searchCtrl.text.isEmpty ? null : _searchCtrl.text);
                          },
                        ),
                      ]),
                    ),
                    // List
                    Expanded(
                      child: prov.debts.isEmpty
                          ? const Center(child: Text('No debts found'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: prov.debts.length,
                              itemBuilder: (_, i) {
                                final d = prov.debts[i];
                                return _DebtCard(
                                  debt: d,
                                  statusColor: _statusColor(d.status),
                                  onTap: () async {
                                    await Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => DebtDetailScreen(debtId: d.id)));
                                    prov.loadDebts(status: _filterStatus);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final DebtSummaryEntity s;
  const _SummaryBar(this.s);

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    return Container(
      color: AppTheme.primary.withValues(alpha: 0.05),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        _SumCard('Outstanding', 'TZS ${fmt.format(s.totalBalance)}', AppTheme.error),
        const SizedBox(width: 8),
        _SumCard('Collected',   'TZS ${fmt.format(s.totalPaid)}',    Colors.green),
        const SizedBox(width: 8),
        _SumCard('Debtors',     '${s.totalDebts} (${s.pending}p/${s.partial}x)',  AppTheme.primary),
      ]),
    );
  }
}

class _SumCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SumCard(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    ),
  );
}

class _DebtCard extends StatelessWidget {
  final DebtEntity debt;
  final Color statusColor;
  final VoidCallback onTap;
  const _DebtCard({required this.debt, required this.statusColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final pct = debt.totalAmount > 0 ? (debt.amountPaid / debt.totalAmount).clamp(0.0, 1.0) : 0.0;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(debt.customerName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(debt.status.toUpperCase(),
                    style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
              ),
            ]),
            if (debt.customerPhone != null) ...[
              const SizedBox(height: 2),
              Text(debt.customerPhone!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
            const SizedBox(height: 6),
            if (debt.quantity != null)
              Text('${NumberFormat('#,##0.##').format(debt.quantity!)} kg of ${debt.productName ?? '-'}',
                  style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Total: TZS ${fmt.format(debt.totalAmount)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text('Paid:  TZS ${fmt.format(debt.amountPaid)}',
                    style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('Balance', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                Text('TZS ${fmt.format(debt.balance)}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: statusColor)),
              ]),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(statusColor),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 6),
            Row(children: [
              Text(debt.date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const Spacer(),
              if (debt.status != 'paid' && debt.daysOutstanding > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (debt.isChronic ? Colors.orange : Colors.grey).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    debt.isChronic
                        ? '⚠ ${debt.daysOutstanding} siku'
                        : '${debt.daysOutstanding} siku',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: debt.isChronic ? Colors.orange : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ]),
          ]),
        ),
      ),
    );
  }
}
