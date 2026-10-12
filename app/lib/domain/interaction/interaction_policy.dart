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

import '../family/child_stage.dart';
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

/// Ebeveynlik eylemleri (Paket BK/3).
const Set<InteractionKind> _ebeveynlik = <InteractionKind>{
  InteractionKind.odevYardim,
  InteractionKind.harclikVer,
  InteractionKind.hobiyeYazdir,
  InteractionKind.kuralKoy,
};

/// Çocuğun **kademesinde** anlamlı olan etkileşimler (Paket BK/4).
///
/// Kademeler D-180'den gelir (0-3, 4-12, 13-17, 18+); bu dosyada yeni
/// bir yaş sınırı tanımlanmadı.
///
/// * **Bebek (0-3):** kucağa alınır, konuşulur, oyuncak alınır. Ödev,
///   harçlık, kurs ve kural bu yaşta yoktur — düğme de **görünmez**,
///   çünkü gerekçesiyle kapanan bir düğme bile bebek kartında anlamsız
///   bir satır olurdu.
/// * **Çocuk (4-12) ve ergen (13-17):** ebeveynlik eylemleri açılır.
///   Kademe içindeki ince koşullar (harçlık 7 yaşından, kurs 6
///   yaşından, ödev için okula gitmek) eylemin kendi uygunluk
///   denetiminde durur.
/// * **Yetişkin (18+):** ebeveynlik eylemleri kapanır; yetişkin
///   çocuğa kural konulmaz, harçlık verilmez. Onun yerine kendi kapısı
///   olan **akıl verme** (`ChildAdvice`, 14 yaşından itibaren) var.
Set<InteractionKind> meaningfulKindsForChildStage(ChildStage stage) {
  final Set<InteractionKind> temel = meaningfulKindsFor(RelationType.cocuk);
  return switch (stage) {
    ChildStage.bebek => temel.difference(_ebeveynlik),
    ChildStage.cocuk || ChildStage.ergen => temel,
    ChildStage.yetiskin => temel.difference(_ebeveynlik),
  };
}

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

    // Komşu (Paket BU): kapı komşusuyla sohbet edilir, vakit geçirilir,
    // bayramda bir şey götürülür. Para ya da hediye **istemek** komşuluk
    // ilişkisinde anlamlı değil.
    case RelationType.komsu:
      return const <InteractionKind>{
        InteractionKind.vakitGecir,
        InteractionKind.sohbet,
        InteractionKind.hediyeVer,
      };

    // Eski komşu: taşındın, gündelik temas bitti. Kayıt kalır, liste
    // boş döner (erişilebilirlik de kapalıdır).
    case RelationType.eskiKomsu:
      return const <InteractionKind>{};

    // Ünlüyle gündelik hayatta vakit geçirilmez; temas sosyal medya
    // üzerinden kurulur. Burada yalnızca sohbet anlamlıdır.
    case RelationType.unlu:
      return const <InteractionKind>{InteractionKind.sohbet};

    case RelationType.ogretmen:
      return _ogretmen;

    case RelationType.arkadas:
    case RelationType.sevgili:
    // Flörtle de vakit geçirilir, sohbet edilir, hediye alınır (D-107).
    case RelationType.flort:
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
    // Kendi çocuğu: gündelik etkileşimlerin yanında **ebeveynlik**
    // eylemleri de açıktır (Paket BK/3). Hangisinin hangi **kademede**
    // anlamlı olduğunu [meaningfulKindsForChildStage] söyler; bu tablo
    // yaşı bilmediği için bağda mümkün olan **tüm** türleri döner.
    case RelationType.cocuk:
      return _arkadas.union(_ebeveynlik);

    // Torun ve yeğenle vakit geçirilir, sohbet edilir ve hediye verilir;
    // onlardan para veya hediye istemek anlamlı değildir (Paket 12,
    // D-087).
    case RelationType.torun:
    case RelationType.yegen:
      return const <InteractionKind>{
        InteractionKind.vakitGecir,
        InteractionKind.sohbet,
        InteractionKind.hediyeVer,
      };

    // Koğuş arkadaşıyla vakit geçirilir ve sohbet edilir (D-140).
    // İçeride hediye alışverişi yoktur; dışarıda da bu bağ arkadaşlık
    // gibi işler ama para/hediye kapıları açılmaz.
    case RelationType.kogusArkadasi:
      return const <InteractionKind>{
        InteractionKind.vakitGecir,
        InteractionKind.sohbet,
      };

    // Üvey ebeveynle aynı evde yaşanır: vakit geçirilir, sohbet edilir,
    // hediyeleşilir. Para istemek bağa göre açılır ama başta kapalıdır;
    // bu sürümde aile kapılarının hepsi açık (D-141).
    case RelationType.uveyAnne:
    case RelationType.uveyBaba:
      return _aile;

    // --- Paket AO: Aile V2 -------------------------------------------

    // Üvey ve yarım kardeş: aynı evde büyüyen kardeşlerdir. Biyolojik
    // kardeşle aynı kapılar açılır — ikisi arasındaki fark kan bağında
    // ve mirastadır, gündelik ilişkide değil (§11).
    case RelationType.uveyKardes:
    case RelationType.yariKardes:
      return const <InteractionKind>{
        InteractionKind.vakitGecir,
        InteractionKind.sohbet,
        InteractionKind.hediyeVer,
        InteractionKind.hediyeIste,
      };

    // Üvey çocuk: çocukla aynı kapılar. Bağ **düşük başlar** ve zamanla
    // kurulur (§20); açık olan kapı bağın kendisini hazır vermez.
    case RelationType.uveyCocuk:
      return _arkadas;

    // Kayınvalide / kayınpeder (§23): vakit geçirilir, sohbet edilir,
    // hediye verilir. **Para istemek açılmaz** — brief bunu bu pakette
    // bilerek dışarıda bıraktı, yüksek yakınlıkta ayrı bir karar konusu.
    case RelationType.kayinvalide:
    case RelationType.kayinpeder:
      return const <InteractionKind>{
        InteractionKind.vakitGecir,
        InteractionKind.sohbet,
        InteractionKind.hediyeVer,
      };

    // --- Paket AP: aile dramaları ------------------------------------

    // Gelin / damat (§24): vakit geçirilir, sohbet edilir, hediye
    // verilir. **Para/hediye istemek açılmaz** — çocuğunun eşinden para
    // istemek bu sürümün tasarladığı bir ilişki değil.
    //
    // Bağ otomatik iyi ya da otomatik kötü değildir (§24): açılan kapı
    // yakınlığı hazır vermez, zamanla kurulur.
    case RelationType.cocugunEsi:
      return _arkadas;

    // Çocuk boşandıktan sonra eski gelin/damat ile gündelik etkileşim
    // kapanır (§21): kayıt kalır, kapı kapanır. Torunun ebeveyniyse soy
    // bağı yine korunur ama bu bir etkileşim hakkı değil.
    case RelationType.eskiCocugunEsi:
      return _yok;

    case RelationType.eskiSevgili:
      return _yok;

    // Paket AO §25: eski eşle **gündelik** yakınlık etkileşimleri hâlâ
    // kapalı — boşandınız, her şey eskisi gibi değil. Ama ortak çocuk
    // varsa iletişim tamamen bitmez: çocuk hakkında konuşulur.
    //
    // Ortak çocuğun olup olmadığı burada bilinemez (bu işlev yalnızca
    // bağ türünü görür); tür **anlamlı** sayılır ve gerçek koşul
    // `FamilyInteractions.availability` içinde denetlenir.
    case RelationType.eskiEs:
      return const <InteractionKind>{InteractionKind.cocukKonus};
  }
}
