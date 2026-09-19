// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/football_models.dart';
import '../services/api_client.dart';
import '../widgets/cached_remote_image.dart';

class TableScreen extends StatefulWidget {
  const TableScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  late Future<List<Standing>> _future;
  int _filter = 0;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getStandings();
  }

  Future<void> _refresh() async {
    final next = widget.api.getStandings();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Standing>>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _StandingsLoading();
      }
      if (snapshot.hasError || snapshot.data == null) {
        return _StandingsError(onRetry: _refresh);
      }
      final allRows = snapshot.data!;
      if (allRows.isEmpty) return const _StandingsEmpty();
      final masry = _masryRow(allRows);
      final rows = _filter == 1
          ? allRows.take(5).toList()
          : _filter == 2
              ? allRows
                  .where((row) =>
                      row.isMasry || row.team.name.contains('المصري'))
                  .toList()
              : allRows;

      return RefreshIndicator(
        color: kPrimary,
        backgroundColor: kCard,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
          children: [
            _StandingsHero(
              leader: allRows.first,
              masry: masry,
              totalTeams: allRows.length,
            ),
            const SizedBox(height: 17),
            const _SectionLabel(
              eyebrow: 'ترتيب لحظي',
              title: 'سباق القمة',
              icon: Icons.insights_rounded,
            ),
            const SizedBox(height: 11),
            _FilterBar(
              selected: _filter,
              onChanged: (value) => setState(() => _filter = value),
            ),
            const SizedBox(height: 12),
            _StandingsBoard(rows: rows),
            const SizedBox(height: 10),
            const _StandingsLegend(),
          ],
        ),
      );
    },
  );
}

Standing _masryRow(List<Standing> rows) {
  for (final row in rows) {
    if (row.isMasry || row.team.name.contains('المصري')) return row;
  }
  return rows.first;
}

