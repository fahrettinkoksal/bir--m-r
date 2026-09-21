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

## Kontrol notu
Bu sıra, inceleme ve karar koordinasyonu içindir. `DECISIONS.md` ile eşdeğer değildir; Claude'un geçici teknik parametreleri Faho'nun ürün kararı sayılmaz.
