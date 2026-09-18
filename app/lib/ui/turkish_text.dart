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
