#!/bin/bash
#===============================================================================
#
#          FILE: zsh_install.sh
#
#         USAGE: ./zsh_install.sh [OPTIONS]
#
#   DESCRIPTION: Professional Zsh development environment installer with
#                Oh My Zsh, plugins, and modern tooling.
#
#   OPTIONS:
#       -h, --help          Show this help message
#       -v, --verbose       Enable verbose output
#       -q, --quiet         Suppress non-essential output
#       -n, --dry-run       Show what would be done without making changes
#       --skip-plugins      Skip plugin installation
#       --skip-starship     Skip Starship prompt installation
#
#  REQUIREMENTS: bash 4.0+, curl, git, sudo
#
#         BUGS: https://github.com/your-repo/zsh_init/issues
#
#        NOTES: This script is idempotent - safe to run multiple times
#
#       AUTHOR: Your Name <your.email@example.com>
#      VERSION: 2.0.0
#      CREATED: 2024-01-01
#     REVISION: 2024-01-15
#===============================================================================

set -o nounset                              # Treat unset variables as errors
set -o pipefail                             # Pipe failures don't mask errors

#-------------------------------------------------------------------------------
# Global Constants
#-------------------------------------------------------------------------------
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_VERSION="2.1.0"

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_GENERAL_ERROR=1
readonly EXIT_INSTALL_FAILED=2
readonly EXIT_OS_UNSUPPORTED=3
readonly EXIT_DEPENDENCY_MISSING=4

# Installation paths
readonly OHMYZSH_DIR="$HOME/.oh-my-zsh"
readonly PLUGINS_DIR="${ZSH_CUSTOM:-$OHMYZSH_DIR/custom}/plugins"

#===============================================================================
# COMPONENT REGISTRY - Add new components here
#===============================================================================
# Each component has:
#   - type: "git" for git repos, "script" for curl|sh installers
#   - source: git URL or script URL
#   - path: installation directory (for git type)
#   - check_cmd: command to check if installed (optional, for script type)
#   - desc: human-readable description
#
# To add a new plugin, just add an entry below. No other code changes needed!
#===============================================================================

declare -A COMPONENTS=(
    # Oh My Zsh core
    ["oh-my-zsh"]="type:git|source:https://github.com/ohmyzsh/ohmyzsh.git|path:$OHMYZSH_DIR|desc:Oh My Zsh framework"
    
    # Zsh plugins (git-based)
    ["zsh-syntax-highlighting"]="type:git|source:https://github.com/zsh-users/zsh-syntax-highlighting.git|path:$PLUGINS_DIR/zsh-syntax-highlighting|desc:Syntax highlighting for commands"
    ["zsh-autosuggestions"]="type:git|source:https://github.com/zsh-users/zsh-autosuggestions.git|path:$PLUGINS_DIR/zsh-autosuggestions|desc:Fish-like autosuggestions"
    ["you-should-use"]="type:git|source:https://github.com/MichaelAquilina/zsh-you-should-use.git|path:$PLUGINS_DIR/you-should-use|desc:Reminder for defined aliases"
    ["zsh-completions"]="type:git|source:https://github.com/zsh-users/zsh-completions.git|path:$PLUGINS_DIR/zsh-completions|desc:Additional completions"
    
    # External tools (script-based)
    ["starship"]="type:script|source:https://starship.rs/install.sh|check_cmd:starship|desc:Cross-shell prompt"
)

# Default plugins for .zshrc (Oh My Zsh built-in + custom)
readonly DEFAULT_PLUGINS=(
    "git"
    "z"
    "extract"
    "sudo"
    "command-not-found"
    "safe-paste"
    "tmux"
    "history"
    "you-should-use"
    "zsh-syntax-highlighting"
    "zsh-autosuggestions"
)

#-------------------------------------------------------------------------------
# Global Variables
#-------------------------------------------------------------------------------
VERBOSE=false
QUIET=false
DRY_RUN=false
SKIP_PLUGINS=false
SKIP_STARSHIP=false

