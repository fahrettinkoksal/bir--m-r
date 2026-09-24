/// Oyun durumunun kayıt dosyası için JSON'a çevrilmesi ve geri okunması.
///
/// Kural: **ekrandaki her şeyin kaynağı olan `GameState` eksiksiz yazılır.**
/// Kişi kimlikleri, okul bağları, hikâye rolleri ve bekleyen olay olduğu
/// gibi saklanır; yüklerken hiçbir şey yeniden rastgele üretilmez.
///
/// Enum değerleri **adlarıyla** yazılır (sıra numarasıyla değil); böylece
/// ileride enum sırası değişse bile eski kayıtlar bozulmaz.
library;

import '../../domain/models/loan.dart';
import '../../domain/models/applied_effect.dart';
import '../../data/education_tracks.dart';
import '../../data/social_catalog.dart';
import '../../domain/models/blackjack_game.dart';
import '../../domain/models/book_progress.dart';
import '../../domain/models/martial_progress.dart';
import '../../domain/models/hobby_progress.dart';
import '../../domain/models/lottery_ticket.dart';
import '../../domain/models/finger_profile.dart';
import '../lottery_catalog.dart';
import '../../domain/models/career.dart';
import '../../domain/models/education.dart';
import '../../domain/models/game_event.dart';
import '../../domain/models/game_settings.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/gender.dart';
import '../../domain/models/gift_record.dart';
import '../../domain/models/life_log.dart';
import '../../domain/models/life_summary.dart';
import '../../domain/models/owned_item.dart';
import '../../domain/models/parental_status.dart';
import '../../domain/models/pending_crisis.dart';
import '../../domain/models/pending_wedding.dart';
import '../../domain/models/military.dart';
import '../../domain/models/pregnancy.dart';
import '../../domain/models/zodiac.dart';
import '../../domain/models/pending_interview.dart';
import '../../domain/models/pending_license_exam.dart';
import '../../domain/models/marriage.dart';
import '../../domain/models/person.dart';
import '../../domain/models/person_development.dart';
import '../../domain/models/playing_card.dart';
import '../../domain/models/celebrity_contact.dart';
import '../../domain/models/social_account.dart';
import '../../domain/models/sponsorship.dart';
import '../../domain/models/trip.dart';
import '../../domain/models/player_character.dart';
import '../../domain/models/relation.dart';
import '../../domain/models/stats.dart';
import '../../domain/models/wealth.dart';
import 'save_format.dart';
import '../../domain/models/pending_notice.dart';

// =====================================================================
// Yazma
// =====================================================================

Map<String, Object?> encodeGameState(GameState state) => <String, Object?>{
      'seed': state.seed,
      'player': _encodePlayer(state.player),
      'people': state.people.map(_encodePerson).toList(growable: false),
      'pets': state.pets.map(_encodePet).toList(growable: false),
      'parentalStatus': state.parentalStatus.name,
      'log': state.log.map(_encodeLogEntry).toList(growable: false),
      'interactionCounts': state.interactionCounts,
      'lastInteractionAge': state.lastInteractionAge,
      'storyFlags': state.storyFlags.toList(growable: false),
      'items': state.items.map(_encodeItem).toList(growable: false),
      'seenEventIds': state.seenEventIds.toList(growable: false),
      'lastEventAge': state.lastEventAge,
      'eventSeenCounts': state.eventSeenCounts,
      'storyPeople': state.storyPeople,
      'gifts': state.gifts.map(_encodeGift).toList(growable: false),
      'pendingEvent': state.pendingEvent == null
          ? null
          : _encodeActiveEvent(state.pendingEvent!),
      'progressSinceLastEvent': state.progressSinceLastEvent,
      'extraEventsThisAge': state.extraEventsThisAge,
      'education': _encodeEducation(state.education),
      'career': _encodeCareer(state.career),
      'pendingInterview': state.pendingInterview == null
          ? null
          : <String, Object?>{
              'jobId': state.pendingInterview!.jobId,
              'questionId': state.pendingInterview!.questionId,
              'askedAtAge': state.pendingInterview!.askedAtAge,
            },
      'books': state.books.map(_encodeBook).toList(growable: false),
      // Dövüş sanatları (Paket 32). Alan eklemeli; eski kayıtta yoksa boş
      // liste okunur, sürüm yükseltmesi gerekmez.
      'martialArts':
          state.martialArts.map(_encodeMartial).toList(growable: false),
      // Hobi geçmişi (Paket 39). Alan eklemeli.
      'hobbies': state.hobbies.map(_encodeHobby).toList(growable: false),
      // Piyango biletleri (Paket 33). Alan eklemeli.
      'lotteryTickets':
          state.lotteryTickets.map(_encodeTicket).toList(growable: false),
      // Finger profilleri (Paket 34). Alan eklemeli.
      'fingerDeck':
          state.fingerDeck.map(_encodeFinger).toList(growable: false),
      'fingerMatches':
          state.fingerMatches.map(_encodeFinger).toList(growable: false),
      'socialAccounts':
          state.socialAccounts.map(_encodeAccount).toList(growable: false),
      // Ünlülerle kurulan temaslar. Eski kayıtlarda bu alan yoktur;
      // okuma tarafı isteğe bağlı okuduğu için kayıt sürümü değişmedi.
      'celebrityContacts': state.celebrityContacts
          .map(_encodeCelebrityContact)
          .toList(growable: false),
      // Sponsorluk teklifi ve anlaşmaları (Paket 10).
      'sponsorOffer': state.sponsorOffer == null
          ? null
          : _encodeSponsorOffer(state.sponsorOffer!),
      'sponsorDeals':
          state.sponsorDeals.map(_encodeSponsorDeal).toList(growable: false),
      // Geziler (Paket 11): kayıt silinmez, ücret ikinci kez düşmez.
      'trips': state.trips.map(_encodeTrip).toList(growable: false),
      'blackjack':
          state.blackjack == null ? null : _encodeBlackjack(state.blackjack!),
      'wagerThisAge': state.wagerThisAge,
      // Krediler (D-080). Alan eklemeli; eski kayıtta boş liste okunur.
      'loans': <Map<String, Object?>>[
        for (final Loan l in state.loans)
          <String, Object?>{
            'id': l.id,
            'bank': l.bank.name,
            'principal': l.principal,
            'annualPayment': l.annualPayment,
            'termYears': l.termYears,
            'remainingPayments': l.remainingPayments,
            'outstanding': l.outstanding,
            'takenAtAge': l.takenAtAge,
            'missedPayments': l.missedPayments,
          },
      ],
      // Bakım geçmişi (D-072). Eski kayıtlarda yoktur; `null` kalır ve
      // ihmal sayılmaz.
      'lastSportAge': state.lastSportAge,
      'lastGroomingAge': state.lastGroomingAge,
      'lastLearningAge': state.lastLearningAge,
      'licenses': state.licenses.toList(growable: false),
      'pendingLicenseExam': state.pendingLicenseExam == null
          ? null
          : <String, Object?>{
              'licenseId': state.pendingLicenseExam!.licenseId,
              'questionIds': state.pendingLicenseExam!.questionIds,
              'answers': state.pendingLicenseExam!.answers,
              'askedAtAge': state.pendingLicenseExam!.askedAtAge,
              'feePaid': state.pendingLicenseExam!.feePaid,
            },
      'settledEstates': state.settledEstates.toList(growable: false),
      'pastLives':
          state.pastLives.map(_encodeLifeSummary).toList(growable: false),
      'careStatus': state.careStatus.name,
      'grief': state.grief,
      'hardshipYears': state.hardshipYears,
      'pendingCrisis': state.pendingCrisis == null
          ? null
          : <String, Object?>{
              'crisisId': state.pendingCrisis!.crisisId,
              'age': state.pendingCrisis!.age,
            },
      'lastCrisisAge': state.lastCrisisAge,
      'healthWarned': state.healthWarned,
      'residenceItemId': state.residenceItemId,
      'movedOut': state.movedOut,
      'generation': state.generation,
      'proposalAges': state.proposalAges,
      'heirChildId': state.heirChildId,
      'notices': <Map<String, Object?>>[
        for (final PendingNotice n in state.notices)
          <String, Object?>{
            'id': n.id,
            'kind': n.kind.name,
            'age': n.age,
            'title': n.title,
            'text': n.text,
            'personId': n.personId,
            'money': n.money,
            'itemNames': n.itemNames,
            'happinessDelta': n.happinessDelta,
            'funeralCost': n.funeralCost,
            'effects': <Map<String, Object?>>[
              for (final AppliedEffect e in n.effects)
                <String, Object?>{
                  'label': e.label,
                  'delta': e.delta,
                  'unit': e.unit,
                },
            ],
          },
      ],
      'marriage': state.marriage == null
          ? null
          : <String, Object?>{
              'spouseId': state.marriage!.spouseId,
              'marriedAtAge': state.marriage!.marriedAtAge,
              'status': state.marriage!.status.name,
              'endedAtAge': state.marriage!.endedAtAge,
            },
      // Önceki evlilikler (Paket 36). Alan eklemeli; kayıt silinmez.
      'pastMarriages': state.pastMarriages
          .map((Marriage m) => <String, Object?>{
                'spouseId': m.spouseId,
                'marriedAtAge': m.marriedAtAge,
                'status': m.status.name,
                'endedAtAge': m.endedAtAge,
              })
          .toList(growable: false),
      // Yarıda kalan "evet" kaybolmaz: düğün seçimi kayda girer
      // (Paket 25).
      'pendingWedding': state.pendingWedding == null
          ? null
          : <String, Object?>{
              'spouseId': state.pendingWedding!.spouseId,
              'acceptedAtAge': state.pendingWedding!.acceptedAtAge,
            },
      // Süren hamilelik kayda girer: uygulama kapansa da bekleyen bebek
      // kaybolmaz (Paket 26).
      'pregnancy': state.pregnancy == null
          ? null
          : <String, Object?>{
              'partnerId': state.pregnancy!.partnerId,
              'startedAtAge': state.pregnancy!.startedAtAge,
              'expecting': state.pregnancy!.expecting.name,
            },
      // Askerlik kaydı (Paket 29); yarım kalan hizmet kaybolmaz.
      'military': <String, Object?>{
        'status': state.military.status.name,
        'trackName': state.military.trackName,
        'rankId': state.military.rankId,
        'calledAtAge': state.military.calledAtAge,
        'startedAtAge': state.military.startedAtAge,
        'finishedAtAge': state.military.finishedAtAge,
        'paidByPersonId': state.military.paidByPersonId,
        'deferralsUsed': state.military.deferralsUsed,
        'deferredUntilAge': state.military.deferredUntilAge,
        'studentDeferral': state.military.studentDeferral,
        'fugitiveSinceAge': state.military.fugitiveSinceAge,
        'fineTotal': state.military.fineTotal,
        'caughtCount': state.military.caughtCount,
      },
      'unprotectedTries': state.unprotectedTries,
      // Tüp bebek denemeleri (Paket 35). Alan eklemeli.
      'ivfAttempts': state.ivfAttempts,
      'lastConceptionTryAge': state.lastConceptionTryAge,
      'settings': <String, Object?>{
        'casinoEnabled': state.settings.casinoEnabled,
        'wagerLimitPerAge': state.settings.wagerLimitPerAge,
        'soundEnabled': state.settings.soundEnabled,
      },
      'deceased': state.deceased,
      'deathAge': state.deathAge,
      'deathCause': state.deathCause,
    };

