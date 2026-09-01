---
title: 8. ボタンを作る
nav_order: 8
---

# 8. ボタンを作る

すべてのボタンは「Companion の Run shell command → PowerShell スクリプト」という
同じ形をしています。**追加したい機能があれば `.ps1` を 1 つ書いて割り当てるだけです。**

各スクリプトの詳細は [12 章 スクリプトリファレンス]({{ site.baseurl }}/12-scripts/) を参照。

---

## 8.1 音量操作（最も簡単な例）

ハードウェアのメディアキーをシミュレートするだけです。

| ボタン | スクリプト |
|---|---|
| 音量アップ | `volume_up.ps1` |
| 音量ダウン | `volume_down.ps1` |
| ミュート切り替え | `volume_mute_toggle.ps1` |
| アプリ別音量ミキサーを開く | `open_volume_mixer.ps1` |

中身は 1 行です。

```powershell
& "$PSScriptRoot\SendKeyCombo.ps1" -Keys "175"   # 175 = VK_VOLUME_UP
```

`SendKeyCombo.ps1` は**共通部品**です。ボタンに直接割り当てないでください。

## 8.2 スクリーンショット

| ボタン | スクリプト | 動作 |
|---|---|---|
| アクティブウィンドウ | `screenshot_active_window.ps1` | Alt+PrintScreen をシミュレートし、`%USERPROFILE%\Pictures\Screenshots\` に PNG も保存 |
| 範囲選択 | `screenshot_menu.ps1` | Windows 標準の範囲選択オーバーレイ（Win+Shift+S）を開く |

## 8.3 アプリ / URL の起動

一番応用の効くパターンです。1 行で書けます。

```powershell
Start-Process "https://www.twitch.tv/<channel>"   # open_twitch.ps1
Start-Process "E:\Games\YourGame\launcher.exe"    # launch_wuthering_waves.ps1
```

リポジトリに入っているものは**サンプル**です。自分の URL / パスに書き換えてください。

---

## 8.4 状態に応じてアイコンを切り替える {#feedback-variables}

「今ミュート中か」「照明が点いているか」をボタン上に反映させる仕組みです。
2 つのパーツで成り立っています。

**① スクリプト側：Companion のカスタム変数に HTTP POST する**

```
POST http://<PC_IP>:8000/api/custom-variable/<変数名>/value
Content-Type: text/plain
Body: 0 または 1
```

スクリプト側では、`config.ps1` が提供する共通関数を呼ぶだけです。

```powershell
Set-CompanionVariable -Name "light_on" -Value $newState
```

{: .warning }
> ⚠️ **`127.0.0.1` ではなく `<PC_IP>` を使ってください。**
> Companion の Web サーバーは LAN インターフェイスにのみバインドしており、
> ループバックでは応答しません。

**② Companion 側：フィードバックで見た目を変える**

```
ボタン → Feedbacks → Internal: Variable: Check value
  Variable = $(custom:<変数名>)
  Comparison = Equal / 1
  → 背景色・アイコンを指定
```

{: .note }
> 💡 このカスタム変数 API は Companion の機能であり、
> Fully Kiosk の Remote Administration（PLUS ライセンス対象）とは**完全に別のシステム**です。
> Remote Admin を無効にしていてもこの機能は使えます。

---

## 8.5 Discord のミュート切り替え（最難関） {#discord-mute}

**やりたいこと**：ボタンから Discord のミュートを切り替え、
かつ **Discord 自身の UI 上でもミュート表示になる**こと
（OS レベルでマイクを黙らせるだけでは不可）。

### 前提：Discord 側の手動設定（自動化不可）

```
ユーザー設定 → 音声・ビデオ → キーバインド
  → 「ミュート切り替え」= 右Ctrl + ¥
