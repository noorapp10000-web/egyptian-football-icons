import 'package:intl/intl.dart';

class Team {
  const Team({required this.name, this.crestUrl, this.id});

  final String name;
  final String? crestUrl;
  final int? id;

  factory Team.fromJson(Map<String, dynamic> json) => Team(
    name: json['name'] as String? ?? '—',
    crestUrl: json['crestUrl'] as String?,
    id: (json['id'] as num?)?.toInt(),
  );
}

class Match {
  const Match({
    required this.id,
    required this.matchId,
    required this.competition,
    required this.status,
    required this.statusText,
    required this.homeTeam,
    required this.awayTeam,
    this.kickoff,
    this.kickoffText,
    this.homeScore,
    this.awayScore,
    this.venue,
  });

  final String id;
  final int matchId;
  final String competition;
  final String status;
  final String statusText;
  final Team homeTeam;
  final Team awayTeam;
  final String? kickoff;
  final String? kickoffText;
  final int? homeScore;
  final int? awayScore;
  final String? venue;

  bool get isPlayed => homeScore != null && awayScore != null;
  bool get isLive => status == 'live';

  String? get formattedKickoff {
    if (kickoff == null && kickoffText == null) return null;
    if (kickoff != null) {
      final parsed = DateTime.tryParse(kickoff!);
      if (parsed != null) {
        try {
          final local = parsed.toLocal();
          return '${DateFormat('HH:mm').format(local)} - '
              '${DateFormat('dd-MM-yyyy').format(local)}';
        } catch (_) {
          // Never let date formatting break the UI.
        }
      }
    }
    return _convert24HourToAmPm(kickoffText);
  }

  String? get formattedDate {
    final parsed = kickoff == null ? null : DateTime.tryParse(kickoff!);
    if (parsed == null) return null;
    try {
      return DateFormat('dd-MM-yyyy').format(parsed.toLocal());
    } catch (_) {
      return null;
    }
  }

