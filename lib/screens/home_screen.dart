import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
=======
import 'package:shared_preferences/shared_preferences.dart';
>>>>>>> 8270f7276a60c1b16d1ab5c9b40aaea437062e70
import '../data/stock_service.dart';
import 'stock_detail_screen.dart';
import 'search_screen.dart';
import 'watchlist_screen.dart';
import 'compare_screen.dart';
import 'portfolio_screen.dart';
<<<<<<< HEAD
import 'news_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
=======
>>>>>>> 8270f7276a60c1b16d1ab5c9b40aaea437062e70

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final StockService _stockService = StockService();
  List<StockData> _stocks = [];
  bool _isLoading = true;
  String _userName = '';

  final Map<String, List<Map<String, String>>> _sectorStocks = {
    'IT': [
      {'name': 'TCS', 'symbol': 'TCS.NS'},
      {'name': 'Infosys', 'symbol': 'INFY.NS'},
      {'name': 'Wipro', 'symbol': 'WIPRO.NS'},
      {'name': 'HCL Tech', 'symbol': 'HCLTECH.NS'},
    ],
    'Banking': [
      {'name': 'HDFC Bank', 'symbol': 'HDFCBANK.NS'},
      {'name': 'ICICI Bank', 'symbol': 'ICICIBANK.NS'},
      {'name': 'SBI', 'symbol': 'SBIN.NS'},
      {'name': 'Axis Bank', 'symbol': 'AXISBANK.NS'},
    ],
    'Auto': [
      {'name': 'Tata Motors', 'symbol': 'TATAMOTORS.NS'},
      {'name': 'Maruti', 'symbol': 'MARUTI.NS'},
      {'name': 'Bajaj Auto', 'symbol': 'BAJAJ-AUTO.NS'},
      {'name': 'Hero Moto', 'symbol': 'HEROMOTOCO.NS'},
    ],
    'Pharma': [
      {'name': 'Sun Pharma', 'symbol': 'SUNPHARMA.NS'},
      {'name': 'Dr Reddy', 'symbol': 'DRREDDY.NS'},
      {'name': 'Cipla', 'symbol': 'CIPLA.NS'},
      {'name': 'Divis Lab', 'symbol': 'DIVISLAB.NS'},
    ],
    'Energy': [
      {'name': 'Reliance', 'symbol': 'RELIANCE.NS'},
      {'name': 'ONGC', 'symbol': 'ONGC.NS'},
      {'name': 'NTPC', 'symbol': 'NTPC.NS'},
      {'name': 'Tata Power', 'symbol': 'TATAPOWER.NS'},
    ],
    'FMCG': [
      {'name': 'ITC', 'symbol': 'ITC.NS'},
      {'name': 'Nestle', 'symbol': 'NESTLEIND.NS'},
      {'name': 'Dabur', 'symbol': 'DABUR.NS'},
      {'name': 'Britannia', 'symbol': 'BRITANNIA.NS'},
    ],
  };

  List<Map<String, String>> _topStocks = [
    {'name': 'Reliance', 'symbol': 'RELIANCE.NS'},
    {'name': 'TCS', 'symbol': 'TCS.NS'},
    {'name': 'Infosys', 'symbol': 'INFY.NS'},
    {'name': 'HDFC Bank', 'symbol': 'HDFCBANK.NS'},
    {'name': 'Wipro', 'symbol': 'WIPRO.NS'},
    {'name': 'SBI', 'symbol': 'SBIN.NS'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final sectors = prefs.getStringList('selected_sectors') ?? [];

    if (sectors.isNotEmpty) {
      List<Map<String, String>> personalizedStocks = [];
      for (String sector in sectors) {
        if (_sectorStocks.containsKey(sector)) {
          personalizedStocks.addAll(_sectorStocks[sector]!);
        }
      }
      final seen = <String>{};
      personalizedStocks = personalizedStocks
          .where((stock) => seen.add(stock['symbol']!))
          .toList();
      setState(() => _topStocks = personalizedStocks.take(6).toList());
    }

    _loadStocks();
    _loadUserName();
  }

  Future<void> _loadStocks() async {
    try {
      final stocks = await _stockService.getWatchlistData(
        _topStocks.map((s) => s['symbol']!).toList(),
      );
      if (mounted) {
        setState(() {
          _stocks = stocks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserName() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (mounted) {
        setState(() {
          _userName = doc.data()?['name'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading name: $e');
    }
  }

  void _onTabTapped(int index) {
    if (index == 1) {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const SearchScreen()));
    } else if (index == 2) {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const WatchlistScreen()));
    } else if (index == 3) {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => NewsScreen()));
    } else if (index == 4) {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()));
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
    if (hour < 9 || (hour == 9 && minute < 15))
      return 'Market Opens at 9:15 AM';
    if (hour > 15 || (hour == 15 && minute > 30)) return 'Market Closed';
    return '🟢 Market Open';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      body: CustomScrollView(
        slivers: [
<<<<<<< HEAD
          _buildHeader(theme),
          SliverToBoxAdapter(child: _buildMarketStatus(theme)),
          SliverToBoxAdapter(child: _buildSearchBar(theme)),
          SliverToBoxAdapter(child: _buildPortfolioCard(theme)),
          SliverToBoxAdapter(child: _buildSectionTitle(theme)),
          SliverToBoxAdapter(child: _buildStockList(theme)),
=======
          _buildHeader(),
          SliverToBoxAdapter(child: _buildMarketStatus()),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildPortfolioCard()),
          SliverToBoxAdapter(child: _buildSectionTitle('Top Stocks')),
          SliverToBoxAdapter(child: _buildStockList()),
>>>>>>> 8270f7276a60c1b16d1ab5c9b40aaea437062e70
        ],
      ),
      bottomNavigationBar: _buildBottomNav(theme),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: theme.colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primaryContainer,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName.isNotEmpty
                            ? '${_getGreeting()}, $_userName 👋'
                            : '${_getGreeting()} 👋',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
<<<<<<< HEAD
                      const SizedBox(height: 4),
                      Text(
                        'StockSense',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
=======
                      const Icon(Icons.person,
                          color: Colors.white, size: 28),
>>>>>>> 8270f7276a60c1b16d1ab5c9b40aaea437062e70
                    ],
                  ),
                  // Profile icon
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProfileScreen()),
                    ),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.onPrimary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.person,
                          color: theme.colorScheme.onPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarketStatus(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
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
          Icon(Icons.access_time,
              color: theme.colorScheme.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            _getMarketStatus(),
<<<<<<< HEAD
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: theme.colorScheme.onSurface),
          ),
          const Spacer(),
          Text('NSE • BSE',
              style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
=======
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const Spacer(),
          Text('NSE • BSE',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
>>>>>>> 8270f7276a60c1b16d1ab5c9b40aaea437062e70
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (context) => const SearchScreen())),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
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
            Icon(Icons.search,
                color: theme.colorScheme.onSurfaceVariant, size: 20),
            const SizedBox(width: 10),
            Text('Search stocks, companies...',
<<<<<<< HEAD
                style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 14)),
