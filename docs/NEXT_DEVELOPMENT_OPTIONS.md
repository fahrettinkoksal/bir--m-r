# Sonraki geliştirme seçenekleri — **öneri listesi**

Bu dosyadaki on maddenin hiçbiri karar değildir ve hiçbiri kodlanmadı.
Amaç, Faho ile ChatGPT'nin hangi yöne gidileceğine karar verirken tek
sayfadan bakabilmesi. Kesin kurallar `DECISIONS.md`, açık sorular
`docs/DESIGN_REVIEW_QUEUE.md` içinde.

Her madde için dört başlık var: **neden faydalı**, **hangi sisteme
bağlanır**, **tahmini kapsam** (küçük / orta / büyük) ve **gereken tasarım
kararları**.

Kapsam ölçüsü: *küçük* ≈ tek paket, mevcut ekranlara birkaç satır;
*orta* ≈ yeni bir alt sayfa ve kayıt alanı; *büyük* ≈ yeni bir sistem,
kayıt biçimi değişikliği ve çok sayıda yeni olay.

---

## 1. Sağlık geçmişi ve kronik durumlar

**Neden faydalı.** Şu an sağlık tek bir sayı ve krizler birbirinden
bağımsız. Aynı krizi üçüncü kez yaşayan oyuncuda hiçbir iz kalmıyor;
"hayatım boyunca şu hastalıkla yaşadım" anlatısı kurulamıyor.

**Bağlanacağı sistem.** Mevcut `HealthCrisisEngine` ve sağlık merkezi
aktiviteleri. Yeni sistem gerekmez: krizin sonucu kalıcı bir kayda
yazılır, sonraki kriz ihtimali ve olay havuzu bu kayda bakar.

**Kapsam.** Orta.

**Gereken kararlar.** Kronik durum oyuncuyu ne kadar cezalandırmalı?
İyileşme mümkün mü, yoksa yalnızca yönetilebilir mi? Kronik durumu olan
biri sigorta/tedavi masrafı ödemeli mi? Ölüm ihtimaline etkisi ne olmalı?

---

## 2. Eşlerin ve çocukların kendi ilerleyen hayatı

**Neden faydalı.** Çocuklar arka planda büyüyor (D-045) ama eş hiç
değişmiyor: emekli olmuyor, iş değiştirmiyor, hastalanmıyor. Uzun
evliliklerde eş donmuş bir kayıt gibi duruyor.

**Bağlanacağı sistem.** `ChildProgression` zaten var; aynı yaklaşım eşe
uygulanır. Yeni ekran gerekmez, kişi detayında zaten gösterilecek alanlar
mevcut.

**Kapsam.** Orta.

**Gereken kararlar.** Eşin geliri hane bütçesine girmeli mi? Eşin işsiz
kalması oyuncuyu nasıl etkilesin? Eşin kendi ailesi (kayınvalide,
kayınpeder) kayda girsin mi?

---

## 3. Hane bütçesi ve ortak para

**Neden faydalı.** Şu an tek cüzdan var; evlilik ekonomik olarak hiçbir
şey değiştirmiyor. Boşanmanın da parasal sonucu yok (Q-104/3).

**Bağlanacağı sistem.** `LivingCosts` ve `Inheritance`. Ortak hesap ayrı
bir sayı olarak kayda girer; gider formülü ondan da düşebilir.

**Kapsam.** Büyük — kayıt biçimi değişir ve miras kuralları (D-037)
yeniden gözden geçirilir.

**Gereken kararlar.** Ortak para zorunlu mu, tercih mi? Boşanmada nasıl
paylaşılır? Nafaka olacak mı? Ölümde ortak hesap mirasa nasıl girer?

---

## 4. Arkadaşlıkların kendi hikâyesi

**Neden faydalı.** Arkadaş kaydı gerçek ama arkadaşlığın kendi olay
zinciri yok: küslük, barışma, uzaklaşma, yıllar sonra karşılaşma. Bağ
sönümlenmesi (Paket 24) var ama anlatısı yok.

**Bağlanacağı sistem.** `Friendship`, `BondDecay` ve olay havuzu. Yeni
kayıt alanı gerekmeyebilir; olay havuzu ve hikâye izleri yeter.

**Kapsam.** Orta (ağırlıklı olarak içerik).

**Gereken kararlar.** Arkadaşlık bitebilmeli mi, yoksa yalnızca soğusun
mu? Küs arkadaş etkileşim listesinde nasıl görünsün? Barışma parayla ya
da hediyeyle mi, yoksa yalnızca olayla mı olsun?

---

## 5. Meslekte ustalık ve itibar

**Neden faydalı.** Kariyer şu an iş kimliği + yıl sayısı. Aynı işte 30
yıl çalışan biriyle üç yıl çalışan biri arasında, maaş dışında, hiçbir
fark yok.

