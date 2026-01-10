#!/bin/bash
function glog() {
    # ▼ 設定: Obsidianのパス
    local VAULT_PATH="/Users/daisukemiyauchi/Documents/Obsidian"
    local LOG_FILE="${VAULT_PATH}/Gemini_Log.md"
    # すべての引数をスペース区切りの1つの文字列として取得
    local prompt="$*"
    local timestamp=$(date "+%Y-%m-%d %H:%M")

    # ▼ 入力チェック
    if [ -z "$prompt" ]; then
        echo "❌ エラー: 質問内容を入力してください (例: glog こんにちは)"
        return 1
    fi
    if ! command -v gemini &> /dev/null; then
        echo "❌ エラー: 'gemini' コマンドが見つかりません"
        return 1
    fi

    # ▼ ログファイル準備
    if [ ! -f "$LOG_FILE" ]; then
        printf "# Antigravity Chat Log\n\n" > "$LOG_FILE"
    fi

    # ▼ 記録開始
    printf "\n## [${timestamp}] User Query\n> ${prompt}\n\n**Antigravity Session:**\n\`\`\`text\n" >> "$LOG_FILE"

    # ▼ 実行と記録
    # 標準エラー出力も含めてファイルに記録しつつ、画面にも表示
    gemini -p "$prompt" 2>&1 | tee -a "$LOG_FILE"

    # ▼ 記録終了
    printf "\n\`\`\`\n\n---\n" >> "$LOG_FILE"

    # ▼ Git 安全同期 (Fail Fast Strategy)
    # サブシェル内で実行することで、呼び出し元のディレクトリを変更しない
    (
        cd "$VAULT_PATH" || exit 1
        
        # 1. ローカル保存 (コミット)
        # ログファイルのみをステージング (他にも変更がある場合に巻き込まない)
        git add "$LOG_FILE"
        
        # 変更がある場合のみコミット
        if ! git diff-index --quiet HEAD --; then
            git commit -m "Auto-log: ${timestamp}" > /dev/null
        fi

        # 2. 同期 (Pull --rebase)
        # 失敗した場合は直ちに中止し、ユーザーに通知する (自動Stash等の危険な操作は行わない)
        if ! git pull --rebase origin main > /dev/null 2>&1; then
            echo "⚠️  同期エラー: リモートとの競合、または未コミットの変更が邪魔をしています。"
            echo "   ログはローカルに保存されましたが、クラウド同期(Push)は行われていません。"
            echo "   Obsidianフォルダで 'git status' を確認し、手動で解決してください。"
            # Rebaseが途中であれば安全に中止する
            git rebase --abort > /dev/null 2>&1
            return 1
        fi

        # 3. Push
        if ! git push origin main > /dev/null 2>&1; then
             echo "⚠️  Pushエラー: インターネット接続を確認してください。"
             return 1
        fi
        
        echo "✅ ログ保存完了 (Synced)"
    )
}
