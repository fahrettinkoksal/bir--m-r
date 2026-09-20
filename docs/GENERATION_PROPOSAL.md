# Kuşak sistemi önerisi ve ön koşulları

Bu belge **öneridir**, karar değildir (CLAUDE.md: tasarım Faho ile ChatGPT
tarafından kararlaştırılır). Kuyruk başlığı: **Q-062**.

## 1) Neden doğrudan kodlanamadı

"Çocuğum olarak devam et" sistemi, oyuncunun **çocuğu olmasını** gerektirir.
Bugünkü oyunda:

- **Evlilik yok.** `RelationType` içinde `es` (eş) bağı yok; yalnızca
  `sevgili` ve `eskiSevgili` var (D-029, D-030).
- **Çocuk yok.** Oyuncunun çocuğu olabileceği hiçbir akış yok; `kardes`
  bağı yalnızca doğuşta üretiliyor.
- Miras kuralı (D-037) **"gerçek evlilik kaydı yokken sevgili eş
  sayılmaz"** diyor; yani oyunda bir evlilik kaydı kavramı bekleniyor ama
  henüz tanımlı değil.
- D-037 ayrıca kuşak sistemi için **"şu anda otomatik olarak ekleme"**
  diyor.

Bu yüzden bu turda kuşak sistemi kodlanmadı. Bunun yerine, kodlanabilmesi
için gereken kararlar aşağıda somut seçeneklerle sunuluyor.

## 2) Önerilen sıra

1. **Paket E1 — Evlilik ve birliktelik** (ön koşul)
2. **Paket E2 — Çocuklar** (ön koşul)
3. **Paket E3 — Kuşak devamı** ("çocuğum olarak devam et")

Her paket kendi PR'ında, mevcut kayıt/aile/miras sistemleriyle uyumlu
ilerler. E3 tek başına anlamlı değildir.

## 3) Paket E1 — Evlilik ve birliktelik (öneri)

**Amaç:** D-037'nin beklediği "gerçek evlilik kaydı"nı oluşturmak.

- `RelationType.es` eklenir; sevgiliden evliliğe geçiş bir **eylem** olur
  (yaş ve ilişki puanı koşuluyla). Kişi kaydı **silinmez**, statü değişir
  (D-029 ile aynı ilke).
- `GameState.marriage`: eş kimliği, evlenme yaşı, durum (evli/ayrı/boşanmış).
- Boşanma bir eylem olarak eklenir; kişi "eski eş" statüsüyle kayıtta kalır.
- Miras kuralı otomatik olarak doğru çalışmaya başlar: eş payı artık gerçek
  bir evlilik kaydına bakar (D-037, hâlihazırda `parentalStatus` ile
  yapıldığı gibi).
- Ekonomi: evlilik hane durumunu etkiler (D-033/D-043 ile birlikte
  düşünülmeli — iki kişilik hane gideri?).

**Karar gereken:** evlenme yaşı ve koşulları, düğün masrafı olacak mı,
boşanmanın ekonomik sonucu (mal paylaşımı) olacak mı, eşin NPC olarak
hayatı (iş, ölüm, kendi mal varlığı — bunlar zaten var).

## 4) Paket E2 — Çocuklar (öneri)

- `RelationType.cocuk` eklenir. Çocuk sahibi olmak **isteğe bağlı** bir
  eylem/olaydır; ilişki durumuna ve yaşa bağlıdır.
- Çocuk kişi kaydı diğer NPC'lerle **aynı** yapıyı kullanır: kalıcı kimlik,
  yaş, hane, mal varlığı, ölüm. Yeni bir paralel sistem kurulmaz (D-038).
- Çocuklar oyuncuyla birlikte yaşlanır; okul/meslek sistemine girmeleri
  ayrı bir karardır (basit tutulabilir: yalnızca yaş ve meslek etiketi).
- Miras: D-037'nin "eş ve çocuklar öncelikli" kuralı gerçek çocuklarla
  çalışmaya başlar.

**Karar gereken:** çocuk sahibi olma koşulları (evlilik şart mı), en fazla
çocuk sayısı, evlat edinme, çocuk bakımının ekonomiye etkisi (gider kalemi),
çocukla etkileşimler (mevcut aile etkileşimleri yeniden kullanılabilir).

## 5) Paket E3 — Kuşak devamı (öneri)

- Oyuncu öldüğünde hayat özeti ekranında **hayatta bir çocuğu varsa**
  "Çocuğum olarak devam et" seçeneği çıkar. Çocuk yoksa seçenek
  **gösterilmez** (sahte düğme olmaz, D-038).
- Devam edilirken:
  - Tamamlanan hayat **Geçmiş Hayatlar arşivine** yazılır (D-037 altyapısı
    hazır).
  - Yeni oyuncu, seçilen çocuğun kaydıdır: kimliği, yaşı, adı ve aile bağları
    korunur; eski oyuncu artık "vefat etmiş ebeveyn" olarak kayıtta kalır.
  - Miras, D-037 kurallarıyla dağıtılır; çocuğa kalan ev/araç **kalıcı varlık
    kimliğiyle** geçer.
  - Ün, meslek ve eğitim **taşınmaz**; yeni kuşak kendi hayatını yaşar.
- Alternatif (daha küçük ilk adım): devam etmek yerine yalnızca "mirasın
  kime kaldığı" hayat özetinde gösterilir.

**Karar gereken:** hangi çocukla devam edileceği (oyuncu seçer mi), dünyanın
ne kadarının taşınacağı, kaç kuşak sürebileceği, arşivde kuşakların nasıl
gösterileceği.

## 6) Riskler

- **Kayıt büyüklüğü:** her kuşakta kişi listesi büyür; eski kuşakların
  kişileri arşive taşınmazsa kayıt şişer.
- **Tutarlılık:** vefat etmiş oyuncunun kaydı, yeni oyuncunun ebeveyni
  olarak doğru görünmeli; yaş ve kuşak farkları tutarlı kalmalı (D-041).
- **Kapsam:** evlilik ve çocuk, oyunun en geniş sistemlerinden biri olur;
  denge (gider, miras, ölüm) yeniden ölçülmelidir.
