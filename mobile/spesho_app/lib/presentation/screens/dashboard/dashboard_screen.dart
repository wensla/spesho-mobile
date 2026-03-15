import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/utils/format_utils.dart';
import '../../../domain/entities/dashboard_entity.dart';

// ── Dark dashboard palette ────────────────────────────────────────────────────
class _DC {
  static const bg       = Color(0xFF0B1120);
  static const surface  = Color(0xFF162032);
  static const surface2 = Color(0xFF1E2D42);
  static const border   = Color(0xFF253347);
  static const text1    = Color(0xFFF0F6FF);
  static const text2    = Color(0xFF8BA3BE);
  static const cyan     = Color(0xFF22D3EE);
  static const blue     = Color(0xFF60A5FA);
  static const purple   = Color(0xFFA78BFA);
  static const orange   = Color(0xFFFB923C);
  static const red      = Color(0xFFF87171);
  static const green    = Color(0xFF34D399);
  static const yellow   = Color(0xFFFBBF24);
  static const teal     = Color(0xFF2DD4BF);
  static const pink     = Color(0xFFF472B6);
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _refreshInterval = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<DashboardProvider>();
      prov.init();
      prov.startAutoRefresh(interval: _refreshInterval);
    });
  }

  @override
  void dispose() {
    context.read<DashboardProvider>().stopAutoRefresh();
    super.dispose();
  }

  static String greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Habari za asubuhi';
    if (h < 17) return 'Habari za mchana';
    return 'Habari za jioni';
  }

  @override
  Widget build(BuildContext context) {
    // Only rebuild when loading state or error changes — not every 3s data refresh
    final hasError  = context.select<DashboardProvider, bool>((p) => p.error != null && p.data == null);
    final hasData   = context.select<DashboardProvider, bool>((p) => p.data != null);
    final isBgLoad  = context.select<DashboardProvider, bool>((p) => p.loading && p.data != null);
    final userName  = context.select<AuthProvider, String>((p) => p.user?.displayName ?? '');

    return Scaffold(
      backgroundColor: _DC.bg,
      appBar: AppBar(
        backgroundColor: _DC.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(isBgLoad ? 2 : 1),
          child: isBgLoad
              ? LinearProgressIndicator(minHeight: 2, backgroundColor: _DC.border,
                  valueColor: const AlwaysStoppedAnimation(_DC.cyan))
              : Container(height: 1, color: _DC.border),
        ),
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF06B6D4)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: _DC.cyan.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: const Icon(Icons.speed_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Dashboard',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _DC.text1)),
            // Isolated widget — only this rebuilds every second
            _CountdownLabel(userName: userName),
          ]),
        ]),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _DC.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _DC.green.withValues(alpha: 0.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _PulsingDot(),
              const SizedBox(width: 4),
              const Text('LIVE', style: TextStyle(fontSize: 9, color: _DC.green,
                  fontWeight: FontWeight.bold, letterSpacing: 1)),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _DC.text2, size: 20),
            onPressed: () => context.read<DashboardProvider>().load(),
          ),
        ],
      ),
      body: hasError && !hasData
          ? _ErrorView(
              error: context.read<DashboardProvider>().error!,
              onRetry: () => context.read<DashboardProvider>().load())
          : hasData
              ? _DashboardBodyWrapper(greeting: greeting(), userName: userName)
              : const _SkeletonDashboard(),
    );
  }
}

/// Isolated widget — only this rebuilds every second (countdown timer).
/// The rest of the dashboard is NOT affected.
class _CountdownLabel extends StatefulWidget {
  final String userName;
  const _CountdownLabel({required this.userName});
  @override
  State<_CountdownLabel> createState() => _CountdownLabelState();
}

class _CountdownLabelState extends State<_CountdownLabel> {
  static const _interval = 3;
  Timer? _timer;
  int _countdown = _interval;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {
        _now = DateTime.now();
        _countdown = _countdown > 1 ? _countdown - 1 : _interval;
      });
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  String _ago(DateTime? lu) {
    if (lu == null) return '';
    final d = _now.difference(lu);
    if (d.inSeconds < 60) return '${d.inSeconds}s ago';
    return '${d.inMinutes}m ago';
  }

  @override
  Widget build(BuildContext context) {
    final lu = context.select<DashboardProvider, DateTime?>((p) => p.lastUpdated);
    final text = lu != null
        ? 'Updated ${_ago(lu)}  •  Refresh ${_countdown}s'
        : widget.userName.isNotEmpty ? 'Welcome, ${widget.userName}' : 'Loading...';
    return Text(text, style: const TextStyle(fontSize: 10, color: _DC.text2));
  }
}

