# Proje durumu

**Aşama:** Tasarım — ana karakter, rastgele aile, serbest yaş alma ve geçmişe bağlı olay akışının temel kuralları belirlendi. **Oynanabilir prototip ve oyun kodu henüz oluşturulmadı.**

## Şu ana kadar ana hatlarını belirledik
Türkiye/nostalji odaklı özgün oyun kimliği; doğum yılı seçilmeyen karma olay havuzu; iki başlangıç modu ve rastgele aile/şehir; dış görünüş, mutluluk, sağlık, zekâ, karizma; ilişkilerin seçimlerden etkilenmesi; geçmiş karar hafızası; yaş ve koşula göre olay uygunluğu; aile üyelerinin bağımsız yaşam gelişmeleri. Kesin karar kaydı: `DECISIONS.md`.

## Aile sistemi: netleşenler
Sabit 'ortalama aile' yok: ebeveyn yaşları, evlilik/ayrılık/boşanma durumları, meslekleri ve ayrı ekonomik koşulları değişebilir. Teyze, dayı, hala, amca, anneanne, babaanne ve dedeler dahil geniş aile rastgele oluşabilir. **Akraba olmak aynı evde yaşamak değildir**; bir kısmı oyuncuyla birlikte yaşayabilir. **Aile sekmesinde** bireyler görüntülenir; anne-babanın yaşı, mesleği, ayrı ekonomik durumu görünür. Hediye verme ve birlikte vakit geçirme etkileşimleri olacaktır. Aile davranışları ve karşılıklı etkileşimler **ana karakterin değerlerini de** değiştirebilir. **Yeni:** Uzun süre oyun içinde aileyle anlamlı temas kurulmaması, uygun koşullarda aile bireyinden sitem olayı doğurabilir; herkes otomatik sitem etmez. Ayrıntılar: `docs/FAMILY_SYSTEM.md` ve `docs/CORE_LOOP.md`.

## Genel işleyiş: kesinleşenler
Oyuncu mevcut yaşında uygun etkileşimleri seçer ve **Yaş Al** düğmesine basarak hazır olduğunda sonraki yaşa geçer; bütün etkinlikleri tamamlamak zorunda değildir. Aynı kişiyle aynı etkileşim tekrarlandığında olumlu getirisi azalır; aile bireyi yakın tekrarı bazen reddedebilir, bu ret mutluluğu biraz azaltabilir. **Yaş Al'a basıldığında ilk olarak tek bir, yeni yaşa ve koşullara uygun olay çıkar.** Seçimler hikâye zincirlerine dönüşebilir; önceki yaşta başlayan olaylar uygun koşullarda devam edebilir. Aynı yaşta farklı yaşam alanlarından **aralıklı, spam olmayan** başka olaylar da gelebilir.

**Yeni kesinleşen tempo:** Olaylar **gerçek dünya dakikalarına veya bekleme süresine değil, oyuncunun oyun içi ilerleyişine** bağlıdır. Anlamlı etkileşimler, seçimler, çözülmüş olaylar ve yaş alma olay fırsatı yaratabilir; her dokunuşta olay çıkmaz. Oyuncu uzun süre aileyle ilgilenmezse ilgili kişinin sitemi de bu hafıza üzerinden aday olay olabilir. Ayrıntılar: `docs/CORE_LOOP.md`.

## Şu anda yapıyoruz
**Oyun içi ilerleme adımının ve olay temposunun teknik tanımını** planlıyoruz: ne zaman yeni bir olay fırsatı oluşacak; devam, yeni sürpriz ve ihmal/sitem olayları nasıl dengelenecek; aynı sitem nasıl tekrarlanmayacak? Eşikler, formüller ve kesin olay sayıları kararlaştırılmadı. Aile veri şeması, ekonomi, olay veri şeması ve ilk prototip kapsamı da açık.

## Sonraki tasarım işleri
Olay motoru tasarımını netleştir, olay veri şemasını örnek zincirlerle sınayarak oluştur; sonra eğitim, kariyer, ekonomi ve ilişkileri ayrıntılandır, ilk oynanabilir prototipin sınırını belirle. Kesin sayısal denge ve teknik yığın henüz seçilmedi.

## ChatGPT / Claude devri
Yeni oturumda önce `DECISIONS.md`, bu dosya ve görevle ilgili tasarım belgesini oku. **Önerileri kesin karar sayma.** Kod yazmaya başlamadan önce ilk prototip kapsamı kullanıcıyla netleşmeli. Çalışma tamamlanınca durum ve ilgili karar belgeleri güncellenmeli.

## Depo sınırı
Yalnızca `fahrettinkoksal/bir--m-r` üzerinde çalış. Hipopotamya organizasyonundaki hiçbir depoya dokunma.
