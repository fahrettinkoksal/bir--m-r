# Bir Ömür — mobil yaşam simülasyonu

Türkiye'nin gündelik hayatından esinlenen, nostaljik mahalle kültürünü günümüz olaylarıyla harmanlayan özgün bir yaşam simülasyonu. **Bir Ömür çalışma adıdır; kesin marka adı seçilmedi.** BitLife kapsam açısından referans olabilir; özgün kod, metin ve görselleri kopyalanmayacak.

## Şu ana kadar / şimdi

- **Tasarladık (kurallar netleşti):** Oyunun temel kimliği; rastgele doğum; iki başlangıç modu; dış görünüş, mutluluk, sağlık, zekâ ve karizma; ilişki etkileri; geçmiş kararların geleceğe yansıması; yaşa uygun olaylar; nostalji ve modern olayların birlikte bulunması.
- **Kodladık (oynanabilir durumda):** `app/` altında Flutter prototipi çalışıyor. Aile, okul, kariyer, ekonomi, eşya, konut, ilişkiler, evlilik, çocuk, kuşak devamı, sağlık krizleri, askerlik, dövüş sanatları, kumarhane, piyango, Finger, sosyal medya, seyahat, kalıcı hobiler ve evcil hayvanlar kodlandı. Kayıt/yükleme çalışıyor. Ayrıntılı durum: `PROJECT_STATUS.md`.
- **Henüz yapmadık:** Gerçek Android telefonda veya gerçek Windows bilgisayarda oynanmış bir doğrulama yok. Sayısal denge büyük ölçüde `prototypeOnly`; kesin değerler `docs/DESIGN_REVIEW_QUEUE.md` üzerinden karara bağlanacak.

## Proje belgeleri

- [GAME_BIBLE.md](GAME_BIBLE.md): Oyun kimliği ve temel prensipler.
- [DECISIONS.md](DECISIONS.md): Birlikte **kesinleştirdiğimiz** kararlar.
- [SYSTEMS.md](SYSTEMS.md): Sistemlerin şimdilik kararlaştırılan ana hatları.
- [docs/FAMILY_SYSTEM.md](docs/FAMILY_SYSTEM.md): Üzerinde çalıştığımız **aile sistemi taslağı**; onaylanmamış öneriler ayrı işaretlenir.
- [BACKLOG.md](BACKLOG.md): Açık sorular ve sonraki tasarım başlıkları.
- [docs/NEXT_DEVELOPMENT_OPTIONS.md](docs/NEXT_DEVELOPMENT_OPTIONS.md): Sonraki büyük sistemler için **öneri** listesi (hiçbiri karar değildir).
- [docs/DESIGN_REVIEW_QUEUE.md](docs/DESIGN_REVIEW_QUEUE.md): Karar bekleyen tasarım soruları (`Q-###`).
- [docs/EVENT_CONTENT_REPORT.md](docs/EVENT_CONTENT_REPORT.md): Olay havuzunun ölçüm raporu.
- [PROJECT_STATUS.md](PROJECT_STATUS.md): Güncel aşama, yapılanlar, sıradaki işler.
- [CLAUDE.md](CLAUDE.md): Claude'un projeyi devralırken okuyacağı kurallar.
- [AGENTS.md](AGENTS.md): ChatGPT ve diğer kodlama oturumları için ortak çalışma kuralları.

## Çalışma yöntemi

Faho ile ChatGPT oyun tasarımını netleştirir; Claude kodlama için kullanılır. Kesinleşen kararlar bu özel GitHub deposuna işlenir. Sohbet geçmişi tek başına kaynak sayılmaz; açık fikirler kararlaştırılmış gibi uygulanmaz. Yeni oturumlarda önce `PROJECT_STATUS.md` ve `DECISIONS.md` okunur.
