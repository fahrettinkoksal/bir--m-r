# Denge ölçüm raporu

Bu rapor, Q-055 (ekonomi) ve Q-058 (ölüm) kararlarının istediği ölçümleri
içerir. Ölçüm aracı: `app/tool/balance_report.dart`
(çalıştırma: `app` dizininde `flutter test tool/balance_report.dart`).
Araç oyuna yeni bir sistem eklemez; yalnızca mevcut kurallarla hayat simüle
eder ve sayıları raporlar.

**Buradaki sayılar ölçüm sonucudur, onaylanmış denge kararı değildir.**
Kesin değerler Faho'nun onayıyla belirlenecektir (D-033, D-036).

İlk ölçüm: PR #18 kodu (`claude/paket5-olum-miras`), 500 simüle hayat.
**Güncelleme:** D-031 – D-038 düzeltmeleri uygulandıktan sonra (yaşam gideri,
yas azalması, mal varlığı değişimi) ölçüm yenilendi; aşağıdaki "güncel"
bölümler bu sürüme aittir.

---

## 1) Ölüm yaşı dağılımı (Q-058)

| Ölçüt | Değer |
|---|---|
| Ortalama ölüm yaşı | **76,4** |
| Medyan | 79 |
| En küçük / en büyük | 6 / 103 |

| Yaş aralığı | Hayat | Oran |
|---|---|---|
| 0-18 | 4 | **%0,8** |
| 18-40 | 8 | %1,6 |
| 40-60 | 47 | %9,4 |
| 60-70 | 73 | %14,6 |
| 70-80 | 125 | %25,0 |
| 80-90 | 155 | %31,0 |
| 90-100 | 81 | **%16,2** |
| 100+ | 7 | %1,4 |

**Yorum (öneri, karar değil):**
- Çocukluk ölümü **%0,8** — "çocuklukta seyrek" ilkesine uygun (D-036).
- Ortalama 76,4 ve medyan 79, bir hayat simülasyonu için makul bir aralık.
- **Yaşlı uç biraz cömert:** hayatların **%17,6'sı 90 yaşını geçiyor**. Gerçek
  hayattaki orandan yüksek; "çok ileri yaşlar olağan hâle gelmesin" ölçütüne
  göre 85+ ihtimalleri bir miktar artırılabilir.
- **Erken ölümler seyrek ama bir uç var:** en düşük ölüm yaşı 6. 500 hayatta 4
  çocukluk ölümü, oyuncuyu sürekli trajediyle cezalandırmıyor.

## 2) Yakın kayıplar ve kuşak farkları (Q-058)

| Ölçüt | Değer |
|---|---|
| 18 yaşından önce ebeveyn kaybı yaşayan hayat | **%16,4** |
| Hayat başına ortalama yakın aile kaybı | 7,7 |
| Ebeveyn - oyuncu yaş farkı (doğum anı) | en az 17, ortalama 35,3, en çok 60 |
| 16 yaşından küçükken ebeveyn olan kayıt | **0** |
| Büyükebeveyn - oyuncu yaş farkı | en az 35, ortalama 66,4, en çok 104 |
| 32 yıldan küçük iki kuşak farkı | **0** |

**Yorum (öneri, karar değil):**
- **Kuşak farkları tutarlı**: mantıksız genç ebeveyn veya sıkışmış kuşak yok.
  Bu, D-036'nın "NPC yaşları ve kuşak farkları tutarlı olsun" maddesini
  karşılıyor.
- **Çocukken ebeveyn kaybı %16,4 ile yüksek.** Başlangıçta ebeveyn yaşının
  60'a kadar çıkabilmesi bunu besliyor. Oran düşürülecekse iki yol var:
  (a) orta yaş ölüm ihtimalini azaltmak, (b) başlangıçta çok yüksek ebeveyn
  yaşlarını seyrekleştirmek. Karar Faho'ya ait.
- Hayat başına 7,7 yakın kayıp, 76 yıllık bir ömürde büyükanne/büyükbaba,
  ebeveyn ve kardeşleri kapsıyor; beklenen düzeyde.

## 3) Ekonomi: kaç yıllık çalışmayla ne alınır? (Q-055)

