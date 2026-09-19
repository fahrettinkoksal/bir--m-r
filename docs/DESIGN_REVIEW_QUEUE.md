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

## Kontrol notu
Bu sıra, inceleme ve karar koordinasyonu içindir. `DECISIONS.md` ile eşdeğer değildir; Claude'un geçici teknik parametreleri Faho'nun ürün kararı sayılmaz.
