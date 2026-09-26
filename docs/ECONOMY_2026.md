# 2026 Türkiye ekonomi kalibrasyonu

Bu belge, oyunun para değerlerinin **neden** bu sayılar olduğunu açıklar.
Kesin kural `DECISIONS.md` içinde **D-053**'tür; buradaki tek tek tutarlar
hâlâ ayarlanabilir, kalibrasyonun **kuralları** ayarlanamaz.

## Temel ilke

Bütün tutarlar **2026 TL satın alma gücü** cinsindendir. Oyun canlı fiyat
çekmez ve 30-50 yıllık nominal enflasyonu **simüle etmez**. Böylece 70
yaşına gelen karakterin maaşı ya da ev fiyatı, gerçek dünyanın gelecek
enflasyonu yüzünden yüz milyonlara çıkmak zorunda kalmaz; oyuncu bütün
hayat boyunca aynı ölçekle düşünür.

## Çıpalar (Eylül 2026 referansı)

| Çıpa | Değer |
|---|---|
| Net aylık asgari ücret | 28.075,50 ₺ |
| Brüt aylık asgari ücret | 33.030 ₺ |
| **Net yıllık asgari ücret (12 ay)** | **336.900 ₺** |
| Ağustos 2026 yıllık TÜFE | %31,51 |
| Konut/su/elektrik/gaz yıllık değişim | %39,77 |

TÜFE ve konut grubu oranları **kalibrasyon gerekçesidir**, oyunda çalışan
bir enflasyon motoru değildir.

Kalibrasyonun ortak dili "kaç aylık asgari ücret" sorusudur; TL rakamı tek
başına okunur bir ölçü değildir.

## Maaşlar

Kural: **tam zamanlı normal bir işin yıllık geliri, özel gerekçe olmadan
336.900 ₺'nin altında kalamaz.** Bu kural `SalaryBand.sabitMaasli` olan
bütün bantlara uygulanır; yaratıcı/değişken bant istisnadır çünkü serbest
çalışanın kötü yılı gerçekten asgari ücretin altında olabilir.

Bantlar (₺/yıl):

| Bant | Alt | Üst |
|---|---|---|
| Asgari / giriş seviyesi | 336.900 | 400.000 |
| Nitelikli hizmet | 400.000 | 540.000 |
| Usta / teknik meslek | 520.000 | 720.000 |
| Ofis / uzmanlık | 620.000 | 900.000 |
| Üniversite profesyoneli | 820.000 | 1.350.000 |
| Yüksek uzmanlık | 1.300.000 | 2.400.000 |
| Yaratıcı / değişken gelir | 380.000 | 2.000.000 |

**Bant bir gelir sınıfıdır, prestij sırası değildir.** Öğretmen üniversite
ister ama ofis bandındadır; bandı belirleyen eğitim değil, işin getirdiği
paradır.

### Eski / yeni maaş örnekleri

| Meslek | Eski (₺/yıl) | Yeni (₺/yıl) | Aylık ≈ | Neden |
|---|---|---|---|---|
| Garson | 165.000 | 344.000 | 28.667 | Asgari ücretin **yarısının altındaydı**; artık asgari ücret seviyesinde |
| Mağaza çalışanı | 180.000 | 352.000 | 29.333 | Aynı sebep; garsondan bir tık yukarıda |
| Teknik servis | 260.000 | 545.000 | 45.417 | Meslek lisesi + tecrübe isteyen iş, asgarinin ~1,6 katı |
| Ressam / tasarımcı | 300.000 | 520.000 | 43.333 | Serbest çalışan; yaratıcı banda alındı |
| Öğretmen | 420.000 | 700.000 | 58.333 | Türkiye'de öğretmen maaşı asgarinin ~2 katı |
| Yazılım geliştirici | 720.000 | 1.320.000 | 110.000 | Sektör gerçeğine göre en yüksek üçüncü meslek |
| Karate eğitmeni | 300.000 | 455.000 | 37.917 | Yarı zamanlı karakterli iş, nitelikli hizmet bandı |
| **Yeni:** Doktor | — | 2.150.000 | 179.167 | Altı yıl okul + uzmanlık; en yüksek maaş |
| **Yeni:** Eczacı | — | 1.420.000 | 118.333 | Beş yıl okul, dar giriş |
| **Yeni:** Kasiyer | — | 340.000 | 28.333 | Asgari ücret çıpasının tam üstü |

