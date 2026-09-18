# Genel oyun döngüsü — v0.4

**Durum:** Faho tarafından onaylanmış akış kuralları aşağıdadır; teknik seçim yöntemleri, sayılar ve aralıkların uzunluğu henüz belirlenmedi. Henüz oyun kodu veya oynanabilir prototip yok.

## 1. Kesinleşen ana döngü
1. Oyuncu bulunduğu yaşta, koşullarına uygun serbest etkileşimleri (ör. Aile → Anne → Vakit Geçir) kendi isteğiyle yapar.
2. Hazır olduğunda **Yaş Al** butonuna basar; bir sonraki yaşa geçer. Bir yaştaki bütün etkinlikleri tamamlamak zorunda değildir.
3. **Yaş alındığında ilk olarak oyuncunun karşısına tek bir uygun olay çıkar.** Bir anda peş peşe bağımsız olay pencereleri yağdırılmaz.
4. Oyuncunun o olayda verdiği seçim, sonucu belirler ve **bir hikâye zincirinin devamını** açabilir. Devam olayı o anda veya sonraki uygun bir zamanda/yaşta ortaya çıkabilir; her seçim zorunlu olarak yeni bir pencere açmaz.
5. Yeni yaşta oyun devam ederken uygun yeni olaylar **aralıklarla** görünebilir. Olaylar birbiriyle bağlantılı olabilecekleri gibi oyuncunun başka bir yaşam alanından da gelebilir (aile, okul/üniversite, ilişki, ev, araç, sosyal medya vb.). Aynı anda sürekli olay çıkarıp oyuncuyu spam'e boğmayacağız.
6. Önemli seçimler, ilgili kişi ve hikâye durumları, karakter değerleri ve varsa maddi/yaşam koşulları sonraki yaşlara taşınır. Olay uygunluğu yaş, mevcut durum ve geçmişe göre kontrol edilir.

**Bir yaşta toplam yalnızca bir olay olur kararı ALINMADI:** Tek olay, **Yaş Al'a basılınca çıkan ilk olay** içindir; yaşam ilerledikçe uygun ve aralıklı ek olaylar gelebilir. Olaylar sadece Yaş Al düğmesine basıldığında çıkmak zorunda değildir. Gerçek zamanlı bekleme, dakikalık bildirim, olay sayısı veya belirli saniye/yıl aralığı kararlaştırılmadı.

## 2. Önceki yaşın hikâyesi sonraki yaşta devam eder
Geçen yaşta sevgilisiyle sorun yaşayan karakter, yeni yaşında o durumun devamını görebilir. Bir önceki yaşta okulda başlattığı olay da sonraki yaşa taşınabilir. Oyun eski kararları unutmaz; devam olayları **yalnızca hâlâ geçerli koşullarda** çıkar. Örneğin sevgilisiyle ilgili devam için ilişki hâlâ mevcutsa o bağlam kullanılır; ayrılmışlarsa ayrılık sonrası farklı devam yazılabilir. Okuldan ayrılmış karaktere hâlâ o okulun öğrencisiymiş gibi etkinlik gösterilmez.

**Öncelik kuralı:** Devamı bekleyen bir hikâye yeni yaşta açılan ilk olayın adayı olabilir; ancak her yaşta mutlaka devam olayı gösterilmesi veya devamların kesin öncelik oranı henüz belirlenmedi. Birden fazla hikâye aynı anda açık kalabilir; olay motoru uygunluk ve tempo gözetir.

## 3. Farklı yaşam alanlarından doğal kesişmeler
22 yaşındaki, üniversite okumaya devam eden oyuncu arkadaşlarıyla ilgili olaylar yaşarken daha sonra ailesiyle ilgili bir haber alabilir. Koşulları uygunsa evini su basması, sahip olduğu aracın çalınması gibi beklenmedik olaylarla karşılaşabilir. Sosyal medya sistemi eklendiğinde oradan da olaylar gelebilir.