/// Wrapper that reads data from provider and passes it down.
class _DashboardBodyWrapper extends StatelessWidget {
  final String greeting;
  final String userName;
  const _DashboardBodyWrapper({required this.greeting, required this.userName});

  @override
  Widget build(BuildContext context) {
    final data = context.select<DashboardProvider, DashboardEntity?>((p) => p.data);
    if (data == null) return const SizedBox();
    return _DashboardBody(data: data, greeting: greeting, userName: userName);
  }
}

// ─── Skeleton loading UI (shows instantly while data loads) ──────────────────

class _SkeletonDashboard extends StatefulWidget {
  const _SkeletonDashboard();
  @override
  State<_SkeletonDashboard> createState() => _SkeletonDashboardState();
}

class _SkeletonDashboardState extends State<_SkeletonDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Widget _box(double w, double h, {double radius = 8}) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Container(
      width: w, height: h,
      decoration: BoxDecoration(
        color: _DC.surface2.withValues(alpha: _anim.value),
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
  );

  Widget _card(double w) => Container(
    width: w,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _DC.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border(left: BorderSide(color: _DC.border, width: 3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _box(38, 38, radius: 10),
        _box(14, 14, radius: 4),
      ]),
      const SizedBox(height: 14),
      _box(60, 10),
      const SizedBox(height: 6),
      _box(w * 0.7, 18),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth - 32;
      final cardW = (w - 12) / 2;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome banner skeleton
          _box(double.infinity, 90, radius: 16),
          const SizedBox(height: 20),
          _box(160, 12, radius: 6),
          const SizedBox(height: 10),
          Wrap(spacing: 12, runSpacing: 12,
            children: List.generate(4, (_) => _card(cardW))),
          const SizedBox(height: 24),
          _box(160, 12, radius: 6),
          const SizedBox(height: 10),
          _box(double.infinity, 260, radius: 16),
          const SizedBox(height: 24),
          _box(160, 12, radius: 6),
          const SizedBox(height: 10),
          Wrap(spacing: 12, runSpacing: 12,
            children: List.generate(3, (_) => _card((w - 24) / 3 < 120 ? cardW : (w - 24) / 3))),
        ],
      );
    });
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}
class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.2, end: 1.0).animate(_ctrl);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _anim,
    child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: _DC.green, shape: BoxShape.circle)),
  );
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, size: 52, color: _DC.red),
      const SizedBox(height: 12),
      Text(error, textAlign: TextAlign.center, style: const TextStyle(color: _DC.text2)),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: onRetry,
        style: ElevatedButton.styleFrom(backgroundColor: _DC.cyan, foregroundColor: Colors.black87),
        child: const Text('Retry'),
      ),
    ]),
  );
}

// ─── Main Body ────────────────────────────────────────────────────────────────

class _DashboardBody extends StatelessWidget {
  final DashboardEntity data;
  final String greeting;
  final String userName;
  const _DashboardBody({required this.data, required this.greeting, required this.userName});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _DC.cyan,
      backgroundColor: _DC.surface,
      onRefresh: () => context.read<DashboardProvider>().load(),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isWide = w >= 700;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _WelcomeBanner(greeting: greeting, userName: userName),
                const SizedBox(height: 20),

                // ── Sales KPI ──────────────────────────────────────────────
                _SectionLabel(title: 'Mauzo', icon: Icons.point_of_sale_rounded, color: _DC.cyan),
                const SizedBox(height: 10),
                _KpiGrid(width: w, cards: [
                  _KpiCard(label: 'Leo',       value: FormatUtils.currency(data.totalSalesToday),  icon: Icons.today_rounded,         accent: _DC.cyan,   prefix: 'TZS'),
                  _KpiCard(label: 'Wiki Hii',  value: FormatUtils.currency(data.totalSalesWeek),   icon: Icons.view_week_rounded,     accent: _DC.blue,   prefix: 'TZS'),
                  _KpiCard(label: 'Mwezi Huu', value: FormatUtils.currency(data.totalSalesMonth),  icon: Icons.calendar_month_rounded,accent: _DC.purple, prefix: 'TZS'),
                  _KpiCard(label: 'Mwaka Huu', value: FormatUtils.currency(data.totalSalesYear),   icon: Icons.bar_chart_rounded,     accent: _DC.orange, prefix: 'TZS'),
                ]),

