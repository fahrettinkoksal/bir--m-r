# Genel oyun döngüsü — tartışma taslağı v0.1

**Durum:** Bu dosyadaki akış bir ÖNERİDİR, Faho tarafından henüz onaylanmadı. Kesinleşen kurallar `DECISIONS.md` içindedir. Oyun kodu / oynanabilir prototip henüz yok.

## Nereden nereye?
- **Ana hatları belirledik:** Özgün Türkiye yaşam simülasyonu, rastgele doğum ve aile, beş ana karakter değeri, kişi bazlı ilişkiler, geçmiş kararların etkisi, yaş ve koşula uygun olaylar.
- **Aile sisteminin ilk kuralları netleşti:** Aile üyeleri, yaşları, meslekleri, maddi durumları ve aynı evde yaşama ihtimalleri çeşitlidir. Aile sekmesinde kişiler görülebilir, hediye verilebilir, birlikte vakit geçirilebilir.
- **Yeni kesinleşen kural:** Ailenin oyuncuya davranışı ve karşılıklı etkileşimleri yalnızca ilişkiyi değil, ana karakterin değerlerini de değiştirebilir. Hangi etkinliğin hangi değeri ne kadar değiştirdiği açık.
- **Şimdi planlıyoruz:** Oyuncunun her yaşta ne yaptığı ve olay/etkileşim/yaş ilerletmenin nasıl bir döngü oluşturduğu.

## Önerilen bir tur akışı
1. **Hayat ekranı:** Karakterin yaşı, beş ana değeri, güncel kısa yaşam özeti ve yeni gelişmeler görünür.
2. **Serbest etkileşim:** Oyuncu Aile sekmesine gidip var olan bir akrabayla vakit geçirebilir veya hediye verebilir; ileride okul, arkadaş ve kariyer sekmeleri de benzer biçimde çalışabilir. Yaş, mevcut kişi, aynı evde olup olmama, maddi imkânlar ve olay koşulları dikkate alınır. Her etkinlik her zaman yapılabilir olmak zorunda değildir.
3. **Etkiler ve hafıza:** Etkileşim hem ilgili ilişkiyi hem oyuncunun uygun değerlerini değiştirebilir; önemli seçimler gelecekte kullanılmak üzere kaydedilebilir. Oyuncunun yapmadığı, aile bireylerinin kendi hayatında gerçekleşen olaylar da onu etkileyebilir.
4. **Yaş ilerletme:** Oyuncu hazır olduğunda yaşı ilerletir. Olay motoru önce yaşı, aile/okul/iş durumunu, yaşayan ve erişilebilir kişileri, geçmiş kararları kontrol eder; yalnızca uygun olayları gösterir. Seçimlerin etkileri işlenir; aile NPC'lerinin hayatındaki olası değişiklikler de işlenir.
5. **Yeni hayat durumu:** Sonuçlar hayat günlüğüne yansır; aynı insanlarla ilişkiler ve geçmiş sonuçlar sonraki yaşlara taşınır.

**Bu sıralama, yaş ilerletme düğmesi, olay adedi ve serbest etkileşimlerin hangi aşamada yapılabileceği henüz kesin karar değildir.**

## Bir aile etkileşiminin örnek sonucu (yalnızca anlatım, rakamlar yok)
Oyuncu anneannesiyle vakit geçirir → anneanneyle ilişki değişebilir → ana karakterin mutluluğu değişebilir → önemli bir ortak anı saklanabilir → ileride anneanneyle ilgili uygun bir olay farklı seçenek sunabilir. Her seçimin mutlaka bütün değerleri değiştirmesi gerekmez; etki, olayın bağlamına bağlıdır. Ailenin oyuncuya yaptığı bir davranış da oyuncu herhangi bir eylem seçmeden uygun bir karakter değerini etkileyebilir.

## Birlikte netleştireceğimiz genel işleyiş soruları
1. Oyuncu yaşı **kendi istediğinde tek tuşla mı** ilerletecek?
2. Yaş ilerletmeden önce kaç serbest etkileşime izin verilecek? Sınırsız etkileşimle değer kasılması nasıl önlenecek?
3. Bir yaşta kaç zorunlu olay ve kaç isteğe bağlı etkileşim olacak? Kesin sayılar yerine önce tempo kuralı belirlenebilir.
4. Serbest etkileşim ile rastgele olayın farkı nasıl gösterilecek? Aile bireylerinin bağımsız olayları ne zaman duyurulacak?
5. Oyuncu kararlarının sonucu hemen mi yoksa yaş sonunda mı gösterilecek? Hayat günlüğü nasıl tutulacak?
6. Ölüm ve hayatın bitişi nasıl işlenecek; yeni hayata nasıl başlanacak?

## Önerilen ilk karar gündemi
**Önce 1. soru:** 'Yaş ilerlet' düğmesiyle oyuncu ne zaman isterse yeni yaşa geçsin mi? Bunun yanıtı etkileşim sınırını, olay yoğunluğunu ve ekran düzenini belirleyecek. Faho onaylarsa net kural `DECISIONS.md` dosyasına taşınacak.
