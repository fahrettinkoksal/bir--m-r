# İlk prototip — arayüz ve gezinme v0.2

**Durum:** Faho, prototip için **Hayat / Aile / Ben** başlangıç menüsünü ve **modern + nostaljik karışımı** görsel yönü onayladı. Bu üç sekme nihai menü sınırı DEĞİL: oyun geliştikçe yeni sekmeler (özellikle Sosyal) ve Ben altındaki eylemler eklenecek. Romantik ilişkilerin eski partnerler dahil geçmişi korunacak. Yerleşimin piksel düzeyindeki ayrıntıları, renk kodları ve prototipin teknik kapsamı henüz onaylanmadı; oyun kodu/oynanabilir prototip yok. BitLife'ın özgün metin, ikon, görsel veya ekranını birebir kopyalama.

## 1. Onaylanmış navigasyon ilkesi
- **İlk prototip alt menüsü: Hayat / Aile / Ben.** Bunlar ilk sürüm için bir başlangıç düzenidir; ileride yalnızca üç sekmeyle sınırlı kalmayacak.
- **Hayat:** ana yaşam ekranı, yaş, değerler, olaylar, yaşam günlüğü ve belirgin **Yaş Al** eylemi.
- **Aile:** aile bireyleri ve ilişkilerin görüldüğü bölüm. Oyuncu sevgili/kız arkadaş edindiğinde kişi burada görünür. Ayrılık yaşanırsa kişi listeden silinmez; **Eski Sevgili / Eski Kız Arkadaş** gibi güncel ilişki statüsüyle görülmeye devam eder. Bu bir ilişki geçmişidir; eski partnerin hâlâ oyuncunun hanesinde yaşadığı veya sevgili etkileşimlerine eriştiği varsayılmaz. Aynı kişinin kaydı korunur, statüsü değişir. Diğer romantik ilişki türleri, kişi grupları ve ekran gruplandırması daha sonra ayrıntılanacak.
- **Ben:** yalnızca özellik/istatistik sayfası değildir; karakterin yapabileceği pek çok **eylemin merkezi** olacak. İleride spor salonu, berber, seyahat gibi faaliyetler burada yer alacak. İlk prototipte henüz çalışmayan faaliyetler sahte tıklanabilir düğme olarak gösterilmez; modüler alanlar genişletilebilir tasarlanır.
- **Sosyal:** ilerleyen geliştirme aşamasında menüye eklenecek; sosyal medya/ilişkili içerik burada ayrıntılanacak. Sosyal medya içerikleriyle Ün özelliğinin nasıl açıldığı ve ilerlediği ayrı tasarım konusu. Başlangıç prototipinde tam Sosyal menüsü zorunlu değil.
- Yeni bölümler için alt çubukta kaç simge olacağı, taşan sekmelerin 'Daha Fazla' altında mı gruplanacağı veya farklı bir gezinme çözümü mü kullanılacağı **henüz kararlaştırılmadı**. Prototip navigasyonu, yeni modüller eklenince baştan yazılması gerekmeyecek biçimde kurulmalı.

## 2. Onaylanmış görsel yön: modern + nostaljik
- Dikey, tek elle erişilebilir, sade ve çağdaş mobil arayüz; okunaklı Türkçe metinler ve belirgin eylem butonları.
- Türkiye'deki yaşama dair **özgün, ölçülü nostaljik dokunuşlar**: örneğin hayat günlüğünün bir hatıra defteri hissi veya sıcak küçük doku/ikon detayları. Bunlar tasarım önerisidir; belirli renk, font, defter dokusu veya ikon paketi henüz seçilmedi.
- Esas kullanım sade kalmalı; yoğun nostaljik süsleme olay metninin okunurluğunu ve gezinmeyi bozmamalı.
- BitLife'a benzer anlaşılır yaşam simülasyonu bilgi mimarisinden yararlan; marka kimliği, ekran çizimi ve içerik **Bir Ömür'e özgün** olsun.

## 3. Hayat ekranı — ilk prototip akışı (önerilen ayrıntı)
- Üst kısımda karakter adı, yaş, şehir ve kısa mevcut yaşam bilgisi; temel değerler ve hayat günlüğü.
- Ün, henüz açılmamış karakterde görünmez; açılma ve gösterim ayrıntıları başka belgede açık konudur.
- Ekranda erişilebilir **Yaş Al**; basılınca yeni yaşta **ilk olarak tek uygun olay** gelir. Sonraki olaylar oyuncunun oyun içi ilerleyişinde aralıklı çıkar, gerçek dakika beklemesi yoktur.
- Seçimlerin anlık sonuçları ve anlamlı geçmiş kararları sonraki yaşları etkileyebilir.

