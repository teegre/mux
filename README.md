# MUX

A basic session manager for tmux.

## Dependencies

Latest versions of **bash**, **coreutils**, **grep** and **tmux** (obviously).

## Installation

Clone this repository:
`$ git clone github.com/teegre/mux`

Then:
`$ cd mux`

Finally:
`# make install`

## Usage

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

A session file is a plain text file that define the configuration of a `tmux` session.

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
  - Example: `mywindow 2* git status` (Makes pane `2` in window `1` the active pane.)

- **Setting Layout**:
  
  - **`layout`**: Applies a specific layout to the window.
  - Example: `mywindow layout main-horizontal` (Sets the layout of window `1` to `main-horizontal`.)

### Comments

- Lines starting with `#` are comments and are ignored by the **mux**.
  - Example: `# This is a comment`

## License

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
