# Aile sistemi taslağı — v0.2

**Durum:** Kararlaştırılmış aile kuralları ile henüz çözülmemiş teknik ayrıntılar ayrı tutulur. Oyun kodu yazılmadı. Kesin kararların kısa kaydı `DECISIONS.md` içindedir.

## Neredeyiz?
**Ana hatlarını tasarladık:** Türkiye odaklı nostaljik + modern yaşam hissi, iki modlu rastgele doğum, beş karakter değeri, ilişkiler, karar hafızası, yaşa/koşullara uygun olaylar. **Şimdi aile sistemini planlıyoruz:** aile üyeleri ve haneler, aile sekmesi, birlikte etkinlikler ve aile bireylerinin bağımsız hayatları. Eğitim, kariyer, ekonomi ve geniş olay havuzu ileride ayrıntılanacak; henüz oynanabilir oyun yok.

## 1. Kesinleşen kurallar: başlangıç aileleri tamamen rastgele
- Oyuncu tamamen rastgele başlayabilir veya yalnızca **isim ve cinsiyetini** seçebilir; diğer başlangıç koşullarını kendisi belirleyemez.
- Ailenin tek bir 'ortalama' kalıbı yoktur. Çok varlıklı / çok yoksul ya da ara düzeylerde olabilir. Aile bireylerinin ekonomik durumları **aynı olmak zorunda değildir**: anne varlıklı, baba yoksul olabilir ya da tersi.
- Anne ve babanın **yaşları rastgele** belirlenir; genç anne/yaşlı baba ya da başka yaş farkları mümkün olabilir. Yaşlar bir örnek aile şablonuna sabitlenmez.
- Anne-baba birlikte, evli, ayrı ya da boşanmış olabilir; ilişki durumları hayat içinde de değişebilir. Her aileyi zorunlu olarak aynı çatı altında yaşayan evli anne-baba modeliyle kurma.
- Kardeş sayısı sıfır ya da çok olabilir. Evcil hayvan bulunabilir veya bulunmayabilir. Doğum şehri rastgeledir.
- Çekirdek aileyle sınırlı kalma: anneanne, babaanne, dedeler, teyze, hala, amca, dayı gibi **geniş aile bireyleri bulunabilir**. Her hayatın bütün akrabalara sahip olması şart değildir; kişi sayısı ve mevcut kişiler rastgele değişir.
- **Akrabalık bağı ile aynı evde yaşamak farklıdır.** Herkesin aynı evde yaşadığı varsayılmaz; ancak anne/baba, büyükler ve uygun durumlarda teyze, hala, amca veya dayı da aynı hanede yaşayabilir. Kimin nerede yaşadığı başlangıçta rastgele belirlenebilir, ileride olaylarla değişebilir.
- Rastgelelik tutarlılık gerektirir: var olmayan akrabayla olay çıkmaz, başka evdeki bir kişi evin daimi sakini gibi yazılmaz, ölmüş karakter yaşayan kişi etkileşimi sunmaz. **Yaş, akrabalık, hane ve olay koşulları birbirleriyle uyumlu** olmalı. Rastgele olmak her olasılığın eşit ağırlıklı olacağı anlamına gelmez; oranlar henüz belirlenmedi.

## 2. Kesinleşen kurallar: aile sekmesi ve etkileşimler
Oyunda ayrı bir **Aile** sekmesi olacak. Oyuncu aile bireylerini bu sekmede ayrı ayrı görebilecek. Anne ve babanın **yaşları, meslekleri ve kendilerine ait ekonomik durumları** görünür olmalı; diğer üyeler için gösterilecek ayrıntı seviyesi henüz net değil. Mesleği olmayan kişinin mesleği uydurulmaz; işsiz/emekli vb. durumların gösterimi tasarlanacak.

