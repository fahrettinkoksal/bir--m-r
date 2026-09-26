/// Aktivite katalogları: berber, spor salonu, kütüphane, sağlık merkezi,
/// eğlence ve kurslar.
///
/// Ücretler, etkiler ve tekrar sınırları `prototypeOnly`'dir
/// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-049 ve Q-086).
library;

import 'package:flutter/material.dart';

import '../domain/life/health_report.dart';

/// Aktivitenin hangi alanda olduğu.
enum ActivityVenue {
  berber('Berber / Kuaför', Icons.content_cut_rounded),
  sporSalonu('Spor salonu', Icons.fitness_center_rounded),
  kutuphane('Kütüphane', Icons.local_library_rounded),

  /// Paket 18: gündelik sağlık bakımı. Kriz beklemeden sağlığa bakmanın
  /// bir yolu yoktu.
  saglikMerkezi('Sağlık Merkezi', Icons.medical_services_rounded),

  /// Paket 18: mutluluğu gerçekten yükselten gündelik eğlenceler.
  eglence('Eğlence', Icons.celebration_rounded),

  /// Paket 18: okul dışında öğrenilen şeyler.
  kurs('Kurslar', Icons.palette_rounded),

  /// Paket 27: kahve falı, tarot ve burç yorumu.
  falTarot('Fal ve Tarot', Icons.auto_awesome_rounded),

  /// D-077: estetik işlemler. Görünüş yaşla düştüğü için (D-072)
  /// oyuncunun buna karşı yapabileceği bir şey olmalı.
  ///
  /// Yeni değerler listenin **sonuna** eklenir; eski kayıtlar bozulmasın.
  estetik('Estetik', Icons.face_retouching_natural_rounded),

  /// D-128: yalnızca cezaevindeyken açılan, güvenli ve genel
  /// aktiviteler. Burada suç mekaniği **yoktur**.
  ///
  /// Yeni değerler listenin **sonuna** eklenir; eski kayıtlar bozulmasın.
  cezaevi('Cezaevi', Icons.gavel_rounded);

  const ActivityVenue(this.label, this.icon);

  final String label;
  final IconData icon;

  /// Bu mekânda en erken hangi yaşta bir şey yapılabilir?
  ///
  /// Menüde yaşına hiç uymayan bir alan gösterilmesin diye kullanılır:
  /// çalışmayan düğme konmaz.
  /// Eylem listesi boş olan mekân (kütüphane kendi kitap akışıyla
  /// çalışır) **0** döndürür. Eskiden 120 dönüyordu: menü bu değeri
  /// "yaşın yetmiyor" diye okuduğu için, eylemsiz bir mekâna bir gün
  /// yaş koşulu eklenirse o mekân hiçbir yaşta açılmazdı.
  int get minAge {
    int enKucuk = 120;
    for (final ActivityAction a in actionsAt(this)) {
      if (a.minAge < enKucuk) enKucuk = a.minAge;
    }
    return enKucuk == 120 ? 0 : enKucuk;
  }
}

/// Tek bir aktivite eylemi.
@immutable
class ActivityAction {
  const ActivityAction({
    required this.id,
    required this.venue,
    required this.label,
    required this.description,
    required this.icon,
    this.cost = 0,
    this.minAge = 0,
    this.appearance = 0,
    this.charisma = 0,
    this.happiness = 0,
    this.health = 0,
    this.intelligence = 0,
    this.maxPerAge = 2,
    this.changesHairStyle = false,
    this.requiresFlag,
    this.clearsFlag,
    this.setsFlag,
    this.reducesHairLoss = false,
    this.riskChance = 0,
    this.minAgeNote,
    this.onlyInPrison = false,
  });

  /// Yalnızca cezaevindeyken yapılabilir mi? (D-128)
  ///
  /// Cezaevi eylemleri dışarıda, dışarının eylemleri içeride açılmaz.
  final bool onlyInPrison;

  final String id;
  final ActivityVenue venue;
  final String label;
  final String description;
  final IconData icon;

  /// prototypeOnly: cüzdandan düşen ücret (₺).
  final int cost;

  /// prototypeOnly: en küçük yaş.
  final int minAge;

  /// prototypeOnly: tam etkiyle uygulandığında kazanılan değerler.
  final int appearance;
  final int charisma;
  final int happiness;
  final int health;

  /// prototypeOnly: kurslarda öğrenilen şeyin zekâya katkısı.
  final int intelligence;

