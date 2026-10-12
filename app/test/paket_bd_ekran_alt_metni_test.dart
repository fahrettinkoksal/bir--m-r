// Oyuncunun gördüğü metin: uzunluk ve cümle başı.
//
// İki ayrı bulgu, aynı kaynaktan — ekran dökümü (`ekran_dokumu_test.dart`)
// hayat günlüğünü ve menüleri gözle okunacak hâlde bastı.
//
// **Nasıl bulundu.** Ekran dökümü (`ekran_dokumu_test.dart`) İlişkiler
// ekranında şu satırı bastı:
//
//     Evcil hayvanlar
//     Kedi ya da Köpek ya da Muhabbet kuşu ya da Kaplumbağa ya da Balık
//     ya da Kanarya ya da Papağan ya da Hamster ya da Tavşan ya da Timsah
//
// Boş durum, sahiplenilebilir **türlerin tamamını** " ya da " ile
// birleştiriyordu: 104 karakter, bir menü alt satırında okunamaz ve
// katalog her büyüdüğünde uzuyor. Dört evrenin üçünde göründü.
//
// Alt metin artık **grupları** sayıyor. Bu dosya iki şeyi güvenceye
// alır: (1) uzunluk bir satırda kalır, (2) metin kataloğu tek tek
// saymaz — yani aynı hata yeni bir tür eklenince geri gelemez.
library;

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/pet_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/pets/pet_care.dart';
import 'package:bir_omur/ui/screens/sections/relationships_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Menü alt satırının makul üst sınırı.
  ///
  /// Telefon genişliğinde iki satıra kadar okunur; 70 karakter bunun
  /// sınırı. Bulunan hata 104 karakterdi.
  const int enFazlaUzunluk = 70;

  test('hayvanı olmayan oyuncunun alt metni bir satırda kalır', () {
    final GameState s =
        LifeGenerator.seeded(3).generate(mode: StartMode.tamamenRastgele);
    // Hayvanı olmayan bir durum kur: kayıttaki hayvanlar boşaltılır.
    final GameState hayvansiz = s.copyWith(pets: const <Pet>[]);
    expect(PetCare.livingPets(hayvansiz), isEmpty,
        reason: 'Testin kurulumu geçersiz: hayvan kalmış.');

    final String metin = debugPetSubtitle(hayvansiz);
    expect(metin.length, lessThanOrEqualTo(enFazlaUzunluk),
        reason: 'Alt metin $enFazlaUzunluk karakteri aşıyor '
            '(${metin.length}): "$metin"');
    expect(metin, isNot(contains(' ya da ')),
        reason: 'Alt metin tür tür sayıyor; katalog büyüdükçe uzayacak: '
            '"$metin"');
  });

  test('alt metin bütün türleri tek tek saymaz', () {
    final GameState s = LifeGenerator.seeded(4)
        .generate(mode: StartMode.tamamenRastgele)
        .copyWith(pets: const <Pet>[]);
    final String metin = debugPetSubtitle(s);
    // Tür adlarından en çok biri geçebilir; onu da grup adı olarak
    // geçiyorsa sorun yok. İkisi birden geçerse katalog sayılıyor.
    final int gecenTur = adoptablePetSpecies
        .where((PetSpecies t) => metin.contains(t.label))
        .length;
    expect(gecenTur, lessThanOrEqualTo(1),
        reason: 'Alt metinde $gecenTur tür adı var: "$metin"');
  });

  test('hayvanı olan oyuncuda alt metin kaydı anlatır', () {
    final GameState s =
        LifeGenerator.seeded(5).generate(mode: StartMode.tamamenRastgele);
    final List<Pet> yasayan = PetCare.livingPets(s);
    if (yasayan.isEmpty) return; // Bu tohumda hayvan yok; iddia yok.
    final String metin = debugPetSubtitle(s);
    expect(metin.length, lessThanOrEqualTo(enFazlaUzunluk));
    if (yasayan.length == 1) {
      expect(metin, contains(yasayan.first.name));
    } else {
      expect(metin, contains('${yasayan.length}'));
    }
  });

  // =================================================================
  // Cümle başındaki yer tutucu küçük harfe açılmamalı
  // =================================================================
  //
  // **Nasıl bulundu.** Döküm, 25 yaşın günlüğünde şu satırı bastı:
  //
  //     arkadaşın Hasan ile bir saat konuştunuz. Aradaki mesafe
  //     kapanmadı ama ilk adım atıldı.
  //
  // **Kök neden.** `EventEngine._fill` iki yer tutucu tanıyor ve ayrımı
  // belgeli: `{sahip}` cümle **başı** için ("Arkadaşın"), `{sahipk}`
  // cümle **içi** için ("arkadaşın", `trLowerFirst`). Motor doğru; hata
  // içerikteydi — iki olay sonucu `{sahipk}` ile **başlıyordu**.
  // `event_pool.dart:464` ve `:509` düzeltildi. Üçüncü bir aday
  // (`:368`) incelendi ve **dokunulmadı**: orada yer tutucu gerçekten
  // cümle içinde ("Bisiklet senin oldu ama {sahipk} …").
  //
  // Bekçi bütün havuzu tarıyor: `kEventPool` alt havuzların hepsini
  // birleştiriyor (`...kLifeStageEvents`, `...kCrimeEvents`, …), yani
  // yeni bir olay yanlış yer tutucuyla eklenirse burada düşer.

  /// Küçük harfe açılan yer tutucular (`event_engine.dart:599-609`).
  const List<String> kucugeAcilanlar = <String>['{sahipk}', '{bag}'];

  test('hiçbir olay metni küçük harfe açılan yer tutucuyla başlamıyor',
      () {
    final List<String> bozuk = <String>[];
    for (final GameEvent olay in kEventPool) {
      void denetle(String etiket, String metin) {
        for (final String tutucu in kucugeAcilanlar) {
          if (metin.trimLeft().startsWith(tutucu)) {
            bozuk.add('${olay.id} · $etiket · "$tutucu…"');
          }
        }
      }

      denetle('text', olay.text);
      for (final EventChoice secim in olay.choices) {
        denetle('seçim ${secim.id} · resultText', secim.resultText);
        denetle('seçim ${secim.id} · label', secim.label);
      }
    }
    expect(bozuk, isEmpty,
        reason: 'Bu metinler küçük harfle başlayacak; cümle başında '
            '{sahip} kullanılmalı: ${bozuk.join(" · ")}');
  });

  test('havuz gerçekten taranıyor (bekçi boşa çalışmıyor)', () {
    expect(kEventPool.length, greaterThan(200),
        reason: 'Havuz beklenenden küçük: tarama kapsamı daralmış olabilir.');
    final int tutuculuMetin = kEventPool
        .where((GameEvent e) =>
            e.text.contains('{sahip') ||
            e.choices.any((EventChoice c) => c.resultText.contains('{sahip')))
        .length;
    expect(tutuculuMetin, greaterThan(5),
        reason: 'Yer tutucu kullanan olay kalmamış; bekçinin denetleyecek '
            'bir şeyi yok.');
  });
}
