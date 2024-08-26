#! /usr/bin/env bash

#  _______ _______ ___ ___
# |   |   |   |   |   |   |
# |       |   |   |-     -|
# |__|_|__|_______|___|___|
# Basic tmux session manager
#
# MAIN
# C : 2024-08-16
# M : 2024-08-26

MUX_VERSION="0.0.2"

declare MUX_SESSION_FILE
MUX_SESSION_DIR="${HOME}/.config/mux"

mux_help()
{
cat << HELP
mux: version $MUX_VERSION
Basic session manager for tmux.

Commands:
  mux             - show session list.
  mux <name>      - run a tmux session.
  mux new <name>  - create a new tmux session.
  mux edit <name> - edit an existing tmux session.
  mux rm <name>   - remove a tmux session.
  mux version     - show version and exit.
  mux help        - show this help screen and exit.

HELP
}

confirm()
{
  # ask user for confirmation.

  local prompt
  prompt="${1:-"sure?"}"

  printf "%s [y/N]: " "$prompt"
  read -r
  [[ ${REPLY,,} == "y" ]] && return 0
  return 1
}

list_sessions()
{
  # show available sessions.

  [[ -d "${MUX_SESSION_DIR}" ]] || {
    echo "no sessions."
    echo "try: mux help"
    return 1
  }

  local session_name session_count=0

  echo "available sessions:"
  for session in "${MUX_SESSION_DIR}"/*
  do
    # strip filepath.
    session_name="${session//${MUX_SESSION_DIR}\/}"
    # strip file extension.
    session_name="${session_name%.*}"

    printf "  %s\n" "$session_name"
    ((session_count++))
  done

  echo
  ((session_count == 0)) && echo "try: mux help"
  ((session_count == 0)) || echo "use: mux <name>"

  return 0
}

new_session()
{
  # create a new session.

  [[ $1 ]] || {
    echo "no session name given."
    return 1
  }

  MUX_SESSION_FILE="${MUX_SESSION_DIR}/${1}.mux"

  [[ -f "$MUX_SESSION_FILE" ]] && {
    echo "session file '$1' exists."
    echo "use: mux edit $1"
    return 1
  }

  [[ -d "${MUX_SESSION_DIR}" ]] || mkdir -p "${MUX_SESSION_DIR}"

  tmp_file="$(mktemp)"

  $EDITOR "$tmp_file"

  [[ -s "$tmp_file" ]] && {
    mv "$tmp_file" "$MUX_SESSION_FILE"
    echo "'$1' saved."
    return 0
  }

  rm "$tmp_file"
  echo "no change."
  return 1
}

edit_session()
{
  MUX_SESSION_FILE="${MUX_SESSION_DIR}/${1}.mux"

  [[ -f "$MUX_SESSION_FILE" ]] || {
    echo "session file '$1' not found."
    echo "use: mux new $1"
    return 1
  }

  $EDITOR "$MUX_SESSION_FILE"
  return 0
}

rm_session()
{
  [[ -f "${MUX_SESSION_DIR}/${1}.mux" ]] || {
    echo "session file '$1' not found."
    return 1
  }

  MUX_SESSION_FILE="${MUX_SESSION_DIR}/${1}.mux"

  confirm "remove '$1'?" && {
     rm "$MUX_SESSION_FILE" 2> /dev/null && echo "removed '$1'."
     return $?
  }

  "cancelled."
  return 1
}

# read_config <key> → <value>
# Print value for a given key.
# Return 0 if success, non-zero otherwise:
# 1 - the key has not been found,
# 2 - the key has not value
# 3 - no given key
# 4 - no session file

read_config()
{
 [[ -a $MUX_SESSION_FILE ]] || return 4

 [[ $1 ]]  || return 3

 local param regex line value
 param="$1"
 regex="^[[:space:]]*${param}[[:space:]]*:[[:space:]]*(.*)$"

 while read -r line
 do
   [[ $line =~ ^#.*$ ]] && continue
   [[ $line =~ $regex ]] && {
     [[ ${BASH_REMATCH[1]} ]] || return 2

     value="${BASH_REMATCH[1]}"
     [[ $value =~ ^\~ ]] &&
       value="${value/\~/"$HOME"}"

     echo "$value"
     return 0
   }
 done < "$MUX_SESSION_FILE"

 return 1
}

run_tmux_session()
{
  session="$(read_config session-name)" || return $?
  session_root="$(read_config session-root)" || return $?

  [[ $TERM =~ ^tmux ]] && return 5

  if [[ ! $(tmux ls -F "#{session_name}" 2> /dev/null | grep "^${session}$") ]]
  then
    tmux new-session -s "$session" -d
  else
    tmux attach -t "$session"
    exit 0
  fi

  declare -a active_panes

  local window pane cmd
  local split pane_num active
  local lineno=0

  while read window pane cmd
  do
    ((lineno++))
    [[ $window =~ ^# ]] && continue
    [[ $window =~ :$ ]] && continue
    [[ -z $window || -z $pane || -z $cmd ]] && continue

    [[ $pane == "layout" ]] && {
      tmux select-layout "$cmd" || {
        tmux kill-session -t $session
        return 6
      }
      continue
    }

    pane_num=${pane//[^0-9]*}
    split="${pane//[^hv]}"

    [[ ${#split} > 1 ]] && {
      echo "error: invalid split on line $lineno: $window $pane_num>$split<"
      tmux kill-session -t $session
      exit 6
    }

    [[ $split ]] && split="-${split}"

    active=${pane//[^*]}
    [[ $active ]] && active_panes+=("$session:$window.$pane_num")

    [[ $(tmux lsw -t $session -F "#{window_name}" | grep "^${window}$") ]] || {
      tmux new-window -a -t $session -n $window -c $session_root
    }

    if [[ ! $(tmux lsp -t $session:$window -F "#{pane_number}" | grep "^${pane_num}$") ]] \
      && [[ $pane_num != 1 ]]
    then
      tmux split-window -t ${session}:${window} $split
    fi

    tmux send-key -t $window.$pane_num "$cmd" C-m

  done < $MUX_SESSION_FILE

  
  tmux kill-window -t :1
  tmux select-window -t :1
  for p in ${active_panes[@]}
  do
    tmux select-pane -t $p
  done
  tmux attach -t $session
}

# Checking dependencies...
deps=0

command -v tmux > /dev/null || {
  echo "Missing dependency: tmux."
  ((deps++))
}

command -v grep > /dev/null || {
  echo "Missing dependency: grep."
  ((deps++))
}

command -v mktemp > /dev/null || {
  echo "Missing dependency: mktemp (coreutils)."
  ((deps++))
}


[[ $EDITOR ]] || {
  echo "EDITOR is not set."
  ((deps++))
}

(( deps > 0 )) && exit 1


[[ $1 ]] || {
  list_sessions
  exit $?
}

case $1 in
  new     ) new_session  $2;    exit $? ;;
  edit    ) edit_session $2;    exit $? ;;
  rm      ) rm_session   $2;    exit $? ;;
  version ) echo "mux: version $MUX_VERSION"; exit 0 ;;
  help    ) mux_help; exit 0 ;;
  *       ) MUX_SESSION_FILE="${MUX_SESSION_DIR}/${1}.mux"; run_tmux_session
esac

case $? in
  1) echo "error: a session key could not be found." ;;
  2) echo "error: a session key has no value." ;;
  # 3) echo "no key was given." ;; # useless.
  4) echo "error: session file '$1' not found." ;;
  5) echo "error: not allowed within a tmux session." ;;
  6) echo "fatal error!"
esac
