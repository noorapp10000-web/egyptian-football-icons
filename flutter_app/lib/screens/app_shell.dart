// ignore_for_file: deprecated_member_use, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import '../models/football_models.dart';
import '../models/history_content.dart';
import '../services/api_client.dart';
import '../services/offline_cache.dart';
import '../widgets/brand_mark.dart';

const teamCrest = 'assets/images/team_crest.png';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  final api = ApiClient();

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(api: api),
      MatchesScreen(api: api),
      TableScreen(api: api),
      SquadScreen(api: api),
      NewsScreen(api: api),
      const HistoryScreen(),
      SettingsScreen(api: api),
    ];
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 18,
        title: const Row(
          children: [
            BrandMark(size: 34),
            SizedBox(width: 10),
            Text(
              'MASRAWY FAN',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: kPrimary.withOpacity(.13),
              child: const Icon(
                Icons.notifications_none,
                size: 18,
                color: kPrimary,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: offlineState,
            builder: (_, offline, __) => offline
                ? const OfflineBanner()
                : const SizedBox.shrink(),
          ),
          Expanded(child: IndexedStack(index: index, children: pages)),
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
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
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
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'التاريخ',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.api});
  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          FutureBuilder<List<Match>>(
            future: api.getMatches(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const LoadingCard();
              if (snapshot.hasError)
                return ErrorCard(message: 'تعذر تحميل المباراة القادمة');
              final matches = snapshot.data ?? [];
              final next = matches
                  .where((m) => m.isLive || m.status == 'upcoming')
                  .firstOrNull;
              return next == null
                  ? const SectionCard(
                      child: Text('لا توجد مباراة قادمة معلنة حاليًا'),
                    )
                  : NextMatchCard(match: next);
            },
          ),
          const SizedBox(height: 18),
          const SectionTitle(
            icon: Icons.dashboard_outlined,
            title: 'مركز المصري',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              QuickTile(
                icon: Icons.calendar_month,
                label: 'المباريات',
                color: kPrimary,
              ),
              QuickTile(
                icon: Icons.list_alt,
                label: 'جدول الدوري',
                color: kGold,
              ),
              QuickTile(
                icon: Icons.groups,
                label: 'قائمة الفريق',
                color: Color(0xff77b5e8),
              ),
              QuickTile(
                icon: Icons.newspaper,
                label: 'آخر الأخبار',
                color: kLive,
              ),
            ],
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<Match>>(
            future: api.getMatches(),
            builder: (context, snapshot) {
              final data = snapshot.data ?? [];
              final recent = data.where((m) => m.isPlayed).take(3).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(
                    icon: Icons.sports_soccer,
                    title: 'آخر النتائج',
                  ),
                  const SizedBox(height: 10),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const LoadingCard()
                  else if (recent.isEmpty)
                    const SectionCard(child: Text('لا توجد نتائج متاحة حاليًا'))
                  else
                    ...recent.map(
                      (match) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: MatchListTile(match: match),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key, required this.api});
  final ApiClient api;

  @override
  Widget build(BuildContext context) => DataPage<List<Match>>(
    title: 'كل المباريات',
    icon: Icons.calendar_month,
    future: api.getMatches(),
    builder: (matches) => ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      itemCount: matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => MatchListTile(match: matches[index]),
    ),
  );
}

class TableScreen extends StatelessWidget {
  const TableScreen({super.key, required this.api});
  final ApiClient api;

