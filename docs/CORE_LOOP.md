# Genel oyun döngüsü — v0.5

**Durum:** Aşağıdaki «kesinleşen» kurallar Faho tarafından onaylandı. Olay sıklığı, takip verisinin biçimi ve rakamsal dengeler henüz tasarım aşamasında. Oyun kodu veya oynanabilir prototip yok.

## 1. Kesinleşen ana döngü
1. Oyuncu bulunduğu yaşta, mevcut hayatına uygun serbest etkileşimleri (ör. Aile → Anne → Vakit Geçir) kendi isteğiyle yapar.
2. Hazır olduğunda **Yaş Al** butonuna basarak sonraki yaşa geçer; mevcut yaştaki her etkinliği bitirmesi gerekmez.
3. Yeni yaşa geçince karşısına **ilk olarak tek bir**, yaşına ve hayat koşullarına uygun olay çıkar. Aynı anda bağımsız pop-up yağmuru olmaz.
4. Seçim bir hikâye zincirini devam ettirebilir. Sonuç hemen işlenebilir; devam olayı aynı anda zorunlu olarak açılmaz, uygun bir oyun içi ilerleme noktasında veya sonraki yaşta gelebilir.
5. Oyuncu aynı yaşta oynamaya devam ettikçe aile, ilişki, okul/üniversite, ev/araç ve eklendiğinde sosyal medya gibi farklı yaşam alanlarından **aralıklı ek olaylar** gelebilir. İlk olay, yaşın tek olayı demek değildir.
6. Önemli seçimler, ilgili kişiler, açık hikâyeler ve karakterin mevcut yaşam durumu geleceğe taşınır; uygunluk denetlenir.

## 2. Yeni kesin karar: gerçek dünya dakikaları değil, oyun içi ilerleme
- **Olayın çıkması için oyuncuyu gerçek hayatta dakika/saat bekletmeyiz.** Uygulamayı açık tutmak, telefon saatinin ilerlemesi veya gerçek zamanlı zamanlayıcı olay motorunun temel tetikleyicisi olmayacak.
- Yeni olay fırsatları **oyuncunun oyun içindeki ilerlemesiyle** doğar: yaptığı anlamlı etkileşimler, verdiği seçimler, tamamlanan olaylar, Yaş Al ile gerçekleşen yaş değişimi ve bunların değiştirdiği hayat koşulları gibi.
- İlerleme, her dokunuşta otomatik yeni pencere açılması demek değildir. Olaylar **aralıklı ve bağlama uygun** çıkar; aynı konunun/kişinin üst üste gelmesiyle spam oluşmamalıdır.
- **Oyuncu hiçbir şey yapmazsa gerçek zaman geçmesi tek başına olay üretmez.** Az etkileşimli bir oyuncu Yaş Al ile ilerlediğinde de hayatın sonuçları ortaya çıkabilir; etkileşim sayısına bağlı tek bir zorunlu eşik henüz belirlenmedi.

## 3. Yeni kesin karar: ihmal edilen ilişkilerin doğal tepkisi
- Oyun, aile üyeleriyle uzun süredir **oyun içinde** vakit geçirilmemesini / anlamlı temas kurulmamasını hatırlayabilmeli. Buradaki 'uzun süre' gerçek hayattaki dakikalar değil, oyun içindeki ilerleme ve ilişki geçmişidir.
- Koşullar uygunsa ilgili aile bireyi bazen **sitem eden bir olay veya mesaj** başlatabilir: 'Uzun zamandır birlikte bir şey yapmıyoruz, beni unuttun mu?' gibi. Oyuncu seçim yapabilir; kararın ilişki veya karakter değerleri üzerinde uygun etkileri olabilir.
- **Her aile bireyi otomatik olarak sitem etmez.** Olay; kişinin gerçekten var olması, hayatta olması, iletişimin mümkün olması, mevcut ilişki ve daha önceki temaslar gibi bağlamlarla uyumlu olmalı; aynı sitem tekrar tekrar yağmamalıdır.
- Sitemi yok saymanın, gönül almanın, buluşmanın veya farklı cevap vermenin olası sonuçları ayrı tasarlanacaktır. Sırf etkileşim az diye otomatik ve sürekli ceza uygulanması kararlaştırılmadı; oyuncunun serbest yaş alma hakkı korunur.

### Örnek akış — kesinleşmiş kuralı anlatan taslak metin
22 yaşında üniversitedeki oyuncu bir arkadaş olayı çözer ve okuluyla ilgilenir. Oyun içinde birden fazla yaş/olay ilerlemesi boyunca annesiyle anlamlı temas kurmamıştır. Uygun bir sonraki ilerleme noktasında annesinden 'İki laf etmeyeli epey oldu' mesajı gelebilir. Oyuncu aramayı, sonra buluşmayı veya uygun başka bir yanıtı seçebilir. **Bu örnek, her oyuncuya aynı olayın aynı yaşta çıkacağı anlamına gelmez.**

