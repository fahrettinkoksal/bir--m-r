# Proje durumu

**Aşama:** Kodlama başladı. Teknoloji olarak **Flutter + Android önceliği Faho tarafından onaylandı**. `docs/CLAUDE_PROTOTYPE_TASK.md` içindeki **Aşama 1 uygulandı** (`app/` klasörü); Aşama 2-5 henüz yapılmadı. **Oynanabilir tam döngü (aile etkileşimi, olay motoru, sevgili/ayrılık) henüz yoktur.**

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

### Çalıştırılan doğrulamalar
`flutter analyze` temiz; `flutter test` ile 41 test geçti (üretim tutarlılığı, yaş alma, arayüz gezinme). Ekran görüntüleri `app/test/goldens/` altında üretildi.
**Doğrulanamayan:** Android APK derlemesi ve gerçek cihaz/emülatör denemesi — bu ortamda Android SDK indirilemedi (ağ politikası `dl.google.com` erişimini engelliyor). APK derlemesi Faho'nun ortamında denenmelidir.

## Şimdi yapılacak iş
Aşama 1 incelenip onaylandıktan sonra `docs/CLAUDE_PROTOTYPE_TASK.md` içindeki **Aşama 2** (aile etkileşimi, azalan etki, doğal ret) uygulanacak. Kodda `prototypeOnly` olarak işaretlenen sayısal ağırlıklar geçicidir; kesin denge Faho onayıyla belirlenecek ve `DECISIONS.md` yalnızca onaylanan kararlarla güncellenecek.

## Sonraki tasarım işleri
İlk çalışan dikey kesit doğrulandıktan sonra olay verisi ve sürekliliğini genişlet, aile, eğitim, kariyer, ekonomi, sosyal medya/Ün sistemlerini aşamalı ayrıntılandır. Kesin sayısal denge ve teknoloji hâlâ açık.

## ChatGPT / Claude devri
Yeni oturumda `DECISIONS.md`, bu dosya, `docs/PROTOTYPE_UI.md`, `docs/CLAUDE_PROTOTYPE_TASK.md` ve ilgili sistem belgelerini oku. **Önerileri kesin karar sayma.** Yeni karar alınırsa ilgili belgeleri güncelle; tamamlanmamış işleri tamamlandı yazma.

## Depo sınırı
Yalnızca `fahrettinkoksal/bir--m-r` üzerinde çalış. Hipopotamya organizasyonundaki hiçbir depoya dokunma.
