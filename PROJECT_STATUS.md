# Proje durumu

**Aşama:** Kodlama sürüyor. Teknoloji olarak **Flutter + Android önceliği Faho tarafından onaylandı**. `docs/CLAUDE_PROTOTYPE_TASK.md` içindeki **Aşama 1 ve Aşama 2 uygulandı** (`app/` klasörü); Aşama 3-5 henüz yapılmadı. **Olay motoru ve sevgili → ayrılık → eski sevgili akışı henüz yoktur.**

## Şu ana kadar ana hatlarını belirledik
Türkiye/nostalji odaklı özgün oyun kimliği; iki başlangıç modu, rastgele aile/şehir; dış görünüş, mutluluk, sağlık, zekâ, karizma; kişi bazlı ilişkiler; geçmiş karar hafızası; yaşa/koşula uygun olaylar; ailenin bağımsız yaşam gelişmeleri. Kesin karar kaydı: `DECISIONS.md`.

## Aile ve genel işleyiş: netleşenler
Aile rastgele çeşitlenir; aynı evde yaşama ile akrabalık ayrı tutulur. Aile sekmesinde kişiler görülür, hediye verilir, birlikte vakit geçirilir; aile etkileşimleri ana karakteri etkiler. Uzun süre oyun içinde görüşülmeyen aile bireyi bazen sitem edebilir.

**Yaş Al** isteğe bağlıdır ve yeni yaşta ilk olarak bir uygun olay çıkar. Sonraki olaylar oyun içi ilerlemeye göre aralıklı gelir; gerçek dünya dakikaları beklenmez. Geçmiş hikâyeler seçimlere göre devam eder. Yakın zamanda yinelenen aile davetini kişi bazen reddedebilir. Genel etkileşim/hak kotası yoktur; aynı yaşta aynı etkinliğin olumlu getirisi giderek azalır ve sıfıra iner.

**Ün**, herkeste başlangıçta görünmeyen; sosyal medya/takipçi veya uygun görünürlük sağlayan olaylarla düşük seviyeden açılabilen özelliktir. Ayrıntılı sosyal medya ve Ün sistemi henüz tasarlanmadı.

## İlk prototip — onaylanan yön
- Başlangıç alt menüsü **Hayat / Aile / Ben**; ileride Sosyal sekmesi, Ben altında spor salonu, berber, seyahat gibi eylemler eklenecek. Üç sekme kalıcı sınır değil.
- Görsel yön **modern + ölçülü nostaljik detaylar**, Bir Ömür'e özgün arayüzdür.
- **Kesin oynanabilir test:** uygun kişiyle sevgili olma → kişinin Aile'de sevgili görünmesi → ayrılık → aynı kişinin silinmeden **eski sevgili** statüsünde kalması. Romantik ilişki, akrabalık ve aynı evde yaşama birbirine karıştırılmaz.
- `docs/PROTOTYPE_UI.md` ekran/kapsam belgesidir. **`docs/CLAUDE_PROTOTYPE_TASK.md` Claude için hazırlanmış aşamalı uygulama görevi ve test matrisidir.** Görev belgesini oluşturmak kodun yazılması veya Claude tarafından çalıştırılması anlamına gelmez.

