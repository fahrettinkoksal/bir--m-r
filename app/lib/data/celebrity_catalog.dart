/// Sosyal medyadaki ünlüler.
///
/// **Hepsi kurgusaldır.** Gerçek kişilerin adları, hesapları, sözleri ya
/// da hayat hikâyeleri kullanılmaz; adlar ve alanlar oyuna özgüdür.
/// Gerçek bir insanı çağrıştıracak biçimde yazmaktan kaçınıldı.
///
/// Ünlüler oyunun kişi kaydına **kendiliğinden girmez**: oyuncu gerçekten
/// temas kurup karşılık aldığında kalıcı bir kişi hâline gelirler
/// (`CelebrityEngine`). Böylece hiç tanışılmamış biri İlişkiler ekranında
/// görünmez.
///
/// Sayısal değerler `prototypeOnly`'dir
/// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-115).
library;

import 'package:flutter/material.dart';

import '../domain/models/gender.dart';
import 'social_catalog.dart';

/// Ünlünün hangi alandan tanındığı.
enum CelebrityField {
  muzik('Müzik', Icons.mic_external_on_outlined),
  oyunculuk('Oyunculuk', Icons.theater_comedy_outlined),
  spor('Spor', Icons.sports_soccer_outlined),
  mizah('Mizah', Icons.sentiment_very_satisfied_outlined),
  icerik('İçerik üreticiliği', Icons.videocam_outlined),
  yazarlik('Yazarlık', Icons.menu_book_outlined),
  mutfak('Mutfak', Icons.restaurant_outlined);

  const CelebrityField(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Kurgusal bir ünlü.
@immutable
class Celebrity {
  const Celebrity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.field,
    required this.platform,
    required this.followers,
    required this.prototypeOnlyApproachability,
    required this.prototypeOnlyNoticeThreshold,
  });

  final String id;
  final String firstName;
  final String lastName;

  /// Cinsiyet **katalogda yazılıdır**, addan tahmin edilmez.
  ///
  /// Adlar genel isim havuzunda bulunmadığı için tahmine dayanan bir
  /// çözüm bütün ünlüleri aynı cinsiyette üretiyordu.
  final Gender gender;

  /// Hangi alandan tanındığı.
  final CelebrityField field;

  /// En çok kullandığı platform. Temas bu platformdan kurulur.
  final SocialPlatform platform;

  /// prototypeOnly: takipçi sayısı. Yalnızca ölçek duygusu verir.
  final int followers;

  /// prototypeOnly: ulaşılabilirliği (0-1).
  ///
  /// Büyük isimler küçük isimlerden daha zor cevap verir. Bu, "şansı
  /// yüksek" demek değil: taban oranı belirler, oyuncunun kendi kitlesi
  /// ve karizması üstüne biner.
  final double prototypeOnlyApproachability;

  /// prototypeOnly: oyuncunun fark edilmesi için gereken en az takipçi.
  ///
  /// Sıfır takipçili birinin mesajı büyük bir ismin kutusunda kaybolur.
  final int prototypeOnlyNoticeThreshold;

  String get fullName => '$firstName $lastName';
}

