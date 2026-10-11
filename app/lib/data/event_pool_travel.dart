/// Gezi olayları (Paket 11).
///
/// Yolda yaşanan kısa sahneler ve yıllar sonra hatırlanan anılar. Anı
/// olayları **gerçekten yapılmış** bir geziye dayanır: kişi o gezinin
/// yoldaşıdır, `{sehir}` gerçek gezi kaydından doldurulur. Yalnızca şehir
/// adı değişen aynı metin çoğaltılmaz.
library;

import '../domain/models/game_event.dart';

/// Gezi hikâyesi izleri.
abstract final class TravelFlags {
  static const String yoldaTanisti = 'gezide_tanisti';
  static const String gezidePara = 'gezide_para_bitti';
}

const List<GameEvent> kTravelEvents = <GameEvent>[
  // 1 — Yolda tanışma (gezi yapmış oyuncuya)
  GameEvent(
    id: 'gezi_yolda_sohbet',
    category: EventCategory.kisisel,
    text:
        'Dönüş yolunda yanındaki koltuktaki kişi konuşmaya başladı. '
        'Yolun yarısında hâlâ konuşuyorsunuz.',
    requirement: EventRequirement(minAge: 16, requiresTripMemory: true),
    repeatable: true,
    minAgeGap: 6,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'dinle',
        label: 'Dinle',
        resultText:
            'Bütün hayatını anlattı. İnip ayrıldığınızda adını '
            'sormadığını fark ettin.',
        happiness: 3,
        charisma: 1,
        addFlags: <String>{TravelFlags.yoldaTanisti},
      ),
      EventChoice(
        id: 'uyu',
        label: 'Uyumaya çalış',
        resultText: 'Gözlerini kapattın. Uyuyamadın ama konuşma da bitti.',
        happiness: 1,
      ),
    ],
  ),

  // 2 — Anı: aynı kişiyle yapılan gezi yıllar sonra
  GameEvent(
    id: 'gezi_anisi',
    category: EventCategory.kisisel,
    text:
        'Bir fotoğraf çıktı ortaya: {kisi} ile {sehir} gezisi. '
        'İkiniz de o gün daha gençsiniz.',
    requirement: EventRequirement(minAge: 20, requiresTripMemory: true),
    repeatable: true,
    minAgeGap: 8,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'goster',
        label: '{kisi} ile birlikte bak',
        resultText:
            'Fotoğrafa birlikte baktınız. {kisi} o gün yediğiniz '
            'yemeği hatırlıyordu, sen hava durumunu.',
        happiness: 5,
        bond: 8,
      ),
      EventChoice(
        id: 'kendine_sakla',
        label: 'Bir süre kendin bak',
        resultText:
            'Fotoğrafı yerine koydun. Bazı günler yalnız '
            'hatırlanmak ister.',
        happiness: 3,
      ),
    ],
  ),

  // 3 — Anı: yeniden gitme isteği
  GameEvent(
    id: 'gezi_tekrar_istegi',
    category: EventCategory.kisisel,
    text:
        '{kisi} bir akşam laf arasında söyledi: "{sehir} iyiydi, bir '
        'daha gitsek mi?"',
    requirement: EventRequirement(minAge: 20, requiresTripMemory: true),
    repeatable: true,
    minAgeGap: 10,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'soz_ver',
        label: '"Gideriz" de',
        resultText:
            'Söz verdin. Tarih koymadınız ama ikiniz de bunu '
            'aklınızda tuttunuz.',
        happiness: 4,
        bond: 6,
      ),
      EventChoice(
        id: 'gulup_gec',
        label: 'Gülüp geç',
        resultText:
            'Konu değişti. Yine de {kisi} o akşam iki kere daha '
            'aynı şeyi söyledi.',
        happiness: 2,
      ),
    ],
  ),

  // 4 — Yolda para sıkıntısı
  GameEvent(
    id: 'gezi_para_sikintisi',
    category: EventCategory.kisisel,
    text:
        'Gezide hesap beklediğinden kabarık çıktı. Cüzdana bakıp bir '
        'an duraksadın.',
    requirement: EventRequirement(minAge: 16, requiresTripMemory: true),
    repeatable: true,
    minAgeGap: 9,
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'idare_et',
        label: 'Kalanla idare et',
        resultText:
            'Dönüş yolunda sadece çay içtin. Anlatınca gülünecek '
            'bir hikâye oldu.',
        happiness: 2,
        addFlags: <String>{TravelFlags.gezidePara},
      ),
      EventChoice(
        id: 'kisa_kes',
        label: 'Geziyi kısa kes',
        resultText:
            'Bir gün erken döndün. Doğru karardı ama biraz burukluk '
            'bıraktı.',
        happiness: -2,
        money: 2500,
      ),
    ],
  ),
];
