# Bir Ömür — eksikler ve tamamlanması gerekenler

**Tarih:** 25 Eylül 2026 · **Hazırlayan:** Claude · **Durum:** envanter, karar
değil.

> **Güncelleme (aynı gün, Paket O + P sonrası):** Bu belgedeki "hiç çıkmayan
> olay" ve "çocukluk fakir" ölçümleri **artık geçerli değil**. Sebebi
> D-125'te yazılı gerçek bir hataydı: oyuncunun eylemleri ilerleme
> sayılmıyordu. Düzeltme ve 51 yeni çocukluk olayından sonraki yeni
> sayılar 4.1 ve 4.2 bölümlerinde, eskisinin yanında duruyor.

Faho'nun isteğiyle hazırlandı: "oyunda eksik ve tamamlanması gerektiğini
düşündüklerini yaz". Bu belge **öneri ve tespit** taşır; hiçbir maddesi
onaylanmış iş değildir. Sıralama kararı `docs/DESIGN_REVIEW_QUEUE.md`
**Q-137**'de sorulmuştur.

## Nasıl ölçüldü

Bu belgedeki sayılar tahmin değil, koddan ve simülasyondan alındı:

- Katalog sayıları `lib/data/` dosyaları sayılarak.
- Olay çeşitliliği **120 hayat** doğumdan ölüme oynanarak, her olay
  cevaplanarak ölçüldü.
- "Hiç çıkmayan olay" listesi o oynanışta bir kez bile sunulmayan
  olaylardır.

**Ölçümün bilinen sınırı:** simülasyon olayları cevaplıyor ve yaş
alıyor, ama **işe başvurmuyor, hobi edinmiyor, geziye çıkmıyor, sosyal
medya hesabı açmıyor**. Bu yüzden "hiç çıkmayan" listesinin büyük
bölümü *bozuk* değil, *simülasyonun uğramadığı* içeriktir. İkisini
ayırmak için her madde aşağıda işaretlendi.

---

## 1. Bugünkü durum — ne var

| Sistem | Sayı |
|---|---|
| Olay havuzu | **316 olay** (221 + 51 çocukluk + 31 suç + 13 arkadaşlık) |
| Olay kategorileri | kişisel 79 · yetişkinlik 44 · aile 40 · mahalle 34 · okul 24 |
| Meslek | **52** (44 tam zamanlı + 8 yarım zamanlı) · kendi işi **13 tür** |
| Aktivite eylemi | 51 (7 mekân) |
| Üniversite bölümü | 11 |
| Evcil hayvan türü | 10 · dövüş sanatı 3 · hobi 4 |
| Sosyal medya | 14 içerik · 7 medya işi · 7 sponsor kategorisi |
| Kesin karar | D-001 … D-133 |
| Test | 2024 geçiyor, 15 atlanıyor |

**Ölçülen oynanış:** ortalama ömür ~71-74 yıl · bir hayatta görülen
farklı olay **ortalama 48** · her yıl bir olay geliyor (0-5 yaş dahil) ·
bir olayın tek hayatta en çok tekrarı **3**.

---

## 2. Hiç kodlanmamış sistemler

Bunlar oyunda **yok**. Kodda tek satırı geçmiyor (arama ile doğrulandı).

### 2.1 Suç, hukuk ve hapis — **eklendi (D-128, V1)**

> **Güncelleme (aynı gün):** Bu bölümdeki "yok" tespiti artık geçerli
> değil. Faho onayıyla **Suç ve Hukuk V1** eklendi.

Gelen: 11 suç türü (hız ihlali, yanlış park, maddi hasarlı kaza, alkollü
araç kullanma, kavga, kamu düzenini bozma, mala zarar verme, hırsızlık
girişimi, yaralama, iş yerinde usulsüzlük, borç davası) · idari ceza,
soruşturma, dava, takipsizlik, karar, sabıka, hapis ve denetim dönemi ·
31 olay ve 5 zincir · ayrı duruşma ekranı · 4 kademeli avukat · sabıkanın
iş başvurusuna etkisi · basit hapis ve cezaevi aktiviteleri · Adli
Geçmiş bölümü.

**V2 geldi (D-161):** denetim dönemi artık şehir dışına çıkmayı
kapatıyor; adli sicil zamanla **başvuruda sayılmaz** oluyor (kayıt
silinmiyor, hafif 5 / orta 12 / ağır 25 yıl); koğuşta kurulan itibar
tahliyeden sonra bir teklif kartına dönüşüyor. Sorular Q-164'te.

