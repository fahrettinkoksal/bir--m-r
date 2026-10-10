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

### Paket BO — motorun zar sözleşmesi · **bitti**
`EventEngine._pick` artık kişiyi **çekilişi kazanan olay için** çözüyor.
Eskiden her havuz girdisi için kişi çözülüyor ve `rng` tüketiliyordu; o
yaşta hiç çıkamayacak bir olay bile zar sırasını kaydırıyordu. Yeni
sıra: ucuz kapılar → kişiden bağımsız koşullar → kişi **adayları**
(zarsız) → bir zarla çekiliş → kazananın kişisi. Yan ürün olarak
`requireReachable` koşulu aday süzgecine taşındı: erişilemeyen bir
kardeş çekildi diye elenen olay, erişilebilir kardeş varken artık
eleniyor değil (D-093 aynı hatayı öbür seçicide kapatmıştı).

Dengenin kaymadığı iki bağımsız blokta 400'er hayatla ölçüldü; sapma
yönü bloklar arasında ters döndü, yani sistematik etki yok
(`PROJECT_STATUS.md`). Bekçi: `app/test/paket_bo_zar_bagimsizligi_test.dart`
— eski motorda kırılıyor, yenisinde geçiyor.

Tam süit iki gerçek boşluk gösterdi. Biri: okulun **tek** öğretmeni
vefat edince yerine kimse gelmiyordu — ölüm turundan sonra öğretmensiz
kalan sınıfa artık yeni öğretmen geliyor ve günlüğe satır düşüyor.
İkincisi: UI smoke testi takılmayı sessizce yutuyordu; 10 hayatın
2'sinde duruşma penceresi modal kalıp arayüzü kilitliyordu ve test
yine geçiyordu. İkisi de ölçülüp düzeltildi (`PROJECT_STATUS.md`).

### Paket BP — oturduğun ev · **bitti**
Seçim gerekçesi ölçümdür: katalogdaki 524 olayın kapıları sayıldı —
kiracı 11, kiraya veren 14, boş ev 8, **oturulan ev 0**. Motorda böyle
bir koşul bile yoktu, dolayısıyla kendi evinde oturan oyuncunun konut
havuzundan aday olayı 30/40/50/60 yaşında sıfırdı (kiracının sekiz).
Evini alınca hayat sessizleşiyordu.

`requiresOwnedResidence` kapısı eklendi ve 28 olay yazıldı; yedisi
yıllar sonra kendi izini okuyan karşılık. Modül: `oturulan_ev`.