/// Kumarhane eli: deste **olduğu gibi** yazılır, böylece kayıt geri
/// yüklenince aynı el aynı kartlarla sürer.
Map<String, Object?> _encodeBlackjack(BlackjackGame g) => <String, Object?>{
      'bet': g.bet,
      'deck': g.deck.map((PlayingCard c) => c.code).toList(growable: false),
      'playerCards':
          g.playerCards.map((PlayingCard c) => c.code).toList(growable: false),
      'dealerCards':
          g.dealerCards.map((PlayingCard c) => c.code).toList(growable: false),
      'phase': g.phase.name,
      'startedAtAge': g.startedAtAge,
      'result': g.result?.name,
      'payout': g.payout,
      'settled': g.settled,
    };

Map<String, Object?> _encodePlayer(PlayerCharacter p) => <String, Object?>{
      'id': p.id,
      'firstName': p.firstName,
      'lastName': p.lastName,
      'gender': p.gender.name,
      'age': p.age,
      'birthCity': p.birthCity,
      'currentCity': p.currentCity,
      'stats': <String, Object?>{
        'appearance': p.stats.appearance,
        'happiness': p.stats.happiness,
        'health': p.stats.health,
        'intelligence': p.stats.intelligence,
        'charisma': p.stats.charisma,
      },
      'fame': p.fame,
      'wallet': p.wallet,
      'hairStyle': p.hairStyle,
      'hairLossStage': p.hairLossStage,
      'infertile': p.infertile,
      // Doğum ayı ve günü (Paket 27). **Yıl yoktur** (D-003).
      'birthMonth': p.birthDate?.month,
      'birthDay': p.birthDate?.day,
    };

Map<String, Object?> _encodeAccount(SocialAccount a) => <String, Object?>{
      'platform': a.platform.name,
      'createdAtAge': a.createdAtAge,
      'followers': a.followers,
      'posts': a.posts
          .map((SocialPost p) => <String, Object?>{
                'contentId': p.contentId,
                'age': p.age,
                'followerDelta': p.followerDelta,
                'earned': p.earned,
                'sponsorId': p.sponsorId,
              })
          .toList(growable: false),
    };

Map<String, Object?> _encodeBook(BookProgress b) => <String, Object?>{
      'bookId': b.bookId,
      'pagesRead': b.pagesRead,
      'finished': b.finished,
      'startedAtAge': b.startedAtAge,
    };

Map<String, Object?> _encodeMartial(MartialProgress m) => <String, Object?>{
      'artId': m.artId,
      'lessons': m.lessons,
      'startedAtAge': m.startedAtAge,
      'topRankAtAge': m.topRankAtAge,
    };

Map<String, Object?> _encodeTicket(LotteryTicket t) => <String, Object?>{
      'drawId': t.drawId,
      'share': t.share.name,
      'number': t.number,
      'boughtAtAge': t.boughtAtAge,
      'price': t.price,
    };

Map<String, Object?> _encodeFinger(FingerProfile p) => <String, Object?>{
      'id': p.id,
      'firstName': p.firstName,
      'lastName': p.lastName,
      'gender': p.gender.name,
      'age': p.age,
      'city': p.city,
      'bio': p.bio,
      'interests': p.interests,
      'occupation': p.occupation,
      'matchedAtAge': p.matchedAtAge,
      'metPersonId': p.metPersonId,
    };

Map<String, Object?> _encodeHobby(HobbyProgress h) => <String, Object?>{
      'hobbyId': h.hobbyId,
      'startedAtAge': h.startedAtAge,
      'experience': h.experience,
      'lastPracticedAge': h.lastPracticedAge,
      'memories': h.memories
          .map((HobbyMemory m) => <String, Object?>{
                'age': m.age,
                'text': m.text,
              })
          .toList(growable: false),
    };

Map<String, Object?> _encodePerson(Person p) => <String, Object?>{
      'id': p.id,
      'firstName': p.firstName,
      'lastName': p.lastName,
      'gender': p.gender.name,
      'relation': p.relation.name,
      'workplaceId': p.workplaceId,
      'city': p.city,
      'age': p.age,
      'isAlive': p.isAlive,
      'inPlayerHousehold': p.inPlayerHousehold,
      'employment': p.employment.name,
      'occupation': p.occupation,
      'wealth': p.wealth?.name,
      'bond': p.bond,
      'happiness': p.happiness,
      'schoolLevel': p.schoolLevel?.name,
      'schoolTie': p.schoolTie?.name,
      'schoolId': p.schoolId,
      'classId': p.classId,
      'estate': p.estate,
      'infertile': p.infertile,
      // Kişinin kendi hayatı (D-045); yalnızca kaydı olanlarda doludur.
      'development': p.development == null
          ? null
          : _encodeDevelopment(p.development!),
    };

Map<String, Object?> _encodeDevelopment(PersonDevelopment d) =>
    <String, Object?>{
      'tracksLife': d.tracksLife,
      'stats': <String, Object?>{
        'appearance': d.stats.appearance,
        'happiness': d.stats.happiness,
        'health': d.stats.health,
        'intelligence': d.stats.intelligence,
        'charisma': d.stats.charisma,
      },
      'schoolLevel': d.schoolLevel?.name,
      'grade': d.grade,
      'finishedSchool': d.finishedSchool,
      'university': d.university?.name,
      'universityYear': d.universityYear,
      'universityProgramId': d.universityProgramId,
      'jobId': d.jobId,
      'jobStartedAtAge': d.jobStartedAtAge,
      'pastJobIds': d.pastJobIds,
      'money': d.money,
      'interests': d.interests,
      'otherParentId': d.otherParentId,
      'track': d.track?.name,
      'adopted': d.adopted,
      'milestones': <Map<String, Object?>>[
        for (final LifeMilestone m in d.milestones)
          <String, Object?>{'age': m.age, 'text': m.text},
      ],
    };

