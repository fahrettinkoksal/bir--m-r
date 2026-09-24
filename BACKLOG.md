# Açık konular ve fikir havuzu

Buradaki maddeler **henüz kesinleşmiş karar değildir**. Onaylanan sonuçlar `DECISIONS.md` içine işlenir.

## Şimdi: Aile sistemi
- Aile üyelerinin başlangıçta nasıl üretileceği ve saklanacak özellikler.
- Farklı ebeveyn/bakım veren yapıları, kardeş sayısı ve geniş ailenin hane içinde/dışında konumu.
- Aile bireylerinin kendi yaşam döngüsü: iş, taşınma, yeni kardeş, ayrılık, ölüm.
- Aile ilişkilerinin puanları, hane ekonomisi ve bu koşullara bağlı olaylar.
- Örnek olayları gerçek olay verisine dönüştürme. Ayrıntılar: `docs/FAMILY_SYSTEM.md`.

## Sonraki sistemler

Bu listenin büyük bölümü artık **kodlandı**; kalanlar aşağıda işaretlidir.
Sayısal denge hemen her kalemde hâlâ `prototypeOnly` ve
`docs/DESIGN_REVIEW_QUEUE.md` üzerinden karara bağlanacak.

- ~~Eğitim: okula başlama, başarı, sınavlar, üniversite seçenekleri.~~
  **Kodlandı** (okul paketi, sınav paketi, üniversite yerleştirme).
- ~~İş ve kariyer: meslekler, iş arama, terfi, işsizlik.~~ **Kodlandı**
  (mülakat, zam/terfi, emeklilik). **Girişimcilik yapılmadı.**
- ~~Ekonomi: oyuncu parası, gelir/gider, mal varlığı.~~ **Kodlandı**
  (geçim gideri, maaş, eşya, konut, kira geliri, miras).
  **Hane bütçesi ve borç yapılmadı.**
- ~~Arkadaşlık, romantik ilişkiler, evlilik, çocuklar ve nesiller.~~
  **Kodlandı** (teklif/düğün, ikinci evlilik, hamilelik, evlat edinme,
  tüp bebek, torunlar, çocuk olarak devam).
- ~~Sosyal medya, sağlık, yaşlanma.~~ **Kodlandı** (hesap/takipçi/
  sponsorluk, sağlık krizleri, yaşlanmanın görünüşe etkisi).
  **Hukuk sistemi yapılmadı.**
- Karakter özelliklerinin puan aralığı, başlangıcı ve değişim dengesi —
  kodda var, **kesin denge kararı yok**.
- ~~Olay sayısı/hedefi, tekrarın önlenmesi, yılda kaç olay gösterileceği.~~
  **Kodlandı** (tekrar sönümü, dönüm noktası önceliği, yılda bir açılış
  olayı + ilerlemeye bağlı ek olay).
- ~~Olay veri şeması, seçim etkileri, geçmiş hafızası, olay zincirleri ve
  testler.~~ **Kodlandı.** Şema hâlâ onaylanmış bir tasarım kararı değil.
- ~~Ekranlar, görsel tarz, teknik yığın, ilk oynanabilir prototipin
  kapsamı.~~ **Kodlandı.** Kesin palet hâlâ seçilmedi (Q-077).

**Sonraki büyük sistem önerileri:** `docs/NEXT_DEVELOPMENT_OPTIONS.md`
(yalnızca öneri; hiçbiri karar değildir).

## Issue #67 — yapılanlar
- ~~**Kalıcı hobiler.**~~ **Kodlandı (Paket 39, PR #70).** Mevcut Kurslar,
  Kütüphane ve Spor salonu eylemleri artık kalıcı iz bırakıyor. Sayılar
  onay bekliyor — **Q-106**.
- ~~**Evcil hayvan sahiplenme ve bakımı.**~~ **Kodlandı (Paket 40,
  PR #71).** Sorular — **Q-107**.
- ~~**Eğlence aktivitelerinin gerçek kişilerle yapılması.**~~ **Kodlandı
  (Paket 41, PR #72).** Sorular — **Q-108**.

Bu üç PR ve bütünleşik test PR'ı (#73) **`main`'e birleştirilmedi**;
Faho'nun onayı bekleniyor.

## Faho'nun işaret ettiği, yapılanlar
- ~~**Aktiviteler → Sağlık menüsü ve tüp bebek tedavisi.**~~ **Yapıldı (Paket 35).** Kısır çiftin artık tıbbi bir çıkış yolu var: başarı oranları gerçeğinden derlendi, kısırlık ihtimali düşürüyor ama sıfırlamıyor. Sayılar onay bekliyor — **Q-103**.
- ~~**İkinci evlilik.**~~ **Yapıldı (Paket 36).** Boşanan ya da dul kalan yeniden evlenebiliyor; eski kayıt engellenerek değil, geçmişe taşınarak korunuyor. Sorular — **Q-104**.
- ~~**Hamilelik süreci.**~~ **Yapıldı (Paket 26).** Korunmadan yakınlaşma artık hamilelik başlatıyor, bebek bir sonraki yaşta doğuyor. Sorular — Q-094.

## Faho'nun PC'de oynarken işaret ettikleri — yapılanlar (Paket 49)
- ~~**Kadına zorunlu askerlik görünüyor.**~~ **Düzeltildi.** Kayıt değil,
  görüntü hatasıydı; gönüllü subaylık yolu korundu.
- ~~**Bazı seçimler pasif kalıyor.**~~ **Denetlendi.** Kapalı düğmelerin
  hepsi gerekçesini yazıyor; kalıcı ulaşılmaz içeriğe karşı test eklendi.
- ~~**Karate vb. eğitimler çok uzun.**~~ **Tıklama yükü düzeltildi**
  ("Yılı çalış"). Süre kararı — **Q-111**.
- ~~**Sosyal medyada çapraz ve yıllık takipçi artışı.**~~ **Kodlandı.**
  Sayılar ve durgunluk kuralı — **Q-112**.
- ~~**Mankenlik, yazarlık vb. meslekler.**~~ **Kodlandı** (katalog 9 → 15).
  Maaşlar ve eşikler — **Q-113**.
- ~~**Olay zincirlerini derinleştir.**~~ **Kodlandı** (4 zincir, 17 olay).
  Sayılar — **Q-114**.

## Faho'nun işaret ettiği, henüz yapılmayanlar
- Şu an bu başlıkta bekleyen madde yok. Yeni istekler geldikçe buraya yazılır.

## İleride değerlendirilir
Premium şehir seçimi; tarihsel takvim/doğum yılı temelli içerik; diğer para kazanma yöntemleri. Şimdilik uygulama kapsamına dahil değiller.
