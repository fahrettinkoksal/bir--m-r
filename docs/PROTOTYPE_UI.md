# İlk prototip — arayüz ve gezinme taslağı v0.1

**Durum: ÖNERİ; Faho'nun 'BitLife gibi bir menü' tercihinden hareketle hazırlanmıştır. Birebir BitLife görünümü, metinleri, ikonları veya varlıkları kopyalanmayacak. Ekran yerleşimi ve görsel dil henüz onaylanmadı. Kod/oynanabilir prototip yok.**

## Tasarım ilkesi
Dikey tek elle kullanılabilir mobil yaşam simülasyonu: okunabilir metin, kolay ulaşılabilir eylemler, karakterin yaşı/durumu ve hayat günlüğü odakta. Tanıdık yaşam-simülasyonu gezinme kalıbı ama Bir Ömür'e özgü Türkçe metin, renk, ikon ve bileşenler. Yaş Al ana ekranda kalıcı ve belirgin; diğer ekranlarda geri dönüş açık. Reklam/premium ekranı prototipte yok.

## Önerilen alt gezinme (ilk prototip)
- **Hayat:** ana ekran; karakter adı, yaş, doğum şehri, mevcut kısa durum, beş ana değer ve aşağı doğru akan **hayat günlüğü**, uygun tek açılış olayı, kalıcı Yaş Al eylemi.
- **Aile:** rastgele doğan aile üyeleri listesi; ilişki ve aynı evde olup olmadığı; anne/baba yaşı, mesleği ve bağımsız maddi durumu. Kişiye basınca detay ve Vakit Geçir / Hediye Ver eylemleri. Eksik veya ölmüş akraba canlı etkileşim olarak sunulmaz.
- **Ben:** ana karakter özellikleri ve güncel yaşam özeti; prototipte sadece gerçekten işleyen temel değerleri göster. Ün başlangıçta görünmez/açık değildir; görünürlük kazanınca ortaya çıkabilen ileriki özellik.
- **Diğer:** eğitim, iş, sosyal medya, sağlık/spor ve varlıklar için ileride genişleyebilir girişler; **prototipte çalışmayan menüleri tıklanabilir/sahte özellik olarak göstermemek**. Gerekirse bu sekme ilk prototipte hiç görünmeyebilir.

**Alternatif:** Alt çubuk yalnızca Hayat / Aile / Ben olsun; oyun alanları genişledikçe Eylemler/Daha Fazla menüsü eklensin. Kesin alt çubuk sayısı Faho tarafından onaylanmadı.

## Önerilen ana ekran iskeleti (orijinal yerleşim; bir görsel tasarım değil)
```
┌─────────────────────────────┐
│ BİR ÖMÜR            [Menü]  │
│ Karakter Adı • 12 yaş       │
│ Şehir / kısa hayat durumu   │
├─────────────────────────────┤
│ Mutluluk ▰▰▰▱▱  Sağlık ▰▰▰▰▱ │
│ Zekâ     ▰▰▰▱▱  Karizma ▰▰▱▱▱│
│ Görünüş  ▰▰▰▱▱              │
├─────────────────────────────┤
│ HAYAT GÜNLÜĞÜ               │
│ 12 yaş • [olayın kısa izi]  │
│ 11 yaş • [önceki karar]     │
│ ...                         │
│                             │
├─────────────────────────────┤
│       [  YAŞ AL  ]          │
│  Hayat     Aile      Ben    │
└─────────────────────────────┘
```
Ün açılmadan çubuk göstermeyiz. Bu ASCII tel-kafes teknik taslak; kesin font, renk ve yüzdeler belirlenmedi.

## Olay sunumu
Yaş Al'a basılınca **yalnızca bir** uygun açılış olayı okunaklı olay kartında/tek bir modalde görünür: kısa özgün anlatım, gerekli kişi/koşul, 2–4 seçenek **örnek öneri, zorunlu adet değil**. Seçim sonucu anında geri bildirim ve gerektiğinde hayat günlüğüne kayıt; sonraki olay anında zincirlenmek zorunda değil, oyun içi ilerleme ile aralıklı gelir. Birden fazla bağımsız olay penceresi üst üste açılmaz. Açık olay varken başka sekmelere geçiş davranışı henüz kararlaştırılmadı.

## Aile ekranı akışı
Aile → Anne (veya mevcut bir akraba) → kişinin adı, akrabalık türü, yaşı, anne/baba için mesleği ve kişisel maddi durumu, mevcut ilişki → Vakit Geçir → özgün sonuç metni → uygun karakter değeri/ilişki etkisi → Hayat günlüğüne gerektiğinde kayıt. Aynı etkileşim aynı yaşta tekrarlandıkça kazanım azalır ve sonunda sıfırlanır; NPC yakın tekrarı bazen reddedebilir. Genel etkileşim kotası veya gerçek dünya zamanlayıcısı YOK.

## Prototip kapsamına öneri (onay bekliyor)
1. İki başlangıç modu ve tutarlı ama ilk aşamada dar içerikli rastgele karakter/aile üretimi.
2. Hayat, Aile ve Ben ekranları; beş ana değer, kişi bazlı ilişki, hane bilgisi.
3. Anneyle vakit geçirmenin olumlu sonucu ve yakın tekrarda azalan etki / olası doğal ret.
4. Yaş Al ile ilk tek olay; önceki kararın sonraki yaşta uygun bir devamını gösterebilen en az bir özgün örnek zincir.
5. Oyun içi ilerlemeye bağlı aralıklı ek olay / aileyle uzun süre temas yoksa sitem örneği, ilk teknik kapsama alınıp alınmayacağı ayrıca seçilecek.
6. Gerçek zamanlı bekleme, sosyal medya ve Ün için tam menüler, tüm meslekler/okullar, mağaza/ödeme ve kapsamlı içerik havuzu şimdilik YOK; bunlar ürün vizyonundan çıkarılmadı.

## Kabul kriteri önerileri
- Ekranların hiçbiri olmayan kişiyi veya açılmamış Ün'ü göstermiyor.
- Rastgele boşanmış ebeveynler otomatik olarak aynı hanedeymiş gibi gösterilmiyor.
- Aynı etkileşim sonsuz mutluluk kazandırmıyor.
- Tek bir Yaş Al tıklaması bir yaş ilerletiyor ve ilk olay tek başına açılıyor.
- Önceki seçim yeni yaşın uygun olayını etkileyebiliyor; bağımsız olaylar spam olmuyor.
- Sadece çalışır durumdaki prototip özellikleri tıklanabilir.

## Onay için iki nokta
1. Alt gezinme: **Hayat / Aile / Ben** ile mi başlayalım, yoksa **Hayat / İlişkiler / Etkinlikler / Profil** gibi geleceğe dönük geniş çubuk mu? İlk öneri daha yalın.
2. Stil: sıcak, sade, Türkiye'ye özgü küçük detayları olan modern kartlar mı; yoksa daha nostaljik gazete/defter havası mı? BitLife'tan ayırt edici özgün tasarım gerekli.
