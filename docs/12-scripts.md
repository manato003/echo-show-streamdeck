---
title: 12. スクリプトリファレンス
nav_order: 12
---

# 12. スクリプトリファレンス

リポジトリの構成と、全ファイルの役割です。

```
companion-pc-tools/
├── README.md / LICENSE
├── config/            設定（*.example.ps1 をコピーして使う）
├── scripts/
│   ├── buttons/       Companion のボタンから呼ぶスクリプト
│   ├── lib/           共通部品（ボタンに直接割り当てない）
│   └── maintenance/   復旧・定期実行
├── echo-show/         Echo Show の /data/adb/ に置く Magisk 起動スクリプト
├── icons/             ボタン用アイコン
├── webpage/           時計・天気ページ（保留中）
├── docs/              この手順書
├── tasks/             開発メモ（教訓・ToDo）
├── state/             実行時の状態ファイル（git 対象外・自動生成）
└── private/           個人メモ（git 対象外）
```

## 12.1 `config/` — 設定ファイル

| ファイル | 用途 |
|---|---|
| `config.ps1` | 環境依存の設定（Companion の IP / エミュレーター ID / ADB の接続先 / adb.exe のパス / SwitchBot デバイス ID）。**git 対象外**（→ [7.6]({{ site.baseurl }}/07-companion/#config)） |
| `config.example.ps1` | 上記のテンプレート |
| `switchbot_secrets.ps1` | SwitchBot の認証情報。**git 対象外・絶対にコミットしないこと** |
| `switchbot_secrets.example.ps1` | 上記のテンプレート |

## 12.2 `scripts/buttons/` — ボタンに割り当てるスクリプト

Companion には次の形式で登録します（→ [7.5]({{ site.baseurl }}/07-companion/)）。

```
powershell.exe -ExecutionPolicy Bypass -File "<REPO>\scripts\buttons\<ファイル名>.ps1"
```

| ファイル | 用途 |
|---|---|
| `volume_up.ps1` | マスター音量アップ（ハードウェアメディアキーをシミュレート） |
| `volume_down.ps1` | マスター音量ダウン |
| `volume_mute_toggle.ps1` | マスター音量ミュート切り替え |
| `open_volume_mixer.ps1` | Windows のアプリ別音量ミキサー（`ms-settings:apps-volume`）を開く |
| `discord_mute_toggle.ps1` | Discord を前面化 → ホットキー送信 → フォーカス復帰。Companion のカスタム変数も更新 |
| `mic_mute_toggle.ps1` | OS レベルで既定のキャプチャデバイス（物理マイク）をミュート切り替え。**Plan B** |
| `screenshot_active_window.ps1` | アクティブウィンドウをキャプチャ（Alt+PrintScreen をシミュレート）し、`%USERPROFILE%\Pictures\Screenshots\` に PNG も保存 |
| `screenshot_menu.ps1` | Windows 標準の範囲選択オーバーレイ（Win+Shift+S）を開く |
| `light_toggle.ps1` | SwitchBot 赤外線リモコン経由で照明を ON/OFF。状態を `state/light_state.txt` とカスタム変数に反映 |
| `open_twitch.ps1` | **サンプル**：指定 URL をブラウザで開く |
| `launch_wuthering_waves.ps1` | **サンプル**：指定した実行ファイルを起動する |

{: .highlight }
> 💡 `open_twitch.ps1` と `launch_wuthering_waves.ps1` は**そのまま使うものではなく雛形**です。
> URL / パスを自分のものに書き換えてください。

## 12.3 `scripts/lib/` — 共通部品

| ファイル | 用途 |
|---|---|
| `LoadConfig.ps1` | **全スクリプトの起点**。`config/config.ps1` を読み込み、`$RepoRoot` / `$LibDir` / `$StateDir` / `$CompanionBaseUrl` / `$CompanionEmulatorUrl` と、カスタム変数を更新する `Set-CompanionVariable` を定義する。各スクリプトは `. "$PSScriptRoot\..\lib\LoadConfig.ps1"` で読み込む |
| `SendKeyCombo.ps1` | グローバルなキーコンボ送信（`keybd_event` ベース）。右側モディファイア／ナビゲーションキーに `KEYEVENTF_EXTENDEDKEY` を自動付与する（→ [10 章]({{ site.baseurl }}/10-troubleshooting/#extended-key)） |
| `AudioMuteHelper.ps1` | Core Audio API の COM interop ヘルパー。`[AudioMute]` クラスに `IsMuted` / `SetMuted` の静的メソッド |
| `SwitchBotApi.ps1` | SwitchBot OpenAPI v1.1 のヘルパー（HMAC-SHA256 署名）。`Get-SwitchBotAuthHeaders` / `Get-SwitchBotDevices` / `Get-SwitchBotStatus` |
| `SwitchBotCommand.ps1` | SwitchBot デバイス／赤外線リモコンにコマンドを送る汎用ラッパー |

## 12.4 `scripts/maintenance/` — 復旧・定期実行

| ファイル | 用途 |
|---|---|
| `restart_echoshow_kiosk.ps1` | PC から ADB 経由で Fully Kiosk を強制再起動。接続先は `config/config.ps1` の `$EchoShowAdbTarget`（USB のシリアル番号、または Wi-Fi の `IP:5555`） |
| `restart_echoshow_kiosk.bat` | 上記をダブルクリックで実行するためのランチャー |
| `update_switchbot_status.ps1` | SwitchBot 温湿度計の値を Companion のカスタム変数に POST。タスクスケジューラから定期実行する |
| `run_hidden_switchbot.vbs` | 上記をコンソールウィンドウなしで起動するためのラッパー（パスは自動解決）。**タスクスケジューラにはこれを登録する** |

{: .warning }
> ⚠️ スクリプトを別のフォルダに移したら、**Companion のボタン・タスクスケジューラ・スタートアップのショートカット**が
> 絶対パスで参照していないか確認してください。いずれも移動に追従しません。

## 12.5 `echo-show/` — Echo Show 側に置くファイル

リポジトリ内の配置が、端末上の `/data/adb/` 以下の配置に対応します。配置方法は `echo-show/README.md` を参照。

| リポジトリ | 端末上のパス | 用途 |
|---|---|---|
| `post-fs-data.d/set_adb_props.sh` | `/data/adb/post-fs-data.d/` | ADB 関連プロパティを `resetprop` で設定（→ [4 章]({{ site.baseurl }}/04-adb/)） |
| `service.d/enable_adb.sh` | `/data/adb/service.d/` | USB ADB を維持し、Wi-Fi ADB（5555）を閉じる（→ [4.3]({{ site.baseurl }}/04-adb/#usb-only)） |
| `service.d/launch_fully.sh` | `/data/adb/service.d/` | 起動 25 秒後に Fully Kiosk を正しい URL で起動（→ [6 章]({{ site.baseurl }}/06-autostart/)）。`<PC_IP>` / `<EMULATOR_ID>` を書き換えて使う |
| — | `/data/misc/adb/adb_keys` | PC の ADB 公開鍵（`system:shell` / `640`） |

`.sh` はいずれも **LF** 改行・`chmod 755` が必要です（`.gitattributes` で LF に固定しています）。

## 12.6 `state/` — 実行時の状態ファイル（git 対象外）

スクリプトが自動で作ります。

| ファイル | 用途 |
|---|---|
| `discord_mute_state.txt` | `0` / `1`。Discord ミュートの想定状態。表示ずれの強制同期以外では手で編集しない |
| `light_state.txt` | `0` / `1`。照明の想定状態 |

## 12.7 `icons/` — アイコン

すべて **GDI+ プリミティブで自作**したもので、ダウンロード品ではありません。
Companion の Image Library にアップロードして使います（アップロード後は Companion 側に保存されるので、移動しても影響ありません）。

| ファイル | 用途 |
|---|---|
| `mic_icon_unmuted.png` / `mic_icon_muted.png` | Discord ボタンの 2 状態用マイクアイコン |
| `volume_up.ico.png` / `volume_down.ico.png` / `volume_mute.ico.png` | 音量ボタン用 |
| `open_mixer.ico.png` | ミキサーボタン用 |
| `screenshot_window.ico.png` / `screenshot_menu.ico.png` | スクショボタン用 |
| `light_on.ico.png` / `light_off.ico.png` | 照明ボタンの 2 状態用 |

## 12.8 現在未使用

| ファイル | 用途 |
|---|---|
| `webpage/clock.html` | 時計＋天気の全画面ページ。単体動作確認済みだが**保留中**（→ [11 章]({{ site.baseurl }}/11-limitations/#clock-page)） |
