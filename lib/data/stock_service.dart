import 'dart:convert';
import 'package:http/http.dart' as http;

// This class holds all the information about a stock
class StockData {
  final String symbol;
  final String companyName;
  final double currentPrice;
  final double changePercent;
  final double peRatio;
  final double high52Week;
  final double low52Week;

  StockData({
    required this.symbol,
    required this.companyName,
    required this.currentPrice,
    required this.changePercent,
    required this.peRatio,
    required this.high52Week,
    required this.low52Week,
  });
}

class StockService {
  // Fetches full stock details for any Indian stock
  // Example symbols: RELIANCE.NS, TCS.NS, INFY.NS
  Future<StockData> getStockData(String symbol) async {
    final url = Uri.parse(
      'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?interval=1d&range=1d'
    );

    final response = await http.get(url, headers: {
      'User-Agent': 'Mozilla/5.0',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final meta = data['chart']['result'][0]['meta'];

      // Extract all the details we need
      final currentPrice = (meta['regularMarketPrice'] ?? 0).toDouble();
      final previousClose = (meta['chartPreviousClose'] ?? currentPrice).toDouble();
      final changePercent = ((currentPrice - previousClose) / previousClose) * 100;

      return StockData(
        symbol: symbol,
        companyName: meta['longName'] ?? symbol,
        currentPrice: currentPrice,
        changePercent: double.parse(changePercent.toStringAsFixed(2)),
        peRatio: (meta['trailingPE'] ?? 0).toDouble(),
        high52Week: (meta['fiftyTwoWeekHigh'] ?? 0).toDouble(),
        low52Week: (meta['fiftyTwoWeekLow'] ?? 0).toDouble(),
      );
    } else {
      throw Exception('Failed to fetch stock data for $symbol');
    }
  }

  // Fetch multiple stocks at once for the watchlist
  Future<List<StockData>> getWatchlistData(List<String> symbols) async {
    List<StockData> watchlist = [];
    for (String symbol in symbols) {
      try {
        final stock = await getStockData(symbol);
        watchlist.add(stock);
      } catch (e) {
        print('Error fetching $symbol: $e');
      }
    }
    return watchlist;
  }
}