// lib/screens/alerts_screen.dart
//
// StockSense - Price Alerts Screen
// Shows all stocks where the user has an active price alert (alertSet == true),
// read directly from Firestore at:  users/{uid}/watchlist/{symbol}
//
// Cancelling an alert sets alertSet = false (we DON'T delete the document,
// since it may still be a watchlist item).

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  bool _isLoading = true;
  List<_Alert> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // -- Load all stocks that have an active alert --------------------------
  Future<void> _loadAlerts() async {
    final uid = _uid;
    if (uid == null) {
      if (!mounted) return;
      setState(() {
        _alerts = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('watchlist')
          .where('alertSet', isEqualTo: true)
          .get();

      final List<_Alert> loaded = snapshot.docs.map((doc) {
        final data = doc.data();
        return _Alert(
          symbol: (data['symbol'] ?? doc.id).toString(),
          companyName:
              (data['companyName'] ?? data['name'] ?? doc.id).toString(),
          alertPrice: (data['alertPrice'] ?? 0).toDouble(),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _alerts = loaded;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _alerts = [];
        _isLoading = false;
      });
    }
  }

  // -- Cancel an alert (set alertSet = false, keep the document) ----------
  Future<void> _cancelAlert(_Alert alert) async {
    final uid = _uid;
    if (uid == null) return;

    // Update UI right away
    setState(() => _alerts.removeWhere((a) => a.symbol == alert.symbol));

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('watchlist')
          .doc(alert.symbol)
          .update({
        'alertSet': false,
        'alertPrice': FieldValue.delete(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alert cancelled for ${alert.companyName}'),
            backgroundColor: const Color(0xFF1B5E20),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // If it failed, reload to restore the true state
      _loadAlerts();
    }
  }

  String _formatRupee(double value) {
    return '\u20B9${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Price Alerts',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlerts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
            )
          : _alerts.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: const Color(0xFF1B5E20),
                  onRefresh: _loadAlerts,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _alerts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _buildAlertCard(_alerts[index]),
                  ),
                ),
    );
  }

  Widget _buildAlertCard(_Alert alert) {
    final symbol = alert.symbol.replaceAll('.NS', '');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bell icon badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_active_outlined,
                color: Color(0xFF1B5E20), size: 22),
          ),
          const SizedBox(width: 14),
          // Name + symbol + target price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.companyName,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  symbol,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Alert at ${_formatRupee(alert.alertPrice)}',
                  style: const TextStyle(
                    color: Color(0xFF1B5E20),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Cancel (trash) button
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                color: Colors.red.shade400),
            onPressed: () => _confirmCancel(alert),
            tooltip: 'Cancel alert',
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(_Alert alert) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Alert?'),
        content: Text(
          'Stop the price alert for ${alert.companyName} at ${_formatRupee(alert.alertPrice)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep it',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red.shade700,
              elevation: 0,
            ),
            child: const Text('Cancel alert'),
          ),
        ],
      ),
    );
    if (confirmed == true) _cancelAlert(alert);
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: Color(0xFF1B5E20), size: 34),
          ),
          const SizedBox(height: 20),
          const Text(
            'No price alerts yet',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Open a stock and tap the bell icon\nto set a price alert.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// Simple model for an alert row
class _Alert {
  final String symbol;
  final String companyName;
  final double alertPrice;

  const _Alert({
    required this.symbol,
    required this.companyName,
    required this.alertPrice,
  });
}