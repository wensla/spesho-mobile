import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/daily_sales_provider.dart';
import '../../providers/debt_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (_tab.index == 1 && mounted) {
        context.read<DailySalesProvider>().loadTodaySales();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DailySalesProvider>().loadTodaySales();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Sales',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(children: [
            const Divider(height: 1, color: AppTheme.border),
            TabBar(
              controller: _tab,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primary,
              indicatorWeight: 2.5,
              tabs: const [
                Tab(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_circle_outline_rounded, size: 18),
                    SizedBox(width: 6),
                    Text('Record Sale'),
                  ]),
                ),
                Tab(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.receipt_long_rounded, size: 18),
                    SizedBox(width: 6),
                    Text('History'),
                  ]),
                ),
              ],
            ),
          ]),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _RecordSaleTab(onRecorded: () => _tab.animateTo(1)),
          const _HistoryTab(),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Tab 1: Record Sale
// ══════════════════════════════════════════════════════════════════════════════

class _RecordSaleTab extends StatefulWidget {
  final VoidCallback? onRecorded;
  const _RecordSaleTab({this.onRecorded});

  @override
  State<_RecordSaleTab> createState() => _RecordSaleTabState();
}

class _RecordSaleTabState extends State<_RecordSaleTab> {
  final _totalCtrl = TextEditingController();
  final _paidCtrl  = TextEditingController();
  final _noteCtrl  = TextEditingController();
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  DateTime _date          = DateTime.now();
  String   _paymentMethod = 'cash';

  static const _paymentMethods = [
    ('cash',           'Cash',            Icons.payments_rounded),
    ('mobile_money',   'Mobile Money',    Icons.phone_android_rounded),
    ('bank_transfer',  'Bank Transfer',   Icons.account_balance_rounded),
    ('credit',         'Credit',          Icons.credit_card_rounded),
  ];

