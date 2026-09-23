# Olay içeriği ölçüm raporu (Paket 47)

**Bu rapor ölçüm sonucudur, onaylanmış denge kararı değildir.** Sayılara
bakıp değiştirilmesi gerekenler `docs/DESIGN_REVIEW_QUEUE.md` → **Q-110**
içinde öneri olarak duruyor.

Ölçüm aracı: `app/tool/event_report.dart`
(çalıştırma: `app` dizininde `flutter test tool/event_report.dart`).
Araç oyuna hiçbir şey eklemez; **500 hayatı gerçek oyun akışıyla** oynar.

## Ölçümün nasıl yapıldığı

Araç bu turda yeniden yazıldı. Önceden yalnızca `LifeProgression`
çağırıyordu; yani oyuncunun yaptığı hiçbir şeyi yapmıyordu. Oysa oyunda
**ek olaylar ancak oyun içi ilerleme biriktiğinde** açılır (D-023, D-024).
Etkileşim yapmayan bir ölçüm, oyuncunun gerçekte gördüğü olay yoğunluğunu
yarı yarıya eksik gösteriyordu.

Araç artık `GameController` üzerinden çalışıyor ve simüle edilen oyuncu:
yakınlarıyla etkileşim kuruyor, kursa/spora gidiyor, kitap bitiriyor,
evcil hayvan sahipleniyor, gezi yapıyor, işe giriyor, evleniyor, çocuk
sahibi oluyor, ev alıyor, sosyal medya hesabı açıyor ve emekli oluyor.
Hayatların **üçte biri bekâr kalıyor** ki yalnız yaşayanlara özel olaylar
da ölçüme girsin.

Ölçümü bozmamak için tek istisna: iş, mülakat akışından geçirilmek yerine
doğrudan kuruluyor (aracın amacı mülakatı sınamak değil). İş arkadaşları
gerçek üreticiyle oluşturuluyor.

## Ana sayılar (500 hayat)

| | |
| --- | --- |
| Katalogdaki olay sayısı | **200** |
| Toplam yaş adımı | 40.432 |
| Toplam gösterilen olay | 76.706 |
| Yıl başına olay | **~1,9** |
| Hiç görülmeyen olay | **6 / 200** |
| Seçim gerektirmeyen (yalnızca bilgi veren) olay | **0 / 200** |

Yıl başına olay sayısının 1'i geçmesi beklenen bir sonuçtur: her yaşta bir
**açılış** olayı, ayrıca yeterli ilerleme biriktiyse **bir ek** olay çıkar.
Bir önceki ölçüm aracı ek olayı hiç üretemediği için oranı %98,7
gösteriyordu; gerçek oynanışta oran **%190** civarındadır.

## Yaş grubuna göre olay sayısı

| Yaş grubu | Olay | Yıl | Oran |
| --- | --- | --- | --- |
| 0-5 | 3.106 | 2.993 | %104 |
| 6-12 | 6.937 | 3.474 | %200 |
| 13-17 | 4.942 | 2.473 | %200 |
| 18-24 | 6.787 | 3.435 | %198 |
| 25-39 | 14.543 | 7.281 | %200 |
| 40-59 | 18.723 | 9.397 | %199 |
| 60-79 | 15.948 | 8.069 | %198 |
| 80+ | 5.720 | 3.310 | %173 |

**Okunacak yer:** 0-5 yaş, oyunun en boş aralığı (yılda ~1 olay; ek olay
için gereken etkileşimler o yaşta çoğunlukla kapalı). 80 yaş üstünde de
havuz inceliyor: o yaşa uygun olayların bir bölümü tükeniyor.

## Konu dağılımı

Katalogda "konu" diye bir alan yok; aşağıdaki kümeler olayların
**koşullarından** türetildi (yalnızca rapor için).

| Konu | Gösterim | Oran |
| --- | --- | --- |
| diğer (kişi/iş/hobi şartı olmayan) | 51.945 | %67,7 |
| kişili (herhangi bir yakınla) | 13.961 | %18,2 |
| aile | 11.976 | %15,6 |
| okul | 6.502 | %8,5 |
| kariyer | 2.938 | %3,8 |
| hobi | 2.264 | %3,0 |
| ilişki (sevgili/eş) | 1.579 | %2,1 |
| evcil hayvan | 993 | %1,3 |

Katalog kategorisine göre: kişisel %34,4 · yetişkinlik %22,5 ·
mahalle %19,9 · aile %15,6 · okul %7,5.

## Hayatlar birbirinden gerçekten farklı mı?

Brifingin doğrudan sorusu buydu. Ölçülen:

