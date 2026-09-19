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

const teamCrest = 'assets/images/team_crest.png';

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
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      children: [
        const BrandMark(size: 50),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masrawy fan',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'كل نبضة من المصري في مكانها',
                style: TextStyle(
                  color: kMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kPrimary.withOpacity(.24)),
          ),
          child: const Icon(
            Icons.waves_rounded,
            color: kPrimary,
            size: 18,
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
      gradient: true,
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
    );
  }
}

class _CountdownRow extends StatelessWidget {
  const _CountdownRow({required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final values = [
      ('يوم', duration.inDays),
      ('ساعة', duration.inHours.remainder(24)),
      ('دقيقة', duration.inMinutes.remainder(60)),
      ('ثانية', duration.inSeconds.remainder(60)),
    ];
    return Row(
      children: values
          .map(
            (item) => Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: kBackground.withOpacity(.53),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kLine.withOpacity(.7)),
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
  bool results = false;
  @override
  Widget build(BuildContext context) => DataPage<List<Match>>(
    title: 'كل المباريات',
    icon: Icons.calendar_month,
    load: widget.api.getMatches,
    builder: (matches) {
      final upcoming = matches.where((m) => !m.isPlayed).toList();
      final played = matches.where((m) => m.isPlayed).toList();
      final shown = results ? played : upcoming;
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                label: Text('قادمة (${upcoming.length})'),
              ),
              ButtonSegment(
                value: true,
                label: Text('النتائج (${played.length})'),
              ),
            ],
            selected: {results},
            onSelectionChanged: (v) => setState(() => results = v.first),
          ),
          const SizedBox(height: 12),
          if (shown.isEmpty)
            const SectionCard(child: Text('لا توجد مباريات في هذا القسم')),
          ...shown.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MatchListTile(match: m),
            ),
          ),
          const SourceNote(),
        ],
      );
    },
  );
}

class TableScreen extends StatelessWidget {
  const TableScreen({super.key, required this.api});
  final ApiClient api;

