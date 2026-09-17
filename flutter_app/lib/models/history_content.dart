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
    this.assists = 0,
    this.image,
  });

  final int rank;
  final String name;
  final int apps;
  final int goals;
  final int assists;
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
        'قبل ميلاد النادي بعام واحد، اشتعلت ثورة 1919 ضد الاحتلال البريطاني. من رحم هذه الروح الوطنية خرجت فكرة إنشاء نادٍ لأبناء مصر في بورسعيد، المدينة التي كانت أنديتها كلها تخص الجاليات الأجنبية. حتى اللون الأخضر للنادي مأخوذ من علم الثورة الأخضر الذي رفعه المصريون لأول مرة.',
    image: 'الشرارة - ثورة 1919.webp',
  ),
  HistoryTimeline(
    year: '18 مارس 1920',
    title: 'التأسيس في بورسعيد',
    body:
        'تأسس النادي المصري للألعاب الرياضية على يد مجموعة من أبناء بورسعيد، وترأس أول مجلس إدارة أحمد حسني، السكرتير العام لمجلس بلدية بورسعيد. ضم المجلس مسلمين ومسيحيين دون أي عضو أجنبي، تأكيدًا على أن النادي كيان جامع لكل المصريين، ومن هنا جاء الاسم: «المصري».',
    gold: true,
  ),
  HistoryTimeline(
    year: '1920',
    title: 'الاسم من «قوم يا مصري»',
    body:
        'استلهم المؤسسون اسم النادي من نشيد سيد درويش الوطني «قوم يا مصري.. مصر دايمًا بتناديك»، وصار الاسم إعلانًا صريحًا عن هوية النادي في مدينة كوزموبوليتانية تعج بأندية الأجانب.',
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
        '17 لقبًا متتاليًا في دوري منطقة القناة من 1932 حتى 1948 — رقم قياسي لم يُكسر. هذه الحقبة صنعت أسطورة «النسور الخضراء» في القناة كلها.',
    image: 'إمبراطورية دوري القناة.webp',
    gold: true,
  ),
  HistoryTimeline(
    year: '1933 · 1934 · 1937',
    title: 'ثلاثية كأس السلطان حسين',
    body:
        'توّج المصري بكأس السلطان حسين ثلاث مرات (1932–33، 1933–34، 1936–37)، إضافة إلى وصافة 1937–38، في واحدة من أقوى فترات النادي على الإطلاق.',
  ),
  HistoryTimeline(
    year: '1953 / 1955',
    title: 'ستاد النادي المصري',
    body:
        'بعدما ضاق الملعب القديم بجماهير النادي، بنى المصري استاده الخاص عام 1953 وافتُتح رسميًا عام 1955 — واحد من أقدم ملاعب الأندية في مصر.',
    image: 'ستاد النادي المصري.webp',
  ),
  HistoryTimeline(
    year: '1979–1982',
    title: 'بوشكاش في بورسعيد',
    body:
        'أسطورة ريال مدريد والمجر فرينك بوشكاش تولى تدريب المصري ثلاث سنوات كاملة (1 يوليو 1979 – 30 يونيو 1982) بحسب سجلات Transfermarkt — أشهر اسم عالمي جلس على دكة النادي.',
    image: 'بوشكاش في بورسعيد.webp',
    gold: true,
  ),
  HistoryTimeline(
    year: '1989 · 1992',
    title: 'كأس الاتحاد المصري',
    body:
        'وصافة 1989 ثم التتويج بكأس الاتحاد المصري عام 1992، في حقبة كان فيها المصري رقمًا ثابتًا في المنافسة على الألقاب.',
  ),
  HistoryTimeline(
    year: '1997–98',
    title: 'كأس مصر: اللقب الأغلى',
    body:
        'أهم لقب في تاريخ النادي: كأس مصر موسم 1997–98، اللقب الوحيد للمصري في البطولة حتى اليوم بعد تسع مرات وصافة (1927، 1945، 1947، 1954، 1957، 1983، 1984، 1989، 2017).',
    gold: true,
  ),
  HistoryTimeline(
    year: '1999',
    title: 'برونزية عربية',
    body:
        'الميدالية البرونزية في كأس الكؤوس العربية 1999، أول حضور عربي بارز للنادي.',
  ),
  HistoryTimeline(
    year: '1 فبراير 2012',
    title: 'كارثة استاد بورسعيد',
    body:
        'أسوأ يوم في تاريخ الكرة المصرية: 72 قتيلًا ومئات المصابين عقب مباراة المصري والأهلي. أُلغي ما تبقى من موسم 2011–12، وقرر المصري عدم المشاركة في موسم 2012–13 احترامًا لأرواح الضحايا وأسرهم، رغم حصوله على حكم من محكمة التحكيم الرياضية (CAS) يؤكد حقه في المشاركة.',
  ),
  HistoryTimeline(
    year: '2013–14',
    title: 'العودة إلى الملاعب',
    body:
        'عاد المصري للمشاركة في الدوري الممتاز موسم 2013–14 بعد غياب موسمين، وسط تذبذب في النتائج لكنه حافظ على مكانه بين الكبار.',
  ),
  HistoryTimeline(
    year: '2015–16',
    title: 'العودة إلى إفريقيا',
    body:
        'تحت قيادة حسام حسن ومع سياسة الاعتماد على الشباب، أنهى المصري الموسم في المركز الرابع وتأهل لكأس الكونفدرالية الإفريقية بعد 14 عامًا من الغياب عن البطولات القارية.',
    image: 'العودة إلى إفريقيا.webp',
  ),
  HistoryTimeline(
    year: '2016–17',
    title: 'وصافة كأس مصر',
    body:
        'وصل المصري إلى نهائي كأس مصر مجددًا في موسم 2016–17، تاسع وصافة في تاريخه بالبطولة.',
  ),
  HistoryTimeline(
    year: '2022–23',
    title: 'وصافة كأس الرابطة',
    body: 'بلوغ نهائي كأس الرابطة المصرية في نسخة 2022–23.',
  ),
  HistoryTimeline(
    year: '2025–26',
    title: 'كأس الرابطة: لقب جديد',
    body:
        'تتويج المصري بكأس الرابطة المصرية موسم 2025–26 (Transfermarkt · قسم الألقاب)، أحدث لقب في خزائن النادي.',
    gold: true,
  ),
];

