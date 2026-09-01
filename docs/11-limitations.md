---
title: 11. 既知の制限・見送った項目
nav_order: 11
---

# 11. 既知の制限・見送った項目

一度検討して**意図的に見送った**項目です。事情が変わらない限り再検討不要、という判断の記録です。

---

## Fully Kiosk PLUS ライセンス — 購入しない（決定済み） {#plus-license}

- 価格：**1,652 円（＋税 165 円）の買い切り**。デバイス ID に紐づきます。
- PLUS で解放される機能は 2 つ。未購入でも機能自体は動きますが、
  画面に半透明の透かし（"PLUS Features Activated" / "Please Get a License"）が
  **常時オーバーレイ表示されます。**

| 機能 | 内容 |
|---|---|
| **Kiosk Mode** | デバイスのロックダウン（ホームボタン・ステータスバー・通知の無効化）。Accessibility Service と各種権限（他のアプリの上に表示、使用状況へのアクセス、電話状態へのアクセス）が必要。Kiosk PIN の既定は `1234` |
| **Remote Administration** | ポート 2323 の HTTP REST API（`http://<ECHO_IP>:2323/?cmd=...&password=...`） |

{: .warning }
> ⚠️ **判明した仕様**：Remote Admin のサブ機能だけ
> （Enable Screenshot on Remote Admin / Enable Camshot on Remote Admin）を無効にしても
> 透かしは消えません。
> **"Enable Remote Administration" 自体を丸ごと無効化して初めて消えます。**

### 決定

この用途に対して価格が見合わないと判断し、**Kiosk Mode と Remote Administration の
両方を完全に無効化**しました。
トレードオフ（誤操作による離脱を防ぐロックダウンがない／リモート API が使えない）を受け入れ、
**透かしのないクリーンな表示**を取っています。

{: .highlight }
> root があるのでバイナリパッチでライセンスチェックを回避することは技術的には可能ですが、
> **開発者の有料機能モデルを迂回することになるため明示的に却下しています。**
> root があっても再検討しない方針です。
> Kiosk Mode / Remote Admin が必要なら、素直にライセンスを購入してください。

---

## 時計・天気ページ — 保留（機能自体は完成済み） {#clock-page}

**構想**：全画面の時計＋天気ページ（`webpage/clock.html`）をローカルの
`python -m http.server 8080` で配信し、Companion のボタン、および時計ページ自体のタップで、
Fully Kiosk の Remote Admin `loadUrl` コマンドを呼んで
**ボタングリッド ⇄ 時計ページを切り替える。**

- 天気は **[Open-Meteo](https://open-meteo.com/) の無料 API**（API キー不要）。
  緯度・経度を書き換えれば任意の地点に対応できます。
- `clock.html` は**作成済み・単体動作確認済み**です。

**保留理由**：切り替えの仕組みが Fully Kiosk の Remote Administration に全面依存しており、
それが PLUS ライセンス対象で無効化されたためです。

{: .note }
> `clock.html` はリポジトリに残してあります。
> **「死んだ機能」ではなく「ライセンス待ちの完成済み機能」**として扱ってください。
> PLUS ライセンスを買えばすぐ復活できます。

---

## 未対応・宿題リスト

| 項目 | 状況 |
|---|---|
| Fire OS の OTA 自動更新の無効化 | **未対応。root が再び飛ぶリスクあり。要検討** |
| Echo Show / PC の DHCP 予約 | **未対応。推奨。IP が変わると Start URL が壊れる** |
| Kiosk PIN（`1234`）の変更 | 未変更。Kiosk Mode が OFF の間は実害なし |
| ボタンの表示サイズ拡大 | 未実施。Fully Kiosk の Page Zoom で対応可能 |
| Fully Kiosk の "Launch on Boot" が実効しているか | **要確認。Magisk スクリプト単独で足りている可能性が高い** |
| Start URL が着地するページ番号 | **要確認（テスト中は `2/x/x` 表示だった）** |
| amonet-cronos のバージョン表記の食い違い | **要確認（ログ上 v2.0.0 / ディレクトリ名 v1.1.4）** |
