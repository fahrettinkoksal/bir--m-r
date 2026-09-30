// Paket AO §49 — 500 hedefli AİLE hayatı.
//
// **Genel 3000 hayat denetimi değil** (§17, §49): yalnızca aile odaklı
// arketiple, yalnızca aile ağının sayılarını ölçer.
//
// KURAL (§49, kelimesi kelimesine): "oranları güzelleştirmek için botu
// veya kuralları oynama. Sadece ölç." Bu dosyada tek bir oyun sabiti
// değiştirilmedi; aşağıdaki iddialar **yalnızca bozukluk** arar
// (aynı kişinin iki kez üretilmesi, kan bağıyla romantik ilişki, kopuk
// soy kaydı). Oran iddiası yoktur; oranlar rapora yazılır, Faho ile
// ChatGPT karar verir.
//
// ignore_for_file: avoid_print
library;

import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/kinship.dart';
import 'package:bir_omur/domain/models/parental_status.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// Tek bir hayattan toplanan aile ölçümleri.
class _AileOlcum {
  bool ebeveynBosandi = false;
  bool uveyEbeveyn = false;
  bool uveyKardes = false;
  bool yariKardes = false;
  bool uveyCocuk = false;
  bool kayinAile = false;
  bool evlendi = false;

  int mukerrerKimlik = 0;
  int gecersizRomantik = 0;
  int kopukSoy = 0;
  int tutarsizYasYasayan = 0;
  int tutarsizYasVefat = 0;
  int kisiSayisi = 0;
}

