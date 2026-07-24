#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PROJECT_ROOT/.siteops/site.env"

SECRET_CONFIG="${HOSTINGER_SITE_CONFIG:-$HOME/.config/hostinger/$SITE_ID.env}"
if [[ ! -f "$SECRET_CONFIG" ]]; then
  echo "Missing private Hostinger config: $SECRET_CONFIG" >&2
  echo "Copy .siteops/hostinger.env.example to that location and fill in the SFTP/SSH values." >&2
  exit 1
fi
source "$SECRET_CONFIG"

: "${HOSTINGER_SFTP_HOST:?Missing HOSTINGER_SFTP_HOST}"
: "${HOSTINGER_SFTP_USER:?Missing HOSTINGER_SFTP_USER}"
: "${HOSTINGER_SFTP_PORT:=22}"
: "${HOSTINGER_SFTP_IDENTITY_FILE:?Missing HOSTINGER_SFTP_IDENTITY_FILE}"
: "${HOSTINGER_DEPLOY_METHOD:=sftp}"

if [[ ! -f "$HOSTINGER_SFTP_IDENTITY_FILE" ]]; then
  echo "Missing SSH identity file: $HOSTINGER_SFTP_IDENTITY_FILE" >&2
  exit 1
fi

"$PROJECT_ROOT/scripts/validate-static-site.sh"
"$PROJECT_ROOT/scripts/backup-to-obsidian.sh"

STAGE_DIR="$PROJECT_ROOT/.siteops/stage"
mkdir -p "$STAGE_DIR"
find "$STAGE_DIR" -mindepth 1 -delete
cp "$PROJECT_ROOT/index.html" "$STAGE_DIR/index.html"

for item in assets favicon.ico robots.txt sitemap.xml site.webmanifest; do
  if [[ -e "$PROJECT_ROOT/$item" ]]; then
    cp -R "$PROJECT_ROOT/$item" "$STAGE_DIR/$item"
  fi
done

if [[ "$HOSTINGER_DEPLOY_METHOD" == "rsync" ]]; then
  rsync -az --delete \
    -e "ssh -i $HOSTINGER_SFTP_IDENTITY_FILE -p $HOSTINGER_SFTP_PORT" \
    "$STAGE_DIR/" "$HOSTINGER_SFTP_USER@$HOSTINGER_SFTP_HOST:$HOSTINGER_REMOTE_DIR/"
elif [[ "$HOSTINGER_DEPLOY_METHOD" == "sftp" ]]; then
  BATCH_FILE="$(mktemp)"
  {
    printf 'cd %s\n' "$HOSTINGER_REMOTE_DIR"
    printf 'lcd %s\n' "$STAGE_DIR"
    printf 'put index.html index.html\n'
    for item in assets favicon.ico robots.txt sitemap.xml site.webmanifest; do
      if [[ -e "$STAGE_DIR/$item" ]]; then
        if [[ -d "$STAGE_DIR/$item" ]]; then
          printf 'put -r %s\n' "$item"
        else
          printf 'put %s %s\n' "$item" "$item"
        fi
      fi
    done
  } > "$BATCH_FILE"
  sftp -o StrictHostKeyChecking=accept-new -i "$HOSTINGER_SFTP_IDENTITY_FILE" -P "$HOSTINGER_SFTP_PORT" -b "$BATCH_FILE" "$HOSTINGER_SFTP_USER@$HOSTINGER_SFTP_HOST"
  find "$BATCH_FILE" -type f -delete
else
  echo "Unsupported HOSTINGER_DEPLOY_METHOD: $HOSTINGER_DEPLOY_METHOD" >&2
  exit 1
fi

echo "Deployment completed: $SITE_ID -> $HOSTINGER_SFTP_HOST/$HOSTINGER_REMOTE_DIR"
