/// Oyuncunun ve oyundaki kişilerin cinsiyeti.
///
/// D-005 gereği oyuncu ikinci başlangıç modunda yalnızca isim ve cinsiyet
/// seçebilir; kalan başlangıç koşulları rastgele üretilir.
enum Gender {
  kadin('Kadın'),
  erkek('Erkek');

  const Gender(this.label);

  final String label;
}
