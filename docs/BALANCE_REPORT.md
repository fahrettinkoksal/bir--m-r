# Denge ölçüm raporu

Bu rapor, Q-055 (ekonomi) ve Q-058 (ölüm) kararlarının istediği ölçümleri
içerir. Ölçüm aracı: `app/tool/balance_report.dart`
(çalıştırma: `app` dizininde `flutter test tool/balance_report.dart`).
Araç oyuna yeni bir sistem eklemez; yalnızca mevcut kurallarla hayat simüle
eder ve sayıları raporlar.

**Buradaki sayılar ölçüm sonucudur, onaylanmış denge kararı değildir.**
Kesin değerler Faho'nun onayıyla belirlenecektir (D-033, D-036).

Ölçüm tarihi: PR #18 kodu (`claude/paket5-olum-miras`), 500 simüle hayat.

---

## 1) Ölüm yaşı dağılımı (Q-058)

| Ölçüt | Değer |
|---|---|
| Ortalama ölüm yaşı | **76,4** |
| Medyan | 79 |
| En küçük / en büyük | 6 / 103 |

| Yaş aralığı | Hayat | Oran |
|---|---|---|
| 0-18 | 4 | **%0,8** |
| 18-40 | 8 | %1,6 |
| 40-60 | 47 | %9,4 |
| 60-70 | 73 | %14,6 |
| 70-80 | 125 | %25,0 |
| 80-90 | 155 | %31,0 |
| 90-100 | 81 | **%16,2** |
| 100+ | 7 | %1,4 |

**Yorum (öneri, karar değil):**
- Çocukluk ölümü **%0,8** — "çocuklukta seyrek" ilkesine uygun (D-036).
- Ortalama 76,4 ve medyan 79, bir hayat simülasyonu için makul bir aralık.
- **Yaşlı uç biraz cömert:** hayatların **%17,6'sı 90 yaşını geçiyor**. Gerçek
  hayattaki orandan yüksek; "çok ileri yaşlar olağan hâle gelmesin" ölçütüne
  göre 85+ ihtimalleri bir miktar artırılabilir.
- **Erken ölümler seyrek ama bir uç var:** en düşük ölüm yaşı 6. 500 hayatta 4
  çocukluk ölümü, oyuncuyu sürekli trajediyle cezalandırmıyor.

## 2) Yakın kayıplar ve kuşak farkları (Q-058)

| Ölçüt | Değer |
|---|---|
| 18 yaşından önce ebeveyn kaybı yaşayan hayat | **%16,4** |
| Hayat başına ortalama yakın aile kaybı | 7,7 |
| Ebeveyn - oyuncu yaş farkı (doğum anı) | en az 17, ortalama 35,3, en çok 60 |
| 16 yaşından küçükken ebeveyn olan kayıt | **0** |
| Büyükebeveyn - oyuncu yaş farkı | en az 35, ortalama 66,4, en çok 104 |
| 32 yıldan küçük iki kuşak farkı | **0** |

**Yorum (öneri, karar değil):**
- **Kuşak farkları tutarlı**: mantıksız genç ebeveyn veya sıkışmış kuşak yok.
  Bu, D-036'nın "NPC yaşları ve kuşak farkları tutarlı olsun" maddesini
  karşılıyor.
- **Çocukken ebeveyn kaybı %16,4 ile yüksek.** Başlangıçta ebeveyn yaşının
  60'a kadar çıkabilmesi bunu besliyor. Oran düşürülecekse iki yol var:
  (a) orta yaş ölüm ihtimalini azaltmak, (b) başlangıçta çok yüksek ebeveyn
  yaşlarını seyrekleştirmek. Karar Faho'ya ait.
- Hayat başına 7,7 yakın kayıp, 76 yıllık bir ömürde büyükanne/büyükbaba,
  ebeveyn ve kardeşleri kapsıyor; beklenen düzeyde.

## 3) Ekonomi: kaç yıllık çalışmayla ne alınır? (Q-055)

Tablolar, **maaşın tamamının birikmesi** (bugünkü kod) ve iki örnek gider
senaryosu için "kaç yıllık maaş" gerektiğini gösterir. Gider sistemi henüz
yazılmadı; %50 ve %70 sütunları yalnızca D-033'ün etkisini görmek içindir.