void main() {
  test(
    'Paket AO §49 — 500 aile hayatı: yalnızca ölçüm',
    () {
      const int hayatSayisi = 500;
      final List<_AileOlcum> olcumler = <_AileOlcum>[];

      for (int seed = 0; seed < hayatSayisi; seed++) {
        // `BotLifeResult` son durumu taşımıyor; `onYear` her yılın
        // sonunda çağrıldığı için son çağrı bize ölüm anındaki durumu
        // verir. Paylaşılan bot altyapısına alan eklemek yerine var olan
        // kancayı kullanıyoruz.
        GameState? sonDurum;
        playBotLife(
          archetype: PlayerArchetype.family,
          seed: seed,
          onYear: (GameState st) => sonDurum = st,
        );
        if (sonDurum == null) continue;
        final GameState son = sonDurum!;
        final _AileOlcum o = _AileOlcum()..kisiSayisi = son.people.length;

        o.ebeveynBosandi = son.parentalStatus == ParentalStatus.bosanmis;
        o.evlendi = son.marriageCount > 0;

        String? anneId;
        String? babaId;
        for (final Person p in son.people) {
          if (p.relation == RelationType.anne) anneId ??= p.id;
          if (p.relation == RelationType.baba) babaId ??= p.id;
        }

        final Set<String> gorulenKimlikler = <String>{};
        for (final Person p in son.people) {
          if (!gorulenKimlikler.add(p.id)) o.mukerrerKimlik++;

          switch (p.relation) {
            case RelationType.uveyAnne:
            case RelationType.uveyBaba:
              o.uveyEbeveyn = true;
            case RelationType.uveyKardes:
              o.uveyKardes = true;
            case RelationType.yariKardes:
              o.yariKardes = true;
            case RelationType.uveyCocuk:
              o.uveyCocuk = true;
            case RelationType.kayinvalide:
            case RelationType.kayinpeder:
              o.kayinAile = true;
            default:
              break;
          }

          // §16: romantik bağ hiçbir zaman yasak akrabayla kurulmamalı.
          // Ölçü `kanBagi` bayrağı değil, gerçek soy kaydı.
          const Set<RelationType> romantikBaglar = <RelationType>{
            RelationType.es,
            RelationType.eskiEs,
            RelationType.sevgili,
            RelationType.eskiSevgili,
            RelationType.flort,
          };
          if (romantikBaglar.contains(p.relation) &&
              Kinship.isRomanceForbiddenFor(
                p,
                playerId: son.player.id,
                // Oyuncunun kendi kaydında ebeveyn kimliği tutulmuyor;
                // anne ve baba birer [Person]. Çocukların soy kaydı da
                // onların kimliğine işaret ediyor, o yüzden ölçü oradan
                // okunuyor — sahte bir "player" sabiti uydurulmuyor.
                playerMotherId: anneId,
                playerFatherId: babaId,
              )) {
            o.gecersizRomantik++;
          }

          // §14-§15, §46: kayıtlı ebeveyn kimliği listede ya da oyuncu
          // olmalı. Olmayan bir kimliğe işaret eden soy kaydı kopuktur.
          for (final String ebeveynId in p.biologicalParentIds) {
            final bool bulundu = ebeveynId == son.player.id ||
                son.people.any((Person q) => q.id == ebeveynId);
            if (!bulundu) o.kopukSoy++;
          }

          // §43: çocuk biyolojik ebeveyninden büyük olamaz.
          //
          // İLK ÖLÇÜMDE 103 İHLAL ÇIKTI ve testi gevşetmek yerine sebebi
          // arandı. Sayaç ikiye ayrılınca ortaya çıktı: **hepsi vefat
          // etmiş ebeveyn**, yaşayan ebeveynde sıfır ihlal.
          //
          // Sebep bir kusur değil, kaydın anlamı: `_agePerson` yalnızca
          // yaşayanları yaşlandırır, vefat edenin yaşı öldüğü yaşta
          // **donar** ("32 yaşında vefat etti" kaydı böyle korunur).
          // Genç yaşta ölen bir ebeveynin çocuğu yıllar sonra o yaşı
          // geçer. Yani yanlış olan oyun değil, ilk yazdığım
          // değişmezdi.
          //
          // İki sayaç da raporda duruyor; vefat edenler **bilerek**
          // iddia dışında. Ölçü, yaşayan ebeveyn.
          for (final String ebeveynId in p.biologicalParentIds) {
            final Person? ebeveyn = son.personById(ebeveynId);
            if (ebeveyn == null || ebeveyn.age > p.age) continue;
            if (ebeveyn.isAlive) {
              o.tutarsizYasYasayan++;
            } else {
              o.tutarsizYasVefat++;
            }
          }
        }
        olcumler.add(o);
      }

      String yuzde(bool Function(_AileOlcum) f) {
        final int n = olcumler.where(f).length;
        return '$n/${olcumler.length} '
            '(%${(n * 100 / olcumler.length).toStringAsFixed(1)})';
      }

      int toplam(int Function(_AileOlcum) f) =>
          olcumler.fold<int>(0, (int t, _AileOlcum o) => t + f(o));

      final List<int> kisiSayilari =
          olcumler.map((_AileOlcum o) => o.kisiSayisi).toList()..sort();

      print('');
      print('=== PAKET AO §49 — 500 AİLE HAYATI (yalnızca ölçüm) ===');
      print('Arketip: aile odaklı. Tohumlar 0-499.');
      print('');
      print('Ebeveyn boşanması      : ${yuzde((o) => o.ebeveynBosandi)}');
      print('Üvey ebeveyn geldi     : ${yuzde((o) => o.uveyEbeveyn)}');
      print('Üvey kardeş oluştu     : ${yuzde((o) => o.uveyKardes)}');
      print('Yarım kardeş doğdu     : ${yuzde((o) => o.yariKardes)}');
      print('Eşin önceki çocuğu     : ${yuzde((o) => o.uveyCocuk)}');
      print('Kayın aile kuruldu     : ${yuzde((o) => o.kayinAile)}');
      print('Oyuncu evlendi         : ${yuzde((o) => o.evlendi)}');
      print('');
      print('Kişi sayısı (medyan)   : ${kisiSayilari[kisiSayilari.length ~/ 2]}');
      print('Kişi sayısı (en yüksek): ${kisiSayilari.last}');
      print('');
      print('--- bozukluk sayaçları (hepsi 0 olmalı) ---');
      print('Mükerrer kimlik        : ${toplam((o) => o.mukerrerKimlik)}');
      print('Geçersiz romantik bağ  : ${toplam((o) => o.gecersizRomantik)}');
      print('Kopuk soy kaydı        : ${toplam((o) => o.kopukSoy)}');
      print('Tutarsız yaş — yaşayan : ${toplam((o) => o.tutarsizYasYasayan)}');
      print('Tutarsız yaş — vefat   : ${toplam((o) => o.tutarsizYasVefat)}');
      print('');

      // Yalnızca bozukluk iddiaları. Oran iddiası **yok** (§49).
      expect(toplam((o) => o.mukerrerKimlik), 0,
          reason: '§37: aynı kimlik iki kez üretilmiş.');
      expect(toplam((o) => o.gecersizRomantik), 0,
          reason: '§16: kan bağı olan kişiyle romantik bağ kurulmuş.');
      expect(toplam((o) => o.kopukSoy), 0,
          reason: '§14: kayıtta olmayan bir kimliğe işaret eden soy bağı.');
      expect(toplam((o) => o.tutarsizYasYasayan), 0,
          reason: '§43: çocuk YAŞAYAN biyolojik ebeveyninden büyük.');
    },
    // 500 tam hayat: uzun sürer.
    timeout: const Timeout(Duration(minutes: 25)),
  );
}
