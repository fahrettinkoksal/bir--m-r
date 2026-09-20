import 'package:flutter/foundation.dart';

import '../../data/social_catalog.dart';

/// Yapılmış bir paylaşımın kaydı.
@immutable
class SocialPost {
  const SocialPost({
    required this.contentId,
    required this.age,
    required this.followerDelta,
  });

  final String contentId;

  /// Paylaşımın yapıldığı yaş.
  final int age;

  /// Takipçi değişimi (eksi olabilir).
  final int followerDelta;

  SocialContent? get content => socialContentById(contentId);

  String get label => content?.label ?? contentId;
}

/// Bir platformdaki hesap.
///
/// Hesap **isteğe bağlıdır**: açılmadıkça o platformda paylaşım yapılamaz
/// ve o platformdan olay gelmez.
@immutable
class SocialAccount {
  const SocialAccount({
    required this.platform,
    required this.createdAtAge,
    this.followers = 0,
    this.posts = const <SocialPost>[],
  });

  final SocialPlatform platform;
  final int createdAtAge;

  /// Takipçi / abone sayısı.
  final int followers;

  /// İçerik geçmişi; en yeni sonda.
  final List<SocialPost> posts;

  int get postCount => posts.length;

  /// Bu yaşta bu platformda yapılan paylaşım sayısı.
  ///
  /// Yıllık paylaşım sınırı **platform başına** işler: Instagram'da sınıra
  /// ulaşmak YouTube'u kapatmaz. Sayı paylaşım geçmişinden okunduğu için
  /// yaş ilerleyince kendiliğinden yenilenir ve eski kayıtlar da doğru
  /// sayılır.
  int postsAtAge(int age) {
    int sayi = 0;
    for (final SocialPost p in posts) {
      if (p.age == age) sayi++;
    }
    return sayi;
  }

  /// Son paylaşımlarda bu içerik türü kaç kez geçti?
  ///
  /// Aynı içeriği üst üste paylaşmak kazancı düşürür.
  int recentCountOf(String contentId, {int window = 5}) {
    final int baslangic = posts.length - window;
    int sayi = 0;
    for (int i = baslangic < 0 ? 0 : baslangic; i < posts.length; i++) {
      if (posts[i].contentId == contentId) sayi++;
    }
    return sayi;
  }

  SocialAccount copyWith({int? followers, List<SocialPost>? posts}) =>
      SocialAccount(
        platform: platform,
        createdAtAge: createdAtAge,
        followers: followers ?? this.followers,
        posts: posts ?? this.posts,
      );
}
