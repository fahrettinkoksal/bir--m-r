# Proje durumu

**Aşama:** Tasarım — ana karakter, rastgele aile, serbest yaş alma ve olay akışının temel kuralları belirlendi. **Oynanabilir prototip ve oyun kodu henüz oluşturulmadı.**

## Şu ana kadar ana hatlarını belirledik
Türkiye/nostalji odaklı özgün oyun kimliği; doğum yılı seçilmeyen karma olay havuzu; iki başlangıç modu ve rastgele aile/şehir; dış görünüş, mutluluk, sağlık, zekâ, karizma; ilişkilerin seçimlerden etkilenmesi; geçmiş karar hafızası; yaş ve koşula göre olay uygunluğu; aile üyelerinin bağımsız yaşam gelişmeleri. Kesin karar kaydı: `DECISIONS.md`.

## Aile sistemi: netleşenler
Sabit 'ortalama aile' yok: ebeveyn yaşları, evlilik/ayrılık/boşanma durumları, meslekleri ve ayrı ekonomik koşulları değişebilir. Teyze, dayı, hala, amca, anneanne, babaanne ve dedeler dahil geniş aile rastgele oluşabilir. **Akraba olmak aynı evde yaşamak değildir**; bir kısmı oyuncuyla birlikte yaşayabilir. **Aile sekmesinde** bireyler görüntülenir; anne-babanın yaşı, mesleği, ayrı ekonomik durumu görünür. Hediye verme ve birlikte vakit geçirme etkileşimleri olacaktır. Aile davranışları ve karşılıklı etkileşimler **ana karakterin değerlerini de** değiştirebilir. Ayrıntılar: `docs/FAMILY_SYSTEM.md`.

## Genel işleyiş: kesinleşenler
Oyuncu mevcut yaşında uygun etkileşimleri seçer ve **Yaş Al** düğmesine basarak hazır olduğunda sonraki yaşa geçer; bütün etkinlikleri tamamlamak zorunda değildir. Aynı kişiyle aynı etkileşim tekrarlandığında olumlu getirisi azalır; aile bireyi yakın tekrarı bazen reddedebilir, bu ret mutluluğu biraz azaltabilir. **Yaş Al'a basıldığında ilk olarak tek bir, yeni yaşa ve koşullara uygun olay çıkar.** Seçimler hikâye zincirlerine dönüşebilir; geçen yaşta başlayan sevgili/okul meselesi uygun koşullarda devam edebilir. Daha sonra aynı yaşta aile, okul/üniversite, ilişki, ev/araç ve eklendiğinde sosyal medya gibi farklı alanlardan **aralıklı, spam olmayan** olaylar gelebilir. Tek açılış olayı = yılda toplam tek olay değildir. Ayrıntılar: `docs/CORE_LOOP.md`.

## Şu anda yapıyoruz
**Olay motorunun tetikleyici ve tempo kurallarını** (aralıklı ek olaylar nasıl başlayacak, seçimden sonraki devam ne zaman gösterilecek, farklı açık hikâyeler nasıl dengelenecek) planlıyoruz. Olayların kesin sayısı veya gerçek zamanlı dakika beklemesi henüz belirlenmedi. Aile veri şeması, ekonomi, olay verisi şeması ve ilk prototip kapsamı da açık.

## Sonraki tasarım işleri
Olay motoru tasarımını netleştir, olay veri şemasını örnek zincirlerle sınayarak oluştur; sonra eğitim, kariyer, ekonomi ve ilişkileri ayrıntılandır, ilk oynanabilir prototipin sınırını belirle. Kesin sayısal denge ve teknik yığın henüz seçilmedi.

## ChatGPT / Claude devri
Yeni oturumda önce `DECISIONS.md`, bu dosya ve görevle ilgili tasarım belgesini oku. **Önerileri kesin karar sayma.** Kod yazmaya başlamadan önce ilk prototip kapsamı kullanıcıyla netleşmeli. Çalışma tamamlanınca durum ve ilgili karar belgeleri güncellenmeli.

## Depo sınırı
Yalnızca `fahrettinkoksal/bir--m-r` üzerinde çalış. Hipopotamya organizasyonundaki hiçbir depoya dokunma.
