# lessons.md — companion-pc-tools 固有の教訓

## Fire OS の OTA は何度でも root を消す（2026-09-17、2回目）
> 昇格: 不要 — Echo Show / Fire OS 固有。手順書 docs/10-troubleshooting.md に記録済み

- 2026-09-15 21:30 JST 頃、`DeviceSoftwareOTA`（priv-app）が Fire OS 6.5.7.3 → 6.5.7.4 を
  自動適用。`/system` と boot（mmcblk0p9）が純正に戻り、Magisk が読み込まれなくなった。
  証拠: `/cache/recovery/block.map`・`intent`（9/15 12:28–12:31 UTC）、build.prop のバージョン、
  `magiskboot cpio ramdisk.cpio test` = 0。
- 表に出た症状は「表示が出ない」だけで、PC 側の `restart_echoshow_kiosk` は接続拒否（10061）になる。
  **症状の出方が前回と同じなら、まず OTA を疑う。** USB が WPD "Fire" になっていれば確定。
- `/data/adb`（Magisk 本体・post-fs-data.d・service.d）は無傷なので、boot を再パッチするだけで全部戻る。
- 1回目で「OTA 無効化は宿題」と書いたまま放置したので、2回目が起きた。**再発した時点で宿題ではなく根本原因**。
- 対処（2026-09-17）: `com.amazon.device.software.ota` と `.override` を `pm disable`。再起動後も無効・自動起動 OK を確認済み。

## root 化した端末で `adb shell su -c` を安易に打たない
> 昇格: 済 → lessons-global.md「環境」

- shell（uid 2000）に root 許可のポリシーが無いと、`su` は**端末の画面に Magisk の許可ダイアログを出して止まる**。
  キオスク端末ではこのダイアログが Fully Kiosk を覆い、「復旧したのに表示が出ない」状態を自分で作った。
- 状態確認はまず `getprop` / `ps` / `dumpsys` など root 不要の手段で行う。`su` が必要なら `timeout` を付け、
  ユーザーに画面で許可してもらう前提で打つ。

## boot を再パッチした後の Magisk アプリは stub。stub では su が永久に止まる
> 昇格: 済 → lessons-global.md「環境」

- `boot_patch.sh` で入る Magisk アプリは簡易版（stub）で、root 許可ダイアログを出せない。
  `su` は応答待ちのまま止まり、画面には「フルバージョンにアップグレード」の案内が Fully Kiosk の裏に隠れて出ていた。
  同じバージョンの完全版 APK を `adb install -r` して解決。
- 許可ダイアログは約 10 秒で自動拒否され、**拒否が保存される**。以降はダイアログなしで即拒否になる。
  ユーザーに操作を頼むときは「ダイアログがすぐ消える」ことと、前面のアプリを先に止めることを先に伝える。

## USB ADB が MTP に戻る本当の原因は adb_enabled。8月の「ro.debuggable が原因」は誤りだった
> 昇格: 不要 — Fire OS / Echo Show 固有。手順書 docs/04-adb.md を訂正済み

- `ro.debuggable=1` と `persist.sys.usb.config=adb` を設定していても、起動後に USB は MTP に戻っていた。
  実際は **Fire OS が起動のたびに `settings global adb_enabled` を 0 に戻し**、UsbDeviceManager が ADB を外していた。
  8月に手順書へ書いた「ro.debuggable 未設定が根本原因」は、Wi-Fi ADB が動いていたせいで検証されないまま残っていた。
- Wi-Fi ADB を開けていたのも自作スクリプトではなく、**純正 ramdisk の `init.cronos.rc`（`on boot` で tcp.port 5555）**だった。
  root で読めないファイルは、PC に退避した boot イメージを展開すれば読める。
- 教訓: 「動いている経路」があると、別経路の原因説明は検証されないまま残る。原因を書くときは、それを外すと再現するかまで確かめる。
