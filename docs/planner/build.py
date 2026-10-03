#!/usr/bin/env python3
"""Bir Ömür — geliştirme panosunu depodan üretir.

Tek doğruluk kaynağı depodur. Bu betik hiçbir şey uydurmaz; her sayı ya
bir dosyadan ya git kayıtlarından gelir. Tek istisna modül↔paket
eşlemesidir: o eşleme bu betikte duruyor ve panoda "sınıflandırma"
olarak işaretli.

Çıktı: `docs/planner/index.html` — tarayıcıda açılabilen tek dosya.

Kullanım (depo kökünden):
    python3 docs/planner/build.py          # panoyu yeniden üretir
    python3 docs/planner/build.py --json   # yalnızca veriyi yazdırır

Her paketin sonunda `docs/planner/tasks.tsv` dosyasına yeni görevleri
ekleyip bu betiği çalıştırın; pano güncellenir.
"""
import json
import os
import re
import subprocess
import sys
from collections import Counter, defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import content  # noqa: E402  (yol yukarıda ayarlandı)

BURASI = os.path.dirname(os.path.abspath(__file__))

APP = 'app'   # depo kökünden çalıştırılır


# =====================================================================
# Ortak yardımcılar
# =====================================================================
def duz(metin: str, sinir: int = 0) -> str:
    """Markdown işaretlerini atar."""
    t = metin or ''
    t = re.sub(r'\[([^\]]+)\]\((?:[^)]*)\)', r'\1', t)
    t = re.sub(r'^\s{0,3}#{1,6}\s*', ' · ', t, flags=re.M)
    t = re.sub(r'^\s{0,3}[-*]\s+', ' · ', t, flags=re.M)
    t = t.replace('**', '').replace('`', '')
    t = re.sub(r'\s+', ' ', t).strip()
    if sinir and len(t) > sinir:
        t = t[:sinir].rstrip() + '…'
    return t


def satir_say(yollar) -> tuple:
    """(dosya sayısı, satır sayısı)."""
    d = s = 0
    for y in yollar:
        if os.path.isfile(y):
            d += 1
            with open(y, encoding='utf-8', errors='replace') as fh:
                s += sum(1 for _ in fh)
    return d, s


def dart_dosyalari(klasor: str) -> list:
    out = []
    for kok, _, dosyalar in os.walk(klasor):
        out += [os.path.join(kok, d) for d in dosyalar if d.endswith('.dart')]
    return out


