import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/stock_service.dart';
import 'stock_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final StockService _stockService = StockService();
  StockData? _result;
  bool _isLoading = false;
  bool _notFound = false;

  List<String> _recentSearches = [];
  List<MapEntry<String, String>> _suggestions = [];

  final List<Map<String, String>> _popularStocks = [
    {'name': 'Reliance', 'symbol': 'RELIANCE.NS'},
    {'name': 'TCS', 'symbol': 'TCS.NS'},
    {'name': 'Infosys', 'symbol': 'INFY.NS'},
    {'name': 'HDFC Bank', 'symbol': 'HDFCBANK.NS'},
    {'name': 'Wipro', 'symbol': 'WIPRO.NS'},
    {'name': 'Adani Ports', 'symbol': 'ADANIPORTS.NS'},
    {'name': 'Bajaj Finance', 'symbol': 'BAJFINANCE.NS'},
    {'name': 'Asian Paints', 'symbol': 'ASIANPAINT.NS'},
    {'name': 'SBI', 'symbol': 'SBIN.NS'},
    {'name': 'Zomato', 'symbol': 'ZOMATO.NS'},
    {'name': 'ICICI Bank', 'symbol': 'ICICIBANK.NS'},
    {'name': 'Ola Electric', 'symbol': 'OLAELEC.NS'},
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _saveRecentSearch(String name) async {
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(name);
    _recentSearches.insert(0, name);
    if (_recentSearches.length > 5) {
      _recentSearches = _recentSearches.sublist(0, 5);
    }
    await prefs.setStringList('recent_searches', _recentSearches);
    setState(() {});
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    setState(() => _recentSearches = []);
  }

  void _updateSuggestions(String query) {
    if (query.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    final lower = query.trim().toLowerCase();
    final matches = stockSymbols.entries
        .where((entry) => entry.key.contains(lower))
        .take(6)
        .toList();
    setState(() => _suggestions = matches);
  }

  Future<void> _searchStock(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _notFound = false;
      _result = null;
      _suggestions = [];
    });

    String symbol = query.trim().toLowerCase();
    if (stockSymbols.containsKey(symbol)) {
      symbol = stockSymbols[symbol]!;
    } else {
      String? partialMatch;
      for (String key in stockSymbols.keys) {
        if (key.contains(symbol) || symbol.contains(key)) {
          partialMatch = stockSymbols[key];
          break;
        }
      }
      if (partialMatch != null) {
        symbol = partialMatch;
      } else {
        symbol = query.trim().toUpperCase();
        if (!symbol.endsWith('.NS')) symbol = '$symbol.NS';
      }
    }

    try {
      final data = await _stockService.getStockData(symbol);
      setState(() {
        _result = data;
        _isLoading = false;
      });
      _saveRecentSearch(data.companyName);
    } catch (e) {
      setState(() {
        _notFound = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text('Search Stocks',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: const Color(0xFF1B5E20),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search by name or symbol...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _controller.clear();
                            setState(() {
                              _result = null;
                              _notFound = false;
                              _suggestions = [];
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (value) {
                  setState(() {});
                  _updateSuggestions(value);
                },
                onSubmitted: _searchStock,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live suggestions while typing
                  if (_suggestions.isNotEmpty) ...[
                    const Text('Suggestions',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ..._suggestions.map((entry) => _buildSuggestionTile(
                        entry.key, entry.value)),
                    const SizedBox(height: 20),
                  ],

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                            color: Color(0xFF1B5E20)),
                      ),
                    ),
                  if (_notFound)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.red.shade400),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Stock not found. Try a different name or NSE symbol.',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_result != null) ...[
                    const Text('Result',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    _buildResultCard(_result!),
                    const SizedBox(height: 20),
                  ],

                  // Recent searches
                  if (_suggestions.isEmpty &&
                      _result == null &&
                      _recentSearches.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Recent Searches',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        GestureDetector(
                          onTap: _clearRecentSearches,
                          child: Text('Clear',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _recentSearches.map((name) {
                        return GestureDetector(
                          onTap: () {
                            _controller.text = name;
                            _searchStock(name);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.history,
                                    size: 14, color: Colors.grey.shade500),
                                const SizedBox(width: 6),
                                Text(name,
                                    style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_suggestions.isEmpty) ...[
                    const Text('Popular Stocks',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _popularStocks.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _searchStock(
                              _popularStocks[index]['symbol']!),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: Colors.grey.shade200),
                            ),
                            child: Center(
                              child: Text(
                                _popularStocks[index]['name']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Color(0xFF1B5E20),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionTile(String name, String symbol) {
    return GestureDetector(
      onTap: () {
        _controller.text = name;
        _searchStock(name);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04), blurRadius: 6),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 18, color: Colors.grey.shade400),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name[0].toUpperCase() + name.substring(1),
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 14),
              ),
            ),
            Text(
              symbol.replaceAll('.NS', ''),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(StockData stock) {
    final isPositive = stock.changePercent >= 0;
    final color =
        isPositive ? const Color(0xFF00C853) : const Color(0xFFFF3B30);
    final bgColor =
        isPositive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);

    return GestureDetector(
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
                  stock.symbol.replaceAll('.NS', '').substring(
                      0,
                      stock.symbol
                          .replaceAll('.NS', '')
                          .length
                          .clamp(0, 3)),
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
                          fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(stock.symbol.replaceAll('.NS', ''),
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${stock.currentPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
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
    );
  }
}