**Bağlanacağı sistem.** `CareerState`, zam/terfi akışı ve hayat sonu
değerlendirmesinin Emek ekseni. Hobi sisteminin basamak yaklaşımı
(Paket 39) aynen kullanılabilir.

**Kapsam.** Orta.

**Gereken kararlar.** Ustalık neyi açsın — daha yüksek maaş mı, yeni iş
seçenekleri mi, yoksa yalnızca anlatı mı? İş değiştirince ustalık
sıfırlanır mı? Eğitmenlik eşiği (Q-100) ile ilişkisi ne olmalı?

---

## 6. Ev ve ev eşyası derinliği

**Neden faydalı.** Konut alınıyor, taşınılıyor, kiraya veriliyor; ama ev
içinde hiçbir şey olmuyor. Eşya envanteri var, evle ilişkisi yok.

**Bağlanacağı sistem.** `Housing`, `ItemActions` ve mağaza kataloğu.

**Kapsam.** Orta.

**Gereken kararlar.** Ev bakımı yıllık gider mi olsun? Eşya yıpranması
zaten var; ev de yıpranmalı mı? Taşınmanın sosyal sonucu (mahalle
arkadaşlarından uzaklaşma) modellenmeli mi?

---

## 7. Şehirlerin kendi karakteri

**Neden faydalı.** Şehir şu an bir etiket: erişilebilirlik ve gezi
dışında hiçbir şeyi değiştirmiyor. Türkiye odaklı bir oyunda şehir
farkı en doğal derinleşme yönü.

**Bağlanacağı sistem.** `GameState.player.currentCity`, `Travel`,
`LivingCosts` ve iş kataloğu.

**Kapsam.** Büyük — denge ölçümü gerektirir ve "premium şehir seçimi"
(BACKLOG) konusuna değer.

**Gereken kararlar.** Şehir neyi değiştirsin — geçim gideri, iş
seçenekleri, olay havuzu, hepsi? Şehirler arası fark oyuncuyu tek bir
şehre hapseder mi? Hangi şehirler oyuna girsin?

---

## 8. Hayat hedefleri / başarımlar

**Neden faydalı.** Hayat sonu değerlendirmesi (Q-090) hayatın sonunda
tek seferlik bir özet veriyor. Oyun içinde oyuncuyu yönlendiren hiçbir
hedef yok; ikinci hayatın birincisinden farklı olmasını sağlayan bir
sebep de yok.

**Bağlanacağı sistem.** `LifeVerdict`, `pastLives` arşivi ve hikâye
izleri. Yeni bir ekran gerekir ama yeni bir simülasyon sistemi gerekmez.

**Kapsam.** Orta.

**Gereken kararlar.** Hedefler hayat başında mı seçilsin, yoksa yol
boyunca mı açılsın? Ödül ne olsun — yalnızca kayıt mı, yoksa oyun içi bir
şey mi? Kuşaklar arası taşınır mı?

---

## 9. Kardeşlerin ve akrabaların kendi hayatı

**Neden faydalı.** Kardeş kaydı doğuştan var ama hayatı ilerlemiyor:
evlenmiyor, çocuğu olmuyor, taşınmıyor. Yeğen diye bir kayıt hiç yok.
Aile ağacı tek kuşakta kalıyor.

**Bağlanacağı sistem.** `ChildProgression` ve `Grandchildren` (torun
üretimi) zaten var; aynı yaklaşım kardeşe uygulanır.

**Kapsam.** Büyük — kişi sayısı hızla artar, erişilebilirlik ve ekran
listeleri gözden geçirilmeli.

**Gereken kararlar.** Yeğenler oyuncunun ilişkiler listesinde görünsün
mü? Kaç kuşak izlenecek? Kişi kaydı şişmesini nasıl sınırlayacağız?

---

## 10. Olay zincirlerinin derinleşmesi

**Neden faydalı.** Hikâye izleri (D-008, D-022) çalışıyor ama zincirler
çoğunlukla iki adım. Üç-dört adımlı, yıllara yayılan ve sonunda gerçek
bir sonuca varan zincirler oyunun en ucuz derinleşme yolu: yeni sistem
gerekmiyor, yalnızca içerik.

**Bağlanacağı sistem.** `EventRequirement.requiredFlags`,
`personRole` ve mevcut olay havuzu.

**Kapsam.** Küçük–orta (her zincir ayrı paket olabilir).

**Gereken kararlar.** Bir zincir kaç yıla yayılabilir? Zincirin ortasında
kişi vefat ederse ne olur? Oyuncu zinciri fark edebilmeli mi (ekranda bir
iz), yoksa sessiz mi kalsın?

---

## Kontrol notu

Bu dosya öneri listesidir. Buradaki hiçbir madde `DECISIONS.md` içine
karar olarak işlenmedi ve hiçbiri kodlanmadı.
