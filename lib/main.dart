import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'data/stock_service.dart';
import 'screens/news_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final stockService = StockService();
  try {
    // Fetch 30 days of price history
    final prices = await stockService.getPriceHistory('RELIANCE.NS');
    
    // Calculate support and resistance
    final levels = stockService.getSupportResistance(prices);
    
    print('Current Price: ₹${prices.last}');
    print('Support Level: ₹${levels['support']}');
    print('Resistance Level: ₹${levels['resistance']}');
  } catch (e) {
    print('Error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StockSense',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const NewsScreen(),
    );
  }
}