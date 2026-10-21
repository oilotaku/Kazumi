#!/usr/bin/env python3
"""把 lib/ 內 Dart 字串字面值與註解由簡體轉成台灣正體(OpenCC s2twp)。

用法: python3 tools/s2twp.py [lib]
需要 pip 套件 opencc-python-reimplemented。可重複執行(冪等)。
raw 字串(r'...')與 KEEP 內的字串不轉:它們用來比對 API 回傳的簡體資料。
"""
import pathlib
import re
import sys

import opencc

CC = opencc.OpenCC('s2twp')
HAN = re.compile(r'[一-鿿]')
# 依序辨識:行註解、區塊註解、raw 字串、一般字串(含三引號)
TOKEN = re.compile(
    r"""(?P<line>//[^\n]*)"""
    r"""|(?P<block>/\*.*?\*/)"""
    r"""|(?P<raw>r(?P<rq>'''|\"\"\"|'|\")(?:(?!(?P=rq)).)*?(?P=rq))"""
    r"""|(?P<q>'''|\"\"\"|'|\")(?P<body>(?:\\.|(?!(?P=q)).)*?)(?P=q)""",
    re.S,
)
# 與 Bangumi API 回傳資料比對用的鍵,必須維持簡體
KEEP = {'简体中文名', '别名', '引用来源'}
# OpenCC 轉完後再覆寫的用語
OVERRIDE = {
    '外掛': '插件',
    '規則倉庫': '規則庫',
    '引數': '參數',
    '賬號': '帳號',
    '賬戶': '帳戶',
    '繫結': '綁定',
    '移動流量': '行動數據',
    '移動資料': '行動數據',
    '移動網路': '行動網路',
    '訊息提示': '提示',
}


def convert(text: str) -> str:
    out = CC.convert(text)
    for src, dst in OVERRIDE.items():
        out = out.replace(src, dst)
    return out


def rep(m: re.Match) -> str:
    whole = m.group(0)
    if m.group('raw') or not HAN.search(whole):
        return whole
    if m.group('line') or m.group('block'):
        return convert(whole)
    body = m.group('body')
    if body in KEEP:
        return whole
    return m.group('q') + convert(body) + m.group('q')


def main() -> None:
    root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else 'lib')
    files = lines = 0
    for path in sorted(root.rglob('*.dart')):
        src = path.read_text(encoding='utf-8')
        out = src
        for _ in range(4):  # OpenCC 詞組轉換偶爾要兩輪才穩定
            nxt = TOKEN.sub(rep, out)
            if nxt == out:
                break
            out = nxt
        if out != src:
            files += 1
            lines += sum(1 for a, b in zip(src.splitlines(), out.splitlines()) if a != b)
            path.write_text(out, encoding='utf-8')
    print(f'changed files={files} lines={lines}')


if __name__ == '__main__':
    main()
