import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/format_utils.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../../../data/repositories/reports_repository.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late ReportsRepository _repo;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _repo = ReportsRepository(ApiClient(AuthLocalDatasource()));
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: const Text('Reports', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(children: [
            const Divider(height: 1, color: AppTheme.border),
            TabBar(
              controller: _tab,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primary, indicatorWeight: 2.5,
              tabs: const [
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.bar_chart_rounded, size: 18), SizedBox(width: 6), Text('Sales')])),
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.inventory_2_rounded, size: 18), SizedBox(width: 6), Text('Stock')])),
              ],
            ),
          ]),
        ),
      ),
      body: TabBarView(controller: _tab, children: [
        _SalesReportTab(repo: _repo),
        _StockReportTab(repo: _repo),
      ]),
    );
  }
}

enum _Period { daily, weekly, monthly, yearly }

class _SalesReportTab extends StatefulWidget {
  final ReportsRepository repo;
  const _SalesReportTab({required this.repo});
  @override
  State<_SalesReportTab> createState() => _SalesReportTabState();
}

class _SalesReportTabState extends State<_SalesReportTab> {
  _Period _period = _Period.daily;
  DateTime _date  = DateTime.now();
  bool _loading   = false;
  SalesSummaryReport? _report;
  String? _error;

  @override void initState() { super.initState(); _load(); }

