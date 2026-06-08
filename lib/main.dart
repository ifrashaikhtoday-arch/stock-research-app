import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'data/stock_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Test fetching 30 days of price history
  final stockService = StockService();
  try {
    final prices = await stockService.getPriceHistory('RELIANCE.NS');
    print('Total days of data: ${prices.length}');
    print('Latest price: ₹${prices.last}');
    print('Oldest price: ₹${prices.first}');
    print('Highest price: ₹${prices.reduce((a, b) => a > b ? a : b)}');
    print('Lowest price: ₹${prices.reduce((a, b) => a < b ? a : b)}');
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
      home: const HomeScreen(),
    );
  }
}