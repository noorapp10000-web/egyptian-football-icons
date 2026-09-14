// بيانات مستخرجة من Transfermarkt (El Masry SC, معرّف النادي 9094) وويكيبيديا.
export type CoachSpell = {
  name: string;
  nameEn: string;
  from: string;
  to: string;
  matches: number;
  ppm: string;
  photo: string | null;
};

export const COACH_HISTORY: CoachSpell[] = [
  { name: "أحمد سامي", nameEn: "Ahmed Samy", from: "02/09/2026", to: "", matches: 1, ppm: "0.00", photo: null },
  { name: "عماد النحاس", nameEn: "Emad El-Nahhas", from: "07/04/2026", to: "02/09/2026", matches: 10, ppm: "1.70", photo: null },
  { name: "نبيل الكوكي", nameEn: "Nabil Kouki", from: "01/07/2025", to: "07/04/2026", matches: 40, ppm: "1.63", photo: null },
  { name: "أنيس بوجلبان", nameEn: "Anis Boujelbene", from: "24/02/2025", to: "18/05/2025", matches: 10, ppm: "1.50", photo: null },
  { name: "علي ماهر", nameEn: "Ali Maher", from: "27/07/2023", to: "23/02/2025", matches: 67, ppm: "1.72", photo: "https://img.a.transfermarkt.technology/portrait/big/56335-1513324242.jpg" },
  { name: "ميمي عبد الرازق", nameEn: "Mimi Abdelrazek", from: "07/05/2023", to: "27/07/2023", matches: 7, ppm: "1.57", photo: null },
  { name: "حسام حسن", nameEn: "Hossam Hassan", from: "14/12/2022", to: "07/05/2023", matches: 22, ppm: "1.50", photo: "https://img.a.transfermarkt.technology/portrait/big/6120-1773315069.jpg" },
  { name: "إيهاب جلال", nameEn: "Ehab Galal", from: "08/09/2022", to: "03/12/2022", matches: 5, ppm: "1.00", photo: "https://img.a.transfermarkt.technology/portrait/big/34980-1497354574.jpg" },
  { name: "حسام حسن", nameEn: "Hossam Hassan", from: "29/05/2022", to: "31/08/2022", matches: 15, ppm: "1.60", photo: "https://img.a.transfermarkt.technology/portrait/big/6120-1773315069.jpg" },
  { name: "معين الشعباني", nameEn: "Moïn Chaabani", from: "12/09/2021", to: "29/05/2022", matches: 36, ppm: "1.22", photo: "https://img.a.transfermarkt.technology/portrait/big/39485-1757624944.jpeg" },
  { name: "علي ماهر", nameEn: "Ali Maher", from: "01/09/2020", to: "04/09/2021", matches: 51, ppm: "1.63", photo: "https://img.a.transfermarkt.technology/portrait/big/56335-1513324242.jpg" },
  { name: "طارق العشري", nameEn: "Tarek El Ashri", from: "21/02/2020", to: "31/08/2020", matches: 6, ppm: "0.33", photo: "https://img.a.transfermarkt.technology/portrait/big/10509-1547330838.jpg" },
  { name: "إيهاب جلال", nameEn: "Ehab Galal", from: "16/12/2018", to: "20/02/2020", matches: 49, ppm: "1.65", photo: "https://img.a.transfermarkt.technology/portrait/big/34980-1497354574.jpg" },
  { name: "مصطفى يونس", nameEn: "Mostafa Younes", from: "22/11/2018", to: "16/12/2018", matches: 6, ppm: "0.83", photo: null },
  { name: "حسام حسن", nameEn: "Hossam Hassan", from: "25/07/2015", to: "29/10/2018", matches: 139, ppm: "1.74", photo: "https://img.a.transfermarkt.technology/portrait/big/6120-1773315069.jpg" },
  { name: "مختار مختار", nameEn: "Mokhtar Mokhtar", from: "29/04/2015", to: "13/07/2015", matches: 13, ppm: "1.46", photo: null },
  { name: "خوانخو ماكيدا", nameEn: "Juanjo Maqueda", from: "21/12/2014", to: "28/04/2015", matches: 13, ppm: "1.08", photo: "https://img.a.transfermarkt.technology/portrait/big/21352-1519379263.jpg" },
  { name: "طارق يحيى", nameEn: "Tarek Yehia", from: "14/07/2014", to: "16/12/2014", matches: 13, ppm: "1.31", photo: null },
  { name: "أنور سلامة", nameEn: "Anwar Salama", from: "22/01/2014", to: "16/05/2014", matches: 15, ppm: "1.40", photo: "https://img.a.transfermarkt.technology/portrait/big/t_9886_20572_2010_1.jpg" },
  { name: "صبري المنياوي", nameEn: "Sabri El Minyawi", from: "18/08/2013", to: "21/01/2014", matches: 4, ppm: "0.50", photo: "https://img.a.transfermarkt.technology/portrait/big/t_27682_3595_2012_1.jpg" },
  { name: "حسام حسن", nameEn: "Hossam Hassan", from: "15/01/2012", to: "01/02/2012", matches: 3, ppm: "2.33", photo: "https://img.a.transfermarkt.technology/portrait/big/6120-1773315069.jpg" },
  { name: "طلعت يوسف", nameEn: "Talaat Youssef", from: "17/07/2011", to: "15/01/2012", matches: 12, ppm: "1.58", photo: null },
  { name: "طه بصري", nameEn: "Taha Basry", from: "04/05/2011", to: "13/07/2011", matches: 11, ppm: "1.82", photo: null },
  { name: "طارق الصاوي", nameEn: "Tarek El Sawy", from: "06/04/2011", to: "04/05/2011", matches: 4, ppm: "0.75", photo: "https://img.a.transfermarkt.technology/portrait/big/t_18731_9094_2010_1.jpg" },
  { name: "آلان جايجر", nameEn: "Alain Geiger", from: "16/12/2010", to: "06/04/2011", matches: 2, ppm: "1.50", photo: "https://img.a.transfermarkt.technology/portrait/big/538-1594106651.jpg" },
  { name: "مختار مختار", nameEn: "Mokhtar Mokhtar", from: "01/06/2010", to: "26/11/2010", matches: 12, ppm: "1.33", photo: null },
  { name: "محمد حلمي", nameEn: "Mohamed Helmi", from: "04/05/2010", to: "26/05/2010", matches: 4, ppm: "1.25", photo: null },
  { name: "تيو بوكر", nameEn: "Theo Bücker", from: "29/01/2010", to: "04/05/2010", matches: 13, ppm: "1.46", photo: "https://img.a.transfermarkt.technology/portrait/big/_1375795790.jpg" },
  { name: "أنور سلامة", nameEn: "Anwar Salama", from: "29/08/2009", to: "24/01/2010", matches: 12, ppm: "0.83", photo: "https://img.a.transfermarkt.technology/portrait/big/t_9886_20572_2010_1.jpg" },
  { name: "برتالان بيكسكي", nameEn: "Bertalan Bicskei", from: "11/02/2009", to: "29/08/2009", matches: 17, ppm: "1.12", photo: null },
  { name: "حسام حسن", nameEn: "Hossam Hassan", from: "29/02/2008", to: "28/12/2008", matches: 27, ppm: "1.41", photo: "https://img.a.transfermarkt.technology/portrait/big/6120-1773315069.jpg" },
  { name: "حلمي طولان", nameEn: "Helmi Toulan", from: "01/07/2007", to: "01/11/2007", matches: 9, ppm: "0.67", photo: "https://img.a.transfermarkt.technology/portrait/big/t_11448_18268_2010_1.jpg" },
  { name: "ميمي عبد الرازق", nameEn: "Mimi Abdelrazek", from: "01/12/2006", to: "01/04/2007", matches: 5, ppm: "1.40", photo: null },
  { name: "محمد عمر", nameEn: "Mohamed Omar", from: "28/09/2006", to: "26/12/2006", matches: 4, ppm: "1.00", photo: "https://img.a.transfermarkt.technology/portrait/big/t_17962_10957_2010_1.jpg" },
  { name: "محمد صلاح", nameEn: "Mohamed Salah", from: "30/11/2005", to: "30/06/2006", matches: 11, ppm: "1.55", photo: "https://img.a.transfermarkt.technology/portrait/big/38589-1497272254.jpg" },
  { name: "أوتو فيستر", nameEn: "Otto Pfister", from: "01/06/2005", to: "21/09/2005", matches: 2, ppm: "1.50", photo: "https://img.a.transfermarkt.technology/portrait/big/188-1763655347.jpg" },
  { name: "فاروق جعفر", nameEn: "Farouk Gaafar", from: "22/12/2003", to: "06/11/2004", matches: 15, ppm: "1.00", photo: null },
  { name: "برتالان بيكسكي", nameEn: "Bertalan Bicskei", from: "01/07/2003", to: "31/12/2003", matches: 6, ppm: "1.50", photo: null },
  { name: "فؤاد مزوروفيتش", nameEn: "Fuad Muzurovic", from: "01/07/2002", to: "30/12/2002", matches: 3, ppm: "0.67", photo: null },
  { name: "أنور سلامة", nameEn: "Anwar Salama", from: "28/01/2002", to: "28/10/2002", matches: 6, ppm: "0.67", photo: "https://img.a.transfermarkt.technology/portrait/big/t_9886_20572_2010_1.jpg" },
  { name: "طارق سليمان", nameEn: "Tarek Soliman", from: "09/12/2001", to: "28/01/2002", matches: 2, ppm: "0.00", photo: null },
  { name: "زيزو", nameEn: "Zizo", from: "27/11/2001", to: "01/07/2002", matches: 1, ppm: "0.00", photo: null },
  { name: "محمود أبو رجيلة", nameEn: "Mahmoud Abou-Regaila", from: "01/08/2000", to: "26/11/2001", matches: 0, ppm: "-", photo: null },
  { name: "فؤاد شعبان", nameEn: "Fouad Shaaban", from: "01/08/2000", to: "26/11/2001", matches: 12, ppm: "1.75", photo: null },
  { name: "أوسكار فولوني", nameEn: "Oscar Fulloné", from: "01/07/2000", to: "30/06/2001", matches: 3, ppm: "1.33", photo: null },
  { name: "زلاتكو كرانيتشار", nameEn: "Zlatko Kranjcar", from: "01/02/1999", to: "30/06/2000", matches: 8, ppm: "0.88", photo: "https://img.a.transfermarkt.technology/portrait/big/2690-1614597359.jpg" },
  { name: "محسن صالح", nameEn: "Mohsen Saleh", from: "12/10/1998", to: "10/12/1998", matches: 4, ppm: "0.75", photo: null },
  { name: "مايكل كروجر", nameEn: "Michael Krüger", from: "01/01/1998", to: "31/10/1998", matches: 16, ppm: "1.69", photo: "https://img.a.transfermarkt.technology/portrait/big/t_675_8_2009_1.jpg" },
  { name: "فؤاد شعبان", nameEn: "Fouad Shaaban", from: "31/03/1997", to: "28/06/1997", matches: 1, ppm: "1.00", photo: null },
  { name: "آلان هاريس", nameEn: "Allan Harris", from: "01/11/1996", to: "31/03/1997", matches: 4, ppm: "0.25", photo: null },
  { name: "أحمد رفعت", nameEn: "Ahmed Refaat", from: "09/07/1996", to: "26/10/1996", matches: 0, ppm: "-", photo: "https://img.a.transfermarkt.technology/portrait/big/81977-1635225338.jpg" },
  { name: "كور بوت", nameEn: "Cor Pot", from: "01/07/1994", to: "30/06/1995", matches: 10, ppm: "0.80", photo: "https://img.a.transfermarkt.technology/portrait/big/_1370591760.jpg" },
  { name: "برتالان بيكسكي", nameEn: "Bertalan Bicskei", from: "19/03/1994", to: "30/06/1994", matches: 2, ppm: "1.00", photo: null },
  { name: "فويتشيك وازاريك", nameEn: "Wojciech Lazarek", from: "01/07/1992", to: "30/06/1993", matches: 7, ppm: "1.29", photo: null },
  { name: "محمود الجوهري", nameEn: "Mahmoud El Gohary", from: "23/08/1991", to: "25/10/1991", matches: 1, ppm: "1.00", photo: "https://img.a.transfermarkt.technology/portrait/big/9166-1593761634.jpg" },
  { name: "فرينك بوشكاش", nameEn: "Ferenc Puskás", from: "01/07/1979", to: "30/06/1982", matches: 0, ppm: "-", photo: "https://img.a.transfermarkt.technology/portrait/big/19495-1776343102.jpg" },
];

