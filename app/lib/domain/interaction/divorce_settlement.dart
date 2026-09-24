/// Boşanmada mal paylaşımı (D-075).
///
/// **Neden var:** Faho bildirdi — "eşimle boşandığımda ... eşinle boşandın
/// mal varlığından şu kadar ona gitti, ev ona gitti vb gibi yazmalı".
/// Boşanma yalnızca nakdin dörtte birini alıyordu; ev, araba ve diğer
/// eşyalar hiç paylaşılmıyordu (Q-063 açık soruydu).
///
/// **Kural neye dayanıyor:** Türkiye'de 2002'den beri geçerli yasal mal
/// rejimi **edinilmiş mallara katılma**dır: evlilik içinde *edinilen*
/// mallar boşanmada paylaşılır, evlilikten önce sahip olunan ile miras ve
/// bağış yoluyla gelen **kişisel mal** sayılır ve paylaşılmaz. Oyun bu
/// ayrımı taşıyabiliyor, çünkü her eşyanın **kaç yaşında** ve **nasıl**
/// edinildiği kayıtlı (`acquiredAtAge`, `source`).
///
/// Bu bir hukuk simülasyonu değildir: mal rejimi sözleşmesi, katkı payı,
/// değer artış payı ve nafaka **yoktur**. Oyun, kuralın ana fikrini
/// uygular. Ayrıntılar karar kuyruğunda (Q-118).
library;

import '../models/owned_item.dart';

/// Boşanmada varlıkların nasıl bölündüğü.
class DivorceSettlement {
  const DivorceSettlement({
    required this.cashToSpouse,
    required this.toSpouse,
    required this.kept,
    required this.personalItems,
  });

  /// Eşe kalan nakit.
  final int cashToSpouse;

  /// Eşe kalan eşyalar.
  final List<OwnedItem> toSpouse;

  /// Oyuncuda kalan **edinilmiş** eşyalar.
  final List<OwnedItem> kept;

  /// Hiç paylaşıma girmeyen kişisel eşyalar.
  final List<OwnedItem> personalItems;

  bool get sharesProperty => toSpouse.isNotEmpty;

  /// Eşe geçen eşyaların toplam değeri.
  int get valueToSpouse =>
      toSpouse.fold(0, (int t, OwnedItem i) => t + DivorceSettlement.valueOf(i));

  /// Bir eşyanın paylaşımda kullanılan değeri.
  ///
  /// Satın alma fiyatı varsa o kullanılır; yoksa türün temel değeri.
  static int valueOf(OwnedItem item) =>
      item.purchasePrice ?? item.type.baseValue;

  /// Bu eşya **edinilmiş mal** mı?
  ///
  /// Evlilik sırasında ve satın alarak edinilmişse evet. Evlilikten önce
  /// sahip olunan, miras kalan, hediye edilen ve olayla gelen eşya
  /// **kişisel maldır**, paylaşıma girmez.
  static bool isMaritalProperty(OwnedItem item, int marriedAtAge) {
    if (item.acquiredAtAge < marriedAtAge) return false;
    return item.source == ItemSource.satinAlma;
  }

  /// Paylaşımı hesaplar.
  ///
  /// Eşyalar bölünemez. Bu yüzden değere göre büyükten küçüğe sıralanıp
  /// her biri **o an daha az pay almış tarafa** verilir; sonuç iki tarafı
  /// da yaklaşık eşitler. Tek bir ev varsa ve evlilik içinde alınmışsa,
  /// o ev bir tarafa gider — yarısı kimseye verilemez.
  static DivorceSettlement compute({
    required List<OwnedItem> items,
    required int marriedAtAge,
    required int wallet,
    required double cashShare,
  }) {
    final List<OwnedItem> kisisel = <OwnedItem>[];
    final List<OwnedItem> ortak = <OwnedItem>[];
    for (final OwnedItem i in items) {
      if (isMaritalProperty(i, marriedAtAge)) {
        ortak.add(i);
      } else {
        kisisel.add(i);
      }
    }

    // Büyükten küçüğe; eşit değerde olanlar kimliğe göre sıralanır ki
    // sonuç deterministik olsun ve kapat-aç aynı sonucu versin.
    ortak.sort((OwnedItem a, OwnedItem b) {
      final int fark = valueOf(b).compareTo(valueOf(a));
      return fark != 0 ? fark : a.id.compareTo(b.id);
    });

    final List<OwnedItem> oyuncuya = <OwnedItem>[];
    final List<OwnedItem> ese = <OwnedItem>[];
    int oyuncuToplam = 0;
    int esToplam = 0;
    for (final OwnedItem i in ortak) {
      final int deger = valueOf(i);
      // Eşitlikte oyuncu alır: boşanma oyuncuyu sebepsiz cezalandırmaz.
      if (oyuncuToplam <= esToplam) {
        oyuncuya.add(i);
        oyuncuToplam += deger;
      } else {
        ese.add(i);
        esToplam += deger;
      }
    }

    final int nakit = (wallet * cashShare).round().clamp(0, wallet);

    return DivorceSettlement(
      cashToSpouse: nakit,
      toSpouse: List<OwnedItem>.unmodifiable(ese),
      kept: List<OwnedItem>.unmodifiable(oyuncuya),
      personalItems: List<OwnedItem>.unmodifiable(kisisel),
    );
  }

  /// Bildirimde gösterilecek satırlar.
  ///
  /// Yalnızca **gerçekten olan** şeyler yazılır: bir şey gitmediyse
  /// gitmiş gibi yazılmaz.
  List<String> summaryLines(String spouseName) {
    final List<String> satirlar = <String>[];
    for (final OwnedItem i in toSpouse) {
      satirlar.add('${i.type.name} $spouseName\'a kaldı.');
    }
    if (kept.isNotEmpty) {
      final List<String> adlar =
          kept.map((OwnedItem i) => i.type.name).toList(growable: false);
      satirlar.add('Sende kalanlar: ${adlar.join(', ')}.');
    }
    if (personalItems.isNotEmpty) {
      satirlar.add(
        'Evlilikten önce sahip olduğun ve miras/hediye yoluyla gelen '
        '${personalItems.length} eşya paylaşıma girmedi.',
      );
    }
    return List<String>.unmodifiable(satirlar);
  }
}
