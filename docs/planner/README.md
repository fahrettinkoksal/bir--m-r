# Bir Ömür — geliştirme panosu

`index.html` tek dosyalık bir web uygulamasıdır. Çift tıklayıp tarayıcıda
açabilirsiniz; sunucu, kurulum ve internet gerekmez. Veri dosyanın içine
gömülüdür.

## Ne var içinde

| Bölüm | Ne gösterir | Kaynağı |
|---|---|---|
| Genel bakış | Sayılar, günlük commit yoğunluğu, açık işler | hepsi |
| Yol haritası | Paketler zaman sırasında, tarih ve commit sayısıyla | `tasks.tsv` + git |
| Görevler | Kanban panosu ve liste; modül/paket/durum filtresi | `tasks.tsv` |
| Modüller | 18 ürün modülü; dosya, satır, test, görev, commit | `app/lib`, `app/test` |
| Oyun içeriği | 43 katalog: meslek, eşya, aktivite, mülakat sorusu, işletme olayı, şehir, hastalık, şirket, fal, ehliyet sorusu, ekonomi çıpası… | `app/lib/data/*.dart` |
| Olaylar | Bütün olay metinleri, seçenekleri ve yaş aralıkları | `app/lib/data/event_pool*.dart` |
| Ekranlar | Ekranlar ve yeniden kullanılan bileşenler | `app/lib/ui` |
| Kararlar (D) | Kesinleşmiş kurallar + her kararın kodda geçtiği dosyalar | `DECISIONS.md`, `app/lib`, `app/test` |
| Sorular (Q) | Tasarım kuyruğu, durumları ve kod bağlantıları | `docs/DESIGN_REVIEW_QUEUE.md` |
| Onay bekleyen | `prototypeOnly` işaretli bütün denge sayıları: değeri, ne işe yaradığı, hangi dosyanın kaçıncı satırında | `app/lib` |
| Fikir havuzu | Açık konular | `BACKLOG.md` |
| Ölçümler | Yüzlerce tam hayat oynatılarak üretilmiş ölçüm tabloları | `PROJECT_STATUS.md` |
| Testler | Hangi testin hangi sistemi koruduğu, test başlıklarıyla | `app/test` |
| CI koşuları | Bütün GitHub Actions koşuları: sonuç, süre, dal, commit | `ci_runs.json` önbelleği |
| Hata kayıtları | Hata düzeltmesi commit'leri | git |
| Dokümanlar | Belgeler ve ne işe yaradıkları | `*.md`, `docs/*.md` |
| Hareketler | Bütün commit geçmişi | git |

`Ctrl+K` her şeyde arar: `D-116`, `Q-189`, bir commit kısa kodu, bir meslek
adı, bir olay metni, bir `prototypeOnly` sayısı ya da bir test dosyası.

**Onay bekleyen sayılar** bölümü özellikle işe yarar: oyunun çalıştığı ama
`DECISIONS.md`'de kesin kural olmayan bütün denge değerleri orada, kod
açıklamalarıyla birlikte. Hangi sayının onayını bekliyorum sorusunun cevabı.

## Tazeleme

Depo kökünden:

```
python3 docs/planner/build.py
```

`index.html` yeniden üretilir. Başka hiçbir şey gerekmez; Python 3 yeter,
bağımlılık yok.

Yalnızca veriyi görmek için: `python3 docs/planner/build.py --json`

### CI geçmişi

`build.py` **ağa çıkmaz**; CI koşularını `ci_runs.json` önbelleğinden okur.
Önbelleği tazelemek için ayrıca:

```
python3 docs/planner/fetch_ci.py --all
```

`gh` komutu gerekir. Ağ kapalıysa ya da `gh` yoksa betik hata verir ve
mevcut önbelleğe dokunmaz; pano da eski geçmişle üretilmeye devam eder.

## Her paketin sonunda

1. `docs/planner/tasks.tsv` dosyasına paketin görevlerini ekleyin.
   Biçim: `durum<TAB>başlık`. Durum `completed`, `in_progress` ya da
   `pending`. Başlık `Paket XX/n: …` kalıbını izlerse pano paketi ve
   modülü kendiliğinden tanır.
2. `python3 docs/planner/build.py` çalıştırın.
3. İsterseniz `python3 docs/planner/fetch_ci.py --all` ile CI geçmişini
   tazeleyin.
4. `docs/planner/index.html`, `tasks.tsv` ve (tazelediyseniz)
   `ci_runs.json` dosyalarını commit'e ekleyin.

Karar, soru, backlog, kod ölçüsü, içerik ve commit verisi **elle
güncellenmez** — betik onları her çalıştığında depodan yeniden okur.

## Sınırlar

- **Pano salt okunurdur.** Buradan karar verilemez, görev durumu
  değiştirilemez. Tek doğruluk kaynağı depodur; bir soru yalnızca
  Faho'nun onayıyla karara dönüşüp `DECISIONS.md`'ye girer.
- **Modül ↔ paket eşlemesi bu panonun sınıflandırmasıdır.** Depoda modül
  etiketi tutulmuyor; eşleme `build.py` içindeki `MODULLER` listesinde
  duruyor. Dosya, satır, test ve commit sayıları ise doğrudan depodan.
- `docs/` CI'ın `paths-ignore` listesinde olduğundan panoyu güncellemek
  CI koşusu başlatmaz.
