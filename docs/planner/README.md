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
| Oyun içeriği | Meslek, eşya, aktivite, şehir, hastalık, şirket… | `app/lib/data/*.dart` |
| Olaylar | Bütün olay metinleri, seçenekleri ve yaş aralıkları | `app/lib/data/event_pool*.dart` |
| Kararlar (D) | Kesinleşmiş kurallar | `DECISIONS.md` |
| Sorular (Q) | Tasarım kuyruğu ve durumları | `docs/DESIGN_REVIEW_QUEUE.md` |
| Fikir havuzu | Açık konular | `BACKLOG.md` |
| Hata kayıtları | Hata düzeltmesi commit'leri | git |
| Dokümanlar | Belgeler ve ne işe yaradıkları | `*.md`, `docs/*.md` |
| Hareketler | Bütün commit geçmişi | git |

`Ctrl+K` her şeyde arar: `D-116`, `Q-189`, bir commit kısa kodu, bir meslek
adı ya da bir olay metni.

## Tazeleme

Depo kökünden:

```
python3 docs/planner/build.py
```

`index.html` yeniden üretilir. Başka hiçbir şey gerekmez; Python 3 yeter,
bağımlılık yok.

Yalnızca veriyi görmek için: `python3 docs/planner/build.py --json`

## Her paketin sonunda

1. `docs/planner/tasks.tsv` dosyasına paketin görevlerini ekleyin.
   Biçim: `durum<TAB>başlık`. Durum `completed`, `in_progress` ya da
   `pending`. Başlık `Paket XX/n: …` kalıbını izlerse pano paketi ve
   modülü kendiliğinden tanır.
2. `python3 docs/planner/build.py` çalıştırın.
3. `docs/planner/index.html` ile `tasks.tsv`'yi commit'e ekleyin.

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
