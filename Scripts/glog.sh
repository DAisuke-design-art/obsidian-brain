#!/bin/bash
function glog() {
    # ▼ 設定: Obsidianのパス
    local VAULT_PATH="/Users/daisukemiyauchi/Documents/Obsidian"
    local LOG_FILE="${VAULT_PATH}/Gemini_Log.md"
    local prompt="$1"
    local timestamp=$(date "+%Y-%m-%d %H:%M")

    # ▼ 入力チェック
    if [ -z "$prompt" ]; then
        echo "❌ エラー: 質問内容を入力してください"
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

    # ▼ 記録実行
    printf "\n## [${timestamp}] User Query\n${prompt}\n\n**Answer:**\n" >> "$LOG_FILE"
    gemini -p "$prompt" | tee -a "$LOG_FILE"
    printf "\n\n---\n" >> "$LOG_FILE"

    # ▼ Git自動バックアップ（安全対策済み）
    echo "\n🔄 GitHubへバックアップ中..."
    
    # ログファイルのみを追加
    git -C "$VAULT_PATH" add "$LOG_FILE"
    
    # 変更チェックとコミット
    if git -C "$VAULT_PATH" diff-index --quiet HEAD --; then
        echo "ℹ️ 変更がないためコミットしませんでした。"
    else
        git -C "$VAULT_PATH" commit -m "Auto-log: ${timestamp}" > /dev/null 2>&1
        
        # 競合回避 (Stash -> Pull Rebase -> Pop) -> Push
        # 1. 未コミットの変更を退避
        local stashed=0
        if ! git -C "$VAULT_PATH" diff-index --quiet HEAD --; then
            git -C "$VAULT_PATH" stash push -m "Auto-glog-stash: ${timestamp}" > /dev/null 2>&1
            stashed=1
        fi

        # 2. Pull (Rebase)
        if git -C "$VAULT_PATH" pull --rebase origin main > /dev/null 2>&1; then
             # 3. 退避した変更を戻す
             if [ $stashed -eq 1 ]; then
                 git -C "$VAULT_PATH" stash pop > /dev/null 2>&1
             fi
             
             # 4. Push
             git -C "$VAULT_PATH" push origin main > /dev/null 2>&1
             if [ $? -eq 0 ]; then
                 echo "✅ 保存完了！GitHubへの同期に成功しました。"
             else
                 echo "⚠️ Push失敗。ネット接続等を確認してください。"
                 echo "詳細: $(git -C "$VAULT_PATH" push origin main 2>&1)"
             fi
        else
             echo "⚠️ Pull (Rebase) 失敗。手動解決が必要です。"
             # Rebase失敗時はAbortして元の状態に戻す試み
             git -C "$VAULT_PATH" rebase --abort > /dev/null 2>&1
             if [ $stashed -eq 1 ]; then
                 git -C "$VAULT_PATH" stash pop > /dev/null 2>&1
             fi
        fi
    fi
}
