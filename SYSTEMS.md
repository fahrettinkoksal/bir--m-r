# Sistemler — kararlaştırılmış ana hatlar

Bu belge **uygulanmış kodu değil tasarımı** anlatır. Teknik veri yapıları ve sayısal dengeler henüz kararlaştırılmadı.

## Karakter
Temel değerler: dış görünüş, mutluluk, sağlık, zekâ, karizma. Olay ve seçimler bu değerleri etkileyebilir. Puan aralığı, başlangıç değerleri ve başarı formülleri açık konudur.

## Doğum
İki mod: her şey rastgele veya yalnızca isim ve cinsiyeti kullanıcı belirler. Doğum şehri, ailenin gelir durumu, kardeş sayısı (sıfır olabilir), evcil hayvan ve aynı evde yaşayan geniş aile rastgele oluşturulur. Tek tip veya 'ortalama aile' kalıbı yoktur. Anne ve babanın yaşı, ilişki durumu (evli/birlikte/ayrı/boşanmış), meslekleri ve kişisel ekonomik durumları da farklı olabilir. Rastgelelik eşit olasılık anlamına gelmez; oranlar belirlenmedi. Akrabalık ve yaş gibi bilgiler çelişmemelidir.

## Aile ve hane
Anne, baba, kardeş, anneanne, babaanne, dede, teyze, hala, amca, dayı gibi akrabalar bulunabilir; her hayatta hepsi zorunlu değildir. **Aile bağı ve aynı hanede yaşama ayrı durumlardır.** Bazı aile bireyleri oyuncuyla aynı evde yaşayabilir, bazıları ayrı yaşar; aynı evde anne/baba dışındaki yakınlar da bulunabilir. Kişiler zamanla eve taşınabilir veya ayrılabilir. Oyunda **Aile** sekmesi olacak ve oyuncu aile bireylerini görebilecek; anne/baba yaşları, meslekleri ve ayrı ekonomik durumları görünür olacak. Hediye verme ve birlikte vakit geçirme gibi etkileşimler desteklenecek. Etkileşim koşulları ve görsel ayrıntılar henüz belirlenmedi. Ayrıntılı taslak: `docs/FAMILY_SYSTEM.md`.

## Yaş alma ve olaylar
Oyuncu doğar ve yaşı ilerler. Her olayın uygun yaş aralığı ve mevcut hayat durumuna dair önkoşulları bulunur. Önce uygunluk kontrol edilir, sonra uygun olaylar arasından seçim yapılır; seçim yöntemi ve yılda kaç olay olacağı açık konudur. Çocukluk olayları 30+ yaşta uygunsuz şekilde görünmez. Bazı temalar farklı yaşlarda ayrı bağlamlarla yeniden kullanılabilir: okul gezisine öğrenci olarak katılmak ile çocuğunun gezi iznini imzalamak farklı olaylardır. Olay havuzu nostaljik ve modern deneyimleri tarih filtresi olmaksızın harmanlar.

## İlişkiler ve yaşayan çevre
Anne, baba, kardeş, büyükanne/büyükbaba, diğer akrabalar, arkadaş, sevgili/eş, çocuk, iş arkadaşı ve diğer önemli kişilerle bağlar ayrı takip edilecek; seçimler ve aile etkileşimleri bağları etkileyebilecek. Aile üyeleri dahil NPC'lerin kendi iş, ekonomik durum, ilişki ve hane gelişmeleri oyuncuyu etkileyebilir. NPC kişilik modeli, ilişkilerin tek mi çok boyutlu mu tutulacağı ve simülasyon sıklığı açık konudur.

## Geçmişin hafızası
Önemli seçimler yalnızca puan değişimi değildir: geçmişte arkadaşını savunmak ileride o arkadaşla bağlantılı bir fırsatın koşuluna dönüşebilir. Hafızanın veri biçimi, saklama miktarı ve olay zinciri kuralları henüz kesinleşmedi.

## Olaylar için tasarım ihtiyacı (nihai şema değil)
Her olayın tanımlanabilir kimliği, özgün metni, yaş uygunluğu, gerekli koşulları, seçenekleri, etkileri ve gerektiğinde geleceğe bırakacağı iz bulunabilmelidir. Binlerce olay hedefi nedeniyle içerik modüler olacak; ancak kesin dosya biçimi ve sayısı henüz kararlaştırılmadı.
