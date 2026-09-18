# Genel oyun döngüsü — v0.2

**Durum:** Yaş ilerletmenin A modeli Faho tarafından onaylandı. Diğer akış ayrıntıları öneri/açık konu olarak kalır. Henüz oyun kodu veya oynanabilir prototip yok.

## Kesin karar: oyuncu istediğinde tek tuşla yaş alır
- Hayat ekranında **Yaş Al** düğmesi bulunacak.
- Oyuncu, mevcut yaşında istediği **uygun ve erişilebilir** serbest etkileşimleri yapabilir; ardından kendisi hazır olduğunda düğmeye basıp sonraki yaşa geçer.
- Yaş ilerlemek için o yaşın bütün etkinliklerini veya olaylarını bitirmesi **gerekmez**. Her olayı tamamlamaya zorlayan sistem kullanılmaz.
- Yaş ilerletme oyuncunun iradesine bağlıdır; gerçek zamanlı otomatik yaşlanma onaylanmadı.
- Aile etkileşimleri ve aileden gelen gelişmeler, ilgili kişiyle ilişkiyi ve ana karakterin uygun değerlerini değiştirebilir; önemli sonuçlar ileride hatırlanabilir.

## Önerilen akış — sırası ve ayrıntıları kesinleşmedi
1. Hayat ekranında yaş, karakter özellikleri, ilişkiler ve son gelişmeler görünür.
2. Oyuncu Aile sekmesinde hediye verme / birlikte vakit geçirme gibi yaşına ve mevcut koşullarına uygun etkileşimleri seçebilir. İleride okul, arkadaş ve iş sekmeleri eklenebilir.
3. Etkileşim sonuçları ilgili ilişkiye, karakter değerlerine ve gerektiğinde geçmiş hafızasına işlenir.
4. Oyuncu **Yaş Al** düğmesine basar; sistem yeni yaşa, mevcut aile/okul/iş durumuna, kişilere ve geçmiş kararlara uygun olayları değerlendirir. NPC gelişmeleri yaş alma sırasında veya başka bir noktada gösterilebilir; zamanlaması henüz belirlenmedi.
5. Sonuçlar sonraki yaşa taşınır.

## Sıradaki tasarım kararı: etkileşim sınırı
Yaş alma serbest olduğu için aynı etkileşimi sürekli tekrarlayıp mutluluk/zeka/ilişki gibi değerleri sınırsız yükseltmeye izin verilip verilmeyeceğini belirlemeliyiz. **Henüz karar verilmedi.** Olası yaklaşımlar: yaş başına sınırlı etkileşim hakkı; aynı etkinlik için azalan etki; para ve durum koşulları; anlamlı etkinliklerde tekrar sınırı. Bu seçenekler öneridir, uygulama talimatı değildir.

## Diğer açık sorular
- Yaş Al'a basıldığında kaç olay gösterilir, olaylar hangi sırayla çözülür?
- Serbest etkileşimler sonuçları anında mı gösterir; geçmiş günlüğüne ne kaydedilir?
- Önemli ama isteğe bağlı/kaçırılabilir olaylar nasıl sunulur? Oyuncu bütün olayları tamamlamak zorunda değildir.
- Oyuncu ömrünün bitişi, ölüm ve yeni hayata başlama akışı nasıl olur?
- Karakter değerlerinin sayısal aralığı ve olay etkileri nasıl dengelenir?

## Durum özeti
**Ana karakterin ana hatları ve rastgele aile kuralları tasarlandı; genel döngünün tek tuşla isteğe bağlı yaş alma kuralı da kesinleşti.** Şimdi yaş başına etkileşimlerin sınırlanıp sınırlanmayacağını ve yaş alma anındaki olay akışını tasarlıyoruz.