const historyHonours = <HistoryHonour>[
  HistoryHonour(
    title: 'كأس مصر',
    wins: ['1997–98'],
    runnersUp: [
      '1926–27',
      '1944–45',
      '1946–47',
      '1953–54',
      '1956–57',
      '1982–83',
      '1983–84',
      '1988–89',
      '2016–17',
    ],
  ),
  HistoryHonour(
    title: 'كأس السلطان حسين',
    wins: ['1932–33', '1933–34', '1936–37'],
    runnersUp: ['1937–38'],
  ),
  HistoryHonour(
    title: 'كأس الاتحاد المصري',
    wins: ['1992'],
    runnersUp: ['1989'],
    note: 'رقم قياسي مشترك',
  ),
  HistoryHonour(
    title: 'كأس الرابطة المصرية',
    wins: ['2025–26'],
    runnersUp: ['2022–23'],
  ),
  HistoryHonour(
    title: 'دوري منطقة القناة',
    wins: [
      '1932',
      '1933',
      '1934',
      '1935',
      '1936',
      '1937',
      '1938',
      '1939',
      '1940',
      '1941',
      '1942',
      '1943',
      '1944',
      '1945',
      '1946',
      '1947',
      '1948',
    ],
    note: '17 لقبًا — رقم قياسي',
  ),
];

