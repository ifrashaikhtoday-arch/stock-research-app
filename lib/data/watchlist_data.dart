// lib/data/watchlist_data.dart
//
// Shared watchlist that reads/writes DIRECTLY to Firestore.
// Path used:  users/{uid}/watchlist/{symbol}
//
// This same document path is ALSO used by the price-alerts system
// (fields: alertPrice, alertSet, companyName). So:
//   * When ADDING, we use SetOptions(merge: true) so we never wipe
//     existing alert fields.
//   * When REMOVING, if the document still has an active alert
//     (alertSet == true), we DON'T delete the whole document -- we
//     just clear the watchlist-specific fields. Otherwise we delete it.
//
// Live price + changePercent are also refreshed from StockService each
// time the watchlist loads, so the prices shown stay up to date.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'stock_service.dart';

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

class WatchlistData extends ChangeNotifier {
  final StockService _stockService = StockService();

  List<WatchlistStock> _stocks = [];
  bool _isLoading = false;

  List<WatchlistStock> get stocks => _stocks;
  bool get isLoading => _isLoading;

  WatchlistData() {
    loadWatchlist();
  }

  // Current logged-in user's id
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // Reference to this user's watchlist collection in Firestore
  CollectionReference<Map<String, dynamic>>? get _collection {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('watchlist');
  }

  // -- Load watchlist from Firestore, then attach live prices --------------
  Future<void> loadWatchlist() async {
    final collection = _collection;
    if (collection == null) {
      _stocks = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await collection.get();
      final List<WatchlistStock> loaded = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Only show docs that are ACTUALLY in the watchlist.
        // A doc with inWatchlist == false is alert-only -- skip it.
        // (We strictly require inWatchlist == true now, so removed
        //  stocks that still have an alert won't reappear.)
        if (data['inWatchlist'] != true) continue;

        final symbol = (data['symbol'] ?? doc.id).toString();
        final name =
            (data['name'] ?? data['companyName'] ?? symbol).toString();

        // Start with the stored values as a fallback
        double price = (data['price'] ?? 0).toDouble();
        double changePercent = (data['changePercent'] ?? 0).toDouble();

        // Then try to refresh with a live price (Option 2)
        try {
          final stockData = await _stockService.getStockData(symbol);
          price = stockData.currentPrice;
          changePercent = stockData.changePercent;
        } catch (_) {
          // keep the stored fallback values if live fetch fails
        }

        loaded.add(WatchlistStock(
          symbol: symbol,
          name: name,
          price: price,
          changePercent: changePercent,
        ));
      }

      _stocks = loaded;
    } catch (e) {
      // keep whatever we have on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // -- Add a stock -- updates UI instantly, saves to Firestore in background
  void addStock(WatchlistStock stock) {
    final exists = _stocks.any((s) => s.symbol == stock.symbol);
    if (exists) return;

    // 1. Update UI right away
    _stocks.add(stock);
    notifyListeners();

    // 2. Save to Firestore (merge so we don't wipe alert fields)
    final collection = _collection;
    if (collection == null) return;

    collection.doc(stock.symbol).set({
      'symbol': stock.symbol,
      'name': stock.name,
      'companyName': stock.name, // keep both for alert-system compatibility
      'price': stock.price,
      'changePercent': stock.changePercent,
      'inWatchlist': true,
      'addedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // -- Remove a stock by index ---------------------------------------------
  Future<void> removeStock(int index) async {
    if (index < 0 || index >= _stocks.length) return;

    final removed = _stocks[index];

    // 1. Update UI right away
    _stocks.removeAt(index);
    notifyListeners();

    // 2. Update Firestore in the background
    final collection = _collection;
    if (collection == null) return;

    final docRef = collection.doc(removed.symbol);

    try {
      final snapshot = await docRef.get();
      final data = snapshot.data();

      // If this stock still has an active alert, DON'T delete the doc --
      // just mark it as not in the watchlist so the alert survives.
      if (data != null && data['alertSet'] == true) {
        await docRef.update({
          'inWatchlist': false,
          'addedAt': FieldValue.delete(),
          'price': FieldValue.delete(),
          'changePercent': FieldValue.delete(),
          'name': FieldValue.delete(),
        });
      } else {
        // No alert -- safe to delete the whole document
        await docRef.delete();
      }
    } catch (_) {
      // ignore background errors
    }
  }

  // -- Insert a stock back at a position (for Undo) ------------------------
  void insertStock(int index, WatchlistStock stock) {
    final safeIndex = index.clamp(0, _stocks.length);
    _stocks.insert(safeIndex, stock);
    notifyListeners();

    final collection = _collection;
    if (collection == null) return;

    collection.doc(stock.symbol).set({
      'symbol': stock.symbol,
      'name': stock.name,
      'companyName': stock.name,
      'price': stock.price,
      'changePercent': stock.changePercent,
      'inWatchlist': true,
      'addedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}