PersonDevelopment _decodeDevelopment(Map<String, Object?> json) {
  final Map<String, Object?> stats = _asMap(json['stats'], 'development.stats');
  return PersonDevelopment(
    tracksLife: json['tracksLife'] == true,
    stats: Stats(
      appearance: _int(stats, 'appearance'),
      happiness: _int(stats, 'happiness'),
      health: _int(stats, 'health'),
      intelligence: _int(stats, 'intelligence'),
      charisma: _int(stats, 'charisma'),
    ),
    schoolLevel: _enumByNameOrNull(
      SchoolLevel.values,
      _stringOrNull(json, 'schoolLevel'),
      'development.schoolLevel',
    ),
    grade: _intOrNull(json, 'grade'),
    finishedSchool: json['finishedSchool'] == true,
    university: _enumByNameOrNull(
      UniversityStatus.values,
      _stringOrNull(json, 'university'),
      'development.university',
    ),
    universityYear: _intOrNull(json, 'universityYear'),
    universityProgramId: _stringOrNull(json, 'universityProgramId'),
    jobId: _stringOrNull(json, 'jobId'),
    jobStartedAtAge: _intOrNull(json, 'jobStartedAtAge'),
    pastJobIds: List<String>.unmodifiable(
      json['pastJobIds'] == null ? const <String>[] : _stringList(json, 'pastJobIds'),
    ),
    money: json['money'] == null ? 0 : _int(json, 'money'),
    interests: List<String>.unmodifiable(
      json['interests'] == null ? const <String>[] : _stringList(json, 'interests'),
    ),
    otherParentId: _stringOrNull(json, 'otherParentId'),
    track: _enumByNameOrNull(
      EducationTrack.values,
      _stringOrNull(json, 'track'),
      'development.track',
    ),
    adopted: json['adopted'] == true,
    milestones: List<LifeMilestone>.unmodifiable(<LifeMilestone>[
      for (final Object? e in _optionalRawList(json, 'milestones'))
        LifeMilestone(
          age: _int(_asMap(e, 'milestone'), 'age'),
          text: _string(_asMap(e, 'milestone'), 'text'),
        ),
    ]),
  );
}

Map<String, Object?> _encodeLifeSummary(LifeSummary l) => <String, Object?>{
      'familyLine': l.familyLine,
      'generation': l.generation,
      'fullName': l.fullName,
      'birthCity': l.birthCity,
      'deathAge': l.deathAge,
      'deathCause': l.deathCause,
      'educationLabel': l.educationLabel,
      'careerLabel': l.careerLabel,
      'wallet': l.wallet,
      'itemCount': l.itemCount,
      'licenseCount': l.licenseCount,
      'highlights': l.highlights,
      'verdictTitle': l.verdictTitle,
    };

LifeSummary _decodeLifeSummary(Map<String, Object?> json) => LifeSummary(
      fullName: _string(json, 'fullName'),
      birthCity: _string(json, 'birthCity'),
      deathAge: _int(json, 'deathAge'),
      deathCause: _string(json, 'deathCause'),
      educationLabel: _string(json, 'educationLabel'),
      careerLabel: _string(json, 'careerLabel'),
      wallet: _int(json, 'wallet'),
      itemCount: _int(json, 'itemCount'),
      licenseCount: _int(json, 'licenseCount'),
      highlights: List<String>.unmodifiable(_stringList(json, 'highlights')),
      // Eski arşiv kayıtlarında aile satırı yoktur; `null` kalır ve
      // ekranda hiç gösterilmez. Arşiv silinmez.
      familyLine: _stringOrNull(json, 'familyLine'),
      // Eski arşiv kayıtlarında kuşak bilgisi yoktur; `null` kalır ve
      // ekranda hiç gösterilmez.
      generation: _intOrNull(json, 'generation'),
      // Eski arşiv kayıtlarında değerlendirme adı yoktur; `null` kalır ve
      // satırda hiç gösterilmez. Geriye dönük ad üretilmez.
      verdictTitle: _stringOrNull(json, 'verdictTitle'),
    );

Map<String, Object?> _encodeItem(OwnedItem i) => <String, Object?>{
      'id': i.id,
      'typeId': i.typeId,
      'acquiredAtAge': i.acquiredAtAge,
      'source': i.source.name,
      'fromPersonId': i.fromPersonId,
      'condition': i.condition,
      'attachments': i.attachments,
      'purchasePrice': i.purchasePrice,
      'location': i.location,
      'rentedOut': i.rentedOut,
    };

Map<String, Object?> _encodeGift(GiftRecord g) => <String, Object?>{
      'itemId': g.itemId,
      'fromId': g.fromId,
      'toId': g.toId,
      'age': g.age,
    };

Map<String, Object?> _encodePet(Pet pet) => <String, Object?>{
      'id': pet.id,
      'name': pet.name,
      'species': pet.species,
      // Paket 40 alanları: tamamen ekleme, eski kayıtta yoksa varsayılan
      // okunur (kayıt biçimi sürümü değişmedi).
      'age': pet.age,
      'adoptedAtPlayerAge': pet.adoptedAtPlayerAge,
      'inPlayerHousehold': pet.inPlayerHousehold,
      'diedAtAge': pet.diedAtAge,
      'diedAtPlayerAge': pet.diedAtPlayerAge,
      'lastCareChargedPlayerAge': pet.lastCareChargedPlayerAge,
      'bond': pet.bond,
    };

Map<String, Object?> _encodeLogEntry(LifeLogEntry e) => <String, Object?>{
      'age': e.age,
      'text': e.text,
      'category': e.category.name,
          'personId': e.personId,
};

Map<String, Object?> _encodeEducation(EducationState e) => <String, Object?>{
      'enrolled': e.enrolled,
      'grade': e.grade,
      'startedAtAge': e.startedAtAge,
      'finished': e.finished,
      'schoolId': e.schoolId,
      'classId': e.classId,
      'track': e.track?.name,
      'placementScore': e.placementScore,
      'universityExamScore': e.universityExamScore,
      'universityProgramId': e.universityProgramId,
      'universityYear': e.universityYear,
      'universityFinished': e.universityFinished,
          // Okul başarısı (Paket 13).
      'gradeAverage': e.gradeAverage,
      'repeatedYears': e.repeatedYears,
      'droppedOut': e.droppedOut,
      'scholarshipSinceAge': e.scholarshipSinceAge,
};

Map<String, Object?> _encodeCareer(CareerState c) => <String, Object?>{
      'jobCity': c.jobCity,
      'jobId': c.jobId,
      'startedAtAge': c.startedAtAge,
      'lastPaidAge': c.lastPaidAge,
      'pastJobIds': c.pastJobIds,
      // Kariyer derinliği (Paket 9): görev seviyesi, gerçek maaş, önemli
      // anlar ve bitmiş çalışma kayıtları.
      'level': c.level,
      'salary': c.salary,
      'milestones': c.milestones.map(_encodeCareerMilestone).toList(
            growable: false,
          ),
      'history': c.history.map(_encodeJobHistory).toList(growable: false),
      'lastRaiseAge': c.lastRaiseAge,
      'lastPromotionAge': c.lastPromotionAge,
      'lastJobLossAge': c.lastJobLossAge,
      // Emeklilik (Paket 12).
      'retiredAtAge': c.retiredAtAge,
      'pension': c.pension,
      // İşveren uyarıları (D-078). Alan eklemeli; eski kayıtta sıfır.
      'employerWarnings': c.employerWarnings,
    };

Map<String, Object?> _encodeCareerMilestone(CareerMilestone m) =>
    <String, Object?>{'age': m.age, 'text': m.text};

Map<String, Object?> _encodeJobHistory(JobHistoryEntry e) => <String, Object?>{
      'jobId': e.jobId,
      'startedAtAge': e.startedAtAge,
      'endedAtAge': e.endedAtAge,
      'endReason': e.endReason?.name,
      'level': e.level,
      'salary': e.salary,
      'city': e.city,
      'milestones':
          e.milestones.map(_encodeCareerMilestone).toList(growable: false),
    };

/// Bekleyen olay **tüm seçenekleriyle** yazılır.
///
/// Böylece uygulama yeniden açıldığında olay havuzdan yeniden üretilmez:
/// aynı metin, aynı kişi ve aynı seçenekler geri gelir. Olay havuzu
/// güncellense bile oyuncunun ekranındaki soru değişmez.
Map<String, Object?> _encodeActiveEvent(ActiveEvent e) => <String, Object?>{
      'eventId': e.eventId,
      'category': e.category.name,
      'text': e.text,
      'personId': e.personId,
      'choices': e.choices.map(_encodeChoice).toList(growable: false),
    };

Map<String, Object?> _encodeChoice(EventChoice c) => <String, Object?>{
      'id': c.id,
      'label': c.label,
      'resultText': c.resultText,
      'happiness': c.happiness,
      'health': c.health,
      'intelligence': c.intelligence,
      'charisma': c.charisma,
      'appearance': c.appearance,
      'bond': c.bond,
      'money': c.money,
      'addFlags': c.addFlags.toList(growable: false),
      'removeFlags': c.removeFlags.toList(growable: false),
      'addPossessions': c.addPossessions.toList(growable: false),
      'startsRomance': c.startsRomance,
      'endsRomance': c.endsRomance,
      'startsSchoolFriendship': c.startsSchoolFriendship,
      'startsFriendship': c.startsFriendship,
      'rememberPersonAs': c.rememberPersonAs,
    };

// =====================================================================
// Okuma
// =====================================================================