export type RecordPlayer = {
  rank: number;
  name: string;
  nameEn: string;
  apps: number;
  goals: number;
  assists: number;
  photo: string | null;
};

export const RECORD_PLAYERS: RecordPlayer[] = [
  { rank: 1, name: "عمرو موسى", nameEn: "Amr Moussa", apps: 317, goals: 9, assists: 8, photo: "https://img.a.transfermarkt.technology/portrait/big/295866-1504785934.jpg" },
  { rank: 2, name: "كريم العراقي", nameEn: "Karim El Eraki", apps: 287, goals: 5, assists: 11, photo: "https://img.a.transfermarkt.technology/portrait/big/518942-1626634510.jpeg" },
  { rank: 3, name: "فريد شوقي", nameEn: "Farid Shawky", apps: 246, goals: 2, assists: 12, photo: "https://img.a.transfermarkt.technology/portrait/big/341386-1504786337.jpg" },
  { rank: 4, name: "حسن علي", nameEn: "Hassan Ali", apps: 210, goals: 18, assists: 7, photo: "https://img.a.transfermarkt.technology/portrait/big/435929-1782314765.jpeg" },
  { rank: 5, name: "أسامة عزب", nameEn: "Osama Azab", apps: 189, goals: 7, assists: 5, photo: "https://img.a.transfermarkt.technology/portrait/big/105416-1538312895.jpg" },
  { rank: 6, name: "أحمد جمعة", nameEn: "Ahmed Gomaa", apps: 177, goals: 54, assists: 9, photo: "https://img.a.transfermarkt.technology/portrait/big/340006-1504786004.jpg" },
  { rank: 7, name: "محمد جرندو", nameEn: "Mohamed Grendo", apps: 167, goals: 27, assists: 15, photo: null },
  { rank: 8, name: "أحمد مسعود", nameEn: "Ahmed Masoud", apps: 159, goals: 0, assists: 0, photo: "https://img.a.transfermarkt.technology/portrait/big/261434-1497347769.jpg" },
  { rank: 9, name: "عاشور الأدهم", nameEn: "Ashour El Adham", apps: 153, goals: 16, assists: 3, photo: "https://img.a.transfermarkt.technology/portrait/big/105428-1497274565.jpg" },
  { rank: 10, name: "أحمد شديد قناوي", nameEn: "Ahmed Shedid Kenawi", apps: 152, goals: 13, assists: 19, photo: "https://img.a.transfermarkt.technology/portrait/big/39651-1615124608.jpg" },
  { rank: 11, name: "Emeka Christian Eze", nameEn: "Emeka Christian Eze", apps: 150, goals: 2, assists: 5, photo: "https://img.a.transfermarkt.technology/portrait/big/s_267082_2930_2012_1.jpg" },
  { rank: 12, name: "Amr El Saadawy", nameEn: "Amr El Saadawy", apps: 124, goals: 4, assists: 7, photo: "https://img.a.transfermarkt.technology/portrait/big/459864-1686463730.jpg" },
  { rank: 13, name: "إسلام صلاح", nameEn: "Islam Salah", apps: 118, goals: 7, assists: 1, photo: "https://img.a.transfermarkt.technology/portrait/big/257832-1504785727.jpg" },
  { rank: 14, name: "Austin Amutu", nameEn: "Austin Amutu", apps: 114, goals: 25, assists: 6, photo: null },
  { rank: 15, name: "Ahmed Fawzy", nameEn: "Ahmed Fawzy", apps: 113, goals: 5, assists: 4, photo: "https://img.a.transfermarkt.technology/portrait/big/107656-1436860831.jpg" },
  { rank: 16, name: "Abderrahim Deghmoum", nameEn: "Abderrahim Deghmoum", apps: 113, goals: 12, assists: 13, photo: "https://img.a.transfermarkt.technology/portrait/big/568203-1681409344.jpg" },
  { rank: 17, name: "Mahmoud Hamada", nameEn: "Mahmoud Hamada", apps: 109, goals: 6, assists: 6, photo: "https://img.a.transfermarkt.technology/portrait/big/471117-1519379510.jpg" },
  { rank: 18, name: "أحمد أيمن منصور", nameEn: "Ahmed Ayman Mansour", apps: 107, goals: 3, assists: 8, photo: "https://img.a.transfermarkt.technology/portrait/big/344283-1673782787.jpeg" },
  { rank: 19, name: "Ahmed Yasser", nameEn: "Ahmed Yasser", apps: 103, goals: 15, assists: 10, photo: "https://img.a.transfermarkt.technology/portrait/big/277972-1553527336.jpg" },
  { rank: 20, name: "Ahmed Shousha", nameEn: "Ahmed Shousha", apps: 101, goals: 1, assists: 6, photo: "https://img.a.transfermarkt.technology/portrait/big/371596-1438177148.jpg" },
];

