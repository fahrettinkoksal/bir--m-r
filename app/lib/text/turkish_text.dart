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
