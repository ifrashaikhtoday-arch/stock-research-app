import 'package:flutter/material.dart';
import '../data/stock_service.dart';
import '../utils.dart';
import 'stock_detail_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final StockService _stockService = StockService();
  List<StockData> _watchlist = [];
  bool _isLoading = true;

  // Default watchlist symbols
  final List<String> _symbols = [
    'RELIANCE.NS',
    'TCS.NS',
    'INFY.NS',
    'HDFCBANK.NS',
    'WIPRO.NS',
  ];

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
  }

  Future<void> _loadWatchlist() async {
    setState(() => _isLoading = true);
    try {
      final stocks = await _stockService.getWatchlistData(_symbols);
      setState(() {
        _watchlist = stocks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _removeStock(int index) {
    final removed = _watchlist[index];
    setState(() => _watchlist.removeAt(index));
    _symbols.removeAt(index);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
        content: Text('${removed.companyName} removed'),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            setState(() => _watchlist.insert(index, removed));
            _symbols.insert(index, removed.symbol);
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: Text(
          'Watchlist (${_watchlist.length} stocks)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWatchlist,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
          : _watchlist.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadWatchlist,
                  color: const Color(0xFF1B5E20),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _watchlist.length,
                    itemBuilder: (context, index) {
                      return _buildStockCard(_watchlist[index], index);
                    },
                  ),
                ),
    );
  }

  Widget _buildStockCard(StockData stock, int index) {
    final isPositive = stock.changePercent >= 0;
    final color =
        isPositive ? const Color(0xFF00C853) : const Color(0xFFFF3B30);
    final bgColor =
        isPositive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final symbol = stock.symbol.replaceAll('.NS', '');

    return Dismissible(
      key: ValueKey(stock.symbol),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _removeStock(index),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.red.shade400),
            const SizedBox(width: 6),
            Text('Remove',
                style: TextStyle(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StockDetailScreen(
              symbol: stock.symbol,
              companyName: stock.companyName,
            ),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    symbol.substring(0, symbol.length.clamp(0, 3)),
                    style: const TextStyle(
                        color: Color(0xFF1B5E20),
                        fontWeight: FontWeight.bold,
                        fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stock.companyName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF1A1A1A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(symbol,
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatRupee(stock.currentPrice),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      '${isPositive ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bookmark_border_rounded,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No stocks saved yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 8),
          Text(
            'Search for a stock and tap the\nbookmark icon to add it here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}