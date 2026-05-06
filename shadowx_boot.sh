#!/usr/bin/env bash
# =============================================================================
#  ShadowX — Elite Access Terminal for Termux
#  Version : 3.3
#  License : GNU General Public License v3.0
#  GitHub  : https://github.com/YOUR-USERNAME/shadowx
#
#  USAGE:
#    bash shadowx_boot.sh --install     # install & enable auto-boot
#    bash shadowx_boot.sh --uninstall   # remove everything cleanly
#    bash shadowx_boot.sh --update      # force update from GitHub
#    bash shadowx_boot.sh --config      # re-run setup wizard
#    bash shadowx_boot.sh --theme       # change color theme
#
#  ONE-LINE INSTALL:
#    curl -sL https://raw.githubusercontent.com/YOUR-USERNAME/shadowx/main/shadowx_boot.sh \
#      -o ~/shadowx_boot.sh && chmod +x ~/shadowx_boot.sh && bash ~/shadowx_boot.sh --install
# =============================================================================

# ── Internals ────────────────────────────────────
VERSION="3.3"
INSTALL_PATH="$HOME/shadowx_boot.sh"
CONFIG_FILE="$HOME/.shadowxrc"
BASHRC="$HOME/.bashrc"
GITHUB_USER="YOUR-USERNAME"
GITHUB_REPO="shadowx"
RAW_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/main/shadowx_boot.sh"

# ── Defaults (overridden by ~/.shadowxrc) ────────
BOSS_NAME="Boss"
ACCESS_CODE="shadowx"
THEME="green"

# ── Base Colors (non-themed) ─────────────────────
R='\033[0m'
RD='\033[1;31m'
YL='\033[1;33m'
WH='\033[1;37m'
DIM='\033[2m'
BOLD='\033[1m'
# G, DG set by load_theme()

hide_cursor() { printf '\033[?25l'; }
show_cursor() { printf '\033[?25h'; }
trap 'show_cursor; stty echo 2>/dev/null' EXIT INT TERM

# =============================================================================
#  THEME
# =============================================================================
load_theme() {
  case "${THEME:-green}" in
    red)   G='\033[1;31m'; DG='\033[0;31m'; CY='\033[1;33m' ;;
    blue)  G='\033[1;34m'; DG='\033[0;34m'; CY='\033[1;36m' ;;
    cyan)  G='\033[1;36m'; DG='\033[0;36m'; CY='\033[1;35m' ;;
    green|*) G='\033[1;32m'; DG='\033[0;32m'; CY='\033[1;36m' ;;
  esac
}

select_theme() {
  clear; echo; print_logo
  printf "  ${YL}Choose a theme:${R}\n\n"
  printf "  \033[1;32m[1] Green\033[0m  —  Classic hacker\n"
  printf "  \033[1;31m[2] Red\033[0m    —  Danger mode\n"
  printf "  \033[1;34m[3] Blue\033[0m   —  Ice cold\n"
  printf "  \033[1;36m[4] Cyan\033[0m   —  Neon ghost\n"
  echo
  printf "  ${YL}Choice [1-4]: ${WH}"
  read -r tc; printf "%b\n" "$R"
  case "$tc" in
    2) THEME="red" ;; 3) THEME="blue" ;; 4) THEME="cyan" ;; *) THEME="green" ;;
  esac
  load_theme
  save_config
  printf "  ${G}[+] Theme set to: ${WH}%s${R}\n\n" "$THEME"
  sleep 1
}

# =============================================================================
#  SCREEN DETECTION
# =============================================================================
detect_screen() {
  COLS=$(tput cols 2>/dev/null || echo 50)
  if (( COLS >= 70 )); then
    PANEL_INNER=52   # desktop / landscape
  elif (( COLS >= 50 )); then
    PANEL_INNER=42   # tablet / wide mobile
  else
    PANEL_INNER=36   # phone portrait
  fi
  # quote box inner width
  QUOTE_W=$(( PANEL_INNER - 2 ))
}

repeat_char() { printf '%*s' "$1" '' | tr ' ' "$2"; }

# =============================================================================
#  CONFIG
# =============================================================================
save_config() {
  cat > "$CONFIG_FILE" << CONF
BOSS_NAME="$BOSS_NAME"
ACCESS_CODE="$ACCESS_CODE"
THEME="$THEME"
CONF
  chmod 600 "$CONFIG_FILE"
}

