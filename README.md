# MUX

A basic session manager for tmux.

## Dependencies

Latest versions of **bash**, **coreutils**, **grep** and **tmux** (obviously).

## Install

Clone this repository:
`$ git clone github.com/teegre/mux`

Then:
`$ cd mux`

Finally:
`# make install`

## Uninstall

`# make uninstall`

## Usage

`mux`
Show list of existing sessions and exit.

`mux <session>`
Run the given tmux session.

`mux new <session>`
Create a new session.

`mux edit <session>`
Edit an existing session.

`mux rm <session>`
Remove a session.

`mux version`
Show version and exit.

`mux help`
Show help and exit.

## Configuration

Add the following lines to the `.tmux.conf` file:

```
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
```

Also, make sure `$EDITOR` environment variable is set properly.

## Session files

### General Structure

A session file is a plain text file that defines the configuration of a `tmux` session.

### session-name and session-root

- **`session-name: <name>`**
  
  - Defines the name of the `tmux` session.
  - Example: `session-name: dev`

- **`session-root: <path>`**
  
  - Sets the root directory for the session.
  - Example: `session-root: ~/projects/myapp`

### Window and Pane Definitions

Each window and pane is defined by a line with the following format:

- **`<window_name> <pane_number> <command>`**
  - **`<window_name>`**: The name of the window.
  - **`<pane_number>`**: The number of the pane within the window.
  - **`<command>`**: The command to run in the specified pane.
  - Example: `mywindow 1 vim .`

### Special Pane Modifiers

- **Splitting Panes**:
  
  - **`v`**: Indicates a vertical split.
  - **`h`**: Indicates a horizontal split.
  - Example: `mywindow 2v npm start` (Creates a vertical split for pane `2` in window `mywindow`.)

- **Active Pane**:
  
  - **`*`**: Indicates that the pane should be the active one after the session starts.
  - Example: `mywindow 2* git status` (Makes pane `2` in window `mywindow` the active pane.)

- **Setting Layout**:
  
  - **`layout`**: Applies a specific layout to the window.
  - Example: `mywindow layout main-horizontal` (Sets the layout of window `1` to `main-horizontal`.)
  
  - For more complex layout, it is possible to paste the output of `tmux` **list-windows** command.
  - Example:
    
    ```
    # Output of 'tmux list-windows -t test-session'
    #
    # 1: my-window* (3 panes) [239x57] [layout 8bbe,239x57,0,0{88x57,0,0,24,150x57,89,0[150x28,89,0,25,150x28,89,29,26]}] @15 (active)
    
    # file: test.mux
    
    session-name: test-session
    session-root: ~
    
    my-window 1* clear; neofetch
    my-window 2 clear; neofetch
    my-window 3 clear; neofetch
    my-window layout 8bbe,239x57,0,0{88x57,0,0,24,150x57,89,0[150x28,89,0,25,150x28,89,29,26]}
    ```

### Comments

- Lines starting with `#` are comments and are ignored by **mux**.
  - Example: `# This is a comment`
