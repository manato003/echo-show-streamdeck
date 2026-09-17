# echo-show/

Echo Show（root 化済み）の `/data/adb/` に置く Magisk 起動スクリプトの実体です。
リポジトリ内の配置が、そのまま端末上の配置に対応します。

| リポジトリ | 端末上のパス | 役割 |
|---|---|---|
| `post-fs-data.d/set_adb_props.sh` | `/data/adb/post-fs-data.d/set_adb_props.sh` | 起動初期に ADB 関連プロパティを設定 |
| `service.d/enable_adb.sh` | `/data/adb/service.d/enable_adb.sh` | USB ADB を維持し、Wi-Fi ADB（5555）を閉じる |
| `service.d/launch_fully.sh` | `/data/adb/service.d/launch_fully.sh` | 起動 25 秒後に Fully Kiosk を Companion の URL で起動（**`<PC_IP>` / `<EMULATOR_ID>` を書き換えてから使う**） |

## 端末への配置

改行コードは **LF** のまま送ってください（`.gitattributes` で LF に固定しています）。

```bash
# Git Bash の場合は先に export MSYS_NO_PATHCONV=1
adb -s <ADB_SERIAL> push service.d/enable_adb.sh /data/local/tmp/
adb -s <ADB_SERIAL> shell 'su -c "cp /data/local/tmp/enable_adb.sh /data/adb/service.d/ && chmod 755 /data/adb/service.d/enable_adb.sh"'
```

`su` には Magisk の完全版アプリで shell への root 許可が必要です
（→ [docs/10-troubleshooting.md](../docs/10-troubleshooting.md) の「Magisk アプリが簡易版（stub）のままだと su が止まる」）。

詳しい理由と背景は [docs/04-adb.md](../docs/04-adb.md) と [docs/06-autostart.md](../docs/06-autostart.md) を参照してください。