                const SizedBox(height: 24),

                // ── Sales Charts (Daily / Weekly / Monthly) ────────────────
                _SectionLabel(title: 'Mwenendo wa Mauzo', icon: Icons.show_chart_rounded, color: _DC.blue),
                const SizedBox(height: 10),
                _SalesChartTabs(data: data),

                const SizedBox(height: 24),

                // ── Debt KPI ───────────────────────────────────────────────
                _SectionLabel(title: 'Madeni & Mikopo', icon: Icons.account_balance_wallet_rounded, color: _DC.red),
                const SizedBox(height: 10),
                _KpiGrid(width: w, cols: 3, cards: [
                  _KpiCard(label: 'Deni Linalodai', value: FormatUtils.currency(data.totalOutstanding),       icon: Icons.money_off_rounded,   accent: _DC.red,    prefix: 'TZS'),
                  _KpiCard(label: 'Makusanyo Leo',  value: FormatUtils.currency(data.totalDebtCollectedToday),icon: Icons.payments_rounded,    accent: _DC.green,  prefix: 'TZS'),
                  _KpiCard(label: 'Wadaiwaji',      value: '${data.totalDebtors}',                           icon: Icons.people_rounded,      accent: _DC.yellow, prefix: ''),
                ]),

                const SizedBox(height: 24),

                // ── Stock KPI ──────────────────────────────────────────────
                _SectionLabel(title: 'Hali ya Stock', icon: Icons.warehouse_rounded, color: _DC.teal),
                const SizedBox(height: 10),
                _KpiGrid(width: w, cols: 2, cards: [
                  _KpiCard(label: 'Jumla ya Stock',  value: '${FormatUtils.number(data.totalStockKg)} kg',   icon: Icons.scale_rounded,   accent: _DC.teal, prefix: ''),
                  _KpiCard(label: 'Thamani ya Stock', value: FormatUtils.currency(data.totalStockValue),      icon: Icons.savings_rounded, accent: _DC.pink, prefix: 'TZS'),
                ]),

                const SizedBox(height: 24),

                // ── Stock levels + Stock trend ────────────────────────────
                if (isWide) ...[
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 5, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _SectionLabel(title: 'Viwango vya Stok', icon: Icons.inventory_rounded, color: _DC.teal),
                      const SizedBox(height: 10),
                      _StockCard(data: data),
                    ])),
                    const SizedBox(width: 16),
                    Expanded(flex: 5, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _SectionLabel(title: 'Mwenendo wa Stok (Siku 30)', icon: Icons.trending_up_rounded, color: _DC.purple),
                      const SizedBox(height: 10),
                      _StockTrendCard(points: data.stockTrend),
                    ])),
                  ]),
                ] else ...[
                  _SectionLabel(title: 'Viwango vya Stok', icon: Icons.inventory_rounded, color: _DC.teal),
                  const SizedBox(height: 10),
                  _StockCard(data: data),
                  const SizedBox(height: 24),
                  _SectionLabel(title: 'Mwenendo wa Stok (Siku 30)', icon: Icons.trending_up_rounded, color: _DC.purple),
                  const SizedBox(height: 10),
                  _StockTrendCard(points: data.stockTrend),
                ],

                const SizedBox(height: 40),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ─── Welcome banner ───────────────────────────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  final String greeting;
  final String userName;
  const _WelcomeBanner({required this.greeting, required this.userName});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days   = ['Jumatatu','Jumanne','Jumatano','Alhamisi','Ijumaa','Jumamosi','Jumapili'];
    final months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ago','Sep','Okt','Nov','Des'];
    final dateStr = '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF0F2544), Color(0xFF162035)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _DC.cyan.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: _DC.cyan.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$greeting,', style: const TextStyle(color: _DC.text2, fontSize: 13)),
          const SizedBox(height: 2),
          Text(userName.isNotEmpty ? userName : 'Admin',
              style: const TextStyle(color: _DC.text1, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _DC.cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _DC.cyan.withValues(alpha: 0.3)),
            ),
            child: Text(dateStr, style: const TextStyle(color: _DC.cyan, fontSize: 11, fontWeight: FontWeight.w500)),
          ),
        ])),
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: _DC.cyan.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: const Icon(Icons.grain_rounded, color: Colors.white, size: 32),
        ),
      ]),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionLabel({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, size: 15, color: color),
    ),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _DC.text1)),
    const SizedBox(width: 8),
    Expanded(child: Container(height: 1, color: _DC.border)),
  ]);
}

