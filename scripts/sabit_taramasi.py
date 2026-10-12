#!/usr/bin/env python3
"""Onaysız sayıları üç hata deseni için tarar.

Neden var
---------
Paket BA'da elle yapılan tarama üç gerçek hata buldu ve her seferinde
betiği yeniden yazmak gerekti. Bu dosya o işi tekrarlanabilir yapar:
depo kökünden `python3 scripts/sabit_taramasi.py` yeter, ağa çıkmaz.

Aranan üç desen
---------------
1. **Ölü sabit** — bildirilmiş ama hiçbir yerde okunmuyor. Yanındaki
   belge yorumu yüzünden yürürlükteki kural gibi görünür, oysa değildir.
   (Paket BA'da 19 tane çıktı; en ağırı `JobMarket`'ın hiç kullanılmayan
   "işe alım olasılığı" modeliydi.)
2. **Doymuş tavan** — birden çok bileşenin toplamı bir tavana
   kıstırılıyor ve tek bileşen tavanı tek başına dolduruyor; o noktadan
   sonra diğerleri **hiç** sayılmaz. (D-169, D-176, D-178.)
3. **Dekoratif eşik** — eşik, karşılaştırıldığı değerin erişebileceği
   aralığın dışında kalıyor; hiçbir şeyi elemez ya da her şeyi eler.
   (D-164: deneme eşiği 62'ydi, en zayıf aday 63 puanla geliyordu.)

Betiğin sınırı — **okunması gereken yer**
-----------------------------------------
Yalnızca 1. desen kesin karar verir. 2 ve 3 için betik **aday** çıkarır;
hangisinin gerçek hata olduğu ölçümle anlaşılır. Çünkü bir tavanın
doyup doymadığı, bileşenlerin erişebileceği gerçek aralığa bağlıdır ve
bunu kaynak taraması bilemez. Aday listesi kısa tutuldu ki elle
okunabilsin.

Bilinen yanlış pozitif türleri (BA'da ölçüldü):
* `deger + kazanc` biçiminde olup 0-100'e kıstırılan satırlar: oradaki
  tavan **stat tavanıdır**, hata değil.
* `clamp(0, 2)` gibi **dizin** kısıtları (ör. `coachLevel`).
* Yalnızca testin okuduğu sabitler ölü değildir; okuma yüzeyine `test`
  de dahildir.
"""
from __future__ import annotations

import os
import re
import sys

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(KOK, 'app', 'lib')
TEST = os.path.join(KOK, 'app', 'test')

STATIK = re.compile(r'^\s*static\s+(?:const|final)\s+[\w<>?,\s]+\s+(prototypeOnly\w+)\s*=')
ALAN = re.compile(r'^\s*final\s+[\w<>?,\s]+\s+(prototypeOnly\w+)\s*;')
SINIF = re.compile(r'^(?:abstract\s+)?(?:final\s+)?(?:class|enum|extension|mixin)\s+(\w+)')
DEGER = re.compile(r'=\s*([-\d.]+)\s*;')


def dart_dosyalari(*kokler: str) -> list[str]:
    out: list[str] = []
    for kok in kokler:
        for dp, _, fns in os.walk(kok):
            out += [os.path.join(dp, f) for f in fns if f.endswith('.dart')]
    return sorted(out)


def okuyor_mu(satir: str, ad: str) -> bool:
    """Bu satır sabiti **okuyor** mu?

    Bildirim, kurucu parametresi ve adlı argüman okuma sayılmaz:
    `prototypeOnlyBond: 3` bir değer **verir**, o değeri kullanmaz.
    """
    if not re.search(rf'\b{ad}\b', satir):
        return False
    if STATIK.match(satir) or ALAN.match(satir):
        return False
    if re.search(rf'\bthis\.{ad}\b', satir):
        return False
    if re.search(rf'^\s*{ad}\s*:', satir):
        return False
    return True


