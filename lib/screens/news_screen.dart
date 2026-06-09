// lib/screens/news_screen.dart
//
// StockSense – News Screen
// Place this file at:  stock_research_app/lib/screens/news_screen.dart

import 'package:flutter/material.dart';

// ─── Data model ──────────────────────────────────────────────────────────────

class NewsArticle {
  final String title;
  final String source;
  final String time;
  final String summary;
  final String? tag; // stock tag like 'RELIANCE', null = general market news
  final bool isPositive; // sentiment

  const NewsArticle({
    required this.title,
    required this.source,
    required this.time,
    required this.summary,
    this.tag,
    required this.isPositive,
  });
}

// ─── Sample local data (replace with API later) ───────────────────────────────

const _allNews = [
  // General market news
  NewsArticle(
    title: 'Sensex surges 600 points as FIIs return to Indian markets',
    source: 'Economic Times',
    time: '2h ago',
    summary:
        'Foreign institutional investors turned net buyers after three weeks of selling, pushing benchmark indices to fresh highs.',
    tag: null,
    isPositive: true,
  ),
  NewsArticle(
    title: 'RBI holds repo rate steady at 6.5% for sixth consecutive meeting',
    source: 'Mint',
    time: '4h ago',
    summary:
        'The central bank maintained its stance on withdrawal of accommodation while keeping a close eye on inflation.',
    tag: null,
    isPositive: true,
  ),
  NewsArticle(
    title: 'Oil prices dip 2% on global recession fears, IT stocks rally',
    source: 'Business Standard',
    time: '5h ago',
    summary:
        'Lower crude prices benefit India\'s import bill, lifting sentiment across energy-importing sectors.',
    tag: null,
    isPositive: true,
  ),
  NewsArticle(
    title: 'Small-cap index falls 3% amid profit booking by retail investors',
    source: 'NDTV Profit',
    time: '7h ago',
    summary:
        'Retail investors booked profits after a 12% rally in small-cap stocks over the past month.',
    tag: null,
    isPositive: false,
  ),
  // Stock-specific news
  NewsArticle(
    title: 'Reliance Jio crosses 500 million subscriber milestone',
    source: 'Reuters',
    time: '1h ago',
    summary:
        'Jio\'s subscriber growth accelerated in Q3, driven by affordable 5G plans and rural expansion.',
    tag: 'RELIANCE',
    isPositive: true,
  ),
  NewsArticle(
    title: 'TCS wins \$2.5 billion deal with European banking giant',
    source: 'Bloomberg',
    time: '3h ago',
    summary:
        'The multi-year digital transformation contract is one of TCS\'s largest wins in Europe this year.',
    tag: 'TCS',
    isPositive: true,
  ),
  NewsArticle(
    title: 'Infosys cuts revenue guidance for FY25 amid weak demand',
    source: 'Financial Express',
    time: '6h ago',
    summary:
        'The IT major revised its full-year revenue growth forecast to 1–3%, down from earlier estimates of 3–4%.',
    tag: 'INFY',
    isPositive: false,
  ),
  NewsArticle(
    title: 'HDFC Bank\'s net interest margin improves to 4.3% in Q3',
    source: 'Mint',
    time: '8h ago',
    summary:
        'Strong retail loan growth and controlled deposit costs helped the bank beat analyst expectations.',
    tag: 'HDFCBANK',
    isPositive: true,
  ),
  NewsArticle(
    title: 'Wipro announces 10,000 fresher hires for FY25',
    source: 'Economic Times',
    time: '10h ago',
    summary:
        'The IT firm resumes mass hiring after a two-year slowdown, signalling recovery in deal pipelines.',
    tag: 'WIPRO',
    isPositive: true,
  ),
  NewsArticle(
    title: 'Reliance Retail eyes acquisition of struggling fashion brand',
    source: 'Business Standard',
    time: '12h ago',
    summary:
        'Reliance is in advanced talks to acquire a mid-sized fashion retailer as part of its offline expansion.',
    tag: 'RELIANCE',
    isPositive: true,
  ),
];

// ─── Design tokens (matches Watchlist screen) ─────────────────────────────────

const _green = Color(0xFF00C853);
const _greenDim = Color(0xFF1B3A2A);
const _red = Color(0xFFFF3B30);
const _redDim = Color(0xFF3A1B1B);
const _bg = Color(0xFF0D0D0D);
const _surface = Color(0xFF181818);
const _divider = Color(0xFF242424);
const _textPrimary = Color(0xFFEEEEEE);
const _textSecondary = Color(0xFF888888);

// ─── Screen ───────────────────────────────────────────────────────────────────

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen>
    with SingleTickerProviderStateMixin {
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

  List<NewsArticle> get _marketNews =>
      _allNews.where((n) => n.tag == null).toList();

  List<NewsArticle> get _stockNews =>
      _allNews.where((n) => n.tag != null).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _NewsList(articles: _marketNews),
          _NewsList(articles: _stockNews),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _bg,
      elevation: 0,
      centerTitle: false,
      title: const Text(
        'Market News',
        style: TextStyle(
          color: _textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: _green,
        indicatorWeight: 2,
        labelColor: _green,
        unselectedLabelColor: _textSecondary,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        tabs: const [
          Tab(text: 'Market'),
          Tab(text: 'Stocks'),
        ],
      ),
    );
  }
}

// ─── News list ────────────────────────────────────────────────────────────────

class _NewsList extends StatelessWidget {
  final List<NewsArticle> articles;
  const _NewsList({required this.articles});

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) {
      return const Center(
        child: Text(
          'No news available',
          style: TextStyle(color: _textSecondary, fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: articles.length,
      separatorBuilder: (_, __) =>
          const Divider(color: _divider, height: 1, indent: 16, endIndent: 16),
      itemBuilder: (_, index) => _NewsCard(article: articles[index]),
    );
  }
}

// ─── News card ────────────────────────────────────────────────────────────────

class _NewsCard extends StatelessWidget {
  final NewsArticle article;
  const _NewsCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final sentimentColor = article.isPositive ? _green : _red;
    final sentimentBg = article.isPositive ? _greenDim : _redDim;

    return InkWell(
      onTap: () {
        // TODO: open full article URL when API is connected
      },
      splashColor: _green.withOpacity(0.06),
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: source + time + stock tag ─────────────────────────
            Row(
              children: [
                // Source dot
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: sentimentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  article.source,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '·',
                  style: TextStyle(color: _textSecondary, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Text(
                  article.time,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                // Stock tag badge (only for stock-specific news)
                if (article.tag != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: sentimentBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      article.tag!,
                      style: TextStyle(
                        color: sentimentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Headline ────────────────────────────────────────────────────
            Text(
              article.title,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.4,
                letterSpacing: -0.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),

            // ── Summary ─────────────────────────────────────────────────────
            Text(
              article.summary,
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 10),

            // ── Read more ───────────────────────────────────────────────────
            Row(
              children: [
                Text(
                  'Read full article',
                  style: TextStyle(
                    color: _green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: _green,
                  size: 13,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
