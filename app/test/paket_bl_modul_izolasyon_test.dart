// Paket BL — **çıkarılabilir özellik** sözleşmesinin ölçümü.
//
// Faho'nun isteği: Claude'un eklediği bir özellik beğenilmezse genel
// yapı bozulmadan çıkarılabilsin. Bu dosya o sözü iki yönden ölçer:
//
//   1. Anahtar kapalıyken özelliğin **hiçbir izi** kalmıyor mu
//      (eylem listelenmiyor, motor reddediyor, kayıt değişmiyor)?
//   2. Anahtar kapalıyken oyunun geri kalanı çalışıyor mu — hayat sonuna
//      kadar gidiyor, iş/evlilik/çocuk hâlâ oluyor mu?
//
// Her ölçüm hem **kapalı** hem **açık** tarafı yazar: açık tarafta izin
// görülmesi testin boş geçmediğini kanıtlar. Oyunun sayılarına
// dokunulmaz; yalnızca modül anahtarı değişir.
// ignore_for_file: avoid_print
library;

import 'dart:io';

import 'package:bir_omur/domain/family/child_rules.dart';
import 'package:bir_omur/domain/features/feature_catalog.dart';
import 'package:bir_omur/domain/interaction/family_interactions.dart';
import 'package:bir_omur/domain/interaction/family_planning.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/pregnancy.dart';
import 'package:bir_omur/domain/interaction/intimacy.dart';
import 'package:bir_omur/ui/widgets/pregnancy_notice.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// prototypeOnly: her ölçümde oynanan hayat sayısı.
const int kHayat = 100;

/// Aile odaklı arketip: çocuk ve eş en çok burada görünür.
const PlayerArchetype kArketip = PlayerArchetype.family;

/// Çocuğa özel eylemler (BK/3).
const Set<InteractionKind> kEbeveynlikEylemleri = <InteractionKind>{
  InteractionKind.odevYardim,
  InteractionKind.harclikVer,
  InteractionKind.hobiyeYazdir,
};

/// Depo kökü: testler `app/` içinden koşar, katalog yolları depo köküne
/// göre yazılıdır.
Directory get _depoKoku {
  Directory dizin = Directory.current;
  for (int i = 0; i < 6; i++) {
    if (Directory('${dizin.path}/.git').existsSync()) return dizin;
    final Directory ust = dizin.parent;
    if (ust.path == dizin.path) break;
    dizin = ust;
  }
  return Directory.current.parent;
}

