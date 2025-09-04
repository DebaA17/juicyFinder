#!/bin/bash

echo -e "\nCreated by Debasis | Email: forensic@debasisbiswas.me\n"

SCAN_PATH="${1:-$HOME}"

declare -A FILE_GROUPS=(
  ["Env Files"]=".env"
  ["Config Files"]="*.conf *.npmrc *.bash_history *.zsh_history"
  ["Key Files"]="*.pem *.key *.crt"
  ["Backup Files"]="*.bak *.old"
  ["Database Files"]="*.sql *.db *.sqlite"
  ["Logs"]="*.log"
  ["Git Files"]=".git"
)

KEYWORDS=("password" "secret" "token" "api_key" "apikey" "private_key")

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}🔍 Scanning directory: $SCAN_PATH${NC}"
echo ""

print_section() {
  local title="$1"
  shift
  local files=("$@")

  if [ "${#files[@]}" -eq 0 ]; then
    return
  fi

  echo -e "${YELLOW}--- $title (${#files[@]} found) ---${NC}"

  for file in "${files[@]}"; do
    local flag=""
    if [ -r "$file" ] && ! grep -Iq . "$file"; then
      content=$(tr '[:upper:]' '[:lower:]' < "$file")
      for kw in "${KEYWORDS[@]}"; do
        if echo "$content" | grep -q "$kw"; then
          flag=" ${RED}⚠️  (contains sensitive keywords)${NC}"
          break
        fi
      done
    fi
    echo -e "  ${GREEN}[+]${NC} $file$flag"
  done
  echo ""
}

for group in "${!FILE_GROUPS[@]}"; do
  patterns=(${FILE_GROUPS[$group]})
  find_expr=""
  for p in "${patterns[@]}"; do
    if [ -z "$find_expr" ]; then
      find_expr="-iname '$p'"
    else
      find_expr="$find_expr -o -iname '$p'"
    fi
  done

  mapfile -t found_files < <(eval "find \"$SCAN_PATH\" -type f \\( $find_expr \\) 2>/dev/null")

  print_section "$group" "${found_files[@]}"
done

# SUID Binary Checker
echo -e "${CYAN}🔒 Checking for SUID binaries...${NC}"
mapfile -t suid_bins < <(find "$SCAN_PATH" -perm -4000 -type f 2>/dev/null)
if [ "${#suid_bins[@]}" -gt 0 ]; then
  echo -e "${YELLOW}--- SUID Binaries (${#suid_bins[@]} found) ---${NC}"
  for bin in "${suid_bins[@]}"; do
    perms=$(stat -c '%A' "$bin")
    owner=$(stat -c '%U' "$bin")
    echo -e "  ${GREEN}[+]${NC} $bin (${perms}, owner: $owner)"
  done
  echo ""
  echo -e "${CYAN}Reference: https://gtfobins.github.io/ (GTFOBins: SUID binary list)${NC}"
else
  echo -e "${GREEN}No SUID binaries found in $SCAN_PATH.${NC}"
fi

echo -e "${CYAN}Scan complete.${NC}"

