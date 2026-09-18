# Sistemler — kararlaştırılmış ana hatlar

Bu belge **uygulanmış kodu değil tasarımı** anlatır. Teknik veri yapıları ve sayısal dengeler henüz kararlaştırılmadı.

## Karakter
Temel ve başlangıçta mevcut değerler: **dış görünüş, mutluluk, sağlık, zekâ, karizma**. Olay ve seçimler bu değerleri etkileyebilir. Puan aralığı, başlangıç değerleri ve başarı formülleri açık konudur.

**Ün — koşullu değer:** Her karakterin doğumunda otomatik görünen veya %100 başlayan bir değer değildir. Sosyal medyada takipçi elde edilmesi veya kahramanca bir davranış gibi görünürlük sağlayan bir gelişmeyle **düşük düzeyde etkinleşebilir**; uygun sonraki etkinliklerle artabilir. Sosyal medyanın ayrıntısı, takipçi sayısının Ün'e dönüşümü, başlangıç değeri ve gösterimi henüz tasarlanmadı. Ünün her zaman mevcut beş statla aynı şekilde işlem görmesi zorunlu değil.

## Doğum
İki mod: her şey rastgele veya yalnızca isim ve cinsiyeti kullanıcı belirler. Doğum şehri, ailenin gelir durumu, kardeş sayısı (sıfır olabilir), evcil hayvan ve aynı evde yaşayan geniş aile rastgele oluşturulur. Tek tip veya 'ortalama aile' kalıbı yoktur. Anne ve babanın yaşı, ilişki durumu (evli/birlikte/ayrı/boşanmış), meslekleri ve kişisel ekonomik durumları da farklı olabilir. Rastgelelik eşit olasılık anlamına gelmez; oranlar belirlenmedi. Akrabalık ve yaş gibi bilgiler çelişmemelidir.

## Aile ve hane
Anne, baba, kardeş, anneanne, babaanne, dede, teyze, hala, amca, dayı gibi akrabalar bulunabilir; her hayatta hepsi zorunlu değildir. **Aile bağı ve aynı hanede yaşama ayrı durumlardır.** Bazı aile bireyleri oyuncuyla aynı evde yaşayabilir, bazıları ayrı yaşar; aynı evde anne/baba dışındaki yakınlar da bulunabilir. Kişiler zamanla eve taşınabilir veya ayrılabilir. Oyunda **Aile** sekmesi olacak ve oyuncu aile bireylerini görebilecek; anne/baba yaşları, meslekleri ve ayrı ekonomik durumları görünür olacak. Hediye verme ve birlikte vakit geçirme gibi etkileşimler desteklenecek. Etkileşim koşulları ve görsel ayrıntılar henüz belirlenmedi. Ayrıntılı taslak: `docs/FAMILY_SYSTEM.md`.

## Yaş alma, etkinlik ve stat dengesi
Oyuncu **Yaş Al** düğmesine hazır olduğunda basar; bütün etkinlikleri bitirmesi gerekmez. **Global etkileşim sayısı/hak sınırı olmayacak.** Aynı yaşta aynı kişiyle aynı etkinlik veya spor/ders gibi aynı faydayı üreten tekrarlar ilkinde daha yüksek, ardından azalan ve sonunda **o yaş için sıfır ek olumlu etki** verir. Sıfırlanan şey etkinliğin ilgili kazancıdır; farklı etkinlikler hâlâ denenebilir, etkinliğin maliyeti ve doğal sonuçları sürebilir. Kesin azalma eğrisi, kaç tekrarda sıfır olacağı, yaş değişiminde nasıl yenileneceği henüz açık. Aile bireyi yakın tekrarı bazen reddedebilir; ret oyuncunun mutluluğunu biraz azaltabilir. Ayrıntılar: `docs/CORE_LOOP.md`.

## Olay motoru
Her olayın uygun yaş aralığı ve mevcut hayat durumuna dair önkoşulları bulunur. **Yaş Al** sonrası önce **tek bir uygun olay** gösterilir; seçimler geçmişteki hikâyeleri devam ettirebilir. Aynı yaşta aile, ilişki, okul/üniversite, ev/araç ve eklendiğinde sosyal medya gibi alanlardan **aralıklı ek olaylar** çıkabilir. Olaylar gerçek hayat dakikaları beklenerek değil **oyun içindeki ilerlemeye** göre gelir; aynı kategori/olay spam gibi yağmaz. Uzun süre aileyle oyun içinde anlamlı temas kurulmaması, uygun koşullarda bir aile bireyinin sitem olayına yol açabilir. Olayların kesin sıklığı/algoritması veya bir yaşın toplam olay sayısı henüz belirlenmedi.

## İlişkiler ve yaşayan çevre
Anne, baba, kardeş, büyükanne/büyükbaba, diğer akrabalar, arkadaş, sevgili/eş, çocuk, iş arkadaşı ve diğer önemli kişilerle bağlar ayrı takip edilecek; seçimler ve aile etkileşimleri bağları etkileyebilecek. Aile üyeleri dahil NPC'lerin kendi iş, ekonomik durum, ilişki ve hane gelişmeleri oyuncuyu etkileyebilir. NPC kişilik modeli, ilişkilerin tek mi çok boyutlu mu tutulacağı ve simülasyon sıklığı açık konudur.

## Geçmişin hafızası
Önemli seçimler yalnızca puan değişimi değildir: geçmişte arkadaşını savunmak ileride o arkadaşla bağlantılı bir fırsatın koşuluna dönüşebilir. Hafızanın veri biçimi, saklama miktarı ve olay zinciri kuralları henüz kesinleşmedi.

## Olaylar için tasarım ihtiyacı (nihai şema değil)
Her olayın tanımlanabilir kimliği, özgün metni, yaş uygunluğu, gerekli koşulları, seçenekleri, etkileri ve gerektiğinde geleceğe bırakacağı iz bulunabilmelidir. Geniş olay havuzu modüler olacak; kesin dosya biçimi ve sayısı henüz kararlaştırılmadı.
