// Paket AR/2 — hikâye rolü bekçisi.
//
// Bulunan gerçek hata: bir seçim `rememberPersonAs` ile kişiyi hikâye
// rolüne kilitlemek isteyebilir, ama motor rolü yalnızca olayın bir
// **kişisi varsa** kaydeder:
//
//     storyPeople: choice.rememberPersonAs == null || bondTargetId == null
//         ? working.storyPeople
//         : {...working.storyPeople, choice.rememberPersonAs!: bondTargetId}
//
// `bondTargetId` ya o seçimin ürettiği kişiden (`startsRomance`,
// `startsFriendship`, `startsSchoolFriendship`) ya da olayın kendi
// kişisinden gelir. İkisi de yoksa rol **sessizce** kaydedilmez ve o rolü
// arayan bütün devam halkaları ömür boyu ölü kalır.
//
// Üç suç zincirinin ilk halkası tam bu durumdaydı: seçimlerde
// `rememberPersonAs` vardı ama olayların hiç kişi koşulu yoktu. 40 kapsam
// hayatında dört devam olayı bir kez bile aday havuza giremedi.
//
// Bu test o sessizliği gürültüye çevirir: rol kilitleyen bir seçim
// yazıldıysa o olayın kişisi de olmalı.
library;

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Olayın bir kişisi olabilir mi?
///
/// Motorun `_resolvePerson` yolları: hikâye rolü, bağ türü, ihmal edilen
/// yakın, gezi anısı, iş arkadaşı, kişi yaş aralığı… Seçim kendi kişisini
/// üretiyorsa (`startsRomance`, `startsFriendship`,
/// `startsSchoolFriendship`) olayın kişisi olmasa da olur.
bool _kisiOlabilir(GameEvent e) {
  final EventRequirement r = e.requirement;
  if (r.personRole != null) return true;
  if (r.livingRelations.isNotEmpty) return true;
  if (r.requiresNeglectedRelative) return true;
  if (r.requiresTripMemory) return true;
  if (r.personMinAge != null || r.personMaxAge != null) return true;
  return false;
}

bool _kisiUretiyor(EventChoice c) =>
    c.startsRomance || c.startsFriendship || c.startsSchoolFriendship;

/// Faho'nun kararını bekleyen, bilinen tek halka.
///
/// `suc_gece_tartismasi` sokakta tartışılan **yabancıyı** hikâye rolüne
/// kilitlemek istiyor. Rol AR/2'de doğru seçime taşındı (kavganın
/// gerçekten olduğu seçime), ama karşı taraf kayıtlı bir kişi değil:
/// motor rolü hâlâ kaydedemiyor, `suc_kavga_karsisindaki` uykuda.
///
/// Çözüm bir tasarım kararı istiyor — "kavga ettiğin kişi İlişkiler
/// ekranında *tanışıklık* olarak görünsün mü?" — ve kuyrukta duruyor.
/// Karar gelince bu liste boşalacak. **Liste büyümemeli:** yeni bir
/// kırık halka buraya eklenmek yerine düzeltilmeli.
const Set<String> kKararBekleyen = <String>{
  'suc_gece_tartismasi/karsilik_ver',
};

void main() {
  test('rol kilitleyen her seçimin kilitleyecek bir kişisi var', () {
    final List<String> kirik = <String>[];
    for (final GameEvent e in kEventPool) {
      for (final EventChoice c in e.choices) {
        if (c.rememberPersonAs == null) continue;
        if (_kisiUretiyor(c) || _kisiOlabilir(e)) continue;
        if (kKararBekleyen.contains('${e.id}/${c.id}')) continue;
        kirik.add('${e.id}/${c.id} → "${c.rememberPersonAs}" rolünü '
            'kilitlemek istiyor ama olayın kişisi yok');
      }
    }

    expect(
      kirik,
      isEmpty,
      reason: 'Aşağıdaki seçimler bir kişiyi hikâye rolüne kilitlemek '
          'istiyor ama olayın kişisi olmadığı için motor rolü sessizce '
          'kaydetmiyor. O rolü arayan devam olayları ömür boyu ölü kalır.\n'
          'Çözüm: olaya bir kişi koşulu ekleyin (örn. '
          'livingRelations) ya da seçim kişiyi kendisi üretsin '
          '(startsFriendship).\n\n${kirik.join("\n")}',
    );
  });

  test('aranan her hikâye rolünü kilitleyen bir seçim var', () {
    final Set<String> kilitlenen = <String>{};
    for (final GameEvent e in kEventPool) {
      for (final EventChoice c in e.choices) {
        final String? rol = c.rememberPersonAs;
        if (rol != null) kilitlenen.add(rol);
      }
    }
    final Map<String, List<String>> aranan = <String, List<String>>{};
    for (final GameEvent e in kEventPool) {
      final String? rol = e.requirement.personRole;
      if (rol != null) aranan.putIfAbsent(rol, () => <String>[]).add(e.id);
    }
    final List<String> sahipsiz = aranan.keys
        .where((String rol) => !kilitlenen.contains(rol))
        .toList()
      ..sort();
    expect(
      sahipsiz,
      isEmpty,
      reason: 'Şu rolleri arayan olay var ama hiçbir seçim o rolü '
          'kilitlemiyor:\n'
          '${sahipsiz.map((String r) => "  $r <- ${aranan[r]!.join(", ")}").join("\n")}',
    );
  });

  test('kilitlenen her rolü arayan bir olay var (ölü rol yok)', () {
    // `yazIsiArkadasi` tam bu durumdaydı: bir seçim rolü kilitliyordu ama
    // hiçbir olay o rolü aramıyordu. İki yönden ölü bir bildirimdi ve
    // AR/2'de kaldırıldı. Bu test aynısının tekrar yazılmasını engelliyor.
    final Map<String, List<String>> kilitleyen = <String, List<String>>{};
    for (final GameEvent e in kEventPool) {
      for (final EventChoice c in e.choices) {
        final String? rol = c.rememberPersonAs;
        if (rol != null) {
          kilitleyen.putIfAbsent(rol, () => <String>[]).add('${e.id}/${c.id}');
        }
      }
    }
    final Set<String> aranan = <String>{
      for (final GameEvent e in kEventPool)
        if (e.requirement.personRole != null) e.requirement.personRole!,
    };
    final List<String> okunmayan = kilitleyen.keys
        .where((String rol) => !aranan.contains(rol))
        .toList()
      ..sort();
    expect(
      okunmayan,
      isEmpty,
      reason: 'Şu roller kilitleniyor ama hiçbir olay onları aramıyor; '
          'kilit hiçbir şeye yaramıyor:\n'
          '${okunmayan.map((String r) => "  $r <- ${kilitleyen[r]!.join(", ")}").join("\n")}',
    );
  });

  test('bağ türü olan olaylarda kişi gerçekten çözülebilir', () {
    // Kişi gerektiren olayın istediği bağ türü, oyunun tanıdığı bir tür
    // olmalı; yazım hatası olan bir tür sessizce "kişi yok" demektir.
    for (final GameEvent e in kEventPool) {
      for (final RelationType t in e.requirement.livingRelations) {
        expect(RelationType.values.contains(t), isTrue,
            reason: '${e.id} tanınmayan bir bağ türü istiyor: $t');
      }
    }
  });
}
