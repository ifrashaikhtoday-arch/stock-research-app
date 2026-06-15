import 'package:flutter/material.dart';

class NewsArticle {
  final String source;
  final String timeAgo;
  final String headline;
  final String summary;
  final String category; // 'market' or 'stocks'

  const NewsArticle({
    required this.source,
    required this.timeAgo,
    required this.headline,
    required this.summary,
    required this.category,
  });
}

final List<NewsArticle> _allNews = [
  NewsArticle(
    source: 'Economic Times',
    timeAgo: '2h ago',
    headline: 'Sensex surges 600 points as FIIs return to Indian markets',
    summary:
        'Foreign institutional investors turned net buyers after three weeks of selling, pushing benchmark indices to fresh highs.',
    category: 'market',
  ),
  NewsArticle(
    source: 'Mint',
    timeAgo: '4h ago',
    headline: 'RBI holds repo rate steady at 6.5% for sixth consecutive meeting',
    summary:
        'The central bank maintained its stance on withdrawal of accommodation while keeping a close eye on inflation.',
    category: 'market',
  ),
  NewsArticle(
    source: 'Business Standard',
    timeAgo: '5h ago',
    headline: 'Oil prices dip 2% on global recession fears, IT stocks rally',
    summary:
        'Lower crude prices benefit India\'s import bill, lifting sentiment across energy-importing sectors.',
    category: 'market',
  ),
  NewsArticle(
    source: 'Moneycontrol',
    timeAgo: '1h ago',
    headline: 'Reliance Industries shares hit 52-week high after Q4 results',
    summary:
        'Strong retail and Jio segment growth pushed the stock to a new yearly peak in early trade.',
    category: 'stocks',
  ),
  NewsArticle(
    source: 'CNBC-TV18',
    timeAgo: '3h ago',
    headline: 'TCS announces share buyback worth ₹18,000 crore',
    summary:
        'The IT major\'s board approved the buyback as part of its capital allocation strategy.',
    category: 'stocks',
  ),
];

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('News'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewsList('market'),
          _buildNewsList('stocks'),
        ],
      ),
    );
  }

  Widget _buildNewsList(String category) {
    final theme = Theme.of(context);
    final articles = _allNews.where((a) => a.category == category).toList();

    return ListView.separated(
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
                  Text(
                    article.source,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
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
              const SizedBox(height: 8),
              Text(
                article.summary,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
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
            ],
          ),
        );
      },
    );
  }
}