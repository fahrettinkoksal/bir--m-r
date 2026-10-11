// Paket CN — **çocuk da hastalanır.**
//
// **Ölçülen eksik.** `EKSIKLER` §3.2 beş madde sayıyordu; dördü bu
// belge yazıldıktan sonra kapanmıştı. Kodda doğrulanan tek açık madde
// hastalıktı: eşin kendi hayatında hastalık D-154'ten beri var
// (`SpouseLife`), `ChildProgression` içinde **hiç** yoktu. Çocuk okula
// gidiyor, iş buluyor, evleniyor, boşanıyor, işsiz kalıyor ama hiç
// hastalanmıyordu.
//
// **Kapsam neden yalnızca çocuk.** İzlenen kişi (torun, yeğen, kardeş,
// üvey kardeş, yarım kardeş, üvey çocuk) sayısı ölçüldü: ortanca 5, en
// çok 23. Çocuk sayısı ortanca 0, en çok 4. Aynı kural bütün izlenen
// kişilere açılsa günlük ve mutluluk taşardı; bu yüzden kapsam çocukla
// sınırlı, genişletme sorusu Q-230'da.
//
// **Zarın yeri (bu paketin asıl kararı).** Çocuk başına yıllık bir
// atış ana zar dizisinden çekilseydi 70 yıllık bir hayatta sıranın
// tamamı kayardı: bütün tohumlu ölçümler ve bekçi testleri tek bir
// içerik eklemesi yüzünden kırılırdı (Paket BO'nun yakaladığı hata tam
// buydu). Atış `NpcIllness.derivedRandom(id, age)` ile **kişi-yıldan
// türetilen** kendi tohumundan yapılıyor. İki sonucu var:
//   * Modül kapalıyken kod Paket CN **öncesiyle birebir aynı** çalışır.
//     40 hayatlık damga (hastalık yılları, ölüm yaşı, kişi sayısı, son
//     mutluluk) eski kodla yeni kodun modül-kapalı koşusunda **satır
//     satır aynı** çıktı; ölçüm `docs/CLAUDE_ROADMAP.md`'de.
//   * Kaydı kapatıp açarak hastalığı yeniden çevirmek imkânsız: sonuç
//     ana zara değil kişinin kimliğine ve yaşına bağlı (5. test).
//
// **Ölçüm (250 bot hayatı, açık/kapalı fark).** 134 çocuk hastalığı
// satırı, 53 hayat en az birini görüyor. Ölüm yaşı ortalaması
// 71,48 / 71,42 — modülün ömre etkisi gürültü düzeyinde. Tek tek
// hayatlar yine de ayrışıyor: hastalanan çocuğun statları değiştiği
// için **sonraki** yılların dalları kayıyor (bir hayatta ölüm yaşı
// 71 → 83). Bu modülün açık olmasının sonucu, zar sözleşmesinin
// ihlali değil — kapalıyken akış bire bir eski akış.
//
// **Hanedeki çocuğun yükü (95 tek yıllık kare).** Hane dışındaki
// çocuğun hastalığı oyuncunun keyfine **hiç** dokunmuyor (60/60 kare
// fark 0). Hanedeki çocuk için fark 17 karede tam −2, 9 karede −1,
// 9 karede 0. Soğuran şey tavan değil **azalan getiri**
// (`StatGain.apply`, yumuşak tavan 95): kayıp tam uygulanıyor ama
// yılın sonraki kazançları daha düşük tabandan işlenince 1-2 puanı
// geri veriyor. Bu bütün statların davranışı, bu paketin değil.
library;

import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/features/feature_catalog.dart';
import 'package:bir_omur/domain/generation/npc_illness.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/life_log.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/person_development.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// Günlükte ve dönüm noktasında kullanılan hastalık cümlesinin kuyruğu.
const String kHastalikKuyrugu = 'bir süre hastalandı.';

