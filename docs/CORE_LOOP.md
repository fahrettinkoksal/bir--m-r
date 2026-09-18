# Genel oyun döngüsü — v0.6

**Durum:** Tasarım kararları kaydedildi; oyun kodu veya oynanabilir prototip henüz yok. Sayısal eğriler ve olay motoru uygulaması henüz kararlaştırılmadı.

## Kesinleşen temel akış
1. Oyuncu yaşına ve hayatına uygun serbest etkileşimleri dilediği sırayla yapar. **Genel etkileşim hakkı / hamle kotası yoktur.**
2. Hazır olduğunda **Yaş Al** düğmesine basar; her etkinliği tamamlaması gerekmez.
3. Yeni yaşta ilk olarak **tek bir**, koşullara uygun olay çıkar. Bu, yılın tek olayı demek değildir.
4. Seçimler geçmiş hikâyelerin devamını açabilir. Aynı yaşta ilerledikçe başka yaşam alanlarından olaylar **spam olmadan aralıklarla** gelebilir.
5. Olaylar gerçek hayatta dakika bekletilerek değil, oyuncunun **oyun içindeki anlamlı ilerlemesine** bağlıdır. Oyuncunun uzun süre oyun içinde aile bireyiyle temas etmemesi uygun koşullarda sitem olayına yol açabilir; otomatik, sürekli ceza yoktur.

## Yeni kesin karar: sınırsız tıklama ≠ sınırsız kazanım
- Oyuncunun bütün menülere ortak 'bu yaşta en fazla X etkileşim' kısıtı **olmayacak**. Farklı uygun etkinlikleri özgürce deneyebilir.
- Aynı yaş içinde **aynı faaliyetin aynı faydasını** tekrar tekrar kazanmak mümkün olmayacak. İlk uygun gerçekleştirme güçlü olumlu etki sağlayabilir; tekrarlar daha az sağlar; sonunda **o yaşta ilgili değere/ilişkiye ek faydası sıfıra iner**.
- Bu ilke yalnızca aileyle vakit geçirmeye değil, spor salonuyla sağlık kazanma ve ders çalışmayla zekâ kazanma gibi stat geliştiren faaliyetlere de uygulanır. Bir faaliyetin faydasının bitmesi diğer farklı faaliyetlerin kapatılması anlamına gelmez.
- Faaliyet, ödülü sıfırlandıktan sonra başka anlamlı sonuçlar/masraflar doğurabilir; **sıfır ek fayda tüm sonuçların iptali demek değildir.** Hangi eylemlerin tekrar seçilebilir kalacağı arayüz ayrıntısıdır.
- Anneyle tekrar vakit geçirme isteğine anne bazen doğal bir gerekçeyle ret verebilir; ret durumunda mutluluk biraz düşebilir. Ret olasılığı ve etkinlik etkisi iki ayrı mekanizmadır.
- **Yaş değiştiğinde** yeni dönemde aynı etkinliğin yeniden anlamlı fayda verebilmesi hedeflenir; tam mı kısmi mi yenileneceği ve geçmişin ne kadar taşınacağı henüz belirlenmedi. Her etkinliğin kaçıncı tekrarda sıfıra ineceğine dair evrensel sayı koyulmadı.

### Açıklayıcı örnek; rakamlar ve etkinlik takvimi kesin karar değildir
22 yaşındaki karakter spor salonuna gider: ilk ziyarette sağlık artabilir. Aynı yaşta tekrar gittikçe kazanımı azalır; bir noktada o yaş için spordan **ilave sağlık kazanmaz**. Buna rağmen aileyle görüşme veya uygun bir okul etkinliği gibi **başka** faaliyetler mevcut olabilir. Bir sonraki yaşta sporun faydasının hangi düzeyde yenileneceği denge tasarımında belirlenecek.

## Ün ve sosyal medyaya geçiş
**Ün**, beş temel değerden farklı olarak **koşullu olarak açılacak** bir özellik. Her karakterin doğumunda görünür veya %100 değildir. Sosyal medyada takipçi kazanmaya başlamak, kahramanca davranış gibi görünürlük yaratan bir olay yaşamak ünü düşük başlangıç düzeyinde etkinleştirebilir. Sonraki uygun etkileşimler ünü artırabilir; bu da aynı yaşta tekrar sömürüsüne karşı etki azalması ilkesine tabidir. Ünün başlangıç miktarı, takipçi sayısı ile ilişkisi, düşme/kalıcılık ve ekran tasarımı daha sonra sosyal medya ve şöhret sisteminde ayrıntılandırılacak. **Takipçi sayısı = doğrudan %100 ün değildir.**

## Olay devamlılığı ve doğal tempo
Bir önceki yaşta sevgilisiyle anlaşmazlık yaşayan karakter, uygun koşullarda sonraki yaşta bunun devamını görebilir. Üniversite olayı yaşarken aile haberi, varsa ev/araçla ilgili sürpriz gelebilir. Sahip olunmayan varlık veya artık var olmayan kişi için uygunsuz olay çıkmaz. Ek olayları tam hangi oyun içi adımda seçeceğimiz ve kaç olay göstereceğimiz henüz belli değildir; **etkileşimlere global hak kotası koymak olay temposunu çözmenin yolu olarak kullanılmayacak**.

## Açık teknik/tasarım konuları
- Bir etkileşimin aynı yaş içindeki azalan etkisi hangi veriyle izlenecek, değerler nasıl sınırlandırılacak ve yaş değişiminde nasıl yenilenecek?
- Farklı aktiviteler aynı istatistiğe katkı verebilirken toplam statın sonsuza çıkması nasıl önlenecek? Ana stat aralıkları henüz seçilmedi.
- Olay seçimleri hangi anlamlı oyun içi ilerleme adımlarında tetiklenecek? Spam ve aynı hikâyenin tekrarını nasıl engelleyeceğiz?
- Ünün açılma koşulları, sosyal medya menüsü, takipçi sistemi ve olası diğer ün kaynakları nasıl ayrıntılandırılacak?
- İlk olay çözülünce ekran akışı, ölüm ve yeni hayata başlama nasıl olacak?

## İlerleme özeti
**Belirledik:** Karakter/aile ana hatları, Yaş Al ile serbest ilerleme, ilk tek olay ve devam hikâyeleri, oyuna bağlı aralıklı olaylar, aile sitemi, aynı faaliyette aynı yaş içinde sıfıra inen fayda, global etkileşim kotasının olmaması, koşullu Ün. **Şimdi:** Etki/veri modeli ve sosyal medya/ün sistemini ayrıntılandırmadan önce prototipte hangi sistemlerin gerekli olacağını netleştiriyoruz.