// صور مدربين حقيقية (من ويكيبيديا / في الجول) لمن لم تتوفر لهم صورة في Transfermarkt.
import coachAhmedSamy from "@/assets/coaches/ahmed-samy.jpg.asset.json";
import coachEmadElNahhas from "@/assets/coaches/emad-el-nahhas.jpg.asset.json";
import coachTarekYehia from "@/assets/coaches/tarek-yehia.jpg.asset.json";
import coachTahaBasry from "@/assets/coaches/taha-basry.jpg.asset.json";
import coachFaroukGaafar from "@/assets/coaches/farouk-gaafar.jpg.asset.json";
import coachAbouRegaila from "@/assets/coaches/mahmoud-abou-regaila.jpg.asset.json";
import coachOscarFullone from "@/assets/coaches/oscar-fullone.jpg.asset.json";
import coachWojciechLazarek from "@/assets/coaches/wojciech-lazarek.jpg.asset.json";
import coachMohsenSaleh from "@/assets/people/legend-mohsen-saleh.jpeg.asset.json";

const EXTRA_COACH_PHOTOS: Record<string, string> = {
  "Ahmed Samy": coachAhmedSamy.url,
  "Emad El-Nahhas": coachEmadElNahhas.url,
  "Tarek Yehia": coachTarekYehia.url,
  "Taha Basry": coachTahaBasry.url,
  "Farouk Gaafar": coachFaroukGaafar.url,
  "Mahmoud Abou-Regaila": coachAbouRegaila.url,
  "Oscar Fulloné": coachOscarFullone.url,
  "Wojciech Lazarek": coachWojciechLazarek.url,
  "Mohsen Saleh": coachMohsenSaleh.url,
};

for (const spell of COACH_HISTORY) {
  if (!spell.photo) spell.photo = EXTRA_COACH_PHOTOS[spell.nameEn] ?? null;
}
