--[[
  NampowerDB
  Crash-persistent SavedVariables replacement using nampower's file API.

  Usage:
    NampowerDB_Register("Accountant_SaveData", "accountant.lua", {
      periodic = true,       -- enable periodic writing (default: true)
      interval = 30,         -- seconds between writes (default: 30, minimum: 10)
      events   = {           -- additional events that trigger a write (optional)
        "AUCTION_HOUSE_CLOSED",
      },
    })

  PLAYER_LOGOUT is always registered regardless of options.
  An event-triggered write resets the periodic timer.
  On load, the newer of SavedVariables and the file wins (compared via last_saved).
  On failure to load a file, an error is raised loudly. Remove the file manually to fall back.
]]

local NAMPOWER_DB_MIN_INTERVAL = 10
local NAMPOWER_DB_VERSION = 1

-- Registry of all registered variables
-- Each entry: { globalName, filename, options, elapsed }
local NampowerDB_Registry = {}

-- Whether nampower file API is available
local NampowerDB_Available = false

-- The single OnUpdate frame shared across all registrations
local NampowerDB_Frame = nil

-- ---------------------------------------------------------------------------
-- Availability check
-- ---------------------------------------------------------------------------

local function NampowerDB_CheckAvailable()
  local ok, major, minor, patch = pcall(GetNampowerVersion)
  if ok and major then
    NampowerDB_Available = true
  else
    NampowerDB_Available = false
  end
  return NampowerDB_Available
end

-- ---------------------------------------------------------------------------
-- Serializer
-- Outputs a Lua expression representing a value.
-- Supports strings, numbers, booleans, nil, and nested tables.
-- ---------------------------------------------------------------------------

local function NampowerDB_Serialize(value, indent)
  indent = indent or 0
  local t = type(value)

  if t == "nil" then
    return "nil"
  elseif t == "boolean" then
    return tostring(value)
  elseif t == "number" then
    return tostring(value)
  elseif t == "string" then
    -- Escape backslashes, quotes, newlines, carriage returns, and null bytes
    local escaped = string.gsub(value, "\\", "\\\\")
    escaped = string.gsub(escaped, '"', '\\"')
    escaped = string.gsub(escaped, "\n", "\\n")
    escaped = string.gsub(escaped, "\r", "\\r")
    escaped = string.gsub(escaped, "%z", "\\0")
    return '"' .. escaped .. '"'
  elseif t == "table" then
    local lines = {}
    local pad = string.rep("  ", indent + 1)
    local padEnd = string.rep("  ", indent)

    for k, v in pairs(value) do
      local keyStr
      if type(k) == "string" and string.find(k, "^[%a_][%w_]*$") then
        keyStr = k
      elseif type(k) == "number" then
        keyStr = "[" .. tostring(k) .. "]"
      else
        keyStr = "[" .. NampowerDB_Serialize(k, 0) .. "]"
      end
      local valStr = NampowerDB_Serialize(v, indent + 1)
      table.insert(lines, pad .. keyStr .. " = " .. valStr)
    end

    if table.getn(lines) == 0 then
      return "{}"
    end
    return "{\n" .. table.concat(lines, ",\n") .. "\n" .. padEnd .. "}"
  else
    -- Functions, userdata, threads cannot be serialized
    error("NampowerDB: cannot serialize value of type '" .. t .. "'")
  end
end

-- ---------------------------------------------------------------------------
-- Write a registered entry to disk
-- Updates last_saved on the table before writing.
-- ---------------------------------------------------------------------------

local function NampowerDB_Write(entry)
  if not NampowerDB_Available then
    return
  end

  local tbl = getglobal(entry.globalName)
  if tbl == nil then
    ACC_Print("|cFFFF0000NampowerDB: cannot write '" .. entry.globalName .. "', global is nil|r")
    return
  end

  -- Stamp last_saved before serializing
  tbl.last_saved = time()

  local ok, result = pcall(NampowerDB_Serialize, tbl)
  if not ok then
    error("NampowerDB: serialization failed for '" .. entry.globalName .. "': " .. tostring(result))
  end

  local contents = "NampowerDB_Load(" .. NampowerDB_Serialize(entry.globalName) .. ", " .. result .. ")\n"

  WriteCustomFile(entry.filename, contents, "w")
end

