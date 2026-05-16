#!/usr/bin/env bash
# Agentic SRE Bootstrap Installer
# Inspired by the OpenSRE installation experience.

set -eu

# -- Configuration ------------------------------------------------------------
BIN_NAME="agentic-sre"
REPO_URL="https://github.com/DsThakurRawat/Agentic-SRE"
DEFAULT_INSTALL_CHANNEL="main"

# -- UI Helpers ---------------------------------------------------------------
COLOR_RESET="\033[0m"
COLOR_CYAN="\033[36m"
COLOR_GREEN="\033[32m"
COLOR_RED="\033[31m"
COLOR_YELLOW="\033[33m"
SUCCESS_MARK="✓"
ERROR_MARK="✗"

step() {
  printf "\n%b%s%b\n" "${COLOR_CYAN}" "$*" "${COLOR_RESET}"
}

success() {
  printf "%b%s %s%b\n" "${COLOR_GREEN}" "${SUCCESS_MARK}" "$*" "${COLOR_RESET}"
}

warn() {
  printf "%b! %s%b\n" "${COLOR_YELLOW}" "$*" "${COLOR_RESET}"
}

fail() {
  printf "%b%s %s%b\n" "${COLOR_RED}" "${ERROR_MARK}" "$*" "${COLOR_RESET}"
  exit 1
}

# -- Help ---------------------------------------------------------------------
usage() {
  cat <<EOF
Usage: install.sh [--main] [--version <version>]

Installs the Agentic SRE CLI.

Options:
  --main                Install the rolling build published from the main branch.
  --version <version>   Install a specific release version.
  -h, --help            Show this help text.

Examples:
  curl -fsSL https://agentic-sre.ai/install | bash
  curl -fsSL https://agentic-sre.ai/install | bash -s -- --main
EOF
}

# -- Detect Python 3.13 -------------------------------------------------------
check_python() {
  PYTHON=""
  for candidate in python3.13 python3 python; do
    if command -v "$candidate" >/dev/null 2>&1; then
      VER="$($candidate --version 2>&1 | awk '{print $2}')"
      if [[ "$VER" == 3.13* ]]; then
        PYTHON="$candidate"
        return 0
      fi
    fi
  done
  return 1
}

# -- Main Logic ---------------------------------------------------------------
INSTALL_CHANNEL="$DEFAULT_INSTALL_CHANNEL"
REQUESTED_VERSION=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --main) INSTALL_CHANNEL="main"; shift ;;
    --version) [ "$#" -ge 2 ] || fail "--version requires a value."; REQUESTED_VERSION="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) shift ;;
  esac
done

printf "\n%b%s%b\n" "\033[1m${COLOR_CYAN}" "Agentic SRE Installer" "${COLOR_RESET}"
echo "The flagship orchestration engine for Autonomous SRE."

step "[1/3] Checking environment..."
if check_python; then
  success "Found Python $VER"
else
  fail "Python 3.13 is required. Please install it before running this script."
fi

# Ensure pipx
if ! command -v pipx >/dev/null 2>&1; then
  step "Installing pipx..."
  "$PYTHON" -m pip install --user pipx >/dev/null 2>&1
  "$PYTHON" -m pipx ensurepath >/dev/null 2>&1
  export PATH="$HOME/.local/bin:$PATH"
fi

step "[2/3] Resolving installation target..."
if [ -f "pyproject.toml" ] && grep -q "name = \"agentic-sre\"" pyproject.toml; then
  INSTALL_TARGET="."
  info_msg="Installing from local source"
elif [ "$INSTALL_CHANNEL" = "main" ]; then
  INSTALL_TARGET="git+$REPO_URL.git"
  info_msg="Installing latest build from main"
elif [ -n "$REQUESTED_VERSION" ]; then
  INSTALL_TARGET="agentic-sre==$REQUESTED_VERSION"
  info_msg="Installing version $REQUESTED_VERSION"
else
  INSTALL_TARGET="agentic-sre"
  info_msg="Installing stable release"
fi
success "$info_msg"

step "[3/3] Installing Agentic SRE..."
if pipx install "$INSTALL_TARGET" --python "$PYTHON" --force >/dev/null 2>&1; then
  success "Agentic SRE successfully installed!"
  echo
  printf "Next steps:\n"
  printf "  1. Run '${BIN_NAME}' to start the configuration wizard.\n"
  printf "  2. Visit ${REPO_URL} for more info.\n\n"
else
  fail "Installation failed. Please check your network and Python setup."
fi