Tablolar, **maaşın tamamının birikmesi** (bugünkü kod) ve iki örnek gider
senaryosu için "kaç yıllık maaş" gerektiğini gösterir. Gider sistemi henüz
yazılmadı; %50 ve %70 sütunları yalnızca D-033'ün etkisini görmek içindir.

### Gider yok (bugünkü durum)

| Meslek | Bisiklet | Telefon | Motosiklet | İkinci el oto. | Ekonomik oto. | Küçük daire |
|---|---|---|---|---|---|---|
| Garson | 0,1 | 0,1 | 0,5 | 1,9 | 4,5 | **10,9** |
| Mağaza çalışanı | 0,1 | 0,1 | 0,4 | 1,8 | 4,2 | **10,0** |
| Teknik servis | 0,0 | 0,1 | 0,3 | 1,2 | 2,9 | 6,9 |
| Ressam / tasarımcı | 0,0 | 0,1 | 0,3 | 1,1 | 2,5 | 6,0 |
| Öğretmen | 0,0 | 0,0 | 0,2 | 0,8 | 1,8 | 4,3 |
| Yazılım geliştirici | 0,0 | 0,0 | 0,1 | 0,4 | 1,0 | **2,5** |

### Yıllık gider = maaşın %50'si

| Meslek | İkinci el oto. | Ekonomik oto. | Küçük daire | Standart daire |
|---|---|---|---|---|
| Garson | 3,9 | 9,1 | 21,8 | 38,8 |
| Mağaza çalışanı | 3,6 | 8,3 | 20,0 | 35,6 |
| Teknik servis | 2,5 | 5,8 | 13,8 | 24,6 |
| Ressam / tasarımcı | 2,1 | 5,0 | 12,0 | 21,3 |
| Öğretmen | 1,5 | 3,6 | 8,6 | 15,2 |
| Yazılım geliştirici | 0,9 | 2,1 | 5,0 | 8,9 |

### Yıllık gider = maaşın %70'i

| Meslek | İkinci el oto. | Ekonomik oto. | Küçük daire | Standart daire |
|---|---|---|---|---|
| Garson | 6,5 | 15,2 | 36,4 | 64,6 |
| Mağaza çalışanı | 5,9 | 13,9 | 33,3 | 59,3 |
| Teknik servis | 4,1 | 9,6 | 23,1 | 41,0 |
| Ressam / tasarımcı | 3,6 | 8,3 | 20,0 | 35,6 |
| Öğretmen | 2,5 | 6,0 | 14,3 | 25,4 |
| Yazılım geliştirici | 1,5 | 3,5 | 8,3 | 14,8 |

**Meslekler arası fark:** en düşük 165.000 ₺/yıl, en yüksek 720.000 ₺/yıl
(**4,4x**). En yüksek ile ikinci sıra arasındaki fark 1,7x; tek meslek
diğerlerini anlamsızlaştırmıyor (D-033).

**Yorum (öneri, karar değil):**
- **Gider olmadan ekonomi fazla cömert:** yazılımcı 2,5 yılda, asgari düzeydeki
  bir meslek 10 yılda küçük daire alıyor; hiçbir kalem para götürmüyor.
- **Gider maaşın %50'si civarındayken** tablo okunaklı hâle geliyor: ikinci el
  otomobil 1-4 yıl, küçük daire 5-22 yıl. Bu aralık, "birkaç yıllık çalışmayla
  neye ulaşılır" ölçütünü karşılıyor.
- **%70 gider** alt gelirli meslekleri konuttan fiilen dışlıyor (33-36 yıl);
  kredi gelene kadar bu sert olabilir.
- Gider oranı **hane durumuna göre** değişeceği için (D-033: ailesiyle yaşayan
  ile bağımsız yaşayan farklı), tek bir oran yerine iki kademeli bir yapı
  öneririm: **ailesiyle yaşayan yetişkin için düşük, bağımsız yaşayan için
  yüksek**. Kesin oranlar Faho'nun kararı.

---

## 4) Güncel ölçüm — D-031 – D-038 düzeltmelerinden sonra

