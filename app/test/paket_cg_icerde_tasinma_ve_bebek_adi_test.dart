// Paket CG — ekran dökümünün yeni turunda çıkan iki hata.
//
// **Nasıl bulundu.** `ekran_dokumu_ozel_durum_test.dart` yedi özel
// durumu tarayıp buluyor ve o karelerin ekranlarını basıyor. Çıktı
// gözle okundu; iki satır birbirini yalanlıyordu.
//
// **1) Cezaevindeki oyuncu evden taşınabiliyordu.** Künye "Evde seninle
// 3 kişi yaşıyor" diyor, Varlıklar ekranı "Yaşadığın yer: Ailesinin
// yanında · Samsun" yazıyor ve **"Kiralık eve çık" düğmesi açık**
// duruyordu. Koda bakıldığında sebep netti: aktivite
// (`activity_engine`), iş (`job_market`) ve işletme
// (`business_engine`) motorları `isImprisoned`'a bakıyor; **konut
// motoru hiçbir yerde bakmıyordu.** Yani bu bir metin hatası değil,
// içeriden ev değiştirme yolu.
//
// **2) Bebeğin iki adı vardı.** Bebek oyunun havuzundan bir adla
// doğuyor ve doğum satırı o adı yazıyor: "Nuri adında bir oğlunuz
// oldu." Oyuncu ad verdiğinde yalnızca ikinci bir satır ekleniyordu:
// "Bebeğe Kemal adını verdin." Doğum satırı olduğu gibi kalıyor ve
// günlükte, aynı yılda, aynı çocuk için iki ad birden duruyordu.
// Günlük oyunun hafızası (`Başından geçenlerin kaydı`); orada hiç var
// olmamış bir ad kalmamalı.
//
// **3) İçerideyken hasta hayvan bildirimi kapalı bir kapıyı
// gösteriyordu.** Hükümlü oyuncunun Aktiviteler sekmesinde yalnızca
// "İçeride yapılabilecekler" bölümü var (döküm bunu da bastı: `Görüş,
// kitap, spor, sakin kalmak`). Buna karşın hayvan hastalandığında
// bildirim "Aktiviteler → Evcil Hayvanlar'dan veterinere
// götürebilirsin" diyordu. Bildirim kalıyor — hayvanının hastalandığını
// bilmek oyuncunun hakkı — ama artık yapılamayacak bir şeyi önermiyor.
// Bakımın kimden çıkacağı ve hayvanın içerideyken ne olacağı tasarım
// sorusu; sayılara dokunulmadı, kuyruğa yazıldı (Q-225).
//
// **Durum kurulmuyor, aranıyor.** İkisi de bot hayatları oynanarak
// bulunuyor; `copyWith` ile hükümlü ya da bebekli bir durum kurmak bu
// dürbünün üç kez yanlış bulgu üretmesine yol açmıştı.
library;

import 'dart:math';

import 'package:bir_omur/domain/economy/housing.dart';
import 'package:bir_omur/domain/interaction/parenthood.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/life_log.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/person_development.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/pets/pet_care.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/state/game_scope.dart';
import 'package:bir_omur/ui/theme/bir_omur_theme.dart';
import 'package:bir_omur/ui/screens/sections/assets_screen.dart';
import 'package:bir_omur/ui/widgets/character_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// Taranan hayatlarda **ilk** bulunan kare.
GameState? _ara(bool Function(GameState) kosul, {int tohum = 101}) {
  GameState? bulunan;
  for (final PlayerArchetype a in PlayerArchetype.values) {
    for (int seed = 1; seed <= 40; seed++) {
      if (bulunan != null) return bulunan;
      playBotLife(
        archetype: a,
        seed: seed * tohum + a.index,
        onPreAge: (GameState s) {
          if (bulunan != null) return;
          if (kosul(s)) bulunan = s;
        },
      );
    }
  }
  return bulunan;
}

