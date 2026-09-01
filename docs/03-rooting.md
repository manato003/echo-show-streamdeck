---
title: 3. Echo Show の root 化
nav_order: 3
---

# 3. Echo Show の root 化

{: .warning }
> この章は**やり直しの効かない操作**を含みます。[2.5 リスクの確認]({{ site.baseurl }}/02-prerequisites/#risks)
> を読んでから進めてください。

## 3.1 使うもの

- **[amonet-cronos](https://github.com/xyzz/amonet)** — MediaTek の "fastbrick" エクスプロイトを使い、
  ブートローダを迂回して TWRP を書き込むツールキット。
- **TWRP** — カスタムリカバリ。ここから Magisk を焼く。
- **Magisk 30.x** — root 管理。本プロジェクトでは
  **起動スクリプト実行基盤としても中核**を担います（→ [6 章]({{ site.baseurl }}/06-autostart/)）。

手順そのものは amonet-cronos の README が正です。ここでは
**README に書かれていない/実際に詰まった点**を補足します。

{: .note }
> 🔶 **バージョン表記に注意**：作業ログでは「v2.0.0」と記録していましたが、
> 実際に使ったディレクトリは `amonet-cronos-v1.1.4` でした。
> 再現時は配布物の実物のバージョンを確認してください。

## 3.2 ブートモードの入り方

**電源ボタンではなく、AC アダプタの抜き差しがトリガー**です。ここが最初の関門です。

| 目的 | 操作 |
|---|---|
| **TWRP** | 完全に電源が落ちた状態から、**音量アップを押しながら AC アダプタを挿す** |
| hacked fastboot | ミュート / 電源ボタンのみ押しながら AC を挿す |
| stock fastboot | 3 ボタン全部押しながら AC を挿す |

{: .warning }
> ⚠️ **ホーム画面が出ている状態で音量アップを押しても TWRP には入りません。**
> 必ず「完全に電源が落ちた状態から AC を挿す」こと。
> 電源が落ちているかどうかは画面が完全に消灯していることで判断します。

## 3.3 バックアップ（必須）

TWRP に入れたら、**何をするより先に**バックアップを取ります。

- TWRP の Backup から `data` / `system` / `boot` を選択して保存
- 保存先は SD カード（対応していれば）か、`adb pull` で PC に退避

とくに **root 化前の純正 boot イメージ**は、後述の OTA 事故からの復旧に直接使えます。
別途 `dd` でも吸い出しておくと安心です（→ [10 章]({{ site.baseurl }}/10-troubleshooting/#ota-root-loss)）。

```sh
# boot パーティションは mmcblk0p9、サイズはちょうど 16MB
dd if=/dev/block/mmcblk0p9 of=/sdcard/stock_boot.img bs=1048576 count=16
```

パーティション番号は環境で変わりうるので、必ず実機で確認してください。

```sh
ls -l /dev/block/platform/soc/by-name/boot
# → /dev/block/mmcblk0p9 へのシンボリックリンクであることを確認
```

## 3.4 Magisk の適用

TWRP から Magisk の zip を flash します。以降、Magisk が

- root 権限の付与
- **`/data/adb/post-fs-data.d/` と `/data/adb/service.d/` の起動スクリプト実行**

を担当します。後者が本プロジェクトの生命線です。

{: .highlight }
> 💡 **`/data/adb/` 配下は `/system` や `boot` とは別パーティションにあるため、
> OTA で `/system` と `boot` が丸ごと純正に戻されても生き残ります。**
> このため本手順書では、**設定は一切 `/system` に書かず、すべて Magisk の
> systemless な仕組み（`resetprop` + 起動スクリプト）で行います。**
> 詳しい理由は [10 章]({{ site.baseurl }}/10-troubleshooting/#ota-root-loss) を参照。

## 3.5 完了確認

`adb shell` から次が通れば OK です。

```sh
su -c id
# → uid=0(root) ... が返る
```

この時点ではまだ ADB は再起動のたびに切れます。恒久化は次章で行います。
