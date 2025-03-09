require("sqlite.database")
local queries = {}

---@param db Database
function queries.get_today_stats(db)
  return db:sql([[
   SELECT 
     language,
     COUNT(*) as entries,
     SUM(duration) as total_seconds,
     ROUND(SUM(duration) / 3600.0, 2) as total_hours
   FROM tracker 
   WHERE DATE(created) = DATE('now')
   GROUP BY language
   ORDER BY total_seconds DESC
 ]])
end

---@param db Database
function queries.get_hourly_stats(db)
  return db:sql([[
   SELECT 
     language,
     strftime('%H', created) as hour,
     SUM(duration) as total_seconds
   FROM tracker
   WHERE DATE(created) = DATE('now')
   GROUP BY language, hour
   ORDER BY hour, total_seconds DESC
 ]])
end

---@param db Database
function queries.get_weekly_stats(db)
  return db:sql([[
   SELECT 
     language,
     COUNT(*) as entries,
     SUM(duration) as total_seconds,
     ROUND(SUM(duration) / 3600.0, 2) as total_hours
   FROM tracker 
   WHERE DATE(created) >= DATE('now', '-7 days')
   GROUP BY language
   ORDER BY total_seconds DESC
   LIMIT 10
 ]])
end

---@param db Database
function queries.get_monthly_stats(db)
  return db:sql([[
   SELECT 
     language,
     COUNT(*) as entries, 
     SUM(duration) as total_seconds,
     ROUND(SUM(duration) / 3600.0, 2) as total_hours,
     strftime('%Y-%m', created) as month
   FROM tracker
   WHERE DATE(created) >= DATE('now', '-30 days')
   GROUP BY language
   ORDER BY total_seconds DESC
   LIMIT 10
 ]])
end

---@param db Database
function queries.get_unsynced_stats(db)
  return db:sql([[
    SELECT
      language,
      date(created) as day,
      COUNT(*) as count,
      SUM(duration) as seconds,
      id
    FROM tracker
    WHERE synced = 0
    GROUP BY language, date(created)
  ]])
end

return queries