En yüksek maaş (doktor) asgari ücretin **6,4 katı**. Uçurum bilerek dar
tutuldu: `test/economy_calibration_test.dart` on katı aşmasını engelliyor.

## Diğer kategoriler

Tek bir enflasyon çarpanı kullanılmadı. Her kategori **kendi içinde** ve
birbirine göre kalibre edildi.

| Kalem | Eski | Yeni | Çarpan | Neden / çıpa |
|---|---|---|---|---|
| Sinema / kafe | 150 ₺ | 450 ₺ | 3,0× | Aylık asgari ücretin %1,6'sı |
| Konser / maç | 1.400 ₺ | 4.500 ₺ | 3,2× | Bir akşamlık eğlence, asgarinin %16'sı |
| Müzik kursu (dönem) | 2.200 ₺ | 12.000 ₺ | 5,5× | Eski değer bir kurs dönemi için gerçekdışı ucuzdu |
| Dövüş dersi (karate) | 180 ₺ | 700 ₺ | 3,9× | D-062 "ders ucuz kalsın": aylık asgarinin %2,5'i |
| Veteriner (kedi) | 1.500 ₺ | 5.500 ₺ | 3,7× | 2026'da rutin muayene + aşı |
| Kedi yıllık bakım | 4.800 ₺ | 18.000 ₺ | 3,75× | Mama + kum + yıllık aşı |
| Köpek yıllık bakım | 7.200 ₺ | 26.000 ₺ | 3,6× | Kediden belirgin pahalı kalmalı |
| Nikâh (sade) | 3.500 ₺ | 14.000 ₺ | 4,0× | Küçük tören |
| Düğün (salon) | 90.000 ₺ | 380.000 ₺ | 4,2× | Salon + orkestra: bir yıllık asgari ücreti aşar |
| Tüp bebek (deneme) | 120.000 ₺ | 250.000 ₺ | 2,1× | Beş denemenin toplamı 1,25 milyon; D-054'ün ömür sınırı bu yüzden anlamlı |
| Evlat edinme masrafı | 80.000 ₺ | 160.000 ₺ | 2,0× | Bürokratik süreç, tedaviden ucuz |
| Doğum | 20.000 ₺ | 65.000 ₺ | 3,3× | Özel hastane payı |
| Cenaze katkısı | 25.000 ₺ | 120.000 ₺ | 4,8× | Eski değer 2026'da gerçekdışı düşüktü |
| Ciddi tedavi | 40.000 ₺ | 140.000 ₺ | 3,5× | Ameliyat + yatış |
| Bedelli askerlik | 280.000 ₺ | 550.000 ₺ | 2,0× | Yaklaşık 20 aylık asgari ücret |
| Piyango bileti (aylık) | 200 ₺ | 500 ₺ | 2,5× | **İkramiyeler de aynı oranda arttı** (aşağıda) |
| Otobüs yolculuğu | 2.200 ₺ | 4.500 ₺ | 2,0× | Şehirlerarası gidiş-dönüş |
| Uçak yolculuğu | 7.800 ₺ | 16.000 ₺ | 2,1× | Otobüsün ~3,5 katı kalmalı |
| Telefon | 18.000 ₺ | 45.000 ₺ | 2,5× | Orta sınıf akıllı telefon = ~1,6 aylık asgari ücret |
| Bilgisayar | 32.000 ₺ | 65.000 ₺ | 2,0× | |
| Bisiklet | 9.000 ₺ | 28.000 ₺ | 3,1× | |
| En ucuz otomobil | 320.000 ₺ | 850.000 ₺ | 2,7× | İkinci el, ~30 aylık asgari ücret |
| En pahalı otomobil | 3.400.000 ₺ | 6.800.000 ₺ | 2,0× | |
| En ucuz konut | 1.800.000 ₺ | 3.200.000 ₺ | 1,8× | Küçük daire, ~9,5 yıllık asgari ücret |
| En pahalı konut | 9.500.000 ₺ | 16.000.000 ₺ | 1,7× | Villa |

### Neden tek çarpan olmadı

Eski ölçekte **bir otomobil 2.100 sinema biletine** denk geliyordu. 2026
Türkiye'sinde bu oran yaklaşık **1.900**'dür — yakın. Ama **bir konut 200
aylık asgari ücret** etmesi gerekirken eski ölçekte **10 yıllık maaşın
üçte biri** ediyordu. Bu yüzden konut çarpanı (1,8×) sinema çarpanından
(3,0×) küçük tutuldu: konut zaten görece pahalıydı, sinema görece ucuzdu.

