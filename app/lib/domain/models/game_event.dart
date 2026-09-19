import 'package:flutter/foundation.dart';

import 'relation.dart';

/// Olayın hangi yaşam alanından geldiği (D-023).
enum EventCategory {
  aile('Aile'),
  okul('Okul'),
  mahalle('Mahalle'),
  kisisel('Kişisel'),
  yetiskinlik('Yetişkinlik');

  const EventCategory(this.label);

  final String label;
}

/// Bir olayın çıkabilmesi için aranan koşullar (D-009).
///
/// Yaş tek başına yeterli değildir: olayın kişisi gerçekten yaşıyor olmalı,
/// gereken hikâye izi bulunmalı, sahip olunmayan varlık için olay çıkmamalıdır.
@immutable
class EventRequirement {
  const EventRequirement({
    this.minAge = 0,
    this.maxAge = 120,
    this.livingRelations = const <RelationType>{},
    this.requireSameHousehold = false,
    this.requiredFlags = const <String>{},
    this.forbiddenFlags = const <String>{},
    this.requiredPossessions = const <String>{},
    this.requiresSchoolStudent = false,
    this.minGrade,
    this.maxGrade,
    this.requiresNeglectedRelative = false,
  });

  final int minAge;
  final int maxAge;

  /// Bu bağlardan **hayatta** en az bir kişi gerekir; olay o kişiyle kurulur.
  /// Boşsa olay kişisizdir.
  final Set<RelationType> livingRelations;

  /// Olayın kişisinin oyuncuyla aynı evde yaşaması gerekir.
  final bool requireSameHousehold;

  /// Geçmişte bırakılmış olması gereken izler (D-008).
  final Set<String> requiredFlags;

  /// Bu izlerden biri varsa olay çıkmaz.
  final Set<String> forbiddenFlags;

  /// Sahip olunması gereken varlıklar; olmayan araç için olay çıkmaz.
  final Set<String> requiredPossessions;

  /// Okula devam ediyor olmayı gerektirir (yaş değil, eğitim durumu).
  final bool requiresSchoolStudent;

  /// Sınıf aralığı (1-12). Verilirse oyuncunun o sınıfta olması gerekir.
  final int? minGrade;
  final int? maxGrade;

  /// Uzun süre oyun içinde temas kurulmamış bir yakın gerektirir (D-025).
  final bool requiresNeglectedRelative;
}

/// Bir olay seçeneği ve sonuçları.
@immutable
class EventChoice {
  const EventChoice({
    required this.id,
    required this.label,
    required this.resultText,
    this.happiness = 0,
    this.health = 0,
    this.intelligence = 0,
    this.charisma = 0,
    this.appearance = 0,
    this.bond = 0,
    this.money = 0,
    this.addFlags = const <String>{},
    this.removeFlags = const <String>{},
    this.addPossessions = const <String>{},
    this.startsRomance = false,
    this.endsRomance = false,
    this.startsSchoolFriendship = false,
  });

  final String id;
  final String label;

  /// Seçimden sonra gösterilen ve hayat günlüğüne yazılan özgün metin.
  final String resultText;

  final int happiness;
  final int health;
  final int intelligence;
  final int charisma;
  final int appearance;

  /// Olayın kişisiyle ilişki değişimi.
  final int bond;

  /// Oyuncunun **kendi** cüzdanındaki değişim (ECO-001). Aile parasıyla
  /// karışmaz. Miktarlar prototypeOnly'dir.
  final int money;

  /// Geleceğe bırakılan iz (D-008, D-022).
  final Set<String> addFlags;

  /// Artık geçerli olmayan izler (örneğin ilişki bittiğinde).
  final Set<String> removeFlags;
  final Set<String> addPossessions;

  /// Bu seçim yeni bir romantik ilişki başlatır: kişi oluşturulur ve
  /// **sevgili** statüsüyle Aile'de listelenir (D-029, D-030).
  final bool startsRomance;

  /// Bu seçim mevcut ilişkiyi bitirir. Kişi **silinmez**; aynı kimlikle
  /// eski sevgili statüsüne geçer.
  final bool endsRomance;

  /// Bu seçim okulda bir arkadaşlık başlatır: kalıcı kimlikli bir kişi
  /// kaydı oluşturulur ve sonraki olaylarda aynı kişi kullanılır.
  final bool startsSchoolFriendship;
}

/// Olay tanımı. Havuz modülerdir; yeni olay eklemek listeye kayıt eklemektir.
@immutable
class GameEvent {
  const GameEvent({
    required this.id,
    required this.category,
    required this.text,
    required this.choices,
    this.requirement = const EventRequirement(),
    this.repeatable = false,
    this.weight = 1,
  });

  final String id;
  final EventCategory category;

  /// `{kisi}` kişinin adıyla, `{bag}` bağ etiketiyle değiştirilir.
  final String text;
  final List<EventChoice> choices;
  final EventRequirement requirement;

  /// Aynı hayatta birden çok kez çıkabilir mi?
  final bool repeatable;

  /// Aynı anda uygun olan olaylar arasında görece ağırlık (prototypeOnly).
  final int weight;
}

/// Oyuncunun karşısına çıkmış, kişisi ve metni çözülmüş olay.
@immutable
class ActiveEvent {
  const ActiveEvent({
    required this.eventId,
    required this.category,
    required this.text,
    required this.choices,
    this.personId,
  });

  final String eventId;
  final EventCategory category;

  /// Yer tutucuları doldurulmuş, ekranda gösterilecek metin.
  final String text;
  final List<EventChoice> choices;

  /// Olay bir kişiyle kurulduysa o kişinin kalıcı kimliği.
  final String? personId;
}

/// Bir seçimin uygulanmış hâli; arayüzde sonucu göstermek için.
@immutable
class EventResolution {
  const EventResolution({
    required this.eventId,
    required this.choiceId,
    required this.resultText,
  });

  final String eventId;
  final String choiceId;
  final String resultText;
}
