#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PROJECT_ROOT/.siteops/site.env"

BACKUP_ROOT="${OBSIDIAN_WEBSITE_BACKUP_ROOT:?Missing OBSIDIAN_WEBSITE_BACKUP_ROOT}"
STAMP="$(date +%Y%m%d-%H%M%S)"
SNAPSHOT_DIR="$BACKUP_ROOT/$SITE_ID/snapshots/$STAMP"

mkdir -p "$SNAPSHOT_DIR/code"
rsync -a \
  --exclude '.git/' \
  --exclude '.qa/' \
  --exclude '.siteops/stage/' \
  --exclude '.siteops/hostinger.env' \
  --exclude '.DS_Store' \
  "$PROJECT_ROOT/" "$SNAPSHOT_DIR/code/"

GIT_REVISION="$(git -C "$PROJECT_ROOT" rev-parse --short HEAD 2>/dev/null || printf 'uncommitted')"
cat > "$SNAPSHOT_DIR/SNAPSHOT.md" <<EOF
# Website Snapshot

- Site: $SITE_ID
- Created: $(date '+%Y-%m-%d %H:%M:%S %Z')
- Git revision: $GIT_REVISION
- Source: $PROJECT_ROOT
EOF

echo "Obsidian snapshot created: $SNAPSHOT_DIR"
