/// İşletme olayları kataloğu (Paket AE, §11-24).
///
/// **Neden var.** AE öncesinde işletmenin başına gelen tek şey yılın
/// oynaklığıydı: kâr biraz yukarı, biraz aşağı. Oyuncu hiçbir şey
/// yaşamıyordu. Bu katalog her işin **kendi** başına gelenleri getirir:
/// halı sahayı su basar, baş aşçı ayrılır, fırın bozulur, karşı sokağa
/// rakip açılır.
///
/// **Kurallar:**
/// * Her işletmede aynı olay çıkmaz (§24). Olaylar etikete göre dağılır;
///   serbest yazılımcıya su baskını gelmez (§21).
/// * Aynı olay aynı yıl **iki kez uygulanmaz** ve kayıt geri yüklenerek
///   yeniden çevrilemez: zar işletmenin kendi akışından gelir.
/// * Afet olayları **çok nadirdir** (§24) ve yalnızca uygun mekânlara
///   dağıtılır.
/// * Denetim ve vergi olayları **mevzuat simülatörü değildir** (§23):
///   yalnızca işletmenin riski ve masrafıdır. Hiçbir metin vergiden
///   kaçınma yolu anlatmaz.
/// * Gerçek marka, kurum ya da kişi adı geçmez.
/// * Dil `docs/WRITING_STYLE_TR.md` kurallarına uyar (§37).
///
/// Bütün sayılar `prototypeOnly`'dir (Q-175).
library;

import 'package:flutter/foundation.dart';

/// Bir işletme olayının şablonu.
@immutable
class BusinessIncident {
  const BusinessIncident({
    required this.id,
    required this.title,
    required this.text,
    required this.tags,
    this.weight = 1.0,
    this.costShare = 0.0,
    this.upkeepDelta = 0,
    this.moraleDelta = 0,
    this.qualityDelta = 0,
    this.reputationDelta = 0,
    this.conditionDelta = 0,
    this.staffLoss = 0,
    this.demandShift = 1.0,
    this.lastingShift = 1.0,
    this.major = false,
    this.minYearsOpen = 1,
    this.requiresStaff = false,
    this.requiresEquipment = false,
    this.maxUpkeep = 101,
    this.minUpkeep = -1,
    this.minReputation = -1,
  });

  final String id;

  /// Bildirim başlığı.
  final String title;

  /// Anlatı metni. Sistem sonucu ayrı satırda gösterilir (üslup §3).
  final String text;

  /// Hangi işletme etiketlerine gider ([BusinessType.incidentTags]).
  final Set<String> tags;

  /// prototypeOnly: seçilme ağırlığı.
  final double weight;

  /// prototypeOnly: taban ciroya oranla çıkardığı masraf.
  final double costShare;

  final int upkeepDelta;
  final int moraleDelta;
  final int qualityDelta;
  final int reputationDelta;
  final int conditionDelta;

  /// Kaç çalışan ayrıldı.
  final int staffLoss;

  /// O yılın talebine çarpan (1,0 etkisiz).
  final double demandShift;

  /// **Kalıcı** talep baskısına çarpan (1,0 etkisiz).
  ///
  /// Karşı sokağa açılan rakip bir yıllık bir dalgalanma değildir: ertesi
  /// yıl da oradadır. Bu alan [Business.demandPressure] değerini çarpar
  /// ve etkisi yıllar içinde yavaşça azalır.
  final double lastingShift;

  /// Oyuncuya pencere açılır mı (§25)?
  final bool major;

  /// İşin en az kaç yıllık olması gerekir.
  final int minYearsOpen;

  /// Kadrosu olan işlere mi gelir?
  final bool requiresStaff;

  /// Bakım isteyen ekipmanı olan işlere mi gelir?
  final bool requiresEquipment;

  /// Ekipman bundan **iyiyse** olay çıkmaz (arıza yıpranmışta olur).
  final int maxUpkeep;

  /// Ekipman bundan **kötüyse** olay çıkmaz.
  final int minUpkeep;

  /// İtibar bundan **düşükse** olay çıkmaz (iyi haber iyi dükkâna gelir).
  final int minReputation;

  bool get isGoodNews =>
      costShare <= 0 &&
      staffLoss == 0 &&
      (demandShift > 1.0 || reputationDelta > 0 || conditionDelta > 0);
}

