class HistoryTimeline {
  const HistoryTimeline({
    required this.year,
    required this.title,
    required this.body,
    this.image,
    this.gold = false,
  });

  final String year;
  final String title;
  final String body;
  final String? image;
  final bool gold;
}

class HistoryHonour {
  const HistoryHonour({
    required this.title,
    required this.wins,
    this.runnersUp = const [],
    this.note,
  });

  final String title;
  final List<String> wins;
  final List<String> runnersUp;
  final String? note;
}

class HistoryCoach {
  const HistoryCoach({
    required this.name,
    required this.from,
    required this.to,
    required this.matches,
    required this.points,
    this.image,
  });

  final String name;
  final String from;
  final String to;
  final int matches;
  final String points;
  final String? image;
}

class HistoryPresident {
  const HistoryPresident({
    required this.name,
    required this.from,
    required this.to,
    this.note,
    this.image,
  });

  final String name;
  final String from;
  final String to;
  final String? note;
  final String? image;
}

class HistoryPerson {
  const HistoryPerson({
    required this.name,
    required this.role,
    required this.note,
    this.image,
    this.era,
  });

  final String name;
  final String role;
  final String note;
  final String? image;
  final String? era;
}

class HistoryRecord {
  const HistoryRecord({
    required this.rank,
    required this.name,
    required this.apps,
    required this.goals,
    this.image,
  });

  final int rank;
  final String name;
  final int apps;
  final int goals;
  final String? image;
}

class HistoryIdentity {
  const HistoryIdentity({required this.title, required this.body});

  final String title;
  final String body;
}

const historyAssetRoot = 'assets/images/history/';

String historyAsset(String name) => '$historyAssetRoot$name';

