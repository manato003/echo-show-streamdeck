---
title: 2. 必要なもの・前提知識
nav_order: 2
---

# 2. 必要なもの・前提知識

## 2.1 対象デバイス

| 項目 | 値 |
|---|---|
| 機種 | Echo Show 5 **第2世代**（2021） |
| コードネーム | `cronos` / `AEOCN` |
| 検証時の OS | Fire OS 6.5.6.4（Android 7.1.2, SDK 25） |

{: .warning }
> **第1世代・第3世代では手順が異なります。**
> root 化に使う `amonet-cronos` は第2世代（`cronos`）専用のエクスプロイトです。
> 機種を取り違えると起動しなくなる可能性があります。購入・実施前に必ず世代を確認してください。

## 2.2 PC 側に必要なもの

| ソフト | 用途 | 備考 |
|---|---|---|
| Windows 10 / 11 | Companion とスクリプトの実行環境 | 本手順書は Windows 前提 |
| [Bitfocus Companion](https://bitfocus.io/companion) v5.x | ボタン UI とアクション実行 | 検証は v5.0.3 |
| ADB (`adb.exe`) | Echo Show の設定・復旧 | `amonet` 同梱のものでも [Platform Tools](https://developer.android.com/tools/releases/platform-tools) でも可 |
| Windows PowerShell 5.1 | ボタンから実行されるスクリプト | Windows 標準。追加インストール不要 |

Echo Show 側：

| ソフト | 用途 |
|---|---|
| [amonet-cronos](https://github.com/xyzz/amonet) | root 化エクスプロイト（TWRP 導入） |
| [Magisk](https://github.com/topjohnwu/Magisk) 30.x | root 管理・起動スクリプト実行 |
| [Fully Kiosk Browser](https://www.fully-kiosk.com/) | 全画面ブラウザ（無料版で足りる → [11 章]({{ site.baseurl }}/11-limitations/)） |

## 2.3 ネットワークの前提

- Echo Show と PC が **同一 LAN** にいること。
- PC 側で **TCP 8000（Companion）** が LAN からアクセスできること。
  Windows ファイアウォールで許可が必要な場合があります。

{: .highlight }
> 💡 **ルーターで DHCP 予約（固定 IP 割り当て）を設定しておくことを強く推奨します。**
> PC の IP は Fully Kiosk の Start URL に直接埋め込まれるため、
> IP が変わると Echo Show が何も表示しなくなります。
> Echo Show 側の IP も、ADB で繋ぐたびに探す羽目になるので固定推奨です。

## 2.4 前提知識

以下が分かっていれば詰まりません。

- `adb shell` でコマンドを打てる
- Android のパーティション / `dd` の意味が分かる（**分からないなら 3 章は実施しないでください**）
- PowerShell スクリプトを読める（改造する場合）

## 2.5 リスクの確認 {#risks}

{: .warning }
> - **メーカー保証は失われます。** root 化は Amazon の想定しない改造です。
> - **文鎮化（起動不能）のリスクがあります。** 特に `dd` でのパーティション書き戻しは、
>   サイズを間違えると復旧不能になります（→ [10 章]({{ site.baseurl }}/10-troubleshooting/)）。
> - **OTA アップデートで root が飛びます。** 一度成功しても、後日突然壊れることがあります。
> - Alexa としての機能は root 化後も残りますが、本手順では Fully Kiosk が常時前面に出るため
>   実質的に「Alexa をやめて専用パネルにする」改造です。

**作業前に必ずバックアップを取ってください。** TWRP から `data` / `system` / `boot` の
バックアップを取得できます（root 化前の純正 boot イメージは特に重要です）。

## 2.6 所要時間の目安

| フェーズ | 目安 |
|---|---|
| root 化（3 章） | 1〜2 時間 |
| ADB 常時有効化（4 章） | 30 分 |
| Fully Kiosk + 自動起動（5〜6 章） | 30 分 |
| Companion とボタン作成（7〜8 章） | 1 時間〜（作るボタン数次第） |
