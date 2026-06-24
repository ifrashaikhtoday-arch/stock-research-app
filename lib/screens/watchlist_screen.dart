// lib/data/watchlist_data.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

  // Stock ko phone mein save karne ke liye Map mein badlo
  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'name': name,
        'price': price,
        'changePercent': changePercent,
      };

  // Phone se wapas Stock object banane ke liye
  factory WatchlistStock.fromJson(Map<String, dynamic> json) => WatchlistStock(
        symbol: json['symbol'] ?? '',
        name: json['name'] ?? '',
        price: (json['price'] ?? 0).toDouble(),
        changePercent: (json['changePercent'] ?? 0).toDouble(),
      );
}

class WatchlistData extends ChangeNotifier {
  // Shuruaat mein KHALI list — koi default stocks nahi
  List<WatchlistStock> _stocks = [];

  List<WatchlistStock> get stocks => _stocks;

  // Constructor — jab ye banta hai, phone se saved stocks load karo
  WatchlistData() {
    _loadFromStorage();
  }

  // ── Phone se saved watchlist load karo (app khulte waqt) ────────────────
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? saved = prefs.getString('watchlist');
      if (saved != null && saved.isNotEmpty) {
        final List<dynamic> decoded = json.decode(saved);
        _stocks = decoded
            .map((item) => WatchlistStock.fromJson(item))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      // Agar load fail ho, toh khali list hi rahegi
      _stocks = [];
    }
  }

  // ── Watchlist phone mein save karo (har change ke baad) ──────────────────
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded =
          json.encode(_stocks.map((s) => s.toJson()).toList());
      await prefs.setString('watchlist', encoded);
    } catch (e) {
      // Save fail hua toh ignore karo
    }
  }

  // ── Stock hatao ──────────────────────────────────────────────────────────
  void removeStock(int index) {
    _stocks.removeAt(index);
    notifyListeners();
    _saveToStorage();
  }

  // ── Stock wapas daalo (Undo ke liye) ─────────────────────────────────────
  void insertStock(int index, WatchlistStock stock) {
    _stocks.insert(index, stock);
    notifyListeners();
    _saveToStorage();
  }

  // ── Naya stock add karo ───────────────────────────────────────────────────
  void addStock(WatchlistStock stock) {
    // Agar stock already hai toh dobara mat add karo
    final exists = _stocks.any((s) => s.symbol == stock.symbol);
    if (exists) return;

    _stocks.add(stock);
    notifyListeners();
    _saveToStorage();
  }
}