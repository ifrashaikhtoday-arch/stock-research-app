import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils.dart';
import '../data/stock_service.dart';

class PortfolioStock {
  final String symbol;
  final String name;
  final double buyPrice;
  final int quantity;
  final double currentPrice;

  PortfolioStock({
    required this.symbol,
    required this.name,
    required this.buyPrice,
    required this.quantity,
    required this.currentPrice,
  });

  double get totalInvested => buyPrice * quantity;
  double get currentValue => currentPrice * quantity;
  double get profitLoss => currentValue - totalInvested;
  double get profitLossPercent => (profitLoss / totalInvested) * 100;
  bool get isProfit => profitLoss >= 0;

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'name': name,
        'buyPrice': buyPrice,
        'quantity': quantity,
        'currentPrice': currentPrice,
      };

  factory PortfolioStock.fromJson(Map<String, dynamic> json) => PortfolioStock(
        symbol: json['symbol'],
        name: json['name'],
        buyPrice: json['buyPrice'].toDouble(),
        quantity: json['quantity'],
        currentPrice: json['currentPrice'].toDouble(),
      );
}

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final StockService _stockService = StockService();
  bool _isRefreshing = false;
  List<PortfolioStock> _portfolio = [];

  bool _showAddForm = false;
  final TextEditingController _symbolController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _buyPriceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  List<MapEntry<String, String>> _stockSuggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadPortfolio().then((_) => _refreshPrices());
  }

  Future<void> _savePortfolio() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _portfolio.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList('portfolio_stocks', data);
  }

  Future<void> _loadPortfolio() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('portfolio_stocks') ?? [];
    setState(() {
      _portfolio = data
          .map((s) => PortfolioStock.fromJson(jsonDecode(s)))
          .toList();
    });
  }

  Future<void> _refreshPrices() async {
    if (_portfolio.isEmpty) return;
    setState(() => _isRefreshing = true);
    for (int i = 0; i < _portfolio.length; i++) {
      try {
        final data = await _stockService.getStockData(_portfolio[i].symbol);
        setState(() {
          _portfolio[i] = PortfolioStock(
            symbol: _portfolio[i].symbol,
            name: _portfolio[i].name,
            buyPrice: _portfolio[i].buyPrice,
            quantity: _portfolio[i].quantity,
            currentPrice: data.currentPrice,
          );
        });
      } catch (e) {
        print('Error refreshing ${_portfolio[i].symbol}: $e');
      }
    }
    await _savePortfolio();
    setState(() => _isRefreshing = false);
  }

  void _updatePortfolioSuggestions(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _stockSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    final lower = query.trim().toLowerCase();
    final matches = stockSymbols.entries
        .where((entry) => entry.key.contains(lower))
        .take(5)
        .toList();
    setState(() {
      _stockSuggestions = matches;
      _showSuggestions = matches.isNotEmpty;
    });
  }

  double get _totalInvested =>
      _portfolio.fold(0, (sum, s) => sum + s.totalInvested);
  double get _currentValue =>
      _portfolio.fold(0, (sum, s) => sum + s.currentValue);
  double get _totalPL => _currentValue - _totalInvested;
  double get _totalPLPercent =>
      _portfolio.isEmpty ? 0 : (_totalPL / _totalInvested) * 100;

  Future<void> _addStock() async {
    if (_symbolController.text.isEmpty ||
        _buyPriceController.text.isEmpty ||
        _quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _showAddForm = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fetching live price...'),
        backgroundColor: Color(0xFF1B5E20),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      String symbol = _symbolController.text.trim().toUpperCase();
      if (!symbol.endsWith('.NS')) symbol = '$symbol.NS';

      final stockData = await _stockService.getStockData(symbol);

      setState(() {
        _portfolio.add(PortfolioStock(
          symbol: symbol,
          name: _nameController.text.trim().isEmpty
              ? stockData.companyName
              : _nameController.text.trim(),
          buyPrice: double.parse(_buyPriceController.text),
          quantity: int.parse(_quantityController.text),
          currentPrice: stockData.currentPrice,
        ));
      });

      await _savePortfolio();

      _symbolController.clear();
      _nameController.clear();
      _buyPriceController.clear();
      _quantityController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${stockData.companyName} added at ₹${stockData.currentPrice}'),
          backgroundColor: const Color(0xFF1B5E20),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not fetch price. Check symbol and try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProfit = _totalPL >= 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text('My Portfolio',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showAddForm ? Icons.close : Icons.add),
            onPressed: () =>
                setState(() => _showAddForm = !_showAddForm),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPrices,
        color: const Color(0xFF1B5E20),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Portfolio Value',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      _portfolio.isEmpty
                          ? '₹0.00'
                          : formatRupee(_currentValue),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Invested',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                              Text(
                                  _portfolio.isEmpty
                                      ? '₹0.00'
                                      : formatRupee(_totalInvested),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('P&L',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                              if (_portfolio.isNotEmpty)
                                Row(
                                  children: [
                                    Text(
                                      '${isProfit ? '+' : ''}${formatRupee(_totalPL)}',
                                      style: TextStyle(
                                          color: isProfit
                                              ? const Color(0xFF00C853)
                                              : Colors.red.shade300,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '(${isProfit ? '+' : ''}${_totalPLPercent.toStringAsFixed(2)}%)',
                                      style: TextStyle(
                                          color: isProfit
                                              ? const Color(0xFF00C853)
                                              : Colors.red.shade300,
                                          fontSize: 12),
                                    ),
                                  ],
                                )
                              else
                                const Text('—',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Add stock form
              if (_showAddForm)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Add Stock',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            _symbolController,
                            'Search company name...',
                            onChanged: (value) {
                              _nameController.text = '';
                              _updatePortfolioSuggestions(value);
                            },
                          ),
                          if (_showSuggestions)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          Colors.black.withOpacity(0.08),
                                      blurRadius: 8),
                                ],
                              ),
                              child: Column(
                                children:
                                    _stockSuggestions.map((entry) {
                                  return ListTile(
                                    leading: const Icon(Icons.search,
                                        color: Color(0xFF1B5E20),
                                        size: 18),
                                    title: Text(
                                      entry.key[0].toUpperCase() +
                                          entry.key.substring(1),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    trailing: Text(
                                      entry.value.replaceAll('.NS', ''),
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _symbolController.text =
                                            entry.value;
                                        _nameController.text =
                                            entry.key[0].toUpperCase() +
                                                entry.key.substring(1);
                                        _showSuggestions = false;
                                        _stockSuggestions = [];
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                      _buildTextField(_nameController, 'Company Name'),
                      _buildTextField(_buyPriceController, 'Buy Price (₹)',
                          isNumber: true),
                      _buildTextField(_quantityController, 'Quantity',
                          isNumber: true),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async => await _addStock(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B5E20),
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Add to Portfolio',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),

              // Empty state
              if (_portfolio.isEmpty && !_showAddForm)
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.pie_chart_outline,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('No stocks yet',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add your first stock',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 14),
                      ),
                    ],
                  ),
                ),

              // Stock list
              if (_portfolio.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Holdings',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 8),
                ..._portfolio.map((stock) => _buildStockCard(stock)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {bool isNumber = false, Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType:
            isNumber ? TextInputType.number : TextInputType.text,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(color: Colors.grey.shade400, fontSize: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStockCard(PortfolioStock stock) {
    final color = stock.isProfit
        ? const Color(0xFF00C853)
        : const Color(0xFFFF3B30);
    final bgColor = stock.isProfit
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFEBEE);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Row(
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
                    Text(stock.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(
                        '${stock.quantity} shares × ${formatRupee(stock.buyPrice)}',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatRupee(stock.currentValue),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      '${stock.isProfit ? '+' : ''}${stock.profitLossPercent.toStringAsFixed(2)}%',
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
          const SizedBox(height: 10),
          Divider(color: Colors.grey.shade100, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniStat('Invested', formatRupee(stock.totalInvested)),
              _miniStat('Current', formatRupee(stock.currentValue)),
              _miniStat(
                  'P&L',
                  '${stock.isProfit ? '+' : ''}${formatRupee(stock.profitLoss)}',
                  color: color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label,
            style:
                TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: color ?? const Color(0xFF1A1A1A))),
      ],
    );
  }
}