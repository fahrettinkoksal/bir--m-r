#!/usr/bin/env python3
"""Oyun içeriğini `app/lib/data` kataloglarından okur.

Kataloglar düzenli Dart yapıcı çağrıları: `GameEvent(id: '...', ...)`.
Burada küçük bir ayrıştırıcı var: parantez/köşeli/süslü dengeler, metin
sabitlerini atlar, bitişik metin parçalarını birleştirir ve üst düzey
`anahtar: değer` çiftlerini çıkarır. Ayrıştırılamayan alan atlanır;
hiçbir değer uydurulmaz.
"""
import os
import re

DATA = 'app/lib/data'   # depo kökünden çalıştırılır


# ---------------------------------------------------------------------
def _blok_sonu(s: str, i: int) -> int:
    """`i` açılış parantezinin eşini bulur; metin sabitlerini atlar."""
    derinlik = 0
    n = len(s)
    while i < n:
        c = s[i]
        if c in "'\"":
            tirnak = c
            ucluk = s[i:i + 3] == tirnak * 3
            i += 3 if ucluk else 1
            while i < n:
                if s[i] == '\\':
                    i += 2
                    continue
                if ucluk and s[i:i + 3] == tirnak * 3:
                    i += 3
                    break
                if not ucluk and s[i] == tirnak:
                    i += 1
                    break
                if not ucluk and s[i] == '\n':
                    break
                i += 1
            continue
        if c in '([{':
            derinlik += 1
        elif c in ')]}':
            derinlik -= 1
            if derinlik == 0:
                return i
        i += 1
    return -1


def _ust_duzey_parcala(govde: str) -> list:
    """Virgülle ayrılmış üst düzey argümanlar."""
    out, derinlik, bas, i, n = [], 0, 0, 0, len(govde)
    while i < n:
        c = govde[i]
        if c in "'\"":
            tirnak = c
            ucluk = govde[i:i + 3] == tirnak * 3
            i += 3 if ucluk else 1
            while i < n:
                if govde[i] == '\\':
                    i += 2
                    continue
                if ucluk and govde[i:i + 3] == tirnak * 3:
                    i += 3
                    break
                if not ucluk and govde[i] == tirnak:
                    i += 1
                    break
                if not ucluk and govde[i] == '\n':
                    break
                i += 1
            continue
        if c in '([{':
            derinlik += 1
        elif c in ')]}':
            derinlik -= 1
        elif c == ',' and derinlik == 0:
            out.append(govde[bas:i])
            bas = i + 1
        i += 1
    if govde[bas:].strip():
        out.append(govde[bas:])
    return out


_METIN = re.compile(r"'((?:[^'\\\n]|\\.)*)'|\"((?:[^\"\\\n]|\\.)*)\"")


def _deger(ham: str):
    """Değeri okunabilir hale getirir: bitişik metinleri birleştirir."""
    t = ham.strip()
    parcalar = _METIN.findall(t)
    if parcalar and _METIN.match(t):
        birlesik = ''.join(a or b for a, b in parcalar)
        birlesik = (birlesik.replace("\\'", "'").replace('\\"', '"')
                    .replace('\\n', ' ').replace('\\\\', '\\'))
        return re.sub(r'\s+', ' ', birlesik).strip()
    sayi = re.fullmatch(r'-?\d+(?:\.\d+)?', t)
    if sayi:
        return float(t) if '.' in t else int(t)
    if t in ('true', 'false'):
        return t == 'true'
    t = re.sub(r'\s+', ' ', t)
    return t[:4000]


