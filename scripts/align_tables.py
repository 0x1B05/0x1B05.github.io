#!/usr/bin/env python3
"""Realign Markdown table columns by display width (CJK counts as 2).

Usage:
  scripts/align_tables.py [path]     # apply in place
  scripts/align_tables.py --check    # report only, do not write

Only contiguous blocks of `| ... |` lines are reformatted; separator-row
alignment markers (:---:) are preserved. The rewrite is idempotent.
"""
import re
import sys
import unicodedata
from pathlib import Path

def display_width(s):
    return sum(2 if unicodedata.east_asian_width(ch) in 'WF' else 1 for ch in s)

cell_re = re.compile(r'^(\s*)\|(.*)\|\s*$')
sep_re = re.compile(r'^\s*:?-{2,}:?\s*$')

def align(lines):
    out = []
    i = 0
    changed_blocks = 0
    changed_lines = 0
    while i < len(lines):
        if not cell_re.match(lines[i]):
            out.append(lines[i])
            i += 1
            continue
        j = i
        block = []
        while j < len(lines) and cell_re.match(lines[j]):
            block.append(lines[j])
            j += 1
        rows = []
        for bl in block:
            indent, inner = cell_re.match(bl).groups()
            rows.append((indent, inner.split('|')))
        ncol = max(len(c) for _, c in rows)
        if ncol < 2:
            out.extend(block)
            i = j
            continue
        widths = [0] * ncol
        for _, cells in rows:
            for k, c in enumerate(cells):
                cs = c.strip()
                if sep_re.match(cs):
                    continue
                widths[k] = max(widths[k], display_width(cs))
        newblock = []
        for indent, cells in rows:
            parts = []
            for k in range(ncol):
                cs = cells[k].strip() if k < len(cells) else ''
                if sep_re.match(cs):
                    l, r = cs.startswith(':'), cs.endswith(':')
                    dash_n = max(3, widths[k] + 1 - int(l) - int(r))
                    seg = (':' if l else '') + '-' * dash_n + (':' if r else '')
                    parts.append(' ' + seg + ' ' * (widths[k] + 1 - display_width(seg)) + ' ')
                else:
                    parts.append(' ' + cs + ' ' * (widths[k] - display_width(cs) + 2))
            newblock.append(indent + '|' + '|'.join(parts) + '|')
        if newblock != block:
            changed_blocks += 1
            changed_lines += sum(1 for a, b in zip(block, newblock) if a != b)
        out.extend(newblock)
        i = j
    return out, changed_blocks, changed_lines

def main():
    args = [a for a in sys.argv[1:]]
    check = '--check' in args
    args = [a for a in args if not a.startswith('--')]
    default = Path(__file__).resolve().parent.parent / 'ISA' / 'tile-npu-isa.typ'
    target = Path(args[0]) if args else default
    lines = target.read_text(encoding='utf-8').split('\n')
    out, blocks, nlines = align(lines)
    print(f'{target}: blocks changed: {blocks}, lines re-aligned: {nlines}')
    if blocks and not check:
        target.write_text('\n'.join(out), encoding='utf-8')

if __name__ == '__main__':
    main()