**Hâlâ yok:** ağır/organize suç. **Bilerek:** yeni bir ağır suç türü
anlatacak bir yöntem gerektirir ve oyunun içerik sınırını zorlar.

**Suç zorunlu içerik değil:** riskli seçim yapmayan 100 hayatta tek bir
dosya bile açılmıyor (ölçüldü, testle sabit).

### 2.2 Girişimcilik — **eklendi (D-132)**

> **Güncelleme:** bu bölümdeki "yok" tespiti artık geçerli değil.

Gelen: 13 iş türü üç ölçekte (sermaye 84.000-2.900.000 ₺) · işin durumu
(0-100) · kâr/zarar · batma · devretme · işine bakmak · para yatırmak ·
ekonomiye bağlı gelir · Kendi İşim ekranı.

**Hâlâ yok:** ortak almak, ikinci iş, işletme kredisi, esnaf emekliliği,
işin kuşak devamında geçmesi. Q-146'da soruldu.

### 2.3 Üvey ebeveyn ve ikinci ailenin bağları — **kısmen eklendi (D-141)**
Eski ölçüm: `üvey` → **0 sonuç**.

**Eklendi (D-141):** Oyuncunun ebeveynlerinden biri vefat ettiyse hayatta
kalan ebeveyn yeniden evlenebiliyor; gelen kişi `RelationType.uveyAnne` /
`uveyBaba` olarak çekirdek ailede listeleniyor, bağ düşük başlıyor ve kan
bağı sayılmıyor. Vefat eden ebeveyn kayıttan silinmiyor.

**Hâlâ yok:** üvey kardeş, üvey ebeveynden miras, ebeveynlerin boşanması
(tek tetik vefat), eşin önceki çocuğu, dünür ailesi. Çocuğun eşi hâlâ
yalnızca bir **ad** olarak tutuluyor (D-121), kişi kaydı değil. Açık
sorular Q-149'da.

### 2.4 Nafaka, velayet, mal rejimi — **nafaka ve velayet eklendi (D-160)**
> **Güncelleme (26 Eylül 2026):** Faho'nun açık isteğiyle nafaka ve
> velayet eklendi; bu **Q-118 kararını değiştiriyor** ve Q-163'te tekrar
> soruldu. Mal rejimi sözleşmesi, katkı payı ve değer artış payı hâlâ
> yok. Aşağıdaki eski gerekçe tarihsel kayıt olarak duruyor.
Arama: `nafaka` → 1 sonuç, o da `BACKLOG.md`'deki erteleme notu.

Q-118'de "şimdilik yok" kararı verildi ve gerekçesiyle yazıldı. Boşanmanın
mal paylaşımı var (D-075) ama nafaka ve velayet yok. İkinci evlilik
açıldıkça bu boşluk daha görünür oluyor.

### 2.5 Hane bütçesi ve eşin ekonomisi — **eklendi (D-154, D-160)**
> **Güncelleme (26 Eylül 2026):** Bu tespit artık geçerli değil.

Eşin kendi işi, iş değiştirmesi, emekli olması ve hastalanması geldi
(D-154). Çalışan eş maaşının %35'ini haneye koyuyor (D-160); ikinci bir
bakiye açılmadı, para doğrudan cüzdana giriyor. Sorular Q-157 ve Q-163.

### 2.6 İkiz gebelik — **eklendi (D-151)**
> **Güncelleme (26 Eylül 2026):** Bu tespit artık geçerli değil.

Eski ölçüm: `ikiz` → 3 sonuç, hepsi **kardeş etiketi**.

**Eklendi (D-151):** Gebelik doğumla sonuçlanırken %2,8 ihtimalle ikinci
bebek de aynı doğumda geliyor. Gebelik kaydı tek kalır, ikinci bebek aynı
diğer ebeveynden olur, tek bildirim açılır ve en fazla çocuk sınırı
aşılmaz. Üçüz yok. Sayılar Q-154'te.

---

### 2.7 Yatırım, portföy ve servet — **eklendi (D-162, V1)**

Oyunda para yalnızca cüzdanda duruyordu: biriktirmenin tek yolu
harcamamaktı ve harcamayan oyuncunun parası geçim giderine gidiyordu.
Varlıklar altına **Yatırımlar** geldi: beş tür (vadeli hesap, altın,
döviz sepeti, dengeli fon, karma hisse sepeti), yılın rejimi olan bir
piyasa (durgun / normal / güçlü / kriz) ve iki gizli parametre. Piyasa
yaş başına bir kez ilerliyor; ekranı açıp kapatmak fiyatı çevirmiyor.

