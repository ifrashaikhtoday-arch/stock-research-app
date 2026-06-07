import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'data/stock_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final stockService = StockService();
  try {
    final stock = await stockService.getStockData('RELIANCE.NS');
    print('Company: ${stock.companyName}');
    print('Price: ₹${stock.currentPrice}');
    print('Change: ${stock.changePercent}%');
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