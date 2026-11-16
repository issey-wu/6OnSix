"""Makes the app's sound effects from scratch: pure numpy, no samples.

Writes three candidate sets to build/sounds/: A_bright_chime, B_arcade and
C_soft_pluck. The app uses set A for correct, incorrect, match_pop,
token_snap and chest_open, and set B for lesson_complete and streak; copy
those files into assets/sounds/ to update them.

Usage, from the project root (needs Python 3 with numpy and scipy):
    python3 tool/sounds/synth.py
"""
import os
import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, lfilter

SR = 44100
OUT = os.path.join('build', 'sounds')


def t(dur):
    return np.arange(int(SR * dur)) / SR


def note(n):
    """MIDI note number to Hz."""
    return 440.0 * 2 ** ((n - 69) / 12)


def env(x, a=0.004, d=0.25, curve=5.0):
    n = len(x)
    tt = np.arange(n) / SR
    att = np.clip(tt / a, 0, 1)
    dec = np.exp(-curve * np.maximum(tt - a, 0) / max(d, 1e-3))
    return x * att * dec


def place(buf, x, at):
    i = int(at * SR)
    end = min(len(buf), i + len(x))
    buf[i:end] += x[: end - i]
    return buf


def lowpass(x, hz):
    b, a = butter(2, hz / (SR / 2), 'low')
    return lfilter(b, a, x)


def highpass(x, hz):
    b, a = butter(2, hz / (SR / 2), 'high')
    return lfilter(b, a, x)


def finish(x, peak=0.85, tail=0.02):
    x = np.concatenate([x, np.zeros(int(SR * tail))])
    fade = int(SR * 0.01)
    x[-fade:] *= np.linspace(1, 0, fade)
    m = np.max(np.abs(x)) or 1
    return (x / m * peak).astype(np.float32)


def save(set_name, name, x):
    d = os.path.join(OUT, set_name)
    os.makedirs(d, exist_ok=True)
    wavfile.write(os.path.join(d, name + '.wav'), SR, (x * 32767).astype(np.int16))


# ---------- timbres ----------

def marimba(f, dur=0.45, bright=1.0):
    tt = t(dur)
    x = np.sin(2 * np.pi * f * tt)
    x += 0.35 * bright * np.sin(2 * np.pi * f * 4 * tt) * np.exp(-tt * 30)
    x += 0.15 * bright * np.sin(2 * np.pi * f * 9.9 * tt) * np.exp(-tt * 60)
    return env(x, 0.002, dur * 0.55, 4)


def bell(f, dur=0.8, index=2.2):
    tt = t(dur)
    mod = index * np.exp(-tt * 6) * np.sin(2 * np.pi * f * 3.5 * tt)
    x = np.sin(2 * np.pi * f * tt + mod)
    x += 0.3 * np.sin(2 * np.pi * f * 2 * tt) * np.exp(-tt * 8)
    return env(x, 0.002, dur * 0.6, 4.5)


def pulse(f, dur=0.12, duty=0.25, vib=0.0):
    tt = t(dur)
    ph = np.cumsum(f * (1 + vib * np.sin(2 * np.pi * 12 * tt)) / SR)
    x = np.where((ph % 1) < duty, 1.0, -1.0)
    x = lowpass(x, 7000)
    return env(x * 0.5, 0.002, dur, 2.5)


def pluck(f, dur=0.3):
    tt = t(dur)
    x = np.sin(2 * np.pi * f * tt) + 0.2 * np.sin(2 * np.pi * 2 * f * tt)
    return env(x, 0.003, dur * 0.4, 5)


def sparkle(start, dur, seed=1, count=14, lo=84, hi=100):
    rng = np.random.default_rng(seed)
    buf = np.zeros(int(SR * (dur + 0.4)))
    for _ in range(count):
        n = rng.integers(lo, hi)
        place(buf, 0.12 * bell(note(n), 0.25, 1.2), rng.uniform(0, dur))
    out = np.zeros(int(SR * start) + len(buf))
    out[int(SR * start):] = buf
    return out


def chirp(f0, f1, dur, shape='sine'):
    tt = t(dur)
    f = f0 * (f1 / f0) ** (tt / dur)
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = np.sin(ph) if shape == 'sine' else np.sign(np.sin(ph)) * 0.5
    return x


def noise_whoosh(dur=0.5, lo=400, hi=4000, seed=3):
    rng = np.random.default_rng(seed)
    x = rng.standard_normal(int(SR * dur))
    tt = t(dur)
    # sweep a band by mixing two filtered copies
    a = lowpass(x, hi) - lowpass(x, lo)
    shape = np.sin(np.pi * tt / dur) ** 2
    return a * shape * 0.6


def add(*xs):
    n = max(len(x) for x in xs)
    out = np.zeros(n)
    for x in xs:
        out[: len(x)] += x
    return out


def mix(length, parts):
    buf = np.zeros(int(SR * length))
    for x, at in parts:
        place(buf, x, at)
    return buf


# ---------- Set A: Bright chime (marimba and bells, closest to Duolingo) ----------

