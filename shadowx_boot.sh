#!/usr/bin/env bash
# ╔══════════════════════════════════════════════╗
# ║   SHADOWX v3.2 — TERMUX EDITION             ║
# ║   Fix: ASCII box, panel alignment, paths     ║
# ╚══════════════════════════════════════════════╝
#
#  INSTALL (run once in Termux):
#    cp shadowx_boot.sh ~/shadowx_boot.sh
#    chmod +x ~/shadowx_boot.sh
#    bash ~/shadowx_boot.sh --install
#
#  UNINSTALL:
#    bash ~/shadowx_boot.sh --uninstall

# ── CONFIG ───────────────────────────────────────
ACCESS_CODE="024955"
BOSS_NAME="Bhagya"
INSTALL_PATH="$HOME/shadowx_boot.sh"
BASHRC="$HOME/.bashrc"
VERSION="3.2"
# ─────────────────────────────────────────────────

# ── Colors ───────────────────────────────────────
R='\033[0m'
G='\033[1;32m'
DG='\033[0;32m'
CY='\033[1;36m'
RD='\033[1;31m'
YL='\033[1;33m'
WH='\033[1;37m'
DIM='\033[2m'
BOLD='\033[1m'

hide_cursor() { printf '\033[?25l'; }
show_cursor() { printf '\033[?25h'; }
trap 'show_cursor; stty echo 2>/dev/null' EXIT INT TERM

# ── Installer ────────────────────────────────────
do_install() {
  clear; echo
  printf "${G}${BOLD}  ShadowX Installer v${VERSION}${R}\n"
  printf "${DG}  --------------------------------${R}\n\n"

  # Always copy from wherever script is running
  local src
  src="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  if [ "$src" != "$INSTALL_PATH" ]; then
    cp "$src" "$INSTALL_PATH"
    chmod +x "$INSTALL_PATH"
    printf "  ${G}[+] Copied to: ${WH}%s${R}\n" "$INSTALL_PATH"
  else
    chmod +x "$INSTALL_PATH"
    printf "  ${G}[+] Already at: ${WH}%s${R}\n" "$INSTALL_PATH"
  fi

  local marker="# shadowx_autoboot"
  if ! grep -q "$marker" "$BASHRC" 2>/dev/null; then
    printf "\n%s\nbash \"%s\"\n" "$marker" "$INSTALL_PATH" >> "$BASHRC"
    printf "  ${G}[+] Auto-boot added to .bashrc${R}\n"
  else
    printf "  ${CY}[i] Auto-boot already set${R}\n"
  fi

  echo
  printf "  ${G}[+] Done! Close and reopen Termux.${R}\n\n"
  exit 0
}

do_uninstall() {
  echo
  sed -i '/shadowx_autoboot/,+1d' "$BASHRC" 2>/dev/null
  printf "  ${G}[+] Removed from .bashrc${R}\n\n"
  exit 0
}

case "${1:-}" in
  --install)   do_install ;;
  --uninstall) do_uninstall ;;
esac

