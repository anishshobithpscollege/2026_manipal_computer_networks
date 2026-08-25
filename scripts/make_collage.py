#!/usr/bin/env python3
"""Stitch Typst page renders into one overlapping fan collage for the README.

The middle page in --pages sits upright at the front; the others fan out
behind it, angled, slightly smaller, and dropped down, each with a soft shadow.

Usage:
    python scripts/make_collage.py --pages 2 1 6 --output dist/collage.png
"""
import argparse
from pathlib import Path

from PIL import Image, ImageFilter, ImageOps


def load_pages(input_dir, template, pages, height):
    imgs = []
    for p in pages:
        path = Path(input_dir) / template.format(p=p)
        if not path.exists():
            print(f"skip missing {path}")
            continue
        im = Image.open(path).convert("RGBA")
        width = round(im.width * height / im.height)
        im = im.resize((width, height), Image.LANCZOS)
        im = ImageOps.expand(im, border=1, fill=(203, 210, 217, 255))
        imgs.append(im)
    return imgs


def shadow_of(im, blur, drop, opacity):
    pad = blur * 3
    base = Image.new("RGBA", (im.width + 2 * pad, im.height + 2 * pad), (0, 0, 0, 0))
    dark = Image.new("RGBA", im.size, (12, 16, 22, opacity))
    base.paste(dark, (pad, pad + drop), im.split()[-1])
    return base.filter(ImageFilter.GaussianBlur(blur)), pad


def build(imgs, angle, overlap, drop_y, scale_step, blur, shadow_drop, opacity, margin):
    mid = (len(imgs) - 1) / 2
    step_x = imgs[0].width * (1 - overlap)
    cards = []
    for i, im in enumerate(imgs):
        dist = abs(i - mid)
        scale = 1 - dist * scale_step
        if scale != 1:
            im = im.resize((round(im.width * scale), round(im.height * scale)), Image.LANCZOS)
        rot = im.rotate((i - mid) * angle, expand=True, resample=Image.BICUBIC)
        cards.append((rot, i * step_x, dist * drop_y, dist))

    minx = min(cx - r.width / 2 for r, cx, cy, _ in cards)
    maxx = max(cx + r.width / 2 for r, cx, cy, _ in cards)
    miny = min(cy - r.height / 2 for r, cx, cy, _ in cards)
    maxy = max(cy + r.height / 2 for r, cx, cy, _ in cards)
    pad = blur * 3
    base = margin + pad
    canvas = Image.new(
        "RGBA",
        (round(maxx - minx) + 2 * base, round(maxy - miny) + 2 * base),
        (0, 0, 0, 0),
    )

    for rot, cx, cy, dist in sorted(cards, key=lambda c: -c[3]):
        px = round(cx - minx - rot.width / 2) + base
        py = round(cy - miny - rot.height / 2) + base
        shadow, spad = shadow_of(rot, blur, shadow_drop, opacity)
        canvas.alpha_composite(shadow, (px - spad, py - spad))
        canvas.alpha_composite(rot, (px, py))
    return canvas


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--input-dir", default="dist/preview")
    ap.add_argument("--template", default="example-{p}.png")
    ap.add_argument("--pages", type=int, nargs="+", default=[2, 1, 6])
    ap.add_argument("--output", default="dist/collage.png")
    ap.add_argument("--height", type=int, default=1000)
    ap.add_argument("--angle", type=float, default=8.0)
    ap.add_argument("--overlap", type=float, default=0.5)
    ap.add_argument("--drop-y", type=int, default=48)
    ap.add_argument("--scale-step", type=float, default=0.08)
    ap.add_argument("--blur", type=int, default=18)
    ap.add_argument("--shadow-drop", type=int, default=12)
    ap.add_argument("--opacity", type=int, default=110)
    ap.add_argument("--margin", type=int, default=20)
    args = ap.parse_args()

    imgs = load_pages(args.input_dir, args.template, args.pages, args.height)
    if not imgs:
        raise SystemExit("no input images found")
    canvas = build(imgs, args.angle, args.overlap, args.drop_y, args.scale_step,
                   args.blur, args.shadow_drop, args.opacity, args.margin)
    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out)
    print(f"wrote {out} ({canvas.width}x{canvas.height})")


if __name__ == "__main__":
    main()
