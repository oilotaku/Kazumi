#!/usr/bin/env python3
"""直接修補官方 Kazumi IPA 的 Dart AOT 快照字串:簡體 → 台灣正體。

用法: python3 tools/patch_ipa_strings.py <App.framework/App> [--dry-run]
保留官方建置內嵌的 API 憑證(彈幕等),不需重新編譯。
只改通過 Dart 字串 hash 驗證的 TwoByteString 物件;轉換後長度必須相同
(否則退回逐字轉換),並重算 hash。KEEP 內為與 API 資料比對的字串,不轉。
"""
import re
import struct
import sys

import opencc

from s2twp import KEEP as SRC_KEEP, OVERRIDE

TWO_BYTE_STRING_CID = 0x5F  # Dart 3.x arm64 AOT;版本不符時會找不到任何字串
S2TWP = opencc.OpenCC('s2twp')
S2TW = opencc.OpenCC('s2tw')
S2T = opencc.OpenCC('s2t')
HAN = re.compile(r'[\u4e00-\u9fff]')
REGEX_CHARS = re.compile(r'[\\\[\]()?*+^$|]')
KEEP = set(SRC_KEEP)


def dart_hash(units) -> int:
    h = 0
    for u in units:
        h = (h + u) & 0xFFFFFFFF
        h = (h + (h << 10)) & 0xFFFFFFFF
        h ^= h >> 6
    h = (h + (h << 3)) & 0xFFFFFFFF
    h ^= h >> 11
    h = (h + (h << 15)) & 0xFFFFFFFF
    h &= (1 << 30) - 1
    return h or 1


def convert(text: str) -> str:
    for cc in (S2TWP, S2TW):
        out = cc.convert(text)
        for src, dst in OVERRIDE.items():
            if len(src) == len(dst):
                out = out.replace(src, dst)
        if len(out) == len(text):
            return out
    # 逐字轉換保證長度不變
    return ''.join(c if len(t := S2T.convert(c)) != 1 else t for c in text)


def main() -> None:
    path = sys.argv[1]
    dry = '--dry-run' in sys.argv
    data = bytearray(open(path, 'rb').read())
    seen = changed = kept = 0
    keep_cands = set()
    for off in range(0, len(data) - 16, 8):
        tags, h, ln = struct.unpack_from('<IIQ', data, off)
        if (tags >> 12) & 0xFFFFF != TWO_BYTE_STRING_CID or ln & 1 or not 2 <= ln < 1 << 20:
            continue
        nbytes = ln  # Smi(len) == len * 2 == 位元組數
        start = off + 16
        if start + nbytes > len(data):
            continue
        units = struct.unpack_from(f'<{nbytes // 2}H', data, start)
        if h != dart_hash(units):
            continue
        seen += 1
        text = bytes(data[start:start + nbytes]).decode('utf-16-le', 'surrogatepass')
        if not HAN.search(text):
            continue
        if text in KEEP or (REGEX_CHARS.search(text) and re.search(r'\\[dsw]|\[[^\]]*[\u4e00-\u9fff]', text)):
            kept += 1
            keep_cands.add(text)
            continue
        out = convert(text)
        if out == text:
            continue
        assert len(out) == len(text)
        new_units = struct.unpack(f'<{nbytes // 2}H', out.encode('utf-16-le'))
        data[start:start + nbytes] = out.encode('utf-16-le')
        struct.pack_into('<I', data, off + 4, dart_hash(new_units))
        changed += 1
    print(f'strings={seen} changed={changed} kept={kept}')
    print('kept:', sorted(keep_cands))
    if not dry:
        open(path, 'wb').write(data)


if __name__ == '__main__':
    main()
