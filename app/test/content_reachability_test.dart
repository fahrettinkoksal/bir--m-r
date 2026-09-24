/// İçerik ulaşılabilirlik denetimi.
///
/// Amaç: ekranda **görünen ama asla açılamayan** seçenek kalmaması.
/// Oyuncu tarafında bu, tıklanmayan bir düğme ya da hep "Şu an kapalı"
/// yazan bir satır olarak görünür; kodda ise çoğunlukla bir kataloğun
/// başka bir katalogda karşılığı olmayan bir kimliğe bakmasıdır.
///
/// Bu testler denge tartışmaz; yalnızca "bu içeriğe hiçbir oyuncu
/// ulaşamaz" durumunu yakalar.
library;

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/education_tracks.dart';
import 'package:bir_omur/data/interview_catalog.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/martial_arts_catalog.dart';
import 'package:bir_omur/data/university_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Meslek kataloğu', () {
    test('her işin mülakat sorusu var', () {
      // JobMarket.applicationAvailability, sorusu olmayan işi
      // "mülakat soruları henüz yazılmadı" diyerek kapatır. İş listede
      // görünmeye devam ettiği için oyuncuya ölü bir düğme kalır.
      final List<String> sorusuz = <String>[
        for (final JobType job in kJobCatalog)
          if (questionsForJob(job.id).isEmpty) job.id,
      ];
      expect(
        sorusuz,
        isEmpty,
        reason: 'Bu işler listede görünür ama başvurulamaz: $sorusuz',
      );
    });

    test('iş kimlikleri benzersiz', () {
      final Set<String> gorulen = <String>{};
      for (final JobType job in kJobCatalog) {
        expect(gorulen.add(job.id), isTrue, reason: 'Tekrar eden: ${job.id}');
      }
    });

    test('aranan üniversite bölümleri gerçekten var', () {
      final Set<String> bolumler = <String>{
        for (final UniversityProgram p in kUniversityPrograms) p.id,
      };
      for (final JobType job in kJobCatalog) {
        for (final String istenen in job.programs) {
          expect(
            bolumler,
            contains(istenen),
            reason: '${job.id} olmayan bir bölüm istiyor: $istenen',
          );
        }
      }
    });

    test('aranan lise alanları kataloğa yazılmış', () {
      final Set<EducationTrack> alanlar = <EducationTrack>{
        for (final EducationTrackInfo a in kEducationTracks) a.track,
      };
      for (final JobType job in kJobCatalog) {
        for (final EducationTrack istenen in job.tracks) {
          expect(
            alanlar,
            contains(istenen),
            reason: '${job.id} seçilemeyen bir alan istiyor: $istenen',
          );
        }
      }
    });

    test('özellik eşikleri ulaşılabilir aralıkta', () {
      // Özellikler 0-100 arasında. 100 üstü bir eşik işi kalıcı kapatır.
      for (final JobType job in kJobCatalog) {
        expect(job.minIntelligence, lessThanOrEqualTo(100), reason: job.id);
        expect(job.minCharisma, lessThanOrEqualTo(100), reason: job.id);
      }
    });

    test('dövüş eğitmenliği işleri gerçek bir sanata bağlı', () {
      for (final JobType job in kJobCatalog) {
        final String? sanatId = job.martialArtId;
        if (sanatId == null) continue;
        expect(
          martialArtById(sanatId),
          isNotNull,
          reason: '${job.id} olmayan bir sanata bağlı: $sanatId',
        );
      }
    });
  });

  group('Dövüş sanatları', () {
    test('eğitmenlik eşiği gerçek bir basamak', () {
      for (final MartialArt art in MartialArt.values) {
        expect(
          art.instructorFromLevel,
          greaterThanOrEqualTo(0),
          reason: art.id,
        );
        expect(
          art.instructorFromLevel,
          lessThan(art.ranks.length),
          reason: '${art.id} eşiği basamak sayısını aşıyor',
        );
      }
    });

    test('eğitmenlik işi katalogda var', () {
      for (final MartialArt art in MartialArt.values) {
        expect(
          jobById(art.instructorJobId),
          isNotNull,
          reason:
              '${art.id} olmayan bir işe işaret ediyor: '
              '${art.instructorJobId}',
        );
      }
    });

    test('basamaklar artan sırada ve ilki sıfır ders', () {
      for (final MartialArt art in MartialArt.values) {
        expect(art.ranks.first.lessonsNeeded, 0, reason: art.id);
        for (int i = 1; i < art.ranks.length; i++) {
          expect(
            art.ranks[i].lessonsNeeded,
            greaterThan(art.ranks[i - 1].lessonsNeeded),
            reason: '${art.id} ${i}. basamak geriye gidiyor',
          );
        }
      }
    });

    test('en üst basamak makul bir ömürde tamamlanabilir', () {
      // Yılda en fazla kMaxMartialLessonsPerAge ders alınabiliyor.
      // En üst basamak, başlama yaşından itibaren bir ömre sığmalı.
      for (final MartialArt art in MartialArt.values) {
        final int gerekenYil = (art.totalLessons / kMaxMartialLessonsPerAge)
            .ceil();
        expect(
          art.minAge + gerekenYil,
          lessThan(90),
          reason: '${art.id} en üst basamağı bir ömre sığmıyor',
        );
      }
    });
  });

  group('Aktiviteler', () {
    test('her mekân ya eylem sunar ya da kendi içeriğiyle çalışır', () {
      // Kütüphane eylem listesi kullanmaz; yaşa uygun kitapları kendi
      // akışında sunar. Bunun dışında boş bir mekân, menüde açılıp
      // hiçbir şey sunmayan ölü bir satır demektir.
      for (final ActivityVenue mekan in ActivityVenue.values) {
        if (mekan == ActivityVenue.kutuphane) {
          expect(kBookCatalog, isNotEmpty, reason: 'Kütüphanede hiç kitap yok');
          continue;
        }
        expect(
          actionsAt(mekan),
          isNotEmpty,
          reason: '${mekan.name} mekânı boş: menüde açılıp hiçbir şey sunmaz',
        );
      }
    });

    test('eylemsiz mekânın yaş eşiği menüyü kapatmaz', () {
      // ActivityVenue.minAge, eylem listesi boşken nöbet değeri olarak
      // 120 döndürüyordu. Menü bu değeri yaş koşulu diye okuduğundan,
      // eylemsiz bir mekâna bir gün koşul eklenirse o mekân hiçbir yaşta
      // açılmazdı.
      for (final ActivityVenue mekan in ActivityVenue.values) {
        expect(
          mekan.minAge,
          lessThan(90),
          reason: '${mekan.name} hiçbir yaşta açılmaz',
        );
      }
    });

    test('her aktivite bir ömür içinde yapılabilecek yaşta açılır', () {
      for (final ActivityAction eylem in kActivityActions) {
        expect(
          eylem.minAge,
          lessThan(90),
          reason: '${eylem.id} ulaşılamayacak bir yaşta açılıyor',
        );
      }
    });

    test('aktivite kimlikleri benzersiz', () {
      final Set<String> gorulen = <String>{};
      for (final ActivityAction eylem in kActivityActions) {
        expect(
          gorulen.add(eylem.id),
          isTrue,
          reason: 'Tekrar eden aktivite: ${eylem.id}',
        );
      }
    });
  });
}
