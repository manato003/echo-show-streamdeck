---
title: 5. Fully Kiosk Browser
nav_order: 5
---

# 5. Fully Kiosk Browser

Echo Show 側で「Companion のボタン画面を全画面表示し続ける」役割を担うアプリです。

## 5.1 インストール

[fully-kiosk.com](https://www.fully-kiosk.com/) から APK をダウンロードし、サイドロードします。

```
adb -s <ECHO_IP>:5555 install fully-kiosk.apk
```

## 5.2 設定

| 設定項目 | 値 | 備考 |
|---|---|---|
| **Start URL** | `http://<PC_IP>:8000/emulator/<EMULATOR_ID>` | [7 章]({{ site.baseurl }}/07-companion/) で作るエミュレーターの URL |
| Kiosk Mode | **OFF** | PLUS ライセンスが必要 → [11 章]({{ site.baseurl }}/11-limitations/) |
| Remote Administration | **OFF** | 同上。ONだと透かしが出る |
| Screen Always On | ON | 常時表示させるため |
| Web Zoom and Scaling | 好みで調整 | ボタンを大きく見せる唯一の実用手段（後述） |

設定値の実体は次のファイルに保存されます。トラブル時はここを直接確認できます。

```
/data/data/de.ozerov.fully/shared_prefs/de.ozerov.fully_preferences.xml
```

Start URL は `startURL` キーに入っています。

## 5.3 ⚠️ 起動は必ず URL を明示すること {#launch-with-url}

これは本プロジェクト最大級のハマりどころです。

**データ URI なしで起動すると、設定済みの Start URL を「見失った」ように振る舞います。**

```
# ✗ これをやると Quick Start Settings のオンボーディング画面が出る
am start -n de.ozerov.fully/de.ozerov.fully.FullyActivity
```

しかもこの画面の Start URL 欄には、実際に保存されている値ではなく
プレースホルダの既定値 `https://www.fully-kiosk.com/welcome/` が表示されます
（`shared_prefs` を見ると正しい値が保存されていることは確認済み）。
**この画面で URL を打ち直さずに "START USING FULLY" を押すと、
プレースホルダのほうが読み込まれ、場合によっては保存されてしまいます。**

```
# ✓ 常にこの形で起動する
am start -a android.intent.action.VIEW \
  -d 'http://<PC_IP>:8000/emulator/<EMULATOR_ID>' \
  -n de.ozerov.fully/de.ozerov.fully.FullyActivity
```

Intent データとして URL を渡せば Quick Start 画面を完全にバイパスできます。
[6 章]({{ site.baseurl }}/06-autostart/) の自動起動スクリプトもこの形です。

{: .note }
> 🔶 設定ファイルが無事なときと壊れたときの両方を観測しており、
> 正確なトリガー条件は特定できていません。
> **「URL を明示して起動する」を常に守る**のが確実な回避策です。

## 5.4 ⚠️ 操作上の細かい罠

- **設定内の検索ボックスは、検索するたびに前回の文字列がクリアされず連結されます。**
  毎回 X（クリア）ボタンを押してから入力してください。
- **画面左端付近（960px 幅で概ね x < 100px）のタップは、
  Fully Kiosk の「左端スワイプ＝設定メニュー」ジェスチャーとして誤認識されることがあります。**
  ADB でタップを送るときは UI 要素の中央寄りを狙ってください。
- Kiosk Mode を有効にした場合、設定画面へは「戻るボタン長押し」または左端スワイプ＋
  **Kiosk PIN** が必要です。**PIN の既定値は `1234` なので、有効化するなら必ず変更してください。**

## 5.5 ⚠️ Fire OS の「ユーザー補助」に出てこない問題

Fire OS の Accessibility 設定画面には「ダウンロード済みのサービス」セクションが
**そもそも存在しません。**（Fire OS の UI 上の制限であり、バグではありません）

Kiosk Mode に必要な Fully Kiosk の Accessibility Service は UI から有効化できないので、
ADB で直接設定します。

```
adb shell settings put secure enabled_accessibility_services de.ozerov.fully/de.ozerov.fully.MyAccessibilityService
adb shell settings put secure accessibility_enabled 1
```

本手順書では Kiosk Mode を OFF にしているため、この設定は使いません。
Kiosk Mode を使う場合のみ実施してください。

## 5.6 ボタンを大きく表示したい場合 {#page-zoom}

Companion 側で行数・列数を減らしても**ボタンは大きくなりません**
（→ [7 章]({{ site.baseurl }}/07-companion/#grid-size)）。

**Fully Kiosk 側の "Web Zoom and Scaling" → Initial Scale / Page Zoom でページ全体を拡大する**
のが実用的な唯一の方法です。