GameState decodeGameState(Map<String, Object?> json) {
  final PlayerCharacter player =
      _decodePlayer(_map(json, 'player'), 'player');

  final List<Person> people = _list(json, 'people')
      .map((Object? e) => _decodePerson(_asMap(e, 'people[]')))
      .toList(growable: false);

  // Aynı kimlikten iki kayıt, aynı kişinin ikiye bölünmesi demektir.
  final Set<String> gorulenKimlikler = <String>{};
  for (final Person p in people) {
    if (!gorulenKimlikler.add(p.id)) {
      throw SaveFormatException(
        'Kayıtta aynı kişi kimliği birden fazla kez geçiyor: ${p.id}',
      );
    }
  }

  // Aynı eşya kimliğinden iki kayıt, aynı eşyanın ikiye bölünmesi demektir.
  final Object? hamEsyalar = json['items'];
  if (hamEsyalar is List) {
    final Set<String> gorulenEsyalar = <String>{};
    for (final Object? e in hamEsyalar) {
      if (e is! Map) continue;
      final Object? id = e['id'];
      if (id is String && !gorulenEsyalar.add(id)) {
        throw SaveFormatException(
          'Kayıtta aynı eşya kimliği birden fazla kez geçiyor: $id',
        );
      }
    }
  }

  // Eş bağı taşıyan kişi varsa evlilik kaydı da olmalı; aksi hâlde
  // "eşi olan ama evliliği olmayan" tutarsız bir hayat yüklenirdi.
  if (json['marriage'] == null &&
      people.any((Person p) => p.relation == RelationType.es)) {
    throw const SaveFormatException(
      'Kayıtta eş bağı var ama evlilik kaydı yok; dosya tutarsız.',
    );
  }

  // Evlilik kaydı, listede gerçekten bulunan bir kişiyi göstermeli;
  // aksi hâlde "eşi olan ama eşi olmayan" bir hayat yüklenirdi.
  final Object? hamEvlilik = json['marriage'];
  if (hamEvlilik is Map) {
    final Object? spouseId = hamEvlilik['spouseId'];
    if (spouseId is String &&
        !people.any((Person p) => p.id == spouseId)) {
      throw SaveFormatException(
        'Kayıttaki evlilik, bulunmayan bir kişiyi gösteriyor: $spouseId',
      );
    }
  }

  final Object? pending = json['pendingEvent'];

  return GameState(
    seed: _int(json, 'seed'),
    player: player,
    people: List<Person>.unmodifiable(people),
    pets: List<Pet>.unmodifiable(
      _list(json, 'pets')
          .map((Object? e) => _decodePet(_asMap(e, 'pets[]')))
          .toList(growable: false),
    ),
    parentalStatus: _enumByName(
      ParentalStatus.values,
      _string(json, 'parentalStatus'),
      'parentalStatus',
    ),
    log: List<LifeLogEntry>.unmodifiable(
      _list(json, 'log')
          .map((Object? e) => _decodeLogEntry(_asMap(e, 'log[]')))
          .toList(growable: false),
    ),
    interactionCounts:
        Map<String, int>.unmodifiable(_intMap(json, 'interactionCounts')),
    lastInteractionAge:
        Map<String, int>.unmodifiable(_intMap(json, 'lastInteractionAge')),
    storyFlags: Set<String>.unmodifiable(_stringSet(json, 'storyFlags')),
    items: List<OwnedItem>.unmodifiable(
      _list(json, 'items')
          .map((Object? e) => _decodeItem(_asMap(e, 'items[]')))
          .toList(growable: false),
    ),
    seenEventIds: Set<String>.unmodifiable(_stringSet(json, 'seenEventIds')),
    lastEventAge: Map<String, int>.unmodifiable(_intMap(json, 'lastEventAge')),
    eventSeenCounts:
        Map<String, int>.unmodifiable(_intMap(json, 'eventSeenCounts')),
    storyPeople: Map<String, String>.unmodifiable(
      _stringMap(json, 'storyPeople'),
    ),
    // Eski kayıtlarda hediye geçmişi yoktur; boş liste ile açılır.
    gifts: List<GiftRecord>.unmodifiable(
      json['gifts'] == null
          ? const <GiftRecord>[]
          : _list(json, 'gifts')
              .map((Object? e) => _decodeGift(_asMap(e, 'gifts[]')))
              .toList(growable: false),
    ),
    pendingEvent: pending == null
        ? null
        : _decodeActiveEvent(_asMap(pending, 'pendingEvent')),
    progressSinceLastEvent: _int(json, 'progressSinceLastEvent'),
    extraEventsThisAge: _int(json, 'extraEventsThisAge'),
    education: _decodeEducation(_map(json, 'education')),
    career: _decodeCareer(_map(json, 'career')),
    pendingInterview: json['pendingInterview'] == null
        ? null
        : _decodeInterview(_asMap(json['pendingInterview'], 'pendingInterview')),
    books: List<BookProgress>.unmodifiable(
      _list(json, 'books')
          .map((Object? e) => _decodeBook(_asMap(e, 'books[]')))
          .toList(growable: false),
    ),
    hobbies: List<HobbyProgress>.unmodifiable(
      _optionalRawList(json, 'hobbies')
          .map((Object? e) => _decodeHobby(_asMap(e, 'hobbies[]')))
          .toList(growable: false),
    ),
    martialArts: List<MartialProgress>.unmodifiable(
      _optionalRawList(json, 'martialArts')
          .map((Object? e) => _decodeMartial(_asMap(e, 'martialArts[]')))
          .toList(growable: false),
    ),
    lotteryTickets: List<LotteryTicket>.unmodifiable(
      _optionalRawList(json, 'lotteryTickets')
          .map((Object? e) => _decodeTicket(_asMap(e, 'lotteryTickets[]')))
          .toList(growable: false),
    ),
    celebrityContacts: List<CelebrityContact>.unmodifiable(
      _optionalRawList(json, 'celebrityContacts')
          .map((Object? e) =>
              _decodeCelebrityContact(_asMap(e, 'celebrityContacts[]')))
          .toList(growable: false),
    ),
    fingerDeck: List<FingerProfile>.unmodifiable(
      _optionalRawList(json, 'fingerDeck')
          .map((Object? e) => _decodeFinger(_asMap(e, 'fingerDeck[]')))
          .toList(growable: false),
    ),
    fingerMatches: List<FingerProfile>.unmodifiable(
      _optionalRawList(json, 'fingerMatches')
          .map((Object? e) => _decodeFinger(_asMap(e, 'fingerMatches[]')))
          .toList(growable: false),
    ),
    socialAccounts: List<SocialAccount>.unmodifiable(
      _list(json, 'socialAccounts')
          .map((Object? e) => _decodeAccount(_asMap(e, 'socialAccounts[]')))
          .toList(growable: false),
    ),
    // Eski kayıtlarda sponsorluk yoktur; boş açılır.
    sponsorOffer: json['sponsorOffer'] == null
        ? null
        : _decodeSponsorOffer(_map(json, 'sponsorOffer')),
    // Eski kayıtlarda gezi yoktur; boş açılır ve geriye dönük gezi
    // uydurulmaz.
    trips: List<TripRecord>.unmodifiable(
      _optionalList(json, 'trips').map(_decodeTrip),
    ),
    sponsorDeals: List<SponsorDeal>.unmodifiable(
      _optionalList(json, 'sponsorDeals').map(_decodeSponsorDeal),
    ),
    // Eski kayıtlarda kumarhane yoktur; masa boş açılır.
    blackjack: json['blackjack'] == null
        ? null
        : _decodeBlackjack(_asMap(json['blackjack'], 'blackjack')),
    wagerThisAge: json['wagerThisAge'] == null ? 0 : _int(json, 'wagerThisAge'),
    loans: List<Loan>.unmodifiable(
      _optionalRawList(json, 'loans')
          .map((Object? e) => _decodeLoan(_asMap(e, 'loan')))
          .toList(growable: false),
    ),
    lastSportAge: _intOrNull(json, 'lastSportAge'),
    lastGroomingAge: _intOrNull(json, 'lastGroomingAge'),
    lastLearningAge: _intOrNull(json, 'lastLearningAge'),
    // Eski kayıtlarda ehliyet yoktur; boş kümeyle açılır.
    licenses: Set<String>.unmodifiable(
      json['licenses'] == null
          ? const <String>{}
          : _stringSet(json, 'licenses'),
    ),
    pendingLicenseExam: json['pendingLicenseExam'] == null
        ? null
        : _decodeLicenseExam(
            _asMap(json['pendingLicenseExam'], 'pendingLicenseExam'),
          ),
    // Eski kayıtlarda ölüm ve miras alanları yoktur; hayat sürüyor sayılır
    // ve kimse vefat etmiş olarak açılmaz.
    settledEstates: Set<String>.unmodifiable(
      json['settledEstates'] == null
          ? const <String>{}
          : _stringSet(json, 'settledEstates'),
    ),
    deceased: json['deceased'] == true,
    // Eski kayıtlarda arşiv, bakım durumu, yas ve ayarlar yoktur; güvenli
    // varsayılanlarla açılır ve hiçbir hayat silinmez.
    pastLives: List<LifeSummary>.unmodifiable(
      json['pastLives'] == null
          ? const <LifeSummary>[]
          : _list(json, 'pastLives')
              .map((Object? e) => _decodeLifeSummary(_asMap(e, 'pastLives[]')))
              .toList(growable: false),
    ),
    careStatus: _enumByNameOrNull(
          CareStatus.values,
          _stringOrNull(json, 'careStatus'),
          'careStatus',
        ) ??
        CareStatus.aileYaninda,
    grief: json['grief'] == null ? 0 : _int(json, 'grief'),
    // Eski kayıtlarda oturma bilgisi yoktur; oyuncu ailesinin yanında
    // sayılır ve mülkleri olduğu gibi korunur.
    // Eski kayıtlarda sağlık krizi yoktur; boş açılır.
    pendingCrisis: json['pendingCrisis'] == null
        ? null
        : PendingCrisis(
            crisisId: _string(
              _asMap(json['pendingCrisis'], 'pendingCrisis'),
              'crisisId',
            ),
            age: _int(_asMap(json['pendingCrisis'], 'pendingCrisis'), 'age'),
          ),
    lastCrisisAge: _intOrNull(json, 'lastCrisisAge'),
    healthWarned: json['healthWarned'] == true,
    residenceItemId: _stringOrNull(json, 'residenceItemId'),
    movedOut: json['movedOut'] == true,
    // Eski kayıtlarda evlilik kaydı yoktur; hayat bekâr sürer, kişiler
    // olduğu gibi korunur.
    marriage: json['marriage'] == null
        ? null
        : _decodeMarriage(_asMap(json['marriage'], 'marriage')),
    pastMarriages: List<Marriage>.unmodifiable(
      _optionalRawList(json, 'pastMarriages')
          .map((Object? e) => _decodeMarriage(_asMap(e, 'pastMarriages[]')))
          .toList(growable: false),
    ),
    // Eski kayıtlarda bekleyen düğün yoktur; boş açılır ve **uydurma bir
    // evlilik üretilmez** (Paket 25).
    pendingWedding: json['pendingWedding'] == null
        ? null
        : _decodePendingWedding(
            _asMap(json['pendingWedding'], 'pendingWedding'),
          ),
    // Eski kayıtlarda hamilelik yoktur; **geriye dönük bebek
    // beklenmez** (Paket 26).
    pregnancy: json['pregnancy'] == null
        ? null
        : _decodePregnancy(_asMap(json['pregnancy'], 'pregnancy')),
    // Eski kayıtlarda askerlik kaydı yoktur; **geriye dönük askerlik
    // uydurulmaz**, durum "yapılmadı" olarak açılır (Paket 29).
    military: json['military'] == null
        ? const MilitaryState()
        : _decodeMilitary(_asMap(json['military'], 'military')),
    // Eski kayıtlarda deneme sayacı yoktur; sıfırdan başlar.
    unprotectedTries: _intOrNull(json, 'unprotectedTries') ?? 0,
    ivfAttempts: _intOrNull(json, 'ivfAttempts') ?? 0,
    lastConceptionTryAge: _intOrNull(json, 'lastConceptionTryAge'),
    // Eski kayıtlarda kuşak bilgisi yoktur: o hayatlar ilk kuşaktır.
    generation: _intOrNull(json, 'generation') ?? 1,
    // Eski kayıtlarda teklif geçmişi yoktur; boş açılır.
    proposalAges: Map<String, int>.unmodifiable(
      json['proposalAges'] == null
          ? const <String, int>{}
          : _intMap(json, 'proposalAges'),
    ),
    // Eski kayıtlarda vasiyet seçimi yoktur; `null` kalır.
    heirChildId: _stringOrNull(json, 'heirChildId'),
    // Eski kayıtlarda bildirim kuyruğu yoktur; boş açılır ve geriye
    // dönük bildirim üretilmez.
    notices: List<PendingNotice>.unmodifiable(<PendingNotice>[
      for (final Object? e
          in _optionalRawList(json, 'notices'))
        _decodeNotice(_asMap(e, 'notice')),
    ]),
    hardshipYears:
        json['hardshipYears'] == null ? 0 : _int(json, 'hardshipYears'),
    settings: json['settings'] == null
        ? const GameSettings()
        : GameSettings(
            casinoEnabled:
                _asMap(json['settings'], 'settings')['casinoEnabled'] != false,
            wagerLimitPerAge: _intOrNull(
              _asMap(json['settings'], 'settings'),
              'wagerLimitPerAge',
            ),
            // Eski kayıtlarda ses ayarı yoktur; açık kabul edilir.
            soundEnabled:
                _asMap(json['settings'], 'settings')['soundEnabled'] != false,
          ),
    deathAge: _intOrNull(json, 'deathAge'),
    deathCause: _stringOrNull(json, 'deathCause'),
  );
}