def kayitlar(metin: str, sinif: str) -> list:
    """Dosyadaki bütün `Sinif( ... )` çağrılarını sözlüğe çevirir."""
    out = []
    for m in re.finditer(r'\b' + sinif + r'\(', metin):
        acilis = m.end() - 1
        kapanis = _blok_sonu(metin, acilis)
        if kapanis < 0:
            continue
        govde = metin[acilis + 1:kapanis]
        # Yapıcı *tanımı* (`const Foo(this.a, this.b)`) bir kayıt değildir.
        if re.search(r'(^|[,{])\s*(required\s+)?this\.', govde):
            continue
        kayit, sira = {}, 0
        for arg in _ust_duzey_parcala(govde):
            a = re.match(r'\s*([A-Za-z_]\w*)\s*:\s*(.+)', arg, re.S)
            if a:
                kayit[a.group(1)] = _deger(a.group(2))
            elif arg.strip():
                # Konumsal argüman: `FortuneReading('metin', 5)`.
                kayit['p%d' % sira] = _deger(arg)
                sira += 1
        if kayit:
            out.append(kayit)
    return out


def enumlar(metin: str, ad: str) -> list:
    """`enum Ad { deger('Etiket', 'Açıklama', ...), ... }` okur."""
    m = re.search(r'\benum\s+' + ad + r'\s*\{', metin)
    if not m:
        return []
    son = _blok_sonu(metin, m.end() - 1)
    if son < 0:
        return []
    govde = metin[m.end():son]
    govde = govde.split(';')[0]          # metot gövdesini at
    govde = re.sub(r'//[^\n]*', '', govde)   # yorum satırları
    out = []
    for parca in _ust_duzey_parcala(govde):
        p = parca.strip()
        d = re.match(r'([a-zA-Z_]\w*)\s*\((.*)\)\s*$', p, re.S)
        if not d:
            d2 = re.match(r'([a-zA-Z_]\w*)\s*$', p)
            if d2:
                out.append({'id': d2.group(1), 'name': d2.group(1), 'args': []})
            continue
        adli, args = {}, []
        for ham in _ust_duzey_parcala(d.group(2)):
            a = re.match(r'\s*([A-Za-z_]\w*)\s*:\s*(.+)', ham, re.S)
            if a:
                adli[a.group(1)] = _deger(a.group(2))
            else:
                args.append(_deger(ham))
        temiz = lambda v: (isinstance(v, str) and v and
                           not v.startswith('Icons.') and not v.startswith('Color'))
        args = [a for a in args if temiz(a)]
        if adli:
            ad = next((adli[k] for k in ('label', 'name', 'title', 'text')
                       if temiz(adli.get(k))), d.group(1))
            kalan = [str(v) for k, v in adli.items()
                     if k not in ('label', 'name', 'title') and temiz(v)]
            out.append({'id': str(adli.get('id', d.group(1))), 'name': str(ad),
                        'args': kalan[:4]})
        else:
            out.append({'id': d.group(1), 'name': args[0] if args else d.group(1),
                        'args': args[1:]})
    return out


def metin_listeleri(metin: str, adlar: list) -> list:
    """`const List<String> kFoo = <String>[ '...', ... ];` listelerini okur."""
    out = []
    for ad in adlar:
        m = re.search(r'List<String>\s+' + ad + r'\s*=\s*(?:const\s*)?'
                      r'<String>\s*\[', metin)
        if not m:
            continue
        acilis = metin.index('[', m.end() - 1)
        son = _blok_sonu(metin, acilis)
        if son < 0:
            continue
        for p in _ust_duzey_parcala(metin[acilis + 1:son]):
            d = _deger(p)
            if isinstance(d, str) and len(d) > 1:
                out.append({'grup': ad, 'metin': d})
    return out


def sabitler(metin: str) -> list:
    """`static const <tip> ad = deger;` bildirimlerini okur."""
    out = []
    for m in re.finditer(r'(?:static\s+)?const\s+([A-Za-z_][\w<>, ?]*?)\s+'
                         r'([A-Za-z_]\w*)\s*=\s*([^;]+);', metin):
        d = re.sub(r'\s+', ' ', m.group(3)).strip()
        if d.startswith('<') or d.startswith('['):
            continue
        out.append({'tip': m.group(1).strip(), 'ad': m.group(2), 'deger': d[:120]})
    return out


