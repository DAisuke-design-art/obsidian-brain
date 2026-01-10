# glog 実装計画書

## ゴール
Geminiとの対話をObsidianに記録し、GitHubへ安全に同期するための堅牢な `glog` コマンドを実装する。

## ユーザーレビュー必須事項
> [!IMPORTANT]
> **制約**: セキュリティ上の理由から、`~/.zshrc` を直接自動編集することは避けました。
> **解決策**: 実体となるスクリプトファイルを `/Users/daisukemiyauchi/Documents/Obsidian/Scripts/glog.sh` に作成しました。
> **アクション**: ユーザー自身の手で、このスクリプトをシェルに読み込ませるためのコマンドを1回だけ実行していただく必要があります。

## 変更内容

### コンポーネント: Obsidian Vault
#### [新規] [Scripts/glog.sh](file:///Users/daisukemiyauchi/Documents/Obsidian/Scripts/glog.sh)
- **関数**: `glog()`
- **ロジック**:
    1.  **入力チェック**: 引数と `gemini` コマンドの有効性を確認。
    2.  **ログ記録**: フォーマットされたログを `Gemini_Log.md` に追記。
    3.  **Git安全性**:
        - `git -C` を使用し、どのディレクトリにいても実行可能にする。
        - `git add Gemini_Log.md` でログファイルのみを対象とし、無関係な変更の巻き込みを防止。
        - `git pull --rebase` をPush前に実行し、他デバイスとの競合を回避。
        - `git push` で同期を実行。

## 検証計画
### 手動検証
1.  **作成**: `Scripts/glog.sh` ファイルを作成済み。
2.  **テスト**: ユーザーによる `source` コマンドの実行と、`glog` コマンドによる実際のログ書き込み・同期テスト。