  @override
  void dispose() {
    _totalCtrl.dispose();
    _paidCtrl.dispose();
    _noteCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  double get _total   => double.tryParse(_totalCtrl.text) ?? 0;
  double get _paid    => _paidCtrl.text.isEmpty ? _total : (double.tryParse(_paidCtrl.text) ?? 0);
  double get _debt    => (_total - _paid).clamp(0, double.infinity);
  bool   get _hasDebt => _paidCtrl.text.isNotEmpty && _debt > 0.01;

  Future<void> _submit() async {
    if (_total <= 0) {
      _show('Enter a valid total amount', AppTheme.error);
      return;
    }
    if (_paid < 0) {
      _show('Cash received cannot be negative', AppTheme.error);
      return;
    }
    if (_hasDebt && _nameCtrl.text.trim().isEmpty) {
      _show('Customer name is required when there is a debt', AppTheme.error);
      return;
    }

    final prov = context.read<DailySalesProvider>();
    prov.clearMessages();

    final ok = await prov.recordSale(
      totalAmount:   _total,
      cashPaid:      _paid,
      note:          _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      customerName:  _hasDebt ? _nameCtrl.text.trim() : null,
      customerPhone: _hasDebt ? _phoneCtrl.text.trim() : null,
      date:          DateFormat('yyyy-MM-dd').format(_date),
      paymentMethod: _paymentMethod,
    );

    if (!mounted) return;
    if (!ok) { _show(prov.error ?? 'Failed', AppTheme.error); return; }

    if (_hasDebt) {
      final debtNote =
          'Credit sale on ${DateFormat('yyyy-MM-dd').format(_date)}'
          '${_noteCtrl.text.trim().isNotEmpty ? ': ${_noteCtrl.text.trim()}' : ''}';
      await context.read<DebtProvider>().createDebtFromSale(
            customerName:  _nameCtrl.text.trim(),
            customerPhone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
            totalAmount:   _total,
            amountPaid:    _paid,
            note:          debtNote,
            date:          DateFormat('yyyy-MM-dd').format(_date),
          );
      if (!mounted) return;
      _show(
        'Sale recorded! TZS ${FormatUtils.currency(_debt)} debt added for ${_nameCtrl.text.trim()}.',
        AppTheme.success,
        duration: 3,
      );
    } else {
      _show('Sale recorded successfully!', AppTheme.success);
    }

    setState(() {
      _totalCtrl.clear();
      _paidCtrl.clear();
      _noteCtrl.clear();
      _nameCtrl.clear();
      _phoneCtrl.clear();
      _date = DateTime.now();
      _paymentMethod = 'cash';
    });
    widget.onRecorded?.call();
  }

  void _show(String msg, Color bg, {int duration = 2}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: bg,
      duration: Duration(seconds: duration),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DailySalesProvider>();

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [

            // ── Date ──────────────────────────────────────────────────────
            _Card(
              child: InkWell(
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
                  decoration: const InputDecoration(
                    labelText: 'Sale Date',
                    prefixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                  child: Text(DateFormat('dd MMM yyyy').format(_date)),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ── Amounts ───────────────────────────────────────────────────
            _Card(
              child: Column(children: [
                TextField(
                  controller: _totalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total Sales Amount (TZS)',
                    prefixText: 'TZS ',
                    prefixIcon: Icon(Icons.receipt_rounded),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _paidCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Cash Received (TZS)',
                    prefixText: 'TZS ',
                    prefixIcon: const Icon(Icons.payments_rounded),
                    hintText: 'Leave empty if fully paid',
                    suffixIcon: _paidCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _paidCtrl.clear()),
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),

                // Summary row shown when cash is entered
                if (_total > 0 && _paidCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _hasDebt
                          ? AppTheme.warning.withValues(alpha: 0.08)
                          : AppTheme.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _hasDebt
                              ? AppTheme.warning.withValues(alpha: 0.35)
                              : AppTheme.success.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _AmountCol('Total',
                            'TZS ${FormatUtils.currency(_total)}',
                            AppTheme.textPrimary),
                        _AmountCol('Cash Paid',
                            'TZS ${FormatUtils.currency(_paid)}',
                            AppTheme.success),
                        _AmountCol('Debt',
                            'TZS ${FormatUtils.currency(_debt)}',
                            _hasDebt ? AppTheme.warning : AppTheme.textSecondary),
                      ],
                    ),
                  ),
                ],
              ]),
            ),

            const SizedBox(height: 10),

            // ── Payment Method ────────────────────────────────────────────
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Method',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _paymentMethods.map((m) {
                      final selected = _paymentMethod == m.$1;
                      return GestureDetector(
                        onTap: () => setState(() => _paymentMethod = m.$1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.primary.withValues(alpha: 0.12)
                                : Colors.grey.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected ? AppTheme.primary : AppTheme.border,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(m.$3,
                                size: 16,
                                color: selected ? AppTheme.primary : AppTheme.textSecondary),
                            const SizedBox(width: 6),
                            Text(m.$2,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                    color: selected ? AppTheme.primary : AppTheme.textSecondary)),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Note ──────────────────────────────────────────────────────
            _Card(
              child: TextField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  prefixIcon: Icon(Icons.note_rounded),
                ),
                maxLines: 2,
              ),
            ),

            // ── Customer (shown only when debt) ──────────────────────────
            if (_hasDebt) ...[
              const SizedBox(height: 10),
              _Card(
                borderColor: AppTheme.warning,
                child: Column(children: [
                  const Row(children: [
                    Icon(Icons.info_outline, size: 14, color: AppTheme.warning),
                    SizedBox(width: 6),
                    Text('Customer details required for debt tracking',
                        style:
                            TextStyle(fontSize: 12, color: AppTheme.warning)),
                  ]),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name *',
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_rounded),
                    ),
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: prov.loading ? null : _submit,
                icon: prov.loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(_hasDebt
                        ? Icons.account_balance_wallet_rounded
                        : Icons.check_circle_rounded),
                label: Text(
                    _hasDebt ? 'Record Sale + Add Debt' : 'Record Sale'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _hasDebt ? AppTheme.warning : AppTheme.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Tab 2: History
// ══════════════════════════════════════════════════════════════════════════════

class _HistoryTab extends StatefulWidget {
  const _HistoryTab();

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  DateTime _date = DateTime.now();

  Future<void> _load(DateTime dt) async {
    final d = DateFormat('yyyy-MM-dd').format(dt);
    await context.read<DailySalesProvider>().loadSales(startDate: d, endDate: d);
  }

  Future<void> _pickDate() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (dt != null && mounted) {
      setState(() => _date = dt);
      await _load(dt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov  = context.watch<DailySalesProvider>();
    final sales = prov.sales;
    final isToday = DateFormat('yyyy-MM-dd').format(_date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    final totalRevenue = sales.fold(0.0, (s, e) => s + e.totalAmount);
    final totalCash    = sales.fold(0.0, (s, e) => s + e.cashPaid);
    final totalDebt    = sales.fold(0.0, (s, e) => s + e.debt);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: RefreshIndicator(
          onRefresh: () => _load(_date),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Date selector
              _Card(
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 20, color: AppTheme.primary),
                      const SizedBox(width: 12),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Viewing sales for',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary)),
                            Text(
                              isToday
                                  ? 'Today — ${DateFormat('dd MMM yyyy').format(_date)}'
                                  : DateFormat('dd MMM yyyy').format(_date),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary),
                            ),
                          ]),
                      const Spacer(),
                      const Icon(Icons.edit_calendar_rounded,
                          size: 18, color: AppTheme.textSecondary),
                    ]),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Summary cards
              if (!prov.loading && sales.isNotEmpty) ...[
                Row(children: [
                  Expanded(
                      child: _SummaryCard(
                          label: 'Total Sales',
                          value: 'TZS ${FormatUtils.currency(totalRevenue)}',
                          icon: Icons.receipt_rounded,
                          color: AppTheme.primary)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _SummaryCard(
                          label: 'Cash Received',
                          value: 'TZS ${FormatUtils.currency(totalCash)}',
                          icon: Icons.payments_rounded,
                          color: AppTheme.success)),
                  if (totalDebt > 0) ...[
                    const SizedBox(width: 8),
                    Expanded(
                        child: _SummaryCard(
                            label: 'Debt',
                            value: 'TZS ${FormatUtils.currency(totalDebt)}',
                            icon: Icons.account_balance_wallet_rounded,
                            color: AppTheme.warning)),
                  ],
                ]),
                const SizedBox(height: 16),
              ],

              // Sales list
              if (prov.loading)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator()))
              else if (sales.isEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: const Column(children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 48, color: AppTheme.textSecondary),
                    SizedBox(height: 12),
                    Text('No sales recorded for this date',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 15)),
                  ]),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: sales.asMap().entries.map((e) {
                      final i = e.key;
                      final s = e.value;
                      return Column(children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text('${i + 1}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TZS ${FormatUtils.currency(s.totalAmount)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppTheme.textPrimary),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(children: [
                                      const Icon(Icons.payments_rounded,
                                          size: 12, color: AppTheme.success),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Paid: TZS ${FormatUtils.currency(s.cashPaid)}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.success),
                                      ),
                                      if (s.debt > 0) ...[
                                        const SizedBox(width: 10),
                                        const Icon(
                                            Icons
                                                .account_balance_wallet_rounded,
                                            size: 12,
                                            color: AppTheme.warning),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Debt: TZS ${FormatUtils.currency(s.debt)}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.warning),
                                        ),
                                      ],
                                    ]),
                                    if (s.customerName != null)
                                      Row(children: [
                                        const Icon(Icons.person_rounded,
                                            size: 12,
                                            color: AppTheme.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(s.customerName!,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textSecondary)),
                                      ]),
                                    if (s.note != null && s.note!.isNotEmpty)
                                      Text(s.note!,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textSecondary,
                                              fontStyle: FontStyle.italic)),
                                  ]),
                            ),
                            Text(
                              DateFormat('HH:mm').format(
                                  DateTime.tryParse(s.createdAt) ??
                                      DateTime.now()),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary),
                            ),
                          ]),
                        ),
                        if (i < sales.length - 1)
                          const Divider(
                              height: 1,
                              color: AppTheme.border,
                              indent: 16,
                              endIndent: 16),
                      ]);
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  const _Card({required this.child, this.borderColor});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor ?? AppTheme.border),
        ),
        padding: const EdgeInsets.all(16),
        child: child,
      );
}

class _AmountCol extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _AmountCol(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        ],
      );
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textSecondary)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: color)),
                  ),
                ]),
          ),
        ]),
      );
}
