# Usage: sprite.py <trace dir> <output.svg>
# Joins potrace outlines into one SVG sprite. Each symbol's viewBox is its whole status item slot,
# as rendered by symbols.swift, so it is drawn at slot size in CSS pixels with no further placement.
import pathlib, re, sys

SCALE = 32  # bitmap pixels per point, as in symbols.swift
src, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])

symbols = []
for svg in sorted(src.glob("*.svg")):
    header = re.match(rb"P5\s+(\d+)\s+(\d+)\s", svg.with_suffix(".pgm").read_bytes())
    w, h = int(header[1]) / SCALE, int(header[2]) / SCALE
    text = svg.read_text()
    transform = re.search(r'<g transform="([^"]+)"', text)[1]
    paths = "".join(f'<path d="{" ".join(d.split())}"/>' for d in re.findall(r'd="([^"]+)"', text))
    symbols.append(f'<symbol id="{svg.stem}" viewBox="0 0 {w:g} {h:g}"><g transform="{transform}">{paths}</g></symbol>')
    print(svg.stem, f"{w:g} {h:g}")

out.write_text('<svg xmlns="http://www.w3.org/2000/svg" fill="currentColor">\n' + "\n".join(symbols) + "\n</svg>\n")
