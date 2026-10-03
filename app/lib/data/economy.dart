/// Oyunun **ortak ekonomi ölçeği** — 2026 Türkiye alım gücü kalibrasyonu.
///
/// Bu tablo gerçek piyasa fiyatlarının kopyası değildir ve oyun canlı fiyat
/// çekmez. Kendi içinde tutarlı, **tek bir dönemin** satın alma gücüne
/// oturtulmuş bir ölçektir.
///
/// ## Neden tek dönem?
///
/// Oyun 30-50 yıllık nominal enflasyonu **simüle etmez**. Bütün tutarlar
/// "2026 TL satın alma gücü" cinsindendir. Böylece 70 yaşına gelen bir
/// karakterin maaşı ya da ev fiyatı, gerçek dünyanın gelecek enflasyonu
/// yüzünden yüz milyonlara çıkmak zorunda kalmaz; oyuncu bütün hayat
/// boyunca aynı ölçekle düşünür.
///
/// ## Çıpalar (Eylül 2026 referansı, Faho onayı)
///
/// | Çıpa                                   | Değer          |
/// |----------------------------------------|----------------|
/// | Net aylık asgari ücret                 | 28.075,50 ₺    |
/// | Brüt aylık asgari ücret                | 33.030 ₺       |
/// | Net yıllık asgari ücret (12 ay)        | 336.906 ₺      |
/// | Yıllık TÜFE (Ağustos 2026)             | %31,51         |
/// | Konut/su/elektrik/gaz yıllık değişim   | %39,77         |
///
/// TÜFE ve konut grubu oranları **kalibrasyon gerekçesidir**, oyunda
/// çalışan bir enflasyon motoru değildir.
///
/// ## Maaş kuralı
///
/// Tam zamanlı normal bir işin yıllık geliri, özel bir gerekçe olmadan
/// [netYearlyMinimumWage] altında kalamaz. Bantlar aşağıda; her işin
/// hangi banda ait olduğu katalogda yazılıdır ve
/// `test/economy_calibration_test.dart` bunu denetler.
///
/// Ayrıntılı gerekçe ve eski/yeni karşılaştırması: `docs/ECONOMY_2026.md`.
library;

/// Bir mesleğin gelir sınıfı.
///
/// Bant, maaşın **nereye oturduğunu** söyler; kesin sayıyı değil. Aynı
/// bantta iki iş aynı parayı vermez, ama ikisi de bandın dışına çıkamaz.
enum SalaryBand {
  /// Asgari ücret / giriş seviyesi: nitelik aranmayan tam zamanlı iş.
  giris('Asgari / giriş seviyesi', 336906, 400000),

  /// Nitelikli hizmet: müşteriyle temas, sertifika ya da beceri ister.
  nitelikliHizmet('Nitelikli hizmet', 400000, 540000),

  /// Usta / teknik meslek: çıraklıkla ya da meslek lisesiyle öğrenilen iş.
  ustaTeknik('Usta / teknik meslek', 520000, 720000),

  /// Ofis / uzmanlık: masa başı, çoğunlukla lise üstü.
  ofisUzmanlik('Ofis / uzmanlık', 620000, 900000),

  /// Üniversite gerektiren profesyonel meslek.
  profesyonel('Üniversite profesyoneli', 820000, 1350000),

  /// Yüksek uzmanlık: uzun eğitim, dar giriş.
  yuksekUzmanlik('Yüksek uzmanlık', 1300000, 2400000),

  /// Ün ve yaratıcı sektör: taban düşük, tavan yüksek ve değişken.
  ///
  /// Bu bandın altı [giris] bandının altına inebilir: serbest çalışan
  /// bir yazarın kötü yılı asgari ücretin altında olabilir. Sabit maaş
  /// kuralı bu banda uygulanmaz.
  yaraticiDegisken('Yaratıcı / değişken gelir', 380000, 2000000),

  /// Yarım zamanlı iş (D-131): okula devam ederken ya da tam gün
  /// çalışmadan yapılan iş.
  ///
  /// **Asgari ücret tabanı bu banda uygulanmaz**, çünkü yarım zamanlı
  /// çalışan tam ay çalışmıyor: 2026'da net asgari ücret aylık
  /// 28.075 ₺, yarım gün çalışan bunun kabaca yarısını alır.
  ///
  /// Yeni değerler listenin **sonuna** eklenir; eski kayıtlar bozulmasın.
  yarimZamanli('Yarım zamanlı', 90000, 260000);

  const SalaryBand(this.label, this.minYearly, this.maxYearly);

  final String label;

  /// Bandın yıllık alt sınırı (₺, 2026 alım gücü).
  final int minYearly;

  /// Bandın yıllık üst sınırı (₺, 2026 alım gücü).
  final int maxYearly;

  /// Sabit maaş kuralının (asgari ücret tabanı) uygulandığı bant mı?
  ///
  /// Yaratıcı/değişken gelirde taban yoktur; yarım zamanlıda da yoktur
  /// çünkü tam ay çalışılmıyor (D-131).
  bool get sabitMaasli =>
      this != SalaryBand.yaraticiDegisken &&
      this != SalaryBand.yarimZamanli;

  bool icerir(int yillik) => yillik >= minYearly && yillik <= maxYearly;
}

abstract final class Economy {
  // -------------------------------------------------------------------
  // Çıpalar
  // -------------------------------------------------------------------

  /// 2026 net **aylık** asgari ücret (₺). Kuruş yuvarlandı.
  static const int netMonthlyMinimumWage = 28075;

  /// 2026 brüt **aylık** asgari ücret (₺).
  static const int grossMonthlyMinimumWage = 33030;

  /// 2026 net **yıllık** asgari ücret (₺): 12 aylık toplam.
  static const int netYearlyMinimumWage = netMonthlyMinimumWage * 12;

  /// Yıllık tutarın kabaca aylık karşılığı.
  ///
  /// Motor yıllık hesapla çalışır; bu yalnızca ekranda "aylık yaklaşık"
  /// satırını yazmak içindir.
  static int monthlyOf(int yearly) => (yearly / 12).round();

  /// Bir tutarın kaç aylık asgari ücrete denk geldiği.
  ///
  /// Kalibrasyonun ortak dili: "bu araba 40 asgari ücret eder" demek,
  /// TL rakamından daha okunur bir ölçüdür.
  static double inMinimumWages(int amount) => amount / netMonthlyMinimumWage;

  // -------------------------------------------------------------------
  // Gündelik harcama kademeleri (₺, 2026)
  // -------------------------------------------------------------------

  /// Bir çay, bir simit: cepten çıktığı fark edilmeyen tutar.
  static const int tierCokUfak = 120;

  /// Kafe, sinema bileti, küçük hediye.
  static const int tierUfak = 450;

  /// Konser, maç bileti, güzel bir akşam yemeği.
  static const int tierOrta = 2000;

  /// Kurs dönemi, iyi bir hediye, kısa gezi.
  static const int tierBuyuk = 12000;

  /// Telefon, bilgisayar: aylık gelirin önemli bir kısmı.
  static const int tierDayanikli = 45000;

  // -------------------------------------------------------------------
  // Eşikler
  // -------------------------------------------------------------------

  /// prototypeOnly: aileden istenebilecek küçük para aralığı.
  static const int prototypeOnlyPocketMoneyMin = 400;
  static const int prototypeOnlyPocketMoneyMax = 1800;

  /// "Değerli eşya" sayılan eşik.
  static const int valuableThreshold = 25000;

  /// Araç sayılan eşya eşiği (bilgi amaçlı).
  static const int vehicleThreshold = 150000;
}
