/// Süren hamilelik (Paket 26).
library;

import 'package:flutter/foundation.dart';

/// Kim hamile?
enum ExpectingParty {
  /// Oyuncu hamile.
  oyuncu,

  /// Eş ya da sevgili hamile.
  partner,
}

/// Başlamış ve henüz doğumla sonuçlanmamış hamilelik.
///
/// **Kayda girer:** uygulama kapatılıp açılsa da hamilelik kaybolmaz.
/// Doğum, bir sonraki yaş ilerlemesinde gerçekleşir; çocuk bu kayıttaki
/// diğer ebeveynin kimliğiyle üretilir, uydurma bir ebeveyn yazılmaz.
@immutable
class Pregnancy {
  const Pregnancy({
    required this.partnerId,
    required this.startedAtAge,
    required this.expecting,
  });

  /// Diğer biyolojik ebeveynin kalıcı kimliği.
  final String partnerId;

  /// Hamileliğin başladığı yaş.
  final int startedAtAge;

  /// Hamile olan taraf.
  final ExpectingParty expecting;
}

/// Çiftin çocuk planı (Paket BK/2).
///
/// **Q-201:** oyuncu çocuk sahibi olmayı *seçemiyordu*. Tek yol eş ya da
/// sevgili kartından yakınlaşıp "korunmadan" demekti; bu bir niyet
/// olarak hiçbir yere yazılmıyor, ekranda görünmüyor ve ertesi yıl
/// hatırlanmıyordu. Plan, çiftin kararının kaydıdır.
///
/// **Plan ihtimali değiştirmez.** Gebelik sayıları `Intimacy` içinde
/// kalır ve hepsi `prototypeOnly`'dir. Burada yalnızca kimin ne
/// istediği yazılı: ekranda görünür, kayda girer ve yakınlaşmada
/// varsayılan korunma tercihini belirler.
enum FamilyPlan {
  belirsiz('Konuşmadınız', 'Çocuk konusunu henüz konuşmadınız.'),
  istiyor('Çocuk düşünüyoruz', 'Çocuk sahibi olmayı deniyorsunuz.'),
  istemiyor('Şimdilik düşünmüyoruz', 'Şimdilik çocuk düşünmüyorsunuz.');

  const FamilyPlan(this.label, this.description);

  final String label;

  /// Ekranda planın altına yazılan açıklama.
  final String description;

  /// Çift çocuk deniyor mu? Yakınlaşmada varsayılan tercih buna bakar.
  bool get triesForChild => this == istiyor;
}
