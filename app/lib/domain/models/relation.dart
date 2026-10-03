import 'gender.dart';

/// Oyuncu ile bir kişi arasındaki **bağ türü**.
///
/// Bağ türü ile hane (aynı evde yaşamak) ayrı bilgilerdir (D-014).
/// Romantik bağların burada bulunması, o kişilerin kan bağı olan akraba
/// sayıldığı anlamına gelmez (`docs/PROTOTYPE_UI.md` §4).
enum RelationType {
  anne,
  baba,
  kardes,
  anneanne,
  babaanne,
  anneTarafiDede,
  babaTarafiDede,
  teyze,
  dayi,
  hala,
  amca,
  sinifArkadasi,
  ogretmen,
  arkadas,
  // İş arkadaşı: kalıcı kimliği olan, işten ayrılınca kaydı silinmeyen
  // kişi (Paket 9). Arkadaşlığa dönüşebilir.
  isArkadasi,
  sevgili,
  eskiSevgili,
  es,
  eskiEs,
  cocuk,
  // Torun: çocuğun çocuğu (Paket 12). Kalıcı kimliği vardır, kendi
  // yaşını yaşar ve ilişkiler ekranında ayrı listelenir.
  torun,

  // Ünlü: sosyal medyada temas kurulup **karşılık alınmış** bir isim
  // (Faho'nun isteği). Kataloğa yazılı her ünlü burada görünmez;
  // yalnızca geri takip edenler kalıcı kişi olur.
  unlu,

  // Yeğen: kardeşin çocuğu (D-087).
  //
  // Kuşak değişiminde gerekti: eski oyuncunun torunlarından **devam
  // edilen çocuğa ait olanlar** yeni oyuncunun çocuğu olur, diğer
  // çocuklara ait olanlar yeğeni olur. Bu bağ olmasaydı o kayıtlar
  // silinirdi; bu projede kayıt silinmez.
  //
  // Yeni değer listenin **sonuna** eklenir; eski kayıtlar bozulmasın.
  yegen,

  // Flört: tanışıldı, görüşülüyor, ama daha "sevgili" denmedi (D-107).
  //
  // Faho bildirdi: "tanışmak sevgili olmak demek değil". Finger'da
  // buluşmak artık doğrudan sevgili yapmıyor; arada bu basamak var.
  // Flört ilerleyebilir (sevgili olur) ya da biter.
  //
  // Yeni değer listenin **sonuna** eklenir; eski kayıtlar bozulmasın.
  flort,

  // Koğuş arkadaşı: cezaevinde tanışılan kişi (D-140).
  //
  // Tahliyeden sonra kaydı silinmez: içeride tanıştığın adam dışarıda da
  // tanıdığındır. Arkadaşlar öbeğinde listelenir.
  //
  // Yeni değer listenin **sonuna** eklenir; eski kayıtlar bozulmasın.
  kogusArkadasi,

  // Üvey anne / üvey baba (D-141).
  //
  // Faho'nun isteği: "üvey anne baba olabilsin." Ebeveyn boşandıktan ya
  // da öldükten sonra yeniden evlenirse gelen kişi burada durur. Çekirdek
  // ailede listelenir ama **kan bağı değildir**.
  //
  // Yeni değerler listenin **sonuna** eklenir; eski kayıtlar bozulmasın.
  uveyAnne,
  uveyBaba,

  // --- Paket AO: Aile V2 ---------------------------------------------
  //
  // Hepsi listenin **sonuna** eklendi; enum sırası bozulmadı, eski
  // kayıtlar bozulmasın.

  // Üvey kardeş (§9): anne ya da babanın yeni eşinin **önceki**
  // çocuğu. Oyuncuyla **kan bağı yoktur** — ortak biyolojik ebeveyni
  // bulunmaz. Aynı evde büyüyebilir; çekirdek ailede listelenir.
  uveyKardes,

  // Yarım kardeş (§12): anne ya da babanın yeni eşinden doğan çocuk.
  // Üvey kardeşten farkı **kan bağıdır**: oyuncuyla bir biyolojik
  // ebeveyni ortaktır. Miras ve akrabalık kuralları buna göre işler.
  yariKardes,

  // Üvey çocuk (§18): eşin önceki ilişkisinden olan çocuğu. Oyuncunun
  // biyolojik çocuğu **değildir**. Boşanınca kaydı silinmez.
  uveyCocuk,

  // Kayın aile (§21): eşin yaşayan ebeveynleri. Boşanınca kayıt kalır,
  // yalnızca gündelik erişim kapanır.
  kayinvalide,
  kayinpeder,