  /// prototypeOnly: aynı yaşta kaç kez anlamlı sonuç verir.
  ///
  /// Sınıra ulaşıldığında eylem kapanır; sınırsız stat kasma olmaz.
  final int maxPerAge;

  /// Saç stilini değiştiren eylem mi?
  final bool changesHairStyle;

  /// Bu eylemin açılması için gereken hikâye izi.
  ///
  /// Tahlile yönlendirilmeden "Tahlile git" düğmesi görünmez (D-076).
  final String? requiresFlag;

  /// Eylem başarıyla yapıldığında **silinen** hikâye izi.
  final String? clearsFlag;

  /// Eylem başarıyla yapıldığında **eklenen** hikâye izi.
  final String? setsFlag;

  /// Saç dökülmesi basamağını bir kademe düşürür mü? (D-077)
  final bool reducesHairLoss;

  /// prototypeOnly: işlemin istenen sonucu vermeme ihtimali.
  ///
  /// Estetik işlemler risksiz değildir. Kötü sonuçta kazanç uygulanmaz,
  /// ücret yine ödenir ve mutluluk düşer — gerçek hayatta da böyle.
  final double riskChance;

  /// Yaş sınırının **gerekçesi**; kapalı düğmede gösterilir.
  final String? minAgeNote;
}