Tam süit bir bot hatası gösterdi: bot oturmak için aldığı eve taşınma
masrafı kalmadığı için taşınamıyor, sonra o ev "boş ev" sayılıp kiraya
veriliyor ve bir daha asla kendi evinde oturmuyordu (ev sahibi 25
hayatın 18'i). Politika düzeltildi; oturulan ev olayını gören hayat
7/25'ten 20/25'e çıktı.

### Paket BQ — görünüm seçimi (sıradaki)

Oyunda koyu tema **var** (`BirOmurTheme.dark()`) ama oyuncu
seçemiyor: `ThemeMode.system` sabit. Ayarlara üç seçenek (sistem /
açık / koyu) eklenecek; kayıtta duracak.

### Paket BR adayları (ölçülmüş, sıralanmadı)

- **İlk eve taşınma hatırlatması.** Paket BP'de ölçüldü: oyuncu ev
  alabiliyor ama taşınmayı yalnızca *Evlerim* ekranındaki düğmeden
  öğreniyor; hatırlatan satır yok. Ölçüm botunun da aynı yere düşmesi
  (ev alıp hiç taşınmaması) bunun gerçek bir görünürlük boşluğu
  olduğunu gösteriyor.
- **Komşunun kalıcı kişi olması.** Paket BP apartmanı metinde yaşattı.
  Komşuyu gerçek kişi yapmak yeni bağ türü, ilişkiler ekranı satırı ve
  erişilebilirlik kuralı gerektirir; kendi paketi olmalı.
- **Eşyanın evle ilişkisi.** `docs/NEXT_DEVELOPMENT_OPTIONS.md` §6'nın
  kalan yarısı: envanterdeki eşya hangi evde duruyor, taşınınca ne
  oluyor, ev eşyası yıpranıyor mu.

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
- **Paket BN.** İçerik eklemek **kapı olaylarını** seyreltir: yılda bir
  olay yuvası var ve tanışma gibi bir alt sistemin kapısı, süs
  olaylarıyla aynı ağırlıkta yarışırsa kaybeder. Ölçüldü: 16-20 bandına
  29 olay eklenince ilişki kurma oranı %65,3'ten %52,7'ye düştü;
  bandın kendi tanışma olayları (ağırlık 12) %62,7'ye çıkardı. Yeni
  banda içerik eklerken o bandın kapılarını da aç.
- **Paket BN.** Motor, aday taramasında yaş/koşul denetiminden **önce**
  kişi çözümü yapıp `rng` tüketiyor. Sonuç: havuza eklenen her olay, o
  olayın hiç çıkamayacağı hayatlarda bile zar sırasını kaydırıyor ve
  tohumlu ölçümleri kırıyor. Geçici çözüm: mekanik ve ekonomi
  ölçümlerini modüller **kapalı** koşmak. Kalıcı çözüm Paket BO'da
  geldi.
- **Paket BO.** Motorun çekirdeğini değiştiren bir paket, dengeyi
  **dağılımla** savunmak zorunda: tek tohum, tek blok ve tek metrik
  yanıltıyor. 160 hayatta medyan servet %18 kaymış görünüyordu; 400
  hayatta fark %2'ye indi ve ikinci tohum bloğunda sapmanın yönü ters
  döndü. Ölçüyü büyütmeden "değişmedi" denmez.
- **Paket BO.** Zar sırasını değiştirmek, gizli duran gerçek boşlukları
  görünür yapar: sekiz tohumla koşan sınıf testi bir kuralı değil
  kurayı ölçüyordu ve kaydırınca okulun tek öğretmeninin vefatı ortaya
  çıktı. Tohuma çakılı bir bekçi düştüğünde ilk soru "tohum mu kaydı?"
  değil, "bu testin iddiası gerçekten bir kural mı?" olmalı.
- **Paket BP.** İçerik eklemeden önce **kapıyı** say: "konut olayı var
  mı?" sorusunun cevabı 30'du, ama hepsi başkasının eviydi. Katalogdaki
  olay sayısı değil, oyuncunun o durumdayken gördüğü olay sayısı
  ölçülür.
- **Paket BP.** Ölçüm botu bir özelliği hiç kullanmıyorsa, o özelliğin
  içeriği "erişilemez" görünür. Bot oturmak için aldığı eve
  taşınamıyordu; düzeltmeden önce yeni havuz 7/25 hayatta görünüyordu,
  sonra 20/25. Yeni içerik ölçülmüyorsa önce **botun o yolu yürüyüp
  yürümediğine** bak.
- **Paket BO.** "Döngüden çık" bir bekçiyi kör eder: `if (!ilerledi)
  break;` yazan smoke testi, arayüz 65 yaşında kilitlenmişken bile
  yeşil kalıyordu çünkü iddia yalnızca "on yıl geçti mi" diye
  soruyordu. Bir döngüden erken çıkmanın **sebebi** ya iddiaya
  girmeli ya da testi düşürmeli.
- **Paket BO.** Bekçi yazarken bekçinin **eski kodda kırıldığını** da
  göster. Paket BO'nun bekçisi eski motorda iki testten kalıyor, yeni
  motorda geçiyor; yoksa testin neyi koruduğu belgede kalır, kodda
  kalmaz.

## Pano

Güncel ilerleme: `docs/planner/index.html` (betikle üretilir,
`docs/planner/tasks.tsv` beslemesiyle).
