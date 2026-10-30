"""FISTAGENT logo: trace the white glyph of the user's reference (gold circle, white glyph) into a clean,
symmetric vector mark. Input: fist_ref.png (converted from the user's upload). Outputs into ../site/assets/."""
import numpy as np, cv2, potrace, cairosvg, os, io
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "site", "assets")
ref = cv2.imread(os.path.join(HERE, "fist_ref.png"))
h, w = ref.shape[:2]
hsv = cv2.cvtColor(ref, cv2.COLOR_BGR2HSV)
# circle: gold pixels
gold = ((hsv[..., 1] > 120) & (hsv[..., 2] > 150)).astype(np.uint8)
ys, xs = np.nonzero(gold)
cx, cy = (xs.min() + xs.max()) / 2, (ys.min() + ys.max()) / 2
R = ((xs.max() - xs.min()) + (ys.max() - ys.min())) / 4
gold_bgr = np.median(ref[gold > 0], axis=0)
print("circle", cx, cy, R, "gold rgb", gold_bgr[::-1])
# glyph: bright, low saturation, inside the circle
yy, xx = np.mgrid[0:h, 0:w]
inside = (xx - cx) ** 2 + (yy - cy) ** 2 < (R * 0.92) ** 2
white = ((hsv[..., 1] < 90) & (hsv[..., 2] > 200) & inside).astype(np.float32)
S = 4
big = cv2.resize(white, (w * S, h * S), interpolation=cv2.INTER_CUBIC)
big = cv2.GaussianBlur(big, (0, 0), 3.0 * S)
m = (big > 0.5).astype(np.uint8)
# symmetry axis = centroid x of the dot (top blob) -> mirror the left half
n, lab, stats, cent = cv2.connectedComponentsWithStats(m)
comps = sorted(range(1, n), key=lambda i: -stats[i, cv2.CC_STAT_AREA])
print("components", [(int(stats[i, 4]), tuple(int(v) for v in cent[i])) for i in comps[:6]])
keep = np.zeros_like(m)
for i in comps:
    if stats[i, cv2.CC_STAT_AREA] > 2000 * S * S / 16:
        keep[lab == i] = 1
m = keep
dot = min(comps[:6], key=lambda i: cent[i][1])
ax = cent[dot][0]
xs_g = np.nonzero(m.any(0))[0]
ax_box = (xs_g.min() + xs_g.max()) / 2
axis = int(round((ax + ax_box) / 2))
print("axis dot", ax, "bbox", ax_box, "->", axis)
left = m[:, :axis]
sym = np.zeros_like(m)
sym[:, :axis] = left
wr = min(axis, m.shape[1] - axis)
sym[:, axis:axis + wr] = left[:, ::-1][:, :wr]
# straighten: close tiny gaps, smooth once more
sym = cv2.morphologyEx(sym, cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (9, 9)))
sym = (cv2.GaussianBlur(sym.astype(np.float32), (0, 0), 2.0 * S) > 0.5).astype(np.uint8)
# the dot becomes an exact circle (fitted to the traced dot), drawn separately
nd, labd, statsd, centd = cv2.connectedComponentsWithStats(sym)
top = min(range(1, nd), key=lambda i: centd[i][1])
dm = (labd == top).astype(np.uint8)
area = dm.sum()
dot_r = (area / np.pi) ** 0.5
dot_c = (axis, centd[top][1])
sym[labd == top] = 0
print("dot r", dot_r / S)
# de-wobble: polygonal simplification of every contour (straight edges become straight, JPEG ripples go),
# near-horizontal/vertical edges snapped, then re-rasterised; potrace turns the facets back into smooth curves.
EPS = float(os.environ.get("EPS", 2.0)) * S
cnts, hier = cv2.findContours(sym, cv2.RETR_CCOMP, cv2.CHAIN_APPROX_NONE)
clean = np.zeros_like(sym)
polys = []
for c in cnts:
    a = cv2.approxPolyDP(c, EPS, True).reshape(-1, 2).astype(np.float64)
    # snap edges within 4 degrees of horizontal / vertical
    for _ in range(2):
        for i in range(len(a)):
            j = (i + 1) % len(a)
            dx, dy = a[j] - a[i]
            if abs(dx) > 1 and abs(dy) / abs(dx) < 0.07:
                m_ = (a[i][1] + a[j][1]) / 2; a[i][1] = a[j][1] = m_
            elif abs(dy) > 1 and abs(dx) / abs(dy) < 0.07:
                m_ = (a[i][0] + a[j][0]) / 2; a[i][0] = a[j][0] = m_
    # resample densely and round the corners with a circular Gaussian along the outline
    pts = []
    for i in range(len(a)):
        p0, p1 = a[i], a[(i + 1) % len(a)]
        n_ = max(1, int(np.hypot(*(p1 - p0)) / S))
        for t in range(n_):
            pts.append(p0 + (p1 - p0) * t / n_)
    pts = np.array(pts)
    sig = float(os.environ.get("SIG", 6.0))
    rad = int(3 * sig)
    ker = np.exp(-0.5 * (np.arange(-rad, rad + 1) / sig) ** 2); ker /= ker.sum()
    ext = np.concatenate([pts[-rad:], pts, pts[:rad]])
    sm = np.stack([np.convolve(ext[:, 0], ker, "valid"), np.convolve(ext[:, 1], ker, "valid")], 1)
    polys.append(sm)
