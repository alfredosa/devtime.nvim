# devtime.nvim

Neovim plugin to track language usage in a local sqlite3. For those data hoarders like me, who like to analyze random stuff. 

## Coming soon:

- Allowing export to any endpoint through configuration.
> I want to be able to treat neovim as an iot device and allow users to export it without providing a backend or forcing logic on them.

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

## Development roadmap:

I plan on adding:

- Custom configurations.
- a local stats page (Optional Web Server)
- Batching. The current method works fine but I think I can optimize this by batching inserts. 
