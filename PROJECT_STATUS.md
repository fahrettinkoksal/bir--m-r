# Proje durumu

**Aşama:** Kodlama sürüyor. Teknoloji olarak **Flutter + Android önceliği Faho tarafından onaylandı**. `docs/CLAUDE_PROTOTYPE_TASK.md` içindeki **Aşama 1, 2, 3 ve 4 uygulandı** (`app/` klasörü); Aşama 5 (baştan sona entegrasyon denemesi ve teslim) henüz yapılmadı. D-030'daki **sevgili → ayrılık → eski sevgili** akışı gerçekten oynanabilir durumdadır.

## Şu ana kadar ana hatlarını belirledik
Türkiye/nostalji odaklı özgün oyun kimliği; iki başlangıç modu, rastgele aile/şehir; dış görünüş, mutluluk, sağlık, zekâ, karizma; kişi bazlı ilişkiler; geçmiş karar hafızası; yaşa/koşula uygun olaylar; ailenin bağımsız yaşam gelişmeleri. Kesin karar kaydı: `DECISIONS.md`.

## Aile ve genel işleyiş: netleşenler
Aile rastgele çeşitlenir; aynı evde yaşama ile akrabalık ayrı tutulur. Aile sekmesinde kişiler görülür, hediye verilir, birlikte vakit geçirilir; aile etkileşimleri ana karakteri etkiler. Uzun süre oyun içinde görüşülmeyen aile bireyi bazen sitem edebilir.

**Yaş Al** isteğe bağlıdır ve yeni yaşta ilk olarak bir uygun olay çıkar. Sonraki olaylar oyun içi ilerlemeye göre aralıklı gelir; gerçek dünya dakikaları beklenmez. Geçmiş hikâyeler seçimlere göre devam eder. Yakın zamanda yinelenen aile davetini kişi bazen reddedebilir. Genel etkileşim/hak kotası yoktur; aynı yaşta aynı etkinliğin olumlu getirisi giderek azalır ve sıfıra iner.

**Ün**, herkeste başlangıçta görünmeyen; sosyal medya/takipçi veya uygun görünürlük sağlayan olaylarla düşük seviyeden açılabilen özelliktir. Ayrıntılı sosyal medya ve Ün sistemi henüz tasarlanmadı.

## İlk prototip — onaylanan yön
- Başlangıç alt menüsü **Hayat / Aile / Ben**; ileride Sosyal sekmesi, Ben altında spor salonu, berber, seyahat gibi eylemler eklenecek. Üç sekme kalıcı sınır değil.
- Görsel yön **modern + ölçülü nostaljik detaylar**, Bir Ömür'e özgün arayüzdür.
- **Kesin oynanabilir test:** uygun kişiyle sevgili olma → kişinin Aile'de sevgili görünmesi → ayrılık → aynı kişinin silinmeden **eski sevgili** statüsünde kalması. Romantik ilişki, akrabalık ve aynı evde yaşama birbirine karıştırılmaz.
- `docs/PROTOTYPE_UI.md` ekran/kapsam belgesidir. **`docs/CLAUDE_PROTOTYPE_TASK.md` Claude için hazırlanmış aşamalı uygulama görevi ve test matrisidir.** Görev belgesini oluşturmak kodun yazılması veya Claude tarafından çalıştırılması anlamına gelmez.

