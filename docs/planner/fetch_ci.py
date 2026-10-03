#!/usr/bin/env python3
"""CI koşu geçmişini GitHub'dan çekip `ci_runs.json` önbelleğine yazar.

Panonun kendisi **çevrimdışı** üretilir: `build.py` yalnızca bu önbelleği
okur, ağa çıkmaz. Geçmişi tazelemek isteyince bu betik ayrıca çalıştırılır.

Kullanım (depo kökünden):
    python3 docs/planner/fetch_ci.py            # son 400 koşu
    python3 docs/planner/fetch_ci.py --all      # elden geldiğince geriye

`gh` komutu gerekir (Claude Code ortamında hazır gelir). Yoksa ya da ağ
kapalıysa betik hata verir ve mevcut önbelleğe dokunmaz.
"""
import json
import os
import subprocess
import sys

DEPO = 'fahrettinkoksal/bir--m-r'
BURASI = os.path.dirname(os.path.abspath(__file__))
CIKTI = os.path.join(BURASI, 'ci_runs.json')
SAYFA = 100

TUT = ('id', 'name', 'head_branch', 'head_sha', 'status', 'conclusion',
       'run_number', 'event', 'created_at', 'updated_at', 'run_started_at',
       'html_url', 'display_title')


def sayfa_cek(no: int) -> dict:
    komut = ['gh', 'api',
             'repos/%s/actions/runs?per_page=%d&page=%d' % (DEPO, SAYFA, no)]
    ham = subprocess.run(komut, capture_output=True, text=True, timeout=120)
    if ham.returncode != 0:
        raise SystemExit('gh api başarısız (sayfa %d):\n%s'
                         % (no, ham.stderr.strip()[:500]))
    return json.loads(ham.stdout)


def main() -> None:
    hepsi = '--all' in sys.argv
    sinir = 999 if hepsi else 4          # 4 sayfa = 400 koşu
    kosular, toplam = [], None
    for no in range(1, sinir + 1):
        veri = sayfa_cek(no)
        if toplam is None:
            toplam = veri.get('total_count', 0)
        parca = veri.get('workflow_runs', [])
        if not parca:
            break
        for r in parca:
            kosular.append({k: r.get(k) for k in TUT})
        print('  sayfa %d · %d koşu' % (no, len(parca)), file=sys.stderr)
        if len(kosular) >= (toplam or 0):
            break

    kosular.sort(key=lambda r: r['created_at'], reverse=True)
    with open(CIKTI, 'w', encoding='utf-8') as fh:
        json.dump({'repo': DEPO, 'total': toplam, 'runs': kosular},
                  fh, ensure_ascii=False, indent=1)
    basarili = sum(1 for r in kosular if r['conclusion'] == 'success')
    print('ci_runs.json yazıldı — %d koşu (depoda toplam %s), %d başarılı'
          % (len(kosular), toplam, basarili), file=sys.stderr)


if __name__ == '__main__':
    main()
