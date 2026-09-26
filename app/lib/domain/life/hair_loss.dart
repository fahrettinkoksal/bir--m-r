/// Erkeklerde yaşa bağlı saç dökülmesi (D-073).
///
/// **Neden var:** Faho istedi — "erkek kullanıcılarının ihtimal dahilinde
/// 30 yaşından sonra saçları dökülmeye başlayabilir, bu da karizmayı
/// etkileyebilir".
///
/// **Oranlar nereden geliyor:** Androjenetik alopesi için yaygın kabul
/// gören epidemiyolojik özet, erkeklerin kabaca **%30'unun 30'lu,
/// %50'sinin 50'li yaşlarda** belirgin dökülme yaşadığıdır; oran ileri
/// yaşta çok daha yükselir. Buradaki yıllık başlama ihtimali, oyunun
/// başlangıç yaşı olan 30'dan itibaren **50 yaşında yaklaşık %50 birikimli
/// ihtimal** verecek biçimde seçildi.
///
/// **Bilerek yapılan sadeleştirme:** Gerçek hayatta dökülme çoğu zaman
/// 20'li yaşlarda başlar. Oyunda başlangıç yaşı 30'dur; bu bir tıbbi iddia
/// değil, Faho'nun onayladığı bir tasarım tercihidir. Daha erken başlangıç
/// tasarım kuyruğunda soru olarak duruyor (Q-117).
///
/// **Karizma etkisi bir yargı değildir:** Etki, karakterin kendi
/// alışma dönemini temsil eder ve **bakım yapan oyuncuda yarıya iner**;
/// kalıcı ve kaçınılmaz bir ceza değildir. Bütün sayılar `prototypeOnly`.
library;

import 'dart:math';

import '../generation/random_util.dart';
import '../models/gender.dart';

/// Saç dökülmesinin bir yıldaki değişimi.
class HairLossStep {
  const HairLossStep({
    required this.stage,
    required this.appearance,
    required this.charisma,
    this.note,
  });

  /// Yılın sonundaki basamak.
  final int stage;

  /// Bu yıl uygulanacak görünüş değişimi (0 veya negatif).
  final int appearance;

  /// Bu yıl uygulanacak karizma değişimi (0 veya negatif).
  final int charisma;

  /// Oyuncuya gösterilecek kısa cümle; yoksa `null`.
  final String? note;

  bool get changed => appearance != 0 || charisma != 0;
}

abstract final class HairLoss {
  /// Oyunda dökülmenin başlayabileceği en küçük yaş.
  static const int prototypeOnlyStartAge = 30;

  /// En ileri basamak.
  static const int maxStage = 3;

  /// Yıllık **başlama** ihtimali.
  ///
  /// 30-49 arası %3,4: yirmi yılın sonunda birikimli ihtimal
  /// `1 - 0,966^20 ≈ 0,50`, yani 50 yaşında erkeklerin yaklaşık yarısı.
  static double prototypeOnlyOnsetChance(int age) {
    if (age < prototypeOnlyStartAge) return 0;
    if (age < 50) return 0.034;
    return 0.039;
  }

  /// Başlamış dökülmenin bir sonraki basamağa geçme ihtimali.
  static const double prototypeOnlyProgressChance = 0.12;

  /// Basamağa ilk geçildiği yıl uygulanan görünüş kaybı.
  ///
  /// Faho'nun Q-117 kararı: saç **görünüşü** etkiler, karizmayı değil.
  /// Eski karizma kaybı buraya taşındı; toplam ağırlık korundu, yalnızca
  /// hangi değere yazıldığı değişti.
  static const List<int> prototypeOnlyAppearanceCost = <int>[0, 3, 4, 5];

  /// Karizma kaybı **yoktur** (Q-117 kararı).
  ///
  /// Saçın dökülmesi karakterin insanlarla kurduğu ilişkiyi değiştirmez;
  /// aynada gördüğü şeyi değiştirir. Alan, eski kayıtlarla ve çağrı
  /// noktalarıyla uyum için duruyor ve hep sıfırdır.
  static const List<int> prototypeOnlyCharismaCost = <int>[0, 0, 0, 0];

  /// Bakım yapan oyuncuda kaybın çarpanı.
  ///
  /// Saçı dökülen ama kendine bakan karakter bunu daha kolay taşır.
  static const double prototypeOnlyGroomedFactor = 0.5;

  /// Bu karakterde saç dökülmesi işletilir mi?
  ///
  /// İlk kapsamda yalnızca erkek karakterlerde; kadınlarda yaşa bağlı
  /// seyrelme gerçektir ama ayrı bir tasarım kararı gerektirir (Q-117).
  static bool applies(Gender gender) => gender == Gender.erkek;

  /// Bir yılın adımını hesaplar.
  ///
  /// [groomedRecently] son yıllarda berbere/kuaföre gidildiğini bildirir.
  static HairLossStep step({
    required Gender gender,
    required int age,
    required int stage,
    required bool groomedRecently,
    required Random rng,
  }) {
    if (!applies(gender) || age < prototypeOnlyStartAge || stage >= maxStage) {
      return HairLossStep(stage: stage, appearance: 0, charisma: 0);
    }

    final bool ilerledi = stage == 0
        ? rng.chance(prototypeOnlyOnsetChance(age))
        : rng.chance(prototypeOnlyProgressChance);
    if (!ilerledi) {
      return HairLossStep(stage: stage, appearance: 0, charisma: 0);
    }

    final int yeni = stage + 1;
    final double carpan = groomedRecently ? prototypeOnlyGroomedFactor : 1.0;
    final int gorunus = -(prototypeOnlyAppearanceCost[yeni] * carpan).round();
    final int karizma = -(prototypeOnlyCharismaCost[yeni] * carpan).round();

    return HairLossStep(
      stage: yeni,
      appearance: gorunus,
      charisma: karizma,
      note: noteFor(yeni),
    );
  }

  /// Basamağa geçildiği yıl gösterilecek cümle.
  static String noteFor(int stage) {
    switch (stage) {
      case 1:
        return 'Tarakta eskisinden fazla saç kalıyor; şakaklar biraz '
            'açılmış.';
      case 2:
        return 'Saçın belirgin biçimde açıldı; fotoğraflarda fark '
            'ediliyor.';
      case 3:
        return 'Saçların büyük ölçüde döküldü.';
      default:
        return '';
    }
  }

  /// Durumun ekranda okunacak adı.
  static String label(int stage) {
    switch (stage) {
      case 1:
        return 'Saçlarda seyrelme';
      case 2:
        return 'Belirgin saç dökülmesi';
      case 3:
        return 'İleri derecede saç dökülmesi';
      default:
        return 'Saçlar yerinde';
    }
  }
}