def _oku(dosya: str) -> str:
    y = os.path.join(DATA, dosya)
    if not os.path.isfile(y):
        return ''
    return open(y, encoding='utf-8', errors='replace').read()


# ---------------------------------------------------------------------
# Katalog tanımları: hangi dosyadan, hangi sınıf, hangi alanlar
# ---------------------------------------------------------------------
def _alanlar(kayit: dict, eslem: list) -> dict:
    """[(hedef, kaynak, 'etiket')] eşlemesini uygular."""
    out = {}
    for hedef, kaynak in eslem:
        for k in (kaynak if isinstance(kaynak, (list, tuple)) else [kaynak]):
            if k in kayit and kayit[k] not in (None, ''):
                out[hedef] = kayit[k]
                break
    return out


def _nitelik(kayit: dict, cikar: set) -> list:
    """Geri kalan alanları `etiket: değer` satırlarına çevirir."""
    out = []
    for k, v in kayit.items():
        if k in cikar or v in (None, '', 0, False):
            continue
        if isinstance(v, str) and (v.startswith('<') or v.startswith('const')):
            continue
        if isinstance(v, str) and len(v) > 180:
            v = v[:180].rstrip() + '…'
        out.append({'k': k, 'v': v if not isinstance(v, bool) else 'evet'})
    return out[:14]


def olaylar() -> list:
    out = []
    for d in sorted(os.listdir(DATA)):
        if not d.startswith('event_pool') or not d.endswith('.dart'):
            continue
        havuz = (d.replace('event_pool_', '').replace('event_pool', 'ana')
                 .replace('.dart', ''))
        for k in kayitlar(_oku(d), 'GameEvent'):
            kat = str(k.get('category', '')).replace('EventCategory.', '')
            req = str(k.get('requirement', ''))
            ya = re.search(r'minAge:\s*(\d+)', req)
            yb = re.search(r'maxAge:\s*(\d+)', req)
            sec = re.findall(r"label:\s*'((?:[^'\\]|\\.)*)'", str(k.get('choices', '')))
            out.append({
                'id': k.get('id', ''), 'pool': havuz, 'category': kat,
                'text': k.get('text', ''),
                'minAge': int(ya.group(1)) if ya else None,
                'maxAge': int(yb.group(1)) if yb else None,
                'choices': [c.replace("\\'", "'") for c in sec][:6],
            })
    return out


