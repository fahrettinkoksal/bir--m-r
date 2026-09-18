# Aile sistemi taslağı — v0.1

**Durum: Tartışmaya açık taslak; aşağıdaki öneriler otomatik olarak onaylanmış karar değildir.** Kesinleşmiş kurallar `DECISIONS.md` içindedir.

## Kısa ilerleme özeti
**Şimdiye kadar ana hatlarını tasarladık:** Türkiye odaklı ve nostaljiyle günümüzü harmanlayan oyun kimliği, iki modlu rastgele doğum, beş ana karakter değeri, ilişkilere etki eden seçimler, geçmiş karar hafızası ve olayların yaşa uygunluğu. Aile üyelerinin de kendi hayatlarında olaylar yaşayacağı kesinleşti. **Şimdi aile sistemini ayrıntılandırıyoruz.** Oynanabilir oyun, kod veya tamamlanmış olay kütüphanesi henüz yok.

## Kesinleşmiş aile ilkeleri
- Karakter çok zengin veya çok yoksul ailede doğabilir; gelir seviyesi rastgeledir.
- Kardeş sayısı sıfır veya çok sayıda olabilir.
- Evde evcil hayvan bulunabilir ya da bulunmayabilir.
- Anneanne, babaanne, dede gibi geniş aile bireyleri aynı evde bulunabilir veya bulunmayabilir.
- Doğum şehri rastgele seçilir; isim/cinsiyet dışında ilk sürümde oyuncu başlangıç koşullarını seçmez.
- Aile üyeleri oyuncudan bağımsız gelişmeler yaşayabilir; bunlar oyuncunun hayatını etkileyebilir.
- Aile ilişkileri oyuncunun seçimleriyle değişebilir; yaş ve mevcut hayat koşulları olay uygunluğunu sınırlar.

## Tasarım önerisi A — Aileyi canlı karakterler olarak tutmak
Oyuncuyla ilişkili her önemli kişinin kalıcı bir kimliği (ID), adı, yakınlık türü, hayatta olup olmadığı ve aynı evde yaşayıp yaşamadığı tutulabilir. Aynı evde yaşamayan bir büyükanne de aile ağacında var olabilir; eve taşınmak veya ayrılmak zamanla değişebilir. **Bu veri alanları henüz kesinleşmedi.**

## Tasarım önerisi B — Tutarlı rastgele doğum
Önce hane ve bakım verenler, sonra kardeşler, geniş aile ve evcil hayvan oluşturulabilir. Rastgele sonuçlar birbiriyle çelişmemeli: aynı evde olmayan kişiye sürekli ev içi olay çıkmamalı; olmayan kardeş oyuncuya seslenmemeli. Her ailenin aynı yapıda olması gerekmez. Gelir seviyesi ayrı olayların olasılıklarını ve erişilebilir seçenekleri etkileyebilir. Olasılık yüzdeleri **belirlenmedi**.

## Tasarım önerisi C — Ailenin kendi olayları
Oyuncu yaş alırken aile bireyleri de gelişmeler yaşayabilir. Özgün örnek zincirler:

1. **Baba işini kaybeder:** Hane bütçesi etkilenebilir; çocuğun dershaneye gitme, mahalle aktivitesine katılma veya aileye yardım etme seçenekleri değişebilir. İşten çıkarılmanın gerçekleşme yaşı ve sıklığı henüz belirlenmedi.
2. **Anne yeni işe başlar:** Aile ekonomisi ve evde geçirilen zaman değişebilir; oyuncunun aile içi ilişkileri mevcut bağlara göre farklı etkilenebilir.
3. **Kardeş evden ayrılır:** Hane üyeleri değişir; özlem, daha az kalabalık ev veya ziyaret olayları açılabilir.
4. **Anneanne aynı eve taşınır:** Ev yaşamı ve kuşaklar arası olaylar açılabilir; oyuncuyla ilişkisi başlangıçtaki bağa göre şekillenir.
5. **Dedenin vefatı:** Aile ağı ve oyuncunun duygusal durumu etkilenebilir; artık yaşayan karakter gerektiren olaylarda görünmez. Ölümün oyun içi sunumu ve sıklığı ayrıca tasarlanmalı.

Bunlar **tasarım örnekleri**, henüz kodlanmış veya tek tek onaylanmış olaylar değildir.

## Tasarım önerisi D — Türkiye'ye özgü aile olay havuzu
Bayram ziyaretinde akraba kalabalığı, misafir çocuğunun oyuncak istemesi, aile büyüklerinin harçlık vermesi, anneannenin evinde yaz tatili, sofrada kardeşle son börek için yarışmak, akrabanın evlilik sorusu gibi tanıdık durumlar kullanılabilir. Olaylar özgün yazılmalı, karakterin yaşına ve ailede gerçekten bulunan kişilere uymalıdır. Aile yapıları stereotipleştirilmemelidir.

## Karara bağlanması gereken sorular
1. Başlangıçta ebeveynler ve bakım verenler için hangi aile yapıları mümkün olacak?
2. Anne, baba ve diğer NPC'lerin meslek, yaş, sağlık, kişilik, mutluluk gibi hangi özellikleri tutulacak?
3. Aile ilişkileri yalnızca bir puan mı, yoksa sevgi/güven/yakınlık gibi birden fazla değer mi taşıyacak?
4. Birlikte yaşama, taşınma, evlilik, ayrılık, yeni kardeş, iş kaybı ve ölüm olaylarının koşulları nasıl tanımlanacak?
5. Aynı yaşta kaç aile olayı olabilecek; tekrarlar nasıl önlenecek?
6. Maddi durum ve şehir, aile olaylarını ne ölçüde etkileyecek?

## Sonraki adım
Faho ile önce **aile üyelerinin başlangıçta nasıl üretileceği** ve hangi bilgilerin saklanacağı netleştirilecek. Ardından aile olayları için ilk veri şeması hazırlanacak. Onaylanan kurallar `DECISIONS.md` ve `SYSTEMS.md` dosyalarına taşınacak; açık kalanlar `BACKLOG.md` içinde kalacak.
