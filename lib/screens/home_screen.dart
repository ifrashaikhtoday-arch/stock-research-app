<<<<<<< HEAD
import 'search_screen.dart';
=======
import 'compare_screen.dart';

>>>>>>> 0bfbefb (connected firebase login to app)
import 'package:flutter/material.dart';
import '../data/stock_service.dart';
import 'stock_detail_screen.dart';
<<<<<<< HEAD
import 'search_screen.dart';
import 'watchlist_screen.dart';
import 'profile_screen.dart';
=======
>>>>>>> 6b57c735ad8e418d013a11977c4363f8d8aaccce

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

void _onTabTapped(int index) {
  if (index == 1) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchScreen()),
    );
  } else {
    setState(() => _selectedIndex = index);
  }
}
  final StockService _stockService = StockService();
  List<StockData> _stocks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStocks();
  }

  Future<void> _loadStocks() async {
    try {
      final stocks = await _stockService.getWatchlistData([
        'RELIANCE.NS',
        'TCS.NS',
        'INFY.NS',
      ]);
      setState(() {
        _stocks = stocks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

<<<<<<< HEAD
  void _onTabTapped(int index) {
    if (index == 1) {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const SearchScreen()));
    } else if (index == 2) {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const WatchlistScreen()));
    } else if (index == 3) {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()));
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getMarketStatus() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final weekday = now.weekday;
    if (weekday == 6 || weekday == 7) return 'Market Closed';
    if (hour < 9 || (hour == 9 && minute < 15)) return 'Market Opens at 9:15 AM';
    if (hour > 15 || (hour == 15 && minute > 30)) return 'Market Closed';
    return '🟢 Market Open';
  }

=======
>>>>>>> 6b57c735ad8e418d013a11977c4363f8d8aaccce
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
  title: const Text('StockSense'),
  backgroundColor: Theme.of(context).colorScheme.primary,
  foregroundColor: Theme.of(context).colorScheme.onPrimary,
),

        
      
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search stocks...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('My Watchlist',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          _isLoading
              ? const CircularProgressIndicator()
              : Expanded(
                  child: ListView.builder(
                    itemCount: _stocks.length,
                    itemBuilder: (context, index) {
                      final stock = _stocks[index];
                      final isPositive = stock.changePercent >= 0;
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StockDetailScreen(
                                symbol: stock.symbol,
                                companyName: stock.companyName,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: ListTile(
                            title: Text(stock.companyName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text('₹${stock.currentPrice}'),
                            trailing: Text(
                              '${isPositive ? '+' : ''}${stock.changePercent}%',
                              style: TextStyle(
                                color: isPositive
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
<<<<<<< HEAD
                          const SizedBox(height: 4),
                          const Text(
                            'StockSense',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        ),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                      ),
                    ],
=======
                        ),
                      );
                    },
>>>>>>> 6b57c735ad8e418d013a11977c4363f8d8aaccce
                  ),
                ),
        ],
      ),
<<<<<<< HEAD
      child: Row(
        children: [
          const Icon(Icons.access_time, color: Color(0xFF2E7D32), size: 18),
          const SizedBox(width: 8),
          Text(
            _getMarketStatus(),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            'NSE • BSE',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (context) => const SearchScreen())),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey.shade400, size: 20),
            const SizedBox(width: 10),
            Text(
              'Search stocks, companies...',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          Text(
            'See all',
            style: TextStyle(
              fontSize: 13,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockList() {
    if (_isLoading) {
      return Column(
        children: List.generate(4, (index) => _buildSkeletonCard()),
      );
    }

    return Column(
      children: _stocks.map((stock) => _buildStockCard(stock)).toList(),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                height: 14,
                width: 70,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 24,
                width: 55,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(StockData stock) {
    final isPositive = stock.changePercent >= 0;
    final color = isPositive ? const Color(0xFF00C853) : const Color(0xFFFF3B30);
    final bgColor = isPositive
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFEBEE);

    final symbol = stock.symbol.replaceAll('.NS', '');

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
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
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
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stock.companyName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    symbol,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${stock.currentPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${isPositive ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
=======
      bottomNavigationBar: BottomNavigationBar(
>>>>>>> 6b57c735ad8e418d013a11977c4363f8d8aaccce
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bookmark), label: 'Watchlist'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Alerts'),
        ],
      ),
    );
  }
}