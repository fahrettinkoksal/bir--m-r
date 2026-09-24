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
  yegen;

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
        return RelationGroup.cekirdek;
      case RelationType.torun:
      case RelationType.yegen:
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
        return RelationGroup.arkadaslar;
      // Faho'nun Q-115 kararı: geri takip eden ünlü arkadaş listesine
      // karışmaz, **kendi başlığında** durur (D-106).
      case RelationType.unlu:
        return RelationGroup.tanidiklar;
      case RelationType.sevgili:
      case RelationType.eskiSevgili:
      case RelationType.eskiEs:
        return RelationGroup.romantik;
    }
  }

  /// Kan bağı olan akraba mı? Okul tanışıklıkları, arkadaşlık ve romantik
  /// bağlar akrabalık değildir.
  ///
  /// **Eş çekirdek ailedendir ama kan bağı değildir**; çocuk ise kan bağıdır.
  bool get kanBagi =>
      this != RelationType.es &&
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
  tanidiklar('Ünlüler ve tanıdıklar');

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
  }
}
