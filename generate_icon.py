#!/usr/bin/env python3
"""Generate the Weather Wise app icon: cloud morphing into brain."""

from PIL import Image, ImageDraw
import math

SIZE = 1024
img = Image.new("RGBA", (SIZE, SIZE))
draw = ImageDraw.Draw(img)
w = h = SIZE


def lerp_color(c1, c2, t):
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))


# MARK: - Background gradient (top-left to bottom-right)
for y in range(h):
    for x in range(w):
        t = (x / w + y / h) / 2.0
        if t < 0.5:
            c = lerp_color((38, 102, 217), (20, 51, 140), t * 2)
        else:
            c = lerp_color((20, 51, 140), (13, 31, 89), (t - 0.5) * 2)
        img.putpixel((x, y), (*c, 255))

# Radial glow
cx, cy = w * 0.5, h * 0.48
max_r = w * 0.4
for y in range(int(h * 0.15), int(h * 0.82)):
    for x in range(int(w * 0.15), int(w * 0.85)):
        dx, dy = x - cx, y - cy
        r = math.sqrt(dx * dx + dy * dy)
        if r < max_r:
            t = r / max_r
            alpha = int(30 * (1.0 - t * t))
            if alpha > 0:
                px = img.getpixel((x, y))
                blended = tuple(min(255, c + alpha) for c in px[:3])
                img.putpixel((x, y), (*blended, 255))


# MARK: - Draw cloud-brain using polygon approximation
def bezier(p0, p1, p2, p3, steps=30):
    """Cubic bezier curve points."""
    pts = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        x = u**3 * p0[0] + 3 * u**2 * t * p1[0] + 3 * u * t**2 * p2[0] + t**3 * p3[0]
        y = u**3 * p0[1] + 3 * u**2 * t * p1[1] + 3 * u * t**2 * p2[1] + t**3 * p3[1]
        pts.append((x, y))
    return pts


def build_cloud_brain():
    baseY = h * 0.68
    baseLeft = w * 0.18
    baseRight = w * 0.82
    pts = [(baseLeft, baseY)]

    # Left cloud puffs
    pts += bezier((baseLeft, baseY), (w*0.10, baseY), (w*0.08, h*0.58), (w*0.14, h*0.52))
    pts += bezier((w*0.14, h*0.52), (w*0.10, h*0.44), (w*0.10, h*0.36), (w*0.18, h*0.34))
    pts += bezier((w*0.18, h*0.34), (w*0.22, h*0.28), (w*0.26, h*0.24), (w*0.32, h*0.24))

    # Top transition
    pts += bezier((w*0.32, h*0.24), (w*0.38, h*0.22), (w*0.43, h*0.20), (w*0.48, h*0.22))
    # Brain fissure dip
    pts += bezier((w*0.48, h*0.22), (w*0.50, h*0.25), (w*0.51, h*0.25), (w*0.52, h*0.23))

    # Right brain lobes
    pts += bezier((w*0.52, h*0.23), (w*0.57, h*0.19), (w*0.63, h*0.20), (w*0.68, h*0.24))
    pts += bezier((w*0.68, h*0.24), (w*0.74, h*0.24), (w*0.80, h*0.26), (w*0.80, h*0.32))
    pts += bezier((w*0.80, h*0.32), (w*0.83, h*0.35), (w*0.84, h*0.38), (w*0.82, h*0.40))
    pts += bezier((w*0.82, h*0.40), (w*0.86, h*0.44), (w*0.88, h*0.48), (w*0.86, h*0.52))
    pts += bezier((w*0.86, h*0.52), (w*0.88, h*0.60), (w*0.88, baseY), (baseRight, baseY))

    pts.append((baseLeft, baseY))
    return pts


shape = build_cloud_brain()
shape_tuples = [tuple(map(int, p)) for p in shape]

# Shadow
shadow_pts = [(int(p[0] + 4), int(p[1] + 6)) for p in shape]
shadow_img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
shadow_draw = ImageDraw.Draw(shadow_img)
shadow_draw.polygon(shadow_pts, fill=(0, 0, 0, 60))
img = Image.alpha_composite(img, shadow_img)

# Shape fill with left-to-right gradient (cloud blue -> brain pink)
# Create a mask from the shape
mask = Image.new("L", (SIZE, SIZE), 0)
mask_draw = ImageDraw.Draw(mask)
mask_draw.polygon(shape_tuples, fill=255)