BlackjackGame _decodeBlackjack(Map<String, Object?> json) {
  List<PlayingCard> kartlar(String alan) => List<PlayingCard>.unmodifiable(
        _list(json, alan)
            .map((Object? e) {
              final PlayingCard? card = PlayingCard.fromCode('$e');
              if (card == null) {
                throw const SaveFormatException(
                  'Kumarhane kaydındaki kart okunamadı.',
                );
              }
              return card;
            })
            .toList(growable: false),
      );

  final String? sonucAdi = _stringOrNull(json, 'result');
  return BlackjackGame(
    bet: _int(json, 'bet'),
    deck: kartlar('deck'),
    playerCards: kartlar('playerCards'),
    dealerCards: kartlar('dealerCards'),
    phase: BlackjackPhase.values.firstWhere(
      (BlackjackPhase p) => p.name == _string(json, 'phase'),
      orElse: () => BlackjackPhase.oyuncu,
    ),
    startedAtAge: _int(json, 'startedAtAge'),
    result: sonucAdi == null
        ? null
        : BlackjackResult.values.firstWhere(
            (BlackjackResult r) => r.name == sonucAdi,
            orElse: () => BlackjackResult.berabere,
          ),
    payout: _int(json, 'payout'),
    settled: json['settled'] == true,
  );
}

PlayerCharacter _decodePlayer(Map<String, Object?> json, String path) {
  final Map<String, Object?> stats = _map(json, 'stats');
  return PlayerCharacter(
    id: _string(json, 'id'),
    firstName: _string(json, 'firstName'),
    lastName: _string(json, 'lastName'),
    gender: _enumByName(Gender.values, _string(json, 'gender'), '$path.gender'),
    age: _int(json, 'age'),
    birthCity: _string(json, 'birthCity'),
    // Eski kayıtlarda yaşanan şehir yoktur; doğum şehri kullanılır.
    currentCity: _stringOrNull(json, 'currentCity'),
    stats: Stats(
      appearance: _int(stats, 'appearance'),
      happiness: _int(stats, 'happiness'),
      health: _int(stats, 'health'),
      intelligence: _int(stats, 'intelligence'),
      charisma: _int(stats, 'charisma'),
    ),
    fame: _intOrNull(json, 'fame'),
    wallet: _int(json, 'wallet'),
    hairStyle: _stringOrNull(json, 'hairStyle'),
    // Eski kayıtlarda saç dökülmesi yoktur; dökülmemiş sayılır.
    hairLossStage: _intOr(json, 'hairLossStage', 0),
    // Eski kayıtlarda doğurganlık bilgisi yoktur; kısır sayılmaz.
    infertile: _boolOr(json, 'infertile'),
    // Eski kayıtlarda doğum ayı/günü yoktur; boş kalır. Burç o zaman
    // hayatın tohumundan **deterministik** türetilir (Paket 27), yani
    // eski hayat da burcunu görür ve her açılışta aynı burcu görür.
    birthDate: json['birthMonth'] == null || json['birthDay'] == null
        ? null
        : BirthDate(
            month: _int(json, 'birthMonth'),
            day: _int(json, 'birthDay'),
          ),
  );
}

Map<String, Object?> _encodeCelebrityContact(CelebrityContact c) =>
    <String, Object?>{
      'celebrityId': c.celebrityId,
      'attempts': c.attempts,
      'replied': c.replied,
      'followsBack': c.followsBack,
      'collaborated': c.collaborated,
      'firstContactAge': c.firstContactAge,
      'lastContactAge': c.lastContactAge,
    };

CelebrityContact _decodeCelebrityContact(Map<String, Object?> json) =>
    CelebrityContact(
      celebrityId: _string(json, 'celebrityId'),
      attempts: _intOr(json, 'attempts', 0),
      replied: _boolOr(json, 'replied', varsayilan: false),
      followsBack: _boolOr(json, 'followsBack', varsayilan: false),
      collaborated: _boolOr(json, 'collaborated', varsayilan: false),
      firstContactAge: _intOrNull(json, 'firstContactAge'),
      lastContactAge: _intOrNull(json, 'lastContactAge'),
    );

