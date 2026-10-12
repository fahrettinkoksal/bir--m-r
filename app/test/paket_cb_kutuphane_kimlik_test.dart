/// Paket CB — kütüphanede kimlik çakışması ve ulaşılamayan basamak.
///
/// **Ölçülen sorun (1): üç kitap iki kez tanımlı.** Q-110'da kütüphane
/// 8'den 23 satıra çıkarılırken üç kimlik ve üç ad yeniden kullanıldı:
/// `gokyuzu_defteri`, `sayilarin_dili`, `uzun_kis`. Katalog 22 satır
/// ama **19 tekil kimlik** taşıyordu. İkisi aynı yaş penceresinde
/// rafta duruyordu (`sayilarin_dili` 16+, `uzun_kis` 18+): oyuncu aynı
/// adı iki kez görüyor, birini bitirince öteki de "Bitirdin." oluyordu,
/// çünkü ilerleme kaydı kimliğe bağlı (`state.bookProgress(book.id)`).
/// Üçüncüsünde pencereler kesişmiyordu ama `bookById` yanlış satırı
/// döndürüyor ve çocukluğunda o kitabı bitiren oyuncu yetişkin sürümünü
/// hiç açamıyordu.
///
/// **Ölçülen sorun (2): merdivenin tepesi ulaşılamaz.** "Okumak"
/// hobisini yalnızca **bitirilen** kitaplar besliyor ve bitmiş kitap
/// yeniden okunamıyor; yani bir hayatın tavanı kütüphanedeki **tekil**
/// kitap sayısıdır. "Usta" basamağı 20 deneyim istiyor, kütüphanede 19
/// tekil kitap vardı: tepe hiçbir hayatta ulaşılamıyordu. Eski bekçi
/// `kBookCatalog.length` (22) kullandığı için bunu göremiyordu.
///
/// Bu dosya tavanı **tekil kimlik** üzerinden sayar; çakışma geri
/// gelirse ya da raf merdivenin altına düşerse kırmızı yanar.
library;

import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/hobby_catalog.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/domain/activities/activity_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/hobby/hobby_tracker.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/hobby_progress.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/state/game_scope.dart';
import 'package:bir_omur/ui/screens/sections/activity_pages.dart';
import 'package:bir_omur/ui/theme/bir_omur_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

const ActivityEngine _aktivite = ActivityEngine();

GameState _hayat(int tohum, {required int yas}) {
  final GameState state =
      LifeGenerator.seeded(tohum).generate(mode: StartMode.tamamenRastgele);
  return state.copyWith(player: state.player.copyWith(age: yas));
}

/// Bir hayatın okuma hobisinde ulaşabileceği **en yüksek** deneyim.
///
/// Bitmiş kitap yeniden okunamadığı için tavan, ömür boyunca yaş
/// penceresine giren **tekil** kitap sayısıdır.
int _okumaTavani({int olumYasi = 90}) {
  final Set<String> ulasilan = <String>{};
  for (final BookInfo b in kBookCatalog) {
    if (b.minAge <= olumYasi) ulasilan.add(b.id);
  }
  return ulasilan.length;
}

