#!/usr/bin/env python3
"""Oyunun kısa ses efektlerini üretir (Paket 28).

Sesler bu proje için **koddan üretilir**; dışarıdan alınmış ses
kullanılmaz. Betik bağımlılıksızdır (yalnızca standart kütüphane), bu
yüzden sesler her zaman yeniden üretilebilir.

Neden yeniden yazıldı: önceki sesler tek frekanslı düz sinüs tonlarıydı
(ölçüm: her dosyada tek baskın frekans, tepe seviyesi ~%20). Kulağa
"bip" gibi geliyordu ve oyunun el çizimi tonuna uymuyordu. Yenileri
marimba/tahta ve yumuşak çan modellenerek üretildi: her sesin birden
çok harmoniği, doğal sönümü ve kısa bir vuruş anı var.

Kullanım:
    python3 tool/make_sounds.py
"""

import math
import os
import random
import struct
import wave

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sounds')


def env(n, attack=0.004, decay=0.25, curve=3.0):
    """Kısa vuruş + üstel sönüm zarfı."""
    a = max(1, int(attack * SR))
    out = []
    for i in range(n):
        if i < a:
            e = i / a
        else:
            t = (i - a) / SR
            e = math.exp(-t / decay) ** 1.0
        out.append(e ** 1.0 if curve == 1.0 else e)
    return out


def tone(freq, dur, partials, decay, attack=0.004, vibrato=0.0):
    """Toplamalı sentez: her harmonik kendi hızında söner."""
    n = int(dur * SR)
    buf = [0.0] * n
    for mult, amp, dmul in partials:
        f = freq * mult
        d = decay * dmul
        for i in range(n):
            t = i / SR
            e = math.exp(-t / d)
            if e < 1e-4:
                break
            v = 2 * math.pi * f * t
            if vibrato:
                v += vibrato * math.sin(2 * math.pi * 5.0 * t)
            buf[i] += amp * e * math.sin(v)
    # Vuruş anı: ilk milisaniyeler yumuşatılır.
    a = max(1, int(attack * SR))
    for i in range(min(a, n)):
        buf[i] *= i / a
    return buf


def knock(dur, cutoff=0.0012, seed=7):
    """Tahtaya vuruş: kısa filtrelenmiş gürültü."""
    rnd = random.Random(seed)
    n = int(dur * SR)
    buf = []
    prev = 0.0
    for i in range(n):
        x = rnd.uniform(-1, 1)
        # Basit alçak geçiren: yüksek frekans tırmalamasını alır.
        prev = prev + (x - prev) * 0.25
        t = i / SR
        buf.append(prev * math.exp(-t / cutoff))
    return buf


def mix(*bufs):
    n = max(len(b) for b in bufs)
    out = [0.0] * n
    for b in bufs:
        for i, v in enumerate(b):
            out[i] += v
    return out


def delay(buf, seconds):
    return [0.0] * int(seconds * SR) + buf


def normalize(buf, peak=0.62):
    m = max(abs(v) for v in buf) or 1.0
    k = peak / m
    return [v * k for v in buf]


def fade_out(buf, seconds=0.02):
    n = int(seconds * SR)
    for i in range(min(n, len(buf))):
        buf[len(buf) - 1 - i] *= i / n
    return buf


def write(name, buf):
    buf = fade_out(normalize(buf))
    path = os.path.normpath(os.path.join(OUT, name))
    w = wave.open(path, 'wb')
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b''.join(
        struct.pack('<h', max(-32768, min(32767, int(v * 32767)))) for v in buf
    ))
    w.close()
    print(f'{name:14s} {len(buf) / SR * 1000:5.0f} ms')


# Marimba: inharmonik üst sesler, hızlı sönen tiz harmonikler.
MARIMBA = ((1.0, 1.0, 1.0), (3.9, 0.30, 0.45), (9.2, 0.10, 0.22))
# Yumuşak çan: uzun sönüm, yakın aralıklı üst sesler.
CAN = ((1.0, 1.0, 1.0), (2.0, 0.42, 0.75), (2.97, 0.20, 0.5), (4.1, 0.09, 0.3))
# Tahta: kısa, boğuk.
TAHTA = ((1.0, 1.0, 1.0), (2.6, 0.35, 0.4))


def main():
    # --- tap: menüye dokunma. Kısa tahta tıkırtısı.
    write('tap.wav', mix(
        knock(0.05, 0.0010),
        [v * 0.55 for v in tone(880, 0.09, TAHTA, 0.035)],
    ))

    # --- select: onay. İki nota yukarı (mi -> la).
    write('select.wav', mix(
        knock(0.03, 0.0008),
        tone(659.25, 0.20, MARIMBA, 0.13),
        delay([v * 0.85 for v in tone(880.00, 0.20, MARIMBA, 0.15)], 0.055),
    ))

    # --- back: geri. İki nota aşağı, daha yumuşak.
    write('back.wav', mix(
        [v * 0.9 for v in tone(587.33, 0.18, MARIMBA, 0.12)],
        delay([v * 0.7 for v in tone(440.00, 0.22, MARIMBA, 0.16)], 0.06),
    ))

    # --- age_up: yaş alma. Üç nota yukarı; küçük bir kutlama.
    write('age_up.wav', mix(
        tone(587.33, 0.5, MARIMBA, 0.20),
        delay(tone(739.99, 0.5, MARIMBA, 0.22), 0.075),
        delay([v * 1.05 for v in tone(880.00, 0.6, CAN, 0.34)], 0.15),
    ))

    # --- good: olumlu sonuç. Parlak majör arpej.
    write('good.wav', mix(
        tone(523.25, 0.4, MARIMBA, 0.17),
        delay(tone(659.25, 0.4, MARIMBA, 0.19), 0.06),
        delay([v * 0.95 for v in tone(783.99, 0.5, CAN, 0.30)], 0.12),
    ))

    # --- bad: olumsuz sonuç. **Bilerek yumuşak**: ceza değil, kısa bir
    # "olmadı". Alçak, boğuk iki vuruş.
    write('bad.wav', mix(
        [v * 0.9 for v in tone(196.00, 0.30, TAHTA, 0.16)],
        delay([v * 0.65 for v in tone(174.61, 0.34, TAHTA, 0.19)], 0.09),
        [v * 0.25 for v in knock(0.05, 0.0015, seed=3)],
    ))

    # --- notice: bildirim. Yumuşak kapı çanı; iki tonlu, uzun sönümlü.
    # Ekranda önemli bir haber açılıyor: dikkat çekmeli ama ürkütmemeli.
    write('notice.wav', mix(
        tone(783.99, 0.62, CAN, 0.32, vibrato=0.012),
        delay([v * 0.9 for v in tone(1046.50, 0.68, CAN, 0.36, vibrato=0.012)],
              0.13),
        delay([v * 0.28 for v in tone(523.25, 0.7, CAN, 0.42)], 0.13),
    ))


if __name__ == '__main__':
    main()
