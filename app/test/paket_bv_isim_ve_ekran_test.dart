// Paket BV — **okunmayan ekranlar ve ad çakışması**.
//
// İki iş bir arada, çünkü ikisi de aynı turda döküm okunurken çıktı:
//
// 1. **Döküm hâle göre kare almıyordu.** Yaş planı belli ekranları hiç
//    yakalamıyordu: yeni doğan bebek, tahliye sonrası denetim dönemi ve
//    süren gebelik. Üçü de `ekran_dokumu_bot_test.dart` içinde durum
//    odaklı kare arayıcısıyla okunur hâle geldi.
// 2. **Ad çakışması ölçüldü.** 300 hayatta kayıttaki kişi sayısının
//    medyanı 58; cinsiyet başına 20 isimle iki yaşayan kişinin aynı adı
//    taşıması 283/300 hayatta oluyordu. Havuz 60'a çıkarıldı (içerik,
//    kural değil) ve kişi üretiminde eksik kalan iki yer düzeltildi:
//    **gelin/damat** ve **torun**. Sonuç: 283/300 → 106/300.
//
// Hayat üretimindeki **ebeveyn ve kardeş** adlarına dokunulmadı: o soru
// `docs/DESIGN_REVIEW_QUEUE.md` Q-198 #6'da Faho'nun kararını bekliyor.
library;

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/name_pool.dart';
import 'package:bir_omur/domain/generation/child_marriage.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/random_util.dart';
import 'package:bir_omur/domain/models/criminal_record.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/person_development.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ===================================================================
  // İsim havuzu
  // ===================================================================
  group('İsim havuzu', () {
    test('havuzlar yeterince geniş ve tekrarsız', () {
      // Ölçüldü: kayıttaki kişi sayısının medyanı 58. Cinsiyet başına
      // 40'tan az isim, aynı adı taşıyan iki kişiyi **kural** yapar.
      expect(kadinIsimleri.length, greaterThanOrEqualTo(50));
      expect(erkekIsimleri.length, greaterThanOrEqualTo(50));
      expect(soyisimler.length, greaterThanOrEqualTo(50));
      for (final List<String> havuz in <List<String>>[
        kadinIsimleri,
        erkekIsimleri,
        soyisimler,
      ]) {
        expect(havuz.toSet().length, havuz.length,
            reason: 'havuzda tekrar eden ad var');
        for (final String ad in havuz) {
          expect(ad.trim(), ad, reason: '"$ad" boşlukla başlıyor/bitiyor');
          expect(ad.length, greaterThanOrEqualTo(2));
        }
      }
      // Kadın ve erkek havuzları karışmaz: aynı ad iki havuzda birden
      // durursa "aynı adlı iki kişi" ihtimali gizlice iki katına çıkar.
      expect(
        kadinIsimleri.toSet().intersection(erkekIsimleri.toSet()),
        isEmpty,
      );
    });

    test('pickFreshName kullanılmayan adı seçer, havuz tükenince döner',
        () {
      final Random rng = Random(3);
      const List<String> havuz = <String>['Ali', 'Veli', 'Ayşe'];
      for (int i = 0; i < 20; i++) {
        expect(
          rng.pickFreshName(havuz, <String>{'Ali', 'Veli'}),
          'Ayşe',
          reason: 'boş yuva varken kullanılan ad seçilmemeli',
        );
      }
      // Hepsi kullanılıyorsa boş dönmek yerine rastgele verir.
      expect(
        havuz,
        contains(rng.pickFreshName(havuz, havuz.toSet())),
      );
    });
  });

  // ===================================================================
  // Kişi üretiminde ad çakışması
  // ===================================================================
  group('Ad çakışması', () {
    test('gelin/damat adı kayıttaki adlardan seçilmez', () {
      // Kalabalık bir kayıt kurulur: havuzun yarısı kullanılmış olur.
      GameState s =
          LifeGenerator.seeded(77).generate(mode: StartMode.tamamenRastgele);
      final List<Person> dolgu = <Person>[
        for (int i = 0; i < 40; i++)
          Person(
            id: 'dolgu-$i',
            firstName: erkekIsimleri[i % erkekIsimleri.length],
            lastName: 'Demir',
            gender: Gender.erkek,
            relation: RelationType.isArkadasi,
            age: 40,
            isAlive: true,
            inPlayerHousehold: false,
            employment: EmploymentStatus.calisiyor,
            occupation: 'memur',
            wealth: WealthTier.ortaHalli,
            bond: 20,
          ),
      ];
      final Person kiz = Person(
        id: 'cocuk-1',
        firstName: 'Elif',
        lastName: 'Demir',
        gender: Gender.kadin,
        relation: RelationType.cocuk,
        age: 26,
        isAlive: true,
        inPlayerHousehold: false,
        employment: EmploymentStatus.calisiyor,
        occupation: 'memur',
        wealth: WealthTier.ortaHalli,
        bond: 60,
        // Evlenebilmesi için kendi hayatını yaşıyor olmalı (eligible).
        development: const PersonDevelopment(
          tracksLife: true,
          stats: Stats(
            happiness: 60,
            health: 70,
            intelligence: 60,
            charisma: 60,
            appearance: 60,
          ),
        ),
      );
      s = s.copyWith(
        player: s.player.copyWith(age: 52),
        people: List<Person>.unmodifiable(<Person>[...s.people, ...dolgu, kiz]),
      );
      final Set<String> mevcut = <String>{
        s.player.firstName,
        for (final Person p in s.people) p.firstName,
      };

      int denenen = 0;
      for (int tohum = 0; tohum < 40 && denenen < 10; tohum++) {
        final ChildMarriageResult? r = ChildMarriage.maybeMarry(
          child: kiz,
          playerAge: s.player.age,
          rng: Random(tohum),
          state: s,
          forceMarriage: true,
        );
        if (r?.spouse == null) continue;
        denenen++;
        expect(mevcut, isNot(contains(r!.spouse!.firstName)),
            reason: 'gelin/damat kayıttaki bir adı aldı: '
                '${r.spouse!.firstName}');
      }
      expect(denenen, greaterThan(0),
          reason: 'hiç evlilik üretilemedi; kurulum bozuk');
    });
  });

  // ===================================================================
  // Denetim dönemi ekranda
  // ===================================================================
  group('Denetim dönemi görünürlüğü', () {
    testWidgets('Okul / Meslek satırı denetim dönemini yazar',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 6000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final GameController controller = GameController(random: Random(9));
      addTearDown(controller.dispose);
      await tester.pumpWidget(BirOmurApp(controller: controller));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rastgele bir hayat'));
      await tester.pumpAndSettle();

      final GameState s = controller.state!;
      controller.debugSetState(
        s.copyWith(
          player: s.player.copyWith(age: 40),
          legal: const LegalState(probationUntilAge: 43),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tab_okul_meslek')));
      await tester.pumpAndSettle();

      final Finder satir = find.byKey(const Key('career_legal_row'));
      expect(satir, findsOneWidget);
      await tester.ensureVisible(satir);
      await tester.pumpAndSettle();
      // Oyuncunun baktığı yerde yazsın: bir tık daha derinde kalmasın.
      expect(find.textContaining('Denetim dönemi'), findsWidgets);
    });
  });
}
