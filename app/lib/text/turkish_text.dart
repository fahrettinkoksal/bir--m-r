/// Sayıyı Türkçe binlik ayırıcıyla yazar: 163400 → "163.400".
///
/// Uzun tutarlar ekranda "163400" diye tek blok hâlinde okunmuyordu.
String trNumber(int value) {
  final bool eksi = value < 0;
  final String rakamlar = value.abs().toString();
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < rakamlar.length; i++) {
    if (i > 0 && (rakamlar.length - i) % 3 == 0) buffer.write('.');
    buffer.write(rakamlar[i]);
  }
  return eksi ? '-$buffer' : buffer.toString();
}

/// Para tutarı: 163400 → "163.400 ₺".
String trMoney(int amount) => '${trNumber(amount)} ₺';

/// Dar yerler için **kısaltılmış** para biçimi (Paket 30).
///
/// Karakter başlığındaki cüzdan rozeti gibi yerlerde tam tutar satırı
/// taşırıp adı kırpıyordu ("Tolga Erd…"). 10.000 ₺'ye kadar tam yazılır;
/// üstünde **B** (bin) ve **M** (milyon) kısaltması kullanılır.
///
/// Yalnızca **gösterim** içindir: hesaplarda hiçbir zaman kullanılmaz,
/// tam tutar her zaman cüzdan ekranında görünür.
String trMoneyShort(int amount) {
  final int mutlak = amount.abs();
  if (mutlak < 10000) return trMoney(amount);
  final String isaret = amount < 0 ? '-' : '';
  if (mutlak < 1000000) {
    return '$isaret${_kisalt(mutlak / 1000)} B ₺';
  }
  return '$isaret${_kisalt(mutlak / 1000000)} M ₺';
}

/// Bir ondalık basamakla kısaltır; yuvarlama 100'e taşırsa tam sayıya
/// döner (99.999 ₺ "100,0 B" değil "100 B" olur).
String _kisalt(double deger) {
  final String birOndalik = deger.toStringAsFixed(1);
  if (double.parse(birOndalik) >= 100) {
    return deger.round().toString();
  }
  return birOndalik.replaceAll('.', ',');
}

/// Türkçe'ye uygun büyük harfe çevirme.
///
/// Dart'ın varsayılan `toUpperCase()` çağrısı 'i' harfini 'I' yapar; Türkçe'de
/// doğrusu 'İ'dir ('ı' ise 'I' olur). Başlıklar bu yüzden buradan geçirilir.
String trUpper(String input) {
  final StringBuffer buffer = StringBuffer();
  for (final String ch in input.split('')) {
    switch (ch) {
      case 'i':
        buffer.write('İ');
      case 'ı':
        buffer.write('I');
      default:
        buffer.write(ch.toUpperCase());
    }
  }
  return buffer.toString();
}

/// İlk harfi Türkçe'ye uygun büyütür: "işçi" → "İşçi".
///
/// Dart'ın `toUpperCase()` çağrısı 'i' harfini 'I' yapıyordu; cümle başına
/// gelen "işçi", "ilkokul", "eşin" gibi kelimeler yanlış yazılıyordu.
String trUpperFirst(String input) {
  if (input.isEmpty) return input;
  return trUpper(input[0]) + input.substring(1);
}

/// Cümle içinde kullanmak için ilk harfi Türkçe'ye uygun küçültür.
///
/// Dart'ın `toLowerCase()` çağrısı 'İ' harfini birleşik noktalı 'i̇' yapar;
/// burada doğru karşılıklar kullanılır.
String trLowerFirst(String input) {
  if (input.isEmpty) return input;
  final String ilk = input[0];
  final String kalan = input.substring(1);
  switch (ilk) {
    case 'İ':
      return 'i$kalan';
    case 'I':
      return 'ı$kalan';
    default:
      return ilk.toLowerCase() + kalan;
  }
}

