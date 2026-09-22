/// Askerlik durumu (Paket 29).
library;

import 'package:flutter/foundation.dart';

import '../../data/military_catalog.dart';

/// Oyuncunun askerlikle ilişkisi.
enum MilitaryStatus {
  /// Henüz bir şey olmadı.
  yok('Yapılmadı'),

  /// Celp geldi: yükümlülük başladı, henüz gidilmedi.
  cagrildi('Celp geldi'),

  /// Şu an görevde.
  gorevde('Askerde'),

  /// Tamamlandı.
  tamamlandi('Tamamlandı'),

  /// Bedelli ödendi; hizmet yapılmadı.
  bedelli('Bedelli ödendi'),

  /// Yükümlü değil (sağlık, cinsiyet ya da yaş).
  yukumluDegil('Yükümlü değil');

  const MilitaryStatus(this.label);

  final String label;

  /// Askerlik meselesi kapandı mı?
  bool get kapandi =>
      this == MilitaryStatus.tamamlandi ||
      this == MilitaryStatus.bedelli ||
      this == MilitaryStatus.yukumluDegil;
}

/// Askerlik kaydı.
///
/// **Kayda girer:** yarım kalan hizmet uygulama kapatılıp açılınca
/// kaybolmaz.
@immutable
class MilitaryState {
  const MilitaryState({
    this.status = MilitaryStatus.yok,
    this.trackName,
    this.rankId,
    this.calledAtAge,
    this.startedAtAge,
    this.finishedAtAge,
    this.paidByPersonId,
  });

  final MilitaryStatus status;

  /// Hangi yoldan yapıldığı ([MilitaryTrack.name]).
  final String? trackName;

  /// Ulaşılan rütbe ([MilitaryRank.id]).
  final String? rankId;

  /// Celbin geldiği yaş.
  final int? calledAtAge;

  /// Hizmetin başladığı yaş.
  final int? startedAtAge;

  /// Hizmetin bittiği yaş.
  final int? finishedAtAge;

  /// Bedelli bir yakın tarafından ödendiyse o kişinin kimliği.
  ///
  /// Oyuncu kendi cebinden ödediyse `null`'dır; uydurma bir ödeyen
  /// yazılmaz.
  final String? paidByPersonId;

  MilitaryTrack? get track =>
      trackName == null ? null : militaryTrackByName(trackName!);

  MilitaryRank? get rank => rankId == null ? null : militaryRankById(rankId!);

  bool get isServing => status == MilitaryStatus.gorevde;

  bool get isCalled => status == MilitaryStatus.cagrildi;

  /// Meslek olarak askerlik mi? (Astsubay/subay maaş alır.)
  bool get isCareer =>
      track == MilitaryTrack.astsubay || track == MilitaryTrack.subay;

  /// Ekranda gösterilecek kısa durum.
  String get label {
    final MilitaryRank? r = rank;
    if (r == null) return status.label;
    switch (status) {
      case MilitaryStatus.gorevde:
        return '${r.label} · görevde';
      case MilitaryStatus.tamamlandi:
        return '${r.label} · terhis';
      default:
        return status.label;
    }
  }

  MilitaryState copyWith({
    MilitaryStatus? status,
    Object? trackName = _unset,
    Object? rankId = _unset,
    Object? calledAtAge = _unset,
    Object? startedAtAge = _unset,
    Object? finishedAtAge = _unset,
    Object? paidByPersonId = _unset,
  }) {
    return MilitaryState(
      status: status ?? this.status,
      trackName: trackName == _unset ? this.trackName : trackName as String?,
      rankId: rankId == _unset ? this.rankId : rankId as String?,
      calledAtAge:
          calledAtAge == _unset ? this.calledAtAge : calledAtAge as int?,
      startedAtAge:
          startedAtAge == _unset ? this.startedAtAge : startedAtAge as int?,
      finishedAtAge:
          finishedAtAge == _unset ? this.finishedAtAge : finishedAtAge as int?,
      paidByPersonId: paidByPersonId == _unset
          ? this.paidByPersonId
          : paidByPersonId as String?,
    );
  }
}

const Object _unset = Object();
