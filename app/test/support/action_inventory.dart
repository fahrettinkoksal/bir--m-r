// Paket AI — oyuncu aksiyonu envanteri.
//
// **Bu liste elle tutulmuyor.** `lib/state/game_controller.dart` test
// çalışırken okunuyor ve üyeler koddan çıkarılıyor; yeni bir aksiyon
// eklendiğinde envanter kendiliğinden büyür ve kapsam yüzdesi düşer.
// Elle yazılmış bir liste, unutulduğu gün yalan söylemeye başlar.
//
// Sınıflandırma kuralı **davranışa** bakar, isme değil:
//
// * **Aksiyon:** gövdesi `_state = …` atıyor, `notifyListeners()` ya da
//   `_autoSave()` çağırıyor — ya da bunu yapan başka bir üyeyi çağırıyor.
//   Yani oyunun durumunu değiştirebilen her şey.
// * **Sorgu:** durumu okur, değiştirmez (`…Availability`, `…BlockReason`,
//   fiyat/önizleme/liste döndürenler).
// * **Test/hayat yönetimi:** oyunun içindeki bir hamle değil
//   (`debugSetState`, `startNewLife`, kayıt işlemleri, ayarlar).
library;

import 'dart:io';

/// Bir üyenin ne olduğu.
enum ActionKind {
  /// Oyuncunun oynarken yaptığı, durumu değiştiren hamle.
  action,

  /// Durumu okuyan yardımcı; kapsam yüzdesine girmez.
  query,

  /// Oyun içi hamle değil: hata ayıklama, kayıt, ayar, hayat açma.
  outOfGame,
}

/// Envanterdeki tek üye.
class ControllerMember {
  const ControllerMember(this.name, this.returnType, this.line, this.kind);

  final String name;
  final String returnType;
  final int line;
  final ActionKind kind;
}

/// Oyun içi hamle sayılmayan üyeler ve **neden**.
///
/// Her biri tek tek okunup karar verildi; bu yüzden gerekçesiyle birlikte
/// duruyor. Liste kısa tutuldu: şüphede kalan üye aksiyon sayılır, çünkü
/// kapsamı olduğundan iyi göstermek en kötü hatadır.
const Map<String, String> kOutOfGameMembers = <String, String>{
  'debugSetState': 'yalnızca test; oyuncu yolu değil',
  'ensureUniversityExamScore': 'yalnızca test kurulum yardımcısı',
  'startNewLife': 'hayat açma; oyunun içindeki bir hamle değil',
  'clearLife': 'hayatı kapatma',
  'continueAsChild': 'ölüm sonrası yeni hayat açma',
  'updateSettings': 'uygulama ayarı, oyun hamlesi değil',
  'flushSaves': 'kayıt altyapısı',
  'deleteSavedLife': 'kayıt altyapısı',
  'restoreSavedLife': 'kayıt altyapısı',
  'checkForSavedLife': 'kayıt altyapısı',
  'dispose': 'Flutter yaşam döngüsü',
};

final RegExp _uyePattern = RegExp(
  r'^  (?!//|/\*|\*|@)(?:static\s+)?([A-Za-z_][\w<>,\s\?\[\]\.\(\)$]*?)\s+'
  r'([a-z_]\w*)\s*\(',
  multiLine: true,
);

final RegExp _atama = RegExp(r'_state\s*=(?!=)');
final RegExp _cagri = RegExp(r'\b(\w+)\s*\(');

/// Üyenin gövdesini alır (`=> …;` ya da `{ … }`).
String _govde(String src, int imzaSonu) {
  int derinlik = 0;
  int j = imzaSonu;
  while (j < src.length) {
    if (src[j] == '(') derinlik++;
    if (src[j] == ')') {
      derinlik--;
      if (derinlik == 0) break;
    }
    j++;
  }
  int k = j + 1;
  while (k < src.length && (src[k] == ' ' || src[k] == '\n' || src[k] == '\t')) {
    k++;
  }
  if (k + 1 < src.length && src.substring(k, k + 2) == '=>') {
    final int son = src.indexOf(';', k);
    return son < 0 ? '' : src.substring(k, son);
  }
  if (k < src.length && src[k] == '{') {
    int d = 0;
    int e = k;
    while (e < src.length) {
      if (src[e] == '{') d++;
      if (src[e] == '}') {
        d--;
        if (d == 0) break;
      }
      e++;
    }
    return src.substring(k, e + 1);
  }
  return '';
}

List<ControllerMember>? _onbellek;

