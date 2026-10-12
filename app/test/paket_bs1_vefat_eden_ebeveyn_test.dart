// Paket BS/1 — diğer biyolojik ebeveynin vefatı bebeği yok saymaz.
//
// **Nasıl bulundu.** Paket BS/0'da bot davranışı düzeltilince
// `paket_bj_oyuncu_yolu_cocuk_test` düştü: dokuz gebeliğin sekizi
// doğumla kapanmıştı. Teşhiste dokuzuncu karede hamile olan kız
// arkadaşın o yıl vefat ettiği, oyunun da günlüğe "Bekleyen bebek
// dünyaya gelemedi." yazıp gebeliği kapattığı görüldü. O karede oyun
// **doğru** davranıyordu: bebeği taşıyan kişi vefat etmişti.
//
// Ama aynı satır bebeği kimin taşıdığına bakmıyordu. Kadın oyuncu
// hamileyken babanın vefatı da bebeği "doğmamış" yapıyordu. Kural
// ayrıldı (`_applyBirth`):
//
//   · Kayıt silinmişse → doğum olmaz, günlüğe yazılır.
//   · **Taşıyan taraf** vefat ettiyse → doğum olmaz, günlüğe yazılır.
//   · Bebeği **oyuncu taşıyorsa** → bebek doğar; çocuk vefat etmiş
//     ebeveynin kaydına bağlanır (uydurma ebeveyn yazılmaz, D-046/D-047)
//     ve günlüğe ebeveynin bunu göremediği yazılır.
//
// **Durum kurulmuyor, tek müdahale var.** Gebelik gerçek akıştan
// geliyor (`IntimacyEngine` ile korunmadan yakınlaşma); sonra diğer
// ebeveyn `isAlive: false` işaretleniyor. Botun kendi hayatları bu
// yolu hiç kullanmıyor (bot `haveChild()` çağırıyor, gebelik aşaması
// oluşmuyor), yani bu kareyi hayatlardan aramak mümkün değil.
//
// Bu bir prototip davranışıdır; `DECISIONS.md`'ye yazılmadı (Q-215).
library;

import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/interaction/parenthood.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/life_log.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/pregnancy.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pregnancy_fixture.dart';

