# Sistemler — kararlaştırılmış ana hatlar

Bu belge **uygulanmış kodu değil tasarımı** anlatır. Teknik veri yapıları ve sayısal dengeler henüz kararlaştırılmadı.

## Karakter
Temel değerler: dış görünüş, mutluluk, sağlık, zekâ, karizma. Olay ve seçimler bu değerleri etkileyebilir. Puan aralığı, başlangıç değerleri ve başarı formülleri açık konudur.

## Doğum
İki mod: her şey rastgele veya yalnızca isim ve cinsiyeti kullanıcı belirler. Doğum şehri, ailenin gelir durumu, kardeş sayısı (sıfır olabilir), evcil hayvan ve aynı evde yaşayan geniş aile rastgele oluşturulur. Rastgelelik eşit olasılık anlamına gelmez; oranlar ve aile üretim kuralları henüz belirlenmedi.

## Yaş alma ve olaylar
Oyuncu doğar ve yaşı ilerler. Her olayın uygun yaş aralığı ve mevcut hayat durumuna dair önkoşulları bulunur. Önce uygunluk kontrol edilir, sonra uygun olaylar arasından seçim yapılır; seçim yöntemi ve yılda kaç olay olacağı açık konudur. Çocukluk olayları 30+ yaşta uygunsuz şekilde görünmez. Bazı temalar farklı yaşlarda ayrı bağlamlarla yeniden kullanılabilir: okul gezisine öğrenci olarak katılmak ile çocuğunun gezi iznini imzalamak farklı olaylardır. Olay havuzu nostaljik ve modern deneyimleri tarih filtresi olmaksızın harmanlar.

## İlişkiler ve yaşayan çevre
Anne, baba, kardeş, büyükanne/büyükbaba, arkadaş, sevgili/eş, çocuk, iş arkadaşı ve diğer önemli kişilerle bağlar ayrı tutulabilir. Seçimler bu bağları etkileyebilir. Aile üyeleri dahil NPC'lerin kendi yaşam gelişmeleri oyuncuyu etkiler. NPC kişilik modeli, ilişkilerin tek mi çok boyutlu mu tutulacağı ve simülasyon sıklığı henüz açık konudur; `docs/FAMILY_SYSTEM.md` taslaktır.

## Geçmişin hafızası
Önemli seçimler yalnızca puan değişimi değildir: geçmişte arkadaşını savunmak ileride o arkadaşla bağlantılı bir fırsatın koşuluna dönüşebilir. Hafızanın veri biçimi, saklama miktarı ve olay zinciri kuralları henüz kesinleşmedi.

## Olaylar için tasarım ihtiyacı (nihai şema değil)
Her olayın tanımlanabilir kimliği, özgün metni, yaş uygunluğu, gerekli koşulları, seçenekleri, etkileri ve gerektiğinde geleceğe bırakacağı iz bulunabilmelidir. Binlerce olay hedefi nedeniyle içerik modüler olacak; ancak kesin dosya biçimi ve sayısı henüz kararlaştırılmadı.