SocialAccount _decodeAccount(Map<String, Object?> json) => SocialAccount(
      platform: _enumByName(
        SocialPlatform.values,
        _string(json, 'platform'),
        'socialAccount.platform',
      ),
      createdAtAge: _int(json, 'createdAtAge'),
      followers: _int(json, 'followers'),
      posts: List<SocialPost>.unmodifiable(
        _list(json, 'posts')
            .map((Object? e) => _decodePost(_asMap(e, 'posts[]')))
            .toList(growable: false),
      ),
    );

SocialPost _decodePost(Map<String, Object?> json) => SocialPost(
      contentId: _string(json, 'contentId'),
      age: _int(json, 'age'),
      followerDelta: _int(json, 'followerDelta'),
      // Eski kayıtlarda gelir yoktur; geriye dönük kazanç uydurulmaz.
      earned: _intOrNull(json, 'earned') ?? 0,
      sponsorId: _stringOrNull(json, 'sponsorId'),
    );

Map<String, Object?> _encodeTrip(TripRecord t) => <String, Object?>{
      'id': t.id,
      'city': t.city,
      'age': t.age,
      'mode': t.mode.name,
      'cost': t.cost,
      'companionId': t.companionId,
      'note': t.note,
    };

TripRecord _decodeTrip(Map<String, Object?> json) => TripRecord(
      id: _string(json, 'id'),
      city: _string(json, 'city'),
      age: _int(json, 'age'),
      mode: _enumByName(TravelMode.values, _string(json, 'mode'), 'trip.mode'),
      cost: _int(json, 'cost'),
      companionId: _stringOrNull(json, 'companionId'),
      note: _stringOrNull(json, 'note'),
    );

Map<String, Object?> _encodeSponsorOffer(SponsorOffer o) => <String, Object?>{
      'id': o.id,
      'categoryId': o.categoryId,
      'platform': o.platform.name,
      'fee': o.fee,
      'offeredAtAge': o.offeredAtAge,
    };

SponsorOffer _decodeSponsorOffer(Map<String, Object?> json) => SponsorOffer(
      id: _string(json, 'id'),
      categoryId: _string(json, 'categoryId'),
      platform: _enumByName(
        SocialPlatform.values,
        _string(json, 'platform'),
        'sponsorOffer.platform',
      ),
      fee: _int(json, 'fee'),
      offeredAtAge: _int(json, 'offeredAtAge'),
    );

Map<String, Object?> _encodeSponsorDeal(SponsorDeal d) => <String, Object?>{
      'id': d.id,
      'categoryId': d.categoryId,
      'platform': d.platform.name,
      'fee': d.fee,
      'acceptedAtAge': d.acceptedAtAge,
      'completedAtAge': d.completedAtAge,
      'expired': d.expired,
    };

SponsorDeal _decodeSponsorDeal(Map<String, Object?> json) => SponsorDeal(
      id: _string(json, 'id'),
      categoryId: _string(json, 'categoryId'),
      platform: _enumByName(
        SocialPlatform.values,
        _string(json, 'platform'),
        'sponsorDeal.platform',
      ),
      fee: _int(json, 'fee'),
      acceptedAtAge: _int(json, 'acceptedAtAge'),
      completedAtAge: _intOrNull(json, 'completedAtAge'),
      expired: json['expired'] == true,
    );

BookProgress _decodeBook(Map<String, Object?> json) => BookProgress(
      bookId: _string(json, 'bookId'),
      pagesRead: _int(json, 'pagesRead'),
      finished: _bool(json, 'finished'),
      startedAtAge: _intOrNull(json, 'startedAtAge'),
    );

MartialProgress _decodeMartial(Map<String, Object?> json) => MartialProgress(
      artId: _string(json, 'artId'),
      lessons: _int(json, 'lessons'),
      startedAtAge: _intOrNull(json, 'startedAtAge'),
      topRankAtAge: _intOrNull(json, 'topRankAtAge'),
    );

LotteryTicket _decodeTicket(Map<String, Object?> json) => LotteryTicket(
      drawId: _string(json, 'drawId'),
      share: ticketShareByName(_string(json, 'share')) ?? TicketShare.tam,
      number: _string(json, 'number'),
      boughtAtAge: _int(json, 'boughtAtAge'),
      price: _int(json, 'price'),
    );

FingerProfile _decodeFinger(Map<String, Object?> json) => FingerProfile(
      id: _string(json, 'id'),
      firstName: _string(json, 'firstName'),
      lastName: _string(json, 'lastName'),
      gender: _enumByName(Gender.values, _string(json, 'gender'), 'gender'),
      age: _int(json, 'age'),
      city: _string(json, 'city'),
      bio: _string(json, 'bio'),
      interests: List<String>.unmodifiable(
        _optionalRawList(json, 'interests')
            .map((Object? e) => e.toString())
            .toList(growable: false),
      ),
      occupation: _stringOrNull(json, 'occupation'),
      matchedAtAge: _intOrNull(json, 'matchedAtAge'),
      metPersonId: _stringOrNull(json, 'metPersonId'),
    );

HobbyProgress _decodeHobby(Map<String, Object?> json) => HobbyProgress(
      hobbyId: _string(json, 'hobbyId'),
      startedAtAge: _int(json, 'startedAtAge'),
      experience: _int(json, 'experience'),
      lastPracticedAge: _int(json, 'lastPracticedAge'),
      memories: List<HobbyMemory>.unmodifiable(
        _optionalRawList(json, 'memories')
            .map((Object? e) {
          final Map<String, Object?> m = _asMap(e, 'hobbies[].memories[]');
          return HobbyMemory(age: _int(m, 'age'), text: _string(m, 'text'));
        }).toList(growable: false),
      ),
    );

/// Evlilik kaydı. Eşin kendisi kişi listesinden okunur; burada yalnızca
/// birlikteliğin kaydı vardır.
Marriage _decodeMarriage(Map<String, Object?> json) => Marriage(
      spouseId: _string(json, 'spouseId'),
      marriedAtAge: _int(json, 'marriedAtAge'),
      status: _enumByName(
        MarriageStatus.values,
        _string(json, 'status'),
        'marriage.status',
      ),
      endedAtAge: _intOrNull(json, 'endedAtAge'),
    );

PendingNotice _decodeNotice(Map<String, Object?> json) => PendingNotice(
      id: _string(json, 'id'),
      kind: _enumByName(NoticeKind.values, _string(json, 'kind'), 'notice.kind'),
      age: _int(json, 'age'),
      title: _string(json, 'title'),
      text: _string(json, 'text'),
      personId: _stringOrNull(json, 'personId'),
      money: json['money'] == null ? 0 : _int(json, 'money'),
      itemNames: List<String>.unmodifiable(
        json['itemNames'] == null
            ? const <String>[]
            : _stringList(json, 'itemNames'),
      ),
      happinessDelta:
          json['happinessDelta'] == null ? 0 : _int(json, 'happinessDelta'),
      funeralCost: json['funeralCost'] == null ? 0 : _int(json, 'funeralCost'),
      // Eski kayıtlarda etki satırı yoktur; boş liste okunur.
      effects: List<AppliedEffect>.unmodifiable(
        _optionalRawList(json, 'effects')
            .map((Object? e) => _decodeAppliedEffect(_asMap(e, 'effect')))
            .toList(growable: false),
      ),
    );

Loan _decodeLoan(Map<String, Object?> json) => Loan(
      id: _string(json, 'id'),
      bank: _enumByName(Bank.values, _string(json, 'bank'), 'loan.bank'),
      principal: _int(json, 'principal'),
      annualPayment: _int(json, 'annualPayment'),
      termYears: _int(json, 'termYears'),
      remainingPayments: _int(json, 'remainingPayments'),
      outstanding: _int(json, 'outstanding'),
      takenAtAge: _int(json, 'takenAtAge'),
      missedPayments: _intOr(json, 'missedPayments', 0),
    );

AppliedEffect _decodeAppliedEffect(Map<String, Object?> json) => AppliedEffect(
      label: _string(json, 'label'),
      delta: _intOrNull(json, 'delta'),
      unit: json['unit'] == null ? '' : _string(json, 'unit'),
    );

MilitaryState _decodeMilitary(Map<String, Object?> json) => MilitaryState(
      status: _enumByName(
        MilitaryStatus.values,
        _string(json, 'status'),
        'military.status',
      ),
      trackName: _stringOrNull(json, 'trackName'),
      rankId: _stringOrNull(json, 'rankId'),
      calledAtAge: _intOrNull(json, 'calledAtAge'),
      startedAtAge: _intOrNull(json, 'startedAtAge'),
      finishedAtAge: _intOrNull(json, 'finishedAtAge'),
      paidByPersonId: _stringOrNull(json, 'paidByPersonId'),
      // Paket 31 alanları; eski kayıtlarda yoktur ve **geriye dönük
      // tecil ya da ceza uydurulmaz**.
      deferralsUsed: _intOrNull(json, 'deferralsUsed') ?? 0,
      deferredUntilAge: _intOrNull(json, 'deferredUntilAge'),
      studentDeferral: _boolOr(json, 'studentDeferral'),
      fugitiveSinceAge: _intOrNull(json, 'fugitiveSinceAge'),
      fineTotal: _intOrNull(json, 'fineTotal') ?? 0,
      caughtCount: _intOrNull(json, 'caughtCount') ?? 0,
    );