```

**Discord の設定は自動化できません。** ここがずれると無言で効かなくなります。
別のキーにする場合は `discord_mute_toggle.ps1` 内の VK コードも合わせて変更してください。

### 問題1：Discord は非フォーカス時の合成キー入力を無視する

`keybd_event` による合成イベントは、Discord が非フォーカスだと**完全に無視されます**。
Discord のアンチ自動化挙動と思われます（`LLKHF_INJECTED` フラグ等をチェックしている）。
手動でフォーカスした状態なら同じキーコンボが通ることを実験で確認済みです。

**対策**：`discord_mute_toggle.ps1` は次の流れで動きます。

1. 無害な Alt キーの押下 / 解放（Windows のフォアグラウンド奪取防止を回避するため）
2. `SetForegroundWindow` で Discord を前面化
3. 約 400ms 待機
4. ホットキーを送信
5. 約 200ms 待機
6. 元のウィンドウにフォーカスを戻す

一瞬フォーカスがちらつきますが、実用上ほとんど気になりません。

### 問題2：右Ctrl が右Ctrl として送れていない（真の根本原因）

これが本当の原因でした。詳細は
[10 章の汎用教訓]({{ site.baseurl }}/10-troubleshooting/#extended-key) を参照。

`SendKeyCombo.ps1` は該当の VK コードに自動で `KEYEVENTF_EXTENDEDKEY` を付けるよう
修正済みなので、**このスクリプト経由で書く限りこの問題を意識する必要はありません。**

### アイコン表示

`discord_mute_state.txt` に `0`/`1` を書いて**ローカルで状態を仮定して管理**しています
（Discord に現在のミュート状態を問い合わせる API が存在しないため）。
仕組みは [8.4]({{ site.baseurl }}/08-buttons/#feedback-variables) と同じで、
変数名は `discord_mute` です。

{: .warning }
> ⚠️ **このボタン以外の経路（Discord のマイクアイコンを直接クリックする等）で
> ミュートを切り替えると、表示と実態がずれます。**
> もう一度ボタンを押すか、`discord_mute_state.txt` を手で `0` / `1` に書き換えて直します。

### それでもダメなときの Plan B

`mic_mute_toggle.ps1`（OS レベルで既定のキャプチャデバイス自体をミュート）に差し替えます。
**100% 確実**ですが、Discord の UI 上はミュート表示になりません。

---

## 8.6 SwitchBot 連携（照明・温湿度） {#switchbot}

### 認証情報の設定

`switchbot_secrets.example.ps1` を `switchbot_secrets.ps1` にコピーし、自分の値を入れます。

```powershell
$SwitchBotToken  = "YOUR_SWITCHBOT_TOKEN"
$SwitchBotSecret = "YOUR_SWITCHBOT_SECRET"
```

トークンの取得場所：
**SwitchBot アプリ → プロフィール → 設定 → 「アプリバージョン」を 10 回タップ → 開発者オプション**

{: .warning }
> ⚠️ **`switchbot_secrets.ps1` は `.gitignore` 済みです。絶対にコミットしないでください。**

### デバイス ID を調べる

```powershell
. .\SwitchBotApi.ps1
Get-SwitchBotDevices | ConvertTo-Json -Depth 5
```

返ってきた `deviceId`（物理デバイス）または `infraredRemoteList` の中の `deviceId`（赤外線リモコン）を
**`config.ps1`** の `$SwitchBotLightDeviceId` / `$SwitchBotMeterDeviceId` に設定します。

### 照明トグル（`light_toggle.ps1`）

赤外線リモコン経由で照明を ON/OFF します。
**赤外線には状態を問い合わせる手段がない**ため、Discord ミュートと同じくローカルで状態を仮定し
（`light_state.txt`）、Companion のカスタム変数 `light_on` に反映しています。

デバイス ID は `config.ps1` の `$SwitchBotLightDeviceId` から読まれます。

### 温湿度の表示（`update_switchbot_status.ps1`）

SwitchBot 温湿度計から温度・湿度・バッテリーを取得し、
Companion のカスタム変数 `switchbot_temperature` / `switchbot_humidity` / `switchbot_battery` に
POST します。ボタンのテキストに `$(custom:switchbot_temperature)` と書けば表示されます。

**定期実行**：タスクスケジューラに `run_hidden_switchbot.vbs` を登録します
（コンソールウィンドウを出さないためのラッパーです）。
スクリプトの場所は自動で解決されるので、パスを書き換える必要はありません。

{: .highlight }
> 💡 SwitchBot OpenAPI は**呼び出し回数に上限（1 日あたり 10,000 回）**があります。
> 5〜10 分間隔程度にしておけば十分です。

---

## 8.7 アイコンについて

リポジトリ同梱のアイコン（`*.ico.png`）は **GDI+ のプリミティブ描画で自作したもの**で、
配布物からのダウンロード品ではありません。自由に使えます。

Companion 側の `Image Library` にアップロードし、ボタンの PNG として指定します。

## 8.8 ⚠️ PowerShell スクリプトを追加するときの注意

{: .warning }
> **日本語コメントを含む `.ps1` を BOM なし UTF-8 で保存しないでください。**
>
> Windows PowerShell 5.1 で `-File` 実行すると、システムコードページとして誤解釈され、
> 後続行が壊れて結合し、`Add-Type -AssemblyName System.Windows.Forms` が無言で失敗する等の
> 不可解な「型が見つかりません」エラーになります。
>
> **本プロジェクトの方針：`.ps1` のコメントはすべて英語にする。**
> BOM と毎回戦うより確実です。
