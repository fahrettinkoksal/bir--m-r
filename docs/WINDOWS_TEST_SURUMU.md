# Bir Ömür — Windows test sürümü

Bilgisayarında **Flutter, Android Studio veya başka bir şey kurmana gerek yok.**
Zip'i indir, çıkar, `.exe` dosyasına çift tıkla.

---

## 1. Paketi indir

1. GitHub'da depoyu aç: `fahrettinkoksal/bir--m-r`
2. Üstteki **Actions** sekmesine tıkla.
3. Soldaki listeden **Windows test sürümü** iş akışını seç.
4. Listeden yeşil ✅ işaretli en son koşuya tıkla.
   *(Elle çalıştırmak istersen: sağdaki **Run workflow** → dal olarak
   `claude/windows-test-v1` → **Run workflow**.)*
5. Açılan sayfanın **en altındaki `Artifacts`** bölümüne in.
6. **`bir-omur-windows`** dosyasına tıkla — bilgisayarına bir **.zip** iner.

## 2. Zip'i çıkar

> **Zip'in içinden doğrudan çalıştırma.** Windows, zip içindeki dosyaları
> geçici bir klasöre açar ve uygulama yanındaki `data` klasörünü bulamaz.

1. İnen `bir-omur-windows.zip` dosyasına **sağ tık → Tümünü ayıkla…**
2. Hedef olarak kolay bir yer seç, örneğin `C:\BirOmur`
3. **Ayıkla**'ya bas.

Çıkan klasörün içinde `BirOmur` adında bir klasör olacak.

## 3. Çalıştır

`BirOmur` klasörünü aç ve **`bir_omur.exe`** dosyasına **çift tıkla**.

Klasörün içinde şunlar bulunur:

```
BirOmur\
  bir_omur.exe          ← çift tıklanacak dosya
  flutter_windows.dll
  msvcp140.dll          ← Visual C++ çalışma zamanı
  vcruntime140.dll
  vcruntime140_1.dll
  data\                 ← oyunun varlıkları (silme, taşıma)
  OKU-BENI.txt
```

### "Windows bilgisayarınızı korudu" uyarısı çıkarsa

Test sürümü dijital olarak imzalı olmadığı için **SmartScreen** uyarı verebilir:

1. **Daha fazla bilgi**'ye tıkla.
2. **Yine de çalıştır** düğmesine bas.

Bu, imzasız test uygulamalarında normaldir.

---

## Sık karşılaşılan sorunlar

| Belirti | Sebep / çözüm |
| --- | --- |
| Çift tıklayınca hiçbir şey olmuyor | Zip'in içinden çalıştırıyorsundur. Önce klasörü diske çıkar. |
| "VCRUNTIME140_1.dll bulunamadı" | Paketin içindeki `.dll` dosyaları silinmiş olabilir; zip'i yeniden çıkar. Sorun sürerse Microsoft Visual C++ 2015-2022 Redistributable (x64) kur. |
| "data klasörü bulunamadı" benzeri hata | `bir_omur.exe` dosyasını tek başına başka yere taşıma; klasörün tamamını taşı. |
| SmartScreen engelliyor | Daha fazla bilgi → Yine de çalıştır. |
| Pencere çok küçük/büyük açılıyor | Pencere kenarından sürükleyerek boyutlandırabilirsin. |

## Bilinen sınırlar

- Bu bir **test sürümüdür**: dijital imzası yoktur, kurulum sihirbazı yoktur.
- **Oyun kaydı yok** — uygulamayı kapatınca hayat baştan başlar.
- Arayüz telefon ölçüsüne göre tasarlandı; masaüstünde pencereyi dar tutmak
  daha doğru bir görünüm verir.
- Görsel tasarım hâlâ onay bekliyor (`docs/DESIGN_REVIEW_QUEUE.md` → Q-001).
- Artifact'lar **30 gün** sonra GitHub tarafından silinir.

## Android'i de denemek istersen

Telefon için debug APK üreten ayrı bir iş akışı var:
[`docs/ANDROID_TEST_APK.md`](ANDROID_TEST_APK.md).
