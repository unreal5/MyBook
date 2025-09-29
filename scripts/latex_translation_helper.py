"""Helper to prepare LaTeX files for Chinese translation while preserving formatting.

This script DOES NOT perform machine translation (to avoid copyright / quality issues).
It creates a parallel directory with the same .tex files, wrapping translatable
paragraph text into a \Trans{EN}{ZH} macro so you can later fill in Chinese.

Heuristics:
 - Keeps lines starting with LaTeX commands (beginning with backslash) unchanged.
 - Leaves environments like code/listings verbatim.
 - For plain text lines (containing letters / punctuation and not only braces or spaces),
   inserts a preceding comment with the English source and wraps the English inside \Trans{...}{}.
 - Consecutive text lines are merged into paragraphs to reduce repetition.

Usage:
  python scripts/latex_translation_helper.py --source chapters_new --target chapters_cn

After populating Chinese text in the second argument of each \Trans macro, you can
switch rendering mode in the Chinese main file by redefining \Trans.
"""
from __future__ import annotations
import argparse
import re
from pathlib import Path

CMD_PATTERN = re.compile(r"^\\[a-zA-Z@]+")
ONLY_BRACES_WS = re.compile(r"^[{}\\s]*$")

def is_pure_command_line(line: str) -> bool:
    if CMD_PATTERN.match(line.strip()):
        # treat sectioning / chapter lines as commands we keep verbatim
        return True
    return False

def should_wrap(line: str) -> bool:
    s = line.rstrip('\n')
    if not s.strip():
        return False
    if is_pure_command_line(s):
        return False
    if s.lstrip().startswith('%'):  # comment
        return False
    if ONLY_BRACES_WS.match(s):
        return False
    # Skip lines that are likely part of environments we don't translate
    if s.lstrip().startswith(('\\begin{code}', '\\end{code}')):
        return False
    return True

def paragraphize(lines):
    para = []
    for line in lines:
        if should_wrap(line):
            para.append(line.rstrip('\n'))
        else:
            if para:
                yield '\n'.join(para)
                para = []
            yield line.rstrip('\n')
    if para:
        yield '\n'.join(para)

def transform_file(src: Path, dst: Path):
    content = src.read_text(encoding='utf-8', errors='ignore').splitlines()
    out_lines = []
    for block in paragraphize(content):
        if '\n' in block:  # paragraph
            en = block
            # Escape closing brace in comment safely
            out_lines.append(f"% EN: {en.replace('}', ' }')}")
            en_single_line = ' '.join(en.split())
            out_lines.append(f"\\Trans{{{en_single_line}}}{{}}")
            out_lines.append("")
        else:
            if should_wrap(block):
                en_single_line = ' '.join(block.split())
                out_lines.append(f"% EN: {block}")
                out_lines.append(f"\\Trans{{{en_single_line}}}{{}}")
            else:
                out_lines.append(block)
    dst.write_text('\n'.join(out_lines) + '\n', encoding='utf-8')

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--source', default='chapters_new', help='Directory with original split chapters')
    ap.add_argument('--target', default='chapters_cn', help='Output directory for translation-ready files')
    args = ap.parse_args()
    src_dir = Path(args.source)
    tgt_dir = Path(args.target)
    tgt_dir.mkdir(parents=True, exist_ok=True)
    for src in sorted(src_dir.glob('*.tex')):
        dst = tgt_dir / src.name
        transform_file(src, dst)
        print(f"Prepared {dst}")
    print('Done. Now edit each \\Trans{EN}{ZH} to add Chinese text.')

if __name__ == '__main__':
    main()