## 4. Önceki yaşın hikâyesi sonraki yaşta devam eder
Geçen yaşta sevgilisiyle sorun yaşayan karakter yeni yaşında o olayın devamını görebilir; okulda başlattığı hikâye de uygun koşullarda sürebilir. Geçmiş seçimler unutulmaz. İlgili ilişki sona ermiş veya oyuncu okuldan ayrılmışsa olay ya yeni gerçekliğe uyarlanır ya da aday havuzuna girmez. Birden fazla hikâye bekleyebilir; devamların kesin öncelik oranı henüz belirlenmedi.

## 5. Farklı yaşam alanlarının kesişmesi
Üniversite arkadaşlarıyla ilgili olay yaşanırken daha sonra aileden haber veya başka bir yaşam alanından gelişme gelebilir. Evi olmayanın *kendi evi* su basmaz (yaşadığı hane için uygun olay ayrı yazılabilir); aracı olmayanın arabası çalınmaz; üniversitede olmayanın üniversite sınıf arkadaşı olayı çıkmaz. Kategori değişimi doğal, tutarlı ve aralıklı olmalı.

## 6. Serbest aile etkileşimleri
- Etkileşimler kişiyle ilişkiyi ve ana karakterin uygun değerlerini etkileyebilir.
- **Azalan etki (B):** Aynı kişiyle aynı etkinlik tekrarlandıkça olumlu getirisi azalır; sonsuz değer kasma yolu olmaz.
- Yakın zamanda birlikte vakit geçirilmişse aynı kişi bazen 'Daha yeni vakit geçirdik' diye reddedebilir; ret mutluluğu az miktarda düşürebilir. Her tekrarda zorunlu ret veya her rette zorunlu ceza yoktur.
- Uzun süreli **temassızlık/sitem** ile **çok sık temas/ret** iki farklı bağlamsal durumdur. Aynı kişiye ait temas geçmişi ikisine de tutarlı biçimde yansıyabilir; bunun veri şeması ve formülü henüz seçilmedi.

## 7. Onaylanmamış uygulama önerileri — Claude kesin karar sanmasın
- Kişi bazında 'son anlamlı temasın gerçekleştiği oyun içi ilerleme noktası', yakın dönem etkinlik sayısı ve açık sitem hikâyesi gibi kayıtlar tutulabilir. **Gerçek zaman damgası temel ölçüt olarak kullanılmamalı.**
- Olay fırsatını her anlamlı adımın sonunda değerlendirmek, uygun adaylar arasından devam/yeni/ihmal temalı olayları dengelemek, birbirine çok yakın pop-up'ları ve aynı sitemin tekrarını engellemek düşünülebilir. Bunun kesin algoritması, her kaç adımda bir fırsat oluşacağı ve sessiz dönemlerin uzunluğu **onaylanmadı**.
- Bir olay penceresi açıkken başka bir pencereyle üstüne binmemek; NPC'nin kendi olaylarını uygun ilerleme noktalarında işlemek; kritik olayların önceliğini bağlama göre ayarlamak değerlendirilebilir.

## 8. Sonraki tasarım soruları
1. İlk olayın çözümünden sonra oyuncu ana ekrana mı döner; doğrudan bağlı kısa devam sahneleri hangi hallerde hemen gösterilir?
2. Ek olaylar için oyun içi ilerleme ne sayılır: tamamlanan anlamlı eylem, olay sonucu, Yaş Al veya bunların kombinasyonu mu? **Belirli bir adım sayısı henüz kararlaştırılmadı.**
3. İhmal/sitem için 'uzun süre' nasıl ölçülür ve kimler hangi bağlamda sitem edebilir? Aile dışındaki ilişkiler için de benzer mantık isteyip istemediğimiz açık.
4. Birden fazla bekleyen hikâye ve yeni olaylar nasıl dengelenir; tekrarlanan sitem nasıl engellenir?
5. Sonuçlar hayat günlüğüne nasıl yazılır; ölüm ve yeni hayat akışı nasıl ilerler?

## İlerleme
**Tasarladık:** Ana karakter ve rastgele aile, tek tuşla yaş alma, azalan etkileşim etkisi, doğal ret, tek açılış olayı, geçmişi hatırlayan olay zincirleri, aralıklı farklı yaşam alanları. **Yeni netleştirdik:** Gerçek zamanlı dakika bekleme yok; olaylar oyun içi ilerlemeye bağlı; aileyle uzun süre temas edilmezse uygun koşullarda sitem olayı gelebilir. **Şimdi:** İlerleme adımının ve olay temposunun teknik tanımını, ilk prototip kapsamını planlıyoruz.
