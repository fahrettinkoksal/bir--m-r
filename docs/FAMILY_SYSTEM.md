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

## 6. Ebeveynlik — Paket BK (9 Ekim 2026)

**Yön Faho tarafından sohbette onaylandı** ("olur yap", Q-203). Aşağıdaki
**sayılar onay beklemiyor çünkü hiçbiri kalıcı kural değil**: hepsi
`prototypeOnly` ve kodda o adla duruyor. Kalıcı kural yalnızca
`DECISIONS.md`'ye Faho'nun onayıyla girer.

### Neden gerekti (ölçülen bulgu)

Oyuncunun kendi 0–18 yaşı dolu: okul kademesi, öğretmen, sınıf arkadaşı,
harçlık, kulüp. Oyuncu **ebeveyn** olunca bu zenginlik kayboluyordu.
Dosyadan ölçüldü: altı etkileşim türünün hiçbiri çocuğa özel değildi,
annene de çocuğuna da aynı liste çıkıyordu; çocuk için yapılabilecek tek
şey bir sorun açıldığında **tepki vermekti**.

### Artık ne var

| Konu | Durum |
|---|---|
| Bekleyen doğum | Üst künye durum satırı, Hayat ekranı kartı, İlişkiler ekranı kartı (BK/1). Diğer ebeveyn hayatta değilse bebek söz verilmiyor. |
| Çocuk planı | Eş/sevgili kartında açık eylem: düşünüyoruz / düşünmüyoruz / konuşmadınız. Plan **çifte** ait, kayda giriyor, korunma penceresinde hatırlatılıyor (BK/2). |
| "Çocuk yap" düğmesi | **Yok** — Faho'nun Paket 25 kararı yerinde. Plan ihtimali değiştirmiyor; gebelik hâlâ korunmadan yakınlaşmanın ihtimali. |
| Çocuğa özel eylemler | Ödevine Otur · Harçlık Ver · Hobiye Yazdır · Kural Koy (BK/3). Hedefleri çocuğun kendi kaydı: zekâ, birikim, ilgi alanları, evdeki kural. |
| Akıl vermek | `ChildAdvice` (Paket AP) motoru vardı ama **hiçbir ekrandan çağrılmıyordu**; kapı BK/3'te açıldı. |
| Yaş kademesi | Bebek 0-3 · çocuk 4-12 · ergen 13-17 · yetişkin 18+ — eşikler **D-180'den** (BK/4). Liste kademeye göre daralıyor; kademe içindeki ince koşullar (harçlık 7 yaşından, kurs 6 yaşından) eylemin kendi uygunluğunda. |
| Çocuğun yıl özeti | Yılın başındaki fotoğrafla (`ChildMark`) bugünün farkı; Hayat ekranında ve çocuğun kartında (BK/5). Yıl içinde doğan bebeğin özeti çıkmıyor. |

### Botun kapısı = oyuncunun kapısı

BK/2'ye kadar bot `GameController.haveChild()` çağırıyordu; o kapı
arayüzden **hiç** açılmıyordu. Yani bütün aile ölçümleri oyuncunun
kullanamadığı bir yoldan geçmişti (Q-201). Bot artık niyetini plana
yazıp korunmadan yakınlaşıyor. Önce/sonra (3 arketip × 100 hayat):

| Ölçü | Önce | Sonra |
|---|---|---|
| Gebelik görülen | %0,0 | %42,0 |
| Kısır ama çocuklu (family) | %11 (11/11) | %4 — hepsi tüp bebek yolu |
| Çocuklu hayat (toplam) | %58,3 | %42,0 |
| family çocuk sayısı ort. | 3,60 (medyan 4) | 2,16 (medyan 2) |
| family ilk çocuk yaşı medyanı | 23 | 27 |
| family ikiz (D-151) | %0 | %10 |
| family tüp bebek deneyen | %0 | %23 |

Gebelik, ikiz ve tüp bebek sistemleri **ilk kez** ölçüme girdi.

### 500 aile hayatı (BK/6)

eş/sevgili %99,2 · çocuklu %74,2 · gebelik %74,4 · ikiz %3,4 · tüp bebek
%15,4 · çocuk sayısı medyan 2 · en az bir çocuk eylemi %73,6 (ödev
%60,2, harçlık %58,8, hobi %54,4, kural %62,8, akıl ver %73,2) · çocuk
zekâsı medyan 69 (n=1000).

İstismar taraması (11 test) temiz: harçlık tek yönlü gider, kurs ücreti
her uğraş için tam ödeniyor, ödeve 200 kez oturmak zekâyı 100 yapmıyor,
kural okul sorununu en çok yarıya indiriyor ve arası kopuk çocukta hiç
işlemiyor, kayıt alıp vermek bir eylemi iki kez uygulamıyor.

### Onay bekleyen / açık

- **Q-204:** gebelik 55 yaşına kadar mümkün ama doğum 45'te kapalı.
  45-55 arasında gebelik yazılıyor, bebek gelmiyor. Sayıya dokunulmadı.
- **Q-205:** çocukla yakınlık medyanı 100 — tavan. Üç arketipte de aynı,
  yani doygunluk BK'nın eylemlerinden değil gündelik etkileşim
  döngüsünden geliyor.
- Etki büyüklükleri (`prototypeOnlyHomeworkIntelligence`,
  `prototypeOnlyAllowanceBySchool`, `prototypeOnlyHobbyCost`,
  `ChildRules.prototypeOnlyRelief` …) **denge kararı değil**; Faho
  onaylamadıkça kalıcı kural sayılmaz.

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
