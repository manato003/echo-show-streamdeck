---
title: 10. トラブルシューティング
nav_order: 10
---

# 10. トラブルシューティング

**このページがこの手順書で最も価値のある部分です。**
セットアップ中に実際に踏んだ地雷と、その根本原因・回避策の記録です。

---

## 最重要：OTA アップデートで root が消える {#ota-root-loss}

> Fire OS が 6.5.6.4 → 6.5.7.3 に自動更新された際、`/system` と boot パーティション
> （`/dev/block/mmcblk0p9`）が **純正の未パッチイメージで丸ごと置き換えられました。**
> これにより Magisk の boot フックと、`/system/build.prop` への直接編集
> （`persist.service.adb.enable` や `ro.debuggable` など）が全て消えました。
> ただし **`/data/adb/` 配下の Magisk 本体ファイルは別パーティションなので無傷**でした。
>
> **2026-09-15 に 6.5.7.3 → 6.5.7.4 で同じ事故が再発しました。** OTA を止めていなかったためです。
> 再発防止として、この後の [OTA 自動更新を止める](#disable-ota) を必ず実施してください。

### 症状の連鎖（この順で気付く）

1. USB ADB が繋がらない。PC 上では ADB デバイスではなく **MTP / Fire の "WPD" デバイス**として認識される
   （Wi-Fi ADB を使っている場合は、5555 番が接続拒否 10061 になる）
2. 起動しても Fully Kiosk が自動で立ち上がらない
3. 現行 boot パーティションに対して `magiskboot cpio ramdisk.cpio test` が
   **`0`（＝純正・未パッチ）** を返す（Magisk パッチ済みなら `1`）

### OTA だったことを確かめる

TWRP に入り（→ [3.2]({{ site.baseurl }}/03-rooting/)）、USB の ADB から次を確認します。

```sh
# /system のバージョンが上がっているか
mkdir -p /mnt/sysro && mount -o ro -t ext4 /dev/block/platform/soc/by-name/system /mnt/sysro
grep ro.build.version.name /mnt/sysro/build.prop

# OTA 適用の痕跡（日時が分かる）
ls -l /cache/recovery/        # block.map / intent / last_blocklist

# /data/adb は無傷か
ls -l /data/adb/post-fs-data.d /data/adb/service.d
```

### 復旧手順

作業はすべて TWRP の ADB シェル（root）で行います。

```sh
# 1. 現行（純正）boot を吸い出す。パーティションはちょうど 16MB
dd if=/dev/block/mmcblk0p9 of=/sdcard/stock_boot.img bs=1048576 count=16
```

パーティションの実体は `/dev/block/platform/soc/by-name/boot` のシンボリックリンク先で確認できます。
吸い出したイメージは PC 側にもバックアップしておいてください。

```sh
# 2. Magisk 自身の boot_patch.sh で再パッチ
#    元のディレクトリを汚さないよう、作業用にコピーしてから実行する
W=/data/local/tmp/recover; mkdir -p $W
cp -a /data/adb/magisk $W/magisk && cd $W/magisk
cp /sdcard/stock_boot.img to_patch.img
sh ./boot_patch.sh $W/magisk/to_patch.img
# → new-boot.img が生成される

# パッチが入ったか確認（1 = Magisk パッチ済み）
./magiskboot unpack new-boot.img && ./magiskboot cpio ramdisk.cpio test; echo $?
```

```sh
# 3. サイズがパーティションサイズと一致することを必ず確認してから書き戻す
#    （TWRP の busybox は stat -c が使えないので wc -c を使う）
[ "$(wc -c < new-boot.img)" -eq "$(blockdev --getsize64 /dev/block/mmcblk0p9)" ] \
  && dd if=new-boot.img of=/dev/block/mmcblk0p9 bs=1048576

# 4. 読み戻して一致を確認してから再起動
dd if=/dev/block/mmcblk0p9 of=readback.img bs=1048576 count=16
sha1sum new-boot.img readback.img
```

吸い出した純正 boot は PC にも `adb pull` で保存しておきます。
Git Bash から `adb pull /data/...` を実行するとパスが書き換えられるので、
先に `export MSYS_NO_PATHCONV=1` を実行してください。

{: .warning }
> ⚠️ **書き戻す前に必ずバイト単位でサイズを確認してください。**
> パーティションサイズを超えるイメージを書き込むと文鎮化します。

### 教訓 / 予防

- ⚠️ **`/system` への直接編集は OTA で必ず消えます。**
  OTA を跨いで生き残らせたい設定は、必ず Magisk の systemless な仕組み
  （`/data/adb/post-fs-data.d/` + `resetprop`）で行ってください（→ [4 章]({{ site.baseurl }}/04-adb/)）。
- ⚠️ **しばらく普通に使っていて突然 ADB / root が死んだら、まず OTA を疑ってください。**
- ⚠️ **OTA は止めない限り必ず再発します。** 実際に 2 回起きました。下の手順で止めてください。

### OTA 自動更新を止める {#disable-ota}

root が戻った状態（通常起動）で、Fire OS の更新アプリ 2 つを無効化します。

| パッケージ | 役割 | 対応 |
|---|---|---|
| `com.amazon.device.software.ota` | Fire OS 本体の更新 | **無効化する** |
| `com.amazon.device.software.ota.override` | アイドル時に更新を強制適用 | **無効化する** |
| `com.amazon.dcp.contracts.library` | Amazon アプリ共通のライブラリ | 触らない（Alexa 等が壊れる恐れ） |
| `com.amazon.device.smarthome.ota` | スマートホーム周辺機器のファームウェア | 触らない（Fire OS とは無関係） |

PowerShell 5.1 はクォートを崩すので、**Git Bash** から実行します。

```bash
adb -s <ADB_SERIAL> shell 'su -c "pm disable com.amazon.device.software.ota; pm disable com.amazon.device.software.ota.override"'
# Package ... new state: disabled が 2 行出れば成功
```

確認（root 不要。再起動後も無効のままであることを確かめる）：

```bash
adb -s <ADB_SERIAL> shell pm list packages -d | grep ota
```

元に戻すときは `disable` を `enable` にして実行します。

{: .warning }
> ⚠️ **`su` が応答しないまま止まる場合**は、下の
> [Magisk アプリが簡易版（stub）のままだと su が止まる](#magisk-stub) を確認してください。

---

## Magisk アプリが簡易版（stub）のままだと su が止まる {#magisk-stub}

**症状**：`adb shell su -c ...` を実行しても何も返ってこない。Echo Show の画面にも許可ダイアログが出ない。

**原因**：boot を再パッチすると、Magisk アプリは**簡易版（stub）**として入ります。
stub は root の許可ダイアログを表示できず、「フルバージョンにアップグレードしますか？」という
案内だけを出します。Fully Kiosk が前面にいると、この案内も**裏に隠れて見えません**。

**対処**：Magisk デーモンと**同じバージョン**の完全版 APK を入れます（root 不要）。

```bash
adb -s <ADB_SERIAL> install -r Magisk-v30.7.apk
```

その後、許可ダイアログが Fully Kiosk の裏に隠れないよう、Fully Kiosk を一時的に止めてから `su` を実行します。

```bash
adb -s <ADB_SERIAL> shell am force-stop de.ozerov.fully
```

{: .warning }
> ⚠️ **許可ダイアログは約 10 秒で自動的に拒否され、その拒否が保存されます。**
> 以降はダイアログが出ずに即座に拒否されます。
> その場合は Magisk アプリを開き（`adb shell monkey -p com.topjohnwu.magisk -c android.intent.category.LAUNCHER 1`）、
> **スーパーユーザー → Shell のスイッチを ON** にします。
>
> - アプリ起動時の「追加のセットアップが必要です」は **キャンセル**（OK を押すと boot の書き換えを始めようとする）
> - ADB は認証なし（`ro.adb.secure=0`）なので、**作業が終わったら Shell のスイッチは OFF に戻す**

作業が終わったら `scripts/maintenance/restart_echoshow_kiosk.ps1` で Fully Kiosk を戻します。

---

## Fire OS の「ユーザー補助」にサードパーティアプリが出てこない

Fire OS の Accessibility 設定画面には「ダウンロード済みのサービス」セクションが
**そもそも存在しません。** Fire OS の UI 上の制限であってバグではありません。

Fully Kiosk の Accessibility Service（Kiosk Mode に必要）は UI から有効化できないので、
ADB で直接叩きます。

```
adb shell settings put secure enabled_accessibility_services de.ozerov.fully/de.ozerov.fully.MyAccessibilityService
adb shell settings put secure accessibility_enabled 1
```

※ Kiosk Mode を OFF で運用する場合はこの設定は不要です（→ [11 章]({{ site.baseurl }}/11-limitations/)）。

---

## Fully Kiosk を URI なしで起動すると設定 URL を「見失う」

詳細は [5.3]({{ site.baseurl }}/05-fully-kiosk/#launch-with-url) を参照。

**要点**：`am start` は必ず `-a android.intent.action.VIEW -d '<URL>'` を付ける。
付けないと Quick Start 画面が出て、プレースホルダ URL
（`https://www.fully-kiosk.com/welcome/`）が読み込まれ、保存されてしまうことがあります。

---

## Companion の Shell command support が無効に戻る

**症状**：ボタンは光るのに PC が全く反応しない。エラーも出ない。

**対処**：`Companion Launcher → Advanced Settings → Dangerous Features →
"Shell command support"` にチェック（Web 管理 UI 側にはありません）。

Companion を再インストールしたり設定がリセットされると戻ります。
→ [7.2]({{ site.baseurl }}/07-companion/#shell-command-support)

---

## Discord のミュートボタンが効かない

原因は主に 2 つです。

### 1. Discord 側のキーバインドが変わった / 再インストールした

Discord の設定は自動化できません。手動で
**ユーザー設定 → 音声・ビデオ → キーバインド → 「ミュート切り替え」を `右Ctrl + ¥` に設定**
する必要があります。ここがずれると無言で効かなくなります。

### 2. Discord がフォーカスされていない状態での合成キー入力を無視する

Discord は合成（injected）キーイベントを、非フォーカス時には意図的に無視します
（低レベルフックで `LLKHF_INJECTED` 相当を見ていると思われる）。

→ `discord_mute_toggle.ps1` は、いったん Discord ウィンドウを前面に出してからキーを送り、
元のウィンドウにフォーカスを戻す実装になっています（→ [8.5]({{ site.baseurl }}/08-buttons/#discord-mute)）。

**それでもダメなときの Plan B**：`mic_mute_toggle.ps1`（OS レベルでマイク自体をミュート）に差し替える。
100% 確実ですが Discord の UI 上はミュート表示になりません。

---

## 右側モディファイア／ナビゲーションキーには EXTENDEDKEY フラグが必須 {#extended-key}

**Discord ミュートが動かなかった真の根本原因はこれでした。汎用的に効く教訓です。**

`keybd_event` で **右側の**モディファイアキーを送るには
`KEYEVENTF_EXTENDEDKEY (0x0001)` を付けないと、右キーとして認識されません。

対象となる VK コード：

| VK | キー |
|---|---|
| `163` | 右 Ctrl |
| `165` | 右 Alt |
| `91` / `92` | Win キー |
| `45` / `46` | Insert / Delete |
| `33`〜`40` | PageUp / PageDown / End / Home / 矢印キー |
| `144` / `145` | NumLock / ScrollLock |

※ `¥`（OEM_5, VK `220`）自体は拡張キーではありません。拡張フラグが必要なのは右Ctrl のほうです。

`SendKeyCombo.ps1` は上記 VK コードに対して自動でこのフラグを付けるよう修正済みなので、
**このスクリプト経由で書くボタンはこの問題を意識する必要はありません。**

---

## Discord ミュート / 照明のアイコン表示がずれる

`discord_mute_toggle.ps1` は `state/discord_mute_state.txt` に、
`light_toggle.ps1` は `state/light_state.txt` に `0`/`1` を書いて
**ローカルで状態を仮定して管理**しています
（Discord にも赤外線リモコンにも、現在の状態を問い合わせる手段が存在しないため）。

{: .warning }
> ⚠️ ボタン以外の経路（Discord のマイクアイコンを直接クリック、照明のリモコンを使う等）で
> 切り替えると、表示と実態がずれます。
> もう一度ボタンを押してずれを解消するか、状態ファイルを手で `0` / `1` に書き換えてください。

---

## PowerShell の日本語コメント × BOM なし

日本語コメントを含む `.ps1` を **BOM なし UTF-8** で保存すると、Windows PowerShell 5.1 で
`-File` 実行した際にシステムコードページとして誤解釈され、後続行が壊れて結合し、
`Add-Type -AssemblyName System.Windows.Forms` が無言で失敗する等の
不可解な「型が見つかりません」エラーになります。

**本プロジェクトの方針：`.ps1` のコメントはすべて英語にする。** BOM と毎回戦うより確実です。

---

## Fully Kiosk / Fire OS の細かい UI 罠

- Fully Kiosk の設定内検索ボックスは、検索するたびに **前回の文字列がクリアされず連結されます。**
  毎回 X（クリア）ボタンを押してから入力してください。
- 画面左端付近（960px 幅で概ね x < 100px）のタップは、普通のタップに見えても
  Fully Kiosk の「左端スワイプ＝設定メニュー」ジェスチャーとして誤認識されることがあります。
  ADB でタップを送るときは UI 要素の中央寄りを狙ってください。
- Kiosk Mode を有効にした場合、設定画面へは「戻るボタン長押し」または左端スワイプ＋
  **Kiosk PIN** が必要です。**既定値は `1234` なので、有効化するなら必ず変更してください。**

---

## Companion API がループバックで応答しない

カスタム変数を更新する HTTP POST 先は、**`127.0.0.1` ではなく LAN の IP（`<PC_IP>`）**を使ってください。
Companion の Web サーバーは LAN インターフェイスにのみバインドしており、ループバックでは応答しません。
