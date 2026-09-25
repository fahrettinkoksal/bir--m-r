# Bir Ömür — Türkçe metin üslubu

**Kaynak:** Faho'nun 25 Eylül 2026 tarihli talimatı.
**Kapsam:** oyuncunun gördüğü **bütün** metinler — olaylar, seçenekler,
sonuç satırları, bildirimler, etkileşim çıktıları.

Bu belge gelecekte yazılacak her olayın kaynağıdır. Yeni metin yazan
herkes (Claude dahil) önce buraya bakar.

---

## 1. Temel kural

Metin **yaşanmış gibi** okunmalı. Rapor gibi değil.

Oyunun dili:
- doğal Türkçe
- kısa
- yaşayan
- yer yer esprili
- günümüz Türkiye'sine yakın
- hafif sokak ağzı taşıyabilen
- **ama zorla gençlik jargonu basmayan**

---

## 2. Yasak kalıplar

Bunlar olay anlatımında **kullanılmaz**. Robotik duruyorlar:

- "olumlu yönde etkiledi"
- "bu deneyim sonucunda"
- "aranızdaki bağ güçlendi"
- "önemli bir karar verdin"
- "duygusal açıdan"
- "sosyal ilişkilerine katkı sağladı"
- "hayatında yeni bir dönem başladı"
- "kendini daha iyi hissettin"
- "bu durum seni mutlu etti"
- "kaliteli vakit geçirdin"

Gerekirse **sistem sonucu satırında** benzeri bir şey olabilir; ama
anlatının içinde olmaz.

---

## 3. Anlatı ile sistem sonucunu ayır

Bildirim ve olay sonucu iki katmandır:

```
Babanın Gönlü Oldu

"Tamam tamam, uzatma. Al şunu."

Baban cebine biraz harçlık sıkıştırdı.

+1.500 ₺
Baba yakınlığı +2
Mutluluk +1

[Devam]
```

Üst taraf **insan dili**, alt taraf **net oyun verisi**.
Sayıyı cümlenin içine gömüp "mutluluğun arttı" deme; etkiler zaten
ayrı satırda gösteriliyor.

---

## 4. Önce/sonra örnekleri

| Robotik | Doğal |
|---|---|
| "Baban sana harçlık verdi. Bu durum mutluluğunu artırdı." | "Baban cebine biraz para sıkıştırdı. 'Çarçur etme ha,' demeyi de unutmadı." |
| "Arkadaşın seni dışarı davet etti." | "Telefon titredi. Mert: 'Evde çürüme, çık da iki insan görelim.'" |
| "İş görüşmen başarısız oldu." | "Görüşme pek istediğin gibi gitmedi. 'Biz size döneriz' dediler. O cümlenin ne demek olduğunu ikiniz de biliyorsunuz." |
| "Aracında mekanik bir arıza meydana geldi." | "Arabadan pek hayra alamet olmayan bir ses geliyor. Usta kaputu açıp baktı: 'Abi bu ses kendi kendine geçmez.'" |
| "Bahis sonucunda para kaybettin." | "At düzlükte güzel geliyordu... Son 200 metrede bütün hevesini bıraktı. Kupon yattı." |
| "Takipçilerin sponsorlu içeriğine olumsuz tepki gösterdi." | "Sponsorlu paylaşım biraz ters tepti. Yorumlarda 'Abi sen de mi reklamcı oldun?' yazanlar çoğaldı." |

---

## 5. Konuşan kişiye göre dil

| Kim | Ton |
|---|---|
| Çocuk | Basit, doğrudan. Kısa cümle. |
| Ergen | Rahat, utangaç, sivri ya da esprili olabilir. |
| Yakın arkadaş | Samimi. Takılabilir. |
| Anne / baba | Doğal aile dili; korumacı, neşeli ya da kızgın. |
| Dede / nine | Geleneksel; sıcak ya da huysuz. |
| Sevgili / eş | Yakınlığa göre değişir. |
| İş arkadaşı | Yarı samimi. |
| Patron / müdür | Resmî. |
| Banka | Temiz, anlaşılır, espri yok. |
| Sağlık / resmî | Sade. Espri dozu düşük. |

**70 yaşındaki dede, okul müdürü ve banka memuru TikTok yorumcusu gibi
konuşmaz.**

---

## 6. Sokak ağzı

Bağlama göre **kullanılabilir**:

abi · ya · oğlum · hadi ya · iyi bari · neyse · bir garip ·
bu işte bir iş var · cebin yandı · işler sarpa sardı ·
ağzının tadı kaçtı · yüzün güldü · fena yakalandın · işler yolunda ·
pek hayra alamet değil

**Kullanılmaz:** bro · kanka · moruk · aga · lan · aq · internet
meme'leri · her iki cümlede bir emoji.

Her cümlede sokak ağzı olmaz. Serpiştirilir.

---

## 7. Ciddi konularda espri yok

Şu alanlarda sokak ağzı **minimuma** iner, dil sade ve saygılı olur:

- ölüm, cenaze
- ağır hastalık
- gebelik kaybı gibi hassas durumlar
- boşanmanın ağır anları
- ciddi borç, icra
- şiddet
- hayatın sonu
- çocukla ilgili ciddi sorunlar

