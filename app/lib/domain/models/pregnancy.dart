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
