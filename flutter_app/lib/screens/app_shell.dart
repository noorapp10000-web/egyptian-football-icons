// ignore_for_file: deprecated_member_use, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import '../models/football_models.dart';
import '../services/api_client.dart';
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
      body: IndexedStack(index: index, children: pages),
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

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
    children: [
      const SectionCard(
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
      const SizedBox(height: 22),
      const SectionTitle(icon: Icons.timeline, title: 'الخط الزمني'),
      const SizedBox(height: 10),
      ...const [
        HistoryEntry(
          year: '1920',
          title: 'تأسيس النادي المصري',
          body:
              'انطلق النادي من قلب بورسعيد ليصبح صوت المدينة وواحدًا من أقدم أندية مصر.',
        ),
        HistoryEntry(
          year: '1933',
          title: 'أول لقب دوري القناة',
          body: 'بدأت مسيرة البطولات المحلية وترسخت هوية الفريق الأخضر.',
        ),
        HistoryEntry(
          year: '1998',
          title: 'نهائي كأس مصر',
          body: 'محطات تاريخية صنعت علاقة خاصة بين النادي وجماهيره.',
        ),
        HistoryEntry(
          year: '2025',
          title: 'كأس الرابطة',
          body: 'عودة جديدة إلى منصات التتويج وطموح مستمر للمستقبل.',
        ),
      ],
    ],
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
        final json = snapshot.data!;
        final match = Match.fromJson(
          (json['match'] as Map?)?.cast<String, dynamic>() ?? json,
        );
        final events =
            ((json['match'] as Map?)?['events'] as List?)
                ?.whereType<Map>()
                .toList() ??
            const [];
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            SectionCard(
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
                  Chip(label: Text(match.statusText)),
                  if (match.venue != null)
                    Text(
                      match.venue!,
                      style: const TextStyle(color: Colors.white60),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (events.isNotEmpty) ...[
              const SectionTitle(icon: Icons.timeline, title: 'أحداث المباراة'),
              const SizedBox(height: 8),
              SectionCard(
                child: Column(
                  children: events.map((event) {
                    final data = event.cast<String, dynamic>();
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: kPrimary.withOpacity(.14),
                        child: Text(
                          '${data['minute'] ?? "—"}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                      title: Text(
                        data['player']?.toString() ??
                            data['type']?.toString() ??
                            'حدث',
                      ),
                      subtitle: Text(data['type']?.toString() ?? ''),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        );
      },
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
        if (match.kickoffText != null) ...[
          const SizedBox(height: 12),
          Text(
            match.kickoffText!,
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

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) =>
      Center(child: ErrorCard(message: 'تعذر تحميل $title الآن'));
}
