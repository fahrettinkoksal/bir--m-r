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
