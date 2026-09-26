# Bir Ömür — tasarım incelemesi ve karar kuyruğu

**Amaç:** Claude Code geliştirmede kullanıcıdan oyun tasarımı, arayüz, içerik veya denge kararı gerektiren bir durumla karşılaşırsa bunu sohbetin içinde kaybolan soru olarak bırakmasın. Buraya **öneri / karar bekliyor** statüsüyle yazsın; Faho ile ChatGPT burada tartışıp kararlaştırsın. **Bu dosyadaki hiçbir seçenek kendiliğinden onaylı değildir.** Kesinleşmiş kural yalnızca Faho'nun onayı üzerine `DECISIONS.md` ve ilgili tasarım belgesine geçirilir.

## Claude için iş akışı
1. Yeni karar gerektiğinde mevcut `DECISIONS.md`, ilgili `docs/` belgeleri ve bu kuyruğu kontrol et. Daha önce kararlaştırılmış konuyu yeniden sorma.
2. Tekil `Q-###` numarasıyla **soru**, neden gerekli olduğu, mevcut ürün kuralı, mümkün seçenekler, uygulamaya etkisi, **Claude'un önerisi (yalnızca öneri)** ve **varsayılan işlem: onay gelene dek ürün kuralını değiştirme** başlıklarıyla kaydet. Uygun olduğunda etkilenen kod/dosya veya PR bağlantısını ekle.
3. Kuyruğu **ayrı bir commit** ile yalnızca `fahrettinkoksal/bir--m-r` deposuna gönder; açık PR/çalışma dalındaysa o dal üzerinden ve PR bağlantısıyla bildir. Ana dala yazma izni açıkça verilmediyse `main`e doğrudan yazma. Güncel dosyayı okuyup değişiklikleri birleştir, mevcut soruları silme.
4. Claude, kullanıcıya kısa bir mesajla **kuyruk bağlantısını ve soru numaralarını** bildirsin. Kararı sohbet içinde tek taraflı aldırmaya çalışma; Faho ve ChatGPT birlikte değerlendirecek. Karar bekleyen bölüm dışında bağımsız, geri alınabilir ve mevcut onaylara uygun işleri sürdürebilir; karar kritik bir engelse durup bildir.
5. Faho'nun kararı teyit edilince ilgili `Q-###` statüsünü **kararlaştırıldı** yap; kararın tam metnini ve ilgili `DECISIONS.md` kimliğini ekle. Karar onayı yoksa `DECISIONS.md` değiştirme. Görsel tasarım beğenilmeyip revizyon istendiyse seçenekleri ve mümkünse ekran görüntülerini/PR'ı kuyrukta referansla.

## Açık sorular — PR #1 incelemesi (19 Eylül 2026)

### Q-001 — İlk prototipin görsel yönü ve ekran yerleşimi
**Durum:** Karar bekliyor. **Kaynak:** [PR #1](https://github.com/fahrettinkoksal/bir--m-r/pull/1), `app/lib/ui/theme/bir_omur_theme.dart`, `app/lib/ui/screens/{life_screen,family_screen,me_screen}.dart`, `app/test/goldens/`.

**Faho'nun geri bildirimi:** Mevcut tasarımını beğenmedi; yeniden ele almak istiyor. Önceki onay **modern + ölçülü nostalji** yönü ve ilk prototip **Hayat / Aile / Ben** gezinmesiydi; mevcut krem/nar/çini paleti, standart Material kartları, yoğun bilgi/istatistik yerleşimi ve kilim şeridi tek tek kullanıcı onayı almış marka tasarımı **değildir**.

**Karar sorusu:** Hayat, Aile, Ben, karakter oluşturma ve olay ekranlarını hangi **özgün** görsel kompozisyon ve yoğunlukta yeniden tasarlayalım? Örnek seçenekler: (A) daha çağdaş, oyun hissi veren güçlü tipografi + sade nostaljik aksanlar; (B) daha sıcak anı defteri/hayat günlüğü ama modern etkileşimler; (C) kullanıcı ekran görüntüleri veya referansından hareketle üçüncü yön. Bunlar seçenek, onay değil. Claude önce mevcut ekran görüntülerini kolay incelenir biçimde PR'a eklemeli; olası yeniden tasarımı mevcut veri/olay mantığından ayırmalı. BitLife ekranını/görselini birebir kopyalama.

**Varsayılan işlem:** Yeni görsel tasarımı onay gelmeden kalıcı marka standardı gibi sunma; görsel revizyon için ayrı, küçük PR taslağı planla.

**Somut öneri hazır (19 Eylül 2026, Claude):** `claude/arayuz-revizyonu-v1` dalında NAV-001 gezinmesini uygulayan bir düzen önerisi var: üstte sabit karakter özeti (ad, yaş/evre, şehir, cüzdan, beş değerin yatay şeridi), ortada hayat günlüğü, altta sıcak koyu ahşap zeminli sabit çubuk ve ortada nar kırmızısı/pirinç halkalı `Yaş Al` düğmesi. Eski sıkışık değer kartı ve ayrı "Ben" ekranı kaldırıldı. Ekranlar: `app/test/goldens/README.md`. **Bu bir öneridir; Q-001 hâlâ karar bekliyor.**

### Q-002 — Aynı yaşta ek olay temposu
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/events/event_engine.dart` (`prototypeOnlyMaxExtraEventsPerAge = 1`, `prototypeOnlyProgressPerExtraEvent = 3`).

**Mevcut kesin kural:** Yaş Al sonrası ilk olay tek başına gelir; oyuncu ilerledikçe **aynı yaşta da aralıklı, uygun yeni olaylar** gelebilir. Oyuncuya gerçek dakika bekletilmez; her dokunuşta olay spam'i olmaz. **Bir yaşta en fazla bir ek olay** veya **üç anlamlı eylem eşiği** onaylanmadı.

**Karar sorusu:** Yeni olay fırsatını sabit kota/eşik olmaksızın hangi oyun içi gelişmeler tetiklesin ve spam nasıl önlensin? Mevcut 1 olay/3 eylem **yalnızca demo parametresi**, nihai çözüm değil. Onay gelene kadar kesin yıllık kural sayma.

### Q-003 — Eski sevgiliyle etkileşimler ve ayrılığın hikâye durumuna etkisi
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/interaction/family_interactions.dart`, `romance.dart`, `app/lib/state/game_controller.dart`, `app/lib/data/event_pool.dart`.

**Mevcut kesin kural:** Eski sevgili aynı kişi kaydı ve geçmişiyle Aile'de kalır; sevgili statüsü devam etmez. Hangi iletişimlerin açık kalacağı onaylanmadı.

**Karar sorusu:** Eski sevgiliyle ör. selamlaşma/konuşma veya koşullu barışma gibi eylemler olacak mı? Hangi bağlamda? **Ayrıca teknik hata:** Kişi detayından `Ayrıl` seçimi kişi statüsünü değiştiriyor ancak `romantikBitti`/`romantikIliskide` hikâye izlerini güncellemiyor; dolayısıyla eski sevgiliyle karşılaşma olayının önkoşulu sağlanmıyor. Bu durum tasarım seçimi değil, iki ayrılık yolunun aynı tutarlı sonuç üretmesini gerektiren hata düzeltmesidir.

**Varsayılan işlem:** Mevcut eski sevgili eylemlerini geçici kapalı tut; teknik tutarsızlığı onaylı hikâye hafızası kurallarına uygun düzeltip test et; yeni eylemler için onay al.

**Teknik durum (19 Eylül 2026, Claude):** Bildirilen hata düzeltildi. `romantikIliskide` / `romantikBitti` izleri artık **yalnızca** `Romance.start` ve `Romance.end` içinde yönetiliyor; olay seçeneği ile kişi detayındaki `Ayrıl` düğmesi aynı kod yolundan geçtiği için iki yol aynı durumu üretiyor. İki yolu da kapsayan regresyon testleri eklendi (`app/test/romance_test.dart` → "İki ayrılık yolu aynı hikâye durumunu üretir"). **Tasarım sorusu (eski sevgiliyle hangi etkileşimler açık kalacak) hâlâ karar bekliyor**; etkileşimler kapalı tutulmaya devam ediyor.

### Q-004 — Romantik eşleşme, yaş uygunluğu ve kişi sürekliliği
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/interaction/romance.dart`, `app/lib/data/event_pool.dart`.

**Mevcut kesin kural:** Uygun kişiyle romantik ilişki başlatılabilir, ayrılınca eski sevgili olarak kalır. İlişki için seçilecek kişi, yönelim/eşleşme modeli, yaş aralıkları kararlaştırılmadı.

**Karar sorusu:** İlk prototipte partnerin cinsiyeti, uygun yaş ve tanışılan kişinin **ilk tanışmadan itibaren aynı kimlikle** kaydı nasıl yönetilsin? Kod şu an partneri yalnızca teklif kabul edilince oluşturuyor; durakta tanışılan kişinin kalıcı kaydı baştan yok. Bu genişleyen hikâye hafızası için geliştirme ihtiyacıdır. Henüz karşıt cinsiyeti veya mevcut yaş sınırlarını nihai ürün kuralı diye yazma.

### Q-005 — Yaş alınca uygun olay havuzu boş olduğunda
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/generation/life_progression.dart`, `app/lib/domain/events/event_engine.dart`.

**Mevcut kesin kural:** Yeni yaşa geçince ilk olarak **tek uygun olay** sunulması hedeflenir; kod uygun olay bulunamazsa `null` ile hiç olay göstermiyor. Prototipte özellikle çok erken yaşlarda geçerli aday eksik olabilir.

**Karar sorusu:** Havuz boşken genel ama yaşa uygun bir olay hazırlanmalı mı, yoksa yaş alma günlüğü ile geçiş geçici olarak kabul mü edilsin? İlk seçenek için özgün içerik gerekli; gizlice uygunsuz olay üretme.

**Ölçüm (19 Eylül 2026, Claude — 200 hayat × 30 yaş):** Olaysız yaşlar **yalnızca 1-4 yaş aralığında** oluşuyor ve bu aralıkta **%100** olaysız. 5-30 yaş aralığında ölçülen olaysız yaş oranı **%0**. Genel oran %13 (800/6000) ve tamamı 1-4 yaşından geliyor; sebebi havuzdaki en düşük olay yaşının 5 olması. Yaş alma her durumda hayat günlüğüne yazılıyor, yani oyuncu olaysız yılda da ilerlemeyi görüyor (`app/test/event_engine_test.dart` → "Uygun olay bulunamayan yaşlar"). Bu ölçümdür, çözüm önerisi değildir.

### Q-006 — Kayıt ve cihazda doğrulama
**Durum:** Karar bekliyor. **Kaynak:** [PR #1](https://github.com/fahrettinkoksal/bir--m-r/pull/1), `app/README.md`.

**Mevcut durum:** Claude PR açıklamasında `flutter analyze` ve `flutter test` sonucu bildirmiş; **Android APK/cihaz testi yapılmamış**, oyun durumu yalnızca bellekte. Kullanıcının beğenmediği arayüzün gerçek cihaz görüntüsü elimizde doğrulanmış değil.

**Karar sorusu:** Görsel revizyonu netleştirirken önce Android emülatörü/cihaz görüntüleri ve cihazda gezinme kontrolü mü istenecek? Kalıcı oyun kaydı ilk testte mi yoksa sonraki aşamada mı yapılacak? Bunlar henüz onaylanmadı.

## Açık sorular — Aşama 1-4 kodundan çıkan geçici parametreler (19 Eylül 2026, Claude)

Aşağıdaki maddeler PR #1 kodunda `prototypeOnly` yorumuyla işaretlenmiş, **yalnızca demo için** seçilmiş değerlerdir. Hiçbiri onaylı oyun kuralı değildir ve `DECISIONS.md` içine yazılmamıştır.

### Q-007 — Tekrar eden aile etkinliğinde azalma eğrisi, ret olasılığı ve ret cezası
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/interaction/family_interactions.dart` (`prototypeOnlyRewardCurve`, `prototypeOnlyRefusalChance`, `prototypeOnlyRefusalPenaltyChance`).

**Mevcut kesin kural:** Aynı yaşta aynı kişiyle aynı etkinliğin olumlu getirisi tekrarlarla azalır ve o yaş için **sıfır ek faydaya** iner (D-019, D-026). Yakın tekrarda kişi **bazen** doğal gerekçeyle reddedebilir; ret hâlinde mutluluk **biraz azalabilir**, her ret zorunlu ceza değildir (D-020). **Kaç tekrarda sıfıra ineceği, ret olasılığı ve kayıp miktarı onaylanmadı.**

**Kodun şu anki geçici değerleri:** getiri çarpanı 1.0 → 0.55 → 0.25 → 0.0 (dördüncü tekrarda sıfır); ret olasılığı 0 → %30 → %45 → %55; ret gerçekleşince %50 ihtimalle 1-2 mutluluk kaybı.

**Karar sorusu:** Azalma kaç tekrarda ve hangi eğriyle sıfıra insin? Ret olasılığı kişi/ilişki/yaş durumuna göre değişmeli mi? Ret cezası sabit mi, koşullu mu, hiç olmasın mı?

**Seçenekler (öneri, onay değil):** (A) mevcut üç kademeli eğri; (B) daha uzun ve yumuşak eğri (ör. beş-altı tekrar); (C) eğriyi etkinlik türüne göre farklılaştırmak; (D) reddi olasılığa değil, son etkileşimden bu yana geçen oyun içi ilerlemeye bağlamak.

**Claude'un önerisi (yalnızca öneri):** (D) ile (A)'nın birleşimi; ret, rastgele olasılık yerine "çok yakın zamanda görüştünüz" ölçüsünden türerse oyuncuya daha adil ve açıklanabilir gelir.

**Varsayılan işlem:** Onay gelene dek mevcut değerler `prototypeOnly` kalır; `DECISIONS.md` değiştirilmez.

### Q-008 — Aile etkileşim türleri ve etkileşimlerin açıldığı asgari yaş
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/models/interaction.dart`, `app/lib/domain/interaction/family_interactions.dart` (`prototypeOnlyMinPlayerAge = 4`).

**Mevcut kesin kural:** Oyuncu aile bireylerine **hediye verebilir, onlarla vakit geçirebilir** ve koşullara uygun başka etkileşimler yapabilir (D-016). Etkileşimin hangi yaşta açılacağı ve tam liste onaylanmadı.

**Kodun şu anki geçici durumu:** İki tür var — **Vakit Geçir** ve **Sohbet Et**. "Sohbet Et" türünü Claude ekledi; gerekçesi, bir etkinliğin aynı yaştaki faydası bitince **diğer etkinliklerin kilitlenmediğini** gösterebilmekti. **Hediye verme yok**, çünkü ekonomi/para sistemi henüz tasarlanmadı. Etkileşimler 4 yaşından itibaren açılıyor.

**Karar sorusu:** İlk sürümde hangi etkileşim türleri olacak? "Sohbet Et" kalıcı bir tür mü, yoksa "Vakit Geçir" içinde eriyecek mi? Etkileşimler hangi yaştan itibaren açılmalı? Hediye verme, ekonomi sistemi tasarlanana kadar bekleyecek mi?

**Claude'un önerisi (yalnızca öneri):** Tür sayısını az tutup her türe ayrı sayaç vermek; hediyeyi ekonomiye bağlamak. Asgari yaş için tek sabit sayı yerine "kişiye ve etkinliğe göre uygunluk" daha doğru olabilir.

**Varsayılan işlem:** Yeni etkileşim türü eklemeden önce onay al; mevcut ikisi `prototypeOnly` kalır.

### Q-009 — Tekrar sayaçlarının yaş değişiminde yenilenmesi
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/generation/life_progression.dart`, `docs/CORE_LOOP.md` (açık konu olarak zaten kayıtlı).

**Mevcut kesin kural:** Yaş değiştiğinde aynı etkinliğin yeniden anlamlı fayda verebilmesi hedeflenir; **tam mı kısmi mi yenileneceği ve geçmişin ne kadar taşınacağı belirlenmedi.**

**Kodun şu anki geçici durumu:** Yaş alınca tekrar sayaçları **tamamen** sıfırlanıyor.

**Karar sorusu:** Yenileme tam mı olsun, kısmi mi (ör. sayacın bir kademe geri gelmesi)? İlişki düzeyi yüksek kişilerde farklı davranmalı mı?

**Varsayılan işlem:** Tam yenileme `prototypeOnly` kalır.

### Q-010 — Olay veri şeması ve olay ağırlıkları
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/models/game_event.dart`, `app/lib/data/event_pool.dart`.

**Mevcut kesin kural:** Her olayın kimliği, özgün metni, yaş uygunluğu, gerekli koşulları, seçenekleri, etkileri ve geleceğe bırakacağı iz bulunmalı (`SYSTEMS.md`). **Kesin dosya biçimi ve şema onaylanmadı.**

**Kodun şu anki geçici şeması:** `GameEvent { id, category, text, choices, requirement, repeatable, weight }`; `EventRequirement { minAge, maxAge, livingRelations, requireSameHousehold, requiredFlags, forbiddenFlags, requiredPossessions, requiresSchoolStudent, requiresNeglectedRelative }`; `EventChoice { id, label, resultText, stat etkileri, bond, addFlags, removeFlags, addPossessions, startsRomance, endsRomance }`. Olaylar Dart sabiti olarak kodda duruyor.

**Karar sorusu:** Bu alan kümesi yeterli mi, eksik ne var (ör. olayın parası/maliyeti, birden çok kişi, sonuç dallanması)? Olay havuzu kodda mı kalsın yoksa JSON/veri dosyasına mı taşınsın (içerik büyüyünce düzenlemesi kolay olur)? Ağırlık sistemi kalsın mı?

**Claude'un önerisi (yalnızca öneri):** Havuz birkaç yüz olayı geçecekse veri dosyasına taşımak; ağırlık yerine kategori bazlı seyreltme kullanmak.

**Varsayılan işlem:** Şema `prototypeOnly` kabul edilir; büyük içerik üretimine karar gelmeden başlanmaz.

### Q-011 — Aile ekranında bölümleme ve kişi kartında gösterilecek alanlar
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/ui/screens/family_screen.dart`, `app/lib/domain/models/relation.dart`; `docs/PROTOTYPE_UI.md` §4 (zaten açık soru), `docs/FAMILY_SYSTEM.md` §5.

**Mevcut kesin kural:** Aile sekmesinde kişiler görünür; anne/babanın yaşı, mesleği ve kendine ait ekonomik durumu görünür (D-015). Diğer akrabalarda hangi alanların görüneceği ve romantik kişilerin nasıl bölümleneceği **kararlaştırılmadı**.

**Kodun şu anki geçici durumu:** Üç bölüm — **Çekirdek aile / Geniş aile / İlişkiler**; her kartta ad, bağ etiketi, yaş ve ayrı bir "Aynı evde" rozeti; kişi detayında yaş, cinsiyet, durum/meslek, kendi maddi durumu, hane ve yakınlık çubuğu.

**Karar sorusu:** Bölümleme böyle mi kalsın? Eski partnerler ayrı bir bölümde mi görünsün? Geniş aile ve romantik kişilerde hangi alanlar gösterilsin, hangileri gizlensin? Yakınlık sayısal çubuk olarak gösterilsin mi, yoksa sözel mi olsun?

**Not:** Bu soru Q-001'in görsel yön kararıyla birlikte ele alınmalı; burada sorulan **bilgi mimarisi**, orada sorulan görsel dildir.

**Varsayılan işlem:** Mevcut bölümleme geçici; görsel revizyon kararı gelmeden değiştirilmez.

### Q-012 — Aile siteminin derinliği ve tetikleme ölçüsü
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/events/event_engine.dart` (`prototypeOnlyNeglectAgeGap = 3`), `app/lib/data/event_pool.dart` (`aile_sitemi`).

**Mevcut kesin kural:** Oyuncu uzun süre bir aile bireyiyle anlamlı temas kurmazsa, o kişi **bazen** sitem eden bir olay başlatabilir; süre gerçek dakika değil oyun içi ilerlemeyle ölçülür. **Her akrabanın otomatik sitem etmesi veya zorunlu puan cezası kararlaştırılmadı** (D-025).

**Kodun şu anki geçici durumu:** Yalnızca **aynı hanede** yaşayan, hayattaki ve son **3 yaş** içinde temas kurulmamış kişi sitem edebiliyor. Kişinin kendi ruh hâli, ilişki düzeyi veya olay geçmişi hesaba katılmıyor; tek kademe sitem var.

**Karar sorusu:** Sitem yalnızca hane üyeleriyle mi sınırlı kalsın? Eşik kaç yaş olsun ve ilişki düzeyine göre değişsin mi? Birden çok kademe (hafif sitem → kırgınlık) olsun mu? Sitem reddedilirse ilişkiye etkisi ne olmalı?

**Varsayılan işlem:** Mevcut tek kademeli, hane sınırlı sürüm `prototypeOnly` kalır; sistem tamamlanmış sayılmaz.

### Q-013 — "Lise sonrası" hikâye izi ile eğitim/kariyer sisteminin ilişkisi
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/data/event_pool.dart` (`lise_sonrasi`, `universite_ilk_hafta`, `ilk_maas`, `StoryFlags.universitede`, `StoryFlags.calismaHayati`).

**Mevcut kesin kural:** Eğitim, iş ve kariyer sistemleri henüz tasarlanmadı (`BACKLOG.md`). Olayların gerçek koşullara uygun olması gerekir (D-009).

**Kodun şu anki geçici durumu:** 18 yaşında çıkan `lise_sonrasi` olayı "üniversiteye devam et" veya "çalışmaya başla" seçeneği sunuyor ve yalnızca bir **hikâye izi** bırakıyor. Bu iz, "öğrenci olmayan karaktere üniversite olayı çıkmaz" kuralının gerçekten çalıştığını göstermek için var. Arkasında not, sınav, bölüm, maaş veya kariyer modeli **yok**.

**Karar sorusu:** Bu iz, eğitim/kariyer sistemi tasarlanana kadar kalsın mı, kaldırılsın mı? Kalacaksa eğitim sistemi geldiğinde bu izin yerini ne alacak? Oyuncuya, arkasında sistem olmayan bir seçim sunmak kabul edilebilir mi?

**Claude'un önerisi (yalnızca öneri):** İz kalsın ama içerik üretimi eğitim sistemi kararlaşana kadar genişletilmesin.

**Varsayılan işlem:** Mevcut üç olay `prototypeOnly` kabul edilir; eğitim/kariyer sistemi Claude tarafından tasarlanmaz.

## Açık sorular — Okul paketi (19 Eylül 2026, Claude)

Kaynak: `claude/okul-sistemi-v1` dalı (temel okul sistemi + küçük okul olay paketi). GEN-001'deki "küçük, oynanabilir paket" yaklaşımına göre yazıldı. Aşağıdakiler **karar bekliyor**; koddaki değerler `prototypeOnly`.

### Q-014 — Okula başlama yaşı, kademe akışı ve okuldan ayrılma
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/models/education.dart`, `app/lib/domain/generation/life_progression.dart` (`prototypeOnlySchoolStartAge = 6`, `lastGrade = 12`).

**Mevcut kesin kural:** Eğitim sistemi henüz tasarlanmadı (`BACKLOG.md`). Olaylar gerçek duruma uygun olmalı (D-009); öğrencilik artık yaştan türetilmiyor, oyun verisinde tutuluyor.

**Kodun şu anki geçici akışı:** 6 yaşında 1. sınıfa otomatik kayıt; her yaş bir sınıf; 4+4+4 kademeleri (ilkokul 1-4, ortaokul 5-8, lise 9-12); 12. sınıftan sonra okul biter ve öğrencilik sona erer. **Sınav, not, diploma, sınıf tekrarı, okulu bırakma ve okula hiç başlamama yok.**

**Karar sorusu:** Okula başlama yaşı sabit 6 mı kalsın, yoksa aile koşullarına göre değişebilsin mi (geç başlama, hiç başlamama)? Sınıf tekrarı ve okulu bırakma ilk sürümde olacak mı? Okulun bitişi otomatik mi olsun, yoksa bir olayla mı verilsin?

**Seçenekler (öneri, onay değil):** (A) mevcut otomatik akış; (B) başlama ve bitişin olayla verilmesi; (C) aile ekonomisine/olaylara bağlı olarak okulu bırakabilme.

**Claude'un önerisi (yalnızca öneri):** Şimdilik (A) kalsın; okulu bırakma, ekonomi ve aile olayları tasarlanınca (C) ile eklensin.

**Varsayılan işlem:** Mevcut akış `prototypeOnly`; sınav/not/diploma yazılmayacak.

### Q-015 — Arkadaşlar arayüzde nerede görünsün?
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/models/relation.dart` (`RelationGroup.arkadaslar`), `app/lib/ui/screens/family_screen.dart`. **Bağlantılı:** Q-011, `docs/PROTOTYPE_UI.md` §4 (açık soru).

**Mevcut kesin kural:** İlk prototip alt menüsü Hayat / Aile / Ben; Aile bölümünde aile bireyleri ve ilişkiler görünür (D-028, D-015). Arkadaşların nerede görüneceği **kararlaştırılmadı**.

**Kodun şu anki geçici durumu:** Okulda tanışılan arkadaş, Aile sekmesinde **"Arkadaşlar"** başlığı altında ayrı bir grupta listeleniyor ("akraba değildir" açıklamasıyla). Yeni sekme açılmadı, görsel düzen değiştirilmedi.

**Karar sorusu:** Arkadaşlar Aile sekmesinde mi kalsın, ileride eklenecek **Sosyal** sekmesine mi taşınsın, yoksa ayrı bir "Kişiler" bölümü mü olsun? Sekme adı "Aile" kalırsa arkadaşların orada durması kabul edilebilir mi?

**Varsayılan işlem:** Mevcut yerleşim geçici; Q-001 görsel revizyon kararıyla birlikte ele alınmalı.

### Q-016 — Arkadaşlarla etkileşimler aile kurallarına mı tabi olsun?
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/interaction/family_interactions.dart`.

**Mevcut kesin kural:** Aile bireyleriyle vakit geçirme/hediye ve tekrar dengesi kuralları onaylı (D-016, D-019, D-020, D-026). Arkadaşlar için ayrı bir kural **kararlaştırılmadı**.

**Kodun şu anki geçici durumu:** Etkileşim motoru kişi türüne bakmıyor; arkadaş da hayattaki diğer kişiler gibi **Vakit Geçir / Sohbet Et** için uygun. Yani azalan etki, doğal ret ve kişi bazlı sayaçlar arkadaşlara da aynen uygulanıyor. Bu, GEN-001'deki ortak altyapı yaklaşımının sonucudur, ayrı bir onay değildir.

**Karar sorusu:** Arkadaşlarla etkileşimler aileyle aynı kurallara mı tabi olsun? Arkadaşa özel eylemler (ör. birlikte ders çalışma, dışarı çıkma) olacak mı? Arkadaşın reddetme gerekçeleri aileyle aynı metinlerden mi gelsin (şu anda öyle)?

**Varsayılan işlem:** Arkadaşa özel yeni eylem eklenmeyecek; mevcut ortak davranış `prototypeOnly`.

### Q-017 — Arkadaşlığın derinliği: kaç arkadaş, nasıl zayıflar, olumsuz seçimlerin devamı
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/interaction/friendship.dart`, `app/lib/data/event_pool.dart` (okul paketi).

**Mevcut kesin kural:** Arkadaşlarla bağlar ayrı takip edilecek ve kararlardan etkilenecek (D-007, D-008). Arkadaş sayısı, arkadaşlığın bitmesi ve içerik derinliği **kararlaştırılmadı**.

**Kodun şu anki geçici durumu:** Okulda **tek** arkadaş edinilebiliyor (tanışma olayı bir kez çıkıyor). Arkadaşlığın bitmesi/uzaklaşması yok; kişi hayat boyu "Arkadaş" statüsünde kalıyor. Arkadaşın cinsiyeti rastgele (romantik eşleşmedeki karşıt cinsiyet varsayımı burada geçerli değil). Ayrıca **"yardım etmedim" dalının devamı yok**: yardım eden oyuncu ileride `yardimin_karsiligi` olayını görüyor, etmeyen oyuncu için karşılık gelen olumsuz devam olayı henüz yazılmadı.

**Karar sorusu:** Oyuncu kaç arkadaş edinebilsin ve yeni arkadaşlar hangi kaynaklardan gelsin (okul, mahalle, iş)? Arkadaşlık zamanla zayıflasın mı, "eski arkadaş" gibi bir statü olsun mu? Olumsuz seçimlerin de kendi devam olayları yazılsın mı, yoksa olumsuz seçim "devam açmamak" olarak mı kalsın?

**Claude'un önerisi (yalnızca öneri):** Olumsuz seçimlere de en az bir devam yazmak hikâyeyi daha adil hissettirir; ancak bu içerik hacmini artırır, GEN-001'e göre sonraki pakete bırakılabilir.

**Varsayılan işlem:** Tek arkadaş, statü değişimi yok; yeni içerik onay gelmeden genişletilmeyecek.

## Açık sorular — Menü ve arayüz revizyonu (19 Eylül 2026, Claude)

Kaynak: `claude/arayuz-revizyonu-v1` dalı. NAV-001'in **karara bağladığı** noktalar (dört menü, yatay sıra, `Yaş Al`ın ortada bağımsız eylem olması, anne-babanın İlişkiler'de en üstte durması) burada yeniden sorulmuyor; aşağıdakiler o kararın **açık bıraktığı** ayrıntılardır.

### Q-018 — Ana ekrana dönüş davranışı ve üst özetin içeriği
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/ui/screens/home_shell.dart`, `app/lib/ui/widgets/character_header.dart`.

**Mevcut kesin kural:** Dört ana menü ve ortadaki `Yaş Al` onaylandı (NAV-001). Ana hayat ekranına nasıl dönüleceği ve üst özette **tam olarak** nelerin duracağı kararlaştırılmadı ("üst karakter özeti ve bakiye görünümü referanstır, tam konum/stil henüz kararlaştırılmadı").

**Kodun şu anki geçici çözümü:** Hayat günlüğü "ana ekran"dır; bir menü seçilince onun ekranı açılır. Geri dönüş iki yoldan olur: seçili menüye **tekrar dokunmak** veya ekranın üstündeki "‹ Hayat" satırı. Üst özette ad, yaş + evre + şehir, "evde kaç kişi yaşıyor" satırı, cüzdan ve beş değerin kısa etiketli şeridi var; şeride dokununca tam adlarıyla ayrıntı açılıyor.

**Karar sorusu:** Hayat ekranı beşinci bir menü mü olsun, yoksa mevcut "tekrar dokun / geri satırı" yaklaşımı mı kalsın? Üst özette hangi bilgiler kalıcı olsun (evre? hane satırı? ün açıldığında nereye girecek)? Değerler üstte şerit olarak mı kalsın, yoksa ayrı bir ekrana mı taşınsın?

**Varsayılan işlem:** Mevcut çözüm geçici; Q-001 ile birlikte değerlendirilmeli.

### Q-019 — Romantik alt menünün adı ve kardeşlerin yeri
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/ui/screens/sections/relationships_screen.dart`. **Bağlantılı:** NAV-001 ("Sevgili/eski sevgilinin tam alt menü adı ve konumu ayrıca netleşecek"), Q-011, Q-015.

**Mevcut kesin kural:** İlişkiler ana ekranında anne ve baba en üstte; `Akrabalar` ve `Arkadaşlar` alt menüleri onaylandı. Romantik bağların alt menü adı ve konumu **açık**.

**Kodun şu anki geçici çözümü:** Üçüncü bir alt menü **"Romantik bağlar"** adıyla eklendi (sevgili ve eski sevgili birlikte). **Kardeşler ayrı bir alt menü değil**, `Akrabalar` içinde listeleniyor.

**Karar sorusu:** Romantik alt menünün adı ne olsun? Sevgili ve eski sevgili aynı listede mi dursun? Kardeşler `Akrabalar` içinde mi kalsın, yoksa kendi alt menüsü mü olsun?

**Varsayılan işlem:** Mevcut adlandırma geçici.

### Q-020 — Okul/Meslek menüsünün okul öncesi ve okul sonrası içeriği
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/ui/screens/sections/school_career_screen.dart`. **Bağlantılı:** NAV-001 ("işsiz/okula başlamamış/okulu bitirmiş karakterde ... tam UX kararı açık").

**Kodun şu anki geçici çözümü:** Öğrenciyken **Okul** (kademe paneli + okul arkadaşları + bilgi notu). Öğrenci değilken **Meslek**: okul öncesi çocukta "Okul öncesi" paneli ve "okul çağına gelince burada okul bilgileri görünecek" notu; okulu bitirmişte eğitim geçmişi paneli ve "kariyer sistemi henüz yazılmadı" notu. Sahte düğme konmadı.

**Karar sorusu:** Bu durumlarda menü hiç görünmesin mi, soluk/pasif mi görünsün, yoksa mevcut dürüst panel mi kalsın? Menü adı duruma göre değişmeye devam etsin mi?

**Varsayılan işlem:** Mevcut dürüst panel yaklaşımı geçici.

### Q-021 — Cüzdan: para birimi, başlangıç bakiyesi ve para akışları
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/models/player_character.dart` (`wallet`), `app/lib/ui/screens/sections/assets_screen.dart`, `app/lib/domain/models/game_event.dart` (`EventChoice.money`). **Bağlantılı:** ECO-001.

**Mevcut kesin kural:** Oyuncunun kendi cüzdanı olacak ve aile parasından ayrı tutulacak (ECO-001). Para birimi, başlangıç bakiyesi, kazanma/harcama yolları, aileden para isteme ve eksi bakiye/borç **kararlaştırılmadı**.

**Kodun şu anki geçici çözümü:** `wallet` alanı eklendi, **0 ile başlıyor**, üst özette ve Varlıklar ekranında `₺` ile gösteriliyor. Kazanma/harcama akışı **yazılmadı**; yalnızca olay seçeneklerine `money` alanı eklendi ve mevcut `ilk_maas` olayında kullanıldı (miktarlar `prototypeOnly`). Cüzdan eksiye düşmüyor.

**Karar sorusu:** Para birimi ve gösterim biçimi ne olsun? Başlangıç bakiyesi 0 mı kalsın? Aileden para isteme ilk turda mı gelsin? Eksi bakiye/borç olacak mı?

**Varsayılan işlem:** Ekonomi bu görevde büyütülmedi; miktarlar ve kurallar onay bekliyor.

### Q-022 — Aktiviteler bölümünün kapsamı
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/ui/screens/sections/activities_screen.dart`.

**Mevcut kesin kural:** `Aktiviteler` ana menü adı ve yeri onaylandı; iç ekranları ve alt özellikleri **ayrıca netleşecek**.

**Kodun şu anki geçici çözümü:** İç içe menü kuruldu ama gerçekten çalışan **tek kategori** var: "Birlikte vakit geçir" (kişi seç → mevcut Vakit Geçir / Sohbet Et etkileşimleri). Spor salonu, berber ve seyahat için **düğme konmadı**; yalnızca tıklanamaz bir bilgi notu var.

**Karar sorusu:** Aktiviteler altında hangi kategoriler olacak ve hangi sırayla eklenecek? Aile/arkadaş etkileşimleri hem İlişkiler hem Aktiviteler altından erişilebilir kalsın mı, yoksa tek yere mi toplansın? Henüz yazılmamış kategoriler pasif olarak listelensin mi, hiç görünmesin mi?

**Varsayılan işlem:** Yeni aktivite sistemi eklenmedi; mevcut yerleşim geçici.

### Q-023 — Olay tekrar aralığı ve tekrar politikası
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/models/game_event.dart` (`minAgeGap`), `app/lib/domain/models/game_state.dart` (`lastEventAge`), `app/lib/data/event_pool.dart`. **Geri bildirim:** "Bayram sabahı olayı gereğinden sık tekrarlandı."

**Mevcut kesin kural:** Yok. Tekrar dengesi kararlaştırılmadı.

**Kodun şu anki geçici çözümü:** Tekrarlanabilir olaylar yasaklanmadı; her olayın bir **en az yaş farkı** (`minAgeGap`) var ve olayın en son çıktığı yaş kaydediliyor. Varsayılan aralık 3 yaş; bayram ziyareti 4, aile sitemi 5, kar tatili 4, sınıf fotoğrafı 5, akşam sofrası 3 (hepsi `prototypeOnly`).

**Karar sorusu:** Tekrar aralıkları yaş farkıyla mı, yoksa "hayat başına en fazla N kez" gibi bir kotayla mı yönetilsin? Bayram gibi doğal olarak yıllık olayların tekrar sıklığı ne olmalı? Aynı olayın farklı yaşlarda farklı metinle gelmesi mi tercih edilir, yoksa tamamen farklı olaylar mı yazılsın?

**Varsayılan işlem:** Sayılar geçici; kesin tekrar dengesi onay bekliyor.

### Q-024 — Okul kişileri: sayı, kademe geçişi ve eski tanıdıkların görünümü
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/generation/school_people.dart`, `app/lib/ui/screens/sections/school_career_screen.dart`. **Bağlantılı:** EDU-001, D-029.

**Mevcut kesin kural:** Kişi kaydı silinmez (D-029). Sınıf arkadaşı olmak yakın arkadaşlık değildir (kullanıcı geri bildirimi).

**Kodun şu anki geçici çözümü:** Her kademede (ilkokul/ortaokul/lise) **4 sınıf arkadaşı + 1 öğretmen** üretiliyor (`prototypeOnly`). Kademe değişince kişiler silinmiyor; güncel sınıf listesinde görünmüyor, "Geçmiş yıllardan tanıdıkların" başlığı altında listeleniyorlar. Tanışıklık yakınlığı 15-35 arası başlıyor.

**Karar sorusu:** Bir sınıfta kaç kişi tanınsın? Kademe değişince sınıfın tamamı mı yenilensin, bir kısmı aynı mı kalsın (gerçek hayatta çoğu arkadaş devam eder)? Kaç öğretmen olsun, branş tutulsun mu? Eski tanıdıklar okul menüsünde mi, İlişkiler altında mı, yoksa ikisinde de mi görünsün? Okul dışında (mahalle, iş) tanışılan kişiler aynı altyapıyı mı kullansın?

**Varsayılan işlem:** Sayılar ve yerleşim geçici; genişletme yapılmadı.

### Q-025 — Hediye ve para etkileşimlerinin kuralları
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/interaction/family_interactions.dart`, `app/lib/domain/models/interaction.dart`. **Bağlantılı:** ECO-001, Q-021.

**Mevcut kesin kural:** Oyuncunun cüzdanı aile parasından ayrıdır (ECO-001). Gerçekleşmeyen işlem olmuş gibi gösterilmez (kullanıcı geri bildirimi).

**Kodun şu anki geçici çözümü:** Üç yeni etkileşim eklendi: **Hediye Ver** (oyuncunun cüzdanından 50 ₺), **Hediye İste** (küçük bir eşya listesinden gerçek bir eşya), **Para İste** (karşı tarafın ekonomik basamağına göre 10-400 ₺). Hepsi `prototypeOnly`. Koşullar: istek yalnızca **18 yaş üstü** anne/baba ve geniş aile üyelerinden, yakınlık **25**'in üstündeyken yapılabiliyor; tekrar reddi normal etkileşimlerden hızlı artıyor; fayda bittiğinde para hiç harcanmıyor.

**Karar sorusu:** Hediye bedeli sabit mi olsun, hediye türüne göre mi değişsin? Harçlık miktarları ekonomiyle nasıl ölçeklenecek? Kardeşten, akrandan, sevgiliden para/hediye istenebilsin mi? İstek için yakınlık eşiği kaç olmalı? Israrla isteme yakınlığı ne kadar düşürsün? Hediye seçimi oyuncuya mı bırakılsın (mağaza), yoksa otomatik mi kalsın?

**Varsayılan işlem:** Kapsamlı mağaza ve hediye kataloğu yazılmadı; sayılar onay bekliyor.

### Q-026 — Etki rozetlerinde ne gösterilecek, ne gizlenecek
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/effects/effect_diff.dart`, `app/lib/ui/widgets/effect_chips.dart`. **Geri bildirim:** "Seçimin ardından gerçekten uygulanan değişiklikler görünsün."

**Kodun şu anki geçici çözümü:** Karakter değerleri, cüzdan, kişi bazında yakınlık, hayata giren kişiler ve kazanılan/kaybedilen eşyalar rozet olarak gösteriliyor. Etkiler niyetten değil, durum farkından okunuyor; uygulanmayan kazanç yazılmıyor.

**Karar sorusu:** Her etki açıkça sayıyla mı gösterilsin, bazıları ("bir şeyler değişti" gibi) gizli mi kalsın? Yakınlık değişimi sayı olarak mı, yoksa çubuk/ifade olarak mı verilsin? Uzun vadeli etkiler (hikâye izleri) oyuncuya bildirilsin mi?

**Varsayılan işlem:** Tam şeffaf gösterim geçici.

### Q-027 — Zorbalık olaylarında kavga seçeneği ve şiddetin sonuçları
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/data/event_pool.dart` (`arkadasi_savunma`). **Geri bildirim:** kullanıcı isteği.

**Kodun şu anki geçici çözümü:** Yok. Yalnızca "savun" ve "sessiz kal" seçenekleri var; fiziksel kavga seçeneği **yazılmadı**.

**Karar sorusu:** Zorbalık olaylarına koşullu bir kavga seçeneği eklensin mi? Hangi koşullarda görünsün (yaş, sağlık, karakter değerleri, geçmiş seçimler)? Şiddet derecesine göre sağlık, görünüm, ilişki ve okul disiplini sonuçları nasıl ölçeklensin? Her zorbalık olayı zorunlu kavgaya dönüşmemeli; kavga oranı ne olmalı? Yaş sınırı ve içerik tonu ne olacak?

**Varsayılan işlem:** Eklenmedi; onay bekleniyor.

### Q-028 — Eşya etkileşimi: kullanma, giyme, yıpranma, bakım
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/data/possession_names.dart`, `app/lib/ui/screens/sections/assets_screen.dart`. **Geri bildirim:** kullanıcı isteği.

**Kodun şu anki geçici çözümü:** Eşyalar yalnızca bir kimlik kümesi (`possessions`); durumu, yaşı, bakımı yok. Varlıklar ekranı listeliyor, etkileşim sunmuyor.

**Karar sorusu:** Eşyalar kullanılabilir/giyilebilir olsun mu? Yıpranma ve temizlik/bakım takip edilsin mi? Bakım maliyeti ve gerçek etkisi ne olsun (bakımsız bisiklet bozulur, bakımsız kıyafet görünümü düşürür gibi)? Eşya durumu sayıyla mı, ifadeyle mi gösterilsin?

**Varsayılan işlem:** Eşya sistemi büyütülmedi.

### Q-029 — Satın alma, ehliyet, araç ve gayrimenkul altyapısı
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/ui/screens/sections/assets_screen.dart`, `app/lib/ui/screens/sections/activities_screen.dart`. **Bağlantılı:** ECO-001, Q-021, Q-022. **Geri bildirim:** kullanıcı isteği.

**Kodun şu anki geçici çözümü:** Yok. Satın alma, ehliyet, araç ve ev sistemi **yazılmadı**; sahte düğme konmadı.

**Karar sorusu:** Satın alma Varlıklar altından mı yapılsın? Ehliyet Aktiviteler altından hangi yaş ve koşullarda alınsın (sınav, ücret, zekâ)? Araç kullanma koşulları neler (ehliyet, araç sahipliği, yakıt/bakım)? Ev ve emlakçı altyapısı kiralama mı, satın alma mı, ikisi mi olsun? Bu paketler hangi sırayla yazılsın?

**Varsayılan işlem:** Eklenmedi; ekonomi kararları beklemede.

### Q-030 — Kademe geçişleri, lise türü/alan seçimi ve sınav sistemi
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/generation/life_progression.dart`, `app/lib/domain/models/education.dart`. **Bağlantılı:** EDU-001. **Geri bildirim:** kullanıcı isteği.

**Kodun şu anki geçici çözümü:** 4+4+4 yapısı var ama geçişler **otomatik**: her yaş bir sınıf ilerler, kademe kendiliğinden değişir. Sınav, not, tercih ve diploma **yok**.

**Karar sorusu:** 4. sınıf sonrası ortaokula geçiş bir olay olarak mı sunulsun? 8. sınıf sonrası lise türü/alan seçimi hangi seçenekleri içersin (düz, fen, meslek, imam hatip, sanat vb.)? Seçim sınav puanına mı bağlı olsun, oyuncunun tercihine mi? Sınav ve puanlama ne zaman eklensin? Sınıfta kalma olacak mı?

**Varsayılan işlem:** Sınav ve tercih sistemi yazılmadı.

### Q-031 — Lise sonrası iş arama, meslekler ve maaş akışı
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/ui/screens/sections/school_career_screen.dart` (Meslek görünümü), `app/lib/data/event_pool.dart` (`lise_sonrasi`, `ilk_maas`). **Bağlantılı:** ECO-001, Q-021. **Geri bildirim:** kullanıcı isteği.

**Kodun şu anki geçici çözümü:** Yok. `lise_sonrasi` olayı yalnızca hikâye izi bırakıyor (`universitede` / `calisma_hayati`); gerçek bir meslek kaydı, iş arama ekranı ve düzenli maaş **yok**. `ilk_maas` olayı cüzdana tek seferlik `prototypeOnly` miktar ekliyor.

**Karar sorusu:** İş arama nasıl çalışsın (ilan listesi, başvuru, mülakat)? Meslek seçeneklerini hangi koşullar belirlesin (eğitim düzeyi, alan, zekâ, karizma, geçmiş seçimler, referans olan kişiler)? Maaş cüzdana nasıl girsin — her yaş alışta toplu mu, olay olarak mı? Terfi, işten çıkarılma ve iş değiştirme ilk turda olsun mu?

**Varsayılan işlem:** Kariyer sistemi yazılmadı.

### Q-032 — Romantik ilişkinin tam akışı
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/interaction/romance.dart`, `app/lib/data/event_pool.dart` (romantik zincir). **Bağlantılı:** D-030, Q-019. **Geri bildirim:** kullanıcı isteği.

**Mevcut kesin kural:** Ayrılıkta kişi silinmez, aynı kimlikle eski sevgili olur (D-029, D-030).

**Kodun şu anki geçici çözümü:** Yalnızca dört adımlı küçük bir zincir var: durakta tanışma → çıkma teklifi → tartışma → ayrılık, artı eski sevgiliyle karşılaşma. Sevgiliye özel etkileşim yok; eski sevgiliyle etkileşimler kapalı.

**Karar sorusu:** Tanışma yolları neler olsun (okul, iş, mahalle, tanıştırma, ileride sosyal medya)? Yakınlaşma aşamaları nasıl ölçülsün? Teklif kabul/ret koşulları neye bağlı olsun? İlişki içinde hangi etkileşimler açılsın (buluşma, hediye, tanıştırma, tartışma)? Ayrılık sonrası hangi etkileşimler açık kalsın, barışma olsun mu? Evlilik ve çocuk bu turun kapsamında mı? **Not:** Kullanıcı isteği doğrultusunda tüm romantik özellikler tek seferde yazılmayacak; sıralama kararı gerekiyor.

**Varsayılan işlem:** Romantik sistem bu pakette büyütülmedi.

### Q-033 — Kayıt/yükleme (oyunu kapatınca aynı hayata devam) — ÖNCELİK SORUSU
**Durum:** **Uygulandı** (Faho'nun açık talimatıyla; öncelik sorusu yanıtlandı, sıradaki paket olarak yazıldı). Kalan açık sorular **Q-035**'e taşındı. **Kaynak:** `app/lib/state/game_controller.dart`, `app/lib/domain/models/game_state.dart`. **Geri bildirim:** kullanıcı isteği; **önceliğin ayrıca bildirilmesi istendi.**

**Kodun şu anki geçici çözümü:** **Yok.** Oyun tamamen bellekte çalışıyor; uygulama kapanınca hayat kayboluyor. Kayıt/yükleme **hiç yazılmadı**.

**Claude'un önerisi (onay bekliyor):** Bu konunun **yüksek öncelikli** olduğunu düşünüyorum. Gerekçe: (1) Test eden kişi oyunu kapatınca her şeyi kaybediyor, bu yüzden uzun bir hayat hiç oynanamıyor ve denge geri bildirimi alınamıyor. (2) `GameState` şu an hızla büyüyor (eğitim durumu, okul kişileri, hikâye rolleri, olay geçmişi, eşyalar, cüzdan); serileştirme ne kadar geç yazılırsa o kadar çok alan dönüştürülecek. (3) Kayıt biçimi bir **teknik** karardır, oyun tasarımını kilitlemez; bu yüzden diğer tasarım kararları beklerken paralel ilerleyebilir. Önerim: sıradaki paketlerden biri olarak, tek kayıt yuvası + JSON serileştirme ile başlanması.

**Karar sorusu:** Kayıt/yükleme sıradaki pakete mi alınsın, yoksa oyun içeriği biraz daha büyüdükten sonra mı yazılsın? Tek hayat mı saklansın, birden çok kayıt yuvası mı olsun? Bitmiş hayatlar geçmiş olarak saklansın mı? Otomatik kayıt hangi anlarda yapılsın (yaş alma, olay çözümü, uygulamadan çıkış)?

**Ne yapıldı:** Tek aktif hayat kaydı; cihazın uygulamaya ait yerel veri klasöründe JSON; biçim sürümü ve taşıma kancası; yarıda kesilmeye dayanıklı yazma (geçici dosya → yedek → tek adımda taşıma); bozuk kayıtta çökmeden uyarı ve **dosyaya dokunmama**; başlangıç ekranında **Devam Et**; yeni hayat için açık onay. Ayrıntı: `docs/SAVE_SYSTEM.md`.

**Varsayılan işlem:** Uygulanan biçim **teknik** bir çözümdür; oyun kuralı değildir ve `DECISIONS.md`'ye eklenmedi.

### Q-034 — Genel kural önerisi: her yeni kişi/eşya/ilişki/olay gerçek kayıt olmalı
**Durum:** Öneri, karar bekliyor. **Kaynak:** proje geneli. **Geri bildirim:** kullanıcı isteği ("bağlantısız sahte ekran olmasın").

**Claude'un önerisi (onay bekliyor):** Şu kuralın `DECISIONS.md` içine alınması öneriliyor: *"Oyunda gösterilen her kişi, eşya, ilişki ve olay, paylaşılan oyun durumuna (`GameState`) bağlı gerçek bir kayda dayanır. Yalnızca görüntüden ibaret, duruma bağlanmamış liste, sayaç veya düğme eklenmez; yazılmamış sistem için sahte düğme konmaz."*

**Karar sorusu:** Bu kural kesin karar olarak `DECISIONS.md` içine eklensin mi? Eklenecekse metni bu hâliyle mi kalsın?

**Varsayılan işlem:** **Kullanıcı onayı olmadan `DECISIONS.md` değiştirilmedi.** Kod bu ilkeye zaten uyuyor.

### Q-035 — Kayıt sisteminde açık kalan seçimler
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/data/save/`, `docs/SAVE_SYSTEM.md`. **Bağlantılı:** Q-033.

**Mevcut kesin kural:** Yok; kayıt biçimi teknik bir çözümdür.

**Kodun şu anki geçici çözümü:** Tek aktif hayat kaydı. Otomatik kayıt; yeni hayat, yaş alma, olay seçimi, kişi etkileşimi ve ayrılıktan sonra yapılıyor. Bitmiş hayatlar saklanmıyor. Ana ekrandan çıkmak kaydı silmiyor; yeni hayat kaydın üzerine yazıyor (onaylı).

**Karar soruları:**
1. Birden çok kayıt yuvası eklenecek mi? Eklenecekse kaç tane ve nasıl adlandırılacak?
2. Bitmiş hayatlar bir "geçmiş hayatlar" listesinde saklansın mı? Saklanacaksa ne kadarı (özet mi, tam kayıt mı)?
3. Otomatik kayıt anları yeterli mi? Uygulamadan çıkarken ayrıca kayıt istenir mi?
4. Oyuncuya elle "kaydet" düğmesi verilecek mi, yoksa kayıt tamamen görünmez mi kalsın?
5. Bozuk kayıtta oyuncuya "kaydı sil ve baştan başla" dışında bir seçenek (ör. kaydı dışa aktarıp bize gönderme) sunulsun mu?

**Claude'un önerisi (yalnızca öneri):** Tek yuva şimdilik yeterli; "geçmiş hayatlar" özelliği ancak hayatın sonu (ölüm) sistemi tasarlandıktan sonra anlamlı olur. Elle kaydet düğmesi önermiyorum; otomatik kayıt oyunun akışını bölmüyor.

**Varsayılan işlem:** Yukarıdakilerin hiçbiri eklenmedi; mevcut davranış geçici.

### Q-036 — Kayıt sonrası rastgelelik sürekliliği
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/state/game_controller.dart` (`Random`), `docs/SAVE_SYSTEM.md`.

**Kodun şu anki geçici çözümü:** Rastgele sayı üreticisinin **iç durumu kaydedilmiyor.** Kaydedilen her şey birebir geri geliyor; bekleyen olay metni, kişisi ve seçenekleriyle saklandığı için yeniden açılışta **aynı** olay geliyor. Ancak kayıttan sonra üretilecek **yeni** rastgele sonuçlar (hangi olayın çıkacağı, etkileşimin reddedilip reddedilmeyeceği), uygulama hiç kapanmasaydı çıkacak olanlarla aynı olmak zorunda değil.

**Neden şimdilik sorun değil:** Olayların uygunluğu, sonuçları ve hikâye bağlantıları rastgeleliğe değil kaydedilen duruma bakıyor; bu yüzden kayıttan dönen oyunda tutarsız bir durum oluşmuyor. Etkilenen tek şey, "aynı anda kaydetmeseydim ne çıkardı" sorusunun cevabı.

**Karar sorusu:** Rastgelelik akışının birebir sürdürülmesi istenir mi? İstenirse, üreticinin durumu (tohum + çekim sayacı) da kaydedilmeli; bu, her rastgele çağrıyı sayaçtan geçirmeyi gerektirir. Yoksa mevcut davranış yeterli mi?

**Claude'un önerisi (yalnızca öneri):** Mevcut davranış yeterli. Birebir sürdürme yalnızca "kaydı yükleyip farklı sonuç almayı" engellemek (save-scumming) istenirse gerekir; bu bir oyun tasarımı kararıdır ve henüz konuşulmadı.

**Varsayılan işlem:** Rastgelelik durumu kaydedilmiyor; sınır `docs/SAVE_SYSTEM.md` içinde açıkça yazılı.

### Q-037 — Kişiye uygun etkileşim tablosu
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/interaction/interaction_policy.dart`. **Geri bildirim:** "Okul arkadaşında kilitli Para İste görmek istemiyorum."

**Kodun şu anki geçici çözümü:** Hangi ilişkide hangi etkileşimin anlamlı olduğu tek tabloda tutuluyor ve uygun olmayan tür **hiç gösterilmiyor**. Şu an: anne/baba/geniş aile → Vakit Geçir, Sohbet Et, Hediye Ver, Hediye İste, Para İste. Kardeş → para isteme hariç hepsi. Sınıf arkadaşı → Vakit Geçir, Sohbet Et, Hediye Ver. Öğretmen → Sohbet Et, Hediye Ver. Arkadaş/sevgili → Vakit Geçir, Sohbet Et, Hediye Ver. Eski sevgili → hiçbiri.

**Karar soruları:** Öğretmenle "Vakit Geçir" gerçekten kapalı mı kalsın? Kardeşten para istemek açılsın mı? Sevgiliye özel etkileşimler (buluşma, tanıştırma) ne zaman eklensin? Eski sevgiliyle hangi etkileşimler açılsın (Q-019 ile bağlantılı)? Aile dışından para istemek yalnızca özel bir olayla mı mümkün olsun?

**Varsayılan işlem:** Tablo `prototypeOnly`'dir; onaylanmadan kalıcı kural sayılmaz.

### Q-038 — Sınıf mevcudu, taşınma oranı ve öğretmen sayısı
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/generation/school_people.dart`. **Bağlantılı:** Q-024.

**Kodun şu anki geçici çözümü:** Oyuncu hariç **10** sınıf arkadaşı, **1** öğretmen; kademe geçişinde sınıfın **%40'ı** aynı kimlikle yeni sınıfa taşınıyor, kalanı eski sınıfta kayıtlı kalıyor. Hepsi `prototypeOnly` ve tek yerden ayarlanabilir.

**Karar soruları:** Gerçek sınıf mevcudu kaç olsun (20-30 kişiyi arayüzde göstermek anlamlı mı)? Taşınma oranı ne olmalı? Bir kademede kaç öğretmen tanınsın, branş tutulsun mu? Aynı kademede okul/sınıf değişimi (taşınma, nakil) ne zaman eklensin? Sınıf arkadaşlarının bir kısmı hiç tanınmadan kalabilir mi (tanışılmamış sınıf arkadaşı)?

**Varsayılan işlem:** Sayılar geçici.

### Q-039 — Hediye kataloğu, fiyatlar ve hediye seçimi
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/data/gift_catalog.dart`. **Bağlantılı:** Q-025.

**Kodun şu anki geçici çözümü:** Yaş aralığı, yaklaşık değer (₺) ve verenin en az ekonomik düzeyi olan **20 civarı** eşyadan oluşan küçük bir katalog. Hediye; alanın yaşı, verenin ekonomik durumu ve halihazırda sahip olunan eşyalar elendikten sonra rastgele seçiliyor. Cinsiyete göre **yasak yok**. Verilen hediyenin bedeli oyuncunun cüzdanından düşüyor; alınan hediye envantere giriyor. `GiftRecord` ile kim/kime/ne/kaç yaşında kaydediliyor.

**Karar soruları:** Fiyatlar hangi ölçeğe oturacak (Q-021 ile birlikte)? Hediye seçimi oyuncuya bırakılsın mı (mağaza), yoksa otomatik mi kalsın? Kişinin "ilgi alanları" verisi eklenip hediye tercihini etkilesin mi? Aynı eşyadan birden fazla sahip olunabilsin mi? Hediye reddi oranı ne olmalı?

**Varsayılan işlem:** Katalog ve fiyatlar `prototypeOnly`.

### Q-040 — Gündelik erişilebilirlik kuralları
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/models/game_state.dart` (`isReachable`). **Geri bildirim:** "İlkokul öğretmenimle yıllar sonra her gün görüşüyormuş gibi olmasın."

**Kodun şu anki geçici çözümü:** Erişilebilir sayılanlar: aynı hanede yaşayanlar, güncel sınıf arkadaşları ve öğretmenler, yakın arkadaşlar, sevgili, ve hane dışındaki anne/baba/kardeş. Diğer herkes (eski öğretmenler, eski sınıf arkadaşları, uzak akrabalar) kayıtta kalıyor ama gündelik listeye girmiyor.

**Karar soruları:** Uzak akrabalar (teyze, amca...) gündelik listede olmalı mı, yalnızca ziyaret/bayram olaylarıyla mı gelsin? Eski tanıdıkla yeniden iletişime geçme nasıl olsun (rastlantı olayı, sosyal medya, telefon)? Yeniden iletişim kurulan kişi kalıcı olarak erişilebilir olsun mu? Taşınma ve şehir değiştirme erişilebilirliği etkilesin mi?

**Varsayılan işlem:** Mevcut koşullar geçici; hiçbir kayıt silinmiyor.

### Q-041 — PAKET 2: Eşya, kondisyon, bakım ve satış
**Durum:** **Uygulandı** (Faho'nun açık talimatıyla). Sayısal değerler ve kalan tasarım soruları **Q-045** ve **Q-046**'da. Teknik özet: `docs/ITEM_SYSTEM.md`. **Kaynak:** `app/lib/ui/screens/sections/assets_screen.dart`, `app/lib/data/gift_catalog.dart`, `app/lib/domain/models/gift_record.dart`. **Bağlantılı:** Q-028, Q-029, Q-039.

**Kodun şu anki durumu:** Eşyalar yalnızca bir kimlik kümesi (`possessions`) ve hediye geçmişi (`GiftRecord`). Kondisyon, aksesuar, bakım ve satış **yok**; Varlıklar ekranı yalnızca listeliyor.

**İstenen (Faho'nun geri bildirimi):** Ortak eşya altyapısında kimlik, tür, sahip, edinilme yolu, kondisyon, temel değer ve takılı aksesuarlar tutulsun. Eşyaya tıklayınca **türüne uygun** eylemler açılsın: bisiklette bin/temizle/bakım/zil tak/reflektör tak/sat; kol saatinde tak/parlat/bakım/sat. Bisiklet aksesuarı saate veya otomobile takılamasın. Kullanım kondisyonu düşürsün; bakım sınırlı iyileştirsin, her hasarı sıfırlamasın; bazı işlemler para veya malzeme istesin. Satış değeri tür + temel değer + kondisyon + özel nitelikten (antika vb.) hesaplansın; satılan eşya envanterden çıksın, para cüzdana girsin, günlüğe yazılsın. İleride zengin aile uygun yaşta otomobil hediye edebilsin; otomobilin sürüş/yakıt/bakım eylemleri bisikletinkiyle aynı olmasın.

**Karar soruları:** Kondisyon 0-100 sayı mı, "yeni / iyi / yıpranmış / bozuk" gibi basamaklar mı olsun? Bakım ücretleri ve iyileştirme tavanı ne olsun? Reşit olmayan oyuncunun değerli eşya satışına kural gelsin mi (aile onayı, düşük fiyat)? Aksesuarlar ayrı eşya mı, yoksa eşyanın niteliği mi olsun? Kayıt biçimi değişeceği için göç adımı gerekecek — eski kayıtlardaki eşyalara hangi kondisyon verilsin?

**Varsayılan işlem:** Kodlanmadı; onay bekleniyor.

### Q-042 — PAKET 3: Eğitim yolu, lise tercihi, üniversite ve iş
**Durum:** **Uygulandı** (Faho'nun açık talimatıyla). Sayısal değerler ve kalan sorular **Q-047** ve **Q-048**'de. **Bağlantılı:** Q-030, Q-031, EDU-001.

**Kodun şu anki durumu:** Her yaş otomatik bir sınıf ilerliyor, kademe kendiliğinden değişiyor. Sınav, tercih, diploma, üniversite ve meslek **yok**.

**İstenen:** 4. sınıf sonrası ortaokula geçiş, 8. sınıf sonrası **lise tercihi** (fen/bilim, sosyal bilimler, bilişim, güzel sanatlar, müzik, tasarım, el sanatları, teknik/mesleki, genel akademik). Gerçek resmî okul türleriyle birebir aynı olmayacak; oyun için tutarlı bir model. Tercih zekâ, önceki okul deneyimi, sınav sonucu, şehir ve aile koşullarıyla ilişkili olsun; oyuncuya gerçekten seçim sunulsun. 12. sınıf sonunda herkes otomatik üniversiteye gitmesin: hazırlan / tercih yap / iş ara / mesleki eğitim. Üniversiteye girmeyen de anlamlı hayat yaşasın. Lise alanı ve üniversite bölümü iş olanaklarını etkilesin (güzel sanatlar → tasarım/ressamlık, bilişim → yazılım); eğitim tek başına iş garantisi vermesin. Maaş cüzdana aktarılsın; başvuru, kabul/ret, çalışma ve iş değiştirme aynı kariyer altyapısına bağlansın.

**Karar soruları:** 8. sınıf sınavı nasıl modellensin — zekâya bağlı puan mı, küçük bir mini oyun mu, ikisi birden mi? Puan eşikleri ne olsun? Lise türü sayısı ilk sürümde kaç olsun? Sınıfta kalma ve okulu bırakma olacak mı? Üniversite bölümü listesi ne kadar geniş olsun? Maaş yaş alırken toplu mu, olay olarak mı gelsin?

**Varsayılan işlem:** Kodlanmadı; sınav ayrıntısı bilinçli olarak ertelendi.

### Q-043 — PAKET 4: Aktiviteler (berber, spor salonu, kütüphane)
**Durum:** **Uygulandı** (Faho'nun açık talimatıyla). Sayısal değerler ve kalan sorular **Q-049**'da. **Bağlantılı:** Q-022.

**Kodun şu anki durumu:** Aktiviteler menüsünde yalnızca "Birlikte vakit geçir" çalışıyor; berber, spor salonu ve seyahat için düğme konmadı.

**İstenen:** Aktiviteler kişi listesinin kopyası olmasın, gerçekten yapılabilir etkinlikler içersin.
- **Berber/kuaför:** saç kestir, saç stilini değiştir, uygun ek bakım. Görünüme ve bazen karizmaya etki; her seferinde garanti büyük artış olmasın, tekrar sınırı bulunsun; ücret gerçekten cüzdandan düşsün.
- **Spor salonu:** koşu, ağırlık, esneme. Sağlık/görünüm/mutluluk/karizma üzerinde eyleme uygun sonuç; sınırsız stat kasma olmasın, yorulma/dinlenme dengesi olsun.
- **Kütüphane:** yaşa uygun kitap seç, oku, bitir. Basit bir kitap mini oyunu: kitaba tıklayınca sayfa ilerlesin; sayfalarda tam metin gerekmez, soyut satır çizgileri yeterli. İlkokulda kısa ve kolay, lise/üniversitede uzun ve farklı türde kitaplar. Zekâya veya uygun değerlere makul katkı; tek kitap tekrarlanarak zekâ 100 yapılamasın. Kitap adları özgün olabilir veya esinlenebilir; **telifli kitapların tam metni kopyalanmaz**.

**Karar soruları:** Berber ücretleri ve etki aralığı ne olsun? Saç stili görünümde kalıcı bir veri mi olsun (karaktere görsel özellik eklemek gerekir mi)? Spor salonunda yorulma nasıl modellensin (yaş başına hak, enerji değeri)? Kitap mini oyunu kaç sayfa sürsün ve bitirmeden bırakma olsun mu? Kaç kitap yazılsın?

**Varsayılan işlem:** Kodlanmadı.

### Q-044 — PAKET 5: Sosyal medya ve Ün
**Durum:** **Uygulandı** (Faho'nun açık talimatıyla). Sayısal değerler ve kalan sorular **Q-050**'de. **Bağlantılı:** D-027 (koşullu Ün).

**Kodun şu anki durumu:** `PlayerCharacter.fame` alanı var ama **hiç açılmıyor**; sosyal medya sistemi yok.

**İstenen:** 16 yaşından itibaren hesap açabilme (YouTube, Instagram, X). Hesap açmak **zorunlu olmasın**; hesabı olmayan oyuncuya o platformdan mesaj/takipçi olayı çıkmasın. Her hesabın ayrı takipçi/abone sayısı ve içerik geçmişi olsun. YouTube'da eğlence, vlog, oyun, bilgilendirici ve gündem videosu gibi türler; Instagram ve X'te platforma uygun farklı türler. Takipçi kazanımı içerik türüne, mevcut kitleye, karakter özelliklerine, şansa ve olaylara göre değişsin; her paylaşım takipçi kazandırmasın. Siyasi içerik **yalnızca tarafsız bir kategori** olarak ele alınsın; gerçek siyasi görüşe veya seçim tercihine yönlendiren içerik üretilmesin. İleride ün, gelir, tanışma, sponsorluk ve romantik mesajlarla bağlansın — hepsi aynı pakette değil.

**Karar soruları:** Hangi platform önce gelsin? Takipçi ölçeği ne olsun (yüzler mi, milyonlar mı)? Ün değeri takipçiden mi türesin, ayrı mı tutulsun? Gelir ne zaman devreye girsin? İçerik türleri kaç tane olsun? Platform adları gerçek markalar mı olsun, yoksa oyuna özgü adlar mı kullanılsın (telif ve marka riski açısından **oyuna özgü adlar öneriyorum**)?

**Varsayılan işlem:** Kodlanmadı.

### Q-045 — Küçük yaşta değerli eşya satışı
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/interaction/item_actions.dart`. **Bağlantılı:** Q-041.

**Mevcut kesin kural:** Yok. Faho: "Küçük yaştaki karakterlerin değerli eşya satışı için henüz kesin bir oyun kuralımız yok."

**Kodun şu anki geçici çözümü:** Temel değeri **300 ₺ üstü** olan eşyalar **15 yaşından** önce satılamıyor; gerekçe ekranda yazıyor. Ucuz oyuncaklar her yaşta satılabiliyor. İkisi de `prototypeOnly`.

**Karar soruları:** Yaş sınırı kaç olmalı, yoksa sınır yaş yerine "aile onayı" olarak mı modellensin (anne/babaya sorma olayı)? Küçük yaşta satış mümkün olsun ama düşük fiyata mı olsun? Hediye edilen bir eşyayı satmak veren kişiyle ilişkiyi etkilesin mi? Eşya satışı hayat günlüğünde aileye görünsün mü?

**Claude'un önerisi (yalnızca öneri):** "Aile onayı" modeli oyuna daha çok yakışır ama bir olay/diyalog akışı gerektirir; basit yaş sınırı şimdilik yeterli.

**Varsayılan işlem:** Mevcut sınır geçicidir, kesin kural ilan edilmedi.

### Q-046 — Eşya ekonomisinin sayısal dengesi
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/interaction/item_actions.dart`, `app/lib/data/item_catalog.dart`, `app/lib/data/shop_catalog.dart`. **Bağlantılı:** Q-021, Q-039, Q-041.

**Kodun şu anki geçici çözümü (hepsi `prototypeOnly`):**
- Kondisyon 0-100; yeni eşya 90, kayıt göçünden gelen eşya 75.
- Kullanımda 2-5 kondisyon düşüşü; kullanım kazancı aynı yaşta 4 tekrarda sıfıra iner.
- Temizlik +6 ve **tavan 85** (mekanik hasarı onaramaz), ücretsiz.
- Bakım +25 ve **tavan 95**; ücret = temel değer × 0.15 × eksik kondisyon oranı, en az 20 ₺; bisiklet bakım seti varsa yarı fiyat.
- Satış: `temel × özelÇarpan(2.2) × (0.25 + 0.75 × kondisyon/100) + Σ(aksesuar × 0.5)`, sonra ikinci el katsayısı **0.55**.
- Kullanılamaz eşik: kondisyon 10 altı.
- Temel değerler: bisiklet 2500 ₺, kol saati 900 ₺, antika cep saati 1800 ₺ (özel), yo-yo 25 ₺ …

**Karar soruları:** Kondisyon sayı olarak mı gösterilsin, yoksa yalnızca "Yeni gibi / İyi / Yıpranmış" basamakları mı? Yıpranma yaş başına mı, kullanım başına mı işlesin? Bakım tavanı 95 mi kalsın? İkinci el katsayısı ve antika çarpanı ne olmalı? Fiyatlar hangi para ölçeğine oturacak (Q-021)? Aksesuar sökülüp yeniden takılabilsin mi? Eşya kaybolma/çalınma olayları olacak mı?

**Claude'un önerisi (yalnızca öneri):** Kondisyonu ekranda hem sayı hem basamak olarak göstermek şimdilik en anlaşılır yol; kesin denge oyun ekonomisi (maaş, fiyatlar) netleşince ayarlanmalı.

**Varsayılan işlem:** Bütün sayılar geçici; hiçbiri `DECISIONS.md`'ye eklenmedi.

### Q-047 — Eğitim yolu: alanlar, puanlar ve üniversite kabulü
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/data/education_tracks.dart`, `app/lib/data/university_catalog.dart`, `app/lib/domain/education/education_path.dart`. **Bağlantılı:** Q-030, Q-042.

**Kodun şu anki geçici çözümü (hepsi `prototypeOnly`):**
- Dokuz lise alanı: fen ve bilim (70 puan), bilişim (65), sosyal bilimler (55), tasarım (45), güzel sanatlar (40), müzik (40), el sanatları (0), teknik/mesleki (0), genel akademik (0). Puan ne olursa olsun **en az üç alan açık**.
- Yerleştirme puanı = zekâ × 0.7 + okul izleri (derste söz almak +8, arkadaşa yardım +4) + 0-20 şans, 0-100 arasına sıkıştırılır. 8. sınıftan 9'a geçerken **bir kez** hesaplanır.
- Alan seçimi lise boyunca her yıl küçük bir zekâ/karizma/görünüş katkısı verir.
- Altı üniversite bölümü (mühendislik 72, bilgisayar 68, eğitim 55, güzel sanatlar 45, sosyoloji 45, işletme 40). Başvuru puanı = (yerleştirme puanı + zekâ)/2 + tercih edilen alandan +12 + 0-10 şans.
- Üniversite 4 yıl; her yaş alışta bir sınıf ilerler.

**Karar soruları:** Alan adları ve sayısı böyle mi kalsın? 8. sınıf sınavı bir mini oyuna dönüşsün mü (Q-030'daki soru)? Yerleştirme puanı formülü zekâya bu kadar bağlı mı olsun? Sınıfta kalma ve okulu bırakma olacak mı? Üniversite sınavı ayrı bir puan olarak mı modellensin? Bölüm sayısı ilk sürümde kaç olsun? Üniversitede başarı/not takibi olacak mı?

**Varsayılan işlem:** Bütün sayılar geçici; `DECISIONS.md`'ye eklenmedi.

### Q-048 — Meslekler, kabul olasılığı ve maaş ölçeği
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/data/job_catalog.dart`, `app/lib/domain/career/job_market.dart`. **Bağlantılı:** Q-021, Q-031, Q-046.

**Kodun şu anki geçici çözümü (hepsi `prototypeOnly`):**
- Altı iş: mağaza çalışanı (16 yaş, 21.000 ₺/yıl), garson (16, 19.500), teknik servis (18, 34.000), ressam/tasarımcı (18, 42.000), yazılım geliştirici (20, 96.000), öğretmen (22, 62.000).
- Koşullar: yaş, lise/üniversite mezuniyeti, uygun lise alanı **veya** uygun üniversite bölümü, asgari zekâ/karizma. Okula devam ederken tam zamanlı işe başvurulmaz.
- Kabul olasılığı: taban %50 + uygun eğitim %25 + yüksek zekâ %15 + yüksek karizma %7,5; **tavan %90** — iş asla garanti değil.
- Aynı yaşta aynı işe en fazla 3 başvuru.
- Maaş yaş alırken **bir kez** ödenir; `lastPaidAge` çift ödemeyi engeller. İşe girilen yıl için ödeme yapılmaz.

**Bilinen tutarsızlık:** `ilk_maas` olayı 1.500-3.000 ₺ veriyor (bir aylık zarf gibi), iş maaşları ise yıllık on binler. Eşya fiyatlarıyla (bisiklet 2.500 ₺) birlikte ele alınması gereken bir ölçek sorunu.

**Karar soruları:** Para ölçeği ne olacak (Q-021)? Maaş yıllık toplu mu ödensin, yoksa olay olarak mı gelsin? Terfi, zam ve işten çıkarılma ne zaman eklensin? Yarı zamanlı öğrenci işleri olsun mu? İşsizlik süresi ve ilişkilere etkisi modellensin mi? Meslek sayısı ilk sürümde kaç olsun?

**Varsayılan işlem:** Sayılar geçici; ölçek uyumu ayrıca kararlaştırılacak.

### Q-049 — Aktivitelerin dengesi ve kitap sistemi
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/data/activity_catalog.dart`, `app/lib/domain/activities/activity_engine.dart`. **Bağlantılı:** Q-043, Q-046.

**Kodun şu anki geçici çözümü (hepsi `prototypeOnly`):**
- **Berber:** saç kestir 120 ₺ (4 yaş+, görünüş +3, yılda 2), saç stili 260 ₺ (10 yaş+, görünüş +4 karizma +2, yılda 1), bakım 90 ₺ (12 yaş+, görünüş +2 mutluluk +2, yılda 2).
- **Spor salonu:** koşu 60 ₺ (12 yaş+, sağlık +4), ağırlık 60 ₺ (14 yaş+, sağlık +3 görünüş +3), esneme ücretsiz (8 yaş+, sağlık +2 mutluluk +2). Hepsi yılda 3 kez.
- Tekrar eğrisi: 1.0 → 0.6 → 0.3; sınıra gelince eylem kapanır.
- **Kitaplar:** yedi kitap, 5-24 sayfa; ilkokul çağında kısa, lise/üniversite çağında uzun. Bitirme kazancı zekâ +2…+7 (bazılarında mutluluk/karizma), **yalnızca ilk bitirişte** uygulanır. Sayfada telifli metin yok, soyut satır çizgileri var.
- Saç stili altı metinden biri olarak saklanır; görsel karakter sistemi yok.

**Karar soruları:** Berber ve spor ücretleri hangi para ölçeğine oturacak (Q-021, Q-048)? Spor için ayrı bir "yorgunluk/enerji" değeri eklensin mi, yoksa yıllık tekrar sınırı yeterli mi? Saç stili karakterin görünümünde görsel olarak yer alsın mı (avatar sistemi gerekir)? Kitap sayısı ve tür çeşitliliği ne olsun? Kitabı yarıda bırakma cezalandırılsın mı? Okunan kitaplar "Ben" ekranında bir kitaplık olarak gösterilsin mi? Aynı kitabı yeniden okumak küçük bir mutluluk verebilir mi?

**Claude'un önerisi (yalnızca öneri):** Yıllık tekrar sınırı şimdilik yeterli; ayrı enerji değeri oyunu karmaşıklaştırır. Okunan kitapların "Ben" ekranında listelenmesi ucuz ve hoş bir ekleme olur.

**Varsayılan işlem:** Bütün sayılar geçici; `DECISIONS.md`'ye eklenmedi.

### Q-050 — Sosyal medya dengesi, platform adları ve Ünün kapsamı
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/data/social_catalog.dart`, `app/lib/domain/social/social_engine.dart`. **Bağlantılı:** D-027, Q-044.

**Kodun şu anki geçici çözümü (hepsi `prototypeOnly`):**
- Üç platform, **16 yaşından itibaren isteğe bağlı** hesap. Hesabı olmayan platformda paylaşım yapılamaz ve olay çıkmaz.
- On içerik türü (video 4, fotoğraf 3, mikroblog 3). Takipçi değişimi = (taban erişim + karakter katkısı × 0.5 + mevcut kitle × 0.06) × tekrar çarpanı × 0.5-1.5 şans.
- Aynı içeriğin son beş paylaşımdaki her tekrarı kazancı %25 düşürür ve kayıp riskini %5 artırır.
- Kayıp riski içerik türüne göre %8-20; kayıp en çok mevcut kitlenin %8'i kadar.
- Bir yaşta en fazla 6 paylaşım anlamlı sonuç verir.
- **Ün** toplam takipçi 500'ü geçince açılır; 900 takipçi ≈ 1 ün puanı, tavan 100. Ün yalnızca arttığında güncellenir.
- Siyasi içerik kategorisi **eklenmedi**: tarafsız bir kategori olarak ileride ele alınacak.

**Karar soruları:**
1. **Platform adları:** şu an gerçek adlar metin olarak kullanılıyor (logo, renk veya ekran tasarımı kopyalanmadı). Marka riski açısından oyuna özgü adlar (ör. "Kare", "Akış", "Vitrin") tercih edilir mi? **Claude'un önerisi: oyuna özgü adlar.**
2. Takipçi ölçeği ne olsun — yüzler mi, milyonlar mı? Büyük sayılar için "1,2 B" gibi kısaltma gerekir mi?
3. Ün eşiği ve ün-takipçi oranı ne olmalı? Ün yalnızca sosyal medyadan mı gelsin, kahramanca davranış gibi olaylardan da mı?
4. Siyasi gündem kategorisi eklenecekse hangi çerçevede tarafsız kalacak?
5. Gelir, sponsorluk, mesajlaşma ve romantik tanışma ne zaman bağlansın?
6. Paylaşım sıklığı yıllık 6 ile mi sınırlı kalsın, yoksa "enerji/zaman" gibi ortak bir kaynak mı gelsin?

**Varsayılan işlem:** Bütün sayılar geçici; gelir/sponsorluk/mesajlaşma yazılmadı ve sahte düğme konmadı.

### Q-051 — Üniversite puanının hesabı ve not ortalaması
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/education/education_path.dart`, `app/lib/ui/screens/sections/education_career_pages.dart`. **Bağlantılı:** Q-047, Q-030.

**Sorun:** Oyuncu başvuru ekranında bölümlerin taban puanını görüyordu ama
kendi puanını göremiyordu. Eski kodda kalıcı bir "başvuru puanı" yoktu;
puan her başvuruda rastgelelikle yeniden hesaplanıyordu, bu yüzden
gösterilebilecek tek bir doğru sayı da yoktu.

**Kodun şu anki geçici çözümü (hepsi `prototypeOnly`):**
- Lise bitince **bir kez** üniversite sınav puanı hesaplanıp kaydediliyor:
  `((lise yerleştirme puanı + zekâ) / 2) + 0..10 sınav günü şansı`, 0-100
  arası. Yerleştirme puanı yoksa zekâ taban alınıyor.
- Başvuruda kullanılan puan = kayıtlı sınav puanı + bölümün tercih ettiği
  alandan gelen **+12** katkı. Rastgelelik yok; ekranda yazan puan ile
  kabul kararındaki puan aynı.
- 8. sınıf **lise yerleştirme puanı** ile **üniversite sınav puanı** ayrı
  alanlar, ekranda ayrı isimlerle gösteriliyor.
- **Üniversite not ortalaması sistemi yok.** Uydurulmadı; ekranda
  "not ortalaması sistemi henüz yok" notu var.

**Karar soruları:**
1. Üniversite puanı gerçek bir sınav olayı olarak mı kurgulansın (hazırlık,
   deneme, sınav günü stresi), yoksa bu sessiz formül yeterli mi?
2. Formül ne olmalı — zekâ ağırlığı, çalışma/ders seçimlerinin katkısı,
   şans payı? Şu anki ±10 şans payı kabul edilebilir mi?
3. Alan katkısı +12 doğru ölçek mi; alan dışı tercihe **ceza** verilsin mi?
4. Puan 0-100 ölçeğinde mi kalsın, yoksa gerçek sınavlara benzer daha geniş
   bir ölçek mi (ör. 100-500) kullanılsın?
5. Üniversitede not ortalaması sistemi gelecek mi? Gelirse mezuniyet
   derecesi iş bulmayı etkilesin mi?
6. Sınavı bir kez daha deneme (ertesi yıl tekrar sınav) hakkı olacak mı?

**Claude'un önerisi (yalnızca öneri):** Puan ölçeği 0-100 olarak kalsın,
ertesi yıl tekrar sınav hakkı ileride "bir yıl kaybı" karşılığında
eklensin. Not ortalaması ancak üniversite yılları gerçek bir oynanışa
kavuşursa anlamlı olur; o zamana kadar uydurulmasın.

**Varsayılan işlem:** Bütün sayılar geçici; `DECISIONS.md`'ye eklenmedi.

### Q-052 — Mülakat soruları: kapsam, zorluk ve tekrar sınırı
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/data/interview_catalog.dart`, `app/lib/domain/career/job_market.dart`, `app/lib/ui/widgets/interview_sheet.dart`. **Bağlantılı:** Q-048.

**Kodun şu anki geçici çözümü (hepsi `prototypeOnly`):**
- Her meslek için **3-5 özgün soru**; başvuruda biri seçiliyor. Sorular
  mesleğe özgü (yazılım: hata ayıklama, teknik servis: arıza bulma,
  ressam/tasarımcı: renk ve tasarım, garson: sipariş ve iletişim, mağaza:
  stok ve kasa, öğretmen: öğrenciye anlatma).
- Çoktan seçmeli, **tek doğru cevap**; seçenek sırası sabit (kayıttan
  geri yüklenince soru ve seçenekler değişmesin diye karıştırılmıyor).
- Yanlış cevapta doğru seçenek ve kısa açıklama gösteriliyor.
- Doğru cevap tek başına yetmiyor: nitelik koşulları cevap anında yeniden
  denetleniyor.
- Aynı yaşta aynı işe en fazla **2 başvuru** (önceden 3); sayaç başvuru
  anında artıyor, mülakattan vazgeçmek hakkı geri vermiyor. Aynı yaşta
  daha önce sorulmamış soru tercih ediliyor.
- Mülakat penceresi açıkken başka işe başvurulamıyor.

**Karar soruları:**
1. Soru sayısı meslek başına 3-5 yeterli mi, yoksa ezberi zorlaştırmak için
   8-10'a mı çıkarılsın?
2. Zorluk karakterin zekâsına göre değişsin mi (düşük zekâda daha çok
   çeldirici), yoksa herkese aynı mı sorulsun?
3. Bir başvuruda tek soru mu, yoksa 2-3 soruluk kısa bir tur mu olsun?
4. Yanlış cevabın maliyeti ne olmalı — yalnızca ret mi, yoksa o işe bir
   süre başvuramama mı?
5. Yıllık 2 başvuru sınırı doğru mu? Farklı işlere başvuru toplamı ayrıca
   sınırlansın mı?
6. Nitelik koşulu sağlanıyorsa mülakat **tek** karar noktası mı olsun,
   yoksa karizma/şans gibi ek bir pay da kalsın mı? (Şu an ek pay yok:
   doğru cevap + koşullar = kabul.)
7. Mülakat metinleri ileride meslek dışı (staj, terfi, üniversite mülakatı)
   durumlarda da kullanılsın mı?

**Claude'un önerisi (yalnızca öneri):** Soru havuzu meslek başına 6-8'e
çıkarılsın; tek soru ve "doğru cevap = kabul" sadeliği korunsun, karizma
payı yeniden eklenmesin (oyuncunun kararı sonucu belirlesin).

**Varsayılan işlem:** Bütün sayılar geçici; `DECISIONS.md`'ye eklenmedi.

### Q-053 — Paylaşım sınırının kapsamı
**Durum:** **Kısmen karara bağlandı** (D-031). İlkeler kesinleşti; sayısal denge geçici. **Kaynak:** `app/lib/domain/social/social_engine.dart`. **Bağlantılı:** Q-050.

**Sorun:** Yıllık paylaşım sayacı bütün platformlar için ortaktı; Instagram'da
sınıra ulaşmak YouTube'u da kapatıyordu. Sayaç platform başına ayrıldı.

**Kodun şu anki geçici çözümü (hepsi `prototypeOnly`):**
- Her platformun kendi yıllık sınırı var: yaş başına **6 paylaşım**.
- Sınır **platformun toplamı** üzerinden işliyor; aynı platformdaki farklı
  içerik türleri aynı sayacı paylaşıyor.
- Sayaç hesabın paylaşım geçmişinden okunuyor, ayrı bir alanda tutulmuyor.

**Karar soruları:**
1. Sınır platform başına 6 olarak mı kalsın? Üç hesabı olan oyuncu yılda 18
   paylaşım yapabiliyor; bu çok mu?
2. İçerik türü başına ayrı sınır olsun mu (ör. vlog 2, kısa video 3), yoksa
   platform toplamı yeterli mi?
3. Platformlar arasında ortak bir "zaman/enerji" kaynağı gelirse sınır ona mı
   bağlansın?
4. Sınır yaşa göre değişsin mi (öğrenciyken az, tam zamanlı içerik üreticisi
   olunca çok)?

**Claude'un önerisi (yalnızca öneri):** Platform başına toplam sınır sade ve
anlaşılır; içerik türü başına ayrı sınır eklemek yerine ileride ortak bir
zaman kaynağı gelirse o kullanılsın.

**Karara bağlananlar (D-031):**
- Sınır **platform başına bağımsız**; bir platformda dolması diğerlerini etkilemez.
- Aynı platformdaki farklı içerik türleri **ortak platform sayacını** kullanır.
- Ayrı bir **enerji sistemi eklenmeyecek**. İleride profesyonel içerik üreticiliği
  ve zaman yönetimi sistemi gelirse kapasite yeniden ele alınacak.

**Geçici kalan (denge kararı değil):** platform başına yaş başına **6** paylaşım.

**Varsayılan işlem:** Bütün sayılar geçici; `DECISIONS.md`'ye eklenmedi.

### Q-054 — Kumarhane: yaş sınırı, bahis ölçeği ve yayın koşulları
**Durum:** **Kısmen karara bağlandı** (D-032). İlkeler kesinleşti; sayısal denge geçici. **Kaynak:** `app/lib/domain/casino/`, `app/lib/ui/screens/sections/casino_pages.dart`. **Bağlantılı:** Q-021, Q-048.

**Kodun şu anki geçici çözümü (hepsi `prototypeOnly`):**
- Kumarhane **18 yaşında** açılıyor.
- Bahis 50-5000 ₺; hazır adımlar 50/100/250/500/1000.
- Bir yaşta toplam **25.000 ₺** bahis sınırı; yaş dönünce sıfırlanıyor.
- Blackjack: krupiye 17'de duruyor (yumuşak 17 dâhil), doğal blackjack 3:2.
  Sigorta, bölme ve ikiye katlama **yok**.
- Rulet: tek sıfırlı Avrupa düzeni; renk ve tek/çift 1:1, sayı 35:1.
- Yalnızca sanal para; gerçek para, ödül veya reklam karşılığı bahis yok.

**Karar soruları:**
1. Oyun içi yaş sınırı 18 mi kalsın? Mağaza yaş derecelendirmesi ve
   **bölgesel yayın koşulları** (bazı ülkelerde sanal kumar içeriği yaş
   derecesini yükseltir veya mağaza kurallarına takılır) nasıl ele alınsın?
   Kumarhane bazı bölgelerde kapatılabilir bir modül mü olsun?
2. Bahis ölçeği maaşlara göre doğru mu (Q-048 ile birlikte)? 5000 ₺ üst
   sınırı maaş ölçeği değişirse yeniden ayarlanmalı.
3. Yıllık 25.000 ₺ sınırı kalsın mı; oyuncunun kendi belirlediği isteğe
   bağlı bir harcama limiti eklensin mi?
4. Kumar kaybı mutluluk/sağlık gibi değerleri etkilesin mi, borç sistemi
   gelsin mi? (Şu an yalnızca cüzdanı etkiliyor.)
5. Blackjack'e sigorta/bölme/ikiye katlama eklensin mi?
6. Kumarhanenin hikâye tarafı (bağımlılık teması, aile tepkisi) işlensin mi;
   işlenecekse hangi çerçevede?

**Claude'un önerisi (yalnızca öneri):** Yaş sınırı 18 kalsın ve kumarhane
ayarlardan kapatılabilir bir modül olarak tasarlansın; bu, bölgesel yayın
koşullarını en az riskle karşılar. Sigorta/bölme gibi kurallar sadeliği
bozar, şimdilik eklenmesin.

**Karara bağlananlar (D-032):**
- Kumarhane **isteğe bağlı** bir aktivite; yalnızca **sanal para**. Gerçek para,
  gerçek ödül, ödeme sistemi, reklam karşılığı bahis ve **borçla bahis yok**.
- **Ayarlardan tamamen gizlenebilir/kapatılabilir bir modül** olacak.
- Oyun içi yaş sınırı şimdilik **18**; bu bir **yayın uygunluğu garantisi değil**.
  Hedef ülke ve mağaza koşulları yayın öncesi ayrıca kontrol edilecek.
- Oyuncu kendisi için **isteğe bağlı harcama limiti** belirleyebilecek; limit
  dolunca **daha fazla oynamaya teşvik eden mesaj gösterilmeyecek**.
- Blackjack'te **bölme, sigorta ve ikiye katlama eklenmeyecek**; rulet ve
  blackjack'in açık kuralları korunacak.
- Kumar kazancı sağlık/mutluluk/karizmada **otomatik büyük artış sağlamayacak**;
  **borç sistemi eklenmeyecek**.

**Geçici kalan (denge kararı değil):** bahis alt/üst sınırı ve yıllık toplam
sınır; bunlar maaş ve gider dengesiyle (Q-055) birlikte belirlenecek.

**Uygulama notu:** Kararın kod tarafı `claude/duzeltmeler-d031-d038`
dalında tamamlandı: kumarhane ayarlardan kapatılabiliyor, oyuncu kendine
yıllık bahis limiti koyabiliyor, kalan hak vurgusu nötr bilgiye çevrildi.

**Denge güncellemesi (D-040):** Sabit 500-25.000 ₺ bahis ve 150.000 ₺ yıllık
sınır kaldırıldı. Bahis bütçesi artık gider sonrası kullanılabilir gelir ve
cüzdandan hesaplanıyor; en küçük bahis 100 ₺. Ölçüm: `docs/BALANCE_REPORT.md` §5.

**Varsayılan işlem:** Bütün sayılar geçici; `DECISIONS.md`'ye eklenmedi.

### Q-055 — Ortak ekonomi ölçeği: fiyatlar ve maaşlar
**Durum:** **Kısmen karara bağlandı** (D-033). İlkeler kesinleşti; sayısal denge geçici. **Kaynak:** `app/lib/data/economy.dart`, `app/lib/data/item_catalog.dart`, `app/lib/data/job_catalog.dart`. **Bağlantılı:** Q-021, Q-041, Q-046, Q-048, Q-054.

**Sorun:** İlk maaşlar, eşya fiyatları ve yeni eklenen araç/konut fiyatları
farklı ölçeklerdeydi (yıllık maaş 21.000 ₺ iken bisiklet 2.500 ₺). Tek bir
tabloya taşındı.

**Kodun şu anki geçici çözümü (hepsi `prototypeOnly`, yıllık ₺):**
- Aileden küçük para 150-600; bayram harçlığı olayı 1.500-3.000.
- Küçük eşya 20-900; kıyafet/ayakkabı/spor 450-1.500; saat/kulaklık 900-2.200.
- Telefon 18.000, konsol 22.000, bilgisayar 32.000.
- Bisiklet 9.000; motosiklet 75.000-190.000; otomobil 320.000-3.400.000.
- Konut 1.800.000-9.500.000.
- Yıllık maaşlar: garson 165.000, mağaza 180.000, teknik servis 260.000,
  ressam/tasarımcı 300.000, öğretmen 420.000, yazılım 720.000.
- Kumarhane bahsi 500-25.000; yıllık toplam 150.000.

**Karar soruları:**
1. Ölçek doğru mu? Bir yıllık en düşük maaş bir telefon + birkaç küçük eşya
   alıyor; ikinci el otomobil ~2 yıl, küçük daire uzun yıllar sürüyor.
2. Enflasyon/yıllara göre fiyat değişimi olacak mı, yoksa sabit mi kalsın?
3. Yaşam gideri (kira, fatura, yemek) eklenecek mi? Şu an hiç gider yok;
   maaşın tamamı birikiyor.
4. Kredi/taksit sistemi gelsin mi (özellikle konut için)?
5. Meslekler arası maaş farkı bu kadar açık olsun mu (yazılım, garsonun
   4,4 katı)?
6. Miras, hediye ve kumar kazancı bu ölçeğe göre yeniden ayarlanmalı mı?

**Claude'un önerisi (yalnızca öneri):** Yaşam gideri olmadan ekonomi çok
cömert; küçük bir yıllık gider kalemi (kira/geçim) eklenirse birikim
anlamlı olur. Kredi, konut alımını erişilebilir kılmak için ilk aday.

**Karara bağlananlar (D-033):**
- Bütün para akışları **tek ekonomi ölçeğine** bağlı ve **yıllık** ölçekte.
- **Yıllık temel yaşam gideri gelecek**: barınma, beslenme, faturalar; karakterin
  **gerçekten yaşadığı hane ve yaşam koşullarına** göre hesaplanacak.
- **Çocuğa yetişkin gideri yüklenmeyecek**; ailesiyle yaşayan ile bağımsız
  yaşayanın gideri farklı olacak.
- Maaşın tamamı otomatik birikmeyecek; giderler cüzdanı **sessizce eksiye
  düşürmeyecek**. Para yetmezse **açık sonuç** ve genişletilebilir bir
  **geçim sıkıntısı durumu** olacak.
- İlk sürümde fiyatlar **sabit**; enflasyon ve ayrıntılı kredi/taksit sonraya.
  Konutu kolaylaştırmak için **sınırsız kredi eklenmeyecek**.
- Meslekler arasında **anlamlı gelir farkı** olacak, ama **tek meslek diğerlerini
  anlamsızlaştırmayacak**.
- Miras, hediye, araç, ev, maaş ve kumar bahisleri **aynı değerleme sistemine**
  bağlı olacak.

**Geçici kalan (denge kararı değil):** bütün fiyatlar, maaşlar ve gider oranları.
Ölçüm raporu: `docs/BALANCE_REPORT.md`. Kesin sayılar **Faho'nun onayı olmadan
kalıcı denge kuralı ilan edilmeyecek**.

**Uygulama notu:** Yıllık geçim gideri uygulandı (çocukta 0; ailesinin
yanında, bağımsız kirada ve kendi evinde farklı). Cüzdan eksiye düşmüyor;
geçim sıkıntısı durumu var. Güncel ölçüm `docs/BALANCE_REPORT.md` §4'te.

**Denge güncellemesi (D-039):** Gider sabit tutar olmaktan çıkıp taban +
gelir payına dönüştü ve kalem kalem tutuluyor. Bağımsız yaşayan garson artık
yılda 65.250 ₺ birikim yapabiliyor (önce 25.000 ₺). Ölçüm:
`docs/BALANCE_REPORT.md` §5.

**Varsayılan işlem:** Bütün sayılar geçici; `DECISIONS.md`'ye eklenmedi.

### Q-056 — Araç sahipliği, ehliyet ve taşınma
**Durum:** **Kısmen karara bağlandı** (D-034). İlkeler kesinleşti; sayısal denge geçici. **Kaynak:** `app/lib/data/license_catalog.dart`, `app/lib/domain/interaction/item_actions.dart`, `app/lib/data/shop_catalog.dart`. **Bağlantılı:** Q-041, Q-055.

**Kodun şu anki geçici çözümü (hepsi `prototypeOnly`):**
- **Araç satın almak ehliyet istemiyor; aracı kullanmak istiyor.** Motosiklet
  ehliyeti otomobil kullandırmıyor.
- Araç satın alma yaşı: motosiklet 16/18, otomobil 17 (galeri listesinde).
- Konut satın alma yaşı 18.
- **Ev satın almak taşınma değil:** mülk sahipliği ile hane ayrı tutuluyor;
  taşınma, kira ve kiraya verme yazılmadı (sahte düğme de konmadı).
- Konutun konumu satın alındığı şehir olarak kaydediliyor (oyuncunun doğum
  şehri); şehir değiştirme sistemi yok.

**Karar soruları:**
1. Ehliyeti olmayan biri araç **sahibi** olabilsin mi? (Şu an olabiliyor:
   miras, hediye veya erken alım mümkün.) Yoksa satın alma da ehliyete mi
   bağlansın?
2. Araç satın alma yaşları ne olsun; ehliyet yaşlarıyla aynı mı olsun?
3. Taşınma sistemi ne zaman gelsin? Ev alınca "taşın" seçeneği mi sunulsun,
   yoksa taşınma ayrı bir olay mı olsun?
4. Kiraya verme ve kira geliri gelsin mi (Q-055 ile birlikte)?
5. Konutun konumu için gerçek bir şehir sistemi mi olsun (şehirler arası
   taşınma, farklı fiyat seviyeleri)?
6. Araç kullanımı yalnızca kondisyonu mu etkilesin, yoksa kaza riski,
   yakıt gideri gibi kalemler de gelsin mi?

**Claude'un önerisi (yalnızca öneri):** Sahiplik ile kullanım ayrı kalsın
(miras ve hediye için gerekli). Taşınma, konut sisteminin ikinci adımı
olarak ayrı bir pakette ele alınsın.

**Karara bağlananlar (D-034):**
- **Sahiplik ile kullanım ayrı**: küçük yaşta miras/hediye araç olabilir, ama
  ilgili ehliyet ve uygun yaş olmadan **sürülemez**.
- Galeriden **normal satın alma için şimdilik 18 yaş** prototip sınırı.
- **Ev almak otomatik taşınmak değil**; mülk sahipliği ile hane ayrı kalacak.
- İleride evin detayında ayrı bir **"Taşın"** eylemi olacak. Şehir değiştirme,
  kiraya verme ve kira geliri **taşınma altyapısına bağlı ayrı bir paket**.
- Araç kondisyonu, bakım masrafı ve satış değeri **mevcut eşya sistemiyle
  tutarlı** olacak; **yakıt ve kaza sistemleri şimdilik genişletilmeyecek**.

**Geçici kalan (denge kararı değil):** satın alma yaş eşikleri ve araç fiyatları.

**Uygulama notu:** Galeride araç satın alma yaşı 18'e çekildi. Aksesuar
yaşları (kask 16, tavan bagajı 17) kararda geçmediği için değiştirilmedi;
Faho'nun tercihi bekleniyor.

**Denge güncellemesi (D-042):** Otomobile özgü aksesuarların satın alma yaşı
18 oldu; motosiklet kaskı ve motosiklet parçaları 16'da kaldı.

**Varsayılan işlem:** Bütün sayılar geçici; `DECISIONS.md`'ye eklenmedi.

### Q-057 — Ehliyet: yaş, sınıf sistemi, ücret ve tekrar kuralı
**Durum:** **Kısmen karara bağlandı** (D-035). İlkeler kesinleşti; sayısal denge geçici. **Kaynak:** `app/lib/data/license_catalog.dart`, `app/lib/data/license_questions.dart`, `app/lib/domain/licensing/license_office.dart`. **Bağlantılı:** Q-055, Q-056.

**Kodun şu anki geçici çözümü (hepsi `prototypeOnly`):**
- İki ehliyet: motosiklet (en az 16 yaş, 4.000 ₺) ve otomobil (en az 18
  yaş, 8.000 ₺). Ehliyetler bağımsız; biri diğerini vermiyor.
- Sınav tek soruyla yapılıyor; motosiklet havuzunda 5, otomobil havuzunda
  6 özgün soru var (basit trafik bilgisi, güvenli sürüş, araç kontrolü).
- Doğru cevap = ehliyet. Yanlış cevapta ehliyet yok; doğru cevap ve kısa
  açıklama gösteriliyor.
- Aynı yaşta aynı ehliyet için **2 deneme**; her denemede ücret yeniden
  alınıyor, vazgeçmek iade getirmiyor.
- **Gerçek dünyadaki resmî sürücü belgesi sınıfları ve yaş sınırları
  doğrulanmış bilgi olarak sunulmuyor**; oyun içi basit bir model.

**Karar soruları:**
1. Yaş eşikleri (16/18) böyle mi kalsın? Gerçek sınıf sistemi (A1, A2, B…)
   modellenecek mi, yoksa oyun içi iki tür yeterli mi?
2. Sınav tek soru mu olsun, yoksa 3-5 soruluk kısa bir tur mu (ör. 5
   sorudan 4 doğru)?
3. Ücret ölçeği doğru mu (Q-055)? Başarısız denemede kısmi iade olsun mu?
4. Kurs/direksiyon dersi gibi bir hazırlık adımı eklensin mi (para ve
   zaman karşılığı başarı şansını artıran)?
5. Ehliyet kaybedilebilsin mi (ceza, kaza, ihlal)? Kaza sistemi gelirse
   ehliyetle nasıl bağlanacak?
6. Ehliyet ekranı Aktiviteler altında mı kalsın, yoksa "Ben"/kimlik
   ekranında bir belge listesi mi olsun?

**Claude'un önerisi (yalnızca öneri):** Tek soru, ücretin gerçekten
hissedildiği bir yapıda yeterli; 3 soruluk tur eklenecekse ücret
düşürülsün. Ehliyetin kaybı ancak bir kaza/ihlal sistemi gelirse anlamlı.

**Karara bağlananlar (D-035):**
- **İki bağımsız ehliyet** (motosiklet, otomobil) şimdilik yeterli.
- Geçici yaş eşikleri **motosiklet 16, otomobil 18**; **resmî belge sınıflarının
  birebir karşılığı olarak sunulmayacak**.
- Sınav **3 kısa soru** sorar; **en az 2 doğru** ile geçilir. Sonuçta **doğru
  cevaplar ve kısa açıklamaları** gösterilir.
- Her başvuruda **ücret bir kez** kesilir.
- Oyun sınav ortasında kapatılırsa **aynı sorulardan devam edilir**.
- Sürücü kursu, direksiyon sınavı, ehliyet kaybı ve ayrıntılı belge sınıfları
  **sonraya bırakıldı**.

**Geçici kalan (denge kararı değil):** yıllık deneme sayısı (şu an 2) ve sınav
ücretleri.

**Uygulama notu:** Sınav 3 soru / en az 2 doğru olarak uygulandı; sonuçta
bütün doğru cevaplar ve açıklamalar gösteriliyor, yarıda kalan sınav aynı
sorulardan sürüyor.

**Varsayılan işlem:** Bütün sayılar geçici; `DECISIONS.md`'ye eklenmedi.

### Q-058 — Ölüm eğrisi ve kaybın etkileri
**Durum:** **Kısmen karara bağlandı** (D-036). İlkeler kesinleşti; sayısal denge geçici. **Kaynak:** `app/lib/domain/life/mortality.dart`, `app/lib/domain/generation/life_progression.dart`. **Bağlantılı:** Q-047, Q-059.

**Kodun şu anki geçici çözümü (hepsi `prototypeOnly`, yıllık ihtimal):**
- 0-1 yaş %0,4 · 1-15 %0,04 · 15-40 %0,12 · 40-55 %0,4 · 55-65 %1,1 ·
  65-75 %2,8 · 75-85 %7,5 · 85-95 %17 · 95-105 %32 · 105+ %55.
- Oyuncuda sağlık değeri riski en çok iki katına çıkarıyor, en az yarıya
  indiriyor. NPC'lerde sağlık değeri yok; uydurulmuyor.
- Kaybın mutluluk etkisi yakınlık ve bağ puanına göre 1-30 arası.
- Ölüm gerekçeleri yaşa göre kısa metinler; ayrıntılı tasvir yok.

**Karar soruları:**
1. Eğri doğru mu? Bir hayat ortalama kaç yıl sürmeli?
2. Sağlık, meslek, alışkanlıklar (spor, kitap, kumar) ölüm riskini
   etkilesin mi?
3. Kaza, hastalık gibi **olay tabanlı** ölümler eklensin mi (şu an yalnızca
   sessiz bir yıllık eğilim var)?
4. Yas dönemi modellensin mi (birkaç yıl süren mutluluk etkisi, anma
   olayları)?
5. Oyuncunun ölümü tamamen rastgele mi kalsın, yoksa sağlık düşerse uyarı
   veren bir aşama mı olsun?
6. Ölüm metinleri hangi tonla yazılsın; çocukken ebeveyn kaybı nasıl
   anlatılsın?

**Claude'un önerisi (yalnızca öneri):** Sağlık değerinin etkisi kalsın,
olay tabanlı ölümler ayrı bir pakette ele alınsın. Ölümün yaklaştığını
sezdiren bir sağlık uyarısı oyuncuya hazırlık imkânı verir.

**Karara bağlananlar (D-036):**
- Ölüm simülasyonun doğal parçası; oyun **sürekli trajediyle cezalandırmayacak**.
- Çocuklukta **seyrek**, ileri yaşta daha olası; **her yıl birinin ölmesi
  gerekmiyor**.
- Sağlık riski etkileyebilir, ama **sağlık 100 diye ölümsüzlük yok**.
- **NPC yaşları ve kuşak farkları tutarlı** olacak.
- Kaza/hastalık kaynaklı **özel ölüm olayları ayrı içerik paketi**; şimdi
  rastgele ağır olay eklenmeyecek.
- Kayıp mutluluğu ilişkiye göre etkileyebilir; **yas zamanla hafifleyecek ve
  kalıcı, geri dönülemez bir değer cezasına dönüşmeyecek**.
- Ölüm metinleri **kısa, saygılı, bağlama uygun**. Sağlığı belirgin kötüleşen
  karakter için uyarı düşünülebilir, ama **her ölüm önceden haber verilmeyecek**.

**Geçici kalan (denge kararı değil):** yaşa göre ölüm olasılıkları. Ölçüm raporu:
`docs/BALANCE_REPORT.md` (500 hayat: ortalama ölüm yaşı 76,4; 18 yaş altı %0,8;
90+ %17,6; 18 yaşından önce ebeveyn kaybı %16,4). Yaşlı uç ve ebeveyn kaybı
oranı Faho'nun onayıyla ayarlanacak.

**Uygulama notu:** Yas artık zamanla hafifliyor (kalan yasın üçte biri her
yıl mutluluğa geri dönüyor). Ölüm olasılıkları değiştirilmedi; güncel
ölçüm `docs/BALANCE_REPORT.md` §4'te ve yaşlı uç ile çocukken ebeveyn
kaybı oranı hâlâ Faho'nun kararını bekliyor.

**Denge güncellemesi (D-041):** Ebeveyn yaşları üçgen dağılımdan seçiliyor ve
85 üstü ölüm eğrisi hafifçe yükseltildi. 5.000 hayatlık ölçümde 90+ oranı
%19,2'den %12,6'ya, çocukken ebeveyn kaybı %19,4'ten %12,3'e indi; genç
yetişkin ölümleri artırılmadı. Ölçüm: `docs/BALANCE_REPORT.md` §5.

**Varsayılan işlem:** Bütün sayılar geçici; `DECISIONS.md`'ye eklenmedi.

### Q-059 — Miras, velayet ve mülk devri
**Durum:** **Kısmen karara bağlandı** (D-037). İlkeler kesinleşti; sayısal denge geçici. **Kaynak:** `app/lib/domain/life/inheritance.dart`, `app/lib/domain/generation/life_generator.dart`. **Bağlantılı:** Q-055, Q-056, Q-058.

**Kodun şu anki geçici çözümü (hepsi `prototypeOnly`, gerçek hukuk kuralı
değildir ve öyle sunulmaz):**
- Mirasçılar: önce eş ve çocuklar, yoksa anne-baba, yoksa kardeşler.
- Eş varsa nakdin dörtte birini alır, kalanı çocuklara eşit bölünür.
- Eşya, araç ve konut bölünmez: her biri tek bir mirasçıya gider.
- Nakit, kişinin ekonomik durumundan geliyor: çok yoksul 0 ₺, dar gelirli
  25.000 ₺, orta halli 180.000 ₺, varlıklı 900.000 ₺, çok varlıklı
  3.500.000 ₺.
- Eşyalar kişinin **gerçekten sahip olduğu** `Person.estate` listesinden
  geliyor; bu liste ekonomik duruma göre hayat başında üretiliyor.
- Aynı miras iki kez dağıtılmıyor (`GameState.settledEstates`).
- **Velayet:** hanede yetişkin kalmazsa hayattaki yakın bir yetişkin haneye
  geçiyor; yeni kişi uydurulmuyor. Kimse yoksa yalnızca günlüğe yazılıyor.

**Karar soruları:**
1. Paylaşım kuralı böyle mi kalsın? Vasiyet, reddi miras, borç mirası gibi
   kavramlar oyuna girsin mi?
2. Miras vergisi veya masraf olsun mu?
3. Kişilerin mal varlığı hayat boyunca değişsin mi (alıp satabilsinler mi),
   yoksa hayat başında belirlenip sabit mi kalsın?
4. Velayet sistemi nasıl genişlesin: koruyucu aile, yurt, taşınma?
   Ebeveyn kaybı okul ve ekonomiyi nasıl etkilesin?
5. Miras kalan ev, oyuncunun **taşındığı** ev olsun mu (Q-056 ile birlikte)?
6. Oyuncunun ölümünde mirası kime kalsın; gelecekte "çocuk olarak devam et"
   gibi bir kuşak sistemi düşünülüyor mu?

**Claude'un önerisi (yalnızca öneri):** Vasiyet ve borç mirası ilk sürüm
için erken; kuşak sistemi düşünülüyorsa oyuncunun mirasının nereye gittiği
şimdiden kararlaştırılsın.

**Karara bağlananlar (D-037):**
- **Basitleştirilmiş oyun içi model**; gerçek miras hukukunun açıklaması olarak
  sunulmayacak.
- Miras **yalnızca ölenin gerçekten sahip olduğu** nakit ve varlıklardan;
  **aynı para veya eşya iki kez dağıtılamaz**.
- **Eş ve çocuklar öncelikli**; yoksa yakın aile. **Gerçek evlilik kaydı yokken
  sevgili eş gibi değerlendirilmeyecek.**
- Kişilerin mal varlıkları **hayat boyunca değişebilecek** şekilde tasarlanacak;
  miras ilk doğumda donmuş bir servet listesine dayanmayacak (ayrı küçük paket).
- **Vasiyet, borç mirası ve miras vergisi şimdilik eklenmeyecek.**
- **Miras kalan evin sahibi oyuncu olabilir, ama otomatik taşınma yok.**
- Çocuk yaşta hanede yetişkin kalmazsa önce **hayatta olan uygun aile büyüğü**
  bakım veren olur; kimse yoksa oyuncu açıklamasız bırakılmaz, **açık bir
  alternatif bakım durumu** oluşturulur. Aile üyeleri silinmez, **sahte akrabalık
  üretilmez**.
- Oyuncu ölünce hayat özeti **"Geçmiş Hayatlar" arşivine** güvenle kaydedilebilecek
  altyapı planlanacak; **yeni hayat başlatmak geçmiş özeti habersizce silmeyecek**.
- **"Çocuğum olarak devam et" kuşak sistemi şimdi eklenmeyecek.**

**Geçici kalan (denge kararı değil):** miras tutarları, paylaşım oranları ve
bakım veren seçim kuralının ayrıntıları.

**Uygulama notu:** Geçmiş Hayatlar arşivi, bakım durumu alanı, eş payının
evlilik kaydına bağlanması ve NPC mal varlığının hayat boyunca değişmesi
uygulandı. Vasiyet, borç mirası, miras vergisi ve kuşak sistemi eklenmedi.

**Varsayılan işlem:** Bütün sayılar geçici; `DECISIONS.md`'ye eklenmedi.

### Q-060 — Konut: taşınma, kira geliri ve şehir
**Durum:** **Kısmen karara bağlandı** (D-043). İlkeler kesinleşti; sayısal denge geçici. **Kaynak:** `app/lib/domain/economy/housing.dart`, `app/lib/ui/screens/sections/assets_screen.dart`. **Bağlantılı:** Q-055, Q-056.

**Kodun şu anki geçici çözümü (hepsi `prototypeOnly`):**
- Taşınma yaşı 18; taşınma masrafı 12.000 ₺ (tek seferlik).
- Kira geliri konut değerinin yılda **%4,5'i**; her yıl **%12** ihtimalle
  kiracı bulunamaz ve o yıl gelir gelmez.
- Oturulan ev kiraya verilemez; kiraya verilmiş eve taşınılamaz.
- Emlakçıda 20 şehirden biri seçilerek konut alınabilir; başka şehirdeki
  kendi evine taşınmak oyuncunun yaşadığı şehri değiştirir.
- Aile evine dönüş yalnızca hanede hayatta bir yetişkin varsa mümkündür.

**Karar soruları:**
1. Kira getirisi %4,5 doğru mu? Konut türüne göre değişmeli mi (küçük daire
   daha yüksek getiri, villa daha düşük)?
2. Kiracı bulunamama ihtimali kalsın mı; kiracı kaynaklı olaylar (hasar,
   kira ödememe) eklensin mi?
3. Taşınma masrafı sabit mi kalsın, şehirler arası taşınmada artsın mı?
4. Şehir değiştirmek başka neleri etkilemeli (iş, okul, arkadaşlar)?
   Şu an yalnızca "yaşanan şehir" bilgisi değişiyor.
5. Kiralık evde yaşarken kira ayrı bir kalem olarak mı gösterilsin (gider
   dökümü buna hazır), yoksa toplam gider yeterli mi?
6. Aile evinden ayrılmanın ilişkilere etkisi olmalı mı?

**Claude'un önerisi (yalnızca öneri):** Kiracı olayları ve şehir değiştirmenin
iş/okul etkisi ayrı bir pakete bırakılsın; önce mevcut akışın oyunda nasıl
hissettirdiği görülsün.

**Varsayılan işlem:** Bütün sayılar geçici; `DECISIONS.md`'ye yalnızca ilkeler
yazıldı.

### Q-061 — Hastalık ve kaza krizleri
**Durum:** **Kısmen karara bağlandı** (D-044). İlkeler kesinleşti; sayısal denge geçici. **Kaynak:** `app/lib/data/health_crisis_catalog.dart`, `app/lib/domain/life/health_crisis_engine.dart`. **Bağlantılı:** Q-058.

**Kodun şu anki geçici çözümü (hepsi `prototypeOnly`):**
- Altı kriz: ateşli hastalık, trafik kazası, kalp uyarısı, iş kazası,
  zatürre, evde düşme. Her birinin yaş aralığı ve iki seçeneği var.
- Yıllık kriz ihtimali: 16 yaş altı %0,3 · 16-40 %0,7 · 40-60 %1,8 ·
  60-75 %3,0 · 75+ %4,0; sağlık düştükçe artar (en çok iki kat).
- İki kriz arasında en az **4 yaş** olur; ekranda kriz varken yenisi çıkmaz.
- Atlatma ihtimali %72-95 arasında; tedavi seçeneği ihtimali artırır,
  ertelemek düşürür. Tedavi bedelleri 3.000-40.000 ₺.
- Ölçüm (5.000 hayat): hayat başına **1,01** kriz, hayatların **%13,1'i**
  krizle sonuçlanıyor. Temel ölüm eğrisi bunu dengelemek için **0,8** ile
  çarpıldı.

**Karar soruları:**
1. Kriz sayısı (hayat başına ~1) ve ölümlü sonuç oranı (%13) doğru mu?
2. Krizler yalnızca oyuncuda mı olsun, yakınlar için de olay çıksın mı
   (ör. "annen hastalandı, tedaviye katkıda bulunur musun")?
3. Kriz sonrası kalıcı etki olmalı mı (sakatlık, kronik hastalık)?
4. Sağlık sigortası / devlet desteği gibi bir kalem gelsin mi (D-033 ile)?
5. Krizler meslekle ilişkili olmalı mı (iş kazası yalnızca çalışanlarda)?
6. Metin sayısı altı ile yeterli mi; yaşa göre daha çeşitli metin gerekir mi?

**Claude'un önerisi (yalnızca öneri):** İş kazası yalnızca çalışan
karakterlerde çıksın; yakınların hastalığı, para/ilişki kararı içerdiği için
güçlü bir içerik olur ve ayrı bir pakette ele alınabilir.

**Varsayılan işlem:** Bütün sayılar geçici; `DECISIONS.md`'ye yalnızca ilkeler
yazıldı.

### Q-062 — Kuşak sistemi ve ön koşulu: evlilik ve çocuk
**Durum:** **Ön koşullar kodlandı (E1 evlilik, E2 çocuklar); kuşak devamı (E3) hâlâ karar bekliyor.** **Kaynak:** `docs/GENERATION_PROPOSAL.md`. **Bağlantılı:** Q-059 (D-037), Q-058.

**Sorun:** "Çocuğum olarak devam et" kuşak sistemi, oyuncunun **çocuğu
olmasını** gerektirir. Oyunda şu an **evlilik, birliktelik ve çocuk sistemi
yok**: yalnızca sevgili/eski sevgili bağı var (D-029, D-030) ve miras
kurallarında "gerçek evlilik kaydı yokken sevgili eş sayılmaz" deniyor
(D-037). Yani kuşak sistemi doğrudan kodlanamaz; önce evlilik ve çocuk
tasarımı gerekir ve bu **oyun tasarımı kararıdır**, Claude'un uyduracağı bir
şey değildir.

**Karar soruları (ayrıntılı öneri `docs/GENERATION_PROPOSAL.md` içinde):**
1. Evlilik/birliktelik oyunda nasıl kurulacak (sevgiliden evliliğe geçiş,
   yaş ve ilişki koşulları, düğün, boşanma)?
2. Çocuk nasıl olacak (isteğe bağlı mı, ilişki durumuna bağlı mı, kaç
   çocuk, evlat edinme)?
3. Çocuklar NPC olarak nasıl büyüyecek; okul/meslek sistemine girecek mi?
4. Oyuncu ölünce miras çocuklara nasıl dağıtılacak (D-037 paylaşımıyla)?
5. "Çocuğum olarak devam et" seçeneği ne zaman sunulacak; çocuk yokken ne
   olacak? Yeni hayat, mevcut dünyanın devamı mı yoksa tamamen yeni bir
   dünya mı olacak?
6. Devam edilen hayatta neler taşınacak (miras, ev, aile bağları, Ün)?

**Claude'un önerisi (yalnızca öneri):** Önce **evlilik + çocuk** paketi
tasarlanıp kodlansın; kuşak devamı onun üstüne küçük bir paket olarak gelsin.
Geçmiş Hayatlar arşivi (D-037) bu geçiş için gereken altyapının bir kısmını
zaten sağlıyor.

**Varsayılan işlem:** Faho'nun "kodlamaya başla" talimatıyla **yalnızca E1
(evlilik) ve E2 (çocuklar)** kodlandı; bütün sayısal değerler `prototypeOnly`
işaretli ve ayrıntıları Q-063/Q-064'te karar bekliyor. **E3 (çocuğum olarak
devam et) kodlanmadı**: yukarıdaki 5. ve 6. sorular yanıtlanmadan hangi
kişilerin, hangi varlıkların ve hangi ilişkilerin yeni kuşağa taşınacağı
uydurulmaz.

### Q-063 — Evlilik kurallarının ayrıntıları
**Durum:** Kodlandı, **karar bekliyor** (bütün değerler `prototypeOnly`). **Kaynak:** Paket E1. **Bağlantılı:** Q-062, Q-055 (gider), Q-059 (miras).

**Şu an kodda olan (geçici) kurallar:**
- Evlenmek sevgiliyle olur; kişi kaydı **silinmez**, aynı kimlik `es` olur.
- Koşullar: iki taraf da **18 yaş**, yakınlık **en az 60**, nikâh masrafı
  **60.000 ₺** (cüzdanda yoksa düğme yerine gerekçe yazılır).
- Evlenmek **kendi haneni kurmaktır**: eş haneye katılır, oyuncu artık
  "ailenin yanında" sayılmaz ve kirada gideri öder (D-033/D-043).
- Boşanmada eş **aynı kimlikle** `eskiEs` olur; nakdin **%25'i** eşe kalır.
  Eşya ve mülk paylaşımı **yoktur**; çocuklar oyuncunun hanesinde kalır.
- Eş vefat edince kayıt **dul** durumuna geçer, silinmez; miras D-037'ye
  göre işler (çocuk yoksa tamamı, varsa %25 eşe).
- Eski eşle etkileşimler kapalıdır (eski sevgilideki gibi, gerekçe yazılı).

**Karar soruları:**
1. Evlenme yaşı, yakınlık eşiği ve düğün masrafı bu değerlerde kalsın mı?
2. Evlenme teklifi her koşulda kabul mü edilsin, yoksa yakınlığa bağlı bir
   ret ihtimali olsun mu?
3. Boşanmada mal paylaşımı olacak mı (ev, araç, birikim) ve oranı ne olsun?
4. Eşin geliri hane bütçesine katılsın mı (şu an eş kendi giderini
   karşılıyor sayılıyor, oyuncunun bütçesine katkı vermiyor)?
5. Dul veya boşanmış karakter yeniden evlenebilsin mi? **Şu an açıkça
   kapalı**: ikinci evlilik, ilk evlilik kaydının üzerine yazmak anlamına
   geleceği için engellendi ve gerekçesi ekranda yazılıyor. Açılacaksa
   evlilik kaydının **liste** hâline gelmesi gerekir.
6. Eski eşle hangi etkileşimler açık kalsın (özellikle ortak çocuk varsa)?
7. Evlenince eşin soyadı değişsin mi? **Şu an değişmiyor**: kimsenin kaydı
   değiştirilmiyor, çocuk ise babanın soyadını alıyor (prototypeOnly).

**Claude'un önerisi (yalnızca öneri):** Eşin gelirinin ortak bütçeye
katılması ekonomiyi belirgin biçimde değiştirir; önce 4. sorunun yanıtı
gelsin, sonra denge yeniden ölçülsün.

**Varsayılan işlem:** Hiçbir değer `DECISIONS.md`'ye kalıcı kural olarak
yazılmadı.

### Q-064 — Çocuk kurallarının ayrıntıları
**Durum:** Kodlandı, **karar bekliyor** (bütün değerler `prototypeOnly`). **Kaynak:** Paket E2. **Bağlantılı:** Q-062, Q-063.

**Şu an kodda olan (geçici) kurallar:**
- Çocuk **isteğe bağlıdır**: kendiliğinden olmaz, eş kartındaki eylemle olur.
- Koşullar: evli olmak, iki taraf da 18 yaş, çiftteki kadın **45**, erkek
  **60** yaşına kadar; aynı yıl ikinci bebek yok; en fazla **4 çocuk**;
  doğum masrafı **20.000 ₺**.
- Çocuk kaydı diğer kişilerle **aynı** yapıdadır: kalıcı kimlik, yaş, hane,
  ölüm, miras. Ayrı bir "çocuk sistemi" kurulmadı (D-038).
- Hanedeki her **18 yaş altı** çocuk için yıllık gider kalemi eklenir
  (taban 24.000 ₺ + gelirin %3'ü, çocuk sayısıyla çarpılır).
- Çocuk **25 yaşında** haneden çıkar; kaydı silinmez, görüşülmeye devam
  edilir ve gider kalemi sona erer.
- Çocukla etkileşimler: vakit geçir, sohbet, hediye ver. Çocuktan para ya
  da hediye istemek açılmadı.

**Karar soruları:**
1. Yaş sınırları, en fazla çocuk sayısı ve doğum masrafı böyle kalsın mı?
2. Evlat edinme olacak mı (aynı cinsiyetteki çiftler ve ileri yaş için tek
   yol budur; şu an ikisi de kapalı ve gerekçesi yazılıyor)?
3. Evlilik dışı çocuk mümkün olsun mu?
4. Çocuk gideri (24.000 ₺ + %3) doğru büyüklükte mi; okul/üniversite gibi
   ayrı kalemler gelsin mi?
5. Çocuklar okul ve meslek sistemine girsin mi, yoksa yalnızca yaş ve
   meslek etiketiyle mi büyüsünler (şu an ikincisi)?
6. Çocuğun evden çıkma yaşı 25 doğru mu; evlenince çıkma gibi bir kural
   olsun mu?

**Claude'un önerisi (yalnızca öneri):** Çocukların okul sistemine girmesi
büyük bir paket olur; önce yaş + meslek etiketiyle büyümeleri yeterli.

**Varsayılan işlem:** Hiçbir değer `DECISIONS.md`'ye kalıcı kural olarak
yazılmadı; ileri yaş ve aynı cinsiyet çiftlerinde uydurma bir kural
uygulanmadı, gerekçe yazıldı.

**Paket 1 entegrasyon turunda düzeltilenler (kural değişikliği değil,
tutarlılık):** eş ve çocuk kaybının duygusal ağırlığı (daha önce uzak bir
tanıdıkla aynıydı), evli karakterin karşısına yeni tanışma olayı çıkması,
`livesWithFamily` ölçütünün eşi "aile" sayması, çocuğun soyadı ve geçmiş
hayat arşivinde aile bilgisinin hiç tutulmaması.

### Q-065 — Şehir değişiminin okul, iş ve çevreye etkisi
**Durum:** Altyapı kuruldu, **karar bekliyor** (değerler ve kurallar `prototypeOnly`). **Kaynak:** Paket 3. **Bağlantılı:** Q-060 (taşınma), Q-063.

**Şu an kodda olan (geçici) davranış:**
- Doğum şehri hiç değişmiyor; yaşanan şehir taşınmayla güncelleniyor.
- Okullar ve sınıflar artık **şehre bağlı** kimliklerle kuruluyor; oyuncu
  aynı anda iki okulda görünemiyor.
- Şehir değiştiren **öğrenci** için okul nakli akışı var: yeni şehirde yeni
  sınıf ve öğretmen tanınıyor, eğitim geçmişi (sınıf, lise alanı, puanlar)
  korunuyor, eski okulun kişileri **silinmiyor** — yalnızca güncel
  listelerden düşüyorlar.
- Başka şehirde kalan okul/hayat arkadaşı gündelik listelerde görünmüyor
  ama kaydı ve yakınlığı duruyor; **yakın aile** (anne, baba, kardeş, eş,
  çocuk) şehir değişse de erişilebilir kalıyor.
- İşin şehri kaydediliyor ve ekranda gösteriliyor. **Şehir değişince işe
  kendiliğinden son verilmiyor**; yalnızca "işin hâlâ X şehrinde" satırı
  yazılıyor.

**Karar soruları:**
1. Şehir değiştiren çalışanın işi ne olmalı (devam, uzaktan, istifa,
   şehirler arası iş piyasası)?
2. Reşit olmayan oyuncu **ailesiyle birlikte** taşınabilmeli mi? Şu an
   taşınma 18 yaş koşuluna bağlı olduğu için okul nakli akışı pratikte
   yalnızca ileride gelecek bir "aile taşınması" mekaniğiyle tetiklenir.
3. Üniversite öğrencisi şehir değiştirirse ne olmalı (nakil, kayıt
   dondurma, uzaktan)?
4. Başka şehirdeki yakın arkadaşla yeniden karşılaşma olayı olsun mu?
5. Şehirlerin birbirinden farkı olacak mı (kira, maaş, iş çeşitliliği)?
   Şu an şehirler yalnızca isim düzeyinde farklı.

**Claude'un önerisi (yalnızca öneri):** Şehirler arası ekonomik fark
(kira/maaş) büyük bir denge işidir; önce 1. ve 2. sorular yanıtlansın.

**Varsayılan işlem:** Hiçbir otomatik işten çıkarma veya okul silme kuralı
uydurulmadı; `DECISIONS.md`'ye yeni kural yazılmadı.

### Q-066 — Olay yoğunluğu, tekrar aralıkları ve içerik dengesi
**Durum:** Ölçüldü ve ayarlandı, **karar bekliyor** (bütün sayılar `prototypeOnly`). **Kaynak:** Paket 4. **Bağlantılı:** Q-005 (olaysız yaşlar).

**Ölçüm (300 hayat, `app/tool/event_report.dart`):**
- Katalog 41 → **74** olay; yaş başına olay oranı %82,8 → **%95,7**.
- 0-4 yaş aralığında **hiç olay yoktu**; şimdi %98.
- 80 yaş üstünde oran hâlâ düşük (%25-61). O yaşa ulaşan hayat sayısı da
  azalıyor, ama içerik de sınırlı.
- En sık olay hayat başına 9,92 → **3,83**.

**Şu an kodda olan (geçici) değerler:**
- Tekrar aralıkları (`minAgeGap`): aile akşam sofrası 8, aile sitemi 9,
  bayram ziyareti 9, aile ziyareti 9, sağlık kontrolü 6, eşle anma 15,
  eşin iş kararı 18, çocuk karnesi 5, bebek gece ağlaması 3.
- Testte bir olayın tek hayatta **8 kereden fazla** çıkmaması kilitlendi.

**Karar soruları:**
1. Her yaşta olay çıkması mı iyi, yoksa sessiz yıllar da olmalı mı?
   (Şu an %95,7; yani neredeyse her yıl bir olay var.)
2. 80 yaş üstü için ayrı bir içerik paketi gerekir mi?
3. Tekrar aralıkları doğru mu; bayram gibi doğal tekrar eden olaylar daha
   sık dönebilir mi?
4. Nostalji-güncel dengesi: yeni olaylarda mahalle/sokak ağırlığı fazla mı?
5. Olayların yaş evrelerine dağılımı (bebeklik 5, çocukluk 4, ergenlik 4,
   genç yetişkinlik 6, 30+ 14) doğru ağırlıkta mı?

**Paket F1 güncellemesi (ölçüm, karar değil):** katalog **113 olaya**
çıktı, yaş başına oran **%98,5** oldu; 80 yaş üstündeki boşluk kapatıldı
(%63/%47/%34/%30 → %93/%84/%81/%83). Bu, 1. sorunun cevabını daha da
aciliyetli hâle getiriyor: **neredeyse her yıl bir olay çıkıyor.** Sessiz
yıl istenirse bu bir ayar meselesidir, içerik silmeyi gerektirmez.

**Claude'un önerisi (yalnızca öneri):** Sessiz yıllar oyunun temposu için
iyi olabilir; %95 yerine %75-85 hedeflenip aradaki fark "yaş aldın" özet
ekranıyla doldurulabilir. Bu bir tasarım kararıdır, değiştirilmedi.

**Varsayılan işlem:** Yalnızca ölçümle görülen açık boşluklar (0-4 yaş,
ileri yaş, spam tekrar) kapatıldı; `DECISIONS.md`'ye yeni kural yazılmadı.

### Q-067 — Kuşak devamı: neyin taşınacağı ve kaç kuşak
**Durum:** Kodlandı, **karar bekliyor** (bütün değerler ve taşıma kuralları `prototypeOnly`). **Kaynak:** Paket E3 ("kuşak sistemini kodla" talimatı). **Bağlantılı:** Q-062 (kuşak sistemi), Q-063 (evlilik), Q-064 (çocuk), Q-059 (miras).

**Şu an kodda olan (geçici) davranış — `GenerationContinuation`:**
- Seçenek yalnızca oyuncu vefat ettiğinde ve **hayatta bir çocuğu varsa**
  hayat özeti ekranında çıkar. Çocuk yoksa hiç gösterilmez (D-038).
- Oyuncu **hangi çocukla** devam edeceğini seçer (birden fazlaysa liste).
- Taşınanlar: çocuğun kendi kaydı (ad, yaş, cinsiyet, şehir), sağ kalan
  ebeveyn (eski eş, boşanmış olsa da **anne/baba** olur), diğer çocuklar
  (**kardeş**), eski oyuncunun anne-babası (**büyükanne/büyükbaba**) ve
  kardeşleri (**teyze/dayı/hala/amca**).
- Taşınmayanlar: eski oyuncunun arkadaşları, öğretmenleri, sınıf
  arkadaşları, romantik geçmişi, hikâye izleri, olay geçmişi, evcil
  hayvanları (yaşları tutulmadığı için ölümsüz hayvan üretirdi). O hayat
  **Geçmiş Hayatlar arşivinde** durur; kayıt şişmez.
- Eski oyuncu kayıtta **vefat etmiş ebeveyn** olarak kalır; mesleği son
  işinden yazılır, mal varlığı dağıtıldığı için boştur.
- Miras: sağ kalan eş varsa nakdin %25'ini alır (Q-059 ile aynı oran),
  kalan hayattaki çocuklara eşit bölünür. Eşyalar bölünmez, sırayla
  dağıtılır; devam eden çocuğa geçenler **aynı eşya kimliğiyle** geçer,
  başkasına düşenler o kişinin mal varlığına yazılır. **Borç miras
  kalmaz** (eksi bakiye 0 sayılır). Aynı miras iki kez dağıtılmaz.
- Ün, meslek, ehliyet, sosyal medya ve eğitim geçmişi taşınmaz.
- Yeni oyuncunun özellikleri (görünüş, zekâ, karizma...) **yeniden
  çizilir**; ebeveynden özellik aktarımı yoktur.
- Eğitim yaşa göre kurulur: 6 yaş altı okula başlamamış, 6-17 yaşına uygun
  sınıfta, 18 ve üstü lise mezunu.
- Taşınan kişilerin yakınlık puanı nötre (55) doğru çekilir: eski
  oyuncunun yakınlığı yeni kuşağın yakınlığı sayılmaz ama sıfırlanmaz da.
- Kuşak sayacı (`GameState.generation`) tutulur, arşivde rozetle görünür;
  **üst sınır yoktur**.

**Karar soruları:**
1. Devam edilecek çocuğu oyuncu mu seçmeli, yoksa en büyük çocuk mu
   otomatik devralmalı?
2. Dünyanın ne kadarı taşınmalı? (Şu an yalnızca kan bağı ve sağ kalan
   ebeveyn taşınıyor; eski oyuncunun yakın arkadaşları da taşınsın mı?)
3. Kaç kuşak sürebilmeli? Sınır olmalı mı?
4. Çocuk ebeveynden özellik (zekâ, görünüş, sağlık) devralmalı mı?
5. Yetişkin çocukla devam edilince meslek ve eğitim gerçekten sıfırdan mı
   başlamalı? (Şu an 40 yaşında devam eden çocuk "lise mezunu, işsiz"
   oluyor; NPC'lerin eğitim/iş geçmişi tutulmuyor.)
6. Kuşak devam ederken eski hayatın evi/parası dışında **aile itibarı**
   gibi bir şey taşınmalı mı?
7. Küçük yaştaki çocukla devam edilebilmeli mi, yoksa asgari bir yaş mı
   olmalı? (Şu an her yaştaki hayattaki çocuk seçilebiliyor; 8 yaşındaki
   çocukla devam edilirse mevcut bakım kuralları devreye giriyor.)
8. Arşivde kuşaklar nasıl gösterilsin? (Şu an yalnızca "2. kuşak" rozeti
   var; soy ağacı ekranı ayrı bir iş.)

**Claude'un önerisi (yalnızca öneri):** 5. madde en görünür boşluk; çocuk
NPC'lerine basit bir "eğitim/iş geçmişi" alanı eklenirse devam eden
oyuncunun geçmişi uydurulmadan taşınabilir.

**Varsayılan işlem:** `DECISIONS.md`'ye hiçbir kural yazılmadı; bütün
değerler `prototypeOnly` ve geri alınabilir.

### Q-068 — Arayüz cilası: günlük düzeni, para biçimi ve değer renkleri
**Durum:** Uygulandı, **karar bekliyor** (hepsi görünüm tercihidir ve geri alınabilir). **Kaynak:** Paket F2 ("oyunu güncelleştir ve güzelleştir" talimatı). **Bağlantılı:** `docs/PROTOTYPE_UI.md`.

**Şu an ekranda olan (geçici) düzen:**
1. **Hayat günlüğü yaşa göre kümelendi.** Eskiden her satırın solunda yaş
   tekrar yazılıyordu ("49 yaş" arka arkaya on kez). Artık bir yıl tek
   kartta toplanıyor, içinde bulunulan yıl "bu yıl" etiketiyle öne
   çıkıyor ve her satırın başında konusunu (aile/kişisel/yaş) gösteren
   küçük bir simge var. Uzun hayatlarda kartlar tembel kuruluyor.
2. **Para biçimi:** tutarlar Türkçe binlik ayırıcıyla yazılıyor
   (`163400 ₺` → `163.400 ₺`). Hem ekranda hem hayat günlüğünde.
3. **Karakter değerleri renkleniyor:** 30 altı uyarı rengi, 30-54 arası
   pirinç, 55 üstü çini yeşili. Çubuklar değer değişince yumuşak geçiyor.
4. **Olay penceresi:** kategori simgesi eklendi, seçenekten sonuca geçiş
   yumuşatıldı.
5. **Açılış ekranı:** ortadaki boşluğa oyunu üç satırda anlatan bir kart
   kondu.

**Bu turda düzeltilen gerçek hata:** Türkçe büyük harf. `toUpperCase()`
"Aile" kelimesini "AILE" yapıyordu (doğrusu "AİLE"); "işçi" de "Işçi"
oluyordu. Artık Türkçe kuralına uygun çevriliyor.

**Paket F3 eki:** karanlık temada "iyi" (çini) ile "orta" (pirinç)
renkleri birbirine karışıyordu; koyu zemin için ayrı tonlar tanımlandı ve
karanlık mod ekran görüntüsü testine eklendi. Karanlık modun bütün
ekranlarda gözden geçirilmesi ayrı bir iştir.

**Karar soruları:**
1. Günlük yaşa göre kümelenmiş hâliyle mi kalsın, yoksa düz akış mı
   tercih edilir?
2. Değer renkleri eşikleri (30/55) uygun mu? Renk körlüğü için yalnızca
   renge dayanmayan bir işaret gerekir mi?
3. Para biçimi "163.400 ₺" doğru mu; kuruş veya kısaltma (163,4 B ₺)
   istenir mi?
4. Açılış kartındaki üç satır bu şekilde mi kalsın?

**Varsayılan işlem:** Hepsi görünüm katmanındadır; oyun kuralı
değişmedi, `DECISIONS.md`'ye bir şey yazılmadı.

### Q-069 — Çocuğun arka plan gelişiminin sayıları
**Durum:** Kural **karara bağlandı (D-045)**; sayılar **karar bekliyor** (`prototypeOnly`). **Kaynak:** Paket 1. **Bağlantılı:** Q-064 (çocuk kuralları), Q-067 (kuşak devamı).

**Karar gereken sayılar:** liseyi bitirme ve üniversiteye başlama olasılığının zekâya bağlanma eğrisi, üniversiteyi bitirme şansı, iş bulma olasılığı ve iş seçiminde eğitim/zekâ ağırlığı, NPC'nin yıllık birikim oranı ve yaşam gideri, ilgi alanı edinme sıklığı, kaç yaşam geçmişi satırının saklanacağı.

**Varsayılan işlem:** Bütün değerler `prototypeOnly` sabitleriyle tek yerde tutuldu; değiştirmek tek satırlık iştir.


**Paket 7 güncellemesi (2026-09-21).** Kendi hayatı izlenen kişi (çocuk, kuşak adayı) artık **liseye geçtiği yıl alanını seçer**; alan zekâ/karizma ve küçük bir rastgelelikten türetilir, bir daha değişmez ve kuşak devamında oyuncunun eğitim kaydına taşınır. Üniversite bölümü seçiminde alanla uyumlu bölümlerin ağırlığı `prototypeOnly` **%70**. Ayrıca yaşlanmanın dış görünüşe etkisi (D-051) bu kişilere de **oyuncuyla aynı kuralla** işler.

**Ek karar soruları:**
1. NPC'nin lise alanı oyuncudaki yerleştirme sınavıyla aynı mantığa mı bağlanmalı, yoksa bu sadeleştirme yeterli mi?
2. Alanın bölüm tercihine etkisi %70 uygun mu?
3. NPC'nin dış görünüşü oyuncu ekranlarında ne kadar görünür olmalı?

### Q-070 — Özellik aktarımının formülü
**Durum:** Kural **karara bağlandı (D-046)**; sayılar **karar bekliyor** (`prototypeOnly`). **Kaynak:** Paket 2.

**Karar gereken sayılar:** ebeveyn ortalamasının ağırlığı ile rastgele payın ağırlığı, sapma aralığı, hangi özelliklerin aktarılacağı (şu an zekâ, görünüş, sağlık, karizma; mutluluk aktarılmıyor), tek ebeveyn bilindiğinde kullanılacak yol, alt/üst sınırların (ör. 10-90) dar mı geniş mi olacağı.

### Q-071 — Evlilik dışı çocuk: velayet, hane ve görüşme
**Durum:** Kural **karara bağlandı (D-047)**; ayrıntılar **karar bekliyor**. **Kaynak:** Paket 3A.

**Karar gereken:** çocuk hangi hanede büyür (şu an prototipte oyuncunun hanesinde), sevgiliden ayrılınca çocukla bağ nasıl sürer, velayet sistemi olacak mı, evlilik dışı çocuğun gideri ve mirası farklı mı (şu an aynı), ikinci bir sevgiliden çocuk mümkün mü.

### Q-072 — Evlenme teklifi: kabul eşiği ve ret sonuçları
**Durum:** Kural **karara bağlandı (D-048)**; sayılar **karar bekliyor** (`prototypeOnly`). **Kaynak:** Paket 3B.

**Karar gereken sayılar:** teklif için asgari yakınlık, kabul olasılığı eğrisi, ilişki geçmişinin ağırlığı, ret sonrası yakınlık etkisi, aynı kişiye yeniden teklif için beklenecek yıl sayısı, reddin ilişkiyi bitirme ihtimali olup olmayacağı.

### Q-073 — Evlat edinme: uygunluk, masraf ve bekleme
**Durum:** Kural **karara bağlandı (D-049)**; ayrıntılar **karar bekliyor**. **Kaynak:** Paket 3C.

**Karar gereken:** asgari yaş ve gelir/birikim ölçütü, hane koşulu (kendi evi şart mı), başvuru ücreti ve masraf, başvurunun reddedilme olasılığı, evlat edinilen çocuğun yaş aralığı, bekleme süresi, en fazla kaç çocuk. Gerçek hukuk kuralları **iddia edilmedi**; ölçütler oyun içi ve geri alınabilir.

### Q-074 — Ölüm bildirimi ve cenaze masrafı
**Durum:** Kural **karara bağlandı (D-050)**; sayılar **karar bekliyor** (`prototypeOnly`). **Kaynak:** Paket 4.

**Karar gereken sayılar:** cenaze katkı tutarı (kişiye/varlığa göre değişsin mi), katkının ilişki ve mutluluk etkisi, hangi bağlar için bildirim çıkar (şu an eş, anne, baba, çocuk, kardeş), bildirim penceresinin hangi sırayla açılacağı.

**Paket 7 güncellemesi (2026-09-21).** Cenaze akışı iki adıma ayrıldı ve bildirim kapsamı genişletildi. Şu an kodda olan (geçici) davranış:
- **Katılmak ile katkıda bulunmak ayrı seçimlerdir.** Önce "Cenazeye katıl / Katılamıyorum", sonra katkı miktarı sorulur. Katkı vermemek katılmayı engellemez; katılamamak katkıda bulunmayı engellemez.
- Katılmanın mutluluk etkisi **+2**, katılamamanın **−3**, katkının **+3** (`prototypeOnly`). Etkiler toplanır ve yalnızca gerçekten uygulanan kadarı yazılır.
- Cenazede bulunmak hayattaki **kan bağlarının** yakınlığını **+2** artırır; arkadaşlık gibi kan bağı olmayan bağlar etkilenmez.
- Bildirim kapsamı: eş, anne, baba, çocuk, kardeş, anneanne/babaanne/dede **her hâlükârde**; sevgili, arkadaş, eski eş, teyze/dayı/hala/amca ise yalnızca yakınlık **≥ 60** ise (`prototypeOnly`).

**Ek karar soruları:**
1. Katılım/katılamama mutluluk etkileri (+2 / −3) uygun mu; katılamamanın bir etkisi olmalı mı?
2. Cenazede bulunmanın yakınlık etkisi (+2) yalnızca kan bağlarına mı işlemeli, yoksa yakın arkadaşlara da mı?
3. Bildirim eşiği 60 uygun mu; bağ türüne göre farklı eşikler mi olmalı?
4. Oyuncunun cenazeye katılamamasının bir gerekçesi (şehir, sağlık, hapis) olmalı mı, yoksa serbest seçim mi kalmalı?

### Q-075 — Yaşlanmanın görünüşe etkisi
**Durum:** Kural **karara bağlandı (D-051)**; sayılar **karar bekliyor** (`prototypeOnly`). **Kaynak:** Paket 5.

**Karar gereken sayılar:** düşüşün başladığı yaş, yaş aralıklarına göre yıllık düşüş miktarı, karakterden karaktere değişen payın büyüklüğü, sağlığın ve bakım aktivitelerinin etkisi, alt sınır (görünüş en fazla ne kadar düşebilir).

### Q-076 — Vasiyet: mirasçı payı ve koşullar
**Durum:** Kural **karara bağlandı (D-052)**; sayılar **karar bekliyor** (`prototypeOnly`). **Kaynak:** Paket 6 (Faho'nun "mirasçı olarak bir çocuğumu seçebileyim" talimatı). **Bağlantılı:** Q-059 (miras), Q-067 (kuşak devamı).

**Şu an kodda olan (geçici) davranış:**
- Mirasçı seçimi Aktiviteler → **Vasiyet** sayfasından yapılır; seçim isteğe bağlıdır, değiştirilebilir ve kaldırılabilir.
- Seçilen çocuk, çocuklara kalan nakdin **%60**'ını alır; kalan %40 diğer çocuklar arasında eşit bölünür. Çocuk tekse zaten tamamını alır.
- Eşya paylaşımında mirasçı **ilk sıradadır** (sıralı dağıtımda ilk payı o alır).
- Eşin payı (%25) korunur; vasiyet eşin payını azaltmaz.
- Seçilen çocuk vefat ederse seçim düşer ve miras eşit bölünür.
- Vasiyet, kuşak devamında yalnızca **önerilen** olarak işaretlenir; oyuncu başka çocuğu seçebilir.

**Karar soruları:**
1. Mirasçı payı %60 uygun mu; yoksa oran seçilebilir mi (ör. %50/%75/%100)?
2. Vasiyet eşin payını etkileyebilmeli mi? (Şu an etkilemiyor.)
3. Birden fazla mirasçı seçilebilmeli mi, pay dağıtımı yapılabilmeli mi?
4. Vasiyetin bir masrafı veya yaş koşulu olmalı mı? (Şu an yok; yalnızca hayatta çocuk gerekiyor.)
5. Vasiyet değişikliği çocuklarla ilişkiyi etkilemeli mi (ör. dışlanan çocuğun yakınlığı düşsün mü)? Şu an **hiçbir ilişki etkisi yok**.
6. Eş, kardeş veya vakıf gibi çocuk dışı mirasçılar eklenmeli mi?

**Varsayılan işlem:** Hiçbir ilişki cezası veya masraf uydurulmadı; oran tek sabitte tutuldu.

### Q-077 — Menü arayüzünün rengi ve düğme dili
**Durum:** Yön **Faho tarafından istendi** ("menü UI'larını güzel hale getir, tasarımı biraz güncel ve renkli yap"); **kesin palet karar bekliyor** (`prototypeOnly`). **Kaynak:** Paket 8 (arayüz yenileme). **Bağlantılı:** `docs/PROTOTYPE_UI.md` §2 (onaylanmış görsel yön: modern + ölçülü nostaljik).

**Şu an kodda olan (geçici) çözüm:**
- Kimlik renkleri korundu ama canlandırıldı: nar `#B53142`, çini `#12897A`, pirinç `#D69A2B`, kâğıt `#FBF7F0`.
- Menülere **renk ailesi** eklendi (`BirOmurAccents`): nar, çini, pirinç, mor, mavi, yeşil, turuncu, gül. Her rengin açık ve koyu tema için ayrı tonu var.
- Her menü satırı kendi rengini taşıyor: degradeli ikon kutusu, renkli sayaç rozeti, yumuşak gölge ve ince renkli çerçeve.
- Bölüm başlığının altında o bölümün rengiyle kısa bir şerit; geri dönüş satırı renkli bir hap.
- Alt gezinme çubuğu degrade zemin + üstte ince pirinç çizgi; seçili sekmenin ikonu renkli hapın içinde; **Yaş Al** degradeli ve hafif parıltılı.
- Düğmeler: köşe yarıçapı 18, daha kalın yazı, hafif yükseklik (basılınca düzleşir), nötr gölge.
- Renk **hiçbir yerde tek bilgi taşıyıcısı değil**: bağ türü, sayaç, hane ve durum bilgisi yazıyla da veriliyor.

**Karar soruları:**
1. Sekiz renkli aile fazla mı; menü başına sabit renk yerine tek vurgu rengi mi tercih edilir?
2. Hangi bölüm hangi rengi alsın? (Şu an: Okul mavi, Meslek mor, Varlıklar yeşil, İlişkiler gül, Aktiviteler turuncu, Kumarhane nar, Vasiyet pirinç.)
3. Kişi kartlarının bağ türüne göre renklenmesi doğru mu, yoksa herkes aynı renk mi olsun?
4. Canlandırılan kimlik renkleri (özellikle nar ve pirinç) onaylanıyor mu, yoksa eski sönük tonlara mı dönülsün?
5. Yazı tipi hâlâ sistem yazı tipi; özel bir yazı tipi istenir mi?

**Varsayılan işlem:** Renk değerleri tek dosyada (`app/lib/ui/theme/bir_omur_theme.dart`) toplandı; istenirse tek commit ile geri alınabilir. Alt menü sırası ve hiçbir metin değiştirilmedi.

### Q-078 — Meslekte ilerleme: görev basamakları, zam ve işten çıkarılma
**Durum:** Yön **Faho tarafından istendi** ("oyuncu yıllarca aynı maaşı alan, hiç değişmeyen bir karakter olarak kalmasın"); **sayılar karar bekliyor** (`prototypeOnly`). **Kaynak:** Paket 9. **Bağlantılı:** Q-048 (maaş ve iş koşulları), Q-065 (şehir değişince iş).

**Şu an kodda olan (geçici) çözüm:**
- Her meslekte **üç görev basamağı** var (ör. Mağaza çalışanı → Kıdemli mağaza çalışanı → Mağaza sorumlusu). Meslek kataloğu büyütülmedi, yalnızca unvan eklendi.
- **Zam:** işte en az 1 yıl, iki zam arası 2 yıl, yılda bir talep. Kabul edilirse maaş **%8** artar.
- **Terfi:** işte en az 3 yıl, iki terfi arası 4 yıl. Kabul edilirse maaş **%22** artar ve unvan değişir.
- **Kabul ihtimali** garanti değil: taban %35 (zam) / %25 (terfi), işte geçen her yıl +%5, zekâ-karizma ortalaması en fazla +%25, "sorumluluk aldı" izi +%12, "işi savsakladı" izi −%15, her üst basamak −%8. Sonuç %5-%85 arasına sıkıştırılır.
- **İşten çıkarılma:** yılda %3,5 ihtimal, yalnızca 2 yıldan uzun süredir çalışanlarda ve iki kayıp arasında en az 8 yıl. Eski iş kaydı silinmez.
- **İş arkadaşı:** her işte 3 kişi, başlangıç yakınlığı 35; işten ayrılırken yakınlığı 60 ve üstü olanlar arkadaşa dönüşür.

**Karar soruları:**
1. Üç basamak yeterli mi; bazı mesleklerde daha fazla/az olmalı mı?
2. Zam %8 ve terfi %22 oranları uygun mu; meslek başına değişmeli mi?
3. İşten çıkarılma hiç olmalı mı? (Şu an ihtimal düşük ve uzun aralıklı.) Kıdem tazminatı gibi bir ödeme olmalı mı? **Şu an hiçbir tazminat ödenmiyor.**
4. Emeklilik yaşı ve emekli maaşı bu turda **eklenmedi**; ayrı bir karar konusu.
5. İş arkadaşı sayısı 3 uygun mu; işten ayrılınca arkadaşlığa dönme eşiği 60 doğru mu?
6. Şehir değişince işin ne olacağı hâlâ açık (Q-065); bu pakette değiştirilmedi.

**Varsayılan işlem:** Hiçbir sayı kalıcı kural sayılmadı; tamamı `CareerProgress` ve `job_catalog.dart` içinde tek tek `prototypeOnly` olarak işaretlendi.

### Q-079 — Sosyal medya geliri ve sponsorluk
**Durum:** Yön **Faho tarafından istendi** ("yeterli kitleye ulaşan oyuncu içeriklerinden oyun içi gelir elde edebilsin"); **sayılar karar bekliyor** (`prototypeOnly`). **Kaynak:** Paket 10. **Bağlantılı:** Q-050 (sosyal medya dengesi), Q-048 (maaş ve ekonomi).

**Şu an kodda olan (geçici) çözüm:**
- **Gelir eşiği:** o platformda en az **1.000 takipçi** ve hesabın en az **1 yaşında** olması. Yeni açılmış hesap, takipçisi olsa bile ödeme almaz.
- **Gelir garanti değil:** taban ihtimal %45, kitle büyüdükçe en fazla +%30. Takipçi kaybettiren ya da hiç ilgi görmeyen paylaşım **hiç** kazandırmaz.
- **Tutar:** her yeni takipçi 45 ₺ + mevcut kitlenin takipçi başına 0,9 ₺'si; içerik türüne göre 0,6-1,08 katsayı ve 0,7-1,3 dalgalanma. Tek paylaşımın üst sınırı 150.000 ₺.
- **Sponsorluk:** kurgusal 6 iş kolu (mahalle kafe zinciri, kırtasiye markası, sporcu içeceği üreticisi, bağımsız mobil oyun stüdyosu, çevrim içi kitap kulübü, elektronik mağazası). Gerçek marka adı, logo veya reklam ağı **kullanılmadı**; gerçek para/uygulama içi satın alma **yok**.
- Teklif yılda %35 ihtimalle gelir, aynı anda tek teklif bekler. Ücret = taban + (fazla takipçi × 1,2 ₺). Kabul edilirse **ödeme paylaşım yapılınca** işler; 2 yıl içinde paylaşım yapılmazsa anlaşma ödenmeden düşer.
- **Ün olayları:** Ün 3/4/5/8 eşiklerinde tanışma, yorum kalabalığı, etkinlik ve iş daveti olayları. Tanışmada kişi **yalnızca buluşma kabul edilirse** üretilir; hiçbiri romantik teklif değildir.

**Karar soruları:**
1. Gelir eşiği 1.000 takipçi uygun mu; platform başına farklı mı olmalı?
2. Takipçi başına 45 ₺ / 0,9 ₺ oranları ekonomiyle uyumlu mu? (Karşılaştırma: mağaza çalışanının yıllık maaşı 180.000 ₺.) Sosyal medya bir mesleğin yerini alabilmeli mi?
3. Tek paylaşım üst sınırı 150.000 ₺ uygun mu?
4. Sponsorluk ücretleri ve 2 yıllık süre uygun mu? Süresi dolan anlaşmanın bir bedeli (ün/itibar kaybı) olmalı mı? **Şu an hiçbir ceza yok.**
5. Sponsorluk reddedilirse yeni teklif ne kadar sonra gelmeli? (Şu an ertesi yıl gelebilir.)
6. Ün eşikleri (3/4/5/8) uygun mu; Ün düşebilmeli mi? **Şu an Ün düşmüyor.**

**Varsayılan işlem:** Gelir hesabı tek dosyada (`SocialIncome`) toplandı; hiçbir tutar kalıcı kural sayılmadı. Vergi, marka anlaşması sözleşmesi veya gerçek reklam entegrasyonu eklenmedi.

### Q-080 — Seyahat: ücretler, sınırlar ve kimlerle gidilebileceği
**Durum:** Yön **Faho tarafından istendi** ("Aktiviteler menüsüne gerçekten oynanabilir bir Seyahat alt menüsü ekle; kalıcı taşınmadan ayrı olacak"); **sayılar karar bekliyor** (`prototypeOnly`). **Kaynak:** Paket 11. **Bağlantılı:** Q-065 (şehir değişince iş), D-043 (taşınma).

**Şu an kodda olan (geçici) çözüm:**
- **Yolculuk türleri ve gidiş-dönüş ücretleri:** otobüs 2.200 ₺, tren 3.400 ₺, uçak 7.800 ₺, kendi arabasıyla 3.000 ₺. Yanına biri alınırsa ücret **1,8 katı**.
- **Kendi arabasıyla** seçeneği yalnızca gerçekten arabası olan, **otomobil ehliyeti** bulunan ve aracın kondisyonu **25'in üzerinde** olan oyuncuya açılır; yoksa hiç gösterilmez. Yola çıkınca araçtan 3 kondisyon düşer.
- **Yaş ve sıklık:** 16 yaşından itibaren, yılda en fazla 2 gezi.
- **Etkiler:** mutluluk +4…+9, sağlık −1, birlikte gidilen kişide yakınlık +7 (100'deyse artırılmaz).
- **Kimlerle:** eş, sevgili, çocuk, arkadaş, anne, baba. Hayatta olma, erişilebilirlik ve **en az 7 yaş** koşulu aranır.
- **Anılar:** her gezi için 10 farklı kısa sahneden biri kaydedilir; yıllar sonra (en az 5 yıl) aynı kişiyle yapılan gezi 4 gezi olayından biriyle hatırlanabilir.
- Gezi, oyuncunun **yaşadığı veya doğduğu şehri değiştirmez** ve Yaş Al akışına dokunmaz.

**Karar soruları:**
1. Ücretler maaşlarla dengeli mi? (Karşılaştırma: mağaza çalışanı yıllık 180.000 ₺.)
2. Yılda 2 gezi sınırı uygun mu; yoksa yalnızca para mı sınırlamalı?
3. Çocuk için 7 yaş sınırı doğru mu? Daha küçük çocuk **ailesiyle** gidebilmeli mi? (Şu an gidemiyor.)
4. Birden fazla kişiyle (ör. bütün aile) gezi olmalı mı? **Şu an tek yoldaş.**
5. Gezi sırasında iş/okul devamsızlığı gibi bir bedel olmalı mı? **Şu an yok.**
6. Uzak şehir–yakın şehir ayrımı yapılmalı mı? Şu an bütün şehirler aynı ücrete gidiliyor (mesafe modellenmedi).
7. Yurt dışı seyahati ileride eklenecek mi? **Bu sürümde yok.**

**Varsayılan işlem:** Ücretler ve etkiler tek dosyada (`Travel`) toplandı. Kalıcı taşınma sistemi hiç değiştirilmedi.

### Q-081 — İleri yaş: emeklilik, aylık ve torunlar
**Durum:** Yön **Faho tarafından istendi** ("ileri yaş ve emeklilik paketini kuralım"); **sayılar karar bekliyor** (`prototypeOnly`). **Kaynak:** Paket 12. **Bağlantılı:** Q-048 (maaş), Q-078 (meslekte ilerleme), Q-064 (çocuk kuralları).

**Önceki durum:** Oyuncu hiç emekli olamıyordu; 90 yaşında bile aynı işte çalışıp maaş alabiliyordu. NPC'ler 65'te emekli oluyordu, oyuncu olamıyordu.

**Şu an kodda olan (geçici) çözüm:**
- **Emeklilik yaşı:** tam 65, erken 60. Erken ayrılışta aylık **×0,8**.
- **Aylık:** son maaş × (0,35 + çalışılan yıl × 0,01), üst sınır **%75**. On yıldan az çalışana **asgari aylık 60.000 ₺** bağlanır (parasız kalmasın diye; gerçek bir sosyal yardım iddiası değildir).
- Emekli olunca süren iş kariyer geçmişine "Emekli oldu" olarak kapanır; zam, terfi, iş arama ve işten ayrılma menüden kalkar. **Emeklilik şimdilik geri alınamaz.**
- Aylık maaşla aynı ödeme dönemini kullanır: ikisi birden alınamaz, yılda bir kez yatar.
- **Torunlar:** yetişkin çocuğun (24-42 yaş) her yıl **%12** ihtimalle çocuğu olur, çocuk başına en fazla **3**. Torun gerçek kişi kaydıdır; kendi özellikleri çocuğun değerlerinden türer, oyuncunun hanesinde yaşamaz, başka şehirde de görüşülür ve kendi hayatını yaşar (okula başlar, büyür). Doğum yılında mutluluk **+8**.
- **İleri yaş olayları:** 8 yeni olay (emekliliğin ilk sabahı, eski iş yeri, torunla gün, torunun büyümesi, sağlık kontrolü, mahalle, geçmişe bakış, emeklilikte küçük iş).

**Karar soruları:**
1. Emeklilik yaşları (60/65) ve aylık formülü uygun mu?
2. **Emeklilikten işe dönülebilmeli mi?** Şu an dönülemiyor.
3. Zorunlu emeklilik olmalı mı? Şu an yok: oyuncu isterse 90 yaşında da çalışabilir.
4. Asgari aylık 60.000 ₺ uygun mu; hiç çalışmamışa aylık bağlanmalı mı?
5. Torun doğum ihtimali %12 ve çocuk başına en fazla 3 uygun mu?
6. **Torun mirastan pay almalı mı?** Şu an almıyor; miras yalnızca çocuklara gidiyor (D-037, D-052).
7. Torunla kuşak devam ettirilebilmeli mi? Şu an yalnızca çocuklarla devam ediliyor.
8. Vefat eden çocuğun torunlarıyla ilişki ne olmalı? Şu an kayıt duruyor ve görüşme sürüyor.

**Ayrıca bu pakette uygulanan karar (Faho):** kayıt dosyası göçü geriye dönük **son beş sürümle** sınırlandı (`kMinReadableSaveVersion = 21`). Daha eski kayıtlar açılmıyor; oyuncuya dosyanın **silinmediği** söyleniyor. Sürüm 20 ve öncesine ait göç adımları ve onlara bağlı testler kaldırıldı — gerekirse sürüm geçmişinden geri alınabilir.

### Q-082 — Okul başarısı: not ortalaması, burs ve sınıfta kalma
**Durum:** Yön **Faho tarafından istendi** ("okul tarafına dediklerini yapalım, okuldan atılma, burs gibi sistemler"); **sayılar karar bekliyor** (`prototypeOnly`). **Kaynak:** Paket 13. **Bağlantılı:** Q-040 (eğitim), Q-048 (ekonomi).

**Şu an kodda olan (geçici) çözüm:**
- **Not ortalaması** 0-100 arası; okula başlarken zekâdan türer (zekâ × 0,8 + şans). Okul dışında `null`'dır, **geriye dönük not uydurulmaz**.
- Her yıl sonunda ortalama zekâya doğru kayar (fark × 0,25) ve ±6 dalgalanır: çalışmayan zeki öğrenci ortalamaya döner, çalışan kazandığını korur.
- **Ders çalış:** yılda 2 kez, ortalamaya +6 (yüksek ortalamada +4/+2), zekâya +1, mutluluğa −2.
- **Burs:** lise 9. sınıftan itibaren ortalama **≥ 80** ise yılda **45.000 ₺**. Okuldan ayrılan burs almaz.
- **Sınıfta kalma:** ortalama **< 35** ise sınıf tekrarı — ama **yalnızca lisede (9. sınıf ve üstü)**. İlkokul ve ortaokulda düşük not sınıfta bırakmaz.
- **Okuldan ayrılma:** üst üste **2 sınıf tekrarından sonra** ve yalnızca **15 yaş ve üstünde**. Eğitim geçmişi silinmez; oyuncu çalışma hayatına geçebilir.
- Ortalama artık **yerleştirme puanını** ve **üniversite sınav puanını** gerçekten etkiliyor: okulda çalışmak sonuç doğuruyor.

**Karar soruları:**
1. Ortalama 0-100 ölçeği mi kalsın, yoksa 4'lük/5'lik sisteme mi çevrilsin?
2. Burs eşiği 80 ve tutar 45.000 ₺ uygun mu? Üniversitede burs farklı olmalı mı?
3. Sınıfta kalma lisede başlasın mı, yoksa ortaokulda da olsun mu?
4. Okuldan ayrılan oyuncu **geri dönebilmeli mi** (açık lise gibi)? Şu an dönemiyor.
5. Ders çalışmanın mutluluk bedeli (−2) doğru mu; "çalışmak mutsuz eder" mesajı istenir mi?
6. Devamsızlık, sınav haftası, özel ders gibi ayrı mekanikler eklenmeli mi? Şu an yok.

**Ayrıca bu pakette:** ilk yılların (0-4 yaş) olayları genişletildi. **Not:** ilk adım, ilk kelime, aşı günü, komşu ziyareti ve ilk oyuncak paylaşımı olayları **zaten vardı**; tekrar yazılmadı. Eklenenler: uykusuz geceler, ateşli gece, ilk ayrılık, "neden" soruları, ilk doğum günü ve yıllar sonra anlatılan bebeklik hikâyesi.

### Q-083 — Ses efektleri: hangi anlar, ne kadar, hangi karakter
**Durum:** Yön **Faho tarafından istendi** ("oyuna ufak müzik efektleri ekle: kart açılınca, seçim yapınca"); **ayrıntılar karar bekliyor** (`prototypeOnly`). **Kaynak:** Paket 15.

**Şu an kodda olan (geçici) çözüm:**
- **Yedi kısa efekt**, hepsi bu proje için üretildi; dışarıdan alınmış ses yok: `tap` (menü/kart dokunuşu), `select` (seçim onayı), `back` (geri), `age_up` (yaş alma), `good` (olumlu sonuç), `bad` (olumsuz sonuç), `notice` (bildirim çanı).
- Sesler yumuşak sinüs tonlarından oluşuyor; olumsuz ses bilerek **cezalandırıcı değil**, kısa bir "olmadı" tonu.
- **Ayarlarda açma/kapama** var; kapalıyken oyun tamamen sessiz ve ayar kayıtla saklanıyor.
- İki ses arasında en az 60 ms var: hızlı dokunuşlarda sesler üst üste binmiyor.
- Ses çalmak oyunun akışını **hiçbir zaman engellemiyor**: platformda ses yoksa sessizce geçiliyor.
- Şu an bağlı olduğu yerler: menü satırları, kişi kartları, alt gezinme sekmeleri, Yaş Al, olay seçimi, geri dönüş, bildirim penceresi.

**Karar soruları:**
1. Efektlerin karakteri uygun mu (yumuşak tonlar), yoksa daha "oyunumsu" mu olmalı?
2. Hangi anlarda ses olmalı? Şu an olumlu/olumsuz sonuç sesleri (`good`/`bad`) **üretildi ama hiçbir yere bağlanmadı** — zam kabulü, burs, sınavda kalma gibi anlara bağlansın mı?
3. **Arka plan müziği** olmalı mı? Şu an yok; yalnızca kısa efektler var.
4. Ses seviyesi (şu an %60) ayarlanabilir olmalı mı, yoksa aç/kapa yeterli mi?
5. Titreşim (haptik geri bildirim) eklensin mi?
6. Ölüm, doğum, evlilik gibi büyük anlara özel ses olmalı mı?

**Varsayılan işlem:** Efektler `assets/sounds/` altında, tanımları tek dosyada (`GameSound`). İstenirse ses dosyaları değiştirilebilir ya da tamamen kaldırılabilir.

### Q-084 — Görsel kimlik yenilemesi: canlı palet, koyu başlık şeridi, renksiz kartlar
**Durum:** Yön **Faho tarafından istendi** ("menüler ve oyun tasarımı çok yapay zeka duruyor; daha iyi işler çıkart ve canlı renkleri kullan"); **ayrıntılar karar bekliyor** (`prototypeOnly`). **Kaynak:** Paket 16, `app/lib/ui/theme/bir_omur_theme.dart`, `app/lib/ui/widgets/`, `app/test/goldens/`.

**Neden değişti:** Önceki sürüm soluk bir "eski kâğıt" zemini üzerine **her menü satırını ayrı bir pastel tonla** boyuyordu. Yan yana gelince ekran hem düşük karşıtlıklı hem de karaktersiz duruyordu; Faho bu görüntüyü "yapay zekâ işi" diye tanımladı.

**Şu an kodda olan (geçici) çözüm:**
- **Palet doygunlaştırıldı.** Nar `#B53142` → `#E4224B`, çini `#12897A` → `#00A99B`, pirinç `#D69A2B` → `#F5A623`. Menü renk ailesi (mor, mavi, yeşil, turuncu, gül) de belirgin biçimde canlandı.
- **Zemin sakinleşti, renk vurguya taşındı.** Açık temada gövde soğuk açık gri (`#F1F2F7`), kartlar **beyaz**; koyu temada gövde mürekkep moru (`#0C0B15`), kartlar `#191826`. Kart zeminleri **artık vurgu rengiyle boyanmıyor**.
- **Üst karakter şeridi ve açılış ekranı koyu degrade oldu** (`#3B1E86` → `#B02A63`), yazı beyaz. Ekranın üstü ve altı çerçeve gibi duruyor, içerik arada nefes alıyor.
- **Her bölüm renkli bir başlık kartıyla açılıyor:** degrade zemin, beyaz başlık, sağda yarı saydam bölüm simgesi.
- **Menü satırı yeniden kuruldu:** beyaz kart, doygun degrade ikon kutusu ve altında kendi renginden bir ışık, nötr gri ok.
- **Düğmeler düzleşti** (gölge kaldırıldı); olay penceresinde seçenekler tonal düğme yerine olayın rengini taşıyan kendi kartlarında.
- **Hayat günlüğü:** içinde bulunulan yıl dolu nar rozeti ve "BU YIL" etiketiyle öne çıkıyor; kategori simgeleri kendi renginde yumuşak kutularda.
- Alt menü sırası ve **Yaş Al**'ın yeri değişmedi (NAV-001).

**Karar soruları:**
1. Üst şeridin ve açılış ekranının **mor → bordo** degradesi doğru kimlik mi? Alternatif: nar kırmızısı ağırlıklı tek renk, ya da tamamen koyu lacivert.
2. Menü kartları **renksiz** mi kalsın, yoksa hafif bir renk tonu geri gelsin mi? (Şu an renk yalnızca ikon kutusunda.)
3. Sekiz renkli menü ailesi çok mu? Üç-dört renge indirilsin mi?
4. **Yazı tipi hâlâ sistem yazı tipi** (Android'de Roboto, Windows'ta Segoe UI). Oyuna özel bir yazı tipi istenirse dosyanın projeye eklenmesi gerekiyor; bu ortamdan indirilemedi. İstenir mi, isteniyorsa hangi karakterde?
5. Bölüm başlık kartı her alt sayfada görünmeli mi, yoksa yalnızca ana menülerde mi?
6. Kilim şeridi bu palette kalsın mı, yoksa başka bir özgün doku mu denensin?

**Varsayılan işlem:** Bütün renk değerleri tek dosyada (`bir_omur_theme.dart`) toplandığı için palet tek commit'le geri alınabilir. Onay gelene dek bu palet kalıcı marka kararı sayılmaz.


### Q-085 — Okul dönüm noktası bildirimleri ve sınav yılı
**Durum:** Yön **Faho tarafından istendi** ("ilk okula başlarken veya ortaokul bittiğinde liseye geçtiğinde ve lise bittiğinde bildirimler ver; ekrana sınav stresi konusunu ekle"); **ayrıntılar karar bekliyor** (`prototypeOnly`). **Kaynak:** Paket 17, `app/lib/domain/life/notices.dart`, `app/lib/data/event_pool_exam.dart`, `app/lib/domain/education/education_path.dart`.

**Şu an kodda olan (geçici) çözüm:**

*Bildirimler* — yeni bir bildirim türü (`NoticeKind.okul`) eklendi. Bilgilendirmedir: seçim sormaz, hiçbir değeri değiştirmez, kayıtta saklanır ve aynı bildirim iki kez açılmaz.
- **Okula başlama** (ilkokul 1. sınıf).
- **Ortaokul bitti, lise başlıyor** — yerleştirme puanı hesaplanmışsa metne yazılır.
- **Lise bitti** — üniversite sınav puanı hesaplanmışsa metne yazılır.
- **Üniversite mezuniyeti** — Faho bunu ayrıca istemedi; lise bitişi bildirilirken üniversitenin bildirilmemesi tutarsız duracağı için eklendi.
- **İlkokul → ortaokul geçişi bildirilmiyor**: istenen üç dönüm noktası arasında yoktu, günlükte satır olarak kalıyor.

*Sınav yılı* — 8. ve 12. sınıf artık diğer yıllardan ayrılıyor.
- Okul ekranında **"Sınav yılı" paneli**: hangi sınavın olduğunu ve o yıl verilen kararların hazırlığa hangi yönde etki ettiğini yazar. **Sayı göstermez**, çünkü puan sınav günü hesaplanır ve şans da içerir.
- **Sekiz yeni olay** (dördü 8. sınıf, dördü 12. sınıf): sınav takvimi, deneme sonucu, gece kaygısı, son hafta / son ay, aile baskısı. İkisi **önceki kararı hatırlar**: yalnızca yılı sınava adamış oyuncuda çıkar.
- Seçimler puanı **gerçekten** değiştiriyor (`prototypeOnly`): odaklanmak **+9**, dengeli çalışmak **+5**, savsaklamak **−10**, kaygı **−4**, öğretmen/aile desteği **+4**. Toplam etki sınırlı: zekâ ve not ortalaması ana bileşen olarak kalıyor.
- Çok çalışmak bedava değil: mutluluk ve sağlık düşebiliyor. Kaygı **kalıcı ceza değil**, tek sınavlık bir iz.
- İki sınav **ayrı tutuluyor**: 8. sınıfta bırakılan iz, dört yıl sonraki üniversite sınavını etkilemiyor.
- Hiçbir olay gerçek bir sınavın adını taşımıyor; kurgusal anlatılıyor.

**Karar soruları:**
1. Bildirim sayısı doğru mu? İlkokul → ortaokul geçişi de bildirilsin mi? Üniversite mezuniyeti kalsın mı?
2. Sınav puanı etkileri (+9 / +5 / −10 / −4 / +4) denge açısından uygun mu? Savsaklamanın cezası odaklanmanın ödülünden büyük — bu doğru mu?
3. Odaklanmanın mutluluk bedeli (12. sınıfta −8) fazla mı? "Çalışmak mutsuz eder" mesajı istenir mi?
4. Sınav yılı paneli **sayı** göstermeli mi (ör. "hazırlık: iyi/orta/zayıf"), yoksa şu anki cümle yeterli mi?
5. Dershane, özel ders, deneme sınavı satın alma gibi **paralı** hazırlık seçenekleri eklensin mi? Şu an yok.
6. Sınav sonucu düşükse **ikinci kez sınava girme** (bir yıl bekleme) seçeneği olmalı mı? Şu an yok.

**Varsayılan işlem:** Bütün sayısal değerler `EducationPath` içinde tek yerde; onay gelene dek kalıcı kural sayılmaz.


### Q-086 — Aktivitelere eklenen üç yeni alan: Sağlık Merkezi, Eğlence, Kurslar
**Durum:** Yön **Faho tarafından istendi** ("aktiviteler kısmına benim unuttuğum şeyleri ekleyebilirsin"); **içerik ve sayılar karar bekliyor** (`prototypeOnly`). **Kaynak:** Paket 18, `app/lib/data/activity_catalog.dart`, `app/lib/ui/screens/sections/activities_screen.dart`.

**Neden bu üçü:** Mevcut Aktiviteler menüsünde üç boşluk vardı.
- **Sağlığa kriz beklemeden bakmanın yolu yoktu.** Spor salonu dışında sağlık yalnızca sağlık krizi çıkınca gündeme geliyordu.
- **Mutluluğu kendi isteğinle yükseltmenin yolu yoktu.** Mutluluk yalnızca olayların rastgele iyi gitmesiyle artıyordu.
- **Okul dışında bir şey öğrenmenin yolu yoktu.** Kütüphane yalnızca okumaydı.

**Şu an kodda olan (geçici) çözüm** — hepsi mevcut aktivite altyapısını kullanıyor; yeni ana menü açılmadı, alt menü sırası değişmedi:

*Sağlık Merkezi* (1 yaşından itibaren) — genel sağlık kontrolü (900 ₺), diş kontrolü (650 ₺), göz muayenesi (450 ₺), mevsim aşısı (300 ₺), bir uzmanla konuşmak (1.400 ₺). Hiçbiri tıbbi tavsiye değil; oyun içi kurgu.

*Eğlence* (4 yaşından itibaren) — parkta yürüyüş (**ücretsiz**), sinema (250 ₺), kafede oturmak (200 ₺), maça gitmek (550 ₺), konsere gitmek (950 ₺).

*Kurslar* (6 yaşından itibaren) — resim atölyesi (1.600 ₺), müzik kursu (2.200 ₺), dil kursu (2.800 ₺), bilgisayar kursu (3.200 ₺). Dil ve bilgisayar kursu **zekâyı** yükseltiyor; aktivite altyapısına bunun için zekâ alanı eklendi.

*Korunan kurallar:* parası yetmeyen işlem gerçekleşmez, aynı yaşta tekrarın getirisi azalır ve sınıra gelince eylem kapanır, sahte "+puan" yazılmaz, her alan yalnızca yaşına uyduğu andan itibaren menüde görünür (çalışmayan düğme yok).

**Karar soruları:**
1. Ücretler doğru ölçekte mi? Kurslar (1.600–3.200 ₺) bir gence göre pahalı; aile bütçesinden karşılanan bir "aile öder" seçeneği olmalı mı?
2. Sağlık kontrolü bazen **bir şey bulmalı** mı (erken teşhis → ileride sağlık krizi olasılığı düşer)? Şu an yalnızca sağlığı yükseltiyor.
3. Kurslar kalıcı bir **hobi/beceri kimliği** bırakmalı mı ("müzikle uğraşıyor" gibi), yoksa yalnızca değer artışı yeterli mi?
4. Eğlenceye **biriyle birlikte gitmek** eklensin mi? Şu an tek başına; "Birlikte vakit geçir" ayrı bir menü.
5. Bu üç alan mı yeterli, yoksa başka eksikler var mı (gönüllülük, tatil köyü, hayvan sahiplenme, ehliyetli araç kullanımı…)?
6. Sağlık Merkezi'nin 1 yaşından itibaren açık olması doğru mu? Küçük yaşta kararı aile veriyor; oyun bunu oyuncuya sorarak anlatıyor.

**Varsayılan işlem:** Bütün eylemler tek katalog dosyasında; istenirse tek tek çıkarılabilir ya da ücretleri değiştirilebilir. Onay gelene dek kalıcı kural sayılmaz.


### Q-087 — Görsel yön üçüncü kez kuruldu: çizgi roman / çıkartma dili
**Durum:** Yön **Faho tarafından istendi** ("bu tasarımı hiç beğenmiyorum, komple baştan tasarla, özgün olsun, yapay zekâsal şeylerden çık, cartoon modda bile yapabilirsin"); **ayrıntılar karar bekliyor** (`prototypeOnly`). **Kaynak:** Paket 19, `app/lib/ui/theme/bir_omur_theme.dart`, `app/lib/ui/widgets/{comic,character_face}.dart`, `app/assets/fonts/`, `app/test/goldens/`.

**Neden üçüncü kez:** İlk iki deneme de reddedildi ve ikisinin de ortak yanı aynıydı — herhangi bir uygulamaya yapıştırılabilecek **genel** bir arayüz dili: degradeler, yumuşak gölgeler, ince çizgiler, hazır Material ikonları, sistem yazı tipi. Bu üçüncü sürüm o dili bilerek ve sertçe kırıyor.

**Şu an kodda olan (geçici) çözüm — altı kural:**
1. **Degrade yok.** Her yüzey tek ve düz bir renk. (Bir test bunu sınıyor: ekranda degrade bulunursa test kırılır.)
2. **Her yüzeyin kalın mürekkep konturu var** (2,5 px): kart, düğme, rozet, ikon kutusu, değer çubuğu.
3. **Gölge bulanık değil, kaydırılmış** (`blurRadius: 0`). Kartlar kâğıda yapıştırılmış çıkartma gibi durur.
4. **Düğmeler basınca gerçekten çöker**: gölge kadar aşağı iner ve gölgesini bırakır.
5. **Oyunun kendi yazı tipi var.** Arayüzün tamamı **Baloo 2** (kalın, yuvarlak, oyuncu); oyunun adı, yaş etiketleri ve günlük başlıkları **Patrick Hand** (el yazısı). İkisi de SIL Open Font License; Türkçe harflerin tamamını taşıyorlar ve yalnızca oyunun kullandığı karakterlere indirgendiler (toplam ~400 KB). Yeniden üretmek için `app/tool/fetch_fonts.py`.
6. **Zemin çizim kâğıdı**: sıcak krem, üzerinde soluk şaşırtmalı nokta dokusu.

**Ve en büyük eksik kapatıldı: karakterin bir yüzü var.** Hazır görsel değil, her karede oyunun kendi verisinden **çiziliyor**: yaş kafanın oranını, saç rengini ve yüz çizgilerini; berberde seçilen saç stili saçı; mutluluk ağzın eğrisini ve kaşların açısını; sağlık ten tonunu ve gözlerin açıklığını; cinsiyet saç hacmini belirliyor. Bebeğin tek tutamı, gencin dağınık saçı, yaşlının beyaz saçı ve göz kenarı çizgileri hep gerçek kayıttan okunuyor — uydurma yok. Ekran görüntüsü: `app/test/goldens/12_karakter_yuzu.png`.

**Karar soruları:**
1. **Bu yön doğru mu?** Çizgi roman / çıkartma dili devam etsin mi, yoksa başka bir yön mü denensin? (Bu sefer beğenilmezse, yönü sen tarif edersen daha isabetli olur: hangi oyunun görüntüsü hoşuna gidiyor?)
2. **Yazı tipi:** Baloo 2 oyunun sesi olarak uygun mu? Daha sert/geometrik ya da daha çocuksu bir alternatif istenir mi?
3. **El yazısı aksanlar** (oyunun adı, yaş etiketleri) kalsın mı, yoksa her şey tek yazı tipiyle mi olsun?
4. **Karakter yüzü:** ayrıntı düzeyi yeterli mi? Ten tonu, göz rengi, gözlük, sakal, kıyafet gibi ayrıntılar eklensin mi? Yüz kişi kartlarında da (anne, baba, arkadaşlar) kullanılsın mı — şu an yalnızca oyuncunun yüzü var.
5. **Kâğıt dokusu** (nokta deseni) kalsın mı, yoksa düz zemin mi?
6. **`docs/PROTOTYPE_UI.md` §2 ile çelişki:** orada onaylanmış yön "modern + ölçülü nostaljik" yazıyor. Çizgi roman yönü onaylanırsa o belge güncellenmeli. **Onay gelmeden o belgeye dokunulmadı.**

**Varsayılan işlem:** Bütün ölçüler (kontur kalınlığı, gölge derinliği, köşe yarıçapları) `Comic` sınıfında, bütün renkler `BirOmurColors` içinde tek yerde. Yön beğenilmezse tek commit'le geri alınabilir. Onay gelene dek kalıcı marka kararı sayılmaz.

**Yan düzeltme (gerçek hata):** Olay penceresinde eylem düğmeleri kaydırma alanının içindeydi; uzun olay metinlerinde **"Devam" düğmesi ekranın altına kaçıp dokunulamaz hale geliyordu**. Düğmeler artık kaydırma alanının dışında, her zaman görünür.


### Q-088 — Olay çeşitliliği: tekrar sönümü ve orta yaş içeriği
**Durum:** Yön **Faho tarafından onaylandı** (21 Eylül 2026; ChatGPT o gün yoktu, Faho "hepsini yap, mantıklı geldi" dedi). **Sayılar karar bekliyor** (`prototypeOnly`). **Kaynak:** Paket 20, `app/lib/domain/events/event_engine.dart`, `app/lib/data/event_pool_midlife.dart`.

**Ölçüm — sorun neydi:** 12 tam hayat simüle edildi.
- Aynı olay bir hayatta **üç kez** çıkıyordu; 12 hayatta en sık olay **39 kez** görüldü.
- 151 olayın yalnızca **94'ü** hiç görülüyordu.
- Asıl sebep ağırlık değil **seçenek yokluğuydu:** 30-49 yaş arasında bir yılda ortalama yalnızca **1-2 uygun olay** vardı ve çoğu daha önce görülmüştü. Hayatın en uzun bölümü içerik olarak boştu.

**Şu an kodda olan (geçici) çözüm — iki parça:**

*1. Tekrar sönümü.* Bir olay her çıkışında ağırlığı **0,30 ile çarpılır** (taban: kendi ağırlığının %4'ü, olay tamamen kaybolmaz) ve tekrar aralığı **her görülmede 6 yıl büyür** (tavan 35 yıl). Sayaç kayda girer; eski kayıtlarda görülmüş her olay **bir kez** görülmüş sayılır, uydurma sayı yazılmaz.

*2. Orta yetişkinlik paketi.* 28-58 yaş için **25 yeni olay**: kira zammı, borç isteyen tanıdık, beklenmedik masraf, birikim kararı, sınıf buluşması, uykusuz gece, aynada ilk beyaz, kırk yaş kararları, yeni bir uğraş, tanıdık düğünü, daralan çevre, taşınan komşu, çocukluk eşyası, unutulan doğum günü, uzak taziye, sağlığı erteleme, gönüllü çağrısı, teknolojinin gerisinde kalmak, ev sahibinin satması, boş hafta sonu, yarım kalan kitap, sabah yolu, ek iş teklifi. **İkisi önceki kararı hatırlıyor:** biriktiren oyuncuya birikimin karşılığı, sağlığını erteleyene ertelemenin bedeli çıkıyor.

**Sonuç (aynı ölçümle):**
| | Önce | Sonra |
|---|---|---|
| 30-49'da uygun olay / yıl | 1-2 | **21-22** |
| Bunların hiç görülmemişi | 0,3-1,9 | **15-20** |
| En çok tekrar (12 hayat) | 39 | **18** |
| Farklı olay görüldü | 94/151 | **120/176** |
| Olaysız yıl | %0 | %1 |

**Karar soruları:**
1. Tekrar sönümü sayıları (×0,30 ağırlık, +6 yıl aralık) uygun mu? Daha sert olsun mu — aynı olayı bir hayatta **hiç** iki kez görmemek istenir mi?
2. Orta yaş olaylarının para tutarları (kira zammı −6.000 ₺, ek iş +14.000 ₺, ertelenen sağlığın bedeli −18.000 ₺) ekonomiyle uyumlu mu?
3. "Sağlığı erteleme → yıllar sonra bedeli" zinciri fazla cezalandırıcı mı? Şu an ikinci kez ertelemek sağlığı 7 puan düşürüyor.
4. Bu 25 olay Türkiye'deki orta yaşı doğru anlatıyor mu? Eksik kalan tipik anlar var mı?
5. Aynı ölçüm **0-29 yaş** için 3-8 olay gösteriyor; çocukluk ve gençlik de genişletilsin mi?

**Yan karar:** Kayıt biçimi 28'e çıktı; **beş sürümlük pencere kuralı gereği** okunabilir taban 22'den **23'e** yükseldi. Sürüm 22 kayıtları artık açılmıyor — dosya silinmiyor, anlaşılır mesaj gösteriliyor.

**Not:** Testlerin tohumları artık sabit değil. Olay havuzu her büyüdüğünde rastgele akış değişiyor ve romantik zincir testleri elle güncellenmek zorunda kalıyordu; bu testler artık koşulu sağlayan ilk tohumu kendileri buluyor.



### Q-089 — Dar pencereli olayların önceliği: sınav yılı havuzda kayboluyordu
**Durum:** Yön **Faho tarafından onaylandı** (21 Eylül 2026; ChatGPT o gün yoktu, Faho "hepsini yap, mantıklı geldi" dedi). **Sayılar ve kapsam karar bekliyor** (`prototypeOnly`). **Kaynak:** Paket 21, `app/lib/domain/events/event_engine.dart`, `app/lib/domain/models/game_event.dart`, `app/lib/data/event_pool_exam.dart`.

**Ölçüm — sorun neydi:** Oyunda **yılda yalnızca bir olay** çıkıyor. Paket 17'de eklenen sınav yılı olayları (8. ve 12. sınıf) ise sadece **tek bir yıl** uygun; o yılın tek yuvası havuzdaki onlarca genel olaydan birine gidince sınav stresi hiç yaşanmadan okul bitiyordu.

| | Önce | Sonra |
|---|---|---|
| 8. sınıfa gelen hayatta sınav olayı gördü | %38 | **%100** (60/60) |
| 12. sınıfa gelen hayatta sınav olayı gördü | %28 | **%100** (56/56) |

**Şu an kodda olan (geçici) çözüm:** Olaylara `priority` alanı eklendi. Bu **sıra kapma değil, ağırlık artırımıdır**: öncelikli olay havuzdan diğerlerini atmaz, yalnızca ağırlığı `120^öncelik` ile çarpılır. Diğer olaylar hâlâ çıkabilir; motorun geri kalanı (tekrar sönümü, tekrar aralığı, koşullar) aynen işler. Öncelik 2: sekiz sınav olayı. Öncelik 1: `lise_sonrasi` (okul bitti, şimdi ne olacak).

**Yol boyunca bulunan iki gerçek hata:**

*1. Öncelik önce "sıra kapma" olarak yazılmıştı.* Öncelikli bir olay varken diğer bütün adaylar eleniyordu. Bu, havuzu açlığa sürükledi ve 15 testi kırdı. Ağırlık artırımına çevrildi.

*2. Geniş pencereli olaylara öncelik vermek oyunu bozuyor.* `ilk_ev_ilk_gece` (18-32), `ilk_maas` (18-24) ve `universite_ilk_hafta` (18-24) önceliklendirildiğinde **25 tohumun hiçbirinde sevgili edinilemedi**: geniş pencereli öncelikli olaylar romantik zincirin bütün penceresini yutuyor. Kural şu oldu ve **kalıcı bir testle korunuyor**: öncelik yalnızca penceresi **3 yıl veya daha dar** ya da tek bir sınıfa kilitli olaylara verilebilir.

Aynı hata `okul_ilk_gun` (6-8 yaş) için daha sessiz bir biçimde tekrarlandı: pencere kurala uyuyordu ama olay, okulun ilk yılındaki tek yuvayı kapıp sıra arkadaşıyla tanışmayı bastırıyordu. Ölçümde **okulda arkadaş edinen hayat oranı 44/60'tan 34/60'a**, 32 yaşına kadar sevgilisi olan hayat oranı **15/60'tan 8/60'a** düştü. Önceliği kaldırıldı; okula başlama zaten Paket 17'nin ekran bildirimiyle duyuruluyor.

**Karar soruları:**
1. Öncelik çarpanı (`120^öncelik`) uygun mu? Sınav yılını **%100** görmek isteniyor mu, yoksa "çoğu hayatta ama her hayatta değil" (örneğin %80) daha mı doğal?
2. `lise_sonrasi` önceliği kalsın mı? Önceliksizken bu olay **60 hayatın yalnızca 11'inde** çıkıyordu — üniversite/çalışma ayrımı hayatların çoğunda hiç sorulmadan geçiyordu.
3. Başka hangi olaylar "hayatta bir kez ve dar pencerede" sayılmalı? Aday olarak: ilk maaş, askerlik, ilk ev. (Bunlar şu an **bilerek** önceliksiz; pencereleri geniş.)
4. Asıl sınır **yılda tek olay** kuralı. Dönüm noktası yıllarında (okula başlama, sınav yılı, okul bitişi) **iki olay** gösterilsin mi? Öncelik, tek yuvayı paylaştırmaya çalışan bir yama; iki yuva bu soruyu kökünden çözerdi.
5. Sınav olaylarının etkisi (odaklanma +9, dengeli +5, savsaklama −10, kaygı −4, destek +4 puan) yerleştirme ve üniversite sınav puanında doğru ağırlıkta mı?


### Q-090 — Hayat sonu değerlendirmesi: "nasıl bir hayattı?"
**Durum:** Yön **Faho tarafından onaylandı** (21 Eylül 2026; ChatGPT o gün yoktu, Faho "hepsini yap, mantıklı geldi" dedi). **Sayılar, eksen adları ve metinler karar bekliyor** (`prototypeOnly`). **Kaynak:** Paket 22, `app/lib/domain/life/life_verdict.dart`, `app/lib/ui/widgets/life_verdict_panel.dart`.

**Sorun neydi:** Hayat bitince ekran yalnızca **liste** veriyordu — cüzdan, eşya sayısı, ehliyet sayısı, günlükten son sekiz satır. Oyuncunun bütün bir ömür boyunca verdiği kararların hiçbir **karşılığı** yoktu; ekran "ne oldu" diyordu ama "nasıl bir hayattı" demiyordu.

**Şu an kodda olan (geçici) çözüm:** Özetin **üstüne** bir değerlendirme paneli geldi. Dört parçası var:

*1. Hayatın adı.* "Emekle geçen bir hayat", "Kalabalık bir hayat", "Gezip görülen bir hayat", "Kendi hâlinde bir hayat", 18 yaşından önce vefatta "Yarıda kalan bir hayat". Bu ad arşive de yazılıyor; Geçmiş Hayatlar listesinde her hayatın artık bir adı var.

*2. Dört eksen.* Bağlar, Emek, Deneyim, Huzur. **Puan değil ayna:** oyuncu kazanmaz veya kaybetmez, çubuklar hayatın hangi yöne ağır bastığını gösterir. Her eksenin yanında sayı değil cümle var ("3 kişi seni yakından tanıdı", "Hayatın hep aynı sokaklarda geçti").

*3. İlkler.* Yaşı **gerçekten kayıtlı** anlar, yaşa göre sıralı: okula başlama, ilk iş, ilk şehir dışı, evlilik, ilk çocuk, emeklilik. Yaşı bilinmeyen hiçbir an listeye girmiyor; uydurma yaş yazılmıyor.

*4. Hiç olmadı.* Yaşanmamış şeyler: hiç evlenmedin, hiç çocuğun olmadı, hiç çalışmadın, üniversite okumadın, hiç şehir dışına çıkmadın, hiç kitap bitirmedin, hiç ehliyet almadın, hiç ev sahibi olmadın, hiç yakın arkadaşın olmadı.

**Yol boyunca düzeltilen bir tasarım hatası:** Başlık önce en yüksek puanlı eksenden geliyordu. Huzur doğrudan 0-100 arası bir istatistikten geldiği, somut eksenler ise seyrek olaylardan toplandığı için huzur neredeyse her zaman kazanıyordu: **38 yıl öğretmenlik yapıp 53 yıl evli kalmış bir hayat, yalnızca keyfi yerinde öldüğü için "Kendi hâlinde bir hayat" sayılıyordu.** Kural değişti: huzur bir **ruh hâlidir**, hayat başka bir şeyle anılabiliyorsa onunla anılır; huzur ancak somut eksenlerin hepsi zayıfken hayata adını verir.

**Karar soruları:**
1. Dört eksen doğru mu? "Emek" yerine "Başarı" mı olmalı, yoksa beşinci bir eksen (örneğin "İz" — geride kalanlar) eklenmeli mi?
2. "Hiç olmadı" listesi doğru tonda mı? Oyuncuyu **suçlamak** istemiyoruz; şu anki metinler ("Hiç evlenmedin.") sitem gibi okunuyor olabilir. "Evlenmedi." gibi üçüncü şahıs mı daha iyi?
3. Eksen ağırlıkları uygun mu? Şu an: yakın kişi başına 16 (tavan 48), evlilik 14, çocuk başına 6 (tavan 18); çalışılan iki yıla 1 puan (tavan 34), emeklilik 10, 250.000 ₺ üzeri birikim 16; şehir başına 7, biten kitap başına 6.
4. Hayat adları listesi genişletilsin mi? Şu an altı ad var; "Zor geçen bir hayat", "Kalabalığın içinde yalnız bir hayat" gibi karşılıklar eksik.
5. Huzur ekseni **ölüm anındaki** mutluluk ve sağlıktan hesaplanıyor — yani bir anlık görüntü, bütün bir hayat değil. Hayat boyu ortalama tutulsun mu? (Bu, kayda yeni bir alan ister.)
6. Değerlendirme yalnızca ekranda mı kalsın, yoksa paylaşılabilir bir kart olarak dışa aktarılsın mı?

**Yan düzeltme (gerçek hata):** `zatürre` sağlık krizinin **iki seçeneği de para istiyordu** (22.000 ₺ ve 3.000 ₺). Diğer beş krizin hepsinde bedelsiz bir çıkış var; zatürre tek istisnaydı. 60 yaşından sonra cüzdanında 3.000 ₺'den azı olan oyuncu, **hiçbir düğmesi etkin olmayan** bir kriz penceresinde kilitleniyordu — oyun oradan devam edemiyordu. "Evde ilaçla idare et" bedelsiz yapıldı; hayatta kalma katkısı (+0,03) ve sağlık etkisi (−15) olduğu gibi bırakıldı, yeni denge sayısı uydurulmadı. Artık kalıcı bir test her krizde parasız seçilebilecek en az bir seçenek olmasını zorunlu kılıyor.

**Yan not:** Arşiv kaydına `verdictTitle` alanı eklendi. **Eski arşiv satırlarında boş kalır ve hiç gösterilmez**; geriye dönük değerlendirme üretilmez, çünkü o hayatların verisi artık elde yok. Kayıt biçim sürümü artmadı: alan tamamen eklemeli ve eksikken `null` okunuyor.


### Q-091 — Romantik ilişki tek bir kapıya bağlıydı: 26 yaşından sonra evlilik imkânsızdı
**Durum:** Yön **Faho tarafından onaylandı** (21 Eylül 2026; ChatGPT o gün yoktu, Faho "hepsini yap, mantıklı geldi" dedi). **Sayılar ve eşleşme kuralları karar bekliyor** (`prototypeOnly`). **Kaynak:** Paket 23, `app/lib/data/event_pool_romance.dart`, `app/lib/data/event_pool.dart`.

**Önce bir düzeltme — kendi teşhisim yanlıştı.** Beş maddelik listede bu maddeyi *"içeriğin çoğu romantizm→evlilik→çocuk zincirine kilitli"* diye yazmıştım. **Ölçüm bunu doğrulamadı:** 176 olayın yalnızca **17'si** romantik zincire bağlı; Paket 20'deki 25 orta yaş olayından sonra bekâr hayatla evli hayat arasında içerik farkı neredeyse kalmamış (yılda uygun olay 22'ye 23, bir hayatta görülen farklı olay 66'ya 70). Sorun **içerik dağılımı değilmiş**.

**Asıl sorun bambaşkaydı:** 176 olayın **yalnızca biri** (`cikma_teklifi`) romantik ilişki başlatabiliyordu. Ve o tek kapı çok dardı:

* Önce `ilk_goz_agrisi` olayının **15-22 yaş** arasında çıkması gerekiyordu,
* orada "selam ver" seçilmeliydi — "otobüse bin" denirse `romantik_gecti` izi **ömür boyu** kapıyı kapatıyordu,
* sonra `cikma_teklifi` **26 yaşından önce** çıkmalıydı,
* bir kez ayrılındıysa `romantik_bitti` izi yine **ömür boyu** kapatıyordu.

Yani **26 yaşını bekâr geçiren ya da bir kez ayrılan oyuncu, ömrünün geri kalanında evlenemiyordu.** Bununla birlikte evlilik motoru, çocuklar, torunlar, miras ve "çocuğum olarak devam et" akışının tamamı erişilmez kalıyordu.

**Ölçüm** (60 hayat, sonuna kadar, seçimler **rastgele**):

| | Önce | Sonra |
|---|---|---|
| Hayatında hiç sevgilisi oldu | **2/60** | **44/60** |
| İlişki başlatabilen olay sayısı | 1 | **7** |
| İlişki kapısının kapandığı yaş | 26 | **84** |

*(Hep "evet" diyen bir oyuncuda tavan 58/60; bekâr kalmak hâlâ gerçek bir sonuç.)*

**Şu an kodda olan (geçici) çözüm — iki parça:**

*1. Yetişkinlik kapıları.* Altı yeni tanışma olayı: iş yerinde (24-52, çalışıyor olmayı ister), arkadaş aracılığıyla (24-58, yakın arkadaş ister), düğünde (24-60), kursta (26-64), komşulukta (28-66) ve ileri yaşta parkta (58-84). Hiçbiri `romantik_gecti` veya `romantik_bitti` izine bakmaz; hepsi `romantik_iliskide` ve `evlendi` izlerinde kapalıdır, yani ikinci bir romantik kişi kaydı üretilmez. `cikma_teklifi` üzerindeki kalıcı `romantik_bitti` yasağı da kaldırıldı.

*2. Bekâr hayat içeriği.* Evlenmeyen ömrün de anlatacak şeyleri olsun diye beş olay: yemekte gelen "sen ne zaman" sorusu, yalnız bayram sabahı, markette iki kişilik paket, kimseye haber vermeden geçen hafta sonu, gece yarısı mutfakta gelen soru.

**Karar soruları:**
1. **44/60 doğru oran mı?** Yani rastgele oynayan oyuncuların yaklaşık dörtte üçünün hayatında bir ilişki olması fazla mı? Bekâr kalmak ne sıklıkta bir sonuç olmalı?
2. **İkinci gerçek engel para.** Sevgilisi olan 44 hayatın yalnızca **25'i** evlenme teklifi verebilecek duruma geliyor; engel neredeyse her zaman **60.000 ₺'lik nikâh masrafı**. Sevgili olunduğu an cüzdanın ortancası **0 ₺**. Bu kasıtlı bir oyun kuralı mı (evlenmek için çalışmak gerekir), yoksa masraf düşürülmeli mi / taksitlendirilmeli mi?
3. Kapıların yaş aralıkları ve ağırlıkları (iş yeri 4, arkadaş 4, düğün 3, kurs 3, komşu 3, ileri yaş 3) uygun mu?
4. İleri yaşta (58-84) yeni bir ilişki kurulabilmesi isteniyor mu? Şu an "parkta aynı bank" olayı bunu açıyor.
5. Boşanmış ya da eşini kaybetmiş oyuncu yeniden evlenebilmeli mi? Şu an **ikinci evlilik yok** (Q-063); yeni sevgili edinebilir ama evlenemez. Bu zincir yarım kalıyor.
6. Eşleşme ve yönelim kuralları hâlâ kararlaştırılmadı: `Romance.start` partnerin cinsiyetini oyuncunun karşıtı seçiyor (`prototypeOnly`).

**Yan düzeltme (test):** `package1_test.dart` içindeki "yeni sınıf en az 10 kişi" beklentisi tohuma bağlıydı. Sınıf **her zaman** 10 kişiye tamamlanıyor, ama aralarından biri o yıl vefat ederse güncel liste 9 veriyor. Test artık sınıfın tam mevcuda tamamlandığını sınıyor, yaşayan sayısına değil.


### Q-092 — İlgisizlikten zayıflayan bağlar
**Durum:** Yön **Faho tarafından onaylandı** (21 Eylül 2026; ChatGPT o gün yoktu, Faho "hepsini yap, mantıklı geldi" dedi). **Sayılar karar bekliyor** (`prototypeOnly`). **Kaynak:** Paket 24, `app/lib/domain/interaction/bond_decay.dart`.

**Sorun neydi:** Yakınlık yalnızca **yükseliyordu**. Bir kişiyle bir kez güzel bir an yaşandıktan sonra oyuncu onu ömrünün geri kalanında hiç aramasa bile bağ olduğu yerde duruyordu. Bu yüzden İlişkiler ekranını düzenli ziyaret etmenin bir karşılığı yoktu: bir kez yükselen bağ bedava kalıcıydı. İlişkilere emek vermekle vermemek arasında hiçbir fark yoktu.

**Şu an kodda olan (geçici) çözüm:** Uzun süre görüşülmeyen kişiyle yakınlık her yıl **yavaşça** düşer. Kurallar bilerek ihtiyatlı:

* **Hoşgörü süresi 3 yıl.** Bir-iki yıl görüşmemek ihmal değildir.
* **Yıllık kayıp 3 puan**, kan bağında **2 puan** (daha yavaş).
* **Kan bağında taban 20.** Anne annedir: uzaklaşır ama yabancıya dönmez. Olay veya seçim kaynaklı düşüşler bu tabana takılmaz; **yalnızca ilgisizlik** takılır. Kan bağı dışında taban 0'dır.
* **Aynı evde yaşayan zayıflamaz.** Her gün görülen biriyle "görüşmemek" diye bir şey yok.
* **Erişilemeyen kişi zayıflamaz.** Yıllar önceki ilkokul öğretmeni ya da başka şehirdeki eski bir sınıf arkadaşı zaten aranamıyor; oyuncu elinden gelmeyen bir şey için cezalandırılmaz.
* **Geriye dönük geçmiş uydurulmaz.** Hiç temas kaydı olmayan kişide sayaç, kişi haneden ayrıldığı (ya da oyuncu evden çıktığı) ilk yıl başlar — aynı evde yaşanırken zaten her gün görülüyordu.
* **Günlük dolup taşmaz.** Her yıl kişi adı sayılmaz; yalnızca araya belirgin bir mesafe girdiğinde (yakınlık 30'un altına inince) tek bir satır düşülür.
* İlişkiler ekranında kişinin sayfasında "**N yıldır görüşmediniz; araya mesafe giriyor**" uyarısı görünür. Sessizce düşen bir sayı olmamalı: oyuncu elinden bir şey geldiğini görmeli.

**Ölçüm** (30 hayat, 80 yaşa kadar, seçimler rastgele, **İlişkiler ekranı hiç kullanılmadan**):

| | Sonuç |
|---|---|
| Bir bağın zayıfladığı hayat | **30/30** |
| Bir hayattaki en büyük yakınlık kaybı | 12 ile 74 arası (ortanca ~30) |
| Hiç aranmayan annenin son yakınlığı | tabana, **20**'ye kadar |

**Karar soruları:**
1. Hoşgörü süresi 3 yıl uygun mu? Daha uzun mu olmalı (örneğin 5)?
2. Yıllık kayıp (3 / kan bağında 2) doğru hızda mı? 80 yıllık bir hayatta hiç aranmayan bir arkadaşın bağının sıfıra inmesi isteniyor mu?
3. Kan bağı tabanı **20** doğru mu? Anne-baba için daha yüksek (örneğin 30), uzak akraba için daha düşük mü olmalı?
4. Eş ve çocuklar evden ayrıldıktan sonra da zayıflamalı mı? Şu an zayıflıyorlar (erişilebilirler ama hanede değiller).
5. Zayıflayan bağ yeniden görüşmekle **hızla** geri kazanılabilmeli mi, yoksa kaybedilen emek geri gelmemeli mi? Şu an normal etkileşim kazancıyla geri gelir, özel bir "araya girmiş mesafeyi kapatma" mekaniği yok.
6. Bağ belli bir eşiğin altına inince bir **olay** çıkmalı mı ("çok uzaklaştınız")? Şu an yalnızca günlüğe satır düşüyor.


### Q-093 — Teklif/düğün ayrımı, yakınlaşma ve gebelik ihtimali
**Durum:** Yön ve akış **Faho tarafından kararlaştırıldı** (21 Eylül 2026, doğrudan talimat). **Sayılar, metinler ve açık uçlar karar bekliyor** (`prototypeOnly`). **Kaynak:** Paket 25, `app/lib/data/wedding_catalog.dart`, `app/lib/domain/interaction/intimacy.dart`, `app/lib/domain/interaction/marriage_engine.dart`.

**Faho'nun talimatı (özet):** Evlenme teklifi **ücretsiz** olsun; kabul edilirse **paraya göre düğün seçenekleri** gelsin (salon, arkadaşlarla parti, aile arasında). Böylece 60.000 ₺ duvarı kalksın. Teklif için de seçenekler olsun (romantik yemek, tatilde, arkadaşlarla küçük organizasyon). "Çocuk yap" yerine daha makul bir seçenek gelsin — "ilişkiye gir" sert kalır, emojiyle ne olduğu vurgulansın. Yakınlaşmada **korunarak / korunmadan** seçimi olsun. "Çocuk yap" deyince doğrudan çocuk olması iyi değil: **ihtimal** olmalı, oyuncu veya eşi **kısır** olabilmeli. İleride Aktiviteler içinde sağlık menüsü ve **tüp bebek tedavisi** olabilir.

**Uygulanan akış:**

*1. Teklif (bedelsiz).* Dört biçim: **Sade bir an** (masrafsız), **Romantik bir yemek** (3.500 ₺), **Arkadaşlarınla küçük bir sürpriz** (7.000 ₺), **Tatile götür, orada sor** (22.000 ₺). Hazırlık kabul ihtimaline sırasıyla +0 / +0,08 / +0,12 / +0,18 ekler — **yanıtı satın almaz**. Masraf **reddedilse de ödenir**: ayrılan masa, alınan bilet geri gelmez.

*2. Düğün (kabulden sonra, cüzdana göre).* **Sadece nikâh** (masrafsız), **Aile arasında** (18.000 ₺), **Arkadaşlarınla parti** (45.000 ₺), **Düğün salonu** (90.000 ₺). Pahalı seçenekler gizlenmez, **kapalı gösterilir ve nedeni yazılır**. Evlilik ancak düğünle kurulur; "evet" ile düğün arasındaki durum **kayda girer**, uygulama kapansa da kaybolmaz.

*3. Yakınlaşma.* "Çocuk sahibi olun" düğmesi kaldırıldı; yerine **"Baş başa kalın 💞"** geldi. Sahne anlatılmaz. Ardından **Korunarak** / **Korunmadan** seçimi çıkar.

*4. Gebelik ihtimali.* Korunulursa gebelik olmaz. Korunmazsa temel ihtimal **%45**; kadının yaşına göre çarpan 29'a kadar 1,0 · 30-34 arası 0,8 · 35-39 arası 0,5 · 40-44 arası 0,25 · 45'ten sonra 0. Aynı yıl ikinci deneme ihtimali **katlamaz**.

*5. Kısırlık.* Oyuncu hayat başında, partner ilişki kurulurken **%8** ihtimalle kısır belirlenir. **Gizlidir:** oyuncuya söylenmez, denedikçe anlaşılır. Dört başarısız denemeden sonra "bir süredir deniyorsunuz ama olmuyor; bir hekime görünmek iyi gelebilir" denir — **"kısırsın" denmez**.

**Kaldırılan iki duvar:**
- Evlenmenin **60.000 ₺** koşulu. (Ölçüm: sevgilisi olan 44 hayattan yalnızca 25'i teklif verebilecek duruma geliyordu, engel neredeyse hep paraydı.)
- Çocuğun **20.000 ₺** koşulu. "Paran yok, o yüzden hamile kalmadın" diye bir şey olmaz; masraf doğumda **cüzdanda ne varsa o kadar** tahsil edilir, borç yazılmaz ve bakiye eksiye inmez.
- Evlilik dışı çocuk için aranan **yakınlık 60** eşiği. Çocuk artık bir düğmeyle değil ihtimalle geldiği için eşik gebeliği *sessizce* engelliyordu; evlilik dışı çocuk zaten serbest (D-047).

**Ölçüm** (60 hayat, sonuna kadar, olay seçimleri rastgele; oyuncu evlenmek ve çocuk sahibi olmak istiyor):

| | Önce | Sonra |
|---|---|---|
| Hayatında sevgilisi oldu | 44/60 | 44/60 |
| **Evlendi** | teklif verebilen 25/60 | **36/60** |
| Çocuğu oldu | — | **20/60** (1-4 çocuk) |
| Seçilen düğün | — | 33 nikâh, 2 salon, 1 parti |

Düğünlerin çoğunun nikâh olması beklenen sonuç: evlenme yaşında cüzdan genelde boş. Önemli olan artık **kimsenin parasızlık yüzünden evlenemeden kalmaması**.

**Karar soruları:**
1. Tutarlar uygun mu? Teklif 3.500 / 7.000 / 22.000 ₺; düğün 0 / 18.000 / 45.000 / 90.000 ₺.
2. Hazırlığın kabul ihtimaline katkısı (+0,08 / +0,12 / +0,18) fazla mı? Şu an tatilde teklif, sade teklife göre belirgin biçimde daha çok kabul alıyor.
3. **Korunmanın başarısızlığı modellenmeli mi?** Şu an korunulursa gebelik **hiç** olmuyor. Küçük bir ihtimal (ör. %2) gerçekçi olur ama beklenmedik çocuk doğurur.
4. Gebelik ihtimali %45 ve yaş çarpanları doğru mu? Bir yıl = bir deneme sayılıyor.
5. Kısırlık oranı **%8 + %8** (yani çiftlerin yaklaşık %15'i) uygun mu? Gerçeğe yakın ama oyunda ağır gelebilir.
6. **Gebelik süreci istenir mi?** Şu an "korunmadan yakınlaşma → o yıl bebek". Dokuz aylık bir hamilelik durumu (ve buna bağlı olaylar) ayrı bir tasarım işi.
7. Doğum masrafının "cüzdanda ne varsa o kadar" tahsil edilmesi doğru mu, yoksa borç mu yazılmalı?
8. **Tüp bebek (Faho'nun notu: "ileride"):** Aktiviteler → Sağlık menüsü ve tedavi henüz **yapılmadı**. Tedavinin bedeli, başarı ihtimali ve kaç kez denenebileceği kararlaştırılmalı. Şu an kısır bir çiftin hiçbir çıkış yolu yok; evlat edinme (D-049) duruyor.
9. Düğün, Ün açıksa küçük bir Ün payı veriyor (parti +1, salon +2); Ün kapalıysa **açılmıyor** (D-027). Düğün Ün doğurmalı mı?
10. Boşanan ya da dul kalan yeniden evlenemiyor (Q-063, ikinci evlilik yok). Yeni akışla birlikte bu eksiklik daha görünür oldu.

**Yan karar (kural gereği):** Kayıt biçimi **29**'a çıktı. Kalıcı testin zorunlu kıldığı **beş sürümlük pencere** kuralı gereği okunabilir taban 23'ten **24**'e yükseldi. Sürüm 23 kayıtları artık açılmıyor — dosya **silinmiyor**, anlaşılır mesaj gösteriliyor. Eski kayıtlarda bekleyen düğün yoktur, deneme sayacı sıfırdan başlar ve **kimse kısır sayılmaz**; geriye dönük gizli bir engel yazılmaz.


### Q-094 — Hamilelik bir süreç oldu
**Durum:** **Faho'nun kararı** (21 Eylül 2026: "hamilelik süreci olsun"). **Sayılar ve açık uçlar karar bekliyor** (`prototypeOnly`). **Kaynak:** Paket 26, `app/lib/domain/models/pregnancy.dart`, `app/lib/domain/interaction/intimacy.dart`, `app/lib/domain/generation/life_progression.dart`.

**Önceki hâli (Paket 25):** Korunmadan yakınlaşma aynı anda bebeği getiriyordu. Q-093'ün 6. sorusu buydu; Faho "olsun" dedi.

**Şu an kodda olan:** Korunmadan yakınlaşma **hamilelik** başlatıyor; bebek **bir sonraki yaş ilerlemesinde** doğuyor.

- Hamilelik **kayda girer**: uygulama kapatılıp açılsa da bekleyen bebek kaybolmaz.
- Hamileyken **ikinci gebelik başlamaz**; aynı hamilelik sürer.
- Bebeğin diğer ebeveyni **hamilelik kaydındaki kişidir**. Bekleme sırasında ayrılık olsa bile bebek başkasının çocuğu olmaz.
- Diğer ebeveyn bekleme sırasında **vefat ederse** doğum olmaz; bu **sessizce** geçmez, günlüğe yazılır.
- Doğum ekranda **bildirimle** duyurulur (D-050): "Kızınız oldu" / "Oğlunuz oldu".
- Kişi kartında hamilelik açıkça yazılır: "Hamilesin. Bebeğiniz bir sonraki yaşta doğacak." — sessizce bekleyen bir durum olmamalı.
- Hamile olan taraf oyuncunun cinsiyetine göre belirlenir; aynı cinsiyetteki çiftlerde bu yol zaten kapalı (Q-064).

**Karar soruları:**
1. Hamilelik **bir yıl** sürüyor (bir yaş ilerlemesi). Oyunun zaman birimi yıl olduğu için en küçük süre bu. Doğru mu, yoksa "aynı yaşta doğsun" mu isteniyordu?
2. **Hamilelik olayları** olsun mu? Şu an bekleme yılı boş geçiyor: ultrason, isim tartışması, kreş/beşik hazırlığı, iş yerinde izin gibi anlar yazılabilir.
3. **Düşük ve riskli gebelik** modellenmeli mi? Şu an hamilelik **her zaman** sağlıklı bir bebekle sonuçlanıyor (diğer ebeveyn vefat etmedikçe). Ağır bir konu; **bilerek eklenmedi**, karar Faho'nun.
4. Hamilelik oyuncunun **sağlığını veya mutluluğunu** etkilemeli mi? Şu an hiçbir etkisi yok.
5. **İkiz** olabilmeli mi?
6. Hamileyken yakınlaşma hâlâ serbest ve yakınlığı artırıyor; doğru mu?
7. Bebek doğduğu yıl oyuncu yaş aldığı için, çocuk sınırına (en fazla 4) dayanan hayatta hamilelik başlamıyor. Bu sınırın kendisi hâlâ `prototypeOnly` (Q-064).

**Yan karar (kural gereği):** Kayıt biçimi **30**'a çıktı; beş sürümlük pencere kuralı gereği okunabilir taban 24'ten **25**'e yükseldi. Sürüm 24 kayıtları artık açılmıyor — dosya **silinmiyor**, anlaşılır mesaj gösteriliyor. Eski kayıtlarda bekleyen bebek yoktur; **geriye dönük hamilelik uydurulmaz**.


### Q-095 — Burçlar, fal/tarot ve burçsal dönemler
**Durum:** **Faho'nun kararı** (21 Eylül 2026: "aktivite kısmına fal tarot ekle, herkesin doğduğu aya göre burcu olsun, burçsal nedenleri de ekle"). **Sayılar, metinler ve açık uçlar karar bekliyor** (`prototypeOnly`). **Kaynak:** Paket 27, `app/lib/domain/models/zodiac.dart`, `app/lib/data/fortune_catalog.dart`, `app/lib/domain/life/astrology.dart`.

**Doğum yılı hâlâ yok (D-003).** Burç yalnızca doğum **ayı ve gününden** hesaplanıyor; tarihsel takvim, dönem motoru veya doğum yılı seçimi eklenmedi. Şubat her zaman 28 gün: yıl olmadığı için artık yıl da yok.

**Şu an kodda olan:**

*1. Burç.* Hayat üretilirken doğum ayı ve günü belirleniyor ve kayda giriyor. Burç bundan hesaplanıyor; yılın 365 gününün tamamı bir burca düşüyor, boşluk yok. Burç, karakter başlığında şehirle aynı satırda görünüyor.

*2. Fal ve Tarot mekânı.* Aktiviteler menüsünde yeni alan, üç eylem: **Kahve falına baktır** (150 ₺, 14 yaş), **Tarot açtır** (400 ₺, 16 yaş), **Burç yorumunu oku** (ücretsiz, 10 yaş).

*3. Sonuçlar rastgele ve iki yönlü.* 10 kahve falı metni, 10 tarot kartı, her burç için yorumlar. Sonuç mutluluğu **artırabilir de düşürebilir de**. Olumlu etki tekrar edildikçe azalıyor ama **olumsuz etki tam uygulanıyor**: hoşuna gitmeyen falı tekrar baktırıp etkisiz hâle getiremezsin. Eylem `maxPerAge` sınırında zaten kapanıyor.

*4. Burçsal dönemler.* Yedi dönem: Merkür retrosu, Dolunay, Venüs geçişi, Mars etkisi, Satürn dönüşü, Jüpiter bolluğu, Ay tutulması. Her dönem **element** üzerinden yazıldı (ateş/toprak/hava/su), böylece her dönem üç burcu birden kapsıyor ve **her burç en az bir dönemden etkileniyor** — kalıcı bir test bunu koruyor. Yılda **%22** ihtimalle, **12 yaşından sonra**, yalnızca oyuncunun burcunu gerçekten etkileyen bir dönem çıkıyor ve ekranda bildirimle duyuruluyor. Mutluluk etkisi bildirimde yazan değerle **aynı**; sahte puan gösterilmiyor.

**Ton:** Fal ve burç yorumları **oyun içi eğlencedir**. Metinler kesin bir gelecek söylemiyor ("şunu yapacaksın" demiyor), oyunun olaylarını yönlendirmiyor ve hayatı belirlemiyor. Etkiler küçük.

**Yol boyunca çıkan iki şey:**
1. Burç önce karakter başlığının **üst satırına** eklenmişti; satır taşıp "Başa…" diye kırpılıyordu. Şehirle aynı satıra alındı.
2. Burç **simgeleri** (♈ ♉ …) ekranda **boş kutu** çiziliyordu: oyunun yazı tipleri (Baloo 2, Patrick Hand) U+2648-2653 aralığını içermiyor. Simgeler veri olarak duruyor ama **gösterilmiyor**; simgeleri olan bir yazı tipi eklenirse geri gelebilir.

**Karar soruları:**
1. Burç **gün** hassasiyetinde hesaplanıyor (21 Mart Koç, 20 Mart Balık). Sen "doğduğu aya göre" demiştin — ay yeterli mi, yoksa gün doğru mu?
2. Dönem çıkma ihtimali **%22** ve en küçük yaş **12** uygun mu?
3. Dönemlerin mutluluk etkileri (+6 ile −6 arası) fazla mı?
4. Yedi dönem yeterli mi? Element yerine tek tek burçlara özel dönemler de yazılabilir.
5. Fal ücretleri (150 ₺ / 400 ₺) ve yaş sınırları (14 / 16 / 10) uygun mu?
6. **Fal oyunun olaylarını etkilemeli mi?** Şu an yalnızca mutluluğu değiştiriyor; "falda çıkan şey gerçekten başına geliyor" diye bir bağ **bilerek** kurulmadı.
7. Kişilerin burcu **kalıcı kimliklerinden** deterministik türetiliyor, kayda ayrıca yazılmıyor. Burçlar ilişkilerde bir şey ifade etmeli mi (burç uyumu gibi)?
8. Metin sayısı yeterli mi? 10 kahve falı ve 10 tarot kartı bir hayatta tekrar edebilir.

**Yan not (kayıt):** Doğum ayı ve günü `player` içine **eklemeli** olarak yazıldı; eksik olduğunda hayatın tohumundan **deterministik** türetiliyor, yani eski kayıtlar da burcunu görüyor ve her açılışta **aynı** burcu görüyor. Bu yüzden kayıt sürümü **artırılmadı**: hiçbir eski kayıt okunamaz hâle gelmiyor ve beş sürümlük pencere boşa harcanmıyor. Sürümü yalnızca gerçekten gerektiğinde artırmak gerektiği için bu bilinçli bir tercihtir.


### Q-096 — Bildirim sesleri, menü düzeni ve genel kontrol
**Durum:** **Faho'nun kararı** (21 Eylül 2026: "genel kontrol yap, bildirim seslerini değiştir, menüleri düzgün listele"). **Sesler ve gruplama karar bekliyor** (`prototypeOnly`). **Kaynak:** Paket 28, `app/tool/make_sounds.py`, `app/lib/ui/widgets/section_scaffold.dart`.

**1. Sesler yeniden üretildi.** Ölçüm: eski yedi sesin **hepsi tek frekanslı düz sinüs tonuydu** ve tepe seviyesi ~%20'ydi — kulağa "bip" gibi geliyordu, oyunun el çizimi tonuna uymuyordu.

Yeniler marimba/tahta ve yumuşak çan modellenerek üretildi: her sesin **birden çok harmoniği**, doğal sönümü ve kısa bir vuruş anı var. Tepe seviyesi %62.

| Ses | Ne oldu | Süre |
|---|---|---|
| tap | tahta tıkırtısı (gürültü vuruşu + 880 Hz) | 90 ms |
| select | iki nota yukarı (mi → la) | 255 ms |
| back | iki nota aşağı, daha yumuşak | 280 ms |
| age_up | üç nota yukarı, çan kuyruklu — küçük bir kutlama | 750 ms |
| good | parlak majör arpej | 620 ms |
| bad | alçak, boğuk iki vuruş — **bilerek yumuşak**, ceza değil | 430 ms |
| **notice** | yumuşak kapı çanı, iki tonlu (sol → do) | 830 ms |

Sesler **koddan üretiliyor** ve üretici betik depoda: `app/tool/make_sounds.py`. Bağımlılığı yok (yalnızca standart kütüphane), yani her zaman yeniden üretilebilir. Dışarıdan alınmış ses yok.

**2. Aktiviteler menüsü gruplandı.** Kök menü on dört satıra kadar çıkıyordu ve hepsi düz bir listeydi; aradığını bulmak için bütün ekranı kaydırmak gerekiyordu. Dört gruba ayrıldı:

- **Kendine bak** — Berber, Spor salonu, Sağlık Merkezi
- **Öğren** — Kütüphane, Kurslar
- **Keyfine bak** — Eğlence, Fal ve Tarot, Seyahat, Kumarhane
- **Hayat işleri** — Sosyal medya, Ehliyet, Evlat Edinme, Vasiyet

"Birlikte vakit geçir" grupların üstünde kaldı: mekân değil, kişiler. Menü satırları da biraz kısaldı (ikon 46 → 40), böylece bir ekrana daha fazla satır sığıyor.

**3. Genel kontrolde bulunan gerçek hata.** "Hayat günlüğü" başlığı 360 px genişlikteki ekranda satırı **24 piksel taşırıyordu**: başlık esnek değildi, yanındaki çizgiyle birlikte sığmıyordu. Taşan içerik **çizilmiyor**, yerine hata şeridi geliyor. Hiçbir test bunu yakalamıyordu.

Başlık esnek yapıldı. Ayrıca **kalıcı bir koruma** eklendi (`test/layout_overflow_test.dart`): iki gerçek telefon genişliğinde (360 ve 390 px) bütün sekmeler gezilip sonuna kadar kaydırılıyor ve **tek bir taşma bile olsa** test düşüyor. Uzun ad + büyük cüzdan durumu da ayrıca sınanıyor.

**4. Karakter başlığı.** Cüzdan rozeti adla aynı satırdaydı ve uzun adlar "Tolga Er…" diye kırpılıyordu. Rozet biraz küçültüldü; burç da üst satıra değil şehir satırına alındı.

**Karar soruları:**
1. Sesler yerinde mi? Özellikle **bildirim sesi** (830 ms, iki tonlu çan) — daha kısa mı olmalı?
2. "Olumsuz sonuç" sesi bilerek yumuşak tutuldu. Daha belirgin olmalı mı?
3. Grup adları ("Kendine bak", "Öğren", "Keyfine bak", "Hayat işleri") uygun mu?
4. Gruplama doğru mu? Kumarhane "Keyfine bak" içinde; "Hayat işleri"ne mi girmeli?
5. Ses seviyesi (%62 tepe) telefonda doğru mu? Bunu ancak cihazda dinleyerek anlarız.


### Q-097 — Askerlik: yükümlülük, bedelli ve rütbeli yollar
**Durum:** **Faho'nun kararı** (21 Eylül 2026, doğrudan talimat). **Sayılar ve kapsam karar bekliyor** (`prototypeOnly`). **Kaynak:** Paket 29, `app/lib/data/military_catalog.dart`, `app/lib/domain/career/military_service.dart`.

**Faho'nun talimatı (özet):** Askerlik meslek kısmına **ayrı bir menü** olarak eklensin. 18 yaşından sonra katılınabilsin. Erkek okumuyorsa 20 yaşında zorunlu askerlik için çağrılsın veya bedelli ödesin. Bedelli ücretini **aileden ödemesini isteyebilsin**: ailede zengin biri varsa ve arası iyiyse ödeyebilir. Dileyen **subay, astsubay gibi rütbelere başvurabilsin**.

**Uygulanan:**

*1. Ayrı menü.* Meslek bölümünde **Askerlik** satırı. 18 yaşından itibaren ya da askerlikle ilgili bir kayıt varsa görünür; durumu (celp geldi / askerde / terhis / bedelli) satırda yazar.

*2. Yükümlülük ve celp.* Okumayan yükümlü **20 yaşında** çağrılır. Çağrı **sessizce** gelmez: ekranda bildirim çıkar (D-050) ve günlüğe yazılır. Okuyan öğrenci çağrılmaz (tecil). **41 yaşından sonra** celp gelmez. Aynı celp iki kez kuyruğa girmez.

*3. Üç yol.*

| Yol | Koşul | Süre | Yıllık maaş |
|---|---|---|---|
| Er olarak yap | yükümlü olmak | 1 yıl | yok |
| Astsubay ol | lise mezunu | 4 yıl | 420.000 ₺ |
| Subay ol | üniversite mezunu | 5 yıl | 560.000 ₺ |

Rütbeli yollara **başvurulur ve reddedilebilir**; kabul ihtimali zekâ ve sağlıkla yükselir (taban astsubay 0,45 · subay 0,30). Görevde iki yılda bir rütbe yükselir: Er → Onbaşı; Astsubay Çavuş → Üstçavuş → Başçavuş; Teğmen → Üsteğmen → Yüzbaşı → Binbaşı.

*4. Bedelli.* Ücret **280.000 ₺**. Kendi cebinden ödenebilir ya da **aileden istenebilir**. İstenebilecek kişi: hayatta, kan bağı ya da eş, serveti **varlıklı/çok varlıklı** ve yakınlık **en az 55**. Kabul ihtimali yakınlık ve servetle yükselir (taban 0,20). **Ret gerçektir**; "her zaman evet" yok. Aile öderse oyuncunun cüzdanından **tek kuruş çıkmaz** ve ödeyen kişi kayda geçer. Ödeyebilecek yakın yoksa **çalışmayan düğme konmaz**, gerekçesi yazılır.

*5. Hizmet etkileri (yıllık).* Sağlık +4, karizma +3, mutluluk −3; terhiste mutluluk +8.

**Karar soruları:**
1. **Zorunluluk bu prototipte yalnızca erkekler için.** Kadın oyuncu çağrılmıyor ama gönüllü olarak astsubay/subay başvurusu yapabiliyor. Doğru mu, yoksa oyunda bu ayrım hiç olmamalı mı?
2. Süreler (er 1 yıl, astsubay 4, subay 5) ve maaşlar uygun mu? Gerçek mevzuat zamanla değişiyor; oyun kendi sayısını seçmeli.
3. Bedelli **280.000 ₺** doğru mu? Oyunun ekonomisinde bu, 20 yaşındaki biri için çok yüksek olabilir — zaten aileden isteme yolu bu yüzden var.
4. Aile ödediğinde **ödeyenin serveti azalmıyor**. NPC nakdi ayrıntılı tutulmadığı için böyle; servet basamağı düşürülmeli mi?
5. Reddedilen bedelli isteğinde **hiçbir ceza yok** (yakınlık düşmüyor). Sitem etmeli mi?
6. Askerlik **işi engellemiyor**: görevdeyken iş arama hâlâ açık. Kapatılmalı mı?
7. Askerliğe hiç gitmemenin bir sonucu yok. Yükümlülüğünü yerine getirmeyen için bir yaptırım (iş bulamama gibi) istenir mi?
8. Rütbeli askerlik ayrı bir "meslek" sayılmalı mı? Şu an kariyer kaydından bağımsız ilerliyor; maaş doğrudan cüzdana yatıyor.
9. Hizmet sırasında **olay** çıkmalı mı? Şu an askerlik yılları olaysız geçiyor.

**Yan not (kayıt):** Askerlik alanı `military` olarak **eklemeli** yazıldı; eksik olduğunda "yapılmadı" olarak açılıyor. Kayıt sürümü **artırılmadı**: hiçbir eski kayıt okunamaz hâle gelmiyor ve beş sürümlük pencere boşa harcanmıyor. **Geriye dönük askerlik uydurulmaz.**


### Q-098 — Rulet animasyonu ve at yarışı
**Durum:** **Faho'nun kararı** (21 Eylül 2026: "rulet tarafında animasyon ekle, dümdüz rulet olmasın, ayrıca at yarışı da ekleyelim"). **Sayılar karar bekliyor** (`prototypeOnly`). **Kaynak:** Paket 30, `app/lib/domain/casino/horse_race.dart`, `app/lib/ui/widgets/roulette_wheel.dart`, `app/lib/ui/widgets/race_track.dart`.

**Kumarhanenin ortak kuralı sürüyor:** yalnızca oyunun sanal cüzdanıyla oynanır; gerçek para yatırma, çekme, ödüle dönüştürme, uygulama içi satın alma veya reklam karşılığı bahis hakkı **yoktur**.

**1. Rulet çarkı.** Ekranda dönen bir çark var: 37 bölme, gerçek Avrupa ruletinin **sıra dizilimi** (0, 32, 15, 19, …) ve ters yönde dönen bir top. Çark yavaşlayıp seçilen sayının üzerinde duruyor, kazanan bölme sarıyla çerçeveleniyor.

**Animasyon sonucu belirlemez.** Sayı alanda (`Roulette.spinDetailed`) tek bir `rng.nextInt(37)` ile zaten çekiliyor; çark yalnızca o sayıya iniyor. **Sonuç metni çark durmadan yazılmıyor** — dönerken sonucu okumak oyunu bozardı.

**2. At yarışı.** Yeni masa. Beş at, adları ve oranları ekranda. Oyuncu birine oynuyor, atlar pistte koşuyor ve bitiş sırasına göre varıyorlar.

- Oranlar rastgele ağırlıklardan türetiliyor, **1,8x ile 12,0x** arasında.
- Kasanın payı **%12**: oranların işaret ettiği ihtimallerin toplamı 1'i bu kadar aşıyor. (Rulette kasa payı 0'a oynamaktan gelir; burada açıkça yazılı.)
- **Kazanan bahisten bağımsız çekiliyor.** Aynı tohumla hangi ata oynanırsa oynansın kazanan değişmiyor; kalıcı bir test bunu koruyor.
- Pist yalnızca çekilmiş sonucu gösteriyor: varış sırası hiçbir zaman değişmiyor, yol boyunca küçük dalgalanmalar sadece görsel.
- Sonuç metni koşu bitmeden yazılmıyor.
- 16 Türkçe at adı havuzu (Rüzgârkıran, Doludizgin, Al Yazmalım…) — metinler bu proje için yazıldı.

**Emoji kullanılmadı.** Atlar için 🐎 denendi ama oyunun yazı tipleri emoji içermiyor ve her cihazda aynı görünmüyor; yerine kulvar numarasını taşıyan renkli jokey işareti çiziliyor.

**Yan düzeltme.** Karakter başlığındaki cüzdan rozeti büyük tutarlarda adı kırpıyordu ("Tolga Erd…"). Başlıkta artık **kısaltılmış** para biçimi kullanılıyor: 10.000 ₺'ye kadar tam, üstünde **B** (bin) ve **M** (milyon). Yalnızca gösterim içindir; hesaplarda kullanılmaz, tam tutar Varlıklar ekranında yazar.

**Karar soruları:**
1. ~~Kasanın payı **%12** uygun mu?~~ **Faho karar verdi:** "Kumarda fark kasıtlı olsun, yani genel kumar kuralı neyse öyle olsun." Yani rulet ile at yarışı arasındaki fark **bilerek** duruyor ve gerçek kumar oranlarına yaklaşıyor: tek sıfırlı rulette kasa payı **%2,7**, at yarışında bahis havuzundan kesilen pay gerçekte çok daha yüksektir (yerine göre %15-25). Oyundaki **%12** bu yüzden gerçeğinden bile **cömert** kalıyor. Soru kapandı; ayrıca ayarlama istenirse yeniden açılır.
2. Oran aralığı **1,8x – 12,0x** ve **beş at** doğru mu?
3. Koşu **3 saniye**, çark **2,6 saniye** sürüyor. Çok uzun mu?
4. "Yeni kadro" düğmesi bedelsiz ve sınırsız: oyuncu beğenmediği oranları yenileyebiliyor. Sınırlanmalı mı?
5. At yarışı için ayrı bir **yıllık bütçe** mi olmalı, yoksa kumarhaneyle ortak mı kalsın? Şu an ortak.
6. Yarış sonucu hayat günlüğüne yazılıyor; her koşu bir satır. Günlük şişer mi?
7. Başlıktaki kısaltma (400 B ₺) okunur mu, yoksa tam tutar mı görünmeli? Uzun ad + tam tutar aynı satıra sığmıyor.

### Q-099 — Askerlik tecili ve bakaya (askerden kaçma)

**Durum:** Faho'nun isteğine göre kodlandı; sayıların onayı bekleniyor. Kod: Paket 31 (`lib/domain/career/military_service.dart`, `lib/domain/models/military.dart`, `lib/ui/screens/sections/military_page.dart`).

**Faho'nun isteği:** "20 yaşına gelip okumuyorsa askerliğe çağrılsın bildirim paneli olarak gelsin… tecil ettirme hakkı olsun 2 yıllık tecil, eğer okuyorsa otomatik okul okuduğu dönem boyunca tecil edilsin fakat bu bildirim panelinde bildirilsin… okul bittiğinde direkt çağırsın… 3 seçenek olsun: bedelli parasını öde, zorunlu askerliğini yap, tecil bitmiş olsa bile askerden kaçabilsin fakat yakalanabilsin, normal Türkiye'deki gibi."

**Araştırma notu (gerçek hayattan, birebir kopya değil):** Türkiye'de yoklama kaçağı/bakaya durumu cezai değil **idari para cezası** ile karşılanıyor; ceza geciken süreyle birlikte büyüyor ve **kendiliğinden başvuran, yakalanana göre daha az** ödüyor. Tekrarlayan yakalanmalarda dosya ağırlaşıyor. Öğrenciler okudukları süre boyunca tecilli sayılıyor, okul bitince sevk sırası geliyor. Oyun bu mantığı taklit ediyor, resmî tutarları değil.

**Kodlanan kurallar:**

*Tecil*
- Çağrılan yükümlü tecil ettirebiliyor: **2 hak, her biri 2 yıl** (`prototypeOnlyMaxDeferrals = 2`, `prototypeOnlyDeferralYears = 2`).
- Okuyan biri **otomatik** tecil ediliyor ve bu artık **sessiz değil**: bildirim panelinde "askerliğin geldi, okulun tecil ettirdi" yazıyor. Okul tecili **hak harcamıyor**.
- Askerlik menüsünde durum "Tecilli — okul bitene kadar" / "Tecilli — 24 yaşına kadar" diye görünüyor.
- Tecil bitince ya da okul bitince **doğrudan yeniden çağrı** geliyor, yine bildirim paneliyle.

*Bakaya (kaçma)*
- Çağrıldıktan sonra kaçılabiliyor; tecil hakkı bitmiş olsa da.
- Yakalanma ihtimali ilk yıl **%30**, her kaçak yıl **+%10** (üst sınırla).
- İdari ceza kaçılan gün üzerinden büyüyor: kendiliğinden teslim olan **günde 50 ₺**, yakalanan **günde 100 ₺** (tam iki katı).
- Yakalanınca ceza kesiliyor, yeniden çağrılıyor, `caughtCount` artıyor. Cüzdan eksiye inmiyor.
- Bakayanın bedellisi **her kaçak yıl için +60.000 ₺** ek bedelle pahalanıyor.
- Yükümlülük yaşı geçince dosya kapanıyor (durum "yükümlü değil").

**Karar soruları:**
1. **Tecil hakkı sayısı çelişkili geldi.** İstekte önce "1 kere tecil ettirme hakkı olsun 2 yıllık tecil", sonra "gene 2 sefer tecil hakkı olsun 2 senelik" yazıyor. **2 hak × 2 yıl** olarak kodlandı. Doğrusu bu mu, yoksa 1 hak mı olsun?
2. Yakalanma ihtimali **%30 + yılda %10** uygun mu? Bu haliyle ortalama 3-4 yılda yakalanılıyor; ömür boyu kaçmak neredeyse imkânsız. Kaçabilen bir azınlık olsun mu?
3. Günlük ceza (**50 ₺ / yakalanınca 100 ₺**) ve bedelli ek bedeli (**yılda 60.000 ₺**) doğru ağırlıkta mı? Şu an 3 yıl kaçmak yaklaşık 55.000 ₺ ceza, bedelli ise 180.000 ₺ zamlanıyor.
4. Kaçakken **iş bulmak, evlenmek, yurt dışına çıkmak** engellenmeli mi? Şu an hiçbiri engellenmiyor — yalnızca para ve yakalanma riski var.
5. Yakalanma **kaç kez** olabilmeli? Şu an sınırsız; her seferinde yeniden çağrılıyor ve tekrar kaçılabiliyor. Belli sayıdan sonra zorunlu sevk mi olsun?
6. Okul tecili **hak harcamıyor**; üniversite + yüksek lisans okuyan biri 2 hakkını hiç kullanmadan 28'e geliyor. Böyle mi kalsın?
7. Kaçaklık **mutluluk/itibar** düşürmeli mi? Şu an yalnızca para etkisi var, ruh hâline dokunmuyor.

---

### Q-100 — Dövüş sanatları: karate, kung fu, yağlı güreş ve eğitmenlik

**Durum:** Faho'nun isteğine göre kodlandı; sayıların onayı bekleniyor. Kod: Paket 32 (`lib/data/martial_arts_catalog.dart`, `lib/domain/activities/martial_arts_engine.dart`, `lib/ui/screens/sections/martial_arts_page.dart`).

**Faho'nun isteği:** "Aktivitelerde spor içerisine kungfu dersleri koyalım, ders başı ücret az olsun. Orada aldığım eğitimde çok ustalaşırsam… kungfunun son seviyesi vb. iş imkânı olarak kungfu eğitmeni olabileyim. Aynısını karateye de ekleyelim, güreş de ekleyelim. Onlarda da seviyeleri internetten araştır; üst seviyeye geldiğinde iş imkânı olarak eğitmenliğini yapabilelim."

**Araştırma notu (basamak adları gerçek, sayılar değil):**
- **Karate:** öğrenci dereceleri *kyu* (aşağıya doğru sayılır), ustalık dereceleri *dan*. Kahverengi kuşak siyaha geçiş sayıldığı için 3., 2. ve 1. kyu diye üçe ayrılıyor. Oyunda beyaz (9. kyu) → siyah kuşak 3. Dan.
- **Kung fu / wushu:** okullarda beyazdan siyaha kuşak (sash) düzeni yaygın; üstünde Çin Wushu Federasyonu'nun *duanwei* dereceleri var. Oyunda beyaz kuşak → siyah kuşak → 1./2./3. Duan.
- **Yağlı güreş:** Kırkpınar'da boy sıralaması minikten başa gider: minik, teşvik, tozkoparan, ayak, deste, küçük orta, büyük orta, başaltı, baş (başpehlivan). Oyun bu sırayı izliyor.

**Kodlanan kurallar:**
- Bölüm **spor salonunun içinde**: Aktiviteler → Spor salonu → Dövüş sanatları.
- Ders ücreti düşük: karate 180 ₺, kung fu 200 ₺, güreş 150 ₺.
- **Ustalık parayla değil yılla geliyor:** bir yaşta en fazla **20 ders** alınabiliyor. Karatede siyah kuşak 110 ders, yani en az 5-6 yıl; en üst basamak 10 yılı buluyor. Kalıcı bir test "en üst basamak en az 5 yıl sürer" diye koruyor.
- Her ders sağlık +2, mutluluk +1; basamak atlayınca ek sağlık/mutluluk/karizma ve hayat günlüğüne satır.
- Dallar birbirinin yıllık kotasını yemiyor.
- **Eğitmenlik:** karate siyah kuşak (1. Dan), kung fu siyah kuşak, güreş başaltı basamağında meslek kataloğunda bir iş açılıyor (Karate eğitmeni, Kung fu eğitmeni, Güreş antrenörü). Kuşağı olmayan başvuramıyor, bir daldaki kuşak başka dalı açmıyor, üçünün de kendi mülakat soruları var. Yan karakterlere rastgele dağıtılmıyor.

**Karar soruları:**
1. **Eğitmenlik eşiği "üst seviye" mi olmalı, yoksa siyah kuşak yetmeli mi?** İstekte "üst seviyeye geldiğinde" deniyor; gerçekte eğitmenlik genellikle siyah kuşakla başlıyor, en üst dan derecesiyle değil. Şu an **siyah kuşak / başaltı** eşiği kodlandı. En üst basamağa mı çekilsin?
2. Ders ücretleri (**150-200 ₺**) ve yıllık ders sınırı (**20**) doğru mu? Bu haliyle yılda 3.000-4.000 ₺ harcanıyor ve siyah kuşak 5-6 yıl sürüyor.
3. Eğitmenlik maaşları (**270.000-300.000 ₺/yıl**) diğer mesleklere göre yerinde mi?
4. Güreşte **başpehlivanlık** yalnızca ders sayısıyla mı gelmeli? Gerçekte Kırkpınar'da güreşilip kazanılıyor. Sonradan bir **turnuva olayı** eklensin mi?
5. Dövüş sanatı **olaylara** yansımalı mı? Şu an yalnızca sağlık/mutluluk/karizma veriyor; kavga, taciz ya da hırsızlık olaylarında ayrı bir seçenek açmıyor.
6. Sakatlanma olmalı mı? Şu an ders hiçbir zaman zarar vermiyor.
7. Bir dalda ilerlerken başka dala da aynı anda devam edilebiliyor. Sınırlanmalı mı (aynı anda tek dal)?
8. Bölüm spor salonunun **içine** kondu. Ana aktivite menüsünde ayrı satır mı olsun?

---

### Q-101 — Milli Piyango: bilet, ikramiye basamakları ve kasa payı

**Durum:** Faho'nun isteğine göre kodlandı; sayıların onayı bekleniyor. Kod: Paket 33 (`lib/data/lottery_catalog.dart`, `lib/domain/casino/lottery.dart`, `lib/ui/screens/sections/lottery_page.dart`).

**Faho'nun isteği:** "Milli piyango bileti de olsun, bilet satın alabilsin, ikramiye vurabilsin."

**Araştırma notu:** Milli Piyango bileti gerçekte **tam, yarım ve çeyrek** olarak satılıyor; çeyrek bilet ikramiyenin dörtte birini alıyor. Yılbaşı çekilişi ayrı ve çok daha büyük (2026 yılbaşında tam bilet 800 ₺, büyük ikramiye 800 milyon ₺). İkramiye basamaklarının altında **amorti** var: bilet parasını geri veriyor. Oyun bu yapıyı taklit ediyor, resmî tutarları değil.

**Kodlanan kurallar:**
- İki çekiliş: **olağan** (tam 200 ₺, yılda en çok 12 bilet) ve **yılbaşı** (tam 800 ₺, yılda en çok 4 bilet).
- Basamaklar: büyük, ikinci, üçüncü, dördüncü ikramiye, teselli ve amorti. İhtimaller ekranda **açıkça yazılı** (1/500.000 gibi); gizlenmiyor.
- Bilet yıl içinde alınıyor, **çekiliş yaş ilerlerken** yapılıyor, sonuç bildirim panelinde çıkıyor. Bilet kayda giriyor.
- **Kasanın payı bilerek büyük:** kuramsal geri dönüş **%56** (kasa payı %44). Rulette %2,7, at yarışında %12 — piyango en pahalısı. Bu, Faho'nun Q-098/1 kararının doğrudan uygulanmasıdır.
- Piyango da kumar sayılıyor: yıllık bahis kaydına giriyor ve **ayarlardan kumar kapatılınca bayi de kapanıyor**.
- 18 yaşından küçüğe bilet satılmıyor.

**Karar soruları:**
1. Kasanın payı **%44** (geri dönüş %56) uygun mu? Gerçek piyangolarda geri dönüş yaklaşık yarıdır; oyunda da öyle duruyor.
2. Büyük ikramiye tutarları (**olağan 20 milyon ₺**, **yılbaşı 800 milyon ₺**) oyunun ekonomisini bozar mı? Vuran oyuncu bir anda her şeyi satın alabilir hâle geliyor; hayatın gerisi anlamsızlaşır mı?
3. Yıllık bilet sınırı (**olağan 12, yılbaşı 4**) doğru mu?
4. Piyango parası **yıllık bahis bütçesine** yazılıyor ama bütçeyle **sınırlanmıyor** — yalnızca bilet sayısıyla sınırlı. Kumarhane bütçesini de yemeli mi?
5. **Ayarlardan kumar kapatılınca piyango da kapanıyor.** Doğru mu, yoksa piyango "kumar" sayılmayıp açık mı kalsın?
6. Çekiliş **yıl sonunda** toplu yapılıyor; oyuncu bileti alıp yaş ilerletince sonucu görüyor. Çekiliş anı için bir **animasyon** (çark/top) istenir mi?
7. Büyük ikramiye vurunca ayrı bir **hayat olayı** (akrabaların araması, dolandırıcılar, yeni "arkadaşlar") çıksın mı?
8. Bilet numarası şu an rastgele. Oyuncu **kendi numarasını seçebilsin** mi?

---

### Q-102 — Finger: tanışma uygulaması

**Durum:** Faho'nun isteğine göre kodlandı; kurallar ve sayılar karar bekliyor. Kod: Paket 34 (`lib/data/finger_catalog.dart`, `lib/domain/interaction/finger.dart`, `lib/ui/screens/sections/finger_page.dart`).

**Faho'nun isteği:** "Oyun içerisine gene aktiviteler bölümüne dating app koyalım, adı Finger olsun, içerisinde bildiğin Tinder gibi ilişki arayan insanlar olsun, eşleştiğin ile tanış vb."

**Kodlanan kurallar:**
- **Aktiviteler → Finger**, 18 yaşından itibaren.
- Profilde ad, yaş, şehir, meslek, kısa tanıtım ve 2-4 ilgi alanı var. **Gerçek fotoğraf yok**; baş harfler gösteriliyor.
- **Beğen / Geç.** Beğeni her zaman karşılık bulmuyor: taban ihtimal %22, görünüş ve karizma yükseldikçe %67'ye kadar çıkıyor. Oran ekranda açıkça yazılı.
- Bir yılda **25 profile** bakılabiliyor; sonsuz kaydırma yok.
- **Eşleşmek tanışmak değildir.** Eşleşme bir listeye düşüyor; "Tanış" denince kişi oyunun kişi listesine **kalıcı kimlikle** giriyor ve oradan sonra normal ilişki kurallarıyla işliyor.
- **Bekârsa** tanışılan kişi sevgili, **sevgilisi/eşi varsa** arkadaş oluyor. Uygulama var olan ilişkiyi kendiliğinden bitirmiyor.
- Bütün profil metinleri bu proje için yazıldı.

**Karar soruları:**
1. Eşleşme ihtimali (**%22 taban, görünüş+karizmayla %67'ye kadar**) doğru mu? Çok cömert mi?
2. Yıllık **25 profil** sınırı yerinde mi?
3. **Sevgilisi varken** eşleşen kişiyle tanışınca **arkadaş** oluyor. Bunun yerine "aldatma" seçeneği mi olmalı? Şu an oyun aldatmayı hiç ele almıyor; bu ayrı ve büyük bir karar.
4. Profiller şu an **karşı cinsten** üretiliyor — `Romance.start` ile aynı geçici varsayım. Yönelim ve eşleşme kuralları hâlâ karara bağlı (Q-0xx romantik ilişki başlığıyla birlikte düşünülmeli).
5. Uygulama **ücretsiz**. Gerçeğindeki gibi ücretli bir "üst paket" (daha çok beğeni, kimin beğendiğini görme) eklensin mi?
6. Eşleşip **hiç tanışılmayan** profiller listede sonsuza kadar duruyor. Bir süre sonra "yazışma söndü" diye düşsün mü?
7. Tanışılan kişiyle ilk buluşma şu an **kesin** başarılı. Kötü geçen bir buluşma ihtimali olsun mu?
8. Uygulamanın kendisi mutluluğu etkilemiyor. Sürekli geçilen/karşılık bulmayan beğeniler moral düşürsün mü?
9. Adı **Finger** olarak kondu (Faho'nun isteği). Uygulama içi metinlerde marka çağrışımı yapmamaya dikkat edildi; başka bir ad istenirse kolayca değişir.

---

### Q-103 — Tüp bebek tedavisi

**Durum: KARARLAŞTIRILDI.** Faho bu maddenin tamamını onayladı; kesin kural `DECISIONS.md` içinde **D-054** olarak kayıtlıdır. Aşağıdaki sorular **kapanmıştır**, tarihsel kayıt olarak duruyor.

**Faho'nun isteği:** "İleride aktiviteler menüsünün içerisine sağlık menüsü olacak, tüp bebek tedavisi eklenebilir."

**Neden gerekliydi:** Paket 25'te kısırlık gerçek bir sonuç oldu — oyuncu ya da eşi %8 ihtimalle kısır olabiliyor ve bunu ancak deneyerek anlıyor. O günden beri kısır bir çiftin **tıbbi hiçbir çıkış yolu yoktu**; yalnızca evlat edinme (D-049) duruyordu.

**Araştırma notu:** Tüp bebekte canlı doğum oranı yaşla birlikte keskin biçimde düşüyor: 35 altında yaklaşık %42-52, 35-37 arası %37-41, 38-39 arası %28-32, 40-42 arası %16-20, 43-44'te %5, 44 üstünde %2'nin altı. Üç denemede kümülatif oran %60-70'e çıkabiliyor. Oyundaki basamaklar bu aralıkları izliyor; tutarlar ve ücret oyunun kendi ekonomisine göre konuldu.

**Kodlanan kurallar:**
- **Aktiviteler → Sağlık Merkezi → Tüp bebek tedavisi.** Yalnızca eşi/sevgilisi olan oyuncuya görünüyor.
- Bir deneme **120.000 ₺**; ücret **her hâlükârda** ödeniyor.
- Başarı oranı taşıyacak tarafın yaşına göre: 35 altı %45, 35-37 %38, 38-39 %30, 40-42 %18, 43-44 %6, 45-46 %2, sonrası sıfır.
- Çiftten biri kısırsa oran **0,6 ile çarpılıyor** — düşüyor ama **sıfırlanmıyor**. Tedavinin bütün anlamı bu.
- **Kapı, oyuncunun zaten gördüğü uyarıyla aynı eşikte açılıyor:** dört başarısız denemeden sonra çıkan "bir süredir deniyorsunuz ama olmuyor; bir hekime görünmek iyi gelebilir" cümlesi artık gerçek bir yolu işaret ediyor.
- Yılda bir deneme (gerçekte bir döngü aylar sürer).
- Başarısızlık mutluluğu **8**, eşle yakınlığı **2** düşürüyor; başarı mutluluğu **12** artırıyor.
- Başarı hamilelik başlatıyor, bebek bir sonraki yaşta doğuyor (Paket 26 akışı).
- **Hiçbir metin "kısırsın" demiyor** (Paket 25 kuralı); kalıcı bir test bunu koruyor.

**Karar soruları:**
1. Deneme ücreti **120.000 ₺** doğru mu? Karşılaştırma: bedelli askerlik 280.000 ₺, salonda düğün 90.000 ₺, yıllık maaşlar 180.000-560.000 ₺.
2. Kısırlık çarpanı **0,6** uygun mu? Daha düşük olursa tedavi umutsuzlaşır, daha yüksek olursa kısırlık anlamsızlaşır.
3. **Deneme sayısına üst sınır** olmalı mı? Şu an sınırsız (yılda bir). Parası olan oyuncu yıllarca deneyebiliyor.
4. Gerçekte SGK belli koşullarda sınırlı sayıda denemeyi karşılıyor. Oyuna **devlet katkısı** girsin mi, yoksa tek fiyat mı kalsın?
5. Başarısızlığın mutluluk ve yakınlık cezası (**-8 / -2**) fazla mı, az mı? Süreç gerçekte ağır; oyun bunu ne kadar taşımalı?
6. Tedaviden **ikiz** çıkabilmeli mi? Gerçekte tüp bebekte ikiz oranı belirgin biçimde yüksek. (Q-094'teki ikiz sorusuyla birlikte düşünülmeli.)
7. Tedavi için **yaş üst sınırı 46**; sonrası sıfır. Doğru mu?
8. Tedavi süreci **olay üretmeli mi** (iğneler, bekleme, aileden gelen sorular)? Şu an tek bir düğme.

---

### Q-104 — İkinci evlilik

**Durum: KARARLAŞTIRILDI.** Faho bu maddenin tamamını onayladı; kesin kural `DECISIONS.md` içinde **D-055** olarak kayıtlıdır. Aşağıdaki sorular **kapanmıştır**, tarihsel kayıt olarak duruyor.

**Önceki hâli:** Boşanan ya da eşini kaybeden oyuncu yeni sevgili edinebiliyor ama **evlenemiyordu**. Ekranda "Bu prototipte ikinci evlilik yok; ilk evliliğin kaydı korunuyor" yazıyordu. Sebep teknikti: yeni bir kayıt açmak eskisinin üzerine yazmak olurdu ve bu projede kayıt asla silinmez.

**Kodlanan kurallar:**
- Yürüyen evlilikte ikinci evlilik **hâlâ engelli** ("Zaten evlisin").
- Kayıt boşanmış ya da dul ise **yeniden evlenilebiliyor**.
- Düğünde sona ermiş kayıt `pastMarriages` listesine **taşınıyor**, üzerine yazılmıyor. Kiminle, kaç yaşında evlenildiği ve nasıl bittiği hayat boyu duruyor.
- Eski eşin evlilik kaydı kişi ekranında **hâlâ görünüyor**.
- Üçüncü, dördüncü evlilikte geçmiş birikiyor.
- Miras kuralı (D-037) ve ebeveyn durumu **yürüyen** kayıttan okunmaya devam ediyor.

**Karar soruları:**
1. İkinci evlilik için **bekleme süresi** olmalı mı? Şu an boşandıktan sonraki yıl yeniden evlenilebiliyor.
2. Önceki evlilikler yeni teklifin **kabul ihtimalini** etkilemeli mi? Şu an etkilemiyor; üç kez boşanmış biri ilk kez evlenecek biriyle aynı şansa sahip.
3. **Nafaka / mal paylaşımı** olmalı mı? Şu an boşanmanın hiçbir parasal sonucu yok — ikinci evlilik açılınca bu boşluk daha görünür hâle geliyor.
4. Önceki evlilikten olan **çocukların** yeni eşle ilişkisi modellenmeli mi? Şu an hiçbir şey olmuyor.
5. Evlilik geçmişi oyuncuya **nerede** gösterilmeli? Şu an yalnızca ilgili kişinin ekranında. Ayrı bir "evlilik geçmişi" bölümü ya da hayat sonu değerlendirmesinde bir satır ister misin?
6. Boşanma şu an serbest ve bedelsiz. İkinci evlilik açıldığına göre boşanmaya bir **koşul** gelmeli mi?

---

### Q-105 — Hayat sonu değerlendirmesi yeni sistemleri görüyor

**Durum: KARARLAŞTIRILDI.** Faho bu maddenin tamamını onayladı; kesin kural `DECISIONS.md` içinde **D-056** olarak kayıtlıdır. Aşağıdaki sorular **kapanmıştır**, tarihsel kayıt olarak duruyor.

**Bulunan boşluk:** Paket 29-36 arasında askerlik, dövüş sanatları ve ikinci evlilik eklendi. Hayat sonu değerlendirmesi (Q-090) bunlardan **hiçbirini görmüyordu**. Ölçüde şu çıkıyordu: başpehlivanlığa çıkmış ya da binbaşı olarak terhis olmuş bir hayat, hiç salona gitmemiş ve hiç askere gitmemiş bir hayatla **aynı** puanı alıyordu. Eklenen sistemler menüde duruyor ama hayatın anlatısına girmiyordu.

**Kodlanan kurallar (hepsi `prototypeOnly`):**
- **Emek** eksenine askerlik: terhis **+8**, her hizmet yılı **+2** (en çok 10), rütbeli yol (astsubay/subay) **+8**. Bedelli ödemek hizmet sayılmıyor; kaçmak hiç sayılmıyor.
- **Deneyim** eksenine dövüş sanatları: her dal için `ulaşılan basamak / dalın toplam basamağı` oranının **18 katı**, toplamda en çok **30**. Basamak sayısı değil, **ne kadar yükselindiği** sayılıyor — böylece dokuz basamaklı güreşle on iki basamaklı karate adil karşılaştırılıyor.
- **İlkler** listesine: terhis (rütbesiyle), dövüş sanatlarında en üst basamak, ve **bütün evlilikler** (Paket 36'dan sonra birden fazla olabiliyor; önceden yalnızca sonuncusu yazılıyordu).
- "Yaşı bilinmeyen bir an ilkler listesine girmez" kuralı korundu: terhis yaşı ya da zirve yaşı kayıtlı değilse satır yazılmıyor.

**Karar soruları:**
1. Askerliğin **Emek** ekseninde olması doğru mu, yoksa kendi ekseni mi olmalı? Şu an iş hayatıyla aynı kefede.
2. **Bedelli ödemek hiç sayılmıyor.** Doğru mu? Bedelli de bir yükümlülüğün yerine getirilmesi; sıfır mı olmalı, yoksa küçük bir puan mı?
3. **Kaçak kalmak hiç sayılmıyor** ama **ceza da almıyor**. Ömrü boyunca bakaya kalmış biri değerlendirmede bunu hiç görmüyor. Eksi puan ya da ayrı bir satır ister misin?
4. Dövüş sanatlarının **Deneyim**'de olması doğru mu? Başpehlivanlık bir deneyim mi, yoksa bir **emek** mi?
5. Ağırlıklar (askerlik en çok **26**, dövüş en çok **30**) diğer kalemlerle kıyaslandığında yerinde mi? Karşılaştırma: şehir gezmek en çok 28, kitap 24, ehliyet 12.
6. **Piyango ve tüp bebek değerlendirmede hiç yok.** Büyük ikramiye vurmuş bir hayat ya da tüp bebekle çocuk sahibi olmuş bir hayat ayrıca anılmalı mı? (Tüp bebekte şu an **yaş kaydı tutulmadığı** için "ilkler" listesine giremiyor; istenirse kayda yaş eklenir.)
7. Finger üzerinden tanışıp evlenmek ayrıca anılmalı mı?

---

### Q-106 — Kalıcı hobiler

**Durum: KARARLAŞTIRILDI.** Faho bu maddenin tamamını onayladı; kesin kural `DECISIONS.md` içinde **D-057** olarak kayıtlıdır. Aşağıdaki sorular **kapanmıştır**, tarihsel kayıt olarak duruyor.

**Mevcut kesin kural:** İkinci bir aktivite sistemi kurulmayacak; mevcut Kurslar, Kütüphane, Spor salonu, Resim ve Müzik altyapısı kullanılacak. Yeni meslek ağacı ya da profesyonel sanatçı yolu açılmayacak (Issue #67 sınırı). Kayıt asla silinmez.

**Kodlanan kurallar (hepsi `prototypeOnly`):**
- Dört hobi var ve **yalnızca gerçekten var olan eylemlerle** besleniyor: müzik (müzik kursu), resim (resim atölyesi), okumak (kütüphanede **bitirilen** kitap), spor (koşu, ağırlık, esneme ve dövüş dersleri).
- Her hobi beş basamak: Heveslendin → Meraklı → Düzenli → Tutkulu → Ustalaşmış. Eşikler müzik/resimde 0-6-18-40-80, okumada 0-3-8-18-35, sporda 0-8-25-55-110.
- Basamak yükseldiğinde geçmişe **bir** anı düşüyor, gerçek yaşıyla. Uydurma anı üretilmiyor.
- Hobi **silinmiyor**. 5 yıldan uzun süre uğraşılmazsa "sürüyor" sayılmıyor, ama kayıtta duruyor ve geçmişe dönüş olayı buna bakıyor.
- Olaylarda "ciddi hobi" eşiği **3 yıl**.
- Hiçbir eylemin ücreti, yaş sınırı ya da yıllık kotası değişmedi; hobi yalnızca zaten izin verilen bir eylem yapıldığında ilerliyor.

**Karar soruları:**
1. Dört hobi yeterli mi? Eksik gördüğün ve **mevcut bir eylemle beslenebilecek** başka bir hobi var mı? (Olmayan bir eylem için sahte düğme açılmadı.)
2. Eşikler doğru mu? Müzik kursu yılda en çok 2 kez yapılabiliyor; "Ustalaşmış" için 80 deneyim demek pratikte **40 yıl** demek. Çok mu uzun?
3. Basamak adları uygun mu? ("Heveslendin", "Tutkulu", "Ustalaşmış")
4. **5 yıl** ara verince "sürüyor" sayılmamak doğru mu? Daha kısa mı, daha uzun mu?
5. Hobi ekranda **nerede** görünmeli? Şu an yalnızca hayat sonu değerlendirmesinde ve olay şartlarında var; oyuncu hobisinin hangi basamakta olduğunu göremiyor. Yeni ana menü açmadım, NAV sırasına dokunmadım — ayrı bir bölüm ister misin, yoksa mevcut bir ekranın içine mi girsin?
6. Hobi **başka kimlere** görünmeli? Şu an iş, arkadaşlık, romantik ve çocuk olaylarında karşılık buluyor. Ebeveyn ya da kardeşle de bir sahne olsun mu?
7. Hobinin **stat etkisi** olmalı mı? Şu an hobi hiçbir stata doğrudan katkı yapmıyor (eylemin kendi katkısı zaten var). Kasıtlı olarak böyle bırakıldı; "yıllardır müzikle uğraşan" biri karizmada ayrıca kazanmalı mı?
8. Hayat sonu değerlendirmesinde hobinin ağırlığı (Deneyim ekseninde toplam en çok **26**) yerinde mi? Karşılaştırma: dövüş sanatları 30, şehir gezmek 28, kitap 24.
9. Bir hobi **bırakılabilmeli mi**? Şu an bırakma düğmesi yok; uğraşılmadıkça kendiliğinden soluyor.

---

### Q-107 — Evcil hayvanlar

**Durum: KARARLAŞTIRILDI.** Faho bu maddenin tamamını onayladı; kesin kural `DECISIONS.md` içinde **D-058** olarak kayıtlıdır. Aşağıdaki sorular **kapanmıştır**, tarihsel kayıt olarak duruyor.

**Mevcut kesin kural:** İkinci bir evcil hayvan sistemi kurulmayacak; `GameState.pets` kullanılacak. v1'de yalnızca kedi ve köpek sahiplenilebilir. Evcil hayvan miras kalemi değildir. Kayıt asla silinmez. Bu paket, `Q-067`'deki "hayvanın yaşı tutulmuyor, kuşaklar arası taşımak ölümsüz hayvan üretirdi" gerekçesini de kapatıyor: artık gerçek yaş var.

**Kodlanan kurallar (hepsi `prototypeOnly`):**
- Sahiplenme 7 yaşından itibaren, aynı anda en çok 3 hayvan.
- Kedi: 900 ₺ sahiplenme, 4.800 ₺ yıllık bakım, 1.500 ₺ veteriner, olağan ömür 15 (üst sınır 21). Köpek: 1.200 ₺ / 7.200 ₺ / 2.200 ₺, olağan ömür 12 (üst sınır 18).
- Dört etkileşim: vakit geçir (yılda 3), oyun oyna (3), bakım yap (2, 250 ₺), veterinere götür (1, tür ücreti). Aynı yıl tekrar edildikçe kazanç 1,0 → 0,6 → 0,3 katına iniyor.
- Bakım gideri yılda **bir kez**. Para yetmezse eldeki kadarı harcanıyor, cüzdan eksiye düşmüyor, mutluluk -4 ve bağ -3; hayvan **ölmüyor**.
- Doğal vefat olağan ömrün yarısından sonra artan bir eğriyle geliyor, üst sınırda kesinleşiyor. Mutluluk kaybı bağa göre -8 ile -18 arasında.
- Hayat başında evde bulunabilen kuş, kaplumbağa ve balık kayıtta kalıyor, yaşlanıyor ve vefat ediyor; sahiplenme menüsünde görünmüyorlar.

**Karar soruları:**
1. Bakım giderleri doğru ölçekte mi? Karşılaştırma: yıllık öğretmen maaşı 180.000 ₺ civarı, resim atölyesi 1.600 ₺, salonda düğün 90.000 ₺.
2. Aynı anda **3 hayvan** sınırı uygun mu?
3. Parasızlıkta hayvan ölmüyor, yalnızca mutluluk ve bağ düşüyor. Doğru mu, yoksa hayvanın sahiplendirilmesi gibi bir sonuç mu olmalı? (Ölüm bilerek yazılmadı: oyuncuyu cezalandırmanın en acı yolu olurdu.)
4. Hayvanın **sağlığı** ayrı bir sayı olmalı mı? Şu an yalnızca yaş ve bağ var; veteriner ziyareti ömrü uzatmıyor. Uzatmalı mı?
5. Hayvan **kaybolup bir daha dönmeyebilmeli mi**? Şu an olayda mutlaka bulunuyor.
6. Kedi ve köpek dışında bir tür v1'e eklensin mi? (Kuş, kaplumbağa ve balık kayıt düzeyinde zaten var; yalnızca sahiplenme kapalı.)
7. Hayvan **hayat sonu değerlendirmesinde** anılmalı mı? Şu an hiç görünmüyor; 14 yıl birlikte yaşanmış bir köpek ile hiç hayvan beslememiş bir hayat aynı puanı alıyor.
8. Kuşak değişiminde hayvan hanede kalıyorsa devam ediyor. Yeni oyuncunun onunla **bağı** ne olmalı? Şu an eski bağ olduğu gibi taşınıyor.
9. Hayvanla ilgili etkileşimler kişi ekranındaki gibi bir "hayvan detay" sayfasına mı taşınmalı? Şu an hepsi tek listede.

---

### Q-108 — Eğlence aktivitelerinin gerçek kişilerle yapılması

**Durum: KARARLAŞTIRILDI.** Faho bu maddenin tamamını onayladı; kesin kural `DECISIONS.md` içinde **D-059** olarak kayıtlıdır. Aşağıdaki sorular **kapanmıştır**, tarihsel kayıt olarak duruyor.

**Mevcut kesin kural:** İkinci bir aktivite sistemi kurulmayacak. Kimse uydurulmayacak: yanına gelen kişi kayıtta gerçekten duran, yaşayan, erişilebilen biri olacak (D-024, Paket 3 erişilebilirlik kuralı). Kayıt ikilenmeyecek.

**Kodlanan kurallar (hepsi `prototypeOnly`):**
- Yalnızca **Eğlence** eylemleri birlikte yapılıyor (park, sinema, kafe, maç, konser). Berberde ya da sağlık ocağında "yanına biri" gelmiyor.
- Katılabilen bağlar: eş, sevgili, çocuk, anne, baba, kardeş ve bağı **45 ve üzeri** olan arkadaş.
- Çocuk için ayrıca **4 yaş** alt sınırı; ayrıca herkes için eylemin kendi yaş sınırı geçerli (konser 13, maç 8, kafe 11).
- Ücret **bir kez**: birlikte gitmek yalnız gitmekle aynı parayı götürüyor.
- Birlikte gitmek mutluluğa **+3**, bağa **+6** ekliyor; aynı yıl aynı kişiyle tekrar çıkıldıkça 1,0 → 0,6 → 0,3 katına iniyor (bağ artışı en az 1'de kalıyor).
- Ortak geçmişe **tek** satır düşüyor ve kişiye bağlanıyor.
- Sahne hem eyleme hem bağ türüne göre seçiliyor; 30'un üzerinde özgün metin var.

**Karar soruları:**
1. Birlikte gidince bilet **iki kişilik** olmalı mı? Şu an tek ücret alınıyor (basitlik için). Gerçekçi olan iki bilet; ama o zaman "birlikte gitmek" cezalandırılmış gibi olur.
2. "Yakın arkadaş" eşiği **45 bağ** doğru mu?
3. Kişi **reddedebilmeli mi**? Şu an çağırdığın herkes geliyor. Bağı düşük olan ya da küs olan reddetsin mi?
4. Bağ artışı **+6** yerinde mi? Karşılaştırma: Vakit Geçir etkileşimi +7 civarında ve ücretsiz.
5. Aynı anda **birden fazla kişi** götürülebilmeli mi? (Bütün aileyle sinemaya gitmek.)
6. Eğlence dışında hangi eylemler birlikte yapılabilmeli? Öneri: spor salonu (arkadaşla), seyahat (eşle). Şu an ikisi de kapalı.
7. Ortak geçmişe düşen satır hayat günlüğünde de görünüyor. İkisi ayrılmalı mı, yoksa böyle kalsın mı?
8. Yaşı geçmiş ebeveynle (85 yaşında anneyle konsere) gitmeye bir üst yaş sınırı gelsin mi? Şu an yalnızca alt sınır var.

---

### Q-109 — Vefat etmiş eşin bağ etiketi

**Durum: KARARLAŞTIRILDI.** Faho bu maddenin tamamını onayladı; kesin kural `DECISIONS.md` içinde **D-060** olarak kayıtlıdır. Aşağıdaki sorular **kapanmıştır**, tarihsel kayıt olarak duruyor.

**Bulunan hata:** Boşanan oyuncunun eski eşi aynı kimlikle `eskiEs` oluyordu; **eşini kaybedip yeniden evlenen** oyuncuda bu yapılmıyordu. Kayıtta iki kişi birden "Eş" kalıyor, bütün metinler ikisine birden "Eşin" diyordu ve İlişkiler ekranında iki eş yan yana görünüyordu.

**Yapılan teknik düzeltme:** Yeni düğünde, önceki eş aynı kimlikle `eskiEs` oluyor. Kayıt silinmiyor, evlilik geçmişi korunuyor, tek bir aktif eş kalıyor.

**Karar soruları:**
1. Vefat etmiş önceki eşe "**Eski eş**" demek doğru mu? Boşanmayla vefatı aynı sözle anmak Türkçede biraz sert duruyor.
2. Ayrı bir etiket ister misin — "Rahmetli eşin", "Merhum eşin", "İlk eşin" gibi? Bu yeni bir bağ türü demek olur (`eskiEs` yanında ikinci bir durum) ve kayıt biçimini etkiler, o yüzden kendi başıma yapmadım.
3. Boşanmış eski eş ile vefat etmiş eski eş İlişkiler ekranında **ayrı başlıklar** altında mı görünsün?
4. Üçüncü evlilikte iki eski eş olacak. Sıralama neye göre olsun — evlilik yılı mı, son görüşme mi?

---

### Q-110 — Olay havuzu dengesi ve okuma merdiveni

**Durum: KARARLAŞTIRILDI.** Faho bu maddenin tamamını onayladı; kesin kural `DECISIONS.md` içinde **D-061** olarak kayıtlıdır. Aşağıdaki sorular **kapanmıştır**, tarihsel kayıt olarak duruyor.

**Ölçülen durum:**
- 200 olaydan **194'ü** en az bir hayatta çıkıyor; bir hayat ortalama **116 farklı** olay görüyor.
- İki rastgele hayatın olay kümesi **%57,5** örtüşüyor; **115** olay hayatların yarısından çoğunda çıkıyor.
- Yıl başına **~1,9** olay. 0-5 yaşta bu oran %104'e, 80 yaş üstünde %173'e iniyor.
- Konu payları: koşulsuz %67,7 · kişili %18,2 · aile %15,6 · okul %8,5 · kariyer %3,8 · hobi %3,0 · ilişki %2,1 · hayvan %1,3.
- **Seçim gerektirmeyen olay yok** (0/200): her olayın en az iki gerçek seçeneği var.

**Bulunan ve düzeltilen hata:** `hobi_okuma_gecesi` olayı hobinin 2. basamağını (8 deneyim) istiyordu; "okumak" hobisini yalnızca bitirilen kitaplar besliyor ve kütüphanede **7 kitap** var, bitmiş kitap yeniden okunamıyor. Olay hiçbir hayatta çıkamıyordu. Şart 1. basamağa indirildi ve bu hata sınıfını yakalayan kalıcı bir test eklendi.

**Karar soruları:**
1. **Okuma merdiveni ile kitap sayısı uyuşmuyor.** Basamak eşikleri 0/3/8/18/35, kütüphanede 7 kitap var: son üç basamak hiç ulaşılamıyor. Hangisi olsun — kütüphaneye kitap mı eklensin (kaç tane?), eşikler mi düşürülsün, yoksa bitmiş kitap yeniden okunup **az** kazanç mı versin?
2. **0-5 yaş boş.** Yılda ~1 olay çıkıyor, ek olay yolu o yaşta pratikte kapalı. Bebeklik/erken çocukluk havuzu genişletilsin mi, yoksa bu yaşların sakin olması bilerek mi kalsın?
3. **80 yaş üstü inceliyor** (%173). İleri yaş havuzu genişletilsin mi?
4. **Hayatların örtüşmesi %57,5.** Bu yeterince farklı mı? Örtüşmeyi düşürmenin yolu koşullu olayların (kişili, kariyerli, hobili) payını artırmak; bugün havuzun **%67,7'si koşulsuz**. Hedef bir oran var mı?
5. `mahalle_dugunu` bir hayatta ortalama **2,10** kez çıkıyor; ilk on olayın hepsi hayat başına 1,5'in üzerinde. Tekrar sönümü (Paket 20) yeterince sert mi?
6. **Ün olayları hiç görülmüyor.** Ölçümde sosyal medya hesabı açılıyor ama düzenli paylaşım yapılmıyor; Ün eşiği gerçek oyunda ne kadar erişilebilir? Ölçüm aracına düzenli paylaşım eklenmeli mi, yoksa eşik mi yüksek?
7. Kariyer olaylarının payı **%3,8**. Oyuncunun hayatının 40 yılı işte geçiyor; bu oran az mı?

---

### Q-111 — Dövüş sanatlarında ustalık süresi

**Durum: KARARLAŞTIRILDI.** Faho bu maddenin tamamını onayladı; kesin kural `DECISIONS.md` içinde **D-062** olarak kayıtlıdır. Aşağıdaki sorular **kapanmıştır**, tarihsel kayıt olarak duruyor.

**Ölçülen durum:**

| Sanat | En üst basamak | Toplam ders | Yılda en fazla | En az kaç yıl | Eğitmenlik eşiği |
|---|---|---|---|---|---|
| Karate | Siyah kuşak (3. Dan) | 200 | 20 | 10 | 110 ders (6 yıl) |
| Kung fu | 3. Duan | 145 | 20 | 8 | 58 ders (3 yıl) |
| Yağlı güreş | Başpehlivan | 120 | 20 | 6 | 92 ders (5 yıl) |

Yıl sınırı (`kMaxMartialLessonsPerAge = 20`) bilerek konmuştu: para yığarak bir yılda usta olunmasın diye. Ama her ders ayrı bir dokunuş olduğu için karate siyah kuşağı **110 kez "Ders al" düğmesine basmak** demekti.

**Yapılan teknik düzeltme (denge değişmedi):** "Yılı çalış" eylemi eklendi; yılın kalan derslerini tek seferde alıyor. Ücret, yıllık sınır, basamak eşikleri ve spor hobisi katkısı **birebir aynı**. Bunu kanıtlayan test var: tek tek ders almakla toplu çalışmanın ders sayısı, basamak, cüzdan ve bütün özellikleri aynı çıkıyor.

**Karar soruları:**
1. Süre **gerçekten** uzun mu, yoksa sorun yalnızca tekrar tıklamak mıydı? Toplu çalışma yeterli geldi mi?
2. Yeterli gelmediyse hangisi değişsin — yıllık ders sınırı (20) mu, basamakların istediği ders sayıları mı, yoksa ikisi de mi?
3. Karatede en üst basamak 10 yıl sürüyor, kung fuda 8, güreşte 6. Bu fark bilerek mi kalsın?
4. Eğitmenlik eşiği karatede 110 ders (6 yıl), kung fuda 58 ders (3 yıl). Meslek olarak açılma hızı sanatlar arasında bu kadar farklı olmalı mı?
5. Ders ücretleri (karate 180 ₺, kung fu 200 ₺, güreş 150 ₺) bilerek düşük tutuldu: "ustalık parayla değil yılla gelir". Bu kural kalsın mı?

---

### Q-112 — Sosyal medyada platformlar arası yayılma ve yıllık büyüme

**Durum: KARARLAŞTIRILDI.** Faho bu maddenin tamamını onayladı; kesin kural `DECISIONS.md` içinde **D-063** olarak kayıtlıdır. Aşağıdaki sorular **kapanmıştır**, tarihsel kayıt olarak duruyor.

**İstek (Faho'nun sözleriyle):** "sosyal medyada takipçim artarsa örneğin X'de takipçi sayım arttı diğer platformlarda da artsın, eğer takipçim fazlaysa her yıl geçtiğinde takipçi sayım artsın".

**Önceki durum:** Takipçi sayısı **yalnızca** paylaşım yapıldığı an değişiyordu. Yıllık ilerleme sosyal medyaya hiç dokunmuyordu; platformlar birbirinden tamamen bağımsızdı.

**Yapılanlar ve sayıları:**

| Kural | Değer | Not |
|---|---|---|
| Çapraz yansıma payı | `prototypeOnlyCrossShare = 0,25` | Kazancın dörtte biri diğer **açık** hesaplara |
| Yansıma için en az kazanç | `prototypeOnlyCrossMinGain = 4` | Küçük dalgalanma yayılmaz |
| Yıllık büyüme eşiği | `prototypeOnlyOrganicThreshold = 1000` | Altındaki hesap kendi kendine büyümez |
| Yıllık büyüme oranı | `prototypeOnlyOrganicRate = %6` | Kitleyle orantılı |
| Durgunluk süresi | `prototypeOnlyDormantAfterYears = 4` yıl | Bu kadar süre paylaşım yoksa |
| Durgun hesabın yıllık erimesi | `prototypeOnlyDormantDecay = %5` | |

**Kendi başıma eklediğim kural — onayını istiyorum.** İstekte durgunluk yoktu. Ama yalnızca "takipçisi çoksa her yıl büyüsün" kuralı konursa, hesabı bir kez büyüten oyuncu **hiçbir şey yapmadan** ömür boyu büyümeye devam ediyor: 50.000 takipçi 40 yılda yarım milyonu geçiyor ve Ün kendiliğinden tavana çıkıyor. Bunu engellemek için 4 yıldır dokunulmayan hesabın yavaşça erimesini ekledim. Bu bir **teknik gereklilik varsayımı**, onaylanmış oyun kuralı değil.

**Karar soruları:**
1. Çapraz yansıma payı %25 doğru mu? Daha az mı (%10), daha çok mu (%50)?
2. Yansıma **her platforma eşit** mi olsun, yoksa platform çiftine göre değişsin mi (ör. Instagram → X yakın, YouTube → X uzak)?
3. **Kayıp yayılmıyor**, yalnızca kazanç. Simetrik mi olmalı? Bir platformda tökezlemek diğerlerindeki kitleyi de azaltsın mı?
4. Yıllık büyüme eşiği 1.000 takipçi doğru mu? Bu eşik "artık kendi kendine yürüyor" sayılan nokta.
5. **Durgunluk kuralı kalsın mı?** Kalacaksa 4 yıl ve %5 doğru mu? Kalmayacaksa kontrolsüz büyümeyi ne durduracak?
6. Ün şu an yalnızca **yukarı** taşınıyor: takipçi kaybedince Ün düşmüyor (D-027'nin "yaşanmış tanınmışlık silinmez" okuması). Erime varken bu doğru mu?
7. Yıllık büyüme günlüğe satır yazıyor ("YouTube hesabın kendiliğinden büyüdü: 3.000 abone eklendi"). Her yıl bu satırı görmek fazla gürültü mü?

---

### Q-113 — Yeni meslekler: görünüş ve hobiyle açılan işler

**Durum: KARARLAŞTIRILDI.** Faho bu maddenin tamamını onayladı; kesin kural `DECISIONS.md` içinde **D-064** olarak kayıtlıdır. Aşağıdaki sorular **kapanmıştır**, tarihsel kayıt olarak duruyor.

**Önceki durum:** Katalogda **dokuz** iş vardı ve altısı genel, üçü dövüş eğitmenliğiydi. Bir ömür boyunca seçilebilecek meslek sayısı azdı.

**Eklenenler (hepsi üç mülakat sorusuyla birlikte):**

| İş | Kapı | Yıllık maaş | Not |
|---|---|---|---|
| Aşçı | yok | 230.000 ₺ | Giriş seviyesi |
| Kuaför | karizma 40 | 210.000 ₺ | Giriş seviyesi |
| Muhasebeci | üniversite · işletme · zekâ 55 | 460.000 ₺ | |
| Manken | görünüş 70 · karizma 45 | 340.000 ₺ | Yeni kapı türü |
| Yazar | okuma hobisi 1. basamak · zekâ 55 | 280.000 ₺ | Yeni kapı türü |
| Müzisyen | müzik hobisi 2. basamak · karizma 40 | 260.000 ₺ | Yeni kapı türü |

**İki yeni kapı türü açıldı** (ikisi de dövüş eğitmenliğinin — Paket 32 — aynı deseni):
- `minAppearance`: işe görünüşle giriliyor.
- `hobbyId` + `minHobbyStage`: işe yıllarca sürdürülmüş bir uğraşla giriliyor.

**Neden bu basamaklar seçildi.** Yazarlık için **1.** basamak (3 bitirilmiş kitap) alındı çünkü Q-110'da ölçüldüğü gibi "okumak" hobisini yalnızca bitirilen kitaplar besliyor ve kütüphanede 8 kitap var: 3. basamak (18 deneyim) **hiçbir hayatta** ulaşılamıyor. Müzisyenlik için 2. basamak (18 deneyim) alındı; müzik kursu yılda iki kez alınabildiği için bu 9 yıl demek. Bu eşiklerin ulaşılabilirliğini kalıcı bir test denetliyor.

**Karar soruları:**
1. Maaşlar mevcut ekonomiye oturuyor mu? (Kıyas: yazılım geliştirici 720.000 ₺, öğretmen 420.000 ₺, mağaza çalışanı 180.000 ₺.)
2. Mankenlik eşiği **görünüş 70** doğru mu? Yaşlanma görünüşü düşürdüğü için bu iş kendiliğinden ileri yaşta kapanıyor — bu istenen davranış mı, yoksa mankenliğe ayrı bir yaş üst sınırı mı konsun?
3. Mankenlik **Ün**'e de bağlanmalı mı? Şu an sosyal medyayla hiç ilişkisi yok; oysa ikisi doğal olarak birbirini besler.
4. Yazarlık 3 bitirilmiş kitapla açılıyor. Az mı? Açılması için kütüphaneye kitap eklenip eşik yükseltilsin mi (Q-110/1 ile aynı konu)?
5. Yazar ve müzisyen **iş kurar gibi** mi çalışsın (gelir dalgalı), yoksa şimdiki gibi sabit yıllık maaş mı alsın? Şu an ikisi de maaşlı.
6. Aşçı/kuaför gibi giriş seviyesi işlerden kaç tane daha olsun? Şu an katalog 15 işte.
7. Hobiyle açılan iş, hobi **bırakılırsa** kapanmalı mı? Şu an bir kez ulaşılan basamak kalıcı; işe girdikten sonra okumayı bırakmak işi etkilemiyor.

---

### Q-114 — Çok adımlı olay zincirleri

**Durum: KARARLAŞTIRILDI.** Faho bu maddenin tamamını onayladı; kesin kural `DECISIONS.md` içinde **D-065** olarak kayıtlıdır. Aşağıdaki sorular **kapanmıştır**, tarihsel kayıt olarak duruyor.

**Önceki durum:** Altyapı (`requiredFlags`, `forbiddenFlags`, `rememberPersonAs`, `personRole`) Paket 4'ten beri duruyordu ama zincirlerin çoğu **iki adımdı**: bir seçim, yıllar sonra tek bir yankı.

**Yazılanlar — 17 olay, 4 zincir, 8 dal:**

| Zincir | Adım | Yaş aralığı | Kişi | Sonuç |
|---|---|---|---|---|
| Öğretmenin defteri | 4 (geçiştiren dal 3) | 10 → 70 | Öğretmen | Anlatan tarafa geçmek |
| Emanet para | 3 | 17 → 55 | Arkadaş | Para geri gelir; hangi dalda ne kadar ve ilişkinin ne olduğu değişir |
| Mahallenin boş arsası | 3 | 11 → 80 | Kişisiz | Arsa park olur ya da bina olur |
| İş yerindeki haksızlık | 3 | 22 → 70 | İş arkadaşı | İş teklifi açılır ya da aynı şey başa gelir |

Dallar birbirini dışlıyor ve hiçbir dal "doğru" diye işaretlenmiyor: emanet parada **beklemek** daha geç ama daha çok getiriyor, **istemek** daha erken ama arkadaşlığı soğutuyor.

**Ölçüm — havuza eklemenin yan etkisi.** 17 yeni olay rastgeleliği kaydırıyor. Okulda arkadaş edinme oranını 30 tohumda ölçtüm: zincirler **kapalıyken 20/30**, **açıkken 20/30**. Oran değişmedi, yalnızca hangi tohumun tuttuğu değişti. (Bu yüzden tek tohuma bağlı bir okul testi kırıldı; test silinmedi, tohumdan bağımsız hâle getirildi.)

**Karar soruları:**
1. Zincir uzunluğu **üç-dört adım** doğru mu? Daha uzun zincir (5-6 adım) ister misin, yoksa bu bir hayatta takip edilebilirliğin sınırı mı?
2. Oyuncu bir zincirin içinde olduğunu **fark edebilmeli mi**? Şu an hiçbir ekranda "bu bir devam olayı" işareti yok; yalnızca metin hatırlatıyor.
3. Emanet parada tutarlar: verilen 4.000 ₺, isteyen dalda geri gelen 4.000 ₺, bekleyen dalda gelen 9.000 ₺. Beklemenin karşılığı iki katından fazla — bu fark doğru mu?
4. İş zincirinde teklifi kabul etmek 25.000 ₺ veriyor ama **işi değiştirmiyor**; yalnızca para ve iz. Gerçekten iş değiştirmeli mi? (Bu, kariyer sistemine dokunmak demek, kendi başıma yapmadım.)
5. Zincirin ortasında **kişi vefat ederse** adım hiç çıkmıyor ve zincir sessizce kesiliyor. Bunun yerine kişisiz bir kapanış adımı yazılsın mı?
6. Öğretmen zinciri 10 yaşta başlayıp 70 yaşa kadar sürebiliyor. Bu kadar uzun bir yay iyi mi, yoksa zincirler bir hayat evresine mi sığmalı?
7. Dört zincir yeterli mi, yoksa her hayat evresi için (çocukluk, gençlik, orta yaş, yaşlılık) ayrı zincirler mi yazılsın?

---

### Q-115 — Ünlülerle temas ve TikTok

**Durum: KARARLAŞTIRILDI — D-106.** Faho bu maddenin karar sorularını cevapladı; kesin kural `DECISIONS.md` içinde **D-106** olarak kayıtlıdır (ünlüye yılda iki temas, ayrı "Ünlüler ve tanıdıklar" bölümü, Türkçe binlik ayracı). Aşağıdaki sorular **kapanmıştır**, tarihsel kayıt olarak duruyor.

**Özgün kayıt —** Faho iki şey istedi: sosyal medyaya TikTok eklenmesi ve "ünlü ile diyaloğa gir gibi bir şey". İkisi de **kodlandı**; sayısal değerler `prototypeOnly` ve **onay bekliyor.** Kod: `lib/data/celebrity_catalog.dart`, `lib/domain/social/celebrity_engine.dart`, `lib/data/social_catalog.dart`. İlgili: Q-112, D-063.

**Yapılanlar.** Dördüncü platform olarak TikTok eklendi (dört özgün içerik). Ünlüler kurgusaldır; gerçek kişilerin adı, hesabı ya da sözü kullanılmaz. Oyuncu bir ünlüye **yorum yapabilir, mesaj atabilir ya da iş birliği teklif edebilir**. Karşılık garanti değildir.

| Kural | Değer |
|---|---|
| Bir ünlüye yılda kaç kez yazılabilir | 1 |
| Eylem çarpanı (yorum / mesaj / iş birliği) | 0,55 / 1,0 / 0,45 |
| Karizmanın katkısı | %25 |
| Ünün katkısı | %30 |
| Her ısrarlı denemenin cezası | −%12 (en fazla dörtte bire iner) |
| En yüksek karşılık ihtimali | %85 (asla %100 değil) |
| İş birliği için gereken en az Ün | 25 |
| Ünlünün kitlesinden geçen pay | %0,16 |
| Sonuç çarpanı (beğendi / cevap / geri takip / iş birliği) | 0,25 / 0,60 / 1,30 / 2,40 |
| Ters cevabın kitleye kaybı | %5 |

**Tasarım kararları (kodlanmış hâliyle):**
- Ünlü **kendiliğinden İlişkiler ekranına girmez**. Yalnızca **geri takip ettiğinde** kalıcı bir kişi kaydı açılır; o an gerçekten bir bağ kurulmuştur. Yeni bir bağ türü eklendi: `RelationType.unlu`.
- Karşılıksız denemeler **günlüğe yazılmaz**; günlük dolmasın diye.
- Israrcı olup hâlâ karşılık alamayan oyuncu, nadiren **alenen ters cevap** alabilir ve takipçi kaybeder.
- Ünlüyle gündelik hayatta vakit geçirilmez; etkileşim listesinde yalnızca sohbet açıktır.

**Karar soruları:**
1. Ulaşılabilirlik sayıları doğru mu? Şu an en küçük isim %45, en büyük isim %9 tabanla başlıyor.
2. Yılda **bir** temas az mı? Oyuncu bir ünlüye ancak yılda bir yazabiliyor.
3. **Ters cevap** kalsın mı? Israr edip karşılık alamayan oyuncunun alenen paylaşılması sert bir sonuç; oyunun tonuna uyuyor mu?
4. Geri takip eden ünlünün İlişkiler ekranında **Arkadaşlar** bölümünde listelenmesi doğru mu, yoksa ayrı bir "Tanıdıklar / Ünlüler" başlığı mı olmalı?
5. İş birliği ücreti ünlünün takipçi sayısının %6'sı (2026 ₺). En büyük isimle iş birliği ~450.000 ₺ getiriyor — bu, bir yıllık ortalama maaşın yarısı. Fazla mı?
6. Ünlü sayısı **on bir**. Yeterli mi, yoksa her platformda daha fazla isim mi olsun?
7. Ünlülerle ilgili **olay** yazılmalı mı? Şu an yalnızca oyuncunun başlattığı temas var; ünlünün kendiliğinden yazması ya da bir olayda görünmesi yok.
8. TikTok içeriklerinin karakteri (yüksek erişim, yüksek kayıp riski) doğru mu?

---

### Q-116 — Statların yaşla düşme hızı ve bakımın gücü
**Durum: KARARLAŞTIRILDI — D-102.** Kesin kural `DECISIONS.md` içinde **D-102** olarak kayıtlıdır (dövüş sanatı spor sayılır, görünüş düşüşü yumuşatıldı). Aşağıdaki sorular **kapanmıştır**, tarihsel kayıt olarak duruyor. Karizmanın hızı sonradan **D-124** ile ayrıca değiştirildi (Q-136).

**Özgün kayıt —** Öneri, karar bekliyor · **Bağlam:** D-072 · `app/lib/domain/life/aging.dart` (`StatAging`), `app/lib/domain/life/upkeep_tracker.dart` · Test: `app/test/stat_aging_test.dart`

Faho bildirdi: "karizma zeka mutluluk sağlık görünüş bunlar yaşa bağlı olarak düşmeli", "zekâ 100 olarak başladım 100 olarak bitirdim", "bakım yapmayınca kendime görünüşüm ve karizmam düşsün", "sürekli spor yapan birisinin karizması daha az düşsün". Kural D-072 olarak kodlandı; **sayılar geçicidir.**

**Şu an kodda olan (hepsi `prototypeOnly`):**

| Değer | Başlangıç yaşı | Yıllık ihtimal | Taban | Koruyan bakım |
|---|---|---|---|---|
| Görünüş | 30 | %25 → %70 (yaşa göre) | 15 | Berber/kuaför |
| Karizma | 35 | %18 → %38 | 15 | Spor (ağırlıklı) + berber |
| Sağlık | 45 | %22 → %46 | 30 | Spor |
| Zekâ | 60 | %14 → %22 | 30 | Kitap ve kurs |
| Mutluluk | 65 | %8 → %38 (sağlığa göre) | 25 | — (sağlık dolaylı korur) |

Bakım "son 2 yıl içinde" yapılmışsa ihtimal **×0,45**; 5 yıldır ya da hiç yapılmamışsa **×1,4**. Bakımsızlık 18 yaşından itibaren sayılır.

**Ölçüm (120 hayat):** ortalama ölüm yaşı **77,6**; 70 yaşında ortalama zekâ 53, karizma 40, sağlık 56, görünüş 32, mutluluk 57.

**Karar soruları:**
1. Sağlık düşüşü **ölüm eğrisini besliyor** (`Mortality` sağlığa bakar). Ortalama ömür 77,6'da kalıyor ama sağlığını hiç kollamayan oyuncu daha erken ölüyor. Bu isteniyor mu, yoksa sağlık düşüşü ölümden ayrılmalı mı?
2. 70 yaşında ortalama **görünüş 32** fazla mı düşük? Taban 15.
3. Mutluluğun yaşla düşmesi D-051'in "yaşlanma mutluluğu düşürmez" hükmünü değiştiriyor. Bu değişiklik onaylanıyor mu, yoksa mutluluk yaşlanmadan muaf mı kalsın?
4. Bakımın koruma gücü (×0,45) yeterli mi? Şu an bakım yapmak kaybı yarıdan biraz fazla azaltıyor.
5. Bakım sayılan mekânlar doğru mu? Şu an **spor = spor salonu**, **bakım = berber/kuaför**, **zihin = kurslar + kitap okumak**. Dövüş sanatları sporu sayılmıyor — sayılmalı mı?
6. Düşüşler günlüğe yazılıyor ama ayrı bir **ekran bildirimi** yok. Yıl sonunda "bu yıl şunlar düştü" özeti gerekli mi?

---

### Q-117 — Saç dökülmesinin kapsamı
**Durum: KARARLAŞTIRILDI — D-102.** Kesin kural `DECISIONS.md` içinde **D-102** olarak kayıtlıdır (saç görünüşü etkiler). Aşağıdaki sorular **kapanmıştır**, tarihsel kayıt olarak duruyor.

**Özgün kayıt —** Öneri, karar bekliyor · **Bağlam:** D-073 · `app/lib/domain/life/hair_loss.dart` · Test: `app/test/stat_aging_test.dart`

Faho istedi: "erkek kullanıcılarının ihtimal dahilinde 30 yaşından sonra saçları dökülmeye başlayabilir bu da karizmayı etkilyebilir".

**Şu an kodda olan:** 30 yaşından itibaren yıllık **%3,4** başlama ihtimali (50 yaşında birikimli ~%50, epidemiyolojik çıpayla uyumlu), başladıktan sonra yılda %12 ihtimalle bir sonraki basamak, en fazla 3 basamak. Basamak ilerlediği yıl bir kez görünüş −2/−2/−3 ve karizma −1/−2/−2; **düzenli bakım yapan oyuncuda yarıya iner**. Ömür boyu ölçüm: erkeklerin **%82'sinde** bir noktada başlıyor (80 yaş üstü gerçek yaygınlıkla uyumlu).

**Karar soruları:**
1. Gerçekte dökülme çoğu zaman **20'li yaşlarda** başlıyor. Oyunda başlangıç 30; erkene çekilsin mi, yoksa 30 kalsın mı?
2. **Kadınlarda** yaşa bağlı seyrelme gerçektir ama şu an işletilmiyor. Eklensin mi, eklenirse nasıl anlatılsın?
3. **Karizma cezası** doğru mu? Saçın dökülmesi karakteri daha az çekici yapmaz; şu anki gerekçe "kendi alışma dönemi". Ceza tamamen kaldırılsın mı, yoksa yalnızca ilk basamakta mı olsun?
4. **Saç ektirme** (Paket C'deki estetik işlemler içinde) basamağı düşürebilmeli mi? Düşürebiliyorsa kaç basamak ve hangi bedelle?
5. Ömür boyu %82 fazla mı? Gerçeğe yakın ama oyunda neredeyse her erkek karakteri kapsıyor.
6. Peruk, şapka, "kabullenmek" gibi **oyuncunun seçebileceği tepkiler** olmalı mı?

---

### Q-118 — Boşanmada mal paylaşımı, nafaka ve davet reddi
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-074, D-075 · Q-063'ün yerini alır · `app/lib/domain/interaction/divorce_settlement.dart`, `app/lib/domain/activities/outing.dart` · Test: `app/test/activity_notice_test.dart`

Faho istedi: "boşandığımda ... mal varlığından şu kadar ona gitti, ev ona gitti vb gibi yazmalı" ve "parka git dediğimde bildirim olarak karşıma çıksın ... bana 5, kızıma 5 mutluluk".

**Şu an kodda olan:** Evlilik içinde **satın alınarak** edinilen eşyalar paylaşılıyor; evlilikten önceki, miras ve hediye eşya kişisel mal sayılıp paylaşıma girmiyor. Bölünemeyen eşyalar değere göre dengeli dağıtılıyor, eşitlikte oyuncu alıyor. Nakit payı **%25**'te kaldı. Sonuç ekranda bildirim olarak gösteriliyor.

**Karar soruları:**
1. **Nafaka yok.** Eklenecek mi? Eklenirse yıllık bir gider mi olsun, tek seferlik mi?
2. Nakit payı **%25**; edinilmiş mal rejiminin mantığına göre evlilik içinde biriken nakdin yarısı olmalıydı. Nakdin ne kadarının evlilik içinde biriktiğini izlemiyoruz. İzlensin mi, yoksa %25 sabit mi kalsın?
3. **Oturulan ev** paylaşımda ayrıcalıklı olmalı mı? Şu an tek ev evlilik içinde alındıysa bir tarafa gidiyor ve oyuncu evsiz kalabiliyor.
4. **Velayet** yok: çocuklar oyuncunun hanesinde kalıyor. Ayrı bir kural gerekli mi?
5. Aracın, evin ve diğer eşyanın **satın alma fiyatı** üzerinden bölünüyor; yıpranma hesaba katılmıyor. Yeterli mi?
6. **Davet reddi:** keyfi düşük kişi daveti geri çevirebiliyor, ret ihtimalinin tavanı **%75**. Bu tavan doğru mu? Ret gerekçesinin metinleri yeterince yumuşak mı?
7. Kişilerin **keyfi** şu an yalnızca birlikte yapılan programlardan yükseliyor ve her yıl nötre kayıyor. Başka neler keyfi etkilemeli — hediye, kavga, oyuncunun başarısı, kendi hayatındaki olaylar?

---

### Q-119 — Sağlık raporu, estetik fiyatları ve hastalık dengesi
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-076, D-077, D-078 · `app/lib/domain/life/health_report.dart`, `app/lib/domain/life/eye_exam.dart`, `app/lib/domain/life/sick_leave.dart`, `app/lib/data/activity_catalog.dart` · Test: `app/test/health_package_test.dart`

Faho istedi: "göz muayenesine tıkladım, küçük bir oyun oynatmalıyız", "aşı olduğumuzda bildirim olarak ekrana vermeliyiz", "checkup'a girmişim gibi bildirim gelsin, ciğerlerin iyi kalp iyi vb", "estetikleri de ekleyelim", "hasta olayım 3-5 gün işe gidemeyeyim işverenim sorun etsin".

**Estetik fiyatları (2026 ₺, hepsi `prototypeOnly`):** kaş/yüz dolgusu 22.000 · göz kapağı 90.000 · saç ekimi 95.000 · burun estetiği 145.000 · gülüş tasarımı 185.000. Burun estetiği için 2025 piyasa aralığı yaygın olarak 60.000-120.000 ₺ diye veriliyor; buradaki 145.000 bunun 2026 ölçeğine taşınmış hâlidir ve net yıllık asgari ücretin (336.900 ₺) kabaca **beş aylığına** denk gelir.

**Risk oranları:** dolgu %12 · gülüş tasarımı %10 · göz kapağı %14 · saç ekimi %15 · burun %18. Kötü sonuçta ücret ödenir, kazanç gelmez, mutluluk −6.

**Hastalık ihtimali (yıllık):** sağlık ≥80 → %12, 60-79 → %20, 40-59 → %30, <40 → %42. Spor ×0,75 / hareketsizlik ×1,2 · 65+ ×1,25 · 12 yaş altı ×1,2.

**Karar soruları:**
1. Estetik fiyatları doğru mu? Şu an burun estetiği bir yılın maaşının yaklaşık yarısı; oyunda erişilebilir ama ucuz değil.
2. **Risk** kalsın mı? Kötü sonuçta oyuncu hem parayı hem kazancı kaybediyor. Oranlar fazla mı?
3. Estetik işlemler **yılda bir** yapılabiliyor. Ömür boyu bir sınır olmalı mı?
4. Saç ekimi basamağı **bir kademe** düşürüyor. Tamamen sıfırlamalı mı?
5. Hastalıkta **gelir kaybı yalnızca iki gün**. Gerçeğe uygun ama oyunda hissedilmiyor olabilir; artırılsın mı?
6. İşveren uyarısı işten çıkarılma ihtimaline en fazla **%16** ekliyor. Yeterli mi, yoksa yeterince uyarı birikince doğrudan işten çıkarma mı olsun?
7. Hastalık şu an **sağlığı kalıcı olarak düşürmüyor**. Düşürmeli mi?
8. Check-up raporundaki altı sistem yeterli mi? Başka sistem eklensin mi?
9. Göz muayenesi mini oyunu **beş satır**. Zorluk doğru mu? Yanlış seçimde satır kaybediliyor, tablo baştan kurulmuyor.
10. Mini oyun başka yerlerde de kullanılsın mı (diş kontrolü, işitme testi, ehliyet sınavı)?

---

### Q-120 — Galeri kademeleri, araç masrafı ve kredi dengesi
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-079, D-080 · `app/lib/data/shop_catalog.dart`, `app/lib/domain/economy/vehicle_trouble.dart`, `app/lib/domain/economy/banking.dart` · Test: `app/test/shops_and_bank_test.dart`

Faho istedi: "araç galerisi kısmını ayır, 3 adet galeri ekle... ucuz araçlar sorun çıkartsın... 2 adet motor galerisi... aksesuarları da ayır... emlak bölümünü de lüks ve orta sınıf olarak ayır" ve "banka sistemi ekleyelim, kredi çekebilelim, faizi ile ödenebilir şekilde; Fakbank ve Bankavrupa".

**Yeni araç türleri (2026 ₺, `prototypeOnly`):** çok yıpranmış otomobil 320.000 · scooter 96.000 · aile otomobili 2.050.000 · arazi aracı 3.400.000 · tur motosikleti 780.000 · spor otomobil 9.500.000 · prestij otomobili 14.500.000.

**Araç arızası:** kondisyon 70'in altındaysa ihtimal artar; 500.000 ₺ altındaki araçlarda ek %15 pay. Tamir, aracın temel değerinin **%5'i**. Ödenirse kondisyon +12, ödenemezse −8. Yılda **en fazla bir** arıza.

**Kredi:** Fakbank aylık %2,95 (yıllık ~%42), Bankavrupa aylık %4,60 (yıllık ~%72). Vade 1-3 yıl. Taksit, gelirin en fazla **%45'i** (Bankavrupa) / **%25'i** (Fakbank, kolaylık çarpanıyla) kadar olabilir. Kaçan her taksit tavanı **%25** düşürür.

**Karar soruları:**
1. Yeni araç fiyatları doğru mu? Prestij otomobili 14,5 milyon ₺ — oyunda ulaşılabilir bir hedef mi, yoksa fazla mı uzak?
2. Araç arızası yılda en fazla bir. İki araç sahibi olan oyuncu için bu az mı?
3. Tamir masrafı aracın **%5'i**. Lüks otomobilde bu 340.000 ₺ ediyor; pahalı araç sahibi olmanın bedeli olarak doğru mu?
4. Ucuz galeriden alınan araç ile miras kalan yaşlı araç **aynı kuralla** bozuluyor. Ucuz galeri ayrıca cezalandırılsın mı?
5. **Kredi faizleri gerçek ama acı:** 3 yıllık 300.000 ₺'lik Fakbank kredisi toplam ~510.000 ₺ ödetiyor. Oyun dengesi için düşürülsün mü, yoksa gerçeklik korunsun mu?
6. Vade **3 yıl** ile sınırlı. Konut kredisi (çok daha uzun vade) ayrı bir ürün olarak eklensin mi?
7. Aynı anda **iki** kredi sınırı doğru mu?
8. **Kredi notu** yok; ödeme geçmişi yalnızca kaçan taksit sayısıyla izleniyor. Gerçek bir kredi notu sistemi gerekli mi?
9. Kredi taksiti ödenemediğinde şu an yalnızca borç büyüyor. İcra, haciz ya da varlık satışı gibi bir sonuç olmalı mı?
10. Banka ekranı **Varlıklar** altında. Doğru yer mi, yoksa ayrı bir bölüm mü olmalı?

---

### Q-121 — Finger kotası, hayvan türleri, tur fiyatları ve hayatın sonu
**Durum: KISMEN KARARLAŞTIRILDI — D-107.** Finger ile ilgili sorular (beğeni kotası, niyet, flörtten sevgiliye geçiş, ekonomik süzgeç) **D-107** ile kapandı; beğeni kotası 5'ten 12'ye çıktı. Hayvan türleri, tur fiyatları ve hayatın sonu **hâlâ karar bekliyor**.

**Özgün kayıt —** Öneri, karar bekliyor · **Bağlam:** D-081, D-082, D-083, D-084, D-085 · `app/lib/domain/interaction/finger.dart`, `app/lib/data/pet_catalog.dart`, `app/lib/data/tour_catalog.dart`, `app/lib/data/city_neighbours.dart`, `app/lib/domain/life/life_end_choice.dart` · Test: `app/test/package_f_test.dart`

**Finger.** Aday yaş bandı: alt sınır `max(yaş−10, yaş/2+7)`, üst sınır `yaş+10`, hiçbir koşulda 18'in altına inmez. Beğeni kotası yılda **5**, premiumda **30**; premium ücreti **4.800 ₺**, bir yıl geçerli. Profil doldurmak eşleşme ihtimaline **+%12**, premium **+%8**, her ortak ilgi alanı **+%5** katıyor. "Seni beğenenler" listesinde en fazla **3** kişi oluyor.

**Evcil hayvanlar.** Yeni türler ve yıllık kaçma riski: muhabbet kuşu %10, kanarya %10, papağan %7, hamster %14, tavşan %9, kaplumbağa %4, balık %0, timsah %12, kedi/köpek %3. Kaçan hayvanın dönme ihtimali yılda **%60**. Hastalanma ihtimali yılda **%12**, sağlığa zararı **−18**, veteriner **+22**.

**Turlar (2026 ₺).** Kapadokya 3 gece 29.000 · Ege 4 gece 38.000 · Akdeniz 5 gece 42.000 · GAP 5 gece 44.000 · Karadeniz 6 gece 48.000 · Doğu 7 gece 62.000. Başka ile taşınmanın ek masrafı **65.000 ₺**.

**Karar soruları:**
1. Beğeni kotası **yılda 5** doğru mu? Oyun yıl yıl ilerlediği için "günde 5" böyle taşındı; oyuncuya az gelebilir.
2. Premium **bir yıl** geçerli ve her yıl yeniden alınıyor. Ömür boyu bir seçenek de olsun mu?
3. **Timsah** oyunda kalsın mı? Gerçek hayatta özel izin gerektiriyor ve bireysel beslenmesi çoğu yerde yasak; oyun bunu uyarıyla anlatıyor ama yine de bir tercih.
4. Kaçan hayvanın dönme ihtimali **%60**. Dönmeyen hayvan yıllarca kayıp kalabiliyor; bir üst sınır konmalı mı?
5. Hayvan hastalandığında oyuncu **bildirim** alıyor ama tedavi zorunlu değil. Bakılmayan hayvanın durumu yıllar içinde kötüleşiyor — bu yeterince görünür mü?
6. Tur fiyatları doğru mu? Doğu turu 62.000 ₺, net yıllık asgari ücretin kabaca **beşte biri**.
7. **Yakın il tablosu** doğru mu? Oyunda 22 şehir var ve aralarında büyük boşluklar bulunuyor; örneğin Amasya'dan yalnızca Samsun, Sivas ve Trabzon'a taşınılabiliyor.
8. Başka ile taşınma **65.000 ₺** ek masraf. Şehir değiştirmenin işe ve okula etkisi henüz yok; eklenmeli mi?
9. **Hayatın sonu seçeneği**: şu an yalnızca yetişkinde görünüyor, ayrı onay istiyor, yöntem geçmiyor, ödül vermiyor ve gerçek yardım hatlarını gösteriyor. Bu çerçeve yeterli mi? Ayarlardan tamamen kapatılabilen bir seçenek olmalı mı?
10. Eşin ev/araba beklentisi olayları yılda bir çıkabiliyor ve en az beş yıl ara var. Sıklık doğru mu?

---

### Q-122 — Lise alan seçimi ve doğumda isim verme
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-094, D-095 · `app/lib/ui/widgets/track_choice_sheet.dart`, `app/lib/domain/interaction/child_naming.dart`, `app/lib/domain/education/education_path.dart` · Test: `app/test/track_choice_test.dart`, `app/test/child_naming_test.dart`

Faho iki şey istedi: "Oyuncu liseye geçtiğinde alan seçimi yapılmadan yaş atlanamasın" ve "çocuk doğduğunda isim verilebilsin". İkisi de **kodlandı**; aşağıdaki sayılar ve ayrıntılar `prototypeOnly` ve **onay bekliyor.**

**Kodlanan hâli.** Alan seçimi 9. sınıfta zorunlu hâle geldi: seçim yapılmadan **Yaş Al** çalışmaz, düğmeye basınca seçim penceresi açılır ve pencere seçim yapılmadan kapanmaz. Puanı yetmeyen alanlar gizlenmez, gerekçesiyle soluk durur. Bebeğin adı doğum bildiriminin içinden değiştirilebilir; yalnızca doğum yılında, 2-16 harf, yalnızca harf.

**Karar soruları:**
1. Alan seçimi penceresi **hiç kapanmasın mı**, yoksa "sonra karar ver" diye bir kapı bırakılsın mı? Şu an kapı yok: karar verilmeden yıl geçmiyor.
2. Mevcut kayıtlarda 9. sınıfı geçmiş ama alanı boş bir karakter varsa ilk **Yaş Al**'da pencere açılıyor. Bu doğru mu, yoksa eski kayıtlarda alan boş kalabilmeli mi?
3. İsim uzunluğu **2-16 harf** doğru mu? Uzun Türkçe adlar (ör. "Abdurrahman") sığıyor, iki adlı kullanım ("Ayşe Nur") 16 harfe kadar mümkün.
4. İsim yalnızca **doğum yılında** değiştirilebiliyor. Oyuncunun sonradan fikir değiştirmesi (ör. ilk yaşta) için bir pencere açılsın mı?
5. Evlat edinilen çocuğa da isim verilebilmeli mi? Şu an yalnızca **doğan** bebek için açık.
6. Oyuncunun kendi adı hâlâ hayat başlangıcında üretiliyor; oradan da değiştirilebilsin mi?

---

### Q-123 — Yıl sonu özeti ve bildirim yoğunluğu
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-096, D-097, D-098 · `app/lib/domain/life/year_review.dart`, `app/lib/domain/generation/life_progression.dart`, `app/lib/domain/life/notices.dart` · Test: `app/test/year_summary_test.dart`, `app/test/critical_notice_test.dart`, `app/test/event_choice_effect_test.dart`

Faho bildirdi: "olayların sonucu ekranda görünsün", "yıl sonunda statların özeti çıksın", "kritik şeyler anında bildirilsin", "oyuncu ne olduğunu anlamak için hayat günlüğünü kurcalamak zorunda kalmasın".

**Kodlanan hâli.** Yaş alındığında biten yılın özeti ana ekranın üstünde bir kart olur (kart, pencere değil: yılda bir modal daha açmak istemedik). Özette yalnızca oyuncunun kendi değerleri var. Kritik iş ve kredi haberleri bildirim oldu. Bildirim yoğunluğu ölçüldü ve iki noktada azaltıldı.

**Ölçüm (100 hayat, ~9.000 yıl):**

| Ölçüm | Önce | Sonra |
|---|---|---|
| Tek yılda aynı anda açılan en çok pencere | 7 (iki vefat, iki cenaze, **iki** miras, bir burç) | 7 (üç vefat, üç cenaze, **tek** toplu miras) |
| Yıl başına ortalama pencere | 0,41 | 0,39 |

En kötü yılın sayısı aynı kaldı ama sebebi değişti: artık yedi pencere görmek için **üç** yakınını aynı yıl kaybetmek gerekiyor. Ölüm ve cenaze kişiye özel olduğu için birleştirilmedi.

**Karar soruları:**
1. Yıl özeti **kart** olarak doğru mu, yoksa yaş alır almaz bir **pencere** olarak mı açılsın? Kart oyuncuyu durdurmuyor; pencere kaçırılmıyor ama her yıl bir tık daha istiyor.
2. Özette yalnızca oyuncunun kendi değerleri var. **Yakınlık değişimleri** de girsin mi? (Örn. "Kızın Elif ile yakınlık −6".) Girerse kart uzar; girmezse ilgisizliğin bedeli yalnızca günlükte kalır.
3. Cüzdan satırı her yıl çıkıyor (geçim gideri ve maaş yüzünden). Küçük tutarlar için bir alt sınır konsun mu?
4. En kötü yıl **yedi pencere**: aynı yıl üç yakınını kaybetmek. Ölüm ve cenaze de birleştirilsin mi (ör. "bu yıl üç kaybın oldu" diye tek pencere ve tek katkı kararı), yoksa her kayıp kendi anını hak ediyor mu? Birleştirme, cenaze başına ayrı katkı kararını ortadan kaldırır.
5. Acılı yılda **burç bildirimi** gösterilmiyor (etki yine uygulanıyor, günlüğe yazılıyor). Doğru mu?
6. Kritik sayılan haberler şimdilik üç tane: işten çıkarılma, işveren uyarısı, kaçan kredi taksiti. Başka ne eklenmeli? (Örn. büyük para kaybı, ciddi sağlık düşüşü, evden çıkarılma.)

---

### Q-124 — Azalan getiri, çaba tavanı ve sağlık dengesi
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-099, D-100, D-101, D-102 (Q-116 ve Q-117'nin kararları) · `app/lib/domain/models/stats.dart`, `app/lib/domain/activities/activity_engine.dart`, `app/lib/domain/life/sick_leave.dart`, `app/lib/domain/life/aging.dart`, `app/lib/domain/life/hair_loss.dart` · Test: `app/test/stat_gain_test.dart`, `app/test/package_j_test.dart`

Faho bildirdi: "statlar gerçekten hissedilsin", "kalıcı 100 olmasın", "check-up ile stat kasılıyor", "hastalanınca sağlık düşmeli", "dövüş sanatı da spor sayılsın", "görünüş düşüşü biraz yumuşasın", "saç karizmayı değil görünüşü etkilesin", "saç ekimi 1-2 kademe düşürsün". Hepsi **kodlandı**; sayılar `prototypeOnly` ve **onay bekliyor.**

**Azalan getiri (ölçülen).**

| Değer | +5 kazancın gerçek karşılığı |
|---|---|
| 40 | +5 |
| 70 | +4 |
| 88 | +1 |
| 94 | +1 |

| Yol | Gereken ham puan |
|---|---|
| 50 → 75 | 31 |
| 75 → 93 | 46 |

Çaba tavanı **95**. Yılda +4 kazandıran bir alışkanlık 40 yıl sürse bile 95'te durur (ölçüldü); eskiden 100'e ulaşıyordu.

**Sağlık Merkezi.** Yıllık toplam sağlık kazancı **6** ile sınırlandı; eskiden üst üste yapılan işlemlerle yılda **17** puan kazanılabiliyordu.

**Hastalık.** Kısa rapor −1, uzun rapor −2 sağlık; sağlığı 40'ın altındaysa bir puan daha.

**Görünüş.** Yıllık düşüş olasılığı 0,25/0,45/0,60/0,70 → **0,18/0,34/0,46/0,55**; çift puan ihtimali 0,20/0,35 → **0,15/0,25**.

**Saç.** Karizma etkisi kaldırıldı; basamak görünüş maliyeti 2/2/3 → **3/4/5**. Saç ekimi 2. ve 3. basamaktan **iki**, 1. basamaktan **bir** kademe düşürür.

**Karar soruları:**
1. Çaba tavanı **95** doğru mu? 100'ü tamamen kapatmak yerine çok nadir bir olayla (ömürde bir kez) açılabilir bir kapı bırakılsın mı?
2. Azalan getiri basamakları (60 / 75 / 85 / 93) ve çarpanları (1,0 / 0,7 / 0,5 / 0,3 / 0,15) doğru mu? Şu an 75'ten 93'e çıkmak 46 ham puan istiyor; bu, yılda +4 kazanan bir oyuncu için ~12 yıl.
3. Sağlık Merkezi'nin yıllık **6** puanlık sınırı doğru mu? Alternatif: her işlemin kendi kazancını sıfıra indirip Sağlık Merkezi'ni tamamen "erken teşhis" yeri yapmak.
4. Genel kontrol hâlâ **+5** sağlık veriyor (sınıra kadar). Muayene olmak insanı sağlıklı yapmadığına göre bu kazanç sıfırlanmalı mı? Sıfırlanırsa işlemin karşılığı yalnızca rapor ve tahlil yönlendirmesi olur.
5. Hastalığın sağlığa bedeli (1-3 puan) doğru mu? Ömür boyu birikimi ölüm eğrisini besliyor.
6. Görünüş düşüşündeki yumuşatma yeterli mi, fazla mı?
7. Saç ekiminin iki kademe düşürmesi fiyatıyla orantılı mı? İşlem tek seferlik ve pahalı; şu an ileri basamaktan gelen oyuncuya belirgin avantaj veriyor.

---

### Q-125 — Medya fırsatları, sponsorluk ölçeği ve yeni hesabın kitlesi
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-103, D-104, D-105, D-106 (Q-115'in kararları) · `app/lib/data/media_catalog.dart`, `app/lib/domain/social/media_opportunities.dart`, `app/lib/data/sponsor_catalog.dart`, `app/lib/domain/social/social_income.dart` · Test: `app/test/package_k_test.dart`

Faho bildirdi: "sponsorluk için platform başına en az 5.000 takipçi olsun ve ücret ölçeklensin", "sponsorluk paylaşılmadan para ödenmesin, yapmazsan tepki olsun", "takipçi sayıları 2.232 gibi yazılsın", "Ün 40'ı geçince Ün/Medya Fırsatları bölümü açılsın", "ünlüyken yeni hesap sıfır takipçiyle başlamasın", "ünlüye yılda 2 kez yazılabilsin ve ünlüler ayrı bölümde dursun". Hepsi **kodlandı**; sayılar `prototypeOnly` ve **onay bekliyor.**

**Medya işleri (2026 ₺, net asgari ücret çıpasıyla).**

| İş | Gereken Ün | Ücret | Ün | Kitle payı |
|---|---|---|---|---|
| Dergi röportajı | 40 | 4 aylık asgari ücret (112.300 ₺) | +2 | %3 |
| Radyo programı | 45 | 6 aylık (168.450 ₺) | +3 | %4 |
| Podcast konukluğu | 50 | 8 aylık (224.600 ₺) | +3 | %6 |
| Televizyon programı | 55 | 16 aylık (449.200 ₺) | +5 | %8 |
| Belgesel seslendirme | 60 | 20 aylık (561.500 ₺) | +3 | %3 |
| Reklam yüzü olmak | 65 | 45 aylık (1.263.375 ₺) | +6 | %10 |
| Kitap teklifi | 70 | 30 aylık (842.250 ₺) | +4 | %5 |

**Sponsorluk ücreti (en küçük kategori, taban 28.000 ₺ + takipçi başına 0,9 ₺).**

| Takipçi | Ücret |
|---|---|
| 5.000 | 32.500 ₺ |
| 20.000 | 46.000 ₺ |
| 100.000 | 118.000 ₺ |
| 500.000 | 478.000 ₺ |

**Yeni hesaba taşınan kitle:** mevcut toplamın **%8'i**, en çok **40.000**, en az 2.000 toplam kitle şartıyla. Ölçüm: 120.000 takipçili oyuncu yeni hesabı **9.600** takipçiyle açıyor.

**Sözünü tutmamanın bedeli:** süresi dolan sponsorlukta ödeme yok, mutluluk **−4**, o platformdaki kitlenin **%4'ü** gidiyor.

**Karar soruları:**
1. Medya işlerinin ücretleri doğru mu? Reklam yüzü olmak 45 aylık asgari ücret; bu, oyunun en büyük tek seferlik gelirlerinden biri.
2. Ün eşikleri (40-70) doğru mu? Ün en fazla kaç olabiliyorsa (şu an 100) buna göre yedi iş yeterli mi, yoksa daha çok ara basamak mı gerekir?
3. Medya işleri **yılda bir kez** yapılabiliyor ve teklif kendiliğinden gelmiyor; oyuncu bölüme girip seçiyor. Teklif olarak da gelmeli mi (sponsorluk gibi)?
4. Sponsorluk eşiği **5.000** ve ücret takipçi başına **0,9 ₺**. Türkiye'deki gerçek aralık geniş; oyun ortayı mı tutmalı, yoksa kategoriye göre çok mu değişmeli?
5. Sözünü tutmamanın bedeli kitlenin **%4'ü**. Az mı, çok mu? Tekrarlanırsa birikmeli mi?
6. Yeni hesaba taşınan **%8** ve tavan **40.000** doğru mu?
7. Ünlüye **yılda iki** temas doğru mu, yoksa üç mü olmalı?
8. "Ünlüler ve tanıdıklar" bölümüne ileride başka kimler girmeli? (Örn. iş dünyasından tanışıklıklar, eski öğretmenler.)

---

### Q-126 — Flört basamağı, niyet ve Finger süzgeci
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-107 (Q-121'in kararları) · `app/lib/domain/interaction/finger.dart`, `app/lib/data/finger_catalog.dart`, `app/lib/domain/models/relation.dart` · Test: `app/test/package_l_test.dart`

Faho bildirdi: "eşleşince ne istediğim sorulsun", "tanışmak sevgili olmak demek değil, flört durumu olsun", "zenginlik filtresi olsun", "beğeni 12/yıl normal, 30 premium olsun". Hepsi **kodlandı**; sayılar `prototypeOnly` ve **onay bekliyor.**

**Niyetin sonucu.**

| Oyuncu | Karşı taraf | Sonuç |
|---|---|---|
| Ciddi | Ciddi | Flört |
| Ciddi | Belirsiz | Flört |
| Belirsiz | Belirsiz | Flört |
| Herhangi | Arkadaşlık | Arkadaş |
| Arkadaşlık | Herhangi | Arkadaş |
| Hayatında biri var | — | Arkadaş |

**Sayılar.** Flörtün sevgiliye dönmesi için gereken yakınlık **60**. Beğeni kotası **12**, premiumda **30**. Aday varlık dağılımı: çok yoksul %6, dar gelirli %16, orta halli %50, varlıklı %22, çok varlıklı %6.

**Karar soruları:**
1. Flörtün sevgiliye dönmesi için **60 yakınlık** doğru mu? Buluşma 45-62 arası bir yakınlıkla başlıyor, yani bazı flörtler ilk yıl resmîleşebiliyor.
2. Flört **kendiliğinden bitmeli mi**? Şu an yalnızca oyuncu ilerletebiliyor; ilgilenilmeyen flört yıllarca flört kalıyor (ilgisizlik yakınlığı düşürüyor ama bağ kopmuyor).
3. Flört sırasında yakınlaşma (D-054 kapsamı) açık olmalı mı? Şu an yalnızca sevgiliyle açık.
4. Süzgeç **ücretsiz** mi kalmalı, yoksa premium özelliği mi olmalı?
5. Süzgeç açıkken üretilen adayların **hepsi** o kademeden oluyor. Bu, "çok varlıklı" süzgecini gerçekçi olmayan biçimde kolaylaştırıyor mu? Alternatif: süzgeci bir eğilim yapmak (o kademeden daha çok, ama yalnızca o değil).
6. Beğeni kotası **12** doğru mu?
7. Niyet seçenekleri üç tane. "Evlilik düşünüyorum" gibi dördüncü bir basamak gerekir mi?

---

### Q-127 — Konut kredisi, kredi karnesi ve borcun sonu
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-108 (Q-120'nin kararları) · `app/lib/domain/economy/banking.dart`, `app/lib/domain/models/loan.dart`, `app/lib/ui/screens/sections/bank_page.dart` · Test: `app/test/package_m_test.dart`

Faho bildirdi: "banka Aktiviteler altına geçsin", "kredi tutarını elle girebileyim", "konut kredisi olsun", "basit bir kredi durumu olsun (İyi/Orta/Riskli/Çok riskli)", "icra-haciz için zemin bırak", "harçlık istediğimde ne aldığımı göreyim". Hepsi **kodlandı**; sayılar `prototypeOnly` ve **onay bekliyor.**

**Kredi örnekleri (ölçüldü).**

| Tür | Banka | Tutar / vade | Yıllık taksit | Toplam geri ödeme |
|---|---|---|---|---|
| İhtiyaç | Fakbank | 300.000 ₺ / 3 yıl | 193.014 ₺ | 579.042 ₺ |
| İhtiyaç | Bankavrupa | 300.000 ₺ / 3 yıl | 267.658 ₺ | 802.974 ₺ |
| Konut | Fakbank | 3.000.000 ₺ / 10 yıl | 1.069.703 ₺ | 10.697.030 ₺ |
| Konut | Bankavrupa | 3.000.000 ₺ / 10 yıl | 1.508.216 ₺ | 15.082.160 ₺ |

**Kredi karnesi.** Kaçan taksit 1 → Riskli, 2+ → Çok riskli. Kaçan yoksa taksit yükü/gelir: ≤%25 İyi, ≤%45 Orta, üstü Riskli.

**Karar soruları:**
1. Konut kredisi aylık faizi **%2,45 / %3,40** doğru mu? Bu oranla 10 yıllık kredide toplam geri ödeme anaparanın **3,5-5 katı** oluyor. Matematik doğru ama oyunda konut kredisi neredeyse alınamaz hâle geliyor; oyun gerçeğe mi yoksa oynanabilirliğe mi uysun?
2. Konut kredisinde vade **10 yıl**. Daha uzun (15-20 yıl) bir seçenek, yıllık taksiti düşürüp krediyi gerçekten kullanılabilir yapar mı?
3. Konut kredisi şu an **eve bağlı değil**: para cüzdana giriyor, oyuncu isterse başka şeye harcıyor. Gerçek konut kredisi gibi **yalnızca ev alımında** kullanılabilir olmalı mı?
4. Kredi karnesinin eşikleri (%25 / %45, 1 ve 2 kaçan taksit) doğru mu?
5. Karne şu an yalnızca **gösteriliyor**; kredi kararında ayrıca kullanılmıyor (kaçan taksit zaten tavanı düşürüyor). Karne doğrudan bir çarpan olmalı mı?
6. **İcra ve haciz**: borç ödenmediğinde ne olmalı? Şu an borç faiziyle büyüyor ve yeni kredi zorlaşıyor, o kadar. Seçenekler: (a) belli bir eşikten sonra eşyaya haciz, (b) maaştan kesinti, (c) hiçbiri — oyun bu kadarıyla kalsın.
7. Harçlık metnine tutar eklendi. Diğer para taşıyan etkileşimlerde (hediye ver/al) de tutar yazılmalı mı?

---

### Q-128 — Sahiplendirme, kaybın sonu, özel izin ve genç ebeveyn tepkisi
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-109, D-110 · `app/lib/domain/pets/pet_care.dart`, `app/lib/domain/generation/life_progression.dart` · Test: `app/test/package_n_test.dart`

Faho bildirdi: "evcil hayvanı sahiplendirebilelim, aktif ve geçmiş ayrılsın", "kaçan hayvan mutlaka sonuçlansın", "timsah nadir/özel olsun", "18-20 yaşında çocuk olunca ailenin tepkisi olsun". Hepsi **kodlandı**; sayılar `prototypeOnly` ve **onay bekliyor.**

**Sayılar.**

| Kural | Değer |
|---|---|
| Sahiplendirmenin mutluluk bedeli | −5 |
| Kayıp hayvanın en çok kayıp kalabileceği süre | 3 yıl |
| Özel izin için en küçük yaş | 25 |
| Özel izin masrafı | Hayvanın bedelinin yarısı (timsahta 90.000 ₺) |
| Genç ebeveyn — evliyse | Yakınlık +3, mutluluk +2 |
| Genç ebeveyn — evli değilse | Yakınlık −5, mutluluk −3 |
| Genç ebeveyn yaş bandı | 18-20 |

**Karar soruları:**
1. Sahiplendirme **geri alınamaz**. Hayvanın sonradan geri alınabilmesi (aynı yuvadan) bir seçenek olmalı mı?
2. Kayıp süresi **3 yıl** doğru mu? Süre dolunca hayvan "başka bir yuva buldu" sayılıyor; bunun yerine "bir daha hiç haber alınamadı" gibi belirsiz bir kapanış mı olmalı?
3. Özel izin için **kendi evinde yaşamak** şartı doğru mu? Şu an ailesinin yanında yaşayan bir yetişkin timsah sahiplenemiyor.
4. İzin masrafı **bedelin yarısı**. Sabit bir tutar mı olmalı?
5. Timsah dışında hangi türler izin gerektirmeli? (Şu an yalnızca timsah.)
6. Genç ebeveyn tepkisi **evlilik durumuna** bakıyor. Başka ne bakmalı — oyuncunun işi var mı, kendi evi var mı, ailenin ekonomik durumu?
7. Tepki **tek seferlik**. Sonraki yıllarda "nasıl gidiyor" diye devam eden bir olay zinciri olmalı mı?
8. Yaş bandı **18-20**. 21-23 için daha hafif bir tepki de olmalı mı?

---

## Kontrol notu
Bu sıra, inceleme ve karar koordinasyonu içindir. `DECISIONS.md` ile eşdeğer değildir; Claude'un geçici teknik parametreleri Faho'nun ürün kararı sayılmaz.

---

### Q-129 — Dövüş dersinin yıllık stat tavanı
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-115 · `app/lib/domain/activities/martial_arts_engine.dart` · Test: `app/test/package_p_test.dart`

Faho bildirdi: "20 dersi birden aldığımda mutluluğum ve sağlığım çok fazla artıyor". Sebep **ölçüldü**: yıllık ders sayısı sınırlıydı (20) ama kazancın toplamı değildi — bir yılda ham **40 sağlık** ve **20 mutluluk**. Kodlandı; sayılar `prototypeOnly` ve **onay bekliyor.**

| Kural | Değer |
|---|---|
| Derslerden bir yılda kazanılabilecek sağlık | 4 |
| Derslerden bir yılda kazanılabilecek mutluluk | 3 |
| Basamak atlama ödülü | Tavanın **dışında** (sağlık +3, mutluluk +6, karizma +2) |
| Yıllık ders hakkı | 20 (değişmedi) |

**Karar soruları:**
1. 4 sağlık / 3 mutluluk doğru mu? Spor salonu ve Sağlık Merkezi'nin yıllık tavanı 6; dövüş bundan düşük tutuldu çünkü ayrıca hobi ve bakım da besliyor.
2. Basamak atlama ödülü tavanın dışında kalmalı mı, yoksa o da mı sayılmalı?
3. Ders hakkı 20 kalsın mı? Stat kazancı kesildikten sonra 20 dersin tek anlamı basamak ilerlemesi oluyor; tekrar tıklama yükü sürüyor. "Bu yıl kalan dersleri toplu al" gibi tek dokunuşluk bir yol açılsın mı?

---

### Q-130 — Finger: arkadaşlıktan flörte, flörtten sevgiliye
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-112 · `app/lib/domain/interaction/finger.dart` · Test: `app/test/package_o_test.dart`

Faho bildirdi: "Finger'da tanıştığım birisi ile nasıl sevgili olacağım... ilerisi yok". İki sebep ölçüldü: tanışmaların **%35'i** arkadaşlıkla bitiyor ve arkadaşta romantik yol hiç yoktu; flörtlerin **%74'ü** ise sevgili olma eşiğinin (60) altında başlıyor. Kodlandı; sayılar `prototypeOnly` ve **onay bekliyor.**

| Kural | Değer |
|---|---|
| Çıkma teklifi için en az yakınlık | 50 |
| Kabul şansı | Yakınlık 50'de %40, 100'de %90 |
| Reddedilince yakınlık kaybı | −6 |
| Sevgili olmak için en az yakınlık | 60 (değişmedi) |
| Teklif için en küçük yaş | 16 (iki taraf da) |

**Karar soruları:**
1. Çıkma teklifi eşiği 50 doğru mu? Flört başlangıç yakınlığı zaten 45-62; yani bazı arkadaşlara ilk yıl teklif edilebiliyor.
2. Reddedilince −6 yakınlık doğru mu, yoksa teklif bedelsiz mi olmalı?
3. Yılda kaç kez teklif edilebilsin? Şu an sınır yok; yakınlık düştükçe şans da düşüyor ama üst üste denenebiliyor.
4. Arkadaşa teklif **yalnızca Finger'da tanışılan** kişiye mi açık olmalı, yoksa okul/iş arkadaşına da mı? Şu an her uygun arkadaşa açık.
5. Flört ilgilenilmezse kendiliğinden bitmeli mi? (Bu ayrıca Faho'nun istediği bir şey; henüz kodlanmadı.)

---

### Q-131 — Hastalığın bedeli ve toparlanma
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-116 · `app/lib/domain/life/sick_leave.dart`, `app/lib/domain/life/aging.dart` · Test: `app/test/package_p_test.dart`

Faho bildirdi: "hastalıkta -1-2-3 değil de en az -10 sağlık düşmeli ve hastalığının ciddiyetine göre bu artmalı". Kodlandı; sayılar `prototypeOnly` ve **onay bekliyor.**

| Ciddiyet | Rapor | Sağlık bedeli |
|---|---|---|
| Hafif | 3-4 gün | −10 |
| Orta | 5-6 gün | −14 |
| Ağır | 7 gün | −18 |
| Sağlığı 40'ın altındaysa | — | 3 puan daha |

**Toparlanma neden eklendi.** İstenen bedel tek başına uygulandığında **ölçüldü ve oyunu bozdu**: toparlanma olmadığı için kayıplar birikiyor ve 100 hayatta **40 yaşta ortalama sağlık 0,8'e** düşüyordu. Bu yüzden hastalanılmayan yılda yılda **7 puan** toparlanma eklendi, bir **tavana** kadar:

| Yaş | Toparlanma tavanı |
|---|---|
| 30'a kadar | 90 |
| 45'e kadar | 80 |
| 60'a kadar | 68 |
| 70'e kadar | 55 |
| 70 üstü | Toparlanma yok |

**Ölçüm (100 hayat):** 40 yaşta ortalama sağlık **54,7** · 60 yaşta **31,1** · ortalama ömür **74,2** (önce 72,4).

**Karar soruları:**
1. −10/−14/−18 doğru mu, yoksa daha da ağır mı olmalı?
2. Toparlanma bu projede **yeni bir mekanizma**. Kabul ediliyor mu? Alternatif: toparlanma olmasın ama hastalık daha seyrek gelsin.
3. Toparlanma tavanları doğru mu? Şu an 30 yaşındaki biri hastalıktan sonra 90'a kadar toparlanıyor.
4. Toparlanma spor/bakım yapana daha hızlı olsun mu? Şu an herkese aynı.
5. 70 yaşından sonra hiç toparlanmama doğru mu?

---

### Q-132 — Her şey pop-up: nerede durmalı?
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-114 · `app/lib/state/game_controller.dart` · Test: `app/test/package_q_test.dart`

Faho bildirdi: "TÜM AMA TÜM BİLDİRİMLER POP UP OLMALI ... KULLANICI ANLAMALI". Kodlandı: uygulanmış her eylem artık ekranda pencere açıyor.

**Ölçüm:** yıl başına ortalama pencere **0,39 → 0,71**, en kötü yıl **7 → 6**. (Aktivite pencereleri oyuncunun kendi dokunuşuyla açıldığı için bu sayıya girmiyor; sayı yıl geçerken kendiliğinden açılanları ölçüyor.)

**İki istisna bırakıldı**, ikisi de aynı gerekçeyle — sonucu zaten kendi penceresi anlatıyor: **mülakat cevabı** ve **eğitim seçimleri**. Ayrıca Finger'da her kaydırma pencere açmıyor; yalnızca tanışma/flört/sevgili olma açıyor.

**Karar soruları:**
1. Bu iki istisna kabul mü, yoksa onlar da mı pencere açsın?
2. Finger kaydırmaları gerçekten pencere açmamalı mı? (Yılda 12 beğeni hakkı var; her biri pencere açsaydı uygulama kullanılamaz olurdu.)
3. Aynı anda birden çok pencere açıldığında üst üste mi gösterilsin, yoksa tek pencerede mi toplansın? Şu an sırayla açılıyor.

---

### Q-133 — Çocuğun evlenmesi, torun haberi ve flörtün sonu
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-121, D-122 · `app/lib/domain/generation/child_marriage.dart`, `app/lib/domain/interaction/finger.dart` · Test: `app/test/package_r_test.dart`

Faho bildirdi: "torunum olduğunda, kızım/çocuğum evlendiğinde pop-up olarak bildirilsin; düğünlerine çağırılabileyim; aram kötü ise sadece düğününün olduğunu, iyi ise direkt davetiye gibi gelsin" ve "ilgilenilmeyen flört bitsin". Kodlandı; sayılar `prototypeOnly` ve **onay bekliyor.**

| Kural | Değer |
|---|---|
| Çocuğun evlenebileceği en küçük yaş | 22 |
| Yıllık evlenme ihtimali | 22 yaşta %10, her yıl +%1, en çok %28 |
| Düğüne davet edilmek için yakınlık | 45 |
| Flörtün bittiği yakınlık | 35 |
| Flörtün bitmesi için sessiz yıl | 2 |

**Karar soruları:**
1. Evlenme ihtimali doğru mu? Şu an 30 yaşındaki bir çocuk her yıl ~%18 ihtimalle evleniyor; ömür boyunca çoğu çocuk evleniyor.
2. Davet eşiği 45 doğru mu? Altında haberi "sonradan duyuyorsun".
3. **Düğüne gitmek bir seçim olmalı mı?** Şu an davetiye yalnızca bir haber; katılma/katılmama seçeneği yok (cenazede var). Katılım yakınlığı etkilesin mi, masrafı olsun mu?
4. Çocuğun eşi **ayrı bir kişi kaydı** olmalı mı? Şu an yalnızca adı tutuluyor; dünür ailesi, torunun diğer ebeveyni gibi bağlar kurulmuyor.
5. Çocuk boşanabilmeli mi? Şu an evlilik tek yönlü.
6. Flört 2 yıl sessizlikte bitiyor; bu çok hızlı mı? Yakınlık eşiği 35 doğru mu?
7. Flört bitince kişi **arkadaş** olarak kalıyor. "Eski flört" diye ayrı bir bağ olsun mu?

---

### Q-134 — Sosyal medyanın yeni ekonomisi
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-117, D-118, D-119, D-120 · `app/lib/domain/social/` · Test: `app/test/package_q_test.dart`

Faho bildirdi: "sponsorluk ücretleri hâlâ çok fazla", "dümdüz yaptığım paylaşımlardan ücret kazanıyorum bu olmamalı", "ün neredeyse hiç düşmüyor", "başvurularda kabul edilmeme durumu olsun", "bazen firmalar kendiliğinden teklif yollasın", "sürekli sponsor alırsa kayıp yaşansın", "her sosyal medya hesabı ayrı". Hepsi **kodlandı**; sayılar `prototypeOnly` ve **onay bekliyor.**

**Sponsorluk ücreti — araştırmaya dayanıyor.** 2026'da Türkiye'de 10K-100K takipçili bir hesap gönderi başına kabaca **3.000-15.000 ₺** alıyor. Oyun 100.000 takipçiye 118.000 ₺ ödüyordu.

| Takipçi (o hesapta) | Eski ücret | Yeni ücret |
|---|---|---|
| 5.000 | 32.500 ₺ | **3.600 ₺** |
| 20.000 | 46.000 ₺ | **5.400 ₺** |
| 100.000 | 118.000 ₺ | **15.000 ₺** |
| 500.000 | 478.000 ₺ | **63.000 ₺** |

**Para nereden geliyor artık:** sponsorluk + 100.000 takipçiden sonra başlayan **yıllık gelir payı** (takipçi başına yılda 0,9 ₺). Paylaşım başına ödeme **tamamen kaldırıldı**.

**Ün düşüşü (D-027 değişti):** hiç paylaşım yapılmayan bir yılın sonunda Ün yılda **%12** düşer; dördüncü sessiz yıldan sonra **%24**. Taban **5**; sıfıra inmez.

**Kitle yorgunluğu:** beş yıllık pencerede ilk iki sponsorluk bedelsiz; sonraki her biri o platformun kitlesinden **%2,5** (en çok %12).

**Başvuru ve davet:** kabul şansı %45 + eşik üstü her Ün puanı için %2 (en çok %92). Yılda **%22** ihtimalle kendiliğinden davet gelir; davetli işte Ün şartı aranmaz ve ret olmaz.

**Karar soruları:**
1. 0,12 ₺/takipçi doğru mu? Araştırma bandını tutuyor ama oyunda sosyal medyayı bir "meslek" olmaktan çıkarır mı?
2. **Yıllık gelir payı yeni bir mekanizma.** Kabul mü? Eşik 100.000 doğru mu?
3. Ün düşüş hızı %12 doğru mu? Taban 5 mi olmalı, yoksa 0'a kadar inmeli mi?
4. Kitle yorgunluğunda "iki bedelsiz sponsorluk" doğru mu?
5. Davet ihtimali %22 çok mu sık? Davetin Ün şartını tamamen kaldırması doğru mu?
6. Reddedilen başvurunun yıllık hakkı tüketmesi doğru mu, yoksa aynı yıl tekrar denenebilmeli mi?

---

### Q-135 — Geçim giderinin gerekçesi
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-123 · `app/lib/domain/economy/living_costs.dart`, `app/lib/ui/screens/sections/assets_screen.dart` · Test: `app/test/package_s_test.dart`

Faho sordu: "yıllık yaşam gideri çalışmıyorsam neden var ve bu giderler neye göre belirleniyor? eğer evim arabam vb tarzı vergilendirilecek şeyler yoksa bir giderim olmamalı, bence olsa bile az olmalı".

**Cevap iki parçalı.** Gider bir **vergi değil**, geçim masrafıdır: kira, yemek, fatura. Bu yüzden mal varlığı olmayan da öder. Ama iki eksik vardı ve ikisi de düzeltildi: (1) hesap ekranda görünmüyordu, artık **kalem kalem** duruyor; (2) ailesinin yanında yaşayan ve **hiç geliri olmayan** oyuncuya tam yük biniyordu, artık yalnızca kişisel harcama (yılda 12.000 ₺) işliyor.

| Durum | Yıllık taban |
|---|---|
| Çocuk (18 altı) | 0 |
| Ailesinin yanında, **geliri yok** | 12.000 ₺ |
| Ailesinin yanında, geliri var | 78.000 ₺ + gelirin %8'i |
| Kirada | 162.000 ₺ + gelirin %15'i |
| Kendi evinde | 114.000 ₺ + gelirin %12'si |

**Karar soruları:**
1. Gelirsiz genç için 12.000 ₺ doğru mu, yoksa sıfır mı olmalı?
2. Bu indirim yalnızca **ailesinin yanında** yaşayana açık. Kirada oturup işsiz kalan tam yükü ödüyor ve cüzdanı erirken borç birikiyor. Doğru mu, yoksa işsizlik için ayrı bir kural mı gerekli?
3. Faho'nun asıl sorusu "vergilendirilecek şey yoksa gider olmamalı" idi. Oyunda **vergi diye ayrı bir kalem yok**; ev/araba masrafı (aidat, bakım) gider kalemlerinin içinde. Ayrı bir "vergi" kalemi olsun mu?
4. Döküm Varlıklar ekranında duruyor. Yıl sonu özetinde de görünsün mü?

---

### Q-136 — Karizmanın yıpranma hızı
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-124 · `app/lib/domain/life/aging.dart` · Test: `app/test/package_p_test.dart`

Faho bildirdi: "statlar hâlâ çok çok fazla, sağlık ve karizma asla düşmüyor neredeyse". Ölçüldü ve haklıydı. Kodlandı; sayılar `prototypeOnly` ve **onay bekliyor.**

| Kural | Eski | Yeni |
|---|---|---|
| Yıpranmanın başladığı yaş | 35 | **32** |
| Düşüş ihtimali (32-49) | %18 | **%30** |
| Düşüş ihtimali (50-64) | %28 | **%45** |
| Düşüş ihtimali (65+) | %38 | **%60** |
| Yılda en çok kayıp | 1 puan | **60 yaşa kadar 1, sonra 2** |
| Taban | 15 | 15 (değişmedi) |

**Ölçüm (100 hayat, ortalama karizma):**

| Yaş | Önce | Sonra |
|---|---|---|
| 20 | 52,6 | 52,6 |
| 40 | 51,0 | **48,9** |
| 50 | 48,7 | **45,2** |
| 60 | 44,5 | **38,9** |
| 70 | 38,4 | **28,7** |

Aynı ölçümde sağlık (D-116 ile birlikte): 20 yaş 69,9 → 70 yaş **13,8**.

**Karar soruları:**
1. Bu hız doğru mu, yoksa daha da sert mi olmalı?
2. Yıpranmanın 32'de başlaması doğru mu? Görünüş 30'da, sağlık 45'te başlıyor.
3. Taban 15 doğru mu? Karizma bir insanda hiç sıfırlanmamalı mı?
4. Bakımın (spor, berber) koruyucu etkisi yeterli mi? Şu an düzenli spor yapan belirgin biçimde daha az kaybediyor ama oran onaylanmadı.

---

### Q-137 — Eksikler envanteri ve sıradaki büyük iş
**Durum:** Öneri, karar bekliyor · **Bağlam:** `docs/EKSIKLER.md` (tam envanter) · Ölçüm: 120 hayat oynanarak

Faho istedi: "oyunda eksik ve tamamlanması gerektiğini düşündüklerini yaz". Tam envanter `docs/EKSIKLER.md` dosyasına çıkarıldı. Burada yalnızca **karar sorusu** duruyor: bundan sonra ne yapılacak?

**Hiç kodlanmamış sistemler** (kodda tek satırı yok, arama ile doğrulandı):

| Sistem | Durum |
|---|---|
| Suç, hukuk, hapis | **Yok** — oyunda hiçbir risk yok |
| Girişimcilik | **Yok** — 44 mesleğin hepsi maaşlı |
| Üvey ebeveyn / ikinci ailenin bağları | **Yok** |
| Nafaka, velayet | Bilerek ertelendi (Q-118) |
| Hane bütçesi, eşin ekonomisi | **Yok** (Q-063) |
| İkiz gebelik | **Yok** |

**Yarım kalmış sistemler:** arkadaşlık (yalnızca sohbet/vakit/hediye; küslük, barışma, arkadaşın kendi hayatı yok) · çocuğun hayatı tek yönlü (boşanamaz, işsiz kalamaz) · Hobilerim bölümü yok · Evlilik Geçmişi ekranı yok · hayvan detay ekranı yok · dul kalmak ile boşanmak aynı bağa düşüyor · çoklu kişiyle aktivite yok.

**Ölçülen içerik boşluğu:** hayatın ilk 18 yılı en fakir dönem — 0-5 yaşta **11**, 6-12'de **25** farklı olay görülüyor; oysa 40-59'da **52**, 60-79'da **60**.

**Bir uyarı:** 120 hayatta 61 olay hiç çıkmadı, ama bunların çoğu **bozuk değil** — simülasyon işe girmediği ve hobi edinmediği için tetiklenemedi (`ilk_maas` yalnızca "18-24 yaşta çalışıyor ol" istiyor). **Ancak 10 hikâye izi hiç konmuyor** ve bir kısmı zincirin ilk halkası hiç çıkmadığı için ölü olabilir; bu gerçek bir hata olabilir.

**Karar soruları:**
1. **Sıradaki büyük iş hangisi olsun?** Claude'un önerisi: (a) ölü hikâye izlerini araştır, (b) çocukluk/ergenlik olayları, (c) suç ve hukuk sistemi, (d) arkadaşlığı derinleştir, (e) görsel kimlik kararı. Bu bir öneridir; sıra sizindir.
2. **Suç ve hukuk sistemi bu sürüme girsin mi?** Daha önce "ileride gelecek" denmişti. Oyuna kaybedilebilirlik katan tek büyük eksik bu.
3. **Görsel kimlik (Q-001 / Q-077) ne zaman karara bağlanacak?** Oyun bir yıl daha kodlanabilir ama palet seçilmeden "bitti" denemez; 15 golden testi de bu yüzden atlanıyor.
4. **136 sorunun 68'i hâlâ karar bekliyor ve hiçbiri "kararlaştırıldı" diye kapatılmamış.** Kuyruk bu hâliyle işe yarıyor mu, yoksa toplu bir karar turu mu gerekiyor?
5. Çocukluk için 40-50 yeni olay yazılması onaylanıyor mu? Onaylanırsa hangi temalar öncelikli?

---

### Q-138 — İlerleme sayacı düzeldi: bir hayat kaç olay görmeli?
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-125, D-023, D-024 · `app/lib/state/game_controller.dart` (`_countProgress`) · Test: `app/test/paket_op_test.dart`

D-125 gerçek bir hatayı kapattı: oyuncunun eylemleri ilerleme sayılmıyordu, bu yüzden aktif oynayan da hiçbir şey yapmayan da aynı sayıda olay görüyordu. Düzeltmeden sonra ölçüm (120 hayat, oyuncu gibi oynanarak):

| Ölçü | Önce | Sonra |
|---|---|---|
| Bir hayatta görülen farklı olay | 48 | **105** |
| Hiç çıkmayan olay | 40 | **9** |
| Havuzun görülen kısmı | 205/221 | **212/221** |

**Karar soruları:**
1. Bir hayatta **105 farklı olay** doğru yoğunluk mu? Az mı, çok mu? Şu an yılda ortalama 1,4 olay demek.
2. Her eylem eşit mi saymalı? Şu an spor yapmak da eşya kullanmak da **1** ilerleme. Kimi eylem daha ağır saymalı mı?
3. Aynı yaşta en fazla **bir** ek olay kuralı (D-024) duruyor. Çok aktif oynayana daha fazla verilmeli mi?
4. Bu yoğunluk mobilde yorucu mu? Oyuncu "yaş al"dan sonra art arda pencere görmekten sıkılır mı?

---

### Q-139 — Çocukluk ve ergenlik olaylarının temaları ve dozu
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-126 · `app/lib/data/event_pool_childhood.dart` · Test: `app/test/paket_op_test.dart`

Faho istedi: "0-17 için yaklaşık 45 yeni olay; kalite nicelikten önemli". 51 olay yazıldı. **Etki değerleri ve bazı temalar onay bekliyor.**

Yazılan temalar: 0-5 — ilk kelime, kreş, ilk düşme, misafirlik, oyuncak kavgası. 6-12 — mahalle maçı, komşunun camı, harçlık biriktirme, karne, sınıf başkanlığı, servis, kantin, okul gösterisi, çocukluk arkadaşı. 13-17 — ilk hoşlanma, cesaret edememe/reddedilme, gruba girme ya da dışlanma, ilk yalan, yaz işi istemek, sigara teklifi, öğretmenle ters düşmek.

**Karar soruları:**
1. **Sigara teklifi, dışlanma ve ilk yalan** gibi temalar bu yaş bandında doğru mu? Dozu ağır mı?
2. Çocukluk arkadaşı ve ilk hoşlanılan kişi **gerçek kişi kaydı** olarak kuruluyor; bu kişiler ileride (20'li, 30'lu yaşlarda) geri dönmeli mi? Şu an dönmüyorlar.
3. Çocuklukta alınan izler yetişkinlikte ne kadar ağır basmalı? Şu an yalnızca birkaç yerde okunuyor.
4. Etki değerleri (`prototypeOnly`) onaylanıyor mu? Örnek: camı itiraf etmek karizma **+4** ve **−300 ₺**, kaçmak mutluluk **−2**.
5. 0-5 bandı hâlâ en zayıfı (24 farklı olay). Bebeklik için daha fazla yazılsın mı, yoksa o yaş **hızlı geçmeli** mi?

---

### Q-140 — Metin üslubu belgesi ve robotik kalıp tavanı
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-127 · `docs/WRITING_STYLE_TR.md` · Test: `app/test/language_quality_test.dart`

Faho'nun talimatı belgeye çevrildi ve bir testle ölçülüyor. Test bir **kelime polisi değil**: yasak kalıpların sayısını raporlar ve tavanla sınırlar, böylece yeni metin eski rapor diline geri dönemez. **Bugünkü ölçüm: 0 robotik kalıp** (tavan 40).

**Karar soruları:**
1. Yasak listesi eksik mi? Faho'nun rahatsız olduğu başka kalıplar var mı?
2. Sokak ağzı listesi (abi, ya, oğlum, neyse, cebin yandı…) doğru mu? Eklenecek/çıkarılacak var mı?
3. Espri yasağının kapsamı doğru mu? Şu an: ölüm, cenaze, ağır hastalık, gebelik kaybı, ağır boşanma, ciddi borç, şiddet, hayatın sonu, çocukla ilgili ciddi sorunlar.
4. Tavan 40 çok gevşek mi? Ölçüm 0 olduğuna göre tavan **0'a** çekilip yeni kalıp tamamen yasaklanabilir; bu CI'yı sertleştirir.
5. Mevcut 272 olayın metinleri tek tek gözden geçirilsin mi? Bu turda yalnızca **mekanik duran** metinler değiştirildi; iyi okunanlara dokunulmadı.

---

### Q-141 — Suç/Hukuk V1: kapsam, sıklık ve denge
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-128 · `app/lib/data/crime_catalog.dart`, `app/lib/domain/law/legal_engine.dart`, `app/lib/data/event_pool_crime.dart` · Test: `app/test/crime_law_test.dart`

Faho istedi: "suç/hukuk sistemini ilk kez ekle ama ilk sürümü kontrollü tut". 11 suç türü, 31 olay ve 5 zincir yazıldı. Sistemin **kapsamı ve sıklığı** onay bekliyor.

**Ölçüm (100 hayat, oyuncu gibi oynanarak):**

| Oynayış | Dosyası olan | Sabıkalı | Mahkemeye çıkan | Hapis yatan |
|---|---|---|---|---|
| **Riskli seçimler yapan** (rastgele seçim) | 97 | **56** | 75 | **22** |
| **Temiz oynayan** (riskli seçim hiç seçilmiyor) | **0** | **0** | **0** | **0** |

"Dosyası olan 97" sayısı yanıltıcı görünebilir: içine **trafik cezası gibi idari işlemler** de giriyor ve bunlar sabıka sayılmıyor. Anlamlı sayı **sabıkalı 56**'dır ve bu, riskli seçimi üçte bir oranında seçen bir oyuncunun sonucudur.

**Karar soruları:**
1. **Sıklık doğru mu?** Riskli seçim yapan oyuncunun %56'sının sabıkalı olması çok mu? Suç olaylarının havuzdaki ağırlığı düşürülsün mü? (Şu an 31 olay / 303 havuz.)
2. **%22 hapis** oranı doğru mu? Hapis cezası çok mu kolay çıkıyor?
3. **Ağır/organize suç** ne zaman gelsin? Bu sürümde bilinçli olarak yok.
4. **Hapis süresi** oyun yılı ölçeğinde (1-3 yıl). Daha uzun cezalar olmalı mı?
5. Tahliye sonrası **iki yıl denetim dönemi** doğru mu? Şu an denetim döneminin somut bir yaptırımı yok; olmalı mı?
6. Suç olayları şu an **yaşa ve mali duruma** bağlı çıkıyor (kötü arkadaş çevresi, düşük para, öfke). Başka bir tetikleyici eklenmeli mi?

---

### Q-142 — Avukat kademeleri ve ücretleri
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-128 · `app/lib/data/lawyer_catalog.dart` · Test: `app/test/crime_law_test.dart`

Üç kademe var; gerçek bir avukatın ya da büronun adı kullanılmıyor. Ücretler 2026 net asgari ücret (28.075 ₺) çıpasından türetildi; Türkiye Barolar Birliği asgari ücret tarifesi ceza davalarında beş haneli tutarlardan başlıyor.

| Kademe | Ücret | Yumuşama payı |
|---|---|---|
| Avukat tutma (kendini savun) | 0 ₺ | 0 |
| Uygun ücretli avukat | 33.690 ₺ | +%10 |
| Deneyimli avukat | 98.263 ₺ | +%20 |
| Adı duyulmuş avukat | 252.675 ₺ | +%32 |

**Karar soruları:**
1. Ücretler doğru bantta mı? Pahalı avukat çok mu ucuz?
2. **Yumuşama payları** doğru mu? En iyi avukat %32 katkı yapıyor ve sonucu **garanti etmiyor** — ölçümde aynı dosyada farklı kararlar çıkıyor. Bu belirsizlik doğru mu?
3. Avukat **peşin** ödeniyor. Taksit ya da "kaybedersen alma" gibi bir yol olmalı mı?
4. Kademe sayısı üç yeterli mi?

---

### Q-143 — Sabıkanın işlere etkisi ve hapsin bedeli
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-128 · `app/lib/data/job_catalog.dart` (`RecordRule`), `app/lib/domain/career/job_market.dart` · Test: `app/test/crime_law_test.dart`

**Kodlanan kural:** `serbest` (çoğu iş) · `temizGerekir` (polis, itfaiyeci, memur, güvenlik) · `agirEngeller` (öğretmen, doktor, hemşire, banka personeli). Dayanak gerçek: 657 sayılı kanun ve 5188 sayılı özel güvenlik kanunu belirli suçlardan hüküm giyenleri bu görevlerin dışında tutuyor.

**Hapsin bedeli:** iş biter (kayıt geçmişe geçer, silinmez) · gelir kesilir · yaşayan herkesle bağ düşer (giriş −6, her yıl −3) · mutluluk −12, sağlık −4 · dışarının bütün aktiviteleri kapanır.

**Karar soruları:**
1. **Hangi işler hangi kuralda olmalı?** Şu an 4 iş temiz kayıt istiyor, 4 iş ağır kayıtta kapanıyor, kalan 36 iş serbest. Liste genişletilsin mi?
2. Sabıka **zamanla silinmeli mi?** Şu an hayat boyu duruyor. Gerçekte adli sicil kaydı belirli koşullarda siliniyor; oyuna girsin mi?
3. **Erteleme** (hükmün ertelenmesi) şu an sabıka sayılıyor ve işi kapatıyor. Doğru mu?
4. Hapsin bağ üzerindeki etkisi (giriş −6, yıllık −3) doğru mu? Çok mu sert, az mı?
5. Cezaevindeki dört aktivite yeterli mi? (Görüş, kitap, spor, sakin kalmak.)
6. Hapisten sonra iş bulmak şu an yalnızca `recordRule` üzerinden zorlaşıyor; ayrıca bir "işe alım isteksizliği" olmalı mı?

---

### Q-144 — Arkadaşlığın eşikleri ve küslüğün sertliği
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-130 · `app/lib/domain/interaction/friendship_depth.dart` · Test: `app/test/friendship_depth_test.dart`

Arkadaşlık artık kurulabiliyor, kopabiliyor ve düzelebiliyor. **Eşikler onay bekliyor.**

| Kural | Şu anki değer |
|---|---|
| Yakın arkadaş olmak için gereken yakınlık | **55** |
| Kabul şansı | 55'te %45 · 100'de %90 |
| Reddedilmenin bedeli | yakınlık **−8** |
| Küsme eşiği | yakınlık **18'in altı** + **3 yıl** ilgisizlik |
| Yılda kopabilecek arkadaşlık | en fazla **1** |
| Barışma için gereken kalan yakınlık | **12** |
| Barışmanın kazandırdığı | yakınlık **+14** |
| Arkadaştan haber gelme ihtimali | yılda **%28** |

**Ölçüm (100 hayat, oyuncu gibi oynanarak):** hiç arkadaşı olmayan **0**, yakın arkadaşla ölen **88**, ortalama arkadaş **6,8**, ortalama yakın arkadaş **3,3**, hayatında küslük yaşayan **89**.

**Karar soruları:**
1. **Küslük çok mu sık?** 100 hayatın 89'unda en az bir arkadaşlık kopuyor. Gerçekçi mi, yoksa fazla mı?
2. Ortalama **6,8 arkadaş** doğru mu? Bir insanın hayatında bu kadar "yakın arkadaş" olur mu, yoksa sayı düşürülmeli mi?
3. Yakınlık eşiği **55** doğru mu? Sınıf arkadaşları 35-55 arası başlıyor; yani çoğunda birkaç kez vakit geçirmek gerekiyor.
4. Reddedilmenin **−8** bedeli doğru mu? Israrla tekrar teklif edilebiliyor; bir üst sınır olmalı mı?
5. Barışma şu an **ısrarla** denenebiliyor (her yıl bir deneme). Sınırlanmalı mı?
6. Arkadaşın "zor gün" haberi şu an yalnızca haber; oyuncunun **gidip yardım etmesi** için ayrı bir eylem olmalı mı? (Şu an yalnızca olay havuzundan geliyor.)

---

### Q-145 — Arkadaşlık olaylarının temaları
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-130 · `app/lib/data/event_pool_friendship.dart`

13 olay yazıldı, üç zincir: çocukluk arkadaşının dönüşü, zor gün ve karşılığı, kırgınlık → kavga → barışma. Tekil olaylar: sır tutmak, sağdıçlık, arkadaşın grubuna girmek, uzaktan arkadaşlık, arkadaşın para istemesi.

**Karar soruları:**
1. Temalar doğru mu? Eksik olan var mı (ör. arkadaşın ihaneti, ortak iş kurmak, arkadaşın vefatı)?
2. Etki değerleri onaylanıyor mu? Örnek: zor günde gitmek yakınlık **+18**, gitmemek **−20**; sırrı anlatmak **−25** ve küslük.
3. Çocukluk arkadaşı zinciri şu an 22 yaşından sonra açılıyor. Doğru yaş mı?
4. "Arkadaşın para istemesi" olayı borç sistemine (D-128'deki borç davası) bağlanmalı mı? Şu an bağlı değil.

---

### Q-146 — Yarım zamanlı iş ve kendi işi: sayılar
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-131, D-132 · `app/lib/data/job_catalog.dart`, `app/lib/data/business_catalog.dart`, `app/lib/domain/economy/business_engine.dart` · Test: `app/test/part_time_work_test.dart`, `app/test/business_test.dart`

**Yarım zamanlı iş (D-131):** 8 iş, yıllık 118.000-186.000 ₺. Okurken çalışmanın bedeli: alan zekâ katkısı yarıya iner, yılda −2 sağlık ve −1 mutluluk.

**Kendi işi (D-132):** 13 tür, sermaye 84.000-2.900.000 ₺. Durum 0-100; 50 üstünde kâr, 25 altında zarar, 0'da batar. İlgilenmek +12 (maaşlı işte +6), ilgilenmemek −9/yıl, para yatırmak asgari ücretin her yıllık katı için +10 (en çok +35).

**Karar soruları:**
1. **Yarım zamanlı maaşlar doğru mu?** En yükseği (kurye, 186.000 ₺/yıl ≈ 15.500 ₺/ay) 2026 için makul mü?
2. Okurken çalışmanın bedeli doğru mu? Zekâ katkısının **yarıya inmesi** çok mu sert?
3. **Sermayeler doğru bantta mı?** Halı saha 2.360.000 ₺, lokanta 2.021.000 ₺, büfe 236.000 ₺.
4. **Batma hızı doğru mu?** İlgilenilmeyen iş kaç yılda batmalı? Şu an durum 48'den başlıyor ve yılda 9 puan düşüyor — yani hiç bakılmazsa kabaca 5-6 yılda batıyor.
5. Aynı anda **tek iş** kuralı doğru mu? İkinci iş ileride açılsın mı?
6. **Kendi işi emeklilik hakkı vermiyor.** Maaşlı çalışan emekli olabiliyor, esnaf olamıyor. Bu bir eksik mi, yoksa bilinçli mi olmalı?
7. Kendi işi için **banka kredisi** kullanılabiliyor (gerekçede yazıyor) ama ayrı bir "işletme kredisi" yok. Gerekli mi?
8. İş **kuşak devamında** ne olmalı? Şu an `BusinessEndReason.kusakDevami` alanı var ama kuşak geçişinde işlenmiyor.

---

### Q-147 — Ekrana gelen kayıtlar ve kalabalık aktivite
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-133 · Test: `app/test/missing_screens_test.dart`

Dört görünmeyen kayıt ekrana geldi: Hobilerim, Evlilik Geçmişi, evcil hayvan detayı, çoklu kişiyle aktivite.

**Karar soruları:**
1. **Hobilerim** Aktiviteler altında; doğru yer mi? Yoksa kendi sekmesi mi olmalı?
2. **Evlilik Geçmişi** İlişkiler altında; doğru mu?
3. Kalabalık aktivitede ücret **kişi başına** artıyor (3 kişi = 3 bilet). Doğru mu, yoksa grup indirimi mi olmalı?
4. Kalabalık gitmek şu an herkese **aynı** bağ puanını veriyor. Kalabalıkta kişi başına daha az mı olmalı? ("Beş kişiyle sinemaya gitmek, bir kişiyle gitmek kadar yakınlaştırmaz.")
5. Kalabalık aktivitede en fazla kaç kişi olmalı? Şu an teknik sınır 8, pratikte listedeki herkes.

---

### Q-148 — Kefalet, tutukluluk ve çeteleşmenin sınırı
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-139, D-140 · `app/lib/domain/law/prison_life.dart`, `app/lib/domain/law/legal_engine.dart` · Test: `app/test/bail_prison_test.dart`, `app/test/bail_prison_widget_test.dart`

Faho'nun isteği: "hapishane sistemine şey ekle, para ile çıkabilelim, kefalet ücretiymiydi neydi; aileden ödemesini isteyebilelim veya paramız var ise biz ödeyelim; avukat tutabilelim; içeride hapishanede arkadaşlar edinebilelim; ileride çete eklicez, onun ilk adımları gibi düşün, hapishanede çeteleşebilelim."

**Claude'un uyguladığı okuma (teknik varsayım, ürün kuralı değil):** Türkiye'de kefalet **tutukluluğu** kaldırır, verilmiş bir hapis cezasını satın almaz. Bu yüzden kod şöyle kuruldu: ağır bir dosyada (%45) tutuklama kararı çıkabiliyor, kefalet belirleniyor, oyuncu kendi yatırıyor ya da aileden istiyor; duruşmaya çıkınca kefalet **geri veriliyor**; tutuklulukta geçen süre cezadan **düşülüyor**. Hükümlülükten para ile çıkış yoktur; onun yerine **iyi hâl → koşullu salıverilme** var.

**Karar soruları:**
1. **Doğru okuma bu mu?** Faho "para ile çıkabilelim" derken hükümlülükten de para ile çıkmayı mı kastetti? Öyleyse bu gerçeklikten ayrılır; isteniyorsa ayrı ve bilinçli bir oyun kuralı olarak yazılır.
2. **Kefalet tutarı:** şu an olayın para cezası tavanının **2 katı** (yaralamada ≈ 6 asgari ücret). Doğru bantta mı?
3. **Tutuklama sıklığı %45** ve yalnızca ağır olayda (orta olayda sabıkalıysa). Çok mu sık, az mı?
4. **Tutukluluk tavanı 2 yıl.** Süre dolunca "tutuksuz yargılanma" ile çıkılıyor. Doğru mu?
5. **Kefalet geri veriliyor.** Aileden biri yatırdıysa para ona dönüyor, oyuncunun cüzdanına girmiyor ve bağ +3 oluyor. Doğru mu?
6. **Çeteleşme nerede durmalı?** Şu an yalnızca bir sayaç: `crewStanding` 0-100, içerideki metinleri değiştiriyor ve **koşullu salıverilmeyi kapatıyor** (eşik 50). Dışarıda örgüt, gelir, emir zinciri **yok**. Sonraki adımda ne gelmeli — tahliyeden sonra süren bir bağ mı, mahalle düzeyinde bir grup mu, hiçbiri mi?
7. **Koşullu salıverilme eşiği:** iyi hâl ≥ 60, cezanın yarısı yatılmış ve koğuş itibarı < 50. Doğru mu?
8. Cezaevi eylemleri yılda **2 kez**; bir hükümlülükte en fazla **3** koğuş arkadaşı. Doğru mu?

**Varsayılan işlem:** Onay gelene dek sayılar `prototypeOnly` kalır; çete tarafı sayaçtan öteye geçmez.

---

### Q-149 — Üvey anne/baba: tetik, sıklık ve üvey kardeş
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-141 · `app/lib/domain/generation/step_parents.dart` · Test: `app/test/bail_prison_test.dart`

Faho'nun isteği: "üvey anne baba olabilsin."

**Uygulanan:** Ebeveynlerden biri **vefat ettiyse**, hayatta kalan ebeveyn (en çok 72 yaşına kadar) yas süresi geçtikten sonra yılda %12 ihtimalle yeniden evleniyor; gelen kişi `uveyAnne`/`uveyBaba` olarak çekirdek ailede listeleniyor, bağ 18'den başlıyor, kan bağı sayılmıyor.

**Karar soruları:**
1. **Tetik yalnızca vefat.** Ebeveynlerin **boşanması** oyunda hiç modellenmiyor. Eklenmeli mi? Eklenirse aynı kapı kullanılacak.
2. **Yas süresi 2 yıl** ve **yıllık %12**. Doğru mu?
3. **Üvey kardeş gelmiyor.** Üvey ebeveynin kendi çocukları olmalı mı? Olursa hangi bağ türü (`uveyKardes`) ve aynı hanede mi?
4. Oyuncu bu evliliğe **karşı çıkabilmeli mi**? Şu an çocuğun karar hakkı yok; haber olarak geliyor.
5. **Üvey ebeveynden miras** olmalı mı? Şu an kan bağı olmadığı için miras akışına girmiyor.
6. Üvey ebeveynle **etkileşimler** anne/babayla aynı (vakit geçir, sohbet, hediye, para iste). Para isteme baştan açık olmalı mı, yoksa bağ belirli bir eşiği geçince mi?
7. Üvey ebeveyn geldiğinde oyuncunun mutluluğu **düşüyor** (18 altında −3, üstünde −1). Doğru mu?

**Varsayılan işlem:** Onay gelene dek üvey kardeş, miras ve boşanma tetiği eklenmez.

---

### Q-150 — 2. el araç pazarı: fiyat, yaş ve ilan dili
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-137 · `app/lib/domain/economy/used_vehicle_market.dart` · Test: `app/test/used_vehicle_market_test.dart`

Faho'nun isteği: "2. el araç pazarı ekleyelim, içerisinde araç ilanları olsun, araç detayları yazsın — şasi podyede oynama yoktur, bel altı temizlik, boyalı vb."

**Uygulanan:** Yaşanan ilde 9 ilan. Fiyat = şehir katsayısı × yaş kaybı (yılda %7, tabanı %35) × durum (hatasız 1,08 / bakımlı 1,00 / ortalama 0,88 / yorgun 0,72) × satıcı (sahibinden 0,97 / galeriden 1,04). Alınan araç ilanın kondisyonuyla giriyor (92/78/60/38). Havuz şehir + oyuncu yaşına göre **belirlenimli**: yıl geçince tazeleniyor.

**Karar soruları:**
1. **Yaş kaybı yılda %7, taban %35.** Doğru mu? 15 yaşındaki bir araç sıfırının ~%35'ine iniyor.
2. **İlan sayısı 9.** Az mı, çok mu?
3. **Pazar yılda bir tazeleniyor.** Aynı yıl içinde yeni ilan çıkmıyor. Doğru mu?
4. **Model yılı yazılmıyor** ("8 yaşında" deniyor), çünkü oyunda takvim yılı yok. Bu kabul edilebilir mi, yoksa gizli bir başlangıç yılı mı eklenmeli?
5. **En yorgun ilanın kondisyonu 38.** Seyahat için alt sınır 25; yani yorgun araç yola çıkabiliyor ama bakım istiyor. Doğru mu?
6. Pazardan alınan aracın **masraf olayı** çıkarması gerekir mi? Şu an yalnızca "uygun fiyatlı galeri" için böyle bir not var.
7. İlan detayları **satıcı beyanıdır**; ekranda öyle yazıyor. İlerideki bir sürümde **yalan ilan** (yazandan kötü çıkan araç) olmalı mı?
8. **Takas** ve **pazarlık** ilan notlarında yazıyor ama mekanik değil. Eklenmeli mi?

---

### Q-151 — Kurgusal araç marka ve model adları
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-136 · `app/lib/data/item_catalog.dart`

Faho'nun isteği: "araçların adlarını biraz günümüz araçları ile vurgula, mesela düşük bütçeli araca foros vb gibi, en azından telif yemeyiz."

**Uygulanan adlar:** Foros 1.0, Foros Kent 1.4, Tunca Ege 1.2, Tunca Ferah 1.6, Veran Sedan 1.6, Doruk Yayla 4x4, Alvera Salon 2.0, Sarp Coupe 3.0, Alvera Prestij 4.0; motosikletler: Rüzgâr Scoot 125, Rüzgâr 250, Sarp 750, Sarp 1100 Tur. Sınıf bilgisi ayrı alanda (`ItemType.segment`) duruyor ve ad altında yazıyor.

**Karar soruları:**
1. **Adlar beğenildi mi?** Faho'nun örneği "Foros" korundu; diğerleri Claude'un önerisi.
2. **Altı marka** çok mu (Foros, Tunca, Veran, Doruk, Alvera, Sarp)? Daha az marka ve daha çok model mi olmalı?
3. Bisiklet hâlâ sadece "Bisiklet". Ona da kurgusal ad verilmeli mi?
4. Konutlara da kurgusal **site/proje adı** verilmeli mi? ("Alvera Konakları" gibi.)
5. Marka adı oyuncunun **statüsünü** anlatmalı mı? ("Alvera sürüyor" demek bir şey ifade etmeli mi, yoksa sadece etiket mi kalmalı?)

---

### Q-152 — Mağaza menülerinin düzeni
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-138 · `app/lib/data/shop_catalog.dart`, `app/lib/ui/screens/sections/assets_screen.dart`

Faho'nun isteği: "menüleri düzenli hale getir", "market menülerini daha stabil ve güzel hale getir."

**Uygulanan:** Mağazalar üç öbekte (Gündelik alışveriş / Araç ve aksesuar / Konut), öbek ve satır sırası sabit; raf içi ürünler ucuzdan pahalıya sıralı. Evcil hayvan edinme listesi tür gruplarına ayrıldı (D-135).

**Karar soruları:**
1. **Üç öbek doğru kırılım mı?** Aksesuarcılar araç öbeğinde duruyor; ayrı bir "Aksesuar" öbeği mi olmalı?
2. Ürünler **ucuzdan pahalıya** sıralı. Alternatif: kademe kademe (giriş/orta/üst) başlıklar. Hangisi?
3. Mağaza satırında şu an **ürün sayısı** yazıyor. Yerine **fiyat aralığı** mı yazsın ("350 ₺ – 14,5 M ₺")?
4. Parası yetmeyen ürün şu an listede **kapalı düğmeyle** duruyor. Gizlenmeli mi, yoksa görünmeye devam mı etmeli?
5. Evcil hayvan grupları açılır-kapanır (`ExpansionTile`). Mağaza öbekleri de açılır-kapanır mı olmalı, yoksa başlık olarak kalmalı mı?

---

### Q-153 — Paket W: Faho'nun 13 maddelik hata listesinden çıkan sayılar
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-142 … D-150 · Test: `app/test/paket_w_test.dart`, `app/test/after_school_widget_test.dart`, `app/test/business_widget_test.dart`

Listedeki maddelerin çoğu **gerçek hataydı** ve düzeltildi (aşağıda ayrıca soru yok). Karar bekleyen yalnızca yeni gelen sayılar ve iki tasarım tercihi:

**1. Araç gideri (D-148).** Sahip olunan her motorlu araç için yıllık gider geldi: zorunlu trafik sigortası (araç değerinin **%1,0**'i), kasko (**%2,5**), MTV (**%1,2**, araç yaşlandıkça %35'ine kadar iner).
   - Oranlar doğru bantta mı? Ekonomik otomobil (1.650.000 ₺) için yılda ≈ 77.000 ₺ çıkıyor.
   - **Kasko isteğe bağlı olmalı mı?** Türkiye'de trafik sigortası zorunlu, kasko değil. Şu an herkes kasko yaptırıyor sayılıyor. Seçilebilir olsun mu (yaptırmayan ucuz kurtulur ama kaza masrafını kendi öder)?
   - Araç kullanılmasa (ehliyet yokken miras kalan araba) da gider çıkıyor. Doğru mu, yoksa "trafiğe kapalı" seçeneği mi olmalı?

**2. Medya fırsatları (D-147).** Yılda toplam **2** iş, aynı iş için **3 yıl** bekleme, kabul şansı tabanı **%30**.
   - Yılda 2 doğru mu? Çok tanınan biri için 3-4 olmalı mı (Ün'e bağlı bir tavan)?
   - Aynı işin 3 yıl bekleme süresi doğru mu?
   - Kabul şansı Ün ile %92'ye kadar çıkıyor; tavan doğru mu?

**3. Arkadaş haberleri (D-149).** Aynı kişiden **3 yıl**, aynı türden **8 yıl** bekleme; her türde 3 metin.
   - Bekleme süreleri doğru mu?
   - Dört haber türü (taşındı, evlendi, iş değiştirdi, zor gün) yeterli mi? "Çocuğu oldu", "hastalandı", "memleketine döndü" eklensin mi?

**4. Hayvan bakım gideri (D-144).** Sahiplenmediğin hayvanın bakımı senden çıkmıyor.
   - Oyuncu **yetişkin olduktan sonra** da ailenin hayvanının bakımı bedava kalmalı mı? Yoksa 18'den sonra (ya da evden çıkınca) sorumluluk oyuncuya mı geçmeli?

**5. Kendi işi (D-143).** İkinci iş uyarısı yılda en çok bir kez, **%28** ihtimalle geliyor.
   - Oran doğru mu? Uyarı birikince işten çıkarılma ihtimali artıyor (D-078 sayacı); bu yeterli bir bedel mi?

**6. Lise sonrası karar (D-142).** Pencere kaldırıldı, oyuncu Okul/Meslek ekranının "Mezuniyet sonrası" sayfasına düşüyor.
   - Doğru yer mi? Lise **alan** seçimi hâlâ pencereyle soruluyor (gidilecek ayrı sayfası yok); o da bir sayfaya mı taşınmalı?

**7. Evcil hayvan (D-146).** Sayfa İlişkiler altına taşındı, Varlıklar'dan ve Aktiviteler'den kaldırıldı.
   - Doğru yer mi? Sahiplenme de aynı sayfada duruyor; sahiplenme Aktiviteler'de mi kalmalıydı?

**Varsayılan işlem:** Onay gelene dek bütün sayılar `prototypeOnly` kalır; kasko isteğe bağlı hâle getirilmez, ek haber türü eklenmez.

---

### Q-154 — İkiz gebelik: oran ve sonuçları
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-151 · Test: `app/test/paket_x_test.dart`

Faho'nun A grubu isteğiyle ikiz gebelik geldi. Gebelik kaydı **tek** kalıyor; ikinci bebek aynı doğumda dünyaya geliyor, aynı diğer ebeveynden. İki ayrı "çocuğunuz oldu" penceresi açılmıyor; tek bir ikiz bildirimi var.

**Karar soruları:**
1. **Oran %2,8** (`Parenthood.prototypeOnlyTwinChance`). Türkiye'de ikiz doğum oranı yaklaşık %2-3; oyunun ölçeği buradan seçildi. Doğru mu?
2. **Tüp bebek tedavisi (D-... / Paket 35) ikiz oranını yükseltmeli mi?** Gerçekte belirgin biçimde yükseltir. Şu an tedaviden gelen gebelik ile kendiliğinden gelen gebelik **aynı** orana bakıyor, çünkü gebelik kaydında "tedaviyle mi oldu" bilgisi tutulmuyor. Tutulsun mu?
3. **Doğum masrafı iki kez alınıyor** (her bebek için `prototypeOnlyBirthCost`). İki bebek iki masraf mı, yoksa tek doğumun tek masrafı mı olmalı?
4. **En fazla çocuk sayısı 4.** Üç çocuğu olan oyuncuda ikiz çıkarsa ikinci bebek gelmiyor (sınır aşılmıyor, doğum tek bebekle kapanıyor). Doğru mu, yoksa ikiz sınırı bir kez aşabilmeli mi?
5. **Üçüz yok.** Eklenmeli mi, yoksa ikiz yeterli mi?

**Varsayılan işlem:** Onay gelene dek oran `prototypeOnly` kalır; üçüz eklenmez, tedavi ile kendiliğinden gebelik ayrılmaz.

---

### Q-155 — Genişletilen kataloglar: yeni hobiler, bölümler, medya işleri ve dövüş dalları
**Durum:** Öneri, karar bekliyor · **Bağlam:** D-152 · Test: `app/test/paket_x_test.dart`

`docs/EKSIKLER.md` §4.3'te kataloğun dar olduğu ölçülmüştü. Genişletilenler:

| Katalog | Önce | Sonra |
|---|---|---|
| Hobi | 4 | **12** |
| Üniversite bölümü | 11 | **20** |
| Medya işi | 7 | **14** |
| Dövüş sanatı | 3 | **6** |

Yeni hobilerin sekizi: mutfak, fotoğraf, dans, satranç, yazmak, bahçe, yabancı dil, bilgisayar. İlk altısı için **altı yeni kurs** eklendi (Kurslar mekânı); son ikisi zaten var olan dil ve bilgisayar kurslarını besliyor, yeni düğme gerekmedi. Kuralı bozmadım: her hobiyi gerçekten var olan bir eylem besliyor, sahte hobi yok (kalıcı test).

Yeni dövüş dalları **boks, judo, taekwondo**. Basamak adları gerçek düzenlerden: boksta kuşak yoktur, amatör yaş kategorileri ve profesyonel sıralama kullanıldı; judo kyu/dan, taekwondo gup/dan. Üçü için eğitmenlik işi ve üçer mülakat sorusu da eklendi — eksik olsa basamak boşa giderdi (mevcut testler bunu yakaladı).

**Karar soruları:**
1. **Hobi 12 yeterli mi, fazla mı?** Hobi ekranı uzadı; öbeklenmeli mi (sanat / spor / zihin / el işi)?
2. **Yeni kursların ücretleri** 3.200 – 11.000 ₺ arası. Doğru bantta mı? Satranç kulübü en ucuz (3.200 ₺), yazarlık atölyesi en pahalı (11.000 ₺).
3. **Yeni bölümlerin taban puanları** doğru mu? Diş hekimliği 84, hukuk 76, veterinerlik 74, turizm 38.
4. **Bölüm–meslek eşleşmesi:** yeni bölümlerin çoğu şu an hiçbir mesleğin **şartı** değil (meslekler yalnızca "üniversite mezunu" istiyor). Hukuk okuyup avukat olmak gibi bir bağ kurulsun mu? Bu ayrı ve büyük bir iş.
5. **Yeni medya işleri** (ödül töreni sunuculuğu 60 asgari ücret, dijital platform programı 55) ün eşiği 78 ve 68. Tutarlar çok mu yüksek?
6. **Boksta kuşak olmadığı için** basamaklar "Yıldızlar / Gençler / Büyükler / Bölge şampiyonu / Türkiye şampiyonu / Profesyonel…" diye gidiyor. Bu doğru bir çözüm mü, yoksa boks hiç girmemeli mi?

**Varsayılan işlem:** Onay gelene dek bütün ücretler, puanlar ve basamak sayıları `prototypeOnly` kalır; bölüm–meslek bağı kurulmaz.
