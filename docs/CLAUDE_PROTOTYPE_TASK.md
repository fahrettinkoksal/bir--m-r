# Claude geliştirme görevi — Bir Ömür ilk oynanabilir prototip v0.1

**Belge türü:** Kodlama için görev devri; bu belge bir kod teslimi değildir. **Durum:** Yürütüldü. Aşama 1-4 uygulandı ve o günden bu yana çok sayıda paket eklendi; `app/` altında oynanabilir bir prototip vardır. Bu belgedeki "kod mevcut değil" varsayımı artık geçerli değildir; güncel durum için `PROJECT_STATUS.md`. **Depo sınırı: YALNIZCA `fahrettinkoksal/bir--m-r`. Hipopotamya organizasyonu ve depolarına hiçbir şekilde dokunma.**

## 0. Başlangıç ve karar kaynakları

Görev aldığında önce bu depoyu aç/klonla ve `AGENTS.md`, `CLAUDE.md`, `README.md`, `DECISIONS.md`, `PROJECT_STATUS.md`, `docs/PROTOTYPE_UI.md`, `docs/CORE_LOOP.md`, `docs/FAMILY_SYSTEM.md`, `SYSTEMS.md` dosyalarını oku. İlgili konu için `BACKLOG.md`'yi de incele. **`DECISIONS.md` onaylı kurallardır; taslak belgelerdeki öneriler otomatik onay değildir.** Belgeler arasında çelişki varsa ilgili kararı kullanıcıdan sor; mevcut onaylı kuralları sessizce değiştirme. BitLife'ın özgün kodunu, metnini, ikon/görsellerini veya ekranlarını kopyalama.

**Teknoloji onay kapısı:** Önceki sohbette Flutter **önerildi**, ancak Faho tarafından açıkça kesin teknoloji kararı olarak teyit edilmedi. Kod üretmeden önce kullanıcıya tek net soru sor: «İlk prototipi Flutter ile Android öncelikli geliştirmemizi onaylıyor musun?» Onaylanırsa yerel ortam/araç sürümlerini doğrula; Flutter yoksa çalıştırdığını iddia etme. Başka teknoloji istenirse seçenekleri ve etkisini gösterip onay al. Flutter onayı alınmışsa aynı soruyu yineleme. Kullanıcı tarafından onaylanmayan oyun tasarım kararlarını teknik kolaylık gerekçesiyle kesinleştirme.

## 1. Hedef: küçük ama gerçekten oynanabilir dikey kesit

Oyuncu doğar → tutarlı bir rastgele aile görür → Aile'de en az bir gerçek etkileşim yapar ve sonucu karakter/ilişkide görür → kendi isteğiyle Yaş Al'a basar → yeni yaşta tek uygun açılış olayıyla karşılaşır → verdiği seçim ileriki uygun bir olayı etkiler → yaşa/koşullara uygun bir romantik ilişki başlatabilir → kişi Aile'de sevgili görünür → ayrılır → **aynı kişi** Aile'de eski sevgili olarak kalır. Bu akış tıklanabilir sahte ekran değil, durum değiştiren çalışan kod olmalı.

**Sınır:** İlk prototip bütün oyun içeriğini, her mesleği/okulu, tam Sosyal/Ün sistemini, spor salonu/berber/seyahat menülerini, mağazayı, reklam veya premium sistemini tamamlamak zorunda değil. Bunları gelecekte modül olarak eklemeyi mümkün kıl; işlevsiz tıklanabilir öğe koyma. Belirli yaş, olay adedi, puan eğrisi veya ret ihtimalini ürünün kalıcı kuralıymış gibi ilan etme; demo için geçici test parametresi gerekiyorsa konfigürasyonda `prototypeOnly` benzeri işaretle ve açıkça belgele.

## 2. Aşamalar (sırayla ilerle; her aşamada sonucu göster)

### Aşama 1 — Uygulama iskeleti, modüler gezinme ve karakter oluşturma
- Kullanıcı onaylı teknolojiyle temiz, derlenebilir mobil proje kur; kısa kurulum/çalıştırma talimatı ekle.
- Dikey, tek elle anlaşılır, **Bir Ömür'e özgün modern + ölçülü nostaljik** UI; prototipte alt sekmeler **Hayat / Aile / Ben**. Sekmeler sonradan Sosyal gibi yeni alanlarla genişletilebilir yapıda olsun; üç sekmeyi sabit ürün sınırı varsayma.
- İlk başlatmada iki başlangıç modu: her şey rastgele veya yalnızca isim/cinsiyet oyuncu tarafından seçilir. Doğum şehri ve geri kalan başlangıç koşulları rastgele belirlenir; gerçek doğum yılı/dönem seçimi yok.
- Karakterin beş başlangıç değerini (dış görünüş, mutluluk, sağlık, zekâ, karizma) göster. **Ün henüz açılmamışsa gösterme**, başlangıçta herkesin Ün'ü varmış gibi davranma.
- Oyuncu ve kişiler için tutarlı durum modeli oluştur; ebeveyn yaşları/meslekleri/kişisel maddi durumları ve gerçek hane üyeliği ayrı bilgi olsun. Demo veri havuzu küçük olabilir ancak zorunlu 'ortalama aile' kalıbı üretme; olmayan/ölü kişiyle etkileşim açma.
- Hayat ekranında kısa hayat günlüğü ile belirgin **Yaş Al** eylemi; Ben ekranında gerçekten işleyen karakter bilgileri. Tekrarlanan sıfır faydalı eylemi tüm menülere küresel kota sayma.
- **Kabul:** İki başlangıç modu çalışır, rastgele aileler hane/akrabalık bakımından çelişmez, üç sekme arasında gezinilir, sahte aktif menü yoktur. Gereken otomatik testleri ekle.

