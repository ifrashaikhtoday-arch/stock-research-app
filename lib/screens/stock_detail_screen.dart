import 'package:flutter/material.dart';
import '../data/stock_service.dart';

class StockDetailScreen extends StatefulWidget {
  final String symbol;
  final String companyName;

  const StockDetailScreen({
    super.key,
    required this.symbol,
    required this.companyName,
  });

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  final StockService _stockService = StockService();
  StockData? _stockData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStockData();
  }

  Future<void> _loadStockData() async {
    try {
      final data = await _stockService.getStockData(widget.symbol);
      setState(() {
        _stockData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.companyName),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stockData == null
              ? const Center(child: Text('Failed to load data'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price section
                      Row(
                        children: [
                          Text(
                            '₹${_stockData!.currentPrice}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _stockData!.changePercent >= 0
                                  ? Colors.green
                                  : Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_stockData!.changePercent >= 0 ? '+' : ''}${_stockData!.changePercent}%',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Details section
                      const Text('Stock Details',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _detailRow('Symbol', _stockData!.symbol),
                      _detailRow('P/E Ratio',
                          _stockData!.peRatio.toStringAsFixed(2)),
                      _detailRow('52 Week High',
                          '₹${_stockData!.high52Week}'),
                      _detailRow(
                          '52 Week Low', '₹${_stockData!.low52Week}'),
                    ],
                  ),
                ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(value,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}