void main() {
  group('Paket BL — katalog bekçisi', () {
    test('kayıt anahtarları benzersiz ve dolu', () {
      final Set<String> anahtarlar = <String>{};
      for (final FeatureId id in FeatureId.values) {
        expect(
          anahtarlar.add(id.saveKey),
          isTrue,
          reason: 'Aynı kayıt anahtarı iki kez: ${id.saveKey}',
        );
        expect(id.saveKey, matches(RegExp(r'^[a-z0-9_]+$')));
        expect(id.title.trim(), isNotEmpty);
        expect(id.lostWhenOff.trim(), isNotEmpty);
        expect(id.paket.trim(), isNotEmpty);
      }
      print('Katalog: ${FeatureId.values.length} modül.');
    });

    test('silinebilir dosyalar gerçekten duruyor', () {
      final String kok = _depoKoku.path;
      for (final FeatureId id in FeatureId.values) {
        for (final String yol in id.removableFiles) {
          expect(
            File('$kok/$yol').existsSync(),
            isTrue,
            reason:
                '${id.saveKey} kataloğunda yazılı dosya yok: $yol. '
                'Dosya taşındıysa katalog satırını güncelle.',
          );
        }
      }
    });

    test('her modül docs/FEATURE_FLAGS.md içinde yazılı', () {
      final File belge = File('${_depoKoku.path}/docs/FEATURE_FLAGS.md');
      expect(belge.existsSync(), isTrue, reason: 'Modül belgesi yok.');
      final String metin = belge.readAsStringSync();
      for (final FeatureId id in FeatureId.values) {
        expect(
          metin.contains(id.saveKey),
          isTrue,
          reason:
              '${id.saveKey} belgede yazılı değil. Yeni modül eklendiyse '
              'docs/FEATURE_FLAGS.md tablosuna da girmeli.',
        );
      }
    });
  });

  group('Paket BL — anahtarın kaydı', () {
    test('varsayılan hâlde hiçbir sapma yazılmaz', () {
      expect(FeatureSwitches.defaults.allDefault, isTrue);
      expect(FeatureSwitches.defaults.overrides, isEmpty);
      for (final FeatureId id in FeatureId.values) {
        expect(FeatureSwitches.defaults.isOn(id), id.defaultOn);
      }
    });

    test('kapatılan modül kayda girer, geri açılınca kayıttan düşer', () {
      const FeatureId modul = FeatureId.cocukPlani;
      final FeatureSwitches kapali =
          FeatureSwitches.defaults.toggled(modul, false);
      expect(kapali.isOff(modul), isTrue);
      expect(kapali.overrides, <String, bool>{modul.saveKey: false});

      final FeatureSwitches geriAcik = kapali.toggled(modul, true);
      expect(geriAcik.allDefault, isTrue);
      expect(geriAcik.overrides, isEmpty);
    });

    test('kayıttan okuma: tanınmayan anahtar atılır, eksik alan '
        'varsayılan verir', () {
      final FeatureSwitches okunan = FeatureSwitches.fromMap(
        <String, Object?>{
          FeatureId.cocukYilOzeti.saveKey: false,
          'silinmis_bir_modul': false,
          'yanlis_tur': 'evet',
        },
      );
      expect(okunan.isOff(FeatureId.cocukYilOzeti), isTrue);
      expect(okunan.overrides.length, 1);
      expect(FeatureSwitches.fromMap(<String, Object?>{}).allDefault, isTrue);
    });

    test('allOff katalogdaki her modülü kapatır', () {
      final FeatureSwitches hepsiKapali = FeatureSwitches.allOff;
      for (final FeatureId id in FeatureId.values) {
        expect(hepsiKapali.isOff(id), isTrue, reason: id.saveKey);
      }
      expect(hepsiKapali.offFeatures.length, FeatureId.values.length);
    });
  });

  group('Paket BL — modül kapalıyken iz kalmıyor', () {
    test('gebelik bildirimi: kapalıyken hiçbir cümle kurulmuyor', () {
      int kapaliGebelik = 0;
      int acikGebelik = 0;
      int kapaliCumle = 0;
      int acikCumle = 0;

      for (int i = 0; i < kHayat; i++) {
        playBotLife(
          archetype: kArketip,
          seed: 7000 + i,
          features:
              FeatureSwitches.defaults.toggled(
            FeatureId.gebelikGorunurlugu,
            false,
          ),
          onPreAge: (GameState s) {
            if (!s.isExpecting) return;
            kapaliGebelik++;
            if (PregnancyNotice.sentence(s) != null) kapaliCumle++;
            if (PregnancyNotice.shortLabel(s) != null) kapaliCumle++;
            if (PregnancyNotice.visible(s)) kapaliCumle++;
          },
        );
        playBotLife(
          archetype: kArketip,
          seed: 7000 + i,
          onPreAge: (GameState s) {
            if (!s.isExpecting) return;
            acikGebelik++;
            if (PregnancyNotice.sentence(s) != null) acikCumle++;
          },
        );
      }

      print(
        'Gebelik modülü — kapalı: $kapaliGebelik gebelik yılı, '
        '$kapaliCumle cümle; açık: $acikGebelik gebelik yılı, '
        '$acikCumle cümle.',
      );
      // Motor aynı: gebelik iki tarafta da yaşanır.
      expect(kapaliGebelik, greaterThan(0), reason: 'Ölçüm boş geçti.');
      expect(kapaliCumle, 0, reason: 'Kapalı modül ekranda satır kurdu.');
      expect(acikCumle, greaterThan(0), reason: 'Açık modül satır kurmadı.');
    });

    test('çocuk planı: kapalıyken kayda hiç girmiyor', () {
      const FamilyPlanning plan = FamilyPlanning();
      int kapaliPartnerYili = 0;
      int kapaliPlanliYil = 0;
      int acikPlanliYil = 0;
      int kapaliKapiAcik = 0;

      for (int i = 0; i < kHayat; i++) {
        playBotLife(
          archetype: kArketip,
          seed: 8100 + i,
          features: FeatureSwitches.defaults.toggled(
            FeatureId.cocukPlani,
            false,
          ),
          onPreAge: (GameState s) {
            final Person? es = Intimacy.partnerOf(s);
            if (es == null) return;
            kapaliPartnerYili++;
            if (plan.blockReason(s, es).isEmpty) kapaliKapiAcik++;
            if (s.familyPlan != FamilyPlan.belirsiz) kapaliPlanliYil++;
            if (s.familyPlanPartnerId != null) kapaliPlanliYil++;
          },
        );
        playBotLife(
          archetype: kArketip,
          seed: 8100 + i,
          onPreAge: (GameState s) {
            if (s.familyPlan != FamilyPlan.belirsiz) acikPlanliYil++;
          },
        );
      }

      print(
        'Çocuk planı — kapalı: $kapaliPartnerYili eş/sevgili yılı, '
        'açık kalan kapı $kapaliKapiAcik, kayda giren $kapaliPlanliYil; '
        'açık: $acikPlanliYil planlı yıl.',
      );
      expect(kapaliPartnerYili, greaterThan(0), reason: 'Ölçüm boş geçti.');
      expect(kapaliKapiAcik, 0, reason: 'Kapalı modülün kapısı açık kaldı.');
      expect(kapaliPlanliYil, 0, reason: 'Kapalı modül kayda plan yazdı.');
      expect(acikPlanliYil, greaterThan(0), reason: 'Açık modül plan yazmadı.');
    });

    test('çocuğa özel eylemler ve kural: kapalıyken listelenmiyor', () {
      const FamilyInteractions etkilesim = FamilyInteractions();

      int kapaliCocukYili = 0;
      int kapaliEylem = 0;
      int kapaliKural = 0;
      int acikEylem = 0;
      int acikKural = 0;
      int kapaliRahatlama = 0;

      for (int i = 0; i < kHayat; i++) {
        playBotLife(
          archetype: kArketip,
          seed: 9200 + i,
          features: FeatureSwitches.allOff,
          onPreAge: (GameState s) {
            for (final Person cocuk in s.children) {
              if (!cocuk.isAlive) continue;
              kapaliCocukYili++;
              final List<InteractionKind> acik =
                  etkilesim.availableKinds(s, cocuk);
              kapaliEylem +=
                  acik.where(kEbeveynlikEylemleri.contains).length;
              if (acik.contains(InteractionKind.kuralKoy)) kapaliKural++;
              if (ChildRules.reliefFor(s, cocuk) != 1.0) kapaliRahatlama++;
            }
          },
        );
        playBotLife(
          archetype: kArketip,
          seed: 9200 + i,
          onPreAge: (GameState s) {
            for (final Person cocuk in s.children) {
              if (!cocuk.isAlive) continue;
              final List<InteractionKind> acik =
                  etkilesim.availableKinds(s, cocuk);
              acikEylem += acik.where(kEbeveynlikEylemleri.contains).length;
              if (acik.contains(InteractionKind.kuralKoy)) acikKural++;
            }
          },
        );
      }

      print(
        'Ebeveynlik eylemleri — kapalı: $kapaliCocukYili çocuk yılı, '
        '$kapaliEylem eylem, $kapaliKural kural satırı, '
        '$kapaliRahatlama kaymış zar; açık: $acikEylem eylem, '
        '$acikKural kural satırı.',
      );
      expect(kapaliCocukYili, greaterThan(0), reason: 'Ölçüm boş geçti.');
      expect(kapaliEylem, 0, reason: 'Kapalı modülün eylemi listelendi.');
      expect(kapaliKural, 0, reason: 'Kapalı modülün kural satırı çıktı.');
      expect(
        kapaliRahatlama,
        0,
        reason: 'Kapalı kural modülü okul sorununun zarını kaydırdı.',
      );
      expect(acikEylem, greaterThan(0), reason: 'Açık modülün eylemi yok.');
      expect(acikKural, greaterThan(0), reason: 'Açık modülün kuralı yok.');
    });

    test('çocuğun yıl özeti: kapalıyken blok kurulmuyor', () {
      int kapaliBlok = 0;
      int acikBlok = 0;

      for (int i = 0; i < kHayat; i++) {
        playBotLife(
          archetype: kArketip,
          seed: 10300 + i,
          features: FeatureSwitches.defaults.toggled(
            FeatureId.cocukYilOzeti,
            false,
          ),
          onYear: (GameState s) {
            kapaliBlok += s.lastYearSummary?.children.length ?? 0;
          },
        );
        playBotLife(
          archetype: kArketip,
          seed: 10300 + i,
          onYear: (GameState s) {
            acikBlok += s.lastYearSummary?.children.length ?? 0;
          },
        );
      }

      print(
        'Çocuk yıl özeti — kapalı: $kapaliBlok blok; açık: $acikBlok blok.',
      );
      expect(kapaliBlok, 0, reason: 'Kapalı modül yıl özetine blok koydu.');
      expect(acikBlok, greaterThan(0), reason: 'Açık modül blok kurmadı.');
    });
  });

  group('Paket BL — modül kapalıyken oyun çalışıyor', () {
    test('hepsi kapalı: $kHayat hayat sonuna kadar gidiyor', () {
      int tamamlanan = 0;
      int evlilik = 0;
      int cocuk = 0;
      int isTutan = 0;
      int toplamYas = 0;

      for (int i = 0; i < kHayat; i++) {
        final BotLifeResult sonuc = playBotLife(
          archetype: kArketip,
          seed: 11400 + i,
          features: FeatureSwitches.allOff,
        );
        tamamlanan++;
        toplamYas += sonuc.deathAge;
        if (sonuc.married) evlilik++;
        if (sonuc.childCount > 0) cocuk++;
        if (sonuc.everEmployed) isTutan++;
      }

      print(
        'Hepsi kapalı — $tamamlanan hayat, ortalama yaş '
        '${(toplamYas / tamamlanan).toStringAsFixed(1)}, '
        'evlenen $evlilik, çocuğu olan $cocuk, iş tutan $isTutan.',
      );
      expect(tamamlanan, kHayat);
      // Modüller kapalıyken oyunun çekirdeği duruyor: bu üçü de
      // modüllerden önce vardı ve yaşanmaya devam etmeli.
      expect(evlilik, greaterThan(0), reason: 'Modüller evliliği kırdı.');
      expect(cocuk, greaterThan(0), reason: 'Modüller çocuğu kırdı.');
      expect(isTutan, greaterThan(0), reason: 'Modüller kariyeri kırdı.');
    });

    test('tek tek kapalı: her modül için hayat tamamlanıyor', () {
      for (final FeatureId modul in FeatureId.values) {
        int tamamlanan = 0;
        for (int i = 0; i < 20; i++) {
          final BotLifeResult sonuc = playBotLife(
            archetype: kArketip,
            seed: 12500 + i,
            features: FeatureSwitches.defaults.toggled(modul, false),
          );
          if (sonuc.deathAge > 0) tamamlanan++;
        }
        expect(tamamlanan, 20, reason: '${modul.saveKey} kapalıyken hayat yok.');
        print('${modul.saveKey}: 20/20 hayat tamamlandı.');
      }
    });
  });
}
