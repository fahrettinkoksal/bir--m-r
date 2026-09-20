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

## Sonraki tasarım işleri
İlk çalışan dikey kesit doğrulandıktan sonra olay verisi ve sürekliliğini genişlet, aile, eğitim, kariyer, ekonomi, sosyal medya/Ün sistemlerini aşamalı ayrıntılandır. Kesin sayısal denge ve teknoloji hâlâ açık.

## ChatGPT / Claude devri
Yeni oturumda `DECISIONS.md`, bu dosya, `docs/PROTOTYPE_UI.md`, `docs/CLAUDE_PROTOTYPE_TASK.md` ve ilgili sistem belgelerini oku. **Önerileri kesin karar sayma.** Yeni karar alınırsa ilgili belgeleri güncelle; tamamlanmamış işleri tamamlandı yazma.

## Depo sınırı
Yalnızca `fahrettinkoksal/bir--m-r` üzerinde çalış. Hipopotamya organizasyonundaki hiçbir depoya dokunma.
