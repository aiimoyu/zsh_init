#!/bin/bash
#===============================================================================
#
#          FILE: install.sh
#
#         USAGE: bash -c "$(curl -fsSL https://raw.githubusercontent.com/aiimoyu/zsh_init/refs/heads/main/install.sh)"
#
#   DESCRIPTION: Bootstrap installer that downloads and executes zsh_install.sh
#
#      AUTHOR: aiimoyu
#     VERSION: 1.0.0
#     CREATED: 2024-01-01
#
#===============================================================================

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Zsh Development Environment Installer Bootstrap      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check for required commands
echo -e "${YELLOW}[1/3] Checking prerequisites...${NC}"
if ! command -v curl &>/dev/null; then
	echo -e "${RED}Error: curl is required but not installed.${NC}"
	exit 1
fi

if ! command -v git &>/dev/null; then
	echo -e "${RED}Error: git is required but not installed.${NC}"
	exit 1
fi
echo -e "${GREEN}✓ Prerequisites check passed${NC}"
echo ""

# Download the installation script
echo -e "${YELLOW}[2/3] Downloading installation script...${NC}"
SCRIPT_URL="https://raw.githubusercontent.com/aiimoyu/zsh_init/refs/heads/main/zsh_install.sh"

if ! curl -fsSL "$SCRIPT_URL" -o /tmp/zsh_install.sh; then
	echo -e "${RED}Error: Failed to download installation script.${NC}"
	echo -e "${RED}Please check your network connection and try again.${NC}"
	exit 1
fi
echo -e "${GREEN}✓ Script downloaded successfully${NC}"
echo ""

# Make executable and run
echo -e "${YELLOW}[3/3] Starting installation...${NC}"
chmod +x /tmp/zsh_install.sh

# Pass all arguments to the main script
exec /tmp/zsh_install.sh "$@"