#-------------------------------------------------------------------------------
# Logging Functions
#-------------------------------------------------------------------------------
log() {
    local level="$1"
    shift
    local message="$*"
    
    # Respect quiet mode for non-error messages
    if [[ "$QUIET" == true && "$level" != "ERROR" ]]; then
        return
    fi
    
    # Color codes
    local red='\033[0;31m'
    local green='\033[0;32m'
    local yellow='\033[0;33m'
    local blue='\033[0;34m'
    local nc='\033[0m'
    
    case "$level" in
        ERROR)
            echo -e "${red}[$level]${nc} $message" >&2
            ;;
        WARN)
            echo -e "${yellow}[$level]${nc} $message"
            ;;
        INFO)
            echo -e "${green}[$level]${nc} $message"
            ;;
        DEBUG)
            if [[ "$VERBOSE" == true ]]; then
                echo -e "${blue}[$level]${nc} $message"
            fi
            ;;
    esac
}

log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }
log_debug() { log "DEBUG" "$@"; }

#-------------------------------------------------------------------------------
# Utility Functions
#-------------------------------------------------------------------------------
usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS] [COMMAND]

Professional Zsh development environment installer and manager.

OPTIONS:
    -h, --help          Show this help message and exit
    -v, --verbose       Enable verbose output (DEBUG level logging)
    -q, --quiet         Suppress non-essential output
    -n, --dry-run       Show what would be done without making changes
    --skip-plugins      Skip plugin installation
    --skip-starship     Skip Starship prompt installation

COMMANDS:
    install             Install all components (default if no command)
    update [NAME]       Update all components or specific component
    status              Show installation status of all components
    list                List all available components

EXAMPLES:
    $SCRIPT_NAME                          # Install with defaults
    $SCRIPT_NAME install                  # Same as above
    $SCRIPT_NAME update                   # Update all components
    $SCRIPT_NAME update zsh-syntax-highlighting  # Update specific plugin
    $SCRIPT_NAME status                   # Check what's installed
    $SCRIPT_NAME list                     # List available components
    $SCRIPT_NAME --dry-run install        # Preview installation

EXIT CODES:
    0   Success
    1   General error
    2   Installation failed
    3   Unsupported operating system
    4   Missing dependency

EOF
}

#-------------------------------------------------------------------------------
# Component Registry Helpers
#-------------------------------------------------------------------------------
parse_component_field() {
    local component="$1"
    local field="$2"
    local data="${COMPONENTS[$component]}"
    
    echo "$data" | grep -oP "\b$field:\K[^|]+"
}

get_component_type() {
    parse_component_field "$1" "type"
}

get_component_source() {
    parse_component_field "$1" "source"
}

get_component_path() {
    parse_component_field "$1" "path"
}

get_component_check_cmd() {
    parse_component_field "$1" "check_cmd"
}

get_component_desc() {
    parse_component_field "$1" "desc"
}

is_component_installed() {
    local name="$1"
    local type
    type=$(get_component_type "$name")
    
    case "$type" in
        git)
            local path
            path=$(get_component_path "$name")
            [[ -d "$path/.git" ]]
            ;;
        script)
            local check_cmd
            check_cmd=$(get_component_check_cmd "$name")
            [[ -n "$check_cmd" ]] && command -v "$check_cmd" &>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

get_component_version() {
    local name="$1"
    local type
    type=$(get_component_type "$name")
    
    case "$type" in
        git)
            local path
            path=$(get_component_path "$name")
            if [[ -d "$path/.git" ]]; then
                (cd "$path" && git describe --tags --always 2>/dev/null) || \
                (cd "$path" && git rev-parse --short HEAD 2>/dev/null) || \
                echo "unknown"
            else
                echo "not installed"
            fi
            ;;
        script)
            local check_cmd
            check_cmd=$(get_component_check_cmd "$name")
            if [[ -n "$check_cmd" ]] && command -v "$check_cmd" &>/dev/null; then
                $check_cmd --version 2>/dev/null | head -n1 || echo "installed"
            else
                echo "not installed"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

check_command() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        log_error "Required command '$cmd' not found"
        return 1
    fi
    return 0
}

get_os_type() {
    local os
    os="$(uname -s)"
    case "$os" in
        Linux)
            if [[ -f /etc/os-release ]]; then
                # shellcheck disable=SC1091
                source /etc/os-release
                echo "linux:$ID"
            else
                echo "linux:unknown"
            fi
            ;;
        Darwin)
            echo "darwin:macos"
            ;;
        *)
            echo "unsupported:$os"
            ;;
    esac
}

