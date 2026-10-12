#!/usr/bin/env python3
"""Değişen dosyaları **gerçekten gezen** testleri bulur.

Neden var
---------
Depo kuralı şöyle: motor/bot/zar akışı değişiyorsa **tam süit**, yalnızca
ekran ya da metin değişiyorsa **hedefli küme**. Hedefli kümeyi seçmek
kulağa kolay geliyor ama Paket CV'de bir CI turuna mal oldu.

Olan şu: `activities_screen.dart` değişti, kümeyi
`grep -rl 'ActivitiesScreen|activity_|ActivityVenue' test/` ile seçtim.
Aktivite ekranını gezen **14 dosya** bu desene uymuyordu;
`martial_arts_widget_test.dart` onlardan biriydi ve tam o test gerçek
bir gerilemeyi yakalayacaktı (7 yaşındaki oyuncunun karatesi kapanmıştı).
Hata yerelde değil CI'da çıktı.

Sebep: o test ne sınıf adını ne anahtarı anıyor — ekrana **görünen
metinle** dokunuyor (`tapMenuRow(tester, 'Spor salonu')`). Dosya adına
ya da sınıf adına bakan bir grep bunu asla bulamaz.

Bu betik aynı işi beş ayrı sinyalle yapar ve hangi sinyalin tuttuğunu
yazar. Ağa çıkmaz, depo kökünden çalışır:

    python3 scripts/test_secimi.py app/lib/ui/screens/sections/activities_screen.dart
    python3 scripts/test_secimi.py --degisenler        # git diff'ten al
    python3 scripts/test_secimi.py --degisenler --komut  # flutter test satırı

Beş sinyal
----------
1. **Doğrudan içe alma** — test, değişen dosyayı `import` ediyor.
2. **Bir adım dolaylı** — test, değişen dosyayı içe alan bir lib
   dosyasını içe alıyor.
3. **Simge** — değişen dosyada tanımlanan genel sınıf/işlev/sabit adı
   testte geçiyor.
4. **Anahtar** — değişen dosyada yazılan `Key('...')` değeri testte
   geçiyor.
5. **Görünen metin** — değişen dosyadaki Türkçe arayüz metni (menü
   başlığı, düğme yazısı) testte geçiyor. **Paket CV'yi kaçıran sinyal
   buydu.**

Çıktı bir öneridir, kesin değildir: betik "şunlar da koşsun" der, "tam
süit gerekmiyor" demez. Motor, bot, zar akışı ya da hüküm matematiği
değiştiyse kural hâlâ tam süit.
"""

from __future__ import annotations

import os
import re
import subprocess
import sys

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(KOK, 'app', 'lib')
TEST = os.path.join(KOK, 'app', 'test')

# Motor/akış dosyası değiştiğinde tam süit şart; betik bunu söyler.
TAM_SUIT_DESENLERI = (
    'domain/generation/',
    'domain/events/',
    'state/game_controller.dart',
    'test/support/player_bot.dart',
    'test/support/coverage_bot.dart',
)


def dart_dosyalari(klasor: str) -> list[str]:
    out: list[str] = []
    for kok, _, dosyalar in os.walk(klasor):
        out += [
            os.path.join(kok, d) for d in dosyalar if d.endswith('.dart')
        ]
    return sorted(out)


def oku(yol: str) -> str:
    try:
        with open(yol, encoding='utf-8') as f:
            return f.read()
    except OSError:
        return ''


def paket_yolu(lib_yolu: str) -> str:
    """`app/lib/a/b.dart` -> `package:bir_omur/a/b.dart`."""
    rel = os.path.relpath(os.path.abspath(lib_yolu), LIB).replace(os.sep, '/')
    return 'package:bir_omur/' + rel


def simgeler(metin: str) -> set[str]:
    """Dosyada tanımlanan genel adlar (sınıf, enum, üst düzey işlev/sabit)."""
    out: set[str] = set()
    out |= set(re.findall(r'^(?:abstract\s+)?(?:final\s+)?class\s+(\w+)',
                          metin, re.M))
    out |= set(re.findall(r'^enum\s+(\w+)', metin, re.M))
    out |= set(re.findall(r'^(?:const|final)\s+[\w<>,\s?]+\s+(k\w+)\s*=',
                          metin, re.M))
    out |= set(re.findall(r'^\w[\w<>,\s?]*\s+(\w+)\s*\(', metin, re.M))
    # Tek harfli ve çok kısa adlar gürültü üretir.
    return {s for s in out if len(s) > 3 and not s.startswith('_')}


def anahtarlar(metin: str) -> set[str]:
    return set(re.findall(r"Key\('([^']+)'\)", metin))


def gorunen_metinler(metin: str) -> set[str]:
    """Arayüzde görünen Türkçe metinler.

    Ölçüt kaba ama işe yarıyor: en az iki sözcük ya da Türkçe'ye özgü
    harf içeren, yeterince uzun tek satırlık dizgeler. Yer tutucu,
    kimlik ve yol gibi dizgeler atılır.
    """
    out: set[str] = set()
    for d in re.findall(r"'([^'\\\n]{6,60})'", metin):
        if any(ch in d for ch in '{}$/:_<>#'):
            continue
        if d != d.strip():
            continue
        turkce = any(ch in d for ch in 'çğıöşüÇĞİÖŞÜ')
        if ' ' in d or turkce:
            out.add(d)
    return out