void main() {
  group('Paket BS/1 — vefat eden ebeveyn ve bekleyen bebek', () {
    test('oyuncu hamileyken diğer ebeveyn vefat ederse bebek doğar', () {
      final ({GameState state, Person partner}) v =
          gebelikCifti(oyuncuCinsiyeti: Gender.kadin);
      final GameState hamile = hamileKalinca(v.state, v.partner.id);
      expect(hamile.isExpecting, isTrue, reason: 'hiç hamile kalınmadı');
      expect(hamile.pregnancy!.expecting, ExpectingParty.oyuncu,
          reason: 'kadın oyuncuda bebeği oyuncu taşır');

      final GameState olu = vefatEttiIsaretle(hamile, v.partner.id);
      final GameState sonra = LifeProgression(Random(3)).advanceOneYear(olu);

      expect(sonra.isExpecting, isFalse, reason: 'hamilelik kapanır');
      expect(sonra.children, isNotEmpty,
          reason: 'babanın vefatı bebeği doğmamış yapmaz');
      expect(sonra.children.first.age, 0);
    });

    test('doğan çocuk vefat etmiş ebeveynin kaydına bağlanır', () {
      final ({GameState state, Person partner}) v =
          gebelikCifti(oyuncuCinsiyeti: Gender.kadin);
      final GameState hamile = hamileKalinca(v.state, v.partner.id);
      final GameState sonra = LifeProgression(Random(5))
          .advanceOneYear(vefatEttiIsaretle(hamile, v.partner.id));

      final Person cocuk = sonra.children.first;
      // Soyadı: kadın oyuncuda çocuk babanın soyadını alır. Vefat etmiş
      // ebeveynin kaydı yerinde durduğu için bu bilgi uydurulmuyor.
      expect(cocuk.lastName, v.partner.lastName,
          reason: 'çocuk vefat etmiş babanın soyadını taşır');
      // Vefat etmiş ebeveyn kayıttan silinmez.
      final Person? baba = sonra.personById(v.partner.id);
      expect(baba, isNotNull);
      expect(baba!.isAlive, isFalse);
    });

    test('günlük, ebeveynin bebeği göremediğini yazar', () {
      final ({GameState state, Person partner}) v =
          gebelikCifti(oyuncuCinsiyeti: Gender.kadin);
      final GameState hamile = hamileKalinca(v.state, v.partner.id);
      final GameState sonra = LifeProgression(Random(7))
          .advanceOneYear(vefatEttiIsaretle(hamile, v.partner.id));

      expect(
        sonra.log.any((LifeLogEntry e) =>
            e.text.contains(v.partner.firstName) &&
            e.text.contains('göremedi')),
        isTrue,
        reason: 'doğum sessiz kalmaz: ebeveynin bunu göremediği yazılır',
      );
      // Eski "dünyaya gelemedi" satırı bu durumda yazılmaz.
      expect(
        sonra.log.any((LifeLogEntry e) => e.text.contains('gelemedi')),
        isFalse,
        reason: 'bebek doğdu; "dünyaya gelemedi" satırı yanlış olur',
      );
    });

    test('doğum bildirimi vefat etmiş ebeveyni bekleyen gibi anmaz', () {
      final ({GameState state, Person partner}) v =
          gebelikCifti(oyuncuCinsiyeti: Gender.kadin);
      final GameState hamile = hamileKalinca(v.state, v.partner.id);
      final GameState sonra = LifeProgression(Random(9))
          .advanceOneYear(vefatEttiIsaretle(hamile, v.partner.id));

      final Iterable<PendingNotice> dogum = sonra.notices
          .where((PendingNotice n) => n.kind == NoticeKind.dogum);
      expect(dogum, isNotEmpty, reason: 'doğum bildirimi gelir');
      expect(dogum.first.text, isNot(contains(v.partner.firstName)),
          reason: '"sen ve X bunu bekliyordunuz" vefat varken yanlış');
    });

    test('bebeği taşıyan taraf vefat ederse doğum olmaz', () {
      // Aynı madalyonun öteki yüzü: erkek oyuncuda bebeği partner
      // taşıyor; o vefat ederse bebek dünyaya gelemez.
      final ({GameState state, Person partner}) v =
          gebelikCifti(oyuncuCinsiyeti: Gender.erkek);
      final GameState hamile = hamileKalinca(v.state, v.partner.id);
      expect(hamile.pregnancy!.expecting, ExpectingParty.partner);

      final GameState sonra = LifeProgression(Random(3))
          .advanceOneYear(vefatEttiIsaretle(hamile, v.partner.id));

      expect(sonra.children, isEmpty);
      expect(sonra.isExpecting, isFalse);
      expect(
        sonra.log.any((LifeLogEntry e) => e.text.contains('gelemedi')),
        isTrue,
        reason: 'bekleyen bebek sessizce kaybolmaz',
      );
    });

    test('kayıttan düşmüş ebeveynde doğum olmaz', () {
      final ({GameState state, Person partner}) v =
          gebelikCifti(oyuncuCinsiyeti: Gender.kadin);
      final GameState hamile = hamileKalinca(v.state, v.partner.id);
      // Kaydı tamamen yok: bağlanacak bir ebeveyn kalmadı.
      final GameState silindi = hamile.copyWith(
        people: hamile.people
            .where((Person p) => p.id != v.partner.id)
            .toList(growable: false),
      );
      final GameState sonra =
          LifeProgression(Random(3)).advanceOneYear(silindi);

      expect(sonra.children, isEmpty);
      expect(sonra.isExpecting, isFalse);
      expect(
        sonra.log.any((LifeLogEntry e) => e.text.contains('gelemedi')),
        isTrue,
      );
    });

    test('izin açıkça istenmedikçe vefat etmiş ebeveyn seçilmez', () {
      // Kapı kendiliğinden açılmasın: `Parenthood` varsayılanı eskisi
      // gibi davranır, yalnızca `_applyBirth` bu izni veriyor.
      final ({GameState state, Person partner}) v =
          gebelikCifti(oyuncuCinsiyeti: Gender.kadin);
      final GameState olu = vefatEttiIsaretle(v.state, v.partner.id);

      expect(Parenthood.coParent(olu, preferredId: v.partner.id), isNull);
      expect(
        Parenthood.coParent(
          olu,
          preferredId: v.partner.id,
          allowDeceasedCoParent: true,
        ),
        isNotNull,
      );
      expect(
        const Parenthood().haveChild(
          olu,
          Random(1),
          coParentId: v.partner.id,
        ).outcome.applied,
        isFalse,
        reason: 'varsayılan yol vefat etmiş ebeveynle çocuk üretmez',
      );
    });

    test('doğan çocuk kapat-aç ile korunur', () {
      final ({GameState state, Person partner}) v =
          gebelikCifti(oyuncuCinsiyeti: Gender.kadin);
      final GameState hamile = hamileKalinca(v.state, v.partner.id);
      final GameState sonra = LifeProgression(Random(3))
          .advanceOneYear(vefatEttiIsaretle(hamile, v.partner.id));
      final GameState geri = decodeGameState(encodeGameState(sonra));

      expect(geri.children.length, sonra.children.length);
      expect(geri.children.first.id, sonra.children.first.id);
      expect(geri.isExpecting, isFalse);
    });
  });
}
