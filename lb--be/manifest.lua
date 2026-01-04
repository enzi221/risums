--! Copyright (c) 2025-2026 amonamona
--! CC BY-NC-SA 4.0 https://creativecommons.org/licenses/by-nc-sa/4.0/
--! LightBoard Backend
--- @generic T
--- @param triggerId string
--- @param val T?
--- @param id string
--- @param globalKey string?
--- @param default T
--- @return T
local function resolveConfig(triggerId, val, id, globalKey, default)
  if val ~= nil then return val == 'true' end
  if globalKey then
    local globalVar = getGlobalVar(triggerId, 'toggle_' .. id .. '.' .. globalKey)
    if globalVar ~= nil and globalVar ~= null and globalVar ~= '' and globalVar ~= 'null' then
      return globalVar == '1'
    end
  end
  return default
end

--- @param triggerId string
--- @param id string
--- @param name string
local function loadCallback(triggerId, id, name)
  local book = prelude.getPriorityLoreBook(triggerId, id .. '.lb.' .. name)
  if book and book.content ~= '' then
    local ok, func = pcall(load, book.content, '@' .. id .. '.' .. name, 't')
    if ok and type(func) == "function" then return func() end
    print('[LightBoard Backend] Callback ' .. name .. ' load error for ' .. id, tostring(func))
  end
end

--- Retrieves all LightBoard manifests.
--- @param triggerId string
--- @return Manifest[]
local function getManifests(triggerId)
  local rawManifests = getLoreBooks(triggerId, "manifest.lb")
  local parsedManifests = {}

  for _, item in ipairs(rawManifests) do
    if item.content and item.content ~= "" then
      local tbl = {}
      for line in item.content:gmatch("[^\r\n]+") do
        local k, v = line:match("^%s*([^=]+)%s*=%s*(.*)%s*$")
        if k then tbl[k] = v end
      end

      local id = tbl.identifier
      if id and id ~= "" then
        local prefix = "toggle_" .. id .. "."

        tbl.mode = getGlobalVar(triggerId, prefix .. "mode")
        if tbl.mode ~= '0' then
          tbl.maxCtx                            = tonumber(tbl.maxCtx) or
              tonumber(getGlobalVar(triggerId, prefix .. "maxCtx"))
          tbl.maxLogs                           = tonumber(tbl.maxLogs) or
              tonumber(getGlobalVar(triggerId, prefix .. "maxLogs"))

          tbl.authorsNote                       = resolveConfig(triggerId, tbl.authorsNote, id, "authorsNote", false)
          tbl.charDesc                          = resolveConfig(triggerId, tbl.charDesc, id, "charDesc", false)
          tbl.loreBooks                         = resolveConfig(triggerId, tbl.loreBooks, id, "loreBooks", false)
          tbl.lazy                              = resolveConfig(triggerId, tbl.lazy, id, "lazy", false)
          tbl.multilingual                      = resolveConfig(triggerId, tbl.multilingual, id, "multilingual", true)

          tbl.onInput                           = loadCallback(triggerId, id, 'onInput')
          tbl.onOutput                          = loadCallback(triggerId, id, 'onOutput')
          tbl.onMutation                        = loadCallback(triggerId, id, 'onMutation')
          tbl.onValidate                        = loadCallback(triggerId, id, 'onValidate')

          parsedManifests[#parsedManifests + 1] = tbl
        end
      end
    end
  end

  return parsedManifests
end

--- Retrieves a specific manifest by identifier.
--- @param identifier string
--- @return Manifest?
local function getManifestByID(triggerId, identifier)
  local manifests = getManifests(triggerId)
  for _, m in ipairs(manifests) do
    if m.identifier == identifier then return m end
  end
  return nil
end

return {
  list = getManifests,
  get = getManifestByID,
}