=======
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PortfolioScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B5E20).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.pie_chart_outline,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Portfolio',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  SizedBox(height: 2),
                  Text('Track your investments & P&L',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white70, size: 16),
>>>>>>> 8270f7276a60c1b16d1ab5c9b40aaea437062e70
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioCard(ThemeData theme) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (context) => const PortfolioScreen())),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
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
            Icon(Icons.pie_chart,
                color: theme.colorScheme.onPrimaryContainer, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Portfolio',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: theme.colorScheme.onPrimaryContainer)),
                  const SizedBox(height: 2),
                  Text('Track your investments',
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onPrimaryContainer
                              .withOpacity(0.7))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: theme.colorScheme.onPrimaryContainer, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
<<<<<<< HEAD
          Text('Top Stocks',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface)),
          GestureDetector(
            onTap: () => Navigator.push(
                context,
=======
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A))),
          GestureDetector(
            onTap: () => Navigator.push(context,
>>>>>>> 8270f7276a60c1b16d1ab5c9b40aaea437062e70
                MaterialPageRoute(
                    builder: (context) => const CompareScreen())),
            child: Text('Compare ⇄',
                style: TextStyle(
                    fontSize: 13,
<<<<<<< HEAD
                    color: theme.colorScheme.primary,
=======
                    color: Colors.green.shade700,
>>>>>>> 8270f7276a60c1b16d1ab5c9b40aaea437062e70
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildStockList(ThemeData theme) {
    if (_isLoading) {
      return Column(
        children: List.generate(4, (index) => _buildSkeletonCard(theme)),
      );
    }
    return Column(
      children:
          _stocks.map((stock) => _buildStockCard(stock, theme)).toList(),
    );
  }

  Widget _buildSkeletonCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
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
<<<<<<< HEAD
                  color: theme.colorScheme.surfaceContainerHighest,
=======
                  color: Colors.grey.shade200,
>>>>>>> 8270f7276a60c1b16d1ab5c9b40aaea437062e70
                  borderRadius: BorderRadius.circular(12))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(
<<<<<<< HEAD
                        color: theme.colorScheme.surfaceContainerHighest,
=======
                        color: Colors.grey.shade200,
>>>>>>> 8270f7276a60c1b16d1ab5c9b40aaea437062e70
                        borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 8),
                Container(
                    height: 12,
                    width: 80,
                    decoration: BoxDecoration(
<<<<<<< HEAD
                        color: theme.colorScheme.surfaceContainerHighest,
=======
                        color: Colors.grey.shade200,
>>>>>>> 8270f7276a60c1b16d1ab5c9b40aaea437062e70
                        borderRadius: BorderRadius.circular(4))),
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
<<<<<<< HEAD
                      color: theme.colorScheme.surfaceContainerHighest,
=======
                      color: Colors.grey.shade200,
>>>>>>> 8270f7276a60c1b16d1ab5c9b40aaea437062e70
                      borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 8),
              Container(
                  height: 24,
                  width: 55,
                  decoration: BoxDecoration(
<<<<<<< HEAD
                      color: theme.colorScheme.surfaceContainerHighest,
=======
                      color: Colors.grey.shade200,
>>>>>>> 8270f7276a60c1b16d1ab5c9b40aaea437062e70
                      borderRadius: BorderRadius.circular(6))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(StockData stock, ThemeData theme) {
    final isPositive = stock.changePercent >= 0;
    final color =
<<<<<<< HEAD
        isPositive ? Colors.green.shade700 : Colors.red.shade700;
    final bgColor =
        isPositive ? Colors.green.shade50 : Colors.red.shade50;
=======
        isPositive ? const Color(0xFF00C853) : const Color(0xFFFF3B30);
    final bgColor =
        isPositive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
>>>>>>> 8270f7276a60c1b16d1ab5c9b40aaea437062e70
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
          color: theme.cardColor,
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
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  symbol.substring(0, symbol.length.clamp(0, 3)),
<<<<<<< HEAD
                  style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
=======
                  style: const TextStyle(
                      color: Color(0xFF1B5E20),
>>>>>>> 8270f7276a60c1b16d1ab5c9b40aaea437062e70
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
<<<<<<< HEAD
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: theme.colorScheme.onSurface),
=======
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF1A1A1A)),
>>>>>>> 8270f7276a60c1b16d1ab5c9b40aaea437062e70
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(symbol,
                      style: TextStyle(
<<<<<<< HEAD
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12)),
=======
                          color: Colors.grey.shade500, fontSize: 12)),
>>>>>>> 8270f7276a60c1b16d1ab5c9b40aaea437062e70
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${stock.currentPrice.toStringAsFixed(2)}',
<<<<<<< HEAD
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: theme.colorScheme.onSurface)),
=======
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF1A1A1A))),
>>>>>>> 8270f7276a60c1b16d1ab5c9b40aaea437062e70
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
    );
  }

  Widget _buildBottomNav(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4)),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurfaceVariant,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Search'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_outline),
              activeIcon: Icon(Icons.bookmark),
              label: 'Watchlist'),
          BottomNavigationBarItem(
              icon: Icon(Icons.newspaper_outlined),
              activeIcon: Icon(Icons.newspaper),
              label: 'News'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }
}