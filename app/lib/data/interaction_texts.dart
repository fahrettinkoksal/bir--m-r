/// Etkileşim sonuç metinleri.
///
/// Metinler bu projeye özgü yazılmıştır. `{ad}` kişinin adıyla, `{bag}` ise
/// küçük harfli bağ etiketiyle (anne, abla, dede ...) değiştirilir.
library;

import 'dart:math';

import '../domain/models/interaction.dart';
import 'gift_catalog.dart';
import '../domain/models/person.dart';
import '../domain/models/relation.dart';
import '../text/turkish_text.dart';

const List<String> _vakitGecirGenel = <String>[
  '{ad} ile çay demleyip balkonda oturdunuz; konu bir yerden eski '
      'mahalleye geldi.',
  '{ad} ile birlikte pazara gittiniz, dönüşte poşetleri paylaşarak '
      'yokuşu çıktınız.',
  '{ad} ile akşamüstü uzun bir yürüyüşe çıktınız; kimse acele etmedi.',
  '{ad} ile mutfakta bir şeyler hazırladınız, yarısını daha tencereye '
      'girmeden yediniz.',
];

const List<String> _vakitGecirBuyuk = <String>[
  '{ad} eski bir kutudan fotoğraflar çıkardı; her birinin arkasında '
      'bir tarih, her tarihte bir hikâye vardı.',
  '{ad} ile radyoda çalan eski bir şarkıyı sonuna kadar dinlediniz.',
  '{ad}, tanımadığın akrabaları tek tek anlattı; yarısını unuttun ama '
      'anlatırkenki hâlini unutmadın.',
];

const List<String> _vakitGecirKardes = <String>[
  '{ad} ile odanın ortasında saatlerce bir şeyler oynadınız; kural '
      'sizden başka kimsenin anlamadığı türdendi.',
  '{ad} ile sokakta top peşinde koştunuz, ikiniz de terli ve mutlu '
      'döndünüz.',
  '{ad} ile televizyonun karşısında aynı çizgi filmi bir kez daha '
      'izlediniz.',
];

/// Bebeklik (0-3): oyun değil bakım; oyuncunun yaptığı gerçek şeyler.
const List<String> _vakitGecirBebek = <String>[
  '{ad} kucağında uyuyakaldı. Kolun uyuştu, kıpırdamadın.',
  '{ad} ile yer minderinde oturdunuz; elindeki oyuncağı üç kez sana '
      'verip üç kez geri aldı.',
  "{ad} yemek yerken yarısı önlüğe gitti. İkiniz de güldünüz.",
  '{ad} ilk kez senin adını andı; tam çıkmadı ama sayıldı.',
];

/// Okul çağı (4-12).
const List<String> _vakitGecirCocukKucuk = <String>[
  '{ad} ile parka gittiniz; salıncakta "bir kere daha" beş kere oldu.',
  '{ad} ile yere kâğıt serip resim yaptınız. Senin çizdiğin ev eğri '
      'çıktı, o beğendi.',
  '{ad} ile ödevine oturdunuz; sonunda ikiniz de bir şey öğrendiniz.',
  '{ad} ile bisiklet sürmeyi çalıştınız. Arkasından koştun, bıraktığın '
      'anı fark etmedi.',
];

/// Ergenlik (13-17): yakınlık kurmak daha zor, sonuç daha kıymetli.
const List<String> _vakitGecirErgen = <String>[
  '{ad} ile arabada radyo açık, kimse konuşmadan gittiniz. İnerken '
      '"iyiydi" dedi.',
  '{ad} ile maç izlediniz. İki cümle kurdunuz, ikisi de gol anında.',
  '{ad} ile market alışverişine çıktınız; sepete koyduğu şeyleri geri '
      'koymadın.',
];

/// Eş: aynı hanede kurulan gündelik yakınlık.
const List<String> _vakitGecirEs = <String>[
  '{ad} ile akşam mutfakta kaldınız; bulaşık sonraya kaldı, sohbet '
      'kalmadı.',
  '{ad} ile balkonda oturup sokağı seyrettiniz. Kimse telefona bakmadı.',
  '{ad} ile yıllar önce gittiğiniz yere bir kez daha gittiniz; orası '
      'değişmiş, siz de.',
];

/// Ayrı evde yaşayan yakınla görüşmek bir **ziyarettir**.
const List<String> _vakitGecirZiyaret = <String>[
  '{ad} ile görüşmek için yol yaptın. Kapıda "geleceğini bilsem '
      'hazırlanırdım" dedi.',
  "{ad} için yola çıktın; çay demlendi, gitme vaktin iki kez ertelendi.",
  '{ad} ile dışarıda buluştunuz. Aynı evde yaşamıyorsunuz, o yüzden '
      'her cümle biraz daha özenliydi.',
];

const List<String> _sohbetEs = <String>[
  '{ad} ile gün içinde olanları anlattınız; küçük şeylerdi, sıkılmadınız.',
  '{ad} ile ileriye dair konuştunuz. Plan yapmadınız, ihtimalleri '
      'konuşmak yetti.',
  '{ad} bugün seni dinledi; söylediğin şeyi zaten fark etmiş ama '
      'senden duymayı beklemiş.',
];