load_config() {
  if [ -f "$CONFIG_FILE" ]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
  else
    first_run_setup
  fi
  load_theme
}

first_run_setup() {
  clear; echo; print_logo
  typewriter "  First run detected. Let's set up ShadowX." "$G" 0.03
  echo; scan_line; echo

  printf "  ${YL}[?] Your name: ${WH}"
  read -r BOSS_NAME
  [ -z "$BOSS_NAME" ] && BOSS_NAME="Boss"

  local c1 c2
  while true; do
    printf "  ${YL}[?] Set access code: ${WH}"
    stty -echo 2>/dev/null; read -r c1; stty echo 2>/dev/null; printf "%b\n" "$R"
    printf "  ${YL}[?] Confirm code:     ${WH}"
    stty -echo 2>/dev/null; read -r c2; stty echo 2>/dev/null; printf "%b\n" "$R"
    if [ "$c1" = "$c2" ] && [ -n "$c1" ]; then
      ACCESS_CODE="$c1"; break
    fi
    printf "  ${RD}[!] Codes don't match or empty. Try again.${R}\n\n"
  done

  echo
  select_theme
  save_config

  printf "  ${G}[+] Setup complete! Welcome, %s.${R}\n" "$BOSS_NAME"
  sleep 1; clear
}

# =============================================================================
#  INSTALLER
# =============================================================================
do_install() {
  clear; echo
  printf "${G}${BOLD}  ShadowX Installer v${VERSION}${R}\n"
  printf "${DG}  --------------------------------${R}\n\n"

  local src
  src="$(cd "$(dirname "$0")" 2>/dev/null && pwd)/$(basename "$0")"
  if [ "$src" != "$INSTALL_PATH" ]; then
    cp "$src" "$INSTALL_PATH" && chmod +x "$INSTALL_PATH"
    printf "  ${G}[+] Installed to: ${WH}%s${R}\n" "$INSTALL_PATH"
  else
    chmod +x "$INSTALL_PATH"
    printf "  ${G}[+] Already at home. Permissions set.${R}\n"
  fi

  local marker="# shadowx_autoboot"
  if ! grep -q "$marker" "$BASHRC" 2>/dev/null; then
    printf "\n%s\nbash \"%s\"\n" "$marker" "$INSTALL_PATH" >> "$BASHRC"
    printf "  ${G}[+] Auto-boot added to .bashrc${R}\n"
  else
    printf "  ${CY}[i] Auto-boot already configured${R}\n"
  fi

  echo
  printf "  ${G}[+] Done! Close and reopen Termux to start.${R}\n\n"
  exit 0
}

do_uninstall() {
  echo
  printf "  ${YL}[*] Uninstalling ShadowX...${R}\n\n"
  sed -i '/shadowx_autoboot/,+1d' "$BASHRC" 2>/dev/null
  printf "  ${G}[+] Removed from .bashrc${R}\n"
  rm -f "$CONFIG_FILE" && printf "  ${G}[+] Config deleted: %s${R}\n" "$CONFIG_FILE"
  if [ "$(realpath "$0" 2>/dev/null)" = "$INSTALL_PATH" ] || [ "$0" = "$INSTALL_PATH" ]; then
    rm -f "$INSTALL_PATH" && printf "  ${G}[+] Script deleted: %s${R}\n" "$INSTALL_PATH"
  fi
  printf "\n  ${G}[+] ShadowX fully removed. Goodbye.${R}\n\n"
  exit 0
}

do_update() {
  printf "\n  ${G}[*] Checking for updates...${R}\n"
  if ! command -v curl &>/dev/null; then
    printf "  ${RD}[!] curl not found. Run: pkg install curl${R}\n\n"; exit 1
  fi
  local latest
  latest=$(curl -sf --max-time 6 "$RAW_URL" 2>/dev/null | grep '^VERSION=' | head -1 | tr -d '"' | cut -d= -f2)
  if [ -z "$latest" ]; then
    printf "  ${RD}[!] Could not reach GitHub. Check connection.${R}\n\n"; exit 1
  fi
  if [ "$latest" = "$VERSION" ]; then
    printf "  ${G}[+] Already on latest version (v%s).${R}\n\n" "$VERSION"; exit 0
  fi
  printf "  ${YL}[!] New version available: v%s -> v%s${R}\n" "$VERSION" "$latest"
  printf "  ${YL}[?] Update now? [Y/n]: ${WH}"; read -r upd; printf "%b\n" "$R"
  case "${upd,,}" in
    ""|y|yes)
      curl -sL "$RAW_URL" -o "$INSTALL_PATH" && chmod +x "$INSTALL_PATH"
      printf "  ${G}[+] Updated to v%s. Restarting...${R}\n\n" "$latest"
      sleep 1; exec bash "$INSTALL_PATH" ;;
    *) printf "  ${CY}[i] Update skipped.${R}\n\n" ;;
  esac
  exit 0
}