/// Oyundaki ünlüler. Küçükten büyüğe ulaşılabilirlik sırasında değil,
/// alan çeşitliliğine göre dizildi.
const List<Celebrity> kCelebrities = <Celebrity>[
  // --- Ulaşılabilir isimler ---------------------------------------------
  Celebrity(
    id: 'sevda_arpaci',
    firstName: 'Sevda',
    lastName: 'Arpacı',
    gender: Gender.kadin,
    field: CelebrityField.icerik,
    platform: SocialPlatform.kisaVideo,
    followers: 180000,
    prototypeOnlyApproachability: 0.42,
    prototypeOnlyNoticeThreshold: 200,
  ),
  Celebrity(
    id: 'bora_yetkin',
    firstName: 'Bora',
    lastName: 'Yetkin',
    gender: Gender.erkek,
    field: CelebrityField.mizah,
    platform: SocialPlatform.mikroblog,
    followers: 240000,
    prototypeOnlyApproachability: 0.38,
    prototypeOnlyNoticeThreshold: 300,
  ),
  Celebrity(
    id: 'nuran_celikkol',
    firstName: 'Nuran',
    lastName: 'Çelikkol',
    gender: Gender.kadin,
    field: CelebrityField.mutfak,
    platform: SocialPlatform.foto,
    followers: 320000,
    prototypeOnlyApproachability: 0.36,
    prototypeOnlyNoticeThreshold: 400,
  ),
  Celebrity(
    id: 'tolga_esmer',
    firstName: 'Tolga',
    lastName: 'Esmer',
    gender: Gender.erkek,
    field: CelebrityField.yazarlik,
    platform: SocialPlatform.mikroblog,
    followers: 150000,
    prototypeOnlyApproachability: 0.45,
    prototypeOnlyNoticeThreshold: 150,
  ),

  // --- Orta ölçek --------------------------------------------------------
  Celebrity(
    id: 'derya_akkoyun',
    firstName: 'Derya',
    lastName: 'Akkoyun',
    gender: Gender.kadin,
    field: CelebrityField.muzik,
    platform: SocialPlatform.foto,
    followers: 1400000,
    prototypeOnlyApproachability: 0.22,
    prototypeOnlyNoticeThreshold: 2500,
  ),
  Celebrity(
    id: 'emre_sancakli',
    firstName: 'Emre',
    lastName: 'Sancaklı',
    gender: Gender.erkek,
    field: CelebrityField.spor,
    platform: SocialPlatform.video,
    followers: 2100000,
    prototypeOnlyApproachability: 0.18,
    prototypeOnlyNoticeThreshold: 4000,
  ),
  Celebrity(
    id: 'pelin_ustundag',
    firstName: 'Pelin',
    lastName: 'Üstündağ',
    gender: Gender.kadin,
    field: CelebrityField.oyunculuk,
    platform: SocialPlatform.foto,
    followers: 1800000,
    prototypeOnlyApproachability: 0.20,
    prototypeOnlyNoticeThreshold: 3000,
  ),
  Celebrity(
    id: 'kaan_delioglu',
    firstName: 'Kaan',
    lastName: 'Delioğlu',
    gender: Gender.erkek,
    field: CelebrityField.icerik,
    platform: SocialPlatform.video,
    followers: 3200000,
    prototypeOnlyApproachability: 0.16,
    prototypeOnlyNoticeThreshold: 6000,
  ),

  // --- Büyük isimler -----------------------------------------------------
  Celebrity(
    id: 'yasemin_korkut',
    firstName: 'Yasemin',
    lastName: 'Korkut',
    gender: Gender.kadin,
    field: CelebrityField.muzik,
    platform: SocialPlatform.kisaVideo,
    followers: 7500000,
    prototypeOnlyApproachability: 0.09,
    prototypeOnlyNoticeThreshold: 20000,
  ),
  Celebrity(
    id: 'orkun_bayraktar',
    firstName: 'Orkun',
    lastName: 'Bayraktar',
    gender: Gender.erkek,
    field: CelebrityField.spor,
    platform: SocialPlatform.mikroblog,
    followers: 6200000,
    prototypeOnlyApproachability: 0.10,
    prototypeOnlyNoticeThreshold: 15000,
  ),
  Celebrity(
    id: 'ilkay_seringul',
    firstName: 'İlkay',
    lastName: 'Seringül',
    gender: Gender.erkek,
    field: CelebrityField.oyunculuk,
    platform: SocialPlatform.video,
    followers: 5400000,
    prototypeOnlyApproachability: 0.11,
    prototypeOnlyNoticeThreshold: 12000,
  ),
];

Celebrity? celebrityById(String id) {
  for (final Celebrity c in kCelebrities) {
    if (c.id == id) return c;
  }
  return null;
}

/// Bu platformda temas kurulabilecek ünlüler.
List<Celebrity> celebritiesOn(SocialPlatform platform) => kCelebrities
    .where((Celebrity c) => c.platform == platform)
    .toList(growable: false);
