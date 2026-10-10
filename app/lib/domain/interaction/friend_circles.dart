/// Arkadaş grubu (Paket CI).
///
/// **Nasıl bulundu.** `docs/EKSIKLER.md` §3.1 arkadaşlığın eksiklerini
/// sayıyordu; D-130 çoğunu kapattı ve o bölümün güncellemesi kalan iki
/// eksiği yazdı: **arkadaş grubu** ve çocukluk arkadaşıyla yıllar sonra
/// karşılaşma. İkincisi D-130'un zincirlerinde kodlanmış durumda; grup
/// kodda hiç yoktu (`arkadasGrubu`/`friendGroup` tek bir dosyada
/// geçmiyordu).
///
/// **Yeni bir etkileşim motoru değil.** Birden çok kişiyle aktiviteye
/// gitmek zaten var (Paket X/2, `Outing`): maliyet kişi başına
/// çarpılıyor, her katılımcıyla bağ artıyor. Eksik olan **kalıcı
/// kimlik**ti: kimlerle takıldığın, ne zamandır, kim ayrıldı. Bu dosya
/// onu tutar; buluşma yine aktivite yolundan geçer, böylece ekonomi ve
/// etki tek yerden okunur (AN §1-§3'ün "tek kanonik yol" dersi).
///
/// **Grubu oyuncu kurar.** D-130'un en pahalı dersi şuydu: oyuncunun
/// düğmesi olmayan bir sistem hiç kullanılmaz — arkadaşlık yalnızca
/// rastgele bir olayla kurulabildiği için 60 hayatın 34'ünde hiç arkadaş
/// yoktu. Grup kendiliğinden oluşmaz; oyuncu kurar, oyun yalnızca
/// adını koyar ve zamanla eritir.
///
/// Bütün sayılar `prototypeOnly`'dir (Q-227).
library;

import '../features/feature_catalog.dart';
import '../models/friend_circle.dart';
import '../models/game_state.dart';
import '../models/life_log.dart';
import '../models/person.dart';
import '../models/relation.dart';

abstract final class FriendCircles {
  /// prototypeOnly: grup kurmak için gereken en az üye.
  ///
  /// Üç kişi bir "grup"un en küçük hâli: iki kişi zaten arkadaşlıktır.
  static const int prototypeOnlyMinMembers = 3;

  /// prototypeOnly: grubun alabileceği en çok üye.
  ///
  /// Aktivite yolu en çok 8 refakatçi taşıyor (`Outing.costForParty`);
  /// grup onun altında tutuldu, çünkü buluşmada eş ya da çocuk da
  /// gelebilir.
  static const int prototypeOnlyMaxMembers = 6;

  /// prototypeOnly: gruba çağrılabilmek için gereken en az bağ.
  ///
  /// Aktiviteye birlikte gitmenin "yakın arkadaş" eşiğiyle aynı sayı
  /// (`Outing.prototypeOnlyCloseFriendBond`); ayrı bir sayı uydurulmadı.
  ///
  /// **Eşik ölçülerek bırakıldı (120 hayat, bütün arketipler).** Aday
  /// sayısının hayat boyu en yüksek değeri:
  ///
  /// | bağ ≥ | ortanca aday | üç kişiye ulaşan hayat |
  /// |---|---|---|
  /// | 30 | 5 | 120/120 |
  /// | 35 | 5 | 120/120 |
  /// | 40 | 2 | 26/120 |
  /// | 45 | 2 | 16/120 |
  ///
  /// 35 ile 40 arasında keskin bir kırılma var ve sebebi şu: sınıf
  /// arkadaşının başlangıç bağı **35-55** aralığında (Paket BS/0).
  /// Yani "bağ ≥ 35" pratikte "herhangi bir sınıf arkadaşı" demek
  /// olurdu ve grup, birlikte vakit geçirilmemiş insanlardan kurulurdu.
  /// 45 eşiği **yatırım yapılmış** bağı ister ve `Outing`'in kendi
  /// "yakın arkadaş" eşiğiyle aynıdır. Bedeli şudur ve bilerek kabul
  /// edildi: grup her hayatta kurulamaz. Eşiği düşürmek, refakatçi
  /// listesini genişletmek ya da ölçüm botunun ilgisini birden çok
  /// kişiye yaymak Q-227'de sorulmuştur.
  static const int prototypeOnlyMinBond = 45;

