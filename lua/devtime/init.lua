local curl = require("plenary.curl")
local queries = require("devtime.queries")
local sqlite = require("sqlite")
local path = vim.fn.fnamemodify(vim.fn.stdpath("data") .. "/devtime/tracker.db", ":p")
local M = {}

local defaults = {
  custom_telemetry_enabled = false,
  telemetry_url = "",
  flush_timer = 30,
  headers = {
    ["Content-Type"] = "application/json",
  },
  notify_on_flush = false,
}

function M.setup(opts)
  opts = vim.tbl_deep_extend("force", defaults, opts or {})

  M.config = opts

  if M.config.custom_telemetry_enabled and M.config.flush_timer > 0 then M.setup_flush_timer() end

  local ok, err = pcall(function()
    vim.fn.mkdir(vim.fn.stdpath("data") .. "/devtime", "p")
    M.db = sqlite.open(path)
    M.create_tbl()
  end)

  if not ok then error("Failed to setup database: " .. tostring(err)) end

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      if M.db then M.cleanup() end
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

function M.flush_telemetry()
  if not M.config.custom_telemetry_enabled or M.config.telemetry_url == "" then return false end

  local data_to_flush = queries.get_unsynced_stats(M.db)

  if not data_to_flush or vim.tbl_isempty(data_to_flush) then return true end

  -- Send the data
  local response = curl.post(M.config.telemetry_url, {
    headers = M.config.headers,
    body = vim.fn.json_encode(data_to_flush),
    timeout = 10000,
  })

  if response.status >= 200 and response.status < 300 then
    M.db:sql([[
        UPDATE tracker
        SET synced = 1
        WHERE (synced = 0 OR synced IS NULL)
      ]])
    M.last_flush_time = os.time()
    if M.notify_on_flush then vim.notify("flushed successfully", vim.log.levels.INFO) end
    return true
  else
    vim.notify("Failed to flush telemetry data: " .. (response.body or "Unknown error"), vim.log.levels.WARN)
    return false
  end
end

-- Timer setup function
function M.setup_flush_timer()
  if M.flush_timer_id then vim.loop.timer_stop(M.flush_timer_id) end

  M.flush_timer_id = vim.loop.new_timer()
  local timer_ms = M.config.flush_timer * 1000

  -- Run the timer
  M.flush_timer_id:start(
    timer_ms,
    timer_ms,
    vim.schedule_wrap(function()
      M.flush_telemetry()
    end)
  )
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
  M.migrate_synced_time()
end

function M.create_sqlite_idxs()
  M.db:sql([[
    CREATE INDEX IF NOT EXISTS idx_language ON tracker(language);
    CREATE INDEX IF NOT EXISTS idx_created ON tracker(created);
  ]])
end

function M.migrate_synced_time()
  -- Check if column exists first
  local column_exists = M.db:sql("PRAGMA table_info(tracker)") or {}
  local has_synced = false

  for _, col in ipairs(column_exists) do
    if col.name == "synced" then
      has_synced = true
      break
    end
  end

  if not has_synced then M.db:sql([[
      ALTER TABLE tracker ADD COLUMN synced INTEGER DEFAULT 0
    ]]) end
end

function M.cleanup()
  if M.flush_timer_id then
    vim.loop.timer_stop(M.flush_timer_id)
    M.flush_timer_id = nil
  end

  if M.config.custom_telemetry_enabled then M.flush_telemetry() end

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
