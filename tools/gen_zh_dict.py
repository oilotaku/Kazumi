#!/usr/bin/env python3
"""產生 App 內即時簡→台灣正體轉換用的字典 assets/opencc/s2twp.txt。

每行「簡體\t正體」,先列詞組再列單字;Dart 端做最長詞優先比對(lib/utils/zh_convert.dart)。
需要 pip 套件 opencc-python-reimplemented。
"""
import pathlib

import opencc

D = pathlib.Path(opencc.__file__).parent / 'dictionary'
S2TWP = opencc.OpenCC('s2twp')
S2TW = opencc.OpenCC('s2tw')
T2S = opencc.OpenCC('t2s')


def load(name):
    for line in (D / name).read_text(encoding='utf-8').splitlines():
        if '\t' in line:
            k, v = line.split('\t', 1)
            yield k, v.split(' ')[0]


phrases = {}
for k, _ in load('STPhrases.txt'):
    if len(k) > 1:
        phrases[k] = S2TWP.convert(k)
for k, _ in load('TWPhrasesIT.txt') if (D / 'TWPhrasesIT.txt').exists() else load('TWPhrases.txt'):
    s = T2S.convert(k)
    if len(s) > 1:
        phrases[s] = S2TWP.convert(s)
chars = {}
for k, _ in load('STCharacters.txt'):
    v = S2TW.convert(k)
    if v != k:
        chars[k] = v
lines = [f'{k}\t{v}' for k, v in phrases.items() if k != v]
lines += [f'{k}\t{v}' for k, v in chars.items()]
out = pathlib.Path('assets/opencc/s2twp.txt')
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text('\n'.join(lines) + '\n', encoding='utf-8')
print(f'phrases={sum(1 for k, v in phrases.items() if k != v)} chars={len(chars)} bytes={out.stat().st_size}')