fill_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
for y in range(h):
    for x in range(w):
        if mask.getpixel((x, y)) > 0:
            t = (x - w * 0.15) / (w * 0.7)
            t = max(0.0, min(1.0, t))
            if t < 0.5:
                c = lerp_color((217, 235, 255), (242, 224, 242), t * 2)
            else:
                c = lerp_color((242, 224, 242), (235, 209, 230), (t - 0.5) * 2)
            # Top highlight
            shape_top = h * 0.20
            shape_bot = h * 0.68
            yt = (y - shape_top) / (shape_bot - shape_top)
            if yt < 0.4:
                highlight = int(120 * (1.0 - yt / 0.4))
                c = tuple(min(255, v + highlight) for v in c)
            fill_layer.putpixel((x, y), (*c, 255))

img = Image.alpha_composite(img, fill_layer)

# Shape outline
outline_img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
outline_draw = ImageDraw.Draw(outline_img)
outline_draw.polygon(shape_tuples, outline=(255, 255, 255, 100))
# Draw it a couple times for thickness
for offset in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
    shifted = [(int(p[0] + offset[0]), int(p[1] + offset[1])) for p in shape]
    outline_draw.polygon(shifted, outline=(255, 255, 255, 60))
img = Image.alpha_composite(img, outline_img)


# MARK: - Brain sulci (fold lines)
def draw_bezier_line(draw_obj, p0, p1, p2, p3, color, width=8):
    pts = bezier(p0, p1, p2, p3, steps=40)
    for i in range(len(pts) - 1):
        draw_obj.line([pts[i], pts[i+1]], fill=color, width=width)


sulci_img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
sulci_draw = ImageDraw.Draw(sulci_img)
sulci_color = (178, 153, 184, 128)
lw = 8

# Central sulcus
draw_bezier_line(sulci_draw,
    (w*0.50, h*0.25), (w*0.51, h*0.38), (w*0.50, h*0.52), (w*0.52, h*0.62),
    sulci_color, lw)
# Upper fold
draw_bezier_line(sulci_draw,
    (w*0.54, h*0.32), (w*0.62, h*0.28), (w*0.70, h*0.30), (w*0.76, h*0.33),
    sulci_color, lw)
# Middle fold
draw_bezier_line(sulci_draw,
    (w*0.53, h*0.43), (w*0.62, h*0.40), (w*0.74, h*0.40), (w*0.80, h*0.44),
    sulci_color, lw)
# Lower fold
draw_bezier_line(sulci_draw,
    (w*0.53, h*0.54), (w*0.63, h*0.51), (w*0.75, h*0.51), (w*0.82, h*0.55),
    sulci_color, lw)

# Mask sulci to shape
sulci_masked = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
sulci_masked.paste(sulci_img, mask=mask)
img = Image.alpha_composite(img, sulci_masked)


# MARK: - Lightning bolt
bolt_pts = [
    (w*0.50, h*0.60),
    (w*0.46, h*0.70),
    (w*0.49, h*0.70),
    (w*0.46, h*0.80),
    (w*0.54, h*0.72),
    (w*0.51, h*0.72),
    (w*0.55, h*0.60),
]
bolt_tuples = [tuple(map(int, p)) for p in bolt_pts]

bolt_img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
bolt_draw = ImageDraw.Draw(bolt_img)

# Bolt fill gradient (yellow to orange, top to bottom)
bolt_mask = Image.new("L", (SIZE, SIZE), 0)
bolt_mask_draw = ImageDraw.Draw(bolt_mask)
bolt_mask_draw.polygon(bolt_tuples, fill=255)

for y in range(int(h * 0.58), int(h * 0.82)):
    for x in range(int(w * 0.44), int(w * 0.57)):
        if bolt_mask.getpixel((x, y)) > 0:
            t = (y - h * 0.58) / (h * 0.22)
            t = max(0.0, min(1.0, t))
            c = lerp_color((255, 217, 51), (255, 166, 26), t)
            bolt_img.putpixel((x, y), (*c, 255))

img = Image.alpha_composite(img, bolt_img)

# Bolt outline
bolt_outline = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
bolt_outline_draw = ImageDraw.Draw(bolt_outline)
bolt_outline_draw.polygon(bolt_tuples, outline=(255, 153, 0, 153))
for offset in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
    shifted = [(int(p[0] + offset[0]), int(p[1] + offset[1])) for p in bolt_pts]
    bolt_outline_draw.polygon(shifted, outline=(255, 153, 0, 100))
img = Image.alpha_composite(img, bolt_outline)


# Save
output = "WeatherWise/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
img.save(output, "PNG")
print(f"App icon saved to {output} ({SIZE}x{SIZE})")