void main() {
  group('Paket CB — kütüphane kimliği', () {
    test('her kitabın kimliği tekil', () {
      final Map<String, int> sayac = <String, int>{};
      for (final BookInfo b in kBookCatalog) {
        sayac[b.id] = (sayac[b.id] ?? 0) + 1;
      }
      final List<String> cakisan = sayac.entries
          .where((MapEntry<String, int> e) => e.value > 1)
          .map((MapEntry<String, int> e) => '${e.key} (${e.value} kez)')
          .toList(growable: false);
      expect(
        cakisan,
        isEmpty,
        reason: 'Aynı kimlik iki kitapta: ${cakisan.join(", ")}. '
            'İlerleme kaydı kimliğe bağlı; biri bitince öteki de '
            'bitmiş görünür.',
      );
    });

    test('aynı ad iki kez rafta değil', () {
      final Map<String, List<String>> adlar = <String, List<String>>{};
      for (final BookInfo b in kBookCatalog) {
        adlar.putIfAbsent(b.title, () => <String>[]).add(b.id);
      }
      final List<String> cakisan = adlar.entries
          .where((MapEntry<String, List<String>> e) => e.value.length > 1)
          .map((MapEntry<String, List<String>> e) =>
              '"${e.key}" -> ${e.value.join(", ")}')
          .toList(growable: false);
      expect(
        cakisan,
        isEmpty,
        reason: 'Oyuncu rafta aynı adı iki kez görüyor: '
            '${cakisan.join(" | ")}',
      );
    });

    test('bookById her satırı kendisine çözüyor', () {
      for (final BookInfo b in kBookCatalog) {
        final BookInfo? cozulen = bookById(b.id);
        expect(cozulen, isNotNull, reason: b.id);
        expect(
          cozulen!.title,
          b.title,
          reason: '${b.id}: kayıt "${b.title}" kitabına ait ama '
              'bookById "${cozulen.title}" döndürüyor',
        );
        expect(cozulen.pages, b.pages, reason: b.id);
        expect(cozulen.author, b.author, reason: b.id);
      }
    });

    test('hiçbir yaşta aynı kimlikten iki satır görünmüyor', () {
      for (int yas = 0; yas <= 100; yas++) {
        final List<BookInfo> raf = booksFor(yas);
        final Set<String> tekil = raf.map((BookInfo b) => b.id).toSet();
        expect(
          tekil.length,
          raf.length,
          reason: '$yas yaşında raf ${raf.length} satır ama '
              '${tekil.length} tekil kitap',
        );
      }
    });
  });

  group('Paket CB — okuma merdiveni ulaşılabilir', () {
    test('tekil kitap sayısı merdivenin tepesine yetiyor', () {
      final int tavan = _okumaTavani();
      final int tepe = HobbyKind.okuma.stages.last.experience;
      expect(
        tavan,
        greaterThanOrEqualTo(tepe),
        reason: 'Kütüphanede $tavan tekil kitap var, "'
            '${HobbyKind.okuma.stages.last.label}" basamağı $tepe '
            'deneyim istiyor. Tepe hiçbir hayatta ulaşılamaz.',
      );
    });

    test('yetişkin olarak başlayan da bir basamak ilerleyebiliyor', () {
      // 20 yaşında okumaya başlayan oyuncunun önünde kaç tekil kitap
      // kalıyor? Çocuk kitapları kapandığı için bu sayı tavandan düşük.
      final Set<String> yetiskinRafi = <String>{
        for (final BookInfo b in kBookCatalog)
          if (b.maxAge >= 20) b.id,
      };
      final int basamak = HobbyKind.okuma.stageFor(yetiskinRafi.length);
      expect(
        basamak,
        greaterThanOrEqualTo(3),
        reason: '20 yaşında başlayan oyuncu ${yetiskinRafi.length} kitap '
            'bitirebiliyor, bu da ancak $basamak. basamak. Okumak '
            'yetişkin için ölü bir hobi olur.',
      );
    });

    test('yazarlık mesleğinin istediği basamak ulaşılabilir', () {
      final JobType yazar =
          kJobCatalog.firstWhere((JobType j) => j.id == 'yazar');
      expect(yazar.hobbyId, 'okuma');
      final int tavan = _okumaTavani();
      expect(
        yazar.minHobbyStage,
        lessThanOrEqualTo(HobbyKind.okuma.stageFor(tavan)),
        reason: 'Yazarlık ${yazar.minHobbyStage}. basamak istiyor ama '
            '$tavan kitapla ancak ${HobbyKind.okuma.stageFor(tavan)}. '
            'basamağa çıkılıyor',
      );
    });
  });

  group('Paket CB — raf gerçekten besliyor', () {
    test('raftaki her kitabı bitirmek hobiyi satır sayısı kadar besliyor',
        () {
      // Çakışma varken bu test kırmızıdır: aynı kimliği taşıyan ikinci
      // kitap "zaten bitti" diye reddedilir ve hobiye hiç yazılmaz.
      GameState state = _hayat(7, yas: 25);
      final List<BookInfo> raf = _aktivite.availableBooks(state);
      expect(raf, isNotEmpty);

      int bitirilen = 0;
      for (final BookInfo kitap in raf) {
        state = _aktivite.openBook(state, kitap).state;
        for (int sayfa = 0; sayfa < kitap.pages; sayfa++) {
          state = _aktivite.turnPage(state, kitap).state;
        }
        final bool bitti = state.bookProgress(kitap.id)?.finished ?? false;
        if (bitti) bitirilen++;
      }

      expect(bitirilen, raf.length, reason: 'Raftaki her kitap bitmeli');
      final HobbyProgress? okuma =
          HobbyTracker.progressOf(state, HobbyKind.okuma);
      expect(okuma, isNotNull, reason: 'Okuma hobisi hiç açılmadı');
      expect(
        okuma!.experience,
        raf.length,
        reason: '${raf.length} kitap bitirildi ama hobiye '
            '${okuma.experience} deneyim yazıldı',
      );
    });
  });

  group('Paket CB — okuma hunisi gerçekten akıyor', () {
    // Ölçüm (120 hayat × 2 bağımsız tohum bloğu), bot okumaya başlamadan
    // önce / sonra:
    //   kitap bitiren hayat     3 / 6   ->  36 / 42
    //   hobi_okuma_gecesi       0 / 0   ->  33 / 35
    //   hobi_sevgili_kitapci    1 / 1   ->  34 / 38
    //   yazar mesleğine giren   0 / 0   ->   2 / 5
    //
    // Eşikler ölçülen değerin çok altında: bu test dağılımı değil
    // **yolun kapanmadığını** korur.
    test('okuyan bot merdiveni tırmanıyor ve iki olay görünüyor', () {
      const int n = 90;
      int okuyan = 0;
      int yazarlikBasamagi = 0;
      int geceOlayi = 0;
      int kitapciOlayi = 0;
      final JobType yazar =
          kJobCatalog.firstWhere((JobType j) => j.id == 'yazar');

      for (int i = 0; i < n; i++) {
        int enYuksekBasamak = -1;
        final BotLifeResult r = playBotLife(
          archetype:
              PlayerArchetype.values[i % PlayerArchetype.values.length],
          seed: 4300 + i,
          onYear: (GameState s) {
            final HobbyProgress? o =
                HobbyTracker.progressOf(s, HobbyKind.okuma);
            if (o != null && o.stage > enYuksekBasamak) {
              enYuksekBasamak = o.stage;
            }
          },
        );
        if (r.booksFinished.isNotEmpty) okuyan++;
        if (enYuksekBasamak >= yazar.minHobbyStage) yazarlikBasamagi++;
        if (r.seenEvents.contains('hobi_okuma_gecesi')) geceOlayi++;
        if (r.seenEvents.contains('hobi_sevgili_kitapci')) kitapciOlayi++;
      }

      expect(
        okuyan,
        greaterThanOrEqualTo(12),
        reason: '$n hayatta yalnızca $okuyan tanesi kitap bitirdi; '
            'kütüphane yolu tıkandı',
      );
      expect(
        yazarlikBasamagi,
        greaterThanOrEqualTo(8),
        reason: 'Yazarlığın istediği ${yazar.minHobbyStage}. basamağa '
            'çıkan hayat: $yazarlikBasamagi. Meslek ilan panosunda '
            'görünüp hiç açılmıyor demektir.',
      );
      expect(
        geceOlayi,
        greaterThanOrEqualTo(6),
        reason: 'hobi_okuma_gecesi $n hayatta $geceOlayi kez göründü',
      );
      expect(
        kitapciOlayi,
        greaterThanOrEqualTo(6),
        reason: 'hobi_sevgili_kitapci $n hayatta $kitapciOlayi kez göründü',
      );
    }, timeout: const Timeout(Duration(minutes: 10)));
  });

  group('Paket CB — kütüphane ekranı', () {
    /// Tek bir bölüm sayfasını kendi başına ekrana getirir
    /// (`missing_screens_test.dart`'taki desenin aynısı).
    Future<void> ekranaGetir(WidgetTester tester, GameState state) async {
      // Raf 45 yaşında 29 kart + 9 grup başlığı: liste tembel kurulduğu
      // için görüntü alanı yüksek olmalı, yoksa alttaki gruplar hiç
      // oluşmaz ve test yanlış yere kırmızı yanar.
      tester.view.physicalSize = const Size(1000, 9000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final GameController controller = GameController(random: Random(7));
      addTearDown(controller.dispose);
      controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 7);
      controller.debugSetState(state);
      await tester.pumpWidget(
        GameScope(
          controller: controller,
          child: MaterialApp(
            theme: BirOmurTheme.light(),
            home: Scaffold(body: LibraryPage(onBack: () {})),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('raf türüne göre gruplanıyor, aynı ad iki kez çıkmıyor',
        (WidgetTester tester) async {
      final GameState state = _hayat(31, yas: 45);
      await ekranaGetir(tester, state);

      final List<BookInfo> raf = booksFor(45);
      expect(raf.length, greaterThan(20), reason: '45 yaşında raf dolu olmalı');

      // Rafta bulunan her tür için bir grup başlığı var.
      final Set<BookKind> turler = raf.map((BookInfo b) => b.kind).toSet();
      for (final BookKind tur in turler) {
        expect(
          find.text(tur.label),
          findsOneWidget,
          reason: '${tur.label} grup başlığı yok ya da iki kez var',
        );
      }

      // Hiçbir kitap adı ekranda iki kez görünmüyor.
      for (final BookInfo kitap in raf) {
        expect(
          find.text(kitap.title),
          findsOneWidget,
          reason: '"${kitap.title}" ekranda bir kez görünmeli',
        );
      }
    });

    testWidgets('bitirilen kitap "Bitirdiklerin" bölümüne iniyor',
        (WidgetTester tester) async {
      GameState state = _hayat(32, yas: 45);
      final BookInfo kitap = _aktivite.availableBooks(state).first;
      state = _aktivite.openBook(state, kitap).state;
      for (int sayfa = 0; sayfa < kitap.pages; sayfa++) {
        state = _aktivite.turnPage(state, kitap).state;
      }
      expect(state.bookProgress(kitap.id)?.finished, isTrue);

      await ekranaGetir(tester, state);
      expect(find.text('Bitirdiklerin'), findsOneWidget);
      expect(find.textContaining('tanesini bitirdin'), findsOneWidget);
      // Bitmiş kitap artık kendi tür grubunda değil.
      expect(find.text(kitap.title), findsOneWidget);
    });
  });
}
