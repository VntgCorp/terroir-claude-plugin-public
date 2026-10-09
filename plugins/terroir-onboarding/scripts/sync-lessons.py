#!/usr/bin/env python3
"""podo 레슨(lesson.html)에서 본문 텍스트를 뽑아 lessons/*.md 와 lessons/index.md 를 다시 만든다.

    python3 plugins/terroir-onboarding/scripts/sync-lessons.py <podo>/content/lessons

순서와 대상은 podo 의 index.md 목차를 따른다. 이미지·스타일·스크립트는 버리고 글만 남긴다.
podo 는 private 이고 이 레포는 public 이다 — 공개해도 되는 레슨인지 확인한 뒤 돌린다.
"""
import html.parser
import pathlib
import re
import sys

OUT = pathlib.Path(__file__).resolve().parent.parent / "lessons"

SKIP = {"style", "script", "svg", "head", "img", "video", "audio", "canvas"}
BLOCK = {"p", "div", "section", "header", "main", "summary", "details", "ol", "ul",
         "table", "pre", "blockquote", "figure", "figcaption", "br", "hr"}
HEAD = {"h1": "# ", "h2": "## ", "h3": "### ", "h4": "#### "}
# 이 레포는 public 이다 — 사내망 주소가 든 줄은 통째로 뺀다.
PRIVATE_IP = re.compile(r"\b(10(\.\d{1,3}){3}|(172\.(1[6-9]|2\d|3[01])|192\.168)(\.\d{1,3}){2})\b")


class Text(html.parser.HTMLParser):
    def __init__(self):
        super().__init__()
        self.out, self.skip, self.pre = [], 0, 0
        self.lede = []
        self.in_lede = False

    def nl(self):
        self.out.append("\n")

    def handle_starttag(self, tag, attrs):
        if tag in SKIP:
            self.skip += tag not in ("img", "br", "hr")
            return
        cls = dict(attrs).get("class") or ""
        if tag == "p" and "lede" in cls.split():
            self.in_lede = True
        if tag in HEAD:
            self.nl(); self.out.append(HEAD[tag])
        elif tag == "li":
            self.nl(); self.out.append("- ")
        elif tag == "tr":
            self.nl(); self.out.append("|")
        elif tag in ("td", "th"):
            self.out.append(" ")
        elif tag == "pre":
            self.pre += 1; self.nl(); self.out.append("```\n")
        elif tag == "code" and not self.pre:
            self.out.append("`")
        elif tag in BLOCK:
            self.nl()

    def handle_endtag(self, tag):
        if tag in SKIP:
            self.skip -= tag not in ("img", "br", "hr")
            return
        if tag == "p":
            self.in_lede = False
        if tag == "span":
            if not self.pre:
                self.out.append(" ")
        elif tag in ("td", "th"):
            self.out.append(" |")
        elif tag == "pre":
            self.pre -= 1; self.out.append("\n```"); self.nl()
        elif tag == "code" and not self.pre:
            self.out.append("`")
        elif tag in BLOCK or tag in HEAD:
            self.nl()

    def handle_data(self, data):
        if self.skip:
            return
        if not self.pre:
            data = re.sub(r"\s+", " ", data)
        if self.in_lede:
            self.lede.append(data)
        self.out.append(data)

    def text(self):
        lines, fence = [], False
        for l in "".join(self.out).split("\n"):
            if l.strip() == "```":
                fence = not fence
            lines.append(l.rstrip() if fence else re.sub(r" {2,}", " ", l).strip())
        body = "\n".join(lines)
        return re.sub(r"\n{3,}", "\n\n", body).strip() + "\n"


def main(src):
    src = pathlib.Path(src)
    order = re.findall(r"\[(.+?)\]\(([\w-]+)/\)", (src / "index.md").read_text())
    OUT.mkdir(exist_ok=True)
    for old in OUT.glob("*.md"):
        old.unlink()
    rows = []
    for title, slug in order:
        p = Text()
        p.feed((src / slug / "lesson.html").read_text())
        body = re.sub(r"\n{3,}", "\n\n", "\n".join(l for l in p.text().split("\n") if not PRIVATE_IP.search(l)))
        (OUT / f"{slug}.md").write_text(body)
        gist = re.sub(r"\s+", " ", "".join(p.lede)).strip()
        gist = re.split(r"(?<=[.다])\s", gist, maxsplit=1)[0]  # 첫 문장만
        rows.append(f"- [{title}]({slug}.md) — {gist}")
    (OUT / "index.md").write_text(
        "# 떼루아 레슨 목차\n\n"
        "원본은 podo `content/lessons` 다. `scripts/sync-lessons.py` 로 다시 만든다 — 직접 고치지 않는다.\n\n"
        + "\n".join(rows) + "\n"
    )
    print(f"{len(rows)}개 레슨 → {OUT}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else sys.exit(__doc__))
