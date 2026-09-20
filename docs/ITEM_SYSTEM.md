# Eşya ve Temel Ekonomi (teknik not)

Bu belge eşya altyapısının **nasıl çalıştığını** anlatır. Açık tasarım
soruları `docs/DESIGN_REVIEW_QUEUE.md` içindeki **Q-041**, **Q-045** ve
**Q-046** maddelerindedir. Bütün sayısal değerler `prototypeOnly`'dir.

## Tek envanter
İkinci bir envanter sistemi yoktur. `GameState.items` envanterdeki **eşya
örneklerini** (`OwnedItem`) tutar; `GameState.possessions` bu listeden
türetilen tür kümesidir ve olay motorunun "şu eşyaya sahip mi?" denetimi
onu kullanmaya devam eder.

- `lib/data/item_catalog.dart` → eşya **türleri**: ad, simge, tür (bisiklet,
  saat, oyuncak, aksesuar …), temel değer, aksesuarın hangi türe takıldığı,
  özel/antika nitelik.
- `lib/domain/models/owned_item.dart` → **örnek**: benzersiz kimlik, tür,
  edinilme yolu (hediye / satın alma / olay), edinildiği yaş, veren kişi,
  kondisyon (0-100), takılı aksesuarlar.
- Hediye kataloğu (`gift_catalog.dart`) ve mağaza (`shop_catalog.dart`) ad
  ve fiyatı aynı tür kataloğundan okur; aynı eşya iki yerde farklı
  adlanmaz veya fiyatlanmaz.

Aynı türden iki eşya **iki ayrı örnektir**: iki bisikletin kondisyonu ve
aksesuarları birbirinden bağımsızdır.

## Eylemler
`actionsFor(ItemKind)` bir türde hangi eylemlerin anlamlı olduğunu söyler;
uymayan eylem **hiç gösterilmez**. Kol saatine bisiklet kornası takılmaz,
kitap sürülmez, yazılmamış otomobil sistemi için düğme konmaz.

- **Kullan** (bisiklete bin / saati tak / oyuncakla oyna): türüne uygun
  değerleri artırır, kondisyonu düşürür. Aynı yaşta tekrarlandıkça kazanç
  azalır ve sıfıra iner; yıpranma devam eder.
- **Temizle**: ücretsizdir, yalnızca kiri giderir. Bir tavanın
  (`prototypeOnlyCleanCeiling`) üstüne çıkaramaz: mekanik hasarı onarmaz.
- **Bakım**: ücretlidir; ücret eksik kondisyonla orantılıdır ve bisiklet
  bakım seti varsa ucuzlar. Kondisyonu sınırlı ölçüde iyileştirir; tavanı
  100 değildir, her hasarı sıfırlamaz.
- **Aksesuar tak**: yalnızca uyumlu aksesuarlar. Takılan aksesuar örneği
  envanterden **düşer** ve eşyanın bağlı parçası olur; böylece aynı zil iki
  bisiklette birden görünmez.
- **Sat**: aşağıya bakın.

Parası yetmeyen işlem gerçekleşmez: kondisyon, aksesuar ve cüzdan
değişmez, ekranda işlem olmuş gibi gösterilmez.

## Mağaza
`Varlıklar → Mağaza`. Yaşa uygun birkaç ürün: bisiklet zili, korna,
reflektör, gidon süsü, bakım seti, yo-yo ve kol saati. Satın alma bedeli
oyuncunun **kendi** cüzdanından bir kez düşer, ürün gerçek bir eşya örneği
olarak envantere girer. Ailenin serveti oyuncunun parası değildir. Kredi,
banka, yatırım, emlak ve otomobil **yok**.

## Değerleme ve satış
Satış bedeli yalnızca ada bakmaz:

```
bedel = temelDeğer × özelÇarpan × (0.25 + 0.75 × kondisyon/100)
        + Σ(takılı aksesuarların temel değeri × 0.5)
bedel = bedel × ikinciElKatsayısı
```

Kondisyon düştükçe değer azalır; antika nitelik çarpan uygular. Satıştan
önce teklif edilen tutar gösterilir ve onay istenir. Onaylanınca eşya
envanterden çıkar, para cüzdana **bir kez** girer ve işlem hayat günlüğüne
yazılır. Vazgeçilirse hiçbir şey değişmez.

Aynı eşya iki kez satılamaz: ilk satıştan sonra kayıt yoktur, satılmış
eşyada bakım veya aksesuar ekranı açık kalmaz.

**Küçük yaş sınırı:** prototipte değerli sayılan eşyalar
(`prototypeOnlyValuableThreshold` üstü) belirli bir yaştan önce
satılamaz. Bu **kesin bir oyun kuralı değildir**; seçenekler Q-045'te.

## Kayıt uyumu
Kayıt biçimi **sürüm 3**.

- **Sürüm 2 → 3:** eski kayıtta eşyalar yalnızca tür kümesiydi
  (`possessions`). Her tür için **tek** bir eşya örneği oluşturulur;
  gereksiz kopya üretilmez. Hediye geçmişi varsa edinilme yolu, veren kişi
  ve yaş oradan doldurulur. Kondisyon, geçmişi bilinmediği için makul bir
  orta değerle başlar.
- **Sürüm 1 → 2 → 3** zinciri çalışır: okul kimlikleri kademeden türetilir,
  hediye geçmişi boş başlar, eşyalar örneklere çevrilir.
- Oyuncunun hayatı, cüzdanı, kişileri ve eşyaları silinmez; kayıt dosyası
  sessizce yeniden başlatılmaz.
