import '../../text/turkish_text.dart';
import '../models/game_state.dart';
import '../models/gender.dart';
import '../models/life_log.dart';
import '../models/person.dart';
import '../models/person_development.dart';
import '../models/relation.dart';
import 'parenthood.dart';

/// Doğumda çocuğa isim verme (D-095).
///
/// Oyun bebeğe bir ad **önerir**; oyuncu isterse kendi adını yazar. İsim
/// yalnızca doğum yılında, yani bebek henüz 0 yaşındayken değiştirilebilir;
/// yıllar sonra geriye dönüp herkesin adını değiştirmek için bir kapı
/// açılmaz.
abstract final class ChildNaming {
  /// prototypeOnly: kabul edilen en kısa ad.
  static const int minLength = 2;

  /// prototypeOnly: kabul edilen en uzun ad.
  static const int maxLength = 16;

  /// Yalnızca harf, boşluk ve kısa çizgi kabul edilir.
  static final RegExp _gecerli = RegExp(r"^[A-Za-zÇĞİÖŞÜçğıöşü' -]+$");

  /// Girilen metni ada çevirir; geçersizse `null` döndürür.
  ///
  /// Baştaki/sondaki boşluklar atılır, aradaki çoklu boşluklar teke iner,
  /// her kelimenin ilk harfi Türkçe kurallarıyla büyütülür.
  static String? normalize(String raw) {
    final String temiz = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (temiz.length < minLength || temiz.length > maxLength) return null;
    if (!_gecerli.hasMatch(temiz)) return null;
    return temiz
        .split(' ')
        .map((String k) => trUpperFirst(trLower(k)))
        .join(' ');
  }

  /// Bu kişiye şu an isim verilebilir mi?
  ///
  /// Yalnızca oyuncunun **yeni doğmuş** çocuğu: yaşayan, 0 yaşında ve
  /// çocuk bağıyla bağlı biri.
  static bool canName(GameState state, String childId) {
    final Person? kisi = state.personById(childId);
    if (kisi == null) return false;
    return kisi.isAlive && kisi.age == 0 && kisi.relation == RelationType.cocuk;
  }

  /// Bebeğin adını değiştirir.
  ///
  /// Değişiklik gerçekten uygulandıysa yeni durum, uygulanmadıysa sebebiyle
  /// birlikte `null` döner. Soyadı değişmez: çocuk ailenin soyadını taşır.
  static ({GameState? state, String message}) rename(
    GameState state,
    String childId,
    String raw,
  ) {
    if (!canName(state, childId)) {
      return (state: null, message: 'Bu isim artık değiştirilemez.');
    }
    final String? ad = normalize(raw);
    if (ad == null) {
      return (
        state: null,
        message: 'İsim $minLength-$maxLength harf arasında olmalı ve '
            'yalnızca harf içermeli.',
      );
    }
    final Person bebek = state.personById(childId)!;
    if (ad == bebek.firstName) {
      return (state: null, message: 'Bebeğin adı zaten $ad.');
    }

    final String eskiAd = bebek.firstName;
    final List<Person> kisiler = state.people
        .map((Person p) => p.id == childId
            ? p.copyWith(
                firstName: ad,
                development: _tazelenmisKayit(p, eskiAd, ad),
              )
            : p)
        .toList(growable: false);

    return (
      state: state.copyWith(
        people: List<Person>.unmodifiable(kisiler),
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          for (final LifeLogEntry e in state.log)
            _tazelenmisSatir(e, childId, bebek.gender, eskiAd, ad),
          LifeLogEntry(
            age: state.player.age,
            text: 'Bebeğe $ad adını verdin.',
            category: LogCategory.aile,
            personId: childId,
          ),
        ]),
      ),
      message: 'Bebeğin adı artık $ad.',
    );
  }

  /// Doğum satırındaki **geçici** adı yeni adla değiştirir.
  ///
  /// **Nasıl bulundu (Paket CG, altıncı döküm turu).** Bebek oyunun ad
  /// havuzundan bir adla doğuyor ve doğum satırı o adı yazıyor. Oyuncu
  /// ad verdiğinde yalnızca ikinci bir satır ekleniyordu; doğum satırı
  /// olduğu gibi kalıyordu. Sonuç, aynı yılda yan yana duran iki ad:
  /// "Nuri adında bir oğlunuz oldu." ve "Bebeğe Kemal adını verdin."
  /// Günlük oyunun hafızası; orada hiç var olmamış bir ad kalmamalı.
  ///
  /// Yalnızca **o çocuğun kimliğini taşıyan** ve **doğum cümlesi
  /// kalıbına** uyan satır değişir; başka satıra dokunulmaz.
  static LifeLogEntry _tazelenmisSatir(
    LifeLogEntry e,
    String childId,
    Gender gender,
    String eskiAd,
    String yeniAd,
  ) {
    if (e.personId != childId) return e;
    for (final bool ikiz in <bool>[false, true]) {
      final String eskiCumle = Parenthood.birthSentence(
          name: eskiAd, gender: gender, twin: ikiz);
      if (!e.text.contains(eskiCumle)) continue;
      return LifeLogEntry(
        age: e.age,
        text: e.text.replaceFirst(
          eskiCumle,
          Parenthood.birthSentence(
              name: yeniAd, gender: gender, twin: ikiz),
        ),
        category: e.category,
        personId: e.personId,
      );
    }
    return e;
  }

  /// Çocuğun kendi kaydındaki doğum kilometre taşını tazeler.
  ///
  /// Kişi kartı bu listeyi gösteriyor; orada da eski ad kalıyordu.
  static PersonDevelopment? _tazelenmisKayit(
    Person p,
    String eskiAd,
    String yeniAd,
  ) {
    final PersonDevelopment? kayit = p.development;
    if (kayit == null) return null;
    final String eski = Parenthood.birthMilestone(eskiAd);
    if (!kayit.milestones.any((LifeMilestone m) => m.text == eski)) {
      return kayit;
    }
    return kayit.copyWith(
      milestones: List<LifeMilestone>.unmodifiable(<LifeMilestone>[
        for (final LifeMilestone m in kayit.milestones)
          if (m.text == eski)
            LifeMilestone(age: m.age, text: Parenthood.birthMilestone(yeniAd))
          else
            m,
      ]),
    );
  }
}