# =====================================================================
# Modüller — ürün sistemleri
# =====================================================================
# dirs: lib altındaki gerçek klasörler · tests: test dosyası anahtar
# kelimeleri · packs: bu modülü ilerleten paket harfleri.
MODULLER = [
    dict(code='CORE', name='Çekirdek & Karakter', tone=0,
         desc='Karakter üretimi, beş değer, yaş alma döngüsü, yaşa bağlı '
              'değer aşınması, hayat günlüğü ve oyun durumu modeli.',
         dirs=['lib/domain/models', 'lib/domain/generation'],
         tests=['stat_', 'aging', 'life_', 'generation', 'character', 'zodiac'],
         packs=['A', 'B', 'G', 'J', 'O']),
    dict(code='HLT', name='Sağlık & Hastalık', tone=1,
         desc='Sağlık bantları, kritik sağlık zorunlu kararı, kronik '
              'hastalık, sağlık geçmişi, hastalık izni, ölüm ve yas.',
         dirs=['lib/domain/life'],
         tests=['health', 'saglik', 'chronic', 'critical', 'paket_aq', 'death'],
         packs=['C', 'Y', 'AQ']),
    dict(code='FAM', name='Aile & İlişkiler', tone=2,
         desc='Soy bağı, hane, ebeveyn boşanması, üvey ve yarım kardeş, '
              'kayın aile, evlilik, çocuk, torun, aile dramaları ve küslük.',
         dirs=['lib/domain/family', 'lib/domain/interaction'],
         tests=['family', 'aile', 'romance', 'child_', 'bond', 'paket_ao',
                'paket_ap', 'pregnancy', 'shared_history', 'generation_cont'],
         packs=['L', 'N', 'R', 'X', 'AO', 'AP']),
    dict(code='EDU', name='Eğitim', tone=3,
         desc='Okula başlama, not ortalaması, lise alan seçimi, sınavlar, '
              'üniversite yerleştirme ve kurs ilerlemesi.',
         dirs=['lib/domain/education'],
         tests=['education', 'school', 'okul', 'exam', 'course', 'paket_an'],
         packs=['H', 'W', 'AJ', 'AN']),
    dict(code='JOB', name='Kariyer & Meslek', tone=4,
         desc='Meslek kataloğu, mülakat, terfi ve zam, ustalık ve itibar, '
              'fiziksel meslek eşikleri, emeklilik.',
         dirs=['lib/domain/career'],
         tests=['career', 'job_', 'meslek', 'retire', 'paket_am'],
         packs=['AM']),
    dict(code='ECO', name='Ekonomi & Yatırım', tone=5,
         desc='Tek ekonomi ölçeği, yaşam gideri, banka ve kredi, piyasa '
              'rejimi, portföy motoru, servet ve miras.',
         dirs=[], globs=['lib/domain/economy/banking.dart',
                         'lib/domain/economy/financial_strain.dart',
                         'lib/domain/economy/household_budget.dart',
                         'lib/domain/economy/investment_engine.dart',
                         'lib/domain/economy/market_engine.dart',
                         'lib/domain/economy/company_engine.dart',
                         'lib/domain/economy/net_worth.dart',
                         'lib/domain/economy/living_costs.dart',
                         'lib/domain/economy/incident_engine.dart',
                         'lib/data/investment_catalog.dart'],
         tests=['economy', 'invest', 'market', 'wealth', 'living_cost',
                'bank', 'portfolio', 'inherit'],
         packs=['E', 'M', 'S', 'AA', 'AC', 'AD']),
    dict(code='BIZ', name='İşletme & Girişim', tone=6,
         desc='İşletme veri modeli, talep ve kâr motoru, fiyat ve reklam, '
              'personel ve bakım, işletme olayları, payback dağılımı.',
         dirs=[], globs=['lib/domain/economy/business*.dart',
                         'lib/data/business*.dart'],
         tests=['business', 'isletme', 'paket_ae', 'paket_af', 'paket_ag',
                'payback', 'entrepreneur'],
         packs=['AE', 'AF', 'AG']),
    dict(code='HOME', name='Konut & Kira', tone=7,
         desc='Konut alım-satım, kiraya verme, kiracı adayları, tahsilat, '
              'konut kondisyonu, bakım ve değer değişimi.',
         dirs=[], globs=['lib/domain/economy/housing.dart',
                         'lib/domain/economy/rental_engine.dart',
                         'lib/domain/economy/property_market.dart'],
         tests=['housing', 'konut', 'rent', 'kira', 'property'],
         packs=['AB']),
    dict(code='EVT', name='Olaylar & Hikâye', tone=8,
         desc='Olay motoru, yaşa ve koşula uygun havuz, çok adımlı '
              'zincirler, hikâye izleri, tekrar kalitesi.',
         dirs=['lib/domain/events'], globs=['lib/data/event_pool*.dart'],
         tests=['event', 'olay', 'priority_event', 'notice'],
         packs=['I']),
    dict(code='ACT', name='Aktivite & Seyahat', tone=9,
         desc='Aktivite kataloğu, mekânlar, yoğunluk, seyahat ve turlar, '
              'evcil hayvanlar, estetik, vasiyet menüsü.',
         dirs=['lib/domain/activities', 'lib/domain/pets', 'lib/domain/hobby'],
         tests=['activit', 'travel', 'seyahat', 'pet_', 'hobby'],
         packs=['D', 'F']),
    dict(code='SOC', name='Sosyal Medya & Ün', tone=10,
         desc='Platformlar, takipçi büyümesi, paylaşım sınırı, sponsorluk, '
              'ün düşüşü ve kendiliğinden teklifler.',
         dirs=['lib/domain/social'],
         tests=['social', 'fame', 'sosyal'],
         packs=['K', 'Q']),
    dict(code='LAW', name='Suç & Hukuk', tone=11,
         desc='Suç eylemleri, yakalanma, dava ve ceza, kefalet, avukat, '
              'cezaevi hayatı ve koğuş arkadaşlıkları.',
         dirs=['lib/domain/law'],
         tests=['law', 'crime', 'suc_', 'prison', 'bail', 'legal'],
         packs=[]),
    dict(code='SPR', name='Spor & Dövüş', tone=12,
         desc='Spor kariyeri, dövüş sanatları, rakipler ve rivalry, '
              'okul-spor çatışması, iş-spor zaman maliyeti.',
         dirs=['lib/domain/combat'],
         tests=['combat', 'sport', 'spor', 'paket_al', 'martial'],
         packs=['AL']),
    dict(code='VEH', name='Araç & Ehliyet', tone=13,
         desc='Ehliyet sınavı, araç sahipliği, 2. el pazarı, muayene, '
              'kaza ve satış, kondisyon ve bakım.',
         dirs=['lib/domain/licensing'],
         globs=['lib/domain/economy/used_vehicle_market.dart',
                'lib/domain/economy/vehicle_*.dart', 'lib/data/vehicle*.dart'],
         tests=['vehicle', 'arac', 'car_', 'licen', 'ehliyet', 'driving'],
         packs=['V', 'Z']),
    dict(code='CAS', name='Kumarhane', tone=14,
         desc='İsteğe bağlı, yalnızca oyun içi parayla çalışan modül: '
              'rulet ve blackjack, harcama limiti, gizlenebilir.',
         dirs=['lib/domain/casino'],
         tests=['casino', 'kumar', 'blackjack'],
         packs=[]),
    dict(code='SAVE', name='Kayıt & Sürüm', tone=15,
         desc='Oyun durumunun kodlanması, eski kayıtların okunabilirliği, '
              'sürüm göçü ve kuşak devamı.',
         dirs=[], dirfiles=['lib/data/save'],
         tests=['save', 'codec', 'kayit', 'migration'],
         packs=[]),
    dict(code='UI', name='Arayüz & Ekranlar', tone=16,
         desc='Hayat, Aile, Ben ekranları, değer şeridi, bildirim ve '
              'sonuç pencereleri, tema, taşma dayanıklılığı.',
         dirs=['lib/ui'],
         tests=['widget', 'screen', 'ekran', 'ui_', 'golden', 'theme'],
         packs=['I']),
    dict(code='QA', name='Ölçüm & Test Altyapısı', tone=17,
         desc='PlayerBot arketipleri, AbuseBot, teşhis turları, yüzlerce '
              'tam hayat ölçümü, değişmezler ve exploit taraması.',
         dirs=[], dirfiles=['test/support'],
         tests=['invariant', 'diagnos', 'teshis', 'bot_', 'abuse', 'olcum',
                'end_to_end', 'consistency'],
         packs=['AH', 'AI', 'Teşhis']),
]


