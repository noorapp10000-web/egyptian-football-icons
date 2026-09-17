import { HISTORY_PHOTOS } from "./history-photos";

export const PRESIDENT_PHOTOS: Record<string, string> = { ...HISTORY_PHOTOS.presidents };

export type TopScorer = {
  rank: number;
  name: string;
  goals: number;
  photo: string | null;
};

// المصدر: ويكيبيديا — الأكثر تهديفًا للنادي المصري في الدوري (آخر تحديث 30 مايو 2019)
export const TOP_SCORERS: TopScorer[] = [
  { rank: 1, name: "السيد الضظوي", goals: 89, photo: HISTORY_PHOTOS.scorers["السيد الضظوي"] },
  { rank: 2, name: "مسعد نور", goals: 87, photo: HISTORY_PHOTOS.scorers["مسعد نور"] },
  { rank: 3, name: "محمد شاهين", goals: 64, photo: HISTORY_PHOTOS.scorers["محمد شاهين"] },
  { rank: 4, name: "جمال جودة", goals: 56, photo: HISTORY_PHOTOS.scorers["جمال جودة"] },
  { rank: 5, name: "محمد بدوي", goals: 45, photo: HISTORY_PHOTOS.scorers["محمد بدوي"] },
  { rank: 6, name: "أحمد جمعة", goals: 39, photo: HISTORY_PHOTOS.scorers["أحمد جمعة"] },
  { rank: 7, name: "إبراهيم المصري", goals: 32, photo: HISTORY_PHOTOS.scorers["إبراهيم المصري"] },
  { rank: 8, name: "عوض الحارثي", goals: 28, photo: null },
  { rank: 9, name: "إينو", goals: 24, photo: HISTORY_PHOTOS.scorers["إينو"] },
  { rank: 10, name: "ياسر محمد", goals: 23, photo: null },
];

export type Legend = {
  name: string;
  role: string;
  era?: string;
  note: string;
  photo: string | null;
};

// أساطير النادي المصري: رموز صنعت تاريخ النسور الخضراء عبر الحقب.
export const LEGENDS: Legend[] = [
  {
    name: "السيد الضظوي",
    role: "مهاجم",
    era: "السبعينيات",
    note: "هدّاف النادي التاريخي برصيد 89 هدفًا في الدوري — رقم صمد لعقود ولم يقترب منه أحد.",
    photo: HISTORY_PHOTOS.legends["السيد الضظوي"],
  },
  {
    name: "مسعد نور «الكاستن»",
    role: "جناح",
    era: "السبعينيات – الثمانينيات",
    note: "رمز المصري الأشهر وثاني هدافيه بـ 87 هدفًا، وقائد جيل كامل في ذاكرة جماهير بورسعيد.",
    photo: HISTORY_PHOTOS.legends["مسعد نور «الكاستن»"],
  },
  {
    name: "عبد الرحمن فوزي",
    role: "مهاجم",
    era: "الثلاثينيات",
    note: "نجم المصري في ثلاثينيات القرن الماضي، وصاحب أول هدفين لمصر في كأس العالم 1934.",
    photo: HISTORY_PHOTOS.legends["عبد الرحمن فوزي"],
  },
  {
    name: "حلمي أبو المعاطي",
    role: "لاعب وسط",
    era: "الخمسينيات – الستينيات",
    note: "من رموز جيل الستينيات الذهبي الذي جعل المصري مصنعًا لكبار نجوم الكرة المصرية.",
    photo: null,
  },
  {
    name: "محسن صالح",
    role: "لاعب وسط",
    era: "السبعينيات",
    note: "ابن بورسعيد الذي بدأ مسيرته في المصري قبل أن يصبح من أبرز أسماء الكرة المصرية لاعبًا ومدربًا.",
    photo: HISTORY_PHOTOS.legends["محسن صالح"],
  },
  {
    name: "إبراهيم المصري «مارادونا بورسعيد»",
    role: "صانع ألعاب",
    era: "التسعينيات",
    note: "أسطورة التسعينيات ومهاريّ الفريق الأول، لُقّب بمارادونا بورسعيد لمهاراته الاستثنائية.",
    photo: HISTORY_PHOTOS.legends["إبراهيم المصري «مارادونا بورسعيد»"],
  },
  {
    name: "محمد شاهين",
    role: "مهاجم",
    era: "الثمانينيات – التسعينيات",
    note: "ثالث هدافي النادي في الدوري بـ 64 هدفًا، وأحد رموز خط هجوم النسور الخضراء.",
    photo: HISTORY_PHOTOS.legends["محمد شاهين"],
  },
  {
    name: "إينو",
    role: "مهاجم",
    era: "الألفينات",
    note: "المهاجم النيجيري الذي أصبح من أشهر المحترفين الأجانب في تاريخ النادي بأهدافه الحاسمة.",
    photo: HISTORY_PHOTOS.legends["إينو"],
  },
];
