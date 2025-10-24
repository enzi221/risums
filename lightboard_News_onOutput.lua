function onOutput(triggerId, output)
  if not string.find(output, "</lightboard%-news>") then
    output = output .. '\n</lightboard-news>'
  end

  -- Convert 5-letter hex colors to 6-letter format
  output = output:gsub("#([a-fA-F0-9])([a-fA-F0-9])([a-fA-F0-9])([a-fA-F0-9])([a-fA-F0-9])([^a-fA-F0-9])", function(c1, c2, c3, c4, c5, after)
    return "#" .. c1 .. c2 .. c3 .. c4 .. c5 .. c5 .. after
  end)
  -- Handle case where 5-letter hex is at end of string
  output = output:gsub("#([a-fA-F0-9])([a-fA-F0-9])([a-fA-F0-9])([a-fA-F0-9])([a-fA-F0-9])$", function(c1, c2, c3, c4, c5)
    return "#" .. c1 .. c2 .. c3 .. c4 .. c5 .. c5
  end)

  -- Add id attribute if missing
  local tagPattern = "(<lightboard%-news)([^>]*)(>)"
  output = output:gsub(tagPattern, function(openTag, attrs, closeTag)
    -- Check if id attribute already exists
    if attrs:find("id%s*=") then
      return openTag .. attrs .. closeTag
    end

    -- Generate random id
    local randomId = math.random(1, 999)
    local newAttrs = attrs
    if newAttrs:match("%S") then
      -- Has other attributes, add space before id
      newAttrs = newAttrs .. ' id="' .. randomId .. '"'
    else
      -- No other attributes
      newAttrs = ' id="' .. randomId .. '"'
    end

    return openTag .. newAttrs .. closeTag
  end)

  return output
end

return onOutput
