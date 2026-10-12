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
- **Paket CE.** Derin bir zincir, kısa bir pencerede **matematik
  gereği** tamamlanmaz. Futbol kulübünde üyelik ortalama 3,9 yıl sürüyor
  ve o süre boyunca 1,6 kulüp olayı çıkıyor; oysa havuzda 14 futbol
  olayı var ve ikinci halkalar aynı pencerede ikinci bir çekiliş
  istiyor. Yani içerik, motorun hiç üretmediği bir yoğunluğa göre
  yazılmış. İçerik yazarken "kaç olay var" değil **"oyuncu o pencerede
  kaç çekiliş alıyor"** sorusunu sor; ikisi tutmuyorsa ya olay
  garantilenir ya zincir tek olayın içine gömülür.
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
- **Paket CF/1.** Tam eşiğe oturan bir oran (`Expected > 0.7, Actual
  0.7`) eşik sorunu değil **çözünürlük** sorunudur: 20 çiftte her çift
  10 puan. Örneklemi büyüt. Büyütünce asıl bulgu çıktı: gerçek oran
  %62, yani 0,70 hiçbir zaman desteklenmiyordu — eski eşik şanslı bir
  20 çiftlik ölçüme kalibre edilmişti. Bir eşiği indirmeden önce
  **oranın bileşenlerini** ölç: burada denemelerin yarısı (104/210)
  tasarım gereği sıfır ihtimalli çiftlerden geliyordu, ihtimali olan
  çiftlerin oranı ise %87,5'ti. Tek bir toplam sayı, biri tasarım
  kapısı olan iki ayrı olguyu topluyorsa **kalibrasyon taşıyamaz**;
  bekçiyi huniye çevir.
- **Paket CF/1.** İki tahmin aracı ters yöne işaret ederse hatayı
  araçta ara. Çift başına `1 − Π(1−p)` ile hesaplanan öngörü gözlemin
  **altında** (22,1 vs 28), deneme başına `Σp` ile hesaplanan öngörü
  **üstünde** (42,1 vs 28) çıktı. İkincisi de yanıltıcıydı: gebe kalan
  çift denemeyi bırakıyor, yani iki sayı da seçilmiş örnekleme
  bakıyordu. Doğru soru "kaç çift gebe kaldı" değil, **"her deneme zara
  ulaştı mı"** idi — ve o 210/210 çıktı.
- **Paket CG.** Bir ekranın yanlış satırı bazen metin hatası değil, bir
  **kapının eksikliği**dir. Cezaevindeki hayatın Varlıklar ekranı
  "Ailesinin yanında" yazıyordu; düzeltilecek şey cümle değil, konut
  motorunun hükümlülüğe hiç bakmamasıydı — aktivite, iş ve işletme
  motorları bakıyordu, konut atlanmıştı. Bir ekran yanlış bilgi
  veriyorsa **o bilgiyi üreten motorun kapılarını** say: aynı kuralı
  uygulayan kardeş motorlar varsa, eksik olan hangisi?
- **Paket CG.** Aynı cümleyi iki yerin kurması, biri değişince ötekinin
  sessizce eskimesidir. Doğum satırı adı elle yazıyordu, ad verme ise
  yeni bir satır ekliyordu; sonuç aynı yılda iki addı. Cümle tek bir
  yerden kurulunca (`Parenthood.birthSentence`) arayan da yazan da aynı
  kalıbı kullanıyor. Bir metin sonradan değişebilen bir veri taşıyorsa
  (ad, şehir, iş), o metni **tek bir yerde** kur.
- **Paket CH.** Olumsuz sonuç da bulgudur ve bekçisi olmalı. "Hangi
  yıllarda hiçbir şey olmuyor?" sorusunun cevabı "hiçbiri" çıktı; buna
  rağmen paketin çıktısı boş değil, çünkü o durumu **sabitleyen** bir
  bekçi bıraktı: bir bandın karanlığa düşmesi (BZ/CD/CC'de tek tek
  olaylarda yakalanan desenin bant ölçeği) artık tek bir testte
  görünür. Ölçüp "sorun yok" demek, ölçümü atmak değil; eşiği yazıp
  gitmek demek.
- **Paket CH.** Bir sayıyı rapor etmeden önce "bu tavanı oyun mu koydu,
  araç mı?" diye sor — ama cevabı **ikisi birden** olabilir. Çocukluğun
  yıl başına 1,0 yoğunluğu yaş 1-3'te oyunun kendi tercihi (hiç eylem
  sunmuyor, D-180), yaş 4-5'te ise aracın tabanı (oyun 32 etkileşim
  sunuyor, bot 1-2 kullanıyor). Aynı sayının iki yarısı iki farklı
  sebepten; tek bir cümleyle sınıflandırmak yanlış olurdu.
- **Paket CI.** Yeni bir sistem yazarken önce **oyunda o işi yapan yol
  var mı** diye bak. Arkadaş grubu için ayrı bir buluşma motoru yazmak
  cazipti; oysa birden çok kişiyle aktiviteye gitmek Paket X/2'de
  zaten vardı. Grup yalnızca **kalıcı kimlik** ekledi: kimlerle, ne
  zamandan beri, kim ayrıldı. Maliyet, kota ve etki tek yerden okunuyor.
- **Paket CI.** Kendi kurguna da ölçümle bak. Grup üç kez yanlış
  kurulmuştu ve üçünü de bot ölçümü söyledi: (1) aday kümesi oyunun
  refakatçi kuralından geniş olduğu için grup kurulup **hiç
  buluşamıyordu**; (2) bot bloğu aktivite rutininin sonunda olduğu için
  sıraya hiç gelmiyordu (D-125 yılı erken bırakıyor); (3) buluşmaya
  bütün üyeler gönderildiği için, bağ sönünce buluşma sessizce
  düşüyordu. Hiçbiri kodu okuyarak görünmedi; "120 hayatta kaç kez
  oldu?" sorusu gösterdi.
- **Paket CI.** Bir eşiği seçerken dağılımın **kırılma noktasını** ara.
  Grup adayı için bağ eşiği 35'te her hayatta üç kişi buluyordu, 40'ta
  yalnızca beşte birinde. Sebep: sınıf arkadaşının başlangıç bağı
  35-55 aralığında, yani 35 eşiği "herhangi bir sınıf arkadaşı" demek.
  Eşik oyunun kendi sayısına (`Outing.prototypeOnlyCloseFriendBond`)
  bağlandı; uydurulmadı.
- **Paket CJ.** "Belgede eksik yazıyor" bir bulgu değil, bir **iddia**;
  önce koda bak. §3.2'nin beş maddesinden dördü çoktan kapanmıştı
  (boşanma, işsizlik, oyuncudan para isteme, torunun hayatı) ve belge
  bayatmıştı. Beşincisi gerçekten boştu — paket onun üzerine kuruldu,
  belgenin tamamına değil.
- **Paket CJ.** Bir sistemin **aynadaki hâli** varsa, sayıları ondan al.
  Yaşlılıkta bakım `ElderCare`'in tersi: yaş eşiği (70), "yaş tek
  başına yeter" kuralı (+10), çocuk payı kademeleri ve "havadan para
  üretilmez" kuralı oradan geldi. Yeni denge uydurmak yerine var olan
  dengeyi çevirmek, hem Faho'ya anlatılabilir hem de tek yerden
  değiştirilebilir oluyor.
- **Paket CJ.** Para yönünü ölçüm düzeltti. İlk yazımda çocuk oyuncunun
  **cebine** para koyuyordu; ölçüm gösterdi ki 736 bakım yılının
  yalnızca 8'inde oyuncunun parası yetmiyor (ölüm anı net servet
  ortancası ~39,6 milyon ₺), yani kapı pratikte hiç açılmayacaktı. Yön
  çevrildi: para cepten çıkar, çocuk faturanın bir kısmını üstlenir.
  Tavan koymadan ölçtüğümde çocuklar faturanın **%100'ünü** kapatıyordu
  ve "para gerçekten çıkar" boşa düşüyordu; pay %60 ile sınırlandı.
- **Paket CJ.** Ölçüm aracının kendi gölgesine dikkat et: bot kararı
  yılın başında verdiği için `onPreAge` ile taranan **her** kare "bu
  yılın kararı verilmiş" oluyordu ve kapıların gerekçeleri hiç
  ölçülemiyordu (ilk koşuda altı test bu yüzden kırmızıydı). Çözüm
  durumu kurmak değil, botun o politikasını `BotOverrides` ile
  kapatmak oldu — oyunun sayıları değişmedi, tarama karar **öncesi**
  kareyi buldu.
- **Paket CK.** "Hiç görülmedi" bir sonuç değil, bir **olasılık
  sorusu**. Olayın aday olduğu kare sayısını ve ağırlık payını
  hesaplayınca beklenen çıkış 1,47 ve 0,12 çıktı; 150-200 hayatta
  sıfır görmek bunların ikisinde de şans dahilinde (%23 ve %89).
  Hesaplamadan "ulaşılamaz içerik" demek, Paket CD'nin listesinde iki
  olayı haksız yere suçlu bırakmıştı.
- **Paket CK.** Kapıyı yazarken **üretimin ne ürettiğine** bak. Olay
  3-7 yaş diyordu ama koşulu "kardeş ≤ 4 yaş"dı; tam kardeş oyuncudan
  her zaman büyük doğduğu için bu, bandı tek yıla indiriyordu. Eşiği
  seçmek için tarama yapıldı (4/5/6/7/9) ve 6'da hem beklenen çıkış
  2,07 → 5,84 oldu hem ilan edilen beş yılın hepsi kullanılmaya
  başladı. Eşik "güzel görünen" sayı değil, **dağılımın kullanılabilir
  olduğu** nokta.
- **Paket CR.** Kancanın **nerede** çalıştığını bilmeden sayı
  okumayın. Aynı kör nokta üç kez yanlış bulgu üretti: yeni doğan
  bebek (CG), yaşlılıkta bakım kararı (CJ) ve bekleyen duruşma (CR —
  250 hayatta "0" görünen sayının gerçeği 57). Üçünde de araç, botun
  o kareyi **zaten yanıtlamış** olduğu bir noktada bakıyordu. Artık
  bekleyen kareler için ayrı bir kanca var (`onPending`) ve kör nokta
  bir testle sabitlendi: `onPreAge` bekleyen duruşmayı görmeye
  başlarsa test bunu söyler.
- **Paket CR.** "Hiç olmuyor" diyen bir sayıyı rapor etmeden önce
  **ikinci bir kaynağa** bak. Botun kendi kaydı (`wentToTrial`) ilk
  turda zaten doğruyu söylüyordu; iki kaynağı karşılaştırmak beş
  dakikalık işti, yanlış bulguyu belgeye yazmak ise paket maliyeti.
- **Paket CQ.** Bir alan **bazı** durumlarda atanıyorsa, ekran onu
  koşulsuz yazmamalı. Kulüp rolü yalnızca rekabetçi kulüplerde
  atanıyor; kart ise her kulüpte `role.label` yazıyordu ve fotoğraf
  kulübünde sekiz yıl "Yedek" görünüyordu. Kusur ne motorda ne
  veridedir: **eksik koşul ekrandadır.** Benzer kalıbı ararken
  "bu alan kim tarafından, hangi koşulda yazılıyor?" sorusu yeterdi.
- **Paket CQ.** Hunide darboğazı yanlış yerde arama. "İlk 11'e çıkan
  2/150" sayısı rol eşiğini suçlu gösteriyordu; kulüp kırılımı
  alınınca eşik genelde ulaşılabilir çıktı (321 üyeliğin 83'ü) ve
  gerçek darboğaz **futbol takımına giren üyelik sayısı** (21) oldu.
  Kırılımı almadan kök neden yazılmaz.
- **Paket CP.** Ölçüm aracının **başarı ölçütünü** de sına.
  `endLifeByChoice` başarıda boş metin döndürüyor; kapsam botu "boş
  değilse oldu" sayıyordu, yani aksiyonun başarısını kapsam dışı,
  başarısızlığını kapsanmış sayıyordu. Kapı hiç çalışmadığı için hata
  yıllarca görünmedi. Bir aksiyonu kapsama bağlarken "oldu" kararının
  nereden okunduğunu kontrol et.
- **Paket CP.** "Denendi ama olmadı" **gerekçesiz** kabul edilmez.
  Grup buluşması 25.038 kez denenip sıfır kez olmuştu ve bu "oyunda
  grup buluşması çalışmıyor" gibi görünüyordu; gerçek engel "Bu eylem
  birlikte yapılmaz."dı — bot yanlış eylemi seçiyordu. Doğru eylemle
  aynı turda 1.367 buluşma oldu. Engelin **metnini** oku.
- **Paket CP.** Aksiyonu kapısına bağla. Koşulsuz çağrılan iki aksiyon
  53 binden fazla boş deneme üretiyordu; ölçüm bunu doğru raporluyordu
  ama rapor bilgi değil gürültü oluyordu.
- **Paket CO.** Aracın **ölçüsüne** de bak, yalnızca kapsamına değil.
  Depoda 65 pencere testi vardı ve hepsi telefon *genişliğinde*
  koşuyordu; kimse yüksekliğe bakmamıştı (3600-14000 px, gerçeğin
  5-15 katı). Ekran dökümü üç tur boyunca sekiz hata buldu ama
  "içerik telefona sığmıyor" sınıfını **yapısal olarak** göremiyordu.
  Oyunun kapağındaki iki modun biri 360x640'ta katlanmanın altındaydı.
- **Paket CO.** Bugün yeşil olan bir bekçi için **aracı sına**.
  Telefon taraması sıfır taşma buldu; bu ya oyunun sağlamlığı ya
  aracın körlüğüydü. Bilerek taşan bir `Row` basıldığında tarama
  "RenderFlex overflowed by 640 pixels" dedi — yani sağlamlık.
  Sınanmamış yeşil test, hiçbir şeyi korumayan testtir.
- **Paket CN.** Yeni bir yıllık zar atışı eklerken **nereden
  çekildiğine** karar ver. Çocuk başına yıllık bir atış ana diziden
  gelseydi 70 yıllık bir hayatta sıranın tamamı kayardı: tek bir
  içerik eklemesi bütün tohumlu ölçümleri ve bekçileri kırardı (Paket
  BO'nun yakaladığı hata tam buydu). Çözüm `derivedRandom(id, age)`:
  kişi-yıldan türeyen kararlı tohum. İki bedava faydası var — modül
  kapalıyken akış eskisiyle **birebir** aynı kalıyor ve kaydı kapatıp
  açarak sonucu yeniden çevirmek imkânsız oluyor.
- **Paket CN.** Bir **görülme** iddiası, beklenen çıkışın sıfırı
  inandırıcı kılmadığı kohortta sınanmalı. CM'in "altı olayın hepsi
  250 hayatta görüldü" testi tek bir koşunun şansıydı: Paket CN
  dünyayı kaydırınca en çok aday üreten olay (261 kare, beklenen 3,53)
  sıfır çekti ve bekçi kırmızıya döndü. Taban düşürülmedi; ölçüt
  düzeltildi — erişilebilirlik **aday kare + beklenen çıkış** ile
  ölçülüyor, görülme ise 500 hayatta. Yeni özellik eklerken yalnızca
  kendi testini değil, **dünyayı kaydırdığı için kırılabilecek**
  eski bekçileri de hesaba kat.
- **Paket CN.** Refactor "davranışı korudum" demekle kanıtlanmaz,
  **damgayla** kanıtlanır. Eşin hastalık kuralı paylaşılan bir dosyaya
  taşınırken eski kodu bir `git worktree`'de bırakıp 40 hayatlık damga
  (hastalık yılları, ölüm yaşı, kişi sayısı, son mutluluk) iki kodda
  karşılaştırıldı: satır satır aynı. `chance(p)` ile
  `nextDouble() < p` eşitliğini de bu yakalardı, gözle okumak değil.
- **Paket CN.** Bir etkinin "uygulanmadığı" kareleri açıklamadan
  bekçiye taban yazma. Hanedeki çocuğun −2'si 35 karenin 17'sinde tam
  görünüyordu; kalanında 0 ve −1. Sebebi ne tavan ne tabandı:
  **azalan getiri** (`StatGain.apply`) kaybı tam uyguluyor ama yılın
  sonraki kazançları daha düşük tabandan işlendiği için 1-2 puanı geri
  veriyor. Açıklamayı bulmadan "çoğunlukla −2" demek, ölçümü değil
  tahmini yazmak olurdu.
- **Paket CN.** Türetilmiş tohumun ölçüm için de faydası var: sonucu
  **önceden bilinebilir** olduğu için bekçi "bu yıl tam bir çocuk
  hastalanacak" karelerini seçip tek yıllık, kontrollü karşılaştırma
  yapabiliyor. 120 hayatta ilk-hastalık yılı 21 kare veriyordu; aynı
  bütçeyle tek yıllık tarama 95 kare verdi.
- **Paket CM.** Bir sistem kayıt tutuyorsa o kayıt **hikâyeye
  dönmeli**; yoksa oyuncu için sayaç değil, boşluk olur. Bakım kaydı
  Paket CJ'den beri duruyordu ve hiçbir olay onu okumuyordu.
- **Paket CM.** Koşulu izle değil **sayaçla** kur. "Üç yıldır yanımda"
  diyen bir cümle, hikâye izine bağlanırsa bir kez destek görmekle
  ömür boyu çıkar ve yalan söyler. İki yeni istek alanı (`minElder…`)
  kayıttan okuyor; bekçi de "sayaç tutmadan aday olan olay sayısı = 0"
  diye ölçüyor.
- **Paket CL.** Yeni bir kart yazdıktan sonra onu **bütün ekran
  olarak** bir kez oku. Anahtar testi aradığını bulur; döküm ekranda
  ne olduğunu gösterir. İki yeni kartın ikisi de kendi testlerinden
  geçiyordu ama biri aynı cümleyi üst üste iki kez yazıyor, öteki
  oyuncunun grubunu üst düzeyde hiç göstermiyordu.
- **Paket CL.** Bekçi yazarken "bu test eski davranışta kırmızı olur
  mu?" sorusunu **çalıştırarak** sor. Tekrar denetimim `contains` ile
  yazılmıştı ve eski metni kaçırıyordu: tek fark baştaki büyük harf.
  Isırma denemesi olmasa bekçi yeşil görünüp hiçbir şey korumayacaktı.
- **Paket CL.** Ekranda bir satırın özet verme kalıbı varsa, komşu
  satırlar ondan geri kalmamalı. Hayvan satırı "Leblebi seninle
  yaşıyor" derken arkadaş satırı sabit bir cümle yazıyordu; oyuncunun
  kurduğu grup o yüzden görünmez kalmıştı.
- **Paket CK.** İçerik ulaşılamaz görünüyorsa "oyun mu, bot mu" sorusu
  cevaplanabilir: `BotOverrides` ile botu yoksullaştırınca
  `suc_ceza_odemesi` çıktı. Oyunun ekonomisine dokunmadan içeriğin
  ulaşılabilir olduğu **kanıtlandı**; geriye kalan "sabıkalı oyuncu
  neden varlıklı" sorusu ise ayrı bir denge işi, kuyruğa yazıldı.
- **Paket CJ.** Bir etkiyi ölçerken tavanı unutma. "Yakınlık artmalı"
  iddiası, bağı zaten **100** olan karede sınanamaz (yaşlılıkta en
  yakın çocuğun bağ ortancası tam olarak bu, Q-205). Bekçi artık
  etkisi ölçülebilen kareyi arıyor ve o karelerin **sayısına** da bir
  taban koyuyor: tavan her kareyi yutmaya başlarsa test bunu söyler.
- **Paket CS.** Bir durum oyunda **ayrı** olarak modellenmişse, o
  durumun kendi içeriği de olmalı. Dulluk ile boşanma ayrı iki
  `MarriageStatus` değeriydi, ekran metinleri bile ayrıydı — ama hiçbir
  `EventRequirement` `MarriageStatus.dul` okumuyordu. Sonuç: 250
  hayatta **502 yıl** dul olarak oynanıyordu ve o yılların tek satırı
  yoktu; oyuncu 70 yaşında eşini kaybetmiş haldeyken 40 yaşında evli
  oyuncunun havuzunu çekiyordu. "Model ayırıyor" ile "oyun ayırıyor"
  aynı şey değil; ikincisi ölçülerek görülür.
- **Paket CS.** Zincirin ilk halkası ne kadar nadir, onu **halka
  yazılmadan** ölç. Kayın ailesi olayı yaşayan kayın istiyordu; o koşul
  evlilik sürerken karelerin %55'inde tutuyor ama dullukta %14'üne
  düşüyor (kayınlar bir kuşak büyük, eşten de önce gidiyorlar). Ağırlık
  4 ile beklenen görülme 0,7'ydi ve zincirin ikinci halkası da onunla
  birlikte ölü doğdu. Çözüm koşulu gevşetmek değil: ağırlığı ölçüme
  göre ayarlamak ve **yaygın durumun** (o taraftan kimsenin kalmaması)
  kendi olayını yazmak.
- **Paket CS.** Bekçinin tabanını tek kohorttan okuma. Dul kare sayısı
  40 `family` hayatında 47, 80 karışık arketip hayatında 51 çıktı —
  arketip bileşimi sayıyı doğrudan değiştiriyor. Taban "ölçüm bu
  durumu gerçekten gördü mü" sorusunu yanıtlamalı, kohortun şansını
  değil; iki ölçümün de altına konur.
- **Paket CS.** Kendi bekçine istisna yazıyorsan dur: depo çapındaki
  bir kural o istisnayı reddediyor olabilir. Beş karşılık olayına
  "kapandı" izi koymuş, kendi testimde bunları "hikâyenin sonu" diye
  muaf tutmuştum. `paket_ar_hikaye_izi_test.dart` muafiyeti tanımadı:
  okunmayan iz sayısı 22'den 27'ye çıkıyordu. Doğru cevap muafiyeti
  genişletmek değil, **izi hiç yazmamaktı** — tekrar çıkmayı
  `seenEventIds` zaten engelliyordu, izin bir işi yoktu. Eski ve dar
  bir çıta, yeni ve geniş bir istisnadan güçlüdür.
- **Paket CT.** Yeni bir sistem yazdıktan sonra onun **ekranını** da
  oku. Paket CS dulluğa 20 olay yazdı, testleri yeşildi; dökümde dul
  karesini basınca iki hata çıktı ve ikisi de dulluğa ait değildi —
  dul kare onları **ortaya çıkardı**. Döküm dört turda on gerçek hata
  buldu; her yeni durum için bir kare eklemek en ucuz denetim.
- **Paket CT.** "Kayıt silinmez, kişi vefat etmiş işaretlenir" doğru
  bir kuraldır ama o kuralın **her tüketicisini** düşündürmez. Aile
  meselesi kapanışı `personById == null` arıyordu; kişi hiç
  silinmediği için koşul asla tutmadı ve oyun iki yıl önce vefat etmiş
  anne için bakım kararı sordu. 200 hayatta 3.251 kare, en uzunu 80
  yıl. "Yok olmaz" ile "anlamını yitirmez" aynı şey değil.
- **Paket CT.** Bir metin hatası gördüğünde tek satırı düzeltme,
  **deseni** tara. "Malatya'de" bir yazım hatası gibi görünüyordu;
  grep 19 yer gösterdi. Türkçe eki ada sabit yazmak isimlerin
  yarısında yanlış: ek, son ünlüye ve son ünsüze göre değişir. Doğru
  çözüm tek yerde bir işlev ve onu koruyan bir **kaynak taraması**.
- **Paket CV.** Bir kalıp dosyanın içinde **kısmen** uygulanmışsa, geri
  kalanını ara. `ActivityVenue.minAge` beş satıra kapı koymuş, üçünü
  atlamıştı; sonuç 1 yaşındaki oyuncuya berber, spor salonu ve
  kütüphane. Üç satırın `Key`'i de yoktu — test bulamadığı şeyi
  koruyamaz. Kapı eklerken anahtar da ekle.
- **Paket CV.** Ölçüm aracı **sessizce** başarısız olmamalı. Dökümün
  pencere açıcısı bulamadığı şeyde `return` ediyordu; döküm sıradan bir
  ekran basıyor ve ben "mülakat okundu" sanıyordum. Açıcı ne yaptığını
  yazınca gerçek ortaya çıktı: ekran hiç değişmemiş. Bir adım daha:
  ilk hata mesajım da fazla iddialıydı ("Meslek açıldı ama satır yok")
  — sekmeye bastığımı doğrulamış, ekranın değiştiğini doğrulamamıştım.
  Araç gördüğünü yazar, varsaydığını yazmaz.
- **Paket CV.** "Okundu" ile "arandı" aynı şey değil. Mülakat penceresi
  bu pakette açılamadı; kareyi silmek ya da okundu saymak yerine açıcı
  neden açılamadığını dökümün başına yazıyor. Eksik, görünür bırakılmış
  bir eksik olarak kalıyor.
- **Paket CV/1.** Bir kapı eklerken "bu sayfanın içinde başka ne var?"
  diye sor. `ActivityVenue.minAge` yalnızca eylemlere bakıyor; spor
  salonu sayfası ise dövüş sanatları bölümünü de taşıyor ve o daha
  erken başlıyor. Kapıyı eylem yaşına koymak 7 yaşındaki oyuncunun
  karatesini kapattı. Mekân satırı, içindeki **en erken** şeye göre
  açılır.
- **Paket CV/1.** Hedefli test kümesini değişen dosyanın **adıyla**
  seçmek yetmez; o ekranı **gezen** testlerle seçilir. `ActivitiesScreen|
  activity_|ActivityVenue` desenim aktivite ekranına değen 14 dosyayı
  kaçırdı ve hata CI'da çıktı. Bir ekranı değiştirdiysen o ekranın
  etiketlerini de (menü satırı adları) grep'e kat.
- **Paket CV/1.** Kendi bekçin de yanılabilir. Paket CV'nin testi kapıyı
  `minAge` sanıyordu; düzeltme doğruydu, test kodu haksız yere
  suçluyordu. Bekçi kuralı **gerçek kapıyı** okumalı, varsaydığını değil.
- **Paket CW.** Hedefli kümeyi elle grep'lemek bir CI turuna mal oldu;
  artık `scripts/test_secimi.py` var. Beş sinyal tarar (içe-alma,
  dolaylı, simge, anahtar, **metin**) ve motor/bot dosyası geçtiğinde
  "tam süit gerekiyor" der. Ekran değiştirdiysen `--degisenler --komut`
  ile kümeyi al; adını tahmin etme.
- **Paket CW.** Isırma denemesi **tutmadıysa** demo başarılı değildir.
  Betiğin kendini sınaması iki çiftle yazıldı ve metin sinyalini
  kapattığımda yeşil kaldı — o iki çift başka sinyallerle de tutuyordu,
  yani sınav asıl korumak istediğim şeyi korumuyordu. Yalnızca o
  sinyalle tutan bir çift eklenince ısırma tuttu. "Yeşil geçti" ile
  "doğru şeyi koruyor" aynı şey değil.
- **Paket CX.** "Bu bant zayıf" bir tespit değil, ölçülmemiş bir
  cümledir. §4.1 aylarca "0-5 en zayıf" diyordu; yaş yaş sayınca yaş 0
  ile yaş 12 arasındaki fark **on kat** çıktı (9 aday / 92 aday). Bantı
  düzeltmeye başlamadan önce bandın içinde **hangi yıl** açık, onu say.
- **Paket CX.** İçerik eklemek **çeşitliliği** büyütür, **tempoyu**
  büyütmez. Motor yılın olayını bir kez çeker; 16 olay yazmak bir
  hayatta yaş 0'da görülen olay sayısını değiştirmez. Ölçümü yazarken
  ikisini ayır, yoksa açık kalan soruyu (Q-226) kapattığını sanırsın.
- **Paket CX.** Kendi bekçim ölü içeriği savunuyordu. §5'i "bu iki
  karşılık olayı bot hayatında hiç aday olmasın" diye kurmuştum; bot
  bayrağı yazıyordu, test patladı ve **test haksızdı**. Doğru soru
  küme bazlı "hiç gelmesin" değil, kare bazlı "izi olmayan karede
  gelmesin"di. Bir bekçi patladığında ilk şüphelenilecek şey koddan
  önce bekçinin **sorduğu soru** olmalı.
- **Paket CX.** Kapı sözleşmesini **oku**, çıkarım yapma.
  `livingRelations`'ı "bu bağların hepsi hayatta olmalı" sandım; oysa
  `game_event.dart` "**en az bir** kişi gerekir; olay o kişiyle
  kurulur" diyor ve bu alanın hemen üstünde yazılı. Yanlış varsayımım
  bir bekçiyi yanlış kurdu — ama patlaması gerçek bir kusuru ortaya
  çıkardı: "İki büyükanne" diye başlayan bir metin yazmıştım, kapı ise
  bir büyükanneyi yetiyordu. **"En az bir" kapısı olan olayın metni
  kişi ya da sayı varsayamaz**; artık kaynak düzeyinde bekçisi var.
- **Paket CX.** İçerik eklemenin bedeli yalnız zar kayması değil,
  **başka paketin oranını** bozmak da olabilir. Havuzu anahtarsız
  bıraktım; Paket BM'in "modül 0 yaşta aday sayısını ikiye katlar"
  iddiası, benim olaylarım iki kohortta da sayıldığı için devrildi.
  Çözüm BM'in bekçisini yeniden yazmak değil, içeriği **ait olduğu
  anahtara** bağlamaktı (kataloğun `lostWhenOff` metni zaten
  "bebeklik" diyordu). Kural: Paket BL'den sonra yeni içerik havuzu
  anahtarsız girmez; emsal BM, BN, BP, BU, CC, CI, CJ, CS.
- **Paket CX.** Bir ölçüm **tohuma yapışmışsa** eşiği düşürmek yanlış
  cevaptır. Paket CI §4 arketip başına 12 hayat koşuyordu ama tohumlar
  arketipler arasında paylaşılıyordu: 120 hayat değil 12 tohum. Grup
  kurmak seyrek olduğu için herhangi bir zar kayması ölçümü deviriyordu
  (görülen olay tohuma göre 3 ile 7 arası). Kohortu 500 ayrık tohuma
  çıkardım, sayı iki tohum tabanında da aynı yere oturdu (8/9) ve
  eşikleri **sıkılaştırdım**. İnce kohort, gevşek eşikten daha
  tehlikelidir: yeşil kalır ama hiçbir şey söylemez.
- **Paket CX.** Bir bulgu, testin görüş alanından **çıkarak** kapanmaz.
  `infancy_events_test.dart` büyükanne olayımı yakalamıştı; olayı ayrı
  dosyaya taşıdığımda o test artık onu görmüyordu — yani düzelmiş gibi
  oldu. Kapsamı kaybetmemek için denetimi kendi bekçimde daha genişine
  kurdum. Taşınan kod, taşınan sorumluluk demek değil.
- **Paket CY.** "Hiç olmuyor" bulgusunun ilk şüphelisi **ölçen
  araçtır**. Bir hikâye izi 150 hayatta sıfır kez yazılıyordu; sebebi
  kapı ya da seyreklik değil, botun yılda bir paylaşım yapmasıydı —
  oyun altısına izin veriyor. Araç kapasitenin altıda birini
  kullandığı için **14 medya işi ve bir bölümün tamamı** ölçümde
  görünmüyordu. "Sunulmayan içerik" ile "ölçülmeyen içerik" aynı şey
  değil; ayrımı yapmanın yolu aracın oyunun verdiği hakkı kullanıp
  kullanmadığını saymak.
- **Paket CY.** Bir aracı düzeltmek, gizlenmiş bir **denge sorusunu**
  açığa çıkarabilir. Bot ilgisi kadar paylaşınca takipçi 2.000'den
  2,3 milyona çıktı: erişim formülü paylaşım başına çarpımsal ve
  takipçinin doyma noktası yok. Bu benim düzeltmem değil; ölçtüm,
  sayıları yazdım, **Q-235**'e öneri ve varsayılanla koydum ve hiçbir
  `prototypeOnly` sayısına dokunmadım. Araç hatası benim, denge kararı
  Faho'nun.
- **Paket CY.** Bir bekçi, **tartışması süren** bir sayıyı eşiğe
  bağlamamalı. Takipçi tavanı (2,3 milyon) Q-235'te açık bir soru, bu
  yüzden bekçi onu yalnızca yazdırıyor; eşiğe bağladığım şey
  tartışmasız olan: o içeriğin oyuncunun yolunda **ulaşılabilir**
  kalması. Kalibrasyon onaylandığında bekçi kırmızıya dönmez.
- **Paket CZ.** "Aday oldu mu" ile "gerçekten çıktı mı" aynı soru
  değil. `debugEligibleIds` görülmüş tek seferlik olayı dışlar, yani
  **ilk uygun yılında çıkan** bir olay aday taramasında hiç görünmez.
  Bir karşılık olayımı "47 karede aday değil" diye ulaşılamaz sandım;
  aynı 47 karede `seenEventIds` içinde işaretliydi — 20 yaşında
  çıkmıştı. Ulaşılabilirliği ölçerken ikisini birlikte sor. Paket CR'ın
  kör noktasıyla aynı aile: aracın neyi sorduğu, neyi ölçtüğünden
  önemli.
- **Paket CZ.** İçerik eklemenin faturası aynı pakette iki kez çıktı:
  22 olay havuza girince Paket CJ'nin iki aramalı testi devrildi
  (aranan kare 236'dan 19'a düştü, biri hiç bulunamadı). İkisi de
  seyreklikti; kohort 600'e çıkarıldı, eşikler yerinde kaldı. Bir
  paket içerik ekliyorsa, **aramalı** testlerin kohort büyüklüğü de o
  paketin işidir.
- **Paket CZ.** Bir ratchet ancak **düşürüldüğünde** kazanç olur.
  Sessiz iz sayacı "22'yi geçmesin" diyordu; 22 izin hepsine karşılık
  yazıldıktan sonra ölçüt 0'a çekildi. Düşürmeyi atlasam sayı sessizce
  geri tırmanabilirdi ve test yine yeşil kalırdı.
- **Paket DA.** Rutin notunu ve kendi eski raporlarımı **doğrula**.
  "Yeni doğan bebek karesi 120 hayatta bulunamadı" diye yazılıydı; bir
  kez koşunca dökümün 12 karesinin hepsinin bulunduğu çıktı. Bayat bir
  "bulunamadı" notu, bulunmuş bir kareyi okumamıza engel oluyordu.
  Ama *bulunmak* ile *okunmak* ayrı: o kareleri gözle okuyunca gerçek
  bir hata çıktı.
- **Paket DA.** Bir parametreyi okuyan fonksiyon, onu **kullanmak**
  zorunda. `maybeMarry` doğru bağı `relation` ile alıyordu ama
  `_createSpouse` eşin bağını sabit `cocugunEsi` yazıyordu: kardeşin
  eşi oyuncunun gelini oldu, 150 hayatın 127'sinde, en küçüğü 6 yaşında.
  Parametresi olup kullanılmayan bir alan, sessiz yanlış veri üretir.
- **Paket DA.** Kuyruk bazen cevabı **zaten** yazmış oluyor. "Kardeşin
  eşi kişi kaydı değil, yalnızca bir ad" satırı kuyrukta duruyordu;
  kod onu ihlal ediyordu. Bu yüzden düzeltme onay beklemedi: belgelenmiş
  niyetle kodun çelişmesi tasarım sorusu değil, hatadır. Önce kuyruğa
  bak; orada yazılı niyet, bulgunun hangi sınıfa girdiğini söyler.
- **Paket DA.** Zar akışını kaydıran bir düzeltme, **hiç
  yürünmemiş yolları** da açar. Paket DA'nın faturası iki gizli araç
  hatası oldu: dökümün `ac()` yardımcısı uygulamayı ikinci kez
  açamıyordu (ilk tohum her zaman yettiği için o yol hiç
  yürünmemişti) ve bir bütünleşme testi tek tohumun 28 yaşına kadar
  yaşamasını varsayıyordu. İkisi de "yeşil" görünüyordu çünkü kimse o
  dalı denememişti. Üretim kodunu kaydıran paket, aramalı testlerin
  tohum varsayımlarını da gözden geçirmeli.
- **Paket DB.** Bir kuralın **ikinci yolu** kapısız kalabilir. D-161
  denetim döneminde şehir dışını kapatıyordu ama yalnızca `availability`
  yolunda; `tourAvailability` ikinci bir çıkış yoluydu ve iki kapıyı da
  (cezaevi, denetim) görmüyordu. Bir kural yazıldığında "bu duruma
  giden kaç yol var?" diye sormak gerekiyor — kapıyı bir yola koymak,
  kuralı uygulamak değil.
- **Paket DB.** Kayıtta bir alanın **dolu** olması, o dönemin hâlâ
  sürdüğü anlamına gelmez. Denetim dönemini `probationUntilAge != null`
  ile ölçtüm ve süresi geçmiş kayıtları da saydım: 254 karenin 224'ünde
  kapı haklı olarak açıktı, bekçim kendi ölçüm hatasını kod hatası
  sandı. Doğru ölçüt kodun kendi yüklemiydi (`LegalEngine.onProbation`)
  ve kare sayısı 14'e indi.

- **Paket DC.** Ekranın kendi kapısı, motorun kapısıyla **aynı kural
  olmak zorunda**. `isAranabilir` diploma istiyordu, motor
  (`requirementReason`) istemiyordu; sonucu diplomasız yetişkine iş
  arama satırının **ömür boyu** gizlenmesi oldu. Ölçüldü: motor o
  karede 13 işe izin veriyor, ekran 0 satır gösteriyor. Kural
  motorda yazılıysa ekran onu **çağırmalı**, yeniden kurmamalı — iki
  yerde iki ayrı doğru, biri her zaman yanlıştır.
- **Paket DC.** Yalnızca ekranda olan kusuru **hiçbir bot ölçümü
  bulamaz**. Bot `applyForJob`'u doğrudan çağırıyor, `isAranabilir`'den
  geçmiyor; yani bu hata 3776 testin hiçbirinde görünmüyordu ve
  ancak kare okunarak çıktı. CT ve CU'dan sonra üçüncü kez: **ekranı
  okumak ayrı bir ölçüm aracıdır.**
- **Paket DC.** Yeni bir durum eklerken "bu bayrağı kim daha okuyor"
  diye sormak gerekiyor. Açık lise kaydı `EducationState.enrolled`
  üzerine konsa oyuncu `isSchoolStudent` sayılacak ve `JobMarket` tam
  zamanlı işi kapatacaktı — yani özelliğin bütün anlamı (çalışırken
  okumak) kendi kaydı yüzünden yok olacaktı. Kayıt ayrı bir alana
  kondu ve bekçi bunu ısırma denemesiyle sabitledi.
- **Paket DC.** "Geri dönüşsüz karar" bir tasarım tercihi olabilir ama
  **kaza olmamalı**. Okulu bırakmak 30 işi ömür boyu kapatıyordu ve
  bunu kimse seçmemişti: geri dönüş yolu yazılmamıştı, o kadar. Her
  kalıcı bayrak için "bunu geri alan bir yol var mı?" sorusu ucuz bir
  tarama ve `docs/EKSIKLER.md` §7'ye madde olarak girdi.
- **Paket DC.** Belgeler de eskiyor. §7'deki "hobi kataloğu (4 hobi)
  duruyor" satırı D-152'den beri yanlıştı; aynı belgenin §4.3 tablosu
  12 yazıyordu. Bir paket seçmek için belgeyi okurken **belgenin
  kendisini de denetlemek** gerekiyor; çelişen iki satır varsa koda
  bakmalı.

- **Paket DD.** Bir hata bulduğunda **sınıfını** tara. DC'nin kusuru
  "kalıcı durum bir şeyi ömür boyu kapatıyor, geri dönüş yolu
  yazılmamış" sınıfındandı; aynı soruyu bütün kalıcı durumlara sormak
  ikinci bir örneği (%45 oranla, DC'nin %1,7'sinden çok daha büyük) ve
  üçüncü bir şüpheliyi ortaya çıkardı. Tek bir hatayı düzeltip geçmek,
  o hatanın en ucuz örneğini düzeltmek olabilir.
- **Paket DD.** "Karar bekliyor mu?" ile "kapı açık mı?" **iki ayrı
  sorudur**. Ekran ikisini tek yüklemle soruyordu
  (`needsAfterSchoolChoice`) ve o yüklem "üniversiteye gitmedim" izini
  okuyor; sonucu, kararı veren oyuncunun kapısının ömür boyu
  kapanması oldu. Bir yüklemi ikinci bir soru için kullanmadan önce
  adını okumak yetiyor: adı "needs", "awaiting", "pending" ile
  başlıyorsa o bir **bekleme** yüklemidir, bir **izin** yüklemi değil.
- **Paket DD.** Önceki bir düzeltmeyle çelişen bir bulgu, o düzeltmeyi
  geri almak için gerekçe değil. Satır eskiden 70 yaşındakine bayat
  duruyordu ve düzeltilmişti; benim bulgum kapının kapanmasıydı.
  İkisini birden çözmek için satırı ikiye ayırmak gerekti: bekleyen
  karar ayrı, yapılabilir eylem ayrı. "Ya o ya bu" diye bakarsam
  birinin faturasını diğerine ödetirim.
- **Paket DD.** Her tutarsızlık benim düzeltmem değil. Emeklilikte de
  aynı şekil vardı (motor izin veriyor, ekran kapatıyor) ama açmak
  emekli maaşı + maaş sömürüsü demekti; bu bir **denge kararı**, bir
  tutarsızlık düzeltmesi değil. Ölçtüm, yazdım, kuyruğa koydum
  (Q-237) ve koda dokunmadım. Düzeltmenin bedeli oyuncunun kazancını
  değiştiriyorsa sınır oradadır.

- **Paket DE.** Bir bandı doldurmak **sıradakini açığa çıkarır**. CX
  0-2'yi doldurunca en ince bant 3-6 oldu (yıl başına 1,04 olay, 55
  farklı olay — ilkokulun yarısı). "İçerik yeterli mi" sorusunun tek
  dürüst cevabı bant bant ölçmek; tek bir ortalama (CH'nin 1,0-1,8'i)
  nerede çalışılacağını söylemiyor.
- **Paket DE.** Ölçtüğün sayının **neyle sınırlı** olduğunu bilmeden
  hedef koyma. 3-6'da yıl başına olay sayısını havuz değiştiremez:
  motor ek olay için üç ilerleme adımı istiyor (D-125) ve o yaşta çocuk
  adım üretmiyor. Yani doğru hedef "yıl başına 1,5" değil, "o bir olay
  hep aynı olmasın". Yanlış hedef seçilse havuz iki katına çıkar ve
  ölçüm hiç değişmezdi.
- **Paket DE.** Kendi bekçin kendi metnini yakaladığında **bekçiyi
  gevşetme, metni değiştir**. §4'ün kaynak taraması düğün olayındaki
  "tabaklardan ikisini" ifadesini işaretledi; yanlış pozitifti ama o
  tarama CX'te gerçek bir hata bulmuştu. Bir kelimeyi yeniden yazmak,
  bir bekçiyi kör etmekten ucuz.

- **Paket DE.** Bir tabanı koyarken **beklenen değere ne kadar yakın**
  olduğunu hesapla. CR'nin "içeriden geçen ≥ 10" tabanı 250 hayatta
  beklenen değeri ~9 olan bir olaya konmuştu: kırmızıya dönmesi için
  bir zar kaymasının olması yeterliydi ve oldu. Aynı şey CJ'de üç
  tohumla yapılan karşılaştırmada çıktı (%6,4 ıskalama olasılığı).
  Taban, ölçümün **belirgin** altında olmalı; "biraz altında" demek
  "sıradaki pakette kırmızı" demek.
- **Paket DE.** Yanlış teşhis koyarken de ölç. DD §4 düşünce önce
  "satır tembel listede altta kaldı" dedim (kaydırma ekledim, yetmedi),
  sonra sessiz kare süzgecini `onYear` üstüne koydum ve **hiç kare
  bırakmadı**: `onYear` yılın olayı cevaplanmadan çalışıyor, orada
  `hasPendingEvent` her zaman dolu. Doğru kanca `onPreAge`'di. İki
  yanlış teşhisin ikisi de "makul"dü; ayıran şey ölçüm oldu.
- **Paket DE.** Aynı dosyada iki test iki ayrı kanca isteyebilir. DD
  §4 ekranı sürüyor, yani oyuncunun ekrana baktığı kareyi
  (`onPreAge`) istiyor; DD §2 karar **kilidini** arıyor ve o kilit
  yaş almadan önce kapanıyor, yani `onYear`'da kalmak zorunda.
  "Projede tek doğru kanca var" varsayımı iki testi de kırıyordu.

- **Paket DF.** "Ekranları okudum" demek için **bitiş ekranını** da
  okumak gerekiyor. Üç döküm de ölümde geri dönüyordu, yani her oyunun
  en son gördüğü ekran hiç basılmamıştı — ve ilk basıldığında altı
  karenin beşinde hata çıktı. Bir akışın başı ve ortası okunmuşsa
  sonu da okunmalı; en kolay atlanan kare, oyuncunun en çok hatırladığı
  kare olabilir.
- **Paket DF.** Aynı ekranda iki ayrı yerden okunan aynı bilgi
  **birbirini yalanlayabilir**. Hüküm paneli "3 işte toplam 43 yıl
  çalıştın" diyordu, iki satır altındaki meslek satırı "Son iş:
  Çalışmıyor". Biri geçmişi, diğeri bugünü okuyordu. Bir ekran aynı
  şeyi iki kez söylüyorsa ikisinin **aynı kaynaktan** okuduğu
  denetlenmeli.
- **Paket DF.** Düzeltirken bilgi kaybetmemeye dikkat. "Son iş:"
  önekini de düşürmüştüm; "Aşçı" ile "Son iş: Aşçı" farklı şeyler
  söyler (ikincisi ölürken çalışmadığını da anlatır). Hatayı düzeltmek,
  satırı sadeleştirmek değildir.

- **Paket DG.** "Hangi bant ince?" sorusunun ölçüsü **yıl başına olay**
  değil, **bant yılı başına farklı olay**. Yıl başına sayı 7-11'de
  ortalamaya yakındı (1,47) ama çeşitlilik en düşüktü (20,6; 16-20'de
  33,2). Yanlış ölçüyle bakıp "bu bant iyi" demek kolaydı; oyuncunun
  hissettiği şey tekrardı.
- **Paket DG.** Boşa çalışan iddia, olmayan iddiadan **daha
  tehlikelidir**: yeşil görünür. §7'nin "okul dışı karede aday olmuyor"
  döngüsü 400 karede 0 kez yürüdü, çünkü 7-11 bandında oyuncu kural
  gereği her zaman okullu (okul 6'da başlıyor, 9. sınıftan önce
  kalınmıyor, 15'ten önce bırakılamıyor). İddiayı silmek yerine
  **varsayımı sabitledim**: o üç sayı banda kayarsa test kırılır ve
  değiştiren kişi notu okur. Bir dalı deneyemiyorsan, deneyemediğinin
  **sebebini** sabitle.
- **Paket DG.** İçerik eklemek hiçbir sayıya dokunmadan **zar akışını
  kaydırır**; düşen eski bekçi çoğu kez yeni hatayı değil, o bekçinin
  **yanlış yüklemini** gösterir. İkisi birden düştü: futbol bekçisi
  "kabul edilen" diyordu, niyeti "oynayan"dı (tohum 41961 imzalayıp 19
  yaşında öldü); BM bekçisi "60 hayatta en az bir karşılık" diyordu,
  ölçüldü ve o satırın baştan beri **%2'lik bir kura** olduğu çıktı.
  Taban düşürmek de, kohortu şişirmek de çare değildi: iddianın zar
  gerektirip gerektirmediğini sor. Karşılık olaylarının tek kapısı yaş
  + iz olduğu için iddia **zarsız** kurulabiliyordu.
- **Paket DG.** Arama ölçütünü iddianın kendisinden alan bekçi
  **döngüseldir**: izin adı bozulursa kare hiç bulunmaz ve test sessizce
  yeşil kalır. Bu yüzden yapısal bekçinin yanına zarsız bir **katalog**
  denetimi kondu (her iz okunuyor mu). İki bölüm birbirinin kör
  noktasıdır; her ikisi de ayrı mutasyonla denendi.
- **Paket DH.** Bir kusuru düzeltirken sor: **bu zincirin ikinci bir
  kopyası var mı?** Paket DF ömür sonu ekranındaki "Son iş: Çalışmıyor"
  hatasını düzeltti; aynı zincirin kopyası arşivi yazan kontrolördeydi
  ve orada kaldı — hem de kayıt dosyasına **kalıcı** yazarak. Düzeltme
  artık kopyayı kaldırıyor: zincir tek dosyada, iki çağıran oradan
  okuyor. Kök neden yazım hatası değil çoğaltmaydı.
- **Paket DH.** "Hangi ekran hiç okunmadı?" sorusu tükenmedi: dokuz
  ekranı dört döküm aracıyla karşılaştırınca Geçmiş Hayatlar ekranının
  testlerde **hiç** geçmediği çıktı ve ilk karede iki gerçek hata
  verdi. Ekranın kendi metniyle çelişmesi en ucuz kusur işaretidir —
  panel "arşivde saklanır" derken ekran "henüz tamamlanmış bir hayat
  yok" diyordu.
- **Paket DH.** Kaynak taraması yazarken **yorumları atla**: ilk hâli
  bütün dosyayı okuyordu ve üç bulgusunun üçü de kusuru *anlatan*
  yorumlardı. Kural koda dairdir; gerekçeyi yazmak yasak değil. Aynı
  derste ikinci yarı: yasaklanan şey alanın kendisi değil, onu **yanlış
  bağlamda** okumak (`career.label` yaşayan oyuncuda doğru alandır).
- **Paket DI.** Belgede taşınan "bulunamadı" notunun tarihi vardır:
  rutin aylarca "yeni doğan bebek 120 hayatta BULUNAMADI" diye taşıdı,
  ölçtüm ve `family` arketipinde 60 hayatın **43'ü** bebek karesi
  gösterdi. Arada Paket CF/1 gebelik hunisini düzeltmişti ve kimse
  notu yeniden ölçmemişti. Bir "yok" iddiası, ölçüldüğü günün
  iddiasıdır.
- **Paket DI.** Çelişki gibi duran iki günlük satırı farklı
  motorlardan gelebilir; kaynağı okumadan "çelişki" demek yanlış
  teşhistir. Burada gerçek kusur çelişki değil **nesnesiz cümle**
  çıktı: ret satırı neyin reddedildiğini söylemiyordu ve yanındaki
  satır yüzünden yanlış okunuyordu. Kabul satırı söylüyordu — asimetri
  kusurun kendisiydi.
- **Paket DI.** "Ekranda yazmıyor" demeden önce **nereye yazması
  gerektiğini** sor. Denetim dönemi ana ekranın üst satırında yoktu ve
  kusur sandım; gerekçe eylemin yanındaydı (Okul/Meslek → Adli
  Geçmiş), yani Paket I'nın ilkesine uygun. Üç şüphenin üçü de böyle
  çürüdü; paketin tek gerçek kusuru dördüncüsüydü.
- **Paket DJ.** Bir ölçüm "sıfır" diyorsa önce **aracı** sorgula. Üç
  bildirim türü sıfıra yakın çıktı; biri Faho'nun özellikle istediği
  boşanma bildirimiydi. Kök neden oyunda değil botta: aksiyon kaynaklı
  bildirimi kurduğu satırda kapatıyordu, o yüzden `onYear`'a da Paket
  CR'ın eklediği `onPending`'e de görünmüyordu. Düzeltmeden sonra
  `aktivite` 1'den **8179**'a çıktı. Paket CR aynı kör noktayı yarım
  kapatmış: motor kaynaklı bekleyenleri açtı, aksiyon kaynaklı
  bildirimleri açmadı.
- **Paket DJ.** Ölçümün **kapsamını** da ölç: ilk sondam türleri elle
  yazılmış bir listeyle sayıyordu ve o liste `grep`'in kestiği yerden
  geldiği için 20 türün 12'sini içeriyordu. Enum'u programla okumak
  bir satırdı; elle liste yazmak sekiz türü sessizce dışarıda bıraktı.
- **Paket DJ.** Aynı değeri iki kaynaktan çizen ekran onu iki kez
  yazar. Bildirim hem `happinessDelta` hem `effects` taşıyordu ve
  pencere ikisini de bastı: "Mutluluk -15 / Mutluluk -15". Düzeltme
  kaynağı kaldırmak değil **çakışmayı** kaldırmaktı; hangi kaynağın
  dolu olduğu bildirime göre değişiyor.
- **Paket DK.** Botun dokunmadığı her mekanik aynı zamanda **ölçülmemiş
  bir ekonomidir.** Piyangonun beklenen getirisi hiç hesaplanmamıştı;
  katalogdan çıkarmak zar bile gerektirmedi (kasa payı %43,75 ve
  %46,25 — kusur yok). Oyuncunun dokunabildiği her para kalemi için bu
  hesap bir satırdır ve kalıcı bekçi olur.
- **Paket DK.** Kendi dersimi kendi testimde iki kez tekrarladım:
  (a) `ageUp()` beş kapılı, bildirimleri kapatmak yetmiyor — yaş
  ilerlemedi ve 25 yılda 24 bilet alındı; (b) "cüzdan arttı mı"
  iddiası boşa çalışıyordu, çünkü cüzdanı maaş da artırır. Doğru
  kaynak oyunun **kendi kaydı**ydı. Bir iddia yazdıktan sonra sor:
  **bu sayı başka hangi sebeple böyle çıkabilir?**
- **Paket DL.** Oyun **ödülü** bildirim penceresiyle duyurup **cezayı**
  yalnızca günlüğe yazıyorsa o ceza oyuncu için yoktur. Sponsorluk
  teklifi pencere açıyordu; kabul edip paylaşmamanın bedeli (takipçinin
  %4'ü + 4 mutluluk) açmıyordu ve 120 hayatta kırılan 89 anlaşmanın
  88'i sessizce geçti. Yeni soru: bu mekaniğin **cezası** nerede
  yazılı, ödülüyle aynı yerde mi?
- **Paket DL.** Süresi olan her yükümlülük süresini **ekranda** söylemek
  zorundadır. Motor iki yıl sayıyordu, kart yalnızca "paylaşım yapınca
  ödenecek" diyordu: oyuncunun elindeki bilgiyle ceza arasında iki yıl
  vardı. Sayıyı tek bir işleve (`deadlineAgeFor`) bağlamak, "ekranda
  yazan yıl ile motorun düşürdüğü yıl aynı mı?" sorusunu da test
  edilebilir yaptı — bir yıl kaydırma mutasyonu iki bölümü düşürüyor.
- **Paket DL.** Katalog seyrekliğini oyuna yazmadan önce **aracı** sor.
  `yerel_lezzet` 12 teklifle en seyrek kategoriydi; sebep eşiği değil,
  botun hesabını `SocialPlatform.values` sırasına göre açıp ilk
  platformda kalmasıydı — o kategori video platformunu kapsamayan tek
  kategori. Katalog ve bot, ikisi de değiştirilmedi: biri gerçek bir
  kusur değil, öteki bütün ölçümlerin zarını kaydırırdı.
- **Paket DM.** Bir kapsam denetimi yaparken **neyi saydığını** yaz.
  Paket DH "dokuz ekranın dokuzunda da test yolu var" dedi; saydığı şey
  `*_screen.dart` dosyalarıydı ve oyunun içeriğinin çoğu
  `sections/*_page.dart` içindeydi. Sekiz sayfanın içine hiç kimse
  girmemişti; girilince üç gerçek kusur çıktı. Denetimin cümlesi
  "dokuz ekran" değil "dokuz `*_screen.dart` dosyası" olsaydı boşluk
  o gün görünürdü.
- **Paket DM.** Kuralı koymak, bekçi yazmak ve **bekçinin bütün çağrı
  yollarını tutması** üç ayrı iştir. Para biçimi kuralı Paket BE'de
  konmuş, bekçisi yazılmış, ama bekçi yalnızca `AppliedEffect.text`'i
  deniyordu; ekranda "5000 ₺" üç paket sonra göründü. Bekçiye kaynak
  taraması eklendi ve tarama, gözün bulduğu birinciden sonra **ikinci**
  bir yeri buldu. Bir kural için "bekçisi var" demek yetmez: **kaç
  yoldan ihlal edilebilir?**
- **Paket DM.** Bildirilmiş bir hatayı düzeltirken aynı bilginin
  ekranda **kaç yerde** yazıldığını say. "Kadın oyuncu askerlikte
  'Yapılmadı' görüyor" hatası düzeltilmişti: gövde metni, menü alt
  yazısı ve Durum alanı tek kaynağa bağlanmış, **sayfa başlığı**
  atlanmıştı. Sonuç tek ekranda iki çelişen cümle; ve o başlığı hiçbir
  test okumuyordu.
- **Paket DM.** Dökümün "açtım ve okudum" demesi, açtığının **o sayfa
  olduğu** anlamına gelmiyor. Kapalı bir satıra dokunmak hiçbir şey
  yapmaz, döküm de eski kareyi basıp "okundu" sayar. Her kare için
  **yalnızca o sayfada bulunan** bir işaret şart; ilk denemede işaret
  olarak üst sayfadaki bir cümleyi seçip aynı tuzağa ikinci kez
  düştüm.
- **Paket DN.** Bir bekçi eklerken "bu kuralın kaç yoldan ihlal
  edilebileceğini" sor. Paket DM'de para taramasını `₺` işaretinin
  yanındaki ham sayıya bağladım; ertesi paket aynı kuralın **para
  olmayan** iki ihlalini buldu ("100000 takipçi", "1/500000"). Kalıcı
  çözüm kaynak değil **çizilmiş metin** oldu: döküm zaten 18 sayfanın
  metnini basıyor, aynı metinde uzun sayı aramak bir satır.
- **Paket DN.** Sayıya Türkçe ek getiren metin, sayının **okunuşunu**
  bilmek zorundadır. "%46'i" sabit ekle yazılmıştı; doğrusu "%46'sı",
  "%30'u", "%20'si". Tek çağrı yeri için morfoloji motoru yazmak
  yerine cümleyi ek gerektirmeyecek biçimde kurmak doğru ölçü; bekçi
  deseni yasaklıyor, böylece ikinci çağrı yeri ortaya çıkarsa kararı
  yeniden verebiliriz.
- **Paket DN.** Sekmenin içeriği duruma göre **başka bir ekran**
  olabilir. Okul/Meslek öğrenciye okul, diğerlerine kariyer görünümü
  çiziyor; satırın kendi kapısı açıkken satır yine ekranda olmayabilir.
  "Kapı açık ama satır yok" bulgusunu ürün hatası diye raporlamadan
  önce **hangi görünümün çizildiğini** sor.
- **Paket DO.** Kapsam kaydının birimi **dosya değil kare** olmalı.
  `activity_pages.dart` altı ayrı sayfa barındırıyor; kayıt dosya
  başına tek satır tuttuğu için beş sayfa "okunuyor" sayılıp hiç
  basılmamıştı. Biri (Taşın) gerçek bir kusur taşıyordu.
- **Paket DO.** Motorun doğru cümleyi **bilmesi** yetmez; o cümlenin
  oyuncuya **ne zaman** gösterildiği de kuralın parçasıdır.
  `moveToRental` "cüzdanında yeterli para yok" diyordu ama yalnızca
  dokunduktan sonra; ekran dört şehri bedava davet gibi diziyordu.
  Kapıyı işleve çıkarıp satıra taşımak kuralı değiştirmedi, **yerini**
  değiştirdi.
- **Paket DO.** Aynı araç hatasını üç pakette üç kez yaptım: döküm
  işareti olarak **koşullu** bir cümle seçmek. İşaret sayfanın her
  hâlinde çizilen bir metin olmalı; en güvenlisi başlık ya da sabit
  açıklama satırı.
- **Paket DP.** Bir engeli **nerede** yazdığın, engelin kendisi kadar
  ürüne dahil. `applicationAvailability` her iş için ayrı çağrılıyor ve
  iki engeli işe hiç bakmıyor; o engel varken liste yirmi satırda aynı
  cümleyi yazıyor ve satırın kendi bilgisi (eğitim kademesi · yaş
  kapısı) kayboluyordu. İşten bağımsız engel sayfanın başında **bir
  kez**, işe özel engel satırda yazılır.
- **Paket DP.** Tekrar bekçisi kurarken "çok tekrar eden metin
  kötüdür" demek yanlış olurdu: ölçüm düğme etiketlerinin ("Başvur"
  21, "Şu an olmaz" 11) ve göz muayenesi tablosundaki tek harflerin
  ("O" 20) meşru biçimde tekrarladığını gösterdi. Ölçüyü **cümleye**
  (boşluk içeren, nokta/ünlem/soru ile biten metin) daraltınca 28
  karede yalnızca iki tekrar kaldı: kusur (20) ve meşru olan (4).
  Tavanı ölçülen meşru değere kurmak, tahmini bir sayıya kurmaktan
  hem daha sıkı hem daha az kırılgan.
- **Paket DP.** Aynı kalıbın doğru hâli yanı başındaydı: Dövüş
  sanatları karesinde altı dal da "para yetmiyor" diyor ama her biri
  **kendi** ücretiyle (700, 750, 600, 650, 620, 640 ₺). Bir kusuru
  düzeltmeden önce oyunun aynı sorunu nerede doğru çözdüğüne bakmak,
  hem düzeltmenin biçimini hem de bekçinin eşiğini verdi.
- **Paket DP.** "Bu sayfa başka testle okunuyor" kaydı **yanlış
  değildi**, yetersizdi: ölçtüm, beş testin beşi de ağacı kuruyor ve
  satıra dokunuyor (`pumpWidget` 1-3, `tester.tap` 4-14). Ama hepsi
  anahtar ve tek tek cümle denetliyor; kareyi baştan sona okumuyor.
  Kusur tam o boşlukta duruyordu. Bir iddiayı çürütmek için yanlış
  olduğunu göstermek gerekmiyor — **neyi ölçmediğini** göstermek
  yetiyor.
- **Paket DP.** Bastırmanın kapsamını kaynak kilidiyle savunmak
  yetmiyor, **ölçmek** gerekiyor: aynı karede 21. kart kendi gerekçesini
  ("Bu yıl Kuaför işine başvurdun…") yazmaya devam ediyor ve test bunu
  ekranda arıyor. "Birebir eşitliğe dayanıyor, o yüzden güvenli"
  argümanı doğruydu ama kanıt değildi.
- **Paket DQ.** Bir bekçi, ölçtüğü şeyin **ne kadarını** ölçtüğünü de
  söylemeli. "Bu sayfa başka testle okunuyor" kaydı, adı yazılan testin
  sayfanın bir başlığını anmasına bakıyordu; bir kayıt bu sınavı
  yalnızca `group('Aktiviteler')` **etiketi** sayesinde geçiyordu ve o
  test hiç widget kurmuyor. Dizi benzerliği kapsam kanıtı değildir.
- **Paket DQ.** Metin eşleştirmesi bir vekildir ve sınırına gelince
  bırakılmalı: kareyi gerçekten basan testin gövdesinde
  `school_career_screen.dart`'ın **30 başlığından sıfırı** geçmiyor.
  Çözüm daha akıllı bir desen değil, **ortak kaynak**: sekme listesi
  artık tek yerde duruyor, döküm onu dolaşıyor, kapsam bekçisi kapsamı
  ondan sayıyor. İddia yapıya dayanınca vekile gerek kalmıyor.
- **Paket DQ.** Bir dosyanın bir kaydı olması, **içindeki her karenin**
  kaydı olduğu anlamına gelmiyor. `social_pages.dart` iki sayfa
  barındırıyor; ikincisinin başlığı dinamik (`platform.label`) olduğu
  için başlık taramasına hiç görünmüyordu ve kusur tam orada duruyordu.
- **Paket DQ.** Gerekçe metni iki yerde kullanılıyorsa (sonuç mesajı ve
  satır), eylemin adını **kendi içine** koymak satırda kekemeliğe yol
  açıyor: "İş birliği teklif et: İş birliği teklif etmek için…".
  Gerekçe yalnızca kapıyı yazar; adı çağıran yer ekler.
- **Paket DR.** Kapsam sorusunu bir katman aşağıda sormak gerekiyordu:
  bölüm sayfalarının hepsi okunduktan sonra `lib/ui/widgets/` kaldı ve
  oyuncuya dönük metnin önemli kısmı oradaydı —
  `person_detail_sheet.dart` tek başına **65 cümle**, okuduğum hiçbir
  bölüm sayfasından yoğun. Modal bir sayfa sekmede görünmüyor, bu yüzden
  dökümün erişemediği bir bölge kalmış.
- **Paket DR.** "Hiçbir test adını anmıyor" ile "çizilmiyor" aynı şey
  değil: bir modal, düğmesine dokunan bir testte adı geçmeden de
  çizilebilir. Sınıf adı taraması yine bir vekildi (DQ'nun dersi);
  iddia kareyi **gerçekten basarak** kapatıldı.
- **Paket DR.** Aynı dosyanın bir karesi dosyayı okumuş saymıyor.
  Kişi kartının 0 yaşındaki karesi 56 metin bastı ve "temiz" göründü;
  etkileşimler 4 yaşından, bakım yaşlılıkta, çocuğa özel satırlar
  yalnızca çocukta açılıyor. İki kusur ancak **43 yaşındaki** karede
  (103 metin) göründü. Yoğun bir modal için birden çok kapı gerekiyor.
- **Paket DR.** Çizilmeyen şeyi kusur sanmamak için aracın ne okuduğunu
  bilmek gerekiyor: "Keyfi" ve "Yakınlık" etiketleri değersiz göründü,
  çünkü değer bir `LinearProgressIndicator` ve döküm yalnızca metni
  okuyor. Kaynağa bakmadan rapor etsem dördüncü yanlış bulgu olurdu.
  Ama aynı bakış gerçek bir tutarsızlık ölçtü: aynı değer üç ayrı yerde
  sayıyla yazılıyor, kişi kartında yazılmıyor (Q-244).
- **Paket DR (kendi hatam, ikinci kez).** Bir cümleyi değiştirirken
  **kaldırdığım** dizgiyi test ağacında aradım, **yerine koyduğumun
  komşusunu** aramadım: `shared_history_test` giden hediye satırında
  "verdin" bekliyordu ve CI'da düştü. Doğru tarama "eski metni kim
  anıyor?" değil, **"bu satırın hangi sözcüğüne bir test dayanıyor?"**
  sorusudur; değişen cümlenin bütün belirgin sözcüklerini (fiil dahil)
  tara. Beklenti güncellenirken gevşetilmedi, sıkıştırıldı.
- **Paket DQ.** Doğru bir sayı yanlış bir izlenim verebilir. Platform
  karesinde üç ünlünün üçü de "~%19" gösteriyordu ve sayı **doğruydu**;
  görünürlük terimi takipçi/eşik ile çarpıldığı için yeni hesapta sıfır
  oluyor ve geriye ünlüden bağımsız terimler kalıyor. Ölçüm olmadan bunu
  "ekran yanlış hesaplıyor" diye raporlayacaktım; ölçümle birlikte doğru
  yere, kuyruğa (Q-243) gitti.

## Pano

Güncel ilerleme: `docs/planner/index.html` (betikle üretilir,
`docs/planner/tasks.tsv` beslemesiyle).
