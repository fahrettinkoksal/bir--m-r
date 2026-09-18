# Aile sistemi taslağı — v0.3

**Durum:** Kararlaştırılmış aile kuralları ile açık teknik ayrıntılar ayrı tutulur. Oyun kodu henüz yazılmadı. Kesin kararların kaydı `DECISIONS.md` içindedir.

## Neredeyiz?
**Ana hatlarını tasarladık:** Türkiye odaklı nostaljik + modern yaşam hissi, iki modlu rastgele doğum, beş karakter değeri, ilişkiler, karar hafızası, yaşa/koşullara uygun olaylar. **Aile için netleştirdik:** rastgele aile çeşitliliği, ayrı haneler, Aile sekmesi, birlikte vakit geçirme/hediye ve aile etkilerinin karakter değerlerini değiştirebilmesi. **Şimdi:** etkileşim dengesi ve yaş alırken olay sunumu. Eğitim, kariyer, ekonomi ve geniş olay havuzu daha sonra ayrıntılanacak; henüz oynanabilir oyun yok.

## 1. Kesinleşen kurallar: başlangıç aileleri tamamen rastgele
- Oyuncu tamamen rastgele başlayabilir veya yalnızca **isim ve cinsiyetini** seçebilir; diğer başlangıç koşullarını kendisi belirleyemez.
- Ailenin tek bir 'ortalama' kalıbı yoktur. Çok varlıklı / çok yoksul ya da ara düzeylerde olabilir. Anne varlıklı, baba yoksul olabilir ya da tersi; kişilerin ekonomik durumları farklı olabilir.
- Anne ve babanın **yaşları rastgele** belirlenir; genç anne/yaşlı baba gibi yaş farkları mümkündür. Anne-baba birlikte, evli, ayrı ya da boşanmış olabilir; durumları hayat içinde değişebilir.
- Kardeş sayısı sıfır ya da çok olabilir. Evcil hayvan bulunabilir veya bulunmayabilir. Doğum şehri rastgeledir.
- Anneanne, babaanne, dedeler, teyze, hala, amca, dayı gibi **geniş aile bireyleri** rastgele bulunabilir; her hayatın bütün akrabalara sahip olması gerekmez.
- **Akrabalık bağı ile aynı evde yaşamak farklıdır.** Herkes aynı hanede değildir; uygun durumlarda anne/baba, büyükler ve teyze, hala, amca veya dayı aynı hanede yaşayabilir. Hane olaylarla değişebilir.
- Rastgele sonuçlar tutarlı olmalı: var olmayan akraba, yaşamayan kişi veya başka evdeki kişi için yanlış bağlamda etkileşim çıkmaz. Rastgelelik tüm ihtimallerin eşit ağırlıkta olduğu anlamına gelmez; oranlar belirlenmedi.

## 2. Kesinleşen kurallar: Aile sekmesi ve karşılıklı etkileşimler
Oyunda ayrı bir **Aile** sekmesi vardır. Oyuncu aile bireylerini ayrı ayrı görür. Anne ve babanın yaşları, meslekleri ve kendilerine ait ekonomik durumları görünür; diğer bireylerin ayrıntı seviyesi açık konudur. İşsiz/emekli kişiye uydurma meslek gösterilmez.

Oyuncu aile bireylerine **hediye verebilir, onlarla vakit geçirebilir** ve uygun başka etkileşimler yapabilir. Aile bireylerinin oyuncuya davranışları ve karşılıklı etkileşimler hem ilgili ilişkiyi hem ana karakterin uygun değerlerini etkileyebilir. Oyuncunun yaşı, maddi imkânı, karşı tarafın hayatta olması, ulaşılabilirliği ve yaşam koşulları dikkate alınır.