  // --- Paket AP: aile dramaları ---------------------------------------
  //
  // Listenin **sonuna** eklendi; enum sırası bozulmadı.

  // Çocuğun eşi (§15): gelin ya da damat. Paket AP'ye kadar bu kişi
  // yalnızca `PersonDevelopment.spouseName` içinde bir **isim**di. Artık
  // gerçek bir kişi: onunla vakit geçirilir, torunun biyolojik ebeveyni
  // olabilir ve kuşak devamında yeni oyuncunun **eşi** olur (§62).
  //
  // İçeride cinsiyetten bağımsız; ekrandaki "Gelin"/"Damat" ayrımı
  // etiket üretilirken yapılır.
  cocugunEsi,

  // Çocuğun eski eşi (§21): çocuk boşandığında kayıt **silinmez**.
  // Torunun biyolojik ebeveyniyse soy bağı aynen korunur (§22).
  eskiCocugunEsi;

  /// Aile ekranındaki gruplama. Kesin ekran bölümlemesi henüz
  /// kararlaştırılmadı (`docs/PROTOTYPE_UI.md` §4, açık soru); bu gruplama
  /// prototipin geçici düzenidir.
  RelationGroup get group {
    switch (this) {
      case RelationType.anne:
      case RelationType.baba:
      case RelationType.kardes:
      // Eş ve çocuklar çekirdek ailedir; eski eş ilişki geçmişine düşer.
      case RelationType.es:
      case RelationType.cocuk:
      // Üvey ebeveyn aynı hanede yaşar; çekirdek ailede listelenir
      // (kan bağı sayılmaz, [kanBagi] ayrıca dışlar).
      case RelationType.uveyAnne:
      case RelationType.uveyBaba:
      // Paket AO: üvey/yarım kardeş ve üvey çocuk da çekirdek ailede
      // yaşar. Kan bağı ayrımı [kanBagi] içinde yapılır.
      case RelationType.uveyKardes:
      case RelationType.yariKardes:
      case RelationType.uveyCocuk:
        return RelationGroup.cekirdek;
      // Eşin ailesi kendi başlığında durur (§38): çekirdek aileye
      // karışmaz, geniş aile de değildir.
      case RelationType.kayinvalide:
      case RelationType.kayinpeder:
        return RelationGroup.esinAilesi;
      case RelationType.torun:
      case RelationType.yegen:
      // Paket AP §15: gelin/damat oyuncunun geniş ailesidir. Eski
      // gelin/damat da kayıtta kalır; ilişkiler ekranı onu "Akrabalar"
      // listesine koymaz, çocuğun kartından görünür (§57).
      case RelationType.cocugunEsi:
      case RelationType.eskiCocugunEsi:
        return RelationGroup.genis;
      case RelationType.anneanne:
      case RelationType.babaanne:
      case RelationType.anneTarafiDede:
      case RelationType.babaTarafiDede:
      case RelationType.teyze:
      case RelationType.dayi:
      case RelationType.hala:
      case RelationType.amca:
        return RelationGroup.genis;
      case RelationType.sinifArkadasi:
      case RelationType.ogretmen:
        return RelationGroup.okul;
      case RelationType.arkadas:
      case RelationType.isArkadasi:
      // İçeride tanışılan kişi de arkadaş öbeğinde durur (D-140).
      case RelationType.kogusArkadasi:
        return RelationGroup.arkadaslar;
      // Faho'nun Q-115 kararı: geri takip eden ünlü arkadaş listesine
      // karışmaz, **kendi başlığında** durur (D-106).
      case RelationType.unlu:
        return RelationGroup.tanidiklar;
      case RelationType.sevgili:
      case RelationType.eskiSevgili:
      case RelationType.eskiEs:
      // Flört de romantik bölümde listelenir; henüz sevgili değildir
      // ama arkadaş da değildir (D-107).
      case RelationType.flort:
        return RelationGroup.romantik;
    }
  }

