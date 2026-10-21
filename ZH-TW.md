# Kazumi 台灣正體版(個人 fork)

分支 `zh-tw`,從上游 tag 起分支。不對上游開 PR。

## 兩種產物

| 版本 | 怎麼做 | 介面 | Bangumi 內容 | 彈幕 / Bangumi 鏡像 |
|---|---|---|---|---|
| 官方修補版 | `tools/patch_ipa_strings.py` 原地改官方 IPA 的 Dart 字串 | 繁體(系統內建選單仍簡體) | 簡體 | 可用(沿用官方內嵌憑證) |
| 原始碼版 | `tools/s2twp.py` 轉字串 + `lib/utils/zh_convert.dart` 顯示時轉換,Actions 編譯 | 繁體 | 繁體 | **不可用**:需自備 DanDanPlay / Kazumi 憑證放進 repo secrets |

## 跟上游新版

```sh
git fetch upstream --tags
git rebase --onto <新tag> <舊tag> zh-tw     # 衝突時:以上游為準,再重跑腳本
pip install opencc-python-reimplemented
python3 tools/s2twp.py lib                  # 冪等,可重跑
python3 tools/gen_zh_dict.py                # 重產字典
git push                                    # 自動觸發 build-ios-unsigned.yml
```

官方修補版:解開官方 `Kazumi_ios_<版本>_no_sign.ipa`,對 `Payload/Runner.app/Frameworks/App.framework/App` 跑
`python3 tools/patch_ipa_strings.py <App>`(在 tools/ 目錄內執行),再 `zip -r` 回 IPA。
若輸出 `strings=0`,代表 Dart 版本改了 TwoByteString 的 class id,要重新確認 `TWO_BYTE_STRING_CID`。

## 不能轉的字串

`tools/s2twp.py` 的 `KEEP`:與 Bangumi API 資料比對或送出查詢的簡體字串
(infobox 鍵、作品關聯類型、製作人員職位、角色快速欄位、搜尋題材標籤)。新增比對用中文字串要加進去。
raw 字串(`r'...'` 正規式)不轉。番名等送去搜尋片源/彈幕的字串只在顯示處用 `.tw` 轉換。