def set_a():
    s = 'A_bright_chime'
    # correct: quick rising major sixth, marimba plus bell sparkle
    x = mix(0.6, [(marimba(note(76)), 0), (add(marimba(note(81)), 0.5 * bell(note(93), 0.5)), 0.085)])
    save(s, 'correct', finish(x))
    # incorrect: soft low two-note "bu-bum", muted
    x = mix(0.5, [(lowpass(marimba(note(55), 0.3, 0.3), 1800), 0),
                  (lowpass(marimba(note(50), 0.4, 0.3), 1500), 0.11)])
    save(s, 'incorrect', finish(x, 0.7))
    # pair matched: bubbly pop going up
    x = add(env(chirp(500, 1400, 0.09), 0.001, 0.08, 3), 0.4 * marimba(note(88), 0.2))
    save(s, 'match_pop', finish(x, 0.75))
    # token snapped: woody knock
    x = add(marimba(note(69), 0.12, 0.6), 0.4 * env(highpass(np.random.default_rng(2).standard_normal(int(SR * 0.03)), 2000), 0.0005, 0.02, 4))
    save(s, 'token_snap', finish(x, 0.7))
    # lesson complete: arpeggio up to a ringing chord with sparkles
    notes = [72, 76, 79, 84]
    parts = [(marimba(note(n), 0.5), i * 0.09) for i, n in enumerate(notes)]
    chord = sum(bell(note(n), 1.3, 1.6) for n in (84, 88, 91)) * 0.5
    parts.append((chord, 0.38))
    parts.append((sparkle(0.4, 0.7, 4), 0))
    save(s, 'lesson_complete', finish(mix(2.0, parts)))
    # chest open: lid thunk, then a shimmering rise
    x = mix(1.4, [(lowpass(marimba(note(48), 0.2, 0.2), 900), 0),
                  (0.5 * env(chirp(400, 2400, 0.35), 0.01, 0.35, 1), 0.08),
                  (sparkle(0.15, 0.6, 7, 18, 88, 103), 0),
                  (bell(note(91), 0.9) * 0.6, 0.42)])
    save(s, 'chest_open', finish(x))
    # streak / milestone: whoosh with a rising fifth fanfare
    parts = [(noise_whoosh(0.5), 0),
             (marimba(note(67)), 0.18), (marimba(note(74)), 0.28),
             (sum(bell(note(n), 1.1, 1.8) for n in (79, 83, 86)) * 0.5, 0.38),
             (sparkle(0.4, 0.5, 9), 0)]
    save(s, 'streak', finish(mix(1.7, parts)))


# ---------- Set B: Arcade (chiptune, coin and power-up feel) ----------

def set_b():
    s = 'B_arcade'
    x = mix(0.4, [(pulse(note(83), 0.07), 0), (pulse(note(88), 0.22), 0.07)])
    save(s, 'correct', finish(x, 0.6))
    x = mix(0.45, [(lowpass(pulse(note(52), 0.12, 0.5), 2000), 0),
                   (lowpass(pulse(note(47), 0.25, 0.5, 0.02), 1800), 0.12)])
    save(s, 'incorrect', finish(x, 0.55))
    x = env(chirp(600, 1800, 0.08, 'sq'), 0.001, 0.08, 2)
    save(s, 'match_pop', finish(lowpass(x, 6000), 0.55))
    x = pulse(note(64), 0.05, 0.125)
    save(s, 'token_snap', finish(x, 0.5))
    seq = [72, 76, 79, 84, 79, 84, 88]
    parts = [(pulse(note(n), 0.1), i * 0.08) for i, n in enumerate(seq)]
    parts.append((pulse(note(91), 0.6, 0.25, 0.01), len(seq) * 0.08))
    save(s, 'lesson_complete', finish(mix(1.4, parts), 0.6))
    parts = [(pulse(note(60 + i * 2), 0.05), i * 0.035) for i in range(14)]
    parts.append((pulse(note(96), 0.5, 0.25, 0.015), 0.5))
    save(s, 'chest_open', finish(mix(1.2, parts), 0.6))
    seq = [67, 71, 74, 79, 83, 86]
    parts = [(pulse(note(n), 0.07), i * 0.05) for i, n in enumerate(seq)]
    parts.append((pulse(note(91), 0.5, 0.5, 0.01), 0.32))
    save(s, 'streak', finish(mix(1.1, parts), 0.6))


# ---------- Set C: Soft pluck (calm, plus Kenney CC0 clicks) ----------

def set_c():
    s = 'C_soft_pluck'
    x = mix(0.5, [(pluck(note(79)), 0), (pluck(note(84)), 0.07)])
    save(s, 'correct', finish(x, 0.75))
    x = mix(0.45, [(lowpass(pluck(note(57), 0.25), 1500), 0), (lowpass(pluck(note(53), 0.3), 1300), 0.1)])
    save(s, 'incorrect', finish(x, 0.6))
    x = add(env(chirp(700, 1300, 0.06), 0.001, 0.05, 3), 0.5 * pluck(note(91), 0.15))
    save(s, 'match_pop', finish(x, 0.7))
    x = lowpass(pluck(note(62), 0.09), 2500)
    save(s, 'token_snap', finish(x, 0.65))
    seq = [67, 71, 74, 79]
    parts = [(pluck(note(n), 0.45), i * 0.1) for i, n in enumerate(seq)]
    parts.append((sum(pluck(note(n), 1.0) for n in (79, 83, 86)) * 0.5, 0.42))
    save(s, 'lesson_complete', finish(mix(1.6, parts), 0.75))
    x = mix(1.0, [(pluck(note(84), 0.3), 0), (pluck(note(88), 0.3), 0.06), (pluck(note(91), 0.6), 0.12),
                  (sparkle(0.1, 0.4, 5, 8), 0)])
    save(s, 'chest_open', finish(x, 0.75))
    x = mix(1.0, [(noise_whoosh(0.4) * 0.6, 0), (pluck(note(74), 0.4), 0.15), (pluck(note(79), 0.4), 0.23),
                  (pluck(note(86), 0.8), 0.31)])
    save(s, 'streak', finish(x, 0.75))


if __name__ == '__main__':
    set_a()
    set_b()
    set_c()
    print('done')