Yaşam gideri, yas azalması ve NPC mal varlığı değişimi eklendikten sonra
500 hayat yeniden simüle edildi.

### Ölüm yaşı (güncel)

| Ölçüt | İlk ölçüm | Güncel |
|---|---|---|
| Ortalama ölüm yaşı | 76,4 | **77,3** |
| Medyan | 79 | 79 |
| 0-18 yaş | %0,8 | **%0,6** |
| 18-40 yaş | %1,6 | %2,2 |
| 70-80 yaş | %25,0 | %28,4 |
| 90+ | %17,6 | **%19,2** |
| 18 yaşından önce ebeveyn kaybı | %16,4 | **%19,4** |

Fark, rastgelelik akışının değişmesinden kaynaklanıyor (aynı eğri, farklı
çekilişler). **İki gözlem aynı kaldı:** çocukluk ölümü çok seyrek; yaşlı uç
ve çocukken ebeveyn kaybı biraz yüksek. Bunlar hâlâ **geçici** değerler ve
Faho'nun onayıyla ayarlanacak (C1).

### Uygulanan yıllık geçim gideri (D-033)

| Durum | Yıllık gider |
|---|---|
| Çocuk (18 yaş altı) | 0 ₺ |
| Ailesinin yanında yetişkin | 45.000 ₺ |
| Bağımsız, kirada | 140.000 ₺ |
| Bağımsız, kendi evinde | 90.000 ₺ |

**Gider sonrası yıllık birikim:**

| Meslek | Ailede | Bağımsız (kira) | Kendi evinde |
|---|---|---|---|
| Garson | 120.000 ₺ | **25.000 ₺** | 75.000 ₺ |
| Mağaza çalışanı | 135.000 ₺ | **40.000 ₺** | 90.000 ₺ |
| Teknik servis | 215.000 ₺ | 120.000 ₺ | 170.000 ₺ |
| Ressam / tasarımcı | 255.000 ₺ | 160.000 ₺ | 210.000 ₺ |
| Öğretmen | 375.000 ₺ | 280.000 ₺ | 330.000 ₺ |
| Yazılım geliştirici | 675.000 ₺ | 580.000 ₺ | 630.000 ₺ |

**Yorum (öneri, karar değil):**
- Ailesinin yanında yaşayan bir mağaza çalışanı küçük daireye **~13 yılda**
  ulaşıyor; okunaklı bir hedef.
- **Bağımsız yaşayan düşük gelirli için birikim çok ince** (garson 25.000 ₺/yıl
  → küçük daire ~72 yıl). Üç ayardan biri gerekebilir: bağımsız gideri
  düşürmek, düşük maaşları yükseltmek ya da konut fiyatını indirmek.
  Karar Faho'nun.
- Yazılımcı ile garson arasındaki **birikim** farkı, maaş farkından (4,4x)
  çok daha büyük (23x): gider sabit olduğu için düşük gelirde orantısız
  ağırlaşıyor. Gideri gelire göre kısmen oranlamak bu makası daraltır.

## 5) Dört denge kararından sonra (D-039 – D-042)

Ölçüm: `claude/denge-q053-q059`, **5.000 simüle hayat** (önceki turlar 500
hayattı; sayılar bu yüzden daha kararlı).

### 5.1 Yıllık gider: taban + gelir payı (D-039)

| Yaşam düzeni | Taban | Gelir payı |
|---|---|---|
| Çocuk | 0 ₺ | — |
| Ailenin yanında | 20.000 ₺ | %8 |
| Kirada, kendi başına | 75.000 ₺ | %15 |
| Kendi evinde | 45.000 ₺ | %12 |

Kalemler ayrı tutuluyor (kira/aidat, beslenme, fatura ve diğer); ileride
ekranda tek tek gösterilebilir.

### 5.2 Gider sonrası yıllık birikim

| Meslek | Ailede | Kirada | Kendi evinde |
|---|---|---|---|
| Garson | 131.800 ₺ | **65.250 ₺** | 100.200 ₺ |
| Mağaza çalışanı | 145.600 ₺ | 78.000 ₺ | 113.400 ₺ |
| Teknik servis | 219.200 ₺ | 146.000 ₺ | 183.800 ₺ |
| Ressam / tasarımcı | 256.000 ₺ | 180.000 ₺ | 219.000 ₺ |
| Öğretmen | 366.400 ₺ | 282.000 ₺ | 324.600 ₺ |
| Yazılım geliştirici | 642.400 ₺ | 537.000 ₺ | 588.600 ₺ |

