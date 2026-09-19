# Bir Ömür — gezinme, eğitim ve ekonomi kapsamı kararları

**Karar sahibi:** Faho. **Durum:** Aşağıdaki açıkça onaylanmış yönler geçerlidir; belirtilen açık konular kesinleşmiş sayılmaz. **Bu belge tasarım kaydıdır, kod yazma veya PR birleştirme talimatı değildir.** Claude uygulamadan önce `main`deki bu yeni belgeyi çalışma dalına almalı, eski belgelerle uyumsuzlukları not etmeli; Faho'nun açık kodlama talimatını beklemelidir.

## NAV-001 — Dört ana menü ve iç içe alt menüler (onaylandı)

- Oyunun alt gezinmesinde **toplam dört ana menü** olacak. Yeni özelliklerin her biri için yeni alt sekme açılmayacak; sistemler uygun ana menünün içindeki alt menülere yerleştirilecek. İki diğer ana menünün kesin adı, sırası ve ayrıntılı yerleşimi henüz bu konuşmada belirlenmedi; mevcut `Hayat` ve `Ben` bunlar için örnek olabilir, ancak otomatik onay sayılmaz.
- Ana menülerden biri **İlişkiler** olacak; anne, baba, akrabalar, okul/iş arkadaşları, diğer arkadaşlar ve romantik bağlar ayrı kişi kimlikleriyle bu menüde erişilebilir olacak.
- **İlişkiler ana ekranında anne ve baba en üstte** görünecek. Aynı menüde `Akrabalar` adlı bir alt menüye girilerek akrabalar, `Arkadaşlar` adlı bir alt menüye girilerek kadın arkadaşlar dahil okul ve iş arkadaşları görüntülenebilecek. İlişkiler kategorilerini alt menülerle derinleştirme tercih edildi; uzun tek listeye yığma. Sevgili/eski sevgili için alt menü adı ve tam konumu ayrıca netleşecek; kişiler akraba/aynı hane sayılmayacak.
- **En sağdaki dördüncü ana menü duruma göre `Okul` veya `Meslek` olacak.** Oyuncu okuldayken okul işlevleri, okulda değilken uygun meslek/çalışma işlevleri gösterilecek. İşsiz/okula başlamamış/okulu bitirmiş karakterde boş ya da yanıltıcı içerik gösterilmemesinin tam UX kararı açık.
- Önceden kararlaştırılmış `Hayat / Aile / Ben` düzeni *ilk prototip* yerleşimiydi (D-015, D-028, D-029). Bu yeni navigasyon kararı, nihai ürün için **Aile'nin tek başına ana sekme olarak kalması varsayımını günceller**; önceki aile/romantik kişi geçmişi ve veri bütünlüğü kuralları geçerlidir. BitLife'tan gezinme mantığı düzeyinde esinlenilebilir, fakat özgün görsel, kod, metin ve varlıkları kopyalanmayacak.

**Görsel referans notu:** Faho, BitLife'tan ana ekran/hayat günlüğü, dört çevresel alt menü + ortadaki büyük `Age` eylemi, ana menü, okul pop-up'ı, ilişkiler listesi ve `Salon & Spa` gibi iç menü ekranlarının görüntülerini sohbet içinde paylaştı. Bunlar **menü hiyerarşisi ve kullanım akışı referansı**, birebir kopyalanacak tasarım şablonu değil. `Age` düğmesinin dört ana menüye ek bir *eylem* olması, dört ana menü sayısına dahil edilmemesi mantığı referans olarak değerlendirilebilir; Bir Ömür'de merkezi yerleşimin tam şekli ayrıca onaylanacak. Üst kısımdaki karakter özeti ve bakiye görünümü de referans; tam konum/stil henüz kararlaştırılmadı.

## EDU-001 — Temel eğitim akışı ve sınav fikirleri (kısmen onaylandı)

