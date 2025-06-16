--- Copyright (c) 2025 amonamona
--- CC BY-NC-SA 4.0 https://creativecommons.org/licenses/by-nc-sa/4.0/

--- LightBoard Guide

local triggerId = ''

local function setTriggerId(tid)
  triggerId = tid
  if type(prelude) ~= "nil" then return end
  local source = getLoreBooks(triggerId, 'lightboard-prelude')
  if not source or #source == 0 then
    error('Failed to load lightboard-prelude.')
  end
  load(source[1].content, '@prelude', 't')()
end

--- @param str string
--- @return string
local function escapeQuotes(str)
  if not str then
    return ""
  end
  local result = {}
  for character in str:gmatch("([%z\1-\127\194-\244][\128-\191]*)") do
    if character == '"' or character == "“" or character == "”" then
      table.insert(result, "&#34;")
    elseif character == "'" or character == "‘" or character == "’" then
      table.insert(result, "&#39;")
    else
      table.insert(result, character)
    end
  end
  return table.concat(result)
end

---Renders a node into HTML.
---@param block table
---@return string
local function render(block)
  local rawContent = block.content
  if not rawContent or rawContent == "" then
    return "[LightBoard Error: Empty Content]"
  end

  local reviewBlockStrings = prelude.extractBlocks("Review", rawContent)
  if not reviewBlockStrings or #reviewBlockStrings == 0 then
    return "[LightBoard Guide: Missing Review block]"
  end
  local reviewData = prelude.parseBlock(reviewBlockStrings[1], { "Direction" })

  if not reviewData.Score or not reviewData.Content then
    return ''
  end

  local directionBlockStrings = prelude.extractBlocks("Direction", rawContent)
  local directionsData = {}
  for _, dirBlockString in ipairs(directionBlockStrings) do
    table.insert(directionsData, prelude.parseBlock(dirBlockString))
  end


  local directionsRow_e = nil

  if #directionsData > 0 then
    local gradientClasses = { "lb-guide-gradient-1", "lb-guide-gradient-2", "lb-guide-gradient-3" }

    local directions_es = {}
    for i, dirData in ipairs(directionsData) do
      local gradientClass = gradientClasses[((i - 1) % #gradientClasses) + 1] -- Cycle through gradients

      table.insert(directions_es, h.button['lb-guide-direction-card lb-guide-card'] {
        type = "button",
        risu_btn = "lb-guide__" .. escapeQuotes(dirData.Content or ""),
        h.div['lb-guide-direction-keyword-header ' .. gradientClass] {
          dirData.Keywords or "Keywords"
        },
        h.div['lb-guide-direction-card-body'] {
          h.span['lb-guide-outcome'] { dirData.Outcome or "" },
          h.span['lb-guide-content'] { dirData.Content or "" },
          h.span['lb-guide-why'] { dirData.Why or "" },
          h.span['lb-guide-direction-score'] { (dirData.Score or '?') .. '/5' }
        }

      })
    end

    directionsRow_e = h.div['lb-guide-directions-row'] {
      directions_es
    }
  end

  local html = h.div['lb-module-root'] {
    data_id = "lightboard-guide",
    h.details['lb-collapsible lb-collapsible-animated'] {
      name = "lightboard-guide",
      h.summary['lb-opener'] {
        h.span "가이드",
      },
      h.div['lb-guide-component-container'] {
        h.div['lb-guide-review-card lb-guide-card'] {
          h.span['lb-guide-content'] { reviewData.Content },
          h.div['lb-guide-score-container'] {
            h.div['lb-guide-score-label'] { "Confidence Score " .. reviewData.Score .. "/5" },
            h.div['lb-guide-score'] {
              data_value = reviewData.Score or 0
            }
          }
        },
        directionsRow_e,
      }
    },
    h.button['lb-reroll'] {
      risu_btn = "lb-reroll__lightboard-guide",
      type = "button",
      h.lb_reroll_icon { closed = true }
    }
  }

  return tostring(html)
end

local function main(tid, data)
  if not data or data == "" then
    return ""
  end

  local output = ""
  local lastIndex = 1

  local success, extractionResult = pcall(prelude.extractNodes, "lightboard-guide", data)
  if success then
  else
    print("[LightBoard] Guide extraction failed:", tostring(extractionResult))
    return data
  end

  if extractionResult and #extractionResult > 0 then
    for i, match in ipairs(extractionResult) do
      if match.rangeStart > lastIndex then
        output = output .. data:sub(lastIndex, match.rangeStart - 1)
      end
      local processSuccess, renderResult = pcall(render, match)
      if processSuccess then
        output = output .. renderResult
      else
        print("[LightBoard] Guide parsing failed in block " .. i .. ":", tostring(renderResult))
        output = output .. "\n\n<!-- LightBoard Block Error -->"
      end
      lastIndex = match.rangeEnd + 1
    end
  else
    lastIndex = 1
  end

  if lastIndex <= #data then
    output = output .. data:sub(lastIndex)
  end

  return output
end

local function onButton(tid, code)
  local prefix = "lb%-guide__"
  local _, endIndex = string.find(code, prefix)
  if not endIndex then
    return
  end

  setTriggerId(tid)
  local body = code:sub(endIndex + 1)
  addChat(tid, "user", body)
end

onButtonClick = async(function(tid, code)
  local success, result = pcall(onButton, tid, code)
  if not success then
    print("[LightBoard] Guide button click failed:", tostring(result))
  end
  return result
end)

listenEdit(
  "editDisplay",
  function(tid, data, meta)
    setTriggerId(tid)

    if meta and meta.index ~= nil then
      local position = meta.index - getChatLength(triggerId)
      if position < -5 then
        return data
      end
    end

    local success, result = pcall(main, tid, data)
    if success then
      return result
    else
      print("[LightBoard] Guide display failed:", tostring(result))
      return data
    end
  end
)
