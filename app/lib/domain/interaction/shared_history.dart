import '../../data/possession_names.dart';
import '../../text/turkish_text.dart';
import '../models/game_state.dart';
import '../models/gift_record.dart';
import '../models/life_log.dart';
import '../models/marriage.dart';
import '../models/person.dart';
import '../models/person_development.dart';
import '../models/relation.dart';
import '../models/trip.dart';

/// Bir kişiyle paylaşılan tek bir an.
class SharedMoment {
  const SharedMoment({
    required this.age,
    required this.text,
    required this.kind,
  });

  /// Anın yaşandığı **oyuncu** yaşı.
  final int age;
  final String text;
  final SharedMomentKind kind;
}

/// Ortak geçmişteki an türü (ekranda ikon seçmek için).
enum SharedMomentKind { olay, hediye, gezi, kilometreTasi }

/// Bir kişiyle yaşanmış olanların derlenmesi (Paket 14).
///
/// Hiçbir şey uydurulmaz: yalnızca kayıtlarda **gerçekten duran** veriler
/// okunur — hayat günlüğünün o kişiye bağlı satırları, hediye kayıtları,
/// birlikte yapılan geziler ve ilişki kilometre taşları. Kayıt yoksa
/// bölüm hiç gösterilmez.
abstract final class SharedHistory {
  /// prototypeOnly: ekranda gösterilecek en fazla an sayısı.
  static const int prototypeOnlyMaxMoments = 12;

  /// Bu kişiyle yaşananlar, eskiden yeniye.
  static List<SharedMoment> of(GameState state, Person person) {
    final List<SharedMoment> anlar = <SharedMoment>[
      ..._milestones(state, person),
      ..._logMoments(state, person),
      ..._gifts(state, person),
      ..._trips(state, person),
    ]..sort((SharedMoment a, SharedMoment b) => a.age.compareTo(b.age));

    if (anlar.length <= prototypeOnlyMaxMoments) return anlar;
    // Çok uzun geçmişte en yeniler gösterilir; eskiler kaybolmaz, yalnızca
    // bu listede görünmez.
    return anlar.sublist(anlar.length - prototypeOnlyMaxMoments);
  }

  /// İlişkinin kilometre taşları: evlilik, boşanma, doğum, aileye katılış.
  static List<SharedMoment> _milestones(GameState state, Person person) {
    final List<SharedMoment> anlar = <SharedMoment>[];

    final Marriage? evlilik = state.marriage;
    if (evlilik != null && evlilik.spouseId == person.id) {
      anlar.add(
        SharedMoment(
          age: evlilik.marriedAtAge,
          text: 'Evlendiniz.',
          kind: SharedMomentKind.kilometreTasi,
        ),
      );
    }

    // Çocuk ve torunun doğumu, oyuncunun o yaşına yazılır.
    //
    // Evlat edinilen çocukta bu satır **yazılmaz** (Paket 43): onun aileye
    // katıldığı yıl kendi kilometre taşı kaydında duruyor. Burada
    // yazılsaydı katılım, çocuğun doğduğu yıla — yani oyuncunun hiç
    // yaşamadığı bir ana — düşerdi ve aynı olay iki kez görünürdü.
    if (person.relation == RelationType.cocuk ||
        person.relation == RelationType.torun) {
      final bool evlatlik = person.development?.adopted ?? false;
      final int dogumYasi = state.player.age - person.age;
      if (!evlatlik && dogumYasi >= 0) {
        anlar.add(
          SharedMoment(
            age: dogumYasi,
            text: '${person.firstName} dünyaya geldi.',
            kind: SharedMomentKind.kilometreTasi,
          ),
        );
      }
    }

    // Kişinin kendi hayatındaki önemli anlar (çocuk/torun kaydı).
    final PersonDevelopment? gelisim = person.development;
    if (gelisim != null && gelisim.tracksLife) {
      final int dogumYasi = state.player.age - person.age;
      for (final LifeMilestone m in gelisim.milestones) {
        final int oyuncuYasi = dogumYasi + m.age;
        if (oyuncuYasi < 0) continue;
        anlar.add(
          SharedMoment(
            age: oyuncuYasi,
            text: m.text,
            kind: SharedMomentKind.kilometreTasi,
          ),
        );
      }
    }

    // Vefat, **gerçekten olduğu yılla** hayat günlüğünden okunur
    // (`_logMoments`). Buraya "şu anki yaş" yazmak uydurma bir tarihti ve
    // her yaş almada kayıyordu (Paket 43).
    return anlar;
  }

  /// Hayat günlüğünün bu kişiye bağlı satırları.
  static List<SharedMoment> _logMoments(GameState state, Person person) =>
      <SharedMoment>[
        for (final LifeLogEntry e in state.log)
          if (e.personId == person.id)
            SharedMoment(
              age: e.age,
              text: e.text,
              kind: SharedMomentKind.olay,
            ),
      ];

  /// Karşılıklı hediyeler.
  static List<SharedMoment> _gifts(GameState state, Person person) {
    final List<SharedMoment> anlar = <SharedMoment>[];
    for (final GiftRecord g in state.gifts) {
      final bool ondan =
          g.fromId == person.id && g.toId == GiftRecord.playerId;
      final bool ona = g.toId == person.id && g.fromId == GiftRecord.playerId;
      if (!ondan && !ona) continue;
      final String ad = possessionName(g.itemId);
      anlar.add(
        SharedMoment(
          age: g.age,
          text: ondan
              ? '${person.firstName} sana $ad verdi.'
              : '${person.firstName} kişisine $ad verdin.',
          kind: SharedMomentKind.hediye,
        ),
      );
    }
    return anlar;
  }

  /// Birlikte yapılan geziler.
  static List<SharedMoment> _trips(GameState state, Person person) =>
      <SharedMoment>[
        for (final TripRecord t in state.trips)
          if (t.companionId == person.id)
            SharedMoment(
              age: t.age,
              text: '${t.city} gezisi (${trMoney(t.cost)})'
                  '${t.note == null ? '' : ' — ${t.note}'}',
              kind: SharedMomentKind.gezi,
            ),
      ];
}
