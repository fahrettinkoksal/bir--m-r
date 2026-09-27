/// **Teşhis kanıtı: tekrar evlenme %0'ın kök nedeni.**
///
/// Ürün simülasyonunda 1000 hayatta tekrar evlenen **%0,0** çıktı.
/// `diagnosis_root_cause_test.dart` hunisi kırılmanın yerini gösterdi:
///
/// ```
/// ayrilan                      141  %100.0
/// yeniden bekar sayiliyor      141  %100.0   <- marryBlockReason acik
/// yeni partner adayi gordu      78   %55.3   <- Finger destesi doluyor
/// yeni flort                     0    %0.0   <- BURADA KIRILIYOR
/// yeni sevgili                   0    %0.0
/// YENIDEN EVLENDI                0    %0.0
/// ```
///
/// Bu dosya istatistik değil **kanıt** üretir: tek bir kurulmuş durumla,
/// rastgelelik olmadan, kilidin yerini gösterir.
///
/// **Bulgu.** `MarriageEngine.marryBlockReason` ikinci evliliği doğru
/// biçimde açıyor — `GameState.isMarried` boşanmış ya da dul kaydı
/// "evli" saymıyor:
///
/// ```dart
/// bool get isMarried {
///   final Marriage? kayit = marriage;
///   if (kayit == null || !kayit.isActive) return false;   // bosandi -> false
///   final Person? es = spouse;
///   return es != null && es.isAlive;                      // vefat -> false
/// }
/// ```
///
/// Ama `Finger` aynı soruyu **başka bir alandan** soruyor:
/// `state.marriage != null`. Boşanmada kayıt silinmiyor, yalnızca
/// `status: bosandi` oluyor (bilerek: "kiminle, kaç yaşında evlenildi"
/// bilgisi hayat boyu duruyor, Paket 36). Dul kalmada da kayıt duruyor.
/// Yani `marriage != null` **bir kez evlenen herkes için hayatının geri
/// kalanında doğru**.
///
/// Sonuç: bir kez evlenmiş oyuncu boşansa da dul kalsa da romantik
/// ilişkiye giren bütün Finger yollarını **kalıcı olarak** kapatıyor:
///
/// * `finger.dart:443` `meetFingerMatch` — `bosta` yanlış olur, eşleşme
///   yalnızca arkadaş kalır, flört olmaz.
/// * `finger.dart:552` `makeRelationshipOfficial` — "Hayatında zaten
///   biri var."
/// * `finger.dart:680` `officialAvailability` — aynı engel.
/// * `finger.dart:711` `askOutAvailability` — aynı engel.
///
/// Oyun "yeniden evlenebilirsin" diyor ama evlenecek sevgiliyi edinmenin
/// yolu kapalı. `second_marriage_test.dart` geçiyor çünkü orada sevgili
/// **elle** kuruluyor; oyuncunun gerçek yolu test edilmiyordu.
///
/// **Bu dosya hiçbir şeyi düzeltmiyor.** Teşhis turunda denge ve kod
/// değiştirmek yasak; bulgu `docs/DESIGN_REVIEW_QUEUE.md` ve
/// `docs/EKSIKLER.md` üzerinden Faho'ya gidiyor. Testler mevcut
/// **yanlış** davranışı sabitliyor ve düzeltildiğinde kırılacak biçimde
/// yazıldı: her birinin adında "BUG" var ve içinde doğru davranışın ne
/// olduğu yazılı.
library;

import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/finger.dart';
import 'package:bir_omur/domain/interaction/marriage_engine.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

const MarriageEngine _evlilik = MarriageEngine();

Person _kisi(
  String id,
  String ad, {
  required RelationType relation,
  int age = 34,
  int bond = 90,
  bool isAlive = true,
}) =>
    Person(
      id: id,
      firstName: ad,
      lastName: 'Yaman',
      gender: Gender.kadin,
      relation: relation,
      age: age,
      isAlive: isAlive,
      inPlayerHousehold: false,
      employment: EmploymentStatus.calisiyor,
      occupation: 'öğretmen',
      wealth: WealthTier.ortaHalli,
      bond: bond,
    );

