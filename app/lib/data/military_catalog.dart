/// Askerlik yolları ve rütbeler (Paket 29).
///
/// **Bu bir prototip modelidir.** Gerçek askerlik mevzuatı (süreler,
/// bedelli tutarı, başvuru koşulları) zamanla değişir; buradaki bütün
/// sayılar `prototypeOnly`'dir ve onaylanmış oyun kuralı değildir
/// (Q-097).
///
/// Kapsam: yükümlülük, bedelli, gönüllü katılım ve rütbeli yollar
/// (astsubay, subay). Siyasi bir iddia yok; oyunun hayat çizgisindeki
/// bir dönem olarak ele alınır.
library;

import 'package:flutter/material.dart';

/// Askerliğin hangi yoldan yapıldığı.
enum MilitaryTrack {
  /// Er olarak yükümlülüğü yerine getirmek.
  er(
    'Er olarak yap',
    'Zorunlu askerlik. Kısa sürer, maaşı yoktur.',
    Icons.military_tech_outlined,
  ),

  /// Astsubaylık: meslek olarak askerlik.
  astsubay(
    'Astsubay ol',
    'Meslek olarak askerlik. Lise mezunu olmak gerekir.',
    Icons.workspace_premium_outlined,
  ),

  /// Subaylık: üniversite mezunu için.
  subay(
    'Subay ol',
    'Meslek olarak askerlik. Üniversite mezunu olmak gerekir.',
    Icons.stars_rounded,
  );

  const MilitaryTrack(this.label, this.description, this.icon);

  final String label;
  final String description;
  final IconData icon;

  /// prototypeOnly: hizmetin kaç yıl sürdüğü.
  int get prototypeOnlyYears {
    switch (this) {
      case MilitaryTrack.er:
        return 1;
      case MilitaryTrack.astsubay:
        return 4;
      case MilitaryTrack.subay:
        return 5;
    }
  }

  /// prototypeOnly: yıllık maaş (₺). Er maaş almaz.
  int get prototypeOnlySalary {
    switch (this) {
      case MilitaryTrack.er:
        return 0;
      case MilitaryTrack.astsubay:
        return 420000;
      case MilitaryTrack.subay:
        return 560000;
    }
  }

  /// prototypeOnly: başvurunun kabul edilme ihtimalinin tabanı.
  ///
  /// Zekâ ve sağlık bunu yukarı çeker; er yolunda başvuru yoktur.
  double get prototypeOnlyBaseChance {
    switch (this) {
      case MilitaryTrack.er:
        return 1.0;
      case MilitaryTrack.astsubay:
        return 0.45;
      case MilitaryTrack.subay:
        return 0.30;
    }
  }

  /// Bu yolda kazanılan rütbeler, en düşükten yükseğe.
  List<MilitaryRank> get ranks {
    switch (this) {
      case MilitaryTrack.er:
        return const <MilitaryRank>[
          MilitaryRank('er', 'Er'),
          MilitaryRank('onbasi', 'Onbaşı'),
        ];
      case MilitaryTrack.astsubay:
        return const <MilitaryRank>[
          MilitaryRank('astcavus', 'Astsubay Çavuş'),
          MilitaryRank('ustcavus', 'Astsubay Üstçavuş'),
          MilitaryRank('basacavus', 'Astsubay Başçavuş'),
        ];
      case MilitaryTrack.subay:
        return const <MilitaryRank>[
          MilitaryRank('tegmen', 'Teğmen'),
          MilitaryRank('ustegmen', 'Üsteğmen'),
          MilitaryRank('yuzbasi', 'Yüzbaşı'),
          MilitaryRank('binbasi', 'Binbaşı'),
        ];
    }
  }
}

/// Tek bir rütbe.
@immutable
class MilitaryRank {
  const MilitaryRank(this.id, this.label);

  final String id;
  final String label;
}

MilitaryRank? militaryRankById(String id) {
  for (final MilitaryTrack t in MilitaryTrack.values) {
    for (final MilitaryRank r in t.ranks) {
      if (r.id == id) return r;
    }
  }
  return null;
}

MilitaryTrack? militaryTrackByName(String name) {
  for (final MilitaryTrack t in MilitaryTrack.values) {
    if (t.name == name) return t;
  }
  return null;
}
