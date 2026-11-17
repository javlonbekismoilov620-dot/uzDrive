#!/usr/bin/env python3
"""Synthesises ALL game audio (original, procedurally generated - no samples):
  * assets/audio/engine/*.wav  seamless engine loops per engine profile
  * assets/audio/sfx/*.wav     one-shot effects
  * assets/audio/music/*.ogg   three looping music tracks (needs ffmpeg/libvorbis)
Run: python3 tools/build_audio.py
"""
import os, wave, subprocess, tempfile
import numpy as np

ROOT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
SR = 22050
rng = np.random.default_rng(1234)


def write_wav(path, x, sr=SR):
    x = np.clip(x, -1.0, 1.0)
    data = (x * 32000).astype(np.int16)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(data.tobytes())


def env_adsr(n, a=0.01, d=0.1, s=0.6, r=0.2, sr=SR):
    a_n, d_n, r_n = int(a * sr), int(d * sr), int(r * sr)
    s_n = max(n - a_n - d_n - r_n, 0)
    e = np.concatenate([np.linspace(0, 1, a_n, endpoint=False), np.linspace(1, s, d_n, endpoint=False),
                        np.full(s_n, s), np.linspace(s, 0, r_n)])
    return np.pad(e, (0, max(0, n - len(e))))[:n]


def lowpass(x, cutoff, sr=SR):
    # simple one-pole low-pass
    a = np.exp(-2 * np.pi * cutoff / sr)
    y = np.zeros_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc = (1 - a) * x[i] + a * acc
        y[i] = acc
    return y


def norm(x, peak=0.9):
    m = np.max(np.abs(x)) + 1e-9
    return x / m * peak


# ------------------------------------------------------------------ engines
ENGINES = {
    # name: (fire_hz, harmonics weights, noise, pulse sharpness, roughness)
    "i3":      (66.0, [1.0, 0.55, 0.35, 0.2, 0.12], 0.10, 3.0, 0.18),
    "i4":      (88.0, [1.0, 0.6, 0.3, 0.18, 0.1], 0.08, 2.5, 0.08),
    "i4_turbo": (96.0, [1.0, 0.5, 0.35, 0.25, 0.15], 0.12, 2.5, 0.06),
    "v6":      (110.0, [1.0, 0.7, 0.45, 0.25, 0.15], 0.07, 2.2, 0.06),
    "v8":      (64.0, [1.0, 0.85, 0.6, 0.35, 0.2], 0.09, 3.5, 0.22),
    "v8_muscle": (58.0, [1.0, 0.95, 0.7, 0.45, 0.3], 0.12, 4.0, 0.35),
    "v12":     (150.0, [1.0, 0.6, 0.5, 0.4, 0.3], 0.05, 1.8, 0.03),
    "diesel":  (52.0, [1.0, 0.8, 0.6, 0.4, 0.3], 0.18, 5.0, 0.25),
    "tractor": (38.0, [1.0, 0.9, 0.7, 0.5, 0.3], 0.2, 6.0, 0.3),
    "flat4":   (74.0, [1.0, 0.4, 0.6, 0.2, 0.25], 0.1, 3.0, 0.2),
    "kart":    (120.0, [1.0, 0.8, 0.6, 0.5, 0.4], 0.14, 1.5, 0.12),
}


def engine_loop(fire_hz, harm, noise, sharp, rough, seconds=1.0):
    n = int(SR * seconds)
    t = np.arange(n) / SR
    # integer number of cycles -> seamless loop
    f = round(fire_hz * seconds) / seconds
    phase = 2 * np.pi * f * t
    # firing pulses: raised cosine to a power gives "thump" character
    pulse = (0.5 + 0.5 * np.cos(phase)) ** sharp
    sig = pulse - pulse.mean()
    for k, w in enumerate(harm, start=1):
        sig += w * 0.35 * np.sin(phase * k + k * 0.7)
    # cycle-to-cycle roughness (deterministic so the loop stays seamless)
    cyc = int(round(f * seconds))
    jitter = rng.uniform(1 - rough, 1 + rough, cyc)
    idx = np.minimum((t * f).astype(int), cyc - 1)
    sig *= jitter[idx]
    nz = rng.normal(0, 1, n)
    nz = lowpass(nz, 1800) * noise * 3
    nz *= 0.6 + 0.4 * pulse
    out = sig + nz
    out = lowpass(out, 2600)
    # make loop ends match: crossfade first/last 300 samples
    m = 300
    fade = np.linspace(0, 1, m)
    out[:m] = out[:m] * fade + out[-m:] * (1 - fade)
    return norm(out, 0.8)


