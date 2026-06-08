import 'package:flutter/material.dart';
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

  // Popular Indian stocks for quick search
  final List<Map<String, String>> _popularStocks = [
    {'name': 'Reliance', 'symbol': 'RELIANCE.NS'},
    {'name': 'TCS', 'symbol': 'TCS.NS'},
    {'name': 'Infosys', 'symbol': 'INFY.NS'},
    {'name': 'HDFC Bank', 'symbol': 'HDFCBANK.NS'},
    {'name': 'Wipro', 'symbol': 'WIPRO.NS'},
    {'name': 'Adani Ports', 'symbol': 'ADANIPORTS.NS'},
    {'name': 'Bajaj Finance', 'symbol': 'BAJFINANCE.NS'},
    {'name': 'Asian Paints', 'symbol': 'ASIANPAINT.NS'},
  ];

     Future<void> _searchStock(String query) async {
    setState(() {
      _isLoading = true;
      _notFound = false;
      _result = null;
    });

    // Convert company name to symbol if needed
    String symbol = query.trim().toLowerCase();
    if (stockSymbols.containsKey(symbol)) {
      symbol = stockSymbols[symbol]!;
    } else {
      // If not found in map, try as direct symbol
      symbol = query.trim().toUpperCase();
      if (!symbol.endsWith('.NS')) {
        symbol = '$symbol.NS';
      }
    }

    try {
      final data = await _stockService.getStockData(symbol);
      setState(() {
        _result = data;
        _isLoading = false;
      });
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
      appBar: AppBar(
        title: const Text('Search Stocks'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Enter NSE symbol e.g. RELIANCE.NS',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (value) => _searchStock(value),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () =>
                      _searchStock(_controller.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  child: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Loading
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),

            // Not found
            if (_notFound)
              const Center(
                child: Text(
                  'Stock not found. Try a valid NSE symbol.',
                  style: TextStyle(color: Colors.red),
                ),
              ),

            // Result
            if (_result != null)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StockDetailScreen(
                        symbol: _result!.symbol,
                        companyName: _result!.companyName,
                      ),
                    ),
                  );
                },
                child: Card(
                  child: ListTile(
                    title: Text(_result!.companyName,
                        style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('₹${_result!.currentPrice}'),
                    trailing: Text(
                      '${_result!.changePercent >= 0 ? '+' : ''}${_result!.changePercent}%',
                      style: TextStyle(
                        color: _result!.changePercent >= 0
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Popular stocks
            const Text('Popular Stocks',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _popularStocks.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () =>
                        _searchStock(_popularStocks[index]['symbol']!),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Center(
                        child: Text(
                          _popularStocks[index]['name']!,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}