const List<ActivityAction> kActivityActions = <ActivityAction>[
  // --- Fal ve Tarot (Paket 27) -----------------------------------------
  // Sonuç metni rastgele seçilir ve mutluluğu **hem artırabilir hem
  // düşürebilir**; bu yüzden etkiler burada sıfırdır, motor uygular.
  ActivityAction(
    id: 'kahve_fali',
    venue: ActivityVenue.falTarot,
    label: 'Kahve falına baktır',
    description: 'Fincan ters çevrilir, beklenir, sonra biri bakar.',
    icon: Icons.coffee_rounded,
    cost: 450, // prototypeOnly
    minAge: 14,
    maxPerAge: 2,
  ),
  ActivityAction(
    id: 'tarot_actir',
    venue: ActivityVenue.falTarot,
    label: 'Tarot açtır',
    description: 'Deste karılır, tek kart çekilir. Gerisi yoruma kalmış.',
    icon: Icons.style_rounded,
    cost: 1200, // prototypeOnly
    minAge: 16,
    maxPerAge: 2,
  ),
  ActivityAction(
    id: 'burc_yorumu',
    venue: ActivityVenue.falTarot,
    label: 'Burç yorumunu oku',
    description: 'Ücretsiz. Gazetede, telefonda, her yerde.',
    icon: Icons.nights_stay_rounded,
    minAge: 10,
    maxPerAge: 3,
  ),

  // --- Berber -----------------------------------------------------------
  ActivityAction(
    id: 'sac_kestir',
    venue: ActivityVenue.berber,
    label: 'Saç kestir',
    description: 'Klasik tıraş. Ense temiz, ayna iki taraflı.',
    icon: Icons.content_cut_outlined,
    cost: 350, // prototypeOnly
    minAge: 4,
    appearance: 3,
    happiness: 1,
    maxPerAge: 2,
  ),
  ActivityAction(
    id: 'sac_stili',
    venue: ActivityVenue.berber,
    label: 'Saç stilini değiştir',
    description:
        'Yeni bir model dene. Bazen iyi gider, bazen saç uzamasını '
        'beklersin.',
    icon: Icons.auto_fix_high_outlined,
    cost: 800, // prototypeOnly
    minAge: 10,
    appearance: 4,
    charisma: 2,
    maxPerAge: 1,
    changesHairStyle: true,
  ),
  ActivityAction(
    id: 'sakal_bakim',
    venue: ActivityVenue.berber,
    label: 'Bakım yaptır',
    description: 'Yıkama, düzeltme ve biraz kolonya.',
    icon: Icons.spa_outlined,
    cost: 90, // prototypeOnly
    minAge: 12,
    appearance: 2,
    happiness: 2,
    maxPerAge: 2,
  ),

  // --- Spor salonu -------------------------------------------------------
  ActivityAction(
    id: 'kosu',
    venue: ActivityVenue.sporSalonu,
    label: 'Koşu yap',
    description: 'Bandın üstünde kırk dakika; ilk on dakika en zoru.',
    icon: Icons.directions_run_outlined,
    cost: 60, // prototypeOnly
    minAge: 12,
    health: 4,
    happiness: 1,
    maxPerAge: 3,
  ),
  ActivityAction(
    id: 'agirlik',
    venue: ActivityVenue.sporSalonu,
    label: 'Ağırlık kaldır',
    description: 'Ağırlıklar, sayılan tekrarlar ve ertesi gün ağrıyan her yer.',
    icon: Icons.fitness_center_outlined,
    cost: 60, // prototypeOnly
    minAge: 14,
    health: 3,
    appearance: 3,
    maxPerAge: 3,
  ),
  ActivityAction(
    id: 'esneme',
    venue: ActivityVenue.sporSalonu,
    label: 'Esneme ve temel egzersiz',
    description: 'Sakin bir ısınma; kalp atışı yerine nefes sayılır.',
    icon: Icons.self_improvement_outlined,
    cost: 0,
    minAge: 8,
    health: 2,
    happiness: 2,
    maxPerAge: 3,
  ),

  // --- Sağlık Merkezi (Paket 18) ----------------------------------------
  //
  // Oyunda sağlığa ancak kriz çıkınca dokunulabiliyordu. Burası, sağlığı
  // **kriz beklemeden** koruma yeri. Hiçbiri tıbbi tavsiye değildir;
  // oyun içi kurgudur.
  ActivityAction(
    id: 'genel_kontrol',
    venue: ActivityVenue.saglikMerkezi,
    label: 'Genel sağlık kontrolü',
    description:
        'Tansiyon, tahlil, kısa bir muayene. Çoğu yıl bir şey '
        'çıkmaz; çıkarsa erken çıkar.',
    icon: Icons.monitor_heart_outlined,
    cost: 2800, // prototypeOnly
    minAge: 3,
    health: 5,
    maxPerAge: 1,
  ),
  ActivityAction(
    id: 'dis_kontrol',
    venue: ActivityVenue.saglikMerkezi,
    label: 'Diş kontrolü',
    description: 'Koltuk arkaya yatar, ışık gözüne gelir, on dakikada biter.',
    icon: Icons.sentiment_satisfied_outlined,
    cost: 2000, // prototypeOnly
    minAge: 5,
    appearance: 3,
    health: 2,
    maxPerAge: 1,
  ),
  ActivityAction(
    id: 'goz_muayenesi',
    venue: ActivityVenue.saglikMerkezi,
    label: 'Göz muayenesi',
    description:
        'Duvardaki harfler gittikçe küçülüyor. En alt satır herkese '
        'aynı şeyi sormuyor.',
    icon: Icons.remove_red_eye_outlined,
    cost: 1400, // prototypeOnly
    minAge: 6,
    health: 2,
    maxPerAge: 1,
  ),
  ActivityAction(
    id: 'mevsim_asisi',
    venue: ActivityVenue.saglikMerkezi,
    label: 'Mevsim aşısı',
    description:
        'Kısa bir iğne, bir gün kolun ağrır, kış biraz daha kolay '
        'geçer.',
    icon: Icons.vaccines_outlined,
    cost: 900, // prototypeOnly
    minAge: 1,
    health: 3,
    maxPerAge: 1,
  ),
  ActivityAction(
    id: 'ruh_sagligi',
    venue: ActivityVenue.saglikMerkezi,
    label: 'Bir uzmanla konuş',
    description:
        'Kırk beş dakika boyunca yalnızca sen konuşuyorsun ve '
        'kimse sözünü kesmiyor.',
    icon: Icons.psychology_outlined,
    cost: 4500, // prototypeOnly
    minAge: 12,
    happiness: 9,
    health: 1,
    maxPerAge: 2,
  ),

  // Tahlil yalnızca check-up sonrası açılır (D-076): hekim
  // yönlendirmediyse bu düğme menüde durmaz.
  ActivityAction(
    id: 'tahlil',
    venue: ActivityVenue.saglikMerkezi,
    label: 'Tahlile git',
    description:
        'Hekimin işaretlediği değerler için kan verilecek. Sonuç aynı '
        'gün çıkıyor.',
    icon: Icons.science_outlined,
    cost: 3600, // prototypeOnly
    minAge: 3,
    health: 3,
    maxPerAge: 1,
    requiresFlag: HealthChecks.labTestFlag,
    clearsFlag: HealthChecks.labTestFlag,
  ),

  // --- Estetik (D-077) ---------------------------------------------------
  //
  // Görünüş yaşla düşüyor (D-072) ve erkeklerde saç dökülebiliyor
  // (D-073). Oyuncunun buna karşı yapabileceği bir şey olmalıydı.
  //
  // Fiyatlar 2026 ölçeğindedir (D-053) ve Türkiye piyasasının gerçek
  // aralıklarına dayanır; tek tek tutarlar `prototypeOnly` (Q-119).
  // Hiçbiri tıbbi tavsiye değildir.
  //
  // Her işlemin bir **riski** vardır: kötü sonuçta ücret yine ödenir,
  // kazanç uygulanmaz ve mutluluk düşer.
  ActivityAction(
    id: 'kas_dolgusu',
    venue: ActivityVenue.estetik,
    label: 'Kaş ve yüz dolgusu',
    description:
        'Küçük bir iğne, yarım saat. Şişlik birkaç günde iner.',
    icon: Icons.brush_outlined,
    cost: 22000, // prototypeOnly
    minAge: 20,
    minAgeNote: 'Estetik işlemler için erişkin olman gerekiyor.',
    appearance: 4,
    maxPerAge: 1,
    riskChance: 0.12,
  ),
  ActivityAction(
    id: 'dis_estetigi',
    venue: ActivityVenue.estetik,
    label: 'Gülüş tasarımı',
    description:
        'Ölçü alındı, kaplamalar hazırlandı. Aynada ilk gülüşün '
        'tuhaf geliyor, sonra alışıyorsun.',
    icon: Icons.sentiment_very_satisfied_outlined,
    cost: 185000, // prototypeOnly
    minAge: 18,
    minAgeNote: 'Estetik işlemler için erişkin olman gerekiyor.',
    appearance: 7,
    charisma: 2,
    maxPerAge: 1,
    riskChance: 0.1,
  ),
  ActivityAction(
    id: 'goz_kapagi',
    venue: ActivityVenue.estetik,
    label: 'Göz kapağı estetiği',
    description:
        'Üst kapaktaki fazlalık alınıyor. Bir hafta morluk, sonra '
        'bakışın açılıyor.',
    icon: Icons.visibility_outlined,
    cost: 90000, // prototypeOnly
    minAge: 30,
    minAgeNote: 'Bu işlem genellikle otuzundan sonra gündeme geliyor.',
    appearance: 6,
    maxPerAge: 1,
    riskChance: 0.14,
  ),
  ActivityAction(
    id: 'burun_ameliyati',
    venue: ActivityVenue.estetik,
    label: 'Burun estetiği',
    description:
        'Ameliyathane, genel anestezi ve iki hafta şişlik. Sonucu '
        'altı ay sonra tam görüyorsun.',
    icon: Icons.face_outlined,
    cost: 145000, // prototypeOnly
    minAge: 18,
    minAgeNote: 'Burun gelişimi tamamlanmadan bu ameliyat yapılmıyor.',
    appearance: 9,
    charisma: 2,
    health: -2,
    maxPerAge: 1,
    riskChance: 0.18,
  ),
  ActivityAction(
    id: 'sac_ekimi',
    venue: ActivityVenue.estetik,
    label: 'Saç ektir',
    description:
        'Uzun bir gün, ensenden alınan kökler öne taşınıyor. Sonuç '
        'bir yılda oturuyor.',
    icon: Icons.content_cut_rounded,
    cost: 95000, // prototypeOnly
    minAge: 25,
    minAgeNote: 'Dökülme oturmadan saç ekimi önerilmiyor.',
    appearance: 5,
    charisma: 3,
    maxPerAge: 1,
    reducesHairLoss: true,
    riskChance: 0.15,
  ),

  // --- Eğlence (Paket 18) ------------------------------------------------
  //
  // Mutluluğu yükseltmenin tek yolu olayların rastgele iyi gitmesiydi.
  // Burası mutluluğa **kendi isteğinle** dokunabildiğin yer.
  ActivityAction(
    id: 'parkta_yuruyus',
    venue: ActivityVenue.eglence,
    label: 'Parkta yürüyüş',
    description:
        'Ücretsiz, yakın ve her yaşa uygun. Bir tur, iki tur, '
        'sonra bir bank.',
    icon: Icons.park_outlined,
    cost: 0,
    minAge: 4,
    happiness: 2,
    health: 1,
    maxPerAge: 3,
  ),
  ActivityAction(
    id: 'sinema',
    venue: ActivityVenue.eglence,
    label: 'Sinemaya git',
    description:
        'Işıklar sönüyor, koltuk arkaya yaslanıyor, iki saat '
        'boyunca başka bir hayat.',
    icon: Icons.movie_outlined,
    cost: 750, // prototypeOnly
    minAge: 5,
    happiness: 5,
    maxPerAge: 3,
  ),
  ActivityAction(
    id: 'kafede_otur',
    venue: ActivityVenue.eglence,
    label: 'Kafede otur',
    description: 'Bir çay, uzun bir sohbet ve camdan dışarıyı seyretmek.',
    icon: Icons.local_cafe_outlined,
    cost: 600, // prototypeOnly
    minAge: 11,
    happiness: 3,
    charisma: 1,
    maxPerAge: 3,
  ),
  ActivityAction(
    id: 'maca_git',
    venue: ActivityVenue.eglence,
    label: 'Maça git',
    description:
        'Tribün ayakta, ses kulağında, sonuç ne olursa olsun akşam '
        'konuşulacak bir şey var.',
    icon: Icons.sports_soccer_outlined,
    cost: 1700, // prototypeOnly
    minAge: 8,
    happiness: 7,
    maxPerAge: 2,
  ),
  ActivityAction(
    id: 'konsere_git',
    venue: ActivityVenue.eglence,
    label: 'Konsere git',
    description: 'Kalabalık, ışık ve herkesin aynı sözü bildiği o an.',
    icon: Icons.music_note_outlined,
    cost: 2900, // prototypeOnly
    minAge: 13,
    happiness: 9,
    charisma: 1,
    maxPerAge: 2,
  ),

  // --- Kurslar (Paket 18) ------------------------------------------------
  //
  // Okul dışında bir şey öğrenmenin yolu yoktu; kütüphane yalnızca
  // okumaydı.
  ActivityAction(
    id: 'resim_atolyesi',
    venue: ActivityVenue.kurs,
    label: 'Resim atölyesi',
    description: 'Önlük, fırça ve kuruması beklenen bir tuval.',
    icon: Icons.brush_outlined,
    cost: 5000, // prototypeOnly
    minAge: 6,
    happiness: 4,
    charisma: 1,
    maxPerAge: 2,
  ),
  ActivityAction(
    id: 'muzik_kursu',
    venue: ActivityVenue.kurs,
    label: 'Müzik kursu',
    description:
        'İlk hafta parmaklar acıyor, üçüncü hafta bir şeye '
        'benziyor.',
    icon: Icons.piano_outlined,
    cost: 12000, // prototypeOnly
    minAge: 7,
    charisma: 3,
    happiness: 3,
    maxPerAge: 2,
  ),
  ActivityAction(
    id: 'dil_kursu',
    venue: ActivityVenue.kurs,
    label: 'Dil kursu',
    description:
        'Yeni bir dilde ilk cümleni kurmak, ilk cümleni kurduğun '
        'günkü kadar tuhaf.',
    icon: Icons.translate_outlined,
    cost: 14000, // prototypeOnly
    minAge: 10,
    intelligence: 4,
    charisma: 1,
    maxPerAge: 2,
  ),
  ActivityAction(
    id: 'bilgisayar_kursu',
    venue: ActivityVenue.kurs,
    label: 'Bilgisayar kursu',
    description:
        'Ekranda çalışmayan bir şey var ve sebebini bulmak '
        'sandığından uzun sürüyor.',
    icon: Icons.terminal_outlined,
    cost: 16000, // prototypeOnly
    minAge: 13,
    intelligence: 5,
    maxPerAge: 2,
  ),

  // --- Kurslar: ikinci tur (D-152) ---------------------------------------
  //
  // Hobi kataloğu dört hobiyle dardı ve "ne yapsam" diye bakan oyuncuya
  // verecek şeyi azdı. Buradaki her kurs **gerçek bir hobiyi** besler
  // (`hobby_catalog.dart`); beslemeyen süs eylemi eklenmedi.
  ActivityAction(
    id: 'yemek_kursu',
    venue: ActivityVenue.kurs,
    label: 'Yemek kursu',
    description:
        'Soğan doğramanın bir yolu varmış, yıllardır yanlış '
        'yapıyormuşsun.',
    icon: Icons.restaurant_menu_outlined,
    cost: 7500, // prototypeOnly
    minAge: 12,
    happiness: 4,
    charisma: 1,
    maxPerAge: 2,
  ),
  ActivityAction(
    id: 'fotograf_kursu',
    venue: ActivityVenue.kurs,
    label: 'Fotoğraf kursu',
    description:
        'Işığı beklemeyi öğreniyorsun; kareyi acele eden kaçırıyor.',
    icon: Icons.photo_camera_outlined,
    cost: 9500, // prototypeOnly
    minAge: 11,
    happiness: 4,
    intelligence: 1,
    maxPerAge: 2,
  ),
  ActivityAction(
    id: 'dans_kursu',
    venue: ActivityVenue.kurs,
    label: 'Dans kursu',
    description:
        'Ayaklar sayıyor, beden saymamayı öğrenene kadar sayıyor.',
    icon: Icons.music_video_outlined,
    cost: 8500, // prototypeOnly
    minAge: 8,
    happiness: 5,
    charisma: 3,
    health: 1,
    maxPerAge: 2,
  ),
  ActivityAction(
    id: 'satranc_kulubu',
    venue: ActivityVenue.kurs,
    label: 'Satranç kulübü',
    description:
        'Tahtanın karşısında oturan kişi bazen kendinden başkası '
        'değil.',
    icon: Icons.grid_on_outlined,
    cost: 3200, // prototypeOnly
    minAge: 7,
    intelligence: 4,
    happiness: 2,
    maxPerAge: 2,
  ),
  ActivityAction(
    id: 'yazarlik_atolyesi',
    venue: ActivityVenue.kurs,
    label: 'Yazarlık atölyesi',
    description:
        'Bir cümleyi on kere kurup dokuzunu çiziyorsun; kalan biri '
        'de durmuyor.',
    icon: Icons.edit_note_outlined,
    cost: 11000, // prototypeOnly
    minAge: 14,
    intelligence: 3,
    charisma: 2,
    maxPerAge: 2,
  ),
  ActivityAction(
    id: 'bahce_atolyesi',
    venue: ActivityVenue.kurs,
    label: 'Bahçe atölyesi',
    description:
        'Toprak sabırla konuşuyor; sen acele ettikçe o susuyor.',
    icon: Icons.local_florist_outlined,
    cost: 4800, // prototypeOnly
    minAge: 9,
    happiness: 5,
    health: 1,
    maxPerAge: 2,
  ),

  // =====================================================================
  // Cezaevi (D-128)
  //
  // İçerideyken yapılabilecek **güvenli ve genel** şeyler. Burada suç
  // mekaniği yoktur; amaç oyuncunun o yılları boş geçirmemesi.
  // =====================================================================
  ActivityAction(
    id: 'cezaevi_gorus',
    venue: ActivityVenue.cezaevi,
    label: 'Görüşe çık',
    description: 'Camın öbür tarafında tanıdık bir yüz.',
    icon: Icons.record_voice_over_outlined,
    happiness: 5,
    maxPerAge: 3,
    onlyInPrison: true,
  ),
  ActivityAction(
    id: 'cezaevi_kitap',
    venue: ActivityVenue.cezaevi,
    label: 'Kitap oku',
    description: 'Kütüphanede üç raf var; üçünü de bitireceksin.',
    icon: Icons.menu_book_outlined,
    intelligence: 4,
    happiness: 1,
    maxPerAge: 3,
    onlyInPrison: true,
  ),
  ActivityAction(
    id: 'cezaevi_spor',
    venue: ActivityVenue.cezaevi,
    label: 'Spor yap',
    description: 'Avluda tur. Sayıyorsun, sonra saymayı bırakıyorsun.',
    icon: Icons.fitness_center_rounded,
    health: 4,
    happiness: 1,
    maxPerAge: 3,
    onlyInPrison: true,
  ),
  ActivityAction(
    id: 'cezaevi_sakin',
    venue: ActivityVenue.cezaevi,
    label: 'Sakin kal',
    description: 'Tartışmanın kenarından dolaş. En zor olanı bu.',
    icon: Icons.self_improvement_rounded,
    happiness: 2,
    charisma: 1,
    maxPerAge: 3,
    onlyInPrison: true,
  ),
];

