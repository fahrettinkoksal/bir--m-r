# Proje durumu

**Aşama:** Kodlama sürüyor. Teknoloji olarak **Flutter + Android önceliği Faho tarafından onaylandı**. `docs/CLAUDE_PROTOTYPE_TASK.md` içindeki **Aşama 1-4 uygulandı** (`app/` klasörü) ve o günden bu yana çok sayıda paket eklendi; bu dosyanın sonundaki paket kayıtları güncel durumu anlatır.

**Aşama 5 (baştan sona deneme ve teslim) yarım:** baştan sona bir hayatı
oynayan bütünleşik senaryo testi yazıldı (Paket 42) ve otomatik testlerle
doğrulandı, ama **gerçek bir Android telefonda veya gerçek bir Windows
bilgisayarda oynanmadı**. Teslim adımı bu yüzden tamamlanmış sayılmaz.

D-030'daki **sevgili → ayrılık → eski sevgili** akışı gerçekten oynanabilir
durumdadır.

> **Bu dosyanın ilk bölümleri tarihsel kayıttır.** Aşağıdaki "Aşama 1-4" ve
> ilk paket bölümleri yazıldıkları günkü durumu anlatır; oradaki test
> sayıları, menü adları ve "henüz yok" ifadeleri o günün kaydıdır, bugünün
> durumu değildir. Güncel durum için dosyanın sonundaki paket kayıtlarına
> bakın.

## Şu ana kadar ana hatlarını belirledik
Türkiye/nostalji odaklı özgün oyun kimliği; iki başlangıç modu, rastgele aile/şehir; dış görünüş, mutluluk, sağlık, zekâ, karizma; kişi bazlı ilişkiler; geçmiş karar hafızası; yaşa/koşula uygun olaylar; ailenin bağımsız yaşam gelişmeleri. Kesin karar kaydı: `DECISIONS.md`.

## Aile ve genel işleyiş: netleşenler
Aile rastgele çeşitlenir; aynı evde yaşama ile akrabalık ayrı tutulur. **İlişkiler** sekmesinde kişiler görülür, hediye verilir, birlikte vakit geçirilir; aile etkileşimleri ana karakteri etkiler. Uzun süre oyun içinde görüşülmeyen aile bireyi bazen sitem edebilir. (Bu bölüm ilk yazıldığında sekmenin adı "Aile" idi; NAV-001 ile "İlişkiler" oldu.)

**Yaş Al** isteğe bağlıdır ve yeni yaşta ilk olarak bir uygun olay çıkar. Sonraki olaylar oyun içi ilerlemeye göre aralıklı gelir; gerçek dünya dakikaları beklenmez. Geçmiş hikâyeler seçimlere göre devam eder. Yakın zamanda yinelenen aile davetini kişi bazen reddedebilir. Genel etkileşim/hak kotası yoktur; aynı yaşta aynı etkinliğin olumlu getirisi giderek azalır ve sıfıra iner.

**Ün**, herkeste başlangıçta görünmeyen; sosyal medya/takipçi veya uygun görünürlük sağlayan olaylarla düşük seviyeden açılabilen özelliktir. Ayrıntılı sosyal medya ve Ün sistemi henüz tasarlanmadı.

## İlk prototip — onaylanan yön
- Başlangıç alt menüsü **Hayat / Aile / Ben** olarak onaylanmıştı. **Bu düzen NAV-001 ile değişti:** alt çubuk bugün soldan sağa **Okul/Meslek — Varlıklar — Yaş Al — İlişkiler — Aktiviteler** biçimindedir; `Yaş Al` bir sekme değil, ortadaki bağımsız ana eylemdir.
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

## Okul paketi — yapıldı (dal: `claude/okul-sistemi-v1`, kod: `app/lib/domain/models/education.dart`, `app/lib/domain/interaction/friendship.dart`)
GEN-001'deki "küçük, oynanabilir, test edilebilir paket" yaklaşımıyla yapıldı. PR #1'den kod kaybı yok; o dalın üzerine kuruldu.

- **Eğitim durumu oyun verisinde tutuluyor**; öğrencilik artık yaştan türetilmiyor. Okula başlamamış veya okulu bitirmiş karaktere okul olayı çıkmıyor.
- Basit akış: 6 yaşında 1. sınıf, her yaş bir sınıf, ilkokul/ortaokul/lise kademeleri, 12. sınıftan sonra okul bitiyor. Anlamlı geçişler hayat günlüğüne yazılıyor. **Sınav, not, diploma, sınıf tekrarı, okulu bırakma yok.**
- Okulda tanışılan arkadaş **kalıcı kimlikli gerçek bir kişi**; Aile bölümünde "Arkadaşlar" başlığında görünüyor, akraba sayılmıyor, otomatik haneye yerleşmiyor. Sonraki olaylar ve ileride sosyal medya aynı kaydı kullanabilir.
- Beş özgün okul olayı: sıra arkadaşıyla tanışma, teneffüs oyun daveti, ödev yardımı isteği, öğretmenin sorusu, yardımın karşılığı. Sonuncusu **yalnızca daha önce yardım etmiş** oyuncuya çıkıyor; yardım etmemek o devamı açmıyor ve ilişkiyi zayıflatıyor.
- Aile, romantik ilişki ve Yaş Al sistemleri bozulmadı; testlerle doğrulandı.

### Çalıştırılan doğrulamalar (okul paketi)
`flutter analyze` temiz; `flutter test` ile **119 test geçti** (5 atlandı: ekran görüntüsü üreteci). Okul paketi için 19 yeni test: eğitim durumunun veride tutulması, kayıt/ilerleme/bitiş, okul olaylarının uygunluğu, arkadaşın kimlik sürekliliği ve seçimlerin sonraki olayda hatırlanması.

### Okul paketinde karar bekleyenler
`docs/DESIGN_REVIEW_QUEUE.md` → **Q-014** (okula başlama yaşı, kademe akışı, okulu bırakma), **Q-015** (arkadaşlar arayüzde nerede görünsün), **Q-016** (arkadaşlarla etkileşimler aile kurallarına mı tabi), **Q-017** (arkadaş sayısı, arkadaşlığın zayıflaması, olumsuz seçimlerin devamı).

## Menü + arayüz revizyonu — yapıldı (dal: `claude/arayuz-revizyonu-v1`)
NAV-001 gezinme kararı uygulandı. Yeni oyun sistemi eklenmedi; aile, yaş alma, ilişkiler ve okul altyapısı korundu.

- **Alt gezinme NAV-001'e göre:** soldan sağa `Okul/Meslek — Varlıklar — [Yaş Al] — İlişkiler — Aktiviteler`. `Yaş Al` sekme değil, ortadaki bağımsız ana eylem düğmesi. Soldaki menü öğrenciyken **Okul**, değilken **Meslek** oluyor.
- **Ana ekran:** üstte sabit karakter özeti (ad, yaş/evre, şehir, kısa durum, cüzdan, beş değerin okunaklı şeridi), ortada hayat günlüğü, altta sabit menü. Değer şeridine dokununca tam adlarıyla ayrıntı açılıyor; eski sıkışık "Ben" ekranı kaldırıldı.
- **İlişkiler:** anne ve baba en üstte, altında `Akrabalar`, `Arkadaşlar` ve `Romantik bağlar` alt menüleri (yalnızca kişi varsa görünüyor). Veri yapısı değişmedi.
- **Aktiviteler:** iç içe menü; gerçekten çalışan tek kategori (birlikte vakit geçirme) gösteriliyor, yazılmamış alanlar için sahte düğme konmadı.
- **Okul/Meslek:** kademe/sınıf paneli, okul arkadaşları listesi; okul dışı durumda dürüst panel.
- **Varlıklar:** kişisel cüzdan (aile parasından ayrı), sahip olunan eşyalar ve evcil hayvanlar.
- **Cüzdan (ECO-001, yalnızca temel):** `PlayerCharacter.wallet` eklendi ve arayüzde gösteriliyor. Kazanma/harcama akışı yazılmadı; bakiye yalnızca olay etkisiyle değişebiliyor.

### Çalıştırılan doğrulamalar (arayüz revizyonu)
`flutter analyze` temiz; `flutter test` ile **120 test geçti** (6 atlandı: ekran görüntüsü üreteci). Ekran görüntüleri `app/test/goldens/` altında yenilendi.

### Arayüz revizyonunda karar bekleyenler
`docs/DESIGN_REVIEW_QUEUE.md` → **Q-018** (ana ekrana dönüş davranışı ve üst özet içeriği), **Q-019** (romantik alt menü adı ve kardeşlerin yeri), **Q-020** (Okul/Meslek menüsünün okul öncesi/okul sonrası içeriği), **Q-021** (cüzdan: para birimi, başlangıç bakiyesi, kazanma/harcama), **Q-022** (Aktiviteler kapsamı). Görsel yönün kendisi hâlâ **Q-001**'de açık.

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

## Kayıt / yükleme (uygulandı)
Faho'nun talimatıyla kayıt sistemi yazıldı: tek aktif hayat kaydı, cihazın
uygulamaya ait yerel veri klasöründe JSON, sürüm numarası, yarıda kesilmeye
dayanıklı yazma (geçici dosya + yedek + tek adımda taşıma) ve bozuk kayıtta
çökmeden uyarı. Başlangıç ekranına **Devam Et** eklendi; yeni hayat kaydın
üzerine yazacağı için önce onay soruluyor. Ayrıntı: `docs/SAVE_SYSTEM.md`.
Açık kalan sorular karar kuyruğunda **Q-035** altında.

## Paket 1 — okul, kişi ve hediye düzeltmeleri (uygulandı)
Sınıf mevcudu oyuncu hariç 10'a çıkarıldı; okul kişileri kademeye değil
**okula ve sınıfa** bağlandı (`Person.schoolId` / `classId`), kademe
geçişinde bir bölüm arkadaş aynı kimlikle yeni sınıfa taşınıyor, kalanlar
silinmeden eski sınıfta kalıyor. Okul ekranından "Yakın Arkadaşların"
kaldırıldı. Kişiye uygun olmayan etkileşim artık kilitli satır olarak
gösterilmiyor (`interaction_policy.dart`). Aktiviteler listesi yalnızca
gündelik hayatta gerçekten erişilebilen kişileri gösteriyor. Hediyeler
gerçek eşya kataloğuna bağlandı; kim kime ne verdi kaydediliyor. Olay
metinleri gerçekçilik açısından gözden geçirildi. Kayıt biçimi **sürüm 2**;
sürüm 1 kayıtları göçle açılıyor.

## Eşyalar ve temel ekonomi (uygulandı)
Varlıklar'daki eşyalar gerçek oyun nesnesi oldu: her eşya kendi kimliği,
kondisyonu, edinilme yolu ve takılı aksesuarlarıyla envanterde duruyor
(`GameState.items`). Bisiklete binme, temizlik, ücretli bakım, uyumlu
aksesuar takma ve onaylı satış çalışıyor; küçük bir mağaza eklendi. Satış
bedeli tür, kondisyon, aksesuar ve antika niteliğe göre hesaplanıyor.
Kayıt biçimi **sürüm 3**; sürüm 1 ve 2 kayıtları göçle açılıyor. Ayrıntı:
`docs/ITEM_SYSTEM.md`.

## Eğitim, lise tercihi, üniversite ve meslek (uygulandı)
8. sınıf sonunda yerleştirme puanı hesaplanıyor ve 9. sınıfta **lise alanı**
seçiliyor (9 alan, puanı düşük oyuncuya da en az üç seçenek). Alan eğitim
geçmişine yazılıyor; üniversite bölümlerini ve iş koşullarını etkiliyor.
12. sınıf sonunda kimse otomatik üniversiteye gitmiyor: başvur / iş ara /
kendi yolunu seç. Altı bölümlü küçük üniversite prototipi, altı işlik iş
pazarı, başvuru-kabul/ret akışı ve yaş alırken **bir kez** ödenen maaş
eklendi. Kayıt biçimi **sürüm 4**.

## Aktiviteler (uygulandı)
Aktiviteler menüsünde üç çalışan alt sistem var: **berber** (saç kestir,
stil değiştir, bakım), **spor salonu** (koşu, ağırlık, esneme) ve
**kütüphane** (yaşa uygun kitap seç, aç, sayfa çevirerek oku, bitir).
Ücretler cüzdandan gerçekten düşüyor, etkiler eyleme uygun ve aynı yaşta
tekrar sınırı var. Kitap ilerlemesi gerçek oyun verisi; bitirme kazancı
**bir kez** uygulanıyor. Kayıt biçimi **sürüm 5**.

