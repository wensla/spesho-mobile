import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/live_badge.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';

class StockBalanceScreen extends StatefulWidget {
  const StockBalanceScreen({super.key});

  @override
  State<StockBalanceScreen> createState() => _StockBalanceScreenState();
}

class _StockBalanceScreenState extends State<StockBalanceScreen> {
  Timer? _timer;
  DateTime? _lastUpdated;

  static const _refreshInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _timer = Timer.periodic(_refreshInterval, (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _load() {
    context.read<StockProvider>().loadBalances().then((_) {
      if (mounted) setState(() => _lastUpdated = DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<StockProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Balance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: LiveBadge(lastUpdated: _lastUpdated, interval: _refreshInterval),
          ),
          Expanded(
            child: prov.loading && prov.balances.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : prov.balances.isEmpty
                    ? const Center(child: Text('No stock data'))
                    : Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 20),
                            itemCount: prov.balances.length,
                            itemBuilder: (_, i) {
                              final b = prov.balances[i];
                              final isLow = b.currentStock <= 0;
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isLow
                                        ? AppTheme.error.withValues(alpha: 0.1)
                                        : AppTheme.success.withValues(alpha: 0.1),
                                    child: Icon(
                                      Icons.grain,
                                      color: isLow ? AppTheme.error : AppTheme.success,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(b.productName,
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text(
                                      'TZS ${FormatUtils.currency(b.unitPrice)} / ${b.packageSize}kg  •  TZS ${FormatUtils.currency(b.unitPrice / b.packageSize)}/kg'),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${FormatUtils.number(b.currentStock)} kg',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isLow ? AppTheme.error : AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        'TZS ${FormatUtils.currency(b.stockValue)}',
                                        style: const TextStyle(
                                            fontSize: 11, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
