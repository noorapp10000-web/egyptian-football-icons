// ignore_for_file: deprecated_member_use, curly_braces_in_flow_control_structures

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import '../models/football_models.dart';
import '../models/history_content.dart';
import '../services/api_client.dart';
import '../services/offline_cache.dart';
import '../widgets/brand_mark.dart';
import '../widgets/cached_remote_image.dart';
import 'news_screen.dart';
import 'standings_screen.dart';

const teamCrest = 'assets/images/team_crest.png';
const matchCardBackground = 'assets/images/match_card_background.png';
const supportersBackground = 'assets/images/supporters_background.jpg';
const teamSquadBackground = 'assets/images/team_squad_background.jpg';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  final api = ApiClient();
  static const pageTitles = [
    'ناديك في كل لحظة',
    'مركز المباريات',
    'جدول المنافسة',
    'الفريق الأول',
    'نبض الأخبار',
    'ذاكرة المصري',
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(api: api),
      MatchesScreen(api: api),
      TableScreen(api: api),
      SquadScreen(api: api),
      NewsScreen(api: api),
      const HistoryScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 14,
        title: Row(
          children: [
            const BrandMark(size: 28),
            const SizedBox(width: 9),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                   'Masrawy fan',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .6,
                  ),
                ),
                Text(
                  pageTitles[index],
                  style: const TextStyle(
                    fontSize: 10,
                    color: kMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('الإعدادات')),
                    body: SettingsScreen(api: api),
                  ),
                ),
              ),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kPrimary.withOpacity(.22)),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 18,
                  color: kPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: offlineState,
            builder: (_, offline, __) =>
                offline ? const OfflineBanner() : const SizedBox.shrink(),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: IndexedStack(
                key: ValueKey(index),
                index: index,
                children: pages,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        backgroundColor: kBackground.withOpacity(.97),
        indicatorColor: kPrimary.withOpacity(.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'المباريات',
          ),
          NavigationDestination(
            icon: Icon(Icons.format_list_numbered),
            selectedIcon: Icon(Icons.format_list_numbered),
            label: 'الترتيب',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'الفريق',
          ),
          NavigationDestination(
            icon: Icon(Icons.newspaper_outlined),
            selectedIcon: Icon(Icons.newspaper),
            label: 'الأخبار',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance),
            label: 'التاريخ',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ApiClient get api => widget.api;

  late Future<List<Match>> _matchesFuture;
  late Future<List<NewsItem>> _newsFuture;
  Timer? _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _loadData() {
    _matchesFuture = api.getMatches();
    _newsFuture = api.getNews();
  }

  Future<void> _refresh() async {
    setState(_loadData);
    await Future.wait([_matchesFuture, _newsFuture]);
  }

  Match? _nextMatch(List<Match> matches) {
    final candidates = matches
        .where((match) => match.isLive || match.status == 'upcoming')
        .toList();
    candidates.sort((a, b) {
      if (a.isLive && !b.isLive) return -1;
      if (!a.isLive && b.isLive) return 1;
      final aDate = DateTime.tryParse(a.kickoff ?? '');
      final bDate = DateTime.tryParse(b.kickoff ?? '');
      if (aDate == null || bDate == null) return 0;
      return aDate.compareTo(bDate);
    });
    return candidates.isEmpty ? null : candidates.first;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: kPrimary,
      backgroundColor: kCard,
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          const _HomeHeader(),
          FutureBuilder<List<Match>>(
            future: _matchesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingCard();
              }
              if (snapshot.hasError) {
                return const ErrorCard(message: 'تعذر تحميل المباراة القادمة');
              }
              final next = _nextMatch(snapshot.data ?? const <Match>[]);
              return next == null
                  ? const _NoUpcomingMatch()
                  : NextMatchShowcase(match: next, now: _now);
            },
          ),
          const SizedBox(height: 12),
          const _FanSignalStrip(),
          const SizedBox(height: 24),
          FutureBuilder<List<Match>>(
            future: _matchesFuture,
            builder: (context, snapshot) {
              final data = snapshot.data ?? [];
              final recent = data.where((m) => m.isPlayed).take(4).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HomeSectionHeading(
                    eyebrow: 'ملخص الجولة',
                    title: 'آخر النتائج',
                    icon: Icons.scoreboard_outlined,
                  ),
                  const SizedBox(height: 11),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const LoadingCard()
                  else if (recent.isEmpty)
                    const SectionCard(
                      child: Text('لا توجد نتائج متاحة حاليًا'),
                    )
                  else
                    ...recent.map(
                      (match) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: MatchListTile(match: match),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 15),
          FutureBuilder<List<NewsItem>>(
            future: _newsFuture,
            builder: (context, snapshot) {
              final news = (snapshot.data ?? <NewsItem>[]).take(2).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HomeSectionHeading(
                    eyebrow: 'من قلب المدرجات',
                    title: 'آخر الأخبار',
                    icon: Icons.auto_stories_outlined,
                  ),
                  const SizedBox(height: 11),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const LoadingCard()
                  else
                    ...news.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: NewsCard(item: item),
                    ),
                  ),
                ],
              );
            },
          ),
          const SourceNote(),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(27),
      child: Container(
        height: 158,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff1d6547), Color(0xff0d2d21), kBackground],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            stops: [0, .48, 1],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: -46,
              bottom: -75,
              child: Container(
                width: 205,
                height: 205,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(.07), width: 20),
                ),
              ),
            ),
            Positioned(
              right: -20,
              top: -45,
              child: Container(
                width: 145,
                height: 145,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kGold.withOpacity(.16), width: 1),
                ),
              ),
            ),
            PositionedDirectional(
              end: 16,
              bottom: -8,
              child: Opacity(
                opacity: .15,
                child: const BrandMark(size: 118),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 17, 18, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.graphic_eq_rounded, color: kGold, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'MASRAWY FAN',
                        style: TextStyle(
                          color: Colors.white.withOpacity(.78),
                          fontSize: 10,
                          letterSpacing: 2.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.1),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: Colors.white.withOpacity(.15)),
                        ),
                        child: const Text(
                          'بورسعيد',
                          style: TextStyle(
                            color: kInk,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Text(
                    'الماتش يبدأ هنا.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'عيش اللحظة قبل صافرة البداية',
                    style: TextStyle(
                      color: Colors.white.withOpacity(.68),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FanSignalStrip extends StatelessWidget {
  const _FanSignalStrip();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
    decoration: BoxDecoration(
      color: kPrimary.withOpacity(.08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kPrimary.withOpacity(.16)),
    ),
    child: Row(
      children: [
        Container(
          width: 27,
          height: 27,
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(.16),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.rss_feed_rounded, color: kPrimary, size: 14),
        ),
        const SizedBox(width: 9),
        const Expanded(
          child: Text(
            'كل تحديث يوصلك في وقته',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
        const Text(
          'جاهز للماتش؟',
          style: TextStyle(
            color: kGold,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _HomeSectionHeading extends StatelessWidget {
  const _HomeSectionHeading({
    required this.eyebrow,
    required this.title,
    required this.icon,
  });

  final String eyebrow;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(.13),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: kPrimary, size: 18),
      ),
      const SizedBox(width: 9),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: const TextStyle(
              color: kPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    ],
  );
}

class _NoUpcomingMatch extends StatelessWidget {
  const _NoUpcomingMatch();

  @override
  Widget build(BuildContext context) => SectionCard(
    gradient: true,
    padding: const EdgeInsets.all(18),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(.13),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.event_available_rounded, color: kPrimary),
        ),
        const SizedBox(width: 13),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'المباراة القادمة',
                style: TextStyle(color: kGold, fontSize: 11),
              ),
              SizedBox(height: 3),
              Text(
                'لسه مفيش مباراة معلنة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 3),
              Text(
                'هنبلغك أول ما الموعد يتحدد',
                style: TextStyle(color: kMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class NextMatchShowcase extends StatelessWidget {
  const NextMatchShowcase({super.key, required this.match, required this.now});

  final Match match;
  final DateTime now;

  DateTime? get kickoff => DateTime.tryParse(match.kickoff ?? '')?.toLocal();

  @override
  Widget build(BuildContext context) {
    final remaining = kickoff?.difference(now);
    final isLive = match.isLive || (remaining != null && remaining.isNegative);
    final safeRemaining = remaining == null || remaining.isNegative
        ? Duration.zero
        : remaining;

    return SectionCard(
      padding: EdgeInsets.zero,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/matchday_stands.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kBackground.withOpacity(.72),
                    kBackground.withOpacity(.56),
                    kBackground.withOpacity(.92),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [.02, .46, 1],
                ),
              ),
            ),
          ),
          Positioned(
            right: -54,
            top: 43,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kPrimary.withOpacity(.12), width: 18),
              ),
            ),
          ),
          Positioned(
            left: -58,
            bottom: 72,
            child: Container(
              width: 115,
              height: 115,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kGold.withOpacity(.1), width: 1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 16, 15, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: kGold, size: 18),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'المباراة القادمة',
                  style: TextStyle(
                    color: kGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: isLive
                      ? kLive.withOpacity(.14)
                      : kPrimary.withOpacity(.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  isLive ? 'مباشر الآن' : 'استعد',
                  style: TextStyle(
                    color: isLive ? kLive : kPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            match.competition,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: kMuted, fontSize: 11),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: TeamColumn(team: match.homeTeam)),
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: kBackground.withOpacity(.56),
                  shape: BoxShape.circle,
                  border: Border.all(color: kPrimary.withOpacity(.25)),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'VS',
                  style: TextStyle(
                    color: kPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(child: TeamColumn(team: match.awayTeam)),
            ],
          ),
          const SizedBox(height: 15),
          if (isLive)
            const _LiveMatchMessage()
          else
            _CountdownRow(duration: safeRemaining),
          if (match.formattedKickoff != null || match.venue != null) ...[
            const SizedBox(height: 13),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: kBackground.withOpacity(.36),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (match.formattedKickoff != null) ...[
                    const Icon(
                      Icons.schedule_rounded,
                      color: kMuted,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      match.formattedKickoff!,
                      style: const TextStyle(color: kMuted, fontSize: 10),
                    ),
                  ],
                  if (match.formattedKickoff != null && match.venue != null)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('•', style: TextStyle(color: kLine)),
                    ),
                  if (match.venue != null) ...[
                    const Icon(Icons.place_outlined, color: kMuted, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        match.venue!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: kMuted, fontSize: 10),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownRow extends StatelessWidget {
  const _CountdownRow({required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final values = [
      ('ثانية', duration.inSeconds.remainder(60)),
      ('دقيقة', duration.inMinutes.remainder(60)),
      ('ساعة', duration.inHours.remainder(24)),
      ('يوم', duration.inDays),
    ];
    return Row(
      textDirection: TextDirection.rtl,
      children: values
          .map(
            (item) => Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kBackground.withOpacity(.72),
                        kCardAlt.withOpacity(.48),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPrimary.withOpacity(.22)),
                    boxShadow: [
                      BoxShadow(
                        color: kBackground.withOpacity(.24),
                        blurRadius: 12,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        item.$2.toString().padLeft(2, '0'),
                        style: const TextStyle(
                          color: kInk,
                          fontSize: 20,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.$1,
                        style: const TextStyle(color: kMuted, fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _LiveMatchMessage extends StatelessWidget {
  const _LiveMatchMessage();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: kLive.withOpacity(.1),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: kLive.withOpacity(.24)),
    ),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.radio_button_checked_rounded, color: kLive, size: 16),
        SizedBox(width: 7),
        Text(
          'المباراة جارية الآن — تابع كل لحظة',
          style: TextStyle(color: kLive, fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  int filter = 0;

  @override
  Widget build(BuildContext context) => DataPage<List<Match>>(
        title: 'كل المباريات',
        icon: Icons.calendar_month,
        load: widget.api.getMatches,
        builder: (matches) {
          final upcoming = matches.where((m) => !m.isPlayed).toList();
          final played = matches.where((m) => m.isPlayed).toList();
          final live = matches.where((m) => m.isLive).toList();
          final shown = switch (filter) {
            1 => played,
            2 => matches,
            _ => upcoming,
          };
          final featured = live.isNotEmpty
              ? live.first
              : upcoming.isNotEmpty
                  ? upcoming.first
                  : null;

          return RefreshIndicator(
            color: kPrimary,
            backgroundColor: kCard,
            onRefresh: () async => setState(() {}),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
              children: [
                _MatchesHero(
                  match: featured,
                  upcomingCount: upcoming.length,
                  playedCount: played.length,
                  liveCount: live.length,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _MatchFilterPill(
                      label: 'القادمة',
                      count: upcoming.length,
                      selected: filter == 0,
                      onTap: () => setState(() => filter = 0),
                    ),
                    const SizedBox(width: 8),
                    _MatchFilterPill(
                      label: 'النتائج',
                      count: played.length,
                      selected: filter == 1,
                      onTap: () => setState(() => filter = 1),
                    ),
                    const SizedBox(width: 8),
                    _MatchFilterPill(
                      label: 'الكل',
                      count: matches.length,
                      selected: filter == 2,
                      onTap: () => setState(() => filter = 2),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: kPrimary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      switch (filter) {
                        1 => 'أرشيف النتائج',
                        2 => 'كل المواجهات',
                        _ => 'أقرب المواجهات',
                      },
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${shown.length} مباراة',
                      style: const TextStyle(color: kMuted, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                if (shown.isEmpty)
                  const SectionCard(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Center(child: Text('لا توجد مباريات في هذا القسم')),
                    ),
                  ),
                ...shown.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: MatchListTile(match: m),
                  ),
                ),
                const SourceNote(),
              ],
            ),
          );
        },
      );
}

class _MatchesHero extends StatelessWidget {
  const _MatchesHero({
    required this.match,
    required this.upcomingCount,
    required this.playedCount,
    required this.liveCount,
  });

  final Match? match;
  final int upcomingCount;
  final int playedCount;
  final int liveCount;

  @override
  Widget build(BuildContext context) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xff1a6245), Color(0xff0b2c20)],
          ),
          border: Border.all(color: kPrimary.withOpacity(.34)),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(.12),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: -34,
              bottom: -48,
              child: Icon(
                Icons.sports_soccer_rounded,
                size: 190,
                color: Colors.white.withOpacity(.035),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 19, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 14,
                              color: kGold,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'مركز المباريات',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (liveCount > 0)
                        _LiveDotLabel(count: liveCount),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    match == null
                        ? 'تابع موسم المصري'
                        : match!.isLive
                            ? 'المصري يلعب الآن'
                            : 'المواجهة القادمة',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    match == null
                        ? 'كل المواعيد والنتائج في مكان واحد'
                        : match!.competition,
                    style: TextStyle(
                      color: Colors.white.withOpacity(.66),
                      fontSize: 12,
                    ),
                  ),
                  if (match != null) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _HeroTeam(
                            team: match!.homeTeam,
                            alignment: CrossAxisAlignment.start,
                          ),
                        ),
                        Column(
                          children: [
                            StatusBadge(match: match!),
                            const SizedBox(height: 6),
                            Text(
                              match!.isPlayed
                                  ? '${match!.homeScore} - ${match!.awayScore}'
                                  : 'VS',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: _HeroTeam(
                            team: match!.awayTeam,
                            alignment: CrossAxisAlignment.end,
                          ),
                        ),
                      ],
                    ),
                    if (match!.formattedKickoff != null) ...[
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 15,
                            color: kGold,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            match!.formattedKickoff!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _HeroMetric(label: 'قادمة', value: '$upcomingCount'),
                      const SizedBox(width: 18),
                      _HeroMetric(label: 'نتائج', value: '$playedCount'),
                      const Spacer(),
                      const Icon(
                        Icons.swipe_left_rounded,
                        size: 15,
                        color: Colors.white38,
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'اضغط للتفاصيل',
                        style: TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: kGold,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      );
}

class _LiveDotLabel extends StatelessWidget {
  const _LiveDotLabel({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(color: kLive, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            '$count مباشر',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      );
}

class _HeroTeam extends StatelessWidget {
  const _HeroTeam({required this.team, required this.alignment});
  final Team team;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: alignment,
        children: [
          TeamLogo(url: team.crestUrl, size: 46),
          const SizedBox(height: 7),
          Text(
            team.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
}

class _MatchFilterPill extends StatelessWidget {
  const _MatchFilterPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: selected ? kPrimary : kCard,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: selected ? kPrimary : kLine,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? const Color(0xff062116) : kInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? const Color(0xff062116) : kMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}


class SquadScreen extends StatelessWidget {
  const SquadScreen({super.key, required this.api});
  final ApiClient api;

  String group(String p) {
    final normalized = p.trim().toLowerCase();
    if (normalized.contains('حارس') || normalized.contains('goalkeeper')) {
      return 'حراس المرمى';
    }
    if (normalized.contains('دفاع') ||
        normalized.contains('مدافع') ||
        normalized.contains('ظهير') ||
        normalized.contains('قلب') ||
        normalized.contains('defen') ||
        normalized.contains('back')) {
      return 'الدفاع';
    }
    if (normalized.contains('وسط') || normalized.contains('midfield')) {
      return 'الوسط';
    }
    if (normalized.contains('هجوم') ||
        normalized.contains('مهاجم') ||
        normalized.contains('جناح') ||
        normalized.contains('attack') ||
        normalized.contains('forward')) {
      return 'الهجوم';
    }
    return 'لاعبون آخرون';
  }

  @override
  Widget build(BuildContext context) => DataPage<List<Player>>(
    title: 'الفريق الأول',
    icon: Icons.groups,
    load: api.getSquad,
    builder: (players) {
      final scorers = [...players]
        ..sort((a, b) => (b.goals ?? 0).compareTo(a.goals ?? 0));
      final totalGoals = players.fold<int>(
        0,
        (total, player) => total + (player.goals ?? 0),
      );
      final groups = <String, List<Player>>{};
      for (final p in players)
        groups.putIfAbsent(group(p.position), () => []).add(p);
      return ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 32),
        children: [
          _SquadHero(
            playerCount: players.length,
            totalGoals: totalGoals,
            topScorer: scorers.isEmpty ? null : scorers.first,
          ),
          if (scorers.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SquadSpotlight(player: scorers.first),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(
                child: SectionTitle(
                  icon: Icons.groups_2_outlined,
                  title: 'قائمة الفريق',
                ),
              ),
              Text(
                '${players.length} لاعب',
                style: const TextStyle(color: kMuted, fontSize: 11),
              ),
            ],
          ),
          for (final title in [
            'حراس المرمى',
            'الدفاع',
            'الوسط',
            'الهجوم',
            'لاعبون آخرون',
          ])
            if (groups[title]?.isNotEmpty ?? false) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 22,
                    decoration: BoxDecoration(
                      color: title == 'حراس المرمى' ? kGold : kPrimary,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${groups[title]!.length}',
                    style: const TextStyle(color: kMuted, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                   crossAxisSpacing: 11,
                   mainAxisSpacing: 11,
                   childAspectRatio: .74,
                ),
                itemCount: groups[title]!.length,
                itemBuilder: (_, i) => PlayerCard(player: groups[title]![i]),
              ),
            ],
          const SourceNote(),
        ],
      );
    },
  );
}

class _SquadHero extends StatelessWidget {
  const _SquadHero({
    required this.playerCount,
    required this.totalGoals,
    required this.topScorer,
  });
  final int playerCount;
  final int totalGoals;
  final Player? topScorer;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      image: const DecorationImage(
        image: AssetImage(teamSquadBackground),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(
          Color(0xaa071912),
          BlendMode.darken,
        ),
      ),
      gradient: const LinearGradient(
        colors: [
          Color(0xd91b6947),
          Color(0xe60b281d),
          Color(0xf5071912),
        ],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        stops: [0, .56, 1],
      ),
      border: Border.all(color: kPrimary.withOpacity(.3)),
      boxShadow: [
        BoxShadow(
          color: kPrimary.withOpacity(.1),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          left: -18,
          bottom: -32,
          child: Icon(
            Icons.shield_rounded,
            size: 154,
            color: Colors.white.withOpacity(.045),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.13),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(.2)),
                  ),
                  child: const BrandMark(size: 54),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MASRAWY FAN',
                        style: TextStyle(
                          color: kGold,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.6,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'الفريق الأول',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'كل لاعب له بصمته',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'تابع نجوم المصري من أول صافرة لآخر لحظة',
              style: TextStyle(
                color: Colors.white.withOpacity(.68),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 17),
            Row(
              children: [
                _SquadMetric(value: '$playerCount', label: 'لاعب'),
                const SizedBox(width: 8),
                _SquadMetric(value: '$totalGoals', label: 'هدف'),
                const SizedBox(width: 8),
                _SquadMetric(
                  value: topScorer?.name ?? '—',
                  label: 'الهداف',
                  compact: true,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

class _SquadMetric extends StatelessWidget {
  const _SquadMetric({
    required this.value,
    required this.label,
    this.compact = false,
  });
  final String value;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.17),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.11)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: kGold,
              fontSize: compact ? 11 : 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SquadSpotlight extends StatelessWidget {
  const _SquadSpotlight({required this.player});
  final Player player;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => openPlayer(context, player.id),
    borderRadius: BorderRadius.circular(23),
    child: Container(
      height: 110,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        gradient: const LinearGradient(
          colors: [Color(0xff173e2d), Color(0xff0d251b)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        border: Border.all(color: kGold.withOpacity(.26)),
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: -10,
            top: -28,
            child: Icon(
              Icons.emoji_events_rounded,
              size: 130,
              color: kGold.withOpacity(.06),
            ),
          ),
          PositionedDirectional(
            end: 16,
            bottom: 0,
            child: CachedRemoteImage(
              url: player.photoUrl,
              width: 96,
              height: 104,
              fit: BoxFit.cover,
              fallback: const Center(
                child: Icon(Icons.person, size: 55, color: Colors.white24),
              ),
              fallbackIcon: Icons.person,
            ),
          ),
          PositionedDirectional(
            start: 16,
            top: 15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'هداف الفريق',
                  style: TextStyle(
                    color: kGold,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  player.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${player.goals ?? 0} أهداف · ${player.position}',
                  style: const TextStyle(color: kMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const PositionedDirectional(
            start: 16,
            bottom: 14,
            child: Icon(Icons.arrow_back_rounded, color: Colors.white54, size: 18),
          ),
        ],
      ),
    ),
  );
}

void openPlayer(BuildContext context, int id) => Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => PlayerDetailScreen(api: ApiClient(), playerId: id),
  ),
);


class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int selected = 0;

  static const tabs = [
    ('الحكاية', Icons.history),
    ('البطولات', Icons.emoji_events_outlined),
    ('مسار الرابطة', Icons.route),
    ('المدربون', Icons.manage_accounts_outlined),
    ('الرؤساء', Icons.workspace_premium_outlined),
    ('الهدافون', Icons.gps_fixed),
    ('الأساطير', Icons.star_outline),
    ('الأكثر مشاركة', Icons.groups_outlined),
    ('الهوية', Icons.verified_outlined),
  ];

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
    children: [
      const SectionCard(
        gradient: true,
        child: Row(
          children: [
            BrandMark(size: 62),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'تاريخ النادي المصري\nقرن كامل من الكرة والهوية',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          StatChip(value: '1920', label: 'سنة التأسيس'),
          StatChip(value: '17', label: 'لقب دوري القناة'),
          StatChip(value: '1', label: 'كأس مصر'),
          StatChip(value: '1', label: 'كأس الرابطة'),
        ],
      ),
      const SizedBox(height: 18),
      Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          for (var i = 0; i < tabs.length; i++)
            ChoiceChip(
              avatar: Icon(tabs[i].$2, size: 15),
              label: Text(tabs[i].$1),
              selected: selected == i,
              onSelected: (_) => setState(() => selected = i),
              selectedColor: kPrimary,
              labelStyle: TextStyle(
                color: selected == i ? const Color(0xff092017) : Colors.white70,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
        ],
      ),
      const SizedBox(height: 20),
      _content(),
    ],
  );

  Widget _content() => switch (selected) {
    0 => const _TimelineSection(),
    1 => const _HonoursSection(),
    2 => const _CupPathSection(),
    3 => const _CoachesSection(),
    4 => const _PresidentsSection(),
    5 => const _RecordsSection(
      title: 'أفضل الهدافين في التاريخ',
      records: historyTopScorers,
      statLabel: 'هدف',
    ),
    6 => const _LegendsSection(),
    7 => const _RecordsSection(
      title: 'الأكثر مشاركة في تاريخ النادي',
      records: historyAppearances,
      statLabel: 'مباراة',
    ),
    _ => const _IdentitySection(),
  };
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionTitle(icon: Icons.timeline, title: 'الخط الزمني'),
      const SizedBox(height: 10),
      for (final item in historyTimeline) ...[
        SectionCard(
          gradient: item.gold,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    item.year,
                    style: const TextStyle(
                      color: kGold,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              if (item.image != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    historyAsset(item.image!),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                item.body,
                style: const TextStyle(color: Colors.white70, height: 1.65),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    ],
  );
}

class _HonoursSection extends StatelessWidget {
  const _HonoursSection();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionTitle(
        icon: Icons.emoji_events_outlined,
        title: 'خزانة البطولات',
      ),
      const SizedBox(height: 10),
      for (final honour in historyHonours) ...[
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      honour.title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Text(
                    '${honour.wins.length}× بطل',
                    style: const TextStyle(
                      color: kGold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final win in honour.wins) _HistoryPill(text: win),
                ],
              ),
              if (honour.runnersUp.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  'الوصافة',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final year in honour.runnersUp)
                      _HistoryPill(text: year, muted: true),
                  ],
                ),
              ],
              if (honour.note != null) ...[
                const SizedBox(height: 10),
                Text(
                  honour.note!,
                  style: const TextStyle(
                    color: kPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    ],
  );
}

class _CupPathSection extends StatelessWidget {
  const _CupPathSection();
  static const stages = <(String, String, String, List<String>)>[
    (
      'دور المجموعات',
      'بداية ثابتة حسمت بطاقة العبور',
      '3 فوز · تعادلان · خسارة',
      [
        '11 ديسمبر 2025 · الاتحاد السكندري 0–0 المصري',
        '19 ديسمبر 2025 · المصري 1–0 زد',
        '25 ديسمبر 2025 · حرس الحدود 0–1 المصري',
        '5 يناير 2026 · المصري 2–0 سموحة',
        '10 يناير 2026 · كهرباء الإسماعيلية 1–1 المصري',
        '15 يناير 2026 · المصري 0–2 الزمالك',
      ],
    ),
    (
      'ربع النهائي',
      'تفوق واضح على الجونة ذهابًا وإيابًا',
      '4–2 في مجموع المباراتين',
      [
        '26 مارس 2026 · الجونة 0–2 المصري · ذهاب',
        '30 مارس 2026 · المصري 2–2 الجونة · إياب',
      ],
    ),
    (
      'نصف النهائي',
      'عودة مثيرة وحسم من نقطة الجزاء',
      '6–5 بركلات الترجيح',
      [
        '25 مايو 2026 · زد 1–0 المصري · ذهاب',
        '1 يونيو 2026 · المصري 1–0 زد · إياب · 6–5 ترجيح',
      ],
    ),
    (
      'النهائي',
      'ليلة التتويج وعودة البطولات بعد 28 عامًا',
      'المصري بطل كأس عاصمة مصر',
      ['8 يونيو 2026 · إنبي 0–3 المصري · النهائي'],
    ),
  ];
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionTitle(icon: Icons.route, title: 'مسار كأس عاصمة مصر 2026'),
      const SizedBox(height: 10),
      for (final stage in stages) ...[
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stage.$1,
                style: const TextStyle(
                  color: kGold,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(stage.$2, style: const TextStyle(color: Colors.white70)),
              Text(
                stage.$3,
                style: const TextStyle(
                  color: kPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Divider(),
              ...stage.$4.map(
                (m) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(m, style: const TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
      SectionCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 190,
            child: PageView(
              children: [
                for (final image in historyGallery)
                  Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(historyAsset(image), fit: BoxFit.cover),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: Colors.black54,
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            image.replaceAll('.webp', ''),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

class _CoachesSection extends StatelessWidget {
  const _CoachesSection();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionTitle(
        icon: Icons.manage_accounts_outlined,
        title: 'تسلسل المدربين',
      ),
      const SizedBox(height: 5),
      const Text(
        'فترات تدريبية موثقة من بوشكاش 1979 حتى اليوم، مع الصور المحلية المتاحة.',
        style: TextStyle(color: Colors.white60, fontSize: 11),
      ),
      const SizedBox(height: 10),
      for (final coach in historyCoaches) ...[
        _HistoryPersonTile(
          title: coach.name,
          subtitle: '${coach.from} — ${coach.to}',
          note: '${coach.matches} مباراة · ${coach.points} نقطة/مباراة',
          image: coach.image,
        ),
        const SizedBox(height: 8),
      ],
    ],
  );
}

class _PresidentsSection extends StatelessWidget {
  const _PresidentsSection();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionTitle(
        icon: Icons.workspace_premium_outlined,
        title: 'تسلسل رؤساء النادي',
      ),
      const SizedBox(height: 5),
      const Text(
        'من أحمد حسني 1920 إلى كامل أبو علي — فترات رئاسة موثقة.',
        style: TextStyle(color: Colors.white60, fontSize: 11),
      ),
      const SizedBox(height: 10),
      for (final president in historyPresidents) ...[
        _HistoryPersonTile(
          title: president.name,
          subtitle: '${president.from} — ${president.to}',
          note: president.note,
          image: president.image,
        ),
        const SizedBox(height: 8),
      ],
    ],
  );
}

class _RecordsSection extends StatelessWidget {
  const _RecordsSection({
    required this.title,
    required this.records,
    required this.statLabel,
  });

  final String title;
  final List<HistoryRecord> records;
  final String statLabel;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionTitle(icon: Icons.gps_fixed, title: title),
      const SizedBox(height: 5),
      const Text(
        'ترتيب محفوظ داخل التطبيق ويظل متاحًا بدون إنترنت.',
        style: TextStyle(color: Colors.white60, fontSize: 11),
      ),
      const SizedBox(height: 10),
      for (final record in records) ...[
        SectionCard(
          child: Row(
            children: [
              SizedBox(
                width: 26,
                child: Text(
                  '${record.rank}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _HistoryPortrait(
                image: record.image,
                size: 48,
                fallback: record.name,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '${record.goals} هدف${record.assists > 0 ? ' · ${record.assists} تمريرة حاسمة' : ''}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    '${statLabel == 'هدف' ? record.goals : record.apps}',
                    style: const TextStyle(
                      color: kPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    statLabel,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    ],
  );
}

class _LegendsSection extends StatelessWidget {
  const _LegendsSection();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionTitle(
        icon: Icons.star_outline,
        title: 'أساطير النسور الخضراء',
      ),
      const SizedBox(height: 10),
      for (final legend in historyLegends) ...[
        _HistoryPersonTile(
          title: legend.name,
          subtitle: '${legend.role} · ${legend.era}',
          note: legend.note,
          image: legend.image,
        ),
        const SizedBox(height: 8),
      ],
    ],
  );
}

class _IdentitySection extends StatelessWidget {
  const _IdentitySection();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionTitle(
        icon: Icons.verified_outlined,
        title: 'الهوية والمنشآت',
      ),
      const SizedBox(height: 10),
      for (final item in historyIdentity) ...[
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  color: kPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.body,
                style: const TextStyle(color: Colors.white70, height: 1.6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
      SectionCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Image.asset(
                historyAsset('مدينة بورسعيد.webp'),
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'بورسعيد — مدينة النادي وجمهوره',
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(icon: Icons.open_in_new, title: 'المصادر'),
            const SizedBox(height: 8),
            for (final source in historySources)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  source['label']!,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(
                  Icons.open_in_new,
                  size: 15,
                  color: kPrimary,
                ),
                onTap: () => launchUrl(
                  Uri.parse(source['url']!),
                  mode: LaunchMode.externalApplication,
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

class _HistoryPersonTile extends StatelessWidget {
  const _HistoryPersonTile({
    required this.title,
    required this.subtitle,
    this.note,
    this.image,
  });

  final String title;
  final String subtitle;
  final String? note;
  final String? image;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HistoryPortrait(image: image, size: 54, fallback: title),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              if (note != null) ...[
                const SizedBox(height: 5),
                Text(
                  note!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _HistoryPortrait extends StatelessWidget {
  const _HistoryPortrait({
    this.image,
    required this.size,
    required this.fallback,
  });

  final String? image;
  final double size;
  final String fallback;

  @override
  Widget build(BuildContext context) => ClipOval(
    child: SizedBox(
      width: size,
      height: size,
      child: image == null
          ? Container(
              color: kPrimary.withOpacity(.14),
              child: Center(
                child: Text(
                  fallback.length > 2 ? fallback.substring(0, 2) : fallback,
                  style: const TextStyle(
                    color: kPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            )
          : Image.asset(
              historyAsset(image!),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: kPrimary.withOpacity(.14),
                child: const Icon(Icons.person, color: kPrimary),
              ),
            ),
    ),
  );
}

class _HistoryPill extends StatelessWidget {
  const _HistoryPill({required this.text, this.muted = false});

  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: muted ? kCardAlt : kGold.withOpacity(.14),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: muted ? Colors.white60 : kGold,
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final name = TextEditingController();
  Preferences prefs = const Preferences(
    notifications: {
      'matchday': true,
      'lineup': true,
      'kickoff': true,
      'goal': true,
      'penalty': true,
      'card': true,
      'substitution': true,
      'injury': true,
      'fulltime': true,
      'news': true,
      'standings': true,
    },
  );
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final local = await SharedPreferences.getInstance();
    try {
      final remote = await widget.api.getPreferences();
      prefs = remote;
      name.text = remote.username;
    } catch (_) {
      name.text = local.getString('username') ?? '';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _save() async {
    final value = name.text.trim();
    final local = await SharedPreferences.getInstance();
    await local.setString('username', value);
    await widget.api.savePreferences(
      username: value,
      notificationsEnabled: prefs.notificationsEnabled,
      notifications: prefs.notifications,
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حفظ الإعدادات')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingCard();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(icon: Icons.person_outline, title: 'الحساب'),
              const SizedBox(height: 12),
              const Text('هذا الجهاز — لا يلزم إنشاء حساب'),
              const SizedBox(height: 12),
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'اسمك داخل التطبيق',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check),
                      label: const Text('حفظ'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () async {
            await OfflineCache.instance.clear();
            if (context.mounted)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم مسح البيانات المحفوظة')),
              );
          },
          icon: const Icon(Icons.delete_outline),
          label: const Text('مسح البيانات المحفوظة'),
        ),
        const SizedBox(height: 14),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                icon: Icons.notifications_active_outlined,
                title: 'الإشعارات',
              ),
              const SizedBox(height: 4),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'تفعيل كل الإشعارات',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                value: prefs.notificationsEnabled,
                onChanged: (value) => setState(
                  () => prefs = Preferences(
                    username: prefs.username,
                    notificationsEnabled: value,
                    notifications: prefs.notifications,
                  ),
                ),
              ),
              const Divider(),
              ...notificationTypes.map(
                (type) => SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(type['label']!),
                  subtitle: Text(
                    type['hint']!,
                    style: const TextStyle(fontSize: 11),
                  ),
                  value: prefs.notifications[type['key']] ?? true,
                  onChanged: prefs.notificationsEnabled
                      ? (value) => setState(() {
                          final map = {
                            ...prefs.notifications,
                            type['key']!: value,
                          };
                          prefs = Preferences(
                            username: prefs.username,
                            notificationsEnabled: prefs.notificationsEnabled,
                            notifications: map,
                          );
                        })
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('حفظ تفضيلات الإشعارات'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MatchDetailScreen extends StatefulWidget {
  const MatchDetailScreen({
    super.key,
    required this.api,
    required this.matchId,
  });
  final ApiClient api;
  final int matchId;

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  late Future<Map<String, dynamic>> _future;
  Timer? _refreshTimer;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getMatchDetail(widget.matchId);
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() => _future = widget.api.getMatchDetail(widget.matchId));
      }
    });
  }

  void _retry() =>
      setState(() => _future = widget.api.getMatchDetail(widget.matchId));

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kBackground,
        appBar: AppBar(
          title: const Text('غرفة المباراة'),
          leading: IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
          ),
          actions: [
            IconButton(
              onPressed: _retry,
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const LoadingCard();
            if (snapshot.hasError || snapshot.data == null) {
              return ErrorState(title: 'تفاصيل المباراة', onRetry: _retry);
            }
            final detail = MatchDetailData.fromJson(snapshot.data!);
            final match = detail.match;
            final timeline =
                detail.timeline.isNotEmpty ? detail.timeline : detail.events;
            final liveEvent = timeline
                .where((event) => event.minute != null)
                .fold<int?>(null, (latest, event) {
              final minute = event.minute;
              if (minute == null) return latest;
              if (latest == null || minute > latest) return minute;
              return latest;
            });
            final hasLineups =
                detail.homeLineup.isNotEmpty || detail.awayLineup.isNotEmpty;
            return ListView(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 30),
              children: [
                _MatchScoreHero(match: match, liveMinute: liveEvent),
                if (detail.stadium != null ||
                    detail.referee != null ||
                    match.venue != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (detail.stadium != null || match.venue != null)
                        Expanded(
                          child: _DetailInfoPill(
                            icon: Icons.stadium_outlined,
                            text: detail.stadium ?? match.venue!,
                          ),
                        ),
                      if (detail.referee != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: _DetailInfoPill(
                            icon: Icons.sports_outlined,
                            text: detail.referee!,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                _MatchDetailTabs(
                  selectedIndex: _selectedTab,
                  onChanged: (value) => setState(() => _selectedTab = value),
                ),
                const SizedBox(height: 8),
                switch (_selectedTab) {
                  0 => _EventsTab(
                      events: timeline,
                      homeTeam: match.homeTeam,
                      awayTeam: match.awayTeam,
                    ),
                  1 => _StatsTab(stats: detail.stats),
                  2 => _LineupsTab(
                      detail: detail,
                      homeTeam: match.homeTeam,
                      awayTeam: match.awayTeam,
                      visible: hasLineups,
                    ),
                  _ => _CommentaryTab(commentary: detail.commentary),
                },
              ],
            );
          },
        ),
      );
}

class _MatchScoreHero extends StatelessWidget {
  const _MatchScoreHero({required this.match, this.liveMinute});
  final Match match;
  final int? liveMinute;

  @override
  Widget build(BuildContext context) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xff195d41), Color(0xff09251b)],
          ),
          border: Border.all(color: kPrimary.withOpacity(.36)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                matchCardBackground,
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xff062c1d).withOpacity(.48),
                      const Color(0xff03180f).withOpacity(.86),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -28,
              top: -34,
              child: Container(
                width: 136,
                height: 136,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(.06), width: 18),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 17, 16, 15),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        color: kGold,
                        size: 16,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          match.competition,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: kGold,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      StatusBadge(match: match),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _ScoreTeam(team: match.homeTeam, angle: -.05),
                      ),
                      Column(
                        children: [
                          Text(
                            match.isPlayed || match.isLive
                                ? '${match.homeScore ?? 0} - ${match.awayScore ?? 0}'
                                : 'VS',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 31,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          if (match.isLive && liveMinute != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: kLive.withOpacity(.17),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$liveMinute’',
                                style: const TextStyle(
                                  color: kLive,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Expanded(
                        child: _ScoreTeam(team: match.awayTeam, angle: .05),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (match.formattedKickoff != null)
                    Text(
                      match.formattedKickoff!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (match.isLive)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PulsingLiveDot(),
                          SizedBox(width: 6),
                          Text(
                            'تغطية مباشرة لحظة بلحظة',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ScoreTeam extends StatelessWidget {
  const _ScoreTeam({required this.team, this.angle = 0});
  final Team team;
  final double angle;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Transform.rotate(
            angle: angle,
            child: TeamLogo(url: team.crestUrl, size: 78, tinted: true),
          ),
          const SizedBox(height: 8),
          Text(
            team.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      );
}

class _PulsingLiveDot extends StatelessWidget {
  const _PulsingLiveDot();

  @override
  Widget build(BuildContext context) => Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(color: kLive, shape: BoxShape.circle),
      );
}

class _DetailInfoPill extends StatelessWidget {
  const _DetailInfoPill({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kLine),
        ),
        child: Row(
          children: [
            Icon(icon, color: kPrimary, size: 16),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
}

class _MatchDetailTabs extends StatelessWidget {
  const _MatchDetailTabs({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const labels = ['الأحداث', 'الإحصائيات', 'التشكيل', 'التعليق'];
  static const icons = [
    Icons.timeline_rounded,
    Icons.bar_chart_rounded,
    Icons.groups_rounded,
    Icons.short_text_rounded,
  ];

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: kLine),
        ),
        child: Row(
          children: [
            for (var index = 0; index < labels.length; index++)
              Expanded(
                child: InkWell(
                  onTap: () => onChanged(index),
                  borderRadius: BorderRadius.circular(13),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selectedIndex == index ? kPrimary : Colors.transparent,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icons[index],
                          size: 15,
                          color: selectedIndex == index
                              ? const Color(0xff062116)
                              : kMuted,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          labels[index],
                          style: TextStyle(
                            color: selectedIndex == index
                                ? const Color(0xff062116)
                                : kMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );

}

class _EventsTab extends StatelessWidget {
  const _EventsTab({
    required this.events,
    required this.homeTeam,
    required this.awayTeam,
  });

  final List<MatchEventModel> events;
  final Team homeTeam;
  final Team awayTeam;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const _DetailTabPlaceholder(
        message: 'لا توجد أحداث مسجلة لهذه المباراة.',
      );
    }
    final ordered = [...events]
      ..sort((a, b) => (a.minute ?? 999).compareTo(b.minute ?? 999));
    return Column(
      children: [
        SectionCard(
          padding: const EdgeInsets.fromLTRB(12, 13, 12, 8),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _TimelineTeamHeader(
                        team: awayTeam,
                        alignment: CrossAxisAlignment.start,
                      ),
                    ),
                    const SizedBox(width: 42),
                    Expanded(
                      child: _TimelineTeamHeader(
                        team: homeTeam,
                        alignment: CrossAxisAlignment.end,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final event in ordered)
                  _TimelineEventRow(
                    event: event,
                    home: _belongsTo(event, homeTeam),
                    away: _belongsTo(event, awayTeam),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

bool _belongsTo(MatchEventModel event, Team team) {
  if (event.teamId != null && team.id != null) return event.teamId == team.id;
  final eventName = event.teamName?.trim().toLowerCase();
  final teamName = team.name.trim().toLowerCase();
  return eventName != null && eventName.isNotEmpty && eventName == teamName;
}

class _TimelineTeamHeader extends StatelessWidget {
  const _TimelineTeamHeader({required this.team, required this.alignment});

  final Team team;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: alignment,
    children: [
      TeamLogo(url: team.crestUrl, size: 34),
      const SizedBox(height: 5),
      Text(
        team.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alignment == CrossAxisAlignment.end
            ? TextAlign.right
            : TextAlign.left,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
      ),
    ],
  );
}

class _TimelineEventRow extends StatelessWidget {
  const _TimelineEventRow({
    required this.event,
    required this.home,
    required this.away,
  });

  final MatchEventModel event;
  final bool home;
  final bool away;

  @override
  Widget build(BuildContext context) {
    final tile = _TimelineEventTile(event: event);
    return SizedBox(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: away
                  ? Align(alignment: Alignment.centerLeft, child: tile)
                  : const SizedBox.shrink(),
            ),
            SizedBox(
              width: 42,
              child: Column(
                children: [
                  Expanded(child: Container(width: 1, color: kLine)),
                  Container(
                    width: 34,
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: kCardAlt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kLine),
                    ),
                    child: Text(
                      event.minute == null
                          ? '—'
                          : '${event.minute}${event.addedTime == null ? '' : '+${event.addedTime}'}’',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: kGold,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Expanded(child: Container(width: 1, color: kLine)),
                ],
              ),
            ),
            Expanded(
              child: home
                  ? Align(alignment: Alignment.centerRight, child: tile)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineEventTile extends StatelessWidget {
  const _TimelineEventTile({required this.event});

  final MatchEventModel event;

  @override
  Widget build(BuildContext context) {
    final color = _eventColor(event.type);
    final details = [
      if (event.player != null) event.player!,
      if (event.relatedPlayer != null) event.relatedPlayer!,
    ].join(' · ');
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: kCardAlt,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withOpacity(.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: color.withOpacity(.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_eventIcon(event.type), size: 14, color: color),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _eventLabel(event.type),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (details.isNotEmpty || event.text != null)
                  Text(
                    details.isNotEmpty ? details : event.text!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kMuted,
                      fontSize: 9,
                      height: 1.3,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab({required this.stats});

  final List<MatchStatRow> stats;

  @override
  Widget build(BuildContext context) => stats.isEmpty
      ? const _DetailTabPlaceholder(
          message: 'الإحصائيات غير متاحة لهذه المباراة.',
        )
      : Column(
          children: [
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle(
                    icon: Icons.bar_chart,
                    title: 'إحصائيات المباراة',
                  ),
                  const SizedBox(height: 14),
                  for (final stat in stats) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${stat.home}${stat.unit == 'percent' ? '%' : ''}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          stat.label,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '${stat.away}${stat.unit == 'percent' ? '%' : ''}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _StatBar(home: stat.home, away: stat.away, unit: stat.unit),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
          ],
        );
}

class _LineupsTab extends StatelessWidget {
  const _LineupsTab({
    required this.detail,
    required this.homeTeam,
    required this.awayTeam,
    required this.visible,
  });

  final MatchDetailData detail;
  final Team homeTeam;
  final Team awayTeam;
  final bool visible;

  @override
  Widget build(BuildContext context) => !visible
      ? const _DetailTabPlaceholder(message: 'لم تُعلن التشكيلة بعد.')
      : Column(
          children: [
            _LineupBoard(
              team: homeTeam,
              formation: detail.homeFormation,
              coach: detail.homeCoach,
              players: detail.homeLineup,
              bench: detail.homeBench,
            ),
            const SizedBox(height: 12),
            _LineupBoard(
              team: awayTeam,
              formation: detail.awayFormation,
              coach: detail.awayCoach,
              players: detail.awayLineup,
              bench: detail.awayBench,
            ),
          ],
        );
}

class _CommentaryTab extends StatelessWidget {
  const _CommentaryTab({required this.commentary});

  final List<Map<String, dynamic>> commentary;

  @override
  Widget build(BuildContext context) => commentary.isEmpty
      ? const _DetailTabPlaceholder(
          message: 'لا يوجد تعليق متاح لهذه المباراة.',
        )
      : Column(
          children: [
            for (var index = 0; index < commentary.length; index++) ...[
              if (index > 0) const SizedBox(height: 7),
              Builder(
                builder: (_) {
                  final item = commentary[index];
                  return SectionCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: kCardAlt,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            item['minute'] == null ? '—' : '${item['minute']}’',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item['text']?.toString() ?? '—',
                            style: const TextStyle(height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        );
}

class _StatBar extends StatelessWidget {
  const _StatBar({required this.home, required this.away, required this.unit});

  final int home;
  final int away;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final total = home + away == 0 ? 1 : home + away;
    final ratio = unit == 'percent' ? home / 100 : home / total;
    final homeFlex = (ratio * 100).round().clamp(1, 99);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            Flexible(
              flex: homeFlex,
              child: Container(color: kPrimary),
            ),
            Expanded(child: Container(color: kGold.withOpacity(.6))),
          ],
        ),
      ),
    );
  }
}

class _LineupBoard extends StatelessWidget {
  const _LineupBoard({
    required this.team,
    required this.players,
    required this.bench,
    this.formation,
    this.coach,
  });

  final Team team;
  final List<LineupPlayer> players;
  final List<LineupPlayer> bench;
  final String? formation;
  final String? coach;

  @override
  Widget build(BuildContext context) {
    final keeper = players.isEmpty
        ? null
        : players.firstWhere(
            (player) =>
                player.position.contains('حارس') ||
                player.position.toLowerCase().contains('goal'),
            orElse: () => players.first,
          );
    final outfield = players
        .where((player) => player.id != keeper?.id)
        .toList();
    final rows = _formationRows(formation, outfield.length);
    var offset = 0;
    final lines = <List<LineupPlayer>>[
      if (keeper != null) [keeper],
    ];
    for (final count in rows) {
      if (offset >= outfield.length) break;
      lines.add(outfield.skip(offset).take(count).toList());
      offset += count;
    }
    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                TeamLogo(url: team.crestUrl, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    team.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                if (formation != null)
                  Text(
                    formation!,
                    style: const TextStyle(
                      color: kPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(10),
            height: 430,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xff237451), Color(0xff0b3928)],
              ),
              border: Border.all(color: kPrimary.withOpacity(.3)),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _PitchMarkingsPainter()),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (final line in lines)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          for (final player in line)
                            Expanded(
                              child: Center(child: _PitchPlayer(player: player)),
                            ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (coach != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'المدرب: $coach',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ),
            ),
          if (bench.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'البدلاء: ${bench.map((player) => player.name).join('، ')}',
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PitchMarkingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(13),
    );
    canvas.drawRRect(rect, paint);
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 34, paint);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 2.5, paint);
    final boxWidth = size.width * .34;
    final boxHeight = size.height * .17;
    canvas.drawRect(
      Rect.fromLTWH((size.width - boxWidth) / 2, 0, boxWidth, boxHeight),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - boxWidth) / 2,
        size.height - boxHeight,
        boxWidth,
        boxHeight,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PitchPlayer extends StatelessWidget {
  const _PitchPlayer({required this.player});

  final LineupPlayer player;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 64,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.9),
                    shape: BoxShape.circle,
                    border: Border.all(color: kPrimary, width: 2),
                  ),
                  child: CachedAvatar(url: player.photoUrl, size: 38),
                ),
                if (player.number != null)
                  Positioned(
                    bottom: -1,
                    right: -3,
                    child: Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: kGold,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${player.number}',
                        style: const TextStyle(
                          color: Color(0xff13281e),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                if (player.isCaptain)
                  Positioned(
                    top: -5,
                    left: -4,
                    child: Container(
                      width: 16,
                      height: 16,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: kPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        'C',
                        style: TextStyle(
                          color: Color(0xff082118),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              player.name.split(' ').take(2).join(' '),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );
}

List<int> _formationRows(String? formation, int count) {
  final parsed = (formation ?? '')
      .split(RegExp(r'[^0-9]+'))
      .where((value) => value.isNotEmpty)
      .map(int.parse)
      .where((value) => value > 0 && value < 7)
      .toList();
  if (parsed.length >= 2 && parsed.reduce((a, b) => a + b) == count)
    return parsed;
  if (count == 10) return const [4, 3, 3];
  final rows = <int>[];
  var remaining = count;
  while (remaining > 0) {
    final take = remaining > 4 ? 4 : remaining;
    rows.add(take);
    remaining -= take;
  }
  return rows;
}

String _eventLabel(String raw) {
  final type = raw.toLowerCase();
  if (type.contains('goal')) return 'هدف';
  if (type.contains('yellow')) return 'بطاقة صفراء';
  if (type.contains('red')) return 'بطاقة حمراء';
  if (type.contains('substitution')) return 'تبديل';
  if (type.contains('injury')) return 'إصابة';
  if (type.contains('corner')) return 'ركلة ركنية';
  if (type.contains('lineup')) return 'التشكيل الرسمي';
  if (type.contains('half')) return 'نهاية الشوط الأول';
  if (type.contains('full')) return 'نهاية المباراة';
  return raw.isEmpty ? 'حدث' : raw;
}

IconData _eventIcon(String raw) {
  final type = raw.toLowerCase();
  if (type.contains('goal')) return Icons.sports_soccer;
  if (type.contains('yellow') || type.contains('red'))
    return Icons.style_outlined;
  if (type.contains('substitution')) return Icons.swap_horiz;
  if (type.contains('injury')) return Icons.healing_outlined;
  if (type.contains('lineup')) return Icons.groups_outlined;
  return Icons.timeline;
}

Color _eventColor(String raw) {
  final type = raw.toLowerCase();
  if (type.contains('goal')) return kPrimary;
  if (type.contains('red')) return kLive;
  if (type.contains('yellow')) return kGold;
  return Colors.white70;
}

class _DetailTabPlaceholder extends StatelessWidget {
  const _DetailTabPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Text(message, style: const TextStyle(color: Colors.white60)),
    ),
  );
}

class SourceNote extends StatelessWidget {
  const SourceNote({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Icon(Icons.radio_button_checked, size: 13, color: kPrimary),
        SizedBox(width: 6),
        Text(
          'المصدر: بيانات مباشرة، وتُستخدم النسخة المحفوظة عند انقطاع الاتصال',
          style: TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    ),
  );
}

class PlayerDetailScreen extends StatelessWidget {
  const PlayerDetailScreen({
    super.key,
    required this.api,
    required this.playerId,
  });
  final ApiClient api;
  final int playerId;

  String text(dynamic v) => v?.toString() ?? '—';

  @override
  Widget build(BuildContext context) => Scaffold(
    body: FutureBuilder<Map<String, dynamic>>(
      future: api.getPlayerDetail(playerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError || snapshot.data == null)
          return const ErrorState(title: 'تعذر تحميل بيانات اللاعب حاليًا');
        final root = snapshot.data!;
        final p = ((root['player'] as Map?) ?? root).cast<String, dynamic>();
        final totals = (p['totals'] as List?)
                ?.whereType<Map>()
                .map((item) => item.cast<String, dynamic>())
                .toList() ??
            <Map<String, dynamic>>[];
        final career = (p['career'] as List?)
                ?.whereType<Map>()
                .map((item) => item.cast<String, dynamic>())
                .toList() ??
            <Map<String, dynamic>>[];
        final metrics = totals.isNotEmpty
            ? totals
            : [
                {'label': 'مشاركة', 'value': p['appearances'] ?? '—'},
                {'label': 'هدف', 'value': p['goals'] ?? '—'},
                {'label': 'رقم', 'value': p['shirtNumber'] ?? '—'},
              ];
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 286,
              pinned: true,
              backgroundColor: kCard,
              surfaceTintColor: Colors.transparent,
              foregroundColor: Colors.white,
              title: Text(
                text(p['name']),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: _PlayerHero(player: p, text: text),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 30),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: metrics
                        .map(
                          (metric) => _PlayerMetric(
                            value: text(metric['value']),
                            label: text(metric['label']),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 22),
                  const SectionTitle(
                    icon: Icons.badge_outlined,
                    title: 'بطاقة اللاعب',
                  ),
                  const SizedBox(height: 10),
                  SectionCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                kPrimary.withOpacity(.14),
                                Colors.transparent,
                              ],
                              begin: AlignmentDirectional.centerStart,
                              end: AlignmentDirectional.centerEnd,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: kGold.withOpacity(.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: kGold.withOpacity(.38),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person_pin_rounded,
                                  color: kGold,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 11),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ملف اللاعب',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'تفاصيله داخل وخارج الملعب',
                                      style: TextStyle(
                                        color: kMuted,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.verified_rounded,
                                color: kPrimary.withOpacity(.8),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: kLine),
                        _PlayerInfoRow(label: 'النادي', value: p['club'], text: text),
                        _PlayerInfoRow(label: 'المركز', value: p['position'], text: text),
                        _PlayerInfoRow(
                          label: 'رقم القميص',
                          value: p['shirtNumber'],
                          text: text,
                        ),
                        _PlayerInfoRow(
                          label: 'الجنسية',
                          value: p['nationality'],
                          text: text,
                        ),
                        _PlayerInfoRow(
                          label: 'تاريخ الميلاد',
                          value: p['birthDate'],
                          text: text,
                        ),
                        _PlayerInfoRow(
                          label: 'مكان الميلاد',
                          value: p['birthPlace'],
                          text: text,
                        ),
                        _PlayerInfoRow(
                          label: 'الحالة',
                          value: p['availability'],
                          text: text,
                          last: true,
                        ),
                      ],
                    ),
                  ),
                  if (career.isNotEmpty) ...[
                    const SizedBox(height: 13),
                    const SectionTitle(
                      icon: Icons.timeline_rounded,
                      title: 'رحلة اللاعب',
                    ),
                    const SizedBox(height: 10),
                    ...career.asMap().entries.map(
                      (entry) {
                        final c = entry.value;
                        final isLast = entry.key == career.length - 1;
                        return Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: SectionCard(
                          padding: const EdgeInsets.fromLTRB(13, 14, 13, 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(.06),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: kLine),
                                    ),
                                    child: TeamLogo(
                                      url: c['toTeamCrestUrl']?.toString(),
                                      size: 34,
                                    ),
                                  ),
                                  if (!isLast)
                                    Container(
                                      width: 2,
                                      height: 33,
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: kPrimary.withOpacity(.45),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      text(c['toTeam']),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${text(c['from'])} ← ${text(c['until'])}',
                                      style: const TextStyle(
                                        color: kMuted,
                                        fontSize: 10,
                                      ),
                                    ),
                                    if (c['contract'] != null) ...[
                                      const SizedBox(height: 7),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: kPrimary.withOpacity(.1),
                                          borderRadius: BorderRadius.circular(7),
                                        ),
                                        child: Text(
                                          text(c['contract']),
                                          style: const TextStyle(
                                            color: kPrimary,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (c['position'] != null)
                                Text(
                                  text(c['position']),
                                  style: const TextStyle(
                                    color: kPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  const SourceNote(),
                ]),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _PlayerHero extends StatelessWidget {
  const _PlayerHero({required this.player, required this.text});
  final Map<String, dynamic> player;
  final String Function(dynamic) text;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage(supportersBackground),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(
          Color(0xb8071912),
          BlendMode.darken,
        ),
      ),
      gradient: LinearGradient(
        colors: [
          Color(0xd91d6344),
          Color(0xe60a2419),
          Color(0xf5071912),
        ],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        stops: [0, .62, 1],
      ),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        PositionedDirectional(
          end: -25,
          top: -34,
          child: Icon(
            Icons.shield_rounded,
            size: 210,
            color: Colors.white.withOpacity(.055),
          ),
        ),
        PositionedDirectional(
          end: 20,
          bottom: 0,
          child: Container(
            width: 142,
            height: 206,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(72)),
              border: Border.all(color: Colors.white.withOpacity(.13)),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(.13),
                  Colors.white.withOpacity(.025),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(64)),
              child: CachedRemoteImage(
                url: player['photoUrl']?.toString(),
                width: 126,
                height: 198,
                fit: BoxFit.cover,
                fallbackIcon: Icons.person,
                fallback: const Center(
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.white24,
                    size: 76,
                  ),
                ),
              ),
            ),
          ),
        ),
        PositionedDirectional(
          start: 20,
          end: 168,
          bottom: 34,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: kGold.withOpacity(.16),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: kGold.withOpacity(.34)),
                ),
                child: Text(
                  text(player['position']),
                  style: const TextStyle(
                    color: kGold,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                text(player['name']),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                text(player['club']),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
        if (player['shirtNumber'] != null)
          PositionedDirectional(
            start: 20,
            top: 92,
            child: Text(
              '#${text(player['shirtNumber'])}',
              style: TextStyle(
                color: Colors.white.withOpacity(.18),
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    ),
  );
}

class _PlayerMetric extends StatelessWidget {
  const _PlayerMetric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    width: 100,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: kLine),
    ),
    child: Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: kGold,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: kMuted, fontSize: 10)),
      ],
    ),
  );
}

class _PlayerInfoRow extends StatelessWidget {
  const _PlayerInfoRow({
    required this.label,
    required this.value,
    required this.text,
    this.last = false,
  });
  final String label;
  final dynamic value;
  final String Function(dynamic) text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: kLine)),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: kMuted, fontSize: 11)),
          const Spacer(),
          Flexible(
            child: Text(
              text(value),
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class DataPage<T> extends StatefulWidget {
  const DataPage({
    super.key,
    required this.title,
    required this.icon,
    required this.load,
    required this.builder,
  });
  final String title;
  final IconData icon;
  final Future<T> Function() load;
  final Widget Function(T data) builder;

  @override
  State<DataPage<T>> createState() => _DataPageState<T>();
}

class _DataPageState<T> extends State<DataPage<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  void _retry() => setState(() => _future = widget.load());

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionTitle(icon: widget.icon, title: widget.title),
            const SizedBox(height: 14),
            const LoadingCard(),
          ],
        );
      }
      if (snapshot.hasError || snapshot.data == null) {
        return ErrorState(title: widget.title, onRetry: _retry);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SectionTitle(icon: widget.icon, title: widget.title),
          ),
          Expanded(child: widget.builder(snapshot.data as T)),
        ],
      );
    },
  );
}

class NextMatchCard extends StatelessWidget {
  const NextMatchCard({super.key, required this.match});
  final Match match;

  @override
  Widget build(BuildContext context) => SectionCard(
    gradient: true,
    child: Column(
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_events_outlined, size: 17, color: kGold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                match.competition,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            StatusBadge(match: match),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TeamColumn(team: match.homeTeam),
            Text(
              match.isPlayed ? '${match.homeScore} - ${match.awayScore}' : 'VS',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            TeamColumn(team: match.awayTeam),
          ],
        ),
        if (match.formattedKickoff != null) ...[
          const SizedBox(height: 12),
          Text(
            match.formattedKickoff!,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ],
    ),
  );
}

class MatchListTile extends StatelessWidget {
  const MatchListTile({super.key, required this.match});
  final Match match;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MatchDetailScreen(api: ApiClient(), matchId: match.matchId),
          ),
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: match.isLive
                  ? kLive.withOpacity(.58)
                  : kPrimary.withOpacity(.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  matchCardBackground,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xff062c1d).withOpacity(.52),
                        const Color(0xff03180f).withOpacity(.88),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.emoji_events_rounded,
                          color: kGold,
                          size: 16,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            match.competition,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        StatusBadge(match: match),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _MatchCardTeam(
                            team: match.homeTeam,
                            angle: -.065,
                            alignment: CrossAxisAlignment.start,
                          ),
                        ),
                        SizedBox(
                          width: 92,
                          child: _MatchCardCenter(match: match),
                        ),
                        Expanded(
                          child: _MatchCardTeam(
                            team: match.awayTeam,
                            angle: .065,
                            alignment: CrossAxisAlignment.end,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Container(height: 1, color: Colors.white.withOpacity(.16)),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        if (match.formattedKickoff != null)
                          Expanded(
                            child: MetaLine(
                              icon: Icons.schedule_rounded,
                              text: match.formattedKickoff!,
                            ),
                          ),
                        if (match.venue != null)
                          Expanded(
                            child: MetaLine(
                              icon: Icons.stadium_outlined,
                              text: match.venue!,
                            ),
                          ),
                        const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: kPrimary,
                          size: 14,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _MatchCardTeam extends StatelessWidget {
  const _MatchCardTeam({
    required this.team,
    required this.angle,
    required this.alignment,
  });

  final Team team;
  final double angle;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: alignment,
        children: [
          Transform.rotate(
            angle: angle,
            child: TeamLogo(url: team.crestUrl, size: 92, tinted: true),
          ),
          const SizedBox(height: 4),
          Text(
            team.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: alignment == CrossAxisAlignment.end
                ? TextAlign.right
                : TextAlign.left,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
            ),
          ),
        ],
      );
}

class _MatchCardCenter extends StatelessWidget {
  const _MatchCardCenter({required this.match});

  final Match match;

  @override
  Widget build(BuildContext context) {
    final score = '${match.homeScore ?? 0} - ${match.awayScore ?? 0}';
    final centerText = match.isPlayed || match.isLive
        ? score
        : match.formattedKickoff?.split(' - ').last ?? 'موعد المباراة';
    final subText = match.isPlayed
        ? 'النتيجة النهائية'
        : match.isLive
            ? 'مباشر الآن'
            : match.formattedKickoff?.split(' - ').first ?? 'لم يحدد بعد';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          centerText,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: match.isLive ? kLive : Colors.white,
            fontSize: match.isPlayed || match.isLive ? 24 : 14,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subText,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: match.isLive ? kLive : Colors.white70,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class MetaLine extends StatelessWidget {
  const MetaLine({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 13, color: Colors.white38),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
      ),
    ],
  );
}

class PlayerCard extends StatelessWidget {
  const PlayerCard({super.key, required this.player});
  final Player player;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    margin: EdgeInsets.zero,
    child: InkWell(
      onTap: () => openPlayer(context, player.id),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xff174533), Color(0xff081b13)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  child: CachedRemoteImage(
                    url: player.photoUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    fallbackIcon: Icons.person,
                    fallback: const Center(
                      child: Icon(
                        Icons.person_rounded,
                        size: 64,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(.08),
                          Colors.black.withOpacity(.72),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0, .46, 1],
                      ),
                    ),
                  ),
                ),
                if (player.number != null)
                  PositionedDirectional(
                    top: 9,
                    end: 9,
                    child: Container(
                      width: 31,
                      height: 31,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: kGold,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.22),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        '${player.number}',
                        style: const TextStyle(
                          color: Color(0xff1a2210),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                PositionedDirectional(
                  start: 11,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.25),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Colors.white.withOpacity(.15)),
                    ),
                    child: Text(
                      player.position,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
            color: kCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.sports_soccer, size: 13, color: kGold),
                    const SizedBox(width: 4),
                    Text(
                      '${player.goals ?? 0} أهداف',
                      style: const TextStyle(color: kMuted, fontSize: 10),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_back_rounded,
                      size: 15,
                      color: kPrimary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class NewsCard extends StatelessWidget {
  const NewsCard({super.key, required this.item, this.hero = false});
  final NewsItem item;
  final bool hero;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(20),
    onTap: () async {
      final uri = Uri.tryParse(item.url);
      if (uri != null)
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    },
    child: SectionCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: hero ? 46 : 40,
            height: hero ? 46 : 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff1d6547), Color(0xff0d2d21)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kPrimary.withOpacity(.2)),
            ),
            child: Icon(
              hero ? Icons.auto_stories_rounded : Icons.article_outlined,
              color: kPrimary,
              size: hero ? 23 : 20,
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
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_outward_rounded,
                      color: kMuted,
                      size: 15,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.title,
                  maxLines: hero ? 4 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: hero ? 16 : 14,
                    fontWeight: FontWeight.w900,
                    height: 1.5,
                  ),
                ),
                if (item.publishedText != null) ...[
                  const SizedBox(height: 7),
                  Text(
                    item.publishedText!,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
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

class HistoryEntry extends StatelessWidget {
  const HistoryEntry({
    super.key,
    required this.year,
    required this.title,
    required this.body,
  });
  final String year;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            year,
            style: const TextStyle(color: kGold, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(color: Colors.white60, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(15),
    this.gradient = false,
  });
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool gradient;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient
            ? const LinearGradient(
                colors: [Color(0xff194633), kCard],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              )
            : null,
        boxShadow: [
          if (gradient)
            BoxShadow(
              color: kPrimary.withOpacity(.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: child,
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(.13),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: kPrimary),
      ),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
      ),
    ],
  );
}

class TeamColumn extends StatelessWidget {
  const TeamColumn({super.key, required this.team, this.compact = false});
  final Team team;
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      TeamLogo(url: team.crestUrl, size: compact ? 34 : 48),
      const SizedBox(height: 5),
      SizedBox(
        width: compact ? 80 : 100,
        child: Text(
          team.name,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );
}

class TeamLogo extends StatelessWidget {
    const TeamLogo({super.key, required this.url, this.size = 44, this.tinted = false});
    final String? url;
    final double size;
    final bool tinted;

    @override
    Widget build(BuildContext context) {
      final image = SizedBox(
        width: size,
        height: size,
        child: url == 'asset://team_crest'
            ? Image.asset('assets/images/team_crest.png', fit: BoxFit.contain, filterQuality: FilterQuality.high)
            : CachedRemoteImage(
                url: url,
                width: size,
                height: size,
                fit: BoxFit.contain,
                fallbackIcon: Icons.shield_outlined,
                fallback: const BrandMark(),
              ),
      );
      return tinted
          ? ColorFiltered(
              colorFilter: ColorFilter.mode(
                const Color(0xff8de5ad).withOpacity(.78),
                BlendMode.modulate,
              ),
              child: image,
            )
          : image;
    }
    }

    
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.match});
  final Match match;

  @override
  Widget build(BuildContext context) {
    final color = match.isLive ? kLive : kPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withOpacity(.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (match.isLive)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsetsDirectional.only(end: 5),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          Text(
            match.statusText,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class QuickTile extends StatelessWidget {
  const QuickTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(.11),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(.22)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

class StatChip extends StatelessWidget {
  const StatChip({super.key, required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    width: 160,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xff2d4b3e)),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: kPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 10),
        ),
      ],
    ),
  );
}

class LoadingCard extends StatelessWidget {
  const LoadingCard({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(16),
    child: Center(child: CircularProgressIndicator()),
  );
}

class ErrorCard extends StatelessWidget {
  const ErrorCard({super.key, required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => SectionCard(
    child: Text(message, style: const TextStyle(color: Colors.white70)),
  );
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    color: kGold.withOpacity(.14),
    child: const Row(
      children: [
        Icon(Icons.cloud_off_outlined, size: 16, color: kGold),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'يرجى الاتصال بالإنترنت للحصول على آخر التحديثات — تعرض الآن آخر نسخة محفوظة.',
            style: TextStyle(
              color: kGold,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.title, this.onRetry});
  final String title;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تعذر تحميل $title الآن',
              style: const TextStyle(color: Colors.white70),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