def modul_istatistik() -> list:
    test_dosyalar = [os.path.join(APP, 'test', d)
                     for d in os.listdir(os.path.join(APP, 'test'))
                     if d.endswith('.dart')]
    out = []
    for m in MODULLER:
        kaynak = []
        for d in m.get('dirs', []):
            kaynak += dart_dosyalari(os.path.join(APP, d))
        for d in m.get('dirfiles', []):
            kaynak += dart_dosyalari(os.path.join(APP, d))
        for g in m.get('globs', []):
            import glob as _g
            kaynak += _g.glob(os.path.join(APP, g))
        kd, ks = satir_say(sorted(set(kaynak)))
        eslesen = [t for t in test_dosyalar
                   if any(a in os.path.basename(t) for a in m['tests'])]
        td, ts = satir_say(eslesen)
        out.append(dict(code=m['code'], name=m['name'], desc=m['desc'],
                        tone=m['tone'], packs=m['packs'],
                        dirs=m.get('dirs', []) + m.get('dirfiles', []),
                        files=kd, lines=ks, testFiles=td, testLines=ts))
    return out


# =====================================================================
# Kararlar · Sorular
# =====================================================================
def kararlar() -> list:
    src = open('DECISIONS.md', encoding='utf-8').read()
    out = []
    for m in re.finditer(r'^- \*\*(D-\d+)\s*—\s*(.+?):\*\*\s*(.*)$', src, re.M):
        baslik = m.group(2).strip()
        soru = re.search(r'\((Q-\d+)\)', baslik)
        out.append({
            'id': m.group(1),
            'title': duz(re.sub(r'\s*\(Q-\d+\)\s*', '', baslik)),
            'text': duz(m.group(3)),
            'fromQuestion': soru.group(1) if soru else None,
        })
    return out