## Yaşam gideri: gerçekçilik ile onaylı kural çatıştı

2026 Türkiye'sinde asgari ücretle tek başına kirada yaşamak pratikte
birikim bırakmaz. Oysa **D-039** onaylanmış bir karardır: "düşük gelirli
bağımsız karakter de birikim yapabilmeli."

İlk kalibrasyonda gerçekçi kira (yıllık 120.000 ₺) kullanıldığında garson
gelirinin yalnızca **%21'ini** elinde tutuyordu ve mevcut test kırıldı.
Çatışma **onaylı kural lehine** çözüldü: kira gerçek piyasanın altına
çekildi.

| Kalem (yıllık taban) | Eski | Yeni |
|---|---|---|
| Aile yanında — eve katkı | 6.000 ₺ | 24.000 ₺ |
| Kirada — kira | 45.000 ₺ | 88.000 ₺ |
| Kirada — beslenme | 22.000 ₺ | 48.000 ₺ |
| Kirada — fatura ve diğer | 8.000 ₺ | 26.000 ₺ |
| Kendi evinde — aidat/bakım | 15.000 ₺ | 40.000 ₺ |
| Çocuk gideri | 24.000 ₺ | 72.000 ₺ |

En düşük maaşlı iş (kasiyer, 340.000 ₺) kirada yaşarken gelirinin
**%37'sini** elinde tutuyor.

## Şehir katsayıları (D-066)

Konut fiyatları şehre göre değişir. Ölçek bilerek dar: **en pahalı şehir
en ucuzun 2,2 katı**. "İstanbul 10x, Amasya 1x" gibi değerler oyuncuyu tek
bir şehre hapsederdi.

| Şehir | Konut | Araç |
|---|---|---|
| İstanbul | 2,20 | 1,06 |
| Antalya | 1,78 | 1,04 |
| İzmir | 1,72 | 1,04 |
| Ankara | 1,55 | 1,03 |
| Bursa | 1,38 | 1,02 |
| Eskişehir | 1,20 | 1,01 |
| Adana | 1,12 | 1,00 |
| Samsun | 1,05 | 1,00 |
| Diyarbakır | 1,00 | 0,99 |
| Malatya | 0,94 | 0,99 |
| Erzurum | 0,92 | 0,99 |
| Sivas | 0,90 | 0,99 |
| Amasya | 0,88 | 0,99 |

(Tam liste: `lib/data/city_catalog.dart`, 22 şehir.)

**Araçta şehir farkı konuttan çok daha azdır**, çünkü araba taşınabilir bir
maldır ve fiyatı ülke genelinde birbirine yakındır.

## Bu turda bulunan ve düzeltilen hatalar

1. **Piyangoda kasanın payı sessizce büyüdü.** Bilet fiyatı 200 → 500 ₺
   yapılırken ikramiyeler sabit bırakılmıştı; oyuncuya geri dönüş
   %40'ın üstünden **%28,5'e** düşmüştü. İkramiyeler bilet fiyatıyla aynı
   oranda ölçeklendi ve amorti bilet fiyatına eşitlendi.
2. **Yaşam gideri onaylı bir kararı ihlal etti.** Yukarıda anlatıldı.
3. **Kumar bütçesi yıl içinde kayıyor.** Bütçe her çağrıda güncel
   cüzdandan hesaplanıyor; oyuncu kazandıkça bütçe de büyüyor. Eski tavan
   (150.000 ₺) bunu maskeliyordu, yeni tavan (450.000 ₺) açığa çıkardı.
   Bu turda davranış değiştirilmedi, yalnızca **not edildi**: bütçenin yıl
   başında dondurulması ayrı bir tasarım sorusudur.

## Denetim

`test/economy_calibration_test.dart` kalibrasyonu kalıcı kılar:

- Sabit maaşlı hiçbir iş asgari ücretin altında değil.
- Her işin maaşı kendi bandının içinde.
- Aynı bantta iki iş aynı parayı vermiyor.
- Bantlar iç içe geçmiyor.
- En yüksek maaş asgari ücretin on katını aşmıyor.
- Sinema bileti aylık asgari ücretin %10'unun altında.
- En ucuz konut en ucuz arabanın iki katından pahalı.
- En ucuz konut yirmi yıllık ortalama maaşın altında.

`test/city_market_test.dart` şehir katsayılarının hem anlamlı hem aşırı
olmamasını denetler.
