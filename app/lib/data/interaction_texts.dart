/// Etkileşim sonuç metinleri.
///
/// Metinler bu projeye özgü yazılmıştır. `{ad}` kişinin adıyla, `{bag}` ise
/// küçük harfli bağ etiketiyle (anne, abla, dede ...) değiştirilir.
library;

import 'dart:math';

import '../domain/models/interaction.dart';
import '../domain/models/person.dart';
import '../domain/models/relation.dart';

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

/// Kişi ve etkileşim türüne uygun bir metin seçer.
String interactionText({
  required Random rng,
  required Person person,
  required InteractionKind kind,
  required bool accepted,
  required bool noNewBenefit,
  required int playerAge,
}) {
  final List<String> pool;
  if (!accepted) {
    pool = _redGenel;
  } else if (noNewBenefit) {
    pool = _doyumGenel;
  } else if (kind == InteractionKind.sohbet) {
    pool = _sohbetGenel;
  } else if (person.relation == RelationType.kardes) {
    pool = _vakitGecirKardes;
  } else if (_buyukler.contains(person.relation)) {
    pool = _vakitGecirBuyuk;
  } else {
    pool = _vakitGecirGenel;
  }

  final String raw = pool[rng.nextInt(pool.length)];
  return raw
      .replaceAll('{ad}', person.firstName)
      .replaceAll('{bag}', person.labelFor(playerAge).toLowerCase());
}

const Set<RelationType> _buyukler = <RelationType>{
  RelationType.anneanne,
  RelationType.babaanne,
  RelationType.anneTarafiDede,
  RelationType.babaTarafiDede,
};