def _bolumler(govde: str) -> list:
    yerler = [(x.start(), x.end(), x.group(1).strip())
              for x in re.finditer(r'\*\*([^*:]{2,60}):\*\*', govde)]
    out = []
    onsoz = duz(govde[:yerler[0][0]] if yerler else govde, 1400)
    if len(onsoz) > 40:
        out.append({'label': 'Ayrıntı', 'text': onsoz})
    for i, (_, son, ad) in enumerate(yerler):
        bit = yerler[i + 1][0] if i + 1 < len(yerler) else len(govde)
        out.append({'label': ad, 'text': duz(govde[son:bit], 1600)})
    return [b for b in out if b['text']]


def _soru_durumu(satir: str) -> str:
    d = satir.lower()
    if 'kararlaştırıldı' in d or 'karara bağlandı' in d or 'onaylandı' in d:
        return 'kararlasti'
    if 'kapandı' in d or 'kapatıldı' in d or 'geçersiz' in d:
        return 'kapandi'
    if 'kodlandı' in d or 'uygulandı' in d or 'düzeltildi' in d:
        return 'kodlandi'
    return 'bekliyor'


def sorular() -> list:
    src = open('docs/DESIGN_REVIEW_QUEUE.md', encoding='utf-8').read()
    out = []
    for blok in re.split(r'^### ', src, flags=re.M)[1:]:
        bas, _, govde = blok.partition('\n')
        m = re.match(r'(Q-\d+)\s*—?\s*(.*)', bas)
        if not m:
            continue
        kisim = _bolumler(govde)
        al = lambda ad: next((b['text'] for b in kisim
                              if b['label'].lower().startswith(ad)), '')
        ham = al('durum')
        kaynak_tam = al('kaynak')
        kes = kaynak_tam.find('. ', 160)
        kes = kes + 1 if kes > 0 else min(len(kaynak_tam), 300)
        kisimlar = []
        for b in kisim:
            ad = b['label'].lower()
            if ad.startswith('durum'):
                continue
            if ad.startswith('kaynak'):
                artan = b['text'][kes:].strip(' .·—-')
                if len(artan) > 80:
                    kisimlar.append({'label': 'Ayrıntı', 'text': artan})
                continue
            kisimlar.append(b)
        baslik = duz(m.group(2))
        pak = re.match(r'Paket ([A-Z]+)', baslik)
        out.append({
            'id': m.group(1), 'title': baslik,
            'state': _soru_durumu(ham), 'rawState': duz(ham, 90),
            'source': kaynak_tam[:kes], 'sections': kisimlar[:8],
            'pack': pak.group(1) if pak else None,
        })
    return out


# =====================================================================
# Git
# =====================================================================
HATA_IZ = ('hata', 'bug', 'duzelt', 'düzelt', 'fix', 'kok neden', 'sizint',
           'leak', 'crash', 'cokme')


def commitler() -> list:
    ham = subprocess.check_output(
        ['git', 'log', '--date=short', '--pretty=%H%x1f%ad%x1f%s%x1f%b%x1e']
    ).decode()
    out = []
    for kayit in ham.split('\x1e'):
        kayit = kayit.strip('\n')
        if not kayit:
            continue
        parca = kayit.split('\x1f')
        if len(parca) < 3:
            continue
        sha, tarih, konu = parca[0], parca[1], parca[2]
        govde = parca[3] if len(parca) > 3 else ''
        m = (re.match(r'Paket ([A-Z]+)\b', konu)
             or re.match(r'([A-Z]{1,2})/\d+\b', konu))
        dusuk = konu.lower()
        out.append({
            'sha': sha[:7], 'date': tarih, 'subject': duz(konu),
            'pack': m.group(1) if m else None,
            'bug': any(a in dusuk for a in HATA_IZ),
            'body': duz(govde, 700),
        })
    return out


# =====================================================================
# Görevler
# =====================================================================
def _paket(baslik: str) -> str:
    m = re.match(r'Paket ([A-Z]+)(?:/\d+)?\s*[:§]', baslik)
    if m:
        return m.group(1)
    if baslik.startswith('Teşhis'):
        return 'Teşhis'
    return 'Erken'