# ── Helpers ──────────────────────────────────────
typewriter() {
  local text="$1" color="${2:-$G}" delay="${3:-0.03}"
  printf "%b" "$color"
  for ((i=0; i<${#text}; i++)); do
    printf "%s" "${text:$i:1}"; sleep "$delay"
  done
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
    printf "\r%b%s%b" "$color" "$c" "$R"
    sleep 0.06
  done
  printf "\r%b%s%b\n" "$G" "$text" "$R"
}

spinner() {
  local pid=$1 msg="$2"
  local f=('-' '\' '|' '/') i=0
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r${CY} [${f[$((i++ % 4))]}] ${G}%s${R}   " "$msg"
    sleep 0.08
  done
  printf "\r${G} [+] ${WH}%s${R}              \n" "$msg"
}

progress_bar() {
  local label="$1" dur="${2:-1.0}" w=22
  printf "  ${DG}%-24s${R} [" "$label"
  local d; d=$(awk "BEGIN{printf \"%.4f\",$dur/$w}")
  for ((i=0;i<w;i++)); do printf "${G}#${R}"; sleep "$d"; done
  printf "] ${G}DONE${R}\n"
}

hex_line() {
  local line=""
  for ((i=0;i<48;i++)); do
    line+=$(printf '%X' $(( RANDOM % 16 )))
    (( i%4==3 )) && line+=" "
  done
  printf "${DG}${DIM}  %s${R}\n" "$line"
}

scan_line() {
  printf "  ${CY}${DIM}"
  for ((i=0;i<46;i++)); do printf "-"; sleep 0.007; done
  printf "${R}\n"
}

# ── Logo (pure printf, no heredoc) ───────────────
print_logo() {
  printf "${G}\n"
  printf '   ____  _               _               __  __\n'
  printf '  / ___|| |__   __ _  __| | _____      _\ \/ /\n'
  printf "  \\___ \\| '_ \\ / _\` |/ _\` |/ _ \\ \\ /\\ / / \\  /\n"
  printf '   ___) | | | | (_| | (_| | (_) \ V  V / /  \/\n'
  printf '  |____/|_| |_|\__,_|\__,_|\___/ \_/\_/ /_/\_\\\n'
  printf "${DG}  ------------------------------------------------\n"
  printf "${DIM}${CY}       E L I T E   A C C E S S   T E R M I N A L\n"
  printf "${DG}  ------------------------------------------------${R}\n\n"
}

# ── Status panel row (ASCII safe) ────────────────
panel_row() {
  local key="$1" val="$2"
  # key=8 chars, val padded to 36 chars, total line = 50
  local vlen=${#val}
  local pad=$(( 36 - vlen ))
  (( pad < 0 )) && pad=0
  printf "  ${G}|${R}  ${DG}%-9s${R}${G}%-36s${R}%*s${G}|${R}\n" \
    "$key" "$val" "$pad" ""
}

print_panel() {
  local ts host
  ts="$(date '+%H:%M:%S // %F')"
  host="$(hostname -s 2>/dev/null || echo SHADOWNODE)"

  printf "  ${G}+--------------------------------------------------+${R}\n"
  printf "  ${G}|   SHADOWX v%-4s  ::  KALI CORE                  |${R}\n" "$VERSION"
  printf "  ${G}+--------------------------------------------------+${R}\n"
  printf "  ${G}|${R}  ${DG}%-9s${G}%-38s|${R}\n" "Status"  "ONLINE"
  printf "  ${G}|${R}  ${DG}%-9s${G}%-38s|${R}\n" "Mode"    "ELITE / UNRESTRICTED"
  printf "  ${G}|${R}  ${DG}%-9s${G}%-38s|${R}\n" "Uplink"  "ENCRYPTED  AES-256-GCM"
  printf "  ${G}|${R}  ${DG}%-9s${G}%-38s|${R}\n" "Proxy"   "TOR + VPN CHAIN ACTIVE"
  printf "  ${G}|${R}  ${DG}%-9s${G}%-38s|${R}\n" "Time"    "$ts"
  printf "  ${G}|${R}  ${DG}%-9s${G}%-38s|${R}\n" "Node"    "$host"
  printf "  ${G}|${R}  ${DG}%-9s${G}%-38s|${R}\n" "Shell"   "${SHELL##*/} @ Termux"
  printf "  ${G}|${R}  ${DG}%-9s${G}%-38s|${R}\n" "User"    "$BOSS_NAME"
  printf "  ${G}+--------------------------------------------------+${R}\n"
}

# ── Denied ───────────────────────────────────────
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

# ────────────────────────────────────────────────
#  HACKER QUOTES
# ────────────────────────────────────────────────
show_quote() {
  local quotes=(
    "The quieter you become, the more you can hear.|Ram Dass"
    "In the middle of chaos lies opportunity.|Sun Tzu"
    "Security is a process, not a product.|Bruce Schneier"
    "The only truly secure system is powered off.|Gene Spafford"
    "Every system has a vulnerability. Find it first.|Unknown"
    "There is no patch for human stupidity.|Unknown"
    "Complexity is the enemy of security.|Bruce Schneier"
    "Knowledge is power. Guard it.|Unknown"
    "Passwords are like underwear - change them often.|Unknown"
    "It takes 20 years to build a reputation and minutes to ruin it.|Stephane Nappo"
    "The more connected we are, the more vulnerable we become.|Unknown"
    "To hack is to question, explore, and understand.|Unknown"
    "Data is the new oil. Protect yours.|Unknown"
    "Never trust, always verify.|Zero Trust Principle"
    "The quieter the system, the deadlier the threat.|Unknown"
    "Offense informs defense.|Unknown"
    "Privacy is not a privilege. It is a right.|Unknown"
    "Move in silence. Only speak when it is time to say checkmate.|Unknown"
    "The best hackers are invisible.|Unknown"
    "In the shadows, we see everything.|ShadowX"
  )

  local pick="${quotes[$((RANDOM % ${#quotes[@]}))]}"
  local text="${pick%%|*}"
  local author="${pick##*|}"

  echo
  printf "  ${DG}${DIM}+----------------------------------------------+${R}\n"
  printf "  ${DG}${DIM}|${R}                                              ${DG}${DIM}|${R}\n"

  # word-wrap at 44 chars
  local words=($text) line=""
  local wrapped=()
  for word in "${words[@]}"; do
    if (( ${#line} + ${#word} + 1 > 44 )); then
      wrapped+=("$line"); line="$word"
    else
      [ -n "$line" ] && line+=" $word" || line="$word"
    fi
  done
  [ -n "$line" ] && wrapped+=("$line")

  for l in "${wrapped[@]}"; do
    local lpad=$(( (46 - ${#l}) / 2 ))
    local rpad=$(( 46 - lpad - ${#l} ))
    printf "  ${DG}${DIM}|${R}%*s${CY}%s${R}%*s${DG}${DIM}|${R}\n" "$lpad" "" "$l" "$rpad" ""
  done

  printf "  ${DG}${DIM}|${R}                                              ${DG}${DIM}|${R}\n"
  local atext="-- ${author}"
  local apad=$(( (46 - ${#atext}) / 2 ))
  local arpad=$(( 46 - apad - ${#atext} ))
  printf "  ${DG}${DIM}|${R}%*s${YL}%s${R}%*s${DG}${DIM}|${R}\n" "$apad" "" "$atext" "$arpad" ""
  printf "  ${DG}${DIM}|${R}                                              ${DG}${DIM}|${R}\n"
  printf "  ${DG}${DIM}+----------------------------------------------+${R}\n"
  echo
}

# ────────────────────────────────────────────────
#  QUICK COMMAND MENU
# ────────────────────────────────────────────────
quick_menu() {
  show_cursor
  while true; do
    clear
    echo; print_logo
    printf "  ${G}${BOLD}+----------------------------------------------+${R}\n"
    printf "  ${G}${BOLD}|        SHADOWX  COMMAND  CENTER              |${R}\n"
    printf "  ${G}${BOLD}+----------------------------------------------+${R}\n"
    printf "  ${G}|${R}  ${CY}[1]${WH} %-42s${G}|${R}\n" "Update packages    (pkg upgrade)"
    printf "  ${G}|${R}  ${CY}[2]${WH} %-42s${G}|${R}\n" "Check storage      (df -h)"
    printf "  ${G}|${R}  ${CY}[3]${WH} %-42s${G}|${R}\n" "Network info       (ip a)"
    printf "  ${G}|${R}  ${CY}[4]${WH} %-42s${G}|${R}\n" "Running processes  (top)"
    printf "  ${G}|${R}  ${CY}[5]${WH} %-42s${G}|${R}\n" "Memory usage       (free -h)"
    printf "  ${G}|${R}  ${CY}[6]${WH} %-42s${G}|${R}\n" "Installed packages"
    printf "  ${G}|${R}  ${CY}[7]${WH} %-42s${G}|${R}\n" "Ping test          (google.com)"
    printf "  ${G}|${R}  ${CY}[8]${WH} %-42s${G}|${R}\n" "Public IP address"
    printf "  ${G}|${R}  ${CY}[9]${WH} %-42s${G}|${R}\n" "New hacker quote"
    printf "  ${G}|${R}  ${YL}[0]${WH} %-42s${G}|${R}\n" "Exit to shell"
    printf "  ${G}${BOLD}+----------------------------------------------+${R}\n"
    echo
    printf "  ${YL}Select: ${WH}"
    read -r choice
    printf "%b\n" "$R"

    case "$choice" in
      1) pkg upgrade ;;
      2) df -h ;;
      3) ip a 2>/dev/null || ifconfig 2>/dev/null ;;
      4) top ;;
      5) free -h 2>/dev/null || cat /proc/meminfo | head -15 ;;
      6) pkg list-installed 2>/dev/null | head -40 ;;
      7) ping -c 4 google.com ;;
      8) curl -s https://api.ipify.org && echo ;;
      9) show_quote; printf "  ${DIM}[Press ENTER]${R}"; read -r; continue ;;
      0|q|Q) printf "\n  ${G}[>>] Entering shell. Stay sharp, %s.${R}\n\n" "$BOSS_NAME"; break ;;
      *) printf "  ${RD}[!] Invalid option.${R}\n" ;;
    esac

    echo
    printf "  ${DIM}[Press ENTER to return to menu]${R}"
    read -r
  done
}

# ── Boot ─────────────────────────────────────────
shadowx_boot() {
  hide_cursor; clear

  # Hex intro
  printf "\n"
  for ((i=0;i<6;i++)); do hex_line; sleep 0.04; done
  sleep 0.2; clear

  echo; print_logo

  printf "  ${DIM}${CY}[*] TIME : %s${R}\n" "$(date '+%Y-%m-%d  %H:%M:%S %Z')"
  printf "  ${DIM}${CY}[*] HOST : %s${R}\n" "$(hostname -s 2>/dev/null || echo SHADOWNODE)"
  printf "  ${DIM}${CY}[*] KERN : %s${R}\n" "$(uname -r 2>/dev/null | cut -c1-28 || echo ?)"
  printf "  ${DIM}${CY}[*] ARCH : %s${R}\n" "$(uname -m 2>/dev/null || echo ?)"
  echo; scan_line

  # ── Auth ─────────────────────────────────────
  local attempts=0 pass max=3
  while (( attempts < max )); do
    echo
    printf "  ${YL}[?] ACCESS CODE REQUIRED${R}\n"
    printf "  ${DIM}${WH}--------------------------${R}\n"
    printf "  ${CY}>>> ${WH}"
    stty -echo 2>/dev/null; read -r pass; stty echo 2>/dev/null
    printf "%b\n" "$R"
    [ "$pass" = "$ACCESS_CODE" ] && break
    (( attempts++ ))
    local left=$(( max - attempts ))
    echo; glitch_text "  [X] AUTHENTICATION FAILED"
    (( left > 0 )) && printf "  ${RD}[!] Attempts left: ${WH}%d/%d${R}\n" "$left" "$max" && sleep 0.7
  done

  # ── Lockout ──────────────────────────────────
  if [ "$pass" != "$ACCESS_CODE" ]; then
    denied_anim; clear; show_cursor
    kill -9 $$ 2>/dev/null
    return 1
  fi

  # ── Granted ──────────────────────────────────
  echo
  printf "  ${G}${BOLD}[OK] IDENTITY VERIFIED - WELCOME, %s${R}\n" "$BOSS_NAME"
  sleep 0.4; echo; scan_line; echo
  printf "  ${WH}${BOLD}>> Initializing ShadowX environment...${R}\n\n"
  sleep 0.3

  progress_bar "Decrypting vault       " 0.7
  progress_bar "Loading core modules   " 0.5
  progress_bar "Injecting stealth layer" 0.8
  progress_bar "Routing through proxy  " 0.6
  progress_bar "Syncing shadow core    " 0.7
  progress_bar "Hardening session keys " 0.5
  progress_bar "Activating countermeas." 0.6
  echo

  (sleep 1.2) & spinner $! "Encrypted tunnel established"
  (sleep 1.0) & spinner $! "Secure filesystem mounted"
  (sleep 0.9) & spinner $! "Intrusion countermeasures armed"
  (sleep 0.8) & spinner $! "Neural signature synced"
  echo

  for ((i=0;i<4;i++)); do hex_line; sleep 0.05; done
  sleep 0.2; clear

  # ── Welcome ──────────────────────────────────
  echo; print_logo
  glitch_text "  >> Authenticating neural signature..."
  sleep 0.3
  typewriter "  >> Welcome back, ${BOSS_NAME}. All systems online." "$G" 0.04
  echo

  print_panel
  show_quote

  scan_line; echo
  typewriter "  All systems nominal. Awaiting your command, ${BOSS_NAME}." "$DG" 0.03
  echo

  # ── Menu prompt ──────────────────────────────
  show_cursor
  printf "  ${YL}[?] Open command menu? ${WH}[Y/n]: ${R}"
  read -r open_menu
  case "${open_menu,,}" in
    ""|y|yes) quick_menu ;;
    *)
      printf "\n  ${G}[>>] Entering shell. Stay sharp, %s.${R}\n\n" "$BOSS_NAME"
      ;;
  esac
}

shadowx_boot
