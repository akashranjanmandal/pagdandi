#!/usr/bin/env python3
"""Feeds GPS positions to an emulator, walking along a GPX route.

Repeats: walk the trail, step ~90 m off it, come back, walk on.
Usage: walk_route.py <file.gpx> [adb serial] [seconds between fixes]
"""
import math, re, subprocess, sys, time, os

gpx, serial = sys.argv[1], (sys.argv[2] if len(sys.argv) > 2 else None)
delay = float(sys.argv[3]) if len(sys.argv) > 3 else 3.0
adb = os.path.join(os.environ.get("ANDROID_HOME", os.path.expanduser("~/Library/Android/sdk")), "platform-tools", "adb")
pts = [(float(a), float(b), float(c or 0)) for a, b, c in re.findall(r'<trkpt lat="([^"]+)" lon="([^"]+)"[^>]*>(?:<ele>([^<]*)</ele>)?', open(gpx).read())]

def metres(a, b):
    dy = (b[0] - a[0]) * 111195
    dx = (b[1] - a[1]) * 111195 * math.cos(math.radians(a[0]))
    return math.hypot(dx, dy)

# Resample every ~15 m along the route.
walk = [pts[0]]
acc = 0.0
for i in range(1, len(pts)):
    acc += metres(pts[i - 1], pts[i])
    if acc >= 15:
        walk.append(pts[i]); acc = 0.0

def send(lat, lon, ele):
    cmd = [adb] + (["-s", serial] if serial else []) + ["emu", "geo", "fix", f"{lon:.6f}", f"{lat:.6f}", f"{ele:.1f}"]
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

# Short repeating cycles, so a test that starts late still sees every phase:
# 10 fixes along the trail, a drift ~90 m off it and back, then 10 more.
k = 0
while k + 20 <= len(walk):
    print(f"cycle at fix {k}: on the trail", flush=True)
    for p in walk[k:k + 10]:
        send(*p); time.sleep(delay)
    q = walk[k + 9]
    print("off the trail", flush=True)
    # Drift away in ~14 m steps (a sudden jump would be filtered as an
    # impossible speed, and repeated identical fixes as no movement).
    east = 90 / (111195 * math.cos(math.radians(q[0])))
    for i in range(1, 8):
        send(q[0], q[1] + east * i / 7, q[2]); time.sleep(delay)
    for i in range(6, 0, -1):
        send(q[0], q[1] + east * i / 7, q[2]); time.sleep(delay)
    print("back on the trail", flush=True)
    for p in walk[k + 10:k + 20]:
        send(*p); time.sleep(delay)
    k += 20
print("done", flush=True)
