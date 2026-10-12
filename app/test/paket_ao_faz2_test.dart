// Paket AO — ikinci faz: erişilebilirlik, kendi hayatlar ve ekran.
//
// Bu dosyanın derdi tek bir cümle: **hiçbir kişi yalnızca hikâye
// metninde var olmasın, hiçbir motor da yalnızca dosyada var olmasın.**
// Paket AO/1 ve AO/2 gerçek kayıtlar üretti ama üçü oyuncuya hiç
// ulaşmıyordu; buradaki testler o kapıların gerçekten açık olduğunu
// ürünün kendi API'lerinden doğrular.
//
// Genel 3000 hayat denetimi **yok** (§17, §49).
library;

import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/event_pool_family_gathering.dart';
import 'package:bir_omur/domain/generation/child_marriage.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/generation/parent_divorce.dart';
import 'package:bir_omur/domain/interaction/elder_care.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/parental_status.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'paket_ao_aile_v2_test.dart' show aileliHayat, kisi, bosandir;

/// Verilen bağla, verilen yaşta, hanede yaşayan bir kişi ekler.
GameState kisiEkle(
  GameState s, {
  required String id,
  required RelationType relation,
  required int age,
  Gender gender = Gender.kadin,
  bool hanede = true,
  WealthTier? wealth,
  String? motherId,
  String? fatherId,
}) {
  // Oyunun kendi değişmezi: 6-17 yaş öğrenci, 6 yaş altı çocuk.
  final EmploymentStatus durum = age < 6
      ? EmploymentStatus.cocuk
      : age < 18
          ? EmploymentStatus.ogrenci
          : EmploymentStatus.issiz;
  return s.copyWith(
    people: List<Person>.unmodifiable(<Person>[
      ...s.people,
      Person(
        id: id,
        firstName: 'Deniz',
        lastName: s.player.lastName,
        gender: gender,
        relation: relation,
        age: age,
        isAlive: true,
        inPlayerHousehold: hanede,
        employment: durum,
        wealth: wealth,
        bond: 40,
        city: s.player.currentCity,
        motherId: motherId,
        fatherId: fatherId,
      ),
    ]),
  );
}

