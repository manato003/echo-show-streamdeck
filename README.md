# echo-show-streamdeck

サポートの切れた **Amazon Echo Show 5（第2世代 / `cronos`）** を root 化し、
[Bitfocus Companion](https://bitfocus.io/companion) の Web Buttons を全画面表示することで、
**タッチ操作できる物理コントロールパネル（Stream Deck 相当）** として再利用するプロジェクトです。

電源を挿すだけで自動的にボタン画面が立ち上がり、ボタンを押すと Windows PC 側で
音量操作・Discord ミュート・スクリーンショット・SwitchBot 家電操作などが実行されます。

## 📖 手順書

**→ [https://manato003.github.io/echo-show-streamdeck/](https://manato003.github.io/echo-show-streamdeck/)**

ソースは [`docs/`](docs/) にあります（ページ間リンクは公開サイト上でのみ機能します）。

| # | ページ | 内容 |
|---|---|---|
| 1 | [はじめに](docs/index.md) | 全体構成・読む順番・表記のルール |
| 2 | [必要なもの・前提知識](docs/02-prerequisites.md) | 機材・ソフト・リスクの確認 |
| 3 | [Echo Show の root 化](docs/03-rooting.md) | amonet-cronos / TWRP / Magisk |
| 4 | [ADB の常時有効化](docs/04-adb.md) | OTA に耐える systemless な設定 |
| 5 | [Fully Kiosk Browser](docs/05-fully-kiosk.md) | 表示アプリの導入と設定 |
| 6 | [起動時の自動起動](docs/06-autostart.md) | 電源投入だけで立ち上がるようにする |
| 7 | [PC 側：Companion の設定](docs/07-companion.md) | エミュレーターとシェル実行の有効化 |
| 8 | [ボタンを作る](docs/08-buttons.md) | 各機能のスクリプトと設定 |
| 9 | [日常の使い方](docs/09-operation.md) | 正常な状態の見分け方・復旧コマンド |
| 10 | [トラブルシューティング](docs/10-troubleshooting.md) | **実際に踏んだ地雷の記録。最重要** |
| 11 | [既知の制限・見送った項目](docs/11-limitations.md) | PLUS ライセンス・保留機能 |
| 12 | [スクリプトリファレンス](docs/12-scripts.md) | 全ファイルの一覧と役割 |

## リポジトリの中身

このリポジトリには、Companion のボタンから呼び出す **PowerShell スクリプト**と
**自作アイコン**が入っています。詳細は [12 章](docs/12-scripts.md) を参照してください。

## セットアップ（PC 側だけ）

```powershell
git clone https://github.com/manato003/echo-show-streamdeck.git
cd echo-show-streamdeck

# 1. 環境設定（必須）
Copy-Item config.example.ps1 config.ps1
# → config.ps1 に Companion の IP・エミュレーター ID・adb.exe のパスなどを記入

# 2. SwitchBot を使う場合のみ
Copy-Item switchbot_secrets.example.ps1 switchbot_secrets.ps1
# → switchbot_secrets.ps1 にトークンとシークレットを記入
```

`config.ps1` と `switchbot_secrets.ps1` は `.gitignore` 済みです。
**環境依存の値はすべてこの 2 ファイルに集約されているので、各スクリプトを編集する必要はありません。**

Companion のボタンには次の形式でコマンドを設定します。

```
powershell.exe -ExecutionPolicy Bypass -File "C:\path\to\echo-show-streamdeck\volume_up.ps1"
```

## ⚠️ 免責

- root 化は**メーカー非公認の改造**です。保証は失われ、**文鎮化のリスク**があります。
- **自己責任でご利用ください。** 本リポジトリの内容によるいかなる損害にも責任を負いません。
- 手順は Echo Show 5 **第2世代**（Fire OS 6.5.x）でのみ検証しています。

## 🔒 自分の環境の値について

このリポジトリには**作者の環境固有の値は含まれていません。** 環境依存の値はすべて
`config.ps1` / `switchbot_secrets.ps1`（どちらも `.gitignore` 済み）に分離されています。

フォークして公開する場合も、この 2 ファイルをコミットしなければ安全です。
`docs/` 配下は `<PC_IP>` / `<ECHO_IP>` / `<EMULATOR_ID>` / `<REPO>` のプレースホルダで書かれています。

## ライセンス

スクリプトとアイコンは MIT ライセンスです。
