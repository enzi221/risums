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

  if not string.find(output, '<lb%-stats') then
    return '<lb-lazy id="lb-stats">오류: 빈 응답 수신? 수신한 응답을 보려면 편집 버튼을 누르세요. <!--  ' .. output .. ' --></lb-lazy>'
  end

  if not string.find(output, "</lb%-stats>") then
    output = output .. '\n</lb-stats>'
  end

  -- Add keepalive attribute if missing
  local tagPattern = "(<lb%-stats)([^>]*)(>)"
  output = output:gsub(tagPattern, function(openTag, attrs, closeTag)
    if attrs:find("keepalive") then
      return openTag .. attrs .. closeTag
    end

    local newAttrs = attrs
    if newAttrs:match("%S") then
      -- Has other attributes, add space before id
      newAttrs = newAttrs .. ' keepalive'
    else
      -- No other attributes
      newAttrs = ' keepalive'
    end

    return openTag .. newAttrs .. closeTag
  end)

  local allBlocks = prelude.queryNodes('lb-stats', output)
  local body = nil
  if #allBlocks >= 1 then
    body = allBlocks[1]
  end

  if not body then
    print('[LightBoard] No <lb-stats> block found')
    return ''
  end

  return output:sub(body.rangeStart, body.rangeEnd)
end

return onOutput
