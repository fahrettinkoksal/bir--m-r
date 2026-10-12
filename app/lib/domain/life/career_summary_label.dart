/// Ömür sonunda yazılan **meslek satırının tek kaynağı** (Paket DH).
///
/// **Neden ayrı bir dosya.** Paket DF ömür sonu özetinde "Son iş:
/// Çalışmıyor" hatasını düzeltti: satır `career.label` okuyordu ve o
/// alan **bugünkü** işi söyler (`job?.name ?? 'Çalışmıyor'`), ölmüş bir
/// oyuncuda ise bugünkü iş yok. Ama aynı zincirin **ikinci bir kopyası**
/// `GameController._archiveWithCurrentLife()` içinde duruyordu ve o
/// kopya düzeltilmedi: Geçmiş Hayatlar arşivine üç hayatın üçünde de
/// "Meslek: Son iş: Çalışmıyor" yazıldı — hem de kayıt dosyasına
/// **kalıcı** olarak (Paket DH dökümü).
///
/// Kusurun kökü yazım hatası değil **kopyaydı**. Bu yüzden zincir tek
/// yere taşındı; iki çağıran da buradan okur ve bir daha ayrı ayrı
/// düzeltilmesi gerekmez.
library;

import '../models/combat_career.dart';
import '../models/game_state.dart';

abstract final class CareerSummaryLabel {
  /// Hiç çalışılmamış hayat için yazılan metin.
  static const String calismadi = 'Çalışmadı';

  /// Ömür sonu özetinde ve arşivde görünen meslek satırı.
  ///
  /// Sıra bilinçli: **çalışıyorsa** bugünkü iş, değilse **geçmişten**
  /// okunan son iş, o da yoksa emeğin geçtiği yer (saha, ring, kendi
  /// dükkânı). Hiçbiri yoksa "Çalışmadı".
  static String of(GameState state) {
    if (state.career.isEmployed) return state.career.label;
    // "Son iş:" öneki **bilerek duruyor** (Paket DF): "Aşçı" ile
    // "Son iş: Aşçı" farklı şeyler söyler — ikincisi oyuncunun
    // ölürken çalışmadığını da anlatır. Düzeltirken öneki de
    // düşürmüştüm; o zaman emekli bir hayat ile çalışan bir hayat
    // aynı görünüyordu.
    final String? sonIs = state.career.lastJobLabel;
    if (sonIs != null) return 'Son iş: $sonIs';
    // Sporcuya ve kendi işini kurmuş olana "Çalışmadı" yazılmaz
    // (AY/3, AY/5 ve DF): o hayatın emeği başka yerde geçti.
    if ((state.footballCareer?.proSeasons ?? 0) > 0) {
      return 'Profesyonel futbolcu';
    }
    if (_dovusenVar(state)) return 'Dövüş sporcusu';
    if (state.businesses.isNotEmpty) return 'Kendi işini kurdu';
    return calismadi;
  }

  static bool _dovusenVar(GameState state) => state.combatCareers.any(
        (CombatCareer k) =>
            k.amateurWins + k.amateurLosses + k.proWins + k.proLosses > 0,
      );
}