const historyTimeline = <HistoryTimeline>[
  HistoryTimeline(
    year: '1919',
    title: 'الشرارة: ثورة 1919',
    body:
        'قبل ميلاد النادي بعام واحد، اشتعلت ثورة 1919 ضد الاحتلال البريطاني. من رحم هذه الروح الوطنية خرجت فكرة إنشاء نادٍ لأبناء مصر في بورسعيد، ومنها جاء اللون الأخضر وهوية النسور الخضراء.',
    image: 'الشرارة - ثورة 1919.webp',
  ),
  HistoryTimeline(
    year: '18 مارس 1920',
    title: 'التأسيس في بورسعيد',
    body:
        'تأسس النادي المصري للألعاب الرياضية على يد مجموعة من أبناء بورسعيد، وترأس أول مجلس إدارة أحمد حسني. ضم المجلس مسلمين ومسيحيين دون عضو أجنبي، تأكيدًا على أن النادي كيان جامع لكل المصريين.',
    gold: true,
  ),
  HistoryTimeline(
    year: '1920',
    title: 'الاسم من «قوم يا مصري»',
    body:
        'استلهم المؤسسون اسم النادي من نشيد سيد درويش الوطني «قوم يا مصري.. مصر دايمًا بتناديك»، وصار الاسم إعلانًا صريحًا عن هوية النادي في مدينة بورسعيد.',
    image: 'الاسم من قوم يا مصري.webp',
  ),
  HistoryTimeline(
    year: '1921',
    title: 'شريك في تأسيس اتحاد الكرة',
    body:
        'شارك المصري مع عدد من الأندية المصرية في تأسيس الاتحاد المصري لكرة القدم عام 1921، ليكون من الآباء المؤسسين للعبة في مصر.',
  ),
  HistoryTimeline(
    year: '1926–27',
    title: 'أول نهائي لكأس مصر',
    body:
        'بلغ المصري نهائي كأس مصر مبكرًا جدًا في موسم 1926–27، ليعلن نفسه قوة كروية خارج القاهرة.',
  ),
  HistoryTimeline(
    year: '1932–1948',
    title: 'إمبراطورية دوري القناة',
    body:
        '17 لقبًا متتاليًا في دوري منطقة القناة من 1932 حتى 1948 — رقم قياسي لم يُكسر. هذه الحقبة صنعت أسطورة النسور الخضراء.',
    image: 'إمبراطورية دوري القناة.webp',
    gold: true,
  ),
  HistoryTimeline(
    year: '1933 · 1934 · 1937',
    title: 'ثلاثية كأس السلطان حسين',
    body:
        'توّج المصري بكأس السلطان حسين ثلاث مرات، إضافة إلى وصافة 1937–38، في واحدة من أقوى فترات النادي على الإطلاق.',
  ),
  HistoryTimeline(
    year: '1953 / 1955',
    title: 'ستاد النادي المصري',
    body:
        'بنى المصري استاده الخاص عام 1953 وافتتح رسميًا عام 1955، ليصبح واحدًا من أقدم ملاعب الأندية في مصر.',
    image: 'ستاد النادي المصري.webp',
  ),
  HistoryTimeline(
    year: '1979–1982',
    title: 'بوشكاش في بورسعيد',
    body:
        'أسطورة ريال مدريد والمجر فرينك بوشكاش تولى تدريب المصري ثلاث سنوات كاملة، وهو أشهر اسم عالمي جلس على دكة النادي.',
    image: 'بوشكاش في بورسعيد.webp',
    gold: true,
  ),
  HistoryTimeline(
    year: '1992',
    title: 'كأس الاتحاد المصري',
    body:
        'توج المصري بكأس الاتحاد المصري عام 1992، في حقبة كان فيها رقمًا ثابتًا في المنافسة على الألقاب.',
  ),
  HistoryTimeline(
    year: '1997–98',
    title: 'كأس مصر: اللقب الأغلى',
    body:
        'بلغ المصري نهائي كأس مصر في موسم 1997–98، لتظل البطولة محطة بارزة في ذاكرة جمهور بورسعيد.',
  ),
  HistoryTimeline(
    year: '2002',
    title: 'العودة إلى إفريقيا',
    body:
        'عاد المصري للمشاركة القارية وواصل تثبيت مكانته بين كبار الأندية المصرية.',
    image: 'العودة إلى إفريقيا.webp',
  ),
  HistoryTimeline(
    year: '2018',
    title: 'نهائي كأس مصر',
    body:
        'وصل المصري إلى نهائي كأس مصر مرة أخرى، مؤكدًا استمراره في المنافسة على البطولات.',
  ),
  HistoryTimeline(
    year: '2025–2026',
    title: 'كأس عاصمة مصر',
    body:
        'توج المصري بكأس عاصمة مصر في موسم 2025–2026 بعد الفوز على إنبي في النهائي بثلاثة أهداف نظيفة.',
    image: 'فريق المصري بطل كأس عاصمة مصر 2026.webp',
    gold: true,
  ),
];

const historyHonours = <HistoryHonour>[
  HistoryHonour(
    title: 'دوري منطقة القناة',
    wins: ['1932–33', '1933–34', '1934–35', '1935–36', '1936–37', '1937–38', '1938–39', '1939–40', '1940–41', '1941–42', '1942–43', '1943–44', '1944–45', '1945–46', '1946–47', '1947–48', '1948–49'],
    note: '17 لقبًا متتاليًا — الرقم القياسي التاريخي للنادي.',
  ),
  HistoryHonour(
    title: 'كأس السلطان حسين',
    wins: ['1932–33', '1933–34', '1936–37'],
    runnersUp: ['1937–38'],
  ),
  HistoryHonour(
    title: 'كأس الاتحاد المصري',
    wins: ['1991–92'],
  ),
  HistoryHonour(
    title: 'كأس عاصمة مصر',
    wins: ['2025–26'],
    note: 'الفوز على إنبي 3–0 في النهائي.',
  ),
];

