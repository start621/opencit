#!/bin/bash

load_env_file() {
  local target="$1"
  if [ -z "$target" ] || [ ! -f "$target" ]; then return 1; fi
  source "$target"
  local env_file_exports=$(cat "$target" | grep -E '^[A-Z0-9_]+\s*=' | cut -d = -f 1)
  if [ -n "$env_file_exports" ]; then eval export $env_file_exports; fi
}

load_env_dir() {
  local target="$1"
  if [ -z "$target" ] || [ ! -d "$target" ]; then return 1; fi
  local files=$(cd "$target" && ls -1 *.env 2>/dev/null)
  for file in $files
  do
    load_env_file "$target/$file"
  done
}

# input: path to a specific .env file, or path to directory with one or more .env files
load_env() {
  local target="$1"
  if [ -z "$target" ] || [ ! -e "$target" ]; then return 1; fi
  if [ -f "$target" ]; then load_env_file "$target"; return $?; fi
  if [ -d "$target" ]; then load_env_dir "$target"; return $?; fi
  return 1;
}

rm_file() {
  local file="$1"
  if [ -n "$file" ] && [ -f "$file" ]; then rm -f "$file"; fi
}

rm_dir() {
  local dir="$1"
  if [ -n "$dir" ] && [ -d "$dir" ]; then rm -rf "$dir"; fi
}