Portföy net varlığa, boşanma paylaşımına ve mirasa giriyor; hayat sonu
değerlendirmesi artık cüzdan değil "eldeki nakit + portföy" okuyor.

**V1'de bilerek yok:** gerçek hisse/şirket adı, canlı fiyat, kripto,
opsiyon, kaldıraç, vadeli işlem, açığa satış, yatırım kredisi, ayrıntılı
vergi, gün içi alım-satım, grafik. Ayrıca **geçim gideri portföyden
tahsil edilmiyor** — bu bir karar sorusu olarak Q-165/5'te duruyor.

### 2.8 Ev sahibi / kiracı / kiralık gayrimenkul — **eklendi (D-163, V1)**

Konut bir sayıydı: "3.000.000 ₺ değerinde bir mülk". Kiraya vermek tek bir
`rentedOut` bayrağıydı; kiracı yoktu, kira katalog değerinden
hesaplanıyordu (şehir farkı kirada hiç görünmüyordu), depozito ve sözleşme
yoktu, konutun kondisyonu hiç değişmiyordu, boş evin maliyeti yoktu ve
evin değeri ömür boyu sabitti.

Gelen: **Varlıklar > Evlerim** ekranı, kullanım durumu (oturuluyor /
kirada / boş), kira bandı, kiracı adayları ve kiracı seçimi, depozito,
ödeme davranışı (tam / gecikmeli-kısmi / hiç), kiracının kendi isteğiyle
çıkması, kondisyon yıpranması, bakım ve tadilat, boş ev gideri, evin
sınırlı değer değişimi ve mülk başına kârlılık defteri.

**Ölçülen:** doluluk %97,5, kiracının ortalama kalma süresi 4,6 yıl, net
kira getirisi %3,70. Mortgage'lı evde net nakit akışı **eksi** ("bedava
ev" yok).

