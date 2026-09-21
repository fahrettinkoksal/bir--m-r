# İlk prototip — arayüz ve gezinme v0.3

**Durum:** Faho, prototipte **Hayat / Aile / Ben** başlangıç menüsünü, **modern + nostaljik karışımı** görsel yönü ve **sevgili edinme → ayrılma → eski sevgili olarak listede kalma** oynanabilir örneğini onayladı. Bunlar bir tasarım/kapsam kararıdır; oyun kodu veya oynanabilir prototip henüz yok. BitLife'ın özgün metin, ikon, görsel veya ekranını birebir kopyalama.

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

**Paket 8 notu (2026-09-21).** Faho'nun "menüler güncel ve renkli olsun" talimatıyla menü arayüzü yenilendi: her menü kendi rengini taşıyan degradeli ikon kutusu ve sayaç rozetiyle görünüyor, bölüm başlıklarının altında renk şeridi var, alt gezinme çubuğu degrade zemin ve seçili sekme hapı kullanıyor, düğmeler daha yuvarlak ve hafif yükseltilmiş. **Kesin palet hâlâ seçilmedi**; kullanılan renk değerleri `prototypeOnly` ve **Q-077**'de karar bekliyor. Renk hiçbir yerde tek bilgi taşıyıcısı değildir; bağ, sayı ve durum bilgisi yazıyla da verilir. Alt menü sırası (Okul/Meslek – Varlıklar – Yaş Al – İlişkiler – Aktiviteler) değişmedi.

## 3. Hayat ekranı — ilk prototip akışı (önerilen ayrıntı)
- Üst kısımda karakter adı, yaş, şehir ve kısa mevcut yaşam bilgisi; temel değerler ve hayat günlüğü.
- Ün, henüz açılmamış karakterde görünmez; açılma ve gösterim ayrıntıları başka belgede açık konudur.
- Ekranda erişilebilir **Yaş Al**; basılınca yeni yaşta **ilk olarak tek uygun olay** gelir. Sonraki olaylar oyuncunun oyun içi ilerleyişinde aralıklı çıkar, gerçek dakika beklemesi yoktur.
- Seçimlerin anlık sonuçları ve anlamlı geçmiş kararları sonraki yaşları etkileyebilir.

## 4. Aile ve romantik ilişkiler — kalıcı kişi, değişen statü
**Prototipte oynanabilir örnek zorunlu:** Yaşa ve koşullara uygun bir olay/etkileşim üzerinden bir karakterle romantik ilişki başlatılır → kişi **Aile** içinde 'Kız Arkadaş' / uygun sevgili statüsüyle görünür → oyuncunun ilişkiyi bitirebildiği ayrı bir seçim/olay olur → aynı kişi **Aile** içinde **'Eski Kız Arkadaş' / 'Eski Sevgili'** statüsünde kalır. **Kişi kaydı yeniden oluşturulmaz veya silinmez; ilişki geçmişi ve önemli seçimler korunur.** Örnek kişi adı veya kesin yaş kullanıcı tarafından belirlenmedi; hikâye özgün yazılacak ve uygun yaş/koşulda sunulacak.

**Örnek test yolu (temsili, tek zorunlu hikâye değil):** Aile → 'Ayşe — Kız Arkadaş' → kişi detayı → ayrılık seçimi → Aile → 'Ayşe — Eski Kız Arkadaş'. Bu, ayrılık sonrasında eski sevgilinin aynı evde yaşadığı, hâlâ sevgili olduğu veya sevgiliye özel eylemlerinin açık kaldığı anlamına gelmez.

Ailede ebeveyn ve geniş akrabaların önceki kuralları aynen geçerli: kişi bazlı gerçek akrabalık, ayrı hane, ebeveyn yaşı/mesleği/kendine ait ekonomik durum; hediye, vakit geçirme, doğal ret, aynı yaşta azalan etki. **Aile başlığı altında romantik kişileri göstermenin kabulü, onları kan bağı olan akraba saymak demek değildir.** Veri modelinde kişi kimliği, bağ türü, ilişki statüsü ve hane durumunu ayrı tutmak teknik öneridir, nihai şema değil.

Açık: Aile ekranında kan bağı olanlar, partnerler ve eski partnerler nasıl bölümlenecek? Eski sevgiliyle hangi etkileşimler açık olacak? Yeni partner, eş, çocuk, eski eş gibi statülerin tam kapsamı ve görünümü henüz ayrıca kararlaştırılmadı.

## 5. Ben eylem merkezi — büyüme planı
Ben → karakter özeti/değerleri ve yaşa/koşullara uygun faaliyet kategorileri. Geleceğe dönük örnekler: **Spor Salonu, Berber, Seyahat**. Bunlar zamanla gerçekten oynanabilir modüller olarak eklenecek; ilk prototipte tüm kategorileri tamamlanmış gibi sunma. Her eylemin uygunluk, maliyet ve aynı yaşta azalan getirisi genel tasarımla uyumlu olmalı; ayrıntılı ekonomi/etki dengesi henüz yok.

## 6. İlk prototip — onaylanan kapsama giren örnekler ve açık ayrıntılar
1. İki başlangıç modu ve rastgele karakter/aile, Hayat / Aile / Ben gezinmesi, aile bilgileri, karakter değerleri ve hayat günlüğü önceki tasarımda bulunur; prototipteki veri derinliği ayrıca planlanacak.
2. Aileden en az bir etkileşimin olumlu etkisini ve yakın tekrarda azalan etki / olası ret davranışını çalışır durumda göstermek hedeflenir.
3. **Yaş Al → ilk tek uygun olay → seçim → geçmişe bağlı uygun devam** akışı prototipin temel oyun döngüsüdür.
4. **YENİ KESİN KAPSAM:** Oyuncunun uygun koşulda bir sevgili edinip Aile listesinde görmesi, sonra ayrılık kararı verebilmesi ve **aynı kişinin eski sevgili statüsüyle listede kalması** çalışır örnek olarak prototipe dahil edilir. Yalnızca sahte ekran veya geleceğe bırakılmış veri alanı yeterli değildir.
5. Oyun içi ilerlemeye bağlı aralıklı ek olay ve aileyle uzun süre temas yoksa sitem örneğinin ilk teknik sürümde ne derinlikte bulunacağı hâlâ açık.
6. Tam Sosyal/Ün, spor salonu/berber/seyahat içeriklerinin tamamı, geniş etkinlik havuzu ve ekonomi ilk prototip için zorunlu değildir; ileriki modüller olarak planlanır.

## 7. Doğrulama ve sıradaki iş
- Üç sekme çalışır, ek menüler için mimari büyüyebilir; henüz işlevsiz modüller aktifmiş gibi görünmez.
- Bir kişi sevgiliyken eski sevgiliye geçtiğinde **kişi kimliği, tanışıklık ve geçmiş hikâye bilgisi korunur**; güncel statü değişir, diğer ilişkilerle karışmaz.
- Ayrı hane/akrabalık/romantik bağlar birbirine karıştırılmaz; olmayan kişi canlı etkileşimde gösterilmez.
- Yaş Al bir yaşı ilerletir, ilk olay tek başına gösterilir; tekrar etkileşimleri sonsuz stat kazandırmaz.
- **Sıradaki iş:** Claude'a verilecek ilk prototip geliştirme görevini küçük, sınanabilir aşamalara ve kabul kriterlerine ayırmak. Teknik yığın, somut örnek olay metinleri, tasarım renkleri ve kapsamın diğer derinlikleri ayrıca netleştirilecek.