const historyCoaches = <HistoryCoach>[
  HistoryCoach(
    name: 'أحمد سامي',
    from: '02/09/2026',
    to: 'حتى الآن',
    matches: 1,
    points: '0.00',
    image: 'أحمد سامي.webp',
  ),
  HistoryCoach(
    name: 'عماد النحاس',
    from: '07/04/2026',
    to: '02/09/2026',
    matches: 10,
    points: '1.70',
    image: 'عماد النحاس.webp',
  ),
  HistoryCoach(
    name: 'نبيل الكوكي',
    from: '01/07/2025',
    to: '07/04/2026',
    matches: 40,
    points: '1.63',
    image: 'نبيل الكوكي.webp',
  ),
  HistoryCoach(
    name: 'أنيس بوجلبان',
    from: '24/02/2025',
    to: '18/05/2025',
    matches: 10,
    points: '1.50',
    image: 'أنيس بوجلبان.webp',
  ),
  HistoryCoach(
    name: 'علي ماهر',
    from: '27/07/2023',
    to: '23/02/2025',
    matches: 67,
    points: '1.72',
    image: 'علي ماهر.webp',
  ),
  HistoryCoach(
    name: 'ميمي عبد الرازق',
    from: '07/05/2023',
    to: '27/07/2023',
    matches: 7,
    points: '1.57',
    image: 'ميمي عبد الرازق.webp',
  ),
  HistoryCoach(
    name: 'حسام حسن',
    from: '14/12/2022',
    to: '07/05/2023',
    matches: 22,
    points: '1.50',
    image: 'حسام حسن.webp',
  ),
  HistoryCoach(
    name: 'إيهاب جلال',
    from: '08/09/2022',
    to: '03/12/2022',
    matches: 5,
    points: '1.00',
    image: 'إيهاب جلال.webp',
  ),
  HistoryCoach(
    name: 'حسام حسن',
    from: '29/05/2022',
    to: '31/08/2022',
    matches: 15,
    points: '1.60',
    image: 'حسام حسن.webp',
  ),
  HistoryCoach(
    name: 'معين الشعباني',
    from: '12/09/2021',
    to: '29/05/2022',
    matches: 36,
    points: '1.22',
    image: 'معين الشعباني.webp',
  ),
  HistoryCoach(
    name: 'علي ماهر',
    from: '01/09/2020',
    to: '04/09/2021',
    matches: 51,
    points: '1.63',
    image: 'علي ماهر.webp',
  ),
  HistoryCoach(
    name: 'طارق العشري',
    from: '21/02/2020',
    to: '31/08/2020',
    matches: 6,
    points: '0.33',
    image: 'طارق العشري.webp',
  ),
  HistoryCoach(
    name: 'إيهاب جلال',
    from: '16/12/2018',
    to: '20/02/2020',
    matches: 49,
    points: '1.65',
    image: 'إيهاب جلال.webp',
  ),
  HistoryCoach(
    name: 'مصطفى يونس',
    from: '22/11/2018',
    to: '16/12/2018',
    matches: 6,
    points: '0.83',
    image: 'مصطفى يونس.webp',
  ),
  HistoryCoach(
    name: 'حسام حسن',
    from: '25/07/2015',
    to: '29/10/2018',
    matches: 139,
    points: '1.74',
    image: 'حسام حسن.webp',
  ),
  HistoryCoach(
    name: 'مختار مختار',
    from: '29/04/2015',
    to: '13/07/2015',
    matches: 13,
    points: '1.46',
    image: 'مختار مختار.webp',
  ),
  HistoryCoach(
    name: 'خوانخو ماكيدا',
    from: '21/12/2014',
    to: '28/04/2015',
    matches: 13,
    points: '1.08',
    image: 'خوانخو ماكيدا.webp',
  ),
  HistoryCoach(
    name: 'طارق يحيى',
    from: '14/07/2014',
    to: '16/12/2014',
    matches: 13,
    points: '1.31',
    image: 'طارق يحيى.webp',
  ),
  HistoryCoach(
    name: 'أنور سلامة',
    from: '22/01/2014',
    to: '16/05/2014',
    matches: 15,
    points: '1.40',
    image: 'أنور سلامة.webp',
  ),
  HistoryCoach(
    name: 'صبري المنياوي',
    from: '18/08/2013',
    to: '21/01/2014',
    matches: 4,
    points: '0.50',
    image: 'صبري المنياوي.webp',
  ),
  HistoryCoach(
    name: 'حسام حسن',
    from: '15/01/2012',
    to: '01/02/2012',
    matches: 3,
    points: '2.33',
    image: 'حسام حسن.webp',
  ),
  HistoryCoach(
    name: 'طلعت يوسف',
    from: '17/07/2011',
    to: '15/01/2012',
    matches: 12,
    points: '1.58',
    image: 'طلعت يوسف.webp',
  ),
  HistoryCoach(
    name: 'طه بصري',
    from: '04/05/2011',
    to: '13/07/2011',
    matches: 11,
    points: '1.82',
    image: 'طه بصري.webp',
  ),
  HistoryCoach(
    name: 'طارق الصاوي',
    from: '06/04/2011',
    to: '04/05/2011',
    matches: 4,
    points: '0.75',
    image: 'طارق الصاوي.webp',
  ),
  HistoryCoach(
    name: 'آلان جايجر',
    from: '16/12/2010',
    to: '06/04/2011',
    matches: 2,
    points: '1.50',
    image: 'آلان جايجر.webp',
  ),
  HistoryCoach(
    name: 'مختار مختار',
    from: '01/06/2010',
    to: '26/11/2010',
    matches: 12,
    points: '1.33',
    image: 'مختار مختار.webp',
  ),
  HistoryCoach(
    name: 'محمد حلمي',
    from: '04/05/2010',
    to: '26/05/2010',
    matches: 4,
    points: '1.25',
    image: 'محمد حلمي.webp',
  ),
  HistoryCoach(
    name: 'تيو بوكر',
    from: '29/01/2010',
    to: '04/05/2010',
    matches: 13,
    points: '1.46',
    image: 'تيو بوكر.webp',
  ),
  HistoryCoach(
    name: 'أنور سلامة',
    from: '29/08/2009',
    to: '24/01/2010',
    matches: 12,
    points: '0.83',
    image: 'أنور سلامة.webp',
  ),
  HistoryCoach(
    name: 'برتالان بيكسكي',
    from: '11/02/2009',
    to: '29/08/2009',
    matches: 17,
    points: '1.12',
    image: 'برتالان بيكسكي.webp',
  ),
  HistoryCoach(
    name: 'حسام حسن',
    from: '29/02/2008',
    to: '28/12/2008',
    matches: 27,
    points: '1.41',
    image: 'حسام حسن.webp',
  ),
  HistoryCoach(
    name: 'حلمي طولان',
    from: '01/07/2007',
    to: '01/11/2007',
    matches: 9,
    points: '0.67',
    image: 'حلمي طولان.webp',
  ),
  HistoryCoach(
    name: 'ميمي عبد الرازق',
    from: '01/12/2006',
    to: '01/04/2007',
    matches: 5,
    points: '1.40',
    image: 'ميمي عبد الرازق.webp',
  ),
  HistoryCoach(
    name: 'محمد عمر',
    from: '28/09/2006',
    to: '26/12/2006',
    matches: 4,
    points: '1.00',
    image: 'محمد عمر.webp',
  ),
  HistoryCoach(
    name: 'محمد صلاح',
    from: '30/11/2005',
    to: '30/06/2006',
    matches: 11,
    points: '1.55',
    image: 'محمد صلاح.webp',
  ),
  HistoryCoach(
    name: 'أوتو فيستر',
    from: '01/06/2005',
    to: '21/09/2005',
    matches: 2,
    points: '1.50',
    image: 'أوتو فيستر.webp',
  ),
  HistoryCoach(
    name: 'فاروق جعفر',
    from: '22/12/2003',
    to: '06/11/2004',
    matches: 15,
    points: '1.00',
    image: 'فاروق جعفر.webp',
  ),
  HistoryCoach(
    name: 'برتالان بيكسكي',
    from: '01/07/2003',
    to: '31/12/2003',
    matches: 6,
    points: '1.50',
    image: 'برتالان بيكسكي.webp',
  ),
  HistoryCoach(
    name: 'فؤاد مزوروفيتش',
    from: '01/07/2002',
    to: '30/12/2002',
    matches: 3,
    points: '0.67',
    image: 'فؤاد مزوروفيتش.webp',
  ),
  HistoryCoach(
    name: 'أنور سلامة',
    from: '28/01/2002',
    to: '28/10/2002',
    matches: 6,
    points: '0.67',
    image: 'أنور سلامة.webp',
  ),
  HistoryCoach(
    name: 'طارق سليمان',
    from: '09/12/2001',
    to: '28/01/2002',
    matches: 2,
    points: '0.00',
    image: 'طارق سليمان.webp',
  ),
  HistoryCoach(
    name: 'زيزو',
    from: '27/11/2001',
    to: '01/07/2002',
    matches: 1,
    points: '0.00',
    image: 'زيزو.webp',
  ),
  HistoryCoach(
    name: 'محمود أبو رجيلة',
    from: '01/08/2000',
    to: '26/11/2001',
    matches: 0,
    points: '-',
    image: 'محمود أبو رجيلة.webp',
  ),
  HistoryCoach(
    name: 'فؤاد شعبان',
    from: '01/08/2000',
    to: '26/11/2001',
    matches: 12,
    points: '1.75',
    image: 'فؤاد شعبان.webp',
  ),
  HistoryCoach(
    name: 'أوسكار فولوني',
    from: '01/07/2000',
    to: '30/06/2001',
    matches: 3,
    points: '1.33',
    image: 'أوسكار فولوني.webp',
  ),
  HistoryCoach(
    name: 'زلاتكو كرانيتشار',
    from: '01/02/1999',
    to: '30/06/2000',
    matches: 8,
    points: '0.88',
    image: 'زلاتكو كرانيتشار.webp',
  ),
  HistoryCoach(
    name: 'محسن صالح',
    from: '12/10/1998',
    to: '10/12/1998',
    matches: 4,
    points: '0.75',
    image: 'محسن صالح.webp',
  ),
  HistoryCoach(
    name: 'مايكل كروجر',
    from: '01/01/1998',
    to: '31/10/1998',
    matches: 16,
    points: '1.69',
    image: 'مايكل كروجر.webp',
  ),
  HistoryCoach(
    name: 'فؤاد شعبان',
    from: '31/03/1997',
    to: '28/06/1997',
    matches: 1,
    points: '1.00',
    image: 'فؤاد شعبان.webp',
  ),
  HistoryCoach(
    name: 'آلان هاريس',
    from: '01/11/1996',
    to: '31/03/1997',
    matches: 4,
    points: '0.25',
    image: 'آلان هاريس.webp',
  ),
  HistoryCoach(
    name: 'أحمد رفعت',
    from: '09/07/1996',
    to: '26/10/1996',
    matches: 0,
    points: '-',
    image: 'أحمد رفعت.webp',
  ),
  HistoryCoach(
    name: 'كور بوت',
    from: '01/07/1994',
    to: '30/06/1995',
    matches: 10,
    points: '0.80',
    image: 'كور بوت.webp',
  ),
  HistoryCoach(
    name: 'برتالان بيكسكي',
    from: '19/03/1994',
    to: '30/06/1994',
    matches: 2,
    points: '1.00',
    image: 'برتالان بيكسكي.webp',
  ),
  HistoryCoach(
    name: 'فويتشيك وازاريك',
    from: '01/07/1992',
    to: '30/06/1993',
    matches: 7,
    points: '1.29',
    image: 'فويتشيك وازاريك.webp',
  ),
  HistoryCoach(
    name: 'محمود الجوهري',
    from: '23/08/1991',
    to: '25/10/1991',
    matches: 1,
    points: '1.00',
    image: 'محمود الجوهري.webp',
  ),
  HistoryCoach(
    name: 'فرينك بوشكاش',
    from: '01/07/1979',
    to: '30/06/1982',
    matches: 0,
    points: '-',
    image: 'فرينك بوشكاش.webp',
  ),
];