SETLER = [
    dict(key='jobs', name='Meslekler', file='job_catalog.dart', cls='JobType',
         desc='Başvurulabilen işler: yaş ve eğitim koşulları, yıllık maaş, '
              'kademeler.', mod='JOB',
         ad=['name'], alt=['description'],
         sayi=[('Yıllık maaş', 'yearlySalary', '₺'), ('En az yaş', 'minAge', ''),
               ('En çok yaş', 'maxAge', '')]),
    dict(key='activities', name='Aktiviteler', file='activity_catalog.dart',
         cls='ActivityAction', mod='ACT',
         desc='Ben menüsünden yapılabilen eylemler: bedeli, mekânı ve etkisi.',
         ad=['label', 'name'], alt=['description', 'resultText'],
         sayi=[('Bedel', 'cost', '₺'), ('En az yaş', 'minAge', '')]),
    dict(key='business', name='İşletme türleri', file='business_catalog.dart',
         cls='BusinessType', mod='BIZ',
         desc='Kurulabilen işletmeler: kuruluş bedeli, talep ve kâr davranışı.',
         ad=['name', 'label'], alt=['description'],
         sayi=[('Kuruluş bedeli', ['setupCost', 'cost', 'price'], '₺')]),
    dict(key='invest', name='Yatırım araçları', file='investment_catalog.dart',
         cls='InvestmentType', mod='ECO',
         desc='Portföye alınabilen varlıklar: oynaklık ve risk profili.',
         ad=['name', 'label'], alt=['description'], sayi=[]),
    dict(key='companies', name='Kurgusal şirketler', file='company_catalog.dart',
         cls='Company', mod='ECO',
         desc='Yatırım evrenindeki şirketler. Hepsi kurgusaldır; gerçek şirket '
              'adı kullanılmaz.',
         ad=['name', 'label'], alt=['sector', 'description'], sayi=[]),
    dict(key='cities', name='Şehirler', file='city_catalog.dart',
         cls='CityProfile', mod='CORE',
         desc='Oyun şehirleri ve fiyat/karakter profilleri.',
         ad=['name', 'label', 'id'], alt=['description', 'note'], sayi=[]),
    dict(key='crises', name='Sağlık krizleri', file='health_crisis_catalog.dart',
         cls='HealthCrisis', mod='HLT',
         desc='Hastalık ve kaza kaynaklı krizler: yaş aralığı ve atlatma '
              'ihtimali.',
         ad=['id'], alt=['text'],
         sayi=[('En az yaş', 'minAge', ''), ('En çok yaş', 'maxAge', ''),
               ('Taban atlatma', 'baseSurvival', '')]),
    dict(key='chronic', name='Kronik hastalıklar', file='chronic_catalog.dart',
         cls='ChronicConditionType', mod='HLT',
         desc='Kalıcı tanılar: yıllık sağlık yükü ve bakım masrafı.',
         ad=['label'], alt=['description'],
         sayi=[('Yıllık sağlık kaybı', 'yearlyHealthDrain', ''),
               ('Takipteyken', 'managedDrain', ''),
               ('Yıllık bakım', 'yearlyCareCost', '₺')]),
    dict(key='crime', name='Suç eylemleri', file='crime_catalog.dart',
         cls='CrimeType', mod='LAW',
         desc='Suç menüsündeki eylemler, yakalanma riski ve sonuçları.',
         ad=['label', 'name'], alt=['description'], sayi=[]),
    dict(key='lawyers', name='Avukatlar', file='lawyer_catalog.dart',
         cls='LawyerTier', mod='LAW',
         desc='Dava sırasında tutulabilen avukatlar ve ücretleri.',
         ad=['label', 'name'], alt=['description'],
         sayi=[('Ücret', ['cost', 'fee', 'price'], '₺')]),
    dict(key='tours', name='Tur paketleri', file='tour_catalog.dart',
         cls='TourPackage', mod='ACT',
         desc='Seyahat menüsündeki turlar: süre, bedel ve etkisi.',
         ad=['name', 'label'], alt=['description'],
         sayi=[('Bedel', ['cost', 'price'], '₺'), ('Gece', 'nights', '')]),
    dict(key='items', name='Eşyalar', file='item_catalog.dart', cls='ItemType',
         mod='ECO', desc='Satın alınabilen eşyalar ve değer kaybı.',
         ad=['name', 'label'], alt=['description'],
         sayi=[('Fiyat', ['price', 'cost'], '₺')]),
    dict(key='shop', name='Mağaza ürünleri', file='shop_catalog.dart',
         cls='ShopProduct', mod='ECO',
         desc='Mağaza menüsündeki ürünler ve hangi yaştan sonra açıldığı.',
         ad=['typeId'], alt=['description'],
         sayi=[('Fiyat', ['price', 'cost'], '₺')]),
    dict(key='gifts', name='Hediyeler', file='gift_catalog.dart', cls='GiftItem',
         mod='FAM', desc='Kişilere verilebilen hediyeler.',
         ad=['name', 'label'], alt=['description'],
         sayi=[('Fiyat', ['price', 'cost'], '₺')]),
    dict(key='wedding', name='Düğün biçimleri', file='wedding_catalog.dart',
         cls='WeddingStyle', mod='FAM', desc='Düğün türleri ve bedelleri.',
         ad=['label', 'name'], alt=['description'],
         sayi=[('Bedel', ['cost', 'price'], '₺')]),
    dict(key='proposal', name='Evlilik teklifi biçimleri',
         file='wedding_catalog.dart', cls='ProposalStyle', mod='FAM',
         desc='Teklif seçenekleri: bedeli ve kabul ihtimaline etkisi.',
         ad=['label', 'name'], alt=['description'],
         sayi=[('Bedel', ['cost', 'price'], '₺')]),
    dict(key='uni', name='Üniversite bölümleri', file='university_catalog.dart',
         cls='UniversityProgram', mod='EDU',
         desc='Yerleşilebilen bölümler ve taban koşulları.',
         ad=['name', 'label'], alt=['description'], sayi=[]),
    dict(key='goals', name='Hayat hedefleri', file='life_goal_catalog.dart',
         cls='LifeGoal', mod='CORE',
         desc='Hayat boyunca takip edilen hedefler ve tamamlanma koşulu.',
         ad=['label', 'name', 'title'], alt=['description'], sayi=[]),
    dict(key='social', name='Sosyal medya içerik türleri',
         file='social_catalog.dart', cls='SocialContent', mod='SOC',
         desc='Paylaşılabilen içerik türleri ve takipçi etkisi.',
         ad=['label', 'name'], alt=['description'], sayi=[]),
    dict(key='sponsors', name='Sponsor kategorileri', file='sponsor_catalog.dart',
         cls='SponsorCategory', mod='SOC',
         desc='Kurgusal sponsor alanları ve teklif aralıkları.',
         ad=['label', 'name'], alt=['description'], sayi=[]),
    dict(key='celebs', name='Kurgusal ünlüler', file='celebrity_catalog.dart',
         cls='Celebrity', mod='SOC',
         desc='Sosyal medya olaylarında geçen kurgusal kişiler.',
         ad=['firstName'], alt=['field'],
         sayi=[('Takipçi', 'followers', '')], ek='lastName'),
    dict(key='martial', name='Dövüş sanatı kuşakları',
         file='martial_arts_catalog.dart', cls='MartialRank', mod='SPR',
         desc='Kuşak kademeleri ve gereken ders sayısı.',
         ad=['name'], alt=['note'],
         sayi=[('Gereken ders', 'lessonsNeeded', '')]),
    dict(key='hobby', name='Hobi kademeleri', file='hobby_catalog.dart',
         cls='HobbyStage', mod='ACT',
         desc='Hobide ilerleme kademeleri ve gereken deneyim.',
         ad=['label'], alt=['memory'],
         sayi=[('Deneyim', 'experience', '')]),
    dict(key='interview', name='Mülakat soruları', file='interview_catalog.dart',
         cls='InterviewQuestion', mod='JOB',
         desc='İşe alım mülakatlarında sorulan sorular ve doğru cevaplar.',
         ad=['prompt', 'question', 'text'], alt=['explanation', 'note'], sayi=[]),
    dict(key='bizincident', name='İşletme olayları',
         file='business_incident_catalog.dart', cls='BusinessIncident', mod='BIZ',
         desc='İşletmenin başına gelenler: denetim, afet, personel sorunu, '
              'fırsat.',
         ad=['title', 'label', 'name'], alt=['text', 'description'], sayi=[]),
    dict(key='circuit', name='Dövüş turnuvaları',
         file='combat_circuit_catalog.dart', cls='CombatCircuit', mod='SPR',
         desc='Katılınabilen dövüş organizasyonları, unvanları ve kademeleri.',
         ad=['titleLabel', 'proLabel', 'artId'], alt=['proLabel'], sayi=[]),
    dict(key='coffee', name='Kahve falı okumaları', file='fortune_catalog.dart',
         cls='FortuneReading', mod='ACT',
         desc='Fal metinleri. Oyun içi eğlence; gerçek bir iddiası yok.',
         ad=['p0', 'text'], alt=['p1'], sayi=[]),
    dict(key='tarot', name='Tarot kartları', file='fortune_catalog.dart',
         cls='TarotCard', mod='ACT', desc='Fal menüsündeki kartlar ve anlamları.',
         ad=['p0', 'name'], alt=['p1', 'text'], sayi=[]),
    dict(key='zodiac', name='Astroloji dönemleri', file='fortune_catalog.dart',
         cls='ZodiacPeriod', mod='CORE',
         desc='Fal ve burç içeriğinde geçen dönemler (Merkür retrosu gibi) ve '
              'etkiledikleri elementler.',
         ad=['name', 'label'], alt=['text', 'description'], sayi=[]),
    dict(key='media', name='Medya fırsatları', file='media_catalog.dart',
         cls='MediaOpportunity', mod='SOC',
         desc='Ün arttıkça gelen program, röportaj ve iş birliği teklifleri.',
         ad=['title', 'label', 'name'], alt=['description', 'text'], sayi=[]),
    dict(key='licenseq', name='Ehliyet sınavı soruları',
         file='license_questions.dart', cls='LicenseQuestion', mod='VEH',
         desc='Sınavda sorulan trafik soruları ve açıklamaları.',
         ad=['prompt', 'question', 'text'], alt=['explanation'], sayi=[]),
    dict(key='lottery', name='Piyango ikramiyeleri', file='lottery_catalog.dart',
         cls='LotteryPrize', mod='ECO',
         desc='Çekiliş ikramiyeleri ve kazanma ihtimalleri.',
         ad=['label', 'name'], alt=['description'],
         sayi=[('İkramiye', ['amount', 'prize', 'value'], '₺')]),
    dict(key='edutrack', name='Lise alanları', file='education_tracks.dart',
         cls='EducationTrackInfo', mod='EDU',
         desc='Seçilebilen lise alanları ve açtığı bölümler.',
         ad=['name', 'label'], alt=['description'], sayi=[]),
]