/// `GameController`'ın bütün public üyeleri, koddan üretilmiş.
List<ControllerMember> controllerInventory() {
  if (_onbellek != null) return _onbellek!;
  final File dosya = File('lib/state/game_controller.dart');
  if (!dosya.existsSync()) {
    throw StateError(
      'game_controller.dart bulunamadı (çalışma dizini: '
      '${Directory.current.path}). Envanter koddan üretiliyor; dosya '
      'olmadan kapsam ölçülemez.',
    );
  }
  final String src = dosya.readAsStringSync();

  final Map<String, ({String ret, int line, String body})> uyeler =
      <String, ({String ret, int line, String body})>{};
  for (final RegExpMatch m in _uyePattern.allMatches(src)) {
    final String ret = m.group(1)!.trim();
    final String ad = m.group(2)!;
    final List<String> parcalar = ret.split(RegExp(r'\s+'));
    if (parcalar.isNotEmpty &&
        <String>{'get', 'set', 'return', 'await'}.contains(parcalar.last)) {
      continue;
    }
    if (uyeler.containsKey(ad)) continue;
    final String govde = _govde(src, m.end - 1);
    final int satir = '\n'.allMatches(src.substring(0, m.start)).length + 1;
    uyeler[ad] = (ret: ret, line: satir, body: govde);
  }

  // Durumu **doğrudan** değiştirenler.
  final Set<String> degistiren = <String>{
    for (final MapEntry<String, ({String ret, int line, String body})> e
        in uyeler.entries)
      if (_atama.hasMatch(e.value.body) ||
          e.value.body.contains('notifyListeners()') ||
          e.value.body.contains('_autoSave()'))
        e.key,
  };
  // Değiştiren birini çağıran da değiştirir. Zincir birkaç kat derin
  // olabildiği için sabit noktaya kadar yayılıyor.
  bool buyudu = true;
  while (buyudu) {
    buyudu = false;
    for (final MapEntry<String, ({String ret, int line, String body})> e
        in uyeler.entries) {
      if (degistiren.contains(e.key)) continue;
      for (final RegExpMatch c in _cagri.allMatches(e.value.body)) {
        final String cagrilan = c.group(1)!;
        if (cagrilan != e.key && degistiren.contains(cagrilan)) {
          degistiren.add(e.key);
          buyudu = true;
          break;
        }
      }
    }
  }

  final List<ControllerMember> sonuc = <ControllerMember>[];
  for (final MapEntry<String, ({String ret, int line, String body})> e
      in uyeler.entries) {
    if (e.key.startsWith('_')) continue;
    final ActionKind tur = kOutOfGameMembers.containsKey(e.key)
        ? ActionKind.outOfGame
        : degistiren.contains(e.key)
            ? ActionKind.action
            : ActionKind.query;
    sonuc.add(ControllerMember(e.key, e.value.ret, e.value.line, tur));
  }
  sonuc.sort((ControllerMember a, ControllerMember b) =>
      a.name.compareTo(b.name));
  _onbellek = sonuc;
  return sonuc;
}

/// Kapsam yüzdesinin paydası: oyuncunun oyun içinde yapabildiği hamleler.
List<String> playerActions() => <String>[
      for (final ControllerMember m in controllerInventory())
        if (m.kind == ActionKind.action) m.name,
    ];

// =====================================================================
// Çağrı kaydı
// =====================================================================

/// Bir aksiyonun test sırasında ne olduğunu tutar.
class ActionRecord {
  int attempts = 0;
  int applied = 0;

  /// Engellendiyse son görülen gerekçe.
  String lastBlock = '';
}

/// Coverage/abuse botlarının çağırdığı aksiyonların kaydı.
///
/// Bot her çağrıyı buradan geçirir; böylece "hangi aksiyon gerçekten
/// çalıştı" sorusu tahminle değil kayıtla cevaplanır.
class ActionLog {
  final Map<String, ActionRecord> records = <String, ActionRecord>{};

  /// Bir aksiyonu dener ve sonucunu kaydeder.
  ///
  /// [uygulandi] cagrinin gerçekten bir şey değiştirip değiştirmediğini
  /// söyler; `null` dönen ya da engellenen çağrı **denendi** sayılır ama
  /// **kapsandı** sayılmaz.
  T call<T>(String ad, T Function() govde, {bool Function(T)? uygulandi}) {
    final ActionRecord r = records.putIfAbsent(ad, ActionRecord.new);
    r.attempts++;
    final T sonuc = govde();
    final bool oldu = uygulandi == null ? sonuc != null : uygulandi(sonuc);
    if (oldu) r.applied++;
    return sonuc;
  }

  /// `applied` alanı taşıyan sonuç nesneleri için.
  ///
  /// Varsayılan ölçüt "null değilse oldu" der; ama oyunun `…Outcome`
  /// sınıfları **başarısız** sonucu da nesne olarak döndürüyor (ör.
  /// reddedilen üniversite başvurusu `applied: true, accepted: false`).
  /// Bu yüzden kapsam sayısı nesnenin kendi bayrağından okunuyor:
  /// "çağırdım" ile "oldu" karıştırılmasın.
  T? outcome<T extends Object>(String ad, T? Function() govde) => call<T?>(
        ad,
        govde,
        uygulandi: (T? v) {
          if (v == null) return false;
          bool oldu;
          try {
            oldu = (v as dynamic).applied == true;
          } on NoSuchMethodError {
            return true;
          }
          if (!oldu) {
            // Oyunun kendi gerekçesini sakla: "neden olmadı" sorusunu
            // tahminle değil, oyunun cümlesiyle cevaplayalım.
            try {
              final Object? metin = (v as dynamic).text;
              if (metin is String) blocked(ad, metin);
            } on NoSuchMethodError {
              // Metni yoksa gerekçe de yok.
            }
          }
          return oldu;
        },
      );

  /// Engellenme gerekçesini not eder.
  void blocked(String ad, String neden) {
    final ActionRecord r = records.putIfAbsent(ad, ActionRecord.new);
    if (neden.isNotEmpty) r.lastBlock = neden;
  }

  /// Gerçekten çalışan aksiyonlar.
  Set<String> get covered => <String>{
        for (final MapEntry<String, ActionRecord> e in records.entries)
          if (e.value.applied > 0) e.key,
      };

  /// Denenip hiç çalışmayan aksiyonlar.
  Set<String> get attemptedOnly => <String>{
        for (final MapEntry<String, ActionRecord> e in records.entries)
          if (e.value.applied == 0) e.key,
      };

  void merge(ActionLog other) {
    for (final MapEntry<String, ActionRecord> e in other.records.entries) {
      final ActionRecord r = records.putIfAbsent(e.key, ActionRecord.new);
      r.attempts += e.value.attempts;
      r.applied += e.value.applied;
      if (e.value.lastBlock.isNotEmpty) r.lastBlock = e.value.lastBlock;
    }
  }
}
