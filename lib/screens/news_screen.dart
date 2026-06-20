import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

// Same model as before, now built from real API data
class NewsArticle {
  final String source;
  final String timeAgo;
  final String headline;
  final String summary;
  final String url; // link to the real article

  const NewsArticle({
    required this.source,
    required this.timeAgo,
    required this.headline,
    required this.summary,
    required this.url,
  });
}

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<NewsArticle> _marketNews = [];
  List<NewsArticle> _stockNews = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Your NewsAPI.org key
  static const String _apiKey = '545a8c5b92eb4619b6f8a13d8786e180';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Fetches real news from NewsAPI.org ──────────────────────────────────
  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Market news: general Indian business news
      final marketUrl = Uri.parse(
        'https://newsapi.org/v2/everything?q=Indian%20stock%20market&language=en&sortBy=publishedAt&apiKey=$_apiKey',
      );

      // Stock news: specific company news
      final stockUrl = Uri.parse(
        'https://newsapi.org/v2/everything?q=Reliance%20OR%20TCS%20OR%20Infosys%20stock&language=en&sortBy=publishedAt&apiKey=$_apiKey',
      );

      final marketResponse = await http.get(marketUrl);
      final stockResponse = await http.get(stockUrl);

      if (marketResponse.statusCode == 200 && stockResponse.statusCode == 200) {
        final marketData = json.decode(marketResponse.body);
        final stockData = json.decode(stockResponse.body);

        setState(() {
          _marketNews = _parseArticles(marketData['articles']);
          _stockNews = _parseArticles(stockData['articles']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load news. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Something went wrong. Check your internet connection.';
        _isLoading = false;
      });
    }
  }

  // ── Converts the raw API response into our NewsArticle objects ─────────
  List<NewsArticle> _parseArticles(List<dynamic> rawArticles) {
    return rawArticles.take(10).map((item) {
      return NewsArticle(
        source: item['source']?['name'] ?? 'Unknown',
        timeAgo: _formatTimeAgo(item['publishedAt']),
        headline: item['title'] ?? 'No title',
        summary: item['description'] ?? '',
        url: item['url'] ?? '',
      );
    }).toList();
  }

  // ── Turns a date like "2026-06-20T10:00:00Z" into "2h ago" ──────────────
  String _formatTimeAgo(String? publishedAt) {
    if (publishedAt == null) return '';
    try {
      final publishedDate = DateTime.parse(publishedAt);
      final difference = DateTime.now().difference(publishedDate);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('News'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNews, // tap to refresh news
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.onPrimary,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withOpacity(0.6),
          tabs: const [
            Tab(text: 'Market'),
            Tab(text: 'Stocks'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNewsList(_marketNews),
                    _buildNewsList(_stockNews),
                  ],
                ),
    );
  }

  Widget _buildNewsList(List<NewsArticle> articles) {
    final theme = Theme.of(context);

    if (articles.isEmpty) {
      return const Center(child: Text('No news found.'));
    }

    return RefreshIndicator(
      onRefresh: _loadNews,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: articles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final article = articles[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        article.source,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '· ${article.timeAgo}',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  article.headline,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                if (article.summary.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    article.summary,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _openArticle(article.url),
                  child: Row(
                    children: [
                      Text(
                        'Read full article',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 16, color: theme.colorScheme.primary),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Opens the article link in the phone's browser ──────────────────────
  Future<void> _openArticle(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}