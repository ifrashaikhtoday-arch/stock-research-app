// lib/screens/watchlist_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/watchlist_data.dart';
import '../screens/stock_detail_screen.dart';

// Sort options
enum SortOption { gainers, losers, alphabetical }

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  SortOption _currentSort = SortOption.gainers;

  // ── Returns the sorted list based on selected option ────────────────────
  List<WatchlistStock> _getSortedStocks(List<WatchlistStock> stocks) {
    final sorted = List<WatchlistStock>.from(stocks);
    switch (_currentSort) {
      case SortOption.gainers:
        sorted.sort((a, b) => b.changePercent.compareTo(a.changePercent));
        break;
      case SortOption.losers:
        sorted.sort((a, b) => a.changePercent.compareTo(b.changePercent));
        break;
      case SortOption.alphabetical:
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }
    return sorted;
  }

  // ── Remove with manual auto-dismiss timer ──────────────────────────────
  void _removeStock(BuildContext context, WatchlistStock stock) {
    final watchlistData = Provider.of<WatchlistData>(context, listen: false);
    // Find the real index in the original list
    final realIndex = watchlistData.stocks.indexOf(stock);
    if (realIndex == -1) return;

    watchlistData.removeStock(realIndex);

    final theme = Theme.of(context);
    final messenger = ScaffoldMessenger.of(context);

    messenger.clearSnackBars();

    final controller = messenger.showSnackBar(
      SnackBar(
        backgroundColor: theme.colorScheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          '${stock.name} removed',
          style: TextStyle(color: theme.colorScheme.onInverseSurface, fontSize: 13),
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: theme.colorScheme.inversePrimary,
          onPressed: () {
            watchlistData.insertStock(realIndex, stock);
          },
        ),
        duration: const Duration(days: 1),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      controller.close();
    });
  }

  // ── Confirm before deleting (long-press) ───────────────────────────────
  Future<void> _confirmRemove(BuildContext context, WatchlistStock stock) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RemoveSheet(stockName: stock.name),
    );
    if (confirmed == true && context.mounted) _removeStock(context, stock);
  }

  @override
  Widget build(BuildContext context) {
    final watchlistData = context.watch<WatchlistData>();
    final sortedStocks = _getSortedStocks(watchlistData.stocks);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(context, watchlistData.stocks.length),
      body: watchlistData.stocks.isEmpty
          ? _buildEmpty(context)
          : Column(
              children: [
                _buildSortBar(),
                Expanded(child: _buildList(context, sortedStocks)),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, int count) {
    return AppBar(
      backgroundColor: const Color(0xFF1B5E20),
      foregroundColor: Colors.white,
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
              '$count stocks',
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Sort chips bar ──────────────────────────────────────────────────────
  Widget _buildSortBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFFF5F7FA),
      child: Row(
        children: [
          _buildSortChip('Gainers', SortOption.gainers),
          const SizedBox(width: 10),
          _buildSortChip('Losers', SortOption.losers),
          const SizedBox(width: 10),
          _buildSortChip('A-Z', SortOption.alphabetical),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, SortOption option) {
    final isSelected = _currentSort == option;
    return GestureDetector(
      onTap: () => setState(() => _currentSort = option),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B5E20) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B5E20) : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ── List ────────────────────────────────────────────────────────────────
  Widget _buildList(BuildContext context, List<WatchlistStock> stocks) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: stocks.length,
      separatorBuilder: (_, __) =>
          Divider(color: Colors.grey.shade200, height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final stock = stocks[index];
        return _StockTile(
          stock: stock,
          onRemove: () => _confirmRemove(context, stock),
          onSwipeRemove: () => _removeStock(context, stock),
        );
      },
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────
  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bookmark_border_rounded,
                color: Color(0xFF1B5E20), size: 34),
          ),
          const SizedBox(height: 20),
          const Text(
            'No stocks saved yet',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search for a stock and tap the\nbookmark icon to add it here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
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
      child: Material(
        color: const Color(0xFFF5F7FA),
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
          splashColor: const Color(0xFF1B5E20).withOpacity(0.08),
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
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        stock.name,
                        style: TextStyle(
                          color: Colors.grey.shade600,
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
                      style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
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
                      color: Colors.grey.shade600,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
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
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Remove from Watchlist?',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$stockName will be removed. You can add it again anytime from Search.',
            style: TextStyle(
              color: Colors.grey.shade600,
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
                    foregroundColor: const Color(0xFF1A1A1A),
                    side: BorderSide(color: Colors.grey.shade300),
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