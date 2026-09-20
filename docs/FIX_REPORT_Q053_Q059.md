# Tespit raporu — Q-053–Q-059 kararlarına göre PR #14–#18

Bu rapor, **D-031…D-038** kararları alındıktan sonra PR #14–#18'deki kodun
tarandığı sonuçları içerir. **Bu turda kod değiştirilmedi**; burada listelenen
maddeler ayrı bir düzeltme PR'ında ele alınacaktır.

Taranan kod: `claude/paket5-olum-miras` (PR #18) — beş paketin tamamı.

Öncelik ölçütü:
- **A — Veri kaybı riski**
- **B — Karara açıkça aykırı**
- **C — İzlenecek / denge ayarı (karar bekliyor)**

---

## A. Veri kaybı riski

### A1 — Yeni hayat, tamamlanmış hayatın kaydını siliyor
**Karar:** D-037 — "Oyuncu öldüğünde hayat özeti **Geçmiş Hayatlar** arşivine
güvenli biçimde kaydedilebilmeli; yeni hayat başlatma işlemi geçmiş hayat
özetini **habersizce silmemeli**."

**Kod:** `app/lib/state/game_controller.dart` — `clearLife()` yalnızca bellekteki
durumu boşaltıyor; ardından `startNewLife(...)` çağrılınca `_autoSave()` aynı tek
kayıt dosyasının üzerine yazıyor. Arşiv yok.

**Sonuç:** Oyuncu ölüp yeni hayata başladığında **tamamlanmış hayatın özeti
kalıcı olarak kayboluyor**. Şu an ekranda "Bu hayatın kaydı silinir. Devam
edilsin mi?" onayı var, yani sessiz silme değil; ama D-037'nin istediği arşiv
altyapısı yok.

**Önerilen düzeltme (ayrı PR):** Kayıt dosyasında tek aktif hayatın yanında
`pastLives` listesi tutan bir arşiv alanı (özet verisi: ad, ölüm yaşı ve sebebi,
eğitim/meslek, varlık özeti, günlükten seçilmiş satırlar). Yeni hayat
başlatılırken tamamlanan hayatın özeti **önce arşive yazılır**, sonra aktif kayıt
yenilenir. Kayıt biçimi sürüm 12 + göç adımı.

---

## B. Karara açıkça aykırı

### B1 — Ehliyet sınavı tek soru soruyor
**Karar:** D-035 — "Sınav her başvuruda **3 kısa soru** sorar; **en az 2 doğru**
cevapla geçilir. Sonuçta doğru cevaplar ve kısa açıklamaları gösterilir. Oyun
sınav ortasında kapatılırsa **aynı sorulardan devam edilir**."

**Kod:** `app/lib/domain/licensing/license_office.dart` ve
`app/lib/domain/models/pending_license_exam.dart` tek bir `questionId` tutuyor;
`answer(...)` tek cevapla sınavı sonuçlandırıyor.
`app/lib/ui/widgets/license_exam_sheet.dart` tek soru gösteriyor.

**Önerilen düzeltme:** `PendingLicenseExam` üç soruluk kimlik listesi + verilen
cevapların listesini tutsun (kayıt sürümü artar). `answer(index)` cevabı sıraya
ekleyip son soruda sonucu hesaplasın (≥2 doğru = geçti). Sonuç ekranı üç sorunun
doğru cevabını ve açıklamasını listelesin. Soru havuzları zaten yeterli
(motosiklet 5, otomobil 6). `app/test/license_test.dart` ve
`app/test/license_widget_test.dart` buna göre güncellenmeli.

### B2 — Araç galerisinde satın alma yaşı 16/17
**Karar:** D-034 — "Galeriden **normal satın alma için şimdilik 18 yaş** prototip
sınırı kullanılacak."

**Kod:** `app/lib/data/shop_catalog.dart`:
`motosiklet_ekonomik` 16, `otomobil_ikinci_el/ekonomik/orta/luks` 17.

**Önerilen düzeltme:** Araçların `minAge` değeri 18'e çekilsin. Aksesuarların
(kask 16, tavan bagajı 17) yaşı ayrı bir tercih; kararda geçmiyor, Faho'ya
sorulabilir. Miras/hediye yoluyla küçük yaşta araç sahibi olmak **serbest
kalmalı** (D-034) — bu yol zaten yaş kontrolüne tabi değil.

### B3 — Yas kalıcı bir mutluluk cezası
**Karar:** D-036 — "Yas etkisi **zamanla hafiflesin**; kalıcı ve geri dönülemez
stat cezasına dönüşmesin."

**Kod:** `app/lib/domain/generation/life_progression.dart` — kayıp anında
mutluluktan tek seferlik düşüş uygulanıyor (`Mortality.prototypeOnlyHappinessLoss`),
sonrasında hiçbir şey bu düşüşü geri getirmiyor. Arka arkaya birkaç kayıp,
mutluluğu kalıcı olarak dibe çekebilir.

**Önerilen düzeltme:** Kaybı kalıcı değil, **azalan bir yas etkisi** olarak
modelle: oyuncu durumunda `grief` (kalan yas puanı ve başlangıç yaşı) tutulsun;
her yaş dönüşünde belirli oranda azalsın ve azalan kısım mutluluğa geri
eklensin. Kayıt sürümü artar; sayısal değerler `prototypeOnly` kalır.

### B4 — Ayrı/boşanmış ebeveyn mirasta "eş" sayılıyor
**Karar:** D-037 — "Eş ve çocuklar öncelikli mirasçı olabilir… **gerçek bir
evlilik kaydı yokken sevgiliyi eş gibi değerlendirme.**"

**Kod:** `app/lib/domain/life/inheritance.dart` — anne veya baba vefat ettiğinde
hayatta olan **diğer ebeveyn** koşulsuz olarak eş payı (nakdin dörtte biri)
alıyor. Oysa `GameState.parentalStatus` `evli / birlikte / ayri / bosanmis`
değerlerini tutuyor; boşanmış ebeveyn eş sayılmamalı.

**Not:** Sevgili (`RelationType.sevgili`) mirasta **doğru biçimde** mirasçı
sayılmıyor; bu yönüyle karara uygun.

**Önerilen düzeltme:** Eş payı yalnızca `parentalStatus.birlikteMi` (evli veya
birlikte) durumunda uygulansın; `ayri` ve `bosanmis` durumunda nakit doğrudan
çocuklara bölünsün. Regresyon testi eklenmeli.

### B5 — Kumarhane kapatılamıyor ve oyuncu harcama limiti koyamıyor
**Karar:** D-032 — "Ayarlardan **tamamen gizlenebilir/kapatılabilir bir modül**
olacak" ve "Oyuncu kendisi için **isteğe bağlı bir harcama limiti**
belirleyebilecek."

**Kod:** Oyunda **hiç ayarlar ekranı yok**; kumarhane 18 yaşından itibaren her
zaman görünüyor. Oyuncunun belirleyebileceği bir limit yok; yalnızca sabit
`prototypeOnlyYearlyWagerLimit` var.

**Önerilen düzeltme:** Küçük bir ayarlar ekranı (kayıtta saklanan iki alan:
`casinoEnabled`, `playerWagerLimit`). Kapalıyken Aktiviteler menüsünde kumarhane
**hiç görünmesin** (sahte düğme olmasın). Limit dolduğunda yalnızca nötr bir
bilgi gösterilsin.

### B6 — Yıllık yaşam gideri yok; maaşın tamamı birikiyor
**Karar:** D-033 — "**Yıllık temel yaşam gideri** olacak… çocuklara yetişkin
gideri yüklenmeyecek… maaşın tamamı otomatik birikmeyecek… giderler cüzdanı
**sessizce eksiye düşürmeyecek**, **geçim sıkıntısı durumu** olacak."

**Kod:** `JobMarket.paySalaryFor` maaşı ekliyor; hiçbir yerde gider düşülmüyor.
Ölçüm raporu (`docs/BALANCE_REPORT.md`) bunun ekonomiyi nasıl cömertleştirdiğini
gösteriyor: yazılımcı 2,5 yılda küçük daire alıyor.

**Önerilen düzeltme (en büyük kalem, ayrı paket):** Yaş dönüşünde hane ve yaşam
koşuluna göre hesaplanan yıllık gider; çocukta 0, ailesiyle yaşayan yetişkinde
düşük, bağımsız yaşayanda yüksek. Para yetmezse cüzdan eksiye düşmesin;
açık sonuç + genişletilebilir "geçim sıkıntısı" durumu. Bütün sayılar Faho
onayına kadar `prototypeOnly`.

### B7 — `Person.estate` hiçbir ekranda gösterilmiyor
**Karar:** D-038 — gösterilen her şey gerçek kayda dayanır; tersi de geçerli:
belgelerde "gösteriliyor" denen bir şey gerçekten gösterilmelidir.

**Kod:** `app/lib/domain/models/person.dart` içindeki açıklama "kişi ekranında
gösterilir" diyor; ancak `lib/ui` içinde `estate` alanını okuyan **hiçbir yer
yok**. Miras hesabı bu listeyi kullanıyor, oyuncu ise kişinin neye sahip
olduğunu göremiyor.

**Önerilen düzeltme:** Ya kişi detayında "Sahip oldukları" satırı eklensin
(tercih edilen), ya da açıklama gerçeğe uydurulsun. Tercihi Faho versin.

### B8 — Kişilerin mal varlığı doğumda donuyor
**Karar:** D-037 — "Kişilerin mal varlıkları **hayat boyunca değişebilecek**
şekilde tasarlansın; miras hesabı ilk doğumda oluşturulmuş değişmez bir servet
listesine dayanmasın."

**Kod:** `LifeGenerator._estateFor(...)` listeyi hayatın başında üretiyor ve bir
daha değişmiyor; `wealth` de sabit.

**Önerilen düzeltme (ayrı küçük paket):** NPC'lerin mal varlığı yıllar içinde
değişebilsin (iş/gelir durumuna göre küçük alım-satımlar). Kararda da "ayrı,
küçük bir paketle genişlet" deniyor.

### B9 — Bakım veren yoksa yalnızca günlük satırı var
**Karar:** D-037 — "Uygun kimse yoksa oyuncuyu açıklamasız ve bakımsız bırakmak
yerine, sonradan geliştirilebilecek **açık bir alternatif bakım durumu**
oluştur."

**Kod:** `LifeProgression._ensureCaregiver` uygun yakın bulamazsa yalnızca
"Evde sana bakabilecek bir yetişkin kalmadı" satırı yazıyor; oyun durumunda
bunu temsil eden bir alan yok.

**Önerilen düzeltme:** Kayıtta açık bir `careStatus` (ör. `aileYaninda`,
`yakinAkraba`, `kurumBakimi`) alanı; ilk sürümde yalnızca durum saklansın ve
ekranda görünsün, ayrıntılı sistem sonra gelsin. **Sahte kişi üretilmemeli**
(D-037/D-038) — mevcut kod bu yönüyle doğru.

---

## C. İzlenecek / denge ayarı

### C1 — Ölüm dağılımının yaşlı ucu ve çocukken ebeveyn kaybı
Ölçüm (500 hayat): 90+ **%17,6**, 18 yaşından önce ebeveyn kaybı **%16,4**.
D-036 "çok ileri yaşlar olağan hâle gelmesin" diyor. Sayılar geçici; ayar
Faho'nun onayına bağlı (`docs/BALANCE_REPORT.md`).

### C2 — Kumarhanede "yıllık sınıra kalan" bilgisi
D-032 "limit dolunca daha fazla oynamaya teşvik eden mesaj gösterilmesin" diyor.
Mevcut metin nötr ("Bu yıl oynadığın toplam bahis… Yıllık sınıra kalan…"), ancak
kalan hakkı vurgulaması teşvik gibi okunabilir. Ayarlar/limit çalışmasıyla
birlikte gözden geçirilmeli.

### C3 — Kumarhane bahis sınırları
D-032: sınırlar maaş ve giderlerle birlikte dengelenecek. Yaşam gideri (B6)
girmeden ayarlamak erken; B6 sonrası yeniden ölçülmeli.

### C4 — Sosyal medyada yaş başına 6 paylaşım
D-031 bunu açıkça geçici bıraktı; şu an kodla uyumlu, düzeltme gerekmiyor.

### C5 — Meslekler arası fark
En düşük/en yüksek maaş oranı **4,4x**, en yüksek ile ikinci sıra arası 1,7x.
D-033'ün "tek meslek diğerlerini anlamsızlaştırmasın" ölçütüne şu an uygun;
gider sistemi geldikten sonra yeniden bakılmalı.

---

## Karara uygun bulunanlar (düzeltme gerekmiyor)

- Sosyal medya sayacı **platform başına bağımsız**, içerik türleri ortak sayaç
  kullanıyor, enerji sistemi yok (D-031).
- Kumarhane yalnızca sanal para; gerçek para/ödül/reklam/borç yok; 18 yaş;
  bölme/sigorta/ikiye katlama yok; kazanç stat artırmıyor (D-032).
- Fiyatlar sabit; enflasyon/kredi eklenmedi (D-033).
- Sahiplik ile kullanım ayrı; ehliyetsiz araç sürülemiyor; ev almak taşınma
  değil; araç bakımı/satışı eşya sistemiyle ortak (D-034).
- İki bağımsız ehliyet; yaş eşikleri 16/18; resmî sınıf iddiası yok; ücret bir
  kez; yılda 2 deneme; yarıda kalan sınav kayıttan sürüyor (D-035).
- Çocuklukta ölüm seyrek; her yıl ölüm yok; sağlık etkili ama ölümsüzlük yok;
  kuşak farkları tutarlı; rastgele ağır olay eklenmedi; metinler kısa ve saygılı
  (D-036).
- Miras ölenin gerçek varlıklarından; iki kez dağıtılmıyor; sevgili eş
  sayılmıyor; vasiyet/borç/vergi yok; miras kalan eve otomatik taşınma yok;
  aile üyeleri silinmiyor ve sahte akrabalık üretilmiyor (D-037).
- Vefat eden kişiyle etkileşim açılmıyor, kayıtları korunuyor; sahte sayaç veya
  çalışmayan düğme eklenmedi (D-038).
