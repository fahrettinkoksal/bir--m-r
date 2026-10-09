# Claude'un geliştirme yol haritası

**9 Ekim 2026.** Faho geliştirmeyi Claude'a bıraktı: "bundan sonra bu
oyunu geliştirmeni ve bana sormadan tüm geliştirmeyi yapmanı istiyorum;
oyunu oynayanların isteyeceği şeyleri ekle." Tek şart: eklenen bir
özellik beğenilmezse çıkarılabilsin — bunun altyapısı Paket BL'de
kuruldu (`docs/FEATURE_FLAGS.md`).

Bu dosya **Claude'un planıdır**. Faho herhangi bir satırı iptal edebilir;
sırası da değişebilir. Her paket bittiğinde burası tazelenir.

**9 Ekim 2026, ikinci talimat:** "bana soru sorma, geç; tüm yetkiyi sana
verdim." Bundan sonra Claude kararı kendisi verir, uygular ve kaydını
`docs/DESIGN_REVIEW_QUEUE.md`'ye **karar olarak** yazar — soru olarak
değil. Geri alma yolu her kayıtta yazılı kalır.

## Değişmeyen sınırlar

Yetki geliştirmeye verildi, kural yazmaya değil. Claude kendi başına:

- `DECISIONS.md`'ye karar **yazmaz** (orası Faho'nun kendi defteri); yeni
  sayılar `prototypeOnly` kalır ve verilen kararlar
  `docs/DESIGN_REVIEW_QUEUE.md`'ye kayıt olarak girer;
- 9 Ekim öncesinde açılmış soruların koduna dokunmaz: **Q-187, Q-188**
  (dokunma), **Q-198**, **Q-204**, **Q-205**, **Q-189** — Faho isterse
  döner;
- gerçek kişi/kulüp/şirket adı, gerçek yatırım tavsiyesi, suçun gerçek
  yöntemi yazmaz; `docs/WRITING_STYLE_TR.md` geçerlidir;
- oranları "güzelleştirmez", **ölçer**; test silmez, test gevşetmez;
- derlenmiş olanı oynanmış gibi göstermez.

Her yeni özellik: kendi modül anahtarı + kapalı/açık izolasyon ölçümü +
ekran tarafı testi + belge satırı.

## Sıra

Seçim ölçütü üç soru: oyuncu bunu ister mi, oyunda gerçekten eksik mi
(belgeye değil **koda** bakarak), ve tek pakette bitiyor mu.

### Paket BL — modül anahtarları · **bitti**
Çıkarılabilirlik altyapısı. Paket BK'nın beş özelliği geriye dönük
bağlandı.

### Paket BM — ilk yıllar (0-7 yaş) · **bitti**
Seçim gerekçesi ölçümdür: katalogdaki olaylar yaşa göre tarandığında 0
yaşında **3**, 1 yaşında 8, 4 yaşında 12 aday olay çıktı; 25 yaşında
194. Her yeni hayat 0 yaşında başlıyor, yani oyunun **ilk izlenimi** en
dar havuzdan geliyordu ve ikinci hayatta aynı olaylar tekrar ediyordu.
31 yeni olay eklendi; dördü ilk yılların izini yıllar sonra okuyan
karşılık olayı. Modül: `ilk_yillar_olaylari`.

**Not — `docs/EKSIKLER.md` §3.1 eskimiş.** Paket BM'yi seçerken ilk
aday arkadaşlıktı; koda bakınca küslük, barışma, yakın arkadaş teklifi
ve arkadaşın kendi hayatı `friendship_depth.dart` içinde **zaten
yazılıydı** (D-130). Belgedeki "arkadaşlıkta bunlar yok" satırı bugünün
durumu değil. Aynı dersi bu oturumda ikinci kez aldım: belgeye değil
koda bak.

### Paket BN — eşikteki yıllar (16-20 yaş) · **bitti**
İlk plan "sessiz hikâye izleri"ydi; ölçtüm ve **o iş bitmiş** çıktı:
bugün gerçekten sessiz kalan iz **bir** tane (Paket AS/2 yankı
olaylarını yazmış). Zincir teşhisi de 0 "OYUN" bulgusu verdi — zincirler
kırık değil, sadece derin.

Bunun yerine oyuncu tarafında ölçüm yaptım: o yıl gerçekten
karşılaşılabilecek olay sayısı 18 yaşında 34, 19'da 26,5, 30'da 77.
Çocukluktan sonra en ince bant buydu. 29 olay eklendi, dördü yıllar
sonra geri dönen karşılık. Modül: `esikteki_yillar`.

### Paket BO — ev, eşya ve mahalle derinliği
`docs/NEXT_DEVELOPMENT_OPTIONS.md` §6: konut alınıyor, kiraya veriliyor,
içinde hiçbir şey olmuyor. Eşya envanteri evle ilişkilenmiyor.

### Paket BP — çocukluk ve ergenlik olayları
`docs/EKSIKLER.md` §7'nin 2. maddesi: 0-17 aralığı oyunun en duygusal
ama en ince içerikli dönemi.

## Ölçülmüş dersler

Her paket sonunda buraya tek satır: bir sonraki paket aynı duvara
çarpmasın.

- **Paket BM.** Yeni içerik havuzun **ağırlık bütçesini** yiyor. Sınav
  olaylarının önceliğini koruyan bekçi, rakip toplamını bütün havuz
  üzerinden alıyordu; havuz büyüdükçe pay eriyordu ve bekçi, ilk yıllar
  havuzu eklenmeden önce zaten eşiğin 0,5 üstündeydi. Bekçi düzeltildi
  (Q-207) ama ders duruyor: içerik eklerken ağırlık sayılarının havuz
  genelindeki etkisini ölç.
- **Paket BM.** Yeni içerik **zar sırasını kaydırır**: sabit tohumla
  kurulan senaryo testleri (ekran dökümü gibi) beklenmedik yerde
  kırılabilir. Hayatı oynayan testler hedefe **ulaşana kadar** tohum
  denemeli.
- **Paket BL.** Modül kapısı zar atılmadan **önce** olmalı; yoksa
  kapalı modül bile hayatın akışını değiştirir.
- **Paket BN.** "Nereye içerik gerek?" sorusunun doğru ölçüsü katalogdaki
  olay sayısı değil, **o yıl gerçekten uygun olan** olay sayısı
  (`debugEligibleIds`): katalogda kalabalık görünen yetişkinlik
  olaylarının çoğu iş/ev/portföy şartına bağlı ve çocuğa hiç çıkmıyor.
- **Paket BN.** Eski belgeye göre paket seçmek iki kez yanlış bant
  gösterdi (arkadaşlık D-130'da bitmiş, sessiz izler AS/2'de bitmiş).
  Paketi ölçüm seçer.

## Pano

Güncel ilerleme: `docs/planner/index.html` (betikle üretilir,
`docs/planner/tasks.tsv` beslemesiyle).