  factory Match.fromJson(Map<String, dynamic> json) => Match(
    id: json['id'] as String? ?? '${json['matchId']}',
    matchId: (json['matchId'] as num?)?.toInt() ?? 0,
    competition: json['competition'] as String? ?? 'مباراة',
    status: json['status'] as String? ?? 'upcoming',
    statusText: json['statusText'] as String? ?? 'لم تبدأ',
    homeTeam: Team.fromJson(
      (json['homeTeam'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    awayTeam: Team.fromJson(
      (json['awayTeam'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    kickoffText: json['kickoffText'] as String?,
    kickoff: json['kickoff'] as String?,
    homeScore: (json['homeScore'] as num?)?.toInt(),
    awayScore: (json['awayScore'] as num?)?.toInt(),
    venue: json['venue'] as String?,
  );
}

String? _convert24HourToAmPm(String? value) {
  if (value == null || value.isEmpty) return value;
  final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(value);
  if (match == null) return value;
  final hour = int.tryParse(match.group(1)!) ?? 0;
  final minute = match.group(2)!;
  final suffix = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return value.replaceFirst(match.group(0)!, '$displayHour:$minute $suffix');
}

class MatchEventModel {
  const MatchEventModel({
    required this.id,
    required this.type,
    this.minute,
    this.addedTime,
    this.teamName,
    this.player,
    this.relatedPlayer,
    this.text,
  });

  final int id;
  final String type;
  final int? minute;
  final int? addedTime;
  final String? teamName;
  final String? player;
  final String? relatedPlayer;
  final String? text;

  factory MatchEventModel.fromJson(Map<String, dynamic> json) => MatchEventModel(
    id: (json['id'] as num?)?.toInt() ?? 0,
    type: json['type']?.toString() ?? '',
    minute: (json['minute'] as num?)?.toInt(),
    addedTime: (json['addedTime'] as num?)?.toInt(),
    teamName: json['teamName']?.toString(),
    player: json['player']?.toString(),
    relatedPlayer: json['relatedPlayer']?.toString(),
    text: json['text']?.toString(),
  );
}

class LineupPlayer {
  const LineupPlayer({
    required this.id,
    required this.name,
    required this.position,
    this.number,
    this.photoUrl,
    this.isCaptain = false,
    this.isSpare = false,
  });

  final int id;
  final String name;
  final String position;
  final int? number;
  final String? photoUrl;
  final bool isCaptain;
  final bool isSpare;

  factory LineupPlayer.fromJson(Map<String, dynamic> json) => LineupPlayer(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name']?.toString() ?? '—',
    position: json['position']?.toString() ?? '—',
    number: (json['number'] as num?)?.toInt(),
    photoUrl: json['photoUrl']?.toString(),
    isCaptain: json['isCaptain'] == true,
    isSpare: json['isSpare'] == true,
  );
}

class MatchStatRow {
  const MatchStatRow({
    required this.label,
    required this.home,
    required this.away,
    required this.unit,
  });

  final String label;
  final int home;
  final int away;
  final String unit;

  factory MatchStatRow.fromJson(Map<String, dynamic> json) => MatchStatRow(
    label: json['label']?.toString() ?? '',
    home: (json['home'] as num?)?.toInt() ?? 0,
    away: (json['away'] as num?)?.toInt() ?? 0,
    unit: json['unit']?.toString() ?? 'count',
  );
}

class MatchDetailData {
  const MatchDetailData({
    required this.match,
    required this.events,
    required this.timeline,
    required this.commentary,
    required this.homeLineup,
    required this.awayLineup,
    required this.homeBench,
    required this.awayBench,
    required this.stats,
    this.homeCoach,
    this.awayCoach,
    this.homeFormation,
    this.awayFormation,
    this.stadium,
    this.referee,
  });

  final Match match;
  final List<MatchEventModel> events;
  final List<MatchEventModel> timeline;
  final List<Map<String, dynamic>> commentary;
  final List<LineupPlayer> homeLineup;
  final List<LineupPlayer> awayLineup;
  final List<LineupPlayer> homeBench;
  final List<LineupPlayer> awayBench;
  final List<MatchStatRow> stats;
  final String? homeCoach;
  final String? awayCoach;
  final String? homeFormation;
  final String? awayFormation;
  final String? stadium;
  final String? referee;

  factory MatchDetailData.fromJson(Map<String, dynamic> json) {
    final raw = (json['match'] as Map?)?.cast<String, dynamic>() ?? json;
    List<Map<String, dynamic>> list(String key) => (raw[key] as List?)
        ?.whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList() ?? const [];
    final lineups = (raw['lineups'] as Map?)?.cast<String, dynamic>() ?? const {};
    final stats = (raw['stats'] as Map?)?.cast<String, dynamic>() ?? const {};
    return MatchDetailData(
      match: Match.fromJson(raw),
      events: list('events').map(MatchEventModel.fromJson).toList(),
      timeline: list('timeline').map(MatchEventModel.fromJson).toList(),
      commentary: list('commentary'),
      homeLineup: _lineup(lineups['home']),
      awayLineup: _lineup(lineups['away']),
      homeBench: _lineup(lineups['homeBench']),
      awayBench: _lineup(lineups['awayBench']),
      stats: [
        if (stats['possession'] is Map)
          MatchStatRow(
            label: 'الاستحواذ',
            home: ((stats['possession'] as Map)['home'] as num?)?.toInt() ?? 0,
            away: ((stats['possession'] as Map)['away'] as num?)?.toInt() ?? 0,
            unit: 'percent',
          ),
        ...((stats['rows'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => MatchStatRow.fromJson(item.cast<String, dynamic>())),
      ],
      homeCoach: raw['homeCoach']?.toString(),
      awayCoach: raw['awayCoach']?.toString(),
      homeFormation: raw['homeFormation']?.toString(),
      awayFormation: raw['awayFormation']?.toString(),
      stadium: raw['stadium']?.toString(),
      referee: raw['referee']?.toString(),
    );
  }

  static List<LineupPlayer> _lineup(dynamic value) => value is List
      ? value
          .whereType<Map>()
          .map((item) => LineupPlayer.fromJson(item.cast<String, dynamic>()))
          .toList()
      : const [];
}

class Standing {
  const Standing({
    required this.rank,
    required this.team,
    required this.played,
    required this.points,
    required this.isMasry,
    this.goalDifference,
    this.goalsFor,
    this.goalsAgainst,
  });

  final int rank;
  final Team team;
  final int played;
  final int points;
  final bool isMasry;
  final int? goalDifference;
  final int? goalsFor;
  final int? goalsAgainst;

  factory Standing.fromJson(Map<String, dynamic> json) => Standing(
    rank: (json['rank'] as num?)?.toInt() ?? 0,
    team: Team.fromJson(
      (json['team'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    played: (json['played'] as num?)?.toInt() ?? 0,
    points: (json['points'] as num?)?.toInt() ?? 0,
    isMasry: json['isMasry'] as bool? ?? false,
    goalDifference: (json['goalDifference'] as num?)?.toInt(),
    goalsFor: (json['goalsFor'] as num?)?.toInt(),
    goalsAgainst: (json['goalsAgainst'] as num?)?.toInt(),
  );
}

class Player {
  const Player({
    required this.id,
    required this.name,
    required this.position,
    this.number,
    this.photoUrl,
    this.nationality,
    this.goals,
    this.appearances,
  });

  final int id;
  final String name;
  final String position;
  final int? number;
  final String? photoUrl;
  final String? nationality;
  final int? goals;
  final int? appearances;

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '—',
    position: json['position'] as String? ?? '—',
    number: (json['number'] as num?)?.toInt(),
    photoUrl: json['photoUrl'] as String?,
    nationality: json['nationality'] as String?,
    goals: (json['goals'] as num?)?.toInt(),
    appearances: (json['appearances'] as num?)?.toInt(),
  );
}

class NewsItem {
  const NewsItem({
    required this.id,
    required this.title,
    required this.url,
    required this.sourceName,
    this.imageUrl,
    this.publishedText,
  });

  final String id;
  final String title;
  final String url;
  final String sourceName;
  final String? imageUrl;
  final String? publishedText;

  factory NewsItem.fromJson(Map<String, dynamic> json) => NewsItem(
    id: json['id'] as String? ?? json['url'] as String? ?? '',
    title: json['title'] as String? ?? '—',
    url: json['url'] as String? ?? '',
    sourceName: json['sourceName'] as String? ?? 'المصدر',
    imageUrl: json['imageUrl'] as String?,
    publishedText: json['publishedText'] as String?,
  );
}

class Preferences {
  const Preferences({
    this.username = '',
    this.notificationsEnabled = true,
    this.notifications = const {},
  });

  final String username;
  final bool notificationsEnabled;
  final Map<String, bool> notifications;

  factory Preferences.fromJson(Map<String, dynamic> json) => Preferences(
    username: json['username'] as String? ?? '',
    notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    notifications:
        ((json['notifications'] as Map?)?.cast<String, dynamic>() ?? const {})
            .map((key, value) => MapEntry(key, value == true)),
  );
}

const notificationTypes = <Map<String, String>>[
  {
    'key': 'matchday',
    'label': 'يوم المباراة',
    'hint': 'تذكير قبل انطلاق المباراة',
  },
  {
    'key': 'lineup',
    'label': 'نزول التشكيل',
    'hint': 'أول ما تُعلن تشكيلة الفريق',
  },
  {'key': 'kickoff', 'label': 'بداية المباراة', 'hint': 'صافرة البداية'},
  {'key': 'goal', 'label': 'الأهداف', 'hint': 'هدف لنا أو علينا'},
  {
    'key': 'penalty',
    'label': 'ركلات الجزاء',
    'hint': 'احتساب أو تصدي ركلة جزاء',
  },
  {'key': 'card', 'label': 'البطاقات', 'hint': 'صفراء وحمراء'},
  {'key': 'substitution', 'label': 'التبديلات', 'hint': 'كل تبديل في المباراة'},
  {'key': 'injury', 'label': 'الإصابات', 'hint': 'إصابة لاعب داخل الملعب'},
  {'key': 'fulltime', 'label': 'نهاية المباراة', 'hint': 'النتيجة النهائية'},
  {'key': 'news', 'label': 'الأخبار', 'hint': 'أخبار جديدة عن النادي'},
  {
    'key': 'standings',
    'label': 'تحديث جدول الدوري',
    'hint': 'تغيّر ترتيب الفريق',
  },
];
