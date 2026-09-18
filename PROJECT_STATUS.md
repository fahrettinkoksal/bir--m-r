# Proje durumu

**Aşama:** Tasarım — ana karakter ve rastgele aile kuralları belirlendi; tek tuşla isteğe bağlı yaş alma, azalan etkileşim getirisi ve bazen gelen doğal ret kesinleşti. **Oynanabilir prototip ve oyun kodu henüz oluşturulmadı.**

## Şu ana kadar ana hatlarını belirledik
Türkiye/nostalji odaklı özgün oyun kimliği; doğum yılı seçilmeyen karma olay havuzu; iki başlangıç modu ve rastgele aile/şehir; dış görünüş, mutluluk, sağlık, zekâ, karizma; ilişkilerin seçimlerden etkilenmesi; geçmiş karar hafızası; yaş ve koşula göre olay uygunluğu; aile üyelerinin bağımsız yaşam gelişmeleri. Kesin karar kaydı: `DECISIONS.md`.

## Aile sistemi: netleşenler
Sabit 'ortalama aile' yok: ebeveyn yaşları, evlilik/ayrılık/boşanma durumları, meslekleri ve ayrı ekonomik koşulları değişebilir. Teyze, dayı, hala, amca, anneanne, babaanne ve dedeler dahil geniş aile rastgele oluşabilir. **Akraba olmak aynı evde yaşamak değildir**; bir kısmı oyuncuyla birlikte yaşayabilir. **Aile sekmesinde** bireyler görüntülenir; anne-babanın yaşı, mesleği, ayrı ekonomik durumu görünür. Hediye verme ve birlikte vakit geçirme etkileşimleri olacaktır. Aile davranışları ve karşılıklı etkileşimler **ana karakterin değerlerini de** değiştirebilir. Ayrıntılar: `docs/FAMILY_SYSTEM.md`.

## Genel işleyiş: kesinleşenler
Oyuncu mevcut yaşında istediği uygun etkileşimleri yapar ve **Yaş Al** düğmesine basarak hazır olduğunda sonraki yaşa geçer; bütün olayları tamamlamak zorunda değildir. **B modeli:** Aynı kişiyle aynı etkileşim tekrarlanırsa olumlu etkisi giderek azalır; sınırsız değer kasılamaz. Hemen tekrar vakit geçirme isteğinde aile bireyi bazen 'Daha yeni vakit geçirdik' diyerek reddedebilir; bu ret oyuncunun mutluluğunu biraz azaltabilir. Her isteğin reddedilmesi veya her rette kesin ceza olması kararlaştırılmadı. Kesin oran/formüller açık. Detay: `docs/CORE_LOOP.md`.

## Şu anda yapıyoruz
**Yaş Al düğmesine basılınca hangi olayların hangi sırayla ve yoğunlukta gösterileceğini** tasarlıyoruz. Tekrar etkisinin formülü, ret ihtimali, ailenin teknik veri şeması, ekonomi, olay veri şeması ve ilk prototip kapsamı da açık.

## Sonraki tasarım işleri
Genel döngü ve aile ayrıntıları netleşince eğitim, kariyer, ekonomi, ilişkiler ve diğer sistemleri ayrıntılandır; ilk olay veri şemasını ve oynanabilir prototip kapsamını belirle. Kesin olay sayısı, yaş bantları ve teknik yığın henüz seçilmedi.

## ChatGPT / Claude devri
Yeni oturumda önce `DECISIONS.md`, bu dosya ve görevle ilgili tasarım belgesini oku. **Önerileri kesin karar sayma.** Kod yazmaya başlamadan önce ilk prototip kapsamı kullanıcıyla netleşmeli. Çalışma tamamlanınca durum ve ilgili karar belgeleri güncellenmeli.

## Depo sınırı
Yalnızca `fahrettinkoksal/bir--m-r` üzerinde çalış. Hipopotamya organizasyonundaki hiçbir depoya dokunma.