def gorevler() -> list:
    ham = open(os.path.join(BURASI, 'tasks.tsv'), encoding='utf-8').read()
    out = []
    for satir in ham.strip().split('\n'):
        if not satir.strip() or satir.startswith('#'):
            continue
        durum, baslik = satir.split('\t', 1)
        out.append({'n': len(out) + 1, 'status': durum.strip(),
                    'title': baslik.strip(), 'pack': _paket(baslik)})
    return out


# =====================================================================
# Backlog · Dokümanlar
# =====================================================================
def backlog() -> list:
    src = open('BACKLOG.md', encoding='utf-8').read()
    out, bolum = [], 'Genel'
    for satir in src.split('\n'):
        b = re.match(r'^##+\s+(.*)', satir)
        if b:
            bolum = duz(b.group(1))
            continue
        m = re.match(r'^-\s+(.*)', satir)
        if not m:
            continue
        metin = m.group(1)
        kapali = metin.strip().startswith('~~')
        t = duz(metin.replace('~~', ''))
        if len(t) < 12 or t.startswith('Şu an bu başlıkta'):
            continue
        out.append({'section': bolum, 'text': t, 'done': kapali})
    return out


DOK_ACIKLAMA = {
    'DECISIONS.md': 'Kesinleşmiş kurallar. Yalnızca Faho onayıyla yazılır.',
    'BACKLOG.md': 'Açık konular ve fikir havuzu; karar değildir.',
    'PROJECT_STATUS.md': 'Güncel ilerleme, paket raporları ve ölçümler.',
    'GAME_BIBLE.md': 'Oyunun dünyası, tonu ve içerik çerçevesi.',
    'SYSTEMS.md': 'Sistemlerin üst düzey haritası.',
    'CLAUDE.md': 'Claude için proje talimatı ve çalışma kuralları.',
    'AGENTS.md': 'Ajan kuralları.',
    'README.md': 'Projeye giriş.',
    'docs/DESIGN_REVIEW_QUEUE.md': 'Tasarım soruları kuyruğu (Q-###).',
}


def dokumanlar() -> list:
    yollar = sorted([d for d in os.listdir('.') if d.endswith('.md')]) + \
        sorted('docs/' + d for d in os.listdir('docs') if d.endswith('.md'))
    out = []
    for y in yollar:
        with open(y, encoding='utf-8', errors='replace') as fh:
            metin = fh.read()
        satir = metin.count('\n') + 1
        bas = re.search(r'^#\s+(.*)', metin, re.M)
        ilk = ''
        for p in metin.split('\n\n')[1:4]:
            p = duz(p, 220)
            if len(p) > 40 and not p.startswith('·'):
                ilk = p
                break
        out.append({'path': y, 'lines': satir,
                    'title': duz(bas.group(1)) if bas else y,
                    'purpose': DOK_ACIKLAMA.get(y, ilk)})
    return out


