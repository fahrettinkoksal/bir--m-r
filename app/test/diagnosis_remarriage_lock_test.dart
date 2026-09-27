/// **Tekrar evlenme kilidi — bulundu, kanıtlandı, düzeltildi (Q-167/3).**
///
/// Ürün simülasyonunda 1000 hayatta tekrar evlenen **%0,0** çıkıyordu.
/// Teşhis hunisi kırılmanın yerini gösterdi:
///
/// ```
/// ayrilan                      141  %100.0
/// yeniden bekar sayiliyor      141  %100.0   <- marryBlockReason acik
/// yeni partner adayi gordu      78   %55.3   <- Finger destesi doluyor
/// yeni flort                     0    %0.0   <- BURADA KIRILIYORDU
/// YENIDEN EVLENDI                0    %0.0
/// ```
///
/// **Kök neden.** `GameState.isMarried` doğru çalışıyor: boşanmış
/// (`bosandi`) ya da dul (`dul`) kayıt "evli" saymıyor, ve
/// `MarriageEngine.marryBlockReason` ikinci evliliği **açıyor**. Ama
/// `Finger` aynı soruyu başka bir alandan soruyordu:
/// **`state.marriage != null`**. Boşanmada ve dullukta kayıt bilerek
/// silinmiyor (Paket 36: "kiminle, kaç yaşında evlenildi" hayat boyu
/// dursun), dolayısıyla o koşul **bir kez evlenen herkes için hayatının
/// sonuna kadar doğruydu**.
///
/// Kapanan yollar (hepsi düzeltildi, `state.isMarried` oldu):
///
/// | Yer | Etkisi |
/// |---|---|
/// | `finger.dart:451` `meetFingerMatch` | eşleşme arkadaş kalıyordu, flört olmuyordu |
/// | `finger.dart:562` `makeRelationshipOfficial` | "Hayatında zaten biri var." |
/// | `finger.dart:691` `officialAvailability` | aynı engel |
/// | `finger.dart:723` `askOutAvailability` | aynı engel |
/// | `life_progression.dart:1696` | boşanmış oyuncunun ebeveynleri onu evli sayıyordu |
///
/// Oyun "yeniden evlenebilirsin" diyordu ama evlenecek sevgiliyi
/// edinmenin yolu kapalıydı. `second_marriage_test.dart` geçiyordu çünkü
/// orada sevgili **elle** kuruluyor; oyuncunun gerçek yolu test
/// edilmiyordu. Bu dosya o boşluğu kapatıyor.
///
/// **Bu bir denge değişikliği değil, hata düzeltmesidir.** Hiçbir eşik,
/// ihtimal, fiyat ya da getiri değişmedi.
library;

import 'dart:math';

import 'package:bir_omur/data/finger_catalog.dart';
import 'package:bir_omur/data/health_crisis_catalog.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/finger.dart';
import 'package:bir_omur/domain/interaction/marriage_engine.dart';
import 'package:bir_omur/domain/models/finger_profile.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

const MarriageEngine _evlilik = MarriageEngine();

Person _kisi(
  String id,
  String ad, {
  required RelationType relation,
  int age = 34,
  int bond = 90,
}) =>
    Person(
      id: id,
      firstName: ad,
      lastName: 'Yaman',
      gender: Gender.kadin,
      relation: relation,
      age: age,
      isAlive: true,
      inPlayerHousehold: false,
      employment: EmploymentStatus.calisiyor,
      occupation: 'öğretmen',
      wealth: WealthTier.ortaHalli,
      bond: bond,
    );

/// Erkek oyuncu; yanında romantik ilişkiye açık bir arkadaş ve bir flört.
///
/// [sevgiliyle] yalnızca evlenip boşanma kurulumunda açılıyor.
/// `Romance.hasPartner` yalnızca **yaşayan sevgiliye** bakıyor, bu yüzden
/// karşılaştırmanın temiz olması için temel durumda sevgili bulunmuyor:
/// yoksa "hayatında zaten biri var" engeli hiç evlenmemiş oyuncuda da
/// çıkar ve kilit ölçülemez.
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