  /// Kan bağı olan akraba mı? Okul tanışıklıkları, arkadaşlık ve romantik
  /// bağlar akrabalık değildir.
  ///
  /// **Eş çekirdek ailedendir ama kan bağı değildir**; çocuk ise kan bağıdır.
  bool get kanBagi =>
      this != RelationType.es &&
      // Üvey ebeveyn çekirdek ailede listelenir ama kan bağı değildir
      // (D-141); kalıtım ve akrabalık kuralları ona uygulanmaz.
      this != RelationType.uveyAnne &&
      this != RelationType.uveyBaba &&
      // Paket AO §9, §18: üvey kardeş ve üvey çocuk da çekirdek ailede
      // listelenir ama **kan bağı değildir**. Yarım kardeş (§12) ise
      // kan bağıdır: bir biyolojik ebeveyn ortaktır, o yüzden burada
      // dışlanmaz.
      this != RelationType.uveyKardes &&
      this != RelationType.uveyCocuk &&
      // Paket AP §15: gelin/damat geniş ailede listelenir ama **kan bağı
      // değildir**. Miras ve kalıtım kuralları onlara işlemez (§66).
      this != RelationType.cocugunEsi &&
      this != RelationType.eskiCocugunEsi &&
      (group == RelationGroup.cekirdek || group == RelationGroup.genis);

  /// Birlikte hane kurulan bağ mı? (Eş ve çocuklar.)
  bool get haneBagi => this == RelationType.es || this == RelationType.cocuk;
}

enum RelationGroup {
  cekirdek('Çekirdek aile'),
  genis('Geniş aile'),
  okul('Okul'),
  arkadaslar('Arkadaşlar'),
  romantik('İlişkiler'),
  // Yeni değerler **listenin sonuna** eklenir; eski kayıtlar bozulmasın.
  tanidiklar('Ünlüler ve tanıdıklar'),
  // Paket AO §38: kayınvalide ve kayınpeder kendi başlığında durur.
  esinAilesi('Eşinin ailesi');

  const RelationGroup(this.title);

  final String title;
}

/// Ekranda gösterilecek bağ etiketi.
///
/// Kardeş etiketi hem cinsiyete hem de oyuncuya göre yaş sırasına bağlıdır;
/// bu yüzden etiket kişi kaydına sabit yazılmaz, burada hesaplanır.
String relationLabel({
  required RelationType relation,
  required Gender gender,
  required int personAge,
  required int playerAge,
}) {
  switch (relation) {
    case RelationType.anne:
      return 'Anne';
    case RelationType.baba:
      return 'Baba';
    case RelationType.kardes:
      if (personAge > playerAge) {
        return gender == Gender.kadin ? 'Abla' : 'Abi';
      }
      if (personAge < playerAge) {
        return gender == Gender.kadin ? 'Küçük kız kardeş' : 'Küçük erkek kardeş';
      }
      return gender == Gender.kadin ? 'İkiz kız kardeş' : 'İkiz erkek kardeş';
    case RelationType.anneanne:
      return 'Anneanne';
    case RelationType.babaanne:
      return 'Babaanne';
    case RelationType.anneTarafiDede:
      return 'Dede (anne tarafı)';
    case RelationType.babaTarafiDede:
      return 'Dede (baba tarafı)';
    case RelationType.teyze:
      return 'Teyze';
    case RelationType.dayi:
      return 'Dayı';
    case RelationType.hala:
      return 'Hala';
    case RelationType.amca:
      return 'Amca';
    case RelationType.sinifArkadasi:
      return 'Sınıf arkadaşı';
    case RelationType.ogretmen:
      return 'Öğretmen';
    case RelationType.arkadas:
      return 'Arkadaş';
    case RelationType.isArkadasi:
      return 'İş arkadaşı';
    case RelationType.flort:
      return 'Flört';
    case RelationType.sevgili:
      return gender == Gender.kadin ? 'Kız arkadaş' : 'Erkek arkadaş';
    case RelationType.eskiSevgili:
      return gender == Gender.kadin ? 'Eski kız arkadaş' : 'Eski erkek arkadaş';
    case RelationType.es:
      return 'Eş';
    case RelationType.eskiEs:
      return 'Eski eş';
    case RelationType.cocuk:
      return gender == Gender.kadin ? 'Kız' : 'Oğul';
    case RelationType.torun:
      return gender == Gender.kadin ? 'Torun (kız)' : 'Torun (erkek)';
    case RelationType.yegen:
      return gender == Gender.kadin ? 'Yeğen (kız)' : 'Yeğen (erkek)';
    case RelationType.unlu:
      return 'Ünlü';
    case RelationType.kogusArkadasi:
      return 'Koğuş arkadaşı';
    case RelationType.uveyAnne:
      return 'Üvey anne';
    case RelationType.uveyBaba:
      return 'Üvey baba';
    case RelationType.uveyKardes:
      return gender == Gender.kadin ? 'Üvey kız kardeş' : 'Üvey erkek kardeş';
    case RelationType.yariKardes:
      // Yaş sırası kardeşte olduğu gibi etikete girer.
      if (personAge > playerAge) {
        return gender == Gender.kadin ? 'Yarım abla' : 'Yarım abi';
      }
      return gender == Gender.kadin
          ? 'Yarım kız kardeş'
          : 'Yarım erkek kardeş';
    case RelationType.uveyCocuk:
      return gender == Gender.kadin ? 'Üvey kız' : 'Üvey oğul';
    case RelationType.kayinvalide:
      return 'Kayınvalide';
    case RelationType.kayinpeder:
      return 'Kayınpeder';
    case RelationType.cocugunEsi:
      return gender == Gender.kadin ? 'Gelin' : 'Damat';
    case RelationType.eskiCocugunEsi:
      return gender == Gender.kadin ? 'Eski gelin' : 'Eski damat';
  }
}