Komedi oyunu yapmıyoruz. Espri, gündelik hayatın içinde nefes aldıran
unsurdur.

---

## 8. Uzunluk

Mobil oyun. Normal olay **2-4 kısa cümle/paragraf**. Roman yazma.

Seçenekler kısa ve eylem gibi:

✅ "Ara, gönlünü al" · "Boş ver" · "Bir kahve ısmarla" ·
"Patrona söyle" · "Sesini çıkarma"

❌ "Bu konuda onunla konuşmayı tercih et"

---

## 9. Aynı şakayı tekrarlama

Her para olayında "cebin yandı", her kötü olayda "işler sarpa sardı"
yazma. Tekrarlanabilen olaylara 2-4 alternatif anlatım yazılabilir.

---

## 10. Oyuncunun adını gereksiz kullanma

Her olaya "Faho, bugün..." diye başlama. Gerçek hayatta kimse sürekli
adımızı söylemez. İsim yalnızca **doğal diyalogda** geçer:

✅ "Faho... sen daha kendi düzenini yeni kuruyorsun."
❌ "Faho, bugün okula gittin."

---

## 11. Türkiye'ye ait gündelik detaylar

Telif sorunu yaratmadan kullanılabilir:

apartman · mahalle · servis · kantin · okul zili · dolmuş · otobüs ·
pazar · misafirlik · bayram harçlığı · aile grubu · komşu · halı saha ·
düğün · çay · tost · simit · berber · sanayi · apartman toplantısı ·
sıra beklemek · sokakta top oynamak

**Gerçek marka adı kullanılmaz.**

---

## 12. Durumla çelişme

Metin `GameState`'i dikkate alır:

- Baba ölmüşse "baban seni maça götürdü" çıkmaz.
- Kardeş yoksa "kardeşinle kavga ettin" çıkmaz.
- Evi olmayana "evinin aidatı" denmez.

Koşulu `EventRequirement` ile kur; metinde varsayma.

---

## 13. Yer tutucular

Metinde kişiye atıf `{kisi}`, iyelikli bağ `{sahip}` ile yapılır;
oyun bunları gerçek isim ve bağla doldurur. Elle "annen" yazmak yerine
yer tutucu kullanmak, olayın farklı kişilerle çalışmasını sağlar.

---

## 14. Sokak kültürü ve hukuk dili (D-129 eki)

**Kaynak:** Faho'nun 25 Eylül 2026 tarihli ek talimatı. Bu bölüm §5 ve
§6'yı **genişletir**, iptal etmez.

### 14.1 Genel ton

Oyunun tonu "günümüz Türkiye'sinde yaşayan insanların doğal konuşma
biçimi"dir. Şu alanlarda hafif sokak kültürü hissi **kullanılabilir**:

arkadaş · kardeş · mahalle · gençlik · flört · iş arkadaşı · sanayi ·
okul · kahvehane/kafe · sokak olayları

Örnek doğal ifadeler:

- "Abi bu iş pek iyi kokmuyor."
- "Oğlum sen ne yaptın?"
- "İyi bari, ucuz atlattın."
- "Mahallede laf hızlı yayılmış."
- "Usta bir baktı, yüzü düştü."
- "Sen daha ne olduğunu anlamadan ortalık karıştı."
- "Bu işin şakası kalmadı."
- "Başına iş aldın."
- "Millet çoktan konuşmaya başlamış."
- "Bir anlık gazla yaptığın şey pahalıya patladı."

**Yapılmayacak:** her cümlede "abi", her cümlede "oğlum", sürekli "lan",
internet meme'leri, aşırı argo, küfür.

**Anlatıcı** hafif esprili ve doğaldır. **Karakter diyaloğu** karakterin
yaşına, çevresine ve rolüne göre daha sokak ağzı olabilir.

### 14.2 Hukuk alanında kim nasıl konuşur

| Kim | Ton |
|---|---|
| Polis | Kısa ve ciddi. "Şöyle kenara geçelim." |
| Hâkim / savcı | Resmî. Sokak ağzı **yok**. |
| Avukat | Yarı resmî. Garanti vermez. |
| Anne / baba | Doğal aile dili. |
| Arkadaş | Rahat. |

**Polis karikatürleşmez** ("Gel lan buraya" yazılmaz). Hâkim sokak ağzı
kullanmaz. Bu iki kural bir testle sabittir (`test/crime_law_test.dart`).

### 14.3 Suç ve hukukta espri sınırı

Suç ve hukuk olaylarında komedi yapılabilir, **ama ciddi sonuç şakaya
çevrilmez**. Hapis kararı, yaralama ve mahkûmiyet anları §7'nin kapsamına
girer: dil sade ve saygılı olur.

### 14.4 Yazılmayacak içerik

Suç olaylarında **yöntem anlatılmaz**: suç işleme yolu, kaçış, saklanma,
delil ya da denetimden kurtulma hiçbir metinde yer almaz. Olaylar
yüksek seviyede **seçimler** olarak kalır; sonucu motor yürütür.
