"""Oyunun yazı tiplerini yeniden üretir.

Google Fonts deposundaki kaynak dosyaları indirir, Baloo 2'nin değişken
sürümünden sabit ağırlıklar çıkarır ve her iki aileyi de oyunun
kullandığı karakterlere indirger (Latin + Türkçe + noktalama + ₺).

Kullanım:  python3 tool/fetch_fonts.py
Gereken:   pip install fonttools
"""

import os
import subprocess
import sys

from fontTools.ttLib import TTFont
from fontTools.varLib import instancer
from fontTools import subset

KAYNAK = 'https://raw.githubusercontent.com/google/fonts/main'
HEDEF = os.path.join(os.path.dirname(__file__), '..', 'assets', 'fonts')

# Oyunda geçen karakterler. Bilinmeyen bir karakter çıkarsa Flutter
# sistem yazı tipine düşer; oyun bozulmaz.
KOD_ARALIKLARI = (
    'U+0020-007E,U+00A0-00FF,U+0100-017F,U+2018-201D,'
    'U+2026,U+20BA,U+20AC,U+00A9,U+2192,U+00B7,U+2013,U+2014'
)

AGIRLIKLAR = (400, 500, 600, 700, 800)


def indir(yol: str, hedef: str) -> None:
    kod = subprocess.run(
        ['curl', '-sS', '-o', hedef, '-w', '%{http_code}',
         f'{KAYNAK}/{yol}', '--max-time', '90'],
        capture_output=True, text=True,
    ).stdout.strip()
    if kod != '200':
        sys.exit(f'{yol} indirilemedi (HTTP {kod})')


def kucult(font: TTFont, cikti: str) -> None:
    secenekler = subset.Options()
    secenekler.layout_features = ['*']
    secenekler.name_IDs = ['*']
    secenekler.notdef_outline = True
    kesici = subset.Subsetter(options=secenekler)
    kesici.populate(unicodes=subset.parse_unicodes(KOD_ARALIKLARI))
    kesici.subset(font)
    font.save(cikti)


def main() -> None:
    os.makedirs(HEDEF, exist_ok=True)

    indir('ofl/baloo2/Baloo2%5Bwght%5D.ttf', '/tmp/Baloo2-var.ttf')
    for agirlik in AGIRLIKLAR:
        font = TTFont('/tmp/Baloo2-var.ttf')
        instancer.instantiateVariableFont(
            font, {'wght': agirlik}, inplace=True, updateFontNames=True,
        )
        kucult(font, os.path.join(HEDEF, f'Baloo2-{agirlik}.ttf'))

    indir('ofl/patrickhand/PatrickHand-Regular.ttf', '/tmp/PatrickHand.ttf')
    kucult(TTFont('/tmp/PatrickHand.ttf'),
           os.path.join(HEDEF, 'PatrickHand-Regular.ttf'))

    indir('ofl/baloo2/OFL.txt', os.path.join(HEDEF, 'OFL-Baloo2.txt'))
    indir('ofl/patrickhand/OFL.txt',
          os.path.join(HEDEF, 'OFL-PatrickHand.txt'))

    # Türkçe harfler gerçekten geldi mi?
    for ad in os.listdir(HEDEF):
        if not ad.endswith('.ttf'):
            continue
        harfler = TTFont(os.path.join(HEDEF, ad)).getBestCmap()
        eksik = ''.join(h for h in 'çÇğĞıİöÖşŞüÜ' if ord(h) not in harfler)
        if eksik:
            sys.exit(f'{ad} Türkçe harf taşımıyor: {eksik}')
    print('Yazı tipleri hazır.')


if __name__ == '__main__':
    main()
