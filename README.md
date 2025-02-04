# grape.nvim 🍇

[![Hits](https://hits.sh/github.com/CatalinPlesu/grape.nvim.svg)](https://hits.sh/github.com/CatalinPlesu/grape.nvim/)

- [grape.nvim 🍇](#grapenvim-)
  - [Introduction](#introduction)
  - [Screenshots](#screenshots)
  - [Installation](#installation)
    - [Dependencies](#dependencies)
    - [Installation using Vim-Plug](#installation-using-vim-plug)
    - [Installation using Packer](#installation-using-packer)
    - [Installation using Lazy](#installation-using-lazy)
  - [Usage](#usage)
  - [Key bindings](#key-bindings)
    - [Basic key bindings](#basic-key-bindings)
  - [Helping `grape.nvim`](#helping-grapenvim)
  - [Commands](#commands)
    - [Commands for graph](#commands-for-graph)
  - [Stargazers over time](#stargazers-over-time)

----

## Introduction

`grape.nvim` is a bloated version of kiwi.nvim which is a stripped down VimWiki for Neovim. The added faetures are support for `[[link to file]]` and Graph view for the files.
| VimWiki | grape.nvim |
|---|---|
| Multiple syntaxes | Sticks to markdown |
| Syntax highlights included | User can install Treesitter plugins `markdown` and `markdown-inline` if required |
| Keymaps like Backspace for autosave | Stick to manual saves and `<C-o>` to move back |

With `grape.nvim`, you can:

- Organize notes and ideas
- Visualize your knowledge graph
- Other things supported by [kiwi.nvim](https://github.com/serenevoid/kiwi.nvim/)

To do a quick start, press `<Leader>ww` (default is `\ww`) to go to your index
wiki file. By default, it is located in `~/wiki/index.md`.
To register a different path for the wiki, you can specify the path inside the 
setup function if required

Feed it with the following example:

```text
# My knowledge base
- Tasks -- things to be done _yesterday_!!!
- Project Gutenberg -- good books are power.
- Scratchpad -- various temporary stuff.
```

Place your cursor on `Tasks` and press Enter to create a link. Once pressed,
`Tasks` will become `[Tasks](./Tasks.md)` and open it. Edit the file, save it.
To go back, you can press `<C-o>` to move to the previous file. Backspace is not 
mapped to go back since we already have vim keybindings to move back.

A markdown link can be constructed from more than one word. Just visually
select the words to be linked and press Enter. Try it, with `Project Gutenberg`.
The result should look something like:

```text
# My knowledge base
- [Tasks](./Tasks.md) -- things to be done _yesterday_!!!
- [Project Gutenberg](./Project_Gutenberg.md) -- good books are power.
- [[Useful Links]]
- Scratchpad -- various temporary stuff.
```

## Screenshots

![custom_note.md](https://u.cubeupload.com/serenevoid/6JqlpX.png)
![todo.md](https://u.cubeupload.com/serenevoid/6JqlpX.png)
![graph](https://i.imgur.com/p4dqG45.png)

## Installation

`grape.nvim` has been tested on **Neovim >= 0.7**. It will likely work on older
versions but will not be officially supported.

### Dependencies

`grape.nvim` is a standalone plugin.

### Installation using [Vim-Plug](https://github.com/junegunn/vim-plug)

Add the following to the plugin-configuration in your vimrc:

```vim

Plug 'CatalinPlesu/grape.nvim'

```

Then run `:PlugInstall`.

### Installation using [Packer](https://github.com/wbthomason/packer.nvim)

```lua

use {
    'CatalinPlesu/grape.nvim'
}

```

### Installation using [Lazy](https://github.com/folke/lazy.nvim)

```lua

-- init.lua:
{
    'CatalinPlesu/grape.nvim'
}

-- plugins/grape.lua:
return {
    'CatalinPlesu/grape.nvim'
}

```

## Usage

For [Lazy](https://github.com/folke/lazy.nvim) users,
```lua
{
    'CatalinPlesu/grape.nvim',
    opts = {
        {
            name = "work",
            path = "work-wiki"
        },
        {
            name = "personal",
            path = "personal-wiki"
        },
        cd_wiki = false
    },
    keys = {
        { "<leader>ww", ":lua require(\"grape\").open_wiki_index()<cr>", desc = "Open Wiki index" },
        { "<leader>wp", ":lua require(\"grape\").open_wiki_index(\"personal\")<cr>", desc = "Open index of personal wiki" },
        { "T", ":lua require(\"grape\").todo.toggle()<cr>", desc = "Toggle Markdown Task" },
        { "<leader>wg", ":lua require(\"grape\").show_graph()<cr>", desc = "Shows the wiki graph" },
        { "<leader>wR", ":lua require(\"grape\").refresh_graph()<cr>", desc = "Regenerate graph, requires manual page refresh" },
        { "<leader>wS", ":lua require(\"grape\").stop_server()<cr>", desc = "Stops the graph server" },
    },
    lazy = true
}
```

For others,
```lua
-- Setup Custom wiki path if required
require('grape').setup({
    {
        name = "work",
        path = "work-wiki"
    },
    {
        name = "personal",
        path = "personal-wiki"
    },
    cd_wiki = false
})
-- Note: The path will be created in user home directory

-- Use default path (i.e. ~/wiki/)
local grape = require('grape')

-- Necessary keybindings
vim.keymap.set('n', '<leader>ww', grape.open_wiki_index, {})
vim.keymap.set('n', 'T', grape.todo.toggle, {})
```

## Key bindings

### Basic key bindings

- `<Enter>` -- In visual mode: Follow/Create wiki link, in Normal mode just follow
- `<Tab>` -- Find next wiki link.

## Helping `grape.nvim`

This is a new project which aims to be a minimal wiki plugin which is very barebones
and doesn't add features which a lot people doesn't use now. You can help by raising issues 
and bug fixes to help develop this project for the neovim community.

## Commands

### Commands for graph

- `ShowGraph` -- Show the graph
- `RefreshGraph` -- Regenerate the data.json for selected wiki, it still requires tab reload in browser
- `StopServer` -- Stops the http server that serves this files

## Stargazers over time

[![Stargazers over time](https://starchart.cc/CatalinPlesu/grape.nvim.svg)](https://starchart.cc/CatalinPlesu/grape.nvim)