  @override
  Widget build(BuildContext context) => DataPage<List<Standing>>(
    title: 'جدول الدوري',
    icon: Icons.list_alt,
    future: api.getStandings(),
    builder: (standings) => ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 28),
      children: [
        SectionCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 34,
                      child: Text('#', style: TextStyle(color: Colors.white54)),
                    ),
                    Expanded(
                      child: Text(
                        'الفريق',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                    Text('لعب   نقاط', style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
              ...standings.map(
                (row) => Container(
                  color: row.isMasry ? kPrimary.withOpacity(.12) : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 34,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: row.rank <= 3
                              ? kGold.withOpacity(.2)
                              : kCardAlt,
                          child: Text(
                            '${row.rank}',
                            style: TextStyle(
                              fontSize: 11,
                              color: row.rank <= 3 ? kGold : Colors.white70,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            TeamLogo(url: row.team.crestUrl, size: 28),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                row.team.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: row.isMasry
                                      ? FontWeight.w900
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                            if (row.isMasry) ...[
                              const SizedBox(width: 6),
                              const Text(
                                'المصري',
                                style: TextStyle(color: kPrimary, fontSize: 10),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        '${row.played}    ${row.points}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class SquadScreen extends StatelessWidget {
  const SquadScreen({super.key, required this.api});
  final ApiClient api;

  @override
  Widget build(BuildContext context) => DataPage<List<Player>>(
    title: 'قائمة الفريق',
    icon: Icons.groups,
    future: api.getSquad(),
    builder: (players) => ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        const SectionCard(
          child: Row(
            children: [
              BrandMark(size: 54),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'الفريق الأول للنادي المصري البورسعيدي',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: .82,
          ),
          itemCount: players.length,
          itemBuilder: (_, index) => PlayerCard(player: players[index]),
        ),
      ],
    ),
  );
}

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key, required this.api});
  final ApiClient api;

  @override
  Widget build(BuildContext context) => DataPage<List<NewsItem>>(
    title: 'آخر الأخبار',
    icon: Icons.newspaper,
    future: api.getNews(),
    builder: (news) => ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      itemCount: news.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => NewsCard(item: news[index]),
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
    5 => const _RecordsSection(title: 'أفضل الهدافين في التاريخ', records: historyTopScorers, statLabel: 'هدف'),
    6 => const _LegendsSection(),
    7 => const _RecordsSection(title: 'الأكثر مشاركة في تاريخ النادي', records: historyAppearances, statLabel: 'مباراة'),
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
                  Text(item.year, style: const TextStyle(color: kGold, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900))),
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
              Text(item.body, style: const TextStyle(color: Colors.white70, height: 1.65)),
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
      const SectionTitle(icon: Icons.emoji_events_outlined, title: 'خزانة البطولات'),
      const SizedBox(height: 10),
      for (final honour in historyHonours) ...[
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(honour.title, style: const TextStyle(fontWeight: FontWeight.w900))),
                  Text('${honour.wins.length}× بطل', style: const TextStyle(color: kGold, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final win in honour.wins) _HistoryPill(text: win)],
              ),
              if (honour.runnersUp.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('الوصافة', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  children: [for (final year in honour.runnersUp) _HistoryPill(text: year, muted: true)],
                ),
              ],
              if (honour.note != null) ...[
                const SizedBox(height: 10),
                Text(honour.note!, style: const TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.w800)),
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

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionTitle(icon: Icons.route, title: 'مسار كأس عاصمة مصر 2026'),
      const SizedBox(height: 10),
      const SectionCard(
        child: Text(
          'من دور المجموعات إلى النهائي، سجل المصري مشوارًا قويًا انتهى بالفوز على إنبي 3–0 والتتويج بالكأس.',
          style: TextStyle(color: Colors.white70, height: 1.6),
        ),
      ),
      const SizedBox(height: 10),
      for (final item in const [
        ('دور المجموعات', 'نتائج متوازنة وتأهل مستحق'),
        ('نصف النهائي', 'عبور صعب أمام منافس قوي'),
        ('النهائي · 8 يونيو 2026', 'المصري 3 — 0 إنبي'),
      ]) ...[
        SectionCard(
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: kPrimary),
              const SizedBox(width: 10),
              Expanded(child: Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w900))),
              Text(item.$2, style: const TextStyle(color: Colors.white60, fontSize: 11)),
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
            height: 170,
            child: PageView(
              children: [
                for (final image in historyGallery)
                  Image.asset(historyAsset(image), fit: BoxFit.cover),
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
      const SectionTitle(icon: Icons.manage_accounts_outlined, title: 'تسلسل المدربين'),
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
      const SectionTitle(icon: Icons.workspace_premium_outlined, title: 'تسلسل رؤساء النادي'),
      const SizedBox(height: 5),
      const Text('من أحمد حسني 1920 إلى كامل أبو علي — فترات رئاسة موثقة.', style: TextStyle(color: Colors.white60, fontSize: 11)),
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
  const _RecordsSection({required this.title, required this.records, required this.statLabel});

  final String title;
  final List<HistoryRecord> records;
  final String statLabel;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionTitle(icon: Icons.gps_fixed, title: title),
      const SizedBox(height: 5),
      const Text('ترتيب محفوظ داخل التطبيق ويظل متاحًا بدون إنترنت.', style: TextStyle(color: Colors.white60, fontSize: 11)),
      const SizedBox(height: 10),
      for (final record in records) ...[
        SectionCard(
          child: Row(
            children: [
              SizedBox(width: 26, child: Text('${record.rank}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w900))),
              const SizedBox(width: 8),
              _HistoryPortrait(image: record.image, size: 48, fallback: record.name),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text('${record.goals} هدف', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                children: [
                  Text('${record.apps}', style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w900)),
                  Text(statLabel, style: const TextStyle(color: Colors.white54, fontSize: 10)),
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
      const SectionTitle(icon: Icons.star_outline, title: 'أساطير النسور الخضراء'),
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
      const SectionTitle(icon: Icons.verified_outlined, title: 'الهوية والمنشآت'),
      const SizedBox(height: 10),
      for (final item in historyIdentity) ...[
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(item.body, style: const TextStyle(color: Colors.white70, height: 1.6)),
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.asset(historyAsset('مدينة بورسعيد.webp'), height: 170, width: double.infinity, fit: BoxFit.cover),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('بورسعيد — مدينة النادي وجمهوره', style: TextStyle(color: Colors.white60, fontSize: 11)),
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
                title: Text(source['label']!, style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.open_in_new, size: 15, color: kPrimary),
                onTap: () => launchUrl(Uri.parse(source['url']!), mode: LaunchMode.externalApplication),
              ),
          ],
        ),
      ),
    ],
  );
}

class _HistoryPersonTile extends StatelessWidget {
  const _HistoryPersonTile({required this.title, required this.subtitle, this.note, this.image});

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
              Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              if (note != null) ...[
                const SizedBox(height: 5),
                Text(note!, style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.45)),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _HistoryPortrait extends StatelessWidget {
  const _HistoryPortrait({this.image, required this.size, required this.fallback});

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
          : Image.asset(historyAsset(image!), fit: BoxFit.cover),
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
    child: Text(text, style: TextStyle(color: muted ? Colors.white60 : kGold, fontSize: 10, fontWeight: FontWeight.w800)),
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

class MatchDetailScreen extends StatelessWidget {
  const MatchDetailScreen({
    super.key,
    required this.api,
    required this.matchId,
  });
  final ApiClient api;
  final int matchId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('تفاصيل المباراة')),
    body: FutureBuilder<Map<String, dynamic>>(
      future: api.getMatchDetail(matchId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const LoadingCard();
        if (snapshot.hasError || snapshot.data == null)
          return const ErrorCard(message: 'تعذر تحميل تفاصيل المباراة');
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
                        _MatchMeta(icon: Icons.stadium_outlined, text: detail.stadium!),
                      if (detail.referee != null)
                        _MatchMeta(icon: Icons.sports_outlined, text: detail.referee!),
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
                    _EventsTab(events: timeline),
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
  const _EventsTab({required this.events});

  final List<MatchEventModel> events;

  @override
  Widget build(BuildContext context) => events.isEmpty
      ? const _DetailTabPlaceholder(message: 'لا توجد أحداث مسجلة لهذه المباراة.')
      : ListView(
          padding: const EdgeInsets.only(top: 12),
          children: [
            SectionCard(
              child: Column(
                children: [
                  for (final event in events) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 17,
                        backgroundColor: _eventColor(event.type).withOpacity(.16),
                        child: Icon(_eventIcon(event.type), size: 17, color: _eventColor(event.type)),
                      ),
                      title: Text(
                        _eventLabel(event.type),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        [
                          if (event.player != null) event.player!,
                          if (event.relatedPlayer != null) event.relatedPlayer!,
                          if (event.teamName != null) event.teamName!,
                          if (event.text != null) event.text!,
                        ].join(' · '),
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                      trailing: Text(
                        event.minute == null
                            ? '—'
                            : '${event.minute}${event.addedTime == null ? '' : '+${event.addedTime}'}’',
                        style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (event != events.last) const Divider(height: 1),
                  ],
                ],
              ),
            ),
          ],
        );
}

class _StatsTab extends StatelessWidget {
  const _StatsTab({required this.stats});

  final List<MatchStatRow> stats;

  @override
  Widget build(BuildContext context) => stats.isEmpty
      ? const _DetailTabPlaceholder(message: 'الإحصائيات غير متاحة لهذه المباراة.')
      : ListView(
          padding: const EdgeInsets.only(top: 12),
          children: [
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle(icon: Icons.bar_chart, title: 'إحصائيات المباراة'),
                  const SizedBox(height: 14),
                  for (final stat in stats) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${stat.home}${stat.unit == 'percent' ? '%' : ''}', style: const TextStyle(fontWeight: FontWeight.w900)),
                        Text(stat.label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                        Text('${stat.away}${stat.unit == 'percent' ? '%' : ''}', style: const TextStyle(fontWeight: FontWeight.w900)),
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
      ? const _DetailTabPlaceholder(message: 'لا يوجد تعليق متاح لهذه المباراة.')
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
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(color: kCardAlt, borderRadius: BorderRadius.circular(7)),
                    child: Text(
                      item['minute'] == null ? '—' : '${item['minute']}’',
                      style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item['text']?.toString() ?? '—', style: const TextStyle(height: 1.5))),
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
            Flexible(flex: homeFlex, child: Container(color: kPrimary)),
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
    final keeper = players.isEmpty ? null : players.firstWhere(
      (player) => player.position.contains('حارس') || player.position.toLowerCase().contains('goal'),
      orElse: () => players.first,
    );
    final outfield = players.where((player) => player.id != keeper?.id).toList();
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
                Expanded(child: Text(team.name, style: const TextStyle(fontWeight: FontWeight.w900))),
                if (formation != null) Text(formation!, style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(colors: [Color(0xff14563b), Color(0xff0c3929)]),
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
                child: Text('المدرب: $coach', style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ),
            ),
          if (bench.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text('البدلاء: ${bench.map((player) => player.name).join('، ')}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
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
        CircleAvatar(
          radius: 18,
          backgroundColor: kPrimary.withOpacity(.18),
          backgroundImage: player.photoUrl == null ? null : NetworkImage(player.photoUrl!),
          child: player.photoUrl == null ? Text('${player.number ?? '—'}', style: const TextStyle(fontSize: 11, color: Colors.white)) : null,
        ),
        const SizedBox(height: 3),
        Text(player.name.split(' ').take(2).join(' '), maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
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
  if (parsed.length >= 2 && parsed.reduce((a, b) => a + b) == count) return parsed;
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
  if (type.contains('yellow') || type.contains('red')) return Icons.style_outlined;
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

class DataPage<T> extends StatelessWidget {
  const DataPage({
    super.key,
    required this.title,
    required this.icon,
    required this.future,
    required this.builder,
  });
  final String title;
  final IconData icon;
  final Future<T> future;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionTitle(icon: icon, title: title),
            const SizedBox(height: 14),
            const LoadingCard(),
          ],
        );
      }
      if (snapshot.hasError || snapshot.data == null)
        return ErrorState(title: title);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SectionTitle(icon: icon, title: title),
          ),
          Expanded(child: builder(snapshot.data as T)),
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
      child: Row(
        children: [
          Expanded(child: TeamColumn(team: match.homeTeam, compact: true)),
          Column(
            children: [
              Text(
                match.isPlayed
                    ? '${match.homeScore} - ${match.awayScore}'
                    : 'VS',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              StatusBadge(match: match),
            ],
          ),
          Expanded(child: TeamColumn(team: match.awayTeam, compact: true)),
        ],
      ),
    ),
  );
}

class PlayerCard extends StatelessWidget {
  const PlayerCard({super.key, required this.player});
  final Player player;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(player.name))),
      child: Column(
        children: [
          Expanded(
            child: player.photoUrl == null
                ? const Center(
                    child: Icon(Icons.person, size: 60, color: Colors.white24),
                  )
                : Image.network(
                    player.photoUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white24,
                    ),
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
  const NewsCard({super.key, required this.item});
  final NewsItem item;

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
          if (item.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Image.network(
                item.imageUrl!,
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(height: 12),
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
      decoration: gradient
          ? const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff194633), kCard],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            )
          : null,
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
      Icon(icon, size: 18, color: kPrimary),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
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
    child: url == null
        ? const BrandMark()
        : Image.network(
            url!,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const BrandMark(),
          ),
  );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.match});
  final Match match;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: match.isLive ? kLive.withOpacity(.16) : kPrimary.withOpacity(.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      match.statusText,
      style: TextStyle(
        fontSize: 10,
        color: match.isLive ? kLive : kPrimary,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
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
    width: 154,
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
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
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
            style: TextStyle(color: kGold, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) =>
      Center(child: ErrorCard(message: 'تعذر تحميل $title الآن'));
}