def tara() -> int:
    lib = dart_dosyalari(LIB)
    hepsi = lib + dart_dosyalari(TEST)
    satir = {p: open(p, encoding='utf-8').read().split('\n') for p in hepsi}
    metin = {p: '\n'.join(satir[p]) for p in hepsi}

    # --- bildirimler -------------------------------------------------
    bildirim = []  # (ad, dosya, sinif, satirNo, statikMi, deger)
    for p in lib:
        sinif = None
        for i, l in enumerate(satir[p]):
            m = SINIF.match(l)
            if m:
                sinif = m.group(1)
            st, al = STATIK.match(l), ALAN.match(l)
            if st or al:
                d = DEGER.search(l)
                bildirim.append((
                    (st or al).group(1), p, sinif, i + 1, st is not None,
                    d.group(1) if d else None,
                ))

    # --- 1) ölü sabit ------------------------------------------------
    olu = []
    for ad, p, sinif, no, statik, _ in bildirim:
        if statik:
            kendi = any(
                i + 1 != no and okuyor_mu(l, ad)
                for i, l in enumerate(satir[p])
            )
            nitelikli = sinif is not None and any(
                f'{sinif}.{ad}' in metin[q] for q in hepsi
            )
            okundu = kendi or nitelikli
        else:
            okundu = any(
                re.search(rf'\.{ad}\b', l) for q in hepsi for l in satir[q]
            )
        if not okundu:
            olu.append(f'{sinif}.{ad}  ({os.path.relpath(p, KOK)}:{no})')

    # --- 2) doymuş tavan adayı ---------------------------------------
    tavan = []
    for p in lib:
        ls = satir[p]
        for i, l in enumerate(ls):
            if '.clamp(' not in l:
                continue
            blok = '\n'.join(ls[max(0, i - 3):i + 1])
            if 'prototypeOnly' not in blok:
                continue
            m = re.search(r'=\s*\(?([^;]*?)\)?\s*\.clamp\(', blok, re.S)
            if not m or m.group(1).count('+') < 1:
                continue
            ifade = ' '.join(m.group(1).split())
            # stat tavanı ve dizin kısıtı yanlış pozitiftir; ayıkla
            if re.search(r'\.clamp\(\s*0\s*,\s*100\s*\)', l):
                continue
            if re.search(r'\.clamp\(\s*0\s*,\s*[1-9]\s*\)', l):
                continue
            tavan.append(f'{os.path.relpath(p, KOK)}:{i + 1}  {ifade[:84]}')

    # --- 3) dekoratif eşik: mekanik olarak karar verilebilen alt sınıf -
    deger = {ad: d for ad, _, _, _, _, d in bildirim if d}
    esik = []
    for p in lib:
        for i, l in enumerate(satir[p]):
            if 'prototypeOnly' not in l:
                continue
            for ad in re.findall(r'\b(prototypeOnly\w+)\b', l):
                d = deger.get(ad)
                if d is None or not re.search(r'[<>]=?', l):
                    continue
                try:
                    v = float(d)
                except ValueError:
                    continue
                kusur = None
                if 'rng.next' in l or 'chance' in l.lower():
                    if '.' in d and v <= 0:
                        kusur = 'olasılık eşiği ≤ 0 — hiç gerçekleşmez'
                    elif '.' in d and v >= 1:
                        kusur = 'olasılık eşiği ≥ 1 — hep gerçekleşir'
                if re.search(r'stats\.\w+|\.bond\b|\.condition\b', l):
                    if '.' not in d and v <= 0:
                        kusur = 'stat eşiği ≤ 0 — hiçbir şeyi elemez'
                    elif '.' not in d and v > 100:
                        kusur = 'stat eşiği > 100 — hiç geçilemez'
                if kusur:
                    esik.append(
                        f'{os.path.relpath(p, KOK)}:{i + 1}  {ad}={d} — {kusur}'
                    )

    # --- rapor -------------------------------------------------------
    print(f'{len(bildirim)} prototypeOnly bildirimi tarandı '
          f'({len(lib)} kaynak dosyası, okuma yüzeyi lib + test)\n')

    print(f'1) ÖLÜ SABİT — kesin bulgu: {len(olu)}')
    for s in olu:
        print(f'   {s}')
    if not olu:
        print('   yok. (Bekçi: app/test/prototype_only_dead_constant_test.dart)')

    print(f'\n2) DOYMUŞ TAVAN — aday, ölçüm gerekir: {len(tavan)}')
    for s in tavan:
        print(f'   {s}')

    print(f'\n3) DEKORATİF EŞİK — mekanik olarak kusurlu: {len(esik)}')
    for s in esik:
        print(f'   {s}')
    if not esik:
        print('   yok. İnce hâli (kapı arkasındaki eşik) elle okunmalı;')
        print('   betik onu göremez, çünkü erişilebilir aralığı bilemez.')

    return 1 if olu else 0


if __name__ == '__main__':
    sys.exit(tara())
