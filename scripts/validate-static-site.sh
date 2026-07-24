#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INDEX_FILE="$PROJECT_ROOT/index.html"

if [[ ! -f "$INDEX_FILE" ]]; then
  echo "Missing index.html" >&2
  exit 1
fi

python3 - "$INDEX_FILE" <<'PY'
from html.parser import HTMLParser
from pathlib import Path
import sys

void = {"area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "param", "source", "track", "wbr"}

class Validator(HTMLParser):
    def __init__(self):
        super().__init__()
        self.stack = []
        self.errors = []

    def handle_starttag(self, tag, attrs):
        if tag not in void:
            self.stack.append(tag)

    def handle_endtag(self, tag):
        if tag in void:
            return
        if not self.stack or self.stack[-1] != tag:
            self.errors.append(f"unexpected closing tag: {tag}")
            return
        self.stack.pop()

path = Path(sys.argv[1])
parser = Validator()
parser.feed(path.read_text(encoding="utf-8"))
if parser.errors or parser.stack:
    raise SystemExit("HTML validation failed: " + "; ".join(parser.errors + parser.stack))
print(f"Static site validation passed: {path.name}")
PY