# outer contours filled, holes (children) cleared
for i, a in enumerate(polys):
    if hier[0][i][3] == -1:
        cv2.fillPoly(clean, [np.round(a).astype(np.int32)], 1)
for i, a in enumerate(polys):
    if hier[0][i][3] != -1:
        cv2.fillPoly(clean, [np.round(a).astype(np.int32)], 0)
# re-symmetrise after snapping
L = clean[:, :axis]
clean[:, axis:axis + wr] = L[:, ::-1][:, :wr]
sym = clean
bmp = potrace.Bitmap(sym == 0)  # potracer traces the False pixels
path = bmp.trace(turdsize=200, alphamax=1.1, opticurve=True, opttolerance=0.6)
# map to a 512 viewBox: circle centered at 256, r 256; glyph keeps its position relative to the reference circle
k = 256 / R / S
ox, oy = cx * S, cy * S
def P(pt):
    return f"{(pt.x - ox) * k + 256:.2f} {(pt.y - oy) * k + 256:.2f}"
d = []
for curve in path:
    d.append("M" + P(curve.start_point))
    for seg in curve.segments:
        if seg.is_corner:
            d.append("L" + P(seg.c) + "L" + P(seg.end_point))
        else:
            d.append("C" + P(seg.c1) + " " + P(seg.c2) + " " + P(seg.end_point))
    d.append("Z")
D = "".join(d)
dcx, dcy = (dot_c[0] - ox) * k + 256, (dot_c[1] - oy) * k + 256
DOT = f'<circle cx="{dcx:.2f}" cy="{dcy:.2f}" r="{dot_r * k:.2f}" fill="#FFFFFF"/>'
print("first path start", D[:60])
GOLD = "#F5B21B"
mark = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><circle cx="256" cy="256" r="256" fill="{GOLD}"/><path fill="#FFFFFF" fill-rule="evenodd" d="{D}"/>{DOT}</svg>'
glyph_only = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><path fill="#FFFFFF" fill-rule="evenodd" d="{D}"/>{DOT}</svg>'
open(os.path.join(OUT, "fistagent-mark.svg"), "w").write(mark)
open(os.path.join(OUT, "favicon-fist.svg"), "w").write(mark)
open(os.path.join(HERE, "logo", "glyph.svg"), "w").write(glyph_only)
def png(svg, size, path):
    cairosvg.svg2png(bytestring=svg.encode(), write_to=path, output_width=size, output_height=size)
png(mark, 1024, os.path.join(OUT, "fistagent-mark.png"))
for s in (32, 180, 512):
    png(mark, s, os.path.join(OUT, f"favicon-fist-{s}.png"))
# side-by-side check
png(mark, 933, os.path.join(HERE, "logo", "mark-933.png"))
a = Image.open(os.path.join(HERE, "fist_ref.png")).convert("RGB").resize((933, 933))
b = Image.open(os.path.join(HERE, "logo", "mark-933.png")).convert("RGBA")
bg = Image.new("RGB", (933, 933), (0, 0, 0)); bg.paste(b, (0, 0), b)
cmp = Image.new("RGB", (1880, 933), (30, 30, 30)); cmp.paste(a, (0, 0)); cmp.paste(bg, (947, 0))
cmp.save(os.path.join(HERE, "logo", "compare.png"))
print("path chars", len(D))