### Aşama 2 — Aile etkileşimi ve tekrar dengesi
- Aile → uygun anne/diğer mevcut üye → kişi detayı → Vakit Geçir çalışsın; uygun olduğunda ilişki ve ana karakter mutluluğu gibi değerleri etkileyen özgün Türkçe sonuç göster.
- **Global toplam etkileşim hakkı YOK.** Aynı kişiyle aynı eylemin aynı yaşta olumlu getirisi tekrarlarla azalır ve o yaş için sonunda **sıfır ek kazanç** olur. Diğer kişiler ve başka faaliyetler bundan küresel olarak kilitlenmez.
- Yakın tekrarlanan görüşme talebinde aile bireyi **bazen** doğal gerekçeyle reddedebilir. Ret olduğunda küçük mutluluk kaybı **olabilir**, her ret zorunlu ceza değildir. Olasılık ve etki değerleri henüz ürün düzeyinde belirlenmedi; demo yapılandırmasını kalıcı tasarım kararı yapma.
- Durum, kişi kimliği ve en azından aynı yaşa ait tekrar geçmişi modellenmeli. Olay günlüğüne yalnızca anlamlı sonuçları yazmak yeterli; metinler özgün olsun.
- **Kabul:** Tekrar eden aynı etkinlik sonsuza kadar stat/ilişki artırmaz; ret ve kabul yolları testle kontrol edilir; farklı kişilerin sayaçları karışmaz.

### Aşama 3 — Yaş Al, tek açılış olayı ve hafıza
- Oyuncu hazır olduğunda **Yaş Al** ile bir yaş ilerler; bütün etkinlikleri bitirmeye zorlanmaz. Yeni yaşa girince **ilk olarak yalnızca tek** yaşına ve mevcut koşullarına uygun olay çıkar. Aynı anda bağımsız olay pencereleri yağdırma.
- Küçük ama genişletilebilir **özgün olay verisi** kullan: olay kimliği, uygunluk (yaş, yaşayan kişi, öğrenci/ilişki/varlık vb.), seçenekler, etkiler ve ilerideki olay için kayıt/hikâye durumu. Nihai veri şeması henüz onaylı değil; uygulamada seçtiğin teknik şemayı açıklayıp tasarım kararı gibi sunma.
- En az bir olay seçimi ileriki **uygun** yaşta farklı devamı görünür biçimde değiştirsin. Koşul kaybolursa geçersiz devam gösterilmesin. Olay sonucu uygun karakter/ilişki değişimine ve hayat günlüğüne yansısın.
- Diğer olaylar oyuncunun **oyun içi ilerleyişine** bağlı aralıklı çıkabilir; gerçek dünya dakikası bekletme. Kesin tempo algoritması henüz onaylı değil: prototipte seçtiğin geçici yaklaşımı açıkça sınırlandır ve gereksiz pop-up spam'i üretme. Az temas edilen aile üyesinin koşula uygun sitemi ana oyun vizyonunun parçasıdır; bu ilk kesitte ne derinlikte yer aldığını raporla, varmış gibi iddia etme.
- **Kabul:** Yaş Al tek yaş artırır ve tek açılış olayı gösterir; geçmiş seçim sonraki olayda gözlenir; uygunsuz (olmayan sevgili, sahip olunmayan araç, öğrenci olmayan üniversite olayı) çıkmaz; gerçek zamanlayıcıya bağımlı akış yoktur.