/// Kişinin hastalandığı yıllar (kendi dönüm noktalarından).
List<int> _hastalikYillari(Person p) {
  final PersonDevelopment? dev = p.development;
  if (dev == null) return const <int>[];
  final List<int> yillar = <int>[];
  for (final LifeMilestone m in dev.milestones) {
    if (m.text.contains(kHastalikKuyrugu)) yillar.add(m.age);
  }
  return yillar;
}

/// Bir hayatın sonunda çocukların hastalık dökümü.
typedef _Tarama = ({int hastalik, int gorenHayat, int ihlal, int cocuk});

/// [adet] tohum × bütün arketipler; modül [acik].
_Tarama _tara(int adet, {required bool acik}) {
  int hastalik = 0;
  int gorenHayat = 0;
  int ihlal = 0;
  int cocuk = 0;
  for (final PlayerArchetype a in PlayerArchetype.values) {
    for (int i = 1; i <= adet; i++) {
      GameState? son;
      playBotLife(
        archetype: a,
        seed: i * 97 + a.index,
        features: acik
            ? FeatureSwitches.defaults
            : FeatureSwitches.defaults
                .toggled(FeatureId.cocukHastaligi, false),
        onYear: (GameState s) => son = s,
      );
      if (son == null) continue;
      int buHayat = 0;
      for (final Person p in son!.people) {
        if (p.relation != RelationType.cocuk) continue;
        cocuk++;
        final List<int> yillar = _hastalikYillari(p);
        buHayat += yillar.length;
        for (int k = 1; k < yillar.length; k++) {
          if (yillar[k] - yillar[k - 1] < NpcIllness.prototypeOnlyGap) {
            ihlal++;
          }
        }
      }
      hastalik += buHayat;
      if (buHayat > 0) gorenHayat++;
    }
  }
  return (
    hastalik: hastalik,
    gorenHayat: gorenHayat,
    ihlal: ihlal,
    cocuk: cocuk,
  );
}

_Tarama? _acikOnbellek;
_Tarama get _acik => _acikOnbellek ??= _tara(12, acik: true);

/// Bu kare bir yıl ilerlerse hangi çocuklar hastalanır?
///
/// Türetilmiş tohum sayesinde **önceden** bilinebiliyor; kare seçmek
/// için kullanılıyor, sonuç her testte ayrıca doğrulanıyor.
List<Person> _gelecekYilHastalar(GameState s) {
  final List<Person> liste = <Person>[];
  for (final Person p in s.people) {
    if (p.relation != RelationType.cocuk || !p.isAlive) continue;
    final PersonDevelopment? dev = p.development;
    if (dev == null) continue;
    final int yas = p.age + 1;
    final int? son = NpcIllness.lastIllnessAge(dev);
    if (son != null && yas - son < NpcIllness.prototypeOnlyGap) continue;
    if (NpcIllness.derivedRandom(p.id, yas).nextDouble() <
        NpcIllness.prototypeOnlyChance(yas)) {
      liste.add(p);
    }
  }
  return liste;
}

/// Çocuğu olan ama bu yıl **hiçbiri hastalanmayacak** kareler ve tek
/// çocuğu hastalanacak kareler.
typedef _Kareler = ({
  List<({GameState kare, bool hanede, String id, int yas})> hasta,
  List<GameState> sakin,
});

_Kareler? _karelerOnbellek;
_Kareler get _kareler => _karelerOnbellek ??= _kareleriTopla();

_Kareler _kareleriTopla() {
  final List<({GameState kare, bool hanede, String id, int yas})> hasta =
      <({GameState kare, bool hanede, String id, int yas})>[];
  final List<GameState> sakin = <GameState>[];
  for (final PlayerArchetype a in PlayerArchetype.values) {
    for (int i = 1; i <= 15; i++) {
      playBotLife(
        archetype: a,
        seed: i * 311 + a.index,
        onPreAge: (GameState s) {
          if (s.hasPendingEvent || s.hasNotice || s.deceased) return;
          final bool cocukVar = s.people.any((Person p) =>
              p.relation == RelationType.cocuk && p.isAlive);
          if (!cocukVar) return;
          final List<Person> hastalar = _gelecekYilHastalar(s);
          if (hastalar.length == 1) {
            hasta.add((
              kare: s,
              hanede: hastalar.first.inPlayerHousehold,
              id: hastalar.first.id,
              yas: hastalar.first.age + 1,
            ));
          } else if (hastalar.isEmpty && sakin.length < 60) {
            sakin.add(s);
          }
        },
      );
    }
  }
  return (hasta: hasta, sakin: sakin);
}