  (String, String) get _range {
    switch (_period) {
      case _Period.daily:
        final d = DateFormat('yyyy-MM-dd').format(_date);
        return (d, d);
      case _Period.weekly:
        final mon = _date.subtract(Duration(days: _date.weekday - 1));
        final sun = mon.add(const Duration(days: 6));
        return (DateFormat('yyyy-MM-dd').format(mon), DateFormat('yyyy-MM-dd').format(sun));
      case _Period.monthly:
        final first = DateTime(_date.year, _date.month, 1);
        final last  = DateTime(_date.year, _date.month + 1, 0);
        return (DateFormat('yyyy-MM-dd').format(first), DateFormat('yyyy-MM-dd').format(last));
      case _Period.yearly:
        return ('${_date.year}-01-01', '${_date.year}-12-31');
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final (sd, ed) = _range;
      final r = await widget.repo.getSalesSummary(startDate: sd, endDate: ed);
      setState(() { _report = r; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _pick() async {
    if (_period == _Period.yearly) {
      final yr = await showDialog<int>(context: context, builder: (_) => _YearPickerDialog(initial: _date.year));
      if (yr != null) { setState(() => _date = DateTime(yr)); _load(); }
      return;
    }
    final dt = await showDatePicker(
      context: context, initialDate: _date,
      firstDate: DateTime(2020), lastDate: DateTime.now(),
      helpText: _period == _Period.weekly ? 'Pick any day in the week' : null,
    );
    if (dt != null) { setState(() => _date = dt); _load(); }
  }

  String get _rangeLabel {
    final (sd, ed) = _range;
    switch (_period) {
      case _Period.daily:   return DateFormat('dd MMM yyyy').format(_date);
      case _Period.weekly:  return '${DateFormat('dd MMM').format(DateFormat('yyyy-MM-dd').parse(sd))} – ${DateFormat('dd MMM yyyy').format(DateFormat('yyyy-MM-dd').parse(ed))}';
      case _Period.monthly: return DateFormat('MMMM yyyy').format(_date);
      case _Period.yearly:  return '${_date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = { _Period.daily: 'Daily', _Period.weekly: 'Weekly', _Period.monthly: 'Monthly', _Period.yearly: 'Yearly' };
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: _Period.values.map((p) {
              final sel = p == _period;
              return Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () { if (_period != p) { setState(() => _period = p); _load(); } },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: sel ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(labels[p]!, textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12,
                            color: sel ? Colors.white : AppTheme.primary)),
                  ),
                ),
              ));
            }).toList()),
            const SizedBox(height: 10),
            _Card(child: InkWell(
              onTap: _pick,
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.primary),
                const SizedBox(width: 10),
                Expanded(child: Text(_rangeLabel, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
                const Icon(Icons.edit_calendar_rounded, size: 16, color: AppTheme.textSecondary),
              ]),
            )),
            const SizedBox(height: 10),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else if (_error != null)
              _Card(child: Row(children: [const Icon(Icons.error_outline, color: AppTheme.error), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.error)))]))
            else if (_report != null) ...[
              Row(children: [
                Expanded(child: _TotCard(label: 'Total Sales', value: 'TZS ${FormatUtils.currency(_report!.grandTotal)}', icon: Icons.receipt_rounded, color: AppTheme.primary)),
                const SizedBox(width: 8),
                Expanded(child: _TotCard(label: 'Cash Received', value: 'TZS ${FormatUtils.currency(_report!.grandCash)}', icon: Icons.payments_rounded, color: AppTheme.success)),
                if (_report!.grandDebt > 0) ...[
                  const SizedBox(width: 8),
                  Expanded(child: _TotCard(label: 'Total Debt', value: 'TZS ${FormatUtils.currency(_report!.grandDebt)}', icon: Icons.account_balance_wallet_rounded, color: AppTheme.warning)),
                ],
              ]),
              const SizedBox(height: 12),
              if (_report!.days.isEmpty)
                const _Card(child: Column(children: [
                  Icon(Icons.receipt_long_outlined, size: 40, color: AppTheme.textSecondary),
                  SizedBox(height: 8),
                  Text('No sales recorded for this period', style: TextStyle(color: AppTheme.textSecondary)),
                ]))
              else
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.border)),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.06), borderRadius: const BorderRadius.vertical(top: Radius.circular(10))),
                      child: const Row(children: [
                        Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary))),
                        Expanded(flex: 3, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary))),
                        Expanded(flex: 3, child: Text('Cash Paid', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary))),
                        Expanded(flex: 3, child: Text('Debt', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary))),
                      ]),
                    ),
                    ...(_report!.days.asMap().entries.map((e) {
                      final i = e.key; final d = e.value;
                      final dt = DateFormat('yyyy-MM-dd').parse(d.date);
                      return Column(children: [
                        if (i > 0) const Divider(height: 1, color: AppTheme.border),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          child: Row(children: [
                            Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(DateFormat('dd MMM').format(dt), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              Text(DateFormat('EEE').format(dt), style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                            ])),
                            Expanded(flex: 3, child: Text(FormatUtils.currency(d.total), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary))),
                            Expanded(flex: 3, child: Text(FormatUtils.currency(d.cashPaid), textAlign: TextAlign.right, style: const TextStyle(color: AppTheme.success, fontSize: 13))),
                            Expanded(flex: 3, child: Text(d.debt > 0 ? FormatUtils.currency(d.debt) : '—', textAlign: TextAlign.right, style: TextStyle(color: d.debt > 0 ? AppTheme.warning : AppTheme.textSecondary, fontSize: 13))),
                          ]),
                        ),
                      ]);
                    })),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.06), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)), border: const Border(top: BorderSide(color: AppTheme.border))),
                      child: Row(children: [
                        const Expanded(flex: 2, child: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                        Expanded(flex: 3, child: Text(FormatUtils.currency(_report!.grandTotal), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary))),
                        Expanded(flex: 3, child: Text(FormatUtils.currency(_report!.grandCash), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success))),
                        Expanded(flex: 3, child: Text(_report!.grandDebt > 0 ? FormatUtils.currency(_report!.grandDebt) : '—', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: _report!.grandDebt > 0 ? AppTheme.warning : AppTheme.textSecondary))),
                      ]),
                    ),
                  ]),
                ),
            ],
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }
}

class _StockReportTab extends StatefulWidget {
  final ReportsRepository repo;
  const _StockReportTab({required this.repo});
  @override
  State<_StockReportTab> createState() => _StockReportTabState();
}