const historyPresidents = <HistoryPresident>[
  HistoryPresident(
    name: 'أحمد حسني',
    from: '1920',
    to: '1925',
    image: 'أحمد حسني.webp',
    note: 'أول رئيس للنادي وسكرتير عام بلدية بورسعيد',
  ),
  HistoryPresident(
    name: 'محمد الطوبشي',
    from: '1925',
    to: '1930',
    image: 'محمد الطوبشي.webp',
  ),
  HistoryPresident(
    name: 'عوض فاكوسة',
    from: '1930',
    to: '1935',
    image: 'عوض فاكوسة.webp',
  ),
  HistoryPresident(
    name: 'إبراهيم يوسف لحيطة',
    from: '1935',
    to: '1940',
    image: 'إبراهيم يوسف لحيطة.webp',
  ),
  HistoryPresident(
    name: 'عبد الرحمن باشا لطفي',
    from: '1940',
    to: '1964',
    image: 'عبد الرحمن باشا لطفي.webp',
    note: 'أطول فترة رئاسة متصلة: 24 عامًا',
  ),
  HistoryPresident(
    name: 'اللواء خليل ترمان',
    from: '1964',
    to: '1967',
    image: 'اللواء خليل ترمان.webp',
  ),
  HistoryPresident(
    name: 'عبد الحميد حسين',
    from: '1971',
    to: '1974',
    image: 'عبد الحميد حسين.webp',
  ),
  HistoryPresident(
    name: 'محمد موسى',
    from: '1974',
    to: '1978',
    image: 'محمد موسى.webp',
  ),
  HistoryPresident(
    name: 'أحمد فؤاد المخزنجي',
    from: 'فبراير 1978',
    to: 'ديسمبر 1979',
    image: 'أحمد فؤاد المخزنجي.webp',
  ),
  HistoryPresident(
    name: 'اللواء إبراهيم المر',
    from: 'مايو 1980',
    to: 'أغسطس 1980',
    image: 'اللواء إبراهيم المر.webp',
  ),
  HistoryPresident(
    name: 'السيد متولي',
    from: '1980',
    to: '1988',
    image: 'السيد متولي.webp',
  ),
  HistoryPresident(
    name: 'اللواء إبراهيم المر',
    from: '1988',
    to: '1989',
    image: 'اللواء إبراهيم المر.webp',
  ),
  HistoryPresident(
    name: 'السيد متولي',
    from: '1989',
    to: '1991',
    image: 'السيد متولي.webp',
  ),
  HistoryPresident(
    name: 'عادل الجزار',
    from: 'مارس 1991',
    to: 'مايو 1991',
    image: 'عادل الجزار.webp',
  ),
  HistoryPresident(
    name: 'السيد متولي',
    from: '1991',
    to: '1997',
    image: 'السيد متولي.webp',
    note: 'في عهده تُوّج النادي بكأس الاتحاد 1992',
  ),
  HistoryPresident(
    name: 'كامل أبو علي',
    from: 'أغسطس 1997',
    to: 'ديسمبر 1997',
    image: 'كامل أبو علي.webp',
  ),
  HistoryPresident(
    name: 'عبد الوهاب قوطة',
    from: 'يناير 1998',
    to: '2002',
    image: 'عبد الوهاب قوطة.webp',
  ),
  HistoryPresident(
    name: 'السيد متولي',
    from: 'سبتمبر 2002',
    to: '2008',
    image: 'السيد متولي.webp',
    note: 'قضى نحو 26 عامًا في الرئاسة عبر فترات متفرقة',
  ),
  HistoryPresident(
    name: 'علي فرج الله',
    from: '2008',
    to: '2009',
    image: 'علي فرج الله.webp',
  ),
  HistoryPresident(
    name: 'كامل أبو علي',
    from: '2009',
    to: '2013',
    image: 'كامل أبو علي.webp',
  ),
  HistoryPresident(
    name: 'ياسر يحيى',
    from: '2014',
    to: 'يوليو 2015',
    image: 'ياسر يحيى.webp',
  ),
  HistoryPresident(
    name: 'سمير حلبية',
    from: '23 يوليو 2015',
    to: '2022',
    image: 'سمير حلبية.webp',
  ),
  HistoryPresident(
    name: 'كامل أبو علي',
    from: '2022',
    to: 'حتى الآن',
    image: 'كامل أبو علي.webp',
    note: 'حقق المصري في عهده كأس عاصمة مصر',
  ),
];