ENUMLAR = [
    dict(key='pets', name='Evcil hayvan grupları', file='pet_catalog.dart',
         en='PetGroup', mod='ACT',
         desc='Sahiplenilebilen hayvan grupları ve karakterleri.'),
    dict(key='military', name='Askerlik yolları', file='military_catalog.dart',
         en='MilitaryTrack', mod='CORE',
         desc='Askerlik seçenekleri: süre, koşul ve sonuçları.'),
    dict(key='licensetype', name='Ehliyet türleri', file='license_catalog.dart',
         en='LicenseType', mod='VEH',
         desc='Motosiklet ve otomobil ehliyeti; birbirinden bağımsız.'),
    dict(key='salaryband', name='Maaş bantları', file='economy.dart',
         en='SalaryBand', mod='ECO',
         desc='Mesleklerin gelir bantları; bütün maaşlar bu ölçeğe oturur.'),
    dict(key='draw', name='Çekiliş türleri', file='lottery_catalog.dart',
         en='LotteryDraw', mod='ECO', desc='Piyango çekiliş biçimleri.'),
    dict(key='edutrackenum', name='Eğitim yolları', file='education_tracks.dart',
         en='EducationTrack', mod='EDU', desc='Eğitim kademeleri ve alanlar.'),
    dict(key='petgrup', name='Evcil hayvan türleri', file='pet_catalog.dart',
         en='PetGroup', mod='ACT', desc='Sahiplenilebilen hayvan grupları.'),
]