const historyCoaches = <HistoryCoach>[
  HistoryCoach(name: 'أحمد سامي', from: '02/09/2026', to: 'حتى الآن', matches: 1, points: '0.00'),
  HistoryCoach(name: 'عماد النحاس', from: '07/04/2026', to: '02/09/2026', matches: 10, points: '1.70'),
  HistoryCoach(name: 'نبيل الكوكي', from: '01/07/2025', to: '07/04/2026', matches: 40, points: '1.63'),
  HistoryCoach(name: 'أنيس بوجلبان', from: '24/02/2025', to: '18/05/2025', matches: 10, points: '1.50'),
  HistoryCoach(name: 'علي ماهر', from: '27/07/2023', to: '23/02/2025', matches: 67, points: '1.72', image: 'علي ماهر.webp'),
  HistoryCoach(name: 'ميمي عبد الرازق', from: '07/05/2023', to: '27/07/2023', matches: 7, points: '1.57', image: 'ميمي عبد الرازق.webp'),
  HistoryCoach(name: 'حسام حسن', from: '14/12/2022', to: '07/05/2023', matches: 22, points: '1.50', image: 'حسام حسن.webp'),
  HistoryCoach(name: 'إيهاب جلال', from: '08/09/2022', to: '03/12/2022', matches: 5, points: '1.00', image: 'إيهاب جلال.webp'),
  HistoryCoach(name: 'معين الشعباني', from: '12/09/2021', to: '29/05/2022', matches: 36, points: '1.22', image: 'معين الشعباني.webp'),
  HistoryCoach(name: 'طارق العشري', from: '21/02/2020', to: '31/08/2020', matches: 6, points: '0.33', image: 'طارق العشري.webp'),
  HistoryCoach(name: 'مصطفى يونس', from: '22/11/2018', to: '16/12/2018', matches: 6, points: '0.83', image: 'مصطفى يونس.webp'),
  HistoryCoach(name: 'حسام حسن', from: '25/07/2015', to: '29/10/2018', matches: 139, points: '1.74', image: 'حسام حسن.webp'),
  HistoryCoach(name: 'مختار مختار', from: '29/04/2015', to: '13/07/2015', matches: 13, points: '1.46', image: 'مختار مختار.webp'),
  HistoryCoach(name: 'خوانخو ماكيدا', from: '21/12/2014', to: '28/04/2015', matches: 13, points: '1.08', image: 'خوانخو ماكيدا.webp'),
  HistoryCoach(name: 'طارق يحيى', from: '14/07/2014', to: '16/12/2014', matches: 13, points: '1.31', image: 'طارق يحيى.webp'),
  HistoryCoach(name: 'أنور سلامة', from: '22/01/2014', to: '16/05/2014', matches: 15, points: '1.40', image: 'أنور سلامة.webp'),
  HistoryCoach(name: 'صبري المنياوي', from: '18/08/2013', to: '21/01/2014', matches: 4, points: '0.50', image: 'صبري المنياوي.webp'),
  HistoryCoach(name: 'طلعت يوسف', from: '17/07/2011', to: '15/01/2012', matches: 18, points: '1.44', image: 'طلعت يوسف.webp'),
  HistoryCoach(name: 'أوسكار فولوني', from: '2004', to: '2005', matches: 30, points: '1.40', image: 'أوسكار فولوني.webp'),
  HistoryCoach(name: 'فرينك بوشكاش', from: '1979', to: '1982', matches: 90, points: '1.47', image: 'فرينك بوشكاش.webp'),
];