const historyTopScorers = <HistoryRecord>[
  HistoryRecord(
    rank: 1,
    name: 'السيد الضظوي',
    apps: 0,
    goals: 89,
    image: 'السيد الضظوي.webp',
  ),
  HistoryRecord(
    rank: 2,
    name: 'مسعد نور',
    apps: 0,
    goals: 87,
    image: 'مسعد نور.webp',
  ),
  HistoryRecord(
    rank: 3,
    name: 'محمد شاهين',
    apps: 0,
    goals: 64,
    image: 'محمد شاهين.webp',
  ),
  HistoryRecord(
    rank: 4,
    name: 'جمال جودة',
    apps: 0,
    goals: 56,
    image: 'جمال جودة.webp',
  ),
  HistoryRecord(
    rank: 5,
    name: 'محمد بدوي',
    apps: 0,
    goals: 45,
    image: 'محمد بدوي.webp',
  ),
  HistoryRecord(
    rank: 6,
    name: 'أحمد جمعة',
    apps: 0,
    goals: 39,
    image: 'أحمد جمعة.webp',
  ),
  HistoryRecord(
    rank: 7,
    name: 'إبراهيم المصري',
    apps: 0,
    goals: 32,
    image: 'إبراهيم المصري.webp',
  ),
  HistoryRecord(
    rank: 8,
    name: 'عوض الحارثي',
    apps: 0,
    goals: 28,
    image: 'عوض الحارثي.webp',
  ),
  HistoryRecord(rank: 9, name: 'إينو', apps: 0, goals: 24, image: 'إينو.webp'),
  HistoryRecord(
    rank: 10,
    name: 'ياسر محمد',
    apps: 0,
    goals: 23,
    image: 'ياسر محمد.webp',
  ),
];

