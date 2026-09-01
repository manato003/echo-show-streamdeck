---
title: 7. PC 側：Companion の設定
nav_order: 7
---

# 7. PC 側：Companion の設定

## 7.1 インストール

[Bitfocus Companion](https://bitfocus.io/companion) v5.x をインストールします（検証は v5.0.3）。
管理 UI は `http://<PC_IP>:8000` で開きます。

## 7.2 ⚠️ 最重要：Shell command support を有効にする {#shell-command-support}

**これをやらないと、PC 操作系のボタンが 1 つも動きません。**
しかも**エラーは一切出ません**（ボタンは光るのに PC が反応しない）。

Companion 5.0 はセキュリティ上、シェルコマンド実行を既定で無効にしています。
有効化は **Web 管理 UI ではなく、デスクトップのトレイアプリ「Companion Launcher」**から行います。

```
Companion Launcher → Advanced Settings → Dangerous Features
  → "Shell command support" にチェック
```

チェックすると Companion が再起動します。

{: .warning }
> ⚠️ **Companion を再インストールしたり設定がリセットされると、この設定は戻ります。**
> 「ボタンは光るのに PC が反応しない」ときは、まずここを疑ってください。

## 7.3 エミュレーター（Surface）を作る

Echo Show に表示する仮想サーフェスを作成します。

```
Surfaces → Add Emulator
```

- 名前：任意（例：`Echo show`）
- ID：作成時に自動生成される文字列（例：`aB3xY9kL2mQ7pR4sT6vW`）
  → これが `<EMULATOR_ID>` です

表示 URL は次の形になります。この URL を Fully Kiosk の Start URL に設定します。

```
http://<PC_IP>:8000/emulator/<EMULATOR_ID>
```

{: .warning }
> ⚠️ **`127.0.0.1` や `localhost` ではなく、LAN の IP（`<PC_IP>`）を使ってください。**
> Companion の Web サーバーは LAN インターフェイスにのみバインドしており、
> ループバックでは応答しないことがあります。
> （これは後述の [カスタム変数 API]({{ site.baseurl }}/08-buttons/#feedback-variables) でも同じです）

## 7.4 グリッドサイズの仕様 {#grid-size}

Echo Show 5 の画面は小さいので、既定の 4×8 では 1 ボタンが小さすぎます。
本構成では **3×3** にしています。

ここに紛らわしい仕様があります。

| 設定 | 実際の意味 |
|---|---|
| `Settings → Buttons → Grid Size` | **グローバルのキャンバスサイズ**（ボタンを配置できる領域全体） |
| `Surfaces → [emulator] → Show Settings` の Row / Column 数 | そのサーフェスがキャンバスの**どの範囲を表示するか**だけを決める |

{: .warning }
> ⚠️ **行列数を減らしても個々のボタンは大きくなりません。**
> エミュレーター / タブレットビューはセルを固定サイズで描画し、周囲に余白を空けるだけです。
> ボタンを大きくしたいなら、
> [Fully Kiosk の Page Zoom]({{ site.baseurl }}/05-fully-kiosk/#page-zoom) で
> ページ全体を拡大してください。

{: .note }
> 🔶 テスト中、エミュレーター上のページ表示が `2/x/x` になっていました。
> Fully Kiosk の Start URL が既定でどのページ番号に着地するのかは確認しきれていません。
> **起動直後に意図したページが出ているかを一度確認してください。**
> ずれる場合は URL の末尾でページを明示できます。

## 7.5 ボタンにアクションを設定する

各ボタンに Internal アクション **"System: Run shell command (local)"** を追加し、
Command に次の形式で入力します。

```
powershell.exe -ExecutionPolicy Bypass -File "<REPO>\<script>.ps1"
```

`<REPO>` はこのリポジトリをクローンしたローカルパスです（例：`C:\Dev\projects\companion-pc-tools`）。

- `-ExecutionPolicy Bypass` は署名なしスクリプトを実行するために必要です。
- **パスに空白が含まれる場合は必ずダブルクォートで囲んでください。**
- ウィンドウを出したくない場合は `-WindowStyle Hidden -NoProfile` を追加します。

どのスクリプトをどのボタンに割り当てるかは [8 章]({{ site.baseurl }}/08-buttons/) を参照してください。

## 7.6 config.ps1 を用意する {#config}

スクリプトが使う環境依存の値（Companion の IP、エミュレーター ID、ADB のパス、
SwitchBot のデバイス ID）は **1 つのファイルに集約**されています。
`config.example.ps1` をコピーして `config.ps1` を作り、自分の値を書いてください。

```powershell
Copy-Item config.example.ps1 config.ps1
```

```powershell
$CompanionHost = "<PC_IP>"          # 127.0.0.1 ではなく LAN の IP
$CompanionPort = "8000"
$CompanionEmulatorId = "<EMULATOR_ID>"

$EchoShowIp = "<ECHO_IP>"
$AdbPath = "C:\platform-tools\adb.exe"

$SwitchBotLightDeviceId = "..."     # SwitchBot を使う場合のみ
$SwitchBotMeterDeviceId = "..."
```

{: .highlight }
> 💡 `config.ps1` は `.gitignore` 済みです。
> **各スクリプトを直接編集する必要はありません。** 環境が変わったらこのファイルだけ直します。

このファイルは、Companion のカスタム変数を更新する共通関数
`Set-CompanionVariable` も提供します（→ [8.4]({{ site.baseurl }}/08-buttons/#feedback-variables)）。

認証情報（SwitchBot のトークン等）は `config.ps1` ではなく
**`switchbot_secrets.ps1`** に分けて置きます（→ [8.6]({{ site.baseurl }}/08-buttons/#switchbot)）。