  @override
  Widget build(BuildContext context) => DataPage<List<Standing>>(
    title: 'جدول الدوري',
    icon: Icons.list_alt,
    load: api.getStandings,
    builder: (standings) => ListView(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 28),
      children: [
        SectionCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    _StandingCell('#', width: 28, muted: true),
                    Expanded(
                      child: Text(
                        'الفريق',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ),
                    _StandingCell('ل', muted: true),
                    _StandingCell('له', muted: true),
                    _StandingCell('ع', muted: true),
                    _StandingCell('ف', muted: true),
                    _StandingCell('ن', width: 34, muted: true),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...standings.map(
                (row) => Container(
                  color: row.isMasry ? kPrimary.withOpacity(.12) : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      _StandingCell('${row.rank}', width: 28, bold: true),
                      Expanded(
                        child: Row(
                          children: [
                            TeamLogo(url: row.team.crestUrl, size: 24),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                row.team.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: row.isMasry
                                      ? FontWeight.w900
                                      : FontWeight.w600,
                                  color: row.isMasry ? kPrimary : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StandingCell('${row.played}'),
                      _StandingCell('${row.goalsFor ?? 0}'),
                      _StandingCell('${row.goalsAgainst ?? 0}'),
                      _StandingCell(
                        (row.goalDifference ?? 0) > 0
                            ? '+${row.goalDifference}'
                            : '${row.goalDifference ?? 0}',
                      ),
                      _StandingCell('${row.points}', width: 34, bold: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'ل: لعب · له: أهداف له · ع: أهداف عليه · ف: فارق الأهداف · ن: نقاط',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 9),
        ),
      ],
    ),
  );
}

class _StandingCell extends StatelessWidget {
  const _StandingCell(
    this.value, {
    this.width = 27,
    this.bold = false,
    this.muted = false,
  });

  final String value;
  final double width;
  final bool bold;
  final bool muted;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Text(
      value,
      maxLines: 1,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: muted ? Colors.white54 : Colors.white,
        fontSize: 10,
        fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
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
    title: 'قائمة الفريق',
    icon: Icons.groups,
    load: api.getSquad,
    builder: (players) {
      final scorers = [...players]
        ..sort((a, b) => (b.goals ?? 0).compareTo(a.goals ?? 0));
      final groups = <String, List<Player>>{};
      for (final p in players)
        groups.putIfAbsent(group(p.position), () => []).add(p);
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          const SectionCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: BrandMark(size: 54),
              title: Text(
                'الفريق الأول للنادي المصري',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text('الجهاز الفني وقائمة اللاعبين'),
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle(icon: Icons.gps_fixed, title: 'هدافو الفريق'),
          const SizedBox(height: 8),
          ...scorers
              .take(5)
              .toList()
              .asMap()
              .entries
              .map(
                (e) => ListTile(
                  leading: CachedAvatar(url: e.value.photoUrl, size: 34),
                  title: Text(e.value.name),
                  trailing: Text(
                    '${e.value.goals ?? 0} هدف',
                    style: const TextStyle(
                      color: kGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => openPlayer(context, e.value.id),
                ),
              ),
          for (final title in [
            'حراس المرمى',
            'الدفاع',
            'الوسط',
            'الهجوم',
            'لاعبون آخرون',
          ])
            if (groups[title]?.isNotEmpty ?? false) ...[
              const SizedBox(height: 16),
              SectionTitle(icon: Icons.groups_outlined, title: title),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: .82,
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

void openPlayer(BuildContext context, int id) => Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => PlayerDetailScreen(api: ApiClient(), playerId: id),
  ),
);

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key, required this.api});
  final ApiClient api;
  @override
  Widget build(BuildContext context) => DataPage<List<NewsItem>>(
    title: 'آخر الأخبار',
    icon: Icons.newspaper,
    load: api.getNews,
    builder: (news) => ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        if (news.isEmpty)
          const SectionCard(child: Center(child: Text('لا توجد أخبار جديدة')))
        else ...[
          NewsCard(item: news.first, hero: true),
          const SizedBox(height: 12),
          ...news
              .skip(1)
              .map(
                (n) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: NewsCard(item: n),
                ),
              ),
        ],
        const SourceNote(),
      ],
    ),
  );
}

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

  @override
  void initState() {
    super.initState();
    _future = widget.api.getMatchDetail(widget.matchId);
  }

  void _retry() =>
      setState(() => _future = widget.api.getMatchDetail(widget.matchId));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('تفاصيل المباراة')),
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
        final timeline = detail.timeline.isNotEmpty
            ? detail.timeline
            : detail.events;
        final hasLineups =
            detail.homeLineup.isNotEmpty || detail.awayLineup.isNotEmpty;
        return DefaultTabController(
          length: 4,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            children: [
              SectionCard(
                gradient: true,
                child: Column(
                  children: [
                    Text(
                      match.competition,
                      style: const TextStyle(
                        color: kGold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        TeamColumn(team: match.homeTeam),
                        Text(
                          match.isPlayed
                              ? '${match.homeScore} - ${match.awayScore}'
                              : 'VS',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        TeamColumn(team: match.awayTeam),
                      ],
                    ),
                    const SizedBox(height: 14),
                    StatusBadge(match: match),
                    if (match.formattedKickoff != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        match.formattedKickoff!,
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ],
                    if (match.venue != null)
                      Text(
                        match.venue!,
                        style: const TextStyle(color: Colors.white60),
                      ),
                  ],
                ),
              ),
              if (detail.stadium != null || detail.referee != null) ...[
                const SizedBox(height: 8),
                SectionCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (detail.stadium != null)
                        _MatchMeta(
                          icon: Icons.stadium_outlined,
                          text: detail.stadium!,
                        ),
                      if (detail.referee != null)
                        _MatchMeta(
                          icon: Icons.sports_outlined,
                          text: detail.referee!,
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: 'الأحداث'),
                  Tab(text: 'الإحصائيات'),
                  Tab(text: 'التشكيل'),
                  Tab(text: 'التعليق'),
                ],
              ),
              SizedBox(
                height: 620,
                child: TabBarView(
                  children: [
                    _EventsTab(
                      events: timeline,
                      homeTeam: match.homeTeam,
                      awayTeam: match.awayTeam,
                    ),
                    _StatsTab(stats: detail.stats),
                    _LineupsTab(
                      detail: detail,
                      homeTeam: match.homeTeam,
                      awayTeam: match.awayTeam,
                      visible: hasLineups,
                    ),
                    _CommentaryTab(commentary: detail.commentary),
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

class _MatchMeta extends StatelessWidget {
  const _MatchMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: kPrimary),
      const SizedBox(width: 5),
      Text(text, style: const TextStyle(color: Colors.white60, fontSize: 11)),
    ],
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
    return ListView(
      padding: const EdgeInsets.only(top: 12),
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
      : ListView(
          padding: const EdgeInsets.only(top: 12),
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
      : ListView(
          padding: const EdgeInsets.only(top: 12),
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
      : ListView.separated(
          padding: const EdgeInsets.only(top: 12),
          itemCount: commentary.length,
          separatorBuilder: (_, __) => const SizedBox(height: 7),
          itemBuilder: (_, index) {
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
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xff14563b), Color(0xff0c3929)],
              ),
              border: Border.all(color: kPrimary.withOpacity(.25)),
            ),
            child: Column(
              children: [
                for (final line in lines) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final player in line) _PitchPlayer(player: player),
                    ],
                  ),
                  const SizedBox(height: 15),
                ],
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

class _PitchPlayer extends StatelessWidget {
  const _PitchPlayer({required this.player});

  final LineupPlayer player;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 62,
    child: Column(
      children: [
        CachedAvatar(url: player.photoUrl, size: 36),
        const SizedBox(height: 3),
        Text(
          player.name.split(' ').take(2).join(' '),
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
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
  Widget info(String label, dynamic value) => value == null
      ? const SizedBox.shrink()
      : ListTile(
          dense: true,
          title: Text(label, style: const TextStyle(color: Colors.white54)),
          trailing: Text(
            text(value),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('بيانات اللاعب')),
    body: FutureBuilder<Map<String, dynamic>>(
      future: api.getPlayerDetail(playerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError || snapshot.data == null)
          return const ErrorState(title: 'تعذر تحميل بيانات اللاعب حاليًا');
        final root = snapshot.data!;
        final p = ((root['player'] as Map?) ?? root).cast<String, dynamic>();
        final totals = (p['totals'] as List?) ?? const [];
        final comps = (p['competitions'] as List?) ?? const [];
        final career = (p['career'] as List?) ?? const [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              child: Row(
                children: [
                  CachedAvatar(url: p['photoUrl']?.toString(), size: 96),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text(p['name']),
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          [
                            p['position'],
                            p['club'],
                          ].where((x) => x != null).join(' · '),
                          style: const TextStyle(color: Colors.white60),
                        ),
                        Wrap(
                          spacing: 6,
                          children: [
                            if (p['shirtNumber'] != null)
                              Chip(label: Text('#${p['shirtNumber']}')),
                            if (p['nationality'] != null)
                              Chip(label: Text(text(p['nationality']))),
                            if (p['availability'] != null)
                              Chip(label: Text(text(p['availability']))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (totals.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: totals
                    .whereType<Map>()
                    .map(
                      (t) => SizedBox(
                        width: 100,
                        child: SectionCard(
                          child: Column(
                            children: [
                              Text(
                                text(t['value']),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                text(t['label']),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                children: [
                  const SectionTitle(
                    icon: Icons.badge_outlined,
                    title: 'بيانات اللاعب',
                  ),
                  info('النادي', p['club']),
                  info('المركز', p['position']),
                  info('رقم القميص', p['shirtNumber']),
                  info('الجنسية', p['nationality']),
                  info('تاريخ الميلاد', p['birthDate']),
                  info('مكان الميلاد', p['birthPlace']),
                  info('الحالة', p['availability']),
                ],
              ),
            ),
            if (comps.isNotEmpty) ...[
              const SizedBox(height: 12),
              const SectionTitle(
                icon: Icons.query_stats,
                title: 'إحصائيات البطولات الحالية',
              ),
              ...comps.whereType<Map>().map(
                (c) => SectionCard(
                  child: ListTile(
                    title: Text(text(c['competition'])),
                    subtitle: Text(
                      'مشاركات ${text(c['appearances'])} · أهداف ${text(c['goals'])}',
                    ),
                    trailing: Text(
                      '🟨 ${text(c['yellowCards'])}  🟥 ${text(c['redCards'])}',
                    ),
                  ),
                ),
              ),
            ],
            if (career.isNotEmpty) ...[
              const SizedBox(height: 12),
              const SectionTitle(
                icon: Icons.timeline,
                title: 'تاريخ الانتقالات',
              ),
              ...career.whereType<Map>().map(
                (c) => SectionCard(
                  child: ListTile(
                    leading: TeamLogo(
                      url: c['toTeamCrestUrl']?.toString(),
                      size: 34,
                    ),
                    title: Text(text(c['toTeam'])),
                    subtitle: Text(
                      '${text(c['from'])} ← ${text(c['until'])}${c['contract'] == null ? '' : ' · ${c['contract']}'}',
                    ),
                    trailing: c['position'] == null
                        ? null
                        : Text(text(c['position'])),
                  ),
                ),
              ),
            ],
            const SourceNote(),
          ],
        );
      },
    ),
  );
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
    borderRadius: BorderRadius.circular(20),
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MatchDetailScreen(api: ApiClient(), matchId: match.matchId),
      ),
    ),
    child: SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_outlined, size: 14, color: kGold),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  match.competition,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kGold,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              StatusBadge(match: match),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TeamColumn(team: match.homeTeam, compact: true)),
              Text(
                match.isPlayed
                    ? '${match.homeScore} - ${match.awayScore}'
                    : 'VS',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Expanded(child: TeamColumn(team: match.awayTeam, compact: true)),
            ],
          ),
          if (match.formattedKickoff != null || match.venue != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xff2d4b3e)),
            const SizedBox(height: 10),
            if (match.formattedKickoff != null)
              MetaLine(
                icon: Icons.calendar_today_outlined,
                text: match.formattedKickoff!,
              ),
            if (match.venue != null) ...[
              const SizedBox(height: 6),
              MetaLine(icon: Icons.place_outlined, text: match.venue!),
            ],
          ],
        ],
      ),
    ),
  );
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
    child: InkWell(
      onTap: () => openPlayer(context, player.id),
      child: Column(
        children: [
          Expanded(
            child: player.photoUrl == null
                ? const Center(
                    child: Icon(Icons.person, size: 60, color: Colors.white24),
                  )
                : CachedRemoteImage(
                    url: player.photoUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    fallbackIcon: Icons.person,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  '${player.position}${player.number == null ? '' : ' · #${player.number}'}',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
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
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: CachedRemoteImage(
              url: item.imageUrl,
              height: hero ? 240 : 170,
              width: double.infinity,
              fit: BoxFit.cover,
              fallbackIcon: Icons.article_outlined,
              fallback: Container(
                height: hero ? 240 : 170,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff1b4d38), Color(0xff0d271d)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.article_outlined,
                  size: 42,
                  color: Colors.white24,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.sourceName,
                  style: const TextStyle(
                    color: kGold,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  item.title,
                  maxLines: hero ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    height: 1.5,
                  ),
                ),
                if (item.publishedText != null) ...[
                  const SizedBox(height: 6),
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
  const TeamLogo({super.key, required this.url, this.size = 44});
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CachedRemoteImage(
      url: url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      fallbackIcon: Icons.shield_outlined,
      fallback: const BrandMark(),
    ),
  );
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
