// Paket CS — dulluk: eşini kaybettikten sonraki yıllar.
//
// **Nereden çıktı.** `docs/EKSIKLER.md` §3.6 dulluğu yarım bırakmıştı.
// 26 Eylül 2026'da kodu okuyan not doğruydu — dulluk ile boşanma ayrı
// iki durum, ekran metinleri ayrı, `settleWidowhood` bağı `eskiEs`'e
// düşürmüyor — ama maddenin kalanı açık kalmıştı: *"hâlâ yok: dulluğun
// kendine ait olay havuzu (anma, yıl dönümü, eşin ailesiyle bağın
// sürmesi)."*
//
// **Ölçüm (11 Ekim 2026, 250 bot hayatı, dört arketip).**
//
// | ölçülen | sayı |
// |---|---|
// | dul kalan hayat | 43 / 250 (%17,2) |
// | dul kalma yaşı | en küçük 38 · medyan 68 · en büyük 87 |
// | dul geçen yıl | en az 0 · medyan 10 · en çok 39 |
// | toplam dul yılı | **502** |
// | dulken görülen olay türü | 212 |
// | bunlardan dulluğa ait olan | **0** |
//
// En çok çıkanlar `komsu_apartman_karari`, `orta_teknoloji_gerisi`,
// `sabah_yuruyusu`: 70 yaşında eşini kaybetmiş oyuncu 40 yaşında evli
// oyuncuyla aynı havuzu çekiyordu. Kodda hiçbir `EventRequirement`
// `MarriageStatus.dul` okumuyordu — kapı yoktu, havuz yoktu.
//
// **Havuzdan sonra (aynı 250 hayat, aynı tohumlar).** Dul kalan 43
// hayatın 29'u (%67) en az bir dulluk olayı görüyor; 556 dul yılında
// toplam 60 dulluk olayı çıktı.
//
// **Çıkmayan üç olay ve gerçek sebepleri** (Paket CK'nın ölçütü:
// "görülmedi" ulaşılamazlık demek değil):
//
// | olay | sebep | sınıf |
// |---|---|---|
// | `dul_kayin_telefonu` | dullukta kayını yaşayan kare 56/397 (%14); ağırlık 4 ile beklenen 0,7 | OYUN — ağırlık 12'ye çıkarıldı |
// | `dul_kayin_kapida` | zincirin ilk halkası çıkmadığı için izi hiç konmadı | aynı kökün sonucu |
// | `dul_odanin_kapisi` | izi koyan seçeneği (`birak`, keyif −2) bot hiç seçmiyor; `birkac` (+2) kazanıyor | **BOT** |
//
// Kayın ölçümü (250 hayat): evlilik sürerken kayını yaşayan kare
// 2818/5112 (%55), dullukta 56/397 (%14) — kayınlar oyuncudan bir
// kuşak büyük olduğu için eşten de önce gidiyorlar. Koşul
// **gevşetilmedi**; yaygın durumun (o taraftan kimse kalmaması) kendi
// olayı yazıldı: `dul_o_taraftan_kimse`.
//
// Bu dosya dört şeyi çiviler:
//
// 1. Kapı kayıttan okunuyor: boşanmışa, evliye ve hiç evlenmemişe
//    dulluk olayı aday **olmuyor**; tekrar evlenince susuyor.
// 2. `minWidowYears` / `maxWidowYears` gerçekten pencere açıyor.
// 3. Botun seçmediği iki yol (iz bırakan `birak` dalı ve kayın
//    zinciri) elle kurulan durumda uçtan uca işliyor.
// 4. Modül kapalıyken havuz hiç listelenmiyor (fail-closed) ve
//    `{es}` yer tutucusu ham kalmıyor.

import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/event_pool_widowhood.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/features/feature_catalog.dart';
import 'package:bir_omur/domain/features/feature_events.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// Havuzun kimlikleri.
Set<String> get _havuz => <String>{
      for (final GameEvent e in kWidowhoodEvents) e.id,
    };

/// Dul kalındıktan bu yana geçen yıl; dul değilse `null`.
int? _dulYil(GameState s) {
  final Marriage? m = s.marriage;
  if (m == null || m.status != MarriageStatus.dul) return null;
  final int? bitis = m.endedAtAge;
  if (bitis == null) return null;
  final int yil = s.player.age - bitis;
  return yil < 0 ? null : yil;
}