/// Kareyi bir yıl ilerletir. Modülü [acik] durumuna getirir; istenirse
/// kaydı yazıp okur ve **başka** bir ana zarla çalışır.
({GameState durum, List<String> yeniSatirlar}) _birYil(
  GameState kare, {
  required bool acik,
  int tohum = 4242,
  bool kaydetYukle = false,
}) {
  GameState giris = kare.copyWith(
    settings: kare.settings.copyWith(
      features: kare.settings.features.toggled(FeatureId.cocukHastaligi, acik),
    ),
  );
  if (kaydetYukle) {
    giris = decodeGameState(encodeGameState(giris));
  }
  final GameController c = GameController(random: Random(tohum))
    ..debugSetState(giris);
  final int oncekiSatir = c.state!.log.length;
  c.ageUp();
  final GameState sonra = c.state!;
  final List<String> yeni = <String>[
    for (final LifeLogEntry k in sonra.log.skip(oncekiSatir)) k.text,
  ];
  c.dispose();
  return (durum: sonra, yeniSatirlar: yeni);
}

/// Kişilerin karşılaştırılabilir özeti (zar sözleşmesi testi için).
String _kisiOzeti(GameState s) => s.people
    .map((Person p) =>
        '${p.id}:${p.age}:${p.isAlive}:${p.happiness}:${p.bond}')
    .join('|');

