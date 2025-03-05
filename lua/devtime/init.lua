local curl = require("plenary.curl")
local queries = require("devtime.queries")
local sqlite = require("sqlite")
local path = vim.fn.fnamemodify(vim.fn.stdpath("data") .. "/devtime/tracker.db", ":p")
local M = {}

local defaults = {
  custom_telemetry_enabled = false,
  telemetry_url = "",
  flush_on_save = true,

  -- If flush_on_save is not enabled, then we can add a flush time.
  flush_timer = 30,
  headers = {
    ["Content-Type"] = "application/json",
  },
}

function M.setup(opts)
  opts = vim.tbl_deep_extend("force", defaults, opts or {})

  M.config = opts

  local ok, err = pcall(function()
    vim.fn.mkdir(vim.fn.stdpath("data") .. "/devtime", "p")
    M.db = sqlite.open(path)
    M.create_tbl()
  end)

  if not ok then error("Failed to setup database: " .. tostring(err)) end

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      if M.db then
        -- Ensure any pending tracking is written
        M.cleanup()
      end
    end,
  })

  -- Set up autocommands
  vim.api.nvim_create_autocmd({ "BufEnter" }, {
    callback = function()
      M.start_tracker()
    end,
  })

  vim.api.nvim_create_autocmd({ "BufLeave" }, {
    callback = function()
      M.stop_tracker()
    end,
  })
end

function M.start_tracker()
  local ft = vim.bo.filetype
  if ft ~= "" then
    M.filetype = ft
    M.init = os.time()
    M.current_file = vim.api.nvim_buf_get_name(0)
  end
end

function M.stop_tracker()
  if M.filetype ~= "" and M.filetype ~= vim.NIL then
    local diff = os.difftime(os.time(), M.init)
    if diff >= 1 then M.insert(M.filetype, diff, M.current_file) end
    M.reset_values()
  end
end

function M.reset_values()
  M.init = 0
  M.filetype = ""
  M.current_file = ""
end

function M.insert(language_value, duration_value, file_path)
  M.db:insert("tracker", {
    language = language_value,
    duration = duration_value,
    file = file_path,
  })
end

function M.wipe_db()
  M.db:drop_table("tracker")
end

function M.create_tbl()
  M.db:sql([[
      CREATE TABLE IF NOT EXISTS tracker (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        language TEXT NOT NULL,
        created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        duration INTEGER,
        file TEXT
      )
    ]])
  M.create_sqlite_idxs()
end

function M.create_sqlite_idxs()
  M.db:sql([[
    CREATE INDEX IF NOT EXISTS idx_language ON tracker(language);
    CREATE INDEX IF NOT EXISTS idx_created ON tracker(created);
  ]])
end

function M.cleanup()
  if M.db then
    M.stop_tracker()
    M.db:close()
    M.db = nil
  end
end

function M.print_todays()
  print(vim.inspect(queries.get_today_stats(M.db)))
end

function M.print_weekly()
  print(vim.inspect(queries.get_weekly_stats(M.db)))
end

function M.print_monthly()
  print(vim.inspect(queries.get_monthly_stats(M.db)))
end

function M.print_hourly()
  print(vim.inspect(queries.get_hourly_stats(M.db)))
end

return M