## Aşama 1 — yapıldı (kod: `app/`)
- Flutter proje iskeleti (`app/`, paket adı `bir_omur`, Android platformu kurulu). Kurulum ve çalıştırma: `app/README.md`.
- İki başlangıç modu (D-005): tamamen rastgele; yalnızca isim ve cinsiyet seçimi. Şehir ve diğer koşullar her iki modda da rastgele.
- Tutarlı rastgele aile üretimi (D-004, D-013, D-014): ebeveyn yaş/meslek/**kişisel** ekonomik durumu, ebeveyn ilişki durumu, 0-6 kardeş, geniş aile, evcil hayvan. Akrabalık ile **hane** ayrı alanlar; ayrı/boşanmış ebeveynler aynı hanede birlikte bulunmaz; vefat etmiş kişi hanede sayılmaz; çalışmayan kişiye meslek uydurulmaz.
- Hayat / Aile / Ben sekmeleri çalışır; sekme listesi yeni bölüm (ör. Sosyal) eklenebilecek biçimde tek listeden okunur.
- Hayat ekranı: karakter özeti, beş değer, hatıra defteri hissi veren hayat günlüğü ve belirgin **Yaş Al**. Yaş Al bu aşamada yalnızca zamanı ilerletir ve günlüğe tek satır yazar.
- **Ün** açılmadığı için hiçbir ekranda gösterilmez (D-027). Yazılmamış eylemler sahte düğme olarak konmadı.
- Görsel yön: Bir Ömür'e özgü modern + ölçülü nostaljik tema (kâğıt tonları, nar kırmızısı/çini yeşili, ince kilim şeridi).

## Aşama 2 — yapıldı (kod: `app/lib/domain/interaction/`)
- Aile → kişi detayı → **Vakit Geçir** ve **Sohbet Et** gerçekten çalışıyor; sonuç özgün Türkçe metinle ve uygulanan değişimlerle (yakınlık, mutluluk, karizma) gösteriliyor.
- **Genel etkileşim kotası yok (D-026).** Tekrar sayacı kişi + etkileşim türü bazında ve **yalnızca içinde bulunulan yaşa ait**. Anneyle vakit geçirmek babayı ya da aynı kişiyle sohbeti kilitlemiyor.
- Aynı yaşta aynı kişiyle aynı etkinliğin getirisi azalıyor ve o yaş için **sıfır ek kazanca** iniyor (D-019). Fayda bitince etkinlik kapanmıyor; sonuç metni gelmeye devam ediyor.
- Yakın tekrarda kişi **bazen** doğal gerekçeyle reddediyor; ret hâlinde küçük mutluluk kaybı **olabiliyor**, her ret ceza değil (D-020). İlk istek hiç reddedilmiyor.
- Vefat etmiş kişiyle veya yaşı uygun olmayan oyuncuyla etkileşim açılmıyor; düğme gösterilmiyor, gerekçe yazılıyor.
- Hayat günlüğüne yalnızca anlamlı sonuçlar yazılıyor; sıfır kazançlı tekrar günlüğü şişirmiyor.

### Çalıştırılan doğrulamalar
`flutter analyze` temiz; `flutter test` ile **60 test geçti** (aile üretim tutarlılığı, yaş alma, aile etkileşimi/azalan etki/ret, arayüz gezinmesi ve etkileşim akışı). Ekran görüntüleri `app/test/goldens/` altında üretildi.
**Doğrulanamayan:** Android APK derlemesi ve gerçek cihaz/emülatör denemesi — bu ortamda Android SDK indirilemedi (ağ politikası `dl.google.com` erişimini engelliyor). APK derlemesi Faho'nun ortamında denenmelidir.

## Şimdi yapılacak iş
Aşama 2 incelendikten sonra **Aşama 3** (Yaş Al sonrası tek açılış olayı, olay verisi ve hafıza) uygulanacak. Kodda `prototypeOnly` olarak işaretlenen sayısal ağırlıklar geçicidir; kesin denge Faho onayıyla belirlenecek ve `DECISIONS.md` yalnızca onaylanan kararlarla güncellenecek.

### Faho'nun kararına bırakılan açık noktalar
- Azalma eğrisi (prototipte 4 tekrarda sıfır), ret olasılıkları ve ret sonrası mutluluk kaybı miktarı.
- Tekrar sayaçlarının yaş değişiminde **tam** mı kısmi mi yenileneceği (prototipte tam).
- Etkileşimlerin açıldığı asgari oyuncu yaşı (prototipte 4).
- "Sohbet Et" etkileşiminin kalıcı bir tür olup olmayacağı; hediye verme ekonomi sistemi tasarlanınca eklenebilir.

## Sonraki tasarım işleri
İlk çalışan dikey kesit doğrulandıktan sonra olay verisi ve sürekliliğini genişlet, aile, eğitim, kariyer, ekonomi, sosyal medya/Ün sistemlerini aşamalı ayrıntılandır. Kesin sayısal denge ve teknoloji hâlâ açık.

## ChatGPT / Claude devri
Yeni oturumda `DECISIONS.md`, bu dosya, `docs/PROTOTYPE_UI.md`, `docs/CLAUDE_PROTOTYPE_TASK.md` ve ilgili sistem belgelerini oku. **Önerileri kesin karar sayma.** Yeni karar alınırsa ilgili belgeleri güncelle; tamamlanmamış işleri tamamlandı yazma.

## Depo sınırı
Yalnızca `fahrettinkoksal/bir--m-r` üzerinde çalış. Hipopotamya organizasyonundaki hiçbir depoya dokunma.