/// Erkek oyuncu; yanında romantik ilişkiye açık bir arkadaş ve bir
/// flört. Hiçbir şey `debugSetState` ile verilmiyor: durum doğrudan
/// kuruluyor ve bütün geçişler üretim motorlarından geçiyor.
///
/// [sevgiliyle] yalnızca evlenip boşanma kurulumunda açılıyor.
/// `Romance.hasPartner` yalnızca **yaşayan sevgiliye** bakıyor, bu
/// yüzden karşılaştırmanın temiz olması için temel durumda sevgili
/// bulunmuyor: yoksa "hayatında zaten biri var" engeli hiç evlenmemiş
/// oyuncuda da çıkar ve kilit ölçülemez.
GameState _hayat({int age = 40, bool sevgiliyle = false}) {
  for (int seed = 0; seed < 300; seed++) {
    final GameState taban =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    if (taban.player.gender != Gender.erkek) continue;
    final List<Person> kisiler = taban.people
        .where((Person p) =>
            p.relation != RelationType.sevgili &&
            p.relation != RelationType.flort &&
            p.relation != RelationType.es)
        .toList(growable: true)
      ..add(_kisi('arkadas-1', 'Selin', relation: RelationType.arkadas))
      ..add(_kisi('flort-1', 'Nazlı', relation: RelationType.flort));
    if (sevgiliyle) {
      kisiler.add(_kisi('sevgili-1', 'Elif', relation: RelationType.sevgili));
    }
    return taban.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      people: List<Person>.unmodifiable(kisiler),
      player: taban.player.copyWith(age: age, wallet: 2000000),
    );
  }
  throw StateError('Uygun hayat bulunamadi');
}

/// Evlendirir, sonra boşar. İkisi de üretim motorundan geçer.
GameState _evlenVeBosan(GameState s) {
  final GameState evli = _evlilik.marry(s, 'sevgili-1').state;
  expect(evli.isMarried, isTrue, reason: 'kurulum: evlilik olusmadi');
  final GameState bosanmis = _evlilik.divorce(evli).state;
  expect(bosanmis.isMarried, isFalse, reason: 'kurulum: bosanma olmadi');
  return bosanmis;
}

/// Evlendirir, sonra eşi vefat eder. Vefatı kaydın kendi durumuyla
/// ifade ediyoruz; oyuncuya hiçbir avantaj verilmiyor.
GameState _evlenVeDulKal(GameState s) {
  final GameState evli = _evlilik.marry(s, 'sevgili-1').state;
  expect(evli.isMarried, isTrue);
  return evli.copyWith(
    marriage: evli.marriage!.copyWith(
      status: MarriageStatus.dul,
      endedAtAge: evli.player.age,
    ),
    people: List<Person>.unmodifiable(
      evli.people.map((Person p) =>
          p.id == 'sevgili-1' ? p.copyWith(isAlive: false) : p),
    ),
  );
}

