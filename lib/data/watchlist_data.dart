// lib/data/watchlist_data.dart
//
// Shared watchlist — yahan watchlist ka data rehta hai taaki
// Watchlist screen aur News screen dono ise use kar sakein.

import 'package:flutter/material.dart';

// Ek stock ka model
class WatchlistStock {
  final String symbol;
  final String name;
  final double price;
  final double changePercent;

  const WatchlistStock({
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePercent,
  });
}

// Ye ChangeNotifier hai — jab bhi watchlist badalti hai,
// ye sabhi screens ko bata deta hai ki "update ho gaya, dobara dikhao"
class WatchlistData extends ChangeNotifier {
  // Shuruaati (default) stocks
  final List<WatchlistStock> _stocks = [
    const WatchlistStock(
      symbol: 'RELIANCE.NS',
      name: 'Reliance Industries',
      price: 2947.55,
      changePercent: 1.34,
    ),
    const WatchlistStock(
      symbol: 'TCS.NS',
      name: 'Tata Consultancy Services',
      price: 3812.20,
      changePercent: -0.58,
    ),
    const WatchlistStock(
      symbol: 'INFY.NS',
      name: 'Infosys',
      price: 1563.80,
      changePercent: 2.11,
    ),
    const WatchlistStock(
      symbol: 'HDFCBANK.NS',
      name: 'HDFC Bank',
      price: 1721.45,
      changePercent: -1.03,
    ),
    const WatchlistStock(
      symbol: 'WIPRO.NS',
      name: 'Wipro',
      price: 478.90,
      changePercent: 0.67,
    ),
  ];

  // Baaki screens isse watchlist padhti hain
  List<WatchlistStock> get stocks => _stocks;

  // Stock hatao
  void removeStock(int index) {
    _stocks.removeAt(index);
    notifyListeners(); // sabhi screens ko batao
  }

  // Stock wapas daalo (Undo ke liye)
  void insertStock(int index, WatchlistStock stock) {
    _stocks.insert(index, stock);
    notifyListeners();
  }

  // Naya stock add karo
  void addStock(WatchlistStock stock) {
    _stocks.add(stock);
    notifyListeners();
  }
}