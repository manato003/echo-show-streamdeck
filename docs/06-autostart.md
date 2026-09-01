---
title: 6. 起動時の自動起動
nav_order: 6
---

# 6. 起動時の自動起動

**目標**：AC アダプタを挿すだけで、ユーザー操作なしにボタン画面が全画面で出る状態。

## 6.1 ⚠️ Fire OS はサイドロードアプリの `BOOT_COMPLETED` を無視する

まずこれを知っておく必要があります。**Fully Kiosk の "Launch on Boot" 設定を ON にしても
この OS では起動しません。**

調査で分かったこと：

- Fully Kiosk の manifest は `RECEIVE_BOOT_COMPLETED` を正しく宣言し、権限も付与されており、
  `.receiver.BootReceiver` も正しく登録されている。
  にもかかわらず実機再起動後にプロセスが立ち上がらない
  （`/proc/uptime` で本当に再起動直後であること、`ps` に fully プロセスが無いことを確認済み）。
- `adb shell` から手動でブロードキャストを送ると拒否される：

  ```
  am broadcast -a android.intent.action.BOOT_COMPLETED
  # → SecurityException: Permission Denial
  ```

  素の AOSP より厳しい制限がかかっています。

## 6.2 解決策：Magisk の late_start サービススクリプト

**root で走るのでアプリレベルの制限を回避できます。**

`/data/adb/service.d/launch_fully.sh` を作成します。

```sh
#!/system/bin/sh
sleep 25
am start -a android.intent.action.VIEW \
  -d 'http://<PC_IP>:8000/emulator/<EMULATOR_ID>' \
  -n de.ozerov.fully/de.ozerov.fully.FullyActivity
```

```sh
chmod 755 /data/adb/service.d/launch_fully.sh
```

ポイント：

- **`sleep 25`** は Fire OS 自身のランチャー / ホーム画面の初期化を待つためです。
  短すぎるとホーム画面に上書きされます。実機に合わせて調整してください。
- **URL を Intent データで明示している**のは [5.3]({{ site.baseurl }}/05-fully-kiosk/#launch-with-url) の理由からです。

エンドツーエンドで動作確認済み：電源投入 → 約25秒後に正しい Companion ページが全画面表示されます。

{: .note }
> 🔶 Fully Kiosk アプリ内の "Launch on Boot" も念のため ON にしてありますが、
> 上記の `BOOT_COMPLETED` 制限がある以上、実際に機能しているかは不明です。
> 実働しているのは Magisk スクリプト側なので、
> **アプリ内設定は OFF にしても問題ない可能性が高い**です（未検証）。

## 6.3 PC 側からの強制リセット用バッチ {#restart-bat}

表示がおかしくなったときに、PC から Fully Kiosk を叩き直すスクリプトを用意してあります。

- `restart_echoshow_kiosk.ps1` — 本体（ADB で force-stop → 正しい URL で再起動）
- `restart_echoshow_kiosk.bat` — ダブルクリック用のランチャー

**設定は [`config.ps1`]({{ site.baseurl }}/07-companion/#config) から読むので、
スクリプト自体を編集する必要はありません。**
`$AdbPath` / `$EchoShowIp` / `$CompanionEmulatorId` が正しく入っていれば動きます。
