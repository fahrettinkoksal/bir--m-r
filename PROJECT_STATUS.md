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

## Sonraki tasarım işleri
İlk çalışan dikey kesit doğrulandıktan sonra olay verisi ve sürekliliğini genişlet, aile, eğitim, kariyer, ekonomi, sosyal medya/Ün sistemlerini aşamalı ayrıntılandır. Kesin sayısal denge ve teknoloji hâlâ açık.

## ChatGPT / Claude devri
Yeni oturumda `DECISIONS.md`, bu dosya, `docs/PROTOTYPE_UI.md`, `docs/CLAUDE_PROTOTYPE_TASK.md` ve ilgili sistem belgelerini oku. **Önerileri kesin karar sayma.** Yeni karar alınırsa ilgili belgeleri güncelle; tamamlanmamış işleri tamamlandı yazma.

## Depo sınırı
Yalnızca `fahrettinkoksal/bir--m-r` üzerinde çalış. Hipopotamya organizasyonundaki hiçbir depoya dokunma.
