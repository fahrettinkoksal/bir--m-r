/// Hangi ilişki türünde hangi etkileşimlerin **anlamlı** olduğu.
///
/// Bu tablo "kişiye uygun olmayan etkileşimi hiç gösterme" kuralının tek
/// kaynağıdır. Koşullar (para, yakınlık, yaş) ayrıca
/// `FamilyInteractions.availability` içinde denetlenir; burada yalnızca
/// **türün o ilişkide anlamlı olup olmadığı** tutulur.
///
/// Yeni ilişki türü eklendiğinde buraya bir satır eklemek yeterlidir.
/// Tablodaki seçimler `prototypeOnly`'dir (`docs/DESIGN_REVIEW_QUEUE.md`,
/// Q-037).
library;

import '../models/interaction.dart';
import '../models/relation.dart';

const Set<InteractionKind> _temel = <InteractionKind>{
  InteractionKind.vakitGecir,
  InteractionKind.sohbet,
};

const Set<InteractionKind> _aile = <InteractionKind>{
  InteractionKind.vakitGecir,
  InteractionKind.sohbet,
  InteractionKind.hediyeVer,
  InteractionKind.hediyeIste,
  InteractionKind.paraIste,
};

const Set<InteractionKind> _arkadas = <InteractionKind>{
  InteractionKind.vakitGecir,
  InteractionKind.sohbet,
  InteractionKind.hediyeVer,
};

/// Öğretmenle vakit geçirilmez; konuşulur ve uygun durumda hediye verilir.
const Set<InteractionKind> _ogretmen = <InteractionKind>{
  InteractionKind.sohbet,
  InteractionKind.hediyeVer,
};

/// Ayrılıktan sonra hangi etkileşimlerin açık kalacağı henüz
/// kararlaştırılmadı (`docs/PROTOTYPE_UI.md` §4); şimdilik hiçbiri.
const Set<InteractionKind> _yok = <InteractionKind>{};

/// Bir ilişki türünde anlamlı olan etkileşimler.
Set<InteractionKind> meaningfulKindsFor(RelationType relation) {
  switch (relation) {
    case RelationType.anne:
    case RelationType.baba:
    case RelationType.anneanne:
    case RelationType.babaanne:
    case RelationType.anneTarafiDede:
    case RelationType.babaTarafiDede:
    case RelationType.teyze:
    case RelationType.dayi:
    case RelationType.hala:
    case RelationType.amca:
      return _aile;

    case RelationType.kardes:
      // Kardeşten para istemek ayrı bir tasarım konusu (Q-025); şimdilik
      // hediye verme ve isteme açık, para isteme kapalı.
      return const <InteractionKind>{
        InteractionKind.vakitGecir,
        InteractionKind.sohbet,
        InteractionKind.hediyeVer,
        InteractionKind.hediyeIste,
      };

    case RelationType.sinifArkadasi:
      return _temel.union(<InteractionKind>{InteractionKind.hediyeVer});

    case RelationType.ogretmen:
      return _ogretmen;

    case RelationType.arkadas:
    case RelationType.sevgili:
      return _arkadas;

    // İş arkadaşıyla vakit geçirilir ve sohbet edilir; para istemek iş
    // ilişkisinde anlamlı değildir.
    case RelationType.isArkadasi:
      return const <InteractionKind>{
        InteractionKind.vakitGecir,
        InteractionKind.sohbet,
        InteractionKind.hediyeVer,
      };

    // Eşle vakit geçirilir, sohbet edilir, hediyeleşilir; aynı hanede
    // yaşadığınız için "para iste" anlamlı değildir.
    case RelationType.es:
      return const <InteractionKind>{
        InteractionKind.vakitGecir,
        InteractionKind.sohbet,
        InteractionKind.hediyeVer,
        InteractionKind.hediyeIste,
      };

    // Çocukla vakit geçirilir ve hediye verilir; çocuktan hediye ya da
    // para istemek bu prototipte açılmaz (Q-064).
    case RelationType.cocuk:
      return _arkadas;

    // Torunla vakit geçirilir, sohbet edilir ve hediye verilir; torundan
    // para veya hediye istemek anlamlı değildir (Paket 12).
    case RelationType.torun:
      return const <InteractionKind>{
        InteractionKind.vakitGecir,
        InteractionKind.sohbet,
        InteractionKind.hediyeVer,
      };

    case RelationType.eskiSevgili:
    case RelationType.eskiEs:
      return _yok;
  }
}