def electric_loop(seconds=1.0):
    n = int(SR * seconds)
    t = np.arange(n) / SR
    f = 220.0
    s = 0.6 * np.sin(2 * np.pi * f * t) + 0.25 * np.sin(2 * np.pi * f * 2 * t) + 0.15 * np.sin(2 * np.pi * 3 * f * t)
    whine = 0.2 * np.sin(2 * np.pi * 880 * t)
    nz = lowpass(rng.normal(0, 1, n), 3000) * 0.05
    out = s + whine + nz
    return norm(out, 0.6)


# ------------------------------------------------------------------ sfx
def tone(freq, dur, kind="sine", vol=1.0):
    n = int(SR * dur)
    t = np.arange(n) / SR
    if isinstance(freq, tuple):
        f = np.linspace(freq[0], freq[1], n)
        ph = 2 * np.pi * np.cumsum(f) / SR
    else:
        ph = 2 * np.pi * freq * t
    if kind == "sine":
        x = np.sin(ph)
    elif kind == "square":
        x = np.sign(np.sin(ph)) * 0.6
    elif kind == "tri":
        x = 2 / np.pi * np.arcsin(np.sin(ph))
    else:
        x = 2 * ((ph / (2 * np.pi)) % 1.0) - 1
    return x * vol


def bell(freq, dur, vol=1.0):
    n = int(SR * dur)
    t = np.arange(n) / SR
    x = (np.sin(2 * np.pi * freq * t) + 0.5 * np.sin(2 * np.pi * freq * 2.01 * t) + 0.25 * np.sin(2 * np.pi * freq * 3.02 * t))
    return x * np.exp(-t * 7) * vol


def noise(dur, cutoff=4000, vol=1.0):
    n = int(SR * dur)
    return lowpass(rng.normal(0, 1, n), cutoff) * vol


def seq(*parts, gap=0.0):
    out = []
    for p in parts:
        out.append(p)
        if gap:
            out.append(np.zeros(int(SR * gap)))
    return np.concatenate(out)


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[:len(p)] += p
    return out


