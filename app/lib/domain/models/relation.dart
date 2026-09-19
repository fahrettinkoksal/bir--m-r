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
  arkadas,
  sevgili,
  eskiSevgili;

  /// Aile ekranındaki gruplama. Kesin ekran bölümlemesi henüz
  /// kararlaştırılmadı (`docs/PROTOTYPE_UI.md` §4, açık soru); bu gruplama
  /// prototipin geçici düzenidir.
  RelationGroup get group {
    switch (this) {
      case RelationType.anne:
      case RelationType.baba:
      case RelationType.kardes:
        return RelationGroup.cekirdek;
      case RelationType.anneanne:
      case RelationType.babaanne:
      case RelationType.anneTarafiDede:
      case RelationType.babaTarafiDede:
      case RelationType.teyze:
      case RelationType.dayi:
      case RelationType.hala:
      case RelationType.amca:
        return RelationGroup.genis;
      case RelationType.arkadas:
        return RelationGroup.arkadaslar;
      case RelationType.sevgili:
      case RelationType.eskiSevgili:
        return RelationGroup.romantik;
    }
  }

  /// Kan bağı olan akraba mı? Arkadaşlık ve romantik bağlar akrabalık
  /// değildir.
  bool get kanBagi =>
      group != RelationGroup.romantik && group != RelationGroup.arkadaslar;
}

enum RelationGroup {
  cekirdek('Çekirdek aile'),
  genis('Geniş aile'),
  arkadaslar('Arkadaşlar'),
  romantik('İlişkiler');

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
    case RelationType.arkadas:
      return 'Arkadaş';
    case RelationType.sevgili:
      return gender == Gender.kadin ? 'Kız arkadaş' : 'Erkek arkadaş';
    case RelationType.eskiSevgili:
      return gender == Gender.kadin ? 'Eski kız arkadaş' : 'Eski erkek arkadaş';
  }
}