# ---------------------------------------------------------------- lockup + og (same layout as BNAGENT v3)
from PIL import ImageDraw, ImageFont, ImageFilter
CREAM = (244, 236, 220)
BG = (10, 10, 12)
FONT = os.path.join(HERE, "fonts", "SpaceGrotesk.ttf")
INTER = os.path.join(HERE, "fonts", "Inter.ttf")

def render_mark(px):
    b = io.BytesIO(); cairosvg.svg2png(bytestring=mark.encode(), write_to=b, output_width=px, output_height=px)
    return Image.open(b).convert("RGBA")

def font(size):
    f = ImageFont.truetype(FONT, size)
    try:
        axes = f.get_variation_axes()
        f.set_variation_by_axes([700 if a["name"] in (b"Weight", "Weight") else a["default"] for a in axes])
    except Exception as e:
        print("font var fail", e)
    return f

def text_img(word, size, tracking, color):
    f = font(size)
    widths = [f.getlength(c) for c in word]
    W = int(sum(widths) + tracking * (len(word) - 1)) + 4
    asc, desc = f.getmetrics()
    im = Image.new("RGBA", (W, asc + desc), (0, 0, 0, 0))
    d = ImageDraw.Draw(im); x = 0
    for c, w in zip(word, widths):
        d.text((x, 0), c, font=f, fill=color + (255,)); x += w + tracking
    return im.crop(im.getbbox())

def lockup(mark_h, color=CREAM):
    m = render_mark(mark_h)
    cap = int(mark_h * 0.40)
    size = cap; t = text_img("FISTAGENT", size, 0, color)
    size = int(size * cap / t.size[1]); t = text_img("FISTAGENT", size, int(size * 0.09), color)
    gap = int(mark_h * 0.26)
    W = m.size[0] + gap + t.size[0]
    im = Image.new("RGBA", (W, mark_h), (0, 0, 0, 0))
    im.alpha_composite(m, (0, 0))
    im.alpha_composite(t, (m.size[0] + gap, int((mark_h - t.size[1]) / 2)))
    return im

def og():
    W, H = 1200, 630
    bg = Image.new("RGB", (W, H), BG)
    glow = Image.new("L", (W, H), 0)
    ImageDraw.Draw(glow).ellipse([-100, -150, 800, 750], fill=46)
    glow = glow.filter(ImageFilter.GaussianBlur(150))
    bg = Image.composite(Image.new("RGB", (W, H), (70, 50, 10)), bg, glow).convert("RGBA")
    lk = lockup(170)
    bg.alpha_composite(lk, ((W - lk.size[0]) // 2, 150))
    d = ImageDraw.Draw(bg)
    f1 = ImageFont.truetype(INTER, 40); f2 = ImageFont.truetype(INTER, 24)
    for f, txt, y, col in ((f1, "Fair mint for .ai Agent IDs on BNB Smart Chain", 392, CREAM),
                           (f2, "Independent · Not affiliated with Binance", 470, (160, 150, 132))):
        w = d.textlength(txt, font=f); d.text(((W - w) / 2, y), txt, font=f, fill=col)
    d.rectangle([0, H - 6, W, H], fill=(0xF5, 0xB2, 0x1B))
    return bg.convert("RGB")

lockup(108).save(os.path.join(OUT, "fistagent-lockup.png"))
o = og(); o.save(os.path.join(OUT, "og-fist.png"))
# preview sheet
P = Image.new("RGBA", (1600, 1100), BG + (255,))
d = ImageDraw.Draw(P); lab = ImageFont.truetype(INTER, 22)
P.alpha_composite(render_mark(300), (80, 90)); d.text((80, 40), "mark (vector)", font=lab, fill=(150, 140, 125))
P.alpha_composite(lockup(108), (520, 120)); d.text((520, 40), "lockup (header)", font=lab, fill=(150, 140, 125))
P.alpha_composite(lockup(36), (520, 290)); d.text((520, 250), "lockup @ 36px", font=lab, fill=(150, 140, 125))
x = 1000
for s_ in (32, 180):
    ic = Image.open(os.path.join(OUT, f"favicon-fist-{s_}.png")).convert("RGBA"); P.alpha_composite(ic, (x, 120)); d.text((x, 80), f"{s_}", font=lab, fill=(150, 140, 125)); x += s_ + 60
P.alpha_composite(o.convert("RGBA").resize((960, 504), Image.LANCZOS), (80, 520)); d.text((80, 480), "og-fist.png", font=lab, fill=(150, 140, 125))
P.convert("RGB").save(os.path.join(OUT, "logo-fist-preview.png"))
