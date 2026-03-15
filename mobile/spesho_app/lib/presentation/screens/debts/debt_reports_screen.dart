import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/debt_provider.dart';
import '../../../domain/entities/debt_entity.dart';

class DebtReportsScreen extends StatefulWidget {
  const DebtReportsScreen({super.key});
  @override
  State<DebtReportsScreen> createState() => _DebtReportsScreenState();
}

class _DebtReportsScreenState extends State<DebtReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DebtProvider>().loadReports();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Reports'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Daily (30d)'),
            Tab(text: 'Monthly'),
            Tab(text: 'Yearly'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<DebtProvider>().loadReports(),
          ),
        ],
      ),
      body: Consumer<DebtProvider>(
        builder: (_, prov, __) {
          if (prov.reportLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (prov.error != null && prov.report == null) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                const SizedBox(height: 12),
                Text(prov.error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => prov.loadReports(),
                  child: const Text('Retry'),
                ),
              ]),
            );
          }
          final r = prov.report;
          if (r == null) return const SizedBox();

          return Column(children: [
            // Today's summary banner
            _TodayBanner(newDebts: r.todayNewDebts, collected: r.todayCollected),

            // Chronic debtors alert
            if (r.chronicDebtors.isNotEmpty)
              _ChronicAlert(debtors: r.chronicDebtors),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _PeriodList(stats: r.daily,   emptyMsg: 'Hakuna madeni 30 siku zilizopita'),
                  _PeriodList(stats: r.monthly, emptyMsg: 'Hakuna data ya kila mwezi'),
                  _PeriodList(stats: r.yearly,  emptyMsg: 'Hakuna data ya kila mwaka'),
                ],
              ),
            ),
          ]);
        },
      ),
    );
  }
}

// ── Today's banner ────────────────────────────────────────────────────────────
class _TodayBanner extends StatelessWidget {
  final int newDebts;
  final double collected;
  const _TodayBanner({required this.newDebts, required this.collected});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    return Container(
      color: AppTheme.primary.withValues(alpha: 0.06),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        _BannerCard(
          label: 'Madeni Mapya Leo',
          value: '$newDebts',
          icon: Icons.person_add_rounded,
          color: AppTheme.primary,
        ),
        const SizedBox(width: 10),
        _BannerCard(
          label: 'Makusanyo Leo',
          value: 'TZS ${fmt.format(collected)}',
          icon: Icons.payments_rounded,
          color: Colors.green,
        ),
      ]),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _BannerCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 10, color: color)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
      ]),
    ),
  );
}

// ── Chronic debtors alert ─────────────────────────────────────────────────────
class _ChronicAlert extends StatefulWidget {
  final List<DebtEntity> debtors;
  const _ChronicAlert({required this.debtors});
  @override
  State<_ChronicAlert> createState() => _ChronicAlertState();
}

class _ChronicAlertState extends State<_ChronicAlert> {
  bool _expanded = false;
  final fmt = NumberFormat('#,##0.00');

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.debtors.length} mdaiwa sugu (deni ≥ 30 siku)',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.orange, fontSize: 13),
                ),
              ),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: Colors.orange),
            ]),
          ),
        ),
        if (_expanded)
          ...widget.debtors.map((d) => Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(children: [
              const Icon(Icons.person, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(child: Text(d.customerName, style: const TextStyle(fontSize: 13))),
              Text('${d.daysOutstanding} siku',
                  style: const TextStyle(fontSize: 11, color: Colors.orange)),
              const SizedBox(width: 8),
              Text('TZS ${fmt.format(d.balance)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.error)),
            ]),
          )),
      ]),
    );
  }
}

// ── Period list ───────────────────────────────────────────────────────────────
class _PeriodList extends StatelessWidget {
  final List<DebtPeriodStatEntity> stats;
  final String emptyMsg;
  const _PeriodList({required this.stats, required this.emptyMsg});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return Center(child: Text(emptyMsg, style: const TextStyle(color: Colors.grey)));
    }
    final fmt = NumberFormat('#,##0.00');
    // Show most recent at top
    final reversed = stats.reversed.toList();
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: reversed.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final s = reversed[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${s.count}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 2),
              Text('${s.count} mdaiwaji', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('Jumla', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text('TZS ${fmt.format(s.totalAmount)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.error)),
            ]),
          ]),
        );
      },
    );
  }
}
