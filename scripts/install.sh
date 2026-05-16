#!/usr/bin/env bash
# Agentic SRE Bootstrap Installer
# Inspired by the OpenSRE installation experience.
# Usage: curl -fsSL https://raw.githubusercontent.com/DsThakurRawat/Agentic-SRE/main/scripts/install.sh | bash

set -eu

# -- Configuration ------------------------------------------------------------
BIN_NAME="agentic-sre"
REPO_URL="https://github.com/DsThakurRawat/Agentic-SRE"
GIT_TARGET="git+$REPO_URL.git"

# -- UI Helpers ---------------------------------------------------------------
COLOR_RESET="\033[0m"
COLOR_CYAN="\033[36m"
COLOR_GREEN="\033[32m"
COLOR_RED="\033[31m"
COLOR_YELLOW="\033[33m"

step()    { printf "\n%b%s%b\n" "${COLOR_CYAN}" "$*" "${COLOR_RESET}"; }
success() { printf "%b✓ %s%b\n" "${COLOR_GREEN}" "$*" "${COLOR_RESET}"; }
warn()    { printf "%b! %s%b\n" "${COLOR_YELLOW}" "$*" "${COLOR_RESET}"; }
fail()    { printf "%b✗ %s%b\n" "${COLOR_RED}" "$*" "${COLOR_RESET}"; exit 1; }

# -- Help ---------------------------------------------------------------------
usage() {
  cat <<EOF
Usage: install.sh [--main] [--version <version>]

Installs the Agentic SRE CLI.

Options:
  --main                Install the rolling build from the main branch.
  --version <version>   Install a specific release version.
  -h, --help            Show this help text.

Examples:
  curl -fsSL https://raw.githubusercontent.com/DsThakurRawat/Agentic-SRE/main/scripts/install.sh | bash
  curl -fsSL https://raw.githubusercontent.com/DsThakurRawat/Agentic-SRE/main/scripts/install.sh | bash -s -- --main
EOF
}

# -- Parse Arguments ----------------------------------------------------------
REQUESTED_VERSION=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --main)    shift ;;
    --version) [ "$#" -ge 2 ] || fail "--version requires a value."; REQUESTED_VERSION="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) shift ;;
  esac
done

printf "\n%b%s%b\n" "\033[1m${COLOR_CYAN}" "Agentic SRE Installer" "${COLOR_RESET}"
echo "The flagship orchestration engine for Autonomous SRE."

# -- [1/3] Install uv ---------------------------------------------------------
step "[1/3] Checking for uv (fast Python package manager)..."

if ! command -v uv >/dev/null 2>&1; then
  warn "uv not found. Installing uv..."
  curl -fsSL https://astral.sh/uv/install.sh | sh
  # Add uv to current PATH
  export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
fi

if command -v uv >/dev/null 2>&1; then
  success "uv is available"
else
  fail "Could not install uv. Please install it manually: https://docs.astral.sh/uv/getting-started/installation/"
fi

# -- [2/3] Resolve target -----------------------------------------------------
step "[2/3] Resolving installation target..."
if [ -n "$REQUESTED_VERSION" ]; then
  INSTALL_TARGET="${BIN_NAME}==${REQUESTED_VERSION}"
  success "Installing version $REQUESTED_VERSION"
elif [ -f "pyproject.toml" ] && grep -q "name = \"agentic-sre\"" pyproject.toml; then
  INSTALL_TARGET="."
  success "Installing from local source"
else
  INSTALL_TARGET="$GIT_TARGET"
  success "Installing latest build from GitHub"
fi

# -- [3/3] Install Agentic SRE ------------------------------------------------
step "[3/3] Installing Agentic SRE..."

if uv tool install "$INSTALL_TARGET" --force 2>&1; then
  echo
  success "Agentic SRE successfully installed!"
  echo
  printf "Next steps:\n"
  printf "  1. Run '%s' to start the configuration wizard.\n" "$BIN_NAME"
  printf "  2. Visit %s for more info.\n\n" "$REPO_URL"
else
  fail "Installation failed. Run with 'bash -x' for debug output."
fi