GameState _evlenVeBosan(GameState s) {
  final GameState evli = _evlilik.marry(s, 'sevgili-1').state;
  expect(evli.isMarried, isTrue, reason: 'kurulum: evlilik olusmadi');
  final GameState bosanmis = _evlilik.divorce(evli).state;
  expect(bosanmis.isMarried, isFalse, reason: 'kurulum: bosanma olmadi');
  return bosanmis;
}

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
  group('Tekrar evlenme — kaydın korunması', () {
    test('boşanmadan sonra evlilik kaydı SİLİNMİYOR', () {
      final GameState s = _evlenVeBosan(_hayat(sevgiliyle: true));
      // Kaydın durması bilinçli bir karar (Paket 36): geçmiş kaybolmasın.
      expect(s.marriage, isNotNull);
      expect(s.marriage!.status, MarriageStatus.bosandi);
      // Ama "evli mi" sorusunun doğru cevabı hayır.
      expect(s.isMarried, isFalse);
    });

    test('dul kaldıktan sonra da kayıt duruyor', () {
      final GameState s = _evlenVeDulKal(_hayat(sevgiliyle: true));
      expect(s.marriage, isNotNull);
      expect(s.marriage!.status, MarriageStatus.dul);
      expect(s.isMarried, isFalse);
    });

    test('`marriage != null` ile `isMarried` boşanmada ÇELİŞİR', () {
      // Kilidin kaynağı buydu: iki alanı aynı şey sanan her kontrol
      // hatalıdır. Bu test kalıbı kalıcı olarak sabitliyor ki aynı hata
      // başka bir yerde tekrar yazılmasın.
      final GameState bosanmis = _evlenVeBosan(_hayat(sevgiliyle: true));
      expect(bosanmis.marriage != null, isTrue);
      expect(bosanmis.isMarried, isFalse);
      expect((bosanmis.marriage != null) == bosanmis.isMarried, isFalse);
    });

    test('motor tekrar evlenmeye izin veriyor', () {
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
      );
    });
  });

  group('Tekrar evlenme — Finger yolları AÇIK (düzeltme)', () {
    test('boşanan oyuncu yeniden çıkma teklif edebiliyor', () {
      expect(
        Finger.askOutAvailability(_hayat(), 'arkadas-1').isAllowed,
        isTrue,
        reason: 'hic evlenmemis oyuncuda zaten acikti',
      );
      final GameState bosanmis = _evlenVeBosan(_hayat(sevgiliyle: true));
      expect(
        Finger.askOutAvailability(bosanmis, 'arkadas-1').isAllowed,
        isTrue,
        reason: 'DUZELTME: bosanan oyuncunun yolu artik kapali degil',
      );
    });

    test('dul kalan oyuncu yeniden çıkma teklif edebiliyor', () {
      final GameState dul = _evlenVeDulKal(_hayat(sevgiliyle: true));
      expect(Finger.askOutAvailability(dul, 'arkadas-1').isAllowed, isTrue);
    });

    test('boşanan oyuncu flörtünü resmîleştirebiliyor', () {
      expect(
        Finger.officialAvailability(_hayat(), 'flort-1').isAllowed,
        isTrue,
      );
      final GameState bosanmis = _evlenVeBosan(_hayat(sevgiliyle: true));
      final InteractionAvailability sonra =
          Finger.officialAvailability(bosanmis, 'flort-1');
      expect(
        sonra.isAllowed,
        isTrue,
        reason: 'DUZELTME: evlenecek sevgili artik edinilebiliyor',
      );
    });

    test('dul kalan oyuncu flörtünü resmîleştirebiliyor', () {
      final GameState dul = _evlenVeDulKal(_hayat(sevgiliyle: true));
      expect(Finger.officialAvailability(dul, 'flort-1').isAllowed, isTrue);
    });

    test('yürüyen evlilikte yollar HÂLÂ kapalı', () {
      // Düzeltme fazla açmamalı: evliyken Finger yine kapalı olmalı.
      final GameState evli =
          _evlilik.marry(_hayat(sevgiliyle: true), 'sevgili-1').state;
      expect(evli.isMarried, isTrue);
      expect(Finger.askOutAvailability(evli, 'arkadas-1').isAllowed, isFalse);
      expect(
        Finger.officialAvailability(evli, 'flort-1').isAllowed,
        isFalse,
      );
    });

    test('yaşayan sevgilisi olan oyuncuda yollar kapalı kalıyor', () {
      // `hasPartner` kapısı korunuyor: iki sevgili aynı anda olmaz.
      final GameState sevgilili = _hayat(sevgiliyle: true);
      expect(
        Finger.askOutAvailability(sevgilili, 'arkadas-1').isAllowed,
        isFalse,
      );
    });
  });

  group('Tekrar evlenme — TAM OYUNCU YOLU (elle sevgili enjekte edilmiyor)', () {
    // §35: evlen → boşan → Finger kullan → flört et → sevgili ol →
    // tekrar evlen.
    //
    // **İki eşin ikisi de Finger'dan geliyor.** Hiçbir yerde hazır
    // sevgili/flört kaydı enjekte edilmiyor; bütün ilişki geçişleri
    // `GameController`'ın gerçek public aksiyonlarından geçiyor.
    // `debugSetState` yalnızca **yaş ve cüzdan** için kullanılıyor
    // (0 yaşından 30'a doğal olarak yaşlanmak bu testin konusu değil);
    // ilişki, stat, kişi ya da yakınlık verilmiyor.

    /// Bekleyen pencereleri kapatır ve bir yıl ilerletir.
    ///
    /// Yakınlık **yıllar içinde** artıyor ("birlikte vakit geçirdikçe
    /// artar"); aynı yıl içinde üst üste etkileşim çağırmak yetmiyor.
    /// İlk yazımda yıl ilerletmeden 14 kez etkileşim çağırmıştım ve
    /// yakınlık 58'den ancak 62'ye çıkıyordu — çoğu çağrı yılın
    /// sınırına takılıp boşa gidiyordu.
    void yilGec(GameController c, Random rng) {
      for (int guard = 0; guard < 40; guard++) {
        final GameState s = c.state!;
        if (s.deceased) return;
        if (s.hasNotice) {
          c.dismissNotice();
          continue;
        }
        if (s.pendingEvent != null) {
          final List<EventChoice> secenekler = s.pendingEvent!.choices;
          c.chooseEventOption(secenekler[rng.nextInt(secenekler.length)].id);
          continue;
        }
        if (s.pendingCrisis != null) {
          final HealthCrisis? katalog =
              healthCrisisById(s.pendingCrisis!.crisisId);
          final List<CrisisChoice> acik = katalog == null
              ? const <CrisisChoice>[]
              : katalog.choices
                  .where((CrisisChoice ch) => ch.cost <= s.player.wallet)
                  .toList(growable: false);
          if (acik.isEmpty) return;
          c.respondToCrisis(acik[rng.nextInt(acik.length)].id);
          continue;
        }
        if (s.hasPendingTrial || s.pendingInterview != null) return;
        if (c.needsEducationChoice) return;
        final int onceki = s.player.age;
        c.ageUp();
        if (c.state!.player.age != onceki) return;
      }
    }

    /// Finger üzerinden bir sevgili edinir ve kimliğini döner; olmazsa
    /// `null`.
    ///
    /// **Israrcı bir oyuncu gibi davranıyor:** her yıl desteyi
    /// tazeliyor, daha önce tanışılmamış ve arkadaşlık aramayan
    /// profilleri beğeniyor, eşleşme olursa flörtle yıllarca vakit
    /// geçirip yakınlığı resmîleştirme eşiğine (60) çıkarıyor. Tek bir
    /// profille tek denemede olmuyor: beğenilerin bir kısmı karşılık
    /// bulmuyor ve yakınlık yıllar içinde artıyor.
    ///
    /// Hiçbir yerde kişi, yakınlık ya da ilişki **enjekte edilmiyor**.
    String? finderdanSevgiliEdin(GameController c, Random rng, {int yil = 25}) {
      c.setFingerIntent(FingerIntent.ciddi);
      for (int i = 0; i < yil; i++) {
        if (c.state!.deceased) return null;

        // Sevgili oluştuysa bitti.
        final Person? sevgili = c.state!.people
            .where((Person p) =>
                p.isAlive && p.relation == RelationType.sevgili)
            .firstOrNull;
        if (sevgili != null) return sevgili.id;

        // Elde flört varsa onunla ilgilen; yoksa yeni aday ara.
        final Person? flort = c.state!.people
            .where((Person p) => p.isAlive && p.relation == RelationType.flort)
            .firstOrNull;
        if (flort != null) {
          if (c.officialAvailability(flort.id).isAllowed) {
            c.makeRelationshipOfficial(flort.id);
            while (c.state!.hasNotice) {
              c.dismissNotice();
            }
            continue;
          }
          final List<InteractionKind> acik = c.availableKindsFor(flort);
          if (acik.isNotEmpty) {
            c.interact(flort.id, acik[rng.nextInt(acik.length)]);
            while (c.state!.hasNotice) {
              c.dismissNotice();
            }
          }
        } else {
          c.fillFingerDeck();
          // Tanışılmamış ve arkadaşlık aramayan profiller. Arkadaşlık
          // niyetli profille tanışmak flört üretmiyor (D-107); bu testin
          // konusu o kural değil.
          final List<FingerProfile> adaylar = c.state!.fingerDeck
              .where((FingerProfile p) =>
                  !p.isMet && p.intent != FingerIntent.arkadaslik)
              .toList(growable: false);
          // Yılda birkaç beğeni: kota dolabilir, hepsi karşılık bulmaz.
          for (final FingerProfile profil in adaylar.take(4)) {
            c.likeFingerProfile(profil.id);
            c.meetFingerMatch(profil.id);
            while (c.state!.hasNotice) {
              c.dismissNotice();
            }
            if (c.state!.people.any((Person p) =>
                p.relation == RelationType.flort ||
                p.relation == RelationType.sevgili)) {
              break;
            }
          }
        }
        yilGec(c, rng);
      }
      final Person? son = c.state!.people
          .where((Person p) => p.isAlive && p.relation == RelationType.sevgili)
          .firstOrNull;
      return son?.id;
    }

    /// Teklif eder ve düğünü yapar; olmazsa `false`.
    bool evlen(GameController c, String partnerId, Random rng) {
      for (int deneme = 0; deneme < 8; deneme++) {
        if (c.state!.pendingWedding != null) break;
        if (!c.proposalAvailability(partnerId).isAllowed) {
          // Teklif bekleme süresi ya da yakınlık: biraz daha vakit geçir.
          final Person? guncel = c.state!.personById(partnerId);
          if (guncel == null) return false;
          final List<InteractionKind> acik = c.availableKindsFor(guncel);
          if (acik.isNotEmpty) {
            c.interact(partnerId, acik[rng.nextInt(acik.length)]);
            while (c.state!.hasNotice) {
              c.dismissNotice();
            }
          }
          yilGec(c, rng);
          if (c.state!.deceased) return false;
          continue;
        }
        c.propose(partnerId);
        while (c.state!.hasNotice) {
          c.dismissNotice();
        }
      }
      if (c.state!.pendingWedding == null) return false;
      c.holdWedding('nikah');
      while (c.state!.hasNotice) {
        c.dismissNotice();
      }
      return c.state!.isMarried;
    }

    test('boşandıktan sonra Finger üzerinden yeniden evlenilebiliyor', () {
      GameController? kazanan;
      int denenen = 0;
      String? ilkEsId;

      // Finger destesi ve teklif kabulü rastgele; bu yüzden birkaç tohum
      // deneniyor. İddia "her tohumda olur" değil, **yolun baştan sona
      // yürüyebildiği**. Düzeltmeden önce bu yol 1000 hayatta %0 idi.
      for (int seed = 1; seed <= 60 && kazanan == null; seed++) {
        denenen++;
        final GameController c = GameController(random: Random(seed));
        c.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
        final Random rng = Random(seed * 31 + 7);

        // Yalnızca yaş ve cüzdan; ilişki/stat/kişi verilmiyor.
        c.debugSetState(
          c.state!.copyWith(
            pendingEvent: null,
            notices: const <PendingNotice>[],
            player: c.state!.player.copyWith(age: 30, wallet: 3000000),
          ),
        );

        // --- 1) İlk sevgili: Finger'dan. ---
        final String? birinci = finderdanSevgiliEdin(c, rng);
        if (birinci == null) {
          c.dispose();
          continue;
        }
        // --- 2) İlk evlilik. ---
        if (!evlen(c, birinci, rng)) {
          c.dispose();
          continue;
        }

        // --- 3) Boşanma. ---
        if (!c.divorceAvailability().isAllowed) {
          c.dispose();
          continue;
        }
        c.divorce();
        while (c.state!.hasNotice) {
          c.dismissNotice();
        }
        if (c.state!.isMarried) {
          c.dispose();
          continue;
        }

        // --- 4) İkinci sevgili: yine Finger'dan. Düzeltmeden önce
        //        BURASI hiç yürümüyordu. ---
        final String? ikinci = finderdanSevgiliEdin(c, rng);
        if (ikinci == null) {
          c.dispose();
          continue;
        }
        // --- 5) Tekrar evlilik. ---
        if (evlen(c, ikinci, rng)) {
          ilkEsId = birinci;
          kazanan = c;
        } else {
          c.dispose();
        }
      }

      expect(
        kazanan,
        isNotNull,
        reason: 'TAM OYUNCU YOLU: $denenen tohumda bir kez bile '
            'Finger->flort->sevgili->evlen->bosan->Finger->flort->'
            'sevgili->tekrar evlen yurumedi.',
      );
      final GameState son = kazanan!.state!;
      expect(son.isMarried, isTrue);
      expect(son.marriageCount, 2, reason: 'ikinci evlilik sayilmali');
      expect(son.pastMarriages, hasLength(1),
          reason: 'ilk evlilik gecmise tasinmali, uzerine yazilmamali');
      expect(son.pastMarriages.first.status, MarriageStatus.bosandi);
      expect(son.pastMarriages.first.spouseId, ilkEsId);
      expect(son.marriage!.spouseId, isNot(ilkEsId),
          reason: 'ikinci es farkli bir kisi olmali');
      // Eski eşin kaydı hâlâ okunabilir.
      expect(son.personById(ilkEsId!), isNotNull);
      expect(son.marriageWith(ilkEsId)!.status, MarriageStatus.bosandi);
      expect(son.personById(ilkEsId)!.relation, RelationType.eskiEs);
      kazanan.dispose();
    });
  });
}
