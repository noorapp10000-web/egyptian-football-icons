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
  final String? kickoffText;
  final int? homeScore;
  final int? awayScore;
  final String? venue;

  bool get isPlayed => homeScore != null && awayScore != null;
  bool get isLive => status == 'live';

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
    homeScore: (json['homeScore'] as num?)?.toInt(),
    awayScore: (json['awayScore'] as num?)?.toInt(),
    venue: json['venue'] as String?,
  );
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
