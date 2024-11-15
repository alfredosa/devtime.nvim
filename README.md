# devtime.nvim

Neovim plugin to track language usage in a local sqlite3. For those data hoarders like me, who like to analyze random stuff. 

## What's stored:

- language (Based on buffers opened and closed)
- duration
- Timestamp (for tracking lang work)
- Buffer Name / file name

## Dependencies:

This plugin requires 

```lua
-- Simple add:
{ '3rd/sqlite.nvim' }
```


## Sqlite3

Sqlite3 is required to operate this pluggin. It will create a db in `.local/share/nvim/devtime` dir.

## Lazy Usage: 

```lua
-- Simple add:
  {
    'alfredosa/devtime.nvim',
    dependencies = {
      { '3rd/sqlite.nvim' },
    },
    config = function()
      require('devtime').setup()
    end,
  },
```


