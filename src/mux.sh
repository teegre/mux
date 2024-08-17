#! /usr/bin/env bash

#  _______ _______ ___ ___
# |   |   |   |   |   |   |
# |       |   |   |-     -|
# |__|_|__|_______|___|___|
# Basic tmux session manager
#
# MAIN
# C : 2024-08-16
# M : 2024-08-17

MUX_VERSION="0.0.1"

declare MUX_SESSION_FILE
MUX_SESSION_DIR="${HOME}/.config/mux"

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

new_session()
{
  # create a new session

  [[ $1 ]] || {
    echo "no session name given."
    return 1
  }

  [[ -f "${MUX_SESSION_DIR}/${1}.mux" ]] && {
    echo "session file '$1' exists."
    echo "use: mux edit $1"
    return 1
  }

  [[ -d "${MUX_SESSION_DIR}" ]] || mkdir -p "${MUX_SESSION_DIR}"

  MUX_SESSION_FILE="${MUX_SESSION_DIR}/${1}.mux"
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
  [[ -f "${MUX_SESSION_DIR}/${1}.mux" ]] || {
    echo "session file '$1' not found."
    echo "use: mux new $1"
    return 1
  }

  MUX_SESSION_FILE="${MUX_SESSION_DIR}/${1}.mux"
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
 regex="^[[:space:]]*${param}[[:space:]]*:[[:space:]]*(.+)$"

 while read -r line
 do
   [[ $line =~ ^#.*$ ]] && continue
   [[ $line =~ $regex ]] && {
     if [[ ! ${BASH_REMATCH[1]} ]]
     then
       return 2
     else
       value="${BASH_REMATCH[1]}"
       [[ $value =~ ^\~ ]] &&
         value="${value/\~/"$HOME"}"
       echo "$value"
       return 0
     fi
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

  local window pane cmd lineno=0

  while read window pane cmd
  do
    ((lineno++))
    [[ $window =~ ^# ]] && continue
    [[ $window =~ :$ ]] && continue
    [[ -z $window || -z $pane || -z $cmd ]] && continue

    [[ $pane == "layout" ]] && {
      tmux select-layout "$cmd"
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

    if [[ ! $(tmux lsw -t $session -F "#{window_name}" | grep "^${window}$") ]]
    then
      tmux new-window -a -t $session -n $window -c $session_root
    fi

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

command -v tmux > /dev/null || {
  echo "Missing dependency: mux won't work without tmux."
  exit 1
}

command -v grep > /dev/null || {
  echo "Missing dependency: mux won't work withou grep."
  exit 1
}

[[ $1 ]] || {
  echo "mux: version $MUX_VERSION"
  echo
  echo "This program is free software."
  echo "It is distributed AS IS with NO WARRANTY."
  echo
  echo "Usage:"
  echo "- mux <session>"
  echo "- mux new <name>"
  echo "- mux edit <name>"
  echo "- mux rm <name>"
  echo
  exit 1
}

case $1 in
  new ) new_session  $2;    exit $? ;;
  edit) edit_session $2;    exit $? ;;
  rm  ) rm_session   $2;    exit $? ;;
  *) MUX_SESSION_FILE="${MUX_SESSION_DIR}/${1}.mux"; run_tmux_session
esac

case $? in
  1) echo "key not found." ;;
  2) echo "key has no value." ;;
  3) echo "no key was given." ;;
  4) echo "session file '$1' not found." ;;
  5) echo "not allowed within a tmux session." ;;
  6) echo "fatal error."
esac
