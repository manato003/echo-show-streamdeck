---
title: 9. 日常の使い方
nav_order: 9
---

# 9. 日常の使い方

## 9.1 起動

1. PC 側で **Bitfocus Companion** が起動していることを確認（タスクトレイの Companion Launcher）。
2. Echo Show の電源（AC アダプタ）を挿す。常時通電で放置でも可。
3. 起動から **約25秒後**、Magisk の起動スクリプトが自動で Fully Kiosk Browser を起動し、
   Companion のボタン画面が全画面で表示されます。

**ここまで完全自動。ユーザー操作は不要です。**

## 9.2 「正常な状態」とは

- Echo Show の画面いっぱいに Companion のボタングリッドが出ている。
- 画面の隅に半透明の透かし（"Please Get a License" など）が **出ていない**。
- ボタンを押すと PC 側で対応する動作が即座に起きる。
- 状態表示付きのボタン（Discord ミュート・照明）のアイコンが、状態に応じて切り替わる。

## 9.3 おかしいと思ったら最初に見る3点

| 症状 | 最初に疑うところ |
|---|---|
| **画面が真っ白 / エラーページ / 別のページ** | PC の Companion が起動しているか。していれば Echo Show 側を再起動（電源抜き差し）するのが一番早い |
| **ボタンは光るが PC が反応しない** | Companion の [Shell command support]({{ site.baseurl }}/07-companion/#shell-command-support) が無効に戻っていないか |
| **ADB で繋がらない・root が効かない** | OTA アップデートで root が飛んだ疑い（→ [10 章]({{ site.baseurl }}/10-troubleshooting/#ota-root-loss)） |

## 9.4 手動での復旧コマンド

表示ページが狂ったときに、**最も確実に正しいページへ戻す**手段です。PC の PowerShell から実行します。

```
adb -s <ECHO_IP>:5555 shell am start -a android.intent.action.VIEW -d 'http://<PC_IP>:8000/emulator/<EMULATOR_ID>' -n de.ozerov.fully/de.ozerov.fully.FullyActivity
```

未接続なら先に：

```
adb connect <ECHO_IP>:5555
```

強制的に再起動したい場合はリポジトリの `restart_echoshow_kiosk.bat` を使います
（→ [6.3]({{ site.baseurl }}/06-autostart/#restart-bat)）。

## 9.5 状態表示がずれたとき

Discord ミュートと照明のアイコンは**ローカルで状態を仮定して管理**しています。
他の経路で切り替えるとずれます。

| 対象 | 直し方 |
|---|---|
| Discord ミュート | もう一度ボタンを押すか、`discord_mute_state.txt` を手で `0` / `1` に書き換える |
| 照明 | もう一度ボタンを押すか、`light_state.txt` を書き換える |
