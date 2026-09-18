# Proje durumu

**Aşama:** Tasarım — ana karakter ve rastgele aile kuralları belirlendi; **tek tuşla isteğe bağlı yaş alma kesinleşti**. Şimdi serbest etkileşimlerin tekrar sınırı ve yaş alma olay akışı planlanıyor. **Oynanabilir prototip ve oyun kodu henüz oluşturulmadı.**

## Şu ana kadar ana hatlarını belirledik
Türkiye/nostalji odaklı özgün oyun kimliği; doğum yılı seçilmeyen karma olay havuzu; iki başlangıç modu ve rastgele aile/şehir; dış görünüş, mutluluk, sağlık, zekâ, karizma; ilişkilerin seçimlerden etkilenmesi; geçmiş karar hafızası; yaş ve koşula göre olay uygunluğu; aile üyelerinin bağımsız yaşam gelişmeleri. Kesin karar kaydı: `DECISIONS.md`.

## Aile sistemi: netleşenler
Sabit 'ortalama aile' yok: ebeveynlerin yaşları, evlilik/ayrılık/boşanma durumları, meslekleri ve ayrı ekonomik koşulları değişebilir. Teyze, dayı, hala, amca, anneanne, babaanne ve dedeler dahil geniş aile rastgele oluşabilir. **Akraba olmak aynı evde yaşamak değildir**; bir kısmı oyuncuyla birlikte yaşayabilir. **Aile sekmesinde** bireyler görüntülenir; anne-babanın yaşı, mesleği, ayrı ekonomik durumu görünür. Hediye verme ve birlikte vakit geçirme etkileşimleri olacaktır. Ailenin oyuncuya davranışı ve karşılıklı etkileşimler **ana karakterin değerlerini de** değiştirebilir. Ayrıntılar: `docs/FAMILY_SYSTEM.md`.

## Genel işleyiş: yeni kesinleşen karar
Oyuncu mevcut yaşında istediği uygun etkileşimleri yapar ve **Yaş Al** düğmesine basarak hazır olduğunda bir sonraki yaşa geçer. Her etkinliği/olayı tamamlamak zorunda değildir. Yaş alma öncesindeki etkileşim sayısı, tekrar sınırları, rastgele olayların gösterilme sırası ve yoğunluğu henüz belirlenmedi. Taslak: `docs/CORE_LOOP.md`.

## Şu anda yapıyoruz
**Yaş başına etkileşim dengesi** ve **Yaş Al düğmesine basılınca hangi olayların nasıl sunulacağı** üzerine karar vereceğiz. Aile veri şeması, ekonomi, olay verisi şeması ve ilk prototip kapsamı da açık.

## Sonraki tasarım işleri
Genel döngü ile aile ayrıntıları netleşince eğitim, kariyer, ekonomi, ilişkiler ve diğer sistemleri ayrıntılandır; ilk olay veri şemasını ve oynanabilir prototip kapsamını belirle. Kesin olay sayısı, yaş bantları ve teknik yığın henüz seçilmedi.

## ChatGPT / Claude devri
Yeni oturumda önce `DECISIONS.md`, bu dosya ve görevle ilgili tasarım belgesini oku. **Önerileri kesin karar sayma.** Kod yazmaya başlamadan önce ilk prototip kapsamı kullanıcıyla netleşmeli. Çalışma tamamlanınca durum ve ilgili karar belgeleri güncellenmeli.

## Depo sınırı
Yalnızca `fahrettinkoksal/bir--m-r` üzerinde çalış. Hipopotamya organizasyonundaki hiçbir depoya dokunma.