Pregnancy _decodePregnancy(Map<String, Object?> json) => Pregnancy(
      partnerId: _string(json, 'partnerId'),
      startedAtAge: _int(json, 'startedAtAge'),
      expecting: _enumByName(
        ExpectingParty.values,
        _string(json, 'expecting'),
        'pregnancy.expecting',
      ),
    );

PendingWedding _decodePendingWedding(Map<String, Object?> json) =>
    PendingWedding(
      spouseId: _string(json, 'spouseId'),
      acceptedAtAge: _int(json, 'acceptedAtAge'),
    );

Person _decodePerson(Map<String, Object?> json) {
  final EmploymentStatus employment = _enumByName(
    EmploymentStatus.values,
    _string(json, 'employment'),
    'person.employment',
  );
  final String? occupation = _stringOrNull(json, 'occupation');
  if (occupation != null && employment != EmploymentStatus.calisiyor) {
    // Model bu durumu zaten reddeder; hatayı anlaşılır biçimde bildir.
    throw SaveFormatException(
      'Kayıtta tutarsız kişi: çalışmayan birine meslek yazılmış '
      '(${_string(json, 'id')}).',
    );
  }
  return Person(
    id: _string(json, 'id'),
    firstName: _string(json, 'firstName'),
    lastName: _string(json, 'lastName'),
    gender: _enumByName(Gender.values, _string(json, 'gender'), 'person.gender'),
    relation: _enumByName(
      RelationType.values,
      _string(json, 'relation'),
      'person.relation',
    ),
    age: _int(json, 'age'),
    isAlive: _bool(json, 'isAlive'),
    inPlayerHousehold: _bool(json, 'inPlayerHousehold'),
    // Eski kayıtlarda iş arkadaşı yoktur; alan boş kalır.
    workplaceId: _stringOrNull(json, 'workplaceId'),
    employment: employment,
    occupation: occupation,
    wealth: _enumByNameOrNull(
      WealthTier.values,
      _stringOrNull(json, 'wealth'),
      'person.wealth',
    ),
    bond: _int(json, 'bond'),
    // Eski kayıtlarda kişinin kendi keyfi yoktur; nötr okunur (D-074).
    happiness: _intOr(
      json,
      'happiness',
      Person.prototypeOnlyDefaultHappiness,
    ),
    // Eski kayıtlarda doğurganlık bilgisi yoktur; **kısır sayılmaz**.
    // Geriye dönük gizli bir engel yazılmaz.
    infertile: _boolOr(json, 'infertile'),
    schoolLevel: _enumByNameOrNull(
      SchoolLevel.values,
      _stringOrNull(json, 'schoolLevel'),
      'person.schoolLevel',
    ),
    schoolTie: _enumByNameOrNull(
      SchoolTie.values,
      _stringOrNull(json, 'schoolTie'),
      'person.schoolTie',
    ),
    schoolId: _stringOrNull(json, 'schoolId'),
    classId: _stringOrNull(json, 'classId'),
    // Eski kayıtlarda kişinin şehri yoktur; `null` kalır ve şehir koşulu
    // hiç uygulanmaz (kimse listeden düşmez).
    city: _stringOrNull(json, 'city'),
    // Eski kayıtlarda kişinin mal varlığı yoktur; boş listeyle açılır.
    estate: List<String>.unmodifiable(
      json['estate'] == null ? const <String>[] : _stringList(json, 'estate'),
    ),
    // Eski kayıtlarda kişinin kendi hayat kaydı yoktur; `null` kalır ve
    // ilk yaş ilerlemesinde geçmiş uydurulmadan açılır (sürüm 19).
    development: json['development'] == null
        ? null
        : _decodeDevelopment(_asMap(json['development'], 'person.development')),
  );
}

PendingLicenseExam _decodeLicenseExam(Map<String, Object?> json) =>
    PendingLicenseExam(
      licenseId: _string(json, 'licenseId'),
      questionIds: List<String>.unmodifiable(_stringList(json, 'questionIds')),
      answers: List<int>.unmodifiable(
        _list(json, 'answers').map((Object? e) => e! as int),
      ),
      askedAtAge: _int(json, 'askedAtAge'),
      feePaid: _int(json, 'feePaid'),
    );

PendingInterview _decodeInterview(Map<String, Object?> json) =>
    PendingInterview(
      jobId: _string(json, 'jobId'),
      questionId: _string(json, 'questionId'),
      askedAtAge: _int(json, 'askedAtAge'),
    );

CareerState _decodeCareer(Map<String, Object?> json) => CareerState(
      // Eski kayıtlarda işin şehri yoktur; `null` kalır ve hiçbir uyarı
      // gösterilmez.
      jobCity: _stringOrNull(json, 'jobCity'),
      jobId: _stringOrNull(json, 'jobId'),
      startedAtAge: _intOrNull(json, 'startedAtAge'),
      lastPaidAge: _intOrNull(json, 'lastPaidAge'),
      pastJobIds:
          List<String>.unmodifiable(_stringList(json, 'pastJobIds')),
      // Kariyer derinliği eski kayıtlarda yoktur: seviye 0, maaş `null`
      // (katalog maaşı geçerli) ve geçmiş boş açılır. Hiçbir iş kaydı
      // uydurulmaz.
      level: _intOrNull(json, 'level') ?? 0,
      salary: _intOrNull(json, 'salary'),
      milestones: List<CareerMilestone>.unmodifiable(
        _optionalList(json, 'milestones').map(_decodeCareerMilestone),
      ),
      history: List<JobHistoryEntry>.unmodifiable(
        _optionalList(json, 'history').map(_decodeJobHistory),
      ),
      lastRaiseAge: _intOrNull(json, 'lastRaiseAge'),
      lastPromotionAge: _intOrNull(json, 'lastPromotionAge'),
      lastJobLossAge: _intOrNull(json, 'lastJobLossAge'),
      // Eski kayıtlarda emeklilik yoktur; oyuncu emekli sayılmaz.
      retiredAtAge: _intOrNull(json, 'retiredAtAge'),
      pension: _intOrNull(json, 'pension'),
      // Eski kayıtta işveren uyarısı yoktur; sıfırdan başlar (D-078).
      employerWarnings: _intOr(json, 'employerWarnings', 0),
    );

CareerMilestone _decodeCareerMilestone(Map<String, Object?> json) =>
    CareerMilestone(age: _int(json, 'age'), text: _string(json, 'text'));

JobHistoryEntry _decodeJobHistory(Map<String, Object?> json) {
  final String? neden = _stringOrNull(json, 'endReason');
  return JobHistoryEntry(
    jobId: _string(json, 'jobId'),
    startedAtAge: _int(json, 'startedAtAge'),
    endedAtAge: _intOrNull(json, 'endedAtAge'),
    endReason: neden == null
        ? null
        : _enumByName(JobEndReason.values, neden, 'career.endReason'),
    level: _intOrNull(json, 'level') ?? 0,
    salary: _intOrNull(json, 'salary'),
    city: _stringOrNull(json, 'city'),
    milestones: List<CareerMilestone>.unmodifiable(
      _optionalList(json, 'milestones').map(_decodeCareerMilestone),
    ),
  );
}

OwnedItem _decodeItem(Map<String, Object?> json) {
  final int condition = _int(json, 'condition');
  if (condition < 0 || condition > 100) {
    throw SaveFormatException(
      'Kayıttaki eşyanın kondisyonu geçersiz: $condition '
      '(${_string(json, 'id')}).',
    );
  }
  return OwnedItem(
    id: _string(json, 'id'),
    typeId: _string(json, 'typeId'),
    acquiredAtAge: _int(json, 'acquiredAtAge'),
    source: _enumByName(ItemSource.values, _string(json, 'source'), 'item.source'),
    fromPersonId: _stringOrNull(json, 'fromPersonId'),
    condition: condition,
    attachments: List<String>.unmodifiable(_stringList(json, 'attachments')),
    // Eski kayıtlarda bu alanlar yoktur; boş kalır, eşya silinmez.
    purchasePrice: _intOrNull(json, 'purchasePrice'),
    location: _stringOrNull(json, 'location'),
    rentedOut: json['rentedOut'] == true,
  );
}

GiftRecord _decodeGift(Map<String, Object?> json) => GiftRecord(
      itemId: _string(json, 'itemId'),
      fromId: _string(json, 'fromId'),
      toId: _string(json, 'toId'),
      age: _int(json, 'age'),
    );