const historyPresidents = <HistoryPresident>[
  HistoryPresident(name: 'أحمد حسني', from: '1920', to: '1925', note: 'أول رئيس للنادي.'),
  HistoryPresident(name: 'محمد الطوبشي', from: '1925', to: '1930'),
  HistoryPresident(name: 'عوض فاكوسة', from: '1930', to: '1935'),
  HistoryPresident(name: 'إبراهيم يوسف لحيطة', from: '1935', to: '1940'),
  HistoryPresident(name: 'عبد الرحمن باشا لطفي', from: '1940', to: '1964', image: 'عبد الرحمن باشا لطفي.webp', note: 'أطول فترة رئاسة متصلة: 24 عامًا.'),
  HistoryPresident(name: 'اللواء خليل ترمان', from: '1964', to: '1967'),
  HistoryPresident(name: 'عبد الحميد حسين', from: '1971', to: '1974'),
  HistoryPresident(name: 'محمد موسى', from: '1974', to: '1978'),
  HistoryPresident(name: 'السيد متولي', from: '1980', to: '2008', image: 'السيد متولي.webp', note: 'فترات رئاسة متفرقة امتدت لنحو 26 عامًا.'),
  HistoryPresident(name: 'كامل أبو علي', from: '1997', to: '1997', image: 'كامل أبو علي.webp'),
  HistoryPresident(name: 'عبد الوهاب قوطة', from: '1998', to: '2002', image: 'عبد الوهاب قوطة.webp'),
  HistoryPresident(name: 'علي فرج الله', from: '2008', to: '2009', image: 'علي فرج الله.webp'),
  HistoryPresident(name: 'كامل أبو علي', from: '2009', to: '2013', image: 'كامل أبو علي.webp'),
  HistoryPresident(name: 'ياسر يحيى', from: '2014', to: '2015', image: 'ياسر يحيى.webp'),
  HistoryPresident(name: 'سمير حلبية', from: '2015', to: '2022', image: 'سمير حلبية.webp'),
  HistoryPresident(name: 'كامل أبو علي', from: '2022', to: 'حتى الآن', image: 'كامل أبو علي.webp', note: 'حقق المصري في عهده كأس عاصمة مصر.'),
];

const historyTopScorers = <HistoryRecord>[
  HistoryRecord(rank: 1, name: 'السيد الضظوي', apps: 116, goals: 89, image: 'السيد الضظوي.webp'),
  HistoryRecord(rank: 2, name: 'مسعد نور', apps: 239, goals: 87, image: 'مسعد نور.webp'),
  HistoryRecord(rank: 3, name: 'محمد شاهين', apps: 184, goals: 64, image: 'محمد شاهين.webp'),
  HistoryRecord(rank: 4, name: 'جمال جودة', apps: 168, goals: 47, image: 'جمال جودة.webp'),
  HistoryRecord(rank: 5, name: 'محمد بدوي', apps: 142, goals: 43, image: 'محمد بدوي.webp'),
  HistoryRecord(rank: 6, name: 'أحمد جمعة', apps: 126, goals: 41, image: 'أحمد جمعة.webp'),
  HistoryRecord(rank: 7, name: 'إبراهيم المصري', apps: 210, goals: 38, image: 'إبراهيم المصري.webp'),
  HistoryRecord(rank: 8, name: 'إينو', apps: 98, goals: 34, image: 'إينو.webp'),
];

const historyLegends = <HistoryPerson>[
  HistoryPerson(name: 'السيد الضظوي', role: 'مهاجم', era: 'الخمسينيات', note: 'أحد أعظم هدافي النادي ورمز من رموز الجيل الذهبي.', image: 'السيد الضظوي.webp'),
  HistoryPerson(name: 'مسعد نور «الكاستن»', role: 'مهاجم', era: 'السبعينيات', note: 'من أشهر هدافي المصري وصاحب حضور لا يُنسى مع النسور.', image: 'مسعد نور - الكاستن.webp'),
  HistoryPerson(name: 'عبد الرحمن فوزي', role: 'أسطورة', era: 'الثلاثينيات', note: 'من أوائل نجوم النادي والكرة المصرية.', image: 'عبد الرحمن فوزي.webp'),
  HistoryPerson(name: 'محسن صالح', role: 'مهاجم ومدرب', era: 'السبعينيات', note: 'لاعب ومدرب ترك بصمة واضحة في تاريخ المصري.', image: 'محسن صالح.webp'),
  HistoryPerson(name: 'إبراهيم المصري «مارادونا بورسعيد»', role: 'صانع ألعاب', era: 'التسعينيات', note: 'أسطورة مهارية لُقّب بمارادونا بورسعيد.', image: 'إبراهيم المصري - مارادونا بورسعيد.webp'),
  HistoryPerson(name: 'محمد شاهين', role: 'مهاجم', era: 'الثمانينيات – التسعينيات', note: 'ثالث هدافي النادي في الدوري بـ64 هدفًا.', image: 'محمد شاهين.webp'),
  HistoryPerson(name: 'إينو', role: 'مهاجم', era: 'الألفينات', note: 'المهاجم النيجيري صاحب الأهداف الحاسمة.', image: 'إينو.webp'),
];

