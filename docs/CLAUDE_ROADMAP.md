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

### Paket BQ — görünüm seçimi · **bitti**

Koyu tema koddaydı, seçim yoktu: uygulamanın kökü `ThemeMode.system`
ile sabitti. Ayarlar → Görünüm'e üç seçenek geldi (cihaza göre / açık /
koyu), seçim kayıtta duruyor ve anında uygulanıyor. Golden testlerinin
tema zorlaması korundu: `BirOmurApp.themeMode` dolu verilince kayıttan
güçlü.

### Paket BR adayları (ölçülmüş, sıralanmadı)

- ~~**İlk eve taşınma hatırlatması.**~~ **Yapıldı (Paket BR/1).** Konut
  alımının sonucuna tek cümle eklendi; yalnızca kendi evinde oturmayana
  çıkıyor (Q-213).
- ~~**Komşunun kalıcı kişi olması.**~~ **Yapıldı (Paket BU).** `komsu`
  ve `eskiKomsu` bağ türleri, `Person.homeTie` ev bağı, taşınmada devir,
  12 kişi hedefli olay, Komşular ekranı ve `komsular` modül anahtarı.
  Ölçüldü: komşu tanıyan hayat 145/200 ve 149/200.
- ~~**Eşyanın evle ilişkisi.**~~ **Yapıldı (Paket BT).** 18 ev eşyası,
  "Ev ve yaşam" mağazası, döşeme seviyesi, yıllık yıpranma ve "Evinin
  hâli" ekranı. Model: eşya oyuncunun, binanın değil — taşınınca
  eşya seninle geliyor. Yazlığı ayrı döşemek açık bırakıldı (Q-216).

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
- **Paket BS/0.** Düşük bir ürün sayısını bildirmeden önce **huniyi**
  ölç: "hayat başına 0,7 arkadaş" bir oyun eksiği gibi duruyordu, oysa
  tanışıklık 80/80 hayatta vardı, teklif eşiği geçtiğinde %100 kabul
  ediliyordu ve sorun botun her yıl rastgele birine zaman ayırmasıydı.
  Aşama aşama saymak, "oyun mu bot mu" sorusunu tek turda bitirdi.
- **Paket BS/0.** Paket BM'nin dersi ("hayatı oynayan test hedefe
  ulaşana kadar tohum denemeli") ekran dökümünde uygulanmamıştı ve
  botun davranışı değişince orada kırıldı. İkinci yarısı da yazıldı:
  hayatın **son yılının karesi ölü karedir** — oyun o karede bilerek
  özet ekranı gösterir, alt sekme yoktur. Bot hayatından kare alan her
  test canlı kare istemeli; yoksa düşen şey ekran değil, karenin
  kendisi olur.
- **Paket BS/1.** Düşen bir testin teşhisi testin iddiasını haklı
  çıkarsa bile orada durma: aynı satırın **başka durumda** ne yaptığına
  bak. "Diğer ebeveyn hayatta değilse doğum olmaz" ölçülen karede
  doğruydu (hamile olan kişi vefat etmişti) ama aynı satır kadın
  oyuncunun bebeğini de yok sayıyordu. Tek koşulun iki farklı durumu
  kapattığı yerde biri genellikle yanlıştır.
