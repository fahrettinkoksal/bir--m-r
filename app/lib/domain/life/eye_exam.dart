/// Göz muayenesi mini oyunu (D-076).
///
/// **Neden var:** Faho bildirdi — "sağlıkta göz muayenesine tıkladım,
/// direkt altta ufak bir bildirim yerine küçük bir oyun oynatmalıyız,
/// yan yana 5'lerin arasında S'yi bulmak gibi".
///
/// Muayene tek tıkla biten bir sayı artışıydı. Artık oyuncu gerçekten
/// **bakıyor**: satırlar küçüldükçe zorlaşan bir tabloda, birbirine
/// benzeyen karakterlerin arasındaki **farklı olanı** buluyor.
///
/// **Bu bir görme testi değildir.** Ekranın boyutu, parlaklığı ve
/// oturma mesafesi bilinmeden görme keskinliği ölçülemez. Oyun bunu
/// ölçtüğünü iddia etmez; sonuç oyun içi bir muayene sonucudur ve
/// karakterin gözünü **oyuncunun dikkatinden bağımsız olarak** yaşa ve
/// sağlığa göre de değerlendirir.
library;

import 'dart:math';

/// Tablodaki tek bir satır.
class EyeExamRow {
  const EyeExamRow({
    required this.characters,
    required this.oddIndex,
    required this.fontSize,
  });

  /// Satırdaki karakterler.
  final List<String> characters;

  /// Diğerlerinden farklı olanın sırası.
  final int oddIndex;

  /// Bu satırın yazı boyutu; aşağı indikçe küçülür.
  final double fontSize;

  String get odd => characters[oddIndex];
}

/// Bir muayenenin tablosu.
class EyeExamPuzzle {
  const EyeExamPuzzle({required this.rows});

  final List<EyeExamRow> rows;

  int get length => rows.length;
}

abstract final class EyeExam {
  /// Satır sayısı.
  static const int rowCount = 5;

  /// Birbirine benzeyen karakter çiftleri.
  ///
  /// İlk karakter satırı doldurur, ikincisi aranan farklı olandır.
  /// Çiftler bilerek **benzer** seçildi; farkı görmek dikkat ister.
  static const List<List<String>> lookalikes = <List<String>>[
    <String>['5', 'S'],
    <String>['O', '0'],
    <String>['1', 'I'],
    <String>['8', 'B'],
    <String>['6', 'G'],
    <String>['2', 'Z'],
    <String>['C', 'G'],
    <String>['E', 'F'],
  ];

  /// Satır uzunlukları: aşağı indikçe daha çok karakter, daha küçük punto.
  static const List<int> rowLengths = <int>[5, 7, 9, 11, 13];
  static const List<double> rowFontSizes = <double>[34, 28, 22, 17, 13];

  /// Yeni bir tablo üretir.
  static EyeExamPuzzle generate(Random rng) {
    final List<EyeExamRow> satirlar = <EyeExamRow>[];
    for (int i = 0; i < rowCount; i++) {
      final List<String> cift = lookalikes[rng.nextInt(lookalikes.length)];
      final int uzunluk = rowLengths[i];
      final int farkli = rng.nextInt(uzunluk);
      satirlar.add(
        EyeExamRow(
          characters: List<String>.unmodifiable(<String>[
            for (int k = 0; k < uzunluk; k++) k == farkli ? cift[1] : cift[0],
          ]),
          oddIndex: farkli,
          fontSize: rowFontSizes[i],
        ),
      );
    }
    return EyeExamPuzzle(rows: List<EyeExamRow>.unmodifiable(satirlar));
  }

  /// Oyuncunun kaç satırı doğru bulduğuna göre sonuç metni.
  ///
  /// Metin **oyuncunun performansını** anlatır; karakterin gözü ayrıca
  /// yaşa ve sağlığa göre değerlendirilir (bkz. [sightNote]).
  static String scoreText(int correct, int total) {
    if (correct == total) {
      return 'Bütün satırları okudun. Hekim "en alt satırı da gördün, '
          'nadir olur" dedi.';
    }
    if (correct >= total - 1) {
      return '$total satırın $correct tanesini okudun. Sonuç iyi.';
    }
    if (correct >= total ~/ 2) {
      return '$total satırın $correct tanesini okudun. Alt satırlarda '
          'zorlandın.';
    }
    return '$total satırın $correct tanesini okudun. Hekim bir de '
        'numara ölçümü yapmak istedi.';
  }

  /// Karakterin gözünün yaşa ve sağlığa göre değerlendirmesi.
  ///
  /// Mini oyunda iyi oynamak karakterin gözünü **iyileştirmez**: kırk
  /// yaşından sonra yakını görmek zorlaşır, oyuncunun dikkati bunu
  /// değiştirmez. İki bilgi ayrı ayrı gösterilir ki oyuncu yanılmasın.
  static String sightNote({required int age, required int health}) {
    if (age >= 60 && health < 60) {
      return 'Hekim: yaşınla birlikte hem yakın hem uzak görmede '
          'azalma var; gözlük numaran değişmiş.';
    }
    if (age >= 45) {
      return 'Hekim: yakını görmede yaşa bağlı azalma başlamış. '
          'Okuma gözlüğü işini kolaylaştırır.';
    }
    if (health < 45) {
      return 'Hekim: gözlerin yorgun; ekran süresini ve uykunu sordu.';
    }
    return 'Hekim: gözlerinde bir sorun görünmüyor.';
  }

  /// Muayenenin sağlığa katkısı.
  ///
  /// Mini oyunun sonucu **sağlığı değiştirmez**; muayene olmanın kendisi
  /// küçük bir katkıdır. Oyuncu iyi oynadı diye karakteri sağlıklı
  /// olmaz.
  static const int prototypeOnlyHealthGain = 2;
}