void main() {
  const EventEngine motor = EventEngine();

  test('§1 kapı kayıttan okunur: dul olmayana hiçbir dulluk olayı '
      'aday olmaz', () {
    int dulKare = 0;
    int dulDegilKare = 0;
    int bosanmisKare = 0;
    int kacak = 0; // dul olmayan karede aday olan dulluk olayı
    int pencereKacak = 0; // yıl penceresini tutmayan aday

    for (final PlayerArchetype a in <PlayerArchetype>[
      PlayerArchetype.family,
      PlayerArchetype.social,
      PlayerArchetype.career,
      PlayerArchetype.sport,
    ]) {
      for (int seed = 0; seed < 30; seed++) {
        playBotLife(
          archetype: a,
          seed: 90000 + seed * 4 + a.index,
          onPreAge: (GameState s) {
            final int? yil = _dulYil(s);
            final Set<String> adaylar =
                motor.debugEligibleIds(s, Random(31)).intersection(_havuz);
            if (yil == null) {
              dulDegilKare++;
              if (s.marriage?.status == MarriageStatus.bosandi) {
                bosanmisKare++;
              }
              kacak += adaylar.length;
              return;
            }
            dulKare++;
            for (final String id in adaylar) {
              final EventRequirement r = kEventPool
                  .firstWhere((GameEvent e) => e.id == id)
                  .requirement;
              if (yil < r.minWidowYears) pencereKacak++;
              if (r.maxWidowYears != null && yil > r.maxWidowYears!) {
                pencereKacak++;
              }
            }
          },
        );
      }
    }

    // Ölçüm gerçekten iki tarafı da gördü mü?
    expect(dulKare, greaterThan(100), reason: 'dul kare: $dulKare');
    expect(dulDegilKare, greaterThan(3000),
        reason: 'dul olmayan kare: $dulDegilKare');
    expect(bosanmisKare, greaterThan(0),
        reason: 'boşanmış kare hiç görülmedi: ölçüm boşanmayı sınamıyor');

    // Kapı: dul olmayan tek bir karede bile dulluk olayı aday olmamalı.
    expect(kacak, 0, reason: 'dul olmayan karede aday olan dulluk olayı');
    // Pencere: minWidowYears / maxWidowYears gerçekten süzüyor mu?
    expect(pencereKacak, 0, reason: 'yıl penceresi tutmayan aday');
  });

  test('§2 havuz oyuncuya ulaşıyor: dul hayatların çoğu en az bir '
      'dulluk olayı görüyor', () {
    int dulHayat = 0;
    int gorenHayat = 0;
    int toplamOlay = 0;
    final Map<String, int> gorulme = <String, int>{};

    for (int i = 0; i < 250; i++) {
      const List<PlayerArchetype> ark = <PlayerArchetype>[
        PlayerArchetype.family,
        PlayerArchetype.social,
        PlayerArchetype.career,
        PlayerArchetype.sport,
      ];
      bool dul = false;
      final BotLifeResult r = playBotLife(
        archetype: ark[i % ark.length],
        seed: 90000 + i,
        onYear: (GameState s) {
          if (_dulYil(s) != null) dul = true;
        },
      );
      if (dul) dulHayat++;
      final Set<String> kesisim = r.seenEvents.intersection(_havuz);
      if (kesisim.isNotEmpty) {
        gorenHayat++;
        toplamOlay += kesisim.length;
        for (final String e in kesisim) {
          gorulme[e] = (gorulme[e] ?? 0) + 1;
        }
      }
    }

    // Ölçülen: 43 dul hayat, 29'u olay görüyor, toplam 60 olay.
    // Tabanlar ölçümün altına konuldu; ORANLARI GÜZELLEŞTİRME, ÖLÇ.
    expect(dulHayat, greaterThanOrEqualTo(25),
        reason: 'dul kalan hayat: $dulHayat');
    expect(gorenHayat, greaterThanOrEqualTo(15),
        reason: 'dulluk olayı gören hayat: $gorenHayat / $dulHayat');
    expect(toplamOlay, greaterThanOrEqualTo(30),
        reason: 'toplam dulluk olayı: $toplamOlay');
    // Havuzun yarısından çoğu gerçekten çıkmalı: tek tek şans değil,
    // havuzun geneli ölçülüyor.
    expect(gorulme.length, greaterThanOrEqualTo(10),
        reason: 'çıkan tekil olay: ${gorulme.length} / ${_havuz.length}');
  });

  test('§3 botun seçmediği iki yol elle kurulduğunda işliyor', () {
    // Ölçümde çıkmayan üç olaydan ikisi bota bağlıydı. Burada o
    // yolların **oyun tarafı** sınanıyor: durum elle kurulup olayın
    // aday olup olmadığına bakılıyor.
    // Kare **aranıyor**, kurulmuyor: tek tohumun şansına bağlı bir
    // test ilk yazımda kırmızıya düştü (90001'de 3+ yıllık dul kare
    // yoktu). Tohumlar sırayla taranıp ilk uygun kare alınıyor.
    GameState? dulKare;
    for (int seed = 0; seed < 60 && dulKare == null; seed++) {
      playBotLife(
        archetype: PlayerArchetype.family,
        seed: 90000 + seed,
        onPreAge: (GameState s) {
          final int? yil = _dulYil(s);
          if (yil != null && yil >= 3 && dulKare == null) dulKare = s;
        },
      );
    }
    expect(dulKare, isNotNull,
        reason: '60 tohumda 3+ yıllık dul kare bulunamadı');
    final GameState temel = dulKare!;

    // (a) `dul_odanin_kapisi`: izi koyan seçeneği bot hiç seçmiyor
    //     (keyif −2). İz elle konunca olay aday olmalı.
    expect(
      motor.debugEligibleIds(temel, Random(7)),
      isNot(contains('dul_odanin_kapisi')),
      reason: 'iz yokken karşılık olayı aday olmamalı',
    );
    final GameState izli = temel.copyWith(
      storyFlags: <String>{...temel.storyFlags, WidowFlags.esyaKaldirilmadi},
    );
    expect(
      motor.debugEligibleIds(izli, Random(7)),
      contains('dul_odanin_kapisi'),
      reason: 'iz konunca karşılık olayı aday olmalı',
    );

    // (b) Kayın zinciri: ilk halka yaşayan kayın istiyor. Kayın
    //     eklenince aday olmalı; iz de konunca ikinci halka gelmeli.
    final Person kayin = Person(
      id: 'cs_kayinvalide',
      firstName: 'Nebahat',
      lastName: 'Aydın',
      relation: RelationType.kayinvalide,
      age: 88,
      bond: 60,
      gender: Gender.kadin,
      isAlive: true,
      inPlayerHousehold: false,
      employment: EmploymentStatus.emekli,
      wealth: WealthTier.ortaHalli,
    );
    final GameState kayinli = temel.copyWith(
      people: List<Person>.unmodifiable(<Person>[...temel.people, kayin]),
    );
    expect(
      motor.debugEligibleIds(kayinli, Random(7)),
      contains('dul_kayin_telefonu'),
      reason: 'yaşayan kayın varken zincirin ilk halkası aday olmalı',
    );
    final GameState kayinliIzli = kayinli.copyWith(
      storyFlags: <String>{...kayinli.storyFlags, WidowFlags.kayinBagiSurdu},
    );
    expect(
      motor.debugEligibleIds(kayinliIzli, Random(7)),
      contains('dul_kayin_kapida'),
      reason: 'bağ sürdüyse ikinci halka aday olmalı',
    );

    // Kayın vefat etmişse ilk halka yine kapalı: koşul gevşetilmedi.
    final GameState oluKayin = temel.copyWith(
      people: List<Person>.unmodifiable(<Person>[
        ...temel.people,
        kayin.copyWith(isAlive: false),
      ]),
    );
    expect(
      motor.debugEligibleIds(oluKayin, Random(7)),
      isNot(contains('dul_kayin_telefonu')),
      reason: 'vefat etmiş kayın zinciri açmamalı',
    );
  });

  test('§4 modül kapalıyken havuz hiç listelenmez (fail-closed)', () {
    int dulKare = 0;
    int kapaliAday = 0;
    const List<PlayerArchetype> ark = <PlayerArchetype>[
      PlayerArchetype.family,
      PlayerArchetype.social,
      PlayerArchetype.career,
      PlayerArchetype.sport,
    ];
    for (int seed = 0; seed < 80; seed++) {
      playBotLife(
        archetype: ark[seed % ark.length],
        seed: 90000 + seed,
        onPreAge: (GameState s) {
          if (_dulYil(s) == null) return;
          dulKare++;
          final GameState kapali = s.copyWith(
            settings: s.settings.copyWith(
              features: s.settings.features.toggled(FeatureId.dulluk, false),
            ),
          );
          kapaliAday +=
              motor.debugEligibleIds(kapali, Random(5)).intersection(_havuz).length;
        },
      );
    }
    // Ölçülen dul kare: 40 `family` hayatında 47, 80 karışık arketip
    // hayatında 51 — `family` arketipi daha çok evlendiği için daha çok
    // dul kalıyor, yani sayı kohortun bileşimine duyarlı. Tabanın işi
    // ölçümün dulluğu **gerçekten gördüğünü** kanıtlamak; iki ölçümün
    // de altına konuldu.
    expect(dulKare, greaterThan(30), reason: 'dul kare: $dulKare');
    expect(kapaliAday, 0, reason: 'modül kapalıyken aday olan dulluk olayı');
    // Modül kaydı gerçekten kurulu mu?
    expect(FeatureEvents.idsOf(FeatureId.dulluk), _havuz);
  });

  test('§5 {es} yer tutucusu ham kalmaz ve ad okunamazsa cümle bozulmaz',
      () {
    // Havuzdaki her metin `{es}` olmadan da tam cümle kurmalı: yer
    // tutucu doldurulamazsa oyuncu yarım cümle görmez, sadece adı
    // görmez.
    for (final GameEvent e in kWidowhoodEvents) {
      for (final String metin in <String>[
        e.text,
        for (final EventChoice c in e.choices) c.label,
        for (final EventChoice c in e.choices) c.resultText,
      ]) {
        // `{es}` dışında yer tutucu kullanan olay yalnızca kişi
        // isteyenler olabilir (`{kisi}`); başka yer tutucu olmamalı.
        final Iterable<Match> tutucular =
            RegExp(r'\{[a-zA-Z]+\}').allMatches(metin);
        for (final Match m in tutucular) {
          expect(
            <String>['{es}', '{kisi}'],
            contains(m.group(0)),
            reason: '${e.id}: bilinmeyen yer tutucu ${m.group(0)}',
          );
        }
        // `{kisi}` kullanan olay gerçekten kişi istemeli.
        if (metin.contains('{kisi}')) {
          expect(
            e.requirement.livingRelations.isNotEmpty ||
                e.requirement.personRole != null,
            isTrue,
            reason: '${e.id}: {kisi} var ama olay kişi istemiyor',
          );
        }
      }
      // `{es}` kullanan her olay dulluk kapısından geçmeli, yoksa
      // doldurucu çalışmaz ve ekranda ham yer tutucu kalır.
      final bool esKullaniyor = e.text.contains('{es}') ||
          e.choices.any((EventChoice c) =>
              c.label.contains('{es}') || c.resultText.contains('{es}'));
      if (esKullaniyor) {
        expect(e.requirement.requiresWidowed, isTrue,
            reason: '${e.id}: {es} var ama requiresWidowed yok');
      }
    }
  });

  test('§6 her iz okunur: karşılığı olmayan iz bırakılmaz', () {
    // Paket AR'nin ölçtüğü "sessiz iz" hatası: bir seçenek iz koyuyor
    // ama hiçbir olay o izi okumuyor.
    final Set<String> konan = <String>{};
    final Set<String> okunan = <String>{};
    for (final GameEvent e in kEventPool) {
      okunan.addAll(e.requirement.requiredFlags);
      for (final EventChoice c in e.choices) {
        konan.addAll(c.addFlags.where((String f) => f.startsWith('dul_')));
      }
    }
    final Set<String> sessiz = konan.difference(okunan);
    // **İstisna yok.** İlk yazımda beş karşılık olayı kendi "kapandı"
    // izini bırakıyor, bu test de onları "hikâyenin sonu" diye muaf
    // tutuyordu. Depo çapındaki `paket_ar_hikaye_izi_test.dart` bunu
    // yakaladı: okunmayan iz sayısı 22'den 27'ye çıkıyordu. Muafiyet
    // kaldırıldı ve izler **yazılmaz** oldu; olayların tekrar
    // çıkmasını `seenEventIds` zaten engelliyor.
    expect(sessiz, isEmpty,
        reason: 'karşılığı olmayan dulluk izi: $sessiz');
    // Beş izin beşi de gerçekten bir karşılık olayı tarafından
    // okunuyor olmalı (zincir kopmasın).
    expect(
      okunan.where((String f) => f.startsWith('dul_')).toSet(),
      <String>{
        WidowFlags.esyaKaldirilmadi,
        WidowFlags.esyaVerildi,
        WidowFlags.anmaDuzeni,
        WidowFlags.kayinBagiSurdu,
        WidowFlags.isiDevraldi,
      },
    );
  });
}