List<ActivityAction> actionsAt(ActivityVenue venue) => kActivityActions
    .where((ActivityAction a) => a.venue == venue)
    .toList(growable: false);

ActivityAction? activityActionById(String id) {
  for (final ActivityAction a in kActivityActions) {
    if (a.id == id) return a;
  }
  return null;
}

/// prototypeOnly: saç stilleri. Görsel bir karakter sistemi henüz yok;
/// seçilen stil metin olarak saklanır.
const List<String> kHairStyles = <String>[
  'Kısa ve sade',
  'Yana ayrılmış',
  'Dağınık',
  'Kısacık',
  'Uzun ve toplu',
  'Kıvırcık bırakılmış',
];

// =======================================================================
// Kitaplar
// =======================================================================

/// Kitabın türü.
enum BookKind {
  cocuk('Çocuk kitabı'),
  macera('Macera'),
  roman('Roman'),
  bilim('Bilim'),
  klasik('Klasik');

  const BookKind(this.label);

  final String label;
}

/// Kütüphanedeki bir kitap.
///
/// Metinler özgündür; telifli eserlerin içeriği kullanılmaz. Sayfalar
/// ekranda soyut satır çizgileriyle gösterilir.
@immutable
class BookInfo {
  const BookInfo({
    required this.id,
    required this.title,
    required this.author,
    required this.kind,
    required this.pages,
    required this.minAge,
    required this.maxAge,
    required this.intelligenceGain,
    this.happinessGain = 0,
    this.charismaGain = 0,
  });