## Sosyal medya ve Ün (uygulandı)
16 yaşından itibaren **isteğe bağlı** hesap açılabiliyor (YouTube,
Instagram, X — arayüz Bir Ömür'e özgü, logo/tasarım kopyalanmıyor). Her
platformun ayrı takipçi sayısı ve içerik geçmişi var; hesabı olmayan
platformda paylaşım yapılamıyor. On içerik türü; sonuç içerik türüne,
mevcut kitleye, karakter özelliklerine, geçmiş paylaşımlara ve şansa göre
değişiyor — bazı paylaşımlar takipçi kaybettiriyor. **Ün** ancak gerçek bir
kitle oluşunca açılıyor (D-027). Kayıt biçimi **sürüm 6**.

## Puan görünürlüğü ve mülakatlı iş başvurusu (uygulandı)
Üniversite başvuru ekranı artık oyuncunun **kendi puanını** gösteriyor:
lise bitince bir kez hesaplanıp kaydedilen **üniversite sınav puanı**, 8.
sınıftaki **lise yerleştirme puanından ayrı bir isimle** sunuluyor; her
bölüm kartında "Senin puanın: X / Taban puan: Y" karşılaştırması ve
uygun olmayan bölüm için gerekçe yazıyor. Başvuruda kullanılan puan
ekranda yazan puanla aynı (rastgelelik yok). **Üniversite not ortalaması
sistemi yok; uydurulmuyor** — ekranda bu açıkça belirtiliyor.

İşe başvuru artık doğrudan kabul/ret vermiyor: mesleğe uygun kısa bir
**mülakat sorusu** açılıyor (her meslek için 3-5 özgün soru, tek doğru
cevap). Doğru cevap **ve** nitelik koşulları birlikte aranıyor; yanlış
cevapta doğru seçenek ve kısa açıklama gösteriliyor. Soru, seçenekler ve
işe alma sonucu otomatik kayda giriyor; oyun kapanıp açılınca soru
değişmiyor ve cevap iki kez uygulanmıyor. Aynı yaşta başvuru sayısı
sınırlı ve aynı soru tekrarlanmıyor. Kayıt biçimi **sürüm 7**.

## Kumarhane: blackjack ve rulet (uygulandı)
Aktiviteler altında **Kumarhane** var; 18 yaşından (prototip sınırı)
itibaren açılıyor. **Yalnızca oyunun sanal cüzdanıyla** oynanıyor: gerçek
para yatırma/çekme, uygulama içi satın alma, reklam karşılığı bahis veya
ödüle dönüştürme **yok**.

**Blackjack:** standart 52 kartlık deste, kart çek / dur, As 1 ya da 11,
krupiye 17 ve üstünde duruyor, doğal blackjack 3:2 ödüyor, beraberlikte
bahis geri geliyor. Deste ve el kayda yazılıyor; oyun kapatılıp açılınca
aynı el aynı kartlarla sürüyor.

**Rulet:** tek sıfırlı Avrupa ruleti (0-36); kırmızı/siyah ve tek/çift
1:1, sayıya bahis 35:1. 0 gelince renk ve tek/çift bahisleri kaybediyor.
Sonuç tek bir rastgele çekilişle belirleniyor; gizlice kazandırma ya da
kaybettirme yok.

Bahis cüzdandan **bir kez** düşüyor, kazanç **bir kez** ekleniyor, cüzdan
eksiye düşmüyor. Bahis 50-5000 ₺ arası; bir yaşta toplam 25.000 ₺ bahis
sınırı var (hepsi `prototypeOnly`). Bahis ve sonuçlar hayat günlüğüne
yazılıyor. Kayıt biçimi **sürüm 8**.

## Mağazalar, araçlar, emlak ve ekonomi ölçeği (uygulandı)
Varlıklar → **Mağazalar** beş alt mağazaya ayrıldı: genel mağaza,
elektronik, spor ve hobi, **araç galerisi** ve **emlakçı**. Ürün sayısı
44'e çıktı; yaşa uygun olmayan mağaza menüde görünmüyor.

**Araçlar:** iki motosiklet, dört otomobil. Her araç gerçek bir varlık
kaydı: kalıcı kimlik, tür/model, satın alma fiyatı, kondisyon, sahip,
takılı aksesuarlar ve güncel satış değeri. Sürme, temizleme, bakım,
uygun aksesuar takma ve satma çalışıyor. **Araç sürmek ilgili ehliyeti
istiyor; araç sahibi olmak istemiyor.** Aksesuarlar türüne bağlı:
bisiklet zili otomobile, kask otomobile takılamıyor.

**Emlak:** dört konut türü. Mülk kaydında kalıcı kimlik, fiyat, sahip,
konum ve güncel değer var. **Ev satın almak o eve taşınmak değil**: mülk
sahipliği ile hangi hanede yaşandığı ayrı tutuluyor.

**Ekonomi ölçeği:** `lib/data/economy.dart` içinde ortak bir tablo var;
eşya fiyatları, araç/konut fiyatları ve yıllık maaşlar aynı para birimi
ve aynı dönem üzerinden yeniden ölçeklendi. Kumarhane bahis sınırları da
bu ölçeğe taşındı. Tablo gerçek piyasa fiyatlarının kopyası değil; tamamı
`prototypeOnly`. Kayıt biçimi **sürüm 9**.

## Ehliyet işlemleri (uygulandı)
Aktiviteler → **Ehliyet İşlemleri**. Motosiklet ve otomobil ehliyeti ayrı
ayrı alınıyor; biri diğerini vermiyor. Başvuruda sınav ücreti cüzdandan
bir kez düşüyor ve mesleğe göre ayrı havuzlardan kısa, çoktan seçmeli bir
soru açılıyor (motosiklet 5, otomobil 6 soru). Doğru cevapta ehliyet
kalıcı olarak ekleniyor ve günlüğe yazılıyor; yanlış cevapta ehliyet
verilmiyor, doğru cevap ve kısa açıklama gösteriliyor. Yarıda kalan sınav
kayıttan **aynı soruyla** geri geliyor; ücret ve cevap iki kez
uygulanmıyor. Aynı yaşta sınırlı deneme hakkı var ve her denemede ücret
yeniden alınıyor. Araç sürme eylemi ilgili ehliyeti kontrol ediyor.
Kayıt biçimi **sürüm 10**.

## Ölüm, aile değişimleri ve miras (uygulandı)
Hayat artık sonlu: yaşa bağlı bir eğilimle NPC'ler ve oyuncu vefat
edebiliyor. Küçük yaşlarda ölüm çok seyrek, ileri yaşta belirgin. Ölüm
gerekçeleri kısa ve yaşa uygun; ayrıntılı tasvir yok.

**Kayıtlar korunuyor:** vefat eden kişi silinmiyor, yalnızca
`isAlive: false` oluyor, haneden düşüyor ve yaşı sabitleniyor. Vefat
edenle yeni sohbet/hediye/para isteme açılmıyor; olay motoru onu canlı
gibi kullanmıyor.

**Hane ve bakım:** hane sayısı doğru güncelleniyor. Çocuk yaştaki oyuncu
hanede yetişkinsiz kalırsa **yeni NPC uydurulmuyor**: hayattaki yakın bir
yetişkin (büyükanne/büyükbaba, teyze/dayı/hala/amca ya da yetişkin
kardeş) haneye geçiyor; kimse yoksa durum yalnızca günlüğe yazılıyor.

**Miras:** kişilerin kendi mal varlığı (`Person.estate`) ve ekonomik
durumu üzerinden hesaplanıyor; nakit, eşya, araç ve konut kalabiliyor.
Basitleştirilmiş oyun içi paylaşım kuralı (eş + çocuklar → anne-baba →
kardeşler) kullanılıyor; zengin annenin serveti olduğu gibi oyuncuya
geçmiyor. Aynı miras iki kez dağıtılmıyor, aynı eşya iki mirasçıya
kopyalanmıyor, miras hayat günlüğüne yazılıyor ve Varlıklar'da görünüyor.

**Oyuncunun ölümü:** hayat tamamlanıyor, yaş ilerlemiyor ve bir hayat
özeti ekranı açılıyor (ad, ölüm yaşı, eğitim/meslek, aile, varlıklar,
hayattan satırlar). Kayıt silinmiyor; yeni hayat ancak onayla başlıyor.
Kayıt biçimi **sürüm 11**.

## Q-053–Q-059 kararları (alındı)
Faho ve ChatGPT bu turda Q-053–Q-059 başlıklarını karara bağladı; ilkeler
`DECISIONS.md` içinde **D-031 – D-038** olarak kayıtlı. Sayısal denge
(fiyatlar, maaşlar, gider oranları, ölüm olasılıkları, bahis sınırları,
sınav ücretleri) **geçici** kaldı ve Faho'nun onayına bağlı.

Ölçüm sonuçları `docs/BALANCE_REPORT.md` içinde. Kararlarla mevcut kod
arasındaki uyumsuzluklar ve veri kaybı riski `docs/FIX_REPORT_Q053_Q059.md`
içinde listelendi; bunlar ayrı bir düzeltme PR'ında ele alınacak.

## D-031 – D-038 düzeltmeleri (uygulandı)
Kararların kodla çeliştiği maddeler düzeltildi:

- **Geçmiş Hayatlar arşivi:** tamamlanan hayatın özeti yeni hayat
  başlatılırken **önce arşive yazılıyor**; arşiv kayıtta saklanıyor ve
  hayat özeti ekranından açılıyor.
- **Yıllık geçim gideri:** çocukta yok; ailesinin yanında, bağımsız kirada
  ve kendi evinde farklı. Cüzdan eksiye düşmüyor; para yetmezse geçim
  sıkıntısı durumu oluşuyor ve günlüğe yazılıyor.
- **Ehliyet sınavı 3 soru / en az 2 doğru;** sonuçta bütün doğru cevaplar
  ve açıklamaları görünüyor, yarıda kalan sınav aynı sorulardan sürüyor.
- **Yas zamanla hafifliyor;** kalıcı mutluluk cezası değil.
- **Miras:** eş payı yalnızca ebeveynler evli/birlikteyken uygulanıyor;
  sevgili eş sayılmıyor. NPC'lerin mal varlığı hayat boyunca değişiyor ve
  kişi detayında görünüyor.
- **Bakım durumu** (ailesinin yanında / yakın akraba / kurum bakımı) açık
  bir alan olarak saklanıyor; sahte kişi üretilmiyor.
- **Ayarlar:** kumarhane tamamen kapatılabiliyor, oyuncu kendine yıllık
  bahis limiti koyabiliyor.
- **Araç galerisinde satın alma yaşı 18;** miras/hediye yoluyla küçük yaşta
  araç sahibi olmak serbest, kullanmak ehliyete bağlı.

Kayıt biçimi **sürüm 12**; sürüm 11 ve öncesi kayıtlar güvenli
varsayılanlarla açılıyor ve hiçbir hayat silinmiyor. Sayısal değerler
(gider tutarları, ölüm olasılıkları, bahis sınırları) **geçici**.

## Denge turu: D-039 – D-042 (uygulandı)
Dört denge kararı kodlandı: gider artık **taban + gelire bağlı pay** ve
kalem kalem tutuluyor; ebeveyn yaşları **üçgen dağılımdan** seçiliyor ve
85 üstü ölüm eğrisi hafifçe yükseltildi; otomobil aksesuarlarının satın
alma yaşı 18 oldu; kumarhane bahis bütçesi **gelire ve cüzdana göre**
hesaplanıyor (en küçük bahis 100 ₺, oyuncunun kendi limiti daha düşükse o
geçerli).

5.000 hayatlık ölçüm: 90+ oranı %19,2 → **%12,6**, çocukken ebeveyn kaybı
%19,4 → **%12,3**, kirada yaşayan garsonun yıllık birikimi 25.000 ₺ →
**65.250 ₺**. Ayrıntı: `docs/BALANCE_REPORT.md` §5. Bütün sayılar
`prototypeOnly`.

## Taşınma, kira geliri ve sağlık krizleri (uygulandı)
**Konut (D-043):** mülk sahipliği ile oturulan ev ayrı. 18 yaşından
itibaren kendi evine taşınma, kiralık eve çıkma ve (hanede yetişkin varsa)
aile evine dönme var; taşınmanın masrafı cüzdandan bir kez düşüyor.
Oturulan ev kiraya verilemiyor, kiradaki eve taşınılamıyor. Kiraya verilen
konut yılda bir kez kira geliri getiriyor (bazı yıllar kiracı bulunmuyor) ve
bu gelir gider hesabına ve kumarhane bütçesine katılıyor. Emlakçıda şehir
seçilebiliyor; başka şehirdeki eve taşınmak yaşanan şehri değiştiriyor.

**Sağlık krizleri (D-044):** altı hastalık/kaza krizi; seyrek, yaşa ve
sağlığa bağlı, art arda çıkmıyor. Oyuncunun kararı (tedavi/erteleme)
sonucu etkiliyor ama garanti etmiyor; tedavi bedeli bir kez düşüyor.
Kriz ölümle biterse hayat olağan yoldan tamamlanıyor ve arşiv çalışıyor.
Sağlık çok düşünce bir kez uyarı veriliyor. Temel ölüm eğrisi, krizlerin
eklediği ölümü dengelemek için ölçümle düşürüldü.

## Evlilik ve çocuklar (uygulandı — onay bekliyor)
**Evlilik (Paket E1):** sevgiliyle evlenilebiliyor; kişi kaydı silinmiyor,
**aynı kimlik** eş oluyor. Koşullar ve tutarlar `prototypeOnly`: 18 yaş,
yakınlık 60, nikâh 60.000 ₺. Evlenmek kendi haneni kurmak demek; eş haneye
katılıyor ve gider "kirada" düzenine geçiyor. Boşanmada eş **aynı kimlikle**
eski eş oluyor, nakdin %25'i ona kalıyor. Eş vefat edince kayıt "dul"
oluyor ve miras D-037'ye göre işliyor.

**Çocuklar (Paket E2):** çocuk sahibi olmak isteğe bağlı bir eylem; evlilik
şartı var, aynı yıl ikinci bebek olmuyor, en fazla 4 çocuk. Çocuk kaydı
diğer kişilerle aynı yapıyı kullanıyor (kalıcı kimlik, yaş, hane, ölüm,
miras); ayrı bir çocuk sistemi kurulmadı. Hanedeki 18 yaş altı her çocuk
için yıllık gider kalemi var; çocuk 25 yaşında evden çıkınca kalem bitiyor
ve kaydı korunuyor.

**Paket 1 — entegrasyon turu (uygulandı):** evlilik/çocuk sistemi bütün
sistemlerle birlikte sınandı. Düzeltilenler: eş ve çocuk kaybının duygusal
ağırlığı (uzak tanıdıkla aynıydı), evli karakterin karşısına yeni romantik
tanışma olayının çıkabilmesi, "ailenin yanında" ölçütünün eşi aile sayması,
çocuğun soyadı, hayat özeti arşivinde aile bilgisinin tutulmaması ve eşi
kayıtlarda bulunmayan bozuk kaydın sessizce yüklenmesi. Ortak tutarlılık
denetimi (`test/support/invariants.dart`) 200 aile hayatında her yıl
çalıştırılıyor.

**Paket 2 — aile hayatı ve çocuk etkileşimleri (uygulandı):** 13 yeni aile
olayı (bebeklik, okulun ilk günü, karne, okul sorunu, söz verme, ergenlik,
meslek seçimi, evden ayrılma, eşle tartışma/anma/iş kararı, ziyaret). Üç
karar zinciri geçmişi hatırlıyor: okulun ilk günündeki destek ergenlikte,
verilen söz yıllar sonra, eşle konuşulan gece ileride. Olay koşullarına
**kişinin kendi yaşı** ve **hane dışında olma** eklendi; çocuk olayları
çocuğun yaşına bağlanıyor. Çocuğun okul kademesi yaşıyla ilerliyor
(22 yaşındaki çocuk "ilkokul öğrencisi" görünmüyor) ve oyuncunun okul
arayüzü kopyalanmıyor. Etkileşim metinleri eşe, çocuğun yaşına ve kişinin
hane durumuna göre değişiyor (ayrı evde yaşayanla görüşmek ziyaret).

**Paket 3 — şehir, okul, iş ve sosyal çevre (uygulandı):** kişilere ve işe
şehir bağı eklendi; okul/sınıf kimlikleri şehre bağlandı. Şehir değiştiren
öğrenci için okul nakli akışı var (eğitim geçmişi korunur, eski okul
kişileri silinmez, aynı anda iki okulda görünülmez). Başka şehirde kalan
arkadaş gündelik listelerden düşer ama kaydı ve yakınlığı durur; yakın
aile etkilenmez. İşin şehri kaydediliyor ve gösteriliyor; **şehir değişince
işe kendiliğinden son verilmiyor** (karar Q-065'te).

**Paket 4 — hayat olayları ve tekrar kalitesi (uygulandı):** olay kataloğu
ölçüldü (`app/tool/event_report.dart`), 0-4 yaş aralığında hiç olay
olmadığı ve 55 yaş sonrası kapsamın düştüğü görüldü. 33 yeni olay eklendi
(bebeklik, mahalle/okul, ergenlik, ilk ev/iş/geçim, meslek, mülk, sağlık,
emeklilik, yaşlılık). Olay koşullarına sosyal medya hesabı, ehliyet ve
gündelik erişilebilirlik eklendi: hesabı olmayana mesaj gelmiyor, ehliyeti
olmayan direksiyona geçmiyor, erişilemeyen kişi gündelik olayda
kullanılmıyor. Beş yeni karar zinciri ileride hatırlanıyor. Tekrar
aralıkları ölçüme göre büyütüldü (en sık olay hayat başına 9,92'den
3,83'e indi).

**Son aşama — uçtan uca test ve kayıt uyumu (uygulandı):**
`test/end_to_end_test.dart` sekiz senaryoyu kapsıyor: eğitim hattı
(doğum → ilkokul → ortaokul → lise → mezuniyet), aile hattı (tanışma →
evlilik → çocuk → taşınma → ölüm → arşiv), ekonomi hattı (alım → kiraya
verme → yıllık hesap → kaydet/yükle), sosyal medya sınırının platform
başına yenilenmesi, bekleyen olay/ehliyet sınavı/sağlık krizi sırasında
kapat-yükle (işlem bir kez uygulanıyor), **sürüm 1-17 göç zinciri**
(sentetik), kayıp/boşanma/yeni hayat sonrası bütünlük ve 300 hayatlık
toplu simülasyon. Ekran görüntüsü testleri bu ortamda çalıştırıldı ve
`test/goldens/` yenilendi.

Kayıt biçimi **sürüm 18**. **Kuşak devamı (E3) kodlandı** (Faho'nun "kuşak
sistemini kodla" talimatıyla): oyuncu vefat ettiğinde hayatta çocuğu varsa
hayat özetinde **"Çocuğum olarak devam et"** çıkar, tamamlanan hayat arşive
yazılır ve seçilen çocuğun kaydıyla devam edilir. Aile bağları bir kuşak
yukarı kayar (eş → anne/baba, diğer çocuklar → kardeş, büyükler →
büyükanne/dede, kardeşler → teyze/dayı/hala/amca), eski oyuncu **vefat
etmiş ebeveyn** olarak kayıtta kalır, miras D-037 oranlarıyla dağıtılır ve
ev/araç **aynı eşya kimliğiyle** geçer; ün, meslek, ehliyet ve eğitim
taşınmaz. Neyin taşınacağı, kaç kuşak süreceği ve çocuğun özellik devralıp
almayacağı **Q-067**'de karar bekliyor. Evlilik/çocuk ayrıntıları **Q-063**
ve **Q-064** altında Faho'nun kararını bekliyor; `DECISIONS.md`'ye yeni
kalıcı kural yazılmadı.

**Olay havuzu (Paket F1):** katalog **74 → 113 olay**. 80 yaş üstünde olay
oranı %63/%47/%34/%30 iken **%93/%84/%81/%83** oldu; hayatın son yılları
artık sessiz kalmıyor. Beş yeni sonuç zinciri eklendi (fidan → ağaç,
emanet para → güven/gölge, komşu gerginliği → yardım/soğukluk, sokak
hayvanı → dönüş, ergenlik defteri → eski defter). Ölçüm aracı düzeltildi
(artık seçenekler rastgele işaretleniyor, devam olayları da ölçülüyor).
Bu turda üç gerçek hata düzeltildi: kriz yolundan gelen ölümde ekrandaki
olayın temizlenmemesi, seçenek etiketlerindeki yer tutucuların ham
kalması ve eşya koşulunun tek ürün kimliğine bağlı olması. Ayrıntı:
`docs/BALANCE_REPORT.md` §9.

**Arayüz cilası (Paket F2):** hayat günlüğü yaşa göre kümelendi ("bu yıl"
etiketi, konu simgeleri, uzun hayatlarda tembel liste), tutarlar Türkçe
binlik ayırıcıyla yazılıyor (`163.400 ₺`), karakter değerleri seviyeye
göre renkleniyor ve çubuklar yumuşak geçiyor, olay penceresine kategori
simgesi ve yumuşak geçiş eklendi, açılış ekranına oyunu üç satırda anlatan
kart kondu. **Türkçe büyük harf hatası düzeltildi:** `toUpperCase()`
"Aile" → "AILE" yazıyordu, artık "AİLE". Görünüm tercihleri **Q-068**
altında karar bekliyor; ekran görüntüsü testleri yenilendi.

**Karanlık mod ve denge ayarı (Paket F3):** karanlık temada karakter
değerlerinin "iyi" ve "orta" renkleri birbirine karışıyordu; koyu zemin
için ayrı tonlar tanımlandı ve karanlık mod ekran görüntüsü testine
eklendi (`10_karanlik_mod.png`). En sık tekrarlayan yedi olayın tekrar
aralığı büyütüldü (en yüksek tekrar 3,00 → 2,53) ve tek ürün kimliğine
bağlı olduğu için hiç çıkmayan `gece_muzigi` olayı erişilebilir hâle
getirildi; artık **hiç çıkmayan olay kalmadı**. Ayrıntı:
`docs/BALANCE_REPORT.md` §9.5.

**Çocukların arka planda gelişmesi (Paket 1, D-045):** Oyuncunun çocuğu
artık kendi kalıcı kaydında yaşıyor: `PersonDevelopment` içinde özellikler,
okul/sınıf, üniversite ve bölüm, meslek, birikim, ilgi alanları ve
**gerçekleştiği yılda yazılan** dönüm noktaları tutuluyor. Çocuk 6 yaşında
okula başlıyor, sınıf atlıyor, liseyi bitiriyor, zekâsına bağlı bir
ihtimalle üniversiteye gidiyor (bölümü o yıl gerçekten seçiliyor), iş
buluyor ve maaşından kendi gideri düşülerek birikim yapıyor; **her çocuk
otomatik olarak başarılı veya zengin olmuyor**. Vefat etmiş çocukta hiçbir
gelişim işlemi yapılmıyor. Kuşak devamında bu kaydın tamamı korunuyor:
40 yaşında öğretmen olan çocuk artık "lise mezunu, işsiz" olmuyor; eski
oyuncunun mesleği, ehliyetleri ve sosyal medyası kopyalanmıyor. Miras da
çocuğun **gerçek birikiminden** dağıtılıyor. Kayıt biçimi **sürüm 19**;
eski kayıtlardaki çocuklara geçmiş uydurulmuyor, kayıt ilk yaş
ilerlemesinde boş geçmişle açılıyor. Sayılar **Q-069**'da karar bekliyor.

**Özellik aktarımı (Paket 2, D-046):** Biyolojik çocuğun başlangıç
değerleri (görünüş, sağlık, zekâ, karizma) iki ebeveynden **kısmen**
geliyor: ebeveyn ortalaması nötre doğru çekiliyor ve üstüne rastgele sapma
biniyor. Düşük zekâlı ebeveynlerin çocuğu genelde daha düşük başlıyor ama
yüksek doğma ihtimali duruyor; yüksek özellikli ebeveynlerin çocuğu da
mutlaka yüksek doğmuyor. Mutluluk aktarılmıyor. Değerler **doğumda bir
kez** çizilip kaydediliyor; kayıttan dönünce veya kuşak değişince yeniden
rastgele belirlenmiyor ve 0-100 sınırı aşılmıyor. Diğer ebeveynin özellik
bilgisi yoksa uydurulmuyor: karışıma girmiyor, kişiye bir kez kalıcı bir
özellik kaydı açılıyor ve o kayıt bir daha çizilmiyor. Hazır kaydı olan
kişinin (ör. evlat edinilecek çocuk) özellikleri **değiştirilmiyor**.
Sayılar **Q-070**'te karar bekliyor.

**İlişki ve aile kurma (Paket 3, D-047/D-048/D-049):** Evlilik artık
zorunlu değil — yetişkin oyuncu, yakın bir ilişkisi olan yetişkin
sevgilisiyle de çocuk sahibi olabiliyor; sevgili kendiliğinden eş
yapılmıyor ve iki biyolojik ebeveyn de kayıtta kalıyor. **Evlenme teklifi**
eklendi: yanıt her zaman "evet" değil, yakınlık ve ilişki geçmişi kabul
ihtimalini belirliyor, ret ilişkiyi bitirmiyor ama yakınlığa ve mutluluğa
işliyor; yanıt kayda giriyor, yeniden yükleyerek değiştirilemiyor ve aynı
kişiye hemen yeniden teklif edilemiyor. Aktiviteler menüsüne **Evlat
Edinme** geldi: maddi durum ve bakım koşulu değerlendiriliyor, yalnızca
zengin olmak otomatik kabul anlamına gelmiyor, evli olmak şart değil,
evlat edinilen çocuk gerçek ve kalıcı bir kişi kaydı oluyor (özellikleri
yeniden çizilmiyor) ve aynı başvuru iki kez çocuk veya ücret üretmiyor.
Kayıt biçimi **sürüm 20** (teklif/başvuru geçmişi). Sayılar **Q-071,
Q-072, Q-073**'te karar bekliyor.

**Ölüm, cenaze ve miras bildirimleri (Paket 4, D-050):** Oyuncuyu
doğrudan etkileyen kayıplar artık günlüğe sessizce satır eklemekle
kalmıyor: ekranda kısa ve saygılı bir bildirim çıkıyor, kişinin adı ve
gerçek bağı yazıyor. Miras bildirimi **yalnızca gerçekten bir şey
kaldığında** çıkıyor ve hangi kişiden ne kadar para/hangi eşya kaldığını
söylüyor. Eş, anne, baba, çocuk ve kardeş vefatında **cenaze masrafına
katkı** soruluyor: tutar önceden görünüyor, ödeme cüzdandan bir kez
düşüyor ve cüzdan eksiye düşmüyor (parası yetmeyene kısmi katkı seçeneği
çıkıyor, hiç parası yoksa yalnızca "katkıda bulunma" kalıyor). Katkı
zorunlu borç değil, mirasın ön koşulu değil ve cenazeye katılmayı
engellemiyor. Mutluluk etkisi **yalnızca gerçekten uygulandığı kadar**
gösteriliyor (mutluluk 0 ise sahte "-puan" yok). Bildirimler sırayla
geliyor, bekleyen olayı ezmiyor, iki kez açılmıyor ve kayıtla birlikte
saklanıyor. Kayıt biçimi **sürüm 21**. Tutarlar **Q-074**'te karar
bekliyor.

**Yaşlanma ve dış görünüş (Paket 5, D-051):** Dış görünüş artık yaşla
birlikte değişiyor: 30 yaşından önce hiç düşüş yok, sonrasında kademeli,
hafif ve kişiden kişiye değişen bir etki uygulanıyor. Sağlık etkiyi
değiştiriyor (sağlıklı karakter daha yavaş yıpranıyor), taban 15 —
yaşlanma karakteri sıfıra indirmiyor. Değişim gerçek değer kaydına
işleniyor, yılda bir kez uygulanıyor (kapat-aç aynı yılı tekrarlamıyor) ve
yalnızca belirgin yıpranma yıllarında günlüğe kısa bir satır giriyor.
Yaşlanma tek başına mutluluğu veya zekâyı düşürmüyor. 2000 hayatlık ölçüm
`docs/BALANCE_REPORT.md` §10'da; aralıklar **Q-075**'te karar bekliyor.

**Zorunlu kontroller (bu tur):** Kuşak geçişinde **üç çocuk türü de**
(biyolojik, evlilik dışı, evlat edinilmiş) doğru aile bağlarıyla
korunuyor — evlilik dışı doğan çocuğun diğer biyolojik ebeveyni artık
çocuğun kendi kaydında tutuluyor ve kuşak geçişinde anne/baba oluyor;
evlilik yoksa "evli" uydurulmuyor. Kayıt göç zinciri testi gerçek eski
kayıt gibi kuruldu (yeni alanlar gövdeden çıkarılıyor) ve bu sayede
**sürüm 19 ve öncesi kayıtların açılmadığı bir hata bulunup düzeltildi**.
Ölçüm: 300 hayatlık toplu simülasyon 18 saniyede tamamlanıyor; arka plan
gelişimi ağır döngü oluşturmuyor. Alt menü sırası değişmedi.

**Vasiyet — mirasçı çocuk seçimi (Paket 6, D-052):** Aktiviteler'e
**Vasiyet** sayfası eklendi. Oyuncu hayattaki çocuklarından birini
mirasçı seçebiliyor, seçimi değiştirebiliyor ve kaldırabiliyor; seçim
isteğe bağlı ve hiç yapılmayabilir. Mirasçı, çocuklara kalan nakdin
%60'ını alıyor ve eşya paylaşımında ilk sırada oluyor; diğer çocuklar
mirastan tamamen çıkmıyor, eşin payı korunuyor. Seçilen çocuk vefat
ederse seçim kendiliğinden düşüyor ve miras eşit bölünüyor. Vasiyet
"Çocuğum olarak devam et" seçimini zorunlu kılmıyor; devam listesinde
yalnızca **önerilen** olarak işaretleniyor. Çocuğu olmayan oyuncuda menü
hiç görünmüyor. Kayıt biçimi **sürüm 22**. Oran ve koşullar **Q-076**'da
karar bekliyor.

**Bilinen eksiklerin kapatılması (Paket 7):** Önceki paketlerde açık
bıraktığım noktalar kapatıldı. (1) **Cenazeye katılmak ile masrafa
katkıda bulunmak artık ayrı iki seçim**: bildirim önce katılımı, sonra
katkıyı soruyor; katkı vermeyen de cenazede olabiliyor, katılamayan da
katkıda bulunabiliyor ve metin ikisini ayrı cümleyle yazıyor. Cenazede
bulunmak hayattaki kan bağlarının yakınlığını küçük ölçüde artırıyor;
katılamamak küçük bir burukluk bırakıyor, kalıcı ceza değil. (2)
**Bildirim kapsamı genişledi**: çekirdek aile yakınlıktan bağımsız,
sevgili/arkadaş/eski eş/teyze-dayı-hala-amca ise yalnızca gerçekten
yakınsa bildiriliyor; uzak tanıdık için bildirim çıkmıyor. (3) **Kendi
hayatı izlenen kişi liseye geçtiği yıl alanını seçiyor** — alan
sonradan uydurulmuyor, üniversite bölümü tercihini etkiliyor ve kuşak
devamında oyuncunun eğitim kaydına taşınıyor. (4) **Yaşlanmanın dış
görünüşe etkisi bu kişilere de oyuncuyla aynı kuralla** işliyor;
çocuklukta otomatik düşüş yok, değerler 0-100 arasında kalıyor. (5)
**Evlat edinilen çocuk kaydında işaretli**: kişi kartında "Aileye
katılışı: Evlat edinildi" ve varsa "Diğer ebeveyni" görünüyor, uydurma
biyolojik ebeveyn yazılmıyor. Yeni sayılar **Q-069** ve **Q-074**'te
karar bekliyor; kayıt biçimi sürüm 22'de kaldı.

**Test durumu (bu tur, gerçekten çalıştırıldı):** `flutter analyze`
temiz; `flutter test` **788 geçti, 10 atlandı, 0 başarısız**. Atlanan 10
test, yalnızca `BIR_OMUR_SCREENSHOTS=1` ile çalışan ekran görüntüsü
testleridir. Kayıt göçü testleri **yapay (sentetik) kayıtlarla** yapıldı;
gerçek cihazdan alınmış eski kayıt dosyasıyla sınanmadı.

**Menü arayüzü yenilendi (Paket 8):** Faho'nun "menüler güncel ve
renkli olsun, butonlar güzel olsun" talimatıyla görünüm elden geçirildi.
Her menü satırı kendi rengini taşıyor (degradeli ikon kutusu, renkli
sayaç rozeti, yumuşak gölge); bölüm başlığının altında o bölümün
rengiyle kısa bir şerit var; geri dönüş satırı renkli bir hap oldu.
Kişi kartları bağ türüne göre renkleniyor, vefat edenler soluk kalıyor.
Alt gezinme çubuğu degrade zemin ve seçili sekme hapı kullanıyor,
**Yaş Al** degradeli ve halkalı. Düğmeler daha yuvarlak, yazıları daha
kalın ve basılınca düzleşen hafif bir yüksekliğe sahip. Kimlik renkleri
(nar, çini, pirinç, kâğıt) korundu ama canlandırıldı; menüler için sekiz
renkli bir aile eklendi ve her rengin koyu tema karşılığı var.
**Renk hiçbir yerde tek bilgi taşıyıcısı değil**: bağ türü, sayaç, hane
ve durum bilgisi yazıyla da veriliyor. **Alt menü sırası, metinler,
akışlar ve oyun kuralları değişmedi.** Renk değerleri `prototypeOnly`
ve **Q-077**'de karar bekliyor; tümü tek dosyada toplandığı için tek
commit ile geri alınabilir.

**Test durumu (Paket 8 sonrası, gerçekten çalıştırıldı):**
`flutter analyze` temiz; `flutter test` **793 geçti, 10 atlandı, 0
başarısız**. On ekran görüntüsü (`app/test/goldens/`) yeni görünümle
yeniden üretildi ve gözle kontrol edildi; bunlar test yazı tipi
kullandığı için ikonlar kutu olarak görünür, gerçek uygulamada ikonlar
çizilir. **Gerçek Windows veya Android cihazda oynanmadı.**

**Meslek hayatı derinleşti (Paket 9):** Her iş için kalıcı çalışma kaydı
tutuluyor: meslek, başlangıç yaşı, ayrılış yaşı ve nedeni, görev
seviyesi, maaş ve o işteki önemli anlar. İş değiştirince eski kayıt
silinmiyor; Meslek → **Kariyer geçmişi** sayfasından görülebiliyor. Altı
mesleğin hepsine üçer görev basamağı eklendi. **"Zam iste"** ve **"Terfi
iste"** gerçek birer etkileşim; kabul garanti değil, işte geçen süre,
zekâ/karizma ve iş hayatında verilen kararlar etkili. Aynı yıl ikinci kez
talep edilemiyor. İstifa mümkün; işten çıkarılma da mümkün ama nadir
(en az 2 yıl çalışmış olmak, iki kayıp arasında en az 8 yıl, yılda %3,5).
İş değişiminde çift maaş oluşmuyor. **İş arkadaşı** yeni bir bağ türü:
kalıcı kimliği var, işin şehrinde yaşıyor, aynı evde yaşıyormuş gibi
gösterilmiyor; işten ayrılınca kaydı silinmiyor, yakınlığı yeterliyse
arkadaşlığa dönüşüyor. İş hayatına 8 özgün olay eklendi; ikisi önceki
kararı hatırlıyor. Kayıt biçimi **sürüm 23**. Sayılar **Q-078**'de.

**Sosyal medya gelirle bağlandı (Paket 10):** Yeterli kitleye ulaşan
oyuncu içeriklerinden oyun parası kazanıyor. Gelir takipçi sayısına körü
körüne eşit değil; paylaşımın gerçek etkileşimine bağlı, her paylaşımda
garanti değil ve yeni açılmış hesap gelir üretmiyor. Para cüzdana
gerçekten işleniyor, günlükte nereden geldiği yazılıyor ve aynı
paylaşımın geliri iki kez ödenmiyor. **Sponsorluk** eklendi: altı
**kurgusal** iş kolu (gerçek marka, logo, reklam ağı ve gerçek para
sistemi yok). Kabul edilirse ücret **paylaşım yapılınca** ödeniyor;
iki yıl içinde paylaşım yapılmazsa anlaşma ödenmeden düşüyor. Ünün
küçük sosyal etkileri için dört olay eklendi; tanışmada kişi yalnızca
buluşma kabul edilirse üretiliyor ve hiçbiri romantik teklif değil.
Platform başına paylaşım sayacı bağımsız kalmaya devam ediyor. Kayıt
biçimi **sürüm 24**. Sayılar **Q-079**'da.

**Aktiviteler → Seyahat (Paket 11):** Kısa gezi sistemi eklendi; kalıcı
taşınmadan **ayrı**. Şehir, yolculuk türü (otobüs/tren/uçak) ve
istenirse bir yakın seçiliyor; ücret önceden görünüyor, cüzdan
yetmiyorsa düğme yerine gerekçe çıkıyor. "Kendi arabanla" seçeneği
yalnızca gerçekten arabası, otomobil ehliyeti ve yeterli araç
kondisyonu olan oyuncuya açılıyor. Eş, sevgili, çocuk, arkadaş, anne
veya babayla gidilebiliyor; vefat etmiş kişi, bebek çocuk ve başka
şehirdeki tanıdık listede görünmüyor. Her gezi günlüğe şehir, yaş,
kiminle gidildiği, gerçek harcama ve kısa bir anıyla yazılıyor; dört
özgün gezi olayı yıllar sonra aynı kişiyle yapılan geziyi
hatırlatabiliyor. Gezi yaşanan veya doğulan şehri **değiştirmiyor**.
Kayıt biçimi **sürüm 25**. Sayılar **Q-080**'de.

**Test durumu (Paket 9-11 sonrası, gerçekten çalıştırıldı):**
`flutter analyze` temiz; `flutter test` **884 geçti, 10 atlandı, 0
başarısız**. Atlanan 10 test yalnızca `BIR_OMUR_SCREENSHOTS=1` ile
çalışan ekran görüntüsü testleridir. Uçtan uca zincir (eğitim → iş →
maaş → zam → iş değişimi → sosyal medya → gelir → sponsorluk → gezi →
yaş alma → kapat/aç) tek testte sınanıyor. Kayıt göçü **yalnızca
sentetik kayıtlarla** sınandı; gerçek cihazdan alınmış eski kayıt
dosyası kullanılmadı. **Gerçek Windows veya Android cihazda
oynanmadı.**

**Görsel kimlik yenilendi (Paket 16):** Faho arayüzü "çok yapay zekâ
duruyor" diye tanımladı ve canlı renk istedi. Palet doygunlaştırıldı
(nar, çini, pirinç ve sekiz menü rengi). Gövde sakinleşti: açık temada
soğuk gri zemin + **beyaz** kart, koyu temada mürekkep moru zemin.
**Kart zeminleri artık vurgu rengiyle boyanmıyor**; renk ikon
kutusunda, rozetlerde ve bölüm başlık kartında duruyor. Üst karakter
şeridi, alt gezinme çubuğu ve açılış ekranı koyu degrade taşıyor. Her
bölüm renkli bir başlık kartıyla açılıyor. Menü satırı, kişi kartı ve
bilgi panelleri tek kart diline taşındı; düğmelerin gri gölge halkası
kaldırıldı. Alt menü sırası ve **Yaş Al**'ın yeri değişmedi (NAV-001).
Renk değerleri **prototypeOnly**; sorular **Q-084**'te. Yan düzeltme:
ses servisi oynatıcıyı artık ilk ses çalınana kadar kurmuyor.
Ekran görüntüsü testleri gerçek Roboto ve Material Icons dosyalarını
yüklüyor; goldenlar artık tasarımı gerçekten temsil ediyor.

**Okul dönüm noktaları ve sınav yılı (Paket 17):** Okula başlama,
liseye geçiş, lise bitişi ve üniversite mezuniyeti artık ekranda
**bildiriliyor** (yeni `NoticeKind.okul`). Bildirim bilgilendirmedir:
seçim sormaz, hiçbir değeri değiştirmez, kayıtta saklanır ve iki kez
açılmaz; puan yalnızca gerçekten hesaplanmışsa yazılır. 8. ve 12. sınıf
artık **sınav yılı**: okul ekranında ayrı bir panel var ve sekiz yeni
olay (sınav takvimi, deneme sonucu, gece kaygısı, son hafta/son ay,
aile baskısı) çıkıyor. İkisi önceki kararı hatırlıyor. Seçimler
yerleştirme ve üniversite sınav puanını **gerçekten** değiştiriyor;
çok çalışmak mutluluk ve sağlık düşürüyor, kaygı kalıcı ceza değil.
İki sınav ayrı tutuluyor. Sayılar **prototypeOnly**; sorular **Q-085**.

**Aktivitelere üç yeni alan (Paket 18):** **Sağlık Merkezi** (kontrol,
diş, göz, mevsim aşısı, bir uzmanla konuşmak), **Eğlence** (parkta
yürüyüş — ücretsiz, sinema, kafe, maç, konser) ve **Kurslar** (resim,
müzik, dil, bilgisayar). Dil ve bilgisayar kursu zekâyı yükseltiyor.
Üçü de mevcut aktivite altyapısını kullanıyor: parası yetmeyen işlem
gerçekleşmiyor, aynı yaşta tekrarın getirisi azalıyor ve sınıra gelince
eylem kapanıyor, her alan yalnızca yaşına uyduğu andan itibaren menüde
görünüyor. Yeni ana menü açılmadı. Ücretler **prototypeOnly**; sorular
**Q-086**.

**Test durumu (Paket 16-18 sonrası, gerçekten çalıştırıldı):**
`flutter analyze` temiz; `flutter test` **1012 geçti, 11 atlandı, 0
başarısız**. Atlanan 11 test yalnızca `BIR_OMUR_SCREENSHOTS=1` ile
çalışan ekran görüntüsü testleridir. Kayıt biçimi **sürüm 27**
değişmedi. **Gerçek Windows veya Android cihazda oynanmadı**; sesler
de duyulmadı.

**Görsel yön üçüncü kez kuruldu — çizgi roman (Paket 19):** İlk iki deneme
de Faho tarafından "yapay zekâ işi gibi" bulundu; ikisinin de ortak yanı
herhangi bir uygulamaya yapıştırılabilecek **genel** bir arayüz diliydi.
Bu sürüm o dili bilerek kırıyor: **degrade yok**, her yüzeyde kalın
mürekkep konturu, **bulanık değil kaydırılmış** gölge, basınca gerçekten
çöken düğmeler, çizim kâğıdı dokulu zemin. Oyunun artık **kendi yazı
tipi** var: arayüzde **Baloo 2**, el yazısı aksanlarda **Patrick Hand**
(ikisi de SIL OFL, tam Türkçe, oyunun kullandığı karakterlere
indirgenmiş — `app/tool/fetch_fonts.py`). **Karakterin bir yüzü var:**
hazır görsel değil, yaş, saç stili, mutluluk, sağlık ve cinsiyetten
**koddan çizilen** bir karikatür. Alt menü sırası ve **Yaş Al**'ın yeri
değişmedi (NAV-001). Yön ve ayrıntılar **prototypeOnly**; sorular
**Q-087**'de. `docs/PROTOTYPE_UI.md` §2'deki "modern + ölçülü nostaljik"
ifadesiyle çelişiyor; onay gelmeden o belgeye dokunulmadı.

Yan düzeltme (gerçek hata): olay penceresinde uzun metinlerde **"Devam"
düğmesi ekranın altına kaçıp dokunulamaz oluyordu**; eylem düğmeleri
artık kaydırma alanının dışında.

**Test durumu (Paket 19 sonrası, gerçekten çalıştırıldı):**
`flutter analyze` temiz; `flutter test` **1026 geçti, 12 atlandı, 0
başarısız**. Atlanan 12 test yalnızca `BIR_OMUR_SCREENSHOTS=1` ile
çalışan ekran görüntüsü testleridir. **Gerçek Windows veya Android
cihazda oynanmadı.**


## Paket 20-24 — beş maddelik genel geliştirme (21 Eylül 2026)

Faho'nun onayıyla ("bugün ChatGPT yok, hepsini yap") beş madde uygulandı.
Hepsi **ayrı PR** olarak üst üste yığılı; hiçbiri main'e birleştirilmedi.
Bütün sayılar `prototypeOnly`, sorular `docs/DESIGN_REVIEW_QUEUE.md`
içinde Q-088…Q-092.

**1. Olay tekrarı (Paket 20, PR #52).** Aynı olay bir hayatta üç kez
çıkabiliyordu; 12 hayatta en sık olay 39 kez görüldü. Tekrar sönümü
eklendi ve 28-58 yaş için 25 yeni olay yazıldı. 30-49 yaşta yılda uygun
olay **1-2'den 21-22'ye** çıktı, en çok tekrar **39'dan 18'e** indi.

**2. Yıla kilitli içerik (Paket 21, PR #53).** Yılda tek olay çıktığı
için sınav yılı olayları havuzda kayboluyordu. Olaylara `priority` alanı
eklendi (sıra kapma değil ağırlık artırımı). 8. sınıfta sınav olayı
görme **%38'den %100'e**, 12. sınıfta **%28'den %100'e** çıktı. Öncelik
yalnızca penceresi 3 yıl veya daha dar olaylara verilebilir; bu kural
kalıcı bir testle korunuyor.

**3. Hayat sonu değerlendirmesi (Paket 22, PR #54).** Özet ekranı yalnızca
liste veriyordu. Artık hayatın bir adı ("Emekle geçen bir hayat"), dört
ekseni (Bağlar, Emek, Deneyim, Huzur), "İlkler" ve "Hiç olmadı" listesi
var. Ad arşive de yazılıyor. Kayıt biçim sürümü **artmadı** (alan
eklemeli). Yan düzeltme: `zatürre` krizinin iki seçeneği de para
istiyordu; 60 yaşından sonra parası olmayan oyuncu **kilitleniyordu**.

**4. Romantik ilişkinin erişilebilirliği (Paket 23, PR #55).** 176 olayın
yalnızca **biri** ilişki başlatabiliyordu ve **26 yaşından sonra evlilik
imkânsızdı**; bir kez ayrılmak da ömür boyu kapatıyordu. Altı yetişkinlik
kapısı eklendi, kalıcı yasaklar kaldırıldı. Hayatında hiç sevgilisi olan
oyuncu oranı (rastgele seçen oyuncuda) **2/60'tan 44/60'a** çıktı. Bekâr
hayat için de beş olay yazıldı. **Not:** bu maddeyi önce "içerik romantizm
zincirine kilitli" diye teşhis etmiştim; ölçüm bunu doğrulamadı, asıl
sorun erişilebilirlikti.

**5. İlgisizlikten zayıflayan bağlar (Paket 24, PR #56).** Yakınlık
yalnızca yükseliyordu; İlişkiler ekranını ziyaret etmenin karşılığı
yoktu. Artık 3 yıllık hoşgörüden sonra bağ yılda 3 (kan bağında 2) puan
düşer. Kan bağında **taban 20** vardır: anne annedir. Aynı evde yaşayan
ve erişilemeyen kişi zayıflamaz. Oyuncu bunu kişi sayfasındaki uyarıdan
görür.

**Test durumu (Paket 24 sonrası, gerçekten çalıştırıldı):**
`flutter analyze` temiz; `flutter test` **1082 geçti, 13 atlandı, 0
başarısız**. Atlanan 13 test yalnızca `BIR_OMUR_SCREENSHOTS=1` ile
çalışan ekran görüntüsü testleridir. **Gerçek Windows veya Android
cihazda oynanmadı.**

## Paket 25-34 ve main'e birleştirme (22 Eylül 2026)

**Faho'nun isteğiyle bütün yığın `main`'e birleştirildi** (`27b83eb..e24a56b`,
ileri sarma, 141 commit). #27-#66 arası 40 PR'ın içeriği artık `main`'de;
PR'lar kapatıldı. Birleştirme öncesi `main` üzerinde doğrulandı:
`flutter analyze` temiz, **1292 test geçti, 15 atlandı, 0 başarısız**
(atlananlar yalnızca `BIR_OMUR_SCREENSHOTS=1` ile çalışan golden testler).

**Paket 25 — Teklif ve düğün (PR #57).** Evlenmenin 60.000 ₺ koşulu kalktı.
Teklif dört biçimde yapılabiliyor (sade bedelsiz), kabul sonrası düğün
cüzdana göre seçiliyor (nikâh bedelsiz). "Çocuk yap" düğmesi kaldırıldı;
yerine yakınlaşma ve korunma seçimi geldi. Çocuk artık garanti değil;
kısırlık gizli ve ancak denedikçe anlaşılıyor.

**Paket 26 — Hamilelik (PR #58).** Bebek aynı anda gelmiyor; bir sonraki
yaş ilerlemesinde doğuyor ve bildirim paneline düşüyor. Kayıt biçimi 30.

**Paket 27 — Burçlar ve fal (PR #59).** Doğum ay/gününden burç, kahve falı,
tarot ve burçsal dönemler. **Doğum yılı hâlâ yok** (D-003). Yazı tipleri
burç simgelerini içermediği için simgeler gösterilmiyor, veri olarak duruyor.

**Paket 28 — Sesler ve menü (PR #60).** Yedi ses yeniden üretildi
(`app/tool/make_sounds.py`); aktiviteler menüsü dört gruba ayrıldı.
Genel kontrolde 360 px'te gerçek bir taşma bulundu ve kalıcı taşma testi
eklendi (`test/layout_overflow_test.dart`).

**Paket 29 — Askerlik (PR #61).** Meslek altında ayrı menü: celp, er/astsubay/
subay yolları, bedelli ve bedelli ücretini aileden isteme (reddedilebilir).

**Paket 30 — Rulet ve at yarışı (PR #62).** Gerçek Avrupa ruleti sıra
dizilimiyle dönen çark; beş atlı yarış. Animasyon sonucu belirlemiyor.

**Paket 31 — Askerlik tecili ve bakaya (PR #63).** 2 hak × 2 yıl tecil;
okul tecili **bildirim panelinde** duyuruluyor ve hak harcamıyor. Kaçmak
mümkün: yakalanma ihtimali yılda artıyor, ceza süreyle büyüyor, teslim
olan yarısını ödüyor.

**Paket 32 — Dövüş sanatları (PR #64).** Spor salonu içinde karate
(kyu/dan), kung fu (kuşak + duanwei) ve yağlı güreş (Kırkpınar boyları).
Basamak adları gerçek düzenlerden derlendi. Ders ucuz ama yılda en fazla
20 ders alınabiliyor: ustalık parayla değil yılla geliyor. Eşiğe gelince
eğitmenlik mesleği açılıyor.

**Paket 33 — Milli Piyango (PR #65).** Tam/yarım/çeyrek bilet, olağan ve
yılbaşı çekilişi, amortiye kadar ikramiye basamakları. Çekiliş yaş
ilerlerken yapılıyor. Kasa payı **%44** (kuramsal geri dönüş %56) —
Faho'nun "genel kumar kuralı neyse öyle olsun" kararının uygulaması.
Kumar ayarı kapalıyken bayi de kapalı.

**Paket 34 — Finger (PR #66).** Tanışma uygulaması: profil, beğen/geç,
eşleşme. Beğeninin karşılık bulma ihtimali %22-67 arası, görünüş ve
karizmaya bağlı ve ekranda yazılı. **Eşleşmek tanışmak değil**;
tanışıldığında kişi kalıcı kimlikle hayata giriyor. Sevgilisi olan biri
eşleşmeyle yeni sevgili edinemiyor (arkadaş oluyor) — bu **varsayılan**,
onaylanmış kural değil.

**Karar bekleyenler:** `docs/DESIGN_REVIEW_QUEUE.md` → Q-093 … Q-102.
Öne çıkanlar: tecil hakkı sayısı (Q-099/1), eğitmenlik eşiği (Q-100/1),
büyük ikramiyenin ekonomiyi bozup bozmayacağı (Q-101/2), sevgilisi varken
eşleşmenin ne anlama geleceği (Q-102/3).

**Test durumu (gerçekten çalıştırıldı):** `flutter analyze` temiz;
`flutter test` **1292 geçti, 15 atlandı, 0 başarısız**. CI `main` üzerinde
Android debug APK ve Windows sürümünü derledi. **Gerçek Windows veya
Android cihazda oynanmadı.**

**Paket 39-42 — Issue #67 (PR #70, #71, #72, #73).** Yığılmış dört PR;
hiçbiri `main`'e birleştirilmedi, Faho'nun onayı bekleniyor.

- **Paket 39 — Kalıcı hobiler (PR #70).** Mevcut Kurslar, Kütüphane ve
  Spor salonu eylemleri artık kalıcı iz bırakıyor: hobi türü, başlama
  yaşı, deneyim, son uğraşılan yaş ve basamak anıları kayda giriyor.
  7 özgün hobi olayı; ikisi geçmişi doğrudan hatırlıyor. Hayat sonu
  değerlendirmesi ciddi hobiyi görüyor. **İkinci bir aktivite sistemi
  kurulmadı, yeni meslek ağacı açılmadı.**
- **Paket 40 — Evcil hayvanlar (PR #71).** Mevcut `GameState.pets` kaydı
  gerçek bir kimlik kazandı: yaş, sahiplenme yaşı, hane, bağ ve vefat
  kaydı. v1'de kedi ve köpek sahiplenilebiliyor. Dört etkileşim, yılda
  bir kez alınan bakım gideri, parasızlıkta ölmeyen hayvan, doğal vefat
  ve silinmeyen kayıt, kuşak değişiminde aynı kimlikle devam. 6 özgün
  olay.
- **Paket 41 — Birlikte eğlence (PR #72).** Eğlence eylemleri artık eş,
  sevgili, çocuk, anne, baba, kardeş ve yakın arkadaşla yapılabiliyor.
  Kimse uydurulmuyor: kişi yaşıyor, kayıtta duruyor, erişilebilir ve yaşı
  uyuyor. Ücret bir kez alınıyor, ortak geçmişe tek satır düşüyor.
  30'un üzerinde özgün sahne.
- **Paket 42 — Bütünleşik test (PR #73).** Bir hayatı baştan sona oynayan
  senaryo testi ve 65 hayatlık kilitlenme taramasının yeni sistemleri de
  kapsayacak biçimde genişletilmesi.

Yol boyunca bulunan **gerçek hatalar**: bildirim panelinin başlık satırı
uzun başlıkta taşıyordu (360 px'de 4,4 px); aktivite kartında gerekçe
metni ile düğme dar ekranda sıkışıyordu. İkisi de düzeltildi.

**Karar bekleyenler:** `docs/DESIGN_REVIEW_QUEUE.md` → Q-106, Q-107,
Q-108. Öne çıkanlar: hobi eşiklerinin gerçek oyun hızına göre çok uzun
olup olmadığı (Q-106/2), hayvanın hayat sonu değerlendirmesinde anılıp
anılmayacağı (Q-107/7), birlikte gidilince biletin tek mi çift mi
sayılacağı (Q-108/1).

**Test durumu (gerçekten çalıştırıldı):** `flutter analyze` temiz;
`flutter test` **1450 geçti, 15 atlandı, 0 başarısız**. Atlananların
tamamı `BIR_OMUR_SCREENSHOTS=1` ile açılan golden testleri.
**Android ve Windows CI çalıştırılamadı:** GitHub Actions işleri
faturalandırma/harcama limiti nedeniyle hiç başlamıyor (aşağıya bakın).
**Gerçek Windows veya Android cihazda oynanmadı.**

### CI durumu — faturalandırma engeli
Android APK iş akışı üç denemede de (push, yeniden çalıştırma,
`workflow_dispatch`) **tek bir adım bile çalışmadan** 3-4 saniyede
düştü. Kayıtlar (log) 404 dönüyordu; sebep `check-run` açıklama
kaydından okundu:

> The job was not started because recent account payments have failed or
> your spending limit needs to be increased. Please check the
> 'Billing & plans' section in your settings

Bu **kod ya da iş akışı yapılandırması hatası değil**. Aynı işlemde
Windows iş akışı (aynı `flutter analyze` + `flutter test` adımlarını
çalıştırıyor) başarıyla tamamlanmıştı ve o işlemde yalnızca bir test
dosyası eklenmişti. Faho'nun GitHub hesabında **Billing & plans**
bölümünden ödeme/harcama limiti düzeltilene kadar hiçbir CI çalışması
başlamayacak; dolayısıyla bu turda Windows sürümü ve Android APK
üretilemedi.

## Paket 43-48 — kalite ve içerik derinliği turu (23 Eylül 2026)

Yeni büyük oyun sistemi eklenmedi. Mevcut sistemler denetlendi, gerçek
hatalar düzeltildi, testler güçlendirildi ve ölçüm yapıldı. Hepsi yığılmış
PR olarak `main`'in **dışında** duruyor.

**Paket 43 — Türkçe metin ve bağlam tutarlılığı (PR #74).** Ortak geçmiş,
vefat eden kişinin ölüm yılını **uyduruyordu** (her zaman "şu anki yaş");
evlat edinilen çocuğun aileye katılışını **doğduğu yıla** yazıyordu ve
olayı iki kez gösteriyordu; eşini kaybedip yeniden evlenen oyuncuda
kayıtta **iki kişi birden "Eş"** kalıyordu. Üçü de düzeltildi. Sonuç
metinlerinde `{hayvan}`/`{sehir}` yer tutucuları doldurulmuyordu; o da
kapatıldı. 21 yeni regression testi.

**Paket 44 — Kayıt dayanıklılığı (PR #75).** Sonradan eklenen alanların
bir bölümü denetimsiz tür dönüşümüyle okunuyordu; bozuk bir kayıt ham
Dart hatasıyla düşüyordu. Hepsi denetimli okumaya geçirildi. 17 senaryo
kaydedilip yükleniyor, 50 rastgele hayatta `encode → decode → encode`
karşılaştırılıyor, 61 alanın her biri tek tek siliniyor ve bozuluyor.
**Gerçek bir eski cihaz kaydı yok; göç sınamaları sentetiktir.**

**Paket 45 — Dar ekran ve büyük yazı (PR #76).** 320/360/390 px × yazı
ölçeği 1,0/1,3/1,5. Üç gerçek taşma bulundu ve düzeltildi (karakter
başlığındaki cüzdan rozeti, hayat günlüğü yaş başlığı, piyango ikramiye
tablosu). 27 yeni test.

**Paket 46 — Hayat tutarlılığı taraması (PR #77).** 100 hayat doğumdan
ölüme oynanıp her yaşta kişi/evlilik/çocuk/para/eşya/gezi/hayvan/hobi/
günlük değişmezleri denetlendi. **17.885 denetim noktasında hiçbir
çelişki bulunmadı**; bu pakette davranış değiştiren tek satır yok.

**Paket 47 — İçerik kalitesi ölçümü (PR #78).** Ölçüm aracı gerçek oyun
akışıyla (etkileşimler, hobi, hayvan, gezi, emeklilik) çalışacak biçimde
yeniden yazıldı. Sonuçlar ve denge önerileri `docs/EVENT_CONTENT_REPORT.md`
ve `docs/DESIGN_REVIEW_QUEUE.md` (Q-110) içinde.

**Paket 48 — Belge gerçeklik denetimi (PR #79).** Kodla çelişen eski
ifadeler düzeltildi; sonraki büyük sistem önerileri
`docs/NEXT_DEVELOPMENT_OPTIONS.md` dosyasında **yalnızca öneri** olarak
toplandı.

**Paket 49 — Faho'nun oyun içi geri bildirimleri.** PC'de oynanan
sürümden çıkan altı madde işlendi:

1. **Askerlik hatası düzeltildi.** Kadın oyuncu 18 yaşından sonra
   "Askerlik · Yapılmadı" satırını görüyordu; zorunlu askerliği yokken
   yerine getirilmemiş bir yükümlülük varmış gibi okunuyordu. Kayıt
   değişmedi (değişseydi gönüllü subaylık yolu da kapanırdı), görüntü
   düzeltildi.
2. **Kalıcı pasif seçenek denetimi.** Açık düğmelerin hepsi gerekçesini
   zaten yazıyordu; asıl risk ekranda durup hiç açılamayan içerikti.
   `test/content_reachability_test.dart` bunu kalıcı hâle getirdi.
3. **Dövüş sanatı eğitimi.** Karate siyah kuşağı 110 ders ve yılda en
   fazla 20 ders demek: 110 ayrı tıklama. "Yılı çalış" eylemi eklendi;
   ücret, yıllık sınır ve basamak eşikleri **birebir aynı**. Süre kararı
   Q-111'de.
4. **Sosyal medya.** Bir platformdaki kazanç artık diğer açık hesaplara
   yansıyor ve kitlesi büyük hesap yıl geçtikçe kendiliğinden büyüyor.
   Durgun hesabın erimesi **Claude'un eklediği varsayımdır**, Q-112'de
   onaya sunuldu.
5. **Meslek kataloğu 9'dan 15'e.** Aşçı, kuaför, muhasebeci, manken,
   yazar, müzisyen. Mankenlik görünüşle, yazarlık okuma hobisiyle,
   müzisyenlik müzik hobisiyle açılıyor. Sayılar Q-113'te.
6. **Olay zincirleri.** Yıllara yayılan 4 zincir, 17 olay, 8 dal.
   Sayılar Q-114'te.

Bu pakette **hiçbir sayısal denge değeri kendi başına değiştirilmedi**;
hepsi `prototypeOnly` kaldı ve kararlar Q-111…Q-114 olarak kuyrukta.

**Paket 50 — Q-103…Q-114 kararları, 2026 ekonomisi ve şehir filtresi.**
Faho on iki tasarım sorusunun tamamını karara bağladı; kararlar
`DECISIONS.md` içine **D-054…D-065** olarak, ekonomi kararı **D-053**,
şehir filtresi **D-066** olarak işlendi. Kuyruktaki Q-103…Q-114
"KARARLAŞTIRILDI" durumuna geçti.

- **2026 Türkiye ekonomisi.** Bütün tutarlar 2026 TL satın alma gücü;
  nominal enflasyon simüle edilmiyor. Çıpa: net yıllık asgari ücret
  336.900 ₺. Maaşlar yedi gelir bandına ayrıldı ve her bant test
  edilerek korunuyor. Gerekçeli eski/yeni tablosu:
  `docs/ECONOMY_2026.md`.
- **Meslek kataloğu 9 → 44.** Hizmet, teknik, ofis, sağlık,
  mühendislik, kamu ve yaratıcı sektörler temsil ediliyor. Sağlık ve
  iletişim meslekleri için üniversite kataloğuna beş bölüm eklendi;
  ulaşılamayan iş üretilmedi.
- **Ev/araç ilanları yaşanan ille sınırlandı.** "Türkiye geneli"
  liste kalktı, şehir bazlı fiyat katsayısı eklendi.
- **Kütüphane 8 → 23 kitap**, okuma eşikleri 0/3/7/12/20; hobi
  basamak adları ve süreleri karara uyduruldu.

**Paket G — bildirilen gerçek hatalar (D-087…D-093).** Kuşak devamında
torunlar kayboluyordu; `RelationType.yegen` eklenerek düzeltildi. Finger
ekranındaki donmanın gerçek sebebi bulundu (menü bileşeni uzun metni
sınırsız genişlikte yerleştiriyordu) ve dar ekran testi eklendi. At
yarışı bahsi emanete alınıp sonuç atomik kesinleşiyor; blackjack'te el
sonunda tekrar oynanabiliyor. Aynı işe aynı yıl ikinci başvuru kapandı.
Finans olayları gerçek mali duruma bakıyor. İlgisizlik artık hızlanarak
yakınlık düşürüyor ve uzaklaşan yakın için sitem olayı eklendi.

**Paket H — lise alan seçimi ve doğumda isim (D-094, D-095).** Liseye
geçen oyuncu alan seçmeden yaş atlayamıyor: **Yaş Al** düğmesi sessiz
kalmıyor, seçim penceresi açılıyor ve seçim yapılmadan kapanmıyor.
Seçilen alan günlüğe yazılıyor, sonuç aynı pencerede gösteriliyor ve
üniversite koşullarında gerçek kaynak oluyor. Bebek doğduğunda adı
doğum bildiriminin içinden değiştirilebiliyor; ad yalnızca doğum
yılında, 2-16 harf ve yalnızca harf olarak kabul ediliyor, soyadı
değişmiyor.

**Paket I — geri bildirim ve sonuç görünürlüğü (D-096…D-098).** Yaş
alındığında biten yılın özeti ana ekranın üstünde kart olarak duruyor:
"23 yaşın böyle geçti". Satırlar yılın başındaki fotoğrafla bugünün
farkından üretiliyor, uydurma kazanç yazamıyor. Kritik iş ve kredi
haberleri (işten çıkarılma, işveren uyarısı, kaçan taksit) artık
bildirim oluyor. Bildirim yoğunluğu 100 hayat üzerinde ölçüldü: en kötü
yıl yedi pencereydi, aynı yıl gelen miras payları tek bildirimde
toplanarak ve acılı yılda burç penceresi kapatılarak altıya indi
(ortalama 0,39/yıl). Olay havuzundaki 467 seçimin tamamı denetlendi:
etkisiz seçim yok, yalnızca görünmez işaret bırakan seçim yok; kural
testle sabitlendi.

**Paket J — statlar gerçekten hissedilsin (D-099…D-102).** Kazançlar
artık azalan getiriyle işleniyor: +5'lik bir kazanç 40'tan +5, 70'ten +4,
88'den +1 getiriyor. Çabayla ulaşılabilecek tavan 95; yılda +4 kazandıran
bir alışkanlık 40 yıl sürse bile 100'e ulaşmıyor (eskiden ulaşıyordu).
Kural tek noktadan geçiyor ve bunu atlayan yeni bir yol açılamasın diye
kaynak taramalı bir testle sabitlendi. Sağlık Merkezi'nin yıllık toplam
sağlık kazancı 17'den 6'ya indirildi (check-up ile stat kasma açığı).
Hastalık artık sağlığı da düşürüyor. Dövüş sanatı spor bakımına sayılıyor.
Görünüş düşüşü yaklaşık dörtte bir yumuşatıldı. Saç dökülmesi karizmayı
değil görünüşü etkiliyor; saç ekimi ileri basamaktan iki kademe düşürüyor.

**Paket K — sosyal medya, sponsorluk ve Ün (D-103…D-106).** Aktiviteler
altında **Ün ve Medya Fırsatları** bölümü açıldı; Ün 40 olmadan menüde
hiç görünmüyor. Yedi kurgusal medya işi var (dergi röportajından reklam
yüzü olmaya). Sponsorluk için platform başına en az 5.000 takipçi
gerekiyor ve ücret kitlenin tamamıyla ölçekleniyor: 5.000 → 32.500 ₺,
500.000 → 478.000 ₺. Kabul edilip paylaşılmayan sponsorlukta ödeme yok,
mutluluk düşüyor ve o platformdaki kitlenin %4'ü gidiyor. Tanınan biri
yeni hesabı sıfırdan açmıyor: mevcut kitlesinin %8'i (en çok 40.000)
taşınıyor. Ünlüye yılda iki kez yazılabiliyor ve geri takip edenler
İlişkiler ekranında "Ünlüler ve tanıdıklar" başlığında duruyor. Takipçi
sayıları Türkçe binlik ayracıyla yazılıyor (2.232).

**Paket L — Finger: niyet, flört ve süzgeç (D-107).** Tanışmak artık
sevgili olmak değil: araya **flört** basamağı girdi. Hem oyuncunun hem
adayın "ne aradığı" profilde yazıyor ve buluşmanın sonucu ikisine birden
bakıyor. Flört kendiliğinden sevgiliye dönmüyor; oyuncu teklif ediyor ve
yakınlık yeterliyse resmîleşiyor. Adaylar ekonomik duruma göre
süzülebiliyor. Beğeni kotası yılda 5'ten 12'ye çıktı, premium 30 kaldı.

**Paket M — banka, konut kredisi ve harçlık (D-108).** Banka
Varlıklar'dan Aktiviteler'e taşındı; Varlıklar'da yalnızca açık borç
hatırlatması kaldı. Kredi tutarı artık elle yazılıyor. Konut kredisi
eklendi: daha ucuz (aylık %2,45 / %3,40), 10 yıla kadar vadeli ve daha
büyük. Basit kredi karnesi (İyi/Orta/Riskli/Çok riskli) banka ekranının
üstünde gerekçesiyle duruyor; icra ve haciz için zemin bırakıldı.
Harçlık isteyince alınan tutar sonucun içinde yazıyor.

**Paket N — hayvanlar ve aile tepkisi (D-109, D-110).** Evcil hayvan
sahiplendirilebiliyor: vefat değil, kaydı duruyor ve "Yeni yuvasına
gidenler" başlığında görünüyor. Hayvan ekranı üçe ayrıldı. Kayıp hayvan
sonsuza kadar kayıp kalmıyor; üç yılın sonunda durum kapanıyor ve hayvan
ölmüş sayılmıyor. Özel izin gerektiren tür (timsah) gerçekten zorlaştı:
25 yaş, kendi evi ve bedelin yarısı kadar izin masrafı. 18-20 yaşında
çocuk sahibi olan oyuncuya ailenin tepkisi eklendi; evliyse destek,
değilse endişe — ikisi de gerçekten uygulanıyor.

**Bu pakette kodlanmayan, açıkça bekleyen işler:** tüp bebekte ikiz
gebelik, üvey ebeveyn ilişkisi ve Evlilik Geçmişi ekranı (D-055),
"Vefat eden eş" ayrı statüsü ve kayıt göçü (D-060), hayvan sağlık
değeri ve Hayvan Detayı ekranı (D-058), "Hobilerim" bölümü (D-057),
bitirilmiş kitabın yeniden okunması, 0-5 ve 80+ yaş havuzlarının
genişletilmesi, olay örtüşmesinin %40-45 bandına indirilmesi ve
kariyer olaylarının payı (D-061), zincir sonundaki gerçek kariyer
teklifi ve kişisiz kapanış olayları (D-065), çoklu kişiyle aktivite
(D-059).

**Test durumu (gerçekten çalıştırıldı):** `flutter analyze` temiz;
`flutter test` **1660 geçti, 15 atlandı, 0 başarısız**. Atlananların
tamamı `BIR_OMUR_SCREENSHOTS=1` ile açılan golden testleridir.
**Gerçek Windows veya Android cihazda oynanmadı.**

**CI:** Depo public yapıldıktan sonra GitHub Actions normal çalışıyor.
Windows test sürümü `claude/paket54-belge-denetimi` dalının
`6f3a852` commitinden üretildi ve artifact olarak yüklendi. Android APK
bu ortamda hâlâ üretilemiyor (Android SDK indirilemiyor).
**Hiçbir sürüm gerçek Windows ya da Android cihazda oynanmadı.**

## Paket A-F: Faho'nun 24 Eylül listesi (D-067 … D-085)

Faho'nun uzun revizyon listesi altı pakette kodlandı. Her paket ayrı
commit; hepsi `claude/stoic-maxwell-6rkrit` dalında.

**Paket A — bildirilen beş hata (D-067…D-071).** Ev sahibi olan
oyuncuya kira zammı olayı çıkması, çalışmayana iş yeri olayı çıkması,
gebeliğin 46 yaşta tamamen kapanması, yıllarca ilgilenilmeyen eşle
yakınlığın tam kalması, bedelli sonrası subay/astsubay yolunun da
kapanması.

**Paket B — statlar yaşla düşer, bakım karşılık verir (D-072, D-073).**
Beş değerin her birinin kendi başlangıç yaşı ve tabanı var. Spor,
berber ve okumak kaybı belirgin biçimde yavaşlatıyor. Erkeklerde saç
dökülmesi eklendi; oran androjenetik alopesinin yaygın epidemiyolojik
özetine göre seçildi ve test bunu ölçüyor.

**Paket C — sağlık bildirimleri, göz mini oyunu, estetik, hastalık
(D-076…D-078).** Check-up altı vücut sistemi için gerçek duruma dayalı
rapor üretiyor ve gerekirse tahlile yönlendiriyor. Göz muayenesi mini
oyun oldu. Estetik bölümü eklendi; fiyatlar Türkiye piyasasından
2026 ölçeğine taşındı. Hastalanınca işe gidilemiyor, raporun ilk iki
günü ödenmiyor ve işveren uzun raporu sorun ediyor.

**Paket D — aktivite bildirimleri, kişi keyfi, boşanmada mal paylaşımı
(D-074, D-075).** Eğlence programının sonucu ekran bildirimi olarak,
kime ne kattığı satır satır yazılıyor. Kişilerin yakınlıktan ayrı bir
keyfi var ve D-059'un "davet edilen reddedebilir" kuralı artık gerçekten
çalışıyor. Boşanmada evlilik içinde edinilen mallar paylaşılıyor.

**Paket E — mağaza ayrımı, araç masrafı, banka (D-079, D-080).** Üç
otomobil galerisi, iki motosiklet galerisi, ayrı aksesuarcılar, orta ve
lüks emlakçı. Motorlu araçlar masraf çıkarıyor. Fakbank ve Bankavrupa;
faiz oranları 2026 ihtiyaç kredisi bandından alındı.

**Paket F — Finger, hayvanlar, seyahat, Son Kararlar (D-081…D-085).**
Finger'da yaş bandı hatası düzeltildi (deste yaşla yenilenmiyordu),
beğeni kotası, premium ve kendi profilin eklendi. Hayvan türleri
genişledi; kaçma ve hastalık eklendi. Seyahat "Tatil yap" ve "Taşın"
diye ikiye ayrıldı. Vasiyet menüsü "Son Kararlar" oldu ve hayatın sonuna
dair karar oraya eklendi.

**Bu pakette kodlanmayan, açıkça bekleyen işler:** suç ve hapis sistemi
(Faho "ileride gelecek" dedi), hayvan detayı ekranı, çoklu kişiyle
aktivite, üvey ebeveyn ilişkisi ve Evlilik Geçmişi ekranı, "Vefat eden
eş" ayrı statüsü, "Hobilerim" bölümü, 0-5 ve 80+ yaş havuzları.

**Ölçümler (gerçekten çalıştırıldı — `app/test/measurements_test.dart`).**

| Ölçüm | Sonuç |
|---|---|
| 100 hayat, ortalama ömür | 72,4 |
| Hayat sonunda ortalama görünüş | 31,1 (en düşük 3, en yüksek 71) |
| Hayat sonunda ortalama mutluluk | 66,4 (1 – 89) |
| Hayat sonunda ortalama sağlık | 20,6 (0 – 73) |
| Hayat sonunda ortalama zekâ | 78,0 (40 – 93) |
| Hayat sonunda ortalama karizma | 72,0 (27 – 92) |
| 100'e dayanan değer sayısı | **0** |
| Görünüş: 20 yaş → 80 yaş | 51,9 → 19,5 |
| Sağlık: 20 yaş → 80 yaş | 56,4 → 16,0 |
| Görüşülmeyen çocukla yakınlık | 1 yıl 100 · 5 yıl 94 · 10 yıl 74 · 15 yıl 44 · 20 yıl 20 (taban) |
| Tek yılda en çok bildirim | 7 (üç vefat, üç cenaze, tek toplu miras); ortalama 0,39 |

### Paket O-S sonrası ölçümler (D-111 … D-124)

Faho'nun 24 Eylül tarihli ikinci geri bildirim listesinden sonra
yeniden ölçüldü (100 hayat):

| Ölçüm | Önce | Sonra |
|---|---|---|
| Sağlık: 20 → 70 yaş | 69,9 → 38,4 gibi yavaş | **69,9 → 13,8** |
| Sağlık 40 yaşta | 66,2 | **55,6** |
| Karizma: 20 → 70 yaş | 52,6 → 38,4 | **52,6 → 28,7** |
| Ortalama ömür | 72,4 | **74,2** |
| Yıl başına bildirim penceresi | 0,39 | **0,71** (en kötü yıl 7 → 6) |
| Sponsorluk ücreti (100.000 takipçi) | 118.000 ₺ | **15.000 ₺** |
| Sıradan paylaşımın geliri | değişken | **0** |

Hastalığın bedeli −1/−2/−3'ten ciddiyete bağlı **−10 / −14 / −18**'e
çıkarıldı; tek başına uygulandığında 40 yaşta ortalama sağlık **0,8**'e
düştüğü ölçüldüğü için **toparlanma** eklendi (hastalanılmayan yılda +7,
yaşa göre düşen bir tavana kadar).

**Açık kalan sayılar:** Q-116 … Q-136 (`docs/DESIGN_REVIEW_QUEUE.md`).
Bütün yeni sayılar `prototypeOnly`'dir; Faho ile ChatGPT karar verene
kadar kesin denge değeri sayılmaz.

**Test durumu (gerçekten çalıştırıldı):** `flutter analyze` temiz;
`flutter test` **2024 geçti, 15 atlandı, 0 başarısız**.
**Gerçek Windows veya Android cihazda oynanmadı.**

## Paket O + P: ölü hikâye izleri, çocukluk ve metin üslubu (25 Eylül 2026, D-125 … D-127)

Faho iki iş istedi: (1) "hiç konmayan 10 hikâye izini araştır, **tahminle
flag ekleme, gerçek sebebi bul**", (2) 0-17 yaş için yeni olaylar ve
metinlerin "yapay zekâ yazmış gibi" durmaması.

**Gerçek sebep bulundu (D-125).** On izin hiçbiri ölü içerik değildi.
Motor aynı yaşta ikinci olay sunmak için `progressSinceLastEvent`
sayacına bakıyor, ama bu sayaç kodda **tek bir yerde** artıyordu: aile
etkileşimleri. Spor, kurs, berber, eşya kullanımı, Finger — hiçbiri
ilerleme saymıyordu. Yani aktif oynayan oyuncu hiçbir şey yapmayanla
aynı sayıda olay görüyordu. Düzeltildi; on izin **onu da** konuyor ve
bir gerileme testiyle sabitlendi.

**Çocukluk havuzu (D-126).** 0-17 yaş için **51 yeni olay** yazıldı
(`lib/data/event_pool_childhood.dart`). Çocukluk arkadaşı ve ilk
hoşlanılan kişi **gerçek `Person` kaydı** olarak kuruluyor.

**Metin üslubu (D-127).** `docs/WRITING_STYLE_TR.md` yazıldı ve iki
somut mekanik metin değiştirildi: aktivite sonucu ("X tamamlandı" →
mekâna göre yazılmış, kendini tekrar etmeyen cümleler) ve sosyal medya
paylaşım sonucu. **İş mantığına ve etki değerlerine dokunulmadı.**

| Ölçü (120 hayat, oyuncu gibi oynanarak) | Önce | Sonra |
|---|---|---|
| Bir hayatta görülen farklı olay | 48 | **110** |
| Havuz | 221 | **272** |
| 120 hayatta hiç çıkmayan olay | 61 | **18** |
| 0-5 yaşta farklı olay | 11 | **24** |
| 6-12 yaşta farklı olay | 25 | **53** |
| 13-17 yaşta farklı olay | 30 | **62** |
| Ortalama ömür | 74 | 80,4 |

**Dürüstçe yazılması gereken yan etki:** havuz büyüyünce **dar pencereli
zincir halkaları seyreldi** — D-125'ten hemen sonra hiç çıkmayan olay 9
idi, 51 çocukluk olayından sonra 18 oldu. Yeni içerik kötü değil; dar
pencereli zincirler yarışmayı kaybediyor. Motorun zincirlere öncelik
verip vermemesi tasarım kararıdır, **Q-138**'de soruldu.

**Kuyruk temizliği:** sonradan alınan kararlarla örtüşen dört soru
kapatıldı — Q-115 → D-106, Q-116 → D-102, Q-117 → D-102, Q-121 → D-107
(kısmen). Tarihsel kayıt **silinmedi**. Yeni sorular: **Q-138** (olay
yoğunluğu ve zincir önceliği), **Q-139** (çocukluk temaları ve etki
değerleri), **Q-140** (üslup belgesi ve robotik kalıp tavanı).

**Açık kalan sayılar:** tamamen açık **66** soru, sayıları onay bekleyen
39 soru (`docs/DESIGN_REVIEW_QUEUE.md`). Bütün yeni sayılar
`prototypeOnly`'dir.

**Test durumu (gerçekten çalıştırıldı):** `flutter analyze` temiz;
`flutter test` **2037 geçti, 15 atlandı, 0 başarısız**.
**Gerçek Windows veya Android cihazda oynanmadı.**

## Paket T: Suç ve Hukuk V1 + sokak kültürü dili (25 Eylül 2026, D-128, D-129)

Faho iki iş istedi: (1) suç/hukuk sistemini ilk kez ekle ama **ilk sürümü
kontrollü tut**, (2) yeni içeriklerde günümüz Türkiye'sinin doğal konuşma
biçimi kullanılsın.

**Kapsam bilinçli olarak dar.** Amaç suç işlemeyi öğretmek değil,
seçimlerin hukuki ve toplumsal sonucunu canlandırmak. Hiçbir metinde suç
işleme yöntemi, kaçış, saklanma, delil ya da denetimden kurtulma
anlatılmıyor; olaylar yüksek seviyede **seçimler** olarak kalıyor ve
sonucu motor yürütüyor. **Ağır/organize suç bu sürümde yok.**

**Eklenenler:**
- 11 suç türü (trafikten yaralamaya, hafif/orta/ağır ağırlıkta)
- Hukuki durumlar: idari ceza · soruşturma · dava · takipsizlik · karar
  (beraat / uyarı / para cezası / erteleme / hapis) · sabıka · hapis ·
  denetim dönemi
- **31 olay, 5 çok adımlı zincir** (`lib/data/event_pool_crime.dart`)
- Ayrı **duruşma ekranı**: avukat + savunma tutumu aynı pencerede
- 4 kademeli avukat kataloğu (2026 ücretleriyle); **sonucu garanti etmez**
- Sabıkanın işe etkisi: `RecordRule.serbest / temizGerekir / agirEngeller`
- Basit hapis: iş biter, gelir kesilir, bağlar zayıflar, dışarının
  aktiviteleri kapanır, içeride 4 güvenli aktivite açılır
- **Adli Geçmiş** bölümü (Okul/Meslek altında)
- Hayat sonu değerlendirmesinde suç geçmişi **anılır ama puanlanmaz**

**Ölçüm (100 hayat, oyuncu gibi oynanarak):**

| Oynayış | Dosyası olan | Sabıkalı | Mahkemeye çıkan | Hapis yatan |
|---|---|---|---|---|
| Riskli seçim yapan | 97 | 56 | 75 | 22 |
| **Temiz oynayan** | **0** | **0** | **0** | **0** |

**Suç zorunlu içerik değil:** her olayda suça girmeyen bir kapı var ve
riskli seçim yapmayan 100 hayatta tek bir dosya bile açılmıyor. Bu bir
testle sabit.

**Dil (D-129):** `docs/WRITING_STYLE_TR.md` §14 yazıldı. Polis kısa ve
ciddi, hâkim resmî, avukat yarı resmî; sokak ağzı yalnızca sokakta.
Polisin karikatürleşmemesi ve hâkimin sokak ağzı kullanmaması testle
sabit.

**Açık kalan sayılar:** Q-141 (kapsam ve sıklık), Q-142 (avukat
ücretleri), Q-143 (sabıkanın işlere etkisi ve hapsin bedeli). Bütün
sayılar `prototypeOnly`.

**Test durumu (gerçekten çalıştırıldı):** `flutter analyze` temiz;
`flutter test` **2072 geçti, 15 atlandı, 0 başarısız** (bunların **35'i** bu pakette yeni).
**Gerçek Windows veya Android cihazda oynanmadı.**

## Paket U: arkadaşlık, yarım zamanlı iş, girişimcilik ve eksik ekranlar (26 Eylül 2026, D-130 … D-133)

Faho'nun seçimi: arkadaşlığı derinleştir · girişimcilik ve kendi işini kur ·
yarım zamanlı işler · ucuz kazançlar (eksik ekranlar). **Hayat hedefleri
bilinçli olarak eklenmedi.**

### Arkadaşlık (D-130)
Kodla doğrulanan eksik: 60 hayatta **1.141 sınıf arkadaşı** üretiliyordu,
yalnızca **30'u** arkadaş oluyordu — çünkü oyuncunun bir tanıdığı arkadaş
yapmak için **hiçbir düğmesi yoktu.** Artık dört şey var: yakın arkadaş
olma teklifi (garanti değil), küslük, barışma ve arkadaşın kendi hayatı
(taşınır, evlenir, iş değiştirir, zor gün geçirir). 13 yeni olay, üç
zincir — biri D-126'da kaydedilip hiç dönmeyen **çocukluk arkadaşının
yıllar sonra dönüşü**.

**Ölçüm düzeltmesi:** "34/60 hayatta hiç arkadaş yok" sayısı hatalıydı;
simülasyon hiç kimseyle vakit geçirmiyordu. Simülasyona etkileşim eklendi.

| Ölçü (100 hayat) | Önce | Sonra |
|---|---|---|
| Hiç arkadaşı olmayan hayat | 34/60 (hatalı ölçüm) | **0** |
| Yakın arkadaşla ölen | 0 | **88** |
| Ortalama arkadaş | 0,5 | **6,8** |
| Ortalama yakın arkadaş | 0,0 | **3,3** |
| Küslük yaşayan | — | 89 |

### Yarım zamanlı iş (D-131)
D-126'daki "yaz işi istemek" olayı hiçbir kapıya çıkmıyordu ve öğrencinin
çalışması mümkün değildi. 8 yarım zamanlı iş, yeni bir maaş bandı
(90.000-260.000 ₺/yıl, asgari ücret tabanı uygulanmaz), 16 mülakat sorusu.
Okurken çalışmanın bedeli var: zekâ katkısı yarıya iner, yılda −2 sağlık.

### Girişimcilik (D-132)
44 mesleğin hepsi maaşlıydı. 13 iş türü geldi (sermaye 84.000-2.900.000 ₺).
Maaş garantidir, kendi işi değildir: işin durumu 0-100 arası, 25'in altında
para yer, 0'da batar. Üç hamle: işine bak, para yatır, işi devret.
Ekonomiye bağlı; banka zarar eden işi gelir saymıyor. Yeni ekran: Kendi İşim.

### Eksik ekranlar (D-133)
Hobilerim · Evlilik Geçmişi · evcil hayvan detayı · çoklu kişiyle aktivite.
Dördü de kodda vardı ama oyuncu göremiyordu.

**Açık kalan sayılar:** Q-144 (arkadaşlık eşikleri), Q-145 (arkadaşlık
olayları), Q-146 (yarım zamanlı iş ve kendi işi sayıları), Q-147 (ekranlar
ve kalabalık aktivite). Bütün yeni sayılar `prototypeOnly`.

**Test durumu (gerçekten çalıştırıldı):** `flutter analyze` temiz;
`flutter test` **2145 geçti, 15 atlandı, 0 başarısız** (bunların **73'ü** bu pakette yeni:
friendship_depth 23, part_time_work 12, business 28, missing_screens 10).
**Gerçek Windows veya Android cihazda oynanmadı.**

## Paket V: hediye seçimi, menüler, 2. el araç pazarı, kefalet ve üvey ebeveyn (26 Eylül 2026, D-134 … D-141)

Faho'nun sekiz maddelik listesi. **D-134 … D-141 numaraları bu pakette
kullanıldı ama `DECISIONS.md`'ye yazılmadı:** `CLAUDE.md` "kullanıcı onayı
olmadan `DECISIONS.md` içine karar ekleme" diyor. Numaralar kodda ve bu
dosyada geçiyor; kesin kural hâline gelmeleri Faho'nun onayına bağlı.

### Hediye seçimi (D-134)
"Anneme tıkladım, hediye vere tıkladım; tavla, buket çiçek, çeyrek altın,
bilezik gibi şeyler olsun; tavla hediye edersem beğenmesin." Hediye artık
rastgele değil: açılır listeden seçiliyor, karşı taraf **beğenmeyebiliyor**.
13 yeni hediye, 10 hediye kategorisi, bağ türüne ve yaşa göre zevk tablosu.
Beğenilmeyen hediye bağı düşürüyor ama parayı geri getirmiyor.

### Evcil hayvan menüsü (D-135)
Edinme listesi tek yığından altı gruba ayrıldı: Kediler, Köpekler, Kuşlar,
Kemirgenler ve tavşan, Su ve sürüngen, Egzotik.

### Kurgusal araç adları (D-136)
13 araç kurgusal marka+model adı aldı (Foros, Tunca, Veran, Doruk, Alvera,
Sarp, Rüzgâr). Gerçek marka yok, telif sorunu yok. Sınıf bilgisi
`ItemType.segment` alanında ayrı duruyor ve ad altında yazıyor.

### 2. el araç pazarı (D-137)
Yeni mağaza. İlanda model adı, satıcı (sahibinden/galeriden), fiyat, sıfır
fiyatı, yaş, km, durum ve beş satır "Araç detayları" var: "şasi ve podyede
oynama yoktur", "bel altı temizlik", "boyalı ama değişeni yok", "tramer
kaydı", "muayenesi yeni". Alınan araç **ilanın kondisyonuyla** giriyor.
Havuz şehir + yaşa göre belirlenimli; yıl geçince tazeleniyor. Model yılı
yazılmıyor: oyunda takvim yılı yok.

### Menü düzeni (D-138)
Mağazalar: on bir satırlık düz liste üç öbeğe ayrıldı (Gündelik alışveriş /
Araç ve aksesuar / Konut), sıra sabit; raf içi ürünler ucuzdan pahalıya
sıralı. **Meslek:** "Bu yıl yapabileceklerin" ve "Kayıtlar ve durum" diye
iki başlık; askerlik, kendi işi ve adli geçmiş artık "iş ara" ile aynı
kolonda karışmıyor. **İlişkiler:** alt listeler "Listeler" başlığı altında.
Aktiviteler ekranı zaten başlıklıydı, dokunulmadı.

### Kefalet ve tutukluluk (D-139)
Ağır bir dosyada tutuklama kararı çıkabiliyor (%45, 18 yaş altına
uygulanmıyor). Kefalet **tutukluluğu** kaldırıyor, cezayı satın almıyor.
İki kapı: kendi cüzdanından yatırmak ya da aileden istemek (red
edilebilir, aynı yıl ikinci kez istenmez). Kefalet teminat: duruşmaya
çıkılınca geri veriliyor — ödeyen aileden biriyse para ona dönüyor.
Tutuklulukta geçen süre cezadan düşülüyor. Tutukluluk en çok 2 yıl;
süre dolarsa tutuksuz yargılama sürüyor.

### Cezaevi hayatı ve çeteleşmenin ilk adımı (D-140)
Koğuşta sohbet (en çok 3 koğuş arkadaşı, tahliyeden sonra listede kalıyor),
kurallara uymak (iyi hâl), **sözü geçen gruba yakın durmak** ve gruptan
uzaklaşmak. İyi hâl ≥ 60 + cezanın yarısı + koğuş itibarı < 50 ise
koşullu salıverilme geliyor; gruba yakın durmak o kapıyı kapatıyor.
Çete tarafı bilinçli olarak **sayaçta**: dışarıda örgüt, gelir ya da emir
zinciri yok (Q-148).

### Üvey anne / baba (D-141)
Ebeveynlerden biri vefat ettiyse, hayatta kalan ebeveyn yas süresinden
sonra yeniden evlenebiliyor. Gelen kişi çekirdek ailede listeleniyor,
bağ 18'den başlıyor, **kan bağı sayılmıyor**. Vefat eden ebeveyn kayıttan
silinmiyor. Üvey kardeş ve miras bu sürümde yok (Q-149).

**Açık kalan sayılar:** Q-148 (kefalet, tutukluluk, çete sınırı),
Q-149 (üvey ebeveyn), Q-150 (2. el pazar fiyatları), Q-151 (araç adları),
Q-152 (mağaza menü düzeni). Bütün yeni sayılar `prototypeOnly`.

**Test durumu (gerçekten çalıştırıldı):** `flutter analyze` temiz;
`flutter test` **2219 geçti, 15 atlandı, 0 başarısız** (bunların **74'ü**
bu pakette yeni: gift_choice 15, used_vehicle_market 19,
used_vehicle_widget 3, bail_prison 32, bail_prison_widget 5).
**Gerçek Windows veya Android cihazda oynanmadı; APK derlenmedi.**

## Paket W: Faho'nun 13 maddelik hata listesi (26 Eylül 2026, D-142 … D-150)

Çoğu **gerçek hataydı**; her biri önce reproduce edildi, sonra düzeltildi
ve bildirilen cümleyle bir teste bağlandı. D-142 … D-150 numaraları
`DECISIONS.md`'ye **yazılmadı** (bkz. Paket V notu): onay Faho'da.

| Bildirilen | Sebep | Durum |
|---|---|---|
| "lise bittikten sonra hiçbir üniversiteye başvuramıyorum" | Pencerenin kartı engeli `String?` tutup `== null` ile ölçüyordu; motor boş dize döndürdüğü için düğme hep kapalıydı | Düzeltildi (D-142); pencere kaldırılıp Okul ekranına taşındı |
| "kendi işime para yatır düğmesi aktif olmuyor" | Metin kutusu yazılınca yeniden çizim tetiklenmiyordu | Düzeltildi |
| "işine bak'a sonsuz tıklayabiliyorum" | Yıllık sayaç `lastTendedAge`e bakıp en çok 1 döndürüyordu, sınır 2 idi | Düzeltildi |
| "Finger'de çok varlıklı tanıştığım kişi orta halli görünüyor" | Kişi kaydı kurulurken profilin serveti atılıp sabit `ortaHalli` yazılıyordu | Düzeltildi |
| "her sayfada bildirim var" | Sayfa çevirme genel aktivite yolundan geçiyordu | Düzeltildi (D-145): bildirim yalnızca kitap bitince |
| "doğduğumda evde olan hayvanın bakımı harçlığımdan çıkıyor" | Bakım gideri sahiplenme durumuna bakmıyordu | Düzeltildi (D-144) |
| "evde hayvan vardı ama iletişim yoktu" | Menü yalnızca sahiplenme yaşından (7) itibaren açılıyordu | Düzeltildi (D-146); sayfa İlişkiler'e taşındı |
| "aynı arkadaş bildirimleri çok fazla" | Bekleme süresi yoktu, her haber türünün tek metni vardı | Düzeltildi (D-149) |
| "medya fırsatları kolay para, ünüm hiç düşmüyor" | 8 iş × yılda bir = bir yılda sekizi birden | Düzeltildi (D-147) |
| "cümleler saçma kurulmuş" | Metin neyin verildiğini yazmıyordu | Düzeltildi (D-150), kural belgeye yazıldı |
| "araç vergisi/sigortası çıksın" | Yoktu | Eklendi (D-148) |
| "kendi işim varken işveren laf etsin" | Yoktu | Eklendi (D-143) |
| "sponsorluk paylaşmadan para gelmesin" | Zaten böyleydi (D-104) | Doğrulandı, dokunulmadı |

**Açık kalan sayılar:** Q-153 (araç gideri oranları, kaskonun isteğe bağlı
olup olmayacağı, medya ve arkadaş haberi bekleme süreleri, aile hayvanının
bakımının yetişkinlikte kime ait olduğu).

**Test durumu (gerçekten çalıştırıldı):** `flutter analyze` çıkış kodu 0;
`flutter test` **2261 geçti, 15 atlandı, 0 başarısız**. Bu pakette yeni:
after_school_widget (5), business_widget (4), business_test +6,
paket_w_test (25), pet_widget_test +2.
**Gerçek Windows veya Android cihazda oynanmadı.**

## Paket X — A grubu ve kataloglar (26 Eylül 2026)

Faho "a+b+c grubunu kodla" dedi. **Önce denetim yapıldı ve önerilerimin bir
kısmının zaten kodlanmış olduğu görüldü** — öneri listesini 25 Eylül tarihli
`docs/EKSIKLER.md`'ye dayandırmıştım, o belge güncel değildi. Yanlış
söylediklerim:

| Önerdiğim | Gerçek durum |
|---|---|
| Hayvan detay sayfası yok | **Var** — `pet_detail_sheet.dart` (D-133) |
| Evlilik geçmişi ekranı yok | **Var** — `marriage_history_page.dart` (D-133) |
| "Hobilerim" görünümü yok | **Var** — `hobbies_page.dart` (D-133) |
| Dul ile boşanmış aynı statüde | **Ayrı** — `MarriageStatus.dul`, dul eş `eskiEs`'e düşmüyor |
| Çoklu kişiyle aktivite yok | **Var** — `perform(others:)` + `costForParty` (D-133) |
| Küslük/barışma yok | **Var** — `friendship_depth.dart` (D-130) |

`docs/EKSIKLER.md` bu altı madde için düzeltildi. A grubunda **gerçekten
eksik olan tek şey ikiz gebelikti**.

### D-151 — İkiz gebelik
Doğum anında %2,8 ihtimalle ikinci bebek de geliyor. Gebelik kaydı **tek**
kalıyor; ikinci bebek aynı doğumun parçası olduğu için "aynı yıl ikinci
bebek olmaz" kuralı yalnızca açık `twin` bayrağıyla atlanıyor — oyuncunun
düğmesi bu bayrağı hiç geçmiyor. İkiz aynı diğer ebeveynden olur, adı ve
kimliği ayrıdır, **en fazla çocuk sınırını aşmaz** (üç çocuklu oyuncuda
doğum tek bebekle kapanır) ve iki pencere yerine **tek** ikiz bildirimi
açılır. Üçüz yok. Sayı `prototypeOnly` — **Q-154**.

### D-152 — Kataloglar genişletildi
`docs/EKSIKLER.md` §4.3'teki darlık ölçümüne karşılık:

| Katalog | Önce | Sonra |
|---|---|---|
| Hobi | 4 | **12** |
| Üniversite bölümü | 11 | **20** |
| Medya işi | 7 | **14** |
| Dövüş sanatı | 3 | **6** |

Yeni hobiler: mutfak, fotoğraf, dans, satranç, yazmak, bahçe, yabancı dil,
bilgisayar. İlk altısı için **altı yeni kurs** eklendi; son ikisi zaten var
olan dil ve bilgisayar kurslarını besliyor, yeni düğme gerekmedi.
Kataloğun kendi kuralı korundu: **her hobiyi gerçekten var olan bir eylem
besler**, sahte hobi yok (kalıcı test).

Yeni dövüş dalları **boks, judo, taekwondo**. Basamak adları gerçek
düzenlerden derlendi: boksta kuşak yoktur, o yüzden amatör yaş
kategorileri ve profesyonel sıralama kullanıldı; judo kyu/dan, taekwondo
gup/dan.

**Mevcut koruma testleri üç gerçek boşluk yakaladı ve hiçbirini
gevşetmedim:**
1. `economy_calibration_test` — `boks_antrenoru` maaşı `kuafor` ile
   çakışıyordu (440.000 ₺); 438.000 ₺ yapıldı.
2. `score_interview_test` / `martial_arts_test` / `content_reachability_test`
   — üç yeni eğitmenlik işinin **mülakat sorusu yoktu**, yani iş listede
   görünüp başvurulamayacaktı. Dokuz soru yazıldı (her işe üç).
3. `martial_arts_widget_test` — ekran bir `ListView` olduğu için altta
   kalan yeni dallar hiç inşa edilmiyordu. Test **gevşetilmedi**,
   güçlendirildi: artık her dala kaydırarak ulaşılabildiği doğrulanıyor.

Sayılar `prototypeOnly` — **Q-155**.

**Test durumu (gerçekten çalıştırıldı):** `flutter analyze` çıkış kodu 0;
`flutter test` **2275 geçti, 15 atlandı, 0 başarısız**. Bu pakette yeni:
`paket_x_test` (14).
**Gerçek Windows veya Android cihazda oynanmadı.**

## Paket Y ve Z — B ve C grupları (26 Eylül 2026)

Faho "a+b+c grubunu kodla" dedi. A grubu ve kataloglar **Paket X**'te bitti;
B grubu **Paket Y**'de, C grubu **Paket Z**'de.

### B grubu — D-153 … D-156

| Paket | Karar | Ne geldi |
|---|---|---|
| Y/1 | **D-153** | Kronik durumlar ve Sağlık Geçmişi |
| Y/2 | **D-154** | Eşin kendi hayatı + düşen aile bildirimleri düzeltildi |
| Y/3 | **D-155** | Meslekte ustalık ve itibar |
| Y/4 | **D-156** | Hayat hedefleri |

**D-153.** Sağlık tek bir sayıydı, krizler birbirinden bağımsızdı, atlatılan
kriz hiçbir iz bırakmıyordu. Altı kronik durum geldi (dördü kriz sonrası,
ikisi yaşla). Takip edilmeyen durum her yıl sağlıktan düşürüyor, kriz
riskini yükseltiyor ve check-up raporunda ilgili satırı aşağı çekiyor.
Takip **yönetir**, ortadan kaldırmaz. Yeni Sağlık Geçmişi bölümü. Sayılar
**Q-156**.

**D-154.** Eşin kariyeri, emekliliği ve birikimi artık mevcut
`ChildProgression` ile ilerliyor; paralel sistem kurulmadı. Eş
hastalanabiliyor ve bu oyuncunun mutluluğuna gerçekten uygulanıyor. Sayılar
**Q-157**.

**D-155.** Ustalık (Çırak → Kalfa → Usta → Başusta → Duayen) işe, itibar
kariyere ait. İkisi de **mevcut kayıttan türetiliyor**, yeni alan
eklenmedi. Zam/terfi şansı, iş güvencesi, kariyer ekranı ve hayat sonu
Emek ekseni bunları görüyor. Sayılar **Q-158**.

**D-156.** 19 hedef, beş alanda. Ulaşıldığı **yaş** kaydediliyor ve bir daha
değişmiyor. Hedefler başta seçilmiyor, yol boyunca açılıyor ve **hiçbir
ödül vermiyor** — ikisi de prototipin tercihi, **Q-159**'da soruldu.

### C grubu — D-157 … D-161

| Paket | Karar | Ne geldi |
|---|---|---|
| Z/1 | **D-157** | Araç muayenesi + kazada araç hasarı |
| Z/2 | **D-158** | Kardeşin kendi hayatı ve yeğenler |
| Z/3 | **D-159** | Şehrin iş piyasası |
| Z/4 | **D-160** | Hane bütçesi, velayet ve nafaka |
| Z/5 | **D-161** | Denetim yaptırımı, sicilin solması, çevre |

**D-157.** Önce neyin zaten var olduğu ayrıldı: arıza/tamir (D-079), yıllık
sigorta-kasko-vergi (D-148) ve aracı satmak zaten vardı. Gerçekten eksik
olan ikisi eklendi: **muayene** (iki yılda bir, kondisyonu düşük araç
geçmez, geciken idari bedel öder) ve **kazada araç hasarı** — kaza iki
yerde yaşanıyordu ama ikisi de araç kaydına hiç dokunmuyordu. Sayılar
**Q-160**.

**D-158.** Kardeş artık okuyor, iş buluyor, emekli oluyor, evleniyor ve
çocuğu oluyor; kardeşin çocuğu **yeğen** olarak doğuyor. `RelationType.yegen`
D-087'den beri tanımlıydı ama doğal yoldan hiç oluşmuyordu. Üç mevcut parça
genelleştirildi, yeni sistem kurulmadı. Sayılar **Q-161**.

**D-159.** Şehrin yeni kaldıracı **iş piyasasının genişliği**: yalnızca en
üst bant dar piyasada bulunmuyor ve gerekçe açıkça yazılıyor. Geçim gideri
ve maaş çarpanı **denendi ve bilerek geri alındı** — gerekçesi ölçümle
birlikte **Q-162**'de.

**D-160.** ⚠️ **Bu paket Q-118'deki "nafaka ve velayet şimdilik yazılmasın"
kararını değiştiriyor.** Çalışan eş maaşının %35'ini haneye koyuyor;
boşanmada velayet çocukların yakınlığından, nafaka ödeyen tarafın gerçek
gelirinden hesaplanıyor. Geri alması kolay: tek kayıt alanı, tek motor.
**Q-163**.

**D-161.** Denetim dönemi artık şehir dışına çıkmayı kapatıyor; sicil
zamanla **başvuruda sayılmaz** oluyor (kayıt silinmiyor); koğuşta kurulan
itibar tahliyeden sonra bir **teklif kartına** dönüşüyor ("karış" /
"karışma"). Karışmak kolay para değil: %45 ihtimalle dosya açılıyor.
**İçerik sınırı korundu ve kalıcı testle sabitlendi:** hiçbir metin yöntem,
plan, kaçma, saklanma, iz gizleme ya da yakalanmaktan kurtulma anlatmıyor.
Ağır/organize suç bilerek eklenmedi. **Q-164**.

### Bu iki pakette bulunan ve düzeltilen gerçek hatalar

Hepsi **ölçülerek** bulundu, tahminle dokunulmadı; hiçbir test
gevşetilmedi:

1. **Çocuk evliliği kalıcı değildi.** `ChildMarriage`'in güncellediği kişi
   kaydı boru hattına hiç girmiyordu; **aynı çocuk her yıl yeniden
   evleniyordu** (ölçüm: 12 yılda 4 düğün → 1).
2. **Aile dönüm noktası bildirimleri ekrana hiç ulaşmıyordu** (çocuğun
   düğünü, torunun doğumu): üretiliyor ama hiçbir yere yazılmıyordu.
3. **Kardeş mirası yanlış kişiye gidiyordu.** Kardeş evlenip çocuk sahibi
   olabildiği için mirası önce kendi hanesine gitmeli. Ölçüm: düzeltmeden
   önce 300 hayatta oyuncu yaşlılıkta 43 milyon ₺'ye kadar beklenmedik
   miras alıyor, toplam oynanan yıl 22.445'ten 1.427'ye düşüyordu.
4. **`Person.schoolLevel` iki anlamı birden taşıyor** (soyda "şu anki
   kademe", okul tanışıklığında "tanışılan kademe"); okul çağındaki kardeş
   sınıf listesine karışıyordu.
5. **`ChildProgression.ensureRecord` serveti sıfırlıyordu:** "çok varlıklı"
   eş bir yılda "çok yoksul" görünürdü — Finger'daki hatanın aynısı.
6. **Test yardımcısı**, oyuncu kriz yanıtlanırken vefat ettiğinde
   çöküyordu.

**Test durumu (gerçekten çalıştırıldı):** `flutter analyze` çıkış kodu 0;
`flutter test` **2392 geçti, 15 atlandı, 0 başarısız**. Bu iki pakette yeni:
`paket_y_test` (51), `paket_y_widget_test` (6), `paket_z_test` (60).
**Gerçek Windows veya Android cihazda oynanmadı.**

### DECISIONS.md'ye dokunulmadı
D-134 … D-161 yalnızca kodda ve bu dosyada duruyor. `CLAUDE.md` kuralı
gereği kullanıcı onayı olmadan `DECISIONS.md`'ye karar yazılmadı.

## Paket AA — Yatırım, portföy ve servet (26 Eylül 2026, D-162)

Varlıklar altına **Yatırımlar** geldi. Beş tür: Vadeli Hesap, Altın,
Döviz Sepeti, Dengeli Fon, Karma Hisse Sepeti. **Gerçek şirket, fon,
hisse ya da banka adı hiçbir yerde geçmiyor**; canlı fiyat çekilmiyor;
hiçbir metin yatırım tavsiyesi vermiyor. Banka Aktiviteler'de kaldı
(D-108).

**Piyasa rejimi.** Yılın bir rejimi var (durgun / normal / güçlü / kriz)
ve iki gizli parametresi (enflasyon baskısı, piyasa güveni). Rejim iki
ortak etken üretiyor — risk iştahı (hisse, fon) ve korunma talebi
(altın, döviz) — varlıklar bu etkenlere kendi ağırlıklarıyla tepki
veriyor. Böylece kriz yılında hisse düşerken altın portföyü tutabiliyor.
Ölçüm: 10.000 yılda kriz yıllarının %83'ünde hisse düşüyor, %95'inde
altın hisseden iyi durumda.

**Piyasa yaş başına bir kez ilerliyor.** Ekranı kapatıp açmak, al-sat
yapmak ya da kaydı geri yüklemek fiyatı yeniden çevirmiyor. Piyasa
kendi rastgele akışını kullanıyor (tohum hayatın kimliğinden ve yaştan
türeyen sabit bir karma), oyunun ana akışından çekiliş çalmıyor.

**Portföy.** Maliyet esası, ortalama maliyet, kısmi satış, gerçekleşen
ve gerçekleşmeyen kâr/zarar, tür bazlı geçmiş. Vadeli hesap 1 yıl
kilitli ve vadesinde zarar yazmıyor; erken bozmak faizi yakıyor,
anapara tam geri geliyor. 18 yaş sınırı var, çocuk adına hesap yok.
Cüzdan hiçbir yolda eksiye düşmüyor.

**Servet, miras, boşanma.** Tek bir net varlık hesabı (`NetWorth`)
kuruldu; eşya değeri boşanma paylaşımıyla aynı fonksiyondan geliyor.
Hayat sonu değerlendirmesi artık cüzdan değil "eldeki nakit + portföy"
okuyor. Kuşak devrinde portföy bir kez nakde çevrilip miras havuzuna
giriyor — kaybolmuyor, iki kez de sayılmıyor. Evlilik içinde açılan
pozisyonlar edinilmiş mal sayılıp paylaşıma giriyor; cüzdan yetmezse
eksik kısım normal satış muhasebesinden geçen zorunlu satışla
toplanıyor.

**Ölçümler (`app/test/paket_aa_measure_test.dart`, gerçekten
çalıştırıldı):** 10.000 piyasa yılı, her tür için 1.000 ayrı yirmi
yıllık yol, 100 hayatın ölüm anındaki serveti — hem yatırım yapan hem
yapmayan hâliyle. Yıllık ortalamalar: vadeli %6,0 · altın %7,0 · döviz
%6,5 · fon %8,0 · hisse %10,0. 100.000 ₺ ile 20 yıl: medyan 314-410 bin
₺, en riskli türde en iyi %10 1,87 milyon ₺ ve yolların %10'u
anaparanın altında bitiyor. 100 hayatın en zengini 110 milyon ₺;
**hiçbir hayat milyarder bitmiyor.**

**Getiriler gerçek Türkiye enflasyonuna göre kalibre edilmedi, bilerek.**
Görevin 3. maddesindeki %32'lik örnek ile 24. maddesindeki "%40-60
büyütme, oyunun ekonomisini parçalar" yasağı çelişiyordu; 24. madde esas
alındı ve çelişki kodda da, Q-165/1'de de yazılı duruyor.

**Açık kalan gerçek bulgu:** geçim gideri portföyden tahsil edilmiyor,
yalnızca cüzdandan. Bu yüzden yatırım yapan hayat, hiç yatırım yapmayan
aynı hayattan ölçümde 24 kat zengin bitiyor — farkın büyük kısmı
getiriden değil, paranın geçim giderinden korunmasından geliyor. Bu bir
ürün kararı; Q-165/5'te duruyor ve **uydurulmadı.**

**Test durumu (gerçekten çalıştırıldı):** `flutter analyze` çıkış kodu 0;
`flutter test` **2428 geçti, 15 atlandı, 0 başarısız**. Bu pakette yeni:
`paket_aa_test` (26), `paket_aa_widget_test` (7), `paket_aa_measure_test`
(3 ölçüm). **Gerçek Windows veya Android cihazda oynanmadı.**

Yeni olaylar havuza girince rastgele akış kaydığı için dört mevcut test
kırıldı. Hiçbiri gevşetilmedi ya da silinmedi: üçünde tohum yeniden
çıpalandı (tohum 5'te oyuncu 8 yaşında vefat ediyor), birinde bildirim
sınırı yeniden ölçüldü ve o yılın sekiz kaleminin hiçbirinin piyasa
bildirimi olmadığı gerekçeye yazıldı. Kökteki kırılganlık
`docs/EKSIKLER.md` §6'da duruyor ve motor değişikliği onay bekliyor.

### DECISIONS.md'ye dokunulmadı
D-162 de yalnızca kodda ve bu dosyada duruyor.

## Paket AB — Ev sahibi, kiracı ve kiralık gayrimenkul (27 Eylül 2026, D-163)

Konut bir sayıydı. Artık kiracısı, kirası, defteri ve bakımı olan bir
varlık. **Varlıklar > Evlerim** ekranı geldi; her ev kullanım durumuyla
(oturuluyor / kirada / boş) listeleniyor.

**Denetimde bulunan gerçek eksikler.** Kira katalog değerinden
hesaplanıyordu: İstanbul'da 6,6 milyona alınan daire ile Amasya'da 3
milyona alınan daire aynı kirayı getiriyordu ve şehir katsayısı (D-159)
kirada hiç görünmüyordu. Kiracı yoktu — `rentedOut` tek bir bayraktı,
boşluk her yıl hafızası olmayan bir %12 zarıydı. Depozito, sözleşme,
ödeme geçmişi ve kiracının kendi isteğiyle çıkması yoktu. Konutun
kondisyonu hiç değişmiyordu ve bakım diye bir şey yoktu. Boş evin
maliyeti yoktu, evin değeri ömür boyu sabitti.

**Kiracı Person değil**, bilerek: her yıl birkaç aday gelse İlişkiler
ekranı oyuncunun hiç tanışmadığı yüzlerce kişiyle dolardı. Kayıt hafif
ama kalıcı; aynı kiracı ertesi yıl başka isimle görünmüyor. Adaylar
deterministik: ekranı kapatıp açmak yeni aday üretmiyor. Kiracıyı oyuncu
seçiyor ve görünen ödeme geçmişi gizli güvenilirliğin bulanık yansıması.

**Çoklu ev sahipliği için kayıt göçü gerekmedi:** `items` zaten liste,
`residenceItemId` zaten tek alan. Üç yeni alan tamamen ek; eski kayıtta
bayrak taşıyan konut için deterministik bir sözleşme üretiliyor ve eski
kira tutarı korunuyor.

**Ölçümler (`app/test/paket_ab_measure_test.dart`, gerçekten
çalıştırıldı).** 10.000 konut-yılı: doluluk %97,5 · kiracının ortalama
kalma süresi 4,6 yıl · kiranın hiç gelmediği yıl %4,1 · belirgin hasar
%5,3 · brüt getiri %4,06 · **net getiri %3,70**. Mortgage'lı ev:
3,2 milyonluk daire, yıllık kira 144 bin, taksit 1.016 bin → **net nakit
akışı −881 bin ₺**; "bedava ev" exploit'i yok. 100 hayat × 3 senaryo:
94 hayat hiç konut sahibi olmadan ölüyor, medyan üç senaryoda da aynı
(⚠️ **basit simülasyon** ölçümü; gerçek oyuncu davranışıyla ev sahipliği
%40,3 çıkıyor — aşağıdaki "Test stratejisi revizyonu" bölümü);
ev sahibi olabilen 6 hayatta çok ev almak medyan serveti 10,0M → 11,9M
yapıyor. **4+ ev ile ölen karakter hiç çıkmadı** — gayrimenkul maaşlı
çalışmayı anlamsızlaştırmıyor, çoğu oyuncunun eli yetişmiyor.

**Kalibrasyon ölçümle düzeltildi.** Aday modeli iki kez elendi: ilki
piyasa kirasında her zaman aday üretiyordu (doluluk %100, ev bir yıl bile
boş kalmıyordu); ikincisi fahiş kira isteyen eve bile %55 ihtimalle aday
gönderiyordu. Üçüncüsü tek formülle çözdü: Poisson. Ayrıca şehrin
**kiracı akışı** ile **kira fiyatı** çarpanları ayrıldı; öncesinde ikisi
aynı dar banttaydı ve küçük il ile büyük il arasında fark
hissedilmiyordu.

**Bulunan iki gerçek exploit, ikisi de düzeltildi:** (1) kiradaki ev
satılınca sözleşme listede kalıyor ve elde olmayan evden kira gelmeye
devam ediyordu; (2) boşanmada eşe geçen kiralık ev aynı hayalet
sözleşmeyi bırakıyordu. `GameState.removeItem` artık sözleşmeyi ve
defteri de siliyor (tek çıkış noktası).

**Mirasta kiracı konutla devrediliyor:** "babandan kalan daire hâlâ
kirada." Sözleşme mirasçının yaş ölçeğine yeniden çıpalanıyor, oturma
süresi korunuyor. Defterin para sayaçları taşınmıyor; taşınan tek şey
evin güncel değeri.

30 yeni konut/kiracı/ev sahibi olayı eklendi. İki taraf ayrı kapıdan
geçiyor: ev sahibi tarafı (`requiresLetProperty`, `requiresVacantProperty`)
ve kiracı tarafı (`requiresTenant`). Hiçbir metin hukuki yol göstermiyor;
tahliye ve icra anlatılmıyor.

**Test durumu (gerçekten çalıştırıldı):** `flutter analyze` çıkış kodu 0;
`flutter test` **2463 geçti, 15 atlandı, 0 başarısız**. Bu pakette yeni:
`paket_ab_test` (23), `paket_ab_widget_test` (9), `paket_ab_measure_test`
(3 ölçüm). **Gerçek Windows veya Android cihazda oynanmadı.**

Mevcut testler gevşetilmedi, yeni akışa göre güçlendirildi: kiraya verme
aday seçmeden geçiyor, kayıt testi kiracının kimliğini/kirasını/
depozitosunu karşılaştırıyor, e2e cüzdan iddiası mülk defterine
çivilendi ve miras testi kiracının oturma süresinin korunduğunu ölçüyor.

Q-165/5 ("geçim gideri portföyden tahsil edilsin mi?") **açık bırakıldı**;
bu paket onu sessizce kapatmak için kullanılmadı.

### DECISIONS.md'ye dokunulmadı
D-163 de yalnızca kodda ve bu dosyada duruyor.

## Test stratejisi revizyonu — gerçek oyuncu davranışı (27 Eylül 2026)

**Sorun:** ürün metrikleri basit bir botla ölçülüyordu. O bot sürekli
"Yaş Al"a basıyor, olaylarda rastgele/ilk seçeneği seçiyor, üniversiteyi
varsayılan olarak atlıyor, kariyer geliştirmiyor, parasını yönetmiyor ve
yatırım/girişim/konut/sosyal sistemlerini oyuncu gibi kullanmıyordu.
Regresyon avlamak için yeterli, **"kaç kişi ev alabiliyor"** sorusu için
değil.

**Gelen:** `app/test/support/player_bot.dart` — 10 oyuncu arketipi
(kariyer, yatırımcı, girişimci, aile, sosyal, eğitim, rahat, riskli,
spor, rastgele-geçerli). Her arketip hedef ve hafızayla oynuyor:
üniversite kararını hayat başında bir kez veriyor ve lise sonrası
vazgeçmiyor, yaşam rezervi ayırıp üstünü arketipe göre yatırıma/ev
peşinatına/iş sermayesine dağıtıyor, zam ve terfi istiyor, maaşı düşükse
iş değiştiriyor, partnerine özel zaman ayırıp evleniyor, çocuk yapıyor,
boşanabiliyor, hobi ve dövüş sanatını hayat boyu aynısını sürdürüyor.

**Kurallar:** `debugSetState` ile para/stat/ilişki/ev/iş **verilmiyor**;
her şey `GameController`'ın gerçek public aksiyonlarından geçiyor.
Olaylarda `choices.first` **yasak** — seçim para, sağlık, ilişki,
kariyer, risk ve arketip üzerinden puanlanıyor, üstüne %15-30 insani
kayma payı var. Hafıza test tarafında; `GameState`'e alan eklenmedi.

**İki test türü ayrıldı:** unit/regresyon testleri bir sistemi doğrular
ve ilk açık seçeneği kullanabilir; **ürün simülasyonu**
(`product_simulation_test.dart`) gerçek oyuncuya benzer ve yalnızca ürün
dengesi tartışması için kullanılır. Raporları karıştırılmaz.

### Ölçüm: 1.500 tam hayat (10 arketip × 100 + 500 rastgele-geçerli)

Hepsi doğumdan ölüme; **1500/1500 hayat ölümle bitti, takılan sıfır**.

| Alan | Sonuç |
|---|---|
| Ortalama ölüm yaşı | 74,1 (medyan 77) |
| Üniversiteye giden / mezun | %48,5 / %48,4 |
| Bölüm çeşitliliği | 20/20 |
| Çalışan / emekli | %98,9 / %85,6 |
| Görülen meslek | 50/55 |
| Ortalama farklı iş / iş değişimi | 2,52 / 1,56 |
| Ölüm anı net servet (medyan) | 134,4M ₺ |
| Yatırım yapan | %92,1 |
| **Ev sahibi** | **%40,3** |
| Yatırım evi / kiraya veren | %28,3 / %28,3 |
| İş sahibi | %23,5 |
| Evlenen / boşanan / tekrar evlenen | %22,0 / %6,4 / **%0,0** |
| Çocuklu / ortalama çocuk / torun gören | %33,4 / 1,27 / %30,1 |
| Arkadaşı olan / küslük yaşayan | %51,4 / %43,8 |
| Sosyal medya açan | %43,3 |
| Kronik / check-up / spor | %74,2 / %97,4 / %99,4 |
| Sabıkalı / hapis yatan | %18,2 / %6,9 |
| **Olay havuzundan görülen** | **349/361 (%96,7)** |
| Hobi / dövüş sanatı / işletme türü | 11/12 · 6/6 · 9/13 |

**Arketip bazlı (medyan servet):** yatırımcı 231M · girişimci 178M ·
rastgele 163M · riskli 152M · kariyer 143M · eğitim 123M · spor 113M ·
rahat 111M · aile 102M · sosyal 25M.

### Simülasyon sırasında bulunan gerçek hatalar (hepsi bot tarafında)

1. **Yıl hiç bitmiyordu.** Eylemler bildirim üretiyor, ana döngü
   bildirimi kapatıp başa dönüyor ve aynı yıl eylemleri yeniden
   yapıyordu. Hayatların %25,6'sı 6000 turluk güvenlik sınırına çarpıyor
   ve ölçüme "ölmedi" diye giriyordu. Eylemler artık yaş başına bir kez.
2. **Bebeğe kendi adını verme sonsuz döngüsü.** `ChildNaming.rename`
   aynı adı değişiklik saymıyor, isim penceresi kapanmıyor ve bot her
   turda başa dönüyordu.
3. **Bekleyen düğün kapanmıyordu.** Doğru akış `holdWedding`; bot
   `marry` çağırıyordu ve iki hayat sonsuz döngüye girdi.
4. **Tek yılda üst üste konut kredisi.** Ev listesi boyunca her ev için
   ayrı kredi çekiliyordu; serveti şişiriyordu.
5. **Bot oyundan daha katıydı:** çocuk için evlilik şartı koyuyordu, oysa
   oyun sevgiliyle de izin veriyor (D-047). Düzeltilince "çocuklu" oranı
   %5,4 → %33,4 çıktı.
6. **Yanlış aktivite kimliği** (`check_up` yerine `genel_kontrol`):
   check-up oranı %0,0 ölçülüyordu, gerçekte %97,4.
7. **Bot hiç boşanmıyordu** → "boşanan %0,0" metriği anlamsızdı.
8. **Metrik tanımı hatası:** "mahkemeye çıkan" açılmış her dosyayı
   sayıyordu (%51); karara bağlanmış dosya ölçülünce %26,1.

### Dikkat çeken sonuçlar (karar Faho + ChatGPT'de)

* **Servet medyanı 134M ₺.** Sebebi bulundu ve bot hatası değil: yatırım
  getirisi bir ömür boyunca bileşik büyüyor ve oyunda anlamlı bir servet
  gideri yok. Bot portföyünü hiç harcamıyor; gerçek oyuncu harcar ama
  oyun bunu zorunlu kılmıyor.
* **Tekrar evlenen %0,0.** Boşanma sonrası yeni partner + yakınlık 45
  eşiği pratikte ulaşılamıyor.
* **Evlenen %22** ama partneri olan %94,9: evlilik dar bir kapı.
* **Sosyal arketip en yoksul** (25M) — yatırım yapmayan profil.
* **Hiç girilmeyen 5 meslek:** kurye, doktor, eczacı, yazar, yz_kurye.
* **Hiç görülmeyen 12 olay**, çoğu suç zinciri devamı ve araç olayları.
* **İşletme türü 9/13**: dört tür hiç kurulmuyor.

**Hiçbir denge değiştirilmedi.** Bu turda yalnızca test altyapısı
düzeltildi; oyunun sayılarına dokunulmadı.

### UI smoke life

10 uzun hayat **arayüzden** oynanıyor (`ui_smoke_life_test.dart`):
menüler açılıyor, sayfa kaydırılıyor, düğmeye basılıyor, pencere
seçiliyor, sekmeler geziliyor. Amaç "motor çalışıyor ama buton
ulaşılamıyor" hatasını yakalamak. 1.000 hayatın tamamını arayüzden
oynamak çok yavaş olurdu.

**Test durumu (gerçekten çalıştırıldı):** `flutter analyze` çıkış kodu 0;
`flutter test` tam takım geçiyor. **Gerçek cihazda oynanmadı.**

## Ürün simülasyonu kök neden analizi (27 Eylül 2026)

**Amaç:** son PlayerBot ölçümündeki altı aşırı sayıyı denge değiştirerek
"düzeltmek" değil, **nedenini ölçmek**. Bu turda oyun dengesinde bir tek
sabit, eşik, fiyat, getiri ya da şart **değişmedi**; kod da düzeltilmedi.
Ayrıntılı karar soruları `docs/DESIGN_REVIEW_QUEUE.md` **Q-167**'de.

**Gelen dosyalar:**
* `app/test/support/bot_diagnostics.dart` — `BotDiag` (servet bileşenleri,
  para akışları, evlilik hunisinin her basamağı, ayrılık sonrası huni,
  meslek/işletme uygunluğu, bot eylem sıklıkları) ve `BotOverrides`
  (teşhis için **botun tercihini** kapatır; oyunun sayılarına dokunmaz).
* `app/test/diagnosis_root_cause_test.dart` — 16 bölümlük rapor.
  1000 hayat (10 arketip × 100, hepsi ölümle bitti, takılan 0) + 5
  senaryo × 200 karşılaştırma + 500 hedefli ayrılık hayatı.
* `app/test/diagnosis_remarriage_lock_test.dart` — 9 test, tekrar evlenme
  %0'ın kök nedeninin **deterministik kanıtı**.

**Ölçüm bütünlüğü:** teşhis botun rastgele akışına dokunmuyor —
`product_simulation_test.dart` çıktısı teşhis eklendikten sonra **satır
satır aynı** kaldı (yalnızca geçen süre satırı değişti). `debugSetState`
ile para/stat/ilişki/ev/iş verilmedi.

**Bulunan sebepler (özet):**

| Soru | Sebep |
|---|---|
| Servet medyan ~134M | Net servetin **%97,8'i portföy**. Eğri hiçbir yaşta patlamıyor; her 5 yılda 1,34-1,94x büyüyor. Yatırımsız senaryo **0,150x**; yatırım yapmayan tek arketip (`social`) 20,7M ile ölüyor. |
| Gayrimenkul | Serveti **azaltıyor**: gayrimenkulsüz senaryo **1,202x**. "Ev al, bedava gelir" exploit'i yok, tersi var. |
| Miras / işletme | Etkisiz. 50M üstü hayatlarda mirasın payı **medyan %0,15**; işletmesiz senaryo 0,977x. |
| Q-165/5 (gider portföyden tahsil edilmiyor) | Ölçüldü ama **ana sebep değil**: korunan yıl medyan 2, ödenmeyen gider %8,2. Portföy/maliyet katı 6,6x. Sürükleyici gerçek getiri. |
| Partner %94,9 / evli %22 | İki kapı. (1) Bot yalnızca %47,1 evlenmek istiyor (**bot parametresi**). (2) İsteyenlerin **%49'u hiç sevgili edinemiyor** — bütün kayıp orada. Yakınlık 45 eşiği kayıp üretmiyor (%50,1 → %49,7); görülen en yüksek yakınlık medyan 100. |
| Tekrar evlenme %0 | **GERÇEK HATA.** `Finger` "evli mi" sorusunu `state.marriage != null` ile soruyor; boşanmada/dullukta kayıt bilerek silinmediği için bu koşul bir kez evlenen herkes için hayat boyu doğru. `finger.dart:443/552/680/711` romantik yolların hepsini kalıcı kapatıyor. `marryBlockReason` izin veriyor ama evlenecek sevgili edinilemiyor. |
| 5 girilmeyen meslek + 4 kurulmayan işletme + 12 görülmeyen olay | Büyük kısmı **tek bir bot eksiği**: PlayerBot hiç ehliyet almıyor (`applyForLicense` çağrılmıyor) → 2 meslek + 1 işletme + 5 olay kapanıyor. |

**Sevgili kapısının mekaniği:** Finger adaylarının %25'i baştan yalnızca
arkadaşlık istiyor (flört değil arkadaş üretir, D-107). Flört oluşursa
yakınlığı `rng.between(45, 62)`, resmîleştirme eşiği **60** → doğrudan
geçme ihtimali %16,7. Kalanı için flörtle vakit geçirmek gerekiyor ama
**bot flörtle hiç vakit geçirmiyor** (`_spendTimeWithFamily` listesinde
flört yok) ve ilgilenilmeyen flört Paket R ile bitiyor. Ölçüm: flört
edinen 412 hayatın **228'i (%55,3) hiç sevgiliye çevirmiyor** — huninin
228 kayıplık basamağıyla birebir aynı.

**Kendi ölçüm hatalarım (düzeltildi, raporda açıkça yazıyor):**
* Spor ve check-up'ı "bir kez yaptı mı" diye ölçmüştüm; on arketipte de
  %95-100 çıktı ve "bot fazla mekanik" diye yorumlamaya hazırdım. Yanlış
  metrikti: bot yılda bir profile bağlı zar atıyor, 57 yılda düşük
  olasılık bile doygunlaşıyor. Yıllık sıklıkla ölçünce arketipler
  ayrışıyor (spor/yıl 0,21-0,97).
* Eski eş kaydını "bağı artık `es` değil" diye ölçtüm, %37,7 çıktı ve
  kayıt bozuluyor sandım. Dullukta eş vefat eder ve bağı `es` kalabilir.
  Doğru ölçümle: kayıt korunma **%100**, boşanmada bağ güncellenme
  **%100**, yeniden bekâr sayılma **%100**. Kayıt yönetimi doğru.
* İlk yazımda `diag.wantedMarriage`'ı hayatın başında okumuştum;
  `_Intent`'in `late final` alanları erişim sırasına göre zar attığı için
  bu bütün niyet zarlarını kaydırdı (ölüm yaşı 74,1 → 74,2, üniversite
  %48,5 → %47,4). Teşhis akışa dokunmamalı; botun kendi okuduğu yere
  taşındı ve çıktı yeniden birebir aynı oldu.
* Evlilik hunisine monoton olmayan basamaklar koymuştum (bot niyeti,
  flört) ve tablo eksi kayıp yüzdesi basıyordu; ikisi huninin yanına
  ayrı bilgi olarak taşındı. "Uygun ama teklif etmeyen" oranını bütün
  korpusta ölçmüştüm (%48,6); neredeyse tamamı hiç evlenmek istememiş
  hayatlardı. Evlenmek isteyenlerde gerçek değer **%0,6**.

**Denge değişmedi.** Bot tarafındaki 7 eksik (ehliyet, flört kuru, Finger
niyeti, her fırsatta yatırım, sermaye birikmemesi, maaş süzgeci, herkesin
çalışması) ürün kararı değil; yine de düzeltilirse **bütün ürün
metrikleri değişeceği için** Faho'ya bildirilmeden dokunulmadı.

**Test durumu (gerçekten çalıştırıldı):** `flutter analyze` çıkış kodu 0;
`flutter test` tam takım geçiyor. **Gerçek cihazda oynanmadı.**

## Paket AC — yatırım riskleri, piyasa şokları ve servet dengesi V2 (27 Eylül 2026)

**Temel prensip:** botu zayıflatarak problem gizlenmedi, **oyun dengelendi**.
Gerçek oyuncu her yıl yatırım yapabilir; oyun ekonomisi o stratejiye
dayanmalı. Karar soruları `docs/DESIGN_REVIEW_QUEUE.md` **Q-168**'de.

**Gelen sistemler**

* **12 kurgusal şirket, 10 sektör** (`data/company_catalog.dart`). Hiçbiri
  gerçek değil; gerçek şirket/banka/fon/kurum/kişi adı geçmiyor.
* **Olay katmanı** (`domain/economy/incident_engine.dart`): konkordato,
  iflas, kayyum, yönetim skandalı, bilanço şoku, sermaye artırımı,
  temettü, satın alma haberi, sektör krizi/atağı, regülatör incelemesi.
  Şirket durumu **kademeli** ilerliyor — sağlıklı şirket tek yılda iflas
  etmiyor, oyuncu yolda haberleri görüyor.
* **İşlem sırasının kapanması**: kayyum/konkordato ve panikte alım **ve**
  satım 1-2 yıl duruyor. "Satayım kurtulayım" her zaman mümkün değil.
* **Fon riski**: yönetici değişimi, yanlış yatırım, strateji değişimi,
  birleşme, **tasfiye** (pozisyon piyasa değerinden nakde döner). Fon tek
  hisse gibi davranmıyor.
* **Çok yıllı kriz** (1-3 yıl) ve yeni **toparlanma** rejimi. "Krizde al,
  ertesi yıl kesin toparlar" garantisi kalktı: krizden doğrudan güçlü yıla
  atlanamıyor.
* **Faiz şoku** (%5/yıl) ve **kur şoku** (%7/yıl, **iki yönlü** — döviz
  her zaman kazanan değil).
* **Maliyetler**: alım-satım komisyonu %0,2, fon yönetim gideri %1,1/yıl,
  gerçekleşen kârdan %10 kesinti. Zararda kesinti yok, zarar mahsubu yok.
  Komisyon **maliyet esasına girmiyor**.
* **Zorunlu portföy satışı**: cüzdan geçim giderini karşılamazsa açık
  portföyden kapanıyor. Portföy artık görünmez kasa değil.
* **Yoğunlaşma riski**: tek riskli varlıkta toplanan portföy daha oynak.
  Çeşitlendirme kazanç garantisi vermiyor, yalnızca oynaklığı düşürüyor.
  **Yapay yatırım limiti yok** — isteyen parasının tamamını yatırıyor.
* **24 yeni piyasa/şirket olayı** (`data/event_pool_market.dart`).
  Hiçbirinde "şunu al kesin yükselir" yok; hiçbir seçenek doğru cevap
  değil.

**Ölçüm (40.000 piyasa yılı)**

Rejim: normal %45,0 · durgun %24,8 · güçlü %20,3 · kriz %7,5 ·
toparlanma %2,4. Kriz bölümü ortalama **2,09 yıl**, en uzun 6.
Şirket batışı yıllık **%0,64**. İşlem kapalı yıl %4,5. Olay görülen yıl
%31,1 — çoğu yıl sessiz.

Yıllık getiri: hisse %9,2 (std %24,8) > fon %7,5 > altın %6,9 >
döviz %6,4 > vadeli %6,0. **Risk merdiveni doğru.** 20 yıllık yolda
anaparanın altında bitme: hisse %19,3 · fon %3,4 · altın %0,4 ·
döviz %0,1 — hiçbir tür risksiz değil.

**Min-max oyuncu (8 strateji × 20/40/60 yıl, 3.000 strateji hayatı)**

60 yılda yatırımın kendi getirisi (maaş karışmaz): %100 hisse medyan
7,41x, kötü%10 **0,69x**, yatırım zarar ettiren **%13,6**. Sadece altın
18,23x. Yatırım yapmayan hiçbir hayatta 50M'ye ulaşmıyor; yatırım yapan
stratejilerde 50M+ %57-76.

**Paket AC öncesi / sonrası (aynı tohumlar)**

| Ölçü | Önce | Sonra |
|---|---|---|
| Ürün simülasyonu medyan net servet | 134.365k ₺ | **97.250k ₺** (−%27,6) |
| Teşhis korpusu medyan servet | 122.254k ₺ | 88.541k ₺ (−%27,6) |
| Portföyün servetteki payı | %97,8 | %95,8 |
| Tekrar evlenen | %0,0 | **%0,5** |

**Tekrar evlenme bug fix (Q-167/3 kapandı)**

`finger.dart`'ta dört yerde ve `life_progression.dart:1696`'da
`state.marriage != null` yerine **`state.isMarried`** kullanılıyor artık.
Boşanmada/dullukta evlilik kaydı bilerek silinmediği için eski koşul bir
kez evlenen herkes için hayat boyu doğruydu ve bütün romantik yollar
kalıcı kapanıyordu. `PlayerBot`'ta da aynı hata vardı (teklif kapısı).
Ayrılık sonrası huni: yeni flört %0,0 → **%47,5**, yeni sevgili → %8,5,
tekrar evlenme → **%5,7** (teşhis korpusu). Yeni regresyon testi tam
oyuncu yolunu yürüyor: **iki eşin ikisi de Finger'dan geliyor**, elle
sevgili enjekte edilmiyor.

**Bulunan yeni defekt: kontrolsüz borç büyümesi**

`banking.dart advanceYear`: ödenmeyen taksitte borç her yıl faiziyle
büyüyor ama `remainingPayments` azalmıyor ve hiçbir haciz/yapılandırma/
silme mekanizması yok. Kredi hiç kapanmıyor. Ölçümde bir hayatta
**1.788.495k ₺ borç** ve **−1.601.336k ₺ net servet** çıktı (125 hayatta
1). **Düzeltilmedi**: doğru çözüm ürün kararı (Q-168/10).

**Saldırgan oyuncu taraması: exploit bulunamadı.** Kayıt geri yükleyip
piyasayı yeniden çevirmek, aynı yılı tekrar ilerletmek, al-sat döngüsü,
kredi arbitrajı, parayı portföye saklayıp boşanma payından kaçmak, ikinci
boşanma, aynı mirası iki kez almak, kapalı sırada zorunlu satışla çıkmak,
vadeli aç-boz döngüsü — hepsi engelli. Al-sat döngüsü 20 turda 1.000k →
923k **kaybettiriyor**.

**Düzeltilen kendi hatalarım (ölçümle bulundu, raporda yazılı)**

* Krizi çok yıllı yapmak kriz yıllarını %8'den **%17,8'e** çıkardı ve
  risk merdivenini tersine çevirdi (hisse %6,4 < altın %7,9). Krize giriş
  ihtimali yarıya indirildi: kriz **daha uzun ama daha seyrek**, payı
  korundu, merdiven düzeldi.
* Korunma primi her kriz yılında tekrar uygulanıyordu; **Döviz Sepeti'nde
  1.000 yirmi yıllık yolun hiçbiri anaparanın altında bitmiyordu**.
  Güvenli limana kaçış krizin **başında** olur: uzayan kriz yılında prim
  eriyor, toparlanmada geri veriliyor.
* Kriz kilidinde bire bir kaydırma hatası: ortalama 3,13 yıl, en uzun 11
  çıkıyordu. Düzeltilince 2,09 / 6 oldu.
* Yoğunlaşma zammı **bütün getiriyi** çarpıyordu, yani eğilimi de: yoğun
  portföyün beklenen getirisi yükseliyordu. Ölçümde bir hayat **10,2
  milyar ₺** ile öldü ve AA'nın bekçisi kırıldı. Doğrusu yalnızca
  eğilimden sapmayı büyütmek.
* "Başlangıç parasının altında bitti" ölçüsünü strateji riski sanmıştım;
  bu hayatlar 60 yıl maaş da alıyor, o yüzden neredeyse hiç gerçekleşmiyor
  ve "%100 hisse hiç kaybetmiyor" diye okunacaktı. Doğru ölçü yatırımın
  kendi getirisi: (portföy + gerçekleşen kâr) / anapara.

**Bilerek yapılmayanlar**

* **Nominal enflasyon motoru (§18):** kurulmadı, yalnızca mimari
  raporlandı (Q-168). Sadece yatırım fiyatını nominal büyütmek yasaktı ve
  yapılmadı. Asıl mesele şu: **%9,2 reel getiri 60 yılda ~200 kat eder.**
  Risk katmanı medyanı %27,6 düşürdü ama üst kuyruk **eğilim × ufuk**
  çarpımından geliyor; olay katmanı onu tek başına çözemez.
* **Tekil hisse (§10):** karma sepetle tek şirket riski karıştırılmadı;
  ayrı paket önerisi olarak bırakıldı.
* **Geçim gideri seçenekli akışı (§19):** zorunlu satış otomatik yapıldı.
  Üç seçenekli akış yeni bir bekleyen pencere demek ve teşhis turunda
  bekleyen pencerelerin gerçek kilitlenme riski ölçülmüştü.

**Denge sayıları değişmedi:** yatırım eğilimleri (hisse %10, fon %8,
altın %7, döviz %6,5, vadeli %6) **aynı**. Değişen şey riskin kendisi.

**Test durumu (gerçekten çalıştırıldı):** `flutter analyze` çıkış kodu 0;
`flutter test` **2549 geçti, 15 atlandı, 0 başarısız**. **Gerçek cihazda
oynanmadı.**

## Paket AD (1/6) — oyunun kendi ekonomisi: sabit getiri eğilimi kaldırıldı (27 Eylül 2026)

Faho'nun "EKONOMİ TASARIM PRENSİBİ REVİZYONU" briefinin **§1-§6 ve
§22-§23** kısmı. Kalan altı başlık (§7-§21) ayrı turlarda; aşağıda
"yapılmayanlar" olarak açıkça yazılı. Sorular `docs/DESIGN_REVIEW_QUEUE.md`
**Q-169**'da; `DECISIONS.md`'ye kesin kural **yazılmadı**.

**Kesin olan (§2, Faho'nun açık yetkisi):** "Yatırım türlerinin SABİT
POZİTİF DRIFT garantisi olmasın." Bu, Q-168/1'de bekleyen soruyu kapattı.

### Ne yapıldı

- **`drift` alanı kaldırıldı.** Yerine `carry` (varlığın *ürettiği* akış:
  hisse %2,8 · fon %2,2 · **altın 0** · **döviz 0** · vadeli %3) ve
  `annualFee` (fonda %1,4 yönetim ücreti) geldi.
- **Vadeli %6 → %3.** §11: ana işlevi nakdi korumak, servet büyütmek değil.
- **Değerleme ısısı** (`MarketState.valuationHeat`, 0-100, gizli): pahalı
  varlığın beklentisi düşer, balon kırılma zarı atılır; ucuzlayanda tersi.
- **Çağ gelgiti** (`MarketState.riskTide` / `hedgeTide`, gizli): hayat
  ölçeğinde yavaş (yarı ömür ~11 yıl), ortalaması sıfır eğilim. §4'ün tek
  gerçek çözümü — aşağıya bak.
- **Risk primi rejim sıklığından doğuyor**, tür başına yazılı sayı değil.
- Banka ekranındaki oyuncuya görünen **"2026" ifadesi kaldırıldı**;
  `docs/ECONOMY_2026.md` tarihsel araştırma notu olarak işaretlendi.
  Denetimde production ekonomi kodunda gerçek tarihe bağlı **hiçbir hesap
  bulunmadı** (`DateTime.now()` yalnızca ses soğuması ve kayıt zaman
  damgası).

### Kalibrasyon sırasında bulunan iki gerçek sorun

Ikisi de ölçümle bulundu, tahminle değil.

1. **Tek yönlü balon sistematik vergiye dönüşüyordu.** Yalnızca "balon
   kırılması" varken altın yıllık ortalama **%-0,3**, hisse geometrik
   **%-0,2** ölçüldü: "uzun vadede kesin zengin" sorunu "uzun vadede kesin
   batık" sorununa dönmüştü. Aynası eklendi (dipte sert toparlanma zarı).
2. **§6 ile §4 birbirine çalışıyor.** Balon mekaniği yıllık getirilere eksi
   otokorelasyon veriyor ve uzun vadeli ortalamanın dağılımını
   *sıkıştırıyor*: 40 yıllık log ortalamanın standart sapması bağımsız
   yıllar varsayımıyla %3,87 olmalıyken **%2,39** ölçüldü. Bu yüzden 40 yıl
   hisse tutanın en kötü %10'u bile 2,47 kat yapıyordu. Çağ gelgiti bu
   sıkışmayı dengelemek için eklendi ve genliği ölçümle büyütüldü.

### Ölçüm (`app/test/paket_ad_measure_test.dart`, gerçekten çalıştırıldı)

Yıllık, 60.000 yıl, tek varlık:

| Tür | ortalama | geometrik | stdev | eksi kapanan yıl |
|---|---|---|---|---|
| altın | %4,0 | %3,4 | %11,8 | %37 |
| döviz | %3,7 | %3,2 | %10,6 | %37 |
| fon | %5,3 | %4,5 | %12,6 | %34 |
| hisse | %9,2 | %6,5 | %23,1 | %34 |

Tek varlığa yatırıp hiç dokunmamak (1000 yol, oyunun sürtünmesi **hariç**):

| Yıl | Tür | Medyan | Kötü %10 | Anapara altı |
|---|---|---|---|---|
| 40 | hisse | 15,25x | 1,61x | **%5,0** (önce %2,9) |
| 60 | altın | 7,42x | 2,26x | %1,2 (**önce medyan 18x**) |

60 yıllık bot stratejileri (yatırımın kendi getirisi, sürtünme **dahil**):

| Strateji | Medyan kat | Kötü %10 | Zarar eden |
|---|---|---|---|
| %100 hisse | 4,85x | 0,49x | **%16,8** |
| sadece altın | 3,97x | 1,04x | %7,2 |
| dengeli (4 varlık) | 2,50x | 1,23x | %3,2 |

Artık hisse **en yüksek medyanı ve en kötü tabanı** birlikte veriyor; altın
arada; dengeli en güvenli. Hiçbir strateji baskın değil (§12).

### Bu turda bilerek yapılmayanlar

- **§7-§9 şirket sağlık modeli** (gizli sağlık, kaldıraç, büyüme, yönetim
  kalitesi) — AD/2.
- **§16 kontrolsüz borç düzeltmesi** — AD/4. Faho yetki verdi, ayrı tur.
- **§13 servetin kullanımı / harcama kanalları** — AD/5.
- **§18-§21 on strateji × 20/40/60 kalibrasyonu** — AD/6. **§18'in dağılım
  hedefi (normal oyuncu milyonlar · milyarderlik çok nadir) henüz
  doğrulanmadı.**
- Enflasyon motoru — Q-168'de duruyor.

**Test durumu (gerçekten çalıştırıldı):** `flutter analyze` çıkış kodu 0;
`flutter test` **2552 geçti, 15 atlandı, 0 başarısız**. **Gerçek cihazda
oynanmadı; Android APK bu makinede derlenmedi.**

## Paket AD (2/6) — borç yaşam döngüsü: kontrolsüz borç bug'ı düzeltildi (28 Eylül 2026)

Faho'nun "PAKET AD DEVAM" briefinin **§8-§11 ve §24** kısmı. Sorular
`docs/DESIGN_REVIEW_QUEUE.md` **Q-170**'te; `DECISIONS.md`'ye kesin kural
**yazılmadı**.

### Hatanın ölçülen hâli

₺200.000 kredi, cüzdan sıfır, 60 yıl: borç 20. yılda 9,7 milyar, 40. yılda
474 trilyon, 60. yılda **9.223.372.036.854.775.807** — yani `int`in tepesi.
Bu bir **tamsayı taşması**, sadece çirkin bir kuyruk değil.
`remainingPayments` hiç azalmıyor; kredi ölümsüz.

Aynı satırda iki hata daha: büyüme `l.bank.yearlyRate` ile hesaplanıyor ve
`purpose`'u yok sayıyordu (ödenmeyen **konut** kredisi ihtiyaç kredisi
oranıyla büyüyordu), ve taksitin %90'ı cüzdanda olsa bile hiç ödeme
yapılmıyordu.

### Gelen yaşam döngüsü

`normal → gecikme → ciddi gecikme → tahsil → yapılandırma → kapanış`.
Kısmi ödeme var; 2. kaçakta banka portföye ve **oturulmayan** mala uzanır;
3. kaçakta borç donup taksite bölünür (en fazla iki kez); gecikme faizi
baştan borçlanılan tutarın **iki katını** geçmez; hak bittiyse borç zarar
yazılıp kapanır; kredi notu izi on yıl sayılıp siliniyor (§11: ömür boyu
yasak yok). **Oturulan ev hiçbir koşulda satılmıyor**, mal satışı en
küçükten başlıyor.

### Ölçüm (1000 borçlu hayat, 60 yıl — gerçekten çalıştırıldı)

| Ölçüm | Değer |
|---|---|
| Gecikme gören | %99,7 |
| Zorunlu tahsil gören | %66,3 |
| Yapılandırma gören | %33,2 |
| Zarar yazılarak kapanan | %33,2 |
| **Hiç kapanmayan** | **0** |
| Kapanma süresi | medyan 6 yıl · en uzun 16 |
| Görülen en büyük borç | medyan 388.540 · **en büyük 997.780** |

### Kalibrasyonda düzelttiğim kendi hatalarım

1. **Yapılandırma rahatlatmak yerine hızlandırıyordu**: şişmiş borca yeniden
   bileşik faiz bindiği için taksit ₺90.000 → ₺725.651 → ₺3.647.779 oluyordu.
   Doğrusu borcun donup vadeye bölünmesi (₺90.000 → ₺40.000 → ₺26.667).
2. **Tahsil testim boştu**: taze üretilen hayatın hiç eşyası olmadığını fark
   etmemişim, "oturulan ev satılmadı" testi hiçbir şeyi kanıtlamıyordu ve
   ölçümde tahsil %0,0 çıkıyordu. Gerçek mal veren yardımcı yazıldı → %66,3.
3. Gecikme faizi tavanını **anaparaya** bağlamıştım; `outstanding` baştan
   anapara değil vade boyunca ödenecek toplam olduğu için tavan borcu kendi
   başlangıç bakiyesinin altına kırpıyordu ve mevcut bir test haklı olarak
   kırıldı. Çıpa `Loan.originalDebt` oldu. **Test gevşetilmedi.**

**Test durumu (gerçekten çalıştırıldı):** `flutter analyze` çıkış kodu 0;
`flutter test` **2562 geçti, 15 atlandı, 0 başarısız**. **Gerçek cihazda
oynanmadı; Android APK bu makinede derlenmedi.**

## Paket AD (3/6) — şirket sağlık modeli (28 Eylül 2026)

Faho'nun "PAKET AD DEVAM" briefinin **AD/2 (§1-§5) ve §23** kısmı. Sorular
`docs/DESIGN_REVIEW_QUEUE.md` **Q-171**'de; `DECISIONS.md`'ye kesin kural
**yazılmadı**.

### Ne geldi

Her kurgusal şirketin beş **gizli, kalıcı, yıldan yıla değişen** göstergesi
var (mali sağlık, borç baskısı, büyüme, yönetim kalitesi, güven) ve on
sektörün kendi gücü. Hepsi kayda giriyor, hiçbiri oyuncuya sayı olarak
gösterilmiyor.

Olaylar artık bunlardan doğuyor: hangi şirketin habere konu olacağı,
haberin iyi mi kötü mü olacağı, krizden çıkma ihtimali (yönetim kalitesi)
ve hangi sektörün kriz/atak yaşayacağı. 24 olayın yedisi şirketin **gerçek
durumuna** kapılı — oyuncu sapasağlam bir şirket için konkordato haberi
okuyamıyor.

Kapanan şirketin sepetteki payını dört yıl sonra **yeni bir ad** devralıyor
(altı yedek kurgusal şirket). Kapanan şirket geri dönmüyor.

### Bulduğum yapısal kusur (Paket AC'den kalma)

1200 yıllık ilk ölçümde şirketlerin yalnızca **%31'i normal**, %68'i kalıcı
sıkıntılı çıktı. Sebep: şirketin durumu yalnızca **olaya konu olduğunda**
değişiyordu ve bir şirket ortalama yetmiş yılda bir seçiliyor; kötüleşme
tam iyileşmeden olası olduğu için durumlar yutucu hâle geliyordu. Oyun
kuşaklar arası devam ettiği için bu, ilerleyen kayıtlarda "bütün şirketler
hasta" demek. Çözüm: göstergeleri düzelen şirket **sessizce** bir kademe
iyileşebiliyor. Kötü haber her zaman duyurulur, iyi haber sessiz olabilir.

İlk denemede fazla cömert davrandım (eşik 0,50) ve kapanma 1200 yılda 1'e
düştü — Paket AC'nin eklediği riski kendi elimle söndürüyordum. Eşiği
ölçümle 0,44'e çektim.

### Ölçüm (14.396 şirket-yılı — gerçekten çalıştırıldı)

| Durum | Pay |
|---|---|
| normal | %65,8 |
| inceleme | %22,1 |
| sıkıntı | %10,1 |
| kayyum | %0,6 |
| konkordato | %0,2 |

Geçişler (1200 yıl): kötüleşen 79 · toparlanan 18 · kapanan 3 · yerine gelen
yeni şirket 3. Durum değişimi şirket-yıllarının **%0,8'i**. 200 tek yıllık
koşuda **normalden doğrudan kapanan şirket 0**.

**Test durumu (gerçekten çalıştırıldı):** `flutter analyze` çıkış kodu 0;
`flutter test` **2571 geçti, 15 atlandı, 0 başarısız**. **Gerçek cihazda
oynanmadı; Android APK bu makinede derlenmedi.**

## Paket AD (4/6) — yatırım kararları gerçek oldu (28 Eylül 2026)

Faho'nun "PAKET AD DEVAM" briefinin **AD/3 (§6, §7)** kısmı. Sorular
`docs/DESIGN_REVIEW_QUEUE.md` **Q-172**'de.

### Bulduğum sorun

Paket AC panik, balon ve şirket olaylarını getirmişti ama **seçeneklerinin
tek etkisi mutluluktu**: "sat", "bekle", "al" seçmek portföyde hiçbir şey
değiştirmiyordu. Karar değil, süslü metindi. Ayrıca panik olayı sapasağlam
bir yılda, FOMO olayı soğuk bir piyasada çıkabiliyordu.

### Ne yapıldı

`EventChoice` artık portföy hamlesi taşıyabiliyor (kısmi sat, kısmi al, kâr
al) ve hamle `InvestmentEngine`'in kendi al/sat yollarından geçiyor —
komisyon, kesinti, işlem durması ve maliyet esası aynen işliyor. İkinci bir
ekonomi motoru kurulmadı. Hamle başarısız olabilir (işlem durmuş, para yok,
zararda kâr alınamaz).

Panik ve devre kesici olayları **gerçek kriz**, FOMO olayı **gerçek ısı**
ister. Konkordato ve bilanço şoku olaylarına "azalt" / "çık" seçenekleri
eklendi.

### Ölçüm (gerçekten çalıştırıldı)

500 panik yolunda, panikte %35 satan ile hiç dokunmayan on yıl sonra
karşılaştırıldı: **satan 154, bekleyen 346**. Panikte satmak çoğu zaman
yanlış ama %31 oranında doğru — tek doğru cevap yok. 29 finansal olayın
hepsinde en az beş yıl tekrar aralığı var: bildirim yağmuru yok.

**Test durumu (gerçekten çalıştırıldı):** `flutter analyze` çıkış kodu 0;
`flutter test` **2578 geçti, 15 atlandı, 0 başarısız**. **Gerçek cihazda
oynanmadı; Android APK bu makinede derlenmedi.**

## Paket AD (5/6) — servetin kullanımı (28 Eylül 2026)

Faho'nun "PAKET AD DEVAM" briefinin **AD/5 (§12-§17)** kısmı. Sorular
`docs/DESIGN_REVIEW_QUEUE.md` **Q-173**'te.

### Denetimin bulduğu sorun

Oyundaki en pahalı şey **₺16.000.000'luk villaydı**; diğer kategorilerin
tepesi önemsiz (saat ₺28.000, takı ₺42.000). Oysa altmış yıl yatırım yapanın
portföyü ₺30.000.000'u aşıyor. Paranın harcanacak yeri olmayınca "her şeyi
yatır" doğal olarak tek akıllı strateji oluyor.

### Ne geldi

- **Lüks katman:** yazlık (₺6,2M-₺145M), tekne (₺4,8M-₺38M), koleksiyon
  (₺3,1M-₺22M). Tavan ₺16M'dan **₺145M'a** çıktı. Hepsi normal eşya: net
  servete giriyor, boşanmada paylaşılıyor, mirasa kalıyor, borç tahsilinde
  satılabiliyor.
- **Servet kapısı:** üç yeni mağaza ve "Lüks ve koleksiyon" öbeği. Eşiğin
  altındaki oyuncu kategoriyi görmüyor (koleksiyon ₺8M · yazlık ₺12M ·
  marina ₺25M).
- **Bakım masrafı:** yazlık %1,2 · tekne %5,5 · koleksiyon %0,8; araç
  giderleriyle aynı mantıkta, gider dökümünde ayrı satır. Motoryat sahibinin
  yıllık gideri ₺12.000 → ₺2.102.000.
- **Yapay zengin vergisi yok:** cüzdanında ₺400.000.000 olan ama malı
  olmayan oyuncunun gideri değişmiyor. Testle sabitlendi.
- **Servet seviyesine açılan beş olay:** aile para istiyor (≥₺2M), çocuğun
  eğitimi (≥₺3M), uzun tatil (≥₺5M), bağış (≥₺10M), özel etkinlik (≥₺20M).
  Sağlık masrafı 55 yaş üstü, ağırlık 3, tekrar aralığı 12 yıl — nadir.

### Kırılan üç test de gerçek bir şeyi yakaladı

1. Bağış olayının bir seçeneğini **etkisiz** yazmışım; mevcut kural haklıydı.
2. "Her mağaza kategorisi açık" iddiası servet kapısıyla çelişiyordu; test
   yeni kuralı öğrenecek biçimde güncellendi ve üstüne "eşiğin altında
   kapalı" iddiası **eklendi**.
3. Mağaza öbeği testi "Konut" başlığının ekranda kalmasına bel bağlıyordu;
   liste uzayınca kırıldı, her başlığa ayrı kaydırılacak biçimde düzeltildi.

İki tohuma çakılı test de kaydı (EKSIKLER §6): tekrar evlenme tam yolu
60→240 tohum, kuşak senaryosu 32→33. 30-80 aralığında **32 dışındaki 48
tohumun hepsi çalışıyor**. Hiçbir iddia gevşetilmedi.

**Test durumu (gerçekten çalıştırıldı):** `flutter analyze` çıkış kodu 0;
`flutter test` **2584 geçti, 15 atlandı, 0 başarısız**. **Gerçek cihazda
oynanmadı; Android APK bu makinede derlenmedi.**

## Paket AD (6/6) — strateji kalibrasyonu · **AD TAMAMLANDI** (28 Eylül 2026)

Faho'nun "PAKET AD DEVAM" briefinin **AD/6 (§18-§22)** kısmı. Sorular
`docs/DESIGN_REVIEW_QUEUE.md` **Q-174**'te; `DECISIONS.md`'ye kesin kural
**yazılmadı**.

### Bulduğum asıl hata: "ceza" diye yazdığım şey piyango biletiymiş

30.000 yolluk ilk tam ölçümde 60 yıllık %100 hisse stratejisi: en iyi %10
**₺1.558M**, görülen en yüksek **₺211.732M**, milyarder payı **%12,7**.

Sebep Paket AC'den kalma yoğunlaşma mekanizmasıydı: tek varlığa yığılan
portföyde getirinin **sapmasını** 1,55 ile çarpıyor ve yorumunda "beklenen
değer kaymaz" yazıyordu. **Bunu ben yazmıştım ve tek yıl için doğru,
bileşik servet için değil.** Sapmayı büyütmek yıllık oynaklığı %23'ten
~%36'ya çıkarıyor; altmış yıl bileşiklenince medyanı düşürürken üst kuyruğu
patlatıyor.

Düzeltme: yoğunlaşma artık **beklenen getiriyi de düşürüyor** (§9),
oynaklık zammı 0,55 → 0,25, risk primi 0,056 → 0,048.

| %100 hisse, 60 yıl | Başlangıç | Sonra |
|---|---|---|
| iyi %10 | ₺1.558M | **₺371M** |
| görülen en yüksek | ₺211.732M | **₺7.460M** |
| milyarder payı | %12,7 | **%3,8** |

2000 tam hayat: medyan ₺62,0M → **₺50,9M**, milyarder %2,5 → **%1,3**,
en yüksek ₺396.089M → **₺38.103M**.

### §22 — BULUNAN DOMİNANT STRATEJİ (Faho'nun kararı gerekiyor)

**`girişim + yatırım` diğer dokuzunun hepsini, her ufukta, hem medyanda hem
en kötü %10'da geçiyor** (60 yıl: medyan ₺52,2M, kötü%10 ₺10,4M — ikisi de
listenin tepesi). İşletme, yatırımın üstüne bedava bir kat ekliyor.

Bu pakette işletme dengesine **dokunulmadı**: işletme ekonomisi Paket U'da
kalibre edildi, değiştirmek ayrı bir ürün kararı (Q-174/1). Bekçi bulguyu
dondurdu; yeni bir baskın strateji çıkarsa test kırılır. Piyasa
stratejileri arasında baskın yok.

### Botu güçlendirdim, zayıflatmadım (§18)

Ehliyet (en büyük tek eksik: 2 meslek + 1 işletme + 5 olay), Finger niyeti,
flörtle vakit geçirme. Ehliyette gerçek bir hata buldum: ilk kurulumumda
yılda bir soru cevaplıyordum ve 60 hayatın 34'ü sınava girip **hiçbiri**
geçemiyordu (rastgele tahminin beklediği %26'nın çok altında) — sınav üç
soruluk, yıllara yayılınca cevaplar düşüyordu. Tek oturuşta bitirilince 34
denemenin 30'u ehliyet alıyor.

Stratejiler 8 → 10 (`sadece fon`, `karma normal oyuncu`). Min-max
stratejiler olduğu gibi duruyor.

### Ölçümün iki kademesi

Ağır ölçüm (30.000 yol + 2000 tam hayat, ~25 dakika) `BIR_OMUR_FULL_MEASURE=1`
ile açılıyor — depodaki golden testlerle aynı kalıp. Her turda çalışan
sürüm aynı kodu daha az yolla koşup bekçi görevi yapıyor.

**Test durumu (gerçekten çalıştırıldı):** `flutter analyze` çıkış kodu 0;
`flutter test` **2586 geçti, 15 atlandı, 0 başarısız**. Ağır ölçüm elle
çalıştırıldı. **Gerçek cihazda oynanmadı; Android APK bu makinede
derlenmedi.**

---

## PAKET AD TAMAMLANDI (1/6 … 6/6)

| Paket | Konu | Commit |
|---|---|---|
| AD/1 | Sabit getiri eğilimi kaldırıldı, getiri piyasadan doğuyor | `1c75f41` |
| AD/2 | Borç yaşam döngüsü (kontrolsüz borç bug'ı) | `7f965a5` |
| AD/3 | Şirket sağlık modeli | `2065baa` |
| AD/4 | Yatırım kararları gerçek oldu (panik, FOMO) | `7324ce1` |
| AD/5 | Servetin kullanımı (lüks katman, harcama kanalları) | `766c90a` |
| AD/6 | Strateji kalibrasyonu | `d3db879` + bu commit |

**Bulunan gerçek buglar:** kontrolsüz borç (int taşması, ₺9,2×10¹⁸),
ödenmeyen konut kredisinin ihtiyaç kredisi faiziyle büyümesi, all-or-nothing
taksit, şirket durumlarının yutucu olması, olay seçimlerinin portföyde hiçbir
şey yapmaması, yoğunlaşma cezasının piyango bileti olması, botun ehliyet
sınavını hiç geçememesi.

**§25 tarih bağımsızlığı doğrulandı:** production ekonomi kodunda
`DateTime.now()` kullanımı **yok** (yalnızca ses soğuması ve kayıt zaman
damgası); oyuncuya gösterilen hiçbir metinde gerçek dünya yılı **yok**;
`lib/` altındaki bütün "2026" geçişleri yorum satırı.

**§27 saldırgan oyuncu taraması: EXPLOIT BULUNAMADI.** Paket AD'nin dört
yeni sistemine sekiz saldırı denendi ve hepsi engellendi — sınırsız
yapılandırma (2'de duruyor, kredi kapanıyor), malı satıp borcu iki kez
kapatmak (net servet 300k → 150k, zorunlu satış zarar ettiriyor),
kayıt/yükleme ile borç durumunu sıfırlamak (aynen korunuyor), olay
hamlesiyle işlem durmasını delmek (portföy değişmiyor), olay hamlesiyle
komisyonsuz al-sat döngüsü (20 turda ₺20.899 kaybettiriyor), lüks varlığı
zorla satarak para üretmek (₺37,7M → ₺28,2M), kredi notu izini kayıtla
temizlemek (iz duruyor), şirket durumunu kayıtla yeniden çevirmek (aynen
çıkıyor).

**Karar bekleyen sorular:** Q-169 … Q-174. `DECISIONS.md`'ye hiçbir kesin
kural yazılmadı.

---

## PAKET AE TAMAMLANDI (1/6 … 6/6)

**Konu:** Girişimcilik V2 — işletme yönetimi, fiyat, müşteri, personel ve
krizler.

**Neden:** AD/6 ölçümünde `girişim + yatırım` diğer dokuz stratejiyi
birden eziyordu (Q-174/1). Çözüm işletme kârını yapay olarak kesmek
değil, işletmeyi gerçek bir **oyun sistemi** hâline getirmekti: oyuncu iş
kurunca "her yıl otomatik kâr alan kişi" değil, işini yöneten bir işletme
sahibi olsun.

| Paket | Konu |
|---|---|
| AE/1 | İşletme veri modeli: fiyat, itibar, personel, bakım, reklam, 5 yıllık döküm |
| AE/2 | Talep ve kâr motoru: bölge ortalaması, elastikiyet, gider kalemleri |
| AE/3 | 70+ işletme olayı, kalıcı rekabet baskısı, afet ve denetim |
| AE/4 | Yatırım önemli olay bildirimleri ve sert düşüş ölçümü |
| AE/5 | İşletme ekranı ve yıllık rapor |
| AE/6 | Pasif/aktif/girişim+yatırım ölçümü, fiyat ve reklam exploit taraması |

**Katalog 14 işletmeye çıktı:** Oto yıkama eklendi. Her işletmenin kendi
sattığı şey ve fiyat başlığı var (halı sahada "Maç / saat ücreti",
kuaförde "Saç kesim ortalaması"). Bölge ortalaması şehirden, ekonomi
rejiminden ve kurgusal rekabetten üretiliyor — **gerçek yıla ya da gerçek
fiyata bağlı değil** (§3, §25).

**Bulunan altı gerçek bug (hepsi ölçümle yakalandı):**

1. `condition` talebe neredeyse hiç etki etmiyordu — durumu 10/100 olan
   büfe hâlâ kâr ediyordu.
2. Fiyat exploit'i: sabit esneklikli talep eğrisinde esneklik 1'in altında
   kalan her işte "fiyatı sonuna kadar yükselt" mutlak baskındı; 14
   işletmenin 10'unda en pahalı seçenek kazanıyordu.
3. `IncidentKind.opensNotice` AC'den beri tanımlıydı ama hiçbir yerde
   okunmuyordu: konkordato, kayyum, şirket kapanması sessizce geçiyordu.
4. Reklam tuzaktı: kampanya sonsuza kadar sürüyor, azalan marjinal etki
   yüzünden bedeli her işletmede katkısını aşıyordu.
5. Katalogdaki `volatility` kâra hiç yansımıyordu — lokanta (0,60) ile
   terzi (0,25) aynı oynaklıkta davranıyordu.
6. İyi yönetilen işletme risksizdi: aktif sahibin kapanma oranı **%0** ve
   `isletme aktif` oyunun en güvenli stratejisiydi.

**§32 — dominans, AD/6'dan bu yana:**

| Ölçü | AE öncesi | AE sonrası |
|---|---|---|
| `girişim + yatırım`ın her ölçüde ezdiği strateji | 10 / 11 | **6 / 11** |
| kötü %10 | ₺13,2M | **₺8,0M** |
| medyan | ₺71,5M | ₺65,1M |
| aktif sahibin işletme kapanma oranı | %0 | **%9** |

Medyanda hâlâ birinci; §32 bunu yasaklamıyor ("Başarılı işletmeci çok para
kazanabilir"), yasak olan her koşulda ezmesi. Magnitude sorusu Faho'ya
Q-175/4 olarak soruldu.

**§34 fiyat exploit taraması:** optimum 14 işletmede piyasa 10 / ucuz 3 /
pahalı 1. Ne en pahalı ne en ucuz her zaman kazanmıyor; optimum
işletmenin itibarına göre de kayıyor.

**§35 reklam exploit taraması:** büyük kampanya ortalamada 14 işletmenin
9'unda kazandırıyor ama **tek tek hayatların %26,2'sinde para
kaybettiriyor** — garanti değil.

**§27 sert düşüş:** %100 hisse portföyünde 6600 yılın %16,3'ü ≥%20, %9,6'sı
≥%30, %5,1'i ≥%40 düşüyor. Dağıtılmış portföyde ≥%20 oranı %1,89. Bu
dağılım AD/1'in onaylı kalibrasyonundan doğuyor; AE'de değiştirilmedi ve
Q-175/2 olarak soruldu.

**§23/§36:** 8.784 işletme-yılı işlendi (ağır ölçümde daha fazla), 283
erken kapanma. Kayıt tamamen additive; eski kayıt varsayılanla açılıyor.

**Karar bekleyen sorular:** Q-169 … Q-175. `DECISIONS.md`'ye hiçbir kesin
kural yazılmadı.

**Doğrulanmayan:** Gerçek cihazda oynanmadı; Android APK bu makinede
derlenmedi.

---

## PAKET AF — TEŞHİS TAMAMLANDI (denge değiştirilmedi)

**Konu:** "Oyunu çözen akıllı oyuncu girişim + yatırım ile ekonomiyi
kırıyor mu?"

**Bu tur ölçümdür.** Hiçbir denge değeri değiştirilmedi; Faho'nun kararı
uyarınca pasif işletme sahibinin %98 batış oranı yumuşatılmadı.

**Gelen test altyapısı:** `PerfectEntrepreneurBot` — işletmeleri görünür
ROI'ye göre karşılaştıran, fiyatı **geçmiş sonuçlarından öğrenerek**
optimize eden (gelecek bilgisi yok, hafıza her hayatta sıfırlanıyor),
reklamı ancak karşılığını görürse veren, kötü işletmeyi kapatıp daha
iyisine geçen ve artan parayı yatıran bot. Debug para/stat yok. Ayrıca
§11'in 12 stratejisini tamamlamak için `kariyer + yatırım` ve
`kariyer + işletme + yatırım`.

**Sonuç: alt mekanikler temiz, abuse katalog sayılarında.**

Fiyat optimizasyonu piyasaya göre yalnızca ×1,04; reklam aşırı güçlü
değil (optimal oyuncu **hiç reklam vermiyor** — aynı para borsada daha
çok getiriyor); bakımı geciktirme exploiti yok, tersine kaybettiriyor;
personelde gerçek trade-off var; maaş + işletme **bedava kombinasyon
değil** (fırsat maliyeti oranı 0,79); işletme kârının borsaya akması üst
kuyruğu %100 hisseden daha az patlatıyor.

**Asıl bulgu:** bütün işletmelerin sermayesi yıllık kârına göre çok
küçük — geri ödeme süresi **0,16 ile 2,24 yıl**. İki yıldan sonra işletme
fiilen bedava bir gelir akışı.

**Serbest yazılımcılık kırık bir aykırı değer:** sermaye ₺84k, geri ödeme
**0,16 yıl**, medyan ROI 340×, kapanma %5 ve **kötü %10'u bile 159×**.
Diğer bütün işletmelerde kötü %10 sıfır civarı ya da negatif. Kadrosu,
mekânı ve kirası olmadığı için kötü yılı yok. Çözücü bot 40 hayatın
28'inde bunu seçiyor.

**§13 dominans:** katı tanımla (medyan VE kötü %10 VE risk ≤) hiçbir
strateji diğerlerinin hepsini ezmiyor; çözücü 6/14'ünü eziyor. Ama hem
medyanda (ikincinin 1,77 katı) hem kötü %10'da (2,7 katı) birinci.

**Karar bekleyen:** Q-176 (yedi soru). Öneri — yapay kâr kesme yerine
sermaye/kâr oranını düzeltmek; ayrıntı ve önce/sonra ölçüm önerisi
`docs/DESIGN_REVIEW_QUEUE.md` içinde.

**Doğrulanmayan:** Gerçek cihazda oynanmadı.

## PAKET AG TAMAMLANDI (1/7 … 7/7)

**Konu:** işletme ekonomisi kalibrasyonu — ortalama denge, ama **hayatın
sürprizleri korunarak**.

**Tasarım kuralı:** bu bir hayat simülasyonu. İşletmeler "her seferinde
3-6 yılda amorti olur" gibi deterministik çalışmayacak. Aynı işletme her
hayatta aynı sonucu vermemeli.

**Katalog (§6, §14).** 14 işletmenin sermaye/kâr oranı yeniden kuruldu:
nominal geri ödeme **0,16-2,24 yıldan 1,52-5,58 yıla** çıktı. Oynaklık da
yükseldi (lokanta 0,60 → 0,66, serbest 0,55 → 0,95), çünkü §14
işletmelerin birbirinden farklı olmasını istiyor. Kataloğun en küçük işi
(terzi) bilerek bir yıllık asgari ücretin altında tutuldu — genç oyuncuya
erişilebilir bir yol kalsın diye; ucuz giriş **düşük tavanla** dengelendi.

**Serbest yazılımcılık (§4, §5, §20).** AF'de kötü %10'u bile 159 kat
kazandırıyordu. Ortalaması ezilmedi, **dağılımı genişletildi**: sermaye
0,25 → 1,60 asgari ücret, sabit gider payı 0,06 → 0,18, tedarik
0,05 → 0,08 ve altı yeni olay (abonelik, tahsil edilemeyen iş, iş
gelmeyen dönem, büyük müşteri kaybı + iki pozitif). Kötü %10 geri ödeme
katsayısı **159 → −0,4**; iyi %10 **64,1** olarak kaldı. Yılların %1,4'ü
zarar (önceden %0).

**Lokanta ve bakkal (§15).** Sadece kâr artırılmadı, gider yapısı
düzeltildi (lokanta personel 0,28 → 0,24 ve tedarik 0,32 → 0,29; bakkal
tedarik 0,58 → 0,52). Kapanma: lokanta %79 → %46, bakkal %60 → %38.
40 hayatta çok iyi giden: bakkal 23, lokanta 4.

**Pozitif kuyruk (§2, §3, §7, §9).** 16 yeni olay — mahalle seni
benimsedi, video patladı, turnuva tuttu, yemeğin adı çıktı, kurumsal
anlaşma, karşıdaki kapandı, bölge hareketlendi, referans zinciri, bayram
siparişleri, düğün sezonu. Hepsi mevcut `demandPressure` altyapısını
kullanıyor: 1-3 yıl süren güçlü avantaj, **sonsuz buff değil**. Popup
yazıp geçmiyorlar; talebi ve itibarı gerçekten değiştiriyorlar.

**Viral reklam (§10, §11).** Kampanya her zaman aynı ROI'yi vermiyor:
tutma ihtimali mahalle %4, sosyal medya %9, büyük %14 (ölçülen 4,0 / 9,1
/ 14,0). Tutan kampanya o yılki katkıyı 3,6 katına çıkarıyor ve bir iki
yıl süren talep bırakıyor. Kampanya bedelleri bu kuyruğu fiyatlıyor
(büyük 0,170 → 0,232); aksi hâlde en pahalı kampanya **her işte**
kazandıran garanti hamle oluyordu ve AE §35 exploit'i geri geliyordu.

**Hikâye bildirimleri (§12, §13).** Kozmetik değil: ölçü geçen yıla göre
**gerçekleşen ciro**, üstelik yıl tutulan bütün geçmişe göre de uç
olmalı — düşüşten sonraki toparlanma haber değil. 2949 işletme-yılında
199 başarı, 173 başarısızlık; yıl başına pencere 0,65.

**Ölçüm boşluğu kapatıldı (Q-176/6).** Nakliyecilik ehliyet istiyor ve
ölçüm botu ehliyet almıyordu; tablo onu boş gösteriyordu. Bot artık
gerçek oyuncu yolundan sınava girip cevaplıyor (`debugSetState` ile
ehliyet **verilmiyor**). Nakliyecilik artık ölçülüyor: medyan 2,8 yıl,
%37 hiç amorti etmiyor.

**Sonuç (§17-§19).** Dağılım genişledi, dominans kalmadı:

| strateji | AF medyan → AG | AF kötü %10 → AG | AG iyi %10 |
|---|---|---|---|
| mükemmel girişimci | 93,1M → **51,6M** | 24,7M → **13,9M** | 228,3M |
| kariyer + işletme + yatırım | 52,5M → 38,8M | 9,3M → 4,7M | 232,7M |
| girişim + yatırım | 41,0M → 18,1M | 11,9M → 4,4M | 181,8M |

§13'ün katı tanımıyla **bütün diğerlerini ezen strateji yok**; çözücü
9/14. Fırsat maliyeti oranı 0,79 → 0,68. Hiçbir işletmede "otomatik
zenginlik" kalmadı: her 14 işletmede sermayesini çıkaramayan hayatlar
var, kötü %10 katsayısı 13'ünde sıfırın altında.

**Yapay hard cap yok (§21):** kâr tavanı, servet tavanı ya da "çok
kazandın artık düş" mekaniği eklenmedi.

**Karar bekleyen:** Q-177. **Doğrulanmayan:** gerçek cihazda oynanmadı.

## PAKET AH — TAM YAŞAM DENETİMİ TAMAMLANDI (teşhis; denge değiştirilmedi)

**Konu:** AD + AE + AF + AG paketlerinden sonra oyunun doğumdan ölüme
bütün döngüsünü yeniden ölçmek.

**Bu tur teşhistir.** Hiçbir denge sayısı değiştirilmedi, `lib/` içinde
yalnızca okuma yapıldı; bütün değişiklikler test tarafında.

**Ölçüm:** 10 arketip × 200 + 1000 rastgele-geçerli = **3000 tam hayat**,
doğumdan ölüme. **Takılan hayat: 0.** Ölüm yaşı medyan 76.

### §2 — botun kapsamı denetlendi, üç bot hatası çıktı

`GameController`'ın 225 genel eyleminin botta kullanılmayan 100'ü
listelendi. Üçü gerçek eksikti:

1. **İşletme yönetimi hiç kullanılmıyordu.** Bot AE'nin getirdiği
   `setBusinessPrice`, `setBusinessAd`, `maintainBusiness` ve
   `businessStaff` ekranlarının hiçbirini açmıyordu. Yani AE'den beri
   "gerçek oyuncu" ölçümlerinde işletme yönetimi hiç ölçülmemiş.
2. **Yatırım hiç satılmıyordu.** Portföy yalnızca oyunun zorunlu
   bozdurmasıyla küçülüyordu.
3. **Yakın arkadaşlık hiçbir zaman çalışamıyordu.** Teklif koşulu
   `relation == arkadas` idi; oysa `arkadas` zaten yakın arkadaşlığın
   kendisi. Üstelik bot sınıf/iş arkadaşıyla hiç vakit geçirmediği için
   yakınlıkları olay dışında hiç artmıyordu.

Üçü de düzeltildi (bot tarafı; oyunun sayıları sabit). Yakın arkadaşlık
hunisi düzelmenin öncesi/sonrası: tanışıklık yakınlığı medyan **35 → 47**,
şartı sağlayan **%1,9 → %16,9**, kabul alan **%1,6 → %15,8**.

### Ölçülen son durum (3000 hayat)

* **Ekonomi.** Ölüm serveti medyan ₺48,2M, kötü %10 ₺11,9M, iyi %10
  ₺160,0M. 50M+ %48,5 · 100M+ %21,5 · 250M+ %4,6 · 500M+ %1,6 · 1B+
  %0,50. Negatif net servetle ölen %0,1, borçlu ölen %1,5. Servetin
  %75,6'sı portföyden, %6,3'ü gayrimenkulden, %3,9'u mirastan.
* **İşletme.** Açan %23,3; 26.272 işletme-yılı. Kapanan %14,3, zarar yılı
  %1,9, reklamlı yıl %36,1, viral 629 yıl. İşletme kârı medyan ₺5,3M,
  iyi %10 ₺17,2M; işten servet yapan %19,7.
* **Yatırım.** Yapan %93,7. Tek varlıkta tek yılda ≥%20 düşüş gören
  %95,8, ≥%30 %67,6, ≥%40 %51,1. Skandal/regülatör %99,0,
  konkordato/kayyum/kapanma %16,3, zorunlu satış %49,3, yatırımı
  zararla biten %18,8. 19 piyasa olay türünün hepsi görüldü.
* **Kariyer.** Çalışan %99,4, emekli %86,1, ortalama 39,6 yıl çalışma,
  1,0 yıl işsiz yetişkin yıl. Meslek kapsamı 53/55.
* **İlişki.** Partneri olan %93,1, evlenen %48,0, boşanan %17,8, dul
  kalan %15,7, tekrar evlenen %12,4, çocuklu %37,7, torun gören %34,2.
* **Sağlık.** Kronik yaşayan %76,4, check-up %96,5, sağlık krizi %69,0.
* **Suç.** Dosyası olan %57,8, sabıkalı %20,1, davaya giden %27,5,
  mahkûm %20,1, hapis %7,5, denetimli %6,8.
* **İçerik.** Olay 381/391 (%97,4), bölüm 20/20, hobi 11/12, dövüş 6/6,
  meslek 53/55, **işletme 9/14**.

### §11 — baskın hayat yolu var mı?

Yok. En zengin %10 ile bütün hayatlar arasındaki fark küçük: üniversite
%47 / %48, işletme %15 / %23, yatırım %100 / %94, ev %55 / %46, kiraya
veren %41 / %28, evli %50 / %48. Zenginliğin tek ayırt edici işareti
**yatırım ve kira geliri**; işletme zenginlerde daha az bile.

### §12 — açık kalan, sınıflandırılmış bulgular

* **Beş işletme hiç açılmadı** (pastane, nakliye, halı saha, spor
  salonu, lokanta) ve terzi tek başına seçimlerin %69,5'i. Bot hatası
  ağır basıyor (nakit biriktirmiyor), ama ardında ürün sorusu var.
* **Yazar mesleği erişilemiyor:** okuma hobisi aşama 2 istiyor, o hobi
  yalnızca kütüphanede kitap bitirerek ilerliyor ve bot kitap açmıyor.
* **Yakın arkadaşlık eşiği 55** düzeltmeden sonra bile hayatların
  %16,9'unda sağlanıyor.
* **Erişilmeyen 10 olayın 5'i suç zinciri devamı**, 3'ü ün, 2'si okuma
  hobisi.

**Karar bekleyen:** Q-178. **Doğrulanmayan:** gerçek cihazda oynanmadı.

## PAKET AI — AKSİYON KAPSAMI VE ABUSE DENETİMİ (teşhis; denge değiştirilmedi)

**Soru:** oyuncunun yapabildiği her şey gerçekten test ediliyor mu ve bu
sistemlerden biri abuse edilerek oyun kırılabiliyor mu?

Üç bot ayrı tutuldu: **PlayerBot** hayatı temsil eder, **CoverageBot**
her şeye dokunur, **AbuseBot** kırmaya çalışır.

### §1 — envanter artık elle tutulmuyor

`test/support/action_inventory.dart`, `game_controller.dart`'ı test
çalışırken okuyup üyeleri koddan çıkarıyor. Sınıflandırma isme değil
davranışa bakıyor: gövdesi `_state = …` atan, `notifyListeners()` ya da
`_autoSave()` çağıran — veya bunu yapan başka bir üyeyi çağıran — üye
**aksiyon**; geri kalanı sorgu.

| | sayı |
|---|---|
| toplam public üye | 225 |
| **oyuncu aksiyonu** | **109** |
| sorgu | 106 |
| oyun dışı (debug, kayıt, ayar) | 10 |

### §2 — ACTION COVERAGE %94,5

400 hedefli hayatta (10 plan × 40) **103/109** aksiyon gerçekten çalıştı,
**takılan hayat 0**. İçerik: 14/14 işletme, 6/6 dövüş sanatı, 20/20
bölüm, 52 meslek, 5/5 yatırım türü, 4/4 sosyal platform, 806 olay-seçenek
kolu.

Kalan 6: `acceptCrewOffer`, `declineCrewOffer` (çete teklifi hiç
açılmadı), `payBailSelf`, `askFamilyForBail` (kefalet anı yakalanamadı),
`endLifeByChoice` (95+ ve bilinçli), `askFamilyForBedelli` (1295 deneme,
oyunun gerekçesi hep "Askerlik meselen kapandı").

### Bulunan gerçek sorunlar

1. **Save-scum vektörü (doğrulandı).** Oyunun zarı
   `GameController._random` kurucuda bir kez üretiliyor ve `GameState`
   içinde taşınmıyor — yani **kayda girmiyor**. Kaydı geri yüklemek
   kumar sonucunu yeniden attırıyor: 30 tekrarın en iyisi blackjack'te
   +135k, rulette +90k. Düzeltilmedi; çözüm seçimi ürün kararı.
2. **Ücretli aktiviteler pratikte erişilemiyor.** 60 hayatta yapılan 16
   aktivitenin hiçbiri ücretli kurs değil; oyunun gerekçesi hep
   "cüzdanında yeterli para yok". Hiç yatırım/alışveriş yapmayan kontrol
   grubu da tek bir kursa giremedi. 12 hobinin 10'u ve onlara bağlı
   içerik bu kapının arkasında.

   > **DÜZELTME (Paket AJ ölçümü).** Burada ayrıca "AH'deki *Yazar
   > mesleği erişilemiyor* bulgusunun asıl sebebi de bu" yazmıştım.
   > **Yanlış.** `okuma` hobisinin `activityIds` listesi boş: onu
   > besleyen hiçbir kurs yok, yalnızca kütüphanede **bitirilen** kitap
   > ilerletiyor ve kitap okumak ücretsiz. Yazar'ın koşulu 7 bitirilmiş
   > kitap + 20 yaş + 55 zekâ; kurs ücreti hiç girmiyor. Paket AJ'nin
   > kurs düzeltmesi Yazar'ı açmıyor. Test:
   > `paket_aj_course_test.dart` → "Yazar mesleği kursla değil, bedava
   > okumayla açılıyor".
3. **Sorgu/aksiyon uyuşmazlığı.** Lise sonrası `availableTracks()` 7
   lise alanı döndürüyor ama `chooseTrack` "Şu an lise alanı
   seçemezsin." diyor. Menü, aksiyonun kabul etmediği seçenekleri
   gösteriyor.

### Abuse sonuçları — para basan tekrar yok

Aynı yıl 100-400 tekrarın hiçbiri net serveti artırmıyor: aktivite
−780k, kitap −120k, hediye −2k, eşya al-sat −9k (komisyon), blackjack
−14k (kasa avantajı), yatırım al-sat 0, sosyal medya 0. Stat farming'de
tek yılda hiçbir stat 100'e çıkmıyor (mutluluk 93'e kadar).

**Karar bekleyen:** Q-179. **Doğrulanmayan:** gerçek cihazda oynanmadı.

## PAKET AJ — KURS / HOBİ ERİŞİLEBİLİRLİĞİ (Faho'nun brief'i uyarınca)

Paket AI'nın ikinci bulgusunun (ücretli kurslara girilemiyor) ürün
cevabı. Faho'nun **KURS / HOBİ ERİŞİLEBİLİRLİK V2** brief'i kodlandı:
kurslar erişilebilir oldu ama bedava stat çeşmesine dönüşmedi.

### Kurs ilerleme sistemi

`app/lib/domain/hobby/course_progress.dart` — ders sayacı hobinin kendi
deneyimi (`HobbyProgress.experience`); ayrı bir sayaç kurulmadı.

| Ders | Kademe | Ücret (müzik kursu) |
|---|---|---|
| 1-5 | Tanışma | 0 ₺ |
| 6-10 | Başlangıç | 4.800 ₺ (katalogun 0,40 katı) |
| 11-20 | Normal | 12.000 ₺ (katalog fiyatı) |
| 20+ | İleri seviye | 26.400 ₺ (katalogun 2,2 katı) |

Kademeler **oyunun kendi ekonomik ölçeğinden** türüyor: katalog fiyatı
"normal" kademeyi anlatıyor, ötekiler onun katı. Asgari ücret çıpası
kayarsa kademeler de birlikte kayıyor. Gerçek bir ülkenin güncel
fiyatlarına bağlanmadı.

### Bedava stat farming'e karşı üç kapı

1. **Ders başına stat katsayısı düşük** (0,2), asıl ödül kilometre
   taşlarında (5/10/20/35, katsayı 2,5). Ölçüldü: tek tanışma dersi
   **+2 stat**, 5. ders **+15**.
2. **Yıllık ücretsiz ders tavanı 6** — bütün kurslar toplamında. Aynı
   yıl on kursu dolaşıp yirmi bedava ders toplanamıyor. Ölçüldü: 6.
3. **Tanışma dönemi hobi ömrü boyunca bir kez.** Bitince ücret başlıyor.

### 18 yaş altı: aileden destek (§4-§9)

Ücret gerekiyor ve çocuğun cüzdanı yetmiyorsa kartta yaşayan ebeveynler
düğme olarak çıkıyor. **Ebeveyn yoksa bölüm hiç görünmüyor** — sahte
düğme yok. 18'den sonra kapı kapanıyor.

Karar tek zar değil. 200 istekte kabul sayısı:

| Etken | Ölçüm |
|---|---|
| Varlık | yoksul 46 · orta hallı 90 · varlıklı 134 |
| Yakınlık | uzak (20) 77 · yakın (95) 118 |
| Devamlılık | yeni 100 · 5 yıldır aynı kurs 145 |

Ayrıca yarıda bırakılan her kurs kabul şansını düşürüyor.

**Para yoktan yaratılmıyor.** Ebeveynin yıllık kurs bütçesi varlık
düzeyinden ve asgari ücret çıpasından türüyor (orta hallı anne:
33.690 ₺/yıl). Ölçüldü: 400 istekte toplam **33.600 ₺** verildi, bütçe
33.690. Kabul edilen ücret o hobiye kredi yazılıyor ve ders yapılırken
**bir kez** harcanıyor; kaydet/yükle ile ikinci kredi alınamıyor.

### Ret kalıcı değil: ücretsiz yollar (§7)

`app/lib/data/event_pool_course.dart` — dört olay: belediye atölyesi
(8-17), okul kulübü (10-18, öğrenciyken), öğretmenin desteği (11-18),
akrabanın desteği (9-17). Hepsi `kurs_destegi` izi bırakıyor; iz varken
dersler yıl içinde dört derse kadar ücretsiz. Sonsuz bedava ders değil,
bir yıl açık kalan kapı. Burslu yıl tanışma hakkını yemiyor.

Ret ayrıca o yıla özgü: sayaçlar yıl başında sıfırlandığı için oyuncu
seneye yeniden sorabiliyor.

### İleri seviye ne satıyor (§12)

Her kademe ücretinin karşılığını da söylüyor; ileri seviyede kart
"Özel hoca, ileri ekipman ve yarışma hazırlığı bu ücrete dahil" diyor.
Ücretsiz tanışma dersinde bu satır görünmüyor.

### Kurs bir hayat yolunun başlangıcı (§13)

Kart kursun nereye götürdüğünü gösteriyor: *"Müzisyen için 10 ders daha
(Düzenli basamağı)"*, yol açıldıysa *"Müzisyen yolu açık"*. Bağ
uydurulmuyor — meslek kataloğunun `hobbyId` / `minHobbyStage` alanları
zaten işe giriş koşulu; burada aynı koşul oyuncunun görebileceği hale
çevriliyor. İkinci bir eşleme tablosu tutulmadı, **yeni kilit
eklenmedi**. Meslek bağı olmayan hobide satır hiç görünmüyor.

Ölçüldü: okuma → **Yazar** (Düzenli basamağı, 7 birim), müzik →
**Müzisyen** (10 ders). Müzik testi dersleri gerçekten kursa girerek
topluyor ve iş kataloğunun `minHobbyStage` koşulunun da sağlandığını
doğruluyor.

**Yazar mesleği kursla açılmıyor.** `okuma` hobisinin `activityIds`
listesi boş; onu besleyen kurs yok, yalnızca kütüphanede bitirilen
kitap ilerletiyor ve o ücretsiz. Yazar'ın koşulu **7 bitirilmiş kitap +
20 yaş + 55 zekâ**. Kitaplar 5-24 sayfa ve her sayfa bir eylem, yani 7
kitap kabaca 50-100 okuma eylemi demek — AH'de Yazar'ın 3000 hayatta
hiç görülmemesinin sebebi kurs ücreti değil, bu. Paket AJ bunu
değiştirmedi; denge sorusu olarak Q-180 #5'te duruyor.
12 hobinin yalnızca 2'si bir mesleğe çıkıyor; kalan 10'u için bağ
kurmak tasarım kararı — Q-180 #4.

### Ölçülen erişilebilirlik

| Ölçüm | Paket AI (önce) | Paket AJ (sonra) |
|---|---|---|
| Girilebilen ücretli kurs | 0 / 10 | **10 / 10** |
| İlerletilebilen hobi | 2 / 12 | **12 / 12** |

### Değiştirilen testler (silinmedi, yeniden yazıldı)

İki test Paket AJ'nin değiştirdiği eski kuralı doğruluyordu:

* `activity_venues_test` "dil kursu zekâyı gerçekten artırır" — her ders
  katalog fiyatını alır ve stati bir kerede verir diyordu. Yerine **üç**
  test: ilk ders bedava ve hobiyi ilerletiyor, 5. ders kilometre taşı
  ödülünü veriyor, tanışma bitince ücret cüzdandan çıkıyor.
* `activity_venues_widget_test` "parası yetmeyen eylemin düğmesi
  kapalıdır" — "kurslarda ücretsiz eylem yok, hepsi kapalı" diyordu.
  Yerine **iki** test: parasız çocuk tanışma dersine girebiliyor, ve
  tanışma bitince parası yetmeyen yetişkinin kursu gerçekten kapanıyor.

28 test: `app/test/paket_aj_course_test.dart`.

**Karar bekleyen:** Q-180 (prototip sayıları, tanışma hakkının ömürlük
olması, yetişkinin ücretsiz yolu, hobi-meslek bağı).
**Doğrulanmayan:** gerçek cihazda oynanmadı.

## PAKET AK — HOBİ / KURS → KARİYER SİNERJİSİ

Paket AJ 12 hobiyi erişilebilir yaptı ama katalogda hobiye bağlı
yalnızca iki meslek vardı ve ikisi de **sert şart**: Yazar (okuma) ve
Müzisyen (müzik). Çocukken başlanan fotoğraf kursu hayatın geri
kalanında hiçbir kapı açmıyordu. Bu paket o boşluğu **kilit koymadan**
dolduruyor.

### Temel kural: hiçbir kapı kapanmadı

Faho'nun kararı: kurs/hobi yapmamış oyuncunun bugün girebildiği
mesleklerin **hiçbiri kapanmayacak**. Bu yüzden sinerji
`JobType.hobbyId` / `minHobbyStage` sert şartından **ayrı** bir alanda
(`JobType.synergies`) duruyor ve `JobMarket.requirementReason` içine
hiç girmiyor.

Ölçüldü: hiç hobisi olmayan oyuncu ile bütün hobileri Usta olan
oyuncunun 19 sinerjili meslekteki **engel gerekçeleri birebir aynı**.
Yanlış cevap veren hobisiz aday 200 başvurunun 200'ünde de eskisi gibi
reddediliyor; doğru cevap veren hobisiz aday eskisi gibi işe giriyor.

### Avantaj nereden geliyor

Üç yerden, üçü de sınırlı. Maaşa ve gelir bandına **hiç dokunmuyor**.

| Kanal | Ne yapıyor | Tavan |
|---|---|---|
| Mülakat | Cevap tutmazsa geçmiş ikinci bir şans veriyor | %45 |
| Başlangıç ustalığı | İşe sıfır çırak olarak başlanmıyor | 5 yıl (= Kalfa) |
| Terfi | Hobi sürüyorsa çok küçük devam payı | +0,05 |

Pay hobinin **basamağından** geliyor, o yıl kaç ders alındığından değil.

| Basamak | Pay | Fotoğrafçıda mülakat ikinci şansı |
|---|---|---|
| Hevesli | 0,00 | %0 |
| Meraklı | 0,25 | %11 |
| Düzenli | 0,55 | %25 |
| Tutkulu | 0,80 | %36 |
| Usta | 1,00 | %45 |

**Usta bile garanti değil.** Aşçılıkta bilerek yanlış cevap verilen 200
başvuruda: hobisiz **0**, Düzenli **44**, Usta **94**. Artıyor, ama
hiçbir zaman 200 olmuyor.

### Hobi → meslek tablosu (§23)

| Hobi | Meslekler |
|---|---|
| Resim | Ressam/tasarımcı (güçlü) · Grafik tasarımcı (güçlü) |
| Mutfak | Aşçı (güçlü) |
| Fotoğraf | Fotoğrafçı (güçlü) · Gazeteci (küçük) |
| Bilgisayar | Yazılım geliştirici (güçlü) · Veri analisti (orta) · Teknik servis (küçük) |
| Yazmak | Yazar (güçlü) · Gazeteci (orta) |
| Yabancı dil | Resepsiyonist (güçlü) · Satış danışmanı (orta) · Gazeteci (orta) · Banka personeli, Çağrı merkezi, İK uzmanı (küçük) |
| Spor | Güvenlik (orta) · İtfaiyeci (orta) · Polis (küçük) |
| Dans | Manken (küçük) |
| Satranç | Veri analisti (küçük) |
| Müzik | Müzisyen (orta) — sert şart ayrıca duruyor |
| Okumak | Yazar (orta) — sert şart ayrıca duruyor |
| **Bahçe** | **Bağ yok** |

Bahçe bilerek boş: §13 uyarınca her hobinin mevcut bir mesleğe
bağlanması gerekmiyor, zorlama bağ kurulmadı. İleride Bahçıvan/Peyzaj
eklenirse tek satırla bağlanır. Test bunu koruyor: bahçe hiçbir
meslekte görünmüyorsa test geçer.

Spor bağları yasal eğitim, yaş ve sabıka şartlarını **bypass etmiyor**;
yazmak hobisi Yazar'ın okuma şartını bypass etmiyor (ölçüldü).

### Aktif / bırakılmış hobi (§20)

Geçmiş silinmiyor ama aktif olanla aynı da değil. Usta resim:
aktif **1,00**, 12 yıldır ara verilmiş **0,55**. Bırakılmış hobi terfi
payı **hiç** vermiyor: geçmiş ustalık işe başlarken sayıldı, terfi
masasında ikinci kez sayılmıyor.

### Başlangıç ustalığı (§18)

Usta fotoğrafçı işe **Kalfa** olarak başlıyor (5 yıl pay), hobisiz
oyuncu **Çırak**. Usta olarak başlamak mümkün değil: Usta 8 yıl ister,
tavan 5.

Pay yalnızca ustalık merdivenine işliyor. Ölçüldü: 28 yaşında işe
girmiş 30 yaşındaki oyuncunun `yearsInJob` ve `totalWorkYears`
değerleri **2**, ustalık merdivenindeki etkin yıl **2 + pay**. Maaş
katalog maaşı olarak kalıyor. İşten ayrılınca pay sıfırlanıyor.

### Abuse (§22)

* 12 hobiden **birer ders** alan oyuncunun en yüksek kariyer payı
  **0,00** — Hevesli basamağının payı sıfır.
* Gazetecinin üç bağını birden Usta yapmak avantajı çarpmıyor: tek hobi
  **0,65**, üç hobi **0,81** (toplasa 1,95 olurdu). En güçlü bağ esas,
  ikincisi yalnızca küçük pay ekliyor.
* Hobi deneyimini 500 artırmak terfi payını **değiştirmiyor**.
* 19 sinerjili mesleğin hepsinde maaş katalog maaşı olarak kalıyor.

### Kayıt

Tek yeni alan: `CareerState.synergyHeadStart` (int). Eski kayıtlar
0 ile yükleniyor, kayıt bozulmuyor.

### Arayüz

* **Kurs kartı** (§15): "Kariyer avantajları — • Yazılım geliştirici —
  güçlü avantaj · • Veri analisti — anlamlı avantaj · • Teknik servis —
  orta avantaj". Bırakılmış hobide "(uzun zamandır ara verdin)".
* **İş ilanı** (§16): "Bilgisayar hobin bu başvuruda sana güçlü avantaj
  sağlıyor." Yüzde gösterilmiyor; test bunu kontrol ediyor.
* Avantajı olmayan işte satır **hiç** görünmüyor.

23 test: `app/test/paket_ak_synergy_test.dart`.

**Karar bekleyen:** Q-181. **Doğrulanmayan:** gerçek cihazda oynanmadı.

## PAKET AL — PROFESYONEL DÖVÜŞ / SPOR KARİYERİ V1

Altı dövüş sanatı "ders al → basamak yüksel → eğitmenlik" olmaktan
çıkıp gerçek bir yaşam yoluna dönüştü: çocuk yaşta kulüp, amatör
müsabaka, bölge, ulusal, profesyonel/elit, sponsor, sakatlık, düşüş,
şampiyonluk, emeklilik, eğitmenlik.

**Ana tasarım kuralı.** "En iyi antrenmanı yaptım, o zaman kesin
kazanmalıyım" değil: *"Doğru kararlarla şansımı yükselttim, ama
karşımda başka bir insan var."*

### Ne eklendi, ne bozulmadı

`MartialProgress` **dokunulmadı**: teknik ilerleme (ders, kuşak) aynı
motorda duruyor. Rekabet ayrı bir modelde: `CombatCareer`. İkinci bir
ders sistemi kurulmadı (§5), yeni bir stamina motoru yok (§36).
Eğitmenlik mesleklerinin `instructorFromLevel` şartı **aynen** duruyor
(§30, testle korunuyor).

### Altı sanatın kendi yolu (§1, §23)

| Sanat | Kademeler | Şampiyonluk |
|---|---|---|
| Boks | Amatör maçlar → Bölgesel → Ulusal amatör → Profesyonel ring | Kemer maçı |
| Yağlı güreş | Yerel güreş → Boy müsabakaları → Bölgesel organizasyon → Büyük organizasyon | Başpehlivanlık |
| Judo | Kulüp → Bölge → Ulusal → Elit turnuva | Uluslararası şampiyonluk |
| Karate | Kulüp → Bölge → Ulusal → Elit kumite turnuvası | Ulusal şampiyonluk |
| Taekwondo | Kulüp → Bölge → Ulusal → Elit turnuva | Ulusal şampiyonluk |
| Kung fu | Okul içi → Açık turnuva → Bölgesel → Ulusal yarışma | Ulusal şampiyonluk |

Organizasyonlar **kurgusal**; hiçbir federasyon, lig ya da şirket
verisine bağlı değil. Ödüller net yıllık asgari ücretin katı olarak
yazıldı (§14): çıpa kayarsa ödüller birlikte kayar, gerçek güncel fiyat
hardcode edilmedi. Amatör kademe **para kazandırmıyor**.

### Maç motoru (§7, §37)

Sonuç ne yalnızca zar ne yalnızca stat karşılaştırması. Güç hesabı:
teknik %42, form %24, sağlık %16, deneyim %10, itibar %8 — hepsi yaş
eğrisi, hazırlık ve sakatlık geçmişiyle ölçekleniyor. Kazanma ihtimali
**hiçbir zaman 0 ya da 1 değil**: band %10-%85.

Ölçüldü: 300 maçta favori **87** kez kaybetti, underdog **30** kez
kazandı. Judoda aynı sporcu için hazırlık farkı: dinlenerek %39,
dengeli %44, yoğun kamp %53.

### Form, kamp, antrenör

Form 0-100; her yıl aşınır, çalışmak ve müsabaka telafi eder. Kamp üç
seçenek (§10): dengeli / yoğun / dinlen — yoğun kamp hazırlığı artırır
ama parayı, sağlığı ve sakatlık riskini de artırır. Antrenör üç kalite
(kulüp hocası / deneyimli koç / elit koç); elit koç ancak üst kademede
kabul ediyor ve **garanti galibiyet yok**.

### Sakatlık (§18-§20)

Ölçüldü: 400 maçta yoğun kampla **59**, dinlenerek **9** sakatlık.
Sakatlık kariyer kademesini ya da şampiyonlukları **silmiyor**; formu
düşürüyor, müsabakayı geçici kapatıyor, cepten masraf çıkarıyor.
"Riski göze al" gerçekten riskli: 200 kararda **98** kez durum
ağırlaştı.

### Yaş (§21)

Zirve 27; sonrası yavaş düşüş, sanatın yıpratıcılığına göre biraz
farklı. Sert kesim yok. Ölçülen boks gücü: 20y **60,4** · 27y **65,0** ·
33y **57,2** · 38y **50,7** · 45y **41,6**.

### Save/load (§44)

Müsabaka fırsatı üretildiği anda **sonucun tohumu kayda yazılıyor**.
Ölçüldü: aynı müsabakayı kaydedip yükleyip tekrar oynamak aynı sonucu,
aynı ödülü ve aynı sakatlığı veriyor. Bu çözüm yalnızca spor
kariyerine uygulandı; oyunun genel rastgelelik mimarisine
dokunulmadı.

### 600 sporcu ölçümü (§49)

6 sanat × 100 hedefli sporcu. **Kohort sıradan bir hayat değil**: bot
her yıl çalışıyor, her fırsatı değerlendiriyor, yalnızca oyun zorlayınca
bırakıyor.

| Sanat | Elit/pro | Şampiyon | Erken bırakan | Ciddi sakatlanan | Medyan gelir |
|---|---|---|---|---|---|
| Boks | 63 | 5 | 3 | 33 | 1.573.324 ₺ |
| Yağlı güreş | 88 | 25 | 1 | 32 | 5.441.778 ₺ |
| Judo | 75 | 10 | 6 | 29 | 2.491.377 ₺ |
| Karate | 80 | 18 | 0 | 29 | 3.682.320 ₺ |
| Taekwondo | 78 | 27 | 0 | 32 | 2.971.461 ₺ |
| Kung fu | 81 | 24 | 2 | 40 | 3.392.585 ₺ |

Toplam: rekabete başlayan **%100**, elit/pro **%77,5**, şampiyon
**%18,2**. Gelir: en kötü %10 **134.760 ₺**, medyan **3.048.104 ₺**, en
iyi %10 **9.099.675 ₺**, en iyi **17.435.417 ₺** (asgari ücret çıpası
336.900 ₺). Absürt sonuç, negatif rekor ya da uçuk gelir yok.

### Ölçümün bulduğu iki gerçek sorun (düzeltildi)

1. **Şampiyonluk pratikte kapalıydı.** İlk yazımda sıralamaya 12.
   sıradan girilip her galibiyette bir basamak çıkılıyordu; 600
   sporcuda **tek** şampiyon çıktı. Merdiven düzeltildi: 10. sıradan
   giriş, alt sıralarda iki basamak.
2. **Zirvedeki sporcunun formu çöküyordu.** En üst teknik basamağa
   çıkan sporcuya ders motoru artık ders vermiyor ("öğrenecek ders
   kalmadı"), dolayısıyla form telafisi sıfırlanıyor ve sporcu otuzlu
   yaşların başında emekliliğe itiliyordu. Artık müsabakalar ve
   zirvedeki kondisyon da forma katkı veriyor.

### Abuse (§42)

Aynı yıl 40 denemede yapılabilen müsabaka **3** (tavan 4). Aynı
müsabakanın ödülü iki kez alınamıyor. Sakatken müsabaka yapılamıyor.
Emekli olup aynı dalda yeniden başlanamıyor. Sıralaması olmayan
şampiyonluk maçına çağrılmıyor (200 denemede 0). İki dalda birden
rekabet edilemiyor.

### Kayıt

Tek yeni alan: `GameState.combatCareers`. Eski kayıtlarda yok, boş
liste ile yükleniyor; test bunu doğruluyor.

### Arayüz (§26, §27)

Mevcut dövüş sanatı ekranı çöpe atılmadı, derinleştirildi: üstte
kariyer paneli (kademe, form, rekor, sıralama, kariyer geliri,
antrenör, sakatlık, sıradaki müsabaka ve rakip), altında eski ders
kartları. Kararlar: üç kamp seçeneği, koç tut, riski göze al, spordan
çekil, kariyeri gör (son 10 önemli an). Sıradan antrenman geçmişe
yazılmıyor.

25 test: `app/test/paket_al_combat_career_test.dart` (24) +
`app/test/paket_al_600_athletes_test.dart` (1, 600 kariyer).

**Karar bekleyen:** Q-182. **Doğrulanmayan:** gerçek cihazda oynanmadı.

## PAKET AL/VERIFY — BAĞIMSIZ DOĞRULAMA

Yeni özellik eklenmedi, denge değiştirilmedi, 3000 hayat testi
yapılmadı. Tek soru: **Paket AL brief'te söylediğimiz gibi mi
çalışıyor, testlerinde hata var mı, eksik uygulanmış madde var mı?**

### Bulunan iki TEST hatası (düzeltildi)

1. **"sakatken müsabaka yapılamıyor" testi hiçbir şeyi sınamıyordu.**
   Yorum "fırsat da çıkmıyor" diyordu ama iddia `isNotNull` idi — ve o
   iddia **her zaman** geçiyordu, çünkü testin kendisi bir satır önce
   bekleyen müsabakayı kuruyor, `offerBout` da bekleyen müsabaka varsa
   onu geri veriyor. Sakatlık kapısı hiç sınanmamış.
   Ürünün gerçek kuralı iki kapılı ve ikisi de motorda **var**: sakat
   sporcuya yeni fırsat üretilmiyor, elinde bekleyen müsabaka olsa bile
   dövüşemiyor. Test artık ikisini de ayrı ayrı sınıyor (50 tohumda 0
   fırsat; sağlam sporcuda fırsat çıkıyor — yani kapı sakatlıktan
   kapanıyor, her koşulda kapalı değil).

2. **`requirementReason(...).contains('basamak')` iddiası asla doğru
   olamazdı.** Motorun ürettiği metin "basamağına gelmen gerekiyor";
   Türkçe yumuşamayla `'basamağına'`, `'basamak'` alt dizesini
   içermiyor (ğ ≠ k). Yani eğitmenlik testinin son iddiası her zaman
   geçiyordu. Ayrıca `dusuk` değişkeni iki kez atanıyordu; ilk atama
   ölü koddu ve yorumla çelişiyordu. İkisi de düzeltildi; iddia artık
   iki yönlü ve gerçek dizeyle: basamağı tutmayanda engel gerekçesi
   eğitmenlik basamağını **söylüyor**, tutanda **kalkıyor**.

### PROD BUG bulunmadı

27 yeni doğrulama testi ürünün gerçek kapılarından geçti; çökme, state
bozulması, çift ödeme ya da save/load hatası çıkmadı.

### Doğrulanan davranışlar

| Konu | Ölçüm |
|---|---|
| 6/6 sanat tam yol | başla → kazan → kaybet → kademe 3 → pro → emekli, hepsi ürün API'siyle |
| Maç motoru bileşenleri | teknik, form, sağlık, deneyim, hazırlık, yaş, sakatlık geçmişi — **yedisi de** ihtimali değiştiriyor |
| Bant uç durumda | en zayıf %10 · en güçlü %85 (0 ve 1 yok) |
| Save/load | 6/6 sanatta sonuç, ödül, sakatlık, sıralama ve şampiyonluk birebir aynı |
| Hazırlık kararı canlı | 200 müsabakanın **18'inde** kamp tercihi sonucu değiştirdi |
| Çift ödeme | unvan maçı tek ödeme; ikinci çağrı ve kaydet/yükle sonrası 0 ₺ |
| Şampiyonluk | 6/6 sanatta ürün kapılarından ulaşılabilir, geçmişe yazılıyor |
| Şampiyon sonrası | unvan kaybı → tekrar şampiyonluk zinciri çalışıyor; kariyer bitmiyor |
| Sıralama | galibiyet 10 → mağlubiyet 12 → 5 yıl ara 20; band 0-20, negatif yok |
| Sakatlık | 600 maçta yok 471 · hafif 85 · orta 36 · ciddi 8 — üç seviye de çıkıyor |
| "Riski göze al" | 200 kararda ağırlaşan 98 · kurtulan 102 (cosmetic değil) |
| Antrenör | elit koç 94.332 ₺/yıl, yılda **bir kez** kesiliyor; kazanma %37 → %44; garanti değil |
| Ün kademeleri | yerel 0 · ulusal 3 · elit 6 · şampiyonluk 18; spor tavanı 70 |
| Sponsor | kademe 1'de 0 · itibar 20'de 0 · kademe 2 itibar 50'de 57 · +ün 172 · +şampiyonluk 174 (300 denemede) |
| Yaş | 20y 60,4 · 27y 65,0 · 33y 57,8 · 35y 55,4 · 45y 43,5 · 55y 31,5 — duvar yok, 50+ dominans yok |
| Emeklilik | üç sebep de çalışıyor, emekli geri dönemiyor, bekleyen müsabaka temizleniyor |
| Boş durum | kariyeri olmayan ve bozuk `artId` taşıyan oyuncuda hiçbir okuma çökmüyor |

### Brief'te yazılı olup UYGULANMAMIŞ maddeler

Bunlar bu turda **eklenmedi** (verify turu); raporlandı ve Q-183'e
yazıldı.

| Madde | Durum |
|---|---|
| **§4 / §16** 18 yaş altı sporcuya aile desteği (ekipman, yol, kulüp, turnuva) | **YOK.** Paket AJ'nin `CourseSupport` sistemi combat tarafında hiç çağrılmıyor. Genç sporcunun kamp/koç masrafı yalnızca kendi cüzdanından çıkıyor. |
| **§35 / §17** Okul + spor çatışması ("Turnuva sınav haftasına denk geldi") | **YOK.** Böyle bir olay ya da karar noktası kodda yok. |
| **§16 / §14** Spor başarısının sosyal medya içerik performansına etkisi | **DOLAYLI.** Şampiyon ile aynı takipçili sıradan oyuncu, paylaşım başına **aynı** sonucu alıyor. Spor yalnızca Ün'ü yükseltiyor; Ün de medya işlerini (`kMediaSectionMinFame`, `job.minFame`) ve ünlü iş birliklerini (`minFame 25`) açıyor. Yani etkisi var ama paylaşım performansında değil. |
| **§9** Rivalry'nin ün/ilgi üzerindeki "küçük etkisi" | **YOK.** Rakip kaydı, tekrar karşılaşma ve karşılıklı skor **gerçek state** (ölçüldü: kendi kademesinde 200 fırsatta 49 kez geri geldi), ama rivalry ne üne ne ödüle ne de fırsat sıklığına dokunuyor. |
| **§36 / §18** İş + spor çatışması | **YALNIZCA PARA/SAĞLIK.** Ölçüldü: çalışan ve çalışmayan sporcunun kazanma ihtimali (%40 vs %40), maç sonucu ve 200 denemedeki fırsat sayısı (133 vs 133) **birebir aynı**. İş durumu spor motoruna hiç girmiyor. |

### Belgelenen sınır (hata değil)

Tanıdık rakip yalnızca gücü oyuncunun **bugünkü** kademesine yakınken
geri gelebiliyor. Oyuncu üst kademeye çıkınca alt kademedeki eski
rakipler bandın dışında kalıyor: ölçüldü, kendi kademesinde 200
fırsatta **49**, üst kademeye çıkınca **0**. Kayıt kaybolmuyor, çökme
yok; ama brief'in "aynı rakiple rövanş, final, kemer maçı" fikri
kademeler arası taşınmıyor.

### §22 — boks (%5) ve taekwondo (%27) farkı BUG mu?

**Hayır, katsayıların bileşik sonucu.** Maç başına fark küçük:

| Sanat | Kademe-3 rakip | Unvan rakibi | Sakatlık | Yıpranma | Denk şans | Unvan şansı |
|---|---|---|---|---|---|---|
| Boks | 76 | 92 | 0,22 | 1,15 | %62 | %40 |
| Yağlı güreş | 74 | 90 | 0,18 | 1,10 | %65 | %43 |
| Judo | 75 | 91 | 0,16 | 1,00 | %64 | %42 |
| Karate | 74 | 90 | 0,14 | 0,95 | %65 | %43 |
| Taekwondo | 74 | 90 | 0,14 | 0,95 | %65 | %43 |
| Kung fu | 72 | 88 | 0,12 | 0,85 | %68 | %46 |

**Dikkat çeken nokta:** unvan maçı başına fark yalnızca **3 puan**
(%40 vs %43), ama 600 hayatlık sonuç **5'e 27** — beş kattan fazla.
Fark tek bir büyük katsayıdan değil, üç küçük katsayının kariyer
boyunca **birbirini çarpmasından** doğuyor: daha güçlü rakip → daha az
terfi; daha yüksek sakatlık → kaybedilen yıllar → sıralama aşınması;
daha hızlı yaş aşınması → daha kısa elit pencere. Bu hassasiyetin
kendisi Faho'ya bildirildi (Q-183 #6); **hiçbir sayı değiştirilmedi.**

### §23 — dominance

Hiçbir sanat dört ölçütün (elit oranı, şampiyonluk, sakatlık, gelir)
dördünde birden önde değil: en çok elit yağlı güreş (88), en çok
şampiyon taekwondo (27), en az sakatlık judo/karate (29), en yüksek
gelir yağlı güreş (5,44 M₺).

**Ters yönde bir uyarı var:** boks dört ölçütün üçünde **son sırada**
(elit 63, şampiyon 5, gelir 1,57 M₺) ve sakatlıkta da üst sıralarda.
Denge sorusu olarak Q-183 #6'da duruyor.

27 doğrulama testi: `app/test/paket_al_verify_test.dart`.

**Karar bekleyen:** Q-183. **Doğrulanmayan:** gerçek cihazda oynanmadı.

## PAKET AL/2 — SPOR KARİYERİ ENTEGRASYONLARI

Paket AL/VERIFY beş brief maddesinin **yazıldığı ama uygulanmadığını**
tespit etmişti. Bu paket o beşini gerçekten kodladı: her biri için
production kod, gerçek state etkisi, hedefli test ve gereken yerde UI
var. **Yeni denge turu değil**; mevcut kazanma bandı, sakatlık oranları,
şampiyonluk oranları, yaş eğrisi ve ödül çarpanlarına dokunulmadı.

### Önce / sonra

| Konu | Paket AL/VERIFY sonunda | Paket AL/2 sonunda |
| --- | --- | --- |
| 18 yaş altı aile desteği | Yok. Genç sporcunun kamp/koç masrafı yalnızca kendi cüzdanından. | Dört masraf başlığında aileden destek istenebiliyor; **Paket AJ ile aynı ebeveyn yıllık bütçesi** paylaşılıyor. Kabul oranı varlığa göre %0 / %0 / %23 / %58 / %69. |
| Okul + spor | Karar noktası yok. | Yılda en fazla bir kez çıkan gerçek çatışma; iki seçim de farklı state üretiyor. 200 kariyer × 8 okul yılında 44 çatışma. |
| Spor başarısı → sosyal medya | Şampiyon ile sıradan oyuncu **birebir aynı** paylaşım performansı. | Spor içeriğinde şampiyon **+%41**; spor dışı içerikte fark **tam olarak 0**. |
| Rivalry | Kayıt tutuluyordu, hiçbir sonucu yoktu. Üst kademeye çıkınca eski rakip 0 kez geliyordu. | Rekabet gücü ölçülüyor; kazanılan önemli rövanş ün ve sosyal ilgi getiriyor (azalan getiri + yıllık tavan). Önemli rakip oyuncuyla birlikte yükseliyor, yaşlanınca düşüyor. |
| İş + spor | Çalışan ve çalışmayan sporcu **birebir aynı**: aynı fırsat, aynı kazanma ihtimali. | Kişi başı müsabaka 13,3 / 10,7 / 9,1; full-time fırsat kaybı %32; kariyer sonu form 48 / 29 / 20. Kazanma ihtimaline **doğrudan** kesinti yok. |

### Yeni dosyalar

- `app/lib/domain/combat/sport_family_support.dart` (§1-§5)
- `app/lib/domain/combat/sport_school_conflict.dart` (§6-§9)
- `app/lib/domain/combat/sport_rivalry.dart` (§15-§19)
- `app/lib/domain/combat/sport_workload.dart` (§20-§25)
- `app/lib/domain/social/sport_social_boost.dart` (§10-§14)
- `app/test/paket_al2_entegrasyon_test.dart` (38 test + §34 ölçümü)

### Bulunan PROD bug — raporlandı, DÜZELTİLMEDİ

`CombatCareerEngine.advanceYear` ders sayacını ters anahtar sırasıyla
okuyor (`karate|dovus`), oysa `MartialArtsEngine` `dovus|karate`
yazıyor. Paket AL'den beri "çalışmak formu telafi eder" kuralı hiç
işlememiş.

Düzeltme **denendi ve geri alındı**: 600 sporcu ölçümünde medyan kariyer
geliri 4,04 M₺ → 6,51 M₺ çıkıp testin kendi denge koruması kırıldı.
Brief §0 bu pakette ödül çarpanlarına ve şampiyonluk oranlarına
dokunmayı yasaklıyor, mevcut testi gevşetmek de yasak. Karar Q-184
#1'de Faho'ya bırakıldı; hatanın varlığı bir belge testiyle kilitlendi.

### Ölçümle düzeltilen iki kalibrasyon (ikisi de bu paketin kendi
### mekanikleri)

1. Okul çatışması ilk yazımda yalnızca kademe ≥ 1'de çıkıyordu ve 200
   sporcuda **1 kez** çıktı — fiilen ölü özellik. Kapı, 4+ müsabaka
   yapmış sporcuyu da kapsayacak şekilde genişletildi.
2. Tam zamanlı iş cezası ilk yazımda kariyeri öldürüyordu (kariyer sonu
   form 3,8, fırsat kaybı %55). Katsayılar yumuşatıldı.

**Karar bekleyen:** Q-184 (ve Q-183 #6 boks/taekwondo hassasiyeti hâlâ
açık). **Doğrulanmayan:** gerçek cihazda oynanmadı; Android APK bu
oturumda cihazda test edilmedi.

## PAKET AM — MANTIKSAL MESLEK / FİZİKSEL UYGUNLUK ŞARTLARI

Bazı kariyer kapıları mevcut statlarla fazla gevşekti. Bu paket
"bu mesleğin doğası hangi statı gerçekten gerektirir?" sorusunu
uyguladı — **keyfi stat duvarı kurmadan**. Her işe "80 zekâ + 80 sağlık
+ 80 karizma" gibi kapılar konmadı; şart mesleğin kendisinden geldi.

### İki kesin karar (Faho)

| | Önce | Sonra |
| --- | --- | --- |
| Manken dış görünüş | 70 | **80** |
| Rekabetçi dövüş kariyerine başlama sağlığı | 40 | **80** |

D-064'ün "görünüş 70 şartı korunur" hükmü Faho'nun bu paketteki kesin
kararıyla **80**'e güncellendi.

### Sağlık üç kademeye ayrıldı (combat)

Tek bir eşik yerine üç kapı, çünkü kariyere **başlamak** ile sakatlanıp
toparlanmayı beklemek aynı şey değil:

- kariyere başlama: **80**
- pro/elit kademeye terfi: **80** (kalıcı kilit değil; sağlık gelince açılır)
- normal müsabakaya çıkma: **70**
- 70'in altı: **geçici** engel. Kariyer durur, **silinmez** — kademe,
  rekor, sıralama ve şampiyonluklar yerinde kalır.

Ciddi sakatlık ayrı bir kapı olarak duruyor: sağlığı 90 olan oyuncu da
sakatken dövüşemez ve ona sağlık cümlesi değil sakatlık cümlesi
gösterilir. İki ceza üst üste binmiyor.

### `JobType.minHealth` (yeni alan, varsayılan 0)

Eşik konan meslekler — brief'in adını verdiği üç kamu mesleği:

| Meslek | minHealth |
| --- | --- |
| İtfaiyeci | 70 |
| Polis | 65 |
| Güvenlik görevlisi | 55 |

Her birinde mesleğe özel `physicalNote` var; oyuncu "işe uygun değilsin"
değil, gerçek sebebi ve eksiğinin ne kadar olduğunu okuyor.

**Ölçümle alınmış bir karar:** §10'un aday saydığı beş işe (kurye 50,
depo personeli 55, oto tamircisi 50, tesisatçı 50, kaynakçı 60) da eşik
konmuştu ve **ölçüm bunu geri aldırdı**. Bu beş iş erişilebilir
kataloğun büyük bir dilimi; kapanmaları maaş yollarını zayıflatıp
`girisim+yatirim` stratejisinin her ölçüde ezdiği strateji sayısını
**5/14'ten 9/14'e** çıkardı ve terzi atölyesinin payback dağılımını
darlattı. Brief toplu denge operasyonunu yasakladığı için eşikler
kaldırıldı; geri alındıktan sonra iki ölçüm de baseline değerine döndü
(dominans yine 5/14). Karar Q-185 #2'de Faho'da.

**Bilerek 0 bırakılanlar:** bütün ofis/uzmanlık meslekleri (yazılımcı,
muhasebeci, öğretmen, banka personeli, üç mühendislik, gazeteci, yazar,
müzisyen, doktor, hemşire, psikolog, eczacı, memur, veri analisti),
yaratıcı meslekler, dövüş eğitmenlikleri ve **bütün yarım zamanlı
gençlik işleri**. Sağlık statı 45 olan birinin muhasebeci olamaması
saçma olurdu.

**Görünüş bariyeri yalnızca mankenlikte** (katalogda tek). Satış
danışmanı, resepsiyonist ve gazetecide doğru stat karizma; hard
appearance gate eklenmedi.

### Ne kapanmadı

- Normal spor aktiviteleri (koşu, ağırlık, esneme) sağlık 55 ile açık.
- Dövüş sanatı **dersleri** sağlık 60 ile açık — ders almak müsabakaya
  çıkmak değil.
- `minAppearance` ve `minHealth` **işe giriş** şartı; işe girdikten
  sonra stat düşerse otomatik kovma yok (D-064).

### UI

İş ilanında ve kapalı işler listesinde gereksinimler ✓/✗ olarak
gösteriliyor; tutan şartta yalnızca ad, tutmayanda eşik ve mevcut değer
yazılıyor. Dövüş ekranında "Rekabetçi kariyer için sağlık: 73 / 80"
satırı var. Yüzde ya da formül gösterilmiyor.

29 hedefli test: `app/test/paket_am_fiziksel_sartlar_test.dart`.

**Dokunulmayan:** Q-184 #1'deki ders/form telafisi anahtar hatası (§21
gereği), boks/taekwondo hassasiyeti (Q-183 #6), genel denge.
**Doğrulanmayan:** gerçek cihazda oynanmadı.

## Sonraki tasarım işleri
İlk çalışan dikey kesit doğrulandıktan sonra olay verisi ve sürekliliğini genişlet, aile, eğitim, kariyer, ekonomi, sosyal medya/Ün sistemlerini aşamalı ayrıntılandır. Kesin sayısal denge ve teknoloji hâlâ açık.

## ChatGPT / Claude devri
Yeni oturumda `DECISIONS.md`, bu dosya, `docs/PROTOTYPE_UI.md`, `docs/CLAUDE_PROTOTYPE_TASK.md` ve ilgili sistem belgelerini oku. **Önerileri kesin karar sayma.** Yeni karar alınırsa ilgili belgeleri güncelle; tamamlanmamış işleri tamamlandı yazma.

## PAKET AN — SPOR FORM BUG FIX + YENİDEN KALİBRASYON

Q-184 #1'de doğrulanmış bir production bug düzeltildi ve arkasından spor
dengesi **doğru çalışan motorun üzerinde** yeniden kuruldu. Yanlış çalışan
kod bir denge mekaniği değildir.

### Hata ve düzeltme

`MartialArtsEngine` ders sayacını `'dovus|<artId>'` yazıyor,
`CombatCareerEngine.advanceYear` ise `'<artId>|dovus'` diye okuyordu.
`GameState.interactionKey` iki parçayı **sırayla** birleştirdiği için bu
iki anahtar farklıydı ve "çalışan sporcu formunu daha iyi korur" kuralı
Paket AL'den Paket AM'e kadar **hiç işlemedi**.

Anahtar artık tek yerde kuruluyor:
`app/lib/domain/combat/martial_lesson_counter.dart` →
`MartialLessonCounter.key(artId)`. Yazan da okuyan da onu kullanıyor;
string sırası hiçbir yerde elle tekrar yazılmıyor.

**Eski kayıtlar migrate edilmedi ve edilmesi gerekmiyor:** hatalı olan
okuma tarafıydı, yazma tarafı baştan beri doğru biçimi yazıyordu. Ters
sıralı anahtar için bilerek fallback konmadı — o biçimi hiçbir kod yolu
hiç yazmadı, ve yazılmamış bir biçim için fallback aynı dersi iki kez
sayma riskini bedavaya alırdı.

### Kalibrasyon: nedenin ayrıştırılması

Bug düzelince fazla para nereden geldi? Ayrıştırıldı: kariyer uzunluğu
neredeyse sabit (24 → 26 yıl), maç sayısı +%29, ama **şampiyonluk
+%160**. Para şampiyonluktan geliyordu.

Ayrıca bir düzeltme: Paket AL/2'nin "4,04 M₺ → 6,51 M₺" rakamları
**brüt** ölçümdü. Net tarafta (ders, koç, kamp ve tedavi düşüldükten
sonra) düzeltilmiş motor 4,01 M₺ veriyor — hedef bandın (3,5–5,0 M₺)
içinde. Yani gelir tarafı kalibrasyon istemiyordu; **ödül çarpanlarına
(tier purse, title purse) dokunulmadı.**

Unvan zinciri ölçüldü ve üç halkasından ikisinin no-op olduğu çıktı:

| zincir halkası | 600 sporcuda |
| --- | --- |
| en iyi sıralaması ≤ 2 | 363 |
| itibarı ≥ 70 | 575 |
| **itibarı 100'e doyan** | **530** |
| en üst kademeye çıkan | 570 |

İtibar yalnızca yukarı gidiyor ve tavana doyuyor; eşiği 100 yapmak bile
600'ün 530'unu geçirirdi. Gerçekten seçici tek halka sıralama.

Üç sayı değişti:

| sabit | Önce | Sonra | Gerekçe |
| --- | --- | --- | --- |
| `prototypeOnlyTitleShotRank` | 2 | **1** | Kemer maçına bir numaralı rakip çağrılır |
| `prototypeOnlyTitleShotChance` | 0,40 | **0,30** | 0,40 "kapı açıldıysa kemer maçı kesin"e yaklaşıyordu |
| `prototypeOnlyFormPerLesson` | 1,2 | **1,6** | Uçurum düzeltmesi, gelir ayarı değil |

Ders katsayısı neden değişti: yıllık form kaybı 8 olduğu için telafi 8'i
geçene kadar form çöküyor, geçtiği anda tırmanıyor. 1,2'de yalnızca
derslerden başabaş ≈ 6,7 ders/yıl; yılda 4 ders alan sporcunun formu
kariyer sonunda 14,7'ye iniyordu. 1,6'da başabaş 5 derse indi ve bant
0 → 2,0 · 2 → 6,2 · 4 → **32,0** · 8 → 61,9 oldu. Telafi tavanı (18)
yerinde, yani ders sayısını artırmak formu 100'e kilitlemiyor.

`prototypeOnlyTitleShotReputation` (70) **bilerek değiştirilmedi**: 90
yazmak filtre kurmuş gibi görünüp hiçbir şey yapmazdı.

### Nihai ölçüm — 600 adanmış sporcu, koçsuz kohort

| ölçüm | BUGLU | FIXED RAW | FIXED + KALİBRE |
| --- | --- | --- | --- |
| kariyer sonu form | 38 | 56 | 57 |
| ortalama müsabaka | 31 | 40 | 40,2 |
| medyan kariyer yılı | 24 | 26 | 26 |
| elit/pro | — | %95,0 | %95,0 |
| şampiyon | %8,8 | %33,8 | **%22,0** |
| medyan BRÜT | 3,35 M₺ | 6,45 M₺ | 6,28 M₺ |
| medyan NET | 1,48 M₺ | 4,01 M₺ | **3,82 M₺** |

Şampiyonluk Q-183'ün %18,2 referansına yakın bir yere indi ve imkânsız
olmadı. Net gelir hedef bandın içinde. `paket_al_600_athletes_test`
bağımsız harness'ıyla aynı sonucu veriyor (%21,7).

BUGLU sütunu git history'ye dokunmadan üretiliyor: ölçüm fixture'ı
`advanceYear` öncesi ders sayacını siliyor, yani ders alınıyor, parası
ödeniyor, teknik basamak kazanılıyor ama form motoru dersi görmüyor —
hatanın tam davranışı.

### Sanat tablosu (600 sporcu, kalibrasyon sonrası)

| sanat | elit% | şamp% | ort.maç | medyan yıl | ciddi sakat% | brüt medyan | NET medyan | iyi %10 | kötü %10 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Boks | 89 | 9 | 32,3 | 23 | 49 | 5,42 M | 3,59 M | 6,71 M | 0,24 M |
| Yağlı güreş | 92 | 22 | 38,6 | 27 | 31 | 6,44 M | 4,10 M | 8,14 M | 1,27 M |
| Judo | 97 | 23 | 40,8 | 28 | 34 | 6,28 M | 3,77 M | 6,83 M | 1,12 M |
| Karate | 97 | 26 | 43,8 | 28 | 26 | 6,85 M | 4,25 M | 7,73 M | 1,88 M |
| Taekwondo | 99 | 25 | 43,3 | 29 | 31 | 6,84 M | 4,16 M | 6,88 M | 1,23 M |
| Kung fu | 96 | 27 | 42,7 | 28 | 31 | 5,90 M | 3,35 M | 5,83 M | 0,70 M |

### Brüt değil net (§7)

Rekabete başlayan 600 sporcunun toplamı:

| kalem | tutar |
| --- | --- |
| + müsabaka ödülü | 3.097 M₺ |
| + sponsorluk | 684 M₺ |
| − ders ücreti | 66 M₺ |
| − koç ücreti | 0 (koçsuz kohort) |
| − kamp + tedavi | 1.338 M₺ (kampın liste fiyatı 1.232 M₺) |
| = **NET** | **2.378 M₺** |

Kamp ve tedavi motorun aynı çağrısında tahsil edildiği için cüzdanda
birlikte ölçülüyor; kampın liste fiyatı ayrıca veriliyor.

Başlık kohortu **koçsuz**, çünkü §5'teki "bug öncesi 4,04 M₺" referansı
Paket AL kohortundan geliyor ve o kohort koç tutmuyordu. Koçun bedeli
ayrı ölçüldü ve bir bulgu çıktı: koç başarıyı artırıyor (şampiyon 132 →
175) ama net geliri düşürüyor (3,82 M₺ → 2,70 M₺). Karar Q-186 #3'te.

### Dokunulmayanlar

- Ödül çarpanları: tier purse, title purse, ödül sıklığı — net gelir
  bandın içinde olduğu için gerek yoktu (§8).
- Yıllık maç tavanı (4): gerçekleşen dağılım 40,2 maç / 26 yıl ≈ 1,55
  maç/yıl, yani tavan sorun değil (§9).
- Boks / taekwondo farkı: kendiliğinden daraldı (5,4× → 2,8×), §11
  gereği müdahale edilmedi.
- Paket AM'in sağlık kuralları: kariyere başlama 80, elit terfi 80,
  müsabaka 70 — hepsi yerinde ve testli (§16, §24).
- Q-184'ün diğer maddeleri (aile desteği, okul çatışması, sosyal boost,
  rivalry ün) — §23.

### Testler

- `app/test/paket_an_form_telafisi_test.dart` — 18 koruma testi: kanonik
  anahtar, production yolu, eski kayıt uyumu, çift sayım yok, telafinin
  sınırı, iş yükü, yaş eğrisi, sakatlık kapısı, 80/70 sağlık kuralları.
- `app/test/paket_an_spor_kalibrasyon_test.dart` — 5 ölçüm: A (6 sanat ×
  100), §19 (BUGLU vs kalibre), koç politikası, B (0/2/4/8 ders),
  C (işsiz/part-time/full-time).
- `app/test/paket_al2_entegrasyon_test.dart` — "BİLİNEN BUG" belge testi
  **doğru davranış testine çevrildi** (§21). Bir bug testle sonsuza kadar
  korunmaz.
- `app/test/paket_al_600_athletes_test.dart` — brüt medyan koruması
  12× asgari ücretten **22×**'e yeniden temellendirildi. Gevşetip
  unutulmadı: eski 12x eşiği ölü bir mekaniğin yan ürünüydü, yeni tavan
  ölçülen 18,5×'in hemen üstünde ve dengenin asıl bekçisi artık
  `paket_an_spor_kalibrasyon_test`'teki **net** band.

## PAKET AO — AİLE / İLİŞKİLER V2: DİNAMİK AİLE AĞI

**Ana tasarım kuralı (Faho):** "Aile menüsü bir NPC listesi olmasın.
İnsanların kendi hayatı olsun. AMA hiçbir kişi, sadece hikâye metninde
var olmasın."

### Yeni bağ türleri (enum sonuna eklendi, eski kayıtlar bozulmadı)

`uveyKardes`, `yariKardes`, `uveyCocuk`, `kayinvalide`, `kayinpeder`.
Yeni bir öbek: `RelationGroup.esinAilesi`.

Kan bağı ayrımı `kanBagi` içinde: üvey kardeş ve üvey çocuk çekirdek
ailede listelenir ama kan bağı **değildir**; yarım kardeş kan bağıdır
çünkü bir biyolojik ebeveyn ortaktır.

### Soy kaydı (§14-§15)

`Person.motherId` / `Person.fatherId` eklendi. İkinci bir Person sistemi
kurulmadı; sahte `'player'` sabiti yok, `state.player.id` kullanılıyor.
`lib/domain/models/kinship.dart` akrabalık sorularının tek adresi.

**Kapatılan iki gerçek boşluk:**

1. Yarım kardeş mirastan hiçbir şey almıyordu. Artık **yalnızca ortak
   olan ebeveynden** miras alıyor; üvey bağlar bilerek dışarıda.
2. Üvey kardeş romantik filtreden geçiyordu. Filtre artık yalnızca
   `kanBagi` bayrağına değil, gerçek soy kaydına bakıyor (§16).

### Ebeveyn boşanması (§1-§6)

Düz bir yıllık yüzde değil: aileye özel, gizli bir **dayanıklılık**
(maddi durum, oyuncunun mutluluğu, ebeveyn yakınlığı, ebeveyn
adlarından türeyen sabit aile sapması). Yıllık tavan %5,5, pencere 4-45.

İki ebeveyn de listede **kalır**; hane gerçekten ayrılır; 12-23 yaş
arasında oyuncuya "kiminle kalacaksın?" sorulur; mutluluk etkisi yaşa
bağlıdır (sabit −20 değil).

**Ölçümle bulunan hata:** ilk yazımda 24 yaş üstü oyuncuda iki ebeveyn
de haneden çıkarılıyordu ve hâlâ ailesinin yanında yaşayan bir yetişkin
bir anda "kendi evinde" sayılıyordu — `LivingCosts.livesWithFamily` buna
bakıyor, yani yaşam gideri kayıyordu. Kural tek yönlü yapıldı.

### Erişilemeyen üç motor (ikinci fazda kapatıldı)

Denetim, AO/1'de yazılan üç şeyin oyuncuya **hiç ulaşmadığını** buldu:

- `ParentDivorce.isPending`/`choose` hiçbir ekrandan çağrılmıyordu.
- `ElderCare` hiçbir yerden çağrılmıyordu: dosya vardı, oyunda yoktu.
- Beş yeni bağ hiçbir listeye düşmüyordu: kaydı vardı, ekranda yoktu.

Üçü de bağlandı. Kod yazılmış olması oyunda erişilebilir olması demek
değildir; bu paketin en pahalı dersi buydu.

### İlişkiler ekranı (§38-§39)

Beş aile öbeği: **çekirdek aile / kendi ailem / geniş aile / eşinin
ailesi / geçmiş ilişkiler**, artı aile dışı. Boş başlık çizilmiyor.
Kardeşler kendi sayfasına alındı; öz, üvey ve yarım kardeş bir arada.

Kişi kartına **yaşadığı şehir**, **soy bağı** (annesi/babasi) ve
boşanma varsa **velayet düzeni** satırları eklendi.

`state.children` **değiştirilmedi**: miras, velayet ve kuşak devamı
biyolojik çocuğa bakmaya devam ediyor. Değişen yalnızca ekranın
gösterdiği liste.

### 500 aile hayatı (§49) — yalnızca ölçüm

Genel 3000 hayat denetimi **yapılmadı**. Aile odaklı arketip, 500 tohum.
Oranları güzelleştirmek için ne bot ne kural oynandı.

| ölçüm | sonuç |
| --- | --- |
| Ebeveyn boşanması | %51,4 |
| Üvey ebeveyn geldi | %78,0 |
| Üvey kardeş oluştu | %38,4 |
| Yarım kardeş doğdu | %15,0 |
| Eşin önceki çocuğu | %18,4 |
| Kayın aile kuruldu | %81,0 |
| Oyuncu evlendi | %90,2 |
| Kişi sayısı (medyan) | 62 |

Bozukluk sayaçları: mükerrer kimlik **0**, geçersiz romantik bağ **0**,
kopuk soy kaydı **0**, yaşayan ebeveynde tutarsız yaş **0**.

**Ölçümün açtığı yanlış alarm.** İlk turda 103 "çocuk ebeveyninden
büyük" vakası çıktı. Test gevşetilmedi; sayaç ikiye ayrıldı ve hepsinin
**vefat etmiş** ebeveyn olduğu görüldü. Sebep kaydın kendi anlamı:
vefat edenin yaşı öldüğü yaşta donar ("32 yaşında vefat etti" böyle
saklanır), genç ölen bir ebeveynin çocuğu yıllar sonra o yaşı geçer.
Yanlış olan oyun değil, ilk yazılan değişmezdi. İki sayaç da raporda
duruyor.

### Testler

- `app/test/paket_ao_aile_v2_test.dart` — 48 hedefli test (AO/1, AO/2).
- `app/test/paket_ao_faz2_test.dart` — 16 hedefli test: kendi hayatlar,
  buluşma havuzu, yaşlı bakımı, hane seçimi.
- `app/test/paket_ao_500_aile_test.dart` — §49 ölçümü.

**Yazarken kendini ele veren iki test.** Yeğen testi önce boştu:
üretilen yeğenin kimliği ebeveynin kimliğini taşımıyor, yani iddia her
koşulda doğruydu. İki yönlü yazıldı — yarım kardeşten yeğen **geliyor**
(pozitif kontrol), üvey kardeşten gelmiyor. Pozitif kontrol de ilk anda
kırıldı, ama sebep ürün değil harness'tı: `advanceOneYear` ekranda
çözülmemiş olay varken hiçbir şey yapmadan dönüyor.

### Tam süitin kırdığı üç bekçi — üçü de ölçümle çözüldü

Paket AO tamamlandıktan sonra tam süitte üç test kırıldı. Üçü de tahminle
değil ölçümle incelendi ve üçünde de aynı sonuç çıktı: kırılan şey ürün
değil, **bekçinin kendisiydi**. Hiçbir eşik düşürülmedi.

**1. `paket_ai_abuse` §24 — "para isteme net serveti artırıyor (+108)".**
Para istemek tasarım gereği para verir (harçlık, D-019); net servet
farkının işareti bu saldırıda kuralı değil, o turda açılan rastgele
olayın cebe ne yaptığını ölçüyordu. Paket AO **öncesi** HEAD'de aynı
saldırı 20 tohumda koşuldu: **14 tohumda net servet zaten artıyordu**,
birebir +108 dahil. Bekçi tek tohumla tesadüfen geçiyormuş.

Gevşetmek yerine saldırının asıl koruması iddiaya çevrildi: **mekanik
doyuyor.** 100 denemede de 1000 denemede de kabul sayısı aynı (20 tohumda
da 3). Yeni iddia: kabul ≤ 4 **ve** on kat deneme bir kabul daha
getirmiyor. Diğer altı saldırıda "servet artmasın" bekçisi aynen duruyor.

**2-3. `paket_ag_payback` §16 ve §20 — dağılım kuyrukları.** Hızlı turda
işletme başına 45 hayat koşuluyordu ve işletmeyi gerçekten **açan** hayat
~25'e düşüyordu; yani "kötü %10" sıralı listenin 3. elemanıydı.

| örneklem | serbest yazılım kötü%10 (AO öncesi → sonrası) |
| --- | --- |
| 45 | −0,37 → **+7,79** |
| 150 | −0,33 → +0,30 |
| 300 | −0,29 → +0,30 |

Örneklem 45'ten **600**'e çıkarıldı; eşikler ve istatistik aynen kaldı.

Paket AO'nun bu sayılara dokunmadığı ayrıca **kanıtlandı**: Faz 3'ün tek
simülasyon etkisi yeni bağlara `ChildProgression` çalıştırmaktı ve o
kayıtlar oyuncunun ekonomisine hiç değmiyor. Deney olarak sonuçlar atılıp
yalnızca zar akışı ilerletildiğinde ölçüm birebir aynı çıktı:
**9,416017364203027**, on beş hanesine kadar. Fark tamamen zarın
konumundan geliyordu.

Yan bulgu (gerçek, denge kararı verilmedi): **terzi atölyesi** katalogdaki
en dar dağılım ve §16 sınırına iki ağaçta da en yakın işletme — Paket
AH'nin "işletme seçimlerinin %60'ı terzi" bulgusuyla aynı yöne işaret
ediyor.

### Bilerek yapılmayanlar (§51)

Dev aile ağacı görseli, DNA testi, evlat edinme akışı, velayet mahkemesi
simülasyonu, karmaşık nafaka davaları, aile şirketi, aile içi suç.

### Paket AU: okul kulüpleri, spor geçmişi ve futbol yolu (4 Ekim 2026)

Oynanabilirlik paketi. Okulda bir kulübe girmek, o kulüpte yıllarca
kalmak, rol kazanmak ve bu geçmişin profesyonel futbol kapısını açıp
açmaması tek bir zincir hâline getirildi. **Mevcut sistemler yeniden
kurulmadı:** hobi ilerlemesi `hobby/`, dövüş kariyeri `combat/`, spor
masrafı/çatışması AL/2'de olduğu yerde kaldı; kulüpler kendi klasöründe
(`domain/sports/`) duruyor ve hobi kimlikleriyle var olan ilerlemeye
bağlanıyor.

### Yapılanlar

- **AU/1 — veri.** `data/school_club_catalog.dart`: 13 kulüp, üç kategori
  (spor, akademik, sanat). `models/school_club_progress.dart`: kalıcı
  üyelik kaydı (sezon sayısı, beceri, performans, rol, kaptanlık yaşı,
  dereceler) ve `SquadRole` (Yedek → Rotasyon → İlk 11 → Önemli oyuncu →
  Kaptan). `GameState`'e `schoolClubs` ve `footballCareer` alanları,
  kayda (`game_state_codec`) kodlama/okuma; eski kayıtlar boş listeyle
  yükleniyor.
- **Gizli atletik yatkınlık.** `PlayerCharacter.athleticPotential`
  doğumda bir kez belirleniyor (25-85), **oyuncuya gösterilmiyor**,
  `copyWith` ile değiştirilemiyor, çocuğa miras geçmiyor (kendi zarını
  atıyor). `infertile` alanı bunun emsali.
- **AU/2 — motor.** `sports/school_club_engine.dart`: engel gerekçeleri,
  seçme (tryout), yılda bir antrenman, azalan getirili beceri artışı,
  sezon ilerlemesi, rol değişimi (sezonda tek kademe), ayrılma (kayıt
  silinmiyor, `active: false`), okul değişiminde üyeliğin düşmesi ama
  geçmişin ve becerinin kalması.
- **Seçme saf kura değil, ama kesin de değil.** Puan statlardan ve
  geçmişten geliyor; üstüne 40'lık zar ve puandan bağımsız %8 sürpriz ret
  var. Yani sağlık 100 + yüksek yatkınlık **kabul garantisi değil** —
  kendi testim bunu ilk yazımda yakaladı ve düzeltildi.
- **AU/2 — futbol kapısı.** `sports/football_career.dart`:
  `FootballPath.evaluate` zar atmadan, gerekçeli bir uygunluk kararı
  veriyor (`FootballStage`: geçmişYok → gelişiyor → denemeyeUygun →
  aktifProfesyonel → emekli). Profesyonel futbol **`kJobCatalog` içinde
  bir iş değil** ve `CombatCareer` içine sıkıştırılmadı; kendi modeli
  var. Test bunu ayrıca denetliyor.
- **AU/3 — yıl akışı.** Kulüp sezonu `life_progression` içinde yaş
  artmadan önce ilerliyor; günlüğe satır, dönüm noktalarına bildirim
  yazıyor. Okul değiştiğinde kanca çalışıyor.
- **AU/4 — olaylar.** `data/event_pool_school_clubs.dart`: 29 olay.
  Olayın gereksinimine üç yeni alan eklendi (`requiresActiveClubId`,
  `minClubYears`, `minSquadRole`) ve motor bunları okuyor. Takım arkadaşı
  olayları var olan `sinifArkadasi` bağını kullanıyor; **ikinci bir kişi
  üretim sistemi yok, uydurma isim yok.**

### Bu pakette ÇIKAN iki CI kırmızısı ve kök nedenleri

Commit `8da66c9` CI'da iki testi kırdı (Windows **ve** Ubuntu, yani
platform sorunu değil). Log adları vermiyordu; tam süit ham çıktıyla
yerelde koşularak bulundu.

1. **`family_interaction_test` — "etkileşim sonucu kişi kimliğini
   bozmaz".** Test kişi listesinin **birebir aynı** kalmasını istiyordu.
   Oysa o yıllarda çözülen okul olayları meşru olarak yeni bir arkadaş
   kaydı ekleyebiliyor; kimlikler bozulmuyordu, listeye `arkadas-1`
   ekleniyordu. Varsayım yanlıştı. Test gevşetilmedi, **daha sıkı**
   yazıldı: eski kayıtların hepsi aynı sırada duruyor mu, kimlik alanları
   (ad, soyad, cinsiyet, bağ) değişmiş mi, kimlik tekrarı var mı, sonradan
   eklenen kayıt gerçekten yeni mi. Eski hâli yalnızca annenin bağına
   bakıyordu.
2. **`critical_notice_test` — bir yıldaki bildirim penceresi 8'i aştı
   (9 oldu).** Sınır büyütülmedi. O yılın dökümü ölçüldü: dokuzuncu kalem
   **bir kulüp bildirimi değildi**, aynı yıl açılan **ikinci hedef
   penceresiydi** (seed 1, 18 yaş: düğün davetiyesi, annenin vefatı,
   cenaze, lise bitişi, hastalık, miras, miras anlaşmazlığı ve iki ayrı
   "Bir hedefe ulaştın"). Aynı başlıkla üst üste iki pencere açmak zaten
   bildirim yağmuru; `LifeGoals` artık yılda **tek pencere** açıyor
   ("Hedeflere ulaştın", hedefleri birlikte sayıyor), tek hedefte eski
   metin aynen kalıyor. Yeniden ölçüm: en kötü yıl **8**, ortalama 0,89.

Yani AU hiçbir bildirim eklemedi; havuzu büyüttüğü için rastgele akış
kaydı ve iki eski kırılganlık ortaya çıktı. İkisi de kök nedeninden
düzeltildi.

### Bu pakette YAPILMAYANLAR (dürüst liste)

- **Gerçek 2026-27 lig ve kulüp kataloğu YAZILMADI.** Brief "hafızadan
  yazma, önce resmi kaynağı kontrol et" diyor. Bu oturumun ağ politikası
  **tüm dış adresleri reddediyor** (tff.org, resmi lig siteleri, UEFA,
  Wikipedia dahil hepsi bağlanmıyor). Doğrulanmamış kulüp listesi
  yazmamak için hiç yazılmadı; `docs/FOOTBALL_DATA_SOURCES.md` de bu
  yüzden açılmadı. `paket_au_football_catalog_test` de bu sebeple yok.
- **Spor Kariyeri menüsü ve kulüp kartları (UI) yapılmadı.**
- **PlayerBot kulüplere girmiyor**, dolayısıyla 500 okul odaklı hayatın
  ölçümü ve `paket_au_measurement_test` de yok.
- **Android APK ya da Windows derlemesi bu pakette denenmedi** — yerel
  kapta araç zinciri yok. "Build edildi" denmiyor.

### Sıradaki paketler (yol haritası)

- **AV — Spor Kariyeri arayüzü.** Kulüp kartı (rol, sezon, beceri,
  dereceler), seçme ekranı ve gerekçeli engel metinleri, futbol
  uygunluğunun oyuncuya okunur hâli. Var olan gezinme bozulmadan.
- **AW — bot ve ölçüm.** PlayerBot profiline göre kulüp seçsin (sporcu /
  akademi / sanat), herkes futbolcu olmasın; 500 okul odaklı hayat
  ölçülüp oranlar yazılsın. Güzelleştirme yok, ölçüm.
- **AX — gerçek lig ve kulüp kataloğu.** Ağ erişimi olan bir ortamda
  TFF ve resmi lig/federasyon kaynaklarından 2026-27 listesi
  doğrulanacak, kaynaklar `docs/FOOTBALL_DATA_SOURCES.md`'ye yazılacak.
  Logo, arma, forma ve gerçek oyuncu/teknik direktör adı yok.
- **AY — profesyonel futbol hayatı.** Sezon özeti, sakatlık, form,
  kariyer sonu ve futbol sonrası hayat. Tam sezon simülasyonu, lig
  tablosu, fikstür, transfer pazarı, sözleşme/maaş pazarlığı, Avrupa
  kupaları ve millî takım **bu yol haritasının dışında** kalmaya devam
  ediyor.

## Paket AV: Spor Kariyeri menüsü ve kulüp kartları (4 Ekim 2026)

AU'nun en görünür boşluğu kapandı. AU kulüpleri, rolleri, çok yıllı
geçmişi ve futbol uygunluk kapısını kurmuştu; ama oyuncu bunların
**hiçbirini ekranda göremiyordu**. Kulüp olayları hayat akışında
çıkıyor, takımdaki yeri görünmüyordu.

### Yapılanlar

- **Kulüpler sayfası** (`ui/screens/sections/school_clubs_page.dart`).
  Okul menüsüne `Kulüpler` satırı eklendi; alt yazısı aktif üyeliği
  söylüyor (ör. "Futbol takımı — İlk 11"). Sayfa üç bölüm:
  1. **Üye olduğun kulüpler** — kart başına rol, sezon sayısı, beceri ve
     bandı, kaptanlık yaşı; kart açılınca katılım yaşı/sınıfı,
     performans, yarışma ve derece sayısı, kulübün tanıtım metni.
  2. **Katılabileceğin kulüpler** — sınıfa açık olanlar. Seçmeli kulüp
     "sonuç kesin değil" diye işaretli. Engel varsa düğme **konmuyor**,
     yerine motorun gerekçesi yazılıyor.
  3. **Geçmiş kulüp kayıtların** — ayrılınan ya da okul değişimiyle
     kapanan üyelikler; kaç sezon, beceri, kaptanlık, derece.
- **Antrenman ve ayrılma** karttan yapılıyor. Antrenman yılda bir kez;
  hakkı bitince düğme kaybolup gerekçe yazılıyor. Ayrılma düğmesi kart
  açıkken görünüyor ve "geçmiş kaydın silinmez" diyor — gerçekten de
  silinmiyor.
- **Spor Kariyeri sayfası** (`ui/screens/sections/sports_career_page.dart`).
  Profesyonel futbol bir `kJobCatalog` işi değil; kendi sayfası var.
  Durum kartı uygunluğu, **gerekçesini**, hazırlık puanını, sezon
  sayısını, en iyi beceriyi, başlama yaşını ve kaptanlığı gösteriyor.
  Altında gençlik geçmişi kademe kademe listeleniyor. Scout ilgisi varsa
  ayrı bir satır çıkıyor ve "bu bir teklif değil" diye açıkça yazıyor.
- **Satır yalnızca hak edilince görünüyor.** Futbol geçmişi olmayan
  oyuncuda Spor Kariyeri satırı yok: boş sayfaya götüren menü satırı
  konmadı. Satır hem Okul hem Meslek menüsünde var, çünkü uygunluk 16
  yaşında (lise sırasında) başlıyor ve okul bitince de sürüyor.
- **Denetleyici eylemleri** (`state/game_controller.dart`): `clubBlock`,
  `joinClub`, `canTrainClub`, `trainClub`, `leaveClub`,
  `footballEligibility`. Motorun imzaları **değiştirilmedi** (testleri
  var); antrenmanın geri bildirim metni denetleyicide üretiliyor ve
  beceri hiç artmazsa bu da dürüstçe yazılıyor, "arttı" diye
  uydurulmuyor.

### Ekran yeni kural koymuyor

Katılma engelleri, seçme sonucu, antrenman sınırı ve uygunluk kararı
tamamen motordan (`SchoolClubEngine`, `FootballPath`) geliyor. Sayfa
hiçbir sayıyı kendi hesaplamıyor. Q-192'deki dokuz sayı hâlâ
`prototypeOnly` ve hiçbiri `DECISIONS.md`'ye yazılmadı.

### Henüz yazılmayan, sayfada açıkça söylenen

Profesyonel sözleşme, kulüp seçimi ve sezon akışı yok. Spor Kariyeri
sayfası bunu kendi üstünde yazıyor; sahte düğme konmadı. Gerçek 2026-27
lig ve kulüp kataloğu da **yazılmadı** (ağ politikası tüm dış adresleri
reddediyor; 4 Ekim 05:41 ve 07:1x kontrollerinde tff.org yine 000).

### Doğrulama

`app/test/paket_av_sports_ui_test.dart` — 11 widget testi: menü satırının
varlığı, katılabilir kulüplerin listelenmesi, kartın rol/sezon/beceri
yazması, antrenmanın yılda bir kez açılması (hem düğme hem gerekçe),
antrenmana basınca kaydın gerçekten güncellenmesi, kritik sağlıkta
fiziksel kulübün engelinin gerekçesiyle çıkması, ayrılınca kaydın
geçmişe geçip silinmemesi, futbol geçmişi yokken satırın görünmemesi,
yeterli geçmişte kapının açılması, yetersiz geçmişte gerekçenin yazması
ve profesyonel adımın henüz yazılmadığının söylenmesi.

`flutter analyze` çıkış kodu 0. **Android APK ya da Windows derlemesi bu
pakette denenmedi** — yerel kapta araç zinciri yok; CI derliyor.

## Paket AW: bot kulüp seçiyor, 500 hayat ölçüldü, bir hata bulundu (4 Ekim 2026)

### Bot artık kulüp seçiyor — ve herkes futbolcu olmuyor

`test/support/player_bot.dart` içine `_handleSchoolClubs` eklendi. Bot
kulübü **profiline göre** seçiyor: spor odaklı spor kulüplerine, eğitim
odaklı akademik olanlara, hobi/sosyal odaklı sanat kulüplerine ağırlık
veriyor; ama hiçbir kategori sıfır almıyor, çünkü gerçek oyuncu da hep
aynı şeyi seçmez. **Spor kategorisinde futbol özel muamele görmüyor**,
beş spor kulübü arasından çekiliyor. Antrenman isteği profile bağlı,
bırakma kararı nadir ve İlk 11 ya da kaptanı bırakmıyor.

### ÖLÇÜLEN HATA: okul bitince üyelik kapanmıyordu

İlk ölçüm saçma bir sayı verdi: **toplam sezon medyanı 58, en fazlası
160.** Okul hayatı en çok ~12 yıl kulüp demek.

Kök neden benim AU/3'teki eksiğimdi: `SchoolClubEngine.advanceSeason`
aktif üyeliğin sezonunu, oyuncunun **hâlâ öğrenci olup olmadığına
bakmadan** artırıyordu. `blockFor` "kulüpler yalnızca okula devam
ederken açık" diyordu ama sezon ilerlemesi bu kuralı bilmiyordu. Mezun
olan oyuncunun üyeliği açık kalıyor ve `yearsActive` ömür boyu
artıyordu — 70 yaşındaki karakter hâlâ "okul futbol takımında"
sayılıyordu.

Düzeltme: okul bittiğinde aktif üyelikler kapanıyor (`leftAtAge`
yazılıyor), kayıt **silinmiyor**, günlüğe bir satır düşüyor. Yeni ölçüm:
**toplam sezon medyanı 7, en fazla 24.** İki kalıcı bekçi testi eklendi
(`paket_au_school_clubs_test`): mezun olunca üyelik kapanıyor ve geçmiş
kalıyor; okul bittikten sonra 20 yıl boyunca sezon bir daha hiç
artmıyor.

### İKİNCİ HATA: ölçüm kodum kördü

Düzeltmeden sonra "profesyonel kapı hiç açılmadı" çıktı. Sebebi oyun
değildi, **benim ölçüm kodumdu**: `_handleSchoolClubs` öğrenci değilse
hemen çıkıyordu, oysa profesyonel uygunluk 16-23 yaş aralığında.
Mezuniyet sonrası yıllar (19-23) hiç ölçülmüyordu. Ölçüm bloğu ayrı bir
fonksiyona (`_olcFutbolYolu`) çıkarılıp her yıl çağrılır hale getirildi.

### 500 okul odaklı hayatın sonucu

| Ölçülen | Sonuç |
|---|---|
| Kulübe giren | %87,0 |
| Antrenmana giden | %79,8 |
| Seçmede reddedilen | %9,2 |
| Kulübü bırakan | %11,2 |
| Toplam sezon (medyan / en fazla) | 7 / 24 |
| Kaptanlık yapan | **%0,0** |
| Futbol oynayan | %13,6 |
| Profesyonel kapı açılan | **%0,2** |
| Scout ilgisi gören | %2,6 |
| Hazırlık puanı (medyan / en yüksek) | 47 / 80 |

Kategori dağılımı dengeli: akademi %52,4, sanat %66,9, spor %57,2.
Futbol takımı kulüpler arasında yedinci (%13,6). Arketip ayrımı
çalışıyor: spor odaklı %100 kulüp / %33 futbol, eğitim odaklı %89 / %5.
**Brief'in "herkes futbolcu olmasın" yasağı tutuyor.**

### İki çıkmaz sokak — ölçüldü, Q-192'ye yazıldı, UYGULANMADI

1. **Kaptanlık 500 hayatta hiç olmadı.** Rol puanı eşiği 78 tam sınırda
   duruyor; okul çağında ulaşılabilir en iyi bileşim 69-79 arasında.
   Önerim eşiğin 70'e inmesi; 3 sezon kuralı ve tek kademe sınırı aynen
   kalsın.
2. **Profesyonel kapı 500 hayatta 1 kez açıldı.** Darboğaz eşik değil
   sezon sayısı: futbol oynayanların sezon medyanı 3 ve puanın sezon
   bileşeni `sezon×7`. Önerim eşiği düşürmek değil sezon katsayısını
   `sezon×9` yapmak — "erken başlayıp uzun oynayan geçer" demek bu.

İkisi de oyuncunun hissettiği dengeyi değiştirir, bu yüzden **onay
gelene kadar uygulanmadı** ve `DECISIONS.md`'ye yazılmadı. Ayrıntı ve
alternatifler `docs/DESIGN_REVIEW_QUEUE.md` → Q-192 EKİ.

### Doğrulama

`flutter analyze` çıkış kodu 0; `paket_au_measurement_test` yeşil (500
hayat), `paket_au_school_clubs_test` 24/24 yeşil. **Android APK ya da
Windows derlemesi bu pakette denenmedi.**

## Açık sorular

Q-187: boşanma oranı, üvey kardeşin çocuğunun yeğen sayılmaması, bakım
masrafı, eşin önceki çocuğu oranı, kayın aile yakınlığı, buluşma havuzu
ve velayet kararı. Hiçbiri `DECISIONS.md`'ye yazılmadı.

# Paket AP — aile dramaları ve yetişkin çocukların kendi hayatı V2

Paket AO aileyi statik bir NPC listesinden yaşayan bir ağa çevirmişti ama
aile hâlâ **olup bitenlerin kaydıydı**: boşanıyor, doğuyor, ölüyordu;
oyuncu izliyordu. Paket AP aileyi **oynanan** bir sisteme çevirdi.

## Ne yapıldı

**Çocuğun eşi gerçek bir insan oldu (§14-§18).** `cocugunEsi` ve
`eskiCocugunEsi` bağ türleri eklendi (enum sonuna, sıra bozulmadı);
gelin/damat gerçek bir `Person` kaydı olarak doğuyor, kimliği
evlilikten türediği için aynı evlilik her yıl yeni eş üretmiyor.
`NpcMarriageRecord` ile NPC evlilik durumu (evli / boşandı / dul) ve
geçmiş evlilikler kayda geçiyor. Paket AP öncesi kayıtlarda yalnızca ad
vardı; geriye dönük NPC **uydurulmadı**.

**Çocuğun kendi evlilik hayatı (§19-§23, §50).** Boşanma, yeniden
evlenme ve dulluk. Eski eş kayıttan silinmiyor, torunun soy bağı
bozulmuyor, yeniden evlenen çocuk **yeni** bir kişiyle evleniyor.

**Kuşak devamı korundu (§62-§65, §74).** Bu paketin en kritik yeri:
gelin/damat gerçek bir kişi olduğu anda kuşak devamındaki
`default: return null` dalı onu **sessizce düşürür** hâle geldi — `torun`
bir zamanlar tam olarak böyle kaybolmuştu. Evli çocukla devam edildiğinde
eşi yeni oyuncunun eşi oluyor ve evlilik yürüyen bir kayıt olarak
taşınıyor: "12 yıldır evli insan bekâr başlamıyor".

**Gizli dram eğilimi (§2).** Her hayatın aile dram eğilimi `seed`'den
deterministik türetiliyor, kayda yazılmıyor, oyuncuya gösterilmiyor ve
**yalnızca sıklığı** ölçekliyor. 400 tohumda hem sakin hem hareketli
aile çıkıyor.

**Yılda en fazla bir büyük aile karari (§3).** Tek kapı:
`GameState.canOpenFamilyDecision`. Beş çocuklu oyuncu aynı yıl beş kriz
yaşamıyor.

**Çok yıllı mesele kaydı (§4, §51).** `FamilyIssue`: kim, ne, kaçıncı
yıl, hangi aşama, oyuncu ne cevap verdi. `storyFlags` bu soruları
taşıyamıyordu. Kapanan mesele silinmiyor; liste 40 ile sınırlı ve sınır
aşılırsa en eski **kapalı** meseleler düşüyor.

**Yedi gerçek karar.** Çocuğun okul meselesi (§5-§7), yetişkin çocuğun
para sıkıntısı ve eve dönüşü (§8-§13), kayın aile çatışması (§27),
kardeşle para (§28-§29), yaşlı bakımı (§30-§32), miras itirazı
(§35-§36). Hepsi `GameController` üzerinden ekrana bağlı.

**Para yoktan üretilmiyor (§9, §36, §70).** Her transferde oyuncunun
cüzdanı + bütün kayıtların birikimi toplamı **aynı** kalıyor; masraflı
kararlarda azalıyor, asla artmıyor. 500 hayatlık ölçümde sıfır ihlal.

**Hane değişimi gerçek (§12).** Eve dönen çocuk gerçekten haneye
giriyor ve `LivingCosts` yeni bir gider kalemi görüyor.

**Tavsiye ihtimali kaydırıyor, karar vermiyor (§1, §40-§41).** Oyuncu
çocuğuna "üniversiteye git" diyemiyor; konuşuyor, karar çocuğun
kendisinde kalıyor. Tavsiye yoksa pay **tam olarak 0** ve hiçbir ek zar
atılmıyor — zar sırası korunuyor.

**Stereotip yok (§26).** "Kayınvalide = sürekli sorun" reddedildi: olay
havuzu dört iyi, dört kötü ve kalıcı bir test çıkan olayların
dağılımının tek yöne kaymadığını ölçüyor.

**Torunun soy bağı (§49).** Yeni torun motoru kurulmadı; var olan
motorun boş bıraktığı `motherId`/`fatherId` alanları yazıldı. Eşi
olmayan çocukta ikinci alan boş kalıyor — uydurma kimlik yazılmıyor.

## Ölçüm (§76) — 500 aile odaklı hayat, oran güzelleştirmesi yok

20.392 yıl. Hayat başına aile kararı: medyan 2, p25 1, p75 3, p95 5, en
yüksek 8. 500 hayatın 69'unda hiç karar çıkmadı, 16'sında altı ve üstü.
Mesele türleri: çocuk parası 291, çocuk okulu 278, kardeş parası 259,
bakım 162, miras 111. Bozulma sayaçları sıfır.

## Ölçümün ortaya çıkardığı gerçek hatalar

Hepsi tahminle değil **ölçümle** bulundu ve ürün tarafında düzeltildi:

1. **17 yaşında sisteme giren kişi aynı yıl liseyi bitiriyordu.**
   `ChildProgression` kaydı açtığı yıl bir de sınıf atlatıyordu; kişi hiç
   okumadığı bir yılı geçmiş sayılıyordu ve 17 yaşında `issiz` kalıyordu
   — oyunun "6-17 arası herkes öğrencidir" değişmezi kırılıyordu. Paket
   AO üvey kardeşi bu motora bağlayınca yol açılmıştı; tohum sırası
   örtüyordu.
2. **Aile içinde küslük hiç olmuyordu.** `FriendshipDepth` yalnızca
   arkadaş bağı için çalışıyordu. Sebebi olmayan küslük olmayacak şekilde
   eklendi: 500 hayatta 8 kişi.
3. **Eve dönüş bir yıl sonra kendiliğinden geri alınıyordu.**
   `_childrenLeaveHome` 25 üstü her çocuğu her yıl çıkarıyor; dönüş
   kaydedilmediği için §12 dekoratif kalıyordu.
4. **Bildirim baskısı.** Bütün aile olayları pencere açınca yıllık
   ortalama bildirim 0,99'dan 1,11'e çıktı. Ayrım kondu: soran olay
   pencere açar, haber veren olay günlüğe düşer. Yeniden ölçüm: 0,99.
5. **Stat artışı `Stats.gain` dışından yapılıyordu.** `stat_gain_test`
   yakaladı; oyunun azalan verim kuralı atlanıyordu.

## Eski testlerde düzeltilen sessiz varsayımlar

Hiçbiri "testi yeşil yapmak için" gevşetilmedi; her biri ölçüldü:

* **"Çocuk evli doğmaz"** → §63 evli çocuğun evliliğini taşımayı açıkça
  istiyor. İddia daraltıldı: taşınan evlilik **çocuğun kendi** eşiyle
  olmalı, ölen oyuncunun eşi devralınmamalı.
* **"Aynı çocuk birden fazla kez evlenmiyor"** → §23 yeniden evlenmeyi
  istiyor. İddia **güçlendirildi**: evli çocuk tekrar evlenemez ve her ek
  düğünün kapanmış bir evlilik kaydı olmalı.
* **"Çocuk on yılda on yaşına gelir"** → çocuk ölebilir (ölçüm: 300
  hayatta 0-1). Vefat edenin yaşı ölüm yılında donar. Yan bulgu: aynı
  sınıftaki bir test çocuk ilk yıl ölürse **hiçbir şey sınamadan** yeşil
  kalıyordu; pozitif kontrol eklendi.
* **"Tek yılda gelir maaş+kira+5 milyonu aşamaz"** → varlıklı akrabanın
  mirası tek yılda 21 milyon gelebiliyor. Eşik büyütülmedi, **kural
  değiştirildi**: büyük artış yalnızca o yıl yeni bir miras kapandıysa
  kabul ediliyor.
* **"12. sınıfa ulaşan herkes sınav olayını görür"** → motor bunu hiç
  garanti etmedi ("neredeyse kesin"). Zarsız bir **mekanizma** testi
  eklendi (sınav olayının ağırlığı priority-0 havuzunun onlarca katı) ve
  uçtan uca iddia %90'a çekildi.
* **Bisiklet olayı ve işletme geri ödemesi** → örneklem kurası; pencere
  genişletildi, eşikler aynı kaldı.

## Bilerek yapılmayanlar

NPC-NPC tam sosyal graph, borç geri ödeme takibi, velayet mahkemesi,
miras davası, aile şirketi, dev aile ağacı görseli. Küslüğün sebebi kişi
kartında yazılmıyor: kayıtta sebep yok ve §60 uydurma sebep yazmayı
yasaklıyor.

## Açık sorular

Q-188: yıllık karar sınırı, dram profili bandı, okul meselesi
toparlanma oranları, evdeki yetişkin çocuk gideri, eve dönüş penceresi,
kardeşin verebileceği para, bakım tutarları, miras itirazı oranı, aile
içi küslük oranı, tavsiye payı, hangi olayın pencere açacağı ve torunun
tek ebeveynli doğması. Hiçbiri `DECISIONS.md`'ye yazılmadı. **Q-187
ayrıca açık kalıyor; ona dokunulmadı.**

# Paket AQ — kritik statlar, sağlık 0 tutarlılığı ve düşük stat etkileri

Faho bildirdi: **sağlık 0'a düşüyor ve karakter hiçbir şey olmamış gibi
yaşamaya, spor yapmaya, seyahat etmeye, çalışmaya ve yıllarca yaş almaya
devam ediyor.** Ölçüldü ve bildirilenden ağır çıktı: AQ öncesi ağaçta
(7427107) 500 hayatın 34.121 yılının **7.100'ü** sağlık 0 iken yaşanmıştı.

## Kök neden

İki ayrı şey vardı ve ikisi de ayrı ayrı düzeltildi.

**1) Sağlık 0 olunca hiçbir şey olmuyordu.** Tek tüketici
`Mortality.prototypeOnlyYearlyChance`'ın en çok iki katına çıkan
çarpanıydı — otuz yaşında yıllık ölüm ihtimalini binde 1'den binde 2'ye
çıkarıyor. Bir de bir kerelik günlük satırı. Aktivite, seyahat, estetik,
iş ve okul yollarının **hiçbiri** sağlığı bir durum olarak okumuyordu.
Yan bulgu: `ageUp` ve `advanceOneYear` bekleyen sağlık krizini
denetlemiyordu, yani kriz ekranda asılı kalırken yıllar geçiyordu.

**2) Sağlık 0'a inmek kaçınılmazdı — tek yönlü dişli.** D-116 hastalığın
sağlık bedelini 1-3'ten 10-18'e çıkardı ama toparlanmayı sabit 7'de
bıraktı ve yalnızca **hastalanılmayan** yıllarda çalıştırdı; yani çukuru
açan yıl onu hiç kapatmıyordu. İzole ölçüm (net yıllık sağlık değişimi):
sağlık 25'te **−5,1**, yaş kaç olursa olsun. Ayrıca toparlanma tavanı 71
yaşından sonra `0` dönüyordu — yaşlanmanın kendisi sağlığı 30'un altına
indirmezken tavanın 0 olması kendi kuralıyla çelişiyordu (70-79 yaşta
ortalama sağlık 17,1).

## Ne kuruldu

Yeni bir kriz çerçevesi **kurulmadı**: zorunlu çözüm mevcut
`PendingCrisis` / `HealthCrisisEngine` yolundan geçiyor — aynı pencere,
aynı kayıt alanı, aynı save/load, aynı ölüm geçişi. Katalogda tek yeni
kriz var (`kritik_saglik`, `isCritical`) ve rastgele havuzda yer almıyor.

* **Bantlar** (`CriticalHealth`): 26-100 olağan · 11-25 kritik derecede
  düşük · 1-10 hayati tehlike · 0 acil. Her yere `if (health < 10)`
  kopyalanmadı, tek yerden sorulur.
* **Zorunlu çözüm** sağlık 0'a inince açılır ve çözülmeden yaş
  ilerlemez. Üretim yollarının hepsinden denetlenir: yıl başı, hastalık
  (sebep: hastalık), kronik yıpratma (sebep: rahatsızlık), yıl sonu, olay
  seçimi (sebep: karar), aktivite ve olağan krizin ardından.
* **Kurtulma zar değil**: yaş, taşınan rahatsızlıklar, daha önce atlatılmış
  hayati tehlikeler ve seçim hesaba katılır. Üç seçenek: acil servis
  (bedelsiz, her yaşta açık), özel tedavi (240.000 ₺), evde bekle.
  Kurtulan karakter 10-25 bandında açılır — ne 100 ne 1.
* **Tek ölüm**: yaşa bağlı ölüm bekleyen krizi kapatır, kriz ölümü olağan
  ölüm yolundan geçer. 500 hayatta çifte ölüm **0**.
* **Dişli düzeltmesi**: toparlanma artık her yıl işler (hastalığın bedeli
  önce uygulanır, pay kalan açığa göre hesaplanır), payı çukurla büyür
  (%35, yıllık tavan 14, 70 üstü yarım) ve tavanı yaşlanmanın kendi
  tabanının altına düşmez.
* **Düşük sağlıkta**: ağır eylem kapanır (koşu, ağırlık, cezaevi sporu —
  hafif yürüyüş ve esneme açık), 3 geceden uzun tur kapanır, elektif
  estetik 1-10'da kapanır ve 11-25'te mevcut risk motoru 1,8 kat çalışır.
  **Sağlık merkezi hiçbir bantta kapanmaz.**
* **Diğer statlar**: mutluluk Paket AQ'dan önce hiçbir sistemin girdisi
  değildi — zam/terfi ve okul ortalamasına kondu, karşı ağırlık olarak
  dipte eğlencenin getirisi artırıldı (sarmal yok). Karizmanın tek boşluğu
  mülakattı; ikinci şansı ölçeklendiriyor. Görünüş ve zekâda boşluk
  bulunamadı, dokunulmadı. Hiçbir stat 0'ı ölüm üretmiyor.

## Ölçüm (A/B, aynı 500 tohum, aynı düzenek)

| | AQ öncesi | AQ sonrası |
|---|---|---|
| tamamlanan hayat | 373 / 500 | **437 / 500** |
| sağlık 0 iken yaşanan yıl | **7.100** | **156** (hepsi çözüm bekliyor) |
| ortalama ölüm yaşı | 64,5 | **68,0** |
| p25 / medyan / p75 | 57 / 67 / 75 | 65 / 71 / 75 |
| 60 yaş öncesi ölüm | %29,8 | **%15,6** |
| 80+ | %2,4 | %1,4 |

500 tam hayat (34.733 yıl): sağlık 0 gören hayat 110 (%22,0), ilk 0 yaşı
medyan **73**, kritik durumdan kurtulma %38,5. Hedefi sıfır olan
sayaçların tamamı sıfır. Bant dağılımı: olağan %94,2 · kritik düşük %2,5
· hayati tehlike %2,8 · acil %0,4. Düşük sağlıkta rapor oranı %24,8
(yüksek sağlıkta %6,9). Karizma, görünüş ve zekâ **hiçbir** yılda 0
görülmedi — yaşlanma tabanları tutuyor.

## Yol boyunca çıkan gerçek hatalar

* **Yıl sonu kaçağı** → işletme zararı, adli süreç ve yarım zamanlı iş
  sağlığı yıl içindeki denetimden **sonra** düşürüyordu (tohum 56, yaş
  73). Yıl kapanmadan son bir denetim eklendi.
* **Olay seçimi kaçağı** → 500 hayatın 20'sinde olay seçimi sağlığı 0'a
  indiriyor ve oyuncu yıl ilerletmeden sağlık kazandıran bir aktiviteye
  gidip durumu sessizce kapatabiliyordu. `EventEngine.resolve` ve
  `ActivityEngine.perform` de denetliyor.
* **Değer ayrıntısı penceresi taşıyordu** → yeni durum satırları gelince
  360 px / yazı ×1,5'te 560 piksel taştı (ölçüldü; AQ öncesi taşmıyordu).
  Pencere artık kendi içinde kayıyor.
* **Değişmez fazla katıydı** → "sağlık 0 + bekleyen **kritik** durum yok"
  yanlış iddiaydı: ekranda olağan bir kriz varken de oyuncu ilerleyemiyor
  ve kriz kapanınca kritik durum devralıyor. Koşul doğrusuna çevrildi.

## Bilerek yapılmayanlar

Generic "all stats condition framework", ikinci bir hastane akışı, ayrı
bir devamsızlık/sınıf tekrarı sistemi, kritik krizden sonra rastgele
kronik tanı, NPC'ler için ayrıntılı sağlık simülasyonu, kritik durumun
süresini tutan yeni bir kayıt alanı. `Mortality`'nin düşük sağlık
çarpanına **dokunulmadı**: çifte sayım şüphesi ölçüldü ve ortalama ölüm
yaşını hiç değiştirmediği görüldü.

**Hiçbir sürüm gerçek Windows veya Android cihazda oynanmadı.**

## CI'ı yiyen sonsuz döngü (Paket AQ'nun yan ürünü)

Paket AQ'dan sonra CI iki kez **tam süre bütçesinde** iptal oldu ve
logda tek bir hata yoktu. İlk okuma "süit uzadı, bütçe yetmiyor" oldu ve
bütçe 45'ten 120'ye çıkarıldı. **O teşhis yanlıştı.**

Gerçek sebep logdaki sessizlikti: Windows işinde 06:19:25 ile 08:12:52
arasında neredeyse iki saat boyunca tek satır çıktı yok. Bu yavaşlık
değil, takılmaydı. Üç test sonsuz döngüye giriyordu — `end_to_end_test`
senaryo 8, `event_catalog_test` tekrar kalitesi, `health_package_test`
hastalık ömrü. Üçü de her yıl bekleyen sağlık krizini silip (ya da hiç
bakmayıp) `advanceOneYear`'ı yeniden çağırıyor; Paket AQ sağlık 0 iken
yaş almayı durdurduğu için yaş hiç ilerlemiyordu.

Dart'ın test zaman aşımı bunu yakalayamaz: `senaryo 8`'in üstünde zaten
`Timeout(minutes: 5)` vardı ve hiç tetiklenmedi, çünkü senkron bir
`while` döngüsü hiç yield etmiyor. Bu sınıf hatanın tek savunması
döngünün kendi ilerleme kontrolü.

Çözüm `app/test/support/corpus_year.dart`: tek bir yıl adımı. Sıradan
kriz yine atlanıyor (ölçülen şey o değil), **kritik kriz silinmiyor,
`HealthCrisisEngine` üzerinden cevaplanıyor** — ölçüm hayatları da
oyuncunun geçtiği yoldan geçiyor. Yıl ilerlemezse `StateError` atıyor.
Takıldığı kanıtlanan üç dosya ve aynı deseni taşıyan ikisi
(`stat_aging_test`, `city_school_work_test`) buna bağlandı.

Bütçe 120'den **60**'a indirildi: 120 kalması bir sonraki takılmayı iki
saat saklardı. Düzeltmeden sonra ölçülen gerçek CI süresi **18 dakika**
(Windows 17 dk 49 sn, Android 17 dk 5 sn — süit + build dahil), yani
"süit 80 dakikaya çıktı" iddiası da yanlıştı.

Hiçbir test silinmedi, atlanmadı, gevşetilmedi; ürün kodu değişmedi.

## Paket AR: ölü hikâye izleri ve kırık rol kilitleri (3 Ekim 2026)

`docs/EKSIKLER.md` §7'nin birinci maddesi: "Ölü hikâye izlerini araştır —
10 iz hiç konmuyor." Araştırıldı; **gerçek bir üretim hatası** çıktı.

### Ne ölçüldü

40 kapsam hayatı (5 plan × 4 tohum × 2 denetim), olaylar oynanarak.

| Ölçüm | AR öncesi | AR sonrası |
| --- | --- | --- |
| İz arayan olay | 67 | 67 |
| Bunlardan hiç ekrana gelmeyen | 13 | **10** |
| └ OYUN (aday havuza bile giremeyen) | 4 | **1** |
| └ BOT (izi koyan seçimi bot seçmiyor) | 6 | 2 |
| └ NORMAL (aday oldu, ağırlık kurasını kaybetti) | 6 | 7 |
| Aday havuza giren farklı olay | — | 380 |
| Konan ama hiçbir olayın okumadığı iz | 38 | 38 |

Sınıflandırma **ölçülüyor, çıkarsanmıyor**: ilk denemede "iz zamanında
kondu, demek ki kurayı kaybetti" diye varsaymıştım ve sonuç yanlış çıktı.
`EventEngine.debugEligibleIds` her yıl çağrılarak olayın gerçekten aday
havuza girip girmediği soruldu; cevap 0 OYUN'u 4 OYUN'a çevirdi.

### Bulunan hata

Motor bir kişiyi hikâye rolüne yalnızca **olayın bir kişisi varsa**
kaydeder (`event_engine.dart`: `bondTargetId == null` ise `storyPeople`
yazılmaz). Dört zincirin ilk halkası `rememberPersonAs` taşıyordu ama
olayların hiç kişi koşulu yoktu. Rol sessizce kaydedilmiyor, o rolü arayan
bütün devam halkaları **her oyuncuda** ömür boyu ulaşılamaz kalıyordu.
Bot sınırı değil, üretim hatası.

Üçü düzeltildi:

- `suc_arkadasin_teklifi` — metin "**Arkadaşın** sesini alçalttı" diyor;
  yaşayan arkadaş koşulu eklendi. `suc_teklif_ikinci_kez` OYUN → BOT
  (yol açıldı, botun seçmediği suç seçimi kaldı), `suc_teklifi_ihbar`
  listeden tamamen düştü.
- `suc_borc_istendi` — metin "Bir **tanıdık** kapıya geldi" diyor; aynı
  koşul eklendi. `suc_borc_odenmedi` ve `suc_borc_hukuk` açıldı.
- `yaz_isi` — kilitlediği rolü **hiçbir olay aramıyordu**; iki yönden ölü
  bildirim ve artık boş kalan `ExtraRoles` sınıfı kaldırıldı.

Dördüncüsünde ayrıca rol yanlış seçimdeydi: kavgadan **çekilen** seçimde
duruyordu, oysa devam olayı kavganın gerçekten olmasını istiyor — rol
doğru kişiye bağlansa bile halka açılamazdı. Rol kavgaya giren seçime
taşındı. Halka hâlâ uykuda: karşı taraf kayıtlı bir kişi değil ve onu
kayda geçirmek tasarım kararı istiyor (**Q-190**).

### AR/3 — teşhis dört sınıfa çıktı ve kura tabanı ölçüldü

"BOT" etiketi iki ayrı şeyi gizliyordu. Ayrıldı:

- **ZİNCİR** — izi koyacak **olay** hiç ekrana gelmedi. Sorun botun
  seçimi değil, zincirin derinliği.
- **BOT** — olay geldi ama bot başka kolu seçti. Yol açık.

Bu ayrım `zincir_ogretmen_3`'ü BOT'tan ZİNCİR'e taşıdı ve asıl soruyu
ortaya çıkardı. Kura tabanı ölçüldü (21.307 oyun yılı):

| Ölçüm | Değer |
| --- | --- |
| Yıllık aday havuz boyutu | ortanca 80 olay (ortalama 73,7; en çok 112) |
| Yıllık toplam etkin ağırlık | ortanca 268 |
| Ağırlık 4'lük halkanın yıllık payı | %1,5 |
| Ağırlık 5 | %1,87 |
| Ağırlık 7 | %2,62 |

Öğretmen zinciri (beş olay yazılmış, 10 → 45 yaş): 1. halka ~%4,4,
2. halka %7,3, 3. halka %28,2 — ve bunlar her halkada kol seçme
ihtimaliyle **çarpılıyor**. 3. halkaya ulaşma ihtimali kabaca **on binde
bir**. Yazılmış içeriğin karşılığı alınmıyor.

Bu bir denge kararı, teknik hata değil: **Q-191**'de öneri (devam
halkalarına ×8 katsayı) ve ölçüm birlikte duruyor. **Uygulanmadı** —
Faho Windows paketini test ettirirken temponun altından değişmemesi için.

### Kalıcı bekçiler

`app/test/paket_ar_rol_bekcisi_test.dart` — dört iddia: rol kilitleyen her
seçimin kilitleyecek bir kişisi var; aranan her rolü kilitleyen bir seçim
var; kilitlenen her rolü arayan bir olay var (ölü rol yok); istenen bağ
türü tanınan bir tür. Q-190 kararını bekleyen tek halka `kKararBekleyen`
listesinde adıyla duruyor; liste büyümeyecek.

`app/test/paket_ar_hikaye_izi_test.dart` — aranan her izin bir üreticisi
var; sessiz iz sayısı 38'i geçemez. Motor tarafında konan izler **elle
yazılmıyor, `lib/` taranıyor**: elle tutulan ilk liste `evlendi` izini
atlamış ve test canlı bir izi "hiç konmuyor" sanıp yanlış hata vermişti.

`app/test/paket_ar_zincir_teshis_test.dart` — teşhis koşusu; sayı iddia
etmez, yalnızca ölçümün çalıştığını iddia eder.

Ürün dengesi değişmedi; hiçbir test silinmedi, atlanmadı, gevşetilmedi.
Doğrulama: `flutter analyze` çıkış kodu 0; suç, zincir, katalog ve iz
testleri (70 test) yeşil. **Android APK ya da Windows derlemesi bu
pakette denenmedi** — yerel kapta Android SDK ve Windows araç zinciri yok.

## Paket AS/1: "sessiz iz" sayısı yanlış şeyi sayıyordu (3 Ekim 2026)

AR/1'in **38 sessiz iz** ölçümü abartılıydı. O test yalnızca katalog
olaylarının `requiredFlags`/`forbiddenFlags` listesine bakıyor; motorun
`state.storyFlags.contains(...)` ile okuduğu izleri saymıyordu.

Ayrım yapıldı ve iki bağımsız taramayla (Dart testi ve ayrı bir betik)
aynı sonuç çıktı:

| Sınıf | Sayı | Anlamı |
| --- | --- | --- |
| Katalogda aranmayan iz | 38 | — |
| **MEKANİK** | **6** | Motor okuyor, etkisi var, anlatısı yok |
| **GERÇEKTEN SESSİZ** | **32** | Hiçbir yer okumuyor; yazılan iz boşa gidiyor |

Mekanik olanlar: `sinav8_kaygi` / `sinav8_destek` / `sinav12_kaygi` /
`sinav12_destek` (`EducationPath` sınav puanına ∓4 veriyor),
`iste_sorumluluk_aldi` (`CareerProgress`), `kurs_destegi`
(`CourseProgress` — iz varken yılda 4 ders ücretsiz). Bunlar eksik içerik
değil; hikâye karşılığı olmayan mekanik.

Bekçinin ölçütü 38'den **32**'ye indirildi: artık doğru şeyi sayıyor ve
daha sıkı.

### Yol boyunca iki tarama hatası (ikisi de kendi yazdığım kodda)

**1. Noktasız sabit.** İlk tarama yalnızca `Sinif.sabit` biçimini
arıyordu; aynı sınıf içinden kullanılan `storyFlags.contains(flagX)`
biçimini kaçırdı ve `iste_sorumluluk_aldi` ile `kurs_destegi` yanlışlıkla
"kimse okumuyor" sayıldı. Bağımsız betikle karşılaştırınca fark çıktı.

**2. Çakışan ad kendini eziyordu.** Sabit haritası ad → tek değer olarak
kuruluydu, bu yüzden çakışmayı bildiren test **0** basıyor ve yanlış
güven veriyordu. Harita ad → **değer kümesi** yapıldı; gerçek sayı 6:

| Ad | Değerler |
| --- | --- |
| `borcVerdi` | `orta_borc_verdi` \| `suc_borc_verdi` \| `zincir_borc_verdi` |
| `arkadasaYardimEtti` | `arkadas_zor_gunde_yaninda` \| `arkadasa_yardim_etti` |
| `isyerindeSustu` | `suc_isyerinde_sustu` \| `zincir_isyerinde_sustu` |

Üç ayrı sınıfta aynı Dart adının farklı izleri var. Ada güvenen bir
denetim bunları tek iz sanar ve "bu iz okunuyor" diye yanlış rapor verir —
tam olarak AR paketinin bulduğu hata sınıfı. Yeni test bu tuzağı sabitler
ve belirsiz adları **okunmuş saymaz** (denetimi gevşetmemek için
muhafazakâr taraf).

### Bundan sonrası

32 sessiz iz, yazılmış ama karşılığı olmayan içerik: `bosandi`,
`cocuk_sahibi`, `bekar_yalnizligi_secti` (dört seçim besliyor),
`bekar_tanismayi_erteledi` (üç seçim), `bebeklik_*`, `esle_susuldu`,
`torunla_vakit`, `zam_istendi`… Bunları okuyan olayları yazmak tasarım
kararı istemiyor: iz zaten konuyor, eksik olan onu okuyan taraf. Sıradaki
içerik paketinin hedef listesi bu.

## Paket AS/2: Q-190 ve Q-191 uygulandı, sessiz izlere karşılık yazıldı (3 Ekim 2026)

Faho sohbette iki kararı onayladı; ikisi de uygulandı ve **ölçüldü**.

### Q-191 — zincir devam halkalarına ×8 ağırlık

`EventEngine.prototypeOnlyChainContinuationBoost = 8` (`prototypeOnly`).
Oyuncunun `requiredFlags`'ı karşılanmış olayları — yani zaten açtığı
devam halkaları — ağırlığını ×8 alıyor. İlk halka normal ağırlıkta
yarışır, yani **zincire girme ihtimali değişmedi**; değişen, girdikten
sonra devamını görme ihtimali. Dönüm noktası katsayısının (×120) çok
altında. Tekrar sönümü ve `forbiddenFlags` üstüne çalışmaya devam ediyor:
halka bir kez çıkınca havuzdan düşer.

### Q-190 — kavga ettiğin kişi kalıcı tanışıklık kaydı

`suc_gece_tartismasi/karsilik_ver` artık `startsFriendship` ile kişi
üretiyor; `rememberPersonAs` onu `kavgaKarsisi` rolüne kilitliyor ve
`suc_kavga_karsisindaki` yıllar sonra aynı kişiyle açılıyor. Bekçi
testindeki `kKararBekleyen` listesi kaldırıldı.

### AS/2 — yankı olayları

Yeni dosya `app/lib/data/event_pool_echo.dart`: **10 olay**, hepsi var
olan ama hiç okunmayan bir izi okuyor. Yeni mekanik yok; kurulum zaten
yazılmıştı, eksik olan sonucuydu.

| Yankı | Okuduğu iz | Neden önemli |
| --- | --- | --- |
| `yanki_bosanma_yil_donumu` | `bosandi` | Boşanıyordun, oyun bir daha hiç anmıyordu |
| `yanki_ilk_ebeveynlik` | `cocuk_sahibi` | Baba/anne oluyordun, yankısı yoktu |
| `yanki_ilk_gun_hatirlandi` | `cocuk_ilk_gun_yalniz` | Çocuğun okulun ilk günü yalnız kalmıştı |
| `yanki_yalnizlik_muhasebesi` | `bekar_yalnizligi_secti` | Dört ayrı seçim besliyordu |
| `yanki_ertelenen_tanisma` | `bekar_tanismayi_erteledi` | Üç ayrı seçim besliyordu |
| `yanki_susmanin_bedeli` | `esle_susuldu` | Tartışmada susmuştun |
| `yanki_zam_sonucu` | `zam_istendi` | Zam istemiştin, cevabı gelmiyordu |
| `yanki_borc_geri_dondu` | `orta_borc_verdi` | Borç vermiştin, geri dönmüyordu |
| `yanki_torun_buyudu` | `torunla_vakit` | Torunla geçen gün hatırlanmıyordu |
| `yanki_dolandirici_tekrar` | `dolandiriciya_kanmadi` | Kanmamıştın, tekrar denenmiyordu |

### Ölçülen sonuç

| Ölçüm | Önce | Sonra |
| --- | --- | --- |
| İz arayan 67 olaydan hiç ekrana gelmeyen | 10 | **0** |
| └ OYUN (aday bile olamadı) | 1 | 0 |
| └ ZİNCİR (önceki halka hiç çıkmadı) | 1 | 0 |
| └ BOT (olay geldi, kol seçilmedi) | 1 | 0 |
| └ NORMAL (aday oldu, kurayı kaybetti) | 7 | 0 |
| Aday havuza giren farklı olay | 380 | 392 |
| Yıllık toplam etkin ağırlık (ortanca) | 268 | 318 |
| Yıllık aday havuz boyutu (ortanca) | 80 | 80 |
| Hiçbir yerin okumadığı iz | 32 | **22** |

Havuz boğulmadı: aday sayısı aynı kaldı, toplam ağırlık %19 arttı ve
**daha fazla** farklı olay ekrana geldi.

### Kalıcı bekçiler

`app/test/paket_as_yanki_test.dart` — altı iddia: yankı havuzu boş değil;
her yankı **var olan** bir izi arıyor (uydurma iz = sessizce ölü içerik);
her yankı kendi tekrarını engelliyor ve **her kol** kapanış izini koyuyor;
kimlikler tekil; sonuç metinleri var ve 260 karakterin altında
(`docs/WRITING_STYLE_TR.md` §8); yasak kalıp ve yasak sokak ağzı yok (§2,
§6).

`paket_ar_hikaye_izi_test.dart` ölçütü 32'den **22**'ye sıkılaştırıldı:
kazanım geri alınamaz.

Doğrulama: `flutter analyze` çıkış kodu 0; iz, rol bekçisi, yankı,
katalog, çeşitlilik, öncelik ve zincir testleri yeşil. Tam süit koşuyor.
**Android APK ya da Windows derlemesi bu pakette denenmedi** — yerel kapta
araç zinciri yok, CI'da derlenir.

## Paket AT: 9-12 yaş boşluğu — oyunun ilk on dakikası (3 Ekim 2026)

**Neden bu iş.** Oynanabilirliği artırmak için nereye yazılacağı
tahminle değil ölçümle seçildi. Olay havuzu yaş başına sayıldı ve
"kapısız" olaylar ayrıldı — kapısız olay, iz/kişi/sahiplik/iş/okul
koşulu olmayan, yani neredeyse her oyuncuda çıkabilen olay.

| Yaş | Olay | Kapısız (önce) | Kapısız (sonra) |
| --- | --- | --- | --- |
| 0 | 31 | 1 | 1 |
| 6 | 46 | 9 | 9 |
| 9 | 73 → 86 | 15 | **29** |
| 10 | 73 → 93 | 15 | **29** |
| 11 | 75 → 95 | 16 | **30** |
| 12 | 75 → 95 | 14 | **28** |
| 17 | 111 → 112 | 22 | 22 |
| 40 | 271 | 78 | 78 |

İki bulgu: çocukluk orta yaşın onda biri kadar kapısız içerikle
açılıyordu, ve `event_pool_childhood.dart` 1-8 ile 13-15 yaşlara
yoğunlaşmış, **9-12 arası tamamen boştu.** Oysa bu dönem oyunun ilk on
dakikası ve her oyuncunun gördüğü tek bölüm.

**Yeni dosya:** `app/lib/data/event_pool_schoolyears.dart` — 9-12 yaş,
**20 olay**. Dönemin karakteri: çocuk ilk kez kendi başına bir şey
yapıyor. Henüz işi, parası ya da ilişkisi yok; elindeki tek şey
kararları.

Okul tarafı: karne günü, tahta nöbeti, ödev kopyası, beden dersinde
takım seçimi, sınıf gezisi parası. Para tarafı: ilk kez yalnız markete
gönderilme, bakkal veresiyesi, bir şey için biriktirme. Mahalle ve ev:
bisikletle mahalle sınırı, sokak kedisi, üst kata taşınan çocuk, ekran
süresi kavgası, sofra kurma, ilk kalın kitap, yaz tatilinde kuzenler.

**İçinde dört küçük zincir var ve hepsi kendi izini kendi okuyor:**
sorumluluk aldıysan tören görevi gelir; ödev kopyaladıysan tahtaya
kalkarsın; veresiye aldıysan defter kapanır; biriktirdiysen kutu dolar
ve o alışkanlık ergenlikte geri döner. Dışarıya sessiz iz
bırakılmadı — bekçi testi ilk denemede bir tanesini yakaladı
(`birikimTamamlandi` okunmuyordu) ve karşılığı yazıldı.

**Ölçülen sonuç (40 kapsam hayatı):** iz arayan olay 67 → 83, bunlardan
hiç çıkmayan 4, **OYUN sınıfı 0** — yani kırık zincir yok. Aday havuza
giren farklı olay 392 → 411.

Çıkmayan dördü ve nedenleri:
- `yanki_yalnizlik_muhasebesi`, `yanki_ertelenen_tanisma` — okudukları
  izler **bekâr kalan** oyuncuda konuyor ("evli değil ve ilişkide
  değil" şartı). Kapsam botu her hayatta evleniyor, bu yüzden iz hiç
  konmuyor. Gerçek oyuncu için erişilebilir ama **botla ölçülemiyor**;
  bu bir ölçüm boşluğu, oyun hatası değil.
- `zincir_ogretmen_3` — ZİNCİR'den **BOT**'a geçti: önceki halka artık
  ekrana geliyor (Q-191'in etkisi), bot sadece o kolu seçmiyor.
- `savundugun_arkadas` — aday oldu, ağırlık kurasını kaybetti. Nadir.

Hâlâ fakir kalan bant **0-6 yaş** (1-9 kapısız olay). Bebeğin karar
alanı doğası gereği dar; yine de sıradaki içerik boşluğu burası.

Doğrulama: `flutter analyze` çıkış kodu 0; iz, yankı, rol bekçisi,
katalog ve zincir testleri yeşil (46 test). **Android APK ya da Windows
derlemesi bu pakette denenmedi** — yerel kapta araç zinciri yok.

## Açık sorular

Q-189: sağlık bantları, kurtulma eşikleri, kurtulma sonrası sağlık bandı,
toparlanma payı ve tavanı, düşük sağlıkta kapanan eylemler, iş tarafı
etkisi, mutluluk motivasyon çarpanı, karizmanın mülakattaki payı,
`Mortality` çarpanı, 80+ oranındaki düşüş ve özel tedavi ücreti. Hiçbiri
`DECISIONS.md`'ye yazılmadı. **Q-187 ve Q-188 ayrıca açık kalıyor; ikisine
de dokunulmadı.**

**Q-192 yeni ve açık:** okul kulüpleri ile futbol yolunun dokuz sayısı
(aktif kulüp sınırı, seçme eşiği, yatkınlığın ağırlığı, beceri büyüme
hızı, profesyonel için asgari geçmiş, scout sıklığı, giriş yaşı,
kaptanlık eşiği, okul-kulüp çatışması). Hepsi `prototypeOnly`; hiçbiri
`DECISIONS.md`'ye yazılmadı.

Q-190 ve Q-191 **kararlaştırıldı** (3 Ekim 2026, Faho onayladı) ve
uygulandı; ayrıntı yukarıdaki Paket AS/2 bölümünde. Kuyrukta kalan tek
açık grup Q-189 ile Q-187/Q-188.

## Depo sınırı
Yalnızca `fahrettinkoksal/bir--m-r` üzerinde çalış. Hipopotamya organizasyonundaki hiçbir depoya dokunma.
