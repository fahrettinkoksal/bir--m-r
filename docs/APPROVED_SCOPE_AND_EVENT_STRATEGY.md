# Bir Ömür — onaylanan kapsam ve olay geliştirme yaklaşımı

**Karar sahibi:** Faho. **Durum:** Bu belgedeki açıkça onaylanan ilkeler geçerlidir; açık sorular çözülmüş sayılmaz. **Kapsam:** Tasarım kaydı; Claude'a kod yazma veya mevcut PR'ı birleştirme talimatı değildir.

## GEN-001 — Bütün oyun için olay geliştirme stratejisi (onaylandı)

**Tercih: Önce ortak olay altyapısı ve küçük, kaliteli, oynanabilir içerik paketleri; sonra paketleri aşamalı genişletmek.** Önce devasa sayıda olay/diyalog üretip tüm oyunu doldurmaya çalışmayacağız. Oyunun uzun vadeli kapsamı bu kararla küçültülmüyor.

- Aile, okul, iş, arkadaşlık, romantik ilişkiler, ekonomi, sosyal medya ve ileride açılabilecek başka alanlar aynı kişi/durum/olay/koşul/hafıza altyapısından yararlanabilsin. İçerik küçük, birbirine bağlanabilen ve test edilebilen paketlerle eklensin.
- Kişi adı, ilişki, geçmiş karar, sahip olunan özellik veya hizmet gibi değişkenler gerektiğinde tekrar kullanılabilir olay yapılarında değerlendirilsin. Her olası kişi ve koşul için sıfırdan ayrı uygulama kodu yazma zorunluluğu yaratılmasın.
- Tekrar kullanılabilirlik, metinlerin sadece isim değiştirilerek sürekli aynen gösterilmesi anlamına gelmez. Özgün metin çeşitliliği, yaş/durum uygunluğu, tekrar kontrolü ve seçimlerin sonuçları korunmalı. Önemli hikâye zincirleri ayrıca özgün yazılabilir.
- İlk sürüm, her yaşam alanının eksiksiz olay kataloğunu gerektirmez. Her paketi oynanabilirlik ve testlerle doğrulayıp ardından genişletelim. Kesin olay sayısı, paket başına miktar, otomatik metin üretme yöntemi veya sayısal tempo bu kararla belirlenmedi.

## Q-004 — Romantik ilişkilerin temel sürüm kapsamı (kısmen onaylandı)

- İlk oynanabilir sürümde **temel ilişki akışı** yeterli: uygun ve akraba olmayan tanışılan kişiyle yakınlaşma, oyuncunun teklif edebilmesi veya uygun koşullarda oyuncuya teklif gelmesi, sevgili olma, ilişkinin sürmesi ve ayrılık sonrası aynı kişinin kimliğinin/geçmişinin korunması.
- Uzun vadede kişiler okul, iş, kafe, rastgele karşılaşma ve ileride eklenen olaylardan tanışılabilir. Oyuncu uygun ve akrabası olmayan tanıştığı kişiye ilişki teklif etmeyi deneyebilir; kişilerin oyuncuya teklif etmesi de mümkün olmalı. Bu kaynakların **tamamının ilk sürümde hazır olması zorunlu değil**; aynı altyapıya sonradan bağlanacaklar.
- Olaylar yalnızca gerçekten mevcut durum/özelliklerle açılmalı: örneğin oyuncunun Instagram hesabı yoksa Instagram'dan eklenme/mesaj olayı çıkmaz; ünle ilgili teklif için ilgili ün koşulu gerçekleşmiş olmalıdır. Örnekler tek tek yazılması zorunlu ilk sürüm görevleri değildir.
- Romantik içeriği tüm varyasyonlarıyla ilk sürümde tamamlama hedefi yok; GEN-001'in küçük paket yaklaşımı burada da geçerli.

**Q-004 içinde hâlâ açık:** Potansiyel partnerlerin cinsiyet ve yönelim/eşleşme kuralları, kesin romantik yaş/yaş farkı uygunluğu, ilk tanışma anındaki kişi kimliği ve tekrar tanışma yönetiminin ayrıntılı veri modeli, teklif kabul/ret kuralları. Mevcut kodun otomatik karşıt cinsiyet eşlemesi nihai karar değildir. Bu kararları Faho ile ChatGPT tek tek netleştirecek; Claude onay gelmeden kalıcı kurala dönüştürmeyecek.

**Claude için sınır:** Bu belgeyi oku ve diğer tasarım sorularını `docs/DESIGN_REVIEW_QUEUE.md` dosyasına kaydet. Şu anda bu belge gerekçesiyle kod yazmaya başlama, PR'ı birleştirme veya mevcut oyunu yeniden tasarlama. Faho'nun sonraki açık uygulama talimatını bekle.
