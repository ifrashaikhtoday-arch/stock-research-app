// lib/screens/watchlist_screen.dart
//
// StockSense – Watchlist Screen
// Place this file at:  stock_research_app/lib/screens/watchlist_screen.dart

import 'package:flutter/material.dart';
import '../screens/stock_detail_screen.dart';

// ─── Data model ──────────────────────────────────────────────────────────────
class WatchlistStock {
  final String symbol;
  final String name;
  final double price;
  final double changePercent;

  const WatchlistStock({
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePercent,
  });
}

// ─── Sample local data (replace with Firebase later) ─────────────────────────
final List<WatchlistStock> _defaultWatchlist = [
  WatchlistStock(
    symbol: 'RELIANCE.NS',
    name: 'Reliance Industries',
    price: 2947.55,
    changePercent: 1.34,
  ),
  WatchlistStock(
    symbol: 'TCS.NS',
    name: 'Tata Consultancy Services',
    price: 3812.20,
    changePercent: -0.58,
  ),
  WatchlistStock(
    symbol: 'INFY.NS',
    name: 'Infosys',
    price: 1563.80,
    changePercent: 2.11,
  ),
  WatchlistStock(
    symbol: 'HDFCBANK.NS',
    name: 'HDFC Bank',
    price: 1721.45,
    changePercent: -1.03,
  ),
  WatchlistStock(
    symbol: 'WIPRO.NS',
    name: 'Wipro',
    price: 478.90,
    changePercent: 0.67,
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────
class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  late List<WatchlistStock> _watchlist;

  @override
  void initState() {
    super.initState();
    _watchlist = List.from(_defaultWatchlist);
  }

  // ── Remove with swipe or trash button ──────────────────────────────────────
  void _removeStock(int index) {
    final removed = _watchlist[index];
    setState(() => _watchlist.removeAt(index));

    final theme = Theme.of(context);
    final messenger = ScaffoldMessenger.of(context);

    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: theme.colorScheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          '${removed.name} removed',
          style: TextStyle(color: theme.colorScheme.onInverseSurface, fontSize: 13),
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: theme.colorScheme.inversePrimary,
          onPressed: () {
            if (mounted) {
              setState(() => _watchlist.insert(index, removed));
            }
          },
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Confirm before deleting (long-press) ───────────────────────────────────
  Future<void> _confirmRemove(int index) async {
    final stock = _watchlist[index];
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RemoveSheet(stockName: stock.name),
    );
    if (confirmed == true) _removeStock(index);
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _watchlist.isEmpty ? _buildEmpty(context) : _buildList(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      elevation: 0,
      centerTitle: false,
      title: const Text(
        'Watchlist',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Text(
              '${_watchlist.length} stocks',
              style: TextStyle(
                color: theme.colorScheme.onPrimary.withOpacity(0.75),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── List ───────────────────────────────────────────────────────────────────
  Widget _buildList() {
    final divider = Theme.of(context).colorScheme.outlineVariant;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _watchlist.length,
      separatorBuilder: (_, __) =>
          Divider(color: divider, height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        return _StockTile(
          stock: _watchlist[index],
          onRemove: () => _confirmRemove(index),
          onSwipeRemove: () => _removeStock(index),
        );
      },
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmpty(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bookmark_border_rounded,
                color: theme.colorScheme.primary, size: 34),
          ),
          const SizedBox(height: 20),
          Text(
            'No stocks saved yet',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search for a stock and tap the\nbookmark icon to add it here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stock tile ───────────────────────────────────────────────────────────────
class _StockTile extends StatelessWidget {
  final WatchlistStock stock;
  final VoidCallback onRemove;
  final VoidCallback onSwipeRemove;

  const _StockTile({
    required this.stock,
    required this.onRemove,
    required this.onSwipeRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = stock.changePercent >= 0;
    final changeColor = isPositive ? Colors.green.shade700 : Colors.red.shade700;
    final changeBg = isPositive ? Colors.green.shade50 : Colors.red.shade50;
    final changeLabel =
        '${isPositive ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%';

    return Dismissible(
      key: ValueKey(stock.symbol),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onSwipeRemove(),
      background: const _SwipeBackground(),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StockDetailScreen(
                symbol: stock.symbol,
                companyName: stock.name,
              ),
            ),
          );
        },
        splashColor: theme.colorScheme.primary.withOpacity(0.08),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _TickerAvatar(symbol: stock.symbol),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock.symbol,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      stock.name,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${_formatPrice(stock.price)}',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: changeBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      changeLabel,
                      style: TextStyle(
                        color: changeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onRemove,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.bookmark_remove_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    final parts = price.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();
    int count = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      if (count == 3 || (count > 3 && (count - 3) % 2 == 0)) {
        buffer.write(',');
      }
      buffer.write(intPart[i]);
      count++;
    }
    return '${buffer.toString().split('').reversed.join()}.$decPart';
  }
}

// ─── Ticker avatar ────────────────────────────────────────────────────────────
class _TickerAvatar extends StatelessWidget {
  final String symbol;

  const _TickerAvatar({required this.symbol});

  static const List<MaterialColor> _palette = [
    Colors.blue,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  @override
  Widget build(BuildContext context) {
    final base = _palette[symbol.codeUnitAt(0) % _palette.length];
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: base.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: base.shade100, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        symbol.substring(0, symbol.length.clamp(0, 3)),
        style: TextStyle(
          color: base.shade700,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Swipe-to-delete background ───────────────────────────────────────────────
class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red.shade50,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline_rounded, color: Colors.red.shade700, size: 22),
          const SizedBox(width: 6),
          Text(
            'Remove',
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Confirm-remove bottom sheet ──────────────────────────────────────────────
class _RemoveSheet extends StatelessWidget {
  final String stockName;

  const _RemoveSheet({required this.stockName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Remove from Watchlist?',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$stockName will be removed. You can add it again anytime from Search.',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Keep it'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade700,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Remove',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}