const List<String> _sohbetCocuk = <String>[
  '{ad} okulda olanları anlattı; hikâyenin yarısı gerçek, yarısı '
      'abartıydı, ikisi de güzeldi.',
  '{ad} sana bir soru sordu, cevabını bilmiyordun. "Bakarız" dedin, '
      'gerçekten baktınız.',
  '{ad} ile korkularından konuştunuz; ciddiye alındığını anlayınca '
      'rahatladı.',
];

const List<String> _sohbetGenel = <String>[
  '{ad} ile uzun uzun konuştunuz; söylemek isteyip söyleyemediğin şeyi '
      'sonunda söyledin.',
  '{ad} sana kendi yaşındayken neler yaptığını anlattı; bazı şeyler '
      'hiç değişmemiş.',
  '{ad} ile bir konuda tartıştınız, sonunda ikiniz de biraz haklı '
      'çıktınız.',
  '{ad} seni dinledi, araya girmedi; bu bile iyi geldi.',
];

const List<String> _redGenel = <String>[
  '{ad}: "Daha yeni oturduk canım, biraz sonra."',
  '{ad}: "Şimdi olmaz, bir işim var; sonra uzun uzun konuşuruz."',
  '{ad} yorgun görünüyordu, "Bugünlük bu kadar" dedi.',
  '{ad}: "Az önce beraberdik ya, biraz nefes al."',
];

const List<String> _doyumGenel = <String>[
  '{ad} ile yine oturdunuz. Güzeldi ama bugün birbirinize '
      'anlatacak yeni bir şey kalmamıştı.',
  '{ad} ile vakit geçirdiniz; bu yaşta artık birbirinizi fazlasıyla '
      'tanıyorsunuz.',
  '{ad} ile aynı sohbeti bir kez daha ettiniz, tadı ilk günkü gibi '
      'değildi.',
];

const List<String> _hediyeVer = <String>[
  '{ad} için {esya} aldın. Paketi açarken "buna ne gerek vardı" dedi ama '
      'gözünü ondan ayırmadı.',
  '{ad} aldığın {esya} karşısında bir süre konuşmadı, sonra "sen benim..." '
      'diye başlayıp cümlesini bitiremedi.',
  '{ad} için aldığın {esya} masada duruyor. Küçük bir şeydi; masadaki en '
      'değerli şey oldu.',
];

const List<String> _hediyeIsteKabul = <String>[
  '{ad} dolabın üst rafına uzandı: "Sende dursun." Sana bir {esya} hediye '
      'etti.',
  '{ad} bir şey demeden içeri girdi, elinde {esya} ile çıktı: "Kaybetme ama."',
  '{ad} "isteyenin bir yüzü kara" dedi ve sana bir {esya} aldı.',
];

const List<String> _paraIsteKabul = <String>[
  '{ad} cüzdanını çıkardı, katlanmış parayı avucuna sıkıştırdı: '
      '"Kimseye söyleme."',
  '{ad} "idareli kullan" diyerek bozuklukları saydı.',
  '{ad} bir şey sormadı, parayı uzattı; sen de sormadın.',
];

const List<String> _hediyeRed = <String>[
  '{ad}: "Bu ay olmaz, biliyorsun."',
  '{ad} başını iki yana salladı: "Daha geçen gün almadık mı?"',
  '{ad}: "Şimdi değil. Bir şey lazım olursa söylersin."',
];

const List<String> _paraRed = <String>[
  '{ad} cüzdanını açtı, kapattı: "Bugün bende de yok."',
  '{ad}: "Her istediğinde veremem, alışırsın."',
  '{ad} bir an düşündü, "Ay sonu" dedi ve konuyu değiştirdi.',
];

const List<String> _hediyeDoyum = <String>[
  '{ad}: "Bu kadar hediye yeter bu aralar." Paketi almadın, '
      'vazgeçtin.',
  '{ad} ile bakıştınız; ikiniz de bunun fazla olacağını biliyordunuz.',
];

/// İstenecek hediye kalmadığında gösterilir; sahte bir kazanç yaratılmaz.
const List<String> _hediyeKalmadi = <String>[
  '{ad} etrafına bakındı: "Verecek bir şey bulamadım, elim boş kalmasın '
      'istemezdim."',
];