Pet _decodePet(Map<String, Object?> json) => Pet(
      id: _string(json, 'id'),
      name: _string(json, 'name'),
      species: _string(json, 'species'),
      age: _intOr(json, 'age', 0),
      adoptedAtPlayerAge: _intOrNull(json, 'adoptedAtPlayerAge'),
      inPlayerHousehold: _boolOr(json, 'inPlayerHousehold', varsayilan: true),
      diedAtAge: _intOrNull(json, 'diedAtAge'),
      diedAtPlayerAge: _intOrNull(json, 'diedAtPlayerAge'),
      lastCareChargedPlayerAge: _intOrNull(json, 'lastCareChargedPlayerAge'),
      bond: _intOr(json, 'bond', 50),
    );

LifeLogEntry _decodeLogEntry(Map<String, Object?> json) => LifeLogEntry(
      age: _int(json, 'age'),
      text: _string(json, 'text'),
      // Eski kayıtlarda günlük satırı kişiye bağlı değildir; geriye
      // dönük kişi bağlanmaz (Paket 14).
      personId: _stringOrNull(json, 'personId'),
      category: _enumByName(
        LogCategory.values,
        _string(json, 'category'),
        'log.category',
      ),
    );

EducationState _decodeEducation(Map<String, Object?> json) {
  final bool enrolled = _bool(json, 'enrolled');
  final int? grade = _intOrNull(json, 'grade');
  if (enrolled && grade == null) {
    throw const SaveFormatException(
      'Kayıttaki eğitim bilgisi tutarsız: okula kayıtlı görünen karakterin '
      'sınıfı yok.',
    );
  }
  return EducationState(
    enrolled: enrolled,
    grade: grade,
    startedAtAge: _intOrNull(json, 'startedAtAge'),
    finished: _bool(json, 'finished'),
    schoolId: _stringOrNull(json, 'schoolId'),
    classId: _stringOrNull(json, 'classId'),
    track: _enumByNameOrNull(
      EducationTrack.values,
      _stringOrNull(json, 'track'),
      'education.track',
    ),
    placementScore: _intOrNull(json, 'placementScore'),
    universityExamScore: _intOrNull(json, 'universityExamScore'),
    universityProgramId: _stringOrNull(json, 'universityProgramId'),
    universityYear: _intOrNull(json, 'universityYear'),
    universityFinished: _bool(json, 'universityFinished'),
    // Eski kayıtlarda not ortalaması yoktur; geriye dönük not
    // uydurulmaz ve öğrenci sınıfta kalmış sayılmaz (Paket 13).
    gradeAverage: _intOrNull(json, 'gradeAverage'),
    repeatedYears: _intOrNull(json, 'repeatedYears') ?? 0,
    droppedOut: json['droppedOut'] == true,
    scholarshipSinceAge: _intOrNull(json, 'scholarshipSinceAge'),
  );
}

ActiveEvent _decodeActiveEvent(Map<String, Object?> json) {
  final List<EventChoice> choices = _list(json, 'choices')
      .map((Object? e) => _decodeChoice(_asMap(e, 'choices[]')))
      .toList(growable: false);
  if (choices.isEmpty) {
    throw const SaveFormatException(
      'Kayıttaki bekleyen olayın hiç seçeneği yok.',
    );
  }
  return ActiveEvent(
    eventId: _string(json, 'eventId'),
    category: _enumByName(
      EventCategory.values,
      _string(json, 'category'),
      'pendingEvent.category',
    ),
    text: _string(json, 'text'),
    choices: List<EventChoice>.unmodifiable(choices),
    personId: _stringOrNull(json, 'personId'),
  );
}

EventChoice _decodeChoice(Map<String, Object?> json) => EventChoice(
      id: _string(json, 'id'),
      label: _string(json, 'label'),
      resultText: _string(json, 'resultText'),
      happiness: _int(json, 'happiness'),
      health: _int(json, 'health'),
      intelligence: _int(json, 'intelligence'),
      charisma: _int(json, 'charisma'),
      appearance: _int(json, 'appearance'),
      bond: _int(json, 'bond'),
      money: _int(json, 'money'),
      addFlags: Set<String>.unmodifiable(_stringSet(json, 'addFlags')),
      removeFlags: Set<String>.unmodifiable(_stringSet(json, 'removeFlags')),
      addPossessions:
          Set<String>.unmodifiable(_stringSet(json, 'addPossessions')),
      startsRomance: _bool(json, 'startsRomance'),
      endsRomance: _bool(json, 'endsRomance'),
      startsSchoolFriendship: _bool(json, 'startsSchoolFriendship'),
      // Eski kayıtlarda bu alan yok; varsayılan false.
      startsFriendship: json['startsFriendship'] == true,
      rememberPersonAs: _stringOrNull(json, 'rememberPersonAs'),
    );

// =====================================================================
// Küçük okuma yardımcıları
//
// Her biri eksik/yanlış türde alanı `SaveFormatException` ile bildirir;
// böylece bozuk kayıt uygulamayı çökertmez.
// =====================================================================

Never _eksik(String key, String beklenen) => throw SaveFormatException(
      'Kayıtta "$key" alanı eksik veya beklenen türde değil ($beklenen).',
    );

Map<String, Object?> _asMap(Object? value, String key) {
  if (value is Map) {
    return value.map<String, Object?>(
      (Object? k, Object? v) => MapEntry<String, Object?>('$k', v),
    );
  }
  _eksik(key, 'nesne');
}

Map<String, Object?> _map(Map<String, Object?> json, String key) =>
    _asMap(json[key], key);

/// Eski kayıtlarda bulunmayan ham listeler için: yoksa boş liste döner.
///
/// Alan varsa **liste olmak zorundadır**; metin ya da sayı gelirse ham bir
/// Dart hatası yerine anlaşılır bir `SaveFormatException` atılır (Paket 44).
List<Object?> _optionalRawList(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value == null) return const <Object?>[];
  if (value is! List) _eksik(key, 'liste');
  return value;
}

/// Eski kayıtlarda bulunmayan tam sayı alanı; yoksa [fallback].
int _intOr(Map<String, Object?> json, String key, int fallback) {
  final Object? value = json[key];
  if (value == null) return fallback;
  if (value is int) return value;
  _eksik(key, 'tam sayı');
}

/// Eski kayıtlarda bulunmayan listeler için: yoksa boş liste döner.
List<Map<String, Object?>> _optionalList(
  Map<String, Object?> json,
  String key,
) {
  final Object? value = json[key];
  if (value == null) return const <Map<String, Object?>>[];
  if (value is! List) _eksik(key, 'liste');
  return <Map<String, Object?>>[
    for (final Object? e in value) _asMap(e, key),
  ];
}

List<Object?> _list(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is List) return value;
  _eksik(key, 'liste');
}

String _string(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is String) return value;
  _eksik(key, 'metin');
}

String? _stringOrNull(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value == null) return null;
  if (value is String) return value;
  _eksik(key, 'metin veya boş');
}

int _int(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is int) return value;
  _eksik(key, 'tam sayı');
}

int? _intOrNull(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value == null) return null;
  if (value is int) return value;
  _eksik(key, 'tam sayı veya boş');
}

/// Eski kayıtlarda olmayan evet/hayır alanı; yoksa [varsayilan] kalır.
bool _boolOr(Map<String, Object?> json, String key, {bool varsayilan = false}) {
  final Object? value = json[key];
  if (value == null) return varsayilan;
  if (value is bool) return value;
  _eksik(key, 'evet/hayır veya boş');
}

bool _bool(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is bool) return value;
  _eksik(key, 'evet/hayır');
}

List<String> _stringList(Map<String, Object?> json, String key) {
  final List<String> sonuc = <String>[];
  for (final Object? e in _list(json, key)) {
    if (e is! String) _eksik(key, 'metin listesi');
    sonuc.add(e);
  }
  return sonuc;
}

Set<String> _stringSet(Map<String, Object?> json, String key) {
  final Set<String> sonuc = <String>{};
  for (final Object? e in _list(json, key)) {
    if (e is! String) _eksik(key, 'metin listesi');
    sonuc.add(e);
  }
  return sonuc;
}

Map<String, int> _intMap(Map<String, Object?> json, String key) {
  final Map<String, Object?> ham = _map(json, key);
  final Map<String, int> sonuc = <String, int>{};
  ham.forEach((String k, Object? v) {
    if (v is! int) _eksik('$key.$k', 'tam sayı');
    sonuc[k] = v;
  });
  return sonuc;
}

Map<String, String> _stringMap(Map<String, Object?> json, String key) {
  final Map<String, Object?> ham = _map(json, key);
  final Map<String, String> sonuc = <String, String>{};
  ham.forEach((String k, Object? v) {
    if (v is! String) _eksik('$key.$k', 'metin');
    sonuc[k] = v;
  });
  return sonuc;
}

T _enumByName<T extends Enum>(List<T> values, String name, String key) {
  for (final T value in values) {
    if (value.name == name) return value;
  }
  throw SaveFormatException(
    'Kayıtta tanınmayan değer: "$name" ($key). Kayıt, oyunun daha yeni bir '
    'sürümünden gelmiş olabilir.',
  );
}

T? _enumByNameOrNull<T extends Enum>(
  List<T> values,
  String? name,
  String key,
) =>
    name == null ? null : _enumByName(values, name, key);
