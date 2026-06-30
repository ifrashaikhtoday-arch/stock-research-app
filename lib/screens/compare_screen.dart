import 'package:flutter/material.dart';
import '../data/stock_service.dart';
import '../utils.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final TextEditingController _controller1 = TextEditingController();
  final TextEditingController _controller2 = TextEditingController();
  final StockService _stockService = StockService();

  StockData? _stock1;
  StockData? _stock2;
  bool _isLoading1 = false;
  bool _isLoading2 = false;
  String? _error1;
  String? _error2;
  List<MapEntry<String, String>> _suggestions1 = [];
  List<MapEntry<String, String>> _suggestions2 = [];
void _updateSuggestions(int stockNumber, String query) {
    if (query.trim().isEmpty) {
      setState(() {
        if (stockNumber == 1) {
          _suggestions1 = [];
        } else {
          _suggestions2 = [];
        }
      });
      return;
    }
    final lower = query.trim().toLowerCase();
    final matches = stockSymbols.entries
        .where((entry) => entry.key.contains(lower))
        .take(5)
        .toList();
    setState(() {
      if (stockNumber == 1) {
        _suggestions1 = matches;
      } else {
        _suggestions2 = matches;
      }
    });
  }
  Future<void> _searchStock(int stockNumber, String query) async {
    if (query.trim().isEmpty) return;

    if (stockNumber == 1) {
      setState(() {
        _isLoading1 = true;
        _error1 = null;
        _stock1 = null;
      });
    } else {
      setState(() {
        _isLoading2 = true;
        _error2 = null;
        _stock2 = null;
      });
    }

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
      if (stockNumber == 1) {
        setState(() {
          _stock1 = data;
          _isLoading1 = false;
          _suggestions1 = [];
        });
      } else {
        setState(() {
          _stock2 = data;
          _isLoading2 = false;
          _suggestions2 = [];
        });
      }
    } catch (e) {
      if (stockNumber == 1) {
        setState(() {
          _error1 = 'Stock not found';
          _isLoading1 = false;
        });
      } else {
        setState(() {
          _error2 = 'Stock not found';
          _isLoading2 = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: const Text('Compare Stocks',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_stock1 != null) await _searchStock(1, _stock1!.symbol);
          if (_stock2 != null) await _searchStock(2, _stock2!.symbol);
        },
        color: theme.colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildSearchBox(theme, 1, _controller1)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('VS',
                        style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _buildSearchBox(theme, 2, _controller2)),
                ],
              ),

              const SizedBox(height: 20),

              if (_stock1 != null || _stock2 != null)
                _buildStockHeaders(theme),

              const SizedBox(height: 16),

              if (_stock1 != null || _stock2 != null) ...[
                _buildCompareCard(theme, 'Current Price',
                    _stock1 != null ? formatRupee(_stock1!.currentPrice) : '-',
                    _stock2 != null ? formatRupee(_stock2!.currentPrice) : '-',
                    higherIsBetter: true,
                    num1: _stock1?.currentPrice,
                    num2: _stock2?.currentPrice),
                const SizedBox(height: 10),
                _buildCompareCard(theme, 'Today\'s Change',
                    _stock1 != null
                        ? '${_stock1!.changePercent >= 0 ? '+' : ''}${_stock1!.changePercent}%'
                        : '-',
                    _stock2 != null
                        ? '${_stock2!.changePercent >= 0 ? '+' : ''}${_stock2!.changePercent}%'
                        : '-',
                    higherIsBetter: true,
                    num1: _stock1?.changePercent,
                    num2: _stock2?.changePercent),
                const SizedBox(height: 10),
                _buildCompareCard(theme, 'P/E Ratio',
                    _stock1 != null
                        ? _stock1!.peRatio.toStringAsFixed(2)
                        : '-',
                    _stock2 != null
                        ? _stock2!.peRatio.toStringAsFixed(2)
                        : '-',
                    higherIsBetter: false,
                    num1: _stock1?.peRatio,
                    num2: _stock2?.peRatio),
                const SizedBox(height: 10),
                _buildCompareCard(theme, '52W High',
                    _stock1 != null ? formatRupee(_stock1!.high52Week) : '-',
                    _stock2 != null ? formatRupee(_stock2!.high52Week) : '-',
                    higherIsBetter: true,
                    num1: _stock1?.high52Week,
                    num2: _stock2?.high52Week),
                const SizedBox(height: 10),
                _buildCompareCard(theme, '52W Low',
                    _stock1 != null ? formatRupee(_stock1!.low52Week) : '-',
                    _stock2 != null ? formatRupee(_stock2!.low52Week) : '-',
                    higherIsBetter: false,
                    num1: _stock1?.low52Week,
                    num2: _stock2?.low52Week),
              ],

              if (_stock1 == null && _stock2 == null)
                Container(
                  margin: const EdgeInsets.only(top: 40),
                  child: Column(
                    children: [
                      Icon(Icons.compare_arrows,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant
                              .withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text('Search two stocks to compare',
                          style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Example: Reliance vs TCS',
                          style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.6),
                              fontSize: 13)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBox(
      ThemeData theme, int number, TextEditingController controller) {
    final isLoading = number == 1 ? _isLoading1 : _isLoading2;
    final error = number == 1 ? _error1 : _error2;
    final suggestions = number == 1 ? _suggestions1 : _suggestions2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(
                fontSize: 13, color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Stock $number...',
              hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
              prefixIcon: isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary),
                      ),
                    )
                  : Icon(Icons.search,
                      color: theme.colorScheme.onSurfaceVariant, size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (value) => _updateSuggestions(number, value),
            onSubmitted: (value) => _searchStock(number, value),
          ),
        ),
        if (suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08), blurRadius: 8),
              ],
            ),
            child: Column(
              children: suggestions.map((entry) {
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.search,
                      color: theme.colorScheme.primary, size: 16),
                  title: Text(
                    entry.key[0].toUpperCase() + entry.key.substring(1),
                    style: TextStyle(
                        fontSize: 13, color: theme.colorScheme.onSurface),
                  ),
                  trailing: Text(
                    entry.value.replaceAll('.NS', ''),
                    style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11),
                  ),
                  onTap: () {
                    controller.text = entry.key;
                    _searchStock(number, entry.key);
                  },
                );
              }).toList(),
            ),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(error,
                style:
                    const TextStyle(color: Colors.red, fontSize: 11)),
          ),
      ],
    );
  }

  Widget _buildStockHeaders(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _stock1?.companyName ?? 'Stock 1',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 40),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _stock2?.companyName ?? 'Stock 2',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                  fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompareCard(
    ThemeData theme,
    String label,
    String display1,
    String display2, {
    required bool higherIsBetter,
    double? num1,
    double? num2,
    bool isPercent = false,
  }) {
    Color? color1;
    Color? color2;

    if (num1 != null && num2 != null && num1 != num2) {
      final stock1Better =
          higherIsBetter ? num1 > num2 : num1 < num2;
      color1 = stock1Better
          ? const Color(0xFF00C853)
          : const Color(0xFFFF3B30);
      color2 = stock1Better
          ? const Color(0xFFFF3B30)
          : const Color(0xFF00C853);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  display1,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: color1 ?? theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Container(
                  width: 1,
                  height: 24,
                  color: theme.colorScheme.outlineVariant),
              Expanded(
                child: Text(
                  display2,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: color2 ?? theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}