void main() {
  group('Paket CG §1 — içerideyken taşınma', () {
    late GameState hukumlu;

    setUpAll(() {
      final GameState? kare = _ara((GameState s) => s.isImprisoned);
      expect(kare, isNotNull,
          reason: 'taranan hayatlarda hükümlü bir yıl bulunamadı; '
              'tarama bozuk olabilir');
      hukumlu = kare!;
    });

    test('konut motoru hükümlülüğü engel sayıyor', () {
      expect(Housing.imprisonedBlockReason(hukumlu), isNotEmpty,
          reason: 'hükümlü oyuncu için taşınma engeli yazılmadı');
      expect(Housing.imprisonedBlockReason(hukumlu), contains('Cezaevindesin'),
          reason: 'engelin gerekçesi oyuncuya cezaevini söylemeli');
    });

    test('kiralık eve çıkma ve aile yanına dönme reddediliyor', () {
      final GameController c = GameController(random: Random(5101))
        ..debugSetState(hukumlu);
      addTearDown(c.dispose);

      final ResidenceKind once = Housing.residenceOf(c.state!);

      final HousingOutcome? kira = c.moveToRental();
      expect(kira, isNotNull);
      expect(kira!.applied, isFalse,
          reason: 'cezaevindeki oyuncu kiralık eve çıkabildi');
      expect(kira.text, contains('Cezaevindesin'));

      final HousingOutcome? aile = c.moveBackToFamily();
      expect(aile, isNotNull);
      expect(aile!.applied, isFalse,
          reason: 'cezaevindeki oyuncu ailesinin yanına taşınabildi');
      expect(aile.text, contains('Cezaevindesin'));

      // Oturulan yer kıpırdamadı: engel yalnızca metin değil.
      expect(Housing.residenceOf(c.state!), once);
    });

    testWidgets('künye haneyi değil hükümlülüğü yazıyor',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: BirOmurTheme.light(),
        home: Scaffold(body: CharacterHeader(state: hukumlu)),
      ));
      await tester.pumpAndSettle();

      final List<String> metinler = <String>[
        for (final Text w in tester.widgetList<Text>(find.byType(Text)))
          w.data ?? w.textSpan?.toPlainText() ?? '',
      ];
      final String hepsi = metinler.join(' | ');
      expect(hepsi, contains('Cezaevindesin'),
          reason: 'içerideki oyuncunun künyesi hükümlülüğü söylemiyor');
      expect(hepsi, isNot(contains('Evde seninle')),
          reason: 'içerideki oyuncunun künyesi hâlâ hane satırını '
              'gösteriyor: $hepsi');
    });

    testWidgets('Varlıklar ekranı gerçek yeri yazıyor, düğmeyi açmıyor',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 9000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final GameController c = GameController(random: Random(5102))
        ..debugSetState(hukumlu);
      addTearDown(c.dispose);

      await tester.pumpWidget(GameScope(
        controller: c,
        child: MaterialApp(
          theme: BirOmurTheme.light(),
          home: Scaffold(body: AssetsScreen(onBack: () {})),
        ),
      ));
      await tester.pumpAndSettle();

      final Text yer = tester.widget<Text>(find.byKey(
        const Key('residence_label'),
      ));
      expect(yer.data, contains('Cezaevinde'),
          reason: 'içerideki oyuncuya hâlâ eski adresi yaşadığı yer '
              'olarak gösteriliyor: ${yer.data}');

      // Kayıt silinmiyor: nerede oturuyordu, ikinci satırda duruyor.
      expect(find.byKey(const Key('residence_registered_label')), findsOneWidget,
          reason: 'kayıtlı yer satırı kayboldu');

      expect(find.byKey(const Key('move_to_rental')), findsNothing,
          reason: 'cezaevindeyken "Kiralık eve çık" düğmesi açık');
      expect(find.byKey(const Key('move_to_family')), findsNothing,
          reason: 'cezaevindeyken "Ailenin yanına dön" düğmesi açık');
    });
  });

  group('Paket CG §3 — içerideyken hasta hayvan bildirimi', () {
    test('kapalı kapıyı göstermiyor, dışarıda ise yolu söylüyor', () {
      final GameState? icerde = _ara(
        (GameState s) =>
            s.isImprisoned && PetCare.livingPets(s).isNotEmpty,
        tohum: 83,
      );
      expect(icerde, isNotNull,
          reason: 'hayvanı olan hükümlü bir yıl bulunamadı');
      final String icerdeMetin = PetCare.illnessNoticeText(
          icerde!, PetCare.livingPets(icerde).first);
      expect(icerdeMetin, contains('tahliye'),
          reason: 'içerideki oyuncuya ne zaman bakabileceği söylenmiyor');
      expect(icerdeMetin, isNot(contains('Aktiviteler')),
          reason: 'içerideyken kapalı olan Evcil Hayvanlar yolu '
              'öneriliyor: $icerdeMetin');

      final GameState? disarda = _ara(
        (GameState s) =>
            !s.isImprisoned && PetCare.livingPets(s).isNotEmpty,
        tohum: 83,
      );
      expect(disarda, isNotNull, reason: 'hayvanı olan serbest yıl yok');
      final String disardaMetin = PetCare.illnessNoticeText(
          disarda!, PetCare.livingPets(disarda).first);
      expect(disardaMetin, contains('Aktiviteler'),
          reason: 'serbest oyuncuya veterinere götürme yolu artık '
              'söylenmiyor: $disardaMetin');
    });
  });

  group('Paket CG §2 — bebeğin tek adı', () {
    test('ad verilince doğum satırı ve kilometre taşı tazeleniyor', () {
      final GameState? kare = _ara(
        (GameState s) => s.people.any((Person p) =>
            p.relation == RelationType.cocuk && p.isAlive && p.age == 0),
        tohum: 97,
      );
      expect(kare, isNotNull,
          reason: 'taranan hayatlarda yeni doğmuş bebek bulunamadı');

      final GameController c = GameController(random: Random(5103))
        ..debugSetState(kare!);
      addTearDown(c.dispose);

      final Person bebek = c.state!.people.firstWhere((Person p) =>
          p.relation == RelationType.cocuk && p.isAlive && p.age == 0);
      final String eskiAd = bebek.firstName;
      expect(c.canNameChild(bebek.id), isTrue,
          reason: '0 yaşındaki bebeğe ad verilemiyor');

      const String yeniAd = 'Zeynep';
      expect(eskiAd, isNot(yeniAd), reason: 'ölçüm için ad farklı olmalı');
      c.nameChild(bebek.id, yeniAd);

      final GameState sonra = c.state!;
      final Person yeni = sonra.personById(bebek.id)!;
      expect(yeni.firstName, yeniAd);

      // 1) Doğum satırı yeni adı taşıyor ve **tek** satır.
      final String yeniCumle = Parenthood.birthSentence(
          name: yeniAd, gender: yeni.gender, twin: false);
      final String eskiCumle = Parenthood.birthSentence(
          name: eskiAd, gender: yeni.gender, twin: false);
      final List<LifeLogEntry> dogum = sonra.log
          .where((LifeLogEntry e) => e.text.contains(yeniCumle))
          .toList(growable: false);
      expect(dogum.length, 1,
          reason: 'doğum satırı yeni adla bir kez yazılmalı; '
              '${dogum.length} satır bulundu');

      // 2) Eski ad günlükte doğum cümlesi olarak **hiç** kalmıyor.
      expect(sonra.log.where((LifeLogEntry e) => e.text.contains(eskiCumle)),
          isEmpty,
          reason: 'günlükte bebeğin eski adıyla doğum satırı kaldı '
              '($eskiAd → $yeniAd): oyuncu aynı yılda iki ad görüyor');

      // 3) Ad verme eylemi kayda giriyor (sonuç görünür olmalı).
      expect(
          sonra.log.any((LifeLogEntry e) =>
              e.text == 'Bebeğe $yeniAd adını verdin.' &&
              e.personId == bebek.id),
          isTrue,
          reason: 'ad verme satırı günlüğe yazılmadı');

      // 4) Çocuğun kendi kaydındaki doğum kilometre taşı da tazelendi.
      final PersonDevelopment? kayit = yeni.development;
      expect(kayit, isNotNull, reason: 'bebeğin gelişim kaydı yok');
      final List<String> tasLar =
          kayit!.milestones.map((LifeMilestone m) => m.text).toList();
      expect(tasLar, contains(Parenthood.birthMilestone(yeniAd)),
          reason: 'kişi kartındaki doğum satırı eski adla kaldı: $tasLar');
      expect(tasLar, isNot(contains(Parenthood.birthMilestone(eskiAd))));
    });
  });
}