## 4. Aile ve romantik ilişkiler — kalıcı kişi, değişen statü
Örnek akış: Aile → 'Ayşe — Kız Arkadaş' → ilişkinin detayları → ayrılık olayı/seçimi → **aynı Ayşe kaydı**, Aile içinde 'Ayşe — Eski Kız Arkadaş' olarak kalır. Ayrılık, kişiyi yok etmez veya tanışıklık/hikâye hafızasını silmez. Mevcut ilişki ile geçmiş romantik bağ ayrı anlamlar taşır; geçmişte yaşanan olaylar ileriki uygun hikâyelerde kullanılabilir.

Ailede ebeveyn ve geniş akrabaların önceki kuralları aynen geçerli: kişi bazlı gerçek akrabalık, ayrı hane, ebeveyn yaşı/mesleği/kendine ait ekonomik durum; hediye, vakit geçirme, doğal ret, aynı yaşta azalan etki. **Aile başlığı altında romantik kişileri göstermenin kabulü, onları kan bağı olan akraba saymak demek değildir.** Veri modelinde kişi kimliği, bağ türü, ilişki statüsü ve hane durumu ayrı tutulması **teknik öneridir, nihai şema değil**.

Açık: Aile ekranında kan bağı olanlar, partnerler ve eski partnerler nasıl bölümlenecek? Eski sevgiliyle hangi etkileşimler açık olacak? Yeni partner, eş, çocuk, eski eş gibi statülerin tam kapsamı ve görünümü henüz ayrıca kararlaştırılmadı.

## 5. Ben eylem merkezi — büyüme planı
Ben → karakter özeti/değerleri ve yaşa/koşullara uygun faaliyet kategorileri. Geleceğe dönük örnekler: **Spor Salonu, Berber, Seyahat**. Bunlar zamanla gerçekten oynanabilir modüller olarak eklenecek; ilk prototipte tüm kategorileri tamamlanmış gibi sunma. Her eylemin uygunluk, maliyet ve aynı yaşta azalan getirisi genel tasarımla uyumlu olmalı; ayrıntılı ekonomi/etki dengesi henüz yok.

## 6. İlk prototip için önerilen ekran akışı — kapsam ayrıca onaylanacak
1. İki başlangıç modu → rastgele karakter ve kendi içinde tutarlı aile.
2. **Hayat / Aile / Ben** arasında çalışır gezinme. Hayat'ta günlük ve Yaş Al; Aile'de kişi listesi/detayı ve en az bir işleyen etkileşim; Ben'de karakter bilgileri ve yalnızca gerçek işleyen eylemler.
3. Anneyle vakit geçirme → sonuç/etki → tekrarda azalan etki veya bağlamsal ret.
4. Yaş Al → tek açılış olayı → seçim → sonraki yaşta uygun devamı gösterilebilen küçük özgün hikâye.
5. Kalıcı romantik kişi ve 'eski sevgili' statüsü için **ilk prototipte örnek akış bulunup bulunmayacağı ayrıca netleşecek**; mimari bunu sonradan eklemeyi engellememeli.
6. Tam Sosyal/Ün, spor salonu/berber/seyahat içeriklerinin tamamı, geniş etkinlik havuzu ve ekonomi ilk prototip için henüz onaylanmış zorunluluk değildir; sonraki modüller olarak planlanır.

## 7. Doğrulama ve sonraki karar
- Sekmeler büyümeye uygun; açılmamış modül butonları aldatıcı biçimde aktif değil.
- Bir kişi sevgiliyken eski sevgiliye geçtiğinde aynı kişiye ait tarihçe kaybolmuyor; mevcut statü doğru gösteriliyor.
- Ayrı hane/akrabalık/romantik bağlar birbirine karıştırılmıyor; olmayan kişi canlı etkileşimde gösterilmiyor.
- Yaş Al ilk tek olayı gösteriyor; tekrar etkileşimleri sonsuz stat kazandırmıyor.
- **Sıradaki ürün kararı:** Prototipte romantik ilişki kurma/ayrılık gösteren küçük bir örnek zincir de yer alsın mı, yoksa veri/ekran yapısı hazırlanıp ilk oynanabilir akış sadece aileyle mi başlasın? Bu tercih henüz belirlenmedi.