#-------------------------------------------------------------------------------
# Pre-flight Checks
#-------------------------------------------------------------------------------
preflight_checks() {
    log_info "Running pre-flight checks..."
    
    local errors=0
    
    # Check required commands
    log_debug "Checking required commands..."
    for cmd in curl git sed; do
        if ! check_command "$cmd"; then
            ((errors++))
        fi
    done
    
    # Check network connectivity
    log_debug "Checking network connectivity..."
    if ! curl -s --connect-timeout 5 https://github.com &>/dev/null; then
        log_error "Network connectivity check failed"
        ((errors++))
    fi
    
    # Check disk space (require at least 500MB)
    log_debug "Checking disk space..."
    local available_space
    available_space=$(df -k "$HOME" | awk 'NR==2 {print $4}')
    if [[ "$available_space" -lt 512000 ]]; then
        log_error "Insufficient disk space. Need at least 500MB"
        ((errors++))
    fi
    
    # Check HOME directory is writable
    if [[ ! -w "$HOME" ]]; then
        log_error "HOME directory ($HOME) is not writable"
        ((errors++))
    fi
    
    if [[ "$errors" -gt 0 ]]; then
        log_error "Pre-flight checks failed with $errors error(s)"
        return 1
    fi
    
    log_info "Pre-flight checks passed"
    return 0
}

#-------------------------------------------------------------------------------
# Package Installation
#-------------------------------------------------------------------------------
install_packages_linux() {
    local distro="$1"
    
    log_info "Installing packages for $distro..."
    
    case "$distro" in
        ubuntu|debian)
            if [[ "$DRY_RUN" == true ]]; then
                log_info "[DRY-RUN] Would run: sudo apt update && sudo apt install -y git curl zsh tmux"
                return 0
            fi
            
            sudo apt update || {
                log_error "Failed to update package lists"
                return 1
            }
            
            sudo apt install -y git curl zsh tmux || {
                log_error "Failed to install packages"
                return 1
            }
            ;;
        fedora)
            if [[ "$DRY_RUN" == true ]]; then
                log_info "[DRY-RUN] Would run: sudo dnf install -y git curl zsh tmux"
                return 0
            fi
            
            sudo dnf install -y git curl zsh tmux || {
                log_error "Failed to install packages"
                return 1
            }
            ;;
        arch|manjaro)
            if [[ "$DRY_RUN" == true ]]; then
                log_info "[DRY-RUN] Would run: sudo pacman -S --noconfirm git curl zsh tmux"
                return 0
            fi
            
            sudo pacman -S --noconfirm git curl zsh tmux || {
                log_error "Failed to install packages"
                return 1
            }
            ;;
        *)
            log_warn "Unsupported Linux distribution: $distro"
            log_warn "Attempting to continue without system packages..."
            return 0
            ;;
    esac
    
    # Set zsh as default shell
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would run: sudo chsh -s /bin/zsh"
    else
        sudo chsh -s /bin/zsh || {
            log_warn "Failed to set zsh as default shell"
        }
    fi
}

install_packages_macos() {
    log_info "Installing packages for macOS..."
    
    # Check if Homebrew is installed
    if ! command -v brew &>/dev/null; then
        log_error "Homebrew not found. Please install Homebrew first:"
        log_error "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would run: brew install tmux"
        return 0
    fi
    
    brew install tmux || {
        log_error "Failed to install tmux"
        return 1
    }
}

#-------------------------------------------------------------------------------
# Component Management (Unified for all types)
#-------------------------------------------------------------------------------
install_component() {
    local name="$1"
    local type
    local source
    local path
    
    # Validate component exists
    if [[ -z "${COMPONENTS[$name]}" ]]; then
        log_error "Unknown component: $name"
        return 1
    fi
    
    type=$(get_component_type "$name")
    source=$(get_component_source "$name")
    
    # Check if already installed
    if is_component_installed "$name"; then
        log_info "$name already installed, skipping..."
        return 0
    fi
    
    log_info "Installing $name..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would install $name ($type) from $source"
        return 0
    fi
    
    case "$type" in
        git)
            path=$(get_component_path "$name")
            # Ensure parent directory exists
            mkdir -p "$(dirname "$path")" || {
                log_error "Failed to create parent directory for $name"
                return 1
            }
            if git clone --depth 1 "$source" "$path" 2>/dev/null; then
                log_info "$name installed successfully"
                return 0
            else
                log_error "Failed to clone $name"
                return 1
            fi
            ;;
        script)
            # Script-based installation (like starship)
            curl -sS "$source" | sh -s -- --yes || {
                log_error "Failed to install $name via script"
                return 1
            }
            log_info "$name installed successfully"
            return 0
            ;;
        *)
            log_error "Unknown component type: $type"
            return 1
            ;;
    esac
}