### Gider yok (bugünkü durum)

| Meslek | Bisiklet | Telefon | Motosiklet | İkinci el oto. | Ekonomik oto. | Küçük daire |
|---|---|---|---|---|---|---|
| Garson | 0,1 | 0,1 | 0,5 | 1,9 | 4,5 | **10,9** |
| Mağaza çalışanı | 0,1 | 0,1 | 0,4 | 1,8 | 4,2 | **10,0** |
| Teknik servis | 0,0 | 0,1 | 0,3 | 1,2 | 2,9 | 6,9 |
| Ressam / tasarımcı | 0,0 | 0,1 | 0,3 | 1,1 | 2,5 | 6,0 |
| Öğretmen | 0,0 | 0,0 | 0,2 | 0,8 | 1,8 | 4,3 |
| Yazılım geliştirici | 0,0 | 0,0 | 0,1 | 0,4 | 1,0 | **2,5** |

### Yıllık gider = maaşın %50'si

| Meslek | İkinci el oto. | Ekonomik oto. | Küçük daire | Standart daire |
|---|---|---|---|---|
| Garson | 3,9 | 9,1 | 21,8 | 38,8 |
| Mağaza çalışanı | 3,6 | 8,3 | 20,0 | 35,6 |
| Teknik servis | 2,5 | 5,8 | 13,8 | 24,6 |
| Ressam / tasarımcı | 2,1 | 5,0 | 12,0 | 21,3 |
| Öğretmen | 1,5 | 3,6 | 8,6 | 15,2 |
| Yazılım geliştirici | 0,9 | 2,1 | 5,0 | 8,9 |

### Yıllık gider = maaşın %70'i

| Meslek | İkinci el oto. | Ekonomik oto. | Küçük daire | Standart daire |
|---|---|---|---|---|
| Garson | 6,5 | 15,2 | 36,4 | 64,6 |
| Mağaza çalışanı | 5,9 | 13,9 | 33,3 | 59,3 |
| Teknik servis | 4,1 | 9,6 | 23,1 | 41,0 |
| Ressam / tasarımcı | 3,6 | 8,3 | 20,0 | 35,6 |
| Öğretmen | 2,5 | 6,0 | 14,3 | 25,4 |
| Yazılım geliştirici | 1,5 | 3,5 | 8,3 | 14,8 |

**Meslekler arası fark:** en düşük 165.000 ₺/yıl, en yüksek 720.000 ₺/yıl
(**4,4x**). En yüksek ile ikinci sıra arasındaki fark 1,7x; tek meslek
diğerlerini anlamsızlaştırmıyor (D-033).

**Yorum (öneri, karar değil):**
- **Gider olmadan ekonomi fazla cömert:** yazılımcı 2,5 yılda, asgari düzeydeki
  bir meslek 10 yılda küçük daire alıyor; hiçbir kalem para götürmüyor.
- **Gider maaşın %50'si civarındayken** tablo okunaklı hâle geliyor: ikinci el
  otomobil 1-4 yıl, küçük daire 5-22 yıl. Bu aralık, "birkaç yıllık çalışmayla
  neye ulaşılır" ölçütünü karşılıyor.
- **%70 gider** alt gelirli meslekleri konuttan fiilen dışlıyor (33-36 yıl);
  kredi gelene kadar bu sert olabilir.
- Gider oranı **hane durumuna göre** değişeceği için (D-033: ailesiyle yaşayan
  ile bağımsız yaşayan farklı), tek bir oran yerine iki kademeli bir yapı
  öneririm: **ailesiyle yaşayan yetişkin için düşük, bağımsız yaşayan için
  yüksek**. Kesin oranlar Faho'nun kararı.

---

## Ölçümün sınırları

- Simülasyon, oyuncunun **iş bulduğu senaryoyu oynamaz**: tablolar "bu maaşla
  çalışıldığında" varsayımıyla hesaplanmış oran tablolarıdır.
- Kumar, miras ve hediye gelirleri tablolara dâhil değildir; bunlar ekonomiyi
  ayrıca hızlandırır.
- Ölüm dağılımı, mevcut olasılık eğrisinin ölçümüdür; olay tabanlı ölümler
  (kaza/hastalık) henüz yoktur (D-036).