Oyuncu aile bireyleriyle etkileşim kurabilecek: **hediye vermek, birlikte vakit geçirmek** ve bunlara uygun başka aile etkileşimleri. Karar ve etkileşimler karakter değerlerini ve ilgili kişiyle ilişkiyi etkileyebilir. Etkinlikler oyuncunun yaşına, parasına/erişimine, kişinin yaşayıp yaşamadığına ve gerçek ilişki/hane koşullarına uygun olmalı. Hediye türleri, fiyatları, ilişki puanları ve kullanım sıklığı henüz belirlenmedi.

## 3. Kesinleşen kurallar: aile de yaşar
Anne, baba ve diğer aile bireyleri oyuncudan bağımsız gelişmeler yaşayabilir. Meslek değiştirme, işten çıkarılma, maddi durum değişimi, ilişki değişimi, ayrılık/boşanma, bir akrabanın eve taşınması veya evden ayrılması, hastalık ve ölüm gibi olaylar **uygun karakter ve koşullarda** gerçekleşebilir; oyuncunun evini, bütçesini, ilişkilerini ve olay seçeneklerini etkileyebilir. Bunlar mümkün olay türleridir; her hayat için zorunlu bir senaryo değildir.

### Özgün olay örnekleri (onaylanmış tekil olaylar değil)
- Aynı evde yaşayan babaanne, oyuncuya eski bir aile fotoğrafını gösterir; birlikte vakit geçirmek ilişkinizi etkiler.
- Ayrı yaşayan babanla hafta sonu buluşması gündeme gelir; ulaşım ve mevcut ilişkiniz seçenekleri belirler.
- Teyzen geçici olarak eve taşınır; hane üyeleri ve gündelik olay havuzu değişir.
- İşini kaybeden annen yeni bir mesleğe yönelir; bu gelişme hanenin koşullarını etkileyebilir.
- Bayramda aile ziyareti, ziyaret edilebilen akrabalar ve oyuncunun yaşına göre farklılaşır.

## 4. Claude'a aktarılacak önerilen veri yaklaşımı — HENÜZ ONAYLANMADI
Her önemli aile bireyini kalıcı bir kişi kimliğiyle tutmak; akrabalığı, yaşı, meslek/çalışma durumunu, kendine ait ekonomik kaynaklarını, ilişki durumunu, yaşayıp yaşamadığını ve mevcut hanesini ayrı alanlarda yönetmek mantıklı görünüyor. Oyuncu–kişi ilişki verisi, kişi verisinden ayrı tutulabilir. Aile sekmesi ve ev içi olaylar **aynı veri kaynağını** kullanmalı. Kesin veri şeması ve algoritma henüz tasarlanmadı; Claude bunları onaylanmış teknik karar gibi uygulamamalı.

## 5. Açık sorular — bizimle tartışılacak
1. Aile sekmesinde her akraba için hangi bilgiler (meslek, yaş, ilişki, maddi durum, aynı evde mi vb.) gösterilecek? Anne-baba için yaş, meslek ve ayrı ekonomik durum kesin.
2. Çocuk doğduğunda anne/baba dışında bakım veren ilişkileri ve ayrı yaşama nasıl modellenir?
3. Yaş, ebeveyn–çocuk bağı ve nesiller için hangi **tutarlılık kısıtları** konur? Sabit 'ortalama aile' yapılmayacak.
4. Kişisel servet, hane bütçesi ve çocuğun kullanabileceği para nasıl ayrılır?
5. Aile etkileşimlerinin sayısı, bedeli, erişilebilirlik koşulları ve tekrar sınırları nasıl belirlenir?
6. NPC'lerin evlilik/boşanma, iş, taşınma ve ölüm olaylarının olasılık ve sıklığı nasıl ayarlanır?
7. Aile sekmesinin görsel düzeni ve akrabaları gruplandırma yöntemi nasıl olacak?

## Sonraki adım
Aile sekmesinde her akraba için gösterilecek temel bilgiler ile rastgele aile üretiminde gerekli tutarlılık kurallarını netleştirelim; ardından aile etkileşimleri ve olay verisi şemasına geçelim. Yeni onaylanan ayrıntılar `DECISIONS.md` ve `SYSTEMS.md` içine işlenecek; belirsiz ayrıntılar açık kalacak.