# Düz metin listeleri: isim havuzları, tanışma uygulaması satırları.
METINLER = [
    dict(key='finger', name='Tanışma uygulaması metinleri',
         file='finger_catalog.dart', mod='FAM',
         desc='Profil cümleleri, ilgi alanları, eşleşme ve ret satırları.',
         listeler=['kFingerBios', 'kFingerInterests', 'kFingerMatchLines',
                   'kFingerNoMatchLines']),
    dict(key='names', name='İsim havuzu', file='name_pool.dart', mod='CORE',
         desc='Karakter ve evcil hayvan üretiminde kullanılan isimler.',
         listeler=['kadinIsimleri', 'erkekIsimleri', 'evcilHayvanIsimleri',
                   'evcilHayvanTurleri', 'meslekler']),
]

# Sayı sabiti tutan dosyalar: ekonomi çıpası.
SABITLER = [
    dict(key='economy', name='2026 ekonomi çıpası', file='economy.dart',
         mod='ECO',
         desc='Bütün fiyatların, maaşların ve giderlerin dayandığı taban '
              'sayılar. Bir yerde değişirse oyunun tamamı kayar.'),
]

def icerik() -> list:
    out = []
    # Mağaza ürünleri eşya kimliğiyle tutuluyor; adı eşya kataloğundan gelir.
    esya_ad = {}
    for k in kayitlar(_oku('item_catalog.dart'), 'ItemType'):
        if k.get('id') and k.get('name'):
            esya_ad[k['id']] = k['name']
    for s in SETLER:
        metin = _oku(s['file'])
        if not metin:
            continue
        ham = kayitlar(metin, s['cls'])
        if not ham:
            continue
        kayit = []
        for k in ham:
            ad = next((k[a] for a in s['ad'] if k.get(a)), k.get('id', '—'))
            if s['key'] == 'shop':
                ad = esya_ad.get(k.get('typeId', ''), k.get('typeId', '—'))
            if s.get('ek') and k.get(s['ek']):
                ad = str(ad) + ' ' + str(k[s['ek']])
            alt = next((k[a] for a in s['alt'] if k.get(a)), '')
            sayilar = []
            for etiket, alan, birim in s['sayi']:
                for a in (alan if isinstance(alan, (list, tuple)) else [alan]):
                    if isinstance(k.get(a), (int, float)):
                        sayilar.append({'k': etiket, 'v': k[a], 'u': birim})
                        break
            kayit.append({
                'id': k.get('id', ''), 'name': str(ad)[:120],
                'sub': str(alt)[:300], 'nums': sayilar,
                'attrs': _nitelik(k, {'id', 'name', 'label', 'title',
                                      'description', 'text', 'resultText'}),
            })
        out.append({'key': s['key'], 'name': s['name'], 'mod': s.get('mod', ''),
                    'desc': s['desc'], 'file': DATA + '/' + s['file'],
                    'count': len(kayit), 'items': kayit})
    for t in METINLER:
        metin = _oku(t['file'])
        ham = metin_listeleri(metin, t['listeler']) if metin else []
        if not ham:
            continue
        out.append({'key': t['key'], 'name': t['name'], 'mod': t.get('mod', ''),
                    'desc': t['desc'], 'file': DATA + '/' + t['file'],
                    'count': len(ham),
                    'items': [{'id': '', 'name': x['metin'][:160],
                               'sub': x['grup'], 'nums': [], 'attrs': []}
                              for x in ham]})
    for sb in SABITLER:
        metin = _oku(sb['file'])
        ham = sabitler(metin) if metin else []
        if not ham:
            continue
        out.append({'key': sb['key'], 'name': sb['name'], 'mod': sb.get('mod', ''),
                    'desc': sb['desc'], 'file': DATA + '/' + sb['file'],
                    'count': len(ham),
                    'items': [{'id': x['ad'], 'name': x['ad'],
                               'sub': x['tip'] + ' = ' + x['deger'],
                               'nums': [], 'attrs': []} for x in ham]})
    for e in ENUMLAR:
        ham = enumlar(_oku(e['file']), e['en'])
        if not ham:
            continue
        out.append({'key': e['key'], 'name': e['name'], 'mod': e.get('mod', ''),
                    'desc': e['desc'], 'file': DATA + '/' + e['file'],
                    'count': len(ham),
                    'items': [{'id': x['id'], 'name': x['name'],
                               'sub': ' · '.join(x['args'])[:300],
                               'nums': [], 'attrs': []} for x in ham]})
    out.sort(key=lambda x: -x['count'])
    return out
