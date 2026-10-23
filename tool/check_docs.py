"""Checks the written documentation. Run from the project folder:

    python3 tool/check_docs.py

It fails (exit 1) if:
  * a file the docs rely on is missing,
  * a relative link or a picture points at a file that does not exist,
  * a link to a heading (#anchor) points at a heading that does not exist,
  * the README does not link to every page in docs/.
"""
import glob
import os
import re
import sys
import urllib.parse

REQUIRED = [
    "README.md", "SECURITY.md", "CONTRIBUTING.md", "CHANGELOG.md",
    ".github/pull_request_template.md",
    ".github/ISSUE_TEMPLATE/problem.md", ".github/ISSUE_TEMPLATE/idea.md",
]

files = [f for f in ["README.md", "SECURITY.md", "CONTRIBUTING.md",
                     "CHANGELOG.md", "STRIPE_SETUP.md"] if os.path.exists(f)]
files += sorted(glob.glob("docs/*.md"))
problems = []


def slug(heading):
    h = re.sub(r"[`*_]", "", heading.strip().lower())
    h = re.sub(r"[^\w\- ]", "", h)
    return h.replace(" ", "-")


for path in REQUIRED:
    if not os.path.exists(path):
        problems.append(f"missing file: {path}")

anchors = {}
for f in files:
    text = open(f, encoding="utf-8").read()
    anchors[f] = {slug(m.group(2))
                  for m in re.finditer(r"^(#{1,6})\s+(.*)$", text, re.M)}

link = re.compile(
    r'(?<!!)\[[^\]]*\]\(([^)\s]+)\)|<img[^>]*src="([^"]+)"|<a href="([^"]+)"')
for f in files:
    text = open(f, encoding="utf-8").read()
    for m in link.finditer(text):
        target_link = m.group(1) or m.group(2) or m.group(3)
        if target_link.startswith(("http://", "https://", "mailto:")):
            continue
        path, _, frag = target_link.partition("#")
        path = urllib.parse.unquote(path)
        target = f if path == "" else os.path.normpath(
            os.path.join(os.path.dirname(f), path))
        if not os.path.exists(target):
            problems.append(f"{f}: broken link -> {target_link}")
        elif frag and target.endswith(".md") and frag not in anchors.get(target, set()):
            problems.append(f"{f}: no heading #{frag} in {target}")

readme = open("README.md", encoding="utf-8").read()
for page in sorted(glob.glob("docs/*.md")):
    name = urllib.parse.quote(os.path.basename(page))
    if f"docs/{name}" not in readme:
        problems.append(f"README.md does not link to {page}")

if problems:
    print("\n".join(problems))
    sys.exit(1)
print(f"docs ok: {len(files)} pages checked")
