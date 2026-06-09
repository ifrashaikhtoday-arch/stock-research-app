// lib/screens/watchlist_screen.dart
//
// StockSense – Watchlist Screen
// Place this file at:  stock_research_app/lib/screens/watchlist_screen.dart

import 'package:flutter/material.dart';

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
    symbol: 'RELIANCE',
    name: 'Reliance Industries',
    price: 2947.55,
    changePercent: 1.34,
  ),
  WatchlistStock(
    symbol: 'TCS',
    name: 'Tata Consultancy Services',
    price: 3812.20,
    changePercent: -0.58,
  ),
  WatchlistStock(
    symbol: 'INFY',
    name: 'Infosys',
    price: 1563.80,
    changePercent: 2.11,
  ),
  WatchlistStock(
    symbol: 'HDFCBANK',
    name: 'HDFC Bank',
    price: 1721.45,
    changePercent: -1.03,
  ),
  WatchlistStock(
    symbol: 'WIPRO',
    name: 'Wipro',
    price: 478.90,
    changePercent: 0.67,
  ),
];

// ─── Design tokens ────────────────────────────────────────────────────────────

const _green = Color(0xFF00C853);       // primary accent
const _greenDim = Color(0xFF1B3A2A);    // green tint for positive badge bg
const _red = Color(0xFFFF3B30);
const _redDim = Color(0xFF3A1B1B);      // red tint for negative badge bg
const _bg = Color(0xFF0D0D0D);          // near-black canvas
const _surface = Color(0xFF181818);     // card surface
const _divider = Color(0xFF242424);
const _textPrimary = Color(0xFFEEEEEE);
const _textSecondary = Color(0xFF888888);

// ─── Screen ───────────────────────────────────────────────────────────────────

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  // Local mutable copy – swap for a provider/Firestore stream later
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

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _surface,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          '${removed.name} removed',
          style: const TextStyle(color: _textPrimary, fontSize: 13),
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: _green,
          onPressed: () => setState(() => _watchlist.insert(index, removed)),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Confirm before deleting (long-press) ───────────────────────────────────

  Future<void> _confirmRemove(int index) async {
    final stock = _watchlist[index];
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: _surface,
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
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: _watchlist.isEmpty ? _buildEmpty() : _buildList(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _bg,
      elevation: 0,
      centerTitle: false,
      title: const Text(
        'Watchlist',
        style: TextStyle(
          color: _textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Text(
            '${_watchlist.length} stocks',
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: _divider, height: 1),
      ),
    );
  }

  // ── List ───────────────────────────────────────────────────────────────────

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _watchlist.length,
      separatorBuilder: (_, __) =>
          const Divider(color: _divider, height: 1, indent: 16, endIndent: 16),
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _greenDim,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bookmark_border_rounded,
                color: _green, size: 34),
          ),
          const SizedBox(height: 20),
          const Text(
            'No stocks saved yet',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Search for a stock and tap the\nbookmark icon to add it here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textSecondary,
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
    final changeColor = isPositive ? _green : _red;
    final changeBg = isPositive ? _greenDim : _redDim;
    final changeLabel =
        '${isPositive ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%';

    return Dismissible(
      key: ValueKey(stock.symbol),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onSwipeRemove(),
      background: _SwipeBackground(),
      child: InkWell(
        onTap: () {
          // TODO: navigate to StockDetailScreen
          // Navigator.push(context, MaterialPageRoute(
          //   builder: (_) => StockDetailScreen(symbol: stock.symbol)));
        },
        splashColor: _green.withOpacity(0.08),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // ── Ticker avatar ───────────────────────────────────────────
              _TickerAvatar(symbol: stock.symbol),
              const SizedBox(width: 14),

              // ── Name + symbol ───────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock.symbol,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      stock.name,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // ── Price + change ──────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${_formatPrice(stock.price)}',
                    style: const TextStyle(
                      color: _textPrimary,
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

              // ── Remove button ───────────────────────────────────────────
              GestureDetector(
                onTap: onRemove,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.bookmark_remove_outlined,
                    color: _textSecondary,
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
    // Show commas for Indian number formatting: 2,947.55
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

  // Simple colour based on first char – gives each stock a consistent identity
  Color _avatarColor(String s) {
    const palette = [
      Color(0xFF1B3A2A), // green-tinted
      Color(0xFF1A2A3A), // blue-tinted
      Color(0xFF2A1A3A), // purple-tinted
      Color(0xFF3A2A1A), // amber-tinted
      Color(0xFF3A1A2A), // rose-tinted
    ];
    return palette[s.codeUnitAt(0) % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _avatarColor(symbol),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _divider, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        symbol.substring(0, symbol.length.clamp(0, 3)),
        style: const TextStyle(
          color: _green,
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
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _redDim,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.delete_outline_rounded, color: _red, size: 22),
          SizedBox(width: 6),
          Text(
            'Remove',
            style: TextStyle(
              color: _red,
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
          // drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Remove from Watchlist?',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$stockName will be removed. You can add it again anytime from Search.',
            style: const TextStyle(
              color: _textSecondary,
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
                    foregroundColor: _textPrimary,
                    side: const BorderSide(color: _divider),
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
                    backgroundColor: _redDim,
                    foregroundColor: _red,
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