# Betiğin kendi gerilemesini yakalayan durum (Paket CW).
#
# Paket CV'de kaçan tam bu eşleşmeydi: `activities_screen.dart`
# değiştiğinde `martial_arts_widget_test.dart` kümeye girmeliydi, çünkü
# o test ekrana görünen metinle dokunuyor (`'Spor salonu'`). Sinyaller
# bozulursa `--kendini-sina` kırmızı döner.
KENDINI_SINA = [
    (
        'app/lib/ui/screens/sections/activities_screen.dart',
        'test/martial_arts_widget_test.dart',
    ),
    (
        'app/lib/domain/economy/living_costs.dart',
        'test/paket_cu_yalnizlik_iddiasi_test.dart',
    ),
    # **Yalnızca "metin" sinyalinin tuttuğu çift.** İlk iki çift
    # anahtar ya da içe-alma ile de tutuyordu; yani metin sinyali
    # bozulsa bile sınav yeşil kalıyordu — yanlış güven. Bu çift
    # yalnızca görünen arayüz metniyle eşleşir, dolayısıyla o sinyali
    # gerçekten çiviler.
    (
        'app/lib/ui/screens/sections/activities_screen.dart',
        'test/adoption_widget_test.dart',
    ),
]


def kendini_sina(adaylar_bul) -> int:
    hata = 0
    for hedef, beklenen in KENDINI_SINA:
        adaylar = {t for t in adaylar_bul([hedef])}
        if beklenen in adaylar:
            print('TAMAM  %s -> %s' % (hedef, beklenen))
        else:
            hata += 1
            print('HATA   %s kümesinde %s yok (%d aday bulundu)'
                  % (hedef, beklenen, len(adaylar)))
    if hata:
        print('\n%d eşleşme kayboldu: sinyaller bozulmuş olabilir.' % hata)
    return 1 if hata else 0


def main() -> int:
    argv = sys.argv[1:]
    komut = '--komut' in argv
    sina = '--kendini-sina' in argv
    argv = [a for a in argv if a not in ('--komut', '--kendini-sina')]

    if sina:
        argv = []
    if '--degisenler' in argv:
        try:
            cikti = subprocess.run(
                ['git', 'diff', '--name-only', 'HEAD'],
                cwd=KOK, capture_output=True, text=True, check=True,
            ).stdout
        except (OSError, subprocess.CalledProcessError) as hata:
            print('git diff okunamadı: %s' % hata, file=sys.stderr)
            return 2
        hedefler = [
            y for y in cikti.split('\n')
            if y.startswith('app/lib/') and y.endswith('.dart')
        ]
        if not hedefler:
            print('Değişen lib dosyası yok.')
            return 0
    else:
        hedefler = [a for a in argv if a.endswith('.dart')]

    if not hedefler and not sina:
        print(__doc__)
        return 1

    testler = dart_dosyalari(TEST)
    test_metni = {t: oku(t) for t in testler}
    lib_dosyalari = dart_dosyalari(LIB)
    lib_metni = {l: oku(l) for l in lib_dosyalari}

    tam_suit_gerekir = [
        h for h in hedefler
        if any(d in h.replace(os.sep, '/') for d in TAM_SUIT_DESENLERI)
    ]

    def adaylari_bul(hedef_listesi: list[str]) -> dict[str, set[str]]:
        sonuc: dict[str, set[str]] = {}
        for hedef in hedef_listesi:
            tam = (os.path.join(KOK, hedef)
                   if not os.path.isabs(hedef) else hedef)
            if not os.path.exists(tam):
                continue
            metin = oku(tam)
            pkg = paket_yolu(tam)
            sim = simgeler(metin)
            anh = anahtarlar(metin)
            gor = gorunen_metinler(metin)
            dolayli_pkg: set[str] = set()
            for l, lm in lib_metni.items():
                if pkg in lm or os.path.basename(tam) in lm:
                    dolayli_pkg.add(paket_yolu(l))
            for t, tm in test_metni.items():
                sinyal: set[str] = set()
                if pkg in tm:
                    sinyal.add('içe-alma')
                elif any(d in tm for d in dolayli_pkg):
                    sinyal.add('dolaylı')
                if any(s in tm for s in sim):
                    sinyal.add('simge')
                if any(a in tm for a in anh):
                    sinyal.add('anahtar')
                if any(g in tm for g in gor):
                    sinyal.add('metin')
                if sinyal:
                    rel_t = os.path.relpath(t, os.path.join(KOK, 'app'))
                    sonuc.setdefault(rel_t, set()).update(sinyal)
        return sonuc

    if sina:
        return kendini_sina(lambda h: adaylari_bul(h).keys())

    bulunan_rel = adaylari_bul(hedefler)
    bulunan: dict[str, set[str]] = {}
    rel = sorted(bulunan_rel.items())

    if tam_suit_gerekir:
        print('UYARI — tam süit gerekiyor. Şu dosyalar motor/bot/akış '
              'tarafında:')
        for h in tam_suit_gerekir:
            print('  %s' % h)
        print()

    if komut:
        print('flutter test ' + ' '.join(t for t, _ in rel))
        return 0

    print('Hedef dosya: %d · aday test: %d' % (len(hedefler), len(rel)))
    for t, s in rel:
        print('  %-58s %s' % (t, ' + '.join(sorted(s))))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
