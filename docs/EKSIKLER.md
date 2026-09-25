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
| Olay havuzu | **303 olay** (221 + 51 çocukluk + 31 suç/hukuk) |
| Olay kategorileri | kişisel 79 · yetişkinlik 44 · aile 40 · mahalle 34 · okul 24 |
| Meslek | 44 |
| Aktivite eylemi | 51 (7 mekân) |
| Üniversite bölümü | 11 |
| Evcil hayvan türü | 10 · dövüş sanatı 3 · hobi 4 |
| Sosyal medya | 14 içerik · 7 medya işi · 7 sponsor kategorisi |
| Kesin karar | D-001 … D-129 |
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

**Hâlâ yok:** ağır/organize suç, suç çevresi/çete, denetim döneminin
somut yaptırımı, adli sicilin zamanla silinmesi. Bunlar V2'ye bırakıldı
ve Q-141 … Q-143'te soruldu.

**Suç zorunlu içerik değil:** riskli seçim yapmayan 100 hayatta tek bir
dosya bile açılmıyor (ölçüldü, testle sabit).

### 2.2 Girişimcilik — **yok**
Arama: `girişim` → **0 sonuç**.

44 meslek var, **hepsi maaşlı**. Kendi işini kurmak, dükkân açmak, ortak
almak, batmak yok. Ekonomi sistemi (banka, kredi, mülk, kira geliri)
zaten var; girişimcilik bu altyapının üstüne oturabilir.

### 2.3 Üvey ebeveyn ve ikinci ailenin bağları — **yok**
Arama: `üvey` → **0 sonuç**.

İkinci evlilik var (D-036), ama eşin önceki çocuğu, üvey kardeş, dünür
ailesi diye bir bağ yok. Çocuğun eşi bile yalnızca bir **ad** olarak
tutuluyor (D-121), kişi kaydı değil.

### 2.4 Nafaka, velayet, mal rejimi — **bilerek ertelendi**
Arama: `nafaka` → 1 sonuç, o da `BACKLOG.md`'deki erteleme notu.

Q-118'de "şimdilik yok" kararı verildi ve gerekçesiyle yazıldı. Boşanmanın
mal paylaşımı var (D-075) ama nafaka ve velayet yok. İkinci evlilik
açıldıkça bu boşluk daha görünür oluyor.

### 2.5 Hane bütçesi ve eşin ekonomisi — **yok**
Eşin kendi geliri "kendi giderini karşılar" varsayılıyor; ortak bütçe,
eşin işi, eşin işsiz kalması yok (Q-063).

### 2.6 İkiz gebelik — **yok**
Arama: `ikiz` → 3 sonuç, hepsi **kardeş etiketi** (`İkiz kız kardeş`).
Oyuncunun ikiz çocuğu olması mümkün değil.

---

## 3. Yarım kalmış sistemler

Kodlandı ama yüzeysel; derinleştirilmesi gerekiyor.

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

### 3.3 "Hobilerim" görünümü yok
Arama: `Hobilerim` → 2 sonuç, ikisi de **eksik listesinde**.
Hobi sistemi çalışıyor (4 hobi, basamaklar) ama oyuncunun neyle
uğraştığını tek yerde gösteren bir bölüm yok.

### 3.4 Evlilik geçmişi ekranı yok
Arama: `Evlilik Geçmişi` → **0 sonuç**.
`pastMarriages` kaydı tutuluyor (D-036) ama oyuncu onu göremiyor.

### 3.5 Hayvan detay ekranı yok
10 tür, bakım, hastalık, kayıp, sahiplendirme var; ama tek bir hayvanın
kendi sayfası (geçmişi, anıları, birlikte geçen yıllar) yok.

### 3.6 "Vefat eden eş" ayrı statü değil
Dul kalmak ile boşanmak aynı `eskiEs` bağına düşüyor. İkisi çok farklı
şeyler.

### 3.7 Çoklu kişiyle aktivite yok
Programa tek kişi davet edilebiliyor. "Ailecek" bir şey yapmak yok.

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

| Katalog | Bugün | Gözlem |
|---|---|---|
| Hobi | **4** | Hobi sistemi güçlü ama seçenek çok az |
| Dövüş sanatı | 3 | |
| Üniversite bölümü | 11 | 44 mesleğe karşı 11 bölüm |
| Medya işi | 7 | Ün 40+ oyuncu için tek içerik |
| Sponsor kategorisi | 7 | |
| Evcil hayvan | 10 | Yeterli görünüyor |

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
4. **Arkadaşlığı derinleştir** — küslük, barışma, arkadaşın kendi hayatı.
5. **Görsel kimlik kararı (Q-001/Q-077).** Oyun bir yıl daha kodlanabilir
   ama nasıl göründüğü seçilmeden "bitti" denemez.
6. Girişimcilik, hobi kataloğunun genişletilmesi, eksik ekranlar
   (Hobilerim, Evlilik Geçmişi, hayvan detayı).

**Claude'un kişisel görüşü:** oyun şu an **oynanabilir ama yeterince
tekrar oynanabilir değil**. İkinci hayatı ilkinden farklı kılan şey
henüz yeterli değil. Bunun sebebi havuzun küçüklüğü değil — bir hayatta
ortalama 48 farklı olay görülüyor ve tekrar en fazla 3 — asıl sebep
**hayatların birbirine benzemesi**: meslek yolları birbirinin aynı
(hepsi maaşlı), arkadaşlık sığ.

**Güncelleme:** bu görüşün iki dayanağı kapandı — çocukluk artık fakir
değil (D-126) ve risk geldi (D-128). Kalan iki dayanak duruyor:
girişimcilik yok, arkadaşlık hâlâ sığ.