### Aşama 4 — Sevgili → ayrılık → eski sevgili, aynı kişi
- Uygun yaş/koşulda oyuncunun **gerçek seçim veya etkileşimle** bir romantik ilişki başlatabildiği özgün küçük hikâye oluştur. Kişi Aile'de mevcut sevgili statüsüyle listelensin.
- Oyuncunun ilişkiyi bitirebildiği gerçek bir seçim/olay oluştur. Ayrılınca kişinin kaydı **silinmez veya yeni kimlikle yeniden yaratılmaz**; aynı kimlikle Aile'de **Eski Sevgili/Eski Kız Arkadaş** olarak kalır. Önceki karşılaşmalar ve önemli seçimler unutulmaz.
- Sevgili/akraba/hane ayrı kavramlardır. Eski sevgiliye sevgiliye özel eylemleri koşulsuz sunma; eski sevgilinin otomatik aynı evde yaşadığını varsayma. Romantik hikâyeyi oyundaki farklı yaşların erişimine zorla açma.
- **Kabul:** Aynı kişi kimliğinin ilişkiden önce, ilişki sırasında ve ayrılıktan sonra değişmediği test edilir; statü ekranda doğru güncellenir; olay geçmişi sürer; başka aile üyeleri etkilenip yanlışlıkla eski sevgiliye dönüşmez.

### Aşama 5 — Entegrasyon, test, teslim ve durum kaydı
- Baştan sona **yeni hayat → Aile etkileşimi → Yaş Al → seçim/hatırlanan devam → sevgili edinme → ayrılma → Aile'de eski sevgili** akışını gerçek uygulamada dene. Rastgele üretim için tekrarlanabilir test senaryosu/seed kullanabilirsin ama bütün oyunculara tek sabit aile verme.
- Çalışma ortamındaki gerçek komutları ve sonuçlarını raporla (örn. analiz/test/build); çalıştırılamayanı dürüstçe belirt. Mümkünse telefon/emülatörde akışı gösteren ekran görüntüsü veya kısa kayıt ekle; görüntü üretme imkânı yoksa uydurma.
- Değişen dosyaları, nasıl çalıştırılacağını, test edilen senaryoları, eksikleri ve sonraki yapılacakları `PROJECT_STATUS.md` ve uygun teknik belgelerde güncelle. **Yeni oyun kararı gerekiyorsa Faho'ya sor; `DECISIONS.md` dosyasına tek taraflı ürün kararı yazma.**
- Kendi çalışma dalında küçük anlaşılır commitler ve mümkünse inceleme için PR kullan; ana dala birleştirme, silme veya büyük kapsam değişikliği için kullanıcı talimatlarını izle. Depo erişimi yoksa erişimin olduğunu iddia etme, kullanıcıdan repo bağlantısı/izin iste.

## 3. Test matrisi (en azından bu davranışları kapsa)

| Durum | Beklenen |
| --- | --- |
| Her şey rastgele / isim-cinsiyet seçimi | İki başlangıç modu; diğer şartlar rastgele |
| Ayrı yaşayan ebeveyn | Akrabalık ile hane karışmaz |
| Aynı kişi + aynı eylem + aynı yaş tekrarları | Getiri azalır ve sonunda sıfır; global kota yok |
| İki farklı aile bireyi | Birinin tekrar geçmişi diğerini kilitlemez |
| Yakın tekrarda kabul veya ret | İki olası yol desteklenir; her ret zorunlu ceza değil |
| Yaş Al | Bir yaş artar, tek uygun açılış olayı |
| Önceki karar / geçersiz önkoşul | Doğru devam veya uygun olayın elenmesi |
| Sevgili → ayrılık | Aynı kimlik korunur; Aile'de eski sevgili görünür |
| Henüz ün kazanmayan karakter | Ün göstergesi yok; tam sosyal medya menüsü uydurulmaz |
| İlerlemeksizin gerçek dakika geçmesi | Oyuna kendiliğinden ek olay yağmaz |

## 4. Claude'a teslim istemi — doğrudan gönderilebilir

> Yalnızca şahsi `fahrettinkoksal/bir--m-r` GitHub depomda Bir Ömür'ün ilk oynanabilir mobil prototipini geliştir. Önce `AGENTS.md`, `CLAUDE.md`, `DECISIONS.md`, `PROJECT_STATUS.md`, `docs/PROTOTYPE_UI.md`, `docs/CORE_LOOP.md` ve **`docs/CLAUDE_PROTOTYPE_TASK.md` dosyasının tamamını** oku; gerekli diğer belgeleri incele. Bu görev belgesindeki aşamaları sırasıyla uygula ve her aşamada çalışan kod, testler ve kısa ilerleme raporu ver. Teknoloji henüz kesin karara bağlanmadıysa **kodlamadan önce Flutter/Android önceliğini benimle onayla**. Taslak önerileri kesin tasarım sanma; BitLife içeriği kopyalama; hiçbir Hipopotamya organizasyon deposuna erişme veya dokunma. Önce mevcut depoda kod olup olmadığını kontrol et; yoksa onaylı teknolojide başlangıç projesini kur. Tasarım belgesindeki romantik ilişki → ayrılık → aynı kişinin eski sevgili olarak kalması akışını gerçekten oynanabilir yap. Test etmediğin şeyi yapılmış sayma, ortaya çıkan yeni tasarım kararlarını benden onay almadan kesinleştirme.
