# devtime.nvim
Neovim plugin to track language usage in a local SQLite database. For data hoarders who like to analyze their coding patterns.

## Features
- Tracks programming language usage based on buffers opened and closed
- Records duration spent in each language
- Timestamps for accurate time tracking
- Records buffer/file names

## Dependencies
This plugin requires:
- `3rd/sqlite.nvim`
- `nvim-lua/plenary.nvim`

SQLite3 is used to store tracking data in `.local/share/nvim/devtime` directory. Plenary is needed for HTTP requests when using custom telemetry.

## Installation with Lazy
```lua
{
  'alfredosa/devtime.nvim',
  dependencies = {
    { '3rd/sqlite.nvim' },
    { "nvim-lua/plenary.nvim" },
  },
  config = function()
    local token_env = "DEVTIME_API_TOKEN"
    local token = os.getenv(token_env)
    if not token then
      vim.notify("Environment variable not found: " .. token_env, vim.log.levels.WARN)
      token = "default_token" -- Optional fallback
    end
    
    require("devtime").setup({
      custom_telemetry_enabled = true,
      telemetry_url = "https://api.example.com/devtime", -- assumes a post 
      flush_timer = 60,
      headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. token,
      },
      notify_on_flush = false, -- Allows to pop a notification on flush, default is false
    })
  end,
}
```

## Configuration Options
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `custom_telemetry_enabled` | boolean | `false` | Enable sending data to a custom endpoint |
| `telemetry_url` | string | `""` | URL for the telemetry endpoint |
| `flush_timer` | number | `30` | Time in seconds between telemetry data flushes |
| `headers` | table | `{ ["Content-Type"] = "application/json" }` | Headers for the telemetry request |

## Development Roadmap
- [x] Custom configurations
- [x] Custom telemetry endpoint
- [ ] Local stats page with optional web server
- [ ] Optimized batching for database inserts

