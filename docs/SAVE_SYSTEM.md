# Kayıt / Yükleme Sistemi (teknik not)

Bu belge kayıt altyapısının **nasıl çalıştığını** anlatır. Oyun tasarımı
kararı içermez; açık kalan tasarım soruları `docs/DESIGN_REVIEW_QUEUE.md`
içindeki **Q-033** ve **Q-035** maddelerindedir.

## Amaç
Oyuncu uygulamayı kapatıp açtığında aynı hayatına kaldığı yerden devam
edebilsin. Altyapı platformdan bağımsızdır: Windows'ta çalışan kod Android'de
de değişiklik gerektirmeden çalışır.

## Dosyanın yeri
`path_provider` paketinin `getApplicationSupportDirectory()` çağrısıyla
bulunan, **uygulamaya ait** yerel veri klasörü kullanılır:

- Windows: `%APPDATA%\<uygulama klasörü>\bir_omur_kayit.json`
- Android: uygulamanın kendi özel veri klasörü

Kullanıcının belgelerine veya ortak klasörlere yazılmaz.

## Dosya biçimi
```json
{ "formatVersion": 30, "savedAt": "...", "state": { ... } }
```

- `formatVersion` **en dış katmandadır**; içerik şeması değişse bile dosyanın
  hangi sürüme ait olduğu her zaman okunabilir.
- Enum değerleri **adlarıyla** yazılır (sıra numarasıyla değil), böylece
  ileride enum sırası değişse eski kayıtlar bozulmaz.
- Eski sürümleri güncel şemaya taşımak için `SaveMigrations.migrate` zinciri
  kullanılır. **Güncel biçim sürümü 30; okunabilen en eski sürüm 25**
  (`kSaveFormatVersion`, `kMinReadableSaveVersion`). Faho'nun kararı gereği
  geriye dönük yalnızca **son beş sürüm** taşınır; bunu kalıcı bir test
  zorunlu kılar. Daha eski bir kayıt açılamaz ama **silinmez**, oyuncuya
  anlaşılır bir mesaj gösterilir.
- Sonradan eklenen alanların hepsi **eklemelidir ve null-güvenli okunur**;
  bu yüzden çoğu paket sürüm numarasını artırmadan alan ekleyebildi.
- Alan eksik ya da yanlış türdeyse ham bir Dart hatası değil, hangi alanın
  bozuk olduğunu söyleyen Türkçe bir `SaveFormatException` atılır
  (Paket 44).
- Kayıt **daha yeni** bir sürümden geliyorsa açılmaz; kullanıcıya oyunu
  güncellemesi gerektiği söylenir ve dosyaya dokunulmaz.

## Neler kaydediliyor
`GameState` bütünüyle yazılır: tohum, oyuncu (ad, yaş, beş değer, Ün, cüzdan,
doğum şehri), kişiler (kalıcı kimlik, ad, cinsiyet, ilişki türü, yaş, yaşıyor
mu, hane, çalışma durumu, meslek, kendi ekonomik durumu, yakınlık, okul
kademesi, okul bağı), evcil hayvanlar, ebeveyn durumu, hayat günlüğü,
etkileşim sayaçları, son temas yaşları, hikâye izleri, eşyalar, görülmüş
olaylar, olay tekrar geçmişi, hikâye rollerine kilitlenmiş kişiler, bekleyen
olay, ilerleme sayaçları ve eğitim durumu.

**Bekleyen olay seçenekleriyle birlikte** yazılır. Uygulama yeniden
açıldığında olay havuzdan yeniden üretilmez: aynı metin, aynı kişi ve aynı
seçenekler geri gelir. Olay havuzu güncellense bile oyuncunun ekranındaki
soru değişmez.

## Otomatik kayıt
Oyun durumunu değiştiren her anlamlı işlemden sonra yazılır: yeni hayat,
yaş alma, olay seçimi, kişi etkileşimi (para/eşya/yakınlık değişimleri dahil)
ve ayrılık. Yazmalar sıraya alınır; iki kayıt birbirinin üzerine binmez.

## Yazma güvenliği
Yazma üç adımlıdır:
1. Yeni içerik `.tmp` dosyasına yazılır ve diske boşaltılır.
2. Var olan sağlam kayıt `.bak` dosyasına kopyalanır.
3. `.tmp` dosyası asıl kaydın üzerine **tek adımda** taşınır.

Hangi adımda kesinti olursa olsun ya eski ya yeni kayıt bütün hâlde kalır;
yarım yazılmış dosya asıl kaydın yerine geçmez. Okuma sırasında asıl dosya
bozuksa **yedek** denenir.

## Bozuk kayıt
İkisi de okunamıyorsa uygulama **çökmez**: başlangıç ekranında anlaşılır bir
açıklama gösterilir, dosya **silinmez ve üzerine yazılmaz**, otomatik kayıt
durdurulur. Oyuncu yeni bir hayat başlatmayı açıkça onaylarsa kayıt silinir
ve yazma yeniden açılır.

## Yeni hayat ve kayıt silme
- Ana ekrandan çıkmak (`clearLife`) kaydı **silmez**; "Devam Et" ile aynı
  hayata dönülür.
- Yeni hayat başlatmak kaydın üzerine yazacağı için önce onay sorulur.
- Kayıt yalnızca kullanıcı onayıyla silinir.

## Bilinen sınır: rastgelelik
Rastgele sayı üreticisinin **iç durumu kaydedilmez**. Kaydedilen her şey
(bekleyen olay dahil) birebir geri gelir; ancak kayıttan sonra üretilecek
**yeni** rastgele sonuçlar, uygulama hiç kapanmasaydı çıkacak olanlarla aynı
olmak zorunda değildir. Oyun tutarlılığı bundan etkilenmez: olayların
uygunluğu ve sonuçları rastgeleliğe değil, kaydedilen duruma bakar.