| | |
| --- | --- |
| Bir hayatta ortalama **farklı** olay türü | **115,7** |
| İki rastgele hayatın olay kümesi örtüşmesi (Jaccard) | **%57,5** |
| Hayatların yarısından çoğunda çıkan olay sayısı | **115** |

**Cevap:** Hayır, "aynı 15-20 olay her hayatta tekrar etmiyor." Bir hayat
ortalama **116 farklı** olay türü görüyor ve 200'lük havuzun 194'ü en az
bir hayatta çıkıyor.

**Ama** ortak bir çekirdek var: 115 olay hayatların yarısından çoğunda
görünüyor ve iki rastgele hayatın olay kümesi **%57,5** örtüşüyor. Yani
hayatlar birbirinin kopyası değil, ama omurgası ortak. Bu bir hata
değil — havuzun büyük bölümü koşulsuz olduğu için doğal sonuç. Örtüşmenin
düşmesi isteniyorsa yol, koşullu (kişili, kariyerli, hobili) olayların
payını artırmaktır; bu bir **denge kararıdır** ve Q-110'a yazıldı.

## En sık gösterilen 20 olay

| Olay | Gösterim | Hayat başına |
| --- | --- | --- |
| mahalle_dugunu | 1.052 | 2,10 |
| market_kuyrugu | 981 | 1,96 |
| is_yerinde_yeni_gelen | 964 | 1,93 |
| is_cikisinda_yagmur | 954 | 1,91 |
| asansor_arizasi | 944 | 1,89 |
| kaybolan_esya | 937 | 1,87 |
| orta_yarim_kalan_kitap | 931 | 1,86 |
| orta_hafta_sonu_bos | 908 | 1,82 |
| zam_istegi | 897 | 1,79 |
| orta_beklenmedik_masraf | 896 | 1,79 |
| orta_komsu_tasiniyor | 885 | 1,77 |
| kis_hazirligi | 853 | 1,71 |
| ileri_yas_kontrol | 844 | 1,69 |
| sabah_yuruyusu | 814 | 1,63 |
| orta_uyku_kacan_gece | 813 | 1,63 |
| orta_uzak_taziye | 808 | 1,62 |
| orta_teknoloji_gerisi | 804 | 1,61 |
| orta_birikim_karari | 800 | 1,60 |
| telefonla_dolandirici | 789 | 1,58 |
| bahcedeki_saksi | 787 | 1,57 |

Aynı hayatta en çok tekrarlanan: `mahalle_dugunu` (562 fazladan gösterim),
`market_kuyrugu` (492), `is_yerinde_yeni_gelen` (480).

## Hiç görülmeyen olaylar

Ölçümde 200 olaydan **6**'sı hiç çıkmadı:

`un_tanisma`, `un_etkinlik_daveti`, `un_is_daveti`, `un_yorumlar`,
`hobi_sevgili_kitapci`, `hobi_okuma_gecesi`.

- **Dört `un_*` olayı** belirli bir **Ün** eşiği istiyor. Ölçüm aracı
  sosyal medya hesabı açıyor ama düzenli paylaşım yapmıyor, bu yüzden Ün
  hiç yükselmiyor. **Bu bir oyun hatası değil, ölçüm kapsamı eksiği.**
  Gerçek oyuncu düzenli paylaşırsa bu olaylar açılır.
- **`hobi_sevgili_kitapci`** ölçümde çıkmadı ama şartı ulaşılabilir
  (okuma 1. basamak + sevgili/eş). Ağırlığı düşük olduğu için 76.706
  çekilişte denk gelmemiş olabilir; **ulaşılamaz değil.**

### Bulunan ve düzeltilen gerçek hata

**`hobi_okuma_gecesi` hiçbir hayatta çıkamıyordu.** "Okumak" hobisini
yalnızca **bitirilen kitaplar** besliyor, bitmiş kitap yeniden
okunamıyor ve kütüphanede **7 kitap** var. Olay ise hobinin **2.
basamağını** istiyordu; o basamağın eşiği **8 deneyim**. Yani şart
matematiksel olarak sağlanamıyordu.

Olayın şartı, verinin gerçekten ulaşabildiği basamağa (**1.**) indirildi
ve bu hata sınıfını yakalayan kalıcı bir test eklendi: *hiçbir hobi olayı,
o hobinin ulaşabileceğinden yüksek bir basamak isteyemez.*

Aynı uyumsuzluğun **daha büyük hâli duruyor:** okuma merdiveninin 2., 3.
ve 4. basamakları (8 / 18 / 35 deneyim) 7 kitapla **hiç ulaşılamıyor**.
Bu bir denge kararı olduğu için kendi başıma değiştirmedim; **Q-110**'da
karara sunuldu.
