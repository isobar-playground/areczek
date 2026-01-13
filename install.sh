#!/usr/bin/env bash
set -euo pipefail

# Areczek OpenCode Pack installer (latest)
# Installs:
# - Pack to:   ~/.config/opencode-packs/areczek
# - Wrapper:   ~/.local/bin/opencode-areczek
# Also installs OpenCode if missing.

REPO_OWNER="isobar-playground"
REPO_NAME="areczek"
REPO_BRANCH="master"
PACK_NAME="areczek"

PACK_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}/opencode-packs"
PACK_DIR="$PACK_ROOT/$PACK_NAME"
BIN_DIR="$HOME/.local/bin"
WRAPPER_PATH="$BIN_DIR/opencode-areczek"

log()  { printf '%s\n' "$*"; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

need() {
  have "$1" || die "Missing required command: $1"
}

install_opencode_if_missing() {
  if have opencode; then
    return 0
  fi

  log "OpenCode not found. Installing via https://opencode.ai/install ..."
  need curl

  # Official installer
  curl -fsSL https://opencode.ai/install | bash

  have opencode || die "OpenCode installation finished, but 'opencode' is still not in PATH"
}

backup_existing_pack_if_present() {
  if [[ -d "$PACK_DIR" ]]; then
    local ts
    ts="$(date +%Y%m%d%H%M%S)"
    local backup
    backup="${PACK_DIR}.bak.${ts}"
    log "Existing pack found. Backing up to: $backup"
    mv "$PACK_DIR" "$backup"
  fi
}

install_pack() {
  need curl
  need tar
  need mktemp

  mkdir -p "$PACK_ROOT"

  local tmp
  tmp="$(mktemp -d)"

  local url
  url="https://codeload.github.com/${REPO_OWNER}/${REPO_NAME}/tar.gz/refs/heads/${REPO_BRANCH}"

  log "Downloading pack from: $url"
  curl -fsSL "$url" -o "$tmp/pack.tgz"

  tar -xzf "$tmp/pack.tgz" -C "$tmp"

  # GitHub tarballs unpack as: <repo>-<branch>/
  local src_dir
  src_dir="$tmp/${REPO_NAME}-${REPO_BRANCH}"

  [[ -d "$src_dir" ]] || die "Unexpected archive layout. Missing: $src_dir"

  backup_existing_pack_if_present

  # Atomic-ish install: move into place
  mv "$src_dir" "$PACK_DIR"

  rm -rf "$tmp"

  log "Installed pack to: $PACK_DIR"
}

install_wrapper() {
  mkdir -p "$BIN_DIR"

  cat >"$WRAPPER_PATH" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

PACK_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode-packs/areczek"
export OPENCODE_CONFIG_DIR="$PACK_DIR"

# If user already selected an agent, don't override it.
case " $* " in
  *" --agent "*|*" -a "*) exec opencode "$@" ;;
  *) exec opencode --agent areczek "$@" ;;
esac
EOF

  chmod +x "$WRAPPER_PATH"
  log "Installed wrapper to: $WRAPPER_PATH"
}

print_path_hint() {
  if have opencode-areczek; then
    return 0
  fi

  log ""
  log "NOTE: 'opencode-areczek' is not on your PATH yet."
  log "Add this to your shell config (zsh/bash) and restart the terminal:"
  log "  export PATH=\"$BIN_DIR:\$PATH\""
}

smoke_check() {
  if ! have opencode; then
    return 0
  fi

  log "Running smoke check: opencode agent list"
  OPENCODE_CONFIG_DIR="$PACK_DIR" opencode agent list || true
}

main() {
  need bash

  install_opencode_if_missing
  install_pack
  install_wrapper
  smoke_check
  print_path_hint

  log ""
  log "Done. Run: opencode-areczek"
}

main "$@"
