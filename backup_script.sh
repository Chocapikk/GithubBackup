#!/bin/bash
#
# github-backup - Full mirror backup of a GitHub account
#
# Backs up all repositories (public + private), wikis, and gists
# using git mirror clones. Subsequent runs are incremental.
#
# Requirements: gh (authenticated), git
# Usage: ./backup_script.sh [backup_dir] [parallel_jobs]

set -euo pipefail

BACKUP_DIR="${1:-$HOME/github-backup}"
PARALLEL="${2:-4}"
FAILED=0

log()  { echo -e "\033[1;34m[*]\033[0m $1"; }
ok()   { echo -e "\033[1;32m[+]\033[0m $1"; }
warn() { echo -e "\033[1;33m[~]\033[0m $1"; }
fail() { echo -e "\033[1;31m[-]\033[0m $1"; }

if ! command -v gh &>/dev/null; then
    fail "gh CLI not found. Install it: https://cli.github.com"
    exit 1
fi

if ! gh auth status &>/dev/null; then
    fail "gh not authenticated. Run: gh auth login"
    exit 1
fi

USERNAME=$(gh api user --jq .login)

log "Account:   $USERNAME"
log "Backup:    $BACKUP_DIR"
log "Parallel:  $PARALLEL jobs"
echo

mkdir -p "$BACKUP_DIR/repos" "$BACKUP_DIR/wikis" "$BACKUP_DIR/gists"

mirror() {
    local url="$1" dest="$2" label="$3"
    local lock="${dest}.lock"

    # Interrupted previous clone - clean up partial data
    if [ -f "$lock" ] && [ -d "$dest" ]; then
        rm -rf "$dest"
    fi

    if [ -d "$dest" ]; then
        if git -C "$dest" remote update --prune &>/dev/null; then
            echo -e "\033[1;32m[+]\033[0m Updated $label"
        else
            echo -e "\033[1;31m[-]\033[0m Failed: $label"
        fi
    else
        touch "$lock"
        if git clone --mirror "$url" "$dest" &>/dev/null; then
            rm -f "$lock"
            echo -e "\033[1;32m[+]\033[0m Cloned $label"
        else
            rm -f "$lock"
            [[ "$label" == *"(wiki)"* ]] && return 0
            echo -e "\033[1;31m[-]\033[0m Failed: $label"
        fi
    fi
}
export -f mirror

# --- Repositories ---
log "Fetching repository list..."
REPO_LIST=$(gh repo list "$USERNAME" --limit 9999 --json name,url,hasWikiEnabled,isPrivate,description,isFork \
    --jq '.[] | "\(.name)\t\(.url)\t\(.hasWikiEnabled)\t\(.isPrivate)\t\(.description // "")\t\(.isFork)"')
REPO_COUNT=$(echo "$REPO_LIST" | wc -l)
log "Found $REPO_COUNT repositories"
echo

# Save repo metadata manifest
MANIFEST="$BACKUP_DIR/manifest.json"
echo "$REPO_LIST" | while IFS=$'\t' read -r name url wiki private desc fork; do
    printf '{"name":"%s","url":"%s","private":%s,"fork":%s,"description":"%s"}\n' \
        "$name" "$url" "$private" "$fork" "$(echo "$desc" | sed 's/"/\\"/g')"
done | jq -s '.' > "$MANIFEST"
log "Saved manifest to $MANIFEST"
echo

echo "$REPO_LIST" | while IFS=$'\t' read -r name url wiki private desc fork; do
    echo "$url|$BACKUP_DIR/repos/${name}.git|$name"
    if [ "$wiki" = "true" ]; then
        echo "${url}.wiki|$BACKUP_DIR/wikis/${name}.wiki.git|$name (wiki)"
    fi
done | xargs -P "$PARALLEL" -I {} bash -c '
    IFS="|" read -r url dest label <<< "{}"
    mirror "$url" "$dest" "$label"
'

# --- Gists ---
echo
log "Fetching gists..."
GIST_LIST=$(gh api gists --paginate --jq '.[] | "\(.id)\t\(.description // "untitled")"')
GIST_COUNT=$(echo "$GIST_LIST" | grep -c . || true)
log "Found $GIST_COUNT gists"
echo

echo "$GIST_LIST" | while IFS=$'\t' read -r id desc; do
    short="${desc:0:40}"
    echo "https://gist.github.com/${id}.git|$BACKUP_DIR/gists/${id}.git|gist: $short"
done | xargs -P "$PARALLEL" -I {} bash -c '
    IFS="|" read -r url dest label <<< "{}"
    mirror "$url" "$dest" "$label"
'

# --- Summary ---
echo
repo_count=$(find "$BACKUP_DIR/repos" -maxdepth 1 -name "*.git" -type d | wc -l)
wiki_count=$(find "$BACKUP_DIR/wikis" -maxdepth 1 -name "*.git" -type d | wc -l)
gist_count=$(find "$BACKUP_DIR/gists" -maxdepth 1 -name "*.git" -type d | wc -l)
total_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ok "Backup complete"
echo "  Repos:  $repo_count"
echo "  Wikis:  $wiki_count"
echo "  Gists:  $gist_count"
echo "  Size:   $total_size"
echo "  Path:   $BACKUP_DIR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