- Şimdiki küçük okul altyapısı **12. sınıfa kadar okul sürecini** taşıyacak. Sınıf tekrarı, ayrılma, not sistemi, üniversite ve geniş okul diyalogları bu aşamada şart değil. Koddaki `6 yaşında otomatik başlangıç / her yıl bir sınıf / 4+4+4` parametreleri Q-014'te henüz ayrıntılı onay bekliyor; 12. sınıfa kadar eğitim hedefini bu parametrelerin tümünü kesin onaylama olarak yorumlama.
- Oyuncunun **8. sınıfta bir sınav deneyimi** yaşaması fikri var. Kullanıcı bunu "üniversite sınavı" diye andı; hangi sınavın kastedildiği (8. sınıf lise geçiş sınavı mı, ayrıca 12. sınıf sonu üniversite sınavı da mı?) netleştirilecek. Zekâya göre puan hesaplama veya küçük mini oyunlara bağlı puan alma alternatifleri ileride değerlendirilecek; **şimdi sınav/mini oyun/puan algoritması kodlama**.
- GEN-001'deki sıra korunsun: genel iskeleti önce kurup test et, geniş olay/diyalog ve sınav ayrıntılarını sonraya bırak.

## ECO-001 — Para, kişisel cüzdan ve ekonomik etkileşimler (çekirdek kapsam onaylandı)

- Oyuncunun **kendisine ait parası/bakiyesi (cüzdanı)** olacak. Ailenin ekonomik durumu, ebeveynlerin mal varlığı/geliri ve oyuncunun kişisel bakiyesi birbirinden ayrı tutulacak; aile varlığı doğrudan oyuncunun harcanabilir parası kabul edilmeyecek.
- Oyuncu uygun koşullarda ailesinden para isteyebilecek; isteğin kabul edilmesi, reddedilmesi veya miktarı ilişkiler ve aile koşullarıyla bağlantılı olabilir. Bu ayrıntılı olasılık/formüller henüz onaylanmadı.
- Oyuncu ileride mesleği, eğitim yoluyla açılan işler ve başka uygun etkinlik/olaylarla para kazanabilecek; alışveriş, hizmetler ve seçimlerle para harcayabilecek. Kazanma yöntemleri ve fiyat/maaş listeleri şimdi kesinleşmedi.
- **İlk tur yaklaşımı:** Tek bir ortak para/bakiye kaydı ve koşula bağlı birkaç küçük kazanma/harcama/para isteme akışıyla teknik temeli doğrula; kapsamlı meslek, banka, borç, mülk, vergi ve onlarca ekonomik diyalog daha sonraki içerik paketlerine ait. Bu yaklaşım GEN-001'in küçük paket stratejisine uygundur; kesin para birimi, başlangıç bakiye dağılımı, eksi bakiye/borç izinleri ve enflasyon/yaşa bağlı fiyatlama kararlaştırılmadı.
- BitLife görsellerindeki üst köşe `Bank Balance` göstergesi **bakiye görünürlüğüne örnektir**; Bir Ömür'de tam konumu/görsel tasarımı ayrıca belirlenecek.

## Karar bekleyen uygulanabilir sorular

- Diğer iki ana menünün kesin isimleri, sırası ve hangi sistemleri barındıracağı; İlişkiler'in alt menüleri içinde romantik kişiler ve eski sevgililerin tam yeri; `Okul / Meslek` sekmesinin hiçbirine uymayan yaş veya işsizlik durumu; merkezi `Yaş Al` düğmesinin nihai konumu.
- 8. sınıf sınavının türü, 12. sınıf sonu sınavı kapsamı, zekâ/mini oyun puanlaması, lise seçimi ve başarı sonuçları. Bunlar `docs/DESIGN_REVIEW_QUEUE.md` içindeki Q-014/Q-015 ile bağlantılı kararlardır; ilgili sorular kararlaştırılmış kısımları ve kalan açıklıkları yansıtacak şekilde, çakışma yaratmadan güncellenmelidir.
- Para birimi, ilk cüzdan bakiyesi, aileden para isteme uygunluğu/sıklığı/miktarı, diğer kazanç ve harcama yolları, borç ve fiyat dengesi ileride ayrı tasarım soruları olarak sıraya alınmalı; onaysız sayısal değerler kalıcı kural yapılmamalı.