/// Bütün metni Türkçe'ye uygun küçük harfe çevirir.
///
/// Dart'ın `toLowerCase()` çağrısı **'I' harfini 'ı' değil 'i' yapar**:
/// "Işık" → "işık", "IŞIK" → "işik". Oyunda etiketler ("İlkokul",
/// "İş arkadaşı", "İkiz kız kardeşin", şehir ve marka adları) cümle içine
/// girerken küçültülüyor ve bu dönüşümden geçiyordu. Ölçümde bugünkü veri
/// havuzunda görünür bir örneği yoktu; yine de doğru dönüşüm tek yerde
/// toplandı ki 'Isparta' ya da 'Instagram' gibi bir etiket cümleye
/// girdiğinde bozuk yazım çıkmasın (Paket 43).
///
/// ('İ' harfini Dart doğru biçimde 'i' yapıyor; bu işlev o davranışı
/// korur, yalnızca 'I' için doğrusunu yazar.)
String trLower(String input) {
  final StringBuffer buffer = StringBuffer();
  for (final String ch in input.split('')) {
    switch (ch) {
      case 'İ':
        buffer.write('i');
      case 'I':
        buffer.write('ı');
      default:
        buffer.write(ch.toLowerCase());
    }
  }
  return buffer.toString();
}

// =====================================================================
// Özel ada ek getirmek (Paket CT)
// =====================================================================
//
// **Nereden çıktı.** Ekran dökümünün yedinci turu (dul karesi) şu satırı
// bastı: *"Taner artık Malatya'de."* Doğrusu "Malatya'da". Deseni depo
// genelinde taradım ve hata tek yerde değildi: ek, kişi ya da şehir adına
// **sabit** yazılmış yirmiden fazla yer vardı. Yani metin yarı Türkçe
// isimde doğru, yarısında yanlış çıkıyordu:
//
//   "Malatya'ye taşındı" · "Malatya'e taşındın" · "Elif'a sor"
//   "Murat'e para vermedin" · "Elif'a kaldı"
//
// Bu işlevler o işi tek yerde toplar. Özel ada gelen ek Türkçede
// **kesme işaretiyle** ayrılır; harf seçimi iki kurala bakar:
//
// * **Büyük/küçük ünlü uyumu:** son ünlü a, ı, o, u ise **kalın** (a),
//   e, i, ö, ü ise **ince** (e).
// * **Ünsüz benzeşmesi:** sözcük sert ünsüzle bitiyorsa (f, s, t, k, ç,
//   ş, h, p — "FıSTıKÇı ŞaHaP") bulunma ve ayrılma ekinin d'si **t**
//   olur: "Sinop'ta", "Uşak'tan".
// * **Yönelme ekinde kaynaştırma:** ünlüyle biten ada 'ya/'ye gelir:
//   "Malatya'ya", "Bursa'ya".
//
// Ek yapmadan önce ad küçültülmüyor: kesme işaretinden sonrası küçük
// harf, adın kendisi olduğu gibi kalır.

const String _kalinUnluler = 'aıou';
const String _inceUnluler = 'eiöü';
const String _sertUnsuzler = 'fstkçşhp';

/// Adın son ünlüsü kalın mı? Hiç ünlü yoksa kalın sayılır.
bool _kalin(String ad) {
  final String kucuk = trLower(ad);
  for (int i = kucuk.length - 1; i >= 0; i--) {
    final String ch = kucuk[i];
    if (_kalinUnluler.contains(ch)) return true;
    if (_inceUnluler.contains(ch)) return false;
  }
  return true;
}

/// Adın son harfi ünlü mü?
bool _unluylaBitiyor(String ad) {
  if (ad.isEmpty) return false;
  final String son = trLower(ad)[ad.length - 1];
  return _kalinUnluler.contains(son) || _inceUnluler.contains(son);
}

/// Adın son harfi sert ünsüz mü?
bool _sertleBitiyor(String ad) {
  if (ad.isEmpty) return false;
  return _sertUnsuzler.contains(trLower(ad)[ad.length - 1]);
}

/// Özel ada **yönelme** eki: "Malatya'ya", "İzmir'e", "Murat'a".
///
/// Ünlüyle biten adda kaynaştırma y'si gelir.
String trDative(String ad) {
  if (ad.isEmpty) return ad;
  final String ek = _kalin(ad) ? 'a' : 'e';
  return _unluylaBitiyor(ad) ? "$ad'y$ek" : "$ad'$ek";
}

/// Özel ada **bulunma** eki: "Malatya'da", "İzmir'de", "Sinop'ta".
String trLocative(String ad) {
  if (ad.isEmpty) return ad;
  final String d = _sertleBitiyor(ad) ? 't' : 'd';
  return "$ad'$d${_kalin(ad) ? 'a' : 'e'}";
}

/// Özel ada **ayrılma** eki: "Malatya'dan", "İzmir'den", "Uşak'tan".
String trAblative(String ad) {
  if (ad.isEmpty) return ad;
  final String d = _sertleBitiyor(ad) ? 't' : 'd';
  return "$ad'$d${_kalin(ad) ? 'an' : 'en'}";
}