  /// prototypeOnly: grup kurmak için en küçük yaş.
  ///
  /// Okul çağının başı: daha küçük yaşta oyunun sunduğu arkadaşlık
  /// kaydı yok (Paket CH ölçümü: yaş 1-3'te hiçbir etkileşim açık
  /// değil).
  static const int prototypeOnlyMinAge = 10;

  /// Modül açık mı? (Paket BL sözleşmesi: kapalıyken hiçbir şey işlemez)
  static bool isOn(GameState state) =>
      state.featureOn(FeatureId.arkadasGrubu);

  /// Şu an süren grup; yoksa `null`.
  static FriendCircle? activeOf(GameState state) {
    for (final FriendCircle c in state.friendCircles) {
      if (c.isActive) return c;
    }
    return null;
  }

  /// Grup adayı olabilecek bağ türleri.
  ///
  /// **Kural uydurulmadı, oyundan türetildi.** Aday kümesi, oyunun
  /// "birlikte programa gelebilir" listesinden (`Outing`) aileyi
  /// çıkararak kalan kümedir: yalnızca `arkadas`. İlk yazımda sınıf
  /// arkadaşı, iş arkadaşı ve komşu da eklenmişti; ölçüm bunun
  /// **çalışmadığını** gösterdi — 120 hayatta grup 11 kez kuruldu ama
  /// **tek bir buluşma** olmadı, çünkü `Outing.companionRelations` o
  /// üç türü taşımıyor ve üye sinemaya gelemiyor. Yani grup kurulup
  /// hiç buluşamıyordu. Kuralı tek yerde tutmak için aday kümesi
  /// refakatçi kuralının kendisinden okunuyor.
  ///
  /// Bedeli yazılı: grup her hayatta kurulamıyor (ölçüm aşağıda).
  /// Refakatçi listesini genişletmek Q-227'de sorulmuştur.
  static const Set<RelationType> candidateRelations = <RelationType>{
    RelationType.arkadas,
  };

  /// Gruba çağrılabilecek kişiler: yaşayan, küs olmayan, bağı yeten
  /// arkadaş ve tanışıklıklar. Bağa göre azalan sırada.
  static List<Person> eligible(GameState state) {
    final List<Person> adaylar = state.people
        .where((Person p) =>
            p.isAlive &&
            !p.isEstranged &&
            candidateRelations.contains(p.relation) &&
            p.bond >= prototypeOnlyMinBond)
        .toList(growable: false);
    final List<Person> sirali = List<Person>.of(adaylar)
      ..sort((Person a, Person b) => b.bond.compareTo(a.bond));
    return List<Person>.unmodifiable(sirali);
  }

  /// Grup kurmaya engel; engel yoksa boş metin.
  static String blockReason(GameState state) {
    if (!isOn(state)) return 'Arkadaş grubu modülü kapalı.';
    if (state.player.age < prototypeOnlyMinAge) {
      return '$prototypeOnlyMinAge yaşından itibaren grup kurabilirsin.';
    }
    if (activeOf(state) != null) {
      return 'Zaten bir grubun var.';
    }
    final int aday = eligible(state).length;
    if (aday < prototypeOnlyMinMembers) {
      return 'Grup için en az $prototypeOnlyMinMembers yakın arkadaş '
          'gerekiyor; şu an $aday kişi uygun (bağ '
          '$prototypeOnlyMinBond ve üstü).';
    }
    return '';
  }

  /// Grubun adı: oyuncunun hayatının o günkü hâlinden türer.
  ///
  /// Ad **uydurma bir takma ad değil**; argo ya da espri de yok
  /// (`docs/WRITING_STYLE_TR.md`). Nerede tanışıldığı kayıtta
  /// tutulmuyor (arkadaş olan kişinin bağ türü `arkadas` oluyor ve
  /// kökeni kayboluyor), bu yüzden ad **oyuncunun o anki çevresinden**
  /// okunuyor.
  static String nameFor(GameState state) {
    final int yas = state.player.age;
    if (yas < 19) return 'Okul çevresi';
    if (state.education.isUniversityStudent) return 'Üniversite çevresi';
    if (state.career.isEmployed) return 'İş çevresi';
    return 'Mahalle çevresi';
  }