/// Kişi ve etkileşim türüne uygun bir metin seçer.
String interactionText({
  required Random rng,
  required Person person,
  required InteractionKind kind,
  required bool accepted,
  required bool noNewBenefit,
  required int playerAge,

  /// Hediye taşıyan etkileşimlerde eşyanın adı; metinde `{esya}` yerine
  /// geçer. Hediye gerçekten el değiştirmediyse `null`'dır.
  String? giftName,
}) {
  final List<String> pool;
  if (!accepted) {
    pool = switch (kind) {
      InteractionKind.paraIste => _paraRed,
      InteractionKind.hediyeIste || InteractionKind.hediyeVer => _hediyeRed,
      _ => _redGenel,
    };
  } else if (noNewBenefit) {
    pool = kind.transfersResource ? _hediyeDoyum : _doyumGenel;
  } else if (kind == InteractionKind.hediyeVer) {
    pool = _hediyeVer;
  } else if (kind == InteractionKind.hediyeIste) {
    pool = _hediyeIsteKabul;
  } else if (kind == InteractionKind.paraIste) {
    pool = _paraIsteKabul;
  } else if (kind == InteractionKind.sohbet) {
    // Sohbet de kişiye göre değişir: eşle konuşmakla çocukla konuşmak
    // aynı şey değildir.
    if (person.relation == RelationType.es) {
      pool = _sohbetEs;
    } else if (person.relation == RelationType.cocuk && person.age <= 12) {
      pool = _sohbetCocuk;
    } else {
      pool = _sohbetGenel;
    }
  } else if (person.relation == RelationType.es) {
    pool = _vakitGecirEs;
  } else if (person.relation == RelationType.cocuk) {
    // Çocukla yapılan etkinlik **çocuğun yaşına** göre seçilir.
    if (person.age <= 3) {
      pool = _vakitGecirBebek;
    } else if (person.age <= 12) {
      pool = _vakitGecirCocukKucuk;
    } else if (person.age <= 17) {
      pool = _vakitGecirErgen;
    } else if (!person.inPlayerHousehold) {
      pool = _vakitGecirZiyaret;
    } else {
      pool = _vakitGecirGenel;
    }
  } else if (!person.inPlayerHousehold && playerAge >= 18) {
    // Ayrı evde yaşayan yakınla görüşmek ziyarettir; aynı evdekiyle
    // kurulan gündelik temasla aynı bağlamda anlatılmaz.
    pool = _vakitGecirZiyaret;
  } else if (person.relation == RelationType.kardes) {
    pool = _vakitGecirKardes;
  } else if (_buyukler.contains(person.relation)) {
    pool = _vakitGecirBuyuk;
  } else {
    pool = _vakitGecirGenel;
  }

  final String raw = pool[rng.nextInt(pool.length)];
  final String metin = raw
      .replaceAll('{ad}', person.firstName)
      .replaceAll('{bag}', trLower(person.labelFor(playerAge)));
  // Eşya adı yoksa `{esya}` içeren metin hiç kullanılmaz; yine de ekrana
  // doldurulmamış yer tutucu çıkmasın diye burada da güvenceye alınır.
  return giftName == null
      ? metin.replaceAll('{esya}', 'küçük bir hediye')
      : metin.replaceAll('{esya}', trLower(giftName));
}

/// Verilecek hediye kalmadığında kullanılacak metin.
String noGiftLeftText({
  required Random rng,
  required Person person,
  required int playerAge,
}) =>
    _hediyeKalmadi[rng.nextInt(_hediyeKalmadi.length)]
        .replaceAll('{ad}', person.firstName)
        .replaceAll('{bag}', trLower(person.labelFor(playerAge)));

const Set<RelationType> _buyukler = <RelationType>{
  RelationType.anneanne,
  RelationType.babaanne,
  RelationType.anneTarafiDede,
  RelationType.babaTarafiDede,
};

// =====================================================================
// Hediye tepkileri (D-134)
//
// Doğru hediye sevindirir, yanlış hediye nazikçe geri çevrilir. Metin
// kimseyi utandırmaz ama belli eder (docs/WRITING_STYLE_TR.md §1, §5).
// =====================================================================

/// Hediyeye verilen tepkinin metni.
String giftReactionText({
  required GiftReaction reaction,
  required Person person,
  required GiftItem gift,
}) {
  final String ad = person.firstName;
  switch (reaction) {
    case GiftReaction.sevindi:
      final List<String> secenekler = <String>[
        '$ad paketi açtı, bir an durdu. "Bunu nereden bildin?"',
        '$ad hediyeyi elinde çevirdi çevirdi. Yüzü güldü.',
        '$ad "şey almayacaktın" dedi ama bırakmadı elinden.',
      ];
      return secenekler[gift.name.length % secenekler.length];
    case GiftReaction.idare:
      final List<String> secenekler = <String>[
        '$ad teşekkür etti, kenara koydu.',
        '$ad "eline sağlık" dedi. Fena değildi.',
        '$ad gülümsedi. Uzun bir şey söylemedi.',
      ];
      return secenekler[gift.name.length % secenekler.length];
    case GiftReaction.begenmedi:
      final List<String> secenekler = <String>[
        '$ad "aa, sağ ol" dedi. Sesindeki o küçük boşluğu ikiniz de '
            'duydunuz.',
        '$ad paketi kapattı, masaya bıraktı. Konu değişti.',
        '$ad bir an ne diyeceğini bilemedi. "Güzelmiş" dedi sonunda.',
      ];
      return secenekler[gift.name.length % secenekler.length];
  }
}