// ─── KPI Grid ─────────────────────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  final List<_KpiCard> cards;
  final double width;
  final int? cols;
  const _KpiGrid({required this.cards, required this.width, this.cols});

  @override
  Widget build(BuildContext context) {
    final c = cols ?? (width < 500 ? 2 : 4);
    final itemW = (width - (c - 1) * 12) / c;
    return Wrap(spacing: 12, runSpacing: 12,
      children: cards.map((card) => SizedBox(width: itemW, child: card)).toList());
  }
}

// ─── KPI Card ─────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label, value, prefix;
  final IconData icon;
  final Color accent;
  const _KpiCard({required this.label, required this.value, required this.icon, required this.accent, this.prefix = ''});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _DC.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border(left: BorderSide(color: accent, width: 3)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, size: 20, color: accent),
        ),
        Icon(Icons.trending_up_rounded, size: 14, color: accent.withValues(alpha: 0.6)),
      ]),
      const SizedBox(height: 12),
      Text(label, style: const TextStyle(fontSize: 11, color: _DC.text2, fontWeight: FontWeight.w500)),
      const SizedBox(height: 3),
      if (prefix.isNotEmpty) Text(prefix, style: TextStyle(fontSize: 9, color: accent, fontWeight: FontWeight.w600)),
      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _DC.text1),
          maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  );
}

// ─── Sales Chart with Tabs (Daily / Weekly / Monthly) ───────────────────────

class _SalesChartTabs extends StatefulWidget {
  final DashboardEntity data;
  const _SalesChartTabs({required this.data});
  @override
  State<_SalesChartTabs> createState() => _SalesChartTabsState();
}

class _SalesChartTabsState extends State<_SalesChartTabs> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _DC.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _DC.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Tab bar
        Container(
          decoration: BoxDecoration(
            color: _DC.surface2,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: TabBar(
            controller: _tab,
            labelColor: _DC.cyan,
            unselectedLabelColor: _DC.text2,
            indicatorColor: _DC.cyan,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: _DC.border,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: const [
              Tab(text: 'Kila Siku'),
              Tab(text: 'Kila Wiki'),
              Tab(text: 'Kila Mwezi'),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: TabBarView(
            controller: _tab,
            children: [
              _BarChartView(
                points: widget.data.salesDaily7d,
                barColor: _DC.cyan,
                gradientColors: const [Color(0xFF0EA5E9), Color(0xFF22D3EE)],
                emptyMsg: 'Hakuna mauzo siku 7 zilizopita',
              ),
              _BarChartView(
                points: widget.data.salesWeekly,
                barColor: _DC.blue,
                gradientColors: const [Color(0xFF2563EB), Color(0xFF60A5FA)],
                emptyMsg: 'Hakuna data ya wiki',
              ),
              _BarChartView(
                points: widget.data.salesMonthly,
                barColor: _DC.purple,
                gradientColors: const [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                emptyMsg: 'Hakuna data ya miezi',
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _BarChartView extends StatelessWidget {
  final List<SalesPeriodPointEntity> points;
  final Color barColor;
  final List<Color> gradientColors;
  final String emptyMsg;
  const _BarChartView({required this.points, required this.barColor, required this.gradientColors, required this.emptyMsg});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.bar_chart_rounded, size: 40, color: _DC.border),
        const SizedBox(height: 8),
        Text(emptyMsg, style: const TextStyle(color: _DC.text2, fontSize: 12)),
      ]));
    }

    final maxVal = points.map((p) => p.total).reduce((a, b) => a > b ? a : b);
    final safeMax = maxVal > 0 ? maxVal * 1.3 : 1.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 12, 8),
      child: BarChart(
        BarChartData(
          maxY: safeMax,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => _DC.surface2,
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                '${points[groupIndex].label}\nTZS ${FormatUtils.currency(rod.toY)}',
                TextStyle(color: barColor, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= points.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(points[idx].label,
                        style: const TextStyle(fontSize: 10, color: _DC.text2)),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(color: _DC.border, strokeWidth: 0.8),
          ),
          barGroups: points.asMap().entries.map((e) => BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.total,
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: points.length <= 7 ? 22 : 14,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: safeMax,
                  color: _DC.border.withValues(alpha: 0.3),
                ),
              ),
            ],
          )).toList(),
        ),
      ),
    );
  }
}

