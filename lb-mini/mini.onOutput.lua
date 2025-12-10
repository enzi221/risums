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

function onOutput(triggerId, output)
  setTriggerId(triggerId)

  if not string.find(output, '<lb%-mini') then
    return nil
  end

  if not string.find(output, "</lb%-mini>") then
    output = output .. '\n</lb-mini>'
  end

  local results = {}
  for _, node in ipairs(prelude.queryNodes('lb-mini', output)) do
    table.insert(results, output:sub(node.rangeStart, node.rangeEnd))
  end
  return table.concat(results, '\n\n')
end

return onOutput