# =====================================================================
def main() -> None:
    mods = modul_istatistik()
    dec, qs, cms, tks = kararlar(), sorular(), commitler(), gorevler()
    bl, dk = backlog(), dokumanlar()

    # paket → modül eşlemesi (bu betiğin sınıflandırması)
    paket_modul = {}
    for m in mods:
        for p in m['packs']:
            paket_modul[p] = m['code']
    for t in tks:
        t['module'] = paket_modul.get(t['pack'], 'CORE')

    # paket özetleri
    pk = defaultdict(lambda: dict(tasks=0, done=0, commits=0,
                                  first=None, last=None, bugs=0))
    for t in tks:
        d = pk[t['pack']]
        d['tasks'] += 1
        d['done'] += t['status'] == 'completed'
    for c in cms:
        if not c['pack']:
            continue
        d = pk[c['pack']]
        d['commits'] += 1
        d['bugs'] += c['bug']
        d['first'] = c['date'] if not d['first'] else min(d['first'], c['date'])
        d['last'] = c['date'] if not d['last'] else max(d['last'], c['date'])
    paketler = [dict(code=k, module=paket_modul.get(k, 'CORE'), **v)
                for k, v in pk.items()]
    paketler.sort(key=lambda p: (p['first'] or '9999', p['code']))

    # modüle görev/commit sayıları
    gorev_mod = Counter(t['module'] for t in tks)
    tamam_mod = Counter(t['module'] for t in tks if t['status'] == 'completed')
    commit_mod = Counter(paket_modul.get(c['pack']) for c in cms if c['pack'])
    for m in mods:
        m['tasks'] = gorev_mod.get(m['code'], 0)
        m['done'] = tamam_mod.get(m['code'], 0)
        m['commits'] = commit_mod.get(m['code'], 0)
        m['questions'] = sum(1 for q in qs if q['pack'] in m['packs'])

    head = subprocess.check_output(['git', 'rev-parse', 'HEAD']).decode().strip()
    dal = subprocess.check_output(
        ['git', 'rev-parse', '--abbrev-ref', 'HEAD']).decode().strip()

    ol, ic = content.olaylar(), content.icerik()
    icerik_sayi = sum(x['count'] for x in ic)
    olay_havuz = Counter(o['pool'] for o in ol)

    veri = dict(
        events=ol, content=ic,
        meta=dict(
            project='Bir Ömür',
            subtitle='Türkiye odaklı mobil yaşam simülasyonu',
            repo='fahrettinkoksal/bir--m-r',
            branch=dal, head=head[:7],
            generatedFrom='DECISIONS.md · docs/DESIGN_REVIEW_QUEUE.md · '
                          'BACKLOG.md · docs/*.md · app/lib · app/test · git log',
        ),
        modules=mods, packages=paketler, tasks=tks, decisions=dec,
        questions=qs, commits=cms, backlog=bl, docs=dk,
        summary=dict(
            modules=len(mods), packages=len(paketler), tasks=len(tks),
            tasksByStatus=dict(Counter(t['status'] for t in tks)),
            decisions=len(dec), questions=len(qs),
            questionsByState=dict(Counter(q['state'] for q in qs)),
            commits=len(cms), bugCommits=sum(1 for c in cms if c['bug']),
            docs=len(dk), docLines=sum(d['lines'] for d in dk),
            backlogOpen=sum(1 for b in bl if not b['done']),
            backlogDone=sum(1 for b in bl if b['done']),
            codeFiles=sum(m['files'] for m in mods),
            codeLines=sum(m['lines'] for m in mods),
            testFiles=len([d for d in os.listdir(os.path.join(APP, 'test'))
                           if d.endswith('_test.dart')]),
            testLines=satir_say(dart_dosyalari(os.path.join(APP, 'test')))[1],
            firstCommit=min(c['date'] for c in cms),
            lastCommit=max(c['date'] for c in cms),
            days=len({c['date'] for c in cms}),
            events=len(ol), eventPools=len(olay_havuz),
            contentSets=len(ic), contentItems=icerik_sayi,
        ),
    )
    if '--json' in sys.argv:
        json.dump(veri, sys.stdout, ensure_ascii=False, indent=1)
        return

    gomulu = json.dumps(veri, ensure_ascii=False, separators=(',', ':'))
    # `</script>` kapanışına ve HTML ayrıştırıcısına karşı güvenli kodlama.
    for ham, kacis in (('<', '\\u003c'), ('>', '\\u003e'), ('&', '\\u0026')):
        gomulu = gomulu.replace(ham, kacis)

    kalip = open(os.path.join(BURASI, 'template.html'), encoding='utf-8').read()
    if kalip.count('__DATA__') != 1:
        raise SystemExit('template.html içinde tam olarak bir __DATA__ olmalı.')
    cikti = os.path.join(BURASI, 'index.html')
    with open(cikti, 'w', encoding='utf-8') as fh:
        fh.write(kalip.replace('__DATA__', gomulu))

    o = veri['summary']
    print('docs/planner/index.html yazıldı — {:.1f} MB'.format(
        os.path.getsize(cikti) / 1048576), file=sys.stderr)
    print('  {} görev · {} paket · {} modül · {} karar · {} soru'.format(
        o['tasks'], o['packages'], o['modules'], o['decisions'], o['questions']),
        file=sys.stderr)
    print('  {} olay · {} içerik kaydı · {} commit'.format(
        o['events'], o['contentItems'], o['commits']), file=sys.stderr)


if __name__ == '__main__':
    main()