// ─── Stock Trend Line Chart ───────────────────────────────────────────────────

class _StockTrendCard extends StatelessWidget {
  final List<StockTrendPointEntity> points;
  const _StockTrendCard({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: _DC.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _DC.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.fromLTRB(8, 16, 12, 8),
      child: points.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.show_chart_rounded, size: 40, color: _DC.border),
              const SizedBox(height: 8),
              const Text('Hakuna data ya mwenendo', style: TextStyle(color: _DC.text2, fontSize: 12)),
            ]))
          : _StockLineChart(points: points),
    );
  }
}

class _StockLineChart extends StatelessWidget {
  final List<StockTrendPointEntity> points;
  const _StockLineChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final inSpots  = points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.qtyIn)).toList();
    final outSpots = points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.qtyOut)).toList();

    final allVals  = [...points.map((p) => p.qtyIn), ...points.map((p) => p.qtyOut)];
    final maxVal   = allVals.isEmpty ? 1.0 : allVals.reduce((a, b) => a > b ? a : b);
    final safeMax  = maxVal > 0 ? maxVal * 1.3 : 1.0;

    return LineChart(
      LineChartData(
        maxY: safeMax,
        minY: 0,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => _DC.surface2,
            tooltipRoundedRadius: 8,
            getTooltipItems: (spots) => spots.map((s) {
              final isIn = s.barIndex == 0;
              return LineTooltipItem(
                '${isIn ? '▲ Ndani' : '▼ Nje'}: ${FormatUtils.number(s.y)} kg',
                TextStyle(color: isIn ? _DC.green : _DC.red, fontSize: 11, fontWeight: FontWeight.bold),
              );
            }).toList(),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (points.length / 5).ceilToDouble().clamp(1, 999),
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx < 0 || idx >= points.length) return const SizedBox();
                final d = points[idx].date;
                final day = d.length >= 10 ? d.substring(8, 10) : d;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(day, style: const TextStyle(fontSize: 9, color: _DC.text2)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: _DC.border, strokeWidth: 0.8),
        ),
        lineBarsData: [
          // Stock IN (green)
          LineChartBarData(
            spots: inSpots,
            isCurved: true,
            color: _DC.green,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                radius: 3, color: _DC.green,
                strokeWidth: 1.5, strokeColor: _DC.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [_DC.green.withValues(alpha: 0.2), _DC.green.withValues(alpha: 0.0)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Stock OUT (red)
          LineChartBarData(
            spots: outSpots,
            isCurved: true,
            color: _DC.red,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                radius: 3, color: _DC.red,
                strokeWidth: 1.5, strokeColor: _DC.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [_DC.red.withValues(alpha: 0.15), _DC.red.withValues(alpha: 0.0)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stock Levels Card with progress bars ─────────────────────────────────────

class _StockCard extends StatelessWidget {
  final DashboardEntity data;
  const _StockCard({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.stockLevels.isEmpty) {
      return Container(
        decoration: BoxDecoration(color: _DC.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _DC.border)),
        padding: const EdgeInsets.all(24),
        child: const Center(child: Text('Hakuna stok', style: TextStyle(color: _DC.text2))),
      );
    }

    final maxStock = data.stockLevels.map((s) => s.stock).reduce((a, b) => a > b ? a : b);
    final colors   = [_DC.cyan, _DC.purple, _DC.orange, _DC.green, _DC.pink, _DC.yellow];

    return Container(
      decoration: BoxDecoration(
        color: _DC.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _DC.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: data.stockLevels.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          final isLow  = s.stock <= 0;
          final accent = isLow ? _DC.red : colors[i % colors.length];
          final pct    = maxStock > 0 ? (s.stock / maxStock).clamp(0.0, 1.0) : 0.0;

          return Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _DC.border.withValues(alpha: 0.6)))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 8, height: 8,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.5), blurRadius: 6)]),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(s.product,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _DC.text1))),
                Text(isLow ? 'Imekwisha' : '${FormatUtils.number(s.stock)} kg',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accent)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct, minHeight: 5,
                  backgroundColor: _DC.border,
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              ),
              const SizedBox(height: 4),
              Text('TZS ${FormatUtils.currency(s.value)}',
                  style: const TextStyle(fontSize: 10, color: _DC.text2)),
            ]),
          );
        }).toList(),
      ),
    );
  }
}