**Tutarlılık zorunlu:** Evi olmayanın *kendi evi* su basmış gibi anlatılmaz (yaşadığı hane için ayrı olay yazılabilir); aracı olmayanın arabası çalınmaz; üniversitede olmayanın sınıf arkadaşlarıyla üniversite etkinliği çıkmaz. Oyuncunun o anda uğraştığı alan, başka alanlardan olay gelmesini bütünüyle engellemez. Kategori geçişi mantıklı ve aralıklı olmalıdır.

## 4. Serbest aile etkileşimleri — önceki kararlar geçerli
- Aile etkileşimleri karakterin uygun değerlerini ve kişiyle ilişkisini etkileyebilir.
- **B modeli:** Aynı kişiyle aynı tür etkinlik tekrarlandıkça olumlu getirisi azalır; sınırsız stat/ilişki kasma engellenir.
- Yakın zamanda birlikte vakit geçirilmişse aynı kişi, 'Daha yeni vakit geçirdik' gibi gerekçeyle **bazen** tekrar teklifini reddedebilir; oyuncunun mutluluğu bir miktar düşebilir. Her ret kesin puan kaybı değildir.
- Tekrar takibi formülü, ret olasılığı ve etkinliğin ne zaman yeniden tam verim vereceği henüz kararlaştırılmadı.

## 5. Onaylanmamış teknik tasarım önerileri
- Olay kayıtlarında hikâye/olay kimliği, açık/beklemede/tamamlandı durumu, ilgili kişi kimlikleri, başlangıç yaşı, son seçim, yaş ve varlık/ilişki/meslek/öğrencilik gibi önkoşullar tutulabilir.
- Aday havuzunda hem **devam olayları** hem **yeni olaylar** bulunabilir; bir sonraki olay seçimi için tekrar/çok yakın tetikleme önlemleri ve kategori çeşitliliği gözetilebilir.
- Anlık seçime doğrudan bağlı sonuçlar ile **daha sonra belirli koşullarda gelen** devam olayları ayrılabilir. Bir olay penceresi açıkken ikinci pencereyle üstüne binilmemesi değerlendirilebilir.
- Aralıklılık için oyun içi eylem/ilerleme bazlı tetikleyiciler, uygun anlar veya başka bir tempo ölçütü tasarlanabilir. **Gerçek zamanlı zamanlayıcı, saniye cinsinden bekleme veya belli sayıda eylem zorunluluğu henüz onaylanmadı.**

## 6. Sonraki tasarım soruları
1. Yaş Al'dan sonra çıkan ilk olay çözülünce oyuncu serbest ekrana mı döner, yoksa seçime doğrudan bağlı kısa bir devam sahnesi hemen gösterilebilir mi? Hikâye devamı mantığı onaylı; kesin arayüz akışı açık.
2. Oyuncu aynı yaşta serbestçe ilerlerken **aralıklı olayların tetikleyicisi** ne olur? Sadece düğmeye basınca olay gelsin kuralı yok; gerçek zamanlı beklemeyi de varsaymıyoruz.
3. Birden fazla bekleyen hikâyenin ve yeni olayların dengesi nasıl kurulur? Aynı kategorinin üst üste gelmesi nasıl azaltılır?
4. Kaçırılan, koşulları artık geçersiz veya sonlanan hikâyeler nasıl işaretlenir? Yaşlanma sırasında değişen hane, okul ve ilişki durumlarının sırası nasıl çözülür?
5. Olay sunumu ve sonuçlar hayat günlüğüne nasıl işlenir? Ölüm/yeni hayata geçiş akışı nasıl olur?

## İlerleme
**Ana hatlar, rastgele aile, karakter/ilişki/hafıza, tek tuşla yaş alma, azalan etkileşim getirisi ve doğal ret belirlendi. Şimdi bir olayla başlayan, seçimle dallanabilen, yaşlar arasında devam eden ve aralıklı sürprizlerle beslenen olay motorunu tasarlıyoruz.** Henüz kod/prototip yok.
