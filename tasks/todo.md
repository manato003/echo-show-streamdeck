# todo.md

## 2026-09-17 ディレクトリ整理 + Wi-Fi ADB フォールバック記載

- [x] Wi-Fi ADB フォールバック（`adb tcpip 5555` → 接続 → `adb usb` で戻す）を実機で検証
- [x] 構成変更: scripts/{buttons,lib,maintenance}/, icons/, state/, echo-show/, private/
- [x] 設定の読み込みを scripts/lib/Config.ps1 に集約（リポジトリルートの config.ps1 を解決）
- [x] .gitattributes（*.sh は LF、*.bat は CRLF）
- [x] 外部参照の移行
  - [x] タスクスケジューラ「SwitchBot Status Update」
  - [x] スタートアップのショートカット
  - [x] Companion のボタン 10 個（db.sqlite をバックアップ → Companion 停止 → 置換 → 整合性確認 → 再起動）
- [x] 検証: 全 .ps1 構文、ボタン押下（API）、スケジュールタスク実行、復旧スクリプト
- [x] 手順書・README を新パスと Wi-Fi フォールバックに更新
- [x] 教訓の未判定 0 件を確認 → コミット → push

### レビュー（2026-09-17）

- 外部参照 12 か所（Companion ボタン 10・タスクスケジューラ・スタートアップ）を移行。Companion は DB をコピーで予行演習 → 本番前に `backups/pre-path-migration-20260917` へ退避。
- 検証: ボタン 2/0/1 を API で押してスクショ生成を確認、タスク実行で温湿度変数の更新を確認、復旧スクリプトを USB / Wi-Fi 両方で実行、`adb tcpip` → `adb usb` で Wi-Fi の開閉を確認。
- 想定外: Companion 再起動でカスタム変数が初期値に戻った（温湿度表示が空）。スケジュールタスクと状態ファイルから再投入して解消。
- 想定外: ツールから `Start-Process` した Companion が起動しなかった。`explorer.exe` 経由で起動。