class _StandingsHero extends StatelessWidget {
  const _StandingsHero({
    required this.leader,
    required this.masry,
    required this.totalTeams,
  });
  final Standing leader;
  final Standing masry;
  final int totalTeams;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      gradient: const LinearGradient(
        colors: [Color(0xff1d6145), Color(0xff0b241a)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ),
      border: Border.all(color: kPrimary.withOpacity(.28)),
      boxShadow: [
        BoxShadow(
          color: kPrimary.withOpacity(.12),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          left: -12,
          bottom: -24,
          child: Icon(
            Icons.emoji_events_rounded,
            size: 128,
            color: Colors.white.withOpacity(.05),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(.24)),
                  ),
                  child: Image.asset(
                    'assets/images/team_crest.png',
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الدوري المصري',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'المنافسة مستمرة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_back_rounded, color: Colors.white70),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'المصري في المركز ' + masry.rank.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'نحن نتابع كل نقطة وكل خطوة حتى صافرة النهاية',
              style: TextStyle(
                color: Colors.white.withOpacity(.72),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 17),
            Row(
              children: [
                _HeroStat(
                  value: masry.points.toString(),
                  label: 'نقطة المصري',
                ),
                const SizedBox(width: 8),
                _HeroStat(value: leader.team.name, label: 'المتصدر', compact: true),
                const SizedBox(width: 8),
                _HeroStat(value: totalTeams.toString(), label: 'فريق'),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
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
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.16),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(.12)),
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
              fontSize: compact ? 11 : 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.eyebrow,
    required this.title,
    required this.icon,
  });
  final String eyebrow;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(.13),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: kPrimary, size: 20),
      ),
      const SizedBox(width: 10),
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
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    ],
  );
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _FilterChip(
        label: 'كل الفرق',
        selected: selected == 0,
        onTap: () => onChanged(0),
      ),
      const SizedBox(width: 8),
      _FilterChip(
        label: 'أول 5',
        selected: selected == 1,
        onTap: () => onChanged(1),
      ),
      const SizedBox(width: 8),
      _FilterChip(
        label: 'المصري',
        selected: selected == 2,
        onTap: () => onChanged(2),
      ),
    ],
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(30),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? kPrimary : kCard,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: selected ? kPrimary : kLine),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? const Color(0xff062117) : kMuted,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _StandingsBoard extends StatelessWidget {
  const _StandingsBoard({required this.rows});
  final List<Standing> rows;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: kCardAlt,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: kLine),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 34,
              child: Text(
                '#',
                style: TextStyle(
                  color: kMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Expanded(
              child: Text(
                'الفريق',
                style: TextStyle(
                  color: kMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(
              width: 36,
              child: Text(
                'لعب',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(
              width: 36,
              child: Text(
                'فارق',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(
              width: 40,
              child: Text(
                'نقاط',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kGold,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
      ...rows.map((row) => _StandingRow(row: row)),
    ],
  );
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({required this.row});
  final Standing row;

  @override
  Widget build(BuildContext context) {
    final isMasry = row.isMasry || row.team.name.contains('المصري');
    final rankColor = row.rank == 1 ? kGold : row.rank <= 4 ? kPrimary : kMuted;
    return Container(
      margin: const EdgeInsets.only(top: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isMasry ? kPrimary.withOpacity(.13) : kCard,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: isMasry ? kPrimary.withOpacity(.55) : kLine),
        boxShadow: isMasry
            ? [BoxShadow(color: kPrimary.withOpacity(.08), blurRadius: 18)]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(.13),
              shape: BoxShape.circle,
            ),
            child: Text(
              row.rank.toString(),
              style: TextStyle(
                color: rankColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Row(
              children: [
                _Crest(row: row),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.team.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isMasry ? kPrimary : kInk,
                          fontSize: 12,
                          fontWeight:
                              isMasry ? FontWeight.w900 : FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        row.played.toString() + ' مباراة',
                        style: const TextStyle(
                          color: kMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _RowStat(value: row.played.toString()),
          _RowStat(
            value: (row.goalDifference ?? 0).toString(),
            positive: (row.goalDifference ?? 0) >= 0,
          ),
          Container(
            width: 40,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isMasry ? kPrimary : kCardAlt,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              row.points.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isMasry ? const Color(0xff062117) : kInk,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Crest extends StatelessWidget {
  const _Crest({required this.row});
  final Standing row;

  @override
  Widget build(BuildContext context) {
    final isMasry = row.isMasry || row.team.name.contains('المصري');
    return Container(
      width: 38,
      height: 38,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isMasry ? Colors.white : kCardAlt,
        shape: BoxShape.circle,
        border: Border.all(color: isMasry ? kPrimary : kLine),
      ),
      child: isMasry
          ? Image.asset(
              'assets/images/team_crest.png',
              filterQuality: FilterQuality.high,
            )
          : CachedRemoteImage(
              url: row.team.crestUrl,
              fit: BoxFit.contain,
              fallbackIcon: Icons.shield_outlined,
            ),
    );
  }
}

class _RowStat extends StatelessWidget {
  const _RowStat({required this.value, this.positive = false});
  final String value;
  final bool positive;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 36,
    child: Text(
      value,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: positive ? kInk : kLive,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _StandingsLegend extends StatelessWidget {
  const _StandingsLegend();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: kLine),
    ),
    child: const Row(
      children: [
        Icon(Icons.info_outline_rounded, size: 16, color: kGold),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'لعب: عدد المباريات · فارق: فارق الأهداف · نقاط: مجموع النقاط',
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

class _StandingsLoading extends StatelessWidget {
  const _StandingsLoading();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Container(
        height: 205,
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(26),
        ),
      ),
      const SizedBox(height: 20),
      const Center(child: CircularProgressIndicator(color: kPrimary)),
    ],
  );
}

class _StandingsError extends StatelessWidget {
  const _StandingsError({required this.onRetry});
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: kGold, size: 42),
          const SizedBox(height: 12),
          const Text(
            'تعذر تحميل جدول الترتيب',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'تحقق من الاتصال وحاول مرة أخرى',
            style: TextStyle(color: kMuted, fontSize: 11),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    ),
  );
}

class _StandingsEmpty extends StatelessWidget {
  const _StandingsEmpty();

  @override
  Widget build(BuildContext context) => const Center(
    child: Text(
      'لا توجد بيانات ترتيب متاحة الآن',
      style: TextStyle(color: kMuted),
    ),
  );
}