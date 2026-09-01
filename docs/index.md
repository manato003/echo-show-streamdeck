---
title: はじめに
nav_order: 1
---

# Echo Show を Stream Deck にする

サポートの切れた **Amazon Echo Show 5（第2世代 / 2021, コードネーム `cronos`）** を root 化し、
[Fully Kiosk Browser](https://www.fully-kiosk.com/) で
[Bitfocus Companion](https://bitfocus.io/companion) の Web Buttons 画面を全画面表示することで、
**タッチ操作できる物理コントロールパネル（Stream Deck 相当）** として再利用するための手順書です。

電源を挿すだけで自動的にボタン画面が立ち上がり、ボタンを押すと PC 側で
音量操作・Discord ミュート・スクリーンショット・スマート家電の操作などが実行されます。

---

## この手順書でできること

| カテゴリ | 例 |
|---|---|
| PC の音量操作 | マスター音量アップ / ダウン / ミュート、アプリ別ミキサーを開く |
| ボイスチャット | Discord のミュート切り替え（Discord の UI 上でもミュート表示になる） |
| スクリーンショット | アクティブウィンドウ / 範囲選択 |
| アプリ起動 | 任意のアプリ・URL をワンタップで起動 |
| スマートホーム | SwitchBot 経由で照明を操作、温湿度をボタンに表示 |
| 状態表示 | ボタンのアイコン・色を PC 側の状態に応じて自動で切り替え |


## 全体構成

```
┌──────────────────────────┐          ┌───────────────────────────────┐
│  Echo Show 5 (2nd gen)   │          │  Windows PC                   │
│  ─ root 化 (Magisk)      │  LAN     │  ─ Bitfocus Companion :8000   │
│  ─ Fully Kiosk Browser   │ ───────► │  ─ PowerShell スクリプト群     │
│    （全画面でボタン表示）  │  HTTP    │  ─ Discord / ゲーム / etc.    │
└──────────────────────────┘          └───────────────┬───────────────┘
         ▲                                            │
         │ ADB (TCP 5555) ─ 保守・復旧用               │ HTTPS
         └────────────────────────────────────────┐   ▼
                                                  │  SwitchBot OpenAPI
```

- Echo Show は **ただのブラウザ端末**です。ロジックは一切持ちません。
- ボタンを押す → Companion が PC 上で PowerShell スクリプトを実行する、という単純な流れです。
- ADB は日常運用では使いません。**セットアップと復旧のためだけ**に常時有効化しておきます。

---

## 読む順番

セットアップは下から順に積み上げる構成になっています。**上から順に実施してください。**

| # | ページ | 内容 |
|---|---|---|
| 2 | [必要なもの・前提知識]({{ site.baseurl }}/02-prerequisites/) | 機材・ソフト・リスクの確認 |
| 3 | [Echo Show の root 化]({{ site.baseurl }}/03-rooting/) | amonet-cronos / TWRP / Magisk |
| 4 | [ADB の常時有効化]({{ site.baseurl }}/04-adb/) | USB / Wi-Fi ADB を OTA に耐える形で固定 |
| 5 | [Fully Kiosk Browser]({{ site.baseurl }}/05-fully-kiosk/) | 表示アプリの導入と設定 |
| 6 | [起動時の自動起動]({{ site.baseurl }}/06-autostart/) | 電源投入だけで立ち上がるようにする |
| 7 | [PC 側：Companion の設定]({{ site.baseurl }}/07-companion/) | エミュレーターとシェル実行の有効化 |
| 8 | [ボタンを作る]({{ site.baseurl }}/08-buttons/) | 各機能のスクリプトと設定 |
| 9 | [日常の使い方]({{ site.baseurl }}/09-operation/) | 正常な状態の見分け方・復旧コマンド |
| 10 | [トラブルシューティング]({{ site.baseurl }}/10-troubleshooting/) | 実際に踏んだ地雷とその回避策 |
| 11 | [既知の制限・見送った項目]({{ site.baseurl }}/11-limitations/) | PLUS ライセンス・保留機能 |
| 12 | [スクリプトリファレンス]({{ site.baseurl }}/12-scripts/) | 全ファイルの一覧と役割 |

{: .warning }
> **10 章は必ず目を通してください。**
> このプロジェクトで最も価値があるのは手順そのものではなく、
> 「なぜ動かないのか」が分からない類の罠（OTA で root が飛ぶ、Discord が合成キーを無視する、
> Companion のシェル実行が既定で無効、など）の記録です。

---

## 表記のルール

環境依存の値はプレースホルダで書いてあります。自分の値に読み替えてください。

| プレースホルダ | 意味 | 例 |
|---|---|---|
| `<PC_IP>` | Companion を動かす Windows PC の LAN IP | `192.168.1.30` |
| `<ECHO_IP>` | Echo Show の LAN IP | `192.168.1.221` |
| `<EMULATOR_ID>` | Companion が生成するエミュレーター（Surface）の ID | `aB3xY9kL2mQ7pR4sT6vW` |
| `<REPO>` | このリポジトリを置いたローカルパス | `C:\Dev\projects\companion-pc-tools` |

記号の意味：

- ⚠️ ハマりどころ・破損リスクのある操作
- 💡 推奨事項
- 🔶 未検証・要確認の項目（そのまま鵜呑みにしないこと）
