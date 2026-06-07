import 'dart:convert';
import 'package:http/http.dart' as http;

class StockService {
  // This function fetches the current price of any Indian stock
  // symbol is the stock name like RELIANCE.NS or TCS.NS
  Future<double> getStockPrice(String symbol) async {
    // Yahoo Finance API URL
    final url = Uri.parse(
      'https://query1.finance.yahoo.com/v8/finance/chart/$symbol'
    );

    // Fetching data from the internet
    final response = await http.get(url);

    // If the request was successful
    if (response.statusCode == 200) {
      // Convert the response to a map we can read
      final data = jsonDecode(response.body);

      // Get the current price from the response
      final price = data['chart']['result'][0]['meta']['regularMarketPrice'];

      return price.toDouble();
    } else {
      throw Exception('Failed to fetch stock price');
    }
  }
}