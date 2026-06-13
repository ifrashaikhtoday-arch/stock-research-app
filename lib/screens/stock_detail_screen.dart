import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../data/stock_service.dart';
import '../utils.dart';

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
  bool _isSaved = false;

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

  void _showToast(BuildContext context, String message, Color color,
      {bool showUndo = false}) {
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        bottom: 50,
        left: 20,
        right: 20,
        child: Material(
          borderRadius: BorderRadius.circular(12),
          color: color,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showUndo)
                  GestureDetector(
                    onTap: () {
                      setState(() => _isSaved = false);
                      entry?.remove();
                      _showToast(context, 'Removed from watchlist', Colors.grey);
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Text('UNDO',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(entry!);
    Future.delayed(const Duration(seconds: 3), () => entry?.remove());
  }

  void _shareStock() {
    if (_stockData == null) return;
    final isPositive = _stockData!.changePercent >= 0;
    final text = '📈 ${widget.companyName} (${widget.symbol})\n'
        'Price: ${formatRupee(_stockData!.currentPrice)}\n'
        'Change: ${isPositive ? '+' : ''}${_stockData!.changePercent}%\n'
        'Support: ${formatRupee(_levels['support'] ?? 0)}\n'
        'Resistance: ${formatRupee(_levels['resistance'] ?? 0)}\n\n'
        'Checked on StockSense app 📊';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = _stockData?.changePercent != null
        ? _stockData!.changePercent >= 0
        : true;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: Text(widget.companyName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: _shareStock),
          IconButton(
            icon: Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_add_outlined,
              color: _isSaved ? Colors.yellow : Colors.white,
            ),
            onPressed: () {
              if (_isSaved) return;
              setState(() => _isSaved = true);
              _showToast(context, '${widget.companyName} added to watchlist!',
                  const Color(0xFF2E7D32),
                  showUndo: true);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
          : _stockData == null
              ? const Center(child: Text('Failed to load data'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1B5E20),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatRupee(_stockData!.currentPrice),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPositive
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${isPositive ? '▲' : '▼'} ${isPositive ? '+' : ''}${_stockData!.changePercent}% today',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Chart section
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
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
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Price Chart',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                                Row(
                                  children: [
                                    Text('Line',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: !_isCandlestick
                                                ? const Color(0xFF1B5E20)
                                                : Colors.grey)),
                                    Switch(
                                      value: _isCandlestick,
                                      onChanged: (v) => setState(
                                          () => _isCandlestick = v),
                                      activeColor: const Color(0xFF1B5E20),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    Text('Candle',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: _isCandlestick
                                                ? const Color(0xFF1B5E20)
                                                : Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildPeriodButtons(),
                            const SizedBox(height: 12),
                            _buildChart(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Stock details
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Stock Details',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            const SizedBox(height: 12),
                            _detailRow('Symbol',
                                widget.symbol.replaceAll('.NS', '')),
                            _divider(),
                            _detailRow('P/E Ratio',
                                _stockData!.peRatio.toStringAsFixed(2)),
                            _divider(),
                            _detailRow('52 Week High',
                                formatRupee(_stockData!.high52Week)),
                            _divider(),
                            _detailRow('52 Week Low',
                                formatRupee(_stockData!.low52Week)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Support and Resistance
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Support & Resistance',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            const SizedBox(height: 4),
                            Text(
                              'Key price levels based on 30 days of data',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            _supportResistanceRow(
                                'Support', _levels['support'] ?? 0),
                            const SizedBox(height: 12),
                            _supportResistanceRow(
                                'Resistance', _levels['resistance'] ?? 0),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1B5E20)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
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
    return _isCandlestick ? _buildCandlestickChart() : _buildLineChart();
  }

  Widget _buildLineChart() {
    if (_priceHistory.isEmpty) return const SizedBox(height: 150);

    final spots = _priceHistory.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    final minPrice = _priceHistory.reduce((a, b) => a < b ? a : b);
    final maxPrice = _priceHistory.reduce((a, b) => a > b ? a : b);
    final isUp = _priceHistory.last >= _priceHistory.first;

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: minPrice * 0.99,
          maxY: maxPrice * 1.01,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade100,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 55,
                getTitlesWidget: (value, meta) => Text(
                  '₹${value.toInt()}',
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade400),
                ),
              ),
            ),
            bottomTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: isUp
                  ? const Color(0xFF00C853)
                  : const Color(0xFFFF3B30),
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: (isUp
                        ? const Color(0xFF00C853)
                        : const Color(0xFFFF3B30))
                    .withOpacity(0.08),
              ),
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: _levels['support'] ?? 0,
                color: Colors.green.shade300,
                strokeWidth: 1,
                dashArray: [5, 5],
                label: HorizontalLineLabel(
                  show: true,
                  labelResolver: (line) => 'Support',
                  style: TextStyle(
                      color: Colors.green.shade600, fontSize: 10),
                ),
              ),
              HorizontalLine(
                y: _levels['resistance'] ?? 0,
                color: Colors.red.shade300,
                strokeWidth: 1,
                dashArray: [5, 5],
                label: HorizontalLineLabel(
                  show: true,
                  labelResolver: (line) => 'Resistance',
                  style: TextStyle(
                      color: Colors.red.shade600, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCandlestickChart() {
    if (_candleData.isEmpty) return const SizedBox(height: 150);

    final minPrice =
        _candleData.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    final maxPrice =
        _candleData.map((c) => c.high).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 180,
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade600)),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(color: Colors.grey.shade100, height: 1);
  }

  Widget _supportResistanceRow(String label, double value) {
    final bool isSupport = label == 'Support';
    final color = isSupport
        ? const Color(0xFF00C853)
        : const Color(0xFFFF3B30);
    final bgColor = isSupport
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFEBEE);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: color,
                      fontSize: 14)),
            ],
          ),
          Text(
            formatRupee(value),
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 15),
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

    double priceToY(double price) =>
        size.height - ((price - minPrice) / priceRange) * size.height;

    canvas.drawLine(
      Offset(0, priceToY(supportLevel)),
      Offset(size.width, priceToY(supportLevel)),
      Paint()
        ..color = const Color(0xFF00C853)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
    canvas.drawLine(
      Offset(0, priceToY(resistanceLevel)),
      Offset(size.width, priceToY(resistanceLevel)),
      Paint()
        ..color = const Color(0xFFFF3B30)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final isGreen = candle.close >= candle.open;
      final color =
          isGreen ? const Color(0xFF00C853) : const Color(0xFFFF3B30);
      final x = i * candleWidth + candleWidth / 2;

      canvas.drawLine(
        Offset(x, priceToY(candle.high)),
        Offset(x, priceToY(candle.low)),
        Paint()
          ..color = color
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );

      final bodyTop = priceToY(isGreen ? candle.close : candle.open);
      final bodyBottom = priceToY(isGreen ? candle.open : candle.close);
      final bodyHeight =
          (bodyBottom - bodyTop).abs().clamp(1.0, double.infinity);

      canvas.drawRect(
        Rect.fromLTWH(
            x - candleWidth / 2 + padding, bodyTop,
            candleWidth - padding * 2, bodyHeight),
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}