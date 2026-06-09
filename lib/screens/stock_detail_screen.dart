import 'package:fl_chart/fl_chart.dart';
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
  List<double> _priceHistory = [];
  Map<String, double> _levels = {};
  bool _isLoading = true;
  String _selectedPeriod = '1mo';

  @override
  void initState() {
    super.initState();
    _loadStockData();
  }

  Future<void> _loadStockData({String period = '1mo'}) async {
    setState(() => _isLoading = true);
    try {
      final data = await _stockService.getStockData(widget.symbol);
      final prices = await _stockService.getPriceHistory(widget.symbol, period: period);
      final levels = _stockService.getSupportResistance(prices);
      setState(() {
        _stockData = data;
        _priceHistory = prices;
        _levels = levels;
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
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price and change
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
                      const SizedBox(height: 16),
                      // Time period buttons
                      _buildPeriodButtons(),
                      const SizedBox(height: 8),
                      // Chart
                      _buildChart(),
                      const SizedBox(height: 24),
                      // Stock Details
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
                      _detailRow('52 Week Low',
                          '₹${_stockData!.low52Week}'),
                      const Divider(height: 32),
                      // Support and Resistance
                      const Text('Support & Resistance',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _supportResistanceRow(
                          'Support', _levels['support'] ?? 0),
                      _supportResistanceRow(
                          'Resistance', _levels['resistance'] ?? 0),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPeriodButtons() {
    final periods = ['1d', '5d', '1mo', '3mo', '6mo', '1y', '3y', '5y'];
    final labels = ['1D', '5D', '1M', '3M', '6M', '1Y', '3Y', '5Y'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periods.asMap().entries.map((entry) {
          final period = entry.value;
          final label = labels[entry.key];
          final isSelected = _selectedPeriod == period;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedPeriod = period);
              _loadStockData(period: period);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.green
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: isSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart() {
    if (_priceHistory.isEmpty) return const SizedBox();

    final spots = _priceHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    final minPrice = _priceHistory.reduce((a, b) => a < b ? a : b);
    final maxPrice = _priceHistory.reduce((a, b) => a > b ? a : b);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: LineChart(
        LineChartData(
          minY: minPrice * 0.99,
          maxY: maxPrice * 1.01,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '₹${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: _priceHistory.last >= _priceHistory.first
                  ? Colors.green
                  : Colors.red,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: (_priceHistory.last >= _priceHistory.first
                        ? Colors.green
                        : Colors.red)
                    .withOpacity(0.1),
              ),
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: _levels['support'] ?? 0,
                color: Colors.green,
                strokeWidth: 1,
                dashArray: [5, 5],
                label: HorizontalLineLabel(
                  show: true,
                  labelResolver: (line) => 'Support',
                  style: const TextStyle(
                      color: Colors.green, fontSize: 10),
                ),
              ),
              HorizontalLine(
                y: _levels['resistance'] ?? 0,
                color: Colors.red,
                strokeWidth: 1,
                dashArray: [5, 5],
                label: HorizontalLineLabel(
                  show: true,
                  labelResolver: (line) => 'Resistance',
                  style: const TextStyle(
                      color: Colors.red, fontSize: 10),
                ),
              ),
            ],
          ),
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

  Widget _supportResistanceRow(String label, double value) {
    final bool isSupport = label == 'Support';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isSupport ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      fontSize: 16, color: Colors.grey)),
            ],
          ),
          Text(
            '₹$value',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSupport ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}