const historyAppearances = <HistoryRecord>[
  HistoryRecord(rank: 1, name: 'عمرو موسى', apps: 268, goals: 12, image: 'عمرو موسى.webp'),
  HistoryRecord(rank: 2, name: 'كريم العراقي', apps: 223, goals: 8, image: 'كريم العراقي.webp'),
  HistoryRecord(rank: 3, name: 'فريد شوقي', apps: 216, goals: 11, image: 'فريد شوقي.webp'),
  HistoryRecord(rank: 4, name: 'حسن علي', apps: 185, goals: 9, image: 'حسن علي.webp'),
  HistoryRecord(rank: 5, name: 'أسامة عزب', apps: 179, goals: 5, image: 'أسامة عزب.webp'),
  HistoryRecord(rank: 6, name: 'أحمد جمعة', apps: 126, goals: 41, image: 'أحمد جمعة.webp'),
  HistoryRecord(rank: 7, name: 'محمد جرندو', apps: 116, goals: 18, image: 'محمد جرندو.webp'),
  HistoryRecord(rank: 8, name: 'أوستن أموتو', apps: 74, goals: 24, image: 'أوستن أموتو.webp'),
];

const historyIdentity = <HistoryIdentity>[
  HistoryIdentity(title: 'الشعار', body: 'نسر حورس فرعوني أخضر يحمل قرص الشمس فوق رأسه بين جناحين مرفوعين، ومنه جاء لقب النسور الخضراء.'),
  HistoryIdentity(title: 'الألوان', body: 'الأخضر والأبيض، مأخوذان من علم مصر بعد ثورة 1919 كرمز للوطنية.'),
  HistoryIdentity(title: 'الملعب', body: 'ستاد النادي المصري بُني عام 1953 وافتتح عام 1955، وكان الفريق يلعب أيضًا على استاد بورسعيد.'),
  HistoryIdentity(title: 'مجمع السيد متولي', body: 'مركز تدريب النادي بملعبين عشبيين للفريق الأول وقطاعات الناشئين، جُدد عام 2011.'),
  HistoryIdentity(title: 'راديو المصري', body: 'المصري إف إم أول محطة إذاعية في مصر تابعة لنادٍ، وانطلقت عبر الإنترنت.'),
  HistoryIdentity(title: 'ألعاب أخرى', body: 'كرة يد، ألعاب قوى، سباحة، جمباز، بلياردو، تنس طاولة وهوكي ميدان.'),
];

const historyGallery = <String>[
  'فريق المصري بطل كأس عاصمة مصر 2026.webp',
  'لحظة رفع كأس عاصمة مصر 2026.webp',
  'فرحة اللاعبين بعد صافرة النهاية.webp',
  'تيفو جمهور المصري في المدرجات.webp',
];

const historySources = <Map<String, String>>[
  {'label': 'FilGoal — كأس عاصمة مصر', 'url': 'https://www.filgoal.com/championships/1527'},
  {'label': 'Transfermarkt — El Masry SC', 'url': 'https://www.transfermarkt.com/el-masry-sc/startseite/verein/9094'},
  {'label': 'Transfermarkt — سجل المدربين', 'url': 'https://www.transfermarkt.com/el-masry-sc/mitarbeiterhistorie/verein/9094'},
  {'label': 'ويكيبيديا — Al Masry SC', 'url': 'https://en.wikipedia.org/wiki/Al_Masry_SC'},
  {'label': 'ويكيميديا كومنز — الصور التاريخية', 'url': 'https://commons.wikimedia.org/'},
];