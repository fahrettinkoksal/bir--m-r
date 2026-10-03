#!/usr/bin/env python3
"""Depo denetimleri: onay bekleyen sayılar, karar↔kod bağı, testler, ölçümler.

Hepsi doğrudan dosyalardan okunur; hiçbir değer uydurulmaz. Bir alan
okunamazsa atlanır.
"""
import os
import re
from collections import defaultdict

APP = 'app'

# `static const int prototypeOnlyX = 5;` ya da `const double kY = 0.3;`
_SABIT = re.compile(
    r'^[ \t]*(?:static\s+)?(?:const|final)\s+'
    r'(?P<tip>[A-Za-z_][\w<>, ?]*?)\s+'
    r'(?P<ad>[A-Za-z_]\w*)\s*=\s*'
    r'(?P<deger>[^;]+);',
    re.M)


def _dart_dosyalari(kok: str) -> list:
    out = []
    for d, _, dosyalar in os.walk(kok):
        out += [os.path.join(d, x) for x in dosyalar if x.endswith('.dart')]
    return sorted(out)


def _belge(satirlar: list, i: int) -> str:
    """Bildirimin hemen üstündeki `///` satırlarını toplar."""
    out = []
    j = i - 1
    while j >= 0:
        s = satirlar[j].strip()
        if s.startswith('///'):
            out.insert(0, s[3:].strip())
        elif s.startswith('@') or not s:
            if not s and out:
                break
        else:
            break
        j -= 1
    metin = ' '.join(x for x in out if x)
    metin = metin.replace('**', '').replace('`', '')
    return re.sub(r'\s+', ' ', metin).strip()


# ---------------------------------------------------------------------
def onay_bekleyen(modul_coz) -> list:
    """`prototypeOnly` ile işaretli bütün denge sayıları.

    Bunlar Faho'nun onayını bekleyen değerlerdir: koda yazılmıştır ama
    `DECISIONS.md`'de kesin kural değildir.
    """
    out = []
    for yol in _dart_dosyalari(os.path.join(APP, 'lib')):
        metin = open(yol, encoding='utf-8', errors='replace').read()
        if 'prototypeOnly' not in metin:
            continue
        satirlar = metin.split('\n')
        for m in _SABIT.finditer(metin):
            ad = m.group('ad')
            if 'prototypeOnly' not in ad:
                continue
            deger = re.sub(r'\s+', ' ', m.group('deger')).strip()
            if len(deger) > 160:
                deger = deger[:160] + '…'
            satir = metin[:m.start()].count('\n')
            out.append({
                'name': ad,
                'type': m.group('tip').strip(),
                'value': deger,
                'file': yol.replace('\\', '/'),
                'line': satir + 1,
                'module': modul_coz(yol),
                'doc': _belge(satirlar, satir)[:420],
            })
    out.sort(key=lambda x: (x['module'], x['file'], x['line']))
    return out


# ---------------------------------------------------------------------
def karar_kod() -> dict:
    """Hangi karar ve sorunun hangi kaynak dosyalarda geçtiği."""
    kd = defaultdict(set)
    kq = defaultdict(set)
    kokler = [os.path.join(APP, 'lib'), os.path.join(APP, 'test')]
    for kok in kokler:
        for yol in _dart_dosyalari(kok):
            metin = open(yol, encoding='utf-8', errors='replace').read()
            kisa = yol.replace('\\', '/')
            for d in set(re.findall(r'\bD-(\d{3})\b', metin)):
                kd['D-' + d].add(kisa)
            for q in set(re.findall(r'\bQ-(\d{3})\b', metin)):
                kq['Q-' + q].add(kisa)
    return {
        'decisions': {k: sorted(v) for k, v in kd.items()},
        'questions': {k: sorted(v) for k, v in kq.items()},
    }


# ---------------------------------------------------------------------
def testler(test_coz) -> list:
    """Test dosyaları: kaç test, kaç satır, hangi modülü koruyor."""
    kok = os.path.join(APP, 'test')
    out = []
    for yol in _dart_dosyalari(kok):
        ad = os.path.basename(yol)
        if not ad.endswith('_test.dart'):
            continue
        metin = open(yol, encoding='utf-8', errors='replace').read()
        n = len(re.findall(r'^\s*(?:test|testWidgets)\s*\(', metin, re.M))
        grup = re.findall(r"^\s*group\s*\(\s*'((?:[^'\\]|\\.)*)'", metin, re.M)
        basliklar = re.findall(
            r"^\s*(?:test|testWidgets)\s*\(\s*'((?:[^'\\]|\\.)*)'", metin, re.M)
        out.append({
            'file': yol.replace('\\', '/'),
            'name': ad[:-5],
            'tests': n,
            'lines': metin.count('\n') + 1,
            'module': test_coz(ad),
            'groups': [g.replace("\\'", "'") for g in grup][:12],
            'titles': [t.replace("\\'", "'") for t in basliklar][:40],
        })
    out.sort(key=lambda x: -x['tests'])
    return out