const historyLegends = <HistoryPerson>[
  HistoryPerson(
    name: 'السيد الضظوي',
    role: 'مهاجم',
    era: 'السبعينيات',
    note:
        'هدّاف النادي التاريخي برصيد 89 هدفًا في الدوري — رقم صمد لعقود ولم يقترب منه أحد.',
    image: 'السيد الضظوي.webp',
  ),
  HistoryPerson(
    name: 'مسعد نور «الكاستن»',
    role: 'جناح',
    era: 'السبعينيات – الثمانينيات',
    note:
        'رمز المصري الأشهر وثاني هدافيه بـ 87 هدفًا، وقائد جيل كامل في ذاكرة جماهير بورسعيد.',
    image: 'مسعد نور - الكاستن.webp',
  ),
  HistoryPerson(
    name: 'عبد الرحمن فوزي',
    role: 'مهاجم',
    era: 'الثلاثينيات',
    note:
        'نجم المصري في ثلاثينيات القرن الماضي، وصاحب أول هدفين لمصر في كأس العالم 1934.',
    image: 'عبد الرحمن فوزي.webp',
  ),
  HistoryPerson(
    name: 'حلمي أبو المعاطي',
    role: 'لاعب وسط',
    era: 'الخمسينيات – الستينيات',
    note:
        'من رموز جيل الستينيات الذهبي الذي جعل المصري مصنعًا لكبار نجوم الكرة المصرية.',
    image: 'حلمي أبو المعاطي.webp',
  ),
  HistoryPerson(
    name: 'محسن صالح',
    role: 'لاعب وسط',
    era: 'السبعينيات',
    note:
        'ابن بورسعيد الذي بدأ مسيرته في المصري قبل أن يصبح من أبرز أسماء الكرة المصرية لاعبًا ومدربًا.',
    image: 'محسن صالح.webp',
  ),
  HistoryPerson(
    name: 'إبراهيم المصري «مارادونا بورسعيد»',
    role: 'صانع ألعاب',
    era: 'التسعينيات',
    note:
        'أسطورة التسعينيات ومهاريّ الفريق الأول، لُقّب بمارادونا بورسعيد لمهاراته الاستثنائية.',
    image: 'إبراهيم المصري - مارادونا بورسعيد.webp',
  ),
  HistoryPerson(
    name: 'محمد شاهين',
    role: 'مهاجم',
    era: 'الثمانينيات – التسعينيات',
    note:
        'ثالث هدافي النادي في الدوري بـ 64 هدفًا، وأحد رموز خط هجوم النسور الخضراء.',
    image: 'محمد شاهين.webp',
  ),
  HistoryPerson(
    name: 'إينو',
    role: 'مهاجم',
    era: 'الألفينات',
    note:
        'المهاجم النيجيري الذي أصبح من أشهر المحترفين الأجانب في تاريخ النادي بأهدافه الحاسمة.',
    image: 'إينو.webp',
  ),
];

