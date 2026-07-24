#!/usr/bin/env bash
set -euo pipefail

KEY_PATH="${1:-$HOME/.ssh/hostinger-naturaquell-ed25519}"
mkdir -p "$(dirname "$KEY_PATH")"

if [[ ! -f "$KEY_PATH" ]]; then
  ssh-keygen -t ed25519 -f "$KEY_PATH" -N "" -C "hostinger-naturaquell"
fi

echo "Add this public key once in Hostinger SSH access settings:"
cat "$KEY_PATH.pub"