Önceki sabit gidere göre kirada yaşayan garsonun birikimi **25.000 ₺ →
65.250 ₺**'ye çıktı; yazılımcının maaşının **%25'i** gidere gidiyor, yani
bütün maaş otomatik birikmiyor.

### 5.3 Erişim süreleri (bisiklet / ikinci el otomobil / küçük daire)

**Ailenin yanında**

| Meslek | Bisiklet | İkinci el otomobil | Küçük daire |
|---|---|---|---|
| Garson | 0,1 yıl | 2,4 yıl | 13,7 yıl |
| Mağaza çalışanı | 0,1 yıl | 2,2 yıl | 12,4 yıl |
| Öğretmen | 0,0 yıl | 0,9 yıl | 4,9 yıl |
| Yazılım geliştirici | 0,0 yıl | 0,5 yıl | 2,8 yıl |

**Kirada, kendi başına**

| Meslek | Bisiklet | İkinci el otomobil | Küçük daire |
|---|---|---|---|
| Garson | 0,1 yıl | **4,9 yıl** | **27,6 yıl** (önce ~72) |
| Mağaza çalışanı | 0,1 yıl | 4,1 yıl | 23,1 yıl |
| Teknik servis | 0,1 yıl | 2,2 yıl | 12,3 yıl |
| Öğretmen | 0,0 yıl | 1,1 yıl | 6,4 yıl |
| Yazılım geliştirici | 0,0 yıl | 0,6 yıl | 3,4 yıl |

**Kendi evinde** (kira yok): garson 3,2 yıl / 18,0 yıl · yazılımcı 0,5 yıl /
3,1 yıl.

### 5.4 Ölüm yaşı ve ebeveyn kaybı (D-041)

| Ölçüt | Önce (500 hayat) | Sonra (5.000 hayat) |
|---|---|---|
| Ortalama ölüm yaşı | 77,3 | 75,5 |
| Medyan | 79 | 78 |
| 0-18 yaş | %0,6 | **%0,9** |
| 18-40 yaş | %2,2 | %2,2 |
| 40-60 yaş | %8,2 | %9,0 |
| 70-80 yaş | %28,4 | %26,4 |
| 80-90 yaş | %29,6 | %34,0 |
| **90+** | **%19,2** | **%12,6** |
| 100+ | %2,8 | %0,6 |
| **18 yaşından önce ebeveyn kaybı** | **%19,4** | **%12,3** |

Kuşak farkları tutarlı kalmaya devam ediyor: 16 yaşından küçükken ebeveyn
olan kayıt **0**, iki kuşak arası en küçük fark 35 yıl. Ebeveyn-oyuncu yaş
farkı ortalaması 35,3 → **33,1**; aralık 17-60 olarak korundu.

Genç yetişkin ölümleri artırılmadı: 18-40 aralığı %2,2'de sabit kaldı;
düzelme yalnızca ileri yaş ucundan ve ebeveyn yaş dağılımından geldi.

*Bu oranlar bir oyun dengesi çalışmasının sonucudur; gerçek yaşam
istatistiği olarak sunulmaz.*

### 5.5 Yıllık bahis bütçesi (D-040)

| Durum | Yıllık bütçe | Tek bahis üst sınırı | Hazır adımlar |
|---|---|---|---|
| Garson (kirada, cüzdan 20.000 ₺) | 10.788 ₺ | 2.158 ₺ | 100 / 200 / 500 / 1.100 / 2.158 ₺ |
| Mağaza çalışanı (aynı koşul) | 12.700 ₺ | 2.540 ₺ | 100 / 300 / 600 / 1.300 / 2.500 ₺ |
| Öğretmen | 43.300 ₺ | 8.660 ₺ | 400 / 900 / 2.200 / 4.300 / 8.660 ₺ |
| Yazılım geliştirici | 81.550 ₺ | 16.310 ₺ | 800 / 1.600 / 4.100 / 8.200 / 16.300 ₺ |
| İşsiz, cüzdan 5.000 ₺ | 2.000 ₺ (taban) | 400 ₺ | 100 / 200 / 400 ₺ |
| İşsiz mirasçı, cüzdan 500.000 ₺ | 25.000 ₺ | 5.000 ₺ | 300 / 500 / 1.300 / 2.500 / 5.000 ₺ |
| İşsiz mirasçı, cüzdan 3.000.000 ₺ | 150.000 ₺ (tavan) | 30.000 ₺ | 1.500 … 30.000 ₺ |

