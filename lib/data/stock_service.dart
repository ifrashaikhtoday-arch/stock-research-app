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
}