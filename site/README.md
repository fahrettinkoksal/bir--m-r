# biromur.com — statik site

Derleme adımı yok, bağımlılık yok. Dosyalar olduğu gibi sunucuya kopyalanır.

## cPanel'e yükleme

1. cPanel → **Dosya Yöneticisi** → `public_html` klasörünü aç.
2. İçindeki hazır `index.html` / `default.html` gibi tanıtım dosyalarını sil.
3. Bu klasörün **içindekileri** (bu `README.md` hariç) `public_html`e yükle.
   Doğru yerleşim:

   ```
   public_html/index.html
   public_html/robots.txt
   public_html/sitemap.xml
   public_html/assets/style.css
   public_html/assets/favicon.svg
   public_html/en/index.html
   ```

   Zip yükleyip "Extract" demek en hızlısı; zip'in içinde `site/` klasörü
   **olmamalı**, dosyalar kökte olmalı.
4. `https://biromur.com` ve `https://biromur.com/en/` adreslerini aç, iki
   sayfa da açılıyor ve diller arası geçiş çalışıyor mu bak.

Yollar kök dizine göre yazıldı (`/assets/style.css`). Siteyi alt klasöre
koyarsan (`public_html/deneme/`) CSS yüklenmez; kökte tut.

## SSL ve www

- cPanel → **SSL/TLS Status** → `biromur.com` ve `www.biromur.com` için
  AutoSSL sertifikasını kur. Başvuruda verdiğin adres https açılmalı.
- `www` ile `www`siz adresten biri diğerine yönlensin; ikisi birden
  aynı içeriği sunarsa arama motoru iki ayrı site sayar.

## E-posta

cPanel → **Email Accounts** → `info@biromur.com` oluştur. Claude for
Startups başvurusu, sitenin alan adıyla **eşleşen** bir şirket e-postası
istiyor; bu yüzden başvuruyu gmail/outlook ile değil bu adresle yap.

## İçeriği güncellerken

- Türkçe sayfa `index.html`, İngilizce sayfa `en/index.html`. İkisi ayrı
  dosya; birinde metin değişince diğerini de güncelle.
- Sitedeki sayılar (180 karar, test sayısı, 122 bin satır kod, 95 bin satır
  test, 55 meslek, 461 olay, 12 hobi/60 basamak, 22 kitap, 39 aktivite,
  21 hedef, 10 hayvan türü, 22 şehir, 58 dövüş kademesi) depodan ölçüldü.
  Ölçüm betiği: katalog dosyalarındaki girdileri saymak; olay sayısı
  `data/event_pool*.dart` içindeki `GameEvent(` sayısı. Depo büyüyünce bu
  sayılar bayatlar — güncellemeden önce yeniden ölç, tahminle yazma.
- "Hayat günlüğü" bölümündeki satırlar oyunun gerçek çıktısından alındı.
  Değiştireceksen yine oyundan al; elle örnek cümle uydurma.
- Ekran görüntüleri (`assets/ekran-*.webp`) ve paylaşım görseli
  (`assets/og-biromur.png`) oyunun **kendi arayüzünden** üretildi, montaj
  değil. Yenilemek için:

  ```bash
  cd app
  BIR_OMUR_SCREENSHOTS=1 flutter test --update-goldens test/golden_screens_test.dart
  ```

  Bu, `app/test/goldens/*.png` dosyalarını 1080x2280 olarak tazeler. Sonra
  seçilenleri ölçekleyip WebP'ye çevir (Pillow ile; 480 piksel genişlik,
  kalite 82) ve paylaşım görselini yeniden kur. Uydurma mockup koyma;
  görüntü oyunun kendisinden gelsin. Arayüz değişince görüntüler bayatlar.