/// Olay ve etkileşim metinlerinde kullanılan **iyelikli** bağ etiketi.
///
/// "Deden Kemal eve bisikletle geldi." gibi cümleler için gereklidir; düz
/// etiket ("Dede (anne tarafı)") cümle içinde kullanılamaz. Dede ve
/// nineler için anne/baba tarafı ayrımı korunur.
String relationPossessive({
  required RelationType relation,
  required Gender gender,
  required int personAge,
  required int playerAge,
}) {
  switch (relation) {
    case RelationType.anne:
      return 'Annen';
    case RelationType.baba:
      return 'Baban';
    case RelationType.kardes:
      if (personAge > playerAge) {
        return gender == Gender.kadin ? 'Ablan' : 'Abin';
      }
      if (personAge < playerAge) {
        return gender == Gender.kadin ? 'Küçük kız kardeşin' : 'Küçük erkek kardeşin';
      }
      return gender == Gender.kadin ? 'İkiz kız kardeşin' : 'İkiz erkek kardeşin';
    case RelationType.anneanne:
      return 'Anneannen';
    case RelationType.babaanne:
      return 'Babaannen';
    case RelationType.anneTarafiDede:
      return 'Anne tarafından deden';
    case RelationType.babaTarafiDede:
      return 'Baba tarafından deden';
    case RelationType.teyze:
      return 'Teyzen';
    case RelationType.dayi:
      return 'Dayın';
    case RelationType.hala:
      return 'Halan';
    case RelationType.amca:
      return 'Amcan';
    case RelationType.sinifArkadasi:
      return 'Sınıf arkadaşın';
    case RelationType.ogretmen:
      return 'Öğretmenin';
    case RelationType.arkadas:
      return 'Arkadaşın';
    case RelationType.isArkadasi:
      return 'İş arkadaşın';
    case RelationType.flort:
      return 'Flörtün';
    case RelationType.sevgili:
      return gender == Gender.kadin ? 'Kız arkadaşın' : 'Erkek arkadaşın';
    case RelationType.eskiSevgili:
      return gender == Gender.kadin ? 'Eski kız arkadaşın' : 'Eski erkek arkadaşın';
    case RelationType.es:
      return 'Eşin';
    case RelationType.eskiEs:
      return 'Eski eşin';
    case RelationType.cocuk:
      return gender == Gender.kadin ? 'Kızın' : 'Oğlun';
    case RelationType.torun:
      return 'Torunun';
    case RelationType.yegen:
      return 'Yeğenin';
    case RelationType.unlu:
      return 'Tanıdığın ünlü';
    case RelationType.kogusArkadasi:
      return 'Koğuş arkadaşın';
    case RelationType.uveyAnne:
      return 'Üvey annen';
    case RelationType.uveyBaba:
      return 'Üvey baban';
    case RelationType.uveyKardes:
      return gender == Gender.kadin
          ? 'Üvey kız kardeşin'
          : 'Üvey erkek kardeşin';
    case RelationType.yariKardes:
      if (personAge > playerAge) {
        return gender == Gender.kadin ? 'Yarım ablan' : 'Yarım abin';
      }
      return gender == Gender.kadin
          ? 'Yarım kız kardeşin'
          : 'Yarım erkek kardeşin';
    case RelationType.uveyCocuk:
      return gender == Gender.kadin ? 'Üvey kızın' : 'Üvey oğlun';
    case RelationType.kayinvalide:
      return 'Kayınvaliden';
    case RelationType.kayinpeder:
      return 'Kayınpederin';
    case RelationType.cocugunEsi:
      return gender == Gender.kadin ? 'Gelinin' : 'Damadın';
    case RelationType.eskiCocugunEsi:
      return gender == Gender.kadin ? 'Eski gelinin' : 'Eski damadın';
  }
}