## Aşama 1 — yapıldı (kod: `app/`)
- Flutter proje iskeleti (`app/`, paket adı `bir_omur`, Android platformu kurulu). Kurulum ve çalıştırma: `app/README.md`.
- İki başlangıç modu (D-005): tamamen rastgele; yalnızca isim ve cinsiyet seçimi. Şehir ve diğer koşullar her iki modda da rastgele.
- Tutarlı rastgele aile üretimi (D-004, D-013, D-014): ebeveyn yaş/meslek/**kişisel** ekonomik durumu, ebeveyn ilişki durumu, 0-6 kardeş, geniş aile, evcil hayvan. Akrabalık ile **hane** ayrı alanlar; ayrı/boşanmış ebeveynler aynı hanede birlikte bulunmaz; vefat etmiş kişi hanede sayılmaz; çalışmayan kişiye meslek uydurulmaz.
- Hayat / Aile / Ben sekmeleri çalışır; sekme listesi yeni bölüm (ör. Sosyal) eklenebilecek biçimde tek listeden okunur.
- Hayat ekranı: karakter özeti, beş değer, hatıra defteri hissi veren hayat günlüğü ve belirgin **Yaş Al**. Yaş Al bu aşamada yalnızca zamanı ilerletir ve günlüğe tek satır yazar.
- **Ün** açılmadığı için hiçbir ekranda gösterilmez (D-027). Yazılmamış eylemler sahte düğme olarak konmadı.
- Görsel yön: Bir Ömür'e özgü modern + ölçülü nostaljik tema (kâğıt tonları, nar kırmızısı/çini yeşili, ince kilim şeridi).

## Aşama 2 — yapıldı (kod: `app/lib/domain/interaction/`)
- Aile → kişi detayı → **Vakit Geçir** ve **Sohbet Et** gerçekten çalışıyor; sonuç özgün Türkçe metinle ve uygulanan değişimlerle (yakınlık, mutluluk, karizma) gösteriliyor.
- **Genel etkileşim kotası yok (D-026).** Tekrar sayacı kişi + etkileşim türü bazında ve **yalnızca içinde bulunulan yaşa ait**. Anneyle vakit geçirmek babayı ya da aynı kişiyle sohbeti kilitlemiyor.
- Aynı yaşta aynı kişiyle aynı etkinliğin getirisi azalıyor ve o yaş için **sıfır ek kazanca** iniyor (D-019). Fayda bitince etkinlik kapanmıyor; sonuç metni gelmeye devam ediyor.
- Yakın tekrarda kişi **bazen** doğal gerekçeyle reddediyor; ret hâlinde küçük mutluluk kaybı **olabiliyor**, her ret ceza değil (D-020). İlk istek hiç reddedilmiyor.
- Vefat etmiş kişiyle veya yaşı uygun olmayan oyuncuyla etkileşim açılmıyor; düğme gösterilmiyor, gerekçe yazılıyor.
- Hayat günlüğüne yalnızca anlamlı sonuçlar yazılıyor; sıfır kazançlı tekrar günlüğü şişirmiyor.

## Aşama 3 — yapıldı (kod: `app/lib/domain/events/`, `app/lib/data/event_pool.dart`)
- **Yaş Al** sonrası yeni yaşın **tek** açılış olayı çıkıyor (D-021); uygun olay yoksa hiç çıkmıyor. Ekranda olay varken yaş ilerlemiyor ve ikinci olay açılmıyor.
- Genişletilebilir özgün olay verisi: kimlik, kategori, metin, uygunluk (yaş, hayatta olan kişi, hane, okul çağı, hikâye izi, sahip olunan varlık), seçenekler, etkiler ve geleceğe bırakılan iz. **Seçilen teknik şema onaylanmış tasarım kararı değildir.**
- **Hafıza (D-008, D-022):** bir seçim iz bırakıyor, ileriki uygun yaşta farklı bir devam açıyor. Çalışan zincir: `arkadasi_savunma` → `savundugun_arkadas` **ya da** `sessiz_kaldigin_gun`. İz yoksa devam gösterilmiyor.
- Uygunsuz olay çıkmıyor: sahip olunmayan bisiklet için bisiklet olayı, üniversiteye gitmemiş karakterde üniversite olayı, hayatta olmayan kişiyle kişili olay çıkmıyor.
- Ek olaylar **gerçek dünya dakikasıyla değil** oyun içi ilerlemeyle geliyor (D-024): kazanç sağlayan bir aile etkileşimi ilerleme sayılıyor; eşiğe ulaşılınca bir yaşta **en fazla bir** ek olay açılıyor. Zamanlayıcı yok.
- Olay sonucu karakter değerlerine, gerektiğinde ilgili kişinin ilişkisine ve hayat günlüğüne yansıyor.

### Sitem olayının bu kesitteki derinliği (D-025)
Uzun süre temas kurulmayan **hane** üyesi sitem edebiliyor. Ölçü oyun içi: kişiyle en son hangi yaşta anlamlı temas kurulduğuna bakılıyor (prototipte 3 yaş fark). Kişinin kendi ruh hâli, olay geçmişi veya farklı sitem kademeleri **modellenmedi**; bu yüzden sistem tam hâliyle var sayılmamalıdır.

## Aşama 4 — yapıldı (kod: `app/lib/domain/interaction/romance.dart`)
- Durakta tanışma → çıkma teklifi → **sevgili** zinciri gerçek seçimlerle işliyor; kişi Aile bölümünde **İlişkiler** başlığı altında sevgili statüsüyle listeleniyor.
- Ayrılık iki gerçek yoldan yapılabiliyor: kişi detayındaki **Ayrıl** düğmesi (onay soruluyor) ve ilişki tartışması olayındaki ayrılma seçeneği.
- **Ayrılınca kayıt silinmiyor, yeni kimlikle yeniden yaratılmıyor:** aynı kimlik, aynı isim ve aynı yakınlık değeriyle **Eski Kız Arkadaş / Eski Sevgili** statüsüne geçiyor; hayat günlüğü korunuyor (D-029).
- Sevgili/akraba/hane ayrı: sevgili kan bağı sayılmıyor, otomatik olarak haneye yerleştirilmiyor.
- Eski sevgiliye sevgiliye özel eylemler koşulsuz sunulmuyor; etkileşimler kapalı ve gerekçesi ekranda yazılı.
- Hikâye her hayatta zorunlu değil; uygun yaş ve koşulda ortaya çıkıyor.

### Çalıştırılan doğrulamalar
`flutter analyze` temiz; `flutter test` ile **94 test geçti** (aile üretim tutarlılığı, yaş alma, aile etkileşimi/azalan etki/ret, olay uygunluğu/hafıza/tempo, sevgili→ayrılık kimlik korunumu, arayüz gezinmesi ve tam ilişki akışı). Ekran görüntüleri `app/test/goldens/` altında üretildi.
**Doğrulanamayan:** Android APK derlemesi ve gerçek cihaz/emülatör denemesi — bu ortamda Android SDK indirilemedi (ağ politikası `dl.google.com` erişimini engelliyor). APK derlemesi Faho'nun ortamında denenmelidir.

## Şimdi yapılacak iş
Aşama 4 incelendikten sonra **Aşama 5** (baştan sona akışın gerçek uygulamada denenmesi, teslim ve durum kaydı) yapılacak. Bu ortamda Android derlemesi mümkün olmadığı için baştan sona deneme şimdilik otomatik testler ve widget akışlarıyla yapılmıştır. Kodda `prototypeOnly` olarak işaretlenen sayısal ağırlıklar geçicidir; kesin denge Faho onayıyla belirlenecek ve `DECISIONS.md` yalnızca onaylanan kararlarla güncellenecek.

### Faho'nun kararına bırakılan açık noktalar
- Azalma eğrisi (prototipte 4 tekrarda sıfır), ret olasılıkları ve ret sonrası mutluluk kaybı miktarı.
- Tekrar sayaçlarının yaş değişiminde **tam** mı kısmi mi yenileneceği (prototipte tam).
- Etkileşimlerin açıldığı asgari oyuncu yaşı (prototipte 4).
- "Sohbet Et" etkileşiminin kalıcı bir tür olup olmayacağı; hediye verme ekonomi sistemi tasarlanınca eklenebilir.
- Olay veri şeması (`GameEvent` / `EventRequirement` / `EventChoice` alanları) ve olay ağırlıkları.
- Bir yaşta en fazla kaç ek olay çıkacağı (prototipte 1) ve ek olay için gereken ilerleme eşiği (prototipte 3 kazançlı etkileşim).
- Sitem için gereken oyun içi yaş farkı (prototipte 3) ve sitemin derinliği.
- `lise_sonrasi` olayındaki "üniversite / çalışma hayatı" seçimi yalnızca bir **hikâye izidir**; eğitim ve kariyer sistemleri tasarlanmadı. Bu izin kalıcı olup olmayacağı Faho'nun kararı.
- **Partnerin cinsiyeti** prototipte oyuncunun karşıtı seçiliyor (`docs/PROTOTYPE_UI.md` §4'teki örneğe uygun). Yönelim ve eşleşme kuralları kararlaştırılmadı.
- Romantik olayların yaş aralıkları (tanışma 15-22, teklif 15-25) ve zincirin bir hayatta yalnızca bir kez kurulabilmesi.
- **Eski sevgiliyle hangi etkileşimlerin açık kalacağı** (`docs/PROTOTYPE_UI.md` §4 açık sorusu); şimdilik tamamı kapalı.
- Aile ekranında kan bağı olanlar, partnerler ve eski partnerlerin nasıl bölümleneceği; prototipte Çekirdek / Geniş / İlişkiler gruplaması kullanılıyor.

## Sonraki tasarım işleri
İlk çalışan dikey kesit doğrulandıktan sonra olay verisi ve sürekliliğini genişlet, aile, eğitim, kariyer, ekonomi, sosyal medya/Ün sistemlerini aşamalı ayrıntılandır. Kesin sayısal denge ve teknoloji hâlâ açık.

## ChatGPT / Claude devri
Yeni oturumda `DECISIONS.md`, bu dosya, `docs/PROTOTYPE_UI.md`, `docs/CLAUDE_PROTOTYPE_TASK.md` ve ilgili sistem belgelerini oku. **Önerileri kesin karar sayma.** Yeni karar alınırsa ilgili belgeleri güncelle; tamamlanmamış işleri tamamlandı yazma.

## Depo sınırı
Yalnızca `fahrettinkoksal/bir--m-r` üzerinde çalış. Hipopotamya organizasyonundaki hiçbir depoya dokunma.