class _StockReportTabState extends State<_StockReportTab> {
  bool _loading = false;
  List<StockBalanceItem> _items = [];
  String? _error;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _items = await widget.repo.getStockBalance();
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalValue = _items.fold(0.0, (s, e) => s + e.stockValue);
    final totalPkgs  = _items.fold(0.0, (s, e) => s + e.packages);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Current Stock Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
              IconButton(icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary), onPressed: _load),
            ]),
            const SizedBox(height: 8),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else if (_error != null)
              _Card(child: Row(children: [const Icon(Icons.error_outline, color: AppTheme.error), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.error)))]))
            else if (_items.isEmpty)
              const _Card(child: Column(children: [Icon(Icons.inventory_2_outlined, size: 40, color: AppTheme.textSecondary), SizedBox(height: 8), Text('No products', style: TextStyle(color: AppTheme.textSecondary))]))
            else ...[
              Row(children: [
                Expanded(child: _TotCard(label: 'Products', value: '${_items.length}', icon: Icons.category_rounded, color: AppTheme.primary)),
                const SizedBox(width: 8),
                Expanded(child: _TotCard(label: 'Total Packages', value: '${totalPkgs.toStringAsFixed(0)} pkgs', icon: Icons.inventory_rounded, color: AppTheme.accent)),
                const SizedBox(width: 8),
                Expanded(child: _TotCard(label: 'Stock Value', value: 'TZS ${FormatUtils.currency(totalValue)}', icon: Icons.monetization_on_rounded, color: AppTheme.success)),
              ]),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.border)),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.06), borderRadius: const BorderRadius.vertical(top: Radius.circular(10))),
                    child: const Row(children: [
                      Expanded(flex: 3, child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary))),
                      Expanded(flex: 2, child: Text('Packages', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary))),
                      Expanded(flex: 2, child: Text('Kg', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary))),
                      Expanded(flex: 3, child: Text('Value (TZS)', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary))),
                    ]),
                  ),
                  ...(_items.asMap().entries.map((e) {
                    final i = e.key; final item = e.value;
                    final low = item.packages < 5;
                    return Column(children: [
                      if (i > 0) const Divider(height: 1, color: AppTheme.border),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(children: [
                          Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            Text('${item.packageSize}kg/pkg', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          ])),
                          Expanded(flex: 2, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                            if (low) const Icon(Icons.warning_amber_rounded, size: 13, color: AppTheme.warning),
                            const SizedBox(width: 2),
                            Text(item.packages.toStringAsFixed(0), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: low ? AppTheme.warning : AppTheme.textPrimary)),
                          ])),
                          Expanded(flex: 2, child: Text(item.currentStock.toStringAsFixed(0), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
                          Expanded(flex: 3, child: Text(FormatUtils.currency(item.stockValue), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.success, fontSize: 13))),
                        ]),
                      ),
                    ]);
                  })),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.06), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)), border: const Border(top: BorderSide(color: AppTheme.border))),
                    child: Row(children: [
                      const Expanded(flex: 3, child: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      Expanded(flex: 2, child: Text(totalPkgs.toStringAsFixed(0), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary))),
                      const Expanded(flex: 2, child: SizedBox()),
                      Expanded(flex: 3, child: Text(FormatUtils.currency(totalValue), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success, fontSize: 14))),
                    ]),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.border)),
    padding: const EdgeInsets.all(14),
    child: child,
  );
}

class _TotCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _TotCard({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.border)),
    padding: const EdgeInsets.all(12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(7)), child: Icon(icon, color: color, size: 14)),
        const SizedBox(width: 6),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary))),
      ]),
      const SizedBox(height: 6),
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color))),
    ]),
  );
}

class _YearPickerDialog extends StatelessWidget {
  final int initial;
  const _YearPickerDialog({required this.initial});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().year;
    return AlertDialog(
      title: const Text('Select Year'),
      content: SizedBox(width: 200, height: 200, child: ListView(
        children: List.generate(now - 2019, (i) {
          final yr = now - i;
          return ListTile(
            title: Text('$yr', style: TextStyle(fontWeight: yr == initial ? FontWeight.bold : FontWeight.normal, color: yr == initial ? AppTheme.primary : null)),
            onTap: () => Navigator.pop(context, yr),
          );
        }),
      )),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
    );
  }
}