void main() {
  test('çocuk gerçekten hastalanıyor', () {
    final _Tarama t = _acik;
    // Bu kohortun ölçümü (120 hayat, 98 çocuk): **82 hastalık, 32
    // hayat**. Tabanlar ölçülenin yarısı kadar — dengeye dokunan bir
    // paket sayıyı kaydırabilir, ama Paket CN öncesi bu sayı **0**'dı
    // ve taban onu geçirmez.
    expect(t.cocuk, greaterThan(60),
        reason: 'taranan hayatlarda çocuk yok; ölçüm temsil etmiyor');
    expect(t.hastalik, greaterThanOrEqualTo(40),
        reason: 'çocuk hastalığı beklenenden seyrek: ${t.hastalik}');
    expect(t.gorenHayat, greaterThanOrEqualTo(15),
        reason: 'en az bir çocuk hastalığı gören hayat az: ${t.gorenHayat}');
  });

  test('iki hastalık arasında en az üç yıl var', () {
    expect(_acik.ihlal, 0,
        reason: 'aynı çocuk üç yıl geçmeden yeniden hastalandı');
  });

  test('zar sözleşmesi: hastalık olmayan yıl açık/kapalı birebir aynı',
      () {
    final List<GameState> sakin = _kareler.sakin;
    expect(sakin.length, greaterThanOrEqualTo(20),
        reason: 'çocuğu olan sakin kare bulunamadı');
    int karsilastirilan = 0;
    for (final GameState kare in sakin) {
      final ({GameState durum, List<String> yeniSatirlar}) acik =
          _birYil(kare, acik: true);
      // Tahmin tutmadıysa (hastalık çıktıysa) kare bu testin konusu
      // değil; atlanır.
      if (acik.yeniSatirlar.any((String t) => t.contains(kHastalikKuyrugu))) {
        continue;
      }
      final ({GameState durum, List<String> yeniSatirlar}) kapali =
          _birYil(kare, acik: false);
      karsilastirilan++;
      expect(acik.yeniSatirlar, kapali.yeniSatirlar,
          reason: 'çocuk hastalanmadığı hâlde yılın günlüğü ayrıştı: '
              'hastalık zarı ana diziden çekiliyor olabilir');
      expect(_kisiOzeti(acik.durum), _kisiOzeti(kapali.durum),
          reason: 'çocuk hastalanmadığı hâlde kişiler ayrıştı');
      expect(acik.durum.player.stats.happiness,
          kapali.durum.player.stats.happiness,
          reason: 'çocuk hastalanmadığı hâlde oyuncunun keyfi ayrıştı');
    }
    expect(karsilastirilan, greaterThanOrEqualTo(20),
        reason: 'karşılaştırılan sakin kare az: $karsilastirilan');
  });

  test('hanedeki çocuğun hastalığı oyuncuya işler, ayrı yaşayanın işlemez',
      () {
    final List<({GameState kare, bool hanede, String id, int yas})> kareler =
        _kareler.hasta;
    expect(kareler.length, greaterThanOrEqualTo(40),
        reason: 'tek çocuğu hastalanan kare az: ${kareler.length}');
    int hane = 0;
    int ayri = 0;
    int tamEtki = 0;
    for (final ({GameState kare, bool hanede, String id, int yas}) k
        in kareler) {
      final ({GameState durum, List<String> yeniSatirlar}) acik =
          _birYil(k.kare, acik: true);
      if (!acik.yeniSatirlar.any((String t) => t.contains(kHastalikKuyrugu))) {
        continue;
      }
      final ({GameState durum, List<String> yeniSatirlar}) kapali =
          _birYil(k.kare, acik: false);
      final int fark = acik.durum.player.stats.happiness -
          kapali.durum.player.stats.happiness;
      if (k.hanede) {
        hane++;
        // Kayıp tam −2'dir; azalan getiri (`StatGain.apply`) yılın
        // sonraki kazançlarında 1-2 puanını geri verebilir. Artıya
        // dönmesi **hiçbir** karede olmaz.
        expect(fark, lessThanOrEqualTo(0),
            reason: 'hanedeki çocuğun hastalığı oyuncunun keyfini '
                'yükseltti (fark $fark)');
        expect(fark, greaterThanOrEqualTo(NpcIllness.prototypeOnlyWorry),
            reason: 'kayıp −2 ile sınırlı olmalı, ölçülen $fark');
        if (fark == NpcIllness.prototypeOnlyWorry) tamEtki++;
      } else {
        ayri++;
        expect(fark, 0,
            reason: 'evden ayrılmış çocuğun hastalığı oyuncunun keyfini '
                'değiştirdi (fark $fark)');
      }
    }
    expect(hane, greaterThanOrEqualTo(10),
        reason: 'hanedeki çocuk karesi az: $hane');
    expect(ayri, greaterThanOrEqualTo(20),
        reason: 'ayrı yaşayan çocuk karesi az: $ayri');
    // Ölçümde 17/35; taban yarısının altında ama "hiç görünmüyor"un
    // çok üstünde.
    expect(tamEtki, greaterThanOrEqualTo(8),
        reason: 'tam −2 görülen kare az: $tamEtki');
  });

  test('aynı kişi-yıl aynı sonucu verir: kayıt yükleyerek çevrilemez', () {
    // Türetilmiş zar kararlı.
    final List<double> bir = <double>[
      for (int i = 0; i < 5; i++) NpcIllness.derivedRandom('abc', 12).nextDouble(),
    ];
    expect(bir.first, NpcIllness.derivedRandom('abc', 12).nextDouble());
    expect(NpcIllness.derivedRandom('abc', 12).nextDouble(),
        isNot(NpcIllness.derivedRandom('abc', 13).nextDouble()),
        reason: 'aynı kişinin iki yılı aynı zarı veriyor');
    expect(NpcIllness.derivedRandom('abc', 12).nextDouble(),
        isNot(NpcIllness.derivedRandom('abd', 12).nextDouble()),
        reason: 'iki kişi aynı zarı veriyor');

    // Oyunun içinde: aynı kare, **başka** ana zar ve kaydet/yükle
    // turundan sonra aynı çocuk aynı yaşta hastalanıyor.
    final List<({GameState kare, bool hanede, String id, int yas})> kareler =
        _kareler.hasta;
    int dogrulanan = 0;
    for (final ({GameState kare, bool hanede, String id, int yas}) k
        in kareler.take(12)) {
      final ({GameState durum, List<String> yeniSatirlar}) duz =
          _birYil(k.kare, acik: true);
      final bool duzHasta = _hastalikYillari(
        duz.durum.people.firstWhere((Person p) => p.id == k.id),
      ).contains(k.yas);
      if (!duzHasta) continue;
      final ({GameState durum, List<String> yeniSatirlar}) yuklu = _birYil(
        k.kare,
        acik: true,
        tohum: 909,
        kaydetYukle: true,
      );
      expect(
        _hastalikYillari(
          yuklu.durum.people.firstWhere((Person p) => p.id == k.id),
        ),
        contains(k.yas),
        reason: 'kaydı yazıp okuyup başka zarla oynayınca hastalık '
            'kayboldu: yeniden çevrilebiliyor',
      );
      dogrulanan++;
    }
    expect(dogrulanan, greaterThanOrEqualTo(8),
        reason: 'doğrulanan kare az: $dogrulanan');
  });

  test('modül kapalıyken çocuk hiç hastalanmıyor', () {
    final _Tarama t = _tara(6, acik: false);
    expect(t.cocuk, greaterThan(25),
        reason: 'taranan hayatlarda çocuk yok; ölçüm temsil etmiyor');
    expect(t.hastalik, 0,
        reason: 'modül kapalı ama çocuk hastalandı');
    expect(t.gorenHayat, 0);
  });

  test('paylaşılan kural eşin sayılarını koruyor', () {
    // Eş, bot hayatından **bulunuyor**; durum kurulmuyor.
    Person? es;
    for (final PlayerArchetype a in PlayerArchetype.values) {
      if (es != null) break;
      for (int i = 1; i <= 20; i++) {
        if (es != null) break;
        playBotLife(
          archetype: a,
          seed: i * 53 + a.index,
          onYear: (GameState s) {
            if (es != null) return;
            final Person? aday = s.spouse;
            if (aday != null &&
                aday.isAlive &&
                aday.development != null &&
                NpcIllness.lastIllnessAge(aday.development!) == null) {
              es = aday;
            }
          },
        );
      }
    }
    expect(es, isNotNull, reason: 'hastalanmamış yaşayan eş bulunamadı');

    // Hastalığı **kesin** çıkaran tohumu ara (zarı çağıran veriyor).
    final double esik = NpcIllness.prototypeOnlyChance(es!.age);
    int tohum = 0;
    while (tohum < 5000 && Random(tohum).nextDouble() >= esik) {
      tohum++;
    }
    expect(Random(tohum).nextDouble(), lessThan(esik),
        reason: 'hastalık çıkaran tohum bulunamadı');

    final int oncekiSaglik = es!.development!.stats.health;
    final int oncekiKeyif = es!.development!.stats.happiness;
    final NpcIllnessYear sonuc = NpcIllness.maybe(es!, Random(tohum));
    expect(sonuc.text, '${es!.firstName} $kHastalikKuyrugu');
    expect(sonuc.person.development!.stats.health,
        StatGain.apply(oncekiSaglik, NpcIllness.prototypeOnlyHealth),
        reason: 'hastalığın sağlık etkisi değişti');
    expect(sonuc.person.development!.stats.happiness,
        StatGain.apply(oncekiKeyif, NpcIllness.prototypeOnlyHappiness),
        reason: 'hastalığın keyif etkisi değişti');
    expect(NpcIllness.lastIllnessAge(sonuc.person.development!), es!.age,
        reason: 'hastalık izi kişinin dönüm noktasına yazılmadı');

    // Üç yıllık ara: aynı zarla hemen ikinci hastalık çıkmaz.
    final NpcIllnessYear ikinci =
        NpcIllness.maybe(sonuc.person, Random(tohum));
    expect(ikinci.text, isNull,
        reason: 'üç yıllık ara eşte çalışmıyor');
  });
}
