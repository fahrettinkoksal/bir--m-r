// Paket AP §2-§4, §51 — gizli dram eğilimi, yıllık karar sınırı ve
// çok yıllı aile meselesi kaydı.
//
// Üç kuralı da ürünün kendi API'sinden geçiriyor; hiçbirini test içinde
// yeniden hesaplamıyor.
library;

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/models/family_drama.dart';
import 'package:bir_omur/domain/models/family_issue.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'paket_ao_aile_v2_test.dart' show aileliHayat;

void main() {
  group('§2 — gizli aile dram eğilimi', () {
    test('aynı tohum her zaman aynı profili verir', () {
      for (final int seed in <int>[0, 1, 7, 99, 100000, -5]) {
        final FamilyDramaProfile a = FamilyDramaProfile.forSeed(seed);
        final FamilyDramaProfile b = FamilyDramaProfile.forSeed(seed);
        expect(a.frequency, b.frequency);
        expect(a.cocukAgirligi, b.cocukAgirligi);
        expect(a.kardesAgirligi, b.kardesAgirligi);
        expect(a.kayinAgirligi, b.kayinAgirligi);
        expect(a.bakimAgirligi, b.bakimAgirligi);
      }
    });

    test('profil kayda yazılmaz; kayıttan dönünce aynı kalır', () {
      final GameState once = aileliHayat(seed: 31, age: 40);
      final GameState sonra = decodeGameState(encodeGameState(once));
      expect(sonra.familyDrama.frequency, once.familyDrama.frequency,
          reason: '§2: profil tohumdan türetilir, yeni save alanı yok.');
      expect(sonra.familyDrama.cocukAgirligi, once.familyDrama.cocukAgirligi);
    });

    test('bütün değerler bandın içinde kalır', () {
      for (int seed = 0; seed < 400; seed++) {
        final FamilyDramaProfile p = FamilyDramaProfile.forSeed(seed);
        expect(p.frequency,
            inInclusiveRange(
              FamilyDramaProfile.prototypeOnlyMinFrequency,
              FamilyDramaProfile.prototypeOnlyMaxFrequency,
            ),
            reason: 'tohum $seed');
        for (final FamilyDramaArea alan in FamilyDramaArea.values) {
          expect(p.weightFor(alan),
              inInclusiveRange(
                FamilyDramaProfile.prototypeOnlyMinWeight,
                FamilyDramaProfile.prototypeOnlyMaxWeight,
              ),
              reason: 'tohum $seed / ${alan.name}');
        }
      }
    });

    test('hayatlar birbirinin aynısı olmuyor: sakin de hareketli de var',
        () {
      int sakin = 0;
      int hareketli = 0;
      for (int seed = 0; seed < 400; seed++) {
        final double f = FamilyDramaProfile.forSeed(seed).frequency;
        if (f < 0.8) sakin++;
        if (f > 1.2) hareketli++;
      }
      // "Her hayat Türk dizisi olmasın" ama "hiçbir hayatta bir şey
      // olmasın" da değil: iki uç da görülmeli.
      expect(sakin, greaterThan(20), reason: 'Sakin aile hiç çıkmıyor.');
      expect(hareketli, greaterThan(20),
          reason: 'Hareketli aile hiç çıkmıyor.');
    });

    test('profil yalnızca sıklığı ölçekler ve tavanı aşamaz', () {
      // En hareketli profili bul; onunla bile tavan korunuyor olmalı.
      FamilyDramaProfile enYuksek = FamilyDramaProfile.forSeed(0);
      for (int seed = 1; seed < 400; seed++) {
        final FamilyDramaProfile p = FamilyDramaProfile.forSeed(seed);
        if (p.frequency * p.cocukAgirligi >
            enYuksek.frequency * enYuksek.cocukAgirligi) {
          enYuksek = p;
        }
      }
      expect(
        enYuksek.scale(0.9, FamilyDramaArea.cocuk),
        lessThanOrEqualTo(0.9),
        reason: 'Profil bir olayı "her yıl olur" hâline getirmemeli.',
      );
      // Sıfır ihtimal profille de sıfır kalır: profil olay uydurmaz.
      expect(enYuksek.scale(0, FamilyDramaArea.cocuk), 0);
    });
  });

  group('§3 — yılda en fazla bir büyük aile kararı', () {
    test('ilk mesele açılır, aynı yıl ikincisi açılmaz', () {
      final GameState taban = aileliHayat(seed: 5, age: 45);
      expect(taban.canOpenFamilyDecision, isTrue);

      final GameState birinci = taban.openFamilyIssue(
        kind: FamilyIssueKind.cocukPara,
        personId: 'cocuk-a',
      );
      expect(birinci.familyIssues, hasLength(1));
      expect(birinci.canOpenFamilyDecision, isFalse,
          reason: '§3: bir yılda bir büyük aile kararı.');

      // Beş çocuklu oyuncu aynı yıl beş kriz yaşamaz.
      final GameState ikinci = birinci.openFamilyIssue(
        kind: FamilyIssueKind.kardesPara,
        personId: 'kardes-b',
      );
      expect(ikinci.familyIssues, hasLength(1),
          reason: 'İkinci mesele aynı yıl açılmamalı.');
    });

    test('yıl geçince yeni mesele açılabilir', () {
      final GameState taban = aileliHayat(seed: 5, age: 45);
      final GameState birinci = taban.openFamilyIssue(
        kind: FamilyIssueKind.cocukPara,
        personId: 'cocuk-a',
      );
      final GameState yilSonra = birinci.copyWith(
        player: birinci.player.copyWith(age: 46),
      );
      expect(yilSonra.canOpenFamilyDecision, isTrue);
      final GameState ikinci = yilSonra.openFamilyIssue(
        kind: FamilyIssueKind.kardesPara,
        personId: 'kardes-b',
      );
      expect(ikinci.familyIssues, hasLength(2));
    });

    test('süren mesele o yıl konuşulduysa yeni karar açılmaz', () {
      final GameState taban = aileliHayat(seed: 5, age: 45);
      final GameState acik = taban.openFamilyIssue(
        kind: FamilyIssueKind.bakim,
        personId: 'anne-1',
      );
      final GameState yilSonra = acik.copyWith(
        player: acik.player.copyWith(age: 46),
      );
      // Mesele bu yıl yine oyuncunun karşısına çıktı.
      final GameState konusuldu = yilSonra.updateFamilyIssue(
        acik.familyIssues.first.id,
        lastEventAge: 46,
        stage: 1,
      );
      expect(konusuldu.canOpenFamilyDecision, isFalse,
          reason: 'Aynı yıl ikinci bir aile konusu daha açılmamalı.');
    });
  });

  group('§4 — çok yıllı mesele kaydı', () {
    test('aynı mesele ikinci kez açılmıyor', () {
      GameState s = aileliHayat(seed: 8, age: 50);
      s = s.openFamilyIssue(
        kind: FamilyIssueKind.cocukOkul,
        personId: 'cocuk-a',
      );
      s = s.copyWith(player: s.player.copyWith(age: 51));
      s = s.openFamilyIssue(
        kind: FamilyIssueKind.cocukOkul,
        personId: 'cocuk-a',
      );
      expect(s.familyIssues, hasLength(1),
          reason: 'Açık mesele varken aynısı tekrar açılmaz.');
      // Farklı kişinin aynı türdeki meselesi ayrı bir mesele.
      s = s.openFamilyIssue(
        kind: FamilyIssueKind.cocukOkul,
        personId: 'cocuk-b',
      );
      expect(s.familyIssues, hasLength(2));
    });

    test('mesele kapanınca kayıttan silinmez (§51)', () {
      GameState s = aileliHayat(seed: 8, age: 50);
      s = s.openFamilyIssue(
        kind: FamilyIssueKind.cocukEvlilik,
        personId: 'cocuk-a',
      );
      final String id = s.familyIssues.first.id;
      s = s.copyWith(player: s.player.copyWith(age: 53));
      s = s.updateFamilyIssue(
        id,
        status: FamilyIssueStatus.cozuldu,
        resolvedAtAge: 53,
      );
      expect(s.familyIssues, hasLength(1),
          reason: '§51: "üç yıl önce ne olmuştu" cevaplanabilmeli.');
      expect(s.openFamilyIssues, isEmpty);
      expect(s.familyIssues.first.yearsOpen(60), 3,
          reason: 'Kapandığı yıl esas alınır, bugünkü yaş değil.');
      // Kapandıktan sonra aynı mesele yeniden açılabilir.
      s = s.copyWith(player: s.player.copyWith(age: 54));
      s = s.openFamilyIssue(
        kind: FamilyIssueKind.cocukEvlilik,
        personId: 'cocuk-a',
      );
      expect(s.familyIssues, hasLength(2));
    });

    test('bilinmeyen kimlikle güncelleme durumu bozmaz', () {
      final GameState s = aileliHayat(seed: 8, age: 50).openFamilyIssue(
        kind: FamilyIssueKind.miras,
        personId: 'kardes-b',
      );
      final GameState sonra = s.updateFamilyIssue('olmayan-kimlik',
          status: FamilyIssueStatus.cozuldu);
      expect(sonra.familyIssues.first.status, FamilyIssueStatus.acik);
    });

    test('kayıt turu: mesele aynen geri geliyor', () {
      GameState s = aileliHayat(seed: 12, age: 60);
      s = s.openFamilyIssue(
        kind: FamilyIssueKind.kayinGerginlik,
        personId: 'cocugunesi-cocuk-a-1',
      );
      s = s.updateFamilyIssue(s.familyIssues.first.id, stage: 2);

      final GameState donen = decodeGameState(encodeGameState(s));
      expect(donen.familyIssues, hasLength(1));
      final FamilyIssue m = donen.familyIssues.first;
      final FamilyIssue o = s.familyIssues.first;
      expect(m.id, o.id);
      expect(m.kind, o.kind);
      expect(m.personId, o.personId);
      expect(m.openedAtAge, o.openedAtAge);
      expect(m.lastEventAge, o.lastEventAge);
      expect(m.status, o.status);
      expect(m.stage, 2);

      // Çift uygulama: aynı kayıt iki kez okunursa mesele çoğalmasın.
      final GameState ikinciKez = decodeGameState(encodeGameState(donen));
      expect(ikinciKez.familyIssues, hasLength(1));
    });

    test('eski kayıt (alan hiç yok) bozulmadan açılıyor', () {
      final GameState s = aileliHayat(seed: 12, age: 60);
      final Map<String, Object?> json = encodeGameState(s);
      json.remove('familyIssues');
      final GameState donen = decodeGameState(json);
      expect(donen.familyIssues, isEmpty);
      // Profil yine var: tohumdan geliyor.
      expect(donen.familyDrama.frequency, s.familyDrama.frequency);
    });

    test('tanınmayan mesele türü yalnızca o meseleyi düşürür', () {
      GameState s = aileliHayat(seed: 12, age: 60);
      s = s.openFamilyIssue(
        kind: FamilyIssueKind.bakim,
        personId: 'anne-1',
      );
      final Map<String, Object?> json = encodeGameState(s);
      final List<Object?> liste =
          (json['familyIssues']! as List<Object?>).toList();
      liste.add(<String, Object?>{
        'id': 'gelecekten-gelen',
        'kind': 'henuzOlmayanTur',
        'personId': 'anne-1',
        'openedAtAge': 59,
        'lastEventAge': 59,
        'status': 'acik',
        'stage': 0,
      });
      json['familyIssues'] = liste;

      final GameState donen = decodeGameState(json);
      expect(donen.familyIssues, hasLength(1),
          reason: 'Tanınmayan tür düşer, kayıt açılır.');
      expect(donen.familyIssues.first.kind, FamilyIssueKind.bakim);
      // Hayatın kalanı yerinde.
      expect(donen.people.length, s.people.length);
    });

    test('kayıt şişmiyor: sınır aşılsa bile açık meseleler korunuyor', () {
      GameState s = aileliHayat(seed: 20, age: 30);
      // Sınırdan fazla mesele aç: her biri ayrı yılda ve ayrı kişide.
      for (int i = 0; i < GameState.prototypeOnlyMaxIssues + 8; i++) {
        s = s.copyWith(player: s.player.copyWith(age: 30 + i));
        s = s.openFamilyIssue(
          kind: FamilyIssueKind.cocukPara,
          personId: 'cocuk-$i',
        );
        // Yarısını kapat ki hem açık hem kapalı mesele olsun.
        if (i.isEven) {
          s = s.updateFamilyIssue(
            s.familyIssues.last.id,
            status: FamilyIssueStatus.cozuldu,
            resolvedAtAge: 30 + i,
          );
        }
      }
      expect(s.familyIssues.length,
          lessThanOrEqualTo(GameState.prototypeOnlyMaxIssues));
      // Düşenler en eski **kapalı** meseleler olmalı; açık mesele
      // kaybolmamalı.
      final int acikSayisi = s.openFamilyIssues.length;
      expect(acikSayisi, greaterThan(0));
      for (final FamilyIssue m in s.openFamilyIssues) {
        expect(m.status, FamilyIssueStatus.acik);
      }
    });
  });
}