update_component() {
    local name="$1"
    local type
    local path
    local source
    
    # Validate component exists
    if [[ -z "${COMPONENTS[$name]}" ]]; then
        log_error "Unknown component: $name"
        return 1
    fi
    
    type=$(get_component_type "$name")
    
    # Check if installed
    if ! is_component_installed "$name"; then
        log_warn "$name is not installed"
        return 0
    fi
    
    log_info "Updating $name..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would update $name"
        return 0
    fi
    
    case "$type" in
        git)
            path=$(get_component_path "$name")
            (cd "$path" && git pull --rebase --autostash) || {
                log_warn "Failed to update $name, may already be up to date"
            }
            return 0
            ;;
        script)
            # Script-based components need reinstall for update
            source=$(get_component_source "$name")
            log_info "Reinstalling $name for update..."
            curl -sS "$source" | sh -s -- --yes || {
                log_error "Failed to update $name"
                return 1
            }
            log_info "$name updated successfully"
            return 0
            ;;
        *)
            log_error "Unknown component type: $type"
            return 1
            ;;
    esac
}

install_components() {
    local failed=0
    
    for name in "${!COMPONENTS[@]}"; do
        # Skip starship if flag is set
        if [[ "$name" == "starship" && "$SKIP_STARSHIP" == true ]]; then
            continue
        fi
        
        # Skip oh-my-zsh (handled separately)
        if [[ "$name" == "oh-my-zsh" ]]; then
            continue
        fi
        
        # Skip plugins if flag is set
        if [[ "$SKIP_PLUGINS" == true && "$name" != "starship" ]]; then
            continue
        fi
        
        if ! install_component "$name"; then
            ((failed++))
        fi
    done
    
    if [[ "$failed" -gt 0 ]]; then
        log_warn "$failed component(s) failed to install"
        return 1
    fi
    
    return 0
}

update_components() {
    local target="$1"
    local failed=0
    
    if [[ -n "$target" ]]; then
        # Update specific component
        update_component "$target"
        return $?
    fi
    
    # Update all installed components
    for name in "${!COMPONENTS[@]}"; do
        if is_component_installed "$name"; then
            if ! update_component "$name"; then
                ((failed++))
            fi
        else
            log_debug "$name not installed, skipping update"
        fi
    done
    
    if [[ "$failed" -gt 0 ]]; then
        log_warn "$failed component(s) failed to update"
        return 1
    fi
    
    return 0
}

show_status() {
    local cyan='\033[0;36m'
    local green='\033[0;32m'
    local yellow='\033[0;33m'
    local nc='\033[0m'
    
    echo -e "\n${cyan}Component Status:${nc}"
    printf "%-25s %-15s %s\n" "NAME" "STATUS" "VERSION"
    printf "%-25s %-15s %s\n" "----" "------" "-------"
    
    for name in $(echo "${!COMPONENTS[@]}" | tr ' ' '\n' | sort); do
        local status
        local version
        
        if is_component_installed "$name"; then
            status="${green}installed${nc}"
            version=$(get_component_version "$name")
        else
            status="${yellow}not installed${nc}"
            version="-"
        fi
        
        printf "%-25s %b %-15s\n" "$name" "$status" "$version"
    done
    
    echo ""
}

list_components() {
    local cyan='\033[0;36m'
    local nc='\033[0m'
    
    printf "\n${cyan}Available Components:${nc}\n\n"
    
    for name in $(echo "${!COMPONENTS[@]}" | tr ' ' '\n' | sort); do
        local desc
        local type
        desc=$(get_component_desc "$name")
        type=$(get_component_type "$name")
        printf "  %-25s [%s] %s\n" "$name" "$type" "$desc"
    done
    
    echo ""
    echo "Usage:"
    echo "  $SCRIPT_NAME install              # Install all components"
    echo "  $SCRIPT_NAME update               # Update all installed components"
    echo "  $SCRIPT_NAME update <name>        # Update specific component"
    echo ""
}