const historyAppearances = <HistoryRecord>[
  HistoryRecord(
    rank: 1,
    name: 'عمرو موسى',
    apps: 317,
    goals: 9,
    assists: 8,
    image: 'عمرو موسى.webp',
  ),
  HistoryRecord(
    rank: 2,
    name: 'كريم العراقي',
    apps: 287,
    goals: 5,
    assists: 11,
    image: 'كريم العراقي.webp',
  ),
  HistoryRecord(
    rank: 3,
    name: 'فريد شوقي',
    apps: 246,
    goals: 2,
    assists: 12,
    image: 'فريد شوقي.webp',
  ),
  HistoryRecord(
    rank: 4,
    name: 'حسن علي',
    apps: 210,
    goals: 18,
    assists: 7,
    image: 'حسن علي.webp',
  ),
  HistoryRecord(
    rank: 5,
    name: 'أسامة عزب',
    apps: 189,
    goals: 7,
    assists: 5,
    image: 'أسامة عزب.webp',
  ),
  HistoryRecord(
    rank: 6,
    name: 'أحمد جمعة',
    apps: 177,
    goals: 54,
    assists: 9,
    image: 'أحمد جمعة.webp',
  ),
  HistoryRecord(
    rank: 7,
    name: 'محمد جرندو',
    apps: 167,
    goals: 27,
    assists: 15,
    image: 'محمد جرندو.webp',
  ),
  HistoryRecord(
    rank: 8,
    name: 'أحمد مسعود',
    apps: 159,
    goals: 0,
    assists: 0,
    image: 'أحمد مسعود.webp',
  ),
  HistoryRecord(
    rank: 9,
    name: 'عاشور الأدهم',
    apps: 153,
    goals: 16,
    assists: 3,
    image: 'عاشور الأدهم.webp',
  ),
  HistoryRecord(
    rank: 10,
    name: 'أحمد شديد قناوي',
    apps: 152,
    goals: 13,
    assists: 19,
    image: 'أحمد شديد قناوي.webp',
  ),
  HistoryRecord(
    rank: 11,
    name: 'إيمكا كريستيان إيزي',
    apps: 150,
    goals: 2,
    assists: 5,
    image: 'إيمكا كريستيان إيزي.webp',
  ),
  HistoryRecord(
    rank: 12,
    name: 'عمرو السعداوي',
    apps: 124,
    goals: 4,
    assists: 7,
    image: 'عمرو السعداوي.webp',
  ),
  HistoryRecord(
    rank: 13,
    name: 'إسلام صلاح',
    apps: 118,
    goals: 7,
    assists: 1,
    image: 'إسلام صلاح.webp',
  ),
  HistoryRecord(
    rank: 14,
    name: 'أوستن أموتو',
    apps: 114,
    goals: 25,
    assists: 6,
    image: 'أوستن أموتو.webp',
  ),
  HistoryRecord(
    rank: 15,
    name: 'أحمد فوزي',
    apps: 113,
    goals: 5,
    assists: 4,
    image: 'أحمد فوزي.webp',
  ),
  HistoryRecord(
    rank: 16,
    name: 'عبد الرحيم دغموم',
    apps: 113,
    goals: 12,
    assists: 13,
    image: 'عبد الرحيم دغموم.webp',
  ),
  HistoryRecord(
    rank: 17,
    name: 'محمود حمادة',
    apps: 109,
    goals: 6,
    assists: 6,
    image: 'محمود حمادة.webp',
  ),
  HistoryRecord(
    rank: 18,
    name: 'أحمد أيمن منصور',
    apps: 107,
    goals: 3,
    assists: 8,
    image: 'أحمد أيمن منصور.webp',
  ),
  HistoryRecord(
    rank: 19,
    name: 'أحمد ياسر',
    apps: 103,
    goals: 15,
    assists: 10,
    image: 'أحمد ياسر.webp',
  ),
  HistoryRecord(
    rank: 20,
    name: 'أحمد شوشة',
    apps: 101,
    goals: 1,
    assists: 6,
    image: 'أحمد شوشة.webp',
  ),
];

