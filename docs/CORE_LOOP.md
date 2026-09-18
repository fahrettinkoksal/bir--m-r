# Genel oyun döngüsü — v0.3

**Durum:** Faho, isteğe bağlı tek tuşla yaş almayı (A) ve tekrarlanan etkileşimlerde azalan olumlu etkiyi (B) onayladı. Hemen yinelenen aile etkileşimlerine bağlamsal ret ve ret halinde küçük mutluluk kaybı ihtimali de kesinleşti. Teknik denge rakamları ve diğer akış ayrıntıları henüz taslak; oyun kodu/prototip yok.

## Kesinleşen ana döngü
- Hayat ekranında **Yaş Al** düğmesi olur. Oyuncu mevcut yaşında uygun/erişilebilir etkileşimlerini kendi isteğiyle yapar; hazır olduğunda düğmeye basarak bir sonraki yaşa geçer.
- Bir sonraki yaşa geçmek için o yaşın bütün etkinliklerini veya olaylarını tamamlamak zorunda değildir; gerçek zamanlı otomatik yaşlanma kararlaştırılmadı.
- Aileyle karşılıklı etkileşimler ilgili ilişkiyi ve ana karakterin uygun değerlerini değiştirebilir; önemli etkiler sonraki yaşlarda hatırlanabilir.
- **Azalan getiri (B):** Aynı kişiyle aynı tür etkinlik art arda tekrarlandığında olumlu getirisi giderek düşer; tek hareketi durmadan kullanıp değerleri sınırsız artırma yolu olmaz. Bu kural, her yaş için tek tip sabit etkileşim hakkı belirlendiği anlamına gelmez.
- **Bağlamsal ret:** Örneğin anneyle vakit geçirdikten hemen sonra tekrar istenirse anne bazen 'Daha yeni birlikte vakit geçirdik' diyerek reddedebilir. Ret her denemede otomatik değildir. Gerçekleştiğinde oyuncunun mutluluğu bir miktar düşebilir; kesin puan, ihtimal ve tetikleme koşulları belirlenmedi.

## Örnek etkileşim akışı — yazılmış olay değil
1. Oyuncu **Aile → Anne → Vakit Geçir** seçer.
2. Uygun bir sonuç metni gösterilir: 'Annenle sinemaya gittin. Sonrasında oturup uzun uzun dertleştiniz.' İlgili ilişki ve uygun karakter değerleri değişebilir.
3. Oyuncu kısa süre içinde aynı isteği tekrarlar. Oyun bağlama göre bir **ret sonucu** seçebilir: 'Daha yeni vakit geçirdik, biraz da kendime zaman ayırayım.' Ret gerçekleşirse karakterin mutluluğu az miktarda düşebilir; etkinlik başarılı olmuş gibi tam ödül verilmez.
4. Ret gerçekleşmez ve etkinlik yeniden yapılırsa aynı etkileşimden sağlanan olumlu etki öncekine göre azalır.

Bu anlatım **örnek metin ve işleyiş taslağıdır**; sinema aktivitesinin her yaşta/şehirde mutlaka bulunacağı ya da her reddin zorunlu puan kaybı yaratacağı kesinleşmedi.

## Önerilen uygulama yaklaşımı — ONAYLANMADI
- Tekrar geçmişini **kişi + etkileşim türü + mevcut dönem** bazında izlemek, anneyle vakit geçirmeyi babayla vakit geçirmeyle karıştırmamayı sağlar.
- Ret olasılığı kişinin güncel durumuna, aradaki süreye, yakın zamandaki deneme sayısına ve ilişkiye göre belirlenebilir. İlk tıklamayı sebepsiz yere cezalandırmamak ve reddi sürekli negatif döngüye dönüştürmemek için denge gerekir.
- Yaş alma sonrasında tekrar baskısının nasıl gevşeyeceği, aynı yaşta farklı faaliyetlerin tekrar sayılıp sayılmayacağı, mutluluk/ilişki etkilerinin üst-alt sınırları belirlenmeli.
- Hediye, sohbet, birlikte vakit geçirme gibi farklı etkinliklerin her birine aynı azalma eğrisini uygulamak zorunda değiliz; kesin formül daha sonra seçilecek.

## Henüz karar vermediğimiz genel akış
Yaş Al düğmesinden sonra olayların kaç tane ve hangi sırayla gösterileceği; NPC gelişmelerinin ne zaman duyurulacağı; olay günlüğünün ayrıntısı; ölüm ve yeni hayata geçiş; oyuncunun ana değerlerinin rakamsal aralığı henüz açık. Olay motoru yaş ve yaşam koşullarına uygun olmayan sonuçları göstermemeli.

## İlerleme özeti
**Tasarladık:** Oyun/karakter ana hatları, rastgele aile, ilişki ve hafıza prensipleri, tek tuşla yaş alma, azalan getirili aile etkileşimleri ve olası doğal ret. **Şimdi tasarlıyoruz:** Yaş Al düğmesi sonrasındaki olay sunumu ve denge ayrıntıları. Kod/prototip henüz yok.
