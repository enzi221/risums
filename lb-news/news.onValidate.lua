local triggerId = ''

local function setTriggerId(tid)
  triggerId = tid
  if type(prelude) ~= 'nil' then
    prelude.import(triggerId, 'toon.decode')
    return
  end
  local source = getLoreBooks(triggerId, 'lightboard-prelude')
  if not source or #source == 0 then
    error('Failed to load lightboard-prelude.')
  end
  load(source[1].content, '@prelude', 't')()

  prelude.import(triggerId, 'toon.decode')
end

function onValidate(triggerId, output)
  setTriggerId(triggerId)

  local node = prelude.queryNodes('lb-mini', output)
  if #node == 0 then
    return
  end

  local success, content = pcall(prelude.toon.decode, node[1].content)
  if not success then
    error('InvalidOutput: Invalid TOON format. ' .. tostring(content))
  end

  if type(content.topAds) ~= 'table' then
    error('InvalidOutput: Missing "topAds" array in TOON data.')
  end
  if #content.topAds ~= 2 then
    error('InvalidOutput: "topAds" array must contain exactly 2 ads.')
  end
  for _, ad in ipairs(content.topAds) do
    if #ad.bg ~= 7 or #ad.fg ~= 7 or #ad.border ~= 7 then
      error('InvalidOutput: Ad colors must be in hex format (e.g., #RRGGBB).')
    end
  end

  if #content.bottomAd.bg ~= 7 or #content.bottomAd.fg ~= 7 or #content.bottomAd.border ~= 7 then
    error('InvalidOutput: Ad colors must be in hex format (e.g., #RRGGBB).')
  end
end

return onValidate