  /// Grubu kurar. Engel varsa durumu değiştirmez.
  ///
  /// Üyeler **bağı en yüksek** adaylardan seçilir; oyuncu listeyi
  /// ekranda görüyor (`friend_circle_card.dart`), yani seçim gizli
  /// değil. Tek tek seçme Q-227'de sorulmuş durumda.
  static ({GameState state, bool applied, String text}) form(
    GameState state,
  ) {
    final String engel = blockReason(state);
    if (engel.isNotEmpty) {
      return (state: state, applied: false, text: engel);
    }
    final List<Person> adaylar = eligible(state);
    final List<Person> uyeler = adaylar
        .take(prototypeOnlyMaxMembers)
        .toList(growable: false);
    final String ad = nameFor(state);
    final FriendCircle grup = FriendCircle(
      name: ad,
      memberIds:
          List<String>.unmodifiable(uyeler.map((Person p) => p.id)),
      formedAtAge: state.player.age,
    );
    final String isimler = uyeler.map((Person p) => p.firstName).join(', ');
    final String metin = '$ad kuruldu: $isimler.';
    return (
      state: state.copyWith(
        friendCircles: <FriendCircle>[...state.friendCircles, grup],
        log: <LifeLogEntry>[
          ...state.log,
          LifeLogEntry(
            age: state.player.age,
            text: metin,
            category: LogCategory.kisisel,
          ),
        ],
      ),
      applied: true,
      text: metin,
    );
  }

  /// Grubun yaşayan ve küs olmayan üyeleri.
  static List<Person> membersOf(GameState state, FriendCircle circle) =>
      List<Person>.unmodifiable(<Person>[
        for (final String id in circle.memberIds)
          if (state.personById(id) case final Person p)
            if (p.isAlive && !p.isEstranged) p,
      ]);

  /// Yılın grup bakımı: ayrılanları düşer, gerekiyorsa dağıtır.
  ///
  /// **Sessiz kayıp yok.** Vefat eden ya da küsen üye gruptan düşer ve
  /// günlüğe tek satır yazılır; üye sayısı en aza inerse grup dağılır
  /// ve o da yazılır. Kayıt silinmez: dağılan grup listede
  /// `dispersedAtAge` ile kalır.
  static GameState yearly(GameState state) {
    if (!isOn(state)) return state;
    final FriendCircle? grup = activeOf(state);
    if (grup == null) return state;

    final List<String> kalan = <String>[
      for (final String id in grup.memberIds)
        if (state.personById(id) case final Person p)
          if (p.isAlive && !p.isEstranged) id,
    ];
    if (kalan.length == grup.memberIds.length) return state;

    final List<String> ayrilan = grup.memberIds
        .where((String id) => !kalan.contains(id))
        .toList(growable: false);
    final List<String> adlar = <String>[
      for (final String id in ayrilan)
        if (state.personById(id) case final Person p) p.firstName,
    ];

    final bool dagildi = kalan.length < prototypeOnlyMinMembers;
    final FriendCircle yeni = dagildi
        ? grup.copyWith(
            memberIds: kalan,
            dispersedAtAge: state.player.age,
          )
        : grup.copyWith(memberIds: kalan);

    final List<LifeLogEntry> satirlar = <LifeLogEntry>[
      if (adlar.isNotEmpty)
        LifeLogEntry(
          age: state.player.age,
          text: adlar.length == 1
              ? '${adlar.first} artık ${grup.name} içinde değil.'
              : '${adlar.join(', ')} artık ${grup.name} içinde değil.',
          category: LogCategory.kisisel,
        ),
      if (dagildi)
        LifeLogEntry(
          age: state.player.age,
          text: '${grup.name} dağıldı; kalan ${kalan.length} kişiyle '
              'grup yürümüyor.',
          category: LogCategory.kisisel,
        ),
    ];

    return state.copyWith(
      friendCircles: <FriendCircle>[
        for (final FriendCircle c in state.friendCircles)
          if (c == grup) yeni else c,
      ],
      log: <LifeLogEntry>[...state.log, ...satirlar],
    );
  }

  /// Buluşma kaydı: aktivite yolundan dönen durumun üstüne yazılır.
  static GameState markMet(GameState state) {
    if (!isOn(state)) return state;
    final FriendCircle? grup = activeOf(state);
    if (grup == null) return state;
    return state.copyWith(
      friendCircles: <FriendCircle>[
        for (final FriendCircle c in state.friendCircles)
          if (c == grup) c.copyWith(lastMetAge: state.player.age) else c,
      ],
    );
  }
}
