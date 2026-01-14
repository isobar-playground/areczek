#!/usr/bin/env bash
set -euo pipefail

# Areczek OpenCode Pack installer (latest stable)
# Installs:
# - Pack to:   ~/.config/opencode-packs/areczek
# - Wrapper:   ~/.local/bin/opencode-areczek
# Also installs OpenCode if missing.
#
# By default, downloads the pack from the latest GitHub Release asset.

REPO_OWNER="isobar-playground"
REPO_NAME="areczek"
REPO_BRANCH="master" # fallback only
PACK_NAME="areczek"
PACK_ASSET="areczek-pack.tgz"

PACK_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}/opencode-packs"
PACK_DIR="$PACK_ROOT/$PACK_NAME"
BIN_DIR="$HOME/.local/bin"
WRAPPER_PATH="$BIN_DIR/opencode-areczek"
OPENCODE_CMD=""

log()  { printf '%s\n' "$*"; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

need() {
  have "$1" || die "Missing required command: $1"
}

locate_opencode_bin_dir() {
  # 1) If already on PATH, use that (covers reuse + login shells).
  if have opencode; then
    dirname "$(command -v opencode)"
    return 0
  fi

  # 2) Common installer targets (documented by OpenCode installer).
  local -a candidates=(
    "${OPENCODE_BIN_DIR:-}"
    "$HOME/.opencode/bin"
    "$HOME/.local/bin"
  )
  local dir
  for dir in "${candidates[@]}"; do
    if [[ -n "$dir" && -x "$dir/opencode" ]]; then
      printf '%s\n' "$dir"
      return 0
    fi
  done

  # 3) Last resort: shallow search under $HOME (non-fatal if find is absent).
  if have find; then
    local found
    found="$(find "$HOME" -maxdepth 4 -type f -name opencode -perm -u+x 2>/dev/null | head -n1 || true)"
    if [[ -n "$found" ]]; then
      dirname "$found"
      return 0
    fi
  fi

  return 1
}

resolve_opencode_cmd() {
  if [[ -n "$OPENCODE_CMD" && -x "$OPENCODE_CMD" ]]; then
    return 0
  fi

  if have opencode; then
    OPENCODE_CMD="$(command -v opencode)"
    return 0
  fi

  local dir
  if dir="$(locate_opencode_bin_dir)"; then
    OPENCODE_CMD="$dir/opencode"
    return 0
  fi

  return 1
}

install_opencode_if_missing() {
  resolve_opencode_cmd || true

  if [[ -n "$OPENCODE_CMD" ]]; then
    return 0
  fi

  log "OpenCode not found. Installing via https://opencode.ai/install ..."
  need curl

  # Official installer
  curl -fsSL https://opencode.ai/install | bash

  resolve_opencode_cmd || true

  if [[ -z "$OPENCODE_CMD" ]]; then
    die "OpenCode installation finished, but 'opencode' binary was not found"
  fi
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
  url="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/latest/download/${PACK_ASSET}"

  log "Downloading pack (latest release) from: $url"

  if ! curl -fsSL "$url" -o "$tmp/pack.tgz"; then
    log "WARNING: Could not download latest release asset. Falling back to branch tarball (${REPO_BRANCH})."

    url="https://codeload.github.com/${REPO_OWNER}/${REPO_NAME}/tar.gz/refs/heads/${REPO_BRANCH}"
    log "Downloading pack (fallback) from: $url"
    curl -fsSL "$url" -o "$tmp/pack.tgz"

    tar -xzf "$tmp/pack.tgz" -C "$tmp"

    # GitHub tarballs unpack as: <repo>-<branch>/
    local src_dir
    src_dir="$tmp/${REPO_NAME}-${REPO_BRANCH}"

    [[ -d "$src_dir" ]] || die "Unexpected archive layout. Missing: $src_dir"

    backup_existing_pack_if_present
    mv "$src_dir" "$PACK_DIR"

    rm -rf "$tmp"

    log "Installed pack to: $PACK_DIR"
    return 0
  fi

  mkdir -p "$tmp/pack"
  tar -xzf "$tmp/pack.tgz" -C "$tmp/pack"

  backup_existing_pack_if_present

  mv "$tmp/pack" "$PACK_DIR"

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
  if ! resolve_opencode_cmd; then
    return 0
  fi

  log "Running smoke check: opencode agent list (areczek*)"
  local output
  output="$(OPENCODE_CONFIG_DIR="$PACK_DIR" "$OPENCODE_CMD" agent list 2>/dev/null || true)"
  printf "%s\n" "$output" | grep -i "areczek" || true

  local -a expected_agents
  expected_agents=(areczek januszek aireczek anetka)
  local missing=()
  for agent in "${expected_agents[@]}"; do
    if ! printf "%s\n" "$output" | grep -qi "$agent"; then
      missing+=("$agent")
    fi
  done
  if (( ${#missing[@]} > 0 )); then
    log "WARNING: Missing expected areczek agents: ${missing[*]}"
  fi
}

print_areczek_ascii() {
  cat <<'ARECZEK_ASCII'
........................................................................................::::::::::::::::::::
.....................................................::-====+=::........................::::::::::::::::::::
.................................................-+*%%@@@@@@@@@%#*=:....................::::::::::::::::::::
...............................................-#@@@@@@@@@@@@@@@@@@%+:..................::::::::::::::::::::
.............................................:#@@@@@@%%###%%%%%%%@@@@%+.................::::::::::::::::::::
.............................................*@@@@%#*+++=+++++++***##%%+...................:::::::::::::::::
............................................-@@%##*++========---====+++#-.................::::::::::::::::::
............................................+%%#**+++========------====+*..................:::::::::::::::::
............................................*#**++++====------------===++-...................:::::::::::::::
...........................................:#*+++======-------------====+-...................:::::::::::::::
.........................................:-=*+++============--------=====-..................::::::::::::::::
........................................:+==++++============---::---==+++-...............:::::::::::::::::::
........................................:+==+++++==--=+++*+++=---=++++++=-...................:::::::::::::::
.........................................=+*+++++=====++++++*+====***+++=-.....................:::::::::::::
.........................................-==+++++++==============++=+++++-.....................:::::::::::::
.........................................:+++++++++====----=+====-========.....................:::::::::::::
.........................................:+++++=+=====---==+**+==-+++=-===.....................:::.:::::::::
.........................................:+++++======---==+##%#**#%%++--==.....................:::.:::::::::
.........................................:=++++=====----======+=++*++---=-.....................:::::::::::::
.........................................%=-=+++====----==-----======--==:...................:.::..:::::::::
........................................+@@*::=+====----------=======--=-....................::.......::::::
.......................................+@@@@@+:-++===----==------====-=-..............................::::::
.....................................-*@@@@@@@@*--===-----====---===---.................................::::
..................................:+%@@@@@@@@@@@@+:-==------------===*#-:..............................:::::
................................-*@@@@@@@@@@@@@@@@%=.:------------==-=@@%%*+-..........................:::::
............................:=#%@@@@@@@@@@@@@@@@@@@@#:..::---------:..=@@@@@@%#+-.....................::::::
.........................:+%@@@@@@@@@@@@@@@@@@@@@@@@@%-......::---::.:.+@@@@@@@@@%+-..................::::::
.......................-*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+.....:::---=-:.:#@@@@@@@@@@@%*-:...............:::::
....................-*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#:...--::::-::::-%@@@@@@@@@@@@@%=..............:::::
.................:+%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%-.::::--:--::::-@@@@@@@@@@@@@@@+.........:::::::::
...............:*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+:.:.:-::==::::=@@@@@@@@@@@@@@@:...........::::::
..............+@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*:.:--:::==::::+@@@@@@@@@@@@@@+........:::::::::
.............#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%-.:=:::--=-:::*@@@@@@@@@@@@@@:.....:.:::::::::
............#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%=.=-:::--=-::-#@@@@@@@@@@@@@+.......:::::::::
...........=@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*:-------=-.:=%@@@@@@@@@@@@@:.....::::::::::
...........#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#--------=-::+%@@@@@@@@@@%@#....:::::::::::
..........-@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%+=------=::-*%@@@@@@@@@@@@=..::::::::::::
.........:@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*=-------::-*%%%@@@@@@@@@%:.::::::::::::
.........#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*------=-.:+*%%@@@@@@@@@@+.::::::::::::
ARECZEK_ASCII

  cat <<'ARECZEK_SIGN'
                                                                                
                                                                                
█████▄  ▄▄▄  ▄▄  ▄▄ ▄▄ ▄▄▄▄▄   ▄████▄ ▄▄▄▄  ▄▄▄▄▄  ▄▄▄▄ ▄▄▄▄▄ ▄▄ ▄▄ ▄▄ ▄▄       
██▄▄█▀ ██▀██ ███▄██ ██ ██▄▄    ██▄▄██ ██▄█▄ ██▄▄  ██▀▀▀   ▄█▀ ██▄█▀ ██ ██       
██     ██▀██ ██ ▀██ ██ ██▄▄▄   ██  ██ ██ ██ ██▄▄▄ ▀████ ▄██▄▄ ██ ██ ▀███▀  ▄    
                                                                          ▀     
                                                                                
                                                                                
▄▄▄▄  ▄▄▄▄  ▄▄▄▄▄ ▄▄▄▄▄ ▄▄▄▄  ▄▄   ▄▄  ▄▄▄      ▄▄ ▄▄▄▄▄  ▄▄▄▄ ▄▄▄▄▄▄           
██▄█▀ ██▄█▄   ▄█▀ ██▄▄  ██▄█▄ ██ ▄ ██ ██▀██     ██ ██▄▄  ███▄▄   ██             
██    ██ ██ ▄██▄▄ ██▄▄▄ ██ ██  ▀█▀█▀  ██▀██   ▄▄█▀ ██▄▄▄ ▄▄██▀   ██             
                                                                                
                                                                                
                                                                                
▄▄▄▄  ▄▄     ▄▄▄    ██████  ▄▄▄  ▄▄▄▄  ▄▄▄▄▄  ▄▄▄  ▄▄▄▄  ▄▄ ▄▄                  
██▀██ ██    ██▀██    ▄▄▀▀  ██▀██ ██▄█▄   ▄█▀ ██▀██ ██▀██ ██ ██                  
████▀ ██▄▄▄ ██▀██   ██████ ██▀██ ██ ██ ▄██▄▄ ██▀██ ████▀ ▀███▀                  
                                                 █▄                             
ARECZEK_SIGN
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
  log ""
  print_areczek_ascii
}

main "$@"