- **Paket BT.** Yeni bir sistem eklerken "eşyası olmayan hayatta tek
  zar atılmaz" kuralını baştan kur: döngü yalnızca sahip olunan eşya
  üzerinde dönünce paket, eski tohumlu ölçümlerin hiçbirini kaydırmadı
  (BO ve BM'de bunu sonradan düzeltmek zorunda kalmıştık).
- **Paket BT.** Servet ortalaması tek bloğa güvenilemeyecek kadar
  oynak: aynı özelliğin servet etkisi bir blokta -12,2 M, ikinci blokta
  +13,2 M çıktı. Para etkisini **yön** üzerinden okumak gerekiyor,
  büyüklük üzerinden değil.
- **Paket BU.** Yeni bir kişi türü eklerken onun **başlangıç bağının
  sıralamadaki yerine** bak: komşunun başlangıç yakınlığı (8-22) sınıf
  arkadaşından (35-55) düşük olduğu için botun "en yüksek bağlıya
  yoğunlaş" politikası komşuyu hiç seçmedi ve içerik 200 hayatta
  **sıfır** kez arkadaşlığa dönüştü. Ölçüm aracının önceliklendirmesi,
  yeni içeriği görünmez yapabilir.
- **Paket BU.** "Bot yapmıyor" ile "oyun yapamıyor" ayrımını tek
  teşhisle çöz: komşuyla her yıl vakit geçiren oyuncunun bağı 2-4 yılda
  eşiği geçiyordu. Botun bütçesini ölçmek yerine **oyunun üst sınırını**
  ölçen küçük bir probe, paketin yönünü bir turda belirledi.
- **Paket BV.** Döküm **yaşa** göre kare alıyorsa duruma bağlı
  ekranları hiç göremez: yeni doğan, denetim dönemi ve gebelik aylarca
  "okunmamış" listede kaldı. Hayatı oynatıp **hâli arayan** bir kare
  arayıcısı üç ekranı tek turda açtı.
- **Paket BV.** Küçük bir katalogda "rastgele ad" çakışma üretir ve bu
  **kural** gibi görünür: 20 isimle ve medyan 58 kişiyle iki yaşayan
  kişinin aynı adı taşıması 283/300 hayatta oluyordu. Önce havuzun
  kapasitesini ölç, sonra kural tartış (Q-198 #6).
- **Paket CA.** Yeni bir ekonomik sistemin değerini **oyunun kendi
  ölçeğine karşı** ölç. Sigortayı ekledim, ilk kalibrasyonda poliçe 200
  hayatın hiçbirinde kâra geçmedi (ömür primi 1.044.000 ₺, karşılanan
  45.600 ₺) — yani karar değil tuzaktı. Primleri ölçülen hasar
  dağılımına göre indirdim, ama asıl bulgu başkaydı: medyan oyuncunun
  serveti 37-43 **milyon**, oysa sigortalanabilir en büyük zarar 85.000
  ₺. O ölçekte hiçbir poliçe fark etmez. Bir sistemin "faydalı" olup
  olmadığını sormadan önce **oyuncunun cebiyle zararın büyüklüğünü
  karşılaştır**; aksi hâlde doğru çalışan ama anlamsız bir mekanik
  yazarsın.
- **Paket CB.** Bir bekçi, koruduğu şeyin **yanlış ölçüsünü** sayarsa
  hatayı gizler. "Okuma hobisinin tavanı kütüphanedeki kitap sayısıdır"
  diyen test `kBookCatalog.length` (22) sayıyordu; katalogda üç kimlik
  iki kez tanımlıydı, yani gerçek tavan 19'du ve merdivenin tepesi ("Usta",
  20 deneyim) **hiçbir hayatta ulaşılamıyordu**. Çakışma hem oyunu hem
  bekçiyi aynı anda bozmuş. Katalog bekçisi yazarken satır değil
  **tüketilebilir tekil birim** say: kimlik, pencere, tekrar kuralı.
- **Paket CB.** "Bot bu sistemi hiç kullanmıyor" bulgusu, sistemin
  **tek besleyicisinin** ne olduğunu sormadan yorumlanamaz. `okuma`
  hobisinin `activityIds` kümesi boştu; onu yalnızca kütüphanede
  bitirilen kitap besliyor. Bota okuma eklemek de yetmedi: D-125'ten
  beri her aktivite "ilerleme" sayılıyor ve sayfa çevirmek bir aktivite
  olduğu için kitap mutlaka olayla kesiliyordu — bot 0-1 sayfada
  kalıyordu. Çok adımlı bir eylemi ölçmek istiyorsan **araya giren
  pencereyi de ölçüm aracının karşılaması** gerekir; yoksa "oyuncu bunu
  yapamıyor" diye yanlış bir OYUN bulgusu yazarsın.
- **Paket CC.** "Bu yaş bandı aç mı?" sorusunun cevabı "hayır" olsa bile
  içerik sorunu olmayabilir demek değil. 65+ bandında yılda 75,3 olay
  uygun hale geliyordu — kıtlık yok. Ama o taramadaki 228 olaydan
  yalnızca **11'i** o yaşlara aitti; 70 yaşındaki oyuncu 40 yaşındakinin
  havuzunu çekiyordu. Bir bandı ölçerken **sayıya değil, sayının
  içindekine** bak: kaç olay değil, kaç olay *o yaşa ait*.
- **Paket CC/1.** Bir bekçi, tasarımın **söylemediği** bir şeyi şart
  koşabilir ve yıllarca kimse bakmaz. "Kimse milyarder olmasın" yazan
  bekçinin yorumu "en yüksek net varlık 100 milyonun çok altında"
  diyordu; gerçekte iki pakettir 302M'de duruyordu ve motorun kendi
  belgesi (AD/6) hedefi "milyarderlik **çok nadir**" diye yazıyordu.
  Yani bekçi "hiç", tasarım "nadir" diyordu. Kırmızı yanınca sayıyı
  yükseltmek de içeriği geri almak da yanlış cevaptı: doğru cevap
  **iddiayı tasarımın belgelenmiş hedefine çevirmek** ve altındaki açık
  soruyu (portföyden hiç para çekilmemesi) kuyruğa, karar sahibine
  götürmekti. Bir bekçi kırmızı yandığında ilk soru "eşiği mi
  değiştireyim" değil, **"bu bekçi hangi onaylı kuralı koruyor?"**
- **Paket CD.** "Bu olay hiç çıkmıyor" raporu, botun **seçim
  politikasının** raporudur. En iyi puanlı dalı alan bot, çok dallı 595
  olayın 117'sinin yalnızca bir dalını geziyordu ve 22'sini hiç
  görmüyordu; yarı yarıya en düşük dalı alan kapsam modunda liste 13'e
  indi ve iki listenin **ortak** kısmı yalnızca altı olay oldu. Yani
  "görülmedi" listesi politikaya ve tohuma bağlıydı. Gerçek şüpheli,
  **iki politikada da** kaçan olaydır; birinde kaçan olay yalnızca
  botun tercihidir.
- **Paket BY/1.** Ölü kod ölçümde "etki yok" diye görünür, hata diye
  değil. Kapsam modunun iş değiştirme dalı oyunun kuralı yüzünden hiç
  çalışmıyordu (`applicationAvailability` çalışan oyuncuyu engelliyor)
  ve ben farkı **tek tohum öbeğinde** görüp "genişletiyor" diye
  yazmıştım; üç öbekle ölçünce fark kayboldu (35/30, 33/34, 32/27). Bir
  aracın işe yaradığını söylemeden önce **aynı tohumlarla iki modu**
  karşılaştır ve farkın tohum değişince ayakta kalıp kalmadığına bak.
  Düzeltmeden sonra fark tartışmasız oldu: 52/55 meslek, hayat başına
  2,5 → 14 iş.
- **Paket BZ.** Bir olay hiç çıkmıyorsa **koşulunu metniyle karşılaştır**.
  Kimliğinde "üniversite" ve "kampüs" yazan dört olay
  `requiresSchoolStudent` istiyordu ve o kapı yalnızca 1-12. sınıfı
  kabul ediyor; yani olaylar tam hedef kitlesini (üniversiteliyi)
  dışarıda bırakıyordu. Havuz rekabetini suçlamadan önce kapının doğru
  kapı olup olmadığına bak — ve bu sınıf hatayı yakalayan tarayıcıyı
  bekçi olarak bırak.
- **Paket BY.** "Hiç girilmeyen meslek" sayısını tek bir sayı olarak
  rapor etmek aylarca yanlış ize götürdü. Doğru rapor **gerekçeye göre
  öbeklenmiş** olandır: botun kendi kuralı mı, üniversite bölümü mü,
  hobi basamağı mı, şehir mi? `yz_kurye` 210 yıl ilanda açıktı ve ilk
  okunan kilit gerekçesi ("ehliyet") yanlıştı — gerçek sebep botun yaş
  filtresiydi. Kilit gerekçesini **o yılın** durumundan oku, hayatın
  ilk kaydından değil.
- **Paket BX.** "Hiç görülmeyen olay" iki ayrı şey olabilir: **kapı
  kapalı** ya da **çekiliş kaybediyor**. İkisini ayırmadan düzeltmeye
  kalkmak yanlış yeri tamir ettirir. Ayıran ölçüm tek satır: olay kaç
  hayatta **uygun hale geldi**, kaç hayatta **görüldü**. Futbol
  zincirinde cevap 31'e 1 çıktı; yani koşullar değil, yıllık havuzdaki
  pay sorunluydu. Bir içeriğin penceresi kısaysa (kulüp üyeliği 2-4 yıl)
  genel havuzla aynı ağırlıkta yarışması onu görünmez yapar.
- **Paket BW/0.** Bir bulguyu kapatmadan önce **çakışan tarafın kim
  olduğunu say**. "Çocuk hanedeki bir adı taşıyor" bulgusunun 52/63'ü
  çocuk-çocuk çakışmasıydı ve sebebi oyun değil, botun sekiz adlı
  sabit isim listesiydi. Ölçüm aracının kendi kısıtı üç pakettir
  oyunun kuralı gibi okunuyor (BS/0 arkadaşlık, BU komşu, BW ad):
  yeni bir oranı rapor etmeden önce "bu sayıyı oyun mu üretti, araç
  mı?" sorusunu sor.
- **Paket BV.** İçerik değişikliği de zar kaydırır: isim havuzunu
  büyütmek, piyasa tohumu oyuncunun **adından** türediği için bütün
  işletme/yatırım yollarını kaydırdı ve tek tohuma dayanan dört bekçiyi
  kırdı. Kırılan bekçiyi **gevşetme**: iddiayı dağılıma ya da motorun
  kendi formülüne bağla. Sönümleme bekçisi artık
  `1 + 0,30·(1−r)^14` tabanını okuyor, elle konmuş bir eşiği değil.
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