> ⚠️ "100 hayatın 94'ü hiç konut sahibi olmadan ölüyor" sonucu **basit
> simülasyonla** alınmıştı (sürekli Yaş Al'a basan bot). Gerçek oyuncu
> davranışıyla ölçüldüğünde (`product_simulation_test.dart`, 1.500 hayat)
> **ev sahipliği %40,3**, yatırım evi %28,3 çıkıyor. Eski sayı tarihsel
> kayıt olarak duruyor, ürün kararı için kullanılmaz.

**V1'de bilerek yok:** günlük kiralama, otel, ticari plaza, arsa/imar,
inşaat şirketi, onlarca kiracılı apartman yönetimi, kira hukuku
simülasyonu, mahkeme/tahliye prosedürü, ayrıntılı emlak vergisi.

## 3. Yarım kalmış sistemler

Kodlandı ama yüzeysel; derinleştirilmesi gerekiyor.

### 3.2b Kardeşin hayatı — **eklendi (D-158)**
Kardeş kaydı doğuştan vardı ama hayatı hiç ilerlemiyordu. Artık okuyor,
iş buluyor, emekli oluyor, evleniyor ve çocuğu oluyor; kardeşin çocuğu
**yeğen** olarak doğuyor. Sorular Q-161.

### 3.1 Arkadaşlık — en zayıf ilişki
Arkadaşlar pratikte birer **isim**. Yapılabilenler: sohbet, vakit geçir,
hediye. Yok olanlar: küslük, kavga, barışma, arkadaşın kendi hayatı
(evlenmesi, taşınması, ölümü), çocukluk arkadaşıyla yıllar sonra
karşılaşma, arkadaş grubu.

Aile (yakınlık, ihmal, sitem, miras) ve romantik ilişki (flört → sevgili →
evlilik → boşanma) derinken, arkadaşlık bunların yanında çok sığ kalıyor.

### 3.2 Çocuğun hayatı tek yönlü
Çocuk kendi hayatını yaşıyor (okul, meslek, birikim — D-045) ve artık
evleniyor (D-121). Ama: boşanamıyor, işsiz kalamıyor, hastalanamıyor,
oyuncudan para isteyemiyor, oyuncuya bakamıyor. Torun doğuyor ama
torunun kendi hayatı yok.

### 3.3 "Hobilerim" görünümü — **eklendi (D-133)**
> **Düzeltme (26 Eylül 2026):** Bu madde bu belge yazıldıktan sonra
> kapandı; envanter güncellenmemişti. `lib/ui/screens/sections/hobbies_page.dart`
> süren ve bırakılan hobileri ayrı ayrı gösteriyor.

Hobi **sayısı** dardı: 4 hobi. **Genişletildi (D-152): 12 hobi.**

### 3.4 Evlilik geçmişi ekranı — **eklendi (D-133)**
> **Düzeltme (26 Eylül 2026):** Kapandı.
> `lib/ui/screens/sections/marriage_history_page.dart` kiminle, kaç
> yaşında evlenildiğini ve nasıl bittiğini gösteriyor.

### 3.5 Hayvan detay ekranı — **eklendi (D-133)**
> **Düzeltme (26 Eylül 2026):** Kapandı.
> `lib/ui/widgets/pet_detail_sheet.dart` sağlık, yakınlık, birlikte geçen
> yıllar ve kayıp geçmişini gösteriyor.

### 3.6 "Vefat eden eş" — **bu tespit yanlıştı**
> **Düzeltme (26 Eylül 2026):** Kodu okuyunca görüldü ki dul kalmak ile
> boşanmak **ayrı** durumlar: `MarriageStatus.dul` ile
> `MarriageStatus.bosandi` ayrı değerler, ekran metinleri ayrı
> (`_marriageLabel`), ve `settleWidowhood` bağı `eskiEs`'e **düşürmüyor**
> — vefat eden eş `es` olarak kalıyor. Yalnızca boşanma `eskiEs` yazıyor.

**Hâlâ yok:** dulluğun kendine ait olay havuzu (anma, yıldönümü, eşin
ailesiyle bağın sürmesi).

### 3.7 Çoklu kişiyle aktivite — **eklendi (D-133)**
> **Düzeltme (26 Eylül 2026):** Kapandı.
> `ActivityEngine.perform(others: ...)` birden fazla kişi alıyor,
> `Outing.costForParty` kişi başı bilet hesaplıyor ve Eğlence ekranında
> çoklu seçim var.

---

## 4. İçerik boşlukları — ölçülmüş

### 4.1 Çocukluk en fakir dönemdi

Gerçek oynanışta yaş bandına göre görülen **farklı** olay sayısı:

| Yaş | Eski ölçüm | **Bugün** (D-125 + D-126 sonrası) |
|---|---|---|
| 0-5 | **11** | **24** |
| 6-12 | **25** | **53** |
| 13-17 | **30** | **62** |
| 18-25 | 35 | 77 |
| 26+ | — | 152 |

Eski ölçümün iki sebebi vardı: (1) çocukluk havuzu gerçekten zayıftı,
(2) simülasyon oyuncu gibi oynamıyordu ve motor ek olay vermiyordu
(D-125). İkisi de kapandı; **51 yeni olay** yazıldı (D-126).

Hayatın ilk **18 yılı** — kimliğin kurulduğu, oyuncunun karaktere
bağlandığı dönem — en fakir kısımdı. Artık 6-17 bandı yetişkinliğin
başıyla aynı ağırlıkta; en zayıf yer 0-5'te kaldı.

**Yapıldı (D-126):** 0-17 yaş için **51 olay** yazıldı — mahalle
oyunları, komşunun camı, ilk arkadaşlık, servis, kantin, karne, sınıf
başkanlığı, harçlık biriktirme, ilk hoşlanma, gruba girme/dışlanma,
yaz işi, sigara teklifi, öğretmenle ters düşmek. **Etki değerleri ve
temalar onay bekliyor: Q-139.**

**Hâlâ en zayıf bant 0-5** (24 olay). Bebeklik için daha fazla mı
yazılmalı, yoksa o yaş hızlı mı geçmeli — Q-139'un 5. sorusu.

### 4.2 Sunulmayan içerik — yeniden ölçüldü

**Eski kayıt (geçersiz):** "120 hayatta 221 olayın 61'i hiç çıkmadı."
O ölçüm **benim hatamdı**: simülasyon işe girmiyor, hobi edinmiyor,
geziye çıkmıyor, sosyal medya açmıyordu; üstüne **D-125'teki gerçek
hata** yüzünden motor ek olay da vermiyordu.

**Yeni ölçüm** (120 hayat, oyuncu gibi oynanarak — işe girerek, hobi
edinerek, evlenerek, çocuk yaparak, yoldaşla geziye çıkarak, sosyal
medya açarak, emekli olarak):

| Ölçü | Eski | Bugün |
|---|---|---|
| Havuz | 221 | **272** |
| Bir hayatta görülen farklı olay | 48 | **110** |
| 120 hayatta hiç çıkmayan | 61 | **18** |
| Ortalama ömür | 74 | 80,4 |
| Bir olayın bir hayatta en çok tekrarı | 3 | **3** |

120 hayatta simülasyonun yaptıkları: işe giren **119/120**, hobi edinen
119, geziye çıkan 119, sosyal medya açan 119, emekli olan 106, evlenen
69, çocuk sahibi olan 49.

**Hiç çıkmayan 18 olay ve gerçek sebepleri:**

| Olay | Sınıf | Sebep |
|---|---|---|
| `hayvan_komsu_sikayet`, `hayvan_yaslandi`, `hayvan_cocukla`, `hayvan_sokakta_yavru` | Simülasyon uğramıyor | Simülasyon hiç **evcil hayvan sahiplenmiyor**. Gerçek oyuncu ulaşır. |
| `direksiyon_basinda`, `araba_yolda_kaldi` | Simülasyon uğramıyor | Ehliyet + araç gerekiyor; simülasyon araba almıyor. Gerçek oyuncu ulaşır. |
| `hobi_arkadas_resim_ister`, `hobi_sevgili_kitapci`, `hobi_yillar_sonra_donus`, `hobi_okuma_gecesi` | Simülasyon uğramıyor | Belirli hobide **basamak** ve bazılarında sevgili/arkadaş şartı var. Gerçek oyuncu ulaşır. |
| `savundugun_arkadas`, `yardimin_karsiligi`, `bisiklet_zinciri`, `zincir_ogretmen_2`, `zincir_ogretmen_3`, `zincir_emanet_3_iste`, `sinav8_son_hafta` | **Dar pencere** | Zincirin ikinci halkası, ilk halkanın izini **çok dar bir yaş/sınıf aralığında** arıyor. `sinav8_son_hafta` hem izi hem **8. sınıfı** istiyor: ikisi de tek bir okul yılına sığmak zorunda. |
| `cocukluk_ilk_kelime_anisi_anne` | Rastlantı | Yeni yazıldı; 120 hayatta oyuncu hep "baba" ya da "hayır" dedi. Karşılığı (`..._baba`) çıkıyor, yani yol açık. |

**Ölçülen yan etki — bunu dürüstçe yazmak gerekiyor:** havuz 221'den
272'ye çıkınca **dar pencereli zincir halkaları seyreldi**. D-125'ten
hemen sonra (havuz 221 iken) hiç çıkmayan olay **9** idi; 51 çocukluk
olayı eklendikten sonra **18** oldu. Yeni içerik kötü değil; **dar
pencereli zincirler yeni içerikle yarışmayı kaybediyor.** Motorun
zincir halkalarına öncelik verip vermemesi bir tasarım kararıdır ve
**Q-138**'de soruldu.

**On hikâye izi soruşturması (Paket O) — sonuç:** `cocuga_soz_verildi`,
`esle_konusuldu`, `is_arkadasina_yardim`, `zor_musteri_sakin`,
`zincir_isyerinde_savundu`, `zincir_isyerinde_sustu`,
`zincir_kidemli_oldu`, `emeklilik_rutini`, `orta_eve_soz_verdi`,
`cocuk_ilk_gun_destek` — **onunun da gerçek sebebi aynıydı ve hiçbiri
ölü içerik değildi.** İzler konmuyordu çünkü (a) simülasyon o
sistemlere hiç girmiyordu ve (b) D-125'teki hata yüzünden oyuncunun
eylemleri ek olay açmıyordu. İkisi düzeltilince **onu da konuyor**;
bir gerileme testiyle sabitlendi (`test/paket_op_test.dart`).

### 4.3 Kataloglar dar

| Katalog | Ölçüldüğünde | **Bugün (D-152)** |
|---|---|---|
| Hobi | 4 | **12** |
| Dövüş sanatı | 3 | **6** (boks, judo, taekwondo geldi) |
| Üniversite bölümü | 11 | **20** |
| Medya işi | 7 | **14** |
| Sponsor kategorisi | 7 | 7 (değişmedi) |
| Evcil hayvan | 10 | 10 (yeterli görünüyor) |

Yeni sayılar onay bekliyor: **Q-155**.

---

## 5. Karar bekleyen sorular

`docs/DESIGN_REVIEW_QUEUE.md` içinde **140 soru** var. Sayım
(25 Eylül 2026, Paket O + P sonrası):

| Durum | Adet |
|---|---|
| Tamamen açık ("karar bekliyor") | **66** |
| Yönü onaylı ama **sayıları** onay bekliyor | 39 |
| Kapatılmış (KARARLAŞTIRILDI / KISMEN) | **16** |

Önceki turda "hiçbiri kararlaştırıldı diye kapatılmamış" yazmıştım;
**yanlıştı** — 12'si zaten kapalıymış. Bu turda sonradan alınan
kararlarla örtüşen dördü daha kapatıldı: **Q-115 → D-106**,
**Q-116 → D-102**, **Q-117 → D-102**, **Q-121 → D-107 (kısmen)**.
Tarihsel kayıt silinmedi; her birinin özgün metni yerinde duruyor.

Bu tek başına bir eksiktir: oyunun neredeyse bütün sayısal dengesi
`prototypeOnly` etiketiyle duruyor ve hiçbiri kesinleşmedi. Öne çıkanlar:

- **Q-001 / Q-077 — görsel kimlik ve palet hiç seçilmedi.** Oyunun
  nasıl görüneceği en baştan beri açık soru. 15 golden testi bu yüzden
  atlanıyor.
- **Q-002 — olay temposu** (yılda kaç olay) hâlâ demo parametresi.
- Karakter özelliklerinin başlangıç aralığı ve denge kararı yok.
- Q-129 … Q-136 — bu haftaki bütün yeni sayılar.

---

## 6. Teknik borç ve doğrulanmamış olanlar

- **Hiçbir sürüm gerçek cihazda oynanmadı.** Bütün "çalışıyor"
  ifadeleri CI derlemesi ve 2024 testin geçmesi anlamına gelir; telefonda
  açıldığı anlamına **gelmez**. Bu belgedeki oynanabilirlik yorumları da
  koddan ve simülasyondan çıkarıldı, oynanarak değil.
- **15 golden testi atlanıyor** (`BIR_OMUR_SCREENSHOTS=1` olmadan
  çalışmaz); görsel regresyon fiilen korumasız.
- **Bildirim yoğunluğu arttı**: D-114 sonrası yıl başına 0,39 → 0,71
  pencere. Oynanırken fazla gelebilir (Q-132).
- **Kayıt göçü** her yeni alanda elle yazılıyor; alan sayısı arttıkça
  bu kırılgan bir nokta.
- **`OwnedItem.rentedOut` artık ölü bir alan.** D-163 ile "bu ev kirada"
  bilgisinin tek kaynağı sözleşme oldu; bayrak yalnızca eski kayıtları
  açmak için duruyor ve yüklemede sözleşmeye çevriliyor. Kaydı bozmamak
  için silinmedi, ama yeni kod okumamalı. Bir sürüm sonra kaldırılabilir.
- **Ürün metrikleri artık yalnızca `PlayerBot` ile ölçülür.** Basit
  "sürekli Yaş Al" botuyla alınmış eski sayılar (ev sahipliği, servet,
  yatırım, kariyer erişimi) belgelerde **etiketli** duruyor ve ürün
  kararı için kullanılmaz. Unit/regresyon testleri ilk açık seçeneği
  kullanmaya devam edebilir; ikisinin raporu karıştırılmaz.
- **Hiç girilmeyen meslekler, kurulmayan işletmeler ve görülmeyen
  olayların sebebi ölçüldü (Q-167).** Tek bir ölçüm eksiği üç yerde
  birden karşımıza çıkıyor: **PlayerBot hiç ehliyet almıyor**
  (`applyForLicense` çağrılmıyor). Bu yüzden `kurye` ve `yz_kurye` ilanı
  hiç açılmıyor, `is_nakliye` hiç kurulamıyor ve **5 olay** hiç
  çıkmıyor (`direksiyon_basinda`, `araba_yolda_kaldi`, `suc_radar`,
  `suc_dugun_donusu` ve zincir halkaları). Oyunun kapısı değil, botun
  eksiği. Diğer sebepler: `muzisyen` 34 kez ilanda açıldı ama bot
  maaşa göre üst üçte birden seçtiği için **hiç başvurmadı**; `doktor`
  tıp + zekâ 75 + büyük şehir birleşimiyle 1.000 hayatta yalnızca 3 yıl
  ilanda göründü; 2M+ sermayeli işletmeler botun bütün artan parayı
  portföye koyması yüzünden hiç karşılanamadı.
- **Görülmeyen olayların 3'ü erişilebilir**, yalnızca havuz çekilişinde
  kaybediyor (`yardimin_karsiligi`, `sinav8_son_hafta`,
  `zincir_ogretmen_3`). Geri kalanlar ehliyet, hobi `okuma` ya da suç
  zincirinin önceki halkasından gelen flag + hatırlanan kişi rolünün
  birlikte gerekmesi yüzünden oluşmuyor.
- **KONTROLSUZ BORÇ BÜYÜMESİ (Paket AC ölçümünde bulundu).**
  `banking.dart advanceYear`: ödenmeyen taksitte borç her yıl faiziyle
  büyüyor ama `remainingPayments` **azalmıyor** ve hiçbir haciz,
  yapılandırma, iflas ya da borç silme mekanizması yok. Kredi hiç
  kapanmıyor. Ölçümde bir hayatta **1.788.495k ₺ borç** ve
  **−1.601.336k ₺ net servet** çıktı (ev+yatırım stratejisinin %0,8'i).
  Net servet istatistiklerini de bozuyor. Düzeltilmedi çünkü doğru çözüm
  bir ürün kararı (Q-168/10).
- **Yatırım eğilimleri reel ölçekte yüksek.** Oyun sabit 2026 TL
  ölçeğinde (D-053), yani hisse %10 / fon %8 / altın %7 **reel** getiri
  demek. %9,2 gerçekleşen reel getiri 60 yılda ~200 kat eder. Paket AC'nin
  risk katmanı medyanı %27,6 düşürdü ve gerçek bir kayıp kuyruğu yarattı
  (%100 hisse stratejisinde hayatların %13,6'sında yatırım para
  kaybettiriyor), ama üst kuyruğun büyüklüğü **eğilim × ufuk**
  çarpımından geliyor. Mimari seçenekler Q-168'de raporlandı; enflasyon
  motoru **kurulmadı**, eğilimler **değiştirilmedi**.
  > **Güncelleme (Paket AD, 27 Eylül 2026): bu madde artık geçerli değil.**
  > Faho §2'de açık yetki verdi ve **`drift` alanı tamamen kaldırıldı.**
  > Getiri artık rejimden, gizli değerleme ısısından, çağ gelgitinden ve
  > varlığın kendi ürettiği akıştan doğuyor. Yeni ölçüm: hisse geometrik
  > **%6,5** (önce ~%9,2 gerçekleşen), altın **%3,4**, vadeli %6 → **%3**.
  > 60 yıllık "sadece altın" stratejisi medyan **18 kat** yerine **7,4
  > kat**. %100 hisse stratejisinde para kaybeden hayat payı %13,6 →
  > **%16,8**. Ayrıntı: `PROJECT_STATUS.md` "Paket AD (1/6)" ve Q-169.
  > **§18'in dağılım hedefi hâlâ doğrulanmadı** (AD/6).
- **Tekrar evlenme %0'ın kök nedeni bulundu ve DÜZELTİLDİ (Q-167/3).**
  `Finger` "evli mi" sorusunu `state.marriage != null` ile soruyor;
  boşanmada ve dullukta kayıt bilerek silinmediği için (Paket 36) bu
  koşul bir kez evlenen herkes için hayatının sonuna kadar doğru.
  Sonuç: `finger.dart:443/552/680/711` — eşleşme flört olmuyor, flört
  resmîleşmiyor, çıkma teklif edilemiyor. `marryBlockReason` ikinci
  evliliği açıyor ama **evlenecek sevgiliyi edinmenin yolu kapalı**.
  Aynı kalıp `life_progression.dart:1696`'da da var (küçük etki).
  Paket AC'de düzeltildi: beş yerde `state.isMarried` kullanılıyor
  (`finger.dart` dördü + `life_progression.dart:1696`). `PlayerBot`'ta da
  aynı hata vardı (teklif kapısı), o da düzeltildi. Sonuç: ayrılık sonrası
  yeni flört %0,0 → **%47,5**, yeni sevgili → %8,5, tekrar evlenme →
  **%5,7**. Kanıt ve tam oyuncu yolu regresyonu:
  `app/test/diagnosis_remarriage_lock_test.dart` (11 test) — iki eşin
  ikisi de Finger'dan geliyor, elle sevgili enjekte edilmiyor.
  **Kalan darlık:** 67 flörtün ancak 12'si sevgiliye dönüyor; bu bot
  eksiği (flörtle vakit geçirmiyor) ve 45-62 / 60 eşik örtüşmesi
  (Q-167/2) — ikisi de açık.
  `second_marriage_test.dart` geçiyordu çünkü orada sevgili elle
  kuruluyordu; oyuncunun gerçek yolu test edilmiyordu.
- **PlayerBot'un bilinen davranış eksikleri (ürün kararı değil, Q-167/7).**
  Ehliyet almıyor; flörtle hiç vakit geçirmiyor (bu yüzden yakınlık 60
  resmîleştirme eşiğine çıkmıyor ve sevgili kapısı daralıyor); Finger
  profilini niyete bakmadan seçiyor (adayların %25'i yalnızca arkadaşlık
  istiyor); yatırım yapabildiği **her** yıl yatırım yapıyor
  (yatırım/fırsat 1,00); artan parayı hep portföye koyduğu için yüksek
  sermayeli işletmeye ulaşamıyor; her arketip çalışıyor (%98-100),
  işsiz kalmayı seçen profil yok. Bunlar düzeltilirse **bütün ürün
  metrikleri değişir**, bu yüzden Faho'ya bildirilmeden yapılmadı.
- **Olay havuzuna içerik eklemek tohuma çakılı testleri kaydırıyor.**
  `EventEngine._pick`, havuzdaki **her** olay için kişiyi çözüyor
  (`_resolvePerson`, çekiliş tüketiyor) ve yaş kapısına ancak ondan
  sonra bakıyor. Sonuç: 20 yaş üstü bir olay eklemek çocukluk yıllarının
  rastgele akışını da kaydırıyor. D-162'de bu dört testi kırdı; hiçbiri
  gevşetilmedi, tohumları yeniden çıpalandı ve gerekçesi yazıldı. Kalıcı
  çözüm yaş kapısını kişi çözmeden önce bakmak; **bu bir motor
  değişikliği olduğu için onay bekliyor**, yatırım paketinin yan etkisi
  olarak yapılmadı.

---

## 7. Claude'un önceliklendirme önerisi

**Bu bir öneridir; sıralamayı Faho ile ChatGPT verir (Q-137).**

1. **Ölü hikâye izlerini araştır** — 10 iz hiç konmuyor. Yeni içerik
   yazmadan önce yazılmış içeriğin çalıştığından emin olmak gerekir.
   Ucuz, ve gerçek bir hata çıkarsa değerli.
2. **Çocukluk ve ergenlik olayları** (0-17 için 40-50 olay). Oyunun en
   fakir ve en duygusal dönemi.
3. ~~**Suç ve hukuk sistemi.**~~ **Yapıldı (D-128, V1).** V2 için açık
   kalanlar Q-141 … Q-143'te.
4. ~~**Arkadaşlığı derinleştir**~~ **Yapıldı (D-130).**
5. **Görsel kimlik kararı (Q-001/Q-077).** Oyun bir yıl daha kodlanabilir
   ama nasıl göründüğü seçilmeden "bitti" denemez. **Sıradaki en büyük
   engel bu.**
6. ~~Girişimcilik, eksik ekranlar~~ **Yapıldı (D-132, D-133).** Hobi
   kataloğunun genişletilmesi (4 hobi) duruyor.
7. ~~Hediye seçimi, menü düzeni, 2. el araç pazarı, kefalet ve cezaevi
   hayatı, üvey ebeveyn~~ **Yapıldı (D-134 … D-141).** Çetenin dışarı
   taşması (Q-148), üvey kardeş ve miras (Q-149) duruyor.

**Claude'un kişisel görüşü (26 Eylül 2026'da güncellendi):** "hayatlar
birbirine benziyor" görüşünün **dört dayanağının dördü de kapandı**:
çocukluk artık fakir değil (D-126), risk geldi (D-128), arkadaşlık
yaşanıyor (D-130) ve kariyerin ikinci bir şekli var (D-131, D-132).

Kalan en büyük engel **kod değil, karar**: görsel kimlik ve palet hiç
seçilmedi (Q-001, Q-077) ve 15 golden testi bu yüzden atlanıyor. Bunun
yanında oyun hâlâ **hiçbir gerçek cihazda oynanmadı** — bütün doğrulama
otomatik test. Bu iki madde kapanmadan "bitti" denemez.
