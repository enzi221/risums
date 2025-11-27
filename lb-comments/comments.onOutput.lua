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

  if not string.find(output, '<lb%-comments') then
    return '<lb-lazy id="lb-comments">오류: 빈 응답 수신? 수신한 응답을 보려면 편집 버튼을 누르세요. <!--  ' .. output .. ' --></lb-lazy>'
  end

  if not string.find(output, "</lb%-comments>") then
    output = output .. '\n</lb-comments>'
  end

  local results = {}
  for _, node in ipairs(prelude.queryNodes('lb-comments', output)) do
    table.insert(results, output:sub(node.rangeStart, node.rangeEnd))
  end
  return table.concat(results, '\n\n')
end

return onOutput
