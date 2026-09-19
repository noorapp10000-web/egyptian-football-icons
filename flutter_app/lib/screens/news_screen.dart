// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import '../models/football_models.dart';
import '../services/api_client.dart';
import '../widgets/brand_mark.dart';
import '../widgets/cached_remote_image.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<NewsItem>> _future;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = widget.api.getNews();
    _searchController.addListener(
      () => setState(() => _query = _searchController.text.trim()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final next = widget.api.getNews();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<NewsItem>>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _NewsLoading();
      }
      if (snapshot.hasError || snapshot.data == null) {
        return _NewsError(onRetry: _refresh);
      }
      final allNews = snapshot.data!;
      final query = _query.toLowerCase();
      final news = allNews.where((item) {
        if (query.isEmpty) return true;
        return (item.title + ' ' + item.sourceName).toLowerCase().contains(query);
      }).toList();

      return RefreshIndicator(
        color: kPrimary,
        backgroundColor: kCard,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
          children: [
            _NewsIntro(count: allNews.length),
            const SizedBox(height: 16),
            _NewsSearch(controller: _searchController),
            const SizedBox(height: 18),
            if (news.isEmpty)
              const _NewsEmpty()
            else ...[
              const _NewsSectionTitle(),
              const SizedBox(height: 11),
              _FeaturedNews(item: news.first),
              const SizedBox(height: 17),
              ...news.skip(1).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _NewsListCard(item: item),
                ),
              ),
              const SizedBox(height: 3),
              const _NewsSourceNote(),
            ],
          ],
        ),
      );
    },
  );
}

class _NewsIntro extends StatelessWidget {
  const _NewsIntro({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 17),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      gradient: const LinearGradient(
        colors: [Color(0xff173f31), Color(0xff0b2118)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ),
      border: Border.all(color: kPrimary.withOpacity(.23)),
    ),
    child: Row(
      children: [
        const BrandMark(size: 55),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'نبض المصري',
                style: TextStyle(
                  color: kPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'كل الخبر في مكان واحد',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                count.toString() + ' خبر متاح للقراءة الآن',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.auto_awesome_rounded, color: kGold, size: 25),
      ],
    ),
  );
}

class _NewsSearch extends StatelessWidget {
  const _NewsSearch({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    textDirection: TextDirection.rtl,
    decoration: InputDecoration(
      hintText: 'ابحث في الأخبار',
      hintStyle: const TextStyle(color: kMuted, fontSize: 12),
      prefixIcon: const Icon(Icons.search_rounded, color: kPrimary),
      suffixIcon: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (_, value, __) => value.text.isEmpty
            ? const SizedBox.shrink()
            : IconButton(
                onPressed: controller.clear,
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
      ),
      filled: true,
      fillColor: kCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: kLine),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: kLine),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: kPrimary),
      ),
    ),
  );
}

class _NewsSectionTitle extends StatelessWidget {
  const _NewsSectionTitle();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Icon(Icons.bolt_rounded, color: kGold, size: 21),
      SizedBox(width: 6),
      Text(
        'الأحدث من قلب الحدث',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
      ),
    ],
  );
}

class _FeaturedNews extends StatelessWidget {
  const _FeaturedNews({required this.item});
  final NewsItem item;

  Future<void> _open() async {
    final uri = Uri.tryParse(item.url);
    if (uri != null && uri.hasScheme) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: _open,
    borderRadius: BorderRadius.circular(22),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 238,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedRemoteImage(
              url: item.imageUrl,
              fit: BoxFit.cover,
              fallback: const _NewsPlaceholder(),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xdd06130d)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.22, 1],
                ),
              ),
            ),
            Positioned(
              left: 15,
              right: 15,
              bottom: 15,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _SourcePill(label: item.sourceName),
                      const SizedBox(width: 7),
                      if (item.publishedText != null)
                        Text(
                          item.publishedText!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.4,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(top: 14, left: 14, child: _ReadButton()),
          ],
        ),
      ),
    ),
  );
}

class _NewsListCard extends StatelessWidget {
  const _NewsListCard({required this.item});
  final NewsItem item;

  Future<void> _open() async {
    final uri = Uri.tryParse(item.url);
    if (uri != null && uri.hasScheme) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: _open,
    borderRadius: BorderRadius.circular(19),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: kLine),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 91,
              height: 91,
              child: CachedRemoteImage(
                url: item.imageUrl,
                fit: BoxFit.cover,
                fallback: const _NewsPlaceholder(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.sourceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: kGold,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.arrow_outward_rounded,
                      size: 14,
                      color: kMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  item.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (item.publishedText != null) ...[
                  const SizedBox(height: 7),
                  Text(
                    item.publishedText!,
                    style: const TextStyle(
                      color: kMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SourcePill extends StatelessWidget {
  const _SourcePill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(30)),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xff062117),
        fontSize: 9,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _ReadButton extends StatelessWidget {
  const _ReadButton();

  @override
  Widget build(BuildContext context) => Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(.26),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white24),
    ),
    child: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 15),
  );
}

class _NewsPlaceholder extends StatelessWidget {
  const _NewsPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xff1d6044), Color(0xff0b2118)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ),
    ),
    child: const Center(
      child: Icon(Icons.newspaper_rounded, color: Colors.white38, size: 36),
    ),
  );
}

class _NewsSourceNote extends StatelessWidget {
  const _NewsSourceNote();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 11),
    child: Row(
      children: [
        Icon(Icons.verified_outlined, size: 14, color: kPrimary),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            'الأخبار تُجمع من مصادر رياضية موثوقة وتفتح في مصدرها الأصلي',
            style: TextStyle(
              color: kMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _NewsLoading extends StatelessWidget {
  const _NewsLoading();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Container(
        height: 130,
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(26),
        ),
      ),
      const SizedBox(height: 18),
      Container(
        height: 238,
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      const SizedBox(height: 16),
      const Center(child: CircularProgressIndicator(color: kPrimary)),
    ],
  );
}

class _NewsError extends StatelessWidget {
  const _NewsError({required this.onRetry});
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, color: kGold, size: 42),
          const SizedBox(height: 12),
          const Text(
            'تعذر تحميل الأخبار',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'حاول مرة أخرى بعد لحظات',
            style: TextStyle(color: kMuted, fontSize: 11),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () { onRetry(); },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    ),
  );
}

class _NewsEmpty extends StatelessWidget {
  const _NewsEmpty();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 42),
    child: const Column(
      children: [
        Icon(Icons.search_off_rounded, color: kMuted, size: 42),
        SizedBox(height: 12),
        Text(
          'لا توجد نتائج بهذا البحث',
          style: TextStyle(color: kMuted, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}