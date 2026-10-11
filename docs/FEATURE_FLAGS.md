# Çıkarılabilir özellikler — modül anahtarları

**Durum:** Paket BL'de kuruldu (9 Ekim 2026). Bu dosya bir **mimari
sözleşmedir**, oyun kuralı değildir: `DECISIONS.md` yalnızca Faho'nun
sohbette onayladığı kararları tutar.

## Neden var

Faho'nun isteği: "yaptığın geliştirmelerden birini beğenmezsem, genel
yapı bozulmadan o özelliği çıkartabilelim."

Oyunda bunun bir örneği zaten vardı: kumarhane isteğe bağlı bir modüldür
ve kapatılınca menüde hiç görünmez (D-032). Paket BL o tek örneği
**kurala** çeviriyor: bundan sonra eklenen her özellik kendi anahtarıyla
gelir.

## Sözleşme

1. **Her yeni özellik kataloğa bir satır olarak girer.** Katalog:
   `app/lib/domain/features/feature_catalog.dart`.
2. **Tek kapı.** Özellik koda tek bir yerden bağlanır ve o yer anahtara
   bakar. Dağınık `if` yoksa çıkarmak da kolaydır.
3. **Kapalıyken iz kalmaz (fail-closed).** Anahtar kapalıysa eylem
   listelenmez *ve* motor çağrıldığında reddeder. Kapalı modül ekranda
   yer tutmaz: sahte düğme, boş kart, artakalan boşluk bırakılmaz.
4. **Kapalı modül zara dokunmaz.** Anahtar kapalıyken oyun, o modül hiç
   yazılmamış gibi davranır: aynı tohum aynı hayatı verir. İlk hâlde
   olay kapısı kişi çözümünden **sonraydı** ve kapalı modülün olayları
   bile `rng` tüketiyordu; hepsi kapalı 100 hayatta ortalama ömür
   70,4'ten 72,1'e kaymıştı. Kapı zardan önceye alındı, ortalama 70,4'e
   döndü ve 240 durumda iki motor (tam havuz + kapalı modül / modülsüz
   havuz) aynı olayı verdi.

   **Paket BO bu kuralı yapısal hâle getirdi.** Artık yalnızca kapalı
   modül değil, **uygun olmayan hiçbir olay** zara dokunmuyor: kişi
   çözümü koşul denetiminden sonraya alındı ve kişi yalnızca çekilişi
   kazanan olay için seçiliyor. Yani havuza olay eklemek, o olayın
   çıkamadığı hayatlarda akışı hiç değiştirmiyor
   (`app/test/paket_bo_zar_bagimsizligi_test.dart`: 60 uygun olmayan
   olay eklenmiş havuz, 320 durumda birebir aynı sonucu veriyor).
5. **Kapalıyken oyun çalışır.** Modül kapalı 100 hayat sonuna kadar
   gider; evlilik, çocuk ve kariyer yaşanmaya devam eder. Bunu
   `app/test/paket_bl_modul_izolasyon_test.dart` ölçer.
6. **Anahtar kayıtta durur.** `GameSettings.features` içinde, yalnızca
   **varsayılandan sapmalar** yazılır. Katalog büyüdükçe kayıt büyümez;
   eski kayıtlar yeni modülü varsayılan hâliyle açar; silinmiş bir
   modülün anahtarı kayıtta kalmışsa sessizce atılır.
7. **Oyuncu da kapatabilir.** Ayarlar → *Modüller*. Her satırın altında
   kapatınca neyin kaybolduğu yazar.

## Katalog

| Kayıt anahtarı | Modül | Paket | Kapatınca ne olur |
| --- | --- | --- | --- |
| `gebelik_gorunurlugu` | Gebelik bildirimi | BK/1 | Bekleyen doğum hayat ve ilişkiler ekranında yazmaz; bebek yine doğar. |
| `cocuk_plani` | Çocuk planı | BK/2 | Eşle çocuk konusunu konuşma satırı kalkar; çocuk yalnızca korunmasız birlikte olmakla gelir. |
| `ebeveynlik_eylemleri` | Çocuğa özel eylemler | BK/3 | Ödev, harçlık ve hobiye yazdırma satırları çıkmaz; sohbet/vakit/hediye kalır. |
| `cocuk_kurallari` | Çocuğa kural koyma | BK/3 | Kural satırı kalkar; okul sorunu ihtimali yalnızca çocuğun kendi kaydına bakar. Daha önce konmuş kural da etkisini yitirir. |
| `cocuk_yil_ozeti` | Çocuğun yıl özeti | BK/5 | Yıl özetinde çocuk bloğu görünmez; çocuğun kartı aynı kalır. |
| `ilk_yillar_olaylari` | İlk yıllar olayları | BM | 0-7 yaş havuzuna eklenen 31 olay ve ilk yılların karşılıkları çıkmaz; ilk yıllar paket öncesi gibi geçer. |
| `esikteki_yillar` | Eşikteki yıllar | BN | 16-20 yaş havuzuna eklenen 29 olay ve eşikteki kararların karşılıkları çıkmaz; lise sonu ve ilk iş yılları paket öncesi gibi geçer. |
| `oturulan_ev` | Oturduğun ev | BP | Kendi evinde oturana çıkan 28 olay (kombi, çatı, küf, apartman toplantısı, komşu, dönüşüm) ve yedi karşılığı çıkmaz; kendi evine çıkmak paket öncesi gibi sessiz geçer. |
| `ev_dosemesi` | Evini döşemek | BT | Evinin hâli ekranı, döşeme seviyesi, ev eşyasının yıllık yıpranması ve iyi döşenmiş evin yıllık mutluluk katkısı kalkar; 18 ev eşyası mağazada kalır ama evin dolu olup olmadığı hiçbir şeyi değiştirmez. |
| `komsular` | Komşular | BU | Apartmanda adı olan komşu olmaz: ilişkiler ekranındaki Komşular bölümü, komşuyla sohbet/vakit/hediye ve 12 komşu olayı çıkmaz. Kendi evinde oturmak Paket BP'nin olaylarıyla devam eder. |
| `ugras_onceligi` | Sürdürülen uğraşa öncelik | BX | Oyuncunun o an içinde olduğu okul kulübü ya da hobinin olayları yıllık çekilişte genel havuzla aynı ağırlıkta yarışır. İçerik kaybolmaz ama ölçümde görüldüğü gibi okul yıllarında neredeyse hiç çıkmaz: 150 spor hayatında futbol zincirinin sekiz olayı 5 kez görünüyordu, öncelikle 21 kez. |
| `son_yillar` | Son yıllar | CC | 65+ için yazılan 31 olay (emekliliğin ilk pazartesisi, günün düzeni, merdiven, ilaç kutusu, torunla eski zaman, çırağa öğretmek, fidan, komşuyla sabah düzeni, emekli bütçesi, dolandırıcı telefonu) ve altı karşılığı çıkmaz; son yıllar orta yaşın havuzuyla geçer. Ölçüldü: 65+ taramasında uygun olan 228 olaydan yalnızca 11'i o yaşlara aitti. |
| `sigorta` | Sigorta | CA | Sigorta ekranı ve poliçeler kalkar: yıllık prim çıkmaz, hasarda karşılık olmaz, sağlık krizinin ve ev hasarının faturası Paket CA öncesi gibi tamamen oyuncunun cebinden çıkar. Kayıttaki poliçeler silinmez, donar. |
| `arkadas_grubu` | Arkadaş grubu | CI | Grup kurma düğmesi ve "Arkadaş grubum" kartı kalkar; sekiz grup olayı çıkmaz, üyenin ayrılması ve grubun dağılması işlemez. Arkadaşlık tek tek yürür (Paket CI öncesi gibi); birden çok kişiyle aktiviteye gitmek yine mümkündür, o Paket X/2'nin yolu. Kayıttaki gruplar silinmez, donar. |
| `yaslilik_bakimi` | Yaşlılıkta bakım | CJ + CM | Yaşlılıkta "kim yanında?" kartı ve üç kapı kalkar; aile oyuncunun yaşlılığına karışmaz, maddi destek gelmez. Kaydı okuyan altı olay da aday havuzuna girmez (Paket CM: "üç yıldır yanımda" ya da "kimseyi aramamışım" hikâyeleri). Yaşlı ebeveyne bakmak (Paket AO §35) yerinde kalır — kalkan şey onun oyuncuya dönük tersi. Kayıttaki sayaçlar silinmez, donar. |
| `cocuk_hastaligi` | Çocuğun hastalanması | CN | Çocuk hiç hastalanmaz: kendi sağlık/keyif kaydı düşmez, günlüğe satır düşmez, hanedeki çocuğun hastalığı oyuncunun mutluluğunu etkilemez. Eşin hastalanması (D-154) yerinde kalır — kural `NpcIllness`'ta paylaşıldı. Geçmişte yazılmış hastalık dönüm noktaları silinmez. |