-- ---------------------------------------------------------------------------
-- NampowerDB_Load
-- Called by the executed file. Compares last_saved and overwrites the global
-- if the file is newer. If the global has no last_saved, the file wins.
-- ---------------------------------------------------------------------------

function NampowerDB_Load(globalName, fileData)
  if type(fileData) ~= "table" then
    error("NampowerDB: file data for '" .. globalName .. "' is not a table")
  end

  local current = getglobal(globalName)

  -- If the global doesn't exist yet or has no last_saved, file wins
  if current == nil or current.last_saved == nil then
    setglobal(globalName, fileData)
    return
  end

  -- If the file has no last_saved, it predates this system — global wins,
  -- but we schedule an immediate write by setting file's last_saved to 0
  if fileData.last_saved == nil then
    fileData.last_saved = 0
  end

  if fileData.last_saved >= current.last_saved then
    setglobal(globalName, fileData)
  end
  -- If current is newer, do nothing — the periodic writer will update the file
end

-- ---------------------------------------------------------------------------
-- Event handler
-- ---------------------------------------------------------------------------

local function NampowerDB_OnEvent(event)
  if not NampowerDB_Available then
    return
  end

  for i = 1, table.getn(NampowerDB_Registry) do
    local entry = NampowerDB_Registry[i]
    for j = 1, table.getn(entry.events) do
      if entry.events[j] == event then
        NampowerDB_Write(entry)
        -- Reset the periodic timer so we don't double-write shortly after
        entry.elapsed = 0
        break
      end
    end
  end
end

-- ---------------------------------------------------------------------------
-- NampowerDB_Register
-- ---------------------------------------------------------------------------

function NampowerDB_Register(globalName, filename, options)
  if not NampowerDB_CheckAvailable() then
    -- Nampower not present — silently do nothing, SavedVariables will work normally
    return
  end

  options = options or {}

  local periodic = true
  if options.periodic == false then
    periodic = false
  end

  local interval = options.interval or 30
  if interval < NAMPOWER_DB_MIN_INTERVAL then
    interval = NAMPOWER_DB_MIN_INTERVAL
  end

  -- Build event list, always including PLAYER_LOGOUT
  local events = {}
  local hasLogout = false
  if options.events then
    for i = 1, table.getn(options.events) do
      table.insert(events, options.events[i])
      if options.events[i] == "PLAYER_LOGOUT" then
        hasLogout = true
      end
    end
  end
  if not hasLogout then
    table.insert(events, "PLAYER_LOGOUT")
  end

  local entry = {
    globalName = globalName,
    filename = filename,
    periodic = periodic,
    interval = interval,
    events = events,
    elapsed = 0,
  }

  table.insert(NampowerDB_Registry, entry)

  -- Register events on the shared frame
  for i = 1, table.getn(events) do
    NampowerDB_Frame:RegisterEvent(events[i])
  end

  -- If the file exists, execute it now so NampowerDB_Load runs and
  -- the comparison happens before the addon reads its SavedVariable
  if CustomFileExists(filename) then
    local ok, err = pcall(ExecuteCustomLuaFile, filename)
    if not ok then
      error(
        "NampowerDB: failed to load file '"
          .. filename
          .. "' for '"
          .. globalName
          .. "'.\n"
          .. "Error: "
          .. tostring(err)
          .. "\n"
          .. "Remove the file manually if you wish to fall back to SavedVariables."
      )
    end
  else
    -- No file yet — if SavedVariables data exists, write it to file immediately
    local tbl = getglobal(globalName)
    if tbl ~= nil then
      NampowerDB_Write(entry)
    end
  end
end

-- ---------------------------------------------------------------------------
-- Frame setup — runs at file load time
-- ---------------------------------------------------------------------------

local function NampowerDB_CreateFrame()
  NampowerDB_Frame = CreateFrame("Frame", "NampowerDBFrame", UIParent)

  NampowerDB_Frame:SetScript("OnEvent", function()
    NampowerDB_OnEvent(event)
  end)

  NampowerDB_Frame:SetScript("OnUpdate", function()
    if not NampowerDB_Available then
      return
    end
    local dt = arg1
    for i = 1, table.getn(NampowerDB_Registry) do
      local entry = NampowerDB_Registry[i]
      if entry.periodic then
        entry.elapsed = entry.elapsed + dt
        if entry.elapsed >= entry.interval then
          entry.elapsed = 0
          NampowerDB_Write(entry)
        end
      end
    end
  end)
end

NampowerDB_CreateFrame()
