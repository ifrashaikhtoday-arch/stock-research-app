import 'dart:convert';
import 'package:http/http.dart' as http;
// Map of company names to NSE symbols
const Map<String, String> stockSymbols = {
  'reliance': 'RELIANCE.NS',
  'tcs': 'TCS.NS',
  'infosys': 'INFY.NS',
  'infy': 'INFY.NS',
  'hdfc bank': 'HDFCBANK.NS',
  'hdfcbank': 'HDFCBANK.NS',
  'icici bank': 'ICICIBANK.NS',
  'icicibank': 'ICICIBANK.NS',
  'wipro': 'WIPRO.NS',
  'bajaj finance': 'BAJFINANCE.NS',
  'bajfinance': 'BAJFINANCE.NS',
  'asian paints': 'ASIANPAINT.NS',
  'maruti': 'MARUTI.NS',
  'maruti suzuki': 'MARUTI.NS',
  'sbi': 'SBIN.NS',
  'state bank': 'SBIN.NS',
  'ongc': 'ONGC.NS',
  'coal india': 'COALINDIA.NS',
  'tata motors': 'TATAMOTORS.NS',
  'tata steel': 'TATASTEEL.NS',
  'adani ports': 'ADANIPORTS.NS',
  'adani enterprises': 'ADANIENT.NS',
  'sun pharma': 'SUNPHARMA.NS',
  'itc': 'ITC.NS',
  'ltim': 'LTIM.NS',
  'hcl': 'HCLTECH.NS',
  'hcl tech': 'HCLTECH.NS',
  'axis bank': 'AXISBANK.NS',
  'kotak': 'KOTAKBANK.NS',
  'kotak bank': 'KOTAKBANK.NS',
  'nestle': 'NESTLEIND.NS',
  'britannia': 'BRITANNIA.NS',
  'dr reddy': 'DRREDDY.NS',
  'cipla': 'CIPLA.NS',
  'ultracemco': 'ULTRACEMCO.NS',
  'ultratech': 'ULTRACEMCO.NS',
  'hindalco': 'HINDALCO.NS',
  'hero motocorp': 'HEROMOTOCO.NS',
  'bajaj auto': 'BAJAJ-AUTO.NS',
  'titan': 'TITAN.NS',
  'power grid': 'POWERGRID.NS',
  'ntpc': 'NTPC.NS',
  'tech mahindra': 'TECHM.NS',
  'indusind bank': 'INDUSINDBK.NS',
};
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
  // Fetches 30 days of closing prices for a stock
Future<List<double>> getPriceHistory(String symbol, {String period = '1mo'}) async {
    final url = Uri.parse(
      'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?interval=${_getInterval(period)}&range=$period'
    );

    final response = await http.get(url, headers: {
      'User-Agent': 'Mozilla/5.0',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Get the list of closing prices
      final closes = data['chart']['result'][0]['indicators']['quote'][0]['close'] as List;
      
      // Convert to list of doubles and remove any null values
      final prices = closes
          .where((price) => price != null)
          .map((price) => (price as num).toDouble())
          .toList();

      return prices;
    } else {
      throw Exception('Failed to fetch price history for $symbol');
    }
  }
  // Calculates support and resistance levels from price history
  Map<String, double> getSupportResistance(List<double> prices) {
    if (prices.isEmpty) {
      return {'support': 0, 'resistance': 0};
    }

    // Split prices into windows of 5 days
    // We look for local lows (support) and local highs (resistance)
    List<double> localLows = [];
    List<double> localHighs = [];

    for (int i = 2; i < prices.length - 2; i++) {
      // A local low is a price lower than the 2 days before and after it
      if (prices[i] < prices[i - 1] &&
          prices[i] < prices[i - 2] &&
          prices[i] < prices[i + 1] &&
          prices[i] < prices[i + 2]) {
        localLows.add(prices[i]);
      }

      // A local high is a price higher than the 2 days before and after it
      if (prices[i] > prices[i - 1] &&
          prices[i] > prices[i - 2] &&
          prices[i] > prices[i + 1] &&
          prices[i] > prices[i + 2]) {
        localHighs.add(prices[i]);
      }
    }

    // If no local lows found, use the overall lowest price
    double support = localLows.isEmpty
        ? prices.reduce((a, b) => a < b ? a : b)
        : localLows.reduce((a, b) => a + b) / localLows.length;

    // If no local highs found, use the overall highest price
    double resistance = localHighs.isEmpty
        ? prices.reduce((a, b) => a > b ? a : b)
        : localHighs.reduce((a, b) => a + b) / localHighs.length;

    // Round to 2 decimal places
    support = double.parse(support.toStringAsFixed(2));
    resistance = double.parse(resistance.toStringAsFixed(2));

    return {
      'support': support,
      'resistance': resistance,
    };
  }
  String _getInterval(String period) {
    switch (period) {
      case '1d':
        return '5m';
      case '5d':
        return '15m';
      case '1mo':
        return '1d';
      case '3mo':
        return '1d';
      case '6mo':
        return '1wk';
      case '1y':
        return '1wk';
      case '3y':
        return '1mo';
      case '5y':
        return '1mo';
      default:
        return '1d';
    }
  }
}