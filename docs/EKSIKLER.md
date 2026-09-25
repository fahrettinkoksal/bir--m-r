# Bir Ömür — eksikler ve tamamlanması gerekenler

**Tarih:** 25 Eylül 2026 · **Hazırlayan:** Claude · **Durum:** envanter, karar
değil.

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
| Olay havuzu | **221 olay · 467 seçim** |
| Olay kategorileri | kişisel 79 · yetişkinlik 44 · aile 40 · mahalle 34 · okul 24 |
| Meslek | 44 |
| Aktivite eylemi | 51 (7 mekân) |
| Üniversite bölümü | 11 |
| Evcil hayvan türü | 10 · dövüş sanatı 3 · hobi 4 |
| Sosyal medya | 14 içerik · 7 medya işi · 7 sponsor kategorisi |
| Kesin karar | D-001 … D-124 |
| Test | 2024 geçiyor, 15 atlanıyor |

**Ölçülen oynanış:** ortalama ömür ~71-74 yıl · bir hayatta görülen
farklı olay **ortalama 48** · her yıl bir olay geliyor (0-5 yaş dahil) ·
bir olayın tek hayatta en çok tekrarı **3**.

---

## 2. Hiç kodlanmamış sistemler

Bunlar oyunda **yok**. Kodda tek satırı geçmiyor (arama ile doğrulandı).

### 2.1 Suç, hukuk ve hapis — **yok**
Arama: `suç|hapis` → kodda **0 sonuç**.

Oyunda hiçbir risk yok; her hayat "iyi vatandaş" olarak geçiyor. Hırsızlık,
kavga, trafik cezası, dava, tutukluluk, sabıka kaydının işe başvuruyu
etkilemesi — hiçbiri yok. Faho daha önce "ileride gelecek" demişti.

**Bu en büyük tek eksik.** Hayatın kaybedilebilir olmadığı bir hayat
simülasyonu, seçimlerin ağırlığını taşıyamıyor.

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

### 4.1 Çocukluk en fakir dönem

Gerçek oynanışta yaş bandına göre görülen **farklı** olay sayısı:

| Yaş | Farklı olay | Yorum |
|---|---|---|
| 0-5 | **11** | Altı yıl, on bir olay |
| 6-12 | **25** | Yedi yıl |
| 13-17 | **30** | |
| 18-25 | 35 | |
| 26-39 | 48 | |
| 40-59 | **52** | En zengin |
| 60-79 | **60** | En zengin |
| 80+ | 28 | |

Hayatın ilk **18 yılı** — kimliğin kurulduğu, oyuncunun karaktere
bağlandığı dönem — en fakir kısım. Olgunluk ve yaşlılık iki katı zengin.

**Öneri:** 0-17 yaş için 40-50 olay. Kardeş kavgası, mahalle oyunları,
ilk arkadaşlık, öğretmenle ilişki, bisiklet, sınav kaygısı, ergenlik
utancı, ilk harçlık.

### 4.2 Sunulmayan içerik: 221 olayın 61'i

120 hayat oynandığında **61 olay bir kez bile çıkmadı**. Bunlar bozuk
değil; **oyuncunun o sisteme girmesini** bekliyorlar. Simülasyon işe
girmediği ve hobi edinmediği için bunları hiç tetikleyemedi.

Kümelenmeleri:

| Küme | Adet | Neyi bekliyor | Bozuk mu? |
|---|---|---|---|
| Ebeveynlik | 11 | Belirli yaşta çocuk | Hayır — oyuncu çocuk sahibi olmalı |
| İş hayatı | 12 | Çalışıyor olmak, kıdem | Hayır — oyuncu işe girmeli |
| Hobi | 7 | Hobi basamağı | Hayır |
| Evlilik | 6 | Eş ve beklentileri | Hayır |
| Emeklilik | 5 | Emekli olmak | Hayır |
| Olay zinciri | 5 | Zincirin ilk halkası | **Şüpheli** — aşağıya bak |
| Gezi | 4 | Gezi anısı | Hayır |
| Ün | 4 | Ün eşiği | Hayır |
| Sınav | 2 | Sınav dönemi | Hayır |
| Torun | 2 | Torun sahibi olmak | Hayır |

**Doğrulandı:** `ilk_maas` yalnızca "18-24 yaşta çalışıyor ol" istiyor;
`cocuk_ilk_okul_gunu` yalnızca "6-7 yaşında çocuğun olsun" istiyor. İkisi
de makul koşullar — yani içerik sağlam, simülasyon yüzeysel.

**Yine de araştırılmalı:** 10 hikâye izi hiç konmuyor
(`cocuga_soz_verildi`, `esle_konusuldu`, `is_arkadasina_yardim`,
`zor_musteri_sakin`, `zincir_isyerinde_savundu`, `zincir_isyerinde_sustu`,
`zincir_kidemli_oldu`, `emeklilik_rutini`, `orta_eve_soz_verdi`,
`cocuk_ilk_gun_destek`). Bunların bir kısmı **zincirin ilk halkası hiç
çıkmadığı için** ölü olabilir. Bu gerçek bir hata olabilir ve tek tek
bakılması gerekir.

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

## 5. Karar bekleyen 68 soru

`docs/DESIGN_REVIEW_QUEUE.md` içinde **136 soru** var; bunların
**68'i hâlâ karar bekliyor**, **hiçbiri "kararlaştırıldı" olarak
kapatılmamış**.

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
3. **Suç ve hukuk sistemi.** Oyuna kaybedilebilirlik katan tek büyük
   eksik.
4. **Arkadaşlığı derinleştir** — küslük, barışma, arkadaşın kendi hayatı.
5. **Görsel kimlik kararı (Q-001/Q-077).** Oyun bir yıl daha kodlanabilir
   ama nasıl göründüğü seçilmeden "bitti" denemez.
6. Girişimcilik, hobi kataloğunun genişletilmesi, eksik ekranlar
   (Hobilerim, Evlilik Geçmişi, hayvan detayı).

**Claude'un kişisel görüşü:** oyun şu an **oynanabilir ama yeterince
tekrar oynanabilir değil**. İkinci hayatı ilkinden farklı kılan şey
henüz yeterli değil. Bunun sebebi havuzun küçüklüğü değil — bir hayatta
ortalama 48 farklı olay görülüyor ve tekrar en fazla 3 — asıl sebep
**hayatların birbirine benzemesi**: risk yok (suç/hukuk yok), meslek
yolları birbirinin aynı (hepsi maaşlı), arkadaşlık sığ, çocukluk fakir.