Tablo elle tutulur ama **bekçisi var**: izolasyon testi her katalog
satırının bu dosyada yazılı olmasını şart koşar.

### Hangi paket anahtar almaz

Sözleşme **yeni özellik** için anahtar şart koşar; her değişiklik yeni
özellik değildir. Anahtar almayan üç tür iş:

1. **Hata düzeltmesi.** Çakışan iki kitap kimliğini ayırmak (Paket CB)
   geri alınabilir bir seçenek değil, bozuk olanı onarmaktır.
2. **Var olan kataloğun büyümesi.** Kütüphaneye 17 kitap eklemek (CB),
   araç modeli ya da mülakat sorusu eklemek yeni bir sistem kurmaz:
   düğme, ekran ve kural aynı kalır. Beğenilmezse satırlar silinir.
3. **Ekranın okunur hale gelmesi.** Uzun listeyi gruplamak (V/5 mağaza,
   CB kütüphane) özellik değil düzen; kapatılacak bir şey yok.

Kuralın sınırı net: **yeni bir eylem, yeni bir ekran ya da yıllık akışa
yeni bir hesap** giriyorsa anahtar alır.

## Bir özelliği tamamen silme tarifi

Anahtarı kapatmak özelliği görünmez yapar. Kodu da gitsin istiyorsan:

1. **Anahtarı kapat ve oyna.** Ayarlar → Modüller. Oyun beklediğin gibi
   çalışıyorsa silmeye değer.
2. **Bağları gör:** depo kökünde `grep -rn "FeatureId.<ad>" app/` .
   Çıkan her satır o özelliğin koda değdiği yerdir — başka yerde
   olmadığını sözleşmenin 2. maddesi garanti eder.
3. **Kendi dosyalarını sil:** katalog satırındaki `removableFiles`
   listesi, yalnızca o özellik için var olan dosyaları sayar.
4. **Katalog satırını sil**, sonra `dart analyze lib/ test/` koştur.
   `FeatureId.<ad>` artık yok olduğu için **derleyici** kalan bütün
   bağları tek tek gösterir. Kalan yer kalmadığında silme tamamdır.

Kayıt uyumu için ek iş yok: silinen modülün anahtarı eski kayıtlarda
kalsa bile okunurken atılır.

## Testler ne garanti ediyor

`app/test/paket_bl_modul_izolasyon_test.dart`:

- katalog bekçisi: anahtarlar benzersiz, `removableFiles` yolları
  gerçekten duruyor, her modül bu belgede yazılı;
- kayıt: kapatma/açma gidiş-dönüşü, tanınmayan anahtarın atılması,
  alanı olmayan eski kaydın varsayılana düşmesi;
- her modül için **kapalı** ve **açık** taraf ayrı ayrı oynanır:
  kapalıda iz sayısı sıfır, açıkta sıfırdan büyük. Açık taraf
  ölçülmezse test boş geçerdi;
- hepsi kapalı 100 hayat: hayatlar sonuna kadar gidiyor, evlilik/çocuk/
  kariyer duruyor.
