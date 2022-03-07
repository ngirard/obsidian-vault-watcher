folder:="~/Obsidian"

watch:
  @echo Surveillance du dossier {{folder}}
  @watchexec -p -w {{folder}} -e md -i './at/' --debounce 500 "just handle_md"

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
  echo "WATCHEXEC_CREATED_PATH=$WATCHEXEC_CREATED_PATH"
  echo "WATCHEXEC_REMOVED_PATH=$WATCHEXEC_REMOVED_PATH"
  echo "WATCHEXEC_RENAMED_PATH=$WATCHEXEC_RENAMED_PATH"
  echo "WATCHEXEC_WRITTEN_PATH=$WATCHEXEC_WRITTEN_PATH"
  echo "WATCHEXEC_META_CHANGED_PATH=$WATCHEXEC_META_CHANGED_PATH"
  echo "WATCHEXEC_COMMON_PATH=$WATCHEXEC_COMMON_PATH"
  if [[ -n "$WATCHEXEC_CREATED_PATH" ]]; then
    parse "$WATCHEXEC_CREATED_PATH" | db_replace
    exit 0
  elif [[ -n "$WATCHEXEC_RENAMED_PATH" ]]; then
    IFS=\: read -r -a ren <<< "$WATCHEXEC_RENAMED_PATH"
    newpath="${WATCHEXEC_COMMON_PATH}${ren[1]}"
    parse "${newpath}" | db_replace
    [[ -n "$WATCHEXEC_WRITTEN_PATH" ]] && {
      IFS=\: read -r -a array <<< "$WATCHEXEC_WRITTEN_PATH"
      for path in "${array[@]}"; do
        parse "${WATCHEXEC_COMMON_PATH}${path}" | db_replace
      done
    }
    exit 0
  elif [[ -n "$WATCHEXEC_WRITTEN_PATH" ]]; then
    parse "$WATCHEXEC_WRITTEN_PATH" | db_replace
    exit 0
  fi
  exit 0