void main() {
  group('Teshis kaniti — tekrar evlenme kilidi', () {
    test('kurulum: bosanmadan sonra evlilik kaydi SILINMIYOR', () {
      final GameState s = _evlenVeBosan(_hayat(sevgiliyle: true));
      // Kaydın durması bilinçli bir karar (Paket 36): geçmiş kaybolmasın.
      expect(s.marriage, isNotNull);
      expect(s.marriage!.status, MarriageStatus.bosandi);
      // Ama "evli mi" sorusunun doğru cevabi hayir.
      expect(s.isMarried, isFalse);
    });

    test('kurulum: dul kaldiktan sonra da kayit duruyor', () {
      final GameState s = _evlenVeDulKal(_hayat(sevgiliyle: true));
      expect(s.marriage, isNotNull);
      expect(s.marriage!.status, MarriageStatus.dul);
      expect(s.isMarried, isFalse);
    });

    test('motor tekrar evlenmeye IZIN VERIYOR (kilit burada degil)', () {
      final GameState s = _evlenVeBosan(_hayat(sevgiliyle: true));
      final GameState yeni = s.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          ...s.people,
          _kisi('sevgili-2', 'Derya', relation: RelationType.sevgili),
        ]),
      );
      expect(
        _evlilik.marryBlockReason(yeni, yeni.personById('sevgili-2')!),
        '',
        reason: 'marryBlockReason ikinci evliligi engellemiyor; '
            'huninin %0 olmasinin sebebi bu degil.',
      );
    });

    // ----------------------------------------------------------------
    // Kilidin kendisi. Aşağıdaki dört test bugünkü **yanlış** davranışı
    // sabitliyor. Düzeltilirse kırılacaklar; kırılmaları iyi haberdir.
    // ----------------------------------------------------------------

    test('BUG: bosanan oyuncuya cikma teklif edilemiyor (finger.dart:711)',
        () {
      // Hiç evlenmemiş oyuncuda yol açık:
      expect(
        Finger.askOutAvailability(_hayat(), 'arkadas-1').isAllowed,
        isTrue,
        reason: 'hic evlenmemis oyuncuda cikma teklifi acik olmali',
      );
      // Boşandıktan sonra kapanıyor. Boşanmadan sonra eski sevgili
      // `eskiEs` oluyor, yani `hasPartner` yanlış: kalan tek fark
      // silinmeyen evlilik kaydı.
      final GameState bosanmis = _evlenVeBosan(_hayat(sevgiliyle: true));
      final InteractionAvailability sonra =
          Finger.askOutAvailability(bosanmis, 'arkadas-1');
      expect(
        sonra.isAllowed,
        isFalse,
        reason: 'BUGUNKU DAVRANIS. Dogrusu: bosanan oyuncu yeniden '
            'cikma teklif edebilmeli (isMarried false).',
      );
      expect(sonra.reason, 'Hayatında zaten biri var.');
    });

    test('BUG: dul kalan oyuncuya da cikma teklif edilemiyor', () {
      final GameState dul = _evlenVeDulKal(_hayat(sevgiliyle: true));
      final InteractionAvailability sonra =
          Finger.askOutAvailability(dul, 'arkadas-1');
      expect(
        sonra.isAllowed,
        isFalse,
        reason: 'BUGUNKU DAVRANIS. Dogrusu: esini kaybeden oyuncu '
            'yeniden cikma teklif edebilmeli.',
      );
      expect(sonra.reason, 'Hayatında zaten biri var.');
    });

    test('BUG: bosanan oyuncu flortunu resmilestiremiyor '
        '(finger.dart:552/680)', () {
      expect(
        Finger.officialAvailability(_hayat(), 'flort-1').isAllowed,
        isTrue,
        reason: 'hic evlenmemis oyuncuda resmilestirme acik olmali',
      );
      final GameState bosanmis = _evlenVeBosan(_hayat(sevgiliyle: true));
      final InteractionAvailability sonra =
          Finger.officialAvailability(bosanmis, 'flort-1');
      expect(
        sonra.isAllowed,
        isFalse,
        reason: 'BUGUNKU DAVRANIS. Dogrusu: bosanan oyuncu yeni bir '
            'flortu sevgiliye cevirebilmeli — yoksa evlenecek sevgili '
            'hic olusmaz ve tekrar evlenme %0 kalir.',
      );
      expect(sonra.reason, 'Hayatında zaten biri var.');
    });

    test('BUG: kilit kaliCi — bosanmadan 30 yil sonra da kapali', () {
      GameState s = _evlenVeBosan(_hayat(age: 35, sevgiliyle: true));
      // Yaşı ilerletmek kilidi açmıyor: engel yaşa değil, silinmeyen
      // evlilik kaydına bağlı.
      s = s.copyWith(player: s.player.copyWith(age: 65));
      expect(Finger.askOutAvailability(s, 'arkadas-1').isAllowed, isFalse);
      expect(Finger.officialAvailability(s, 'flort-1').isAllowed, isFalse);
    });

    test('kanit: kilit TEK alandan geliyor — kayit bosaltilinca acilir', () {
      final GameState bosanmis = _evlenVeBosan(_hayat(sevgiliyle: true));
      // `marriage` alanını boşaltmak **çözüm değil** (geçmiş kaybolur);
      // burada yalnızca engelin kaynağını kanıtlıyor: aynı durumda
      // yalnızca bu alan değişince yol açılıyor. Yani sorun yaşta,
      // yakınlıkta, para veya kişi kaydında değil.
      final GameState kayitsiz = bosanmis.copyWith(marriage: null);
      expect(kayitsiz.isMarried, isFalse);
      expect(bosanmis.isMarried, isFalse);
      expect(
        Finger.askOutAvailability(kayitsiz, 'arkadas-1').isAllowed,
        isTrue,
        reason: 'Iki durum yalnizca `marriage` alaninda farkli ve ikisinde '
            'de isMarried false. Yol yalnizca alan bosalinca aciliyor: '
            'engel `marriage != null` kontrolu.',
      );
      expect(
        Finger.officialAvailability(kayitsiz, 'flort-1').isAllowed,
        isTrue,
      );
    });

    test('ikinci kirilma: bosanmis oyuncu ebeveyn tepkisinde "evli" '
        'sayiliyor (life_progression.dart:1696)', () {
      // Aynı kalıbın ikinci örneği. `final bool evli = state.marriage
      // != null;` — boşanmış oyuncunun ebeveynleri onu hâlâ evli
      // sayıyor ve "destekleyici" tepki veriyor; oysa `isMarried` false.
      // Etkisi küçük (yakınlık/mutluluk farkı), ama kalıp aynı.
      final GameState bosanmis = _evlenVeBosan(_hayat(sevgiliyle: true));
      expect(bosanmis.marriage != null, isTrue);
      expect(bosanmis.isMarried, isFalse);
      // Bu test bir davranışı değil, iki alanın **çeliştiğini** sabitliyor.
      expect(
        (bosanmis.marriage != null) == bosanmis.isMarried,
        isFalse,
        reason: '`marriage != null` ile `isMarried` bosanmada celisiyor; '
            'ikisini ayni sey sanan her kontrol hatali.',
      );
    });
  });
}
