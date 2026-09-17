---
title: 4. ADB の常時有効化
nav_order: 4
---

# 4. ADB の常時有効化

Fire OS の Echo Show には**開発者オプションの UI がありません**。
「USB デバッグを ON にする」という通常の手段が使えないため、
root 権限でプロパティを直接設定します。

日常運用で ADB は使いませんが、**表示が壊れたときの唯一の復旧手段**なので必ず通しておきます。

本手順書では **USB ADB のみ**を使い、Wi-Fi ADB は閉じます。
`ro.adb.secure=0`（認証なし）で運用するため、Wi-Fi で開けると同じ LAN の誰でも接続できてしまうからです。
**Echo Show と PC は USB ケーブルでつなぎっぱなしにします。**

## 4.1 必要なプロパティ

| プロパティ | 値 | 役割 |
|---|---|---|
| `ro.debuggable` | `1` | これが無いと後述の上書き問題が起きる |
| `ro.adb.secure` | `0` | 認証プロンプトを不要にする |
| `persist.service.adb.enable` | `1` | adbd を有効化 |
| `persist.sys.usb.config` | `adb` | USB を MTP ではなく ADB として列挙 |

{: .warning }
> ⚠️ **プロパティだけでは USB ADB は維持できません**
>
> 起動の後半で USB が MTP（PC 上で Fire の "WPD" デバイス）に戻り、`persist.sys.usb.config` も `none` に書き換わります。
> 根本原因は、**Fire OS が起動のたびにシステム設定 `settings global adb_enabled` を `0` に戻し**、
> Android の UsbDeviceManager がそれを見て USB から ADB を外していることです
> （`ro.debuggable=1` にしても防げないことを確認済み）。
> 対処は [4.3](#usb-only) の起動スクリプトで行います。

## 4.2 USB ADB — `post-fs-data.d` で固定する

`/data/adb/post-fs-data.d/set_adb_props.sh` を作成します。

```sh
#!/system/bin/sh
resetprop -n ro.debuggable 1
resetprop -n ro.adb.secure 0
resetprop persist.service.adb.enable 1
resetprop persist.service.debuggable 1
resetprop persist.sys.usb.config adb
```

```sh
chmod 755 /data/adb/post-fs-data.d/set_adb_props.sh
```

`resetprop -n` は read-only プロパティ（`ro.*`）を上書きするためのフラグです。
`post-fs-data` は Fire OS の USB マネージャより**早い**タイミングで走るため、
既定値による上書きを先回りできます。

{: .highlight }
> 💡 これが **systemless（`/system` を触らない）** 方式です。
> Magisk が現行の boot イメージにパッチされている限り、OTA を跨いでも生き残ります。

## 4.3 USB ADB を維持し、Wi-Fi ADB を閉じる {#usb-only}

起動後に Fire OS が行う 2 つの動作を打ち消します。

| Fire OS の動作 | 結果 | 対処 |
|---|---|---|
| 起動のたびに `settings global adb_enabled` を `0` に戻す | USB が MTP に切り替わり、USB ADB が切れる | `1` に戻し続ける |
| 純正の `init.cronos.rc` が `on boot` で `setprop service.adb.tcp.port 5555` を実行する | adbd が動くと **Wi-Fi でも待ち受ける** | 起動完了後に `0` にして adbd を再起動 |

`/data/adb/service.d/enable_adb.sh` を作成します。

```sh
#!/system/bin/sh
# USB ADB only (Wi-Fi ADB intentionally disabled).
until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 2; done
resetprop service.adb.tcp.port 0
stop adbd
start adbd
while true; do
    if [ "$(settings get global adb_enabled)" != "1" ]; then
        settings put global adb_enabled 1
    fi
    sleep 10
done
```

```sh
chmod 755 /data/adb/service.d/enable_adb.sh
```

{: .note }
> 起動から約 30 秒の間に、Fire OS が USB を MTP に戻す → スクリプトが ADB に戻す、という切り替わりが 1 回起きます。
> その間 `adb devices` から一瞬消えるのは正常です。

**改行コードは LF** で作成してください（CRLF だと Android の sh で動きません）。
Windows で作った場合は `adb push` で `/data/local/tmp/` に送り、root で `service.d` にコピーします。

PC からの接続はケーブルだけで、`adb connect` は不要です。シリアル番号は次で確認します。

```
adb devices
# G0XXXXXXXXXXXXXX   device   ← これが <ADB_SERIAL>
```

このスクリプトの実体はリポジトリの `echo-show/service.d/enable_adb.sh` にあります。

USB が使えないときは、Wi-Fi ADB を一時的に開けられます（→ [4.4 フォールバック](#wifi-fallback)）。

## 4.4 フォールバック：Wi-Fi ADB を使う {#wifi-fallback}

USB が使えないとき（ケーブルの断線、PC から離れた場所での作業など）の代替手段です。
**Wi-Fi ADB は認証なしで LAN に公開される**ので、使い終わったら閉じてください。

### A. 一時的に開く（推奨・root 不要）

USB でつながっているうちに、Wi-Fi 接続を**追加で**開けます。USB と Wi-Fi は同時に使えます。

```bash
adb -s <ADB_SERIAL> tcpip 5555      # Echo Show 側で 5555 番を開く
adb connect <ECHO_IP>:5555
adb -s <ECHO_IP>:5555 shell getprop sys.usb.state   # Wi-Fi 経由で応答すれば OK
```

- **次に再起動するまで**有効です。再起動すると `enable_adb.sh` が自動で閉じます
- 起動スクリプトの監視ループは `adb_enabled` しか見ないので、途中で閉じられることはありません
- 使い終わったらすぐ閉じる場合：

```bash
adb -s <ECHO_IP>:5555 usb           # USB 専用に戻す（5555 番が閉じる）
```

{: .note }
> USB が**すでに**使えなくなっている場合、この方法は使えません。
> そのときは TWRP に入れば USB 経由で ADB が使えます（→ [3.2]({{ site.baseurl }}/03-rooting/)）。

### B. 常に開いておく（root が必要）

`/data/adb/service.d/enable_adb.sh` から次の 3 行を削除して再起動すると、
純正の `init.cronos.rc` の設定どおり、起動のたびに 5555 番で待ち受けます。

```sh
resetprop service.adb.tcp.port 0
stop adbd
start adbd
```

### PC 側スクリプトの接続先を切り替える

`config.ps1` の `$EchoShowAdbTarget` を書き換えるだけで、`restart_echoshow_kiosk.ps1` が Wi-Fi 経由で動きます
（`IP:ポート` の形なら、スクリプトが自動で `adb connect` します）。

```powershell
$EchoShowAdbTarget = "G0XXXXXXXXXXXXXX"      # 通常：USB（シリアル番号）
$EchoShowAdbTarget = "<ECHO_IP>:5555"        # フォールバック：Wi-Fi
```

Wi-Fi で使う場合は、Echo Show の IP が変わらないよう **DHCP 予約**をしておくと確実です（→ [2.3]({{ site.baseurl }}/02-prerequisites/)）。

## 4.5 認証プロンプト対策（公開鍵の直接配置）

通常の Android なら初回接続時に「このコンピュータを許可しますか」ダイアログが出ますが、
**Fire OS の Alexa 向け UI にはこのダイアログを表示する手段がありません。**
そこで PC の公開鍵を root 権限で直接書き込みます。

PC 側の鍵の場所：

```
%USERPROFILE%\.android\adbkey.pub
```

この内容を Echo Show の `/data/misc/adb/adb_keys` に追記し、所有者とパーミッションを合わせます。

```sh
# Echo Show 側（root）
cat /sdcard/adbkey.pub >> /data/misc/adb/adb_keys
chown system:shell /data/misc/adb/adb_keys
chmod 640 /data/misc/adb/adb_keys
```

## 4.6 確認

再起動して 1 分ほど待ち、PC から次を確認します。

```
adb -s <ADB_SERIAL> shell getprop sys.usb.state
# → adb

adb -s <ADB_SERIAL> shell getprop service.adb.tcp.port
# → 0（Wi-Fi ADB は閉じている）
```

{: .note }
> 🔶 USB が再び "Fire"（WPD）として認識され ADB が使えなくなった場合は、**まず OTA を疑ってください。**
> 詳細は [10 章]({{ site.baseurl }}/10-troubleshooting/#ota-root-loss)。