### Kesin karar: tekrarın etkisi azalır, bazen ret gelir
- Oyuncu aynı aile bireyiyle aynı tür olumlu etkileşimi art arda tekrarlarsa **sağladığı olumlu etki giderek azalır**; sınırsız değer kasılamaz.
- Örneğin **Aile → Anne → Vakit Geçir** seçilir. Olası bir sonuç: 'Annenle sinemaya gittin, ardından sohbet edip dertleştiniz.' Bu etkinlik uygun karakter değerlerini ve anneyle ilişkiyi etkileyebilir.
- Oyuncu hemen yeniden **Vakit Geçir** isterse anne **bazen** 'Daha yeni vakit geçirdik' diyerek reddedebilir; her tekrarda otomatik ret uygulanmaz.
- Ret olursa oyuncunun **mutluluğu biraz azalabilir**. Reddedilen etkinlik, başarılı etkinlik gibi tam olumlu ödül vermez.
- Azalma eğrisi, ret ihtimali, ne kadar zaman sonra tekrar normal getiri olacağı, mutluluk kaybı ve bu davranışın diğer aile etkileşimlerine uyarlanması **henüz rakamsal veya teknik olarak kararlaştırılmadı**. Yaş başına sabit etkileşim kotası da onaylanmadı.

## 3. Kesinleşen kurallar: aile de yaşar
Anne, baba ve diğer aile bireyleri oyuncudan bağımsız gelişmeler yaşayabilir. Meslek değiştirme, işten çıkarılma, ekonomik/ilişki durumu değişimi, ayrılık/boşanma, eve taşınma, evden ayrılma, hastalık ve ölüm gibi olaylar uygun koşullarda oyuncunun evini, bütçesini, ilişkilerini ve olay seçeneklerini etkileyebilir. Her yaşamda her olayın olması zorunlu değildir.

### Özgün olay örnekleri (onaylanmış tekil olaylar değil)
- Aynı evde yaşayan babaanne, eski bir aile fotoğrafını gösterir.
- Ayrı yaşayan babanla hafta sonu buluşması gündeme gelir.
- Teyzen geçici olarak eve taşınır; hane üyeleri değişir.
- İşini kaybeden annen yeni bir mesleğe yönelir.
- Bayram ziyareti, oyuncunun yaşına ve mevcut akrabalarına göre değişir.

## 4. Claude'a aktarılacak önerilen veri yaklaşımı — HENÜZ ONAYLANMADI
Her aile bireyinin kalıcı kişi kimliği, akrabalık bağı, yaşı, mesleği/çalışma durumu, kendi ekonomik kaynakları, ilişki durumu, yaşam durumu ve hanesi ayrı tutulabilir. Oyuncu–kişi ilişki verisi ve **kişi + etkileşim türü için yakın geçmiş** de ayrı izlenebilir; böylece anneyle zaman geçirmek babayla zaman geçirmekle karışmaz. Aile sekmesi ve olay motoru aynı kişilerin tutarlı durumunu kullanmalı. Kesin veri şeması, formüller ve eşik değerleri belirlenmedi.

## 5. Açık sorular
1. Aile sekmesinde diğer akrabalar için hangi bilgiler gösterilecek?
2. Çocuk doğduğunda ebeveyn dışındaki bakım verenler nasıl modellenir?
3. Yaş, ebeveyn–çocuk ilişkisi ve nesiller için tutarlılık kısıtları ne olur?
4. Kişisel servet, hane bütçesi ve çocuğun kullanabildiği para nasıl ayrılır?
5. Tekrar geçmişi ne zaman sıfırlanır/azalır; ret şansı, azalan etki ve küçük mutluluk kaybı nasıl dengelenir?
6. NPC'lerin evlilik, boşanma, iş, taşınma ve ölüm olaylarının sıklığı nasıl ayarlanır?
7. Aile sekmesinin görsel düzeni nasıl olur?

## Sonraki adım
`docs/CORE_LOOP.md` içindeki **Yaş Al sonrası olayların sunumu** netleşsin. Sonra aile sekmesinin gösterilecek alanları ve olay/etkileşim verisi şemasına geçelim; onaylanan kuralları `DECISIONS.md` içinde tutalım.