def sfx_all():
    S = {}
    S["coin"] = norm(seq(bell(1318, 0.06), bell(1760, 0.18)), 0.7)
    S["coin_big"] = norm(seq(bell(1046, 0.05), bell(1318, 0.05), bell(1568, 0.05), bell(2093, 0.3)), 0.75)
    S["gem"] = norm(mix(seq(bell(1568, 0.07), bell(1976, 0.07), bell(2349, 0.07), bell(3136, 0.35)), noise(0.4, 9000, 0.05) * np.exp(-np.arange(int(SR * 0.4)) / SR * 6)), 0.75)
    n = int(SR * 0.45)
    glug = tone((180, 90), 0.25, "sine") * env_adsr(int(SR * 0.25), 0.005, 0.05, 0.5, 0.15)
    S["fuel"] = norm(seq(glug, mix(bell(784, 0.25), bell(1175, 0.3) * 0.7)), 0.8)
    S["boost_pickup"] = norm(tone((400, 1600), 0.25, "tri") * env_adsr(int(SR * 0.25), 0.01, 0.05, 0.7, 0.12), 0.6)
    S["jump"] = norm(noise(0.3, 1500) * env_adsr(int(SR * 0.3), 0.05, 0.1, 0.4, 0.15), 0.5)
    th = tone((110, 45), 0.25, "sine") * np.exp(-np.arange(int(SR * 0.25)) / SR * 14)
    S["land"] = norm(mix(th, noise(0.2, 800, 0.4) * np.exp(-np.arange(int(SR * 0.2)) / SR * 20)), 0.7)
    S["land_hard"] = norm(mix(tone((90, 35), 0.4, "sine") * np.exp(-np.arange(int(SR * 0.4)) / SR * 8), noise(0.35, 1200, 0.8) * np.exp(-np.arange(int(SR * 0.35)) / SR * 10)), 0.9)
    crunch = noise(0.9, 3500, 1.0) * np.exp(-np.arange(int(SR * 0.9)) / SR * 4)
    clank = mix(bell(420, 0.6, 0.6), bell(613, 0.5, 0.4), bell(980, 0.4, 0.3))
    S["crash"] = norm(mix(crunch, clank, tone((80, 30), 0.6, "sine") * np.exp(-np.arange(int(SR * 0.6)) / SR * 5)), 0.95)
    S["brake"] = norm(mix(tone((1800, 1500), 0.4, "saw") * 0.15 * env_adsr(int(SR * 0.4), 0.02, 0.1, 0.6, 0.2), noise(0.4, 6000, 0.2)), 0.4)
    whoosh = noise(0.8, 2500) * env_adsr(int(SR * 0.8), 0.08, 0.2, 0.6, 0.4)
    S["boost"] = norm(mix(whoosh, tone((60, 180), 0.8, "saw") * 0.4 * env_adsr(int(SR * 0.8), 0.05, 0.2, 0.6, 0.4)), 0.85)
    S["click"] = norm(mix(tone(1200, 0.035, "sine") * np.exp(-np.arange(int(SR * 0.035)) / SR * 90), noise(0.02, 7000, 0.3)), 0.5)
    S["whoosh"] = norm(noise(0.35, 3000) * env_adsr(int(SR * 0.35), 0.06, 0.08, 0.5, 0.2), 0.45)
    S["purchase"] = norm(seq(bell(523, 0.08), bell(659, 0.08), bell(784, 0.08), mix(bell(1046, 0.5), bell(1318, 0.5, 0.6))), 0.8)
    S["upgrade"] = norm(seq(*(tone(f, 0.06, "square", 0.5) * env_adsr(int(SR * 0.06), 0.003, 0.02, 0.7, 0.02) for f in [392, 523, 659, 784, 1046])), 0.55)
    S["error"] = norm(seq(tone(196, 0.12, "square"), tone(147, 0.2, "square")) * 0.5, 0.45)
    S["checkpoint"] = norm(seq(bell(784, 0.1), bell(988, 0.1), bell(1175, 0.35)), 0.75)
    S["complete"] = norm(seq(*(mix(bell(f, 0.16), bell(f * 1.5, 0.16, 0.4)) for f in [523, 659, 784]), mix(bell(1046, 0.8), bell(1318, 0.8, 0.6), bell(1568, 0.8, 0.4))), 0.85)
    S["flip"] = norm(seq(tone((500, 1100), 0.15, "tri") * env_adsr(int(SR * 0.15), 0.01, 0.03, 0.7, 0.05), bell(1568, 0.25)), 0.6)
    S["unlock"] = norm(seq(noise(0.06, 5000, 0.6), bell(880, 0.1), bell(1318, 0.4)), 0.7)
    S["reward"] = norm(seq(bell(659, 0.08), bell(880, 0.08), bell(1046, 0.08), mix(bell(1318, 0.6), bell(1760, 0.6, 0.5))), 0.8)
    lf = seq(tone(880, 0.09, "square", 0.6), np.zeros(int(SR * 0.06)), tone(880, 0.09, "square", 0.6))
    S["low_fuel"] = norm(lf, 0.4)
    return S


# ------------------------------------------------------------------ music
NOTE = {n: i for i, n in enumerate(["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"])}


def midi(name):
    n = name[:-1]
    o = int(name[-1])
    return 12 * (o + 1) + NOTE[n]