/// prototypeOnly: bütün işletme olayları.
///
/// Kimlikler kayda yazılmaz ama tekrar kontrolünde kullanılır; yeni
/// olaylar listenin **sonuna** eklenir.
const List<BusinessIncident> kBusinessIncidents = <BusinessIncident>[
  // ===================================================================
  // §7 — Personel (kadrosu olan bütün işler)
  // ===================================================================
  BusinessIncident(
    id: 'ae_personel_ayrildi',
    title: 'Çalışanın işi bıraktı',
    text: 'Sabah dükkânı açmadan telefon geldi.\n\n'
        'Bugün gelmeyecekmiş.\n\n'
        'Sonra bir daha gelmeyeceğini söyledi.',
    tags: <String>{'*'},
    weight: 2.4,
    requiresStaff: true,
    staffLoss: 1,
    moraleDelta: -6,
    demandShift: 0.93,
    major: true,
  ),
  BusinessIncident(
    id: 'ae_personel_zam_istedi',
    title: 'Zam istediler',
    text: 'Kapanıştan sonra ikisi yanına geldi.\n\n'
        'Uzun uzun anlatmaya çalıştılar ama derdi üç kelimeyle söylediler.\n\n'
        '"Bu parayla olmuyor."',
    tags: <String>{'*'},
    weight: 2.0,
    requiresStaff: true,
    moraleDelta: -12,
  ),
  BusinessIncident(
    id: 'ae_personel_hastalandi',
    title: 'Çalışan hastalandı',
    text: 'Bir hafta gelemeyecek.\n\n'
        'Onun işini de sen yaptın. Akşamları eve geç geldin.',
    tags: <String>{'*'},
    weight: 1.6,
    requiresStaff: true,
    costShare: 0.014,
    demandShift: 0.96,
  ),
  BusinessIncident(
    id: 'ae_personel_iyi_cikti',
    title: 'Yeni çalışan iyi çıktı',
    text: 'İşe aldığın çocuk iki haftada işi kaptı.\n\n'
        'Sen olmadığın gün de dükkân aynı dükkân.',
    tags: <String>{'*'},
    weight: 1.2,
    requiresStaff: true,
    qualityDelta: 11,
    moraleDelta: 6,
    minYearsOpen: 2,
  ),
  BusinessIncident(
    id: 'ae_personel_gerginlik',
    title: 'Personel arasında sorun',
    text: 'İkisi bir haftadır konuşmuyor.\n\n'
        'Müşteri bile fark etti.',
    tags: <String>{'*'},
    weight: 1.5,
    requiresStaff: true,
    moraleDelta: -14,
    reputationDelta: -4,
  ),

  // ===================================================================
  // §23 — Denetim ve maliyet (mevzuat simülatörü değil)
  // ===================================================================
  BusinessIncident(
    id: 'ae_mali_denetim',
    title: 'Mali denetim',
    text: 'Öğleden sonra iki kişi geldi.\n\n'
        'Defterleri istediler, oturup baktılar.\n\n'
        'Akşam üstü gittiler. Eksik bir iki şey çıktı.',
    tags: <String>{'dukkan', 'tesis', 'nakliye', 'serbest'},
    weight: 1.1,
    costShare: 0.055,
    minYearsOpen: 3,
    major: true,
  ),
  BusinessIncident(
    id: 'ae_ruhsat_kontrol',
    title: 'Evrak kontrolü',
    text: 'Ruhsat ve evrak kontrolü için geldiler.\n\n'
        'Yenilenmesi gereken bir belge varmış. Harcını yatırdın.',
    tags: <String>{'dukkan', 'tesis'},
    weight: 1.3,
    costShare: 0.022,
    minYearsOpen: 2,
  ),
  BusinessIncident(
    id: 'ae_enerji_gideri',
    title: 'Elektrik faturası',
    text: 'Bu ayki fatura geldi.\n\n'
        'Bir süre ekrana baktın.\n\n'
        'Sonra tekrar baktın.',
    tags: <String>{'dukkan', 'tesis', 'firin', 'mutfak', 'yikama'},
    weight: 1.8,
    costShare: 0.038,
  ),
  BusinessIncident(
    id: 'ae_tedarik_zammi',
    title: 'Tedarikçi zam yaptı',
    text: 'Tedarikçi yeni fiyat listesini gönderdi.\n\n'
        'Bir süre ekrana baktın.\n\n'
        'Sonra tekrar baktın.',
    tags: <String>{'tedarik'},
    weight: 2.2,
    costShare: 0.048,
  ),

  // ===================================================================
  // §11 — Halı saha
  // ===================================================================
  BusinessIncident(
    id: 'ae_saha_su_basti',
    title: 'Sahayı su bastı',
    text: 'Gece yağmur iyice bastırmış.\n\n'
        'Sabah sahaya gittiğinde sentetik çimin yarısı suyun altında.\n\n'
        'Bir hafta kimse maç yapamadı.',
    tags: <String>{'saha'},
    weight: 1.6,
    costShare: 0.075,
    upkeepDelta: -16,
    demandShift: 0.88,
    major: true,
  ),
  BusinessIncident(
    id: 'ae_saha_cim_yiprandi',
    title: 'Çim yıprandı',
    text: 'Orta sahada çim iyice yatmış.\n\n'
        'Oynayanlar bir şey demiyor ama kayıyorlar.',
    tags: <String>{'saha'},
    weight: 1.9,
    upkeepDelta: -13,
    reputationDelta: -5,
    maxUpkeep: 85,
  ),
  BusinessIncident(
    id: 'ae_saha_projektor',
    title: 'Projektör bozuldu',
    text: 'Akşam yedide iki direk yanmadı.\n\n'
        'Saat sekiz maçı yarım karanlıkta oynandı.',
    tags: <String>{'saha'},
    weight: 1.7,
    costShare: 0.042,
    upkeepDelta: -10,
    reputationDelta: -6,
    requiresEquipment: true,
    maxUpkeep: 82,
  ),
  BusinessIncident(
    id: 'ae_saha_soyunma',
    title: 'Soyunma odasında sorun',
    text: 'Soyunma odasının sıcak suyu bir haftadır gelmiyor.\n\n'
        'Kış ortası. Bunu kimse sessizce geçiştirmedi.',
    tags: <String>{'saha', 'salon'},
    weight: 1.4,
    costShare: 0.028,
    reputationDelta: -8,
  ),
  BusinessIncident(
    id: 'ae_saha_rakip',
    title: 'Mahallede yeni saha açıldı',
    text: 'İki sokak ötede yeni bir saha açıldı.\n\n'
        'Çimi yeni, ışığı yeni, fiyatı da düşük.',
    tags: <String>{'saha'},
    weight: 1.3,
    demandShift: 0.82,
    lastingShift: 0.88,
    minYearsOpen: 3,
    major: true,
  ),
  BusinessIncident(
    id: 'ae_saha_turnuva',
    title: 'Turnuva teklifi',
    text: 'Mahalleden birkaç takım gelip turnuva istedi.\n\n'
        'Üç hafta boyunca saha bir gün bile boş kalmadı.',
    tags: <String>{'turnuva'},
    weight: 1.5,
    demandShift: 1.24,
    reputationDelta: 7,
    minReputation: 40,
  ),
  BusinessIncident(
    id: 'ae_saha_yaz_bosluk',
    title: 'Yaz boyu saha boş kaldı',
    text: 'Haziranda rezervasyonlar düştü.\n\n'
        'Temmuzda telefon neredeyse hiç çalmadı.',
    tags: <String>{'saha'},
    weight: 1.6,
    demandShift: 0.83,
  ),
  BusinessIncident(
    id: 'ae_saha_lig',
    title: 'Takımlar ligi tuttu',
    text: 'Kurdukların lig tuttu.\n\n'
        'Salı ve perşembe akşamları sahada yer yok.',
    tags: <String>{'turnuva'},
    weight: 1.2,
    demandShift: 1.18,
    lastingShift: 1.06,
    conditionDelta: 4,
    minYearsOpen: 2,
  ),

  // ===================================================================
  // §12 — Kahve dükkânı
  // ===================================================================
  BusinessIncident(
    id: 'ae_kahve_barista',
    title: 'Barista işi bıraktı',
    text: 'Sabahın körü. Telefon çaldı.\n\n'
        'Başka bir yerde teklif almış. Bugün son günüymüş.',
    tags: <String>{'kahve'},
    weight: 2.0,
    requiresStaff: true,
    staffLoss: 1,
    qualityDelta: -9,
    demandShift: 0.90,
    major: true,
  ),
  BusinessIncident(
    id: 'ae_kahve_makine',
    title: 'Kahve makinesi durdu',
    text: 'Sabah dokuzda makine tamamen durdu.\n\n'
        'Gelen herkese aynı cümleyi kurdun.',
    tags: <String>{'kahve'},
    weight: 1.8,
    costShare: 0.062,
    upkeepDelta: -18,
    demandShift: 0.87,
    requiresEquipment: true,
    maxUpkeep: 80,
    major: true,
  ),
  BusinessIncident(
    id: 'ae_kahve_cekirdek',
    title: 'Çekirdek pahalandı',
    text: 'Yeni liste geldi. Çekirdek belirgin şekilde zamlanmış.\n\n'
        'Fiyatı aynı tuttun. Kâr satırı bunu gördü.',
    tags: <String>{'kahve'},
    weight: 1.9,
    costShare: 0.044,
  ),
  BusinessIncident(
    id: 'ae_kahve_sut',
    title: 'Süt maliyeti arttı',
    text: 'Süt de zamlandı.\n\n'
        'Günde kaç litre gittiğini ilk kez oturup hesapladın.',
    tags: <String>{'kahve'},
    weight: 1.6,
    costShare: 0.031,
  ),
  BusinessIncident(
    id: 'ae_kahve_rakip',
    title: 'Karşı sokakta yeni kahveci',
    text: 'Karşı sokağa yeni bir kahveci açıldı.\n\n'
        'Açılışa özel kahveyi neredeyse maliyetine veriyorlar.',
    tags: <String>{'kahve'},
    weight: 1.4,
    demandShift: 0.84,
    lastingShift: 0.90,
    minYearsOpen: 2,
    major: true,
  ),
  BusinessIncident(
    id: 'ae_kahve_video',
    title: 'Video tuttu',
    text: 'Biri dükkânda çektiği videoyu paylaşmış.\n\n'
        'İki gün sonra kapıda sıra vardı.',
    tags: <String>{'sosyal'},
    weight: 1.3,
    demandShift: 1.26,
    reputationDelta: 9,
    minReputation: 45,
  ),
  BusinessIncident(
    id: 'ae_kahve_kapasite',
    title: 'Masa yetmiyor',
    text: 'Öğleden sonraları gelen çoğu kişi ayakta bekleyip gidiyor.\n\n'
        'Kaçırdığın müşteriyi sayamıyorsun bile.',
    tags: <String>{'kahve', 'sosyal'},
    weight: 1.1,
    demandShift: 0.94,
    reputationDelta: -3,
    minYearsOpen: 2,
  ),
  BusinessIncident(
    id: 'ae_kahve_sabah',
    title: 'Sabah yoğunluğu oturdu',
    text: 'Karşıdaki ofisten her sabah aynı yüzler geliyor.\n\n'
        'Sekiz buçukta sıra kapıya kadar.',
    tags: <String>{'kahve'},
    weight: 1.2,
    demandShift: 1.15,
    lastingShift: 1.06,
    conditionDelta: 3,
    minYearsOpen: 2,
  ),

  // ===================================================================
  // §13 — Lokanta
  // ===================================================================
  BusinessIncident(
    id: 'ae_lokanta_asci',
    title: 'Baş aşçın işi bıraktı',
    text: 'Servis bitti, ocakları kapattı, önlüğünü astı.\n\n'
        '"Hakkını helal et."\n\n'
        'Mutfağın yarısı onunla beraber gitti.',
    tags: <String>{'mutfak'},
    weight: 2.1,
    requiresStaff: true,
    staffLoss: 1,
    qualityDelta: -14,
    reputationDelta: -6,
    demandShift: 0.88,
    major: true,
  ),
  BusinessIncident(
    id: 'ae_lokanta_buzdolabi',
    title: 'Buzdolabı bozuldu',
    text: 'Sabah mutfağa girdiğinde koku seni karşıladı.\n\n'
        'İçindekilerin çoğu gitti.',
    tags: <String>{'mutfak'},
    weight: 1.7,
    costShare: 0.070,
    upkeepDelta: -17,
    requiresEquipment: true,
    maxUpkeep: 82,
    major: true,
  ),
  BusinessIncident(
    id: 'ae_gida_denetim',
    title: 'Hijyen denetimi',
    text: 'Denetim için geldiler.\n\n'
        'Mutfağı gezdiler, birkaç not aldılar.\n\n'
        'Eksikleri kapatman söylendi.',
    tags: <String>{'gida'},
    weight: 1.5,
    costShare: 0.040,
    minYearsOpen: 2,
    major: true,
  ),
  BusinessIncident(
    id: 'ae_lokanta_sikayet',
    title: 'Müşteri şikâyeti',
    text: 'Akşam bir masa yemeği beğenmedi.\n\n'
        'Sesi salonun yarısı duyacak kadar yüksekti.',
    tags: <String>{'gida', 'kuafor'},
    weight: 1.8,
    reputationDelta: -9,
  ),
  BusinessIncident(
    id: 'ae_lokanta_israf',
    title: 'Mutfakta israf',
    text: 'Ay sonu hesabı tutmadı.\n\n'
        'Çöpe giden malzemenin ne kadar olduğunu görünce durdun.',
    tags: <String>{'mutfak', 'firin'},
    weight: 1.6,
    costShare: 0.033,
  ),
  BusinessIncident(
    id: 'ae_lokanta_rezervasyon',
    title: 'Toplu rezervasyon',
    text: 'Bir aile bütün salonu istedi.\n\n'
        'O akşam mutfaktan kimse başını kaldıramadı.',
    tags: <String>{'mutfak', 'sosyal'},
    weight: 1.4,
    demandShift: 1.16,
    minReputation: 42,
  ),
  BusinessIncident(
    id: 'ae_bayram_yogunluk',
    title: 'Bayram yoğunluğu',
    text: 'Bayramda kepenk bir gün bile kapanmadı.\n\n'
        'Ayakların şişti ama kasa doldu.',
    tags: <String>{'bayram'},
    weight: 1.7,
    demandShift: 1.22,
    moraleDelta: -5,
  ),

  // ===================================================================
  // §14 — Spor salonu
  // ===================================================================
  BusinessIncident(
    id: 'ae_salon_antrenor',
    title: 'Antrenör ayrıldı',
    text: 'En çok sevilen antrenör başka salona geçti.\n\n'
        'Üyelerin bir kısmı da onunla gitti.',
    tags: <String>{'salon'},
    weight: 2.0,
    requiresStaff: true,
    staffLoss: 1,
    demandShift: 0.87,
    reputationDelta: -5,
    major: true,
  ),
  BusinessIncident(
    id: 'ae_salon_cihaz',
    title: 'Cihaz bozuldu',
    text: 'Koşu bandının ikisi de durdu.\n\n'
        'Üstlerine kâğıt yapıştırdın. Kimse memnun değil.',
    tags: <String>{'salon'},
    weight: 1.8,
    costShare: 0.058,
    upkeepDelta: -15,
    reputationDelta: -6,
    requiresEquipment: true,
    maxUpkeep: 84,
  ),
  BusinessIncident(
    id: 'ae_salon_ocak',
    title: 'Ocakta üye patlaması',
    text: 'Ocağın ilk haftası kapı kapanmadı.\n\n'
        'Herkes bu sene kararlı.',
    tags: <String>{'salon'},
    weight: 1.9,
    demandShift: 1.30,
  ),
  BusinessIncident(
    id: 'ae_salon_terk',
    title: 'Üyeler gelmiyor',
    text: 'Martta salon sessizleşti.\n\n'
        'Ocakta yazılanların çoğunu bir daha görmedin.',
    tags: <String>{'salon'},
    weight: 1.9,
    demandShift: 0.84,
  ),
  BusinessIncident(
    id: 'ae_salon_rakip',
    title: 'Rakip salon açıldı',
    text: 'Caddeye büyük bir salon açıldı.\n\n'
        'İlk üç ay üyelik yarı fiyat.',
    tags: <String>{'salon', 'yikama'},
    weight: 1.3,
    demandShift: 0.85,
    lastingShift: 0.90,
    minYearsOpen: 3,
    major: true,
  ),
  BusinessIncident(
    id: 'ae_tesisat_sorunu',
    title: 'Tesisat patladı',
    text: 'Duşların altındaki boru gece patlamış.\n\n'
        'Sabah gelen ilk kişi seni aradı.',
    tags: <String>{'su'},
    weight: 0.8,
    costShare: 0.090,
    upkeepDelta: -14,
    demandShift: 0.90,
    major: true,
  ),

  // ===================================================================
  // §15 — Oto tamir
  // ===================================================================
  BusinessIncident(
    id: 'ae_oto_usta',
    title: 'Usta işi bıraktı',
    text: 'Sabah dükkânı açmadan telefon geldi.\n\n'
        'Usta bugün gelmeyecekmiş.\n\n'
        'Sonra bir daha gelmeyeceğini söyledi.',
    tags: <String>{'atolye', 'oto'},
    weight: 2.1,
    requiresStaff: true,
    staffLoss: 1,
    qualityDelta: -12,
    demandShift: 0.88,
    major: true,
  ),
  BusinessIncident(
    id: 'ae_oto_lift',
    title: 'Lift bozuldu',
    text: 'Lift yarı yolda kaldı.\n\n'
        'Üstünde bir araba, altında sen.',
    tags: <String>{'oto'},
    weight: 1.7,
    costShare: 0.065,
    upkeepDelta: -16,
    requiresEquipment: true,
    maxUpkeep: 82,
    major: true,
  ),
  BusinessIncident(
    id: 'ae_oto_parca',
    title: 'Parça fiyatları yükseldi',
    text: 'Yedek parça listesi güncellendi.\n\n'
        'Müşteriye söylerken sesin kısıldı.',
    tags: <String>{'oto'},
    weight: 1.9,
    costShare: 0.046,
  ),
  BusinessIncident(
    id: 'ae_oto_geri_geldi',
    title: 'Araba geri geldi',
    text: 'Geçen hafta teslim ettiğin araba aynı sesle geri geldi.\n\n'
        'Sahibi hiçbir şey söylemedi. Söylemesine gerek de yoktu.',
    tags: <String>{'atolye', 'oto'},
    weight: 1.6,
    reputationDelta: -10,
    costShare: 0.018,
  ),
  BusinessIncident(
    id: 'ae_oto_rakip',
    title: 'Sanayide yeni dükkân',
    text: 'İki bölme ötede yeni bir tamirci açıldı.\n\n'
        'Genç, hızlı ve ucuz.',
    tags: <String>{'atolye'},
    weight: 1.2,
    demandShift: 0.87,
    lastingShift: 0.92,
    minYearsOpen: 3,
  ),
  BusinessIncident(
    id: 'ae_filo_anlasmasi',
    title: 'Filo anlaşması',
    text: 'Bir şirket bütün araçlarını sana getirmek istedi.\n\n'
        'Fiyatı kendileri söyledi ama işin sürekli.',
    tags: <String>{'filo'},
    weight: 1.3,
    demandShift: 1.25,
    lastingShift: 1.10,
    conditionDelta: 5,
    minReputation: 48,
    minYearsOpen: 2,
  ),
  BusinessIncident(
    id: 'ae_oto_yogun_donem',
    title: 'Yoğun dönem',
    text: 'Muayene dönemi geldi.\n\n'
        'Kapıda sıra oldu, akşamları geç çıktın.',
    tags: <String>{'oto'},
    weight: 1.5,
    demandShift: 1.14,
    moraleDelta: -4,
  ),

  // ===================================================================
  // §16 — Pastane / fırın
  // ===================================================================
  BusinessIncident(
    id: 'ae_firin_bozuldu',
    title: 'Fırın bozuldu',
    text: 'Gece hamuru yoğurdun.\n\n'
        'Sabah fırını yaktın, ısınmadı.',
    tags: <String>{'firin'},
    weight: 1.8,
    costShare: 0.072,
    upkeepDelta: -18,
    demandShift: 0.88,
    requiresEquipment: true,
    maxUpkeep: 82,
    major: true,
  ),
  BusinessIncident(
    id: 'ae_firin_maliyet',
    title: 'Un ve yağ zamlandı',
    text: 'Un, şeker, yağ. Üçü birden.\n\n'
        'Vitrindeki fiyatı değiştirmek için bir hafta düşündün.',
    tags: <String>{'firin'},
    weight: 1.9,
    costShare: 0.050,
  ),
  BusinessIncident(
    id: 'ae_firin_elde_kaldi',
    title: 'Ürünler elde kaldı',
    text: 'Akşam vitrin hâlâ doluydu.\n\n'
        'Sabaha kalanı kimse almaz.',
    tags: <String>{'firin', 'perakende'},
    weight: 1.7,
    costShare: 0.030,
  ),
  BusinessIncident(
    id: 'ae_firin_bayram_siparisi',
    title: 'Bayram siparişi patladı',
    text: 'Bayram öncesi telefon susmadı.\n\n'
        'Üç gün fırın hiç sönmedi.',
    tags: <String>{'bayram'},
    weight: 1.5,
    demandShift: 1.28,
    moraleDelta: -6,
  ),
  BusinessIncident(
    id: 'ae_ozel_siparis',
    title: 'Özel sipariş',
    text: 'Bir düğün için büyük bir sipariş geldi.\n\n'
        'İşi teslim ettiğinde arkandan konuşulan şey iyi bir şeydi.',
    tags: <String>{'firin', 'dugun'},
    weight: 1.3,
    demandShift: 1.12,
    reputationDelta: 6,
    minReputation: 40,
  ),

  // ===================================================================
  // §17 — Nakliye
  // ===================================================================
  BusinessIncident(
    id: 'ae_nakliye_ariza',
    title: 'Araç arızalandı',
    text: 'Yolun ortasında kaldın.\n\n'
        'Çekici bekledin, yükü müşteriye bir gün geç götürdün.',
    tags: <String>{'arac'},
    weight: 2.0,
    costShare: 0.068,
    upkeepDelta: -17,
    reputationDelta: -5,
    requiresEquipment: true,
    major: true,
  ),
  BusinessIncident(
    id: 'ae_nakliye_sofor',
    title: 'Şoför işi bıraktı',
    text: 'Bir sabah anahtarı masaya bıraktı.\n\n'
        'Yükü o gün sen taşıdın.',
    tags: <String>{'nakliye'},
    weight: 1.9,
    requiresStaff: true,
    staffLoss: 1,
    demandShift: 0.90,
    major: true,
  ),
  BusinessIncident(
    id: 'ae_nakliye_yakit',
    title: 'Yakıt zamlandı',
    text: 'Pompada rakamı görünce bir süre durdun.\n\n'
        'Fiyat listeni aynı gün değiştirmedin. Değiştirmen gerekiyordu.',
    tags: <String>{'nakliye'},
    weight: 2.1,
    costShare: 0.054,
  ),
  BusinessIncident(
    id: 'ae_nakliye_buyuk_musteri',
    title: 'Büyük müşteri',
    text: 'Bir depo bütün sevkiyatını sana verdi.\n\n'
        'Takvimin bir anda doldu.',
    tags: <String>{'nakliye'},
    weight: 1.4,
    demandShift: 1.26,
    lastingShift: 1.10,
    conditionDelta: 4,
    minReputation: 45,
  ),
  BusinessIncident(
    id: 'ae_nakliye_iptal',
    title: 'Sözleşme iptal',
    text: 'En çok iş aldığın yer sözleşmeyi yenilemedi.\n\n'
        'Sebep söylemediler.',
    tags: <String>{'nakliye'},
    weight: 1.5,
    demandShift: 0.82,
    lastingShift: 0.88,
    major: true,
  ),
  BusinessIncident(
    id: 'ae_nakliye_sezon',
    title: 'Yoğun sezon',
    text: 'Taşınma mevsimi başladı.\n\n'
        'Bir ay boyunca boş gün olmadı.',
    tags: <String>{'nakliye'},
    weight: 1.6,
    demandShift: 1.18,
  ),

  // ===================================================================
  // §18 — Bakkal / büfe / kuruyemişçi
  // ===================================================================
  BusinessIncident(
    id: 'ae_perakende_dolap',
    title: 'Dolap bozuldu',
    text: 'Soğutucu gece durmuş.\n\n'
        'Sabah içindekilerin bir kısmını çöpe attın.',
    tags: <String>{'perakende'},
    weight: 1.8,
    costShare: 0.055,
    upkeepDelta: -16,
    requiresEquipment: true,
    maxUpkeep: 84,
    major: true,
  ),
  BusinessIncident(
    id: 'ae_perakende_veresiye',
    title: 'Veresiye defteri',
    text: 'Defteri açtın, bir süre baktın.\n\n'
        'Yazan isimlerin yarısı mahalleden çoktan taşındı.',
    tags: <String>{'perakende'},
    weight: 1.9,
    costShare: 0.034,
  ),
  BusinessIncident(
    id: 'ae_perakende_zincir',
    title: 'Yakına zincir mağaza açıldı',
    text: 'Köşeye zincir market açıldı.\n\n'
        'Fiyatlarıyla yarışmanın bir yolu yok.',
    tags: <String>{'perakende'},
    weight: 1.3,
    demandShift: 0.80,
    lastingShift: 0.86,
    minYearsOpen: 3,
    major: true,
  ),
  BusinessIncident(
    id: 'ae_perakende_stok_kaybi',
    title: 'Stokta eksik',
    text: 'Sayım yaptın. Rakamlar tutmadı.\n\n'
        'İkinci kez saydın. Yine tutmadı.',
    tags: <String>{'perakende'},
    weight: 1.5,
    costShare: 0.026,
  ),
  BusinessIncident(
    id: 'ae_perakende_hareket',
    title: 'Mahalle canlandı',
    text: 'Karşıya yeni bir okul açıldı.\n\n'
        'Sabah ve ikindi dükkân doluyor.',
    tags: <String>{'perakende'},
    weight: 1.4,
    demandShift: 1.20,
    lastingShift: 1.08,
    conditionDelta: 3,
  ),
  BusinessIncident(
    id: 'ae_perakende_elde_kaldi',
    title: 'Mal elde kaldı',
    text: 'Fazla aldın, satamadın.\n\n'
        'Tarihi geçenleri ayırırken canın sıkıldı.',
    tags: <String>{'perakende'},
    weight: 1.6,
    costShare: 0.029,
  ),

  // ===================================================================
  // §19 — Kuaför
  // ===================================================================
  BusinessIncident(
    id: 'ae_kuafor_ekipman',
    title: 'Ekipman bozuldu',
    text: 'Koltuğun pompası indi, bir daha kalkmadı.\n\n'
        'O gün herkesi tek koltukta idare ettin.',
    tags: <String>{'kuafor'},
    weight: 1.7,
    costShare: 0.048,
    upkeepDelta: -14,
    requiresEquipment: true,
    maxUpkeep: 84,
  ),
  BusinessIncident(
    id: 'ae_kuafor_paylasim',
    title: 'Paylaşım tuttu',
    text: 'Bir müşteri çıkışta fotoğraf paylaşmış.\n\n'
        'Ertesi hafta randevu defteri doldu.',
    tags: <String>{'kuafor', 'sosyal'},
    weight: 1.4,
    demandShift: 1.24,
    reputationDelta: 8,
    minReputation: 42,
  ),
  BusinessIncident(
    id: 'ae_dugun_sezonu',
    title: 'Düğün sezonu',
    text: 'Haziran geldi.\n\n'
        'Cumartesileri sabah yedide açıp gece yarısı kapattın.',
    tags: <String>{'dugun'},
    weight: 1.6,
    demandShift: 1.22,
    moraleDelta: -5,
  ),
  BusinessIncident(
    id: 'ae_kuafor_rakip',
    title: 'Rakip salon açıldı',
    text: 'Aynı sokağa bir salon daha açıldı.\n\n'
        'Vitrinleri seninkinden yeni.',
    tags: <String>{'kuafor'},
    weight: 1.3,
    demandShift: 0.86,
    lastingShift: 0.92,
    minYearsOpen: 3,
  ),

  // ===================================================================
  // §20 — Terzi
  // ===================================================================
  BusinessIncident(
    id: 'ae_terzi_makine',
    title: 'Makine bozuldu',
    text: 'Dikiş makinesi yarım işin ortasında durdu.\n\n'
        'Tamirci üç gün sonra gelebildi.',
    tags: <String>{'atolye'},
    weight: 1.7,
    costShare: 0.050,
    upkeepDelta: -15,
    requiresEquipment: true,
    maxUpkeep: 84,
  ),
  BusinessIncident(
    id: 'ae_terzi_kumas',
    title: 'Kumaş pahalandı',
    text: 'Toptancı yeni fiyatı söyledi.\n\n'
        'İki kere sordun, iki kere aynı rakamı duydun.',
    tags: <String>{'atolye'},
    weight: 1.6,
    costShare: 0.040,
  ),
  BusinessIncident(
    id: 'ae_terzi_toplu_siparis',
    title: 'Toplu sipariş',
    text: 'Bir yerden tek seferde otuz parça iş geldi.\n\n'
        'Bir ay boyunca ışığı gece yarısından önce söndürmedin.',
    tags: <String>{'atolye'},
    weight: 1.3,
    demandShift: 1.20,
    moraleDelta: -6,
    minReputation: 42,
  ),
  BusinessIncident(
    id: 'ae_terzi_yetismedi',
    title: 'İş yetişmedi',
    text: 'Söz verdiğin gün geldi, iş bitmedi.\n\n'
        'Müşteri bekledi. Bir daha gelmedi.',
    tags: <String>{'atolye'},
    weight: 1.5,
    reputationDelta: -8,
  ),

  // ===================================================================
  // §21 — Serbest yazılımcı (fiziksel dükkân olayları gelmez)
  // ===================================================================
  BusinessIncident(
    id: 'ae_serbest_iptal',
    title: 'Müşteri projeyi iptal etti',
    text: 'Üç aydır üstünde çalıştığın iş iptal edildi.\n\n'
        'Bir cümlelik mesaj geldi. Gerekçe yoktu.',
    tags: <String>{'serbest'},
    weight: 2.0,
    demandShift: 0.80,
    lastingShift: 0.91,
    major: true,
  ),
  BusinessIncident(
    id: 'ae_serbest_odeme',
    title: 'Ödeme gecikti',
    text: 'Faturayı kestin. Bir ay geçti.\n\n'
        'Hatırlattın. Bir ay daha geçti.',
    tags: <String>{'serbest'},
    weight: 2.1,
    costShare: 0.055,
  ),
  BusinessIncident(
    id: 'ae_serbest_buyuk_proje',
    title: 'Büyük proje',
    text: 'Bir yerden ciddi bir iş geldi.\n\n'
        'Rakamı duyunca telefonu iki elinle tuttun.',
    tags: <String>{'serbest'},
    weight: 1.5,
    demandShift: 1.34,
    minReputation: 45,
  ),
  BusinessIncident(
    id: 'ae_serbest_kapsam',
    title: 'Kapsam büyüdü',
    text: '"Ufak bir ekleme daha yapsak?"\n\n'
        'Beşinci kez aynı cümleyi duydun.',
    tags: <String>{'serbest'},
    weight: 1.8,
    costShare: 0.030,
    moraleDelta: -4,
  ),
  BusinessIncident(
    id: 'ae_serbest_referans',
    title: 'Referansla iş geldi',
    text: 'Eski bir müşteri seni başkasına anlatmış.\n\n'
        'Hiç tanımadığın biri aradı.',
    tags: <String>{'serbest'},
    weight: 1.5,
    demandShift: 1.18,
    reputationDelta: 6,
    minReputation: 40,
  ),
  BusinessIncident(
    id: 'ae_serbest_bilgisayar',
    title: 'Bilgisayar arızalandı',
    text: 'Ekran bir sabah açılmadı.\n\n'
        'Yedek aldığın günü hatırlamaya çalıştın.',
    tags: <String>{'serbest'},
    weight: 1.4,
    costShare: 0.060,
    upkeepDelta: -20,
    requiresEquipment: true,
    major: true,
  ),
  BusinessIncident(
    id: 'ae_serbest_tukenme',
    title: 'Tükendin',
    text: 'Üç ay boyunca hafta sonu diye bir şey olmadı.\n\n'
        'Sonunda bir sabah bilgisayarı hiç açmadın.',
    tags: <String>{'serbest'},
    weight: 1.6,
    conditionDelta: -9,
    demandShift: 0.90,
  ),

  // ===================================================================
  // §22 — Oto yıkama
  // ===================================================================
  BusinessIncident(
    id: 'ae_yikama_su_kesintisi',
    title: 'Su kesildi',
    text: 'Sabah vanayı açtın, ses geldi ama su gelmedi.\n\n'
        'Gelen araçlara bir şey diyemedin.',
    tags: <String>{'yikama'},
    weight: 1.8,
    demandShift: 0.86,
    costShare: 0.014,
  ),
  BusinessIncident(
    id: 'ae_yikama_basinc',
    title: 'Basınç makinesi bozuldu',
    text: 'Makine öksüre öksüre durdu.\n\n'
        'Yedek hortumla idare etmeye çalıştın. Olmadı.',
    tags: <String>{'yikama'},
    weight: 1.8,
    costShare: 0.058,
    upkeepDelta: -17,
    demandShift: 0.90,
    requiresEquipment: true,
    maxUpkeep: 84,
    major: true,
  ),
  BusinessIncident(
    id: 'ae_yikama_yagmurlu',
    title: 'Yağmurlu dönem',
    text: 'İki hafta boyunca hiç durmadan yağdı.\n\n'
        'Kimse arabasını yıkatmadı.',
    tags: <String>{'yikama'},
    weight: 2.0,
    demandShift: 0.80,
  ),
  BusinessIncident(
    id: 'ae_yikama_toz',
    title: 'Toz dönemi',
    text: 'Bir hafta boyunca gökyüzü sarıydı.\n\n'
        'Ertesi hafta kapının önünde kuyruk vardı.',
    tags: <String>{'yikama'},
    weight: 1.7,
    demandShift: 1.26,
  ),
  BusinessIncident(
    id: 'ae_yikama_rakip',
    title: 'Rakip yıkamacı açıldı',
    text: 'Aynı caddeye bir yıkamacı daha açıldı.\n\n'
        'İlk ay yarı fiyata yıkıyorlar.',
    tags: <String>{'yikama'},
    weight: 1.3,
    demandShift: 0.85,
    lastingShift: 0.90,
    minYearsOpen: 2,
  ),

  // ===================================================================
  // §24 — Afet ve beklenmedik olay (ÇOK nadir, uygun mekânlara)
  // ===================================================================
  BusinessIncident(
    id: 'ae_afet_sel',
    title: 'Dükkânı su bastı',
    text: 'Gece sağanak başladı.\n\n'
        'Sabah kepengi kaldırdığında su diz boyuydu.\n\n'
        'İçeride ne varsa ıslandı.',
    tags: <String>{'dukkan', 'tesis', 'saha'},
    weight: 0.28,
    costShare: 0.190,
    upkeepDelta: -34,
    conditionDelta: -12,
    demandShift: 0.78,
    minYearsOpen: 3,
    major: true,
  ),
  BusinessIncident(
    id: 'ae_afet_yangin',
    title: 'Küçük yangın',
    text: 'Gece bir kontak yapmış.\n\n'
        'İtfaiye erken yetişti. Yine de duvarın yarısı is içinde.',
    tags: <String>{'dukkan', 'mutfak', 'firin', 'atolye'},
    weight: 0.22,
    costShare: 0.240,
    upkeepDelta: -42,
    conditionDelta: -15,
    demandShift: 0.72,
    minYearsOpen: 3,
    major: true,
  ),
  BusinessIncident(
    id: 'ae_afet_elektrik',
    title: 'Elektrik arızası',
    text: 'Üç gün boyunca elektrik bir gelip bir gitti.\n\n'
        'Üçüncü gün panoyu komple değiştirmek gerekti.',
    tags: <String>{'dukkan', 'tesis', 'salon', 'yikama'},
    weight: 0.42,
    costShare: 0.110,
    upkeepDelta: -18,
    demandShift: 0.88,
    minYearsOpen: 2,
    major: true,
  ),
];