  final String id;
  final String title;

  /// Özgün, oyuna ait yazar adı.
  final String author;
  final BookKind kind;

  /// Kaç sayfa çevrilince biter (prototypeOnly).
  final int pages;

  final int minAge;
  final int maxAge;

  /// prototypeOnly: kitap **bitirildiğinde** bir kez uygulanan kazanç.
  final int intelligenceGain;
  final int happinessGain;
  final int charismaGain;

  bool fitsAge(int age) => age >= minAge && age <= maxAge;
}

const List<BookInfo> kBookCatalog = <BookInfo>[
  // --- İlkokul çağı: kısa ve kolay --------------------------------------
  BookInfo(
    id: 'kirmizi_bisiklet',
    title: 'Kırmızı Bisikletin Peşinde',
    author: 'Nihal Aydın',
    kind: BookKind.cocuk,
    pages: 6,
    minAge: 6,
    maxAge: 11,
    intelligenceGain: 2,
    happinessGain: 2,
  ),
  BookInfo(
    id: 'mahalle_kedisi',
    title: 'Mahallenin Kedisi',
    author: 'Sabri Gülen',
    kind: BookKind.cocuk,
    pages: 5,
    minAge: 6,
    maxAge: 10,
    intelligenceGain: 2,
    happinessGain: 2,
  ),
  BookInfo(
    id: 'kayip_anahtar',
    title: 'Kayıp Anahtar',
    author: 'Deniz Akman',
    kind: BookKind.macera,
    pages: 8,
    minAge: 9,
    maxAge: 14,
    intelligenceGain: 3,
    happinessGain: 1,
  ),

  // --- Ortaokul / lise ---------------------------------------------------
  BookInfo(
    id: 'ucuncu_kat',
    title: 'Üçüncü Kattaki Sessizlik',
    author: 'Melis Ergün',
    kind: BookKind.roman,
    pages: 14,
    minAge: 13,
    maxAge: 120,
    intelligenceGain: 4,
    charismaGain: 1,
  ),
  BookInfo(
    id: 'gokyuzu_defteri',
    title: 'Gökyüzü Defteri',
    author: 'Orhan Taşkın',
    kind: BookKind.bilim,
    pages: 16,
    minAge: 13,
    maxAge: 120,
    intelligenceGain: 5,
  ),

  // --- Lise sonu / üniversite --------------------------------------------
  BookInfo(
    id: 'uzun_kis',
    title: 'Uzun Kış',
    author: 'Bedri Yalçın',
    kind: BookKind.klasik,
    pages: 22,
    minAge: 16,
    maxAge: 120,
    intelligenceGain: 6,
    charismaGain: 1,
  ),
  BookInfo(
    id: 'sayilarin_dili',
    title: 'Sayıların Dili',
    author: 'Ayla Serin',
    kind: BookKind.bilim,
    pages: 24,
    minAge: 16,
    maxAge: 120,
    intelligenceGain: 7,
  ),
  // --- Q-110: kütüphane 8'den 23 kitaba çıkarıldı ------------------------
  //
  // Okuma hobisini yalnızca bitirilen kitaplar besliyor. Sekiz kitapla
  // merdivenin üst basamakları hiçbir hayatta ulaşılamıyordu; yazarlık
  // mesleği de bu yüzden açılamıyordu. Bütün adlar ve yazarlar özgündür.
  BookInfo(
    id: 'gokyuzu_defteri',
    title: 'Gökyüzü Defteri',
    author: 'Ela Sarıgül',
    kind: BookKind.cocuk,
    pages: 6,
    minAge: 6,
    maxAge: 11,
    intelligenceGain: 2,
    happinessGain: 2,
  ),
  BookInfo(
    id: 'tahta_kilic',
    title: 'Tahta Kılıç',
    author: 'Mert Özbay',
    kind: BookKind.macera,
    pages: 7,
    minAge: 7,
    maxAge: 12,
    intelligenceGain: 2,
    happinessGain: 3,
  ),
  BookInfo(
    id: 'komsunun_bahcesi',
    title: 'Komşunun Bahçesi',
    author: 'Sevil Tuna',
    kind: BookKind.cocuk,
    pages: 5,
    minAge: 6,
    maxAge: 10,
    intelligenceGain: 2,
    happinessGain: 2,
  ),
  BookInfo(
    id: 'gece_treni',
    title: 'Gece Treni',
    author: 'Kerem Alpaslan',
    kind: BookKind.macera,
    pages: 9,
    minAge: 10,
    maxAge: 16,
    intelligenceGain: 3,
    happinessGain: 2,
  ),
  BookInfo(
    id: 'sessiz_sinif',
    title: 'Sessiz Sınıf',
    author: 'Bahar Keskin',
    kind: BookKind.roman,
    pages: 12,
    minAge: 12,
    maxAge: 120,
    intelligenceGain: 3,
    charismaGain: 1,
  ),
  BookInfo(
    id: 'demir_kopru',
    title: 'Demir Köprü',
    author: 'Ozan Yılmazer',
    kind: BookKind.roman,
    pages: 15,
    minAge: 14,
    maxAge: 120,
    intelligenceGain: 4,
    charismaGain: 1,
  ),
  BookInfo(
    id: 'tuz_ve_deniz',
    title: 'Tuz ve Deniz',
    author: 'Nergis Akbulut',
    kind: BookKind.roman,
    pages: 16,
    minAge: 15,
    maxAge: 120,
    intelligenceGain: 4,
    happinessGain: 2,
  ),
  BookInfo(
    id: 'sayilarin_dili',
    title: 'Sayıların Dili',
    author: 'Cem Doğanay',
    kind: BookKind.bilim,
    pages: 18,
    minAge: 14,
    maxAge: 120,
    intelligenceGain: 6,
  ),
  BookInfo(
    id: 'gorunmeyen_sehir',
    title: 'Görünmeyen Şehir',
    author: 'İpek Yalçınkaya',
    kind: BookKind.roman,
    pages: 17,
    minAge: 16,
    maxAge: 120,
    intelligenceGain: 4,
    charismaGain: 2,
  ),
  BookInfo(
    id: 'atolye_notlari',
    title: 'Atölye Notları',
    author: 'Hakan Erdoğmuş',
    kind: BookKind.bilim,
    pages: 20,
    minAge: 17,
    maxAge: 120,
    intelligenceGain: 6,
  ),
  BookInfo(
    id: 'uzun_kis',
    title: 'Uzun Kış',
    author: 'Ayşen Bozdağ',
    kind: BookKind.roman,
    pages: 19,
    minAge: 18,
    maxAge: 120,
    intelligenceGain: 5,
    happinessGain: 2,
  ),
  BookInfo(
    id: 'bir_ustanin_anlattiklari',
    title: 'Bir Ustanın Anlattıkları',
    author: 'Rıza Çamlıca',
    kind: BookKind.bilim,
    pages: 16,
    minAge: 16,
    maxAge: 120,
    intelligenceGain: 5,
    charismaGain: 1,
  ),
  BookInfo(
    id: 'kapali_carsi_hikayeleri',
    title: 'Kapalı Çarşı Hikâyeleri',
    author: 'Suat Nalbantoğlu',
    kind: BookKind.roman,
    pages: 14,
    minAge: 15,
    maxAge: 120,
    intelligenceGain: 4,
    charismaGain: 2,
  ),
  BookInfo(
    id: 'yildizlara_bakmak',
    title: 'Yıldızlara Bakmak',
    author: 'Defne Korkmazer',
    kind: BookKind.bilim,
    pages: 22,
    minAge: 18,
    maxAge: 120,
    intelligenceGain: 7,
  ),
  BookInfo(
    id: 'son_mektup',
    title: 'Son Mektup',
    author: 'Orhan Tezcan',
    kind: BookKind.roman,
    pages: 21,
    minAge: 20,
    maxAge: 120,
    intelligenceGain: 5,
    happinessGain: 3,
  ),
];

BookInfo? bookById(String id) {
  for (final BookInfo b in kBookCatalog) {
    if (b.id == id) return b;
  }
  return null;
}

/// Yaşa uygun kitaplar.
List<BookInfo> booksFor(int age) =>
    kBookCatalog.where((BookInfo b) => b.fitsAge(age)).toList(growable: false);
