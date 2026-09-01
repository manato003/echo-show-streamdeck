---
title: 12. スクリプトリファレンス
nav_order: 12
---

# 12. スクリプトリファレンス

リポジトリ同梱の全ファイルの一覧です。

## 12.1 共通部品（ボタンに直接割り当てない）

| ファイル | 用途 |
|---|---|
| `config.ps1` | 環境依存の設定（Companion の IP / エミュレーター ID / ADB パス / SwitchBot デバイス ID）と共通関数 `Set-CompanionVariable`。**全スクリプトがここから読む**（→ [7.6]({{ site.baseurl }}/07-companion/#config)） |
| `SendKeyCombo.ps1` | グローバルなキーコンボ送信（`keybd_event` ベース）。右側モディファイア／ナビゲーションキーに `KEYEVENTF_EXTENDEDKEY` を自動付与する（→ [10 章]({{ site.baseurl }}/10-troubleshooting/#extended-key)） |
| `AudioMuteHelper.ps1` | Core Audio API の COM interop ヘルパー。`[AudioMute]` クラスに `IsMuted` / `SetMuted` の静的メソッド。`mic_mute_toggle.ps1` からドットソースされる |
| `SwitchBotApi.ps1` | SwitchBot OpenAPI v1.1 のヘルパー（HMAC-SHA256 署名）。`Get-SwitchBotAuthHeaders` / `Get-SwitchBotDevices` / `Get-SwitchBotStatus` |
| `SwitchBotCommand.ps1` | SwitchBot デバイス／赤外線リモコンにコマンドを送る汎用ラッパー |

## 12.2 ボタンに割り当てるスクリプト

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
| `light_toggle.ps1` | SwitchBot 赤外線リモコン経由で照明を ON/OFF。状態を `light_state.txt` とカスタム変数に反映 |
| `open_twitch.ps1` | **サンプル**：指定 URL をブラウザで開く |
| `launch_wuthering_waves.ps1` | **サンプル**：指定した実行ファイルを起動する |

{: .highlight }
> 💡 `open_twitch.ps1` と `launch_wuthering_waves.ps1` は**そのまま使うものではなく雛形**です。
> URL / パスを自分のものに書き換えてください。

## 12.3 定期実行・保守

| ファイル | 用途 |
|---|---|
| `update_switchbot_status.ps1` | SwitchBot 温湿度計の値を Companion のカスタム変数に POST。タスクスケジューラから定期実行する |
| `run_hidden_switchbot.vbs` | 上記をコンソールウィンドウなしで起動するためのラッパー（パスは自動解決） |
| `restart_echoshow_kiosk.ps1` | PC から ADB 経由で Fully Kiosk を強制再起動。設定は `config.ps1` から読む |
| `restart_echoshow_kiosk.bat` | 上記をダブルクリックで実行するためのランチャー |

## 12.4 設定・状態ファイル

| ファイル | 用途 |
|---|---|
| `config.example.ps1` | 環境設定のテンプレート。`config.ps1` にコピーして使う |
| `switchbot_secrets.example.ps1` | SwitchBot 認証情報のテンプレート。コピーして使う |
| `switchbot_secrets.ps1` | **実際の認証情報。`.gitignore` 済み。絶対にコミットしないこと** |
| `discord_mute_state.txt` | `0` / `1`。Discord ミュートの想定状態。表示ずれの強制同期以外では手で編集しない |
| `light_state.txt` | `0` / `1`。照明の想定状態 |

## 12.5 アイコン

すべて **GDI+ プリミティブで自作**したもので、ダウンロード品ではありません。
Companion の Image Library にアップロードして使います。

| ファイル | 用途 |
|---|---|
| `mic_icon_unmuted.png` / `mic_icon_muted.png` | Discord ボタンの 2 状態用マイクアイコン |
| `volume_up.ico.png` / `volume_down.ico.png` / `volume_mute.ico.png` | 音量ボタン用 |
| `open_mixer.ico.png` | ミキサーボタン用 |
| `screenshot_window.ico.png` / `screenshot_menu.ico.png` | スクショボタン用 |
| `light_on.ico.png` / `light_off.ico.png` | 照明ボタンの 2 状態用 |

## 12.6 現在未使用

| ファイル | 用途 |
|---|---|
| `webpage/clock.html` | 時計＋天気の全画面ページ。単体動作確認済みだが**保留中**（→ [11 章]({{ site.baseurl }}/11-limitations/#clock-page)） |

## 12.7 Echo Show 側に置くファイル

| パス | 用途 |
|---|---|
| `/data/adb/post-fs-data.d/set_adb_props.sh` | ADB 関連プロパティを `resetprop` で設定（→ [4 章]({{ site.baseurl }}/04-adb/)） |
| `/data/adb/service.d/enable_adb.sh` | Wi-Fi ADB（TCP 5555）を維持するループ |
| `/data/adb/service.d/launch_fully.sh` | 起動 25 秒後に Fully Kiosk を正しい URL で起動（→ [6 章]({{ site.baseurl }}/06-autostart/)） |
| `/data/misc/adb/adb_keys` | PC の ADB 公開鍵（`system:shell` / `640`） |

いずれも `chmod 755` が必要です（`adb_keys` のみ `640`）。