case "${1:-}" in
  --install)   do_install ;;
  --uninstall) do_uninstall ;;
  --update)    do_update ;;
  --config)    load_config; first_run_setup; exit 0 ;;
  --theme)     print_logo() { :; }; load_config; select_theme; save_config; exit 0 ;;
esac

# =============================================================================
#  VISUAL HELPERS
# =============================================================================
typewriter() {
  local text="$1" color="${2:-$G}" delay="${3:-0.03}"
  printf "%b" "$color"
  for ((i=0; i<${#text}; i++)); do printf "%s" "${text:$i:1}"; sleep "$delay"; done
  printf "%b\n" "$R"
}

glitch_text() {
  local text="$1" color="${2:-$RD}"
  local chars='@#$%&?!<>|/\^~*='
  for ((r=0; r<4; r++)); do
    local c=""
    for ((i=0; i<${#text}; i++)); do
      (( RANDOM % 3 == 0 )) \
        && c+="${chars:$(( RANDOM % ${#chars} )):1}" \
        || c+="${text:$i:1}"
    done
    printf "\r%b%s%b" "$color" "$c" "$R"; sleep 0.06
  done
  printf "\r%b%s%b\n" "$G" "$text" "$R"
}

spinner() {
  local pid=$1 msg="$2" f=('-' '\' '|' '/') i=0
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r${CY} [${f[$((i++ % 4))]}] ${G}%s${R}   " "$msg"; sleep 0.08
  done
  printf "\r${G} [+] ${WH}%s${R}              \n" "$msg"
}

progress_bar() {
  local label="$1" dur="${2:-1.0}" w=20
  printf "  ${DG}%-22s${R} [" "$label"
  local d; d=$(awk "BEGIN{printf \"%.4f\",$dur/$w}")
  for ((i=0;i<w;i++)); do printf "${G}#${R}"; sleep "$d"; done
  printf "] ${G}OK${R}\n"
}

hex_line() {
  local line=""
  for ((i=0;i<44;i++)); do
    line+=$(printf '%X' $(( RANDOM % 16 )))
    (( i%4==3 )) && line+=" "
  done
  printf "${DG}${DIM}  %s${R}\n" "$line"
}

scan_line() {
  printf "  ${CY}${DIM}"
  for ((i=0; i<PANEL_INNER+4; i++)); do printf "-"; sleep 0.006; done
  printf "${R}\n"
}

# =============================================================================
#  LOGO
# =============================================================================
print_logo() {
  printf "%b\n" "$G"
  printf '   ____  _               _               __  __\n'
  printf '  / ___|| |__   __ _  __| | _____      _\ \/ /\n'
  printf "  \\___ \\| '_ \\ / _\` |/ _\` |/ _ \\ \\ /\\ / / \\  /\n"
  printf '   ___) | | | | (_| | (_| | (_) \ V  V / /  \/\n'
  printf '  |____/|_| |_|\__,_|\__,_|\___/ \_/\_/ /_/\_\\\n'
  printf "%b  %s\n" "$DG" "$(repeat_char $((PANEL_INNER+6)) '-')"
  printf "%b%b  E L I T E   A C C E S S   T E R M I N A L\n" "$DIM" "$CY"
  printf "%b  %s%b\n\n" "$DG" "$(repeat_char $((PANEL_INNER+6)) '-')" "$R"
}

# =============================================================================
#  STATUS PANEL
# =============================================================================
panel_row() {
  local key="$1" val="$2"
  local vmax=$(( PANEL_INNER - 12 ))
  [ ${#val} -gt $vmax ] && val="${val:0:$((vmax-2))}.."
  local vpad=$(( vmax - ${#val} ))
  printf "  ${G}|${R}  ${DG}%-9s${R} ${G}%s%*s |${R}\n" "$key" "$val" "$vpad" ""
}

print_panel() {
  local ts host border title
  ts="$(date '+%H:%M:%S // %F')"
  host="$(hostname -s 2>/dev/null || echo SHADOWNODE)"
  border="$(repeat_char $((PANEL_INNER+2)) '-')"
  title="SHADOWX v${VERSION}  ::  KALI CORE"
  local tpad=$(( (PANEL_INNER + 2 - ${#title}) / 2 ))
  local trpad=$(( PANEL_INNER + 2 - ${#title} - tpad ))

  printf "  ${G}+%s+${R}\n" "$border"
  printf "  ${G}|%*s%s%*s|${R}\n" "$tpad" "" "$title" "$trpad" ""
  printf "  ${G}+%s+${R}\n" "$border"
  panel_row "Status"  "ONLINE"
  panel_row "Mode"    "ELITE / UNRESTRICTED"
  panel_row "Uplink"  "ENCRYPTED AES-256-GCM"
  panel_row "Proxy"   "TOR + VPN CHAIN ACTIVE"
  panel_row "Time"    "$ts"
  panel_row "Node"    "$host"
  panel_row "Shell"   "${SHELL##*/} @ Termux"
  panel_row "User"    "$BOSS_NAME"
  panel_row "Theme"   "$THEME"
  printf "  ${G}+%s+${R}\n" "$border"
}

# =============================================================================
#  HACKER QUOTES
# =============================================================================
show_quote() {
  local quotes=(
    "In the middle of chaos lies opportunity.|Sun Tzu"
    "The quieter you become, the more you can hear.|Ram Dass"
    "Security is a process, not a product.|Bruce Schneier"
    "The only truly secure system is powered off.|Gene Spafford"
    "Every system has a vulnerability. Find it first.|Unknown"
    "There is no patch for human stupidity.|Unknown"
    "Complexity is the enemy of security.|Bruce Schneier"
    "Knowledge is power. Guard it.|Unknown"
    "Passwords are like underwear — change them often.|Unknown"
    "It takes 20 years to build reputation, minutes to ruin it.|Stephane Nappo"
    "The more connected we are, the more vulnerable we become.|Unknown"
    "To hack is to question, explore, and understand.|Unknown"
    "Data is the new oil. Protect yours.|Unknown"
    "Never trust, always verify.|Zero Trust Principle"
    "Move in silence. Speak only when it is checkmate.|Unknown"
    "The best hackers are invisible.|Unknown"
    "Offense informs defense.|Unknown"
    "Privacy is not a privilege. It is a right.|Unknown"
    "In the shadows, we see everything.|ShadowX"
    "The quieter the system, the deadlier the threat.|Unknown"
  )

  local pick="${quotes[$((RANDOM % ${#quotes[@]}))]}"
  local text="${pick%%|*}" author="${pick##*|}"
  local inner=$((QUOTE_W))
  local border="$(repeat_char $((inner+2)) '-')"

  echo
  printf "  ${DG}${DIM}+%s+${R}\n" "$border"
  printf "  ${DG}${DIM}|%*s|${R}\n" $((inner+2)) ""

  # word wrap
  local words=($text) line="" wrapped=()
  for word in "${words[@]}"; do
    if (( ${#line} + ${#word} + 1 > inner )); then
      wrapped+=("$line"); line="$word"
    else
      [ -n "$line" ] && line+=" $word" || line="$word"
    fi
  done
  [ -n "$line" ] && wrapped+=("$line")

  for l in "${wrapped[@]}"; do
    local lp=$(( (inner + 2 - ${#l}) / 2 ))
    local rp=$(( inner + 2 - ${#l} - lp ))
    printf "  ${DG}${DIM}|${R}%*s${CY}%s${R}%*s${DG}${DIM}|${R}\n" "$lp" "" "$l" "$rp" ""
  done

  printf "  ${DG}${DIM}|%*s|${R}\n" $((inner+2)) ""
  local atxt="-- ${author}"
  local ap=$(( (inner + 2 - ${#atxt}) / 2 ))
  local arp=$(( inner + 2 - ${#atxt} - ap ))
  printf "  ${DG}${DIM}|${R}%*s${YL}%s${R}%*s${DG}${DIM}|${R}\n" "$ap" "" "$atxt" "$arp" ""
  printf "  ${DG}${DIM}|%*s|${R}\n" $((inner+2)) ""
  printf "  ${DG}${DIM}+%s+${R}\n" "$border"
  echo
}

# =============================================================================
#  AUTO-UPDATE CHECK (silent, non-blocking)
# =============================================================================
silent_update_check() {
  command -v curl &>/dev/null || return
  local latest
  latest=$(curl -sf --max-time 4 "$RAW_URL" 2>/dev/null | grep '^VERSION=' | head -1 | tr -d '"' | cut -d= -f2)
  [ -n "$latest" ] && [ "$latest" != "$VERSION" ] && \
    printf "  ${YL}[!] ShadowX v%s available! Run: bash ~/shadowx_boot.sh --update${R}\n\n" "$latest"
}

# =============================================================================
#  DENIED ANIMATION
# =============================================================================
denied_anim() {
  echo
  for ((i=0;i<4;i++)); do
    printf "\r${RD}${BOLD}  ## ACCESS DENIED ##${R}"; sleep 0.20
    printf "\r${DIM}  -- ACCESS DENIED --${R}";       sleep 0.20
  done; echo
  glitch_text "  [!!] SECURITY LOCKOUT INITIATED" "$RD"
  typewriter  "  [>>] Logging intrusion attempt..."  "$RD" 0.04
  typewriter  "  [>>] Tracing connection origin..."  "$RD" 0.04
  sleep 0.3
  typewriter  "  [>>] Session terminated."           "$RD" 0.05
  sleep 1.5
}

# =============================================================================
#  QUICK COMMAND MENU
# =============================================================================
quick_menu() {
  show_cursor
  local border="$(repeat_char $((PANEL_INNER+2)) '-')"
  while true; do
    clear; echo; print_logo
    printf "  ${G}${BOLD}+%s+${R}\n" "$border"
    printf "  ${G}${BOLD}|%-*s|${R}\n" $((PANEL_INNER+2)) "   SHADOWX  COMMAND  CENTER"
    printf "  ${G}${BOLD}+%s+${R}\n" "$border"
    printf "  ${G}|${R} ${CY}[1]${R} %-*s${G}|${R}\n" $((PANEL_INNER-1)) "Update packages    (pkg upgrade)"
    printf "  ${G}|${R} ${CY}[2]${R} %-*s${G}|${R}\n" $((PANEL_INNER-1)) "Check storage      (df -h)"
    printf "  ${G}|${R} ${CY}[3]${R} %-*s${G}|${R}\n" $((PANEL_INNER-1)) "Network info       (ip a)"
    printf "  ${G}|${R} ${CY}[4]${R} %-*s${G}|${R}\n" $((PANEL_INNER-1)) "Running processes  (top)"
    printf "  ${G}|${R} ${CY}[5]${R} %-*s${G}|${R}\n" $((PANEL_INNER-1)) "Memory usage       (free -h)"
    printf "  ${G}|${R} ${CY}[6]${R} %-*s${G}|${R}\n" $((PANEL_INNER-1)) "Installed packages"
    printf "  ${G}|${R} ${CY}[7]${R} %-*s${G}|${R}\n" $((PANEL_INNER-1)) "Ping test          (google.com)"
    printf "  ${G}|${R} ${CY}[8]${R} %-*s${G}|${R}\n" $((PANEL_INNER-1)) "Public IP address"
    printf "  ${G}|${R} ${CY}[9]${R} %-*s${G}|${R}\n" $((PANEL_INNER-1)) "New hacker quote"
    printf "  ${G}|${R} ${CY}[T]${R} %-*s${G}|${R}\n" $((PANEL_INNER-1)) "Change color theme"
    printf "  ${G}|${R} ${CY}[U]${R} %-*s${G}|${R}\n" $((PANEL_INNER-1)) "Check for updates"
    printf "  ${G}|${R} ${YL}[0]${R} %-*s${G}|${R}\n" $((PANEL_INNER-1)) "Exit to shell"
    printf "  ${G}${BOLD}+%s+${R}\n\n" "$border"
    printf "  ${YL}Select: ${WH}"; read -r choice; printf "%b\n" "$R"

    case "${choice,,}" in
      1) pkg upgrade ;;
      2) df -h ;;
      3) ip a 2>/dev/null || ifconfig 2>/dev/null ;;
      4) top ;;
      5) free -h 2>/dev/null || head -15 /proc/meminfo ;;
      6) pkg list-installed 2>/dev/null | head -40 ;;
      7) ping -c 4 google.com ;;
      8) curl -s https://api.ipify.org && echo ;;
      9) show_quote; printf "  ${DIM}[Press ENTER]${R}"; read -r; continue ;;
      t) select_theme; save_config; continue ;;
      u) do_update ;;
      0|q|exit) printf "\n  ${G}[>>] Entering shell. Stay sharp, %s.${R}\n\n" "$BOSS_NAME"; break ;;
      *) printf "  ${RD}[!] Invalid option.${R}\n" ;;
    esac
    echo; printf "  ${DIM}[Press ENTER to return to menu]${R}"; read -r
  done
}

# =============================================================================
#  BOOT SEQUENCE
# =============================================================================
shadowx_boot() {
  hide_cursor; clear

  # Load config and theme first
  detect_screen
  load_config

  # Hex noise intro
  printf "\n"
  for ((i=0;i<6;i++)); do hex_line; sleep 0.04; done
  sleep 0.2; clear

  # Logo + system info
  echo; print_logo
  printf "  ${DIM}${CY}[*] TIME : %s${R}\n" "$(date '+%Y-%m-%d %H:%M:%S %Z')"
  printf "  ${DIM}${CY}[*] HOST : %s${R}\n" "$(hostname -s 2>/dev/null || echo SHADOWNODE)"
  printf "  ${DIM}${CY}[*] KERN : %s${R}\n" "$(uname -r 2>/dev/null | cut -c1-26 || echo ?)"
  printf "  ${DIM}${CY}[*] ARCH : %s${R}\n" "$(uname -m 2>/dev/null || echo ?)"
  echo; scan_line

  # ── Auth ───────────────────────────────────────
  local attempts=0 pass max=3
  while (( attempts < max )); do
    echo
    printf "  ${YL}[?] ACCESS CODE REQUIRED${R}\n"
    printf "  ${DIM}${WH}%s${R}\n" "$(repeat_char 26 '-')"
    printf "  ${CY}>>> ${WH}"
    stty -echo 2>/dev/null; read -r pass; stty echo 2>/dev/null
    printf "%b\n" "$R"
    [ "$pass" = "$ACCESS_CODE" ] && break
    (( attempts++ ))
    local left=$(( max - attempts ))
    echo; glitch_text "  [X] AUTHENTICATION FAILED"
    (( left > 0 )) && \
      printf "  ${RD}[!] Attempts left: ${WH}%d/%d${R}\n" "$left" "$max" && sleep 0.7
  done

  # ── Lockout ────────────────────────────────────
  if [ "$pass" != "$ACCESS_CODE" ]; then
    denied_anim; clear; show_cursor
    kill -9 $$ 2>/dev/null; return 1
  fi

  # ── Granted ────────────────────────────────────
  echo
  printf "  ${G}${BOLD}[OK] IDENTITY VERIFIED — WELCOME, %s${R}\n" "$BOSS_NAME"
  sleep 0.4; echo; scan_line; echo
  printf "  ${WH}${BOLD}>> Initializing ShadowX environment...${R}\n\n"
  sleep 0.2

  progress_bar "Decrypting vault       " 0.6
  progress_bar "Loading core modules   " 0.5
  progress_bar "Injecting stealth layer" 0.7
  progress_bar "Routing through proxy  " 0.5
  progress_bar "Syncing shadow core    " 0.6
  progress_bar "Hardening session keys " 0.4
  progress_bar "Activating countermeas." 0.5
  echo

  (sleep 1.1) & spinner $! "Encrypted tunnel established"
  (sleep 0.9) & spinner $! "Secure filesystem mounted"
  (sleep 0.8) & spinner $! "Intrusion countermeasures armed"
  (sleep 0.7) & spinner $! "Neural signature synced"
  echo

  for ((i=0;i<4;i++)); do hex_line; sleep 0.05; done
  sleep 0.2; clear

  # ── Welcome ────────────────────────────────────
  echo; print_logo
  glitch_text "  >> Authenticating neural signature..."
  sleep 0.3
  typewriter "  >> Welcome back, ${BOSS_NAME}. All systems online." "$G" 0.04
  echo

  print_panel
  show_quote

  # Silent update check (runs in background, shows message if update found)
  silent_update_check

  scan_line; echo
  typewriter "  All systems nominal. Awaiting your command, ${BOSS_NAME}." "$DG" 0.03
  echo

  # ── Menu prompt ────────────────────────────────
  show_cursor
  printf "  ${YL}[?] Open command menu? ${WH}[Y/n]: ${R}"
  read -r open_menu
  case "${open_menu,,}" in
    ""|y|yes) quick_menu ;;
    *) printf "\n  ${G}[>>] Entering shell. Stay sharp, %s.${R}\n\n" "$BOSS_NAME" ;;
  esac
}

shadowx_boot
