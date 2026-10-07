#!/usr/bin/env python3
"""
Assemble docs/jenkins-complete-guide.html from:
    docs/_shell.html        (design system + JS)
    docs/blocks/*.html      (one fragment per block, edited independently)

Usage:  python3 scripts/build-doc.py
"""
import re, pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SHELL = ROOT / "docs" / "_shell.html"
BLOCKS = ROOT / "docs" / "blocks"
OUT = ROOT / "docs" / "jenkins-complete-guide.html"

def key(p):
    m = re.search(r"block-(\d+)", p.stem)
    return int(m.group(1)) if m else 999

def main():
    shell = SHELL.read_text(encoding="utf-8")
    frags = sorted(BLOCKS.glob("block-*.html"), key=key)
    if not frags:
        sys.exit("no block fragments found")

    parts = []
    for f in frags:
        txt = f.read_text(encoding="utf-8").strip()
        parts.append(txt)
    body = "\n\n".join(parts)

    if "<!--BLOCKS-->" not in shell:
        sys.exit("shell is missing the <!--BLOCKS--> placeholder")
    html = shell.replace("<!--BLOCKS-->", body)

    OUT.write_text(html, encoding="utf-8")
    words = len(re.sub(r"<[^>]+>", " ", html).split())
    print(f"built {OUT.relative_to(ROOT)}")
    print(f"  {len(frags)} fragments · {len(html):,} bytes · ~{words:,} words · ~{round(words/430)} printed pages")

if __name__ == "__main__":
    main()