def hz(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def synth_note(m, dur, kind, vol, sr=44100):
    n = int(sr * dur)
    t = np.arange(n) / sr
    f = hz(m)
    if kind == "bass":
        x = np.sign(np.sin(2 * np.pi * f * t)) * 0.5 + np.sin(2 * np.pi * f * t) * 0.5
        e = np.exp(-t * 3.5)
    elif kind == "lead":
        x = (2 * ((f * t) % 1.0) - 1) * 0.5 + np.sin(2 * np.pi * f * 2 * t) * 0.2
        vib = np.sin(2 * np.pi * 5.5 * t) * 0.003
        x = (2 * ((f * (t + vib)) % 1.0) - 1) * 0.5
        e = np.minimum(t / 0.02, 1.0) * np.exp(-t * 2.2)
    elif kind == "pluck":
        x = np.sin(2 * np.pi * f * t) + 0.4 * np.sin(2 * np.pi * 2 * f * t)
        e = np.exp(-t * 6.0)
    else:  # pad
        x = sum(np.sin(2 * np.pi * f * d * t) for d in (0.995, 1.0, 1.005)) / 3
        e = np.minimum(t / 0.15, 1.0) * np.minimum((dur - t) / 0.2, 1.0)
    return x * e * vol


def drums(bpm, bars, pattern, sr=44100):
    beat = 60.0 / bpm
    step = beat / 4
    n = int(sr * step * 16 * bars)
    out = np.zeros(n)
    r = np.random.default_rng(7)
    kick_n = int(sr * 0.25)
    tk = np.arange(kick_n) / sr
    kick = np.sin(2 * np.pi * (55 + 90 * np.exp(-tk * 30)) * tk) * np.exp(-tk * 9)
    sn_n = int(sr * 0.2)
    snare = r.normal(0, 1, sn_n) * np.exp(-np.arange(sn_n) / sr * 18) * 0.5 + np.sin(2 * np.pi * 190 * np.arange(sn_n) / sr) * np.exp(-np.arange(sn_n) / sr * 25) * 0.4
    hh_n = int(sr * 0.05)
    hat = r.normal(0, 1, hh_n) * np.exp(-np.arange(hh_n) / sr * 70) * 0.25
    hat = np.diff(hat, prepend=0)
    for b in range(bars):
        for s in range(16):
            pos = int((b * 16 + s) * step * sr)
            for ch, smp in (("k", kick), ("s", snare), ("h", hat)):
                if pattern[ch][s] == "x":
                    end = min(pos + len(smp), n)
                    out[pos:end] += smp[:end - pos]
    return out


def song(bpm, prog, melody, bars_per_chord, kind_lead, drum_pat, seed, sr=44100):
    beat = 60.0 / bpm
    bar = beat * 4
    total_bars = len(prog) * bars_per_chord
    n = int(sr * bar * total_bars)
    out = np.zeros(n)
    pos_bar = 0
    for chord in prog:
        root = midi(chord[0])
        third = root + (3 if chord[1] == "m" else 4)
        fifth = root + 7
        for b in range(bars_per_chord):
            start = int((pos_bar + b) * bar * sr)
            # pad
            for m in (root + 12, third + 12, fifth + 12):
                p = synth_note(m, bar, "pad", 0.09, sr)
                out[start:start + len(p)] += p[:n - start]
            # bass (8ths)
            for s in range(8):
                m = root - 12 if s % 4 != 3 else fifth - 12
                p = synth_note(m, beat / 2 * 0.95, "bass", 0.22, sr)
                st = start + int(s * beat / 2 * sr)
                out[st:st + len(p)] += p[:max(0, n - st)]
            # arpeggio plucks (16ths)
            arp = [root + 24, third + 24, fifth + 24, third + 24]
            for s in range(16):
                m = arp[s % 4]
                p = synth_note(m, beat / 4, "pluck", 0.06, sr)
                st = start + int(s * beat / 4 * sr)
                out[st:st + len(p)] += p[:max(0, n - st)]
        pos_bar += bars_per_chord
    # melody: list of (beat_offset, note, beats)
    for (off, note, ln) in melody:
        p = synth_note(midi(note), ln * beat, kind_lead, 0.13, sr)
        st = int(off * beat * sr)
        if st < n:
            out[st:st + len(p)] += p[:n - st]
    d = drums(bpm, total_bars, drum_pat, sr)
    out[:len(d)] += d[:n] * 0.55
    # gentle master: soft clip + loop crossfade
    out = np.tanh(out * 1.3) * 0.8
    m = int(sr * 0.05)
    fade = np.linspace(0, 1, m)
    out[:m] = out[:m] * fade + out[-m:] * (1 - fade)
    return out


def make_melody(scale, prog_len_beats, seed, density=0.6):
    r = np.random.default_rng(seed)
    mel = []
    beat = 0.0
    idx = 4
    motif = [r.integers(-2, 3) for _ in range(8)]
    while beat < prog_len_beats - 1:
        phrase_pos = int(beat) % 16
        if r.random() < density:
            step = motif[int(beat * 2) % len(motif)] if phrase_pos < 8 else r.integers(-2, 3)
            idx = int(np.clip(idx + step, 0, len(scale) - 1))
            ln = r.choice([0.5, 0.5, 1.0, 1.5])
            mel.append((beat, scale[idx], ln * 0.95))
            beat += ln
        else:
            beat += 0.5
    return mel


def write_ogg(path, x, sr=44100):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tf:
        tmp = tf.name
    data = (np.clip(x, -1, 1) * 32000).astype(np.int16)
    with wave.open(tmp, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(data.tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", "3", path], check=True)
    os.unlink(tmp)


def main():
    for name, p in ENGINES.items():
        write_wav(os.path.join(ROOT, "engine", name + ".wav"), engine_loop(*p))
    write_wav(os.path.join(ROOT, "engine", "electric.wav"), electric_loop())
    for name, x in sfx_all().items():
        write_wav(os.path.join(ROOT, "sfx", name + ".wav"), x)
    pat_drive = {"k": "x...x...x...x...", "s": "....x.......x...", "h": "x.x.x.x.x.x.x.x."}
    pat_menu = {"k": "x.......x.......", "s": "....x.......x...", "h": "..x...x...x...x."}
    pat_b = {"k": "x..x....x.x.....", "s": "....x.......x..x", "h": "xxx.xxx.xxx.xxx."}
    # menu: relaxed, major
    prog_m = [("C3", ""), ("A2", "m"), ("F2", ""), ("G2", "")]
    scale_c = ["C4", "D4", "E4", "G4", "A4", "C5", "D5", "E5", "G5"]
    mel = make_melody(scale_c, len(prog_m) * 2 * 4 * 2, 11, 0.45)
    menu = song(96, prog_m * 2, mel, 2, "pluck", pat_menu, 11)
    write_ogg(os.path.join(ROOT, "music", "menu.ogg"), menu)
    # drive A: upbeat, sunny
    prog_a = [("G2", ""), ("D3", ""), ("E2", "m"), ("C3", "")]
    scale_g = ["G4", "A4", "B4", "D5", "E5", "G5", "A5", "B5"]
    mel_a = make_melody(scale_g, len(prog_a) * 2 * 4 * 2, 21, 0.65)
    drive_a = song(126, prog_a * 2, mel_a, 2, "lead", pat_drive, 21)
    write_ogg(os.path.join(ROOT, "music", "drive_a.ogg"), drive_a)
    # drive B: minor, adventurous (forest / snow / rocky / night)
    prog_b = [("A2", "m"), ("F2", ""), ("C3", ""), ("G2", "")]
    scale_a = ["A4", "C5", "D5", "E5", "G5", "A5", "C6"]
    mel_b = make_melody(scale_a, len(prog_b) * 2 * 4 * 2, 31, 0.6)
    drive_b = song(118, prog_b * 2, mel_b, 2, "lead", pat_b, 31)
    write_ogg(os.path.join(ROOT, "music", "drive_b.ogg"), drive_b)
    print("audio done")


if __name__ == "__main__":
    main()