const historyIdentity = <HistoryIdentity>[
  HistoryIdentity(
    title: 'الشعار',
    body:
        'نسر حورس فرعوني أخضر يحمل قرص الشمس فوق رأسه بين جناحين مرفوعين، ومنه جاء لقب النسور الخضراء.',
  ),
  HistoryIdentity(
    title: 'الألوان',
    body: 'الأخضر والأبيض، مأخوذان من علم مصر بعد ثورة 1919 كرمز للوطنية.',
  ),
  HistoryIdentity(
    title: 'الملعب',
    body:
        'ستاد النادي المصري بُني عام 1953 وافتتح عام 1955، وكان الفريق يلعب أيضًا على استاد بورسعيد.',
  ),
  HistoryIdentity(
    title: 'مجمع السيد متولي',
    body:
        'مركز تدريب النادي بملعبين عشبيين للفريق الأول وقطاعات الناشئين، جُدد عام 2011.',
  ),
  HistoryIdentity(
    title: 'راديو المصري',
    body:
        'المصري إف إم أول محطة إذاعية في مصر تابعة لنادٍ، وانطلقت عبر الإنترنت.',
  ),
  HistoryIdentity(
    title: 'ألعاب أخرى',
    body: 'كرة يد، ألعاب قوى، سباحة، جمباز، بلياردو، تنس طاولة وهوكي ميدان.',
  ),
];

const historyGallery = <String>[
  'فريق المصري بطل كأس عاصمة مصر 2026.webp',
  'لحظة رفع كأس عاصمة مصر 2026.webp',
  'فرحة اللاعبين بعد صافرة النهاية.webp',
  'تيفو جمهور المصري في المدرجات.webp',
];

const historySources = <Map<String, String>>[
  {
    'label': 'FilGoal — كأس عاصمة مصر',
    'url': 'https://www.filgoal.com/championships/1527',
  },
  {
    'label': 'Transfermarkt — El Masry SC',
    'url': 'https://www.transfermarkt.com/el-masry-sc/startseite/verein/9094',
  },
  {
    'label': 'Transfermarkt — سجل المدربين',
    'url':
        'https://www.transfermarkt.com/el-masry-sc/mitarbeiterhistorie/verein/9094',
  },
  {
    'label': 'ويكيبيديا — Al Masry SC',
    'url': 'https://en.wikipedia.org/wiki/Al_Masry_SC',
  },
  {
    'label': 'ويكيميديا كومنز — الصور التاريخية',
    'url': 'https://commons.wikimedia.org/',
  },
];