Düşük gelirli karakter **100 ₺ ile oynayabiliyor** ve büyük bahislere
yönlendirilmiyor; maaşsız mirasçı tamamen engellenmiyor; oyuncunun kendi
limiti bu bütçeden düşükse **o** geçerli oluyor.

## 6) Konut ve sağlık krizleri sonrası (D-043, D-044)

Ölçüm: `claude/paketA-tasinma-kira`, **5.000 simüle hayat**. Krizler
simülasyonda ödenebilir bir seçenekle yanıtlanıyor.

### 6.1 Ölüm yaşı: krizler devredeyken

| Yaş aralığı | Krizsiz (§5) | Krizler eklendi (ham) | **Temel eğri ayarlandı** |
|---|---|---|---|
| 0-18 | %0,9 | %1,6 | **%0,8** |
| 18-40 | %2,2 | %4,7 | %3,0 |
| 40-60 | %9,0 | %12,8 | %11,2 |
| 70-80 | %26,4 | %26,5 | %25,0 |
| 80-90 | %34,0 | %29,7 | %32,9 |
| 90+ | %12,6 | %7,5 | **%13,4** |
| Ortalama ölüm yaşı | 75,5 | 71,2 | **74,8** |
| 18'den önce ebeveyn kaybı | %12,3 | %10,9 | **%9,6** |

Krizler eklenince toplam ölüm beklendiği gibi yukarı kaydı; bu yüzden temel
ölüm eğrisi **0,8 ile çarpıldı** (D-044: krizler ölümün *bir sebebidir*,
üstüne eklenen ayrı bir yük değil). Sonuçta dağılım §5'teki ayarlı hâline
yakın kaldı, ama artık ölümlerin bir kısmının **anlatılabilir bir sebebi**
var.

### 6.2 Kriz sıklığı

| Ölçüt | Değer |
|---|---|
| Hayat başına ortalama sağlık krizi | **1,01** |
| Krizle sonuçlanan hayat oranı | **%13,1** |
| İki kriz arasındaki en az yaş farkı | 4 |

Hayat başına ~1 kriz, "oyuncuyu sürekli trajediyle cezalandırmama" ölçütüne
uygun. Krizlerin %87'si atlatılıyor.

### 6.3 Konut ve kira

| Kalem | Değer (prototypeOnly) |
|---|---|
| Taşınma masrafı | 12.000 ₺ (tek seferlik) |
| Yıllık kira getirisi | konut değerinin %4,5'i |
| Kiracı bulunamama ihtimali | %12 / yıl |

Örnek: küçük daire (1.800.000 ₺) yılda **81.000 ₺** kira getiriyor — kirada
yaşayan bir garsonun yıllık birikiminin (65.250 ₺) üstünde. Yani ikinci bir
ev, düşük gelirli bir karakter için anlamlı bir gelir kapısı oluyor; bu
oranın doğru olup olmadığı Q-060'ta Faho'nun kararına bırakıldı.

## Ölçümün sınırları

- Simülasyon, oyuncunun **iş bulduğu senaryoyu oynamaz**: tablolar "bu maaşla
  çalışıldığında" varsayımıyla hesaplanmış oran tablolarıdır.
- Kumar, miras ve hediye gelirleri tablolara dâhil değildir; bunlar ekonomiyi
  ayrıca hızlandırır.
- Ölüm dağılımı, mevcut olasılık eğrisinin ölçümüdür; olay tabanlı ölümler
  (kaza/hastalık) henüz yoktur (D-036).
