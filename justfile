set dotenv-load := true
set export := true
set positional-arguments := true
env := ".env"
version := "0.2.0"

folder:="~/Obsidian"

_default:
  @just --list --unsorted

watch:
  #!/usr/bin/env bash
  echo "Surveillance du dossier $PWD"
  # Permet de changer de version de Watchexec, car son comportement diffère selon les versions
  watchexec=watchexec
  # watchexec="/home/ngirard/soft/watchexec/watchexec-1.15.1-x86_64-unknown-linux-gnu/watchexec"
  # @echo Surveillance du dossier {{folder}}
  "${watchexec}" -p -w {{folder}} -e md -i './at/' --debounce 500 "just handle_md"

handle_md:
  #!/usr/bin/env bash
  ix=~/Documents/index.sqlite
  
  parse(){
    local path="$1"
    rg --no-heading --with-filename --no-line-number -t md '^(`ID`:: )([0-9a-z]{3,6})(\s*)' -r '$2' -- "${path}" \
      | rg '^(.*)/(.*):([0-9a-z]{3,6})' -r '$3:$2' \
      | sd -s "'" "''"
  }

  db_replace(){
      rargs -p '(?P<id>.*):(?P<path>.*)' \
        sqlite3 -echo "${ix}" \
          "replace into notes (id,path) values (\
            '{id}',
            '{path}' \
          )"
  }

  handle_path(){
    path="$1"
    [[ ! -f "${path}" ]] && {
      echo "Not a file: ${path}"
      exit 1
    }
    parse "${path}" | db_replace
    #echo parse "${path}"
    exit 0
  }

  handle_paths(){
    local parent="$1"
    local f
    IFS=\: read -r -a paths <<< "$2"
    for path in "${paths[@]}"; do
      f="${parent}/${path}"
      [[ -f "${f}" ]] && handle_path "${f}"
    done
  }

  echo "WATCHEXEC_COMMON_PATH      = $WATCHEXEC_COMMON_PATH"
  echo "WATCHEXEC_CREATED_PATH     = $WATCHEXEC_CREATED_PATH"
  echo "WATCHEXEC_META_CHANGED_PATH= $WATCHEXEC_META_CHANGED_PATH"
  echo "WATCHEXEC_REMOVED_PATH     = $WATCHEXEC_REMOVED_PATH"
  echo "WATCHEXEC_RENAMED_PATH     = $WATCHEXEC_RENAMED_PATH"
  echo "WATCHEXEC_WRITTEN_PATH     = $WATCHEXEC_WRITTEN_PATH"

  if [[ -n "${WATCHEXEC_CREATED_PATH}" ]]; then
    handle_paths "${WATCHEXEC_COMMON_PATH}" "${WATCHEXEC_CREATED_PATH}"
    exit 0
  elif [[ -n "${WATCHEXEC_RENAMED_PATH}" ]]; then
    handle_paths "${WATCHEXEC_COMMON_PATH}" "${WATCHEXEC_RENAMED_PATH}"
    exit 0
  elif [[ -n "${WATCHEXEC_WRITTEN_PATH}" ]]; then
    handle_paths "${WATCHEXEC_COMMON_PATH}" "${WATCHEXEC_WRITTEN_PATH}"
    exit 0
  fi
  exit 0
