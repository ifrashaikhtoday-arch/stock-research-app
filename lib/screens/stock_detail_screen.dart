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
  List<CandleData> _candleData = [];
  bool _isLoading = true;
  String _selectedPeriod = '1mo';
  bool _isCandlestick = false;

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
      final candles = await _stockService.getCandleData(widget.symbol, period: period);
      final levels = _stockService.getSupportResistance(prices);
      setState(() {
        _stockData = data;
        _priceHistory = prices;
        _candleData = candles;
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
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Line',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: !_isCandlestick
                                      ? Colors.green
                                      : Colors.grey)),
                          Switch(
                            value: _isCandlestick,
                            onChanged: (value) =>
                                setState(() => _isCandlestick = value),
                            activeColor: Colors.green,
                          ),
                          Text('Candle',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: _isCandlestick
                                      ? Colors.green
                                      : Colors.grey)),
                        ],
                      ),
                      _buildPeriodButtons(),
                      const SizedBox(height: 8),
                      _buildChart(),
                      const SizedBox(height: 24),
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
    if (_isCandlestick) {
      return _buildCandlestickChart();
    } else {
      return _buildLineChart();
    }
  }

  Widget _buildLineChart() {
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

  Widget _buildCandlestickChart() {
    if (_candleData.isEmpty) return const SizedBox();

    final minPrice =
        _candleData.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    final maxPrice =
        _candleData.map((c) => c.high).reduce((a, b) => a > b ? a : b);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: CustomPaint(
        painter: CandlestickPainter(
          candles: _candleData,
          minPrice: minPrice,
          maxPrice: maxPrice,
          supportLevel: _levels['support'] ?? 0,
          resistanceLevel: _levels['resistance'] ?? 0,
        ),
        child: Container(),
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

class CandlestickPainter extends CustomPainter {
  final List<CandleData> candles;
  final double minPrice;
  final double maxPrice;
  final double supportLevel;
  final double resistanceLevel;

  CandlestickPainter({
    required this.candles,
    required this.minPrice,
    required this.maxPrice,
    required this.supportLevel,
    required this.resistanceLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final priceRange = maxPrice - minPrice;
    final candleWidth = size.width / candles.length;
    final padding = candleWidth * 0.2;

    double priceToY(double price) {
      return size.height - ((price - minPrice) / priceRange) * size.height;
    }

    // Draw support line
    final supportPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, priceToY(supportLevel)),
      Offset(size.width, priceToY(supportLevel)),
      supportPaint,
    );

    // Draw resistance line
    final resistancePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, priceToY(resistanceLevel)),
      Offset(size.width, priceToY(resistanceLevel)),
      resistancePaint,
    );

    // Draw candles
    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final isGreen = candle.close >= candle.open;
      final color = isGreen ? Colors.green : Colors.red;

      final candlePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final wickPaint = Paint()
        ..color = color
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      final x = i * candleWidth + candleWidth / 2;

      canvas.drawLine(
        Offset(x, priceToY(candle.high)),
        Offset(x, priceToY(candle.low)),
        wickPaint,
      );

      final bodyTop = priceToY(isGreen ? candle.close : candle.open);
      final bodyBottom = priceToY(isGreen ? candle.open : candle.close);
      final bodyHeight =
          (bodyBottom - bodyTop).abs().clamp(1.0, double.infinity);

      canvas.drawRect(
        Rect.fromLTWH(
          x - candleWidth / 2 + padding,
          bodyTop,
          candleWidth - padding * 2,
          bodyHeight,
        ),
        candlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}