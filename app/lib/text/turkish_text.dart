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
