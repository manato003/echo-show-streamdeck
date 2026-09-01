---
title: 4. ADB の常時有効化
nav_order: 4
---

# 4. ADB の常時有効化

Fire OS の Echo Show には**開発者オプションの UI がありません**。
「USB デバッグを ON にする」という通常の手段が使えないため、
root 権限でプロパティを直接設定します。

日常運用で ADB は使いませんが、**表示が壊れたときの唯一の復旧手段**なので必ず通しておきます。

## 4.1 必要なプロパティ

| プロパティ | 値 | 役割 |
|---|---|---|
| `ro.debuggable` | `1` | これが無いと後述の上書き問題が起きる |
| `ro.adb.secure` | `0` | 認証プロンプトを不要にする |
| `persist.service.adb.enable` | `1` | adbd を有効化 |
| `persist.sys.usb.config` | `adb` | USB を MTP ではなく ADB として列挙 |

{: .warning }
> ⚠️ **`persist.sys.usb.config` が毎回 `none` に戻る問題**
>
> USB が ADB ではなく MTP（PC 上で Fire の "WPD" デバイス）として認識される、という症状が出ます。
> 根本原因は **`ro.debuggable` が未設定だと Fire OS 自身の USB マネージャが
> 起動のたびに persist 値を MTP/none の既定値へ上書きしていた**ことでした。
>
> `/data/property/persist.sys.usb.config` を直接書き換える対処は一時的には効きますが、
> **OTA で消えます。** 下の systemless な方法を使ってください。

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

## 4.3 Wi-Fi ADB（TCP 5555）

`/data/adb/service.d/enable_adb.sh` を作成します。

```sh
#!/system/bin/sh
while true; do
    resetprop service.adb.tcp.port 5555
    resetprop persist.service.adb.enable 1
    start adbd
    sleep 10
done
```

```sh
chmod 755 /data/adb/service.d/enable_adb.sh
```

10 秒ごとのループにしているのは、Fire OS が adbd を落としても自動で復活させるためです。

PC からの接続：

```
adb connect <ECHO_IP>:5555
```

## 4.4 認証プロンプト対策（公開鍵の直接配置）

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

## 4.5 確認

再起動後、PC から次が通れば完了です。

```
adb connect <ECHO_IP>:5555
adb -s <ECHO_IP>:5555 shell getprop ro.debuggable
# → 1
```

{: .note }
> 🔶 ここで `adb connect` が通らなくなった場合、**まず OTA を疑ってください。**
> 詳細は [10 章]({{ site.baseurl }}/10-troubleshooting/#ota-root-loss)。