#-------------------------------------------------------------------------------
# Oh My Zsh Installation (special handling)
#-------------------------------------------------------------------------------
install_ohmyzsh() {
    log_info "Installing Oh My Zsh..."
    
    # Check if already installed
    if [[ -d "$OHMYZSH_DIR" ]]; then
        log_info "Oh My Zsh already installed, skipping..."
        return 0
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would install Oh My Zsh"
        return 0
    fi
    
    # Clone Oh My Zsh
    if ! git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$OHMYZSH_DIR" 2>/dev/null; then
        log_error "Failed to clone Oh My Zsh"
        return 1
    fi
    
    # Create default .zshrc if it doesn't exist
    if [[ ! -f "$HOME/.zshrc" ]]; then
        cp "$OHMYZSH_DIR/templates/zshrc.zsh-template" "$HOME/.zshrc"
    fi
    
    log_info "Oh My Zsh installed successfully"
    return 0
}

#-------------------------------------------------------------------------------
# Zshrc Configuration
#-------------------------------------------------------------------------------
configure_zshrc() {
    log_info "Configuring .zshrc..."
    
    local zshrc="$HOME/.zshrc"
    
    # Check if .zshrc exists
    if [[ ! -f "$zshrc" ]]; then
        log_error ".zshrc not found. Oh My Zsh installation may have failed."
        return 1
    fi
    
    # Create backup
    if [[ "$DRY_RUN" != true ]]; then
        cp "$zshrc" "$zshrc.backup.$(date +%Y%m%d%H%M%S)" || {
            log_warn "Failed to create .zshrc backup"
        }
    fi
    
    # Update plugins list
    local plugins_str="plugins=(${DEFAULT_PLUGINS[*]})"
    log_debug "Setting plugins: $plugins_str"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would update plugins in $zshrc"
    else
        # Check if plugins line exists
        if grep -q '^plugins=' "$zshrc"; then
            sed -i.bak "s/^plugins=.*/$plugins_str/" "$zshrc" || {
                log_error "Failed to update plugins in .zshrc"
                return 1
            }
            rm -f "$zshrc.bak"  # Clean up sed backup
        else
            # Append plugins line
            echo "$plugins_str" >> "$zshrc"
        fi
    fi
    
    # Disable magic functions (optional)
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would disable Oh My Zsh magic functions"
    else
        if grep -q '^# DISABLE_MAGIC_FUNCTIONS=' "$zshrc"; then
            sed -i.bak 's/^# DISABLE_MAGIC_FUNCTIONS=/DISABLE_MAGIC_FUNCTIONS=/' "$zshrc"
            rm -f "$zshrc.bak"
        elif ! grep -q '^DISABLE_MAGIC_FUNCTIONS=' "$zshrc"; then
            echo 'DISABLE_MAGIC_FUNCTIONS="true"' >> "$zshrc"
        fi
    fi
    
    # Add Starship initialization (if not skipped)
    if [[ "$SKIP_STARSHIP" != true ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            log_info "[DRY-RUN] Would add Starship initialization to $zshrc"
        else
            if ! grep -q 'starship init zsh' "$zshrc"; then
                cat >> "$zshrc" << 'EOF'

# Starship prompt
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi
EOF
                log_debug "Added Starship initialization"
            else
                log_debug "Starship initialization already present"
            fi
        fi
    fi
    
    # Add zsh-completions fpath
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would add zsh-completions to fpath"
    else
        if ! grep -q 'zsh-completions/src' "$zshrc"; then
            cat >> "$zshrc" << 'EOF'

# zsh-completions
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi
EOF
            log_debug "Added zsh-completions configuration"
        else
            log_debug "zsh-completions already configured"
        fi
    fi
    
    log_info ".zshrc configured successfully"
    return 0
}

#-------------------------------------------------------------------------------
# Main Installation Function
#-------------------------------------------------------------------------------
install() {
    log_info "Starting Zsh environment installation..."
    log_info "Version: $SCRIPT_VERSION"
    
    # Get OS type
    local os_info
    os_info=$(get_os_type)
    local os_type="${os_info%%:*}"
    local os_distro="${os_info#*:}"
    
    log_info "Detected OS: $os_type ($os_distro)"
    
    if [[ "$os_type" == "unsupported" ]]; then
        log_error "Unsupported operating system: $os_distro"
        return $EXIT_OS_UNSUPPORTED
    fi
    
    # Install system packages
    case "$os_type" in
        linux)
            install_packages_linux "$os_distro" || return $EXIT_INSTALL_FAILED
            ;;
        darwin)
            install_packages_macos || return $EXIT_INSTALL_FAILED
            ;;
    esac
    
    # Install Oh My Zsh (core framework)
    install_ohmyzsh || return $EXIT_INSTALL_FAILED
    
    # Install all registered components (plugins + starship)
    install_components || return $EXIT_INSTALL_FAILED
    
    # Configure Starship preset (if installed)
    if [[ "$SKIP_STARSHIP" != true ]] && command -v starship &>/dev/null; then
        local config_dir="$HOME/.config"
        local starship_config="$config_dir/starship.toml"
        if [[ ! -f "$starship_config" ]]; then
            mkdir -p "$config_dir"
            curl -fsSL "https://raw.githubusercontent.com/starship/starship/master/presets/gruvbox-rainbow.toml" \
                -o "$starship_config" 2>/dev/null || log_warn "Failed to download Starship preset"
        fi
        
        # Configure conda settings in starship.toml
        if [[ -f "$starship_config" ]]; then
            # Add or update [conda] section with ignore_base = false
            if grep -q '^\[conda\]' "$starship_config"; then
                # [conda] section exists, update ignore_base
                if grep -q '^ignore_base' "$starship_config"; then
                    sed -i.bak 's/^ignore_base.*/ignore_base = false/' "$starship_config"
                    rm -f "$starship_config.bak"
                else
                    # Add ignore_base after [conda]
                    sed -i.bak '/^\[conda\]/a ignore_base = false' "$starship_config"
                    rm -f "$starship_config.bak"
                fi
            else
                # Add [conda] section at the end
                echo '' >> "$starship_config"
                echo '[conda]' >> "$starship_config"
                echo 'ignore_base = false' >> "$starship_config"
            fi
            log_debug "Configured conda settings in starship.toml"
        fi
        
        # Configure conda to not change prompt
        if command -v conda &>/dev/null; then
            conda config --set changeps1 False 2>/dev/null || log_debug "Conda changeps1 already set or conda not configured"
        fi
    fi
    
    # Configure .zshrc
    configure_zshrc || return $EXIT_INSTALL_FAILED
    
    log_info "Installation completed successfully!"
    log_info "Please restart your shell or run: source $HOME/.zshrc"
    
    return $EXIT_SUCCESS
}

