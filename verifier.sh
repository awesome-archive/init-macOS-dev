#!/usr/bin/env bash
# Integrity Verifier

local PROJECT_NAME="init-macOS-dev"
local HASH_FILE="md5sum.txt"
local SOURCE_URL="https://github.com/zthxxx/${PROJECT_NAME}/raw/master/"

is_command() { command -v $@ &> /dev/null; }

download() {
  local file="$1"
  if ! curl -sSL "${SOURCE_URL}${file}" -o "$file" --create-dirs; then
    exit 1
  fi
}

exist_check() {
  local file="$1"
  if [[ ! -r "$file" ]]; then
    download "$file"
  fi
}

integrity_verifier() {
  exist_check "$HASH_FILE"
  if is_command md5sum; then
    if ! md5sum --quiet -c "$HASH_FILE"; then 
      exit 1
    fi
  elif is_command md5; then
    local files=(`awk '{print $2}' "$HASH_FILE"`)
    local sums=(`awk '{print $1}' "$HASH_FILE"`)
    local index=0
    for file in "${files[@]}"; do
      local sum=`openssl md5 -r "$file" | awk '{print $1}'`
      if [[ "$sum" != "${sums[$index]}" ]]; then
        exit 1
      fi
      let index++
    done
  else
    echo "Cannot to use md5sum" >&2
    exit 1
  fi
}

download_files() {
  exist_check "$HASH_FILE"
  local files=(`awk '{print $2}' "$HASH_FILE"`)

  for file in "${files[@]}"; do
    exist_check "$file"
  done

  integrity_verifier
}

verify() {
  if is_command git; then 
    git clone "https://github.com/zthxxx/${PROJECT_NAME}.git"
    cd "$PROJECT_NAME"
  else
    mkdir "$PROJECT_NAME"
    cd "$PROJECT_NAME"
    download_files
  fi
}

verify

MAIN="init.sh"
chmod +x "$MAIN"
eval "./${MAIN}" "$@"