void main() {
  group('§28 — yeni bağlar da kendi hayatını yaşar', () {
    test('üvey, yarım kardeş ve üvey çocuk yıl geçince gelişim kaydı alır',
        () {
      GameState s = aileliHayat(seed: 11, age: 14);
      s = kisiEkle(s, id: 'uveyk-1', relation: RelationType.uveyKardes, age: 9);
      s = kisiEkle(s, id: 'yarik-1', relation: RelationType.yariKardes, age: 7);
      s = kisiEkle(s, id: 'uveyc-1', relation: RelationType.uveyCocuk, age: 8);

      // Paket AO/1'de bu üçü yalnızca yaşlanıyordu: okula başlamıyor, iş
      // bulmuyor, hiçbir dönüm noktası yaşamıyorlardı.
      for (final String id in <String>['uveyk-1', 'yarik-1', 'uveyc-1']) {
        expect(s.personById(id)!.development, isNull,
            reason: 'Kurulum: henüz gelişim kaydı olmamalı.');
      }

      final GameState sonra = LifeProgression(Random(3)).advanceOneYear(s);

      for (final String id in <String>['uveyk-1', 'yarik-1', 'uveyc-1']) {
        expect(
          sonra.personById(id)!.development,
          isNotNull,
          reason: '$id kendi hayatını yaşamıyor: gelişim kaydı açılmadı.',
        );
      }
    });

    test('yarım kardeş yetişkin olunca kendi evliliğini yapabilir', () {
      // Kural motorun kendisinden okunuyor: uydurma bir evlilik kurulmuyor.
      GameState s = aileliHayat(seed: 5, age: 40);
      s = kisiEkle(s, id: 'yarik-2', relation: RelationType.yariKardes, age: 30);
      // Gelişim kaydı olmadan evlenemez; bir yıl geçirip kaydı açtırıyoruz.
      s = LifeProgression(Random(9)).advanceOneYear(s);
      final Person kardes = s.personById('yarik-2')!;
      expect(kardes.development, isNotNull);

      ChildMarriageResult? sonuc;
      for (int seed = 0; seed < 300 && sonuc == null; seed++) {
        sonuc = ChildMarriage.maybeMarry(
          child: kardes,
          playerAge: s.player.age,
          rng: Random(seed),
          relation: RelationType.yariKardes,
        );
      }
      expect(sonuc, isNotNull,
          reason: '300 denemede yarım kardeş hiç evlenmedi: kapı kapalı.');
      expect(sonuc!.person.development!.isMarried, isTrue);
      // Bildirim kimliği bağın kendi adından türer; çocuk/kardeş önekleri
      // bozulmadan yeni bağ eklenebilsin diye.
      expect(sonuc.notice.id, startsWith('yariKardes-evlilik-'));
    });

    test('öz kardeş ve çocuk bildirimlerinin eski kimliği bozulmadı', () {
      // Bu bir gerileme testi: §28 için başlık üretimi değişti, eski iki
      // bağın kimlik öneki ve başlığı **aynen** kalmalı.
      GameState s = aileliHayat(seed: 5, age: 40);
      s = kisiEkle(s, id: 'kardes-x', relation: RelationType.kardes, age: 30);
      s = LifeProgression(Random(9)).advanceOneYear(s);
      final Person kardes = s.personById('kardes-x')!;

      ChildMarriageResult? sonuc;
      for (int seed = 0; seed < 300 && sonuc == null; seed++) {
        sonuc = ChildMarriage.maybeMarry(
          child: kardes,
          playerAge: s.player.age,
          rng: Random(seed),
          relation: RelationType.kardes,
        );
      }
      expect(sonuc, isNotNull);
      expect(sonuc!.notice.id, startsWith('kardes-evlilik-'));
    });

    test('yeğen kapısı: yarım kardeşten açılır, üvey kardeşten açılmaz', () {
      // İKİ YÖNLÜ test. Tek yönlü yazmak tuzaktı: üretilen yeğenin
      // kimliği `yegen-1` biçiminde, ebeveynin kimliğini **taşımıyor**;
      // "kimliğinde uveyKardes geçen yeğen yok" demek her koşulda doğru
      // olurdu ve test hiçbir şey kanıtlamazdı. O yüzden ölçü, yeğen
      // sayısının kendisi.
      int yegenSayisi(RelationType bag, int seed) {
        GameState akan = aileliHayat(seed: 21, age: 45);
        akan = kisiEkle(akan, id: 'kardes-t', relation: bag, age: 34);
        for (int i = 0; i < 10; i++) {
          // `advanceOneYear` ekranda çözülmemiş olay varken **hiçbir şey
          // yapmadan** döner (olaylar üst üste binmesin diye). İlk
          // yazımda bu unutulmuştu: döngü on kez çağrılıyor ama yalnızca
          // bir yıl ilerliyordu, sonra da "yeğen doğmadı" diye ürünü
          // suçluyordum. Olay burada tüketiliyor.
          akan = akan.copyWith(pendingEvent: null);
          akan = LifeProgression(Random(seed * 100 + i)).advanceOneYear(akan);
        }
        return akan.people
            .where((Person p) => p.relation == RelationType.yegen)
            .length;
      }

      // Pozitif kontrol: kan bağı olan yarım kardeşten yeğen **gelir**.
      // Gelmiyorsa kapı baştan kapalıdır ve alttaki negatif kontrol
      // hiçbir şey ölçmez.
      int yarimToplam = 0;
      for (int seed = 1; seed <= 12; seed++) {
        yarimToplam += yegenSayisi(RelationType.yariKardes, seed);
      }
      expect(yarimToplam, greaterThan(0),
          reason: '12 tohumda yarım kardeşten hiç yeğen doğmadı: '
              'kan bağı kapısı çalışmıyor.');

      // Negatif kontrol: üvey kardeşten yeğen gelmez (§12-§13, V1 sınırı).
      int uveyToplam = 0;
      for (int seed = 1; seed <= 12; seed++) {
        uveyToplam += yegenSayisi(RelationType.uveyKardes, seed);
      }
      expect(uveyToplam, 0,
          reason: 'Üvey kardeşten yeğen üretildi; sınır kasıtsız delinmiş.');
    });
  });

  group('§30 — aile buluşmaları gerçek kişiye bağlı', () {
    test('her buluşma olayı ya bağ ya da ihmal koşulu taşır', () {
      for (final GameEvent e in kFamilyGatheringEvents) {
        final bool kisiyeBagli = e.requirement.livingRelations.isNotEmpty ||
            e.requirement.requiresNeglectedRelative;
        expect(kisiyeBagli, isTrue,
            reason: '${e.id} hiçbir gerçek kişiye bağlanmıyor.');
      }
    });

    test('metindeki yer tutucular gerçek kişi gerektiriyor', () {
      for (final GameEvent e in kFamilyGatheringEvents) {
        if (!e.text.contains('{')) continue;
        expect(e.requirement.livingRelations.isNotEmpty ||
            e.requirement.requiresNeglectedRelative, isTrue,
            reason: '${e.id} "{kisi}" kullanıyor ama kişi koşulu yok; '
                'ekranda "{sahip}" yazardı.');
      }
    });

    test('buluşma olayları ana havuza gerçekten eklendi', () {
      final Set<String> havuz =
          kEventPool.map((GameEvent e) => e.id).toSet();
      for (final GameEvent e in kFamilyGatheringEvents) {
        expect(havuz.contains(e.id), isTrue,
            reason: '${e.id} havuzda yok: dosyada var, oyunda yok.');
      }
    });

    test('her olayın en az iki seçeneği ve özgün kimliği var', () {
      final Set<String> gorulen = <String>{};
      for (final GameEvent e in kFamilyGatheringEvents) {
        expect(e.choices.length, greaterThanOrEqualTo(2), reason: e.id);
        expect(gorulen.add(e.id), isTrue, reason: '${e.id} tekrar ediyor.');
      }
    });
  });

  group('§35-§36 — yaşlı bakımı gerçekten uygulanıyor', () {
    /// Bakıma muhtaç bir anne kurar.
    GameState bakimliHayat({int playerAge = 45}) {
      GameState s = aileliHayat(seed: 13, age: playerAge);
      final Person anne = kisi(s, RelationType.anne)!;
      return s.copyWith(
        people: List<Person>.unmodifiable(s.people
            .map((Person p) => p.id == anne.id
                ? p.copyWith(age: 84, happiness: 30, bond: 50)
                : p)
            .toList(growable: false)),
      );
    }

    test('yaş ve sağlık birlikte bakılır; sağlıklı yetmişlik bakım açmaz',
        () {
      final GameState s = aileliHayat(seed: 13, age: 45);
      final Person anne = kisi(s, RelationType.anne)!;
      final Person saglikli =
          anne.copyWith(age: 72, happiness: 90);
      expect(ElderCare.needsCare(s, saglikli), isFalse);
    });

    test('masrafa yardım cüzdandan gerçekten para çıkarır', () {
      final GameState s = bakimliHayat();
      final Person anne = kisi(s, RelationType.anne)!;
      expect(ElderCare.needsCare(s, anne), isTrue);

      final int maliyet = ElderCare.yearlyCost();
      final GameState zengin =
          s.copyWith(player: s.player.copyWith(wallet: maliyet * 4));

      final ElderCareResult r = ElderCare.apply(
        state: zengin,
        parent: anne,
        choice: ElderCareChoice.masrafaYardim,
        rng: Random(1),
      );
      expect(r.paid, greaterThan(0));
      expect(r.state.player.wallet, zengin.player.wallet - r.paid);
      expect(r.state.personById(anne.id)!.bond,
          greaterThan(anne.bond),
          reason: 'Bakım yakınlığı artırmalı.');
    });

    test('parası yetmeyen oyuncuya sahte yardım yazılmaz', () {
      final GameState s = bakimliHayat();
      final Person anne = kisi(s, RelationType.anne)!;
      final GameState fakir =
          s.copyWith(player: s.player.copyWith(wallet: 0));

      final ElderCareResult r = ElderCare.apply(
        state: fakir,
        parent: anne,
        choice: ElderCareChoice.masrafaYardim,
        rng: Random(1),
      );
      expect(r.paid, 0);
      expect(identical(r.state, fakir), isTrue,
          reason: 'Durum değişmemeliydi; cüzdan eksiye düşemez.');
      expect(r.state.player.wallet, 0);
    });

    test('§36 — parası olmayan kardeş havadan katkı üretmez', () {
      GameState s = bakimliHayat();
      s = kisiEkle(s,
          id: 'kardes-fakir',
          relation: RelationType.kardes,
          age: 42,
          hanede: false,
          wealth: WealthTier.cokYoksul);
      final ({int amount, List<String> names}) katki =
          ElderCare.siblingContribution(s, ElderCare.yearlyCost());
      expect(katki.amount, 0);
      expect(katki.names, isEmpty);
    });

    test('§36 — varlıklı kardeş katkı verir ama masrafı aşamaz', () {
      GameState s = bakimliHayat();
      for (int i = 0; i < 4; i++) {
        s = kisiEkle(s,
            id: 'kardes-zengin-$i',
            relation: RelationType.kardes,
            age: 40 + i,
            hanede: false,
            wealth: WealthTier.cokVarlikli);
      }
      final int maliyet = ElderCare.yearlyCost();
      final ({int amount, List<String> names}) katki =
          ElderCare.siblingContribution(s, maliyet);
      expect(katki.amount, greaterThan(0));
      expect(katki.amount, lessThanOrEqualTo(maliyet),
          reason: 'Kardeşler masrafın tamamından fazlasını ödeyemez.');
    });

    test('ilgilenmemek bedelsiz değil: yakınlık düşer', () {
      final GameState s = bakimliHayat();
      final Person anne = kisi(s, RelationType.anne)!;
      final ElderCareResult r = ElderCare.apply(
        state: s,
        parent: anne,
        choice: ElderCareChoice.ilgilenme,
        rng: Random(4),
      );
      expect(r.paid, 0);
      expect(r.state.personById(anne.id)!.bond, lessThan(anne.bond));
    });
  });

  group('§4 — hane seçimi gerçekten uygulanıyor', () {
    test('seçim bekleyen boşanmada oyuncu anneyi seçince baba haneden çıkar',
        () {
      final GameState taban = aileliHayat(seed: 17, age: 13);
      final GameState bosandi = bosandir(taban, yas: 13);
      expect(bosandi.parentalStatus, ParentalStatus.bosanmis);

      if (!ParentDivorce.isPending(bosandi)) {
        // Seçim yaşı dışındaysa bu test anlamsız; kurulum hatası olmasın
        // diye açıkça belirtiliyor.
        fail('13 yaşındaki oyuncuya hane seçimi sorulmadı.');
      }

      final GameState secildi =
          ParentDivorce.choose(bosandi, DivorceHouseholdChoice.anne);
      expect(ParentDivorce.isPending(secildi), isFalse,
          reason: 'Seçim tüketilmeliydi.');
      expect(kisi(secildi, RelationType.anne)!.inPlayerHousehold, isTrue);
      expect(kisi(secildi, RelationType.baba)!.inPlayerHousehold, isFalse);
      // §2: kimse silinmez.
      expect(kisi(secildi, RelationType.anne), isNotNull);
      expect(kisi(secildi, RelationType.baba), isNotNull);
    });

    test('seçim yapılmasa da oyun tutarlı kalır', () {
      final GameState taban = aileliHayat(seed: 17, age: 13);
      final GameState bosandi = bosandir(taban, yas: 13);
      // Varsayılan hane boşanma anında zaten kuruldu: iki ebeveynden
      // **tam olarak biri** hanede olmalı.
      final int hanede = <RelationType>[RelationType.anne, RelationType.baba]
          .where((RelationType t) => kisi(bosandi, t)!.inPlayerHousehold)
          .length;
      expect(hanede, 1);
    });
  });
}
