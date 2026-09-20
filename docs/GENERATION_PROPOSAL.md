# Kuşak sistemi önerisi ve ön koşulları

Bu belge **öneridir**, karar değildir (CLAUDE.md: tasarım Faho ile ChatGPT
tarafından kararlaştırılır). Kuyruk başlığı: **Q-062**.

## 1) Neden doğrudan kodlanamamıştı (ve şimdi durum ne)

"Çocuğum olarak devam et" sistemi, oyuncunun **çocuğu olmasını** gerektirir.
Belgenin ilk hâlinde oyunda evlilik de çocuk da yoktu; bu yüzden kuşak
sistemi doğrudan kodlanamıyordu:

- **Evlilik yoktu.** `RelationType` içinde `es` bağı yoktu; yalnızca
  `sevgili` ve `eskiSevgili` vardı (D-029, D-030).
- **Çocuk yoktu.** Oyuncunun çocuğu olabileceği hiçbir akış yoktu.
- Miras kuralı (D-037) **"gerçek evlilik kaydı yokken sevgili eş
  sayılmaz"** diyor; yani bir evlilik kaydı kavramı bekleniyordu ama
  tanımlı değildi.
- D-037 ayrıca kuşak sistemi için **"şu anda otomatik olarak ekleme"**
  diyor: sistem kendiliğinden değil, Faho'nun açık talimatıyla eklendi ve
  oyuncuya **seçenek** olarak sunulur; kimse zorla yeni kuşağa geçmez.

**Güncel durum:** Faho'nun "kodlamaya başla" talimatıyla E1 (evlilik) ve
E2 (çocuklar), "kuşak sistemini kodla" talimatıyla da E3 kodlandı: `RelationType.es`, `RelationType.eskiEs`,
`RelationType.cocuk` ve `GameState.marriage` artık var, miras bunlara göre
işliyor. Kullanılan bütün yaş/tutar/oran değerleri `prototypeOnly`'dir ve
**Q-063 ile Q-064** altında karar bekliyor; `DECISIONS.md`'ye kalıcı kural
yazılmadı. **E3 (kuşak devamı) hâlâ kodlanmadı**; gereken kararlar 5.
bölümde. E3'ün kodlanmış hâli aynı bölümde işaretlendi.

## 2) Önerilen sıra ve durum

1. **Paket E1 — Evlilik ve birliktelik** (ön koşul) — **kodlandı**
   (Faho'nun "kodlamaya başla" talimatıyla; bütün değerler `prototypeOnly`,
   ayrıntılar **Q-063**'te karar bekliyor).
2. **Paket E2 — Çocuklar** (ön koşul) — **kodlandı** (aynı şekilde;
   ayrıntılar **Q-064**).
3. **Paket E3 — Kuşak devamı** ("çocuğum olarak devam et") — **kodlandı**
   (Faho'nun "kuşak sistemini kodla" talimatıyla). Bölüm 5'teki akış
   uygulandı; açık tasarım soruları **Q-067**'de karar bekliyor.

Her paket kendi PR'ında, mevcut kayıt/aile/miras sistemleriyle uyumlu
ilerler. E3 tek başına anlamlı değildir.

## 3) Paket E1 — Evlilik ve birliktelik (kodlandı)

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

## 4) Paket E2 — Çocuklar (kodlandı)

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

## 5) Paket E3 — Kuşak devamı (kodlandı)

E1 ve E2'nin ardından teknik ön koşul hazırdı: gerçek bir evlilik kaydı
(`GameState.marriage`) ve gerçek çocuk kayıtları (`RelationType.cocuk`).
Aşağıdaki akış `lib/domain/generation/generation_continuation.dart`
içinde kodlandı; bütün değerler ve "neyin taşınacağı" ayrıntısı
`prototypeOnly`'dir ve **Q-067**'de karar bekler.

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

**Kodlanan geçici davranış:** çocuğu oyuncu seçer; yalnızca kan bağı ve
sağ kalan ebeveyn taşınır; kuşak sayısında sınır yoktur; arşivde "2. kuşak"
rozeti görünür. Dördü de **karar bekliyor (Q-067)**; hiçbiri
`DECISIONS.md`'ye yazılmadı.

## 6) Riskler

- **Kayıt büyüklüğü:** her kuşakta kişi listesi büyür; eski kuşakların
  kişileri arşive taşınmazsa kayıt şişer. **Kodlanan çözüm:** yeni kuşağa
  yalnızca aile bağı olan kişiler geçer, tamamlanan hayat arşivde
  özet olarak durur.
- **Tutarlılık:** vefat etmiş oyuncunun kaydı, yeni oyuncunun ebeveyni
  olarak doğru görünmeli; yaş ve kuşak farkları tutarlı kalmalı (D-041).
- **Kapsam:** evlilik ve çocuk, oyunun en geniş sistemlerinden biri olur;
  denge (gider, miras, ölüm) yeniden ölçülmelidir.