#-------------------------------------------------------------------------------
# Cleanup Handler
#-------------------------------------------------------------------------------
cleanup() {
    local exit_code=$?
    
    if [[ "$exit_code" -ne 0 ]]; then
        log_warn "Installation exited with error code: $exit_code"
        log_warn "You may need to clean up partial installation manually"
    fi
    
    exit "$exit_code"
}

#-------------------------------------------------------------------------------
# Main Entry Point
#-------------------------------------------------------------------------------
main() {
    # Set up cleanup handler
    trap cleanup EXIT
    
    # Parse options (stops at first non-option argument)
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit $EXIT_SUCCESS
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            --skip-plugins)
                SKIP_PLUGINS=true
                shift
                ;;
            --skip-starship)
                SKIP_STARSHIP=true
                shift
                ;;
            --)
                shift
                break
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                exit $EXIT_GENERAL_ERROR
                ;;
            *)
                # First non-option argument is the command
                break
                ;;
        esac
    done
    
    # Get command (default: install)
    local command="${1:-install}"
    local command_arg="${2:-}"
    
    # Show banner for install command only
    if [[ "$command" == "install" && "$QUIET" != true ]]; then
        cat << BANNER
╔══════════════════════════════════════════════════════════╗
║           Zsh Development Environment Installer          ║
║                     Version $SCRIPT_VERSION                        ║
╚══════════════════════════════════════════════════════════╝
BANNER
    fi
    
    # Execute command
    case "$command" in
        install)
            # Run pre-flight checks only for install
            preflight_checks || exit $EXIT_DEPENDENCY_MISSING
            install || exit $?
            ;;
        update)
            # Pre-flight for update too (need network, git, etc.)
            preflight_checks || exit $EXIT_DEPENDENCY_MISSING
            update_components "$command_arg" || exit $?
            log_info "Update completed!"
            ;;
        status)
            show_status
            ;;
        list)
            list_components
            ;;
        *)
            log_error "Unknown command: $command"
            usage
            exit $EXIT_GENERAL_ERROR
            ;;
    esac
    
    exit $EXIT_SUCCESS
}

# Run main function
main "$@"