# ---------------------------------------------------------------------
_SAYI = re.compile(r'^[\s|]*[-:]+[\s|:-]*$')


def olcumler() -> list:
    """`PROJECT_STATUS.md` içindeki ölçüm tablolarını başlıklarıyla alır.

    Bu tablolar yüzlerce tam hayat oynatılarak üretilmiş gerçek
    ölçümlerdir; panoda okunabilsin diye çıkarılıyor.
    """
    if not os.path.isfile('PROJECT_STATUS.md'):
        return []
    satirlar = open('PROJECT_STATUS.md', encoding='utf-8').read().split('\n')
    out, baslik, ustbaslik = [], '', ''
    i = 0
    while i < len(satirlar):
        s = satirlar[i]
        b = re.match(r'^(#{1,3})\s+(.*)', s)
        if b:
            if len(b.group(1)) == 1:
                ustbaslik = b.group(2).strip()
            baslik = b.group(2).strip()
        if s.strip().startswith('|') and i + 1 < len(satirlar) \
                and _SAYI.match(satirlar[i + 1]):
            basliklar = [c.strip() for c in s.strip().strip('|').split('|')]
            i += 2
            satir = []
            while i < len(satirlar) and satirlar[i].strip().startswith('|'):
                satir.append([c.strip().replace('**', '')
                              for c in satirlar[i].strip().strip('|').split('|')])
                i += 1
            if len(satir) >= 2 and len(basliklar) >= 2:
                out.append({'section': ustbaslik, 'title': baslik,
                            'head': basliklar, 'rows': satir[:60]})
            continue
        i += 1
    return out


# ---------------------------------------------------------------------
def ekranlar() -> list:
    """Arayüz dosyaları: ekranlar ve widget'lar."""
    out = []
    for alt in ('screens', 'widgets'):
        kok = os.path.join(APP, 'lib', 'ui', alt)
        if not os.path.isdir(kok):
            continue
        for yol in _dart_dosyalari(kok):
            metin = open(yol, encoding='utf-8', errors='replace').read()
            siniflar = re.findall(r'^class\s+(\w+)', metin, re.M)
            out.append({
                'file': yol.replace('\\', '/'),
                'name': os.path.basename(yol)[:-5],
                'kind': 'Ekran' if alt == 'screens' else 'Bileşen',
                'lines': metin.count('\n') + 1,
                'classes': siniflar[:10],
            })
    out.sort(key=lambda x: (x['kind'] != 'Ekran', -x['lines']))
    return out


# ---------------------------------------------------------------------
def ci_kosulari() -> dict:
    """`ci_runs.json` önbelleğindeki CI koşu geçmişi.

    Önbellek `fetch_ci.py` ile tazelenir. Burada ağa çıkılmaz: pano
    çevrimdışı üretilebilsin diye geçmiş depoda duruyor.
    """
    import datetime
    import json as _json
    yol = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       'ci_runs.json')
    if not os.path.isfile(yol):
        return {'runs': [], 'cached': False}
    ham = _json.load(open(yol, encoding='utf-8'))
    out = []
    for r in ham.get('runs', []):
        bas, bit = r.get('run_started_at'), r.get('updated_at')
        dk = None
        if bas and bit:
            try:
                a = datetime.datetime.fromisoformat(bas.replace('Z', '+00:00'))
                b = datetime.datetime.fromisoformat(bit.replace('Z', '+00:00'))
                dk = round((b - a).total_seconds() / 60, 1)
            except ValueError:
                dk = None
        out.append({
            'n': r.get('run_number'), 'job': r.get('name', ''),
            'branch': r.get('head_branch', ''), 'sha': (r.get('head_sha') or '')[:7],
            'status': r.get('status', ''), 'result': r.get('conclusion') or 'devam',
            'date': (r.get('created_at') or '')[:10],
            'time': (r.get('created_at') or '')[11:16],
            'minutes': dk, 'title': r.get('display_title', '')[:160],
            'url': r.get('html_url', ''),
        })
    return {'runs': out, 'cached': True, 'total': ham.get('total')}
