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

### Q-002 — Aynı yaşta ek olay temposu
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/events/event_engine.dart` (`prototypeOnlyMaxExtraEventsPerAge = 1`, `prototypeOnlyProgressPerExtraEvent = 3`).

**Mevcut kesin kural:** Yaş Al sonrası ilk olay tek başına gelir; oyuncu ilerledikçe **aynı yaşta da aralıklı, uygun yeni olaylar** gelebilir. Oyuncuya gerçek dakika bekletilmez; her dokunuşta olay spam'i olmaz. **Bir yaşta en fazla bir ek olay** veya **üç anlamlı eylem eşiği** onaylanmadı.

**Karar sorusu:** Yeni olay fırsatını sabit kota/eşik olmaksızın hangi oyun içi gelişmeler tetiklesin ve spam nasıl önlensin? Mevcut 1 olay/3 eylem **yalnızca demo parametresi**, nihai çözüm değil. Onay gelene kadar kesin yıllık kural sayma.

### Q-003 — Eski sevgiliyle etkileşimler ve ayrılığın hikâye durumuna etkisi
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/interaction/family_interactions.dart`, `romance.dart`, `app/lib/state/game_controller.dart`, `app/lib/data/event_pool.dart`.

**Mevcut kesin kural:** Eski sevgili aynı kişi kaydı ve geçmişiyle Aile'de kalır; sevgili statüsü devam etmez. Hangi iletişimlerin açık kalacağı onaylanmadı.

**Karar sorusu:** Eski sevgiliyle ör. selamlaşma/konuşma veya koşullu barışma gibi eylemler olacak mı? Hangi bağlamda? **Ayrıca teknik hata:** Kişi detayından `Ayrıl` seçimi kişi statüsünü değiştiriyor ancak `romantikBitti`/`romantikIliskide` hikâye izlerini güncellemiyor; dolayısıyla eski sevgiliyle karşılaşma olayının önkoşulu sağlanmıyor. Bu durum tasarım seçimi değil, iki ayrılık yolunun aynı tutarlı sonuç üretmesini gerektiren hata düzeltmesidir.

**Varsayılan işlem:** Mevcut eski sevgili eylemlerini geçici kapalı tut; teknik tutarsızlığı onaylı hikâye hafızası kurallarına uygun düzeltip test et; yeni eylemler için onay al.

### Q-004 — Romantik eşleşme, yaş uygunluğu ve kişi sürekliliği
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/interaction/romance.dart`, `app/lib/data/event_pool.dart`.

**Mevcut kesin kural:** Uygun kişiyle romantik ilişki başlatılabilir, ayrılınca eski sevgili olarak kalır. İlişki için seçilecek kişi, yönelim/eşleşme modeli, yaş aralıkları kararlaştırılmadı.

**Karar sorusu:** İlk prototipte partnerin cinsiyeti, uygun yaş ve tanışılan kişinin **ilk tanışmadan itibaren aynı kimlikle** kaydı nasıl yönetilsin? Kod şu an partneri yalnızca teklif kabul edilince oluşturuyor; durakta tanışılan kişinin kalıcı kaydı baştan yok. Bu genişleyen hikâye hafızası için geliştirme ihtiyacıdır. Henüz karşıt cinsiyeti veya mevcut yaş sınırlarını nihai ürün kuralı diye yazma.

### Q-005 — Yaş alınca uygun olay havuzu boş olduğunda
**Durum:** Karar bekliyor. **Kaynak:** `app/lib/domain/generation/life_progression.dart`, `app/lib/domain/events/event_engine.dart`.

**Mevcut kesin kural:** Yeni yaşa geçince ilk olarak **tek uygun olay** sunulması hedeflenir; kod uygun olay bulunamazsa `null` ile hiç olay göstermiyor. Prototipte özellikle çok erken yaşlarda geçerli aday eksik olabilir.

**Karar sorusu:** Havuz boşken genel ama yaşa uygun bir olay hazırlanmalı mı, yoksa yaş alma günlüğü ile geçiş geçici olarak kabul mü edilsin? İlk seçenek için özgün içerik gerekli; gizlice uygunsuz olay üretme.

### Q-006 — Kayıt ve cihazda doğrulama
**Durum:** Karar bekliyor. **Kaynak:** [PR #1](https://github.com/fahrettinkoksal/bir--m-r/pull/1), `app/README.md`.

**Mevcut durum:** Claude PR açıklamasında `flutter analyze` ve `flutter test` sonucu bildirmiş; **Android APK/cihaz testi yapılmamış**, oyun durumu yalnızca bellekte. Kullanıcının beğenmediği arayüzün gerçek cihaz görüntüsü elimizde doğrulanmış değil.

**Karar sorusu:** Görsel revizyonu netleştirirken önce Android emülatörü/cihaz görüntüleri ve cihazda gezinme kontrolü mü istenecek? Kalıcı oyun kaydı ilk testte mi yoksa sonraki aşamada mı yapılacak? Bunlar henüz onaylanmadı.

## Kontrol notu
Bu sıra, inceleme ve karar koordinasyonu içindir. `DECISIONS.md` ile eşdeğer değildir; Claude'un geçici teknik parametreleri Faho'nun ürün kararı sayılmaz.
