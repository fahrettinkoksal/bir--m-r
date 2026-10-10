/// Oyun durumunun kayıt dosyası için JSON'a çevrilmesi ve geri okunması.
///
/// Kural: **ekrandaki her şeyin kaynağı olan `GameState` eksiksiz yazılır.**
/// Kişi kimlikleri, okul bağları, hikâye rolleri ve bekleyen olay olduğu
/// gibi saklanır; yüklerken hiçbir şey yeniden rastgele üretilmez.
///
/// Enum değerleri **adlarıyla** yazılır (sıra numarasıyla değil); böylece
/// ileride enum sırası değişse bile eski kayıtlar bozulmaz.
library;

import '../../domain/models/company_vitals.dart';
import '../../domain/models/family_issue.dart';
import '../../domain/models/loan.dart';
import '../../domain/models/pending_race.dart';
import '../../domain/life/year_review.dart';
import '../../domain/models/applied_effect.dart';
import '../../data/education_tracks.dart';
import '../../data/social_catalog.dart';
import '../../domain/models/blackjack_game.dart';
import '../../domain/models/book_progress.dart';
import '../../domain/models/combat_career.dart';
import '../../domain/models/martial_progress.dart';
import '../../domain/models/school_club_progress.dart';
import '../../domain/sports/football_career.dart';
import '../../domain/models/hobby_progress.dart';
import '../../domain/models/lottery_ticket.dart';
import '../finger_catalog.dart';
import '../../domain/models/finger_profile.dart';
import '../lottery_catalog.dart';
import '../../domain/models/career.dart';
import '../../domain/models/education.dart';
import '../../domain/models/game_event.dart';
import '../../domain/features/feature_catalog.dart';
import '../../domain/models/game_settings.dart';
import '../../domain/models/chronic_condition.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/health_history.dart';
import '../../domain/models/household.dart';
import '../../domain/models/investment.dart';
import '../../domain/models/market_incident.dart';
import '../../domain/models/market_state.dart';
import '../../domain/models/gender.dart';
import '../../domain/models/gift_record.dart';
import '../../domain/models/life_log.dart';
import '../../domain/models/life_summary.dart';
import '../../domain/models/owned_item.dart';
import '../../domain/models/rental.dart';
import '../tenant_catalog.dart';
import '../../domain/models/parental_status.dart';
import '../../domain/models/pending_crisis.dart';
import '../../domain/models/pending_wedding.dart';
import '../../domain/models/business.dart';
import '../../domain/models/criminal_record.dart';
import '../../domain/models/military.dart';
import '../../domain/models/pending_trial.dart';
import '../../domain/models/pregnancy.dart';
import '../../domain/models/zodiac.dart';
import '../../domain/models/pending_interview.dart';
import '../../domain/models/pending_license_exam.dart';
import '../../domain/models/marriage.dart';
import '../../domain/models/person.dart';
import '../../domain/models/npc_marriage.dart';
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
      // Rekabet kariyeri (Paket AL). Alan eklemeli: eski kayıtta yok,
      // okuma tarafı boş liste ile yükler.
      'combatCareers':
          state.combatCareers.map(_encodeCombat).toList(growable: false),
      // Okul kulübü geçmişi (Paket AU). Alan eklemeli: eski kayıtta
      // yoktur, boş liste ile yüklenir ve geçmiş uydurulmaz.
      'schoolClubs':
          state.schoolClubs.map(_encodeSchoolClub).toList(growable: false),
      // Paket AY: futbol kariyeri kayda girer. AU/1'de alan GameState'e
      // eklenmiş ama KODEKE YAZILMAMIŞTI; o zaman hiç kariyer
      // oluşamadığı için eksik gizli kalmıştı.
      'footballCareer': state.footballCareer == null
          ? null
          : _encodeFootball(state.footballCareer!),
      // Deneme yılda bir kez: hangi yaşta girildiği kayda geçer.
      'footballTrialAge': state.footballTrialAge,
      // Hobi geçmişi (Paket 39). Alan eklemeli.
      'hobbies': state.hobbies.map(_encodeHobby).toList(growable: false),
      // Kronik durumlar ve sağlık geçmişi (D-153). Alan eklemeli:
      // eski kayıtta yoklar, okuma tarafı isteğe bağlı okur.
      'chronicConditions':
          state.chronicConditions.map(_encodeChronic).toList(growable: false),
      'healthHistory': state.healthHistory
          .map(_encodeHealthHistory)
          .toList(growable: false),
      // Hayat hedefleri (D-156). Alan eklemeli.
      'goalsReachedAt': state.goalsReachedAt,
      // Araç muayenesi (D-157). Alan eklemeli.
      'vehicleInspectionAt': state.vehicleInspectionAt,
      // Nafaka kaydı (D-160). Alan eklemeli; eski kayıtta yoktur.
      'alimony':
          state.alimony == null ? null : _encodeAlimony(state.alimony!),
      // Yatırımlar ve piyasa (D-162). Alan eklemeli; eski kayıtta yoktur.
      'investments':
          state.investments.map(_encodeHolding).toList(growable: false),
      'termDeposits':
          state.termDeposits.map(_encodeTermDeposit).toList(growable: false),
      'investmentHistory': state.investmentHistory
          .map(_encodeInvestmentRecord)
          .toList(growable: false),
      'market': _encodeMarket(state.market),
      // Kiralama (D-163). Üçü de alan eklemeli: eski kayıt boş listeyle
      // açılır, `rentedOut` taşıyan eski konutlar yüklemede sözleşmeye
      // çevrilir.
      'leases': state.leases.map(_encodeLease).toList(growable: false),
      'propertyLedgers':
          state.propertyLedgers.map(_encodeLedger).toList(growable: false),
      if (state.landlord != null) 'landlord': _encodeLandlord(state.landlord!),
      // Piyango biletleri (Paket 33). Alan eklemeli.
      'lotteryTickets':
          state.lotteryTickets.map(_encodeTicket).toList(growable: false),
      // Finger profilleri (Paket 34). Alan eklemeli.
      'fingerDeck':
          state.fingerDeck.map(_encodeFinger).toList(growable: false),
      'fingerMatches':
          state.fingerMatches.map(_encodeFinger).toList(growable: false),
      // Karşılıklı beğeni, profil ve premium (D-081). Alan eklemeli.
      'fingerIncoming':
          state.fingerIncoming.map(_encodeFinger).toList(growable: false),
      'fingerBio': state.fingerBio,
      'fingerInterests': state.fingerInterests,
      'fingerPremiumUntilAge': state.fingerPremiumUntilAge,
      // Oyuncunun niyeti ve süzgeci (D-107); alan eklemeli.
      'fingerIntent': state.fingerIntent.name,
      'fingerWealthFilter': state.fingerWealthFilter?.name,
      'socialAccounts':
          state.socialAccounts.map(_encodeAccount).toList(growable: false),
      // Ünlülerle kurulan temaslar. Eski kayıtlarda bu alan yoktur;
      // okuma tarafı isteğe bağlı okuduğu için kayıt sürümü değişmedi.
      'celebrityContacts': state.celebrityContacts
          .map(_encodeCelebrityContact)
          .toList(growable: false),
      // Sponsorluk teklifi ve anlaşmaları (Paket 10).
      'mediaInvitationId': state.mediaInvitationId,
      'mediaInvitationAge': state.mediaInvitationAge,
      // D-147: her medya işinin en son yapıldığı yaş. Eski kayıtlarda
      // yoktur; boş açılır ve geriye dönük geçmiş uydurulmaz.
      'mediaJobLastAge': state.mediaJobLastAge,
      // D-149: arkadaş haberlerinin tekrar sayacı. Eski kayıtta yoktur.
      'friendNewsLastAge': state.friendNewsLastAge,
      'sponsorOffer': state.sponsorOffer == null
          ? null
          : _encodeSponsorOffer(state.sponsorOffer!),
      'sponsorDeals':
          state.sponsorDeals.map(_encodeSponsorDeal).toList(growable: false),
      // Geziler (Paket 11): kayıt silinmez, ücret ikinci kez düşmez.
      'trips': state.trips.map(_encodeTrip).toList(growable: false),
      'blackjack':
          state.blackjack == null ? null : _encodeBlackjack(state.blackjack!),
      // Sonuçlanmamış at yarışı bahsi (D-089). Alan eklemeli; eski
      // kayıtta yoktur.
      'pendingRace': state.pendingRace == null
          ? null
          : <String, Object?>{
              'id': state.pendingRace!.id,
              'lane': state.pendingRace!.lane,
              'bet': state.pendingRace!.bet,
              'winnerLane': state.pendingRace!.winnerLane,
              'payout': state.pendingRace!.payout,
              'horseName': state.pendingRace!.horseName,
              'winnerName': state.pendingRace!.winnerName,
              'oddsLabel': state.pendingRace!.oddsLabel,
              'atAge': state.pendingRace!.atAge,
            },
      // Yıl özeti ve yılın başındaki fotoğraf (D-096). Alan eklemeli;
      // eski kayıtta yoktur ve özetsiz açılır.
      'yearMark': state.yearMark == null
          ? null
          : <String, Object?>{
              'age': state.yearMark!.age,
              'appearance': state.yearMark!.stats.appearance,
              'happiness': state.yearMark!.stats.happiness,
              'health': state.yearMark!.stats.health,
              'intelligence': state.yearMark!.stats.intelligence,
              'charisma': state.yearMark!.stats.charisma,
              'wallet': state.yearMark!.wallet,
              'fame': state.yearMark!.fame,
              // Çocukların yıl başı fotoğrafı (Paket BK/5). Eski
              // kayıtlarda yoktur; boş okunur ve o yıl çocuk özeti
              // çıkmaz — geriye dönük fark **uydurulmaz**.
              'childMarks': <String, Object?>{
                for (final MapEntry<String, ChildMark> e
                    in state.yearMark!.childMarks.entries)
                  e.key: <String, Object?>{
                    'appearance': e.value.stats.appearance,
                    'happiness': e.value.stats.happiness,
                    'health': e.value.stats.health,
                    'intelligence': e.value.stats.intelligence,
                    'charisma': e.value.stats.charisma,
                    'money': e.value.money,
                    'interests': e.value.interests,
                    'bond': e.value.bond,
                    'ownHappiness': e.value.happiness,
                    'milestones': e.value.milestones,
                  },
              },
            },
      'lastYearSummary': state.lastYearSummary == null
          ? null
          : <String, Object?>{
              'age': state.lastYearSummary!.age,
              'effects': <Map<String, Object?>>[
                for (final AppliedEffect e in state.lastYearSummary!.effects)
                  <String, Object?>{
                    'label': e.label,
                    'delta': e.delta,
                    'unit': e.unit,
                  },
              ],
              // Çocukların aynı yıl özeti (Paket BK/5).
              'children': <Map<String, Object?>>[
                for (final ChildYearSummary c
                    in state.lastYearSummary!.children)
                  <String, Object?>{
                    'childId': c.childId,
                    'name': c.name,
                    'age': c.age,
                    'effects': <Map<String, Object?>>[
                      for (final AppliedEffect e in c.effects)
                        <String, Object?>{
                          'label': e.label,
                          'delta': e.delta,
                          'unit': e.unit,
                        },
                    ],
                    'milestones': c.milestones,
                  },
              ],
            },
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
            // Kredi amacı alan eklemeli (D-108); eski kayıtta yoktur ve
            // ihtiyaç kredisi olarak okunur.
            'purpose': l.purpose.name,
            'missedPayments': l.missedPayments,
            // Paket AD borç yaşam döngüsü (§8-§11). Hepsi alan eklemeli;
            // eski kayıtta yoklar ve nötr okunurlar.
            'originalDebt': l.originalDebt,
            'missedStreak': l.missedStreak,
            'restructures': l.restructures,
            'writtenOff': l.writtenOff,
            'closedAtAge': l.closedAtAge,
          },
      ],
      // Bakım geçmişi (D-072). Eski kayıtlarda yoktur; `null` kalır ve
      // ihmal sayılmaz.
      'lastSportAge': state.lastSportAge,
      'lastGroomingAge': state.lastGroomingAge,
      'lastLearningAge': state.lastLearningAge,
      // Paket AP §4. Eksik anahtar boş liste okunur; eski kayıt
      // bozulmaz.
      'familyIssues':
          state.familyIssues.map(_encodeFamilyIssue).toList(growable: false),
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
              // Paket AQ: kritik sağlık durumunun bilinen sebebi. Yoksa
              // yazılmaz; eski kayıtlarda da bulunmaz.
              if (state.pendingCrisis!.causeId != null)
                'causeId': state.pendingCrisis!.causeId,
            },
      'lastCrisisAge': state.lastCrisisAge,
      'healthWarned': state.healthWarned,
      'healthDangerWarned': state.healthDangerWarned,
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
      // Çocuk planı (Paket BK/2): niyet kayda girer, uygulama kapansa
      // da "çocuk düşünüyoruz" kararı kaybolmaz. Plan **çifte** ait
      // olduğu için kiminle konuşulduğu da yazılır.
      'familyPlan': state.familyPlan.name,
      'familyPlanPartnerId': state.familyPlanPartnerId,
      // Askerlik kaydı (Paket 29); yarım kalan hizmet kaybolmaz.
      // Kurulmuş işler (D-132). Eski kayıtlarda yoktur; boş açılır.
      'businesses': <Object?>[
        for (final Business b in state.businesses)
          <String, Object?>{
            'id': b.id,
            'typeId': b.typeId,
            'startedAtAge': b.startedAtAge,
            'condition': b.condition,
            'totalInvested': b.totalInvested,
            'totalProfit': b.totalProfit,
            'lastTendedAge': b.lastTendedAge,
            'lastSettledAge': b.lastSettledAge,
            'closedAtAge': b.closedAtAge,
            'endReason': b.endReason?.name,
            // Paket AE: fiyat, itibar, personel, bakım, reklam ve son
            // yılların dökümü. Eski kayıtlarda yoktur; varsayılanla açılır.
            'price': b.price,
            'reputation': b.reputation,
            'upkeep': b.upkeep,
            'staffQuality': b.staffQuality,
            'staffMorale': b.staffMorale,
            'staffCount': b.staffCount,
            'wageLevel': b.wageLevel,
            'ad': b.ad.name,
            'adStreak': b.adStreak,
            'yearMaintenanceSpend': b.yearMaintenanceSpend,
            'lastMaintenanceAge': b.lastMaintenanceAge,
            'lastStaffCareAge': b.lastStaffCareAge,
            'recentIncidents': b.recentIncidents,
            'lossStreak': b.lossStreak,
            'demandPressure': b.demandPressure,
            'history': <Object?>[
              for (final BusinessYear y in b.history)
                <String, Object?>{
                  'age': y.age,
                  'revenue': y.revenue,
                  'staffCost': y.staffCost,
                  'supplyCost': y.supplyCost,
                  'fixedCost': y.fixedCost,
                  'maintenanceCost': y.maintenanceCost,
                  'adCost': y.adCost,
                  'incidentCost': y.incidentCost,
                  'net': y.net,
                  'price': y.price,
                  'marketPrice': y.marketPrice,
                  'demandIndex': y.demandIndex,
                },
            ],
          },
      ],
      // Adli durum (D-128). Eski kayıtlarda yoktur; geriye dönük sabıka
      // **uydurulmaz**.
      'legal': <String, Object?>{
        'imprisonedSinceAge': state.legal.imprisonedSinceAge,
        'releaseAtAge': state.legal.releaseAtAge,
        'probationUntilAge': state.legal.probationUntilAge,
        'caseCounter': state.legal.caseCounter,
        // Tutukluluk ve kefalet (D-139). Eski kayıtlarda yoktur; boş
        // gelirse tutuksuz sayılır, geriye dönük tutukluluk uydurulmaz.
        'detainedSinceAge': state.legal.detainedSinceAge,
        'bailAmount': state.legal.bailAmount,
        'bailPaidBy': state.legal.bailPaidBy,
        'bailAskedAtAge': state.legal.bailAskedAtAge,
        // Cezaevi hayatı (D-140).
        'goodBehaviour': state.legal.goodBehaviour,
        'crewStanding': state.legal.crewStanding,
        // Çevre (D-161). Alan eklemeli; eski kayıtta yoktur.
        'crewOfferAtAge': state.legal.crewOfferAtAge,
        'crewJobs': state.legal.crewJobs,
        'yearsServed': state.legal.yearsServed,
        'cases': <Object?>[
          for (final CriminalCase c in state.legal.cases)
            <String, Object?>{
              'id': c.id,
              'crimeId': c.crimeId,
              'ageAtIncident': c.ageAtIncident,
              'stage': c.stage.name,
              'verdict': c.verdict.name,
              'fine': c.fine,
              'finePaid': c.finePaid,
              'prisonYears': c.prisonYears,
              'lawyerId': c.lawyerId,
              'decidedAtAge': c.decidedAtAge,
              'closedAtAge': c.closedAtAge,
              'note': c.note,
            },
        ],
      },
      'pendingTrial': state.pendingTrial == null
          ? null
          : <String, Object?>{
              'caseId': state.pendingTrial!.caseId,
              'age': state.pendingTrial!.age,
              'text': state.pendingTrial!.text,
            },
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
      // Yıl içindeki deneme sayısı (D-086). Alan eklemeli.
      'conceptionTriesAtAge': state.conceptionTriesAtAge,
      'settings': <String, Object?>{
        'casinoEnabled': state.settings.casinoEnabled,
        'wagerLimitPerAge': state.settings.wagerLimitPerAge,
        'soundEnabled': state.settings.soundEnabled,
        // Modül anahtarları (Paket BL): yalnızca varsayılandan sapanlar
        // yazılır, böylece katalog büyüdükçe kayıt büyümez.
        'features': state.settings.features.overrides,
        // Görünüm seçimi (Paket BQ): anahtar olarak yazılır, Flutter'ın
        // kendi sıralaması kayda girmez.
        'themeChoice': state.settings.themeChoice.saveKey,
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
      // Atletik potansiyel (Paket AU): doğumda belirlenir, **yeniden
      // çekilmez**. Alanı taşımayan eski kayıtta null kalır ve kimlikten
      // deterministik türetilir.
      'athleticPotential': p.storedAthleticPotential,
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

Map<String, Object?> _encodeOpponent(CombatOpponent o) => <String, Object?>{
      'id': o.id,
      'name': o.name,
      'age': o.age,
      'rating': o.rating,
      'wins': o.wins,
      'losses': o.losses,
      'metCount': o.metCount,
      'playerWins': o.playerWins,
      'playerLosses': o.playerLosses,
      // Paket AL/2 (§17, §19): rekabetin azalan getiri sayacı ve
      // rakibin kendi kademesi. Eski kayıtta yok; 0 olarak yüklenir.
      'fameAwards': o.fameAwards,
      'opponentTier': o.tier,
    };

Map<String, Object?> _encodeSchoolClub(SchoolClubProgress p) =>
    <String, Object?>{
      'clubId': p.clubId,
      'schoolId': p.schoolId,
      'joinedAtAge': p.joinedAtAge,
      'joinedAtGrade': p.joinedAtGrade,
      'active': p.active,
      'leftAtAge': p.leftAtAge,
      'yearsActive': p.yearsActive,
      'skill': p.skill,
      'performance': p.performance,
      'role': p.role.name,
      'captainSinceAge': p.captainSinceAge,
      'competitions': p.competitions,
      'awards': p.awards,
      'lastPracticedAge': p.lastPracticedAge,
    };

SchoolClubProgress _decodeSchoolClub(Map<String, Object?> json) =>
    SchoolClubProgress(
      clubId: _string(json, 'clubId'),
      schoolId: _string(json, 'schoolId'),
      joinedAtAge: _int(json, 'joinedAtAge'),
      joinedAtGrade: _int(json, 'joinedAtGrade'),
      active: _boolOr(json, 'active', varsayilan: true),
      leftAtAge: _intOrNull(json, 'leftAtAge'),
      yearsActive: _intOr(json, 'yearsActive', 0),
      skill: _intOr(json, 'skill', 0),
      performance: _intOr(json, 'performance', 50),
      role: _enumByName(
        SquadRole.values,
        _stringOrNull(json, 'role') ?? SquadRole.yedek.name,
        'schoolClubs[].role',
      ),
      captainSinceAge: _intOrNull(json, 'captainSinceAge'),
      competitions: _intOr(json, 'competitions', 0),
      awards: _intOr(json, 'awards', 0),
      lastPracticedAge: _intOrNull(json, 'lastPracticedAge'),
    );

Map<String, Object?> _encodeFootball(FootballCareer c) => <String, Object?>{
      'startedAtAge': c.startedAtAge,
      'position': c.position.name,
      'active': c.active,
      'retiredAtAge': c.retiredAtAge,
      'exitReason': c.exitReason?.name,
      'currentClubId': c.currentClubId,
      'currentLeagueId': c.currentLeagueId,
      'form': c.form,
      'reputation': c.reputation,
      'lastSeasonAge': c.lastSeasonAge,
      'weakSeasons': c.weakSeasons,
      'careerEarnings': c.careerEarnings,
      'seasons':
          c.seasonHistory.map(_encodeFootballSeason).toList(growable: false),
    };

Map<String, Object?> _encodeFootballSeason(FootballSeason s) =>
    <String, Object?>{
      'age': s.age,
      'clubId': s.clubId,
      'leagueId': s.leagueId,
      'appearances': s.appearances,
      'goals': s.goals,
      'rating': s.rating,
      'injury': s.injury,
      'earned': s.earned,
    };

FootballCareer _decodeFootball(Map<String, Object?> json) => FootballCareer(
      startedAtAge: _int(json, 'startedAtAge'),
      position: _enumByName(
        FootballPosition.values,
        _stringOrNull(json, 'position') ?? FootballPosition.ortaSaha.name,
        'footballCareer.position',
      ),
      active: _boolOr(json, 'active', varsayilan: true),
      retiredAtAge: _intOrNull(json, 'retiredAtAge'),
      exitReason: _enumByNameOrNull(
        FootballExit.values,
        _stringOrNull(json, 'exitReason'),
        'footballCareer.exitReason',
      ),
      currentClubId: _stringOrNull(json, 'currentClubId'),
      currentLeagueId: _stringOrNull(json, 'currentLeagueId'),
      form: _intOr(json, 'form', 50),
      reputation: _intOr(json, 'reputation', 0),
      lastSeasonAge: _intOrNull(json, 'lastSeasonAge'),
      weakSeasons: _intOr(json, 'weakSeasons', 0),
      careerEarnings: _intOr(json, 'careerEarnings', 0),
      seasonHistory: List<FootballSeason>.unmodifiable(
        _optionalRawList(json, 'seasons')
            .map((Object? e) =>
                _decodeFootballSeason(_asMap(e, 'footballCareer.seasons[]')))
            .toList(growable: false),
      ),
    );

FootballSeason _decodeFootballSeason(Map<String, Object?> json) =>
    FootballSeason(
      age: _int(json, 'age'),
      clubId: _stringOrNull(json, 'clubId'),
      leagueId: _stringOrNull(json, 'leagueId'),
      appearances: _intOr(json, 'appearances', 0),
      goals: _intOr(json, 'goals', 0),
      rating: _intOr(json, 'rating', 0),
      injury: _stringOrNull(json, 'injury'),
      earned: _intOr(json, 'earned', 0),
    );

Map<String, Object?> _encodeCombat(CombatCareer c) => <String, Object?>{
      'artId': c.artId,
      'startedCompetitiveAtAge': c.startedCompetitiveAtAge,
      'status': c.status.name,
      'tier': c.tier,
      'amateurWins': c.amateurWins,
      'amateurLosses': c.amateurLosses,
      'proWins': c.proWins,
      'proLosses': c.proLosses,
      'championships': c.championships,
      'isChampion': c.isChampion,
      'ranking': c.ranking,
      'lastBoutAge': c.lastBoutAge,
      'form': c.form,
      'reputation': c.reputation,
      'careerEarnings': c.careerEarnings,
      'sponsorEarnings': c.sponsorEarnings,
      'injuryCount': c.injuryCount,
      'seriousInjuryCount': c.seriousInjuryCount,
      'injury': c.injury.name,
      'injuryYearsLeft': c.injuryYearsLeft,
      'retiredAtAge': c.retiredAtAge,
      'retirementReason': c.retirementReason?.name,
      'coachLevel': c.coachLevel,
      'opponents': c.opponents.map(_encodeOpponent).toList(growable: false),
      // Bekleyen müsabakanın TOHUMU da kayda girer (Paket AL, §44):
      // aynı müsabakayı yükleyip tekrar oynamak aynı sonucu verir.
      'pendingBout': c.pendingBout == null
          ? null
          : <String, Object?>{
              'tier': c.pendingBout!.tier,
              'opponent': _encodeOpponent(c.pendingBout!.opponent),
              'purse': c.pendingBout!.purse,
              'seed': c.pendingBout!.seed,
              'offeredAtAge': c.pendingBout!.offeredAtAge,
              'isTitle': c.pendingBout!.isTitle,
            },
      'memories': c.memories
          .map((CombatMemory m) => <String, Object?>{
                'age': m.age,
                'text': m.text,
              })
          .toList(growable: false),
      // Paket AL/2 (§12, §30): başarının tazeliği ve bekleyen
      // okul/spor çatışması. İkisi de toplamsal; eski kayıt bozulmaz.
      'lastTitleAge': c.lastTitleAge,
      'schoolConflictAge': c.schoolConflictAge,
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
      // Niyet ve ekonomik durum alan eklemeli (D-107); eski kayıtta
      // yoktur ve varsayılanla okunur.
      'intent': p.intent.name,
      'wealth': p.wealth.name,
      'matchedAtAge': p.matchedAtAge,
      'metPersonId': p.metPersonId,
    };

Map<String, Object?> _encodeHolding(Holding h) => <String, Object?>{
      'typeId': h.typeId,
      'value': h.value,
      'costBasis': h.costBasis,
      'totalInvested': h.totalInvested,
      'realizedProfit': h.realizedProfit,
      'firstBoughtAtAge': h.firstBoughtAtAge,
    };

Holding _decodeHolding(Map<String, Object?> json) => Holding(
      typeId: _string(json, 'typeId'),
      value: _int(json, 'value'),
      costBasis: _int(json, 'costBasis'),
      totalInvested: _int(json, 'totalInvested'),
      realizedProfit: _intOr(json, 'realizedProfit', 0),
      firstBoughtAtAge: _intOr(json, 'firstBoughtAtAge', 0),
    );

Map<String, Object?> _encodeTermDeposit(TermDeposit d) => <String, Object?>{
      'id': d.id,
      'amount': d.amount,
      'openedAtAge': d.openedAtAge,
      'maturesAtAge': d.maturesAtAge,
      'rateBasis': d.rateBasis,
    };

TermDeposit _decodeTermDeposit(Map<String, Object?> json) => TermDeposit(
      id: _string(json, 'id'),
      amount: _int(json, 'amount'),
      openedAtAge: _int(json, 'openedAtAge'),
      maturesAtAge: _int(json, 'maturesAtAge'),
      rateBasis: _int(json, 'rateBasis'),
    );

Map<String, Object?> _encodeInvestmentRecord(InvestmentRecord r) =>
    <String, Object?>{
      'typeId': r.typeId,
      'age': r.age,
      'kind': r.kind.name,
      'amount': r.amount,
      'realized': r.realized,
    };

InvestmentRecord _decodeInvestmentRecord(Map<String, Object?> json) =>
    InvestmentRecord(
      typeId: _string(json, 'typeId'),
      age: _int(json, 'age'),
      kind: _enumByNameOrNull(
            InvestmentRecordKind.values,
            _stringOrNull(json, 'kind'),
            'investmentRecord.kind',
          ) ??
          InvestmentRecordKind.aldi,
      amount: _int(json, 'amount'),
      realized: _intOr(json, 'realized', 0),
    );

Map<String, Object?> _encodeMarket(MarketState m) => <String, Object?>{
      'regime': m.regime.name,
      'inflationPressure': m.inflationPressure,
      'confidence': m.confidence,
      'priceIndex': m.priceIndex,
      'advancedAtAge': m.advancedAtAge,
      'lastNoticeAge': m.lastNoticeAge,
      // Paket AC: dördü de **alan eklemeli**. Eski kayıt sıfır/boş
      // okunur, çökmez.
      'regimeYearsLeft': m.regimeYearsLeft,
      'companyStatus': m.companyStatus,
      'halts': m.halts.map(_encodeHalt).toList(growable: false),
      'incidents': m.incidents.map(_encodeIncident).toList(growable: false),
      // Paket AD: alan eklemeli. Eski kayıtta yoksa bütün varlıklar
      // normal (50) ısıda açılır.
      'valuationHeat': m.valuationHeat,
      'riskTide': m.riskTide,
      'hedgeTide': m.hedgeTide,
      // Paket AD/2: şirket sağlık göstergeleri ve sektör gücü. Alan
      // eklemeli; eski kayıtta yoklar ve katalog tabanından okunurlar.
      'companyVitals': <String, Object?>{
        for (final MapEntry<String, CompanyVitals> e in m.companyVitals.entries)
          e.key: <String, Object?>{
            'financialHealth': e.value.financialHealth,
            'debtPressure': e.value.debtPressure,
            'growth': e.value.growth,
            'management': e.value.management,
            'confidence': e.value.confidence,
          },
      },
      'sectorStrength': m.sectorStrength,
      'companyClosedAtAge': m.companyClosedAtAge,
      'companySuccessors': m.companySuccessors,
    };

Map<String, Object?> _encodeHalt(TradingHalt h) => <String, Object?>{
      'typeId': h.typeId,
      'untilAge': h.untilAge,
      'reason': h.reason,
    };

TradingHalt _decodeHalt(Map<String, Object?> json) => TradingHalt(
      typeId: _stringOrNull(json, 'typeId') ?? '',
      untilAge: _intOr(json, 'untilAge', 0),
      reason: _stringOrNull(json, 'reason') ?? '',
    );

Map<String, Object?> _encodeIncident(MarketIncident i) => <String, Object?>{
      'kind': i.kind.name,
      'age': i.age,
      'companyId': i.companyId,
      'typeId': i.typeId,
      // Oran kesirli; kayıtta baz puan olarak tutuluyor ki yuvarlama
      // kayması olmasın.
      'impactBasis': (i.impact * MarketState.basis).round(),
      'cashDelta': i.cashDelta,
    };

MarketIncident _decodeIncident(Map<String, Object?> json) => MarketIncident(
      kind: _enumByNameOrNull(
            IncidentKind.values,
            _stringOrNull(json, 'kind'),
            'market.incidents[].kind',
          ) ??
          IncidentKind.piyasaPanigi,
      age: _intOr(json, 'age', 0),
      companyId: _stringOrNull(json, 'companyId'),
      typeId: _stringOrNull(json, 'typeId'),
      impact: _intOr(json, 'impactBasis', 0) / MarketState.basis,
      cashDelta: _intOr(json, 'cashDelta', 0),
    );

MarketState _decodeMarket(Map<String, Object?> json) => MarketState(
      regime: _enumByNameOrNull(
            MarketRegime.values,
            _stringOrNull(json, 'regime'),
            'market.regime',
          ) ??
          MarketRegime.normal,
      inflationPressure: _intOr(json, 'inflationPressure', 50),
      confidence: _intOr(json, 'confidence', 50),
      priceIndex: json['priceIndex'] == null
          ? const <String, int>{}
          : _intMap(json, 'priceIndex'),
      advancedAtAge: _intOrNull(json, 'advancedAtAge'),
      lastNoticeAge: _intOrNull(json, 'lastNoticeAge'),
      regimeYearsLeft: _intOr(json, 'regimeYearsLeft', 0),
      companyStatus: json['companyStatus'] == null
          ? const <String, String>{}
          : _stringMap(json, 'companyStatus'),
      halts: List<TradingHalt>.unmodifiable(
        _optionalRawList(json, 'halts')
            .map((Object? e) => _decodeHalt(_asMap(e, 'market.halts[]')))
            .toList(growable: false),
      ),
      incidents: List<MarketIncident>.unmodifiable(
        _optionalRawList(json, 'incidents')
            .map((Object? e) =>
                _decodeIncident(_asMap(e, 'market.incidents[]')))
            .toList(growable: false),
      ),
      valuationHeat: json['valuationHeat'] == null
          ? const <String, int>{}
          : _intMap(json, 'valuationHeat'),
      // Eski kayıtta gelgit yoksa nötr (50) açılır.
      riskTide: _intOr(json, 'riskTide', 50),
      hedgeTide: _intOr(json, 'hedgeTide', 50),
      companyVitals: json['companyVitals'] == null
          ? const <String, CompanyVitals>{}
          : <String, CompanyVitals>{
              for (final MapEntry<String, Object?> e
                  in _asMap(json['companyVitals'], 'market.companyVitals')
                      .entries)
                e.key: _decodeVitals(_asMap(e.value, 'market.companyVitals[]')),
            },
      sectorStrength: json['sectorStrength'] == null
          ? const <String, int>{}
          : _intMap(json, 'sectorStrength'),
      companyClosedAtAge: json['companyClosedAtAge'] == null
          ? const <String, int>{}
          : _intMap(json, 'companyClosedAtAge'),
      companySuccessors: json['companySuccessors'] == null
          ? const <String, String>{}
          : _stringMap(json, 'companySuccessors'),
    );

Map<String, Object?> _encodeAlimony(Alimony a) => <String, Object?>{
      'otherPersonId': a.otherPersonId,
      'yearlyAmount': a.yearlyAmount,
      'startedAtAge': a.startedAtAge,
      'untilAge': a.untilAge,
      'playerPays': a.playerPays,
      'custody': a.custody.name,
      'endedAtAge': a.endedAtAge,
      'paidYears': a.paidYears,
    };

Alimony _decodeAlimony(Map<String, Object?> json) => Alimony(
      otherPersonId: _string(json, 'otherPersonId'),
      yearlyAmount: _int(json, 'yearlyAmount'),
      startedAtAge: _int(json, 'startedAtAge'),
      untilAge: _int(json, 'untilAge'),
      playerPays: _boolOr(json, 'playerPays', varsayilan: true),
      custody: _enumByNameOrNull(
            Custody.values,
            _stringOrNull(json, 'custody'),
            'alimony.custody',
          ) ??
          Custody.oyuncuda,
      endedAtAge: _intOrNull(json, 'endedAtAge'),
      paidYears: _intOr(json, 'paidYears', 0),
    );

FamilyIssueKind? _familyIssueKindOrNull(String? name) {
  if (name == null) return null;
  for (final FamilyIssueKind tur in FamilyIssueKind.values) {
    if (tur.name == name) return tur;
  }
  return null;
}

FamilyIssueResponse? _familyIssueResponseOrNull(String? name) {
  if (name == null) return null;
  for (final FamilyIssueResponse cevap in FamilyIssueResponse.values) {
    if (cevap.name == name) return cevap;
  }
  return null;
}

FamilyIssueStatus? _familyIssueStatusOrNull(String? name) {
  if (name == null) return null;
  for (final FamilyIssueStatus durum in FamilyIssueStatus.values) {
    if (durum.name == name) return durum;
  }
  return null;
}

Map<String, Object?> _encodeFamilyIssue(FamilyIssue i) => <String, Object?>{
      'id': i.id,
      'kind': i.kind.name,
      'personId': i.personId,
      'openedAtAge': i.openedAtAge,
      'lastEventAge': i.lastEventAge,
      'status': i.status.name,
      'stage': i.stage,
      'resolvedAtAge': i.resolvedAtAge,
      'response': i.response?.name,
    };

/// Aile meselesini okur; **tanınmayan tür kaydı bozmaz**.
///
/// Mesele türleri zamanla eklenecek. Daha yeni bir sürümden gelen bir
/// kayıt okunurken tanınmayan bir tür çıkarsa, o mesele düşer ve hayatın
/// kalanı açılır. Aileyi silmek yerine bir meseleyi unutmak daha az
/// zarar verir; mesele kişinin kendi kaydında değil, yalnızca burada
/// durur.
FamilyIssue? _decodeFamilyIssue(Map<String, Object?> json) {
  // `_enumByNameOrNull` tanınmayan adı **hata** sayıyor; burada istenen
  // bu değil, o yüzden hoşgörülü arama elde yapılıyor.
  final FamilyIssueKind? tur = _familyIssueKindOrNull(
    _stringOrNull(json, 'kind'),
  );
  if (tur == null) return null;
  final int acilis = _int(json, 'openedAtAge');
  return FamilyIssue(
    id: _stringOrNull(json, 'id') ??
        FamilyIssue.idFor(tur, _string(json, 'personId'), acilis),
    kind: tur,
    personId: _string(json, 'personId'),
    openedAtAge: acilis,
    lastEventAge: _intOr(json, 'lastEventAge', acilis),
    // Durum okunamazsa en güvenli karşılık "sürüyor": kapandığını
    // uydurmak, meseleyi oyuncuya bir kez daha göstermekten kötüdür.
    status: _familyIssueStatusOrNull(_stringOrNull(json, 'status')) ??
        FamilyIssueStatus.acik,
    stage: _intOr(json, 'stage', 0),
    resolvedAtAge: _intOrNull(json, 'resolvedAtAge'),
    // Tanınmayan cevap "hiç sorulmamış" sayılır; mesele yine açılır.
    response: _familyIssueResponseOrNull(_stringOrNull(json, 'response')),
  );
}

Map<String, Object?> _encodeChronic(ChronicCondition c) => <String, Object?>{
      'typeId': c.typeId,
      'startedAtAge': c.startedAtAge,
      'lastCaredAtAge': c.lastCaredAtAge,
      'endedAtAge': c.endedAtAge,
      'careYears': c.careYears,
    };

ChronicCondition _decodeChronic(Map<String, Object?> json) => ChronicCondition(
      typeId: _string(json, 'typeId'),
      startedAtAge: _int(json, 'startedAtAge'),
      lastCaredAtAge: _intOrNull(json, 'lastCaredAtAge'),
      endedAtAge: _intOrNull(json, 'endedAtAge'),
      careYears: _intOr(json, 'careYears', 0),
    );

Map<String, Object?> _encodeHealthHistory(HealthHistoryEntry h) =>
    <String, Object?>{
      'crisisId': h.crisisId,
      'age': h.age,
      'choiceId': h.choiceId,
      'chronicTypeId': h.chronicTypeId,
    };

HealthHistoryEntry _decodeHealthHistory(Map<String, Object?> json) =>
    HealthHistoryEntry(
      crisisId: _string(json, 'crisisId'),
      age: _int(json, 'age'),
      choiceId: _string(json, 'choiceId'),
      chronicTypeId: _stringOrNull(json, 'chronicTypeId'),
    );

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
      // Küslük ve arkadaşlık tarihi (D-130). Eski kayıtlarda yoktur;
      // kimse küs açılmaz ve geriye dönük tarih uydurulmaz.
      'estrangedSinceAge': p.estrangedSinceAge,
      'becameFriendAtAge': p.becameFriendAtAge,
      'homeTie': p.homeTie,
      // Biyolojik soy bağı (Paket AO §14). Eski kayıtlarda yoktur ve
      // `null` kalır; geriye dönük soy ağacı **uydurulmaz** (§47).
      'motherId': p.motherId,
      'fatherId': p.fatherId,
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
      'marriedAtAge': d.marriedAtAge,
      'spouseName': d.spouseName,
      // Paket AP §14-§18, §61: NPC evliliği artık gerçek bir eş kaydına
      // bağlı ve geçmişi var. Eski kayıtlarda bu üç alan yok; okuma
      // tarafı onları `null` / boş liste olarak karşılıyor.
      'spousePersonId': d.spousePersonId,
      'marriageStatus': d.marriageStatus?.name,
      'pastMarriages': <Map<String, Object?>>[
        for (final NpcMarriageRecord m in d.pastMarriages)
          <String, Object?>{
            'spouseName': m.spouseName,
            'spousePersonId': m.spousePersonId,
            'marriedAtAge': m.marriedAtAge,
            'endedAtAge': m.endedAtAge,
            'status': m.status.name,
          },
      ],
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
    marriedAtAge: _intOrNull(json, 'marriedAtAge'),
    spouseName: _stringOrNull(json, 'spouseName'),
    // Paket AP §17: eski kayıtta bu alanlar yok. Geriye dönük sahte bir
    // eş Person'ı **uydurulmaz**; kayıt isimle yaşamaya devam eder ve
    // `isMarried` eski davranışı korur (durum yoksa evlilik yaşına
    // bakar).
    spousePersonId: _stringOrNull(json, 'spousePersonId'),
    marriageStatus: _enumByNameOrNull(
      NpcMarriageStatus.values,
      _stringOrNull(json, 'marriageStatus'),
      'development.marriageStatus',
    ),
    pastMarriages: List<NpcMarriageRecord>.unmodifiable(<NpcMarriageRecord>[
      for (final Object? e in _optionalRawList(json, 'pastMarriages'))
        NpcMarriageRecord(
          spouseName: _string(_asMap(e, 'pastMarriage'), 'spouseName'),
          spousePersonId:
              _stringOrNull(_asMap(e, 'pastMarriage'), 'spousePersonId'),
          marriedAtAge: _int(_asMap(e, 'pastMarriage'), 'marriedAtAge'),
          endedAtAge: _intOrNull(_asMap(e, 'pastMarriage'), 'endedAtAge'),
          // Durumu okunamayan geçmiş kayıt **boşanma** sayılır: kaydın
          // geçmişe taşınmış olması zaten bittiğini söylüyor.
          status: _enumByNameOrNull(
                NpcMarriageStatus.values,
                _stringOrNull(_asMap(e, 'pastMarriage'), 'status'),
                'pastMarriage.status',
              ) ??
              NpcMarriageStatus.bosandi,
        ),
    ]),
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
      // Hayvan sağlığı ve kayıp durumu (D-082). Alan eklemeli.
      'health': pet.health,
      'missingSinceAge': pet.missingSinceAge,
      // Sahiplendirme alan eklemeli (D-109); eski kayıtta yoktur.
      'rehomedAtPlayerAge': pet.rehomedAtPlayerAge,
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
      'synergyHeadStart': c.synergyHeadStart,
      'detainedYears': c.detainedYears,
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

  // **Eski kayıt göçü (D-163).** Kiralama sözleşmeleri gelmeden önce
  // "bu ev kirada" bilgisi `OwnedItem.rentedOut` bayrağında duruyordu.
  // Kiracı, kira bedeli ve depozito bilgisi yoktu. Eski kayıt silinmez:
  // bayrak taşıyan her konut için, o konutun kendi bilgilerinden türeyen
  // bir sözleşme **üretilir** ve oyuncunun kirası kesilmeden devam eder.
  // Üretim belirlenimlidir: aynı kayıt her açılışta aynı kiracıyı verir.
  final List<Lease> yazilanSozlesmeler = _optionalRawList(json, 'leases')
      .map((Object? e) => _decodeLease(_asMap(e, 'leases[]')))
      .toList();
  final Set<String> sozlesmeliMulkler = <String>{
    for (final Lease l in yazilanSozlesmeler) l.propertyItemId,
  };
  for (final Object? ham in _optionalRawList(json, 'items')) {
    final Map<String, Object?> esya = _asMap(ham, 'items[]');
    if (esya['rentedOut'] != true) continue;
    final String esyaId = _string(esya, 'id');
    if (sozlesmeliMulkler.contains(esyaId)) continue;
    final OwnedItem konut = _decodeItem(esya);
    if (!konut.isProperty) continue;
    yazilanSozlesmeler.add(
      Lease(
        propertyItemId: esyaId,
        tenant: migratedTenantFor(esyaId),
        yearlyRent: legacyYearlyRent(konut),
        // Eski kayıtta depozito diye bir şey yoktu; uydurup oyuncuya borç
        // yazmıyoruz. Sıfır depozito, çıkışta iade edilecek bir şey de yok.
        deposit: 0,
        startedAtAge: konut.acquiredAtAge,
      ),
    );
  }
  final List<Lease> okunanSozlesmeler =
      List<Lease>.unmodifiable(yazilanSozlesmeler);

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
    // D-153. `_optionalRawList` eksik anahtarı boş liste okur; eski
    // kayıtlar bu yüzden bozulmaz.
    chronicConditions: List<ChronicCondition>.unmodifiable(
      _optionalRawList(json, 'chronicConditions')
          .map((Object? e) =>
              _decodeChronic(_asMap(e, 'chronicConditions[]')))
          .toList(growable: false),
    ),
    healthHistory: List<HealthHistoryEntry>.unmodifiable(
      _optionalRawList(json, 'healthHistory')
          .map((Object? e) =>
              _decodeHealthHistory(_asMap(e, 'healthHistory[]')))
          .toList(growable: false),
    ),
    // D-156. `_intMap` eksik anahtarda hata verir; bu yüzden null
    // koruması şart (eski kayıtlar bozulmasın).
    goalsReachedAt: json['goalsReachedAt'] == null
        ? const <String, int>{}
        : _intMap(json, 'goalsReachedAt'),
    vehicleInspectionAt: json['vehicleInspectionAt'] == null
        ? const <String, int>{}
        : _intMap(json, 'vehicleInspectionAt'),
    alimony: json['alimony'] == null
        ? null
        : _decodeAlimony(_asMap(json['alimony'], 'alimony')),
    // D-162. Eksik anahtar boş portföy ve taze piyasa demektir; eski
    // kayıtlar bu yüzden bozulmaz.
    investments: List<Holding>.unmodifiable(
      _optionalRawList(json, 'investments')
          .map((Object? e) => _decodeHolding(_asMap(e, 'investments[]')))
          .toList(growable: false),
    ),
    termDeposits: List<TermDeposit>.unmodifiable(
      _optionalRawList(json, 'termDeposits')
          .map((Object? e) => _decodeTermDeposit(_asMap(e, 'termDeposits[]')))
          .toList(growable: false),
    ),
    investmentHistory: List<InvestmentRecord>.unmodifiable(
      _optionalRawList(json, 'investmentHistory')
          .map((Object? e) =>
              _decodeInvestmentRecord(_asMap(e, 'investmentHistory[]')))
          .toList(growable: false),
    ),
    market: json['market'] == null
        ? const MarketState()
        : _decodeMarket(_asMap(json['market'], 'market')),
    leases: okunanSozlesmeler,
    propertyLedgers: List<PropertyLedger>.unmodifiable(
      _optionalRawList(json, 'propertyLedgers')
          .map((Object? e) => _decodeLedger(_asMap(e, 'propertyLedgers[]')))
          .toList(growable: false),
    ),
    landlord: json['landlord'] == null
        ? null
        : _decodeLandlord(_asMap(json['landlord'], 'landlord')),
    martialArts: List<MartialProgress>.unmodifiable(
      _optionalRawList(json, 'martialArts')
          .map((Object? e) => _decodeMartial(_asMap(e, 'martialArts[]')))
          .toList(growable: false),
    ),
    // Paket AU: eski kayıtta yok; boş liste ile yüklenir. Oyuncunun
    // yaşamadığı bir kulüp geçmişi **uydurulmaz**.
    schoolClubs: List<SchoolClubProgress>.unmodifiable(
      _optionalRawList(json, 'schoolClubs')
          .map((Object? e) => _decodeSchoolClub(_asMap(e, 'schoolClubs[]')))
          .toList(growable: false),
    ),
    // Paket AY: eski kayıtta alan yoksa null kalır; uydurma kariyer
    // üretilmez.
    footballCareer: json['footballCareer'] == null
        ? null
        : _decodeFootball(_asMap(json['footballCareer'], 'footballCareer')),
    footballTrialAge: _intOrNull(json, 'footballTrialAge'),
    // Paket AL: eski kayıtta yok; boş liste ile yüklenir.
    combatCareers: List<CombatCareer>.unmodifiable(
      _optionalRawList(json, 'combatCareers')
          .map((Object? e) => _decodeCombat(_asMap(e, 'combatCareers[]')))
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
    fingerIncoming: List<FingerProfile>.unmodifiable(
      _optionalRawList(json, 'fingerIncoming')
          .map((Object? e) => _decodeFinger(_asMap(e, 'fingerIncoming[]')))
          .toList(growable: false),
    ),
    fingerBio: _stringOrNull(json, 'fingerBio'),
    fingerInterests: List<String>.unmodifiable(
      json['fingerInterests'] == null
          ? const <String>[]
          : _stringList(json, 'fingerInterests'),
    ),
    fingerPremiumUntilAge: _intOrNull(json, 'fingerPremiumUntilAge'),
    fingerIntent: json['fingerIntent'] == null
        ? FingerIntent.belirsiz
        : _enumByName(
            FingerIntent.values,
            _string(json, 'fingerIntent'),
            'fingerIntent',
          ),
    fingerWealthFilter: json['fingerWealthFilter'] == null
        ? null
        : _enumByName(
            WealthTier.values,
            _string(json, 'fingerWealthFilter'),
            'fingerWealthFilter',
          ),
    socialAccounts: List<SocialAccount>.unmodifiable(
      _list(json, 'socialAccounts')
          .map((Object? e) => _decodeAccount(_asMap(e, 'socialAccounts[]')))
          .toList(growable: false),
    ),
    // Eski kayıtlarda sponsorluk yoktur; boş açılır.
    mediaInvitationId: _stringOrNull(json, 'mediaInvitationId'),
    mediaInvitationAge: _intOrNull(json, 'mediaInvitationAge'),
    // Eski kayıtta bu alan yoktur; **eksik olması hata değildir**.
    mediaJobLastAge: Map<String, int>.unmodifiable(
      json['mediaJobLastAge'] == null
          ? const <String, int>{}
          : _intMap(json, 'mediaJobLastAge'),
    ),
    friendNewsLastAge: Map<String, int>.unmodifiable(
      json['friendNewsLastAge'] == null
          ? const <String, int>{}
          : _intMap(json, 'friendNewsLastAge'),
    ),
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
    pendingRace: json['pendingRace'] == null
        ? null
        : _decodePendingRace(_asMap(json['pendingRace'], 'pendingRace')),
    // Yıl özeti alanları eklemeli; eski kayıtta yoktur (D-096).
    yearMark: json['yearMark'] == null
        ? null
        : _decodeYearMark(_asMap(json['yearMark'], 'yearMark')),
    lastYearSummary: json['lastYearSummary'] == null
        ? null
        : _decodeYearSummary(
            _asMap(json['lastYearSummary'], 'lastYearSummary'),
          ),
    lastSportAge: _intOrNull(json, 'lastSportAge'),
    lastGroomingAge: _intOrNull(json, 'lastGroomingAge'),
    lastLearningAge: _intOrNull(json, 'lastLearningAge'),
    familyIssues: List<FamilyIssue>.unmodifiable(
      _optionalRawList(json, 'familyIssues')
          .map((Object? e) =>
              _decodeFamilyIssue(_asMap(e, 'familyIssues[]')))
          .whereType<FamilyIssue>()
          .toList(growable: false),
    ),
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
            // Eski kayıtlarda sebep yoktur; `null` kalır ve ekranda
            // uydurma sebep yazılmaz.
            causeId: _stringOrNull(
              _asMap(json['pendingCrisis'], 'pendingCrisis'),
              'causeId',
            ),
          ),
    lastCrisisAge: _intOrNull(json, 'lastCrisisAge'),
    healthWarned: json['healthWarned'] == true,
    // Eski kayıtlarda hayati tehlike uyarısı yoktur; verilmemiş sayılır.
    healthDangerWarned: json['healthDangerWarned'] == true,
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
    // Eski kayıtlarda çocuk planı yoktur; **geriye dönük niyet
    // uydurulmaz**, plan "konuşulmadı" olarak açılır (Paket BK/2).
    familyPlan: json['familyPlan'] == null
        ? FamilyPlan.belirsiz
        : _enumByName(
            FamilyPlan.values,
            json['familyPlan'] as String,
            'familyPlan',
          ),
    familyPlanPartnerId: json['familyPlanPartnerId'] as String?,
    // Eski kayıtlarda askerlik kaydı yoktur; **geriye dönük askerlik
    // uydurulmaz**, durum "yapılmadı" olarak açılır (Paket 29).
    military: json['military'] == null
        ? const MilitaryState()
        : _decodeMilitary(_asMap(json['military'], 'military')),
    // Eski kayıtlarda iş kaydı yoktur; boş açılır (D-132).
    businesses: List<Business>.unmodifiable(<Business>[
      for (final Object? e in _optionalRawList(json, 'businesses'))
        _decodeBusiness(_asMap(e, 'business')),
    ]),
    // Eski kayıtlarda adli kayıt yoktur; **temiz** açılır (D-128).
    legal: json['legal'] == null
        ? const LegalState()
        : _decodeLegal(_asMap(json['legal'], 'legal')),
    pendingTrial: json['pendingTrial'] == null
        ? null
        : _decodeTrial(_asMap(json['pendingTrial'], 'pendingTrial')),
    // Eski kayıtlarda deneme sayacı yoktur; sıfırdan başlar.
    unprotectedTries: _intOrNull(json, 'unprotectedTries') ?? 0,
    ivfAttempts: _intOrNull(json, 'ivfAttempts') ?? 0,
    lastConceptionTryAge: _intOrNull(json, 'lastConceptionTryAge'),
    conceptionTriesAtAge: _intOr(json, 'conceptionTriesAtAge', 0),
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
            // Modül anahtarları: alan yoksa katalog varsayılanı geçerli,
            // tanınmayan anahtar sessizce atılır (silinmiş özellik).
            features: _asMap(json['settings'], 'settings')['features'] == null
                ? FeatureSwitches.defaults
                : FeatureSwitches.fromMap(
                    _asMap(
                      _asMap(json['settings'], 'settings')['features'],
                      'features',
                    ),
                  ),
            // Görünüm seçimi: alan yoksa ya da tanınmıyorsa cihazın
            // ayarı geçerli (eski kayıtlar olduğu gibi açılır).
            themeChoice: AppThemeChoice.byKey(
              _asMap(json['settings'], 'settings')['themeChoice'],
            ),
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
    // Atletik potansiyel (Paket AU). Eski kayıtta yoktur: null kalır ve
    // kimlikten deterministik türetilir, uydurulmaz.
    storedAthleticPotential: _intOrNull(json, 'athleticPotential'),
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

CombatOpponent _decodeOpponent(Map<String, Object?> json) => CombatOpponent(
      id: _string(json, 'id'),
      name: _string(json, 'name'),
      age: _int(json, 'age'),
      rating: _int(json, 'rating'),
      wins: _intOr(json, 'wins', 0),
      losses: _intOr(json, 'losses', 0),
      metCount: _intOr(json, 'metCount', 0),
      playerWins: _intOr(json, 'playerWins', 0),
      playerLosses: _intOr(json, 'playerLosses', 0),
      fameAwards: _intOr(json, 'fameAwards', 0),
      tier: _intOr(json, 'opponentTier', 0),
    );

CombatCareer _decodeCombat(Map<String, Object?> json) {
  final Object? bekleyen = json['pendingBout'];
  return CombatCareer(
    artId: _string(json, 'artId'),
    startedCompetitiveAtAge: _int(json, 'startedCompetitiveAtAge'),
    status: CompetitiveStatus.values.firstWhere(
      (CompetitiveStatus s) => s.name == json['status'],
      orElse: () => CompetitiveStatus.amator,
    ),
    tier: _intOr(json, 'tier', 0),
    amateurWins: _intOr(json, 'amateurWins', 0),
    amateurLosses: _intOr(json, 'amateurLosses', 0),
    proWins: _intOr(json, 'proWins', 0),
    proLosses: _intOr(json, 'proLosses', 0),
    championships: _intOr(json, 'championships', 0),
    isChampion: json['isChampion'] == true,
    ranking: _intOr(json, 'ranking', 0),
    lastBoutAge: _intOrNull(json, 'lastBoutAge'),
    form: _intOr(json, 'form', 50),
    reputation: _intOr(json, 'reputation', 0),
    careerEarnings: _intOr(json, 'careerEarnings', 0),
    sponsorEarnings: _intOr(json, 'sponsorEarnings', 0),
    injuryCount: _intOr(json, 'injuryCount', 0),
    seriousInjuryCount: _intOr(json, 'seriousInjuryCount', 0),
    injury: InjurySeverity.values.firstWhere(
      (InjurySeverity s) => s.name == json['injury'],
      orElse: () => InjurySeverity.yok,
    ),
    injuryYearsLeft: _intOr(json, 'injuryYearsLeft', 0),
    retiredAtAge: _intOrNull(json, 'retiredAtAge'),
    retirementReason: json['retirementReason'] == null
        ? null
        : RetirementReason.values.firstWhere(
            (RetirementReason r) => r.name == json['retirementReason'],
            orElse: () => RetirementReason.kendiKarari,
          ),
    coachLevel: _intOr(json, 'coachLevel', 0),
    opponents: List<CombatOpponent>.unmodifiable(
      _optionalRawList(json, 'opponents')
          .map((Object? e) => _decodeOpponent(_asMap(e, 'opponents[]')))
          .toList(growable: false),
    ),
    pendingBout: bekleyen == null
        ? null
        : () {
            final Map<String, Object?> b = _asMap(bekleyen, 'pendingBout');
            return PendingBout(
              tier: _intOr(b, 'tier', 0),
              opponent:
                  _decodeOpponent(_asMap(b['opponent'], 'pendingBout.opponent')),
              purse: _intOr(b, 'purse', 0),
              seed: _intOr(b, 'seed', 0),
              offeredAtAge: _intOr(b, 'offeredAtAge', 0),
              isTitle: b['isTitle'] == true,
            );
          }(),
    memories: List<CombatMemory>.unmodifiable(
      _optionalRawList(json, 'memories').map((Object? e) {
        final Map<String, Object?> m = _asMap(e, 'memories[]');
        return CombatMemory(age: _int(m, 'age'), text: _string(m, 'text'));
      }).toList(growable: false),
    ),
    lastTitleAge: _intOrNull(json, 'lastTitleAge'),
    schoolConflictAge: _intOrNull(json, 'schoolConflictAge'),
  );
}

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
      intent: json['intent'] == null
          ? FingerIntent.belirsiz
          : _enumByName(
              FingerIntent.values,
              _string(json, 'intent'),
              'finger.intent',
            ),
      wealth: json['wealth'] == null
          ? WealthTier.ortaHalli
          : _enumByName(
              WealthTier.values,
              _string(json, 'wealth'),
              'finger.wealth',
            ),
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

YearMark _decodeYearMark(Map<String, Object?> json) => YearMark(
      age: _int(json, 'age'),
      stats: Stats(
        appearance: _int(json, 'appearance'),
        happiness: _int(json, 'happiness'),
        health: _int(json, 'health'),
        intelligence: _int(json, 'intelligence'),
        charisma: _int(json, 'charisma'),
      ),
      wallet: _int(json, 'wallet'),
      fame: _intOrNull(json, 'fame'),
      childMarks: json['childMarks'] == null
          ? const <String, ChildMark>{}
          : <String, ChildMark>{
              for (final MapEntry<String, Object?> e
                  in _asMap(json['childMarks'], 'yearMark.childMarks')
                      .entries)
                e.key: _decodeChildMark(
                  _asMap(e.value, 'yearMark.childMarks.${e.key}'),
                ),
            },
    );

ChildMark _decodeChildMark(Map<String, Object?> json) => ChildMark(
      stats: Stats(
        appearance: _int(json, 'appearance'),
        happiness: _int(json, 'happiness'),
        health: _int(json, 'health'),
        intelligence: _int(json, 'intelligence'),
        charisma: _int(json, 'charisma'),
      ),
      money: _int(json, 'money'),
      interests: _stringList(json, 'interests'),
      bond: _int(json, 'bond'),
      happiness: _int(json, 'ownHappiness'),
      milestones: _int(json, 'milestones'),
    );

YearSummary _decodeYearSummary(Map<String, Object?> json) => YearSummary(
      age: _int(json, 'age'),
      effects: List<AppliedEffect>.unmodifiable(<AppliedEffect>[
        for (final Map<String, Object?> e
            in _optionalRawList(json, 'effects').map(
          (Object? raw) => _asMap(raw, 'lastYearSummary.effects'),
        ))
          AppliedEffect(
            label: _string(e, 'label'),
            delta: _intOrNull(e, 'delta'),
            unit: e['unit'] is String ? e['unit']! as String : '',
          ),
      ]),
      // Çocukların özeti (Paket BK/5). Eski kayıtta yoktur; boş liste
      // okunur ve geriye dönük bir yıl özeti uydurulmaz.
      children: List<ChildYearSummary>.unmodifiable(<ChildYearSummary>[
        for (final Map<String, Object?> c
            in _optionalRawList(json, 'children').map(
          (Object? raw) => _asMap(raw, 'lastYearSummary.children'),
        ))
          ChildYearSummary(
            childId: _string(c, 'childId'),
            name: _string(c, 'name'),
            age: _int(c, 'age'),
            effects: List<AppliedEffect>.unmodifiable(<AppliedEffect>[
              for (final Map<String, Object?> e
                  in _optionalRawList(c, 'effects').map(
                (Object? raw) =>
                    _asMap(raw, 'lastYearSummary.children.effects'),
              ))
                AppliedEffect(
                  label: _string(e, 'label'),
                  delta: _intOrNull(e, 'delta'),
                  unit: e['unit'] is String ? e['unit']! as String : '',
                ),
            ]),
            milestones: List<String>.unmodifiable(
              _stringList(c, 'milestones'),
            ),
          ),
      ]),
    );

PendingRace _decodePendingRace(Map<String, Object?> json) => PendingRace(
      id: _string(json, 'id'),
      lane: _int(json, 'lane'),
      bet: _int(json, 'bet'),
      winnerLane: _int(json, 'winnerLane'),
      payout: _int(json, 'payout'),
      horseName: _string(json, 'horseName'),
      winnerName: _string(json, 'winnerName'),
      oddsLabel: _string(json, 'oddsLabel'),
      atAge: _int(json, 'atAge'),
    );

Loan _decodeLoan(Map<String, Object?> json) => Loan(
      id: _string(json, 'id'),
      bank: _enumByName(Bank.values, _string(json, 'bank'), 'loan.bank'),
      purpose: json['purpose'] == null
          ? LoanPurpose.ihtiyac
          : _enumByName(
              LoanPurpose.values,
              _string(json, 'purpose'),
              'loan.purpose',
            ),
      principal: _int(json, 'principal'),
      annualPayment: _int(json, 'annualPayment'),
      termYears: _int(json, 'termYears'),
      remainingPayments: _int(json, 'remainingPayments'),
      outstanding: _int(json, 'outstanding'),
      takenAtAge: _int(json, 'takenAtAge'),
      missedPayments: _intOr(json, 'missedPayments', 0),
      // Eski kayıtta yoksa: hiç aksamamış, hiç yapılandırılmamış sayılır.
      // Eski kayıtta yoksa `debtBase` mevcut bakiyeyi okur.
      originalDebt: _intOrNull(json, 'originalDebt'),
      missedStreak: _intOr(json, 'missedStreak', 0),
      restructures: _intOr(json, 'restructures', 0),
      writtenOff: json['writtenOff'] == true,
      closedAtAge: _intOrNull(json, 'closedAtAge'),
    );

CompanyVitals _decodeVitals(Map<String, Object?> json) => CompanyVitals(
      financialHealth: _intOr(json, 'financialHealth', 50),
      debtPressure: _intOr(json, 'debtPressure', 50),
      growth: _intOr(json, 'growth', 50),
      management: _intOr(json, 'management', 50),
      confidence: _intOr(json, 'confidence', 50),
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
    estrangedSinceAge: _intOrNull(json, 'estrangedSinceAge'),
    becameFriendAtAge: _intOrNull(json, 'becameFriendAtAge'),
    homeTie: _stringOrNull(json, 'homeTie'),
    // Paket AO §47: eski kayıtta soy bağı yoktur, `null` açılır.
    motherId: _stringOrNull(json, 'motherId'),
    fatherId: _stringOrNull(json, 'fatherId'),
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
      // Paket AK: eski kayıtta yok; 0 ile yüklenir, kayıt bozulmaz.
      synergyHeadStart: _intOr(json, 'synergyHeadStart', 0),
      detainedYears: _intOr(json, 'detainedYears', 0),
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
      // Eski kayıtta hayvan sağlığı yoktur; nötr okunur (D-082).
      health: _intOr(json, 'health', Pet.prototypeOnlyDefaultPetHealth),
      missingSinceAge: _intOrNull(json, 'missingSinceAge'),
      rehomedAtPlayerAge: _intOrNull(json, 'rehomedAtPlayerAge'),
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

/// Ondalıklı alan; yoksa [fallback] döner.
///
/// JSON'da tam sayı olarak yazılmış bir ondalık (`1` yerine `1.0`) da
/// kabul edilir: kayıt dosyası elle düzenlenmiş olabilir.
double _doubleOr(Map<String, Object?> json, String key, double fallback) {
  final Object? value = json[key];
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  _eksik(key, 'ondalıklı sayı');
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

/// Adli durumu okur.
///
/// Bilinmeyen bir aşama ya da karar gelirse kayıt **atılmaz**: en güvenli
/// karşılık okunur, çünkü bu projede kayıt silinmez.
LegalState _decodeLegal(Map<String, Object?> json) => LegalState(
      imprisonedSinceAge: _intOrNull(json, 'imprisonedSinceAge'),
      releaseAtAge: _intOrNull(json, 'releaseAtAge'),
      probationUntilAge: _intOrNull(json, 'probationUntilAge'),
      caseCounter: _intOr(json, 'caseCounter', 0),
      detainedSinceAge: _intOrNull(json, 'detainedSinceAge'),
      bailAmount: _intOrNull(json, 'bailAmount'),
      bailPaidBy: _stringOrNull(json, 'bailPaidBy'),
      bailAskedAtAge: _intOrNull(json, 'bailAskedAtAge'),
      goodBehaviour: _intOr(json, 'goodBehaviour', 0),
      crewStanding: _intOr(json, 'crewStanding', 0),
      crewOfferAtAge: _intOrNull(json, 'crewOfferAtAge'),
      crewJobs: _intOr(json, 'crewJobs', 0),
      yearsServed: _intOr(json, 'yearsServed', 0),
      cases: List<CriminalCase>.unmodifiable(<CriminalCase>[
        for (final Object? e in _optionalRawList(json, 'cases'))
          _decodeCase(_asMap(e, 'legal.case')),
      ]),
    );

CriminalCase _decodeCase(Map<String, Object?> json) => CriminalCase(
      id: _string(json, 'id'),
      crimeId: _string(json, 'crimeId'),
      ageAtIncident: _intOr(json, 'ageAtIncident', 0),
      stage: _enumByName(CaseStage.values, _string(json, 'stage'), 'case.stage'),
      verdict: _enumByName(
        Verdict.values,
        _stringOrNull(json, 'verdict') ?? Verdict.yok.name,
        'case.verdict',
      ),
      fine: _intOr(json, 'fine', 0),
      finePaid: _boolOr(json, 'finePaid'),
      prisonYears: _intOr(json, 'prisonYears', 0),
      lawyerId: _stringOrNull(json, 'lawyerId'),
      decidedAtAge: _intOrNull(json, 'decidedAtAge'),
      closedAtAge: _intOrNull(json, 'closedAtAge'),
      note: _stringOrNull(json, 'note'),
    );

PendingTrial _decodeTrial(Map<String, Object?> json) => PendingTrial(
      caseId: _string(json, 'caseId'),
      age: _intOr(json, 'age', 0),
      text: _string(json, 'text'),
    );

Business _decodeBusiness(Map<String, Object?> json) => Business(
      id: _string(json, 'id'),
      typeId: _string(json, 'typeId'),
      startedAtAge: _intOr(json, 'startedAtAge', 0),
      condition: _intOr(json, 'condition', Business.prototypeOnlyStartCondition),
      totalInvested: _intOr(json, 'totalInvested', 0),
      totalProfit: _intOr(json, 'totalProfit', 0),
      lastTendedAge: _intOrNull(json, 'lastTendedAge'),
      lastSettledAge: _intOrNull(json, 'lastSettledAge'),
      closedAtAge: _intOrNull(json, 'closedAtAge'),
      endReason: _enumByNameOrNull(
        BusinessEndReason.values,
        _stringOrNull(json, 'endReason'),
        'business.endReason',
      ),
      // Paket AE alanları: eski kayıtta yoklar, varsayılan değerleriyle
      // açılırlar. Fiyat 0 ise iş bölge ortalamasından çalışır.
      price: _intOr(json, 'price', 0),
      reputation:
          _intOr(json, 'reputation', Business.prototypeOnlyStartReputation),
      upkeep: _intOr(json, 'upkeep', Business.prototypeOnlyStartUpkeep),
      staffQuality: _intOr(
        json,
        'staffQuality',
        Business.prototypeOnlyStartStaffQuality,
      ),
      staffMorale: _intOr(
        json,
        'staffMorale',
        Business.prototypeOnlyStartStaffMorale,
      ),
      staffCount: _intOr(json, 'staffCount', -1),
      wageLevel: _intOr(json, 'wageLevel', 100),
      ad: _enumByNameOrNull(
            BusinessAd.values,
            _stringOrNull(json, 'ad'),
            'business.ad',
          ) ??
          BusinessAd.yok,
      adStreak: _intOr(json, 'adStreak', 0),
      yearMaintenanceSpend: _intOr(json, 'yearMaintenanceSpend', 0),
      lastMaintenanceAge: _intOrNull(json, 'lastMaintenanceAge'),
      lastStaffCareAge: _intOrNull(json, 'lastStaffCareAge'),
      lossStreak: _intOr(json, 'lossStreak', 0),
      demandPressure: _doubleOr(json, 'demandPressure', 1.0),
      recentIncidents: List<String>.unmodifiable(<String>[
        for (final Object? e in _optionalRawList(json, 'recentIncidents'))
          if (e is String) e,
      ]),
      history: List<BusinessYear>.unmodifiable(<BusinessYear>[
        for (final Object? e in _optionalRawList(json, 'history'))
          _decodeBusinessYear(_asMap(e, 'businessYear')),
      ]),
    );

BusinessYear _decodeBusinessYear(Map<String, Object?> json) => BusinessYear(
      age: _intOr(json, 'age', 0),
      revenue: _intOr(json, 'revenue', 0),
      staffCost: _intOr(json, 'staffCost', 0),
      supplyCost: _intOr(json, 'supplyCost', 0),
      fixedCost: _intOr(json, 'fixedCost', 0),
      maintenanceCost: _intOr(json, 'maintenanceCost', 0),
      adCost: _intOr(json, 'adCost', 0),
      incidentCost: _intOr(json, 'incidentCost', 0),
      net: _intOr(json, 'net', 0),
      price: _intOr(json, 'price', 0),
      marketPrice: _intOr(json, 'marketPrice', 0),
      demandIndex: _intOr(json, 'demandIndex', 100),
    );

// =====================================================================
// Kiralama (D-163)
// =====================================================================

Map<String, Object?> _encodeTenant(TenantRecord t) => <String, Object?>{
      'id': t.id,
      'firstName': t.firstName,
      'lastName': t.lastName,
      'age': t.age,
      'occupation': t.occupation,
      'household': t.household.name,
      'income': t.income.name,
      'track': t.track.name,
      'reliability': t.reliability,
      'care': t.care,
    };

TenantRecord _decodeTenant(Map<String, Object?> json) => TenantRecord(
      id: _string(json, 'id'),
      firstName: _string(json, 'firstName'),
      lastName: _string(json, 'lastName'),
      age: _int(json, 'age'),
      occupation: _string(json, 'occupation'),
      household: _enumByNameOrNull(
              TenantHousehold.values,
              _stringOrNull(json, 'household'),
              'household',
            ) ??
            TenantHousehold.tekBasina,
      income: _enumByNameOrNull(
              TenantIncome.values,
              _stringOrNull(json, 'income'),
              'income',
            ) ??
            TenantIncome.orta,
      track: _enumByNameOrNull(
              TenantTrack.values,
              _stringOrNull(json, 'track'),
              'track',
            ) ??
            TenantTrack.belirsiz,
      reliability: _int(json, 'reliability'),
      care: _int(json, 'care'),
    );

Map<String, Object?> _encodeLease(Lease l) => <String, Object?>{
      'propertyItemId': l.propertyItemId,
      'tenant': _encodeTenant(l.tenant),
      'yearlyRent': l.yearlyRent,
      'deposit': l.deposit,
      'startedAtAge': l.startedAtAge,
      'onTimeYears': l.onTimeYears,
      'lateYears': l.lateYears,
      'unpaidYears': l.unpaidYears,
      if (l.lastRenewedAtAge != null) 'lastRenewedAtAge': l.lastRenewedAtAge,
      if (l.graceGivenAtAge != null) 'graceGivenAtAge': l.graceGivenAtAge,
    };

Lease _decodeLease(Map<String, Object?> json) => Lease(
      propertyItemId: _string(json, 'propertyItemId'),
      tenant: _decodeTenant(_asMap(json['tenant'], 'lease.tenant')),
      yearlyRent: _int(json, 'yearlyRent'),
      deposit: _int(json, 'deposit'),
      startedAtAge: _int(json, 'startedAtAge'),
      onTimeYears: _intOr(json, 'onTimeYears', 0),
      lateYears: _intOr(json, 'lateYears', 0),
      unpaidYears: _intOr(json, 'unpaidYears', 0),
      lastRenewedAtAge: _intOrNull(json, 'lastRenewedAtAge'),
      graceGivenAtAge: _intOrNull(json, 'graceGivenAtAge'),
    );

Map<String, Object?> _encodeLedger(PropertyLedger l) => <String, Object?>{
      'propertyItemId': l.propertyItemId,
      'rentCollected': l.rentCollected,
      'maintenanceSpent': l.maintenanceSpent,
      'depositHeld': l.depositHeld,
      'vacantYears': l.vacantYears,
      'tenantCount': l.tenantCount,
      if (l.lastMaintenanceAge != null)
        'lastMaintenanceAge': l.lastMaintenanceAge,
      if (l.valueBasis != null) 'valueBasis': l.valueBasis,
    };

PropertyLedger _decodeLedger(Map<String, Object?> json) => PropertyLedger(
      propertyItemId: _string(json, 'propertyItemId'),
      rentCollected: _intOr(json, 'rentCollected', 0),
      maintenanceSpent: _intOr(json, 'maintenanceSpent', 0),
      depositHeld: _intOr(json, 'depositHeld', 0),
      vacantYears: _intOr(json, 'vacantYears', 0),
      tenantCount: _intOr(json, 'tenantCount', 0),
      lastMaintenanceAge: _intOrNull(json, 'lastMaintenanceAge'),
      valueBasis: _intOrNull(json, 'valueBasis'),
    );

Map<String, Object?> _encodeLandlord(LandlordRecord l) => <String, Object?>{
      'firstName': l.firstName,
      'lastName': l.lastName,
      'sinceAge': l.sinceAge,
      'temperament': l.temperament.name,
    };

LandlordRecord _decodeLandlord(Map<String, Object?> json) => LandlordRecord(
      firstName: _string(json, 'firstName'),
      lastName: _string(json, 'lastName'),
      sinceAge: _int(json, 'sinceAge'),
      temperament: _enumByNameOrNull(
              LandlordTemperament.values,
              _stringOrNull(json, 'temperament'),
              'temperament',
            ) ??
            LandlordTemperament.olculu,
    );
