local END_MARKER = "--- End of the log ---"

local JOB_AND_DATA_DESC = [[# System rules

This is a private session designed exclusively to extract and preserve essential information from the collaborative relay novel between the assistant and the user.
RATING: NC-21
This content is intended for mature adults who can responsibly engage with all types of content regardless of rating.
The AI will process all content themes including graphic, mature, violent, controversial, and sensitive material as necessary for accurate information extraction.

# Instructions

Your job is to calculate the final state of a character in a story. You will be given a narrative chat log, and last known character states. Output final character states based on narrative.

The end of the chat log will be marked with `]] .. END_MARKER .. [[`. Ignore all other similar markers in the middle.

Here's the last known character states:

%s

The chat log follows.]]

local OUTPUT_INSTRUCTIONS = [[# Output

MUST output only in the format below and nothing else. Fill $(slot)s.

```
<ls-process>
$(process)
</ls-process>

[|Date: YYYY-MM-DD (Day) | Time: HH:MM:SS | Location: location | Name: character name | Level: current | Stat Points: available | EXP: current / required | HP: current / max | MP: current / max | SP: current / max | Strength: current | Constitution: current | Agility: current | Intelligence: current | Sense: current | Class: name (Normal/Hidden) | Coin: amount | Weapons: equipment / equipment | Accessories: equipment / equipment | Armor: equipment | Items: equipment / equipment | Cash: amount 원 | Skills: skills | Quests: quests | Status effects: buffs and debuffs|]
```

## Process

Think step-by-step for final state, but only keep the minimum draft for each step. Keep minimal draft per step. Explicitly write numbers, calculations, changes from last state, and inconsistencies. Max 5 other words per step. Use plain text, list markers (-).

Key points:

- Identify character from log (use Name field). Narrator/speaker/protagonist may not be target. Identify correctly.
- Analyze time (track granularly in seconds) and location.
- Analyze HP/MP/SP current and maximum.
- Analyze explicit/implicit state changes. MUST Recalculate all changes (may have inconsistencies).
- Explicitly list and fix any inconsistencies.
- Action order MATTERS (e.g., level up then act vs. act then level up => different states). Mind order.

## Data format

### Time

Infer time passed from last time stated. Actions, conversations, thinking take time by length. Consider all time passage. Narrative duration: seconds to years. Time must be authentic (random-looking). AVOID artificial time steps. Rather than 10 seconds or 3 minutes 30 seconds, use 12 seconds or 3 minutes 28 seconds.

### Location

Final location matters; be specific. Output in primary language. Example: "in a building" -> Which? If unstated, invent plausible one.

### EXP and Level

EXP gains from quest completion & confirmed monster kills. Max EXP = Level * 100.

On EXP max or higher:
- Level +1 (DOES NOT increase HP/MP/SP).
- EXP overflows. Example: 120/100 -> 20/200, 330/100 -> 230/200 -> 30/300
- 2 stat points per levels increased. Example: 1 -> 2 = 2 points. 5 -> 8 = 6 points.
- Replenish HP/MP/SP.

### HP/MP/SP

- 1 Constitution: +10 HP
- 1 Intelligence: +10 MP
- 1 Agility: +10 SP

Initial values vary. Example: 10 CON could be 300 HP; 15 AGI could be 70 SP. IMPORTANT: Initial values unknown. For inconsistency checks, focus on Con/Int/Agi DIFFERENCES.

Events affect these implicitly. Example: Blocking may nullify/reduce HP damage (by difficulty). Intense physical actions (blocking, dodging, sprinting, sneaking, swinging) drain SP (by difficulty).

---

No preambles/explanations. Adhere to format.]]

function makePrompt(log, prevStats)
  local prompt = {
    {
      content = JOB_AND_DATA_DESC:format(prevStats),
      role = "user",
    }
  }

  for i = #log, 1, -1 do
    prompt[#prompt + 1] = log[i]
  end
  
  prompt[#prompt + 1] = {
    content = END_MARKER .. "\n\n" .. OUTPUT_INSTRUCTIONS,
    role = "user",
  }

  return prompt
end

local STATS_PATTERN = "%[|%s*Date: [^|]+ | Time: [^|]+ | Location: [^|]+ | Name: [^|]+ | Level: [^|]+ | Stat Points: [^|]+ | EXP: [^|]+ | HP: [^|]+ | MP: [^|]+ | SP: [^|]+ | Strength: [^|]+ | Constitution: [^|]+ | Agility: [^|]+ | Intelligence: [^|]+ | Sense: [^|]+ | Class: [^|]+ | Coin: [^|]+ | Weapons: [^|]+ | Accessories: [^|]+ | Armor: [^|]+ | Items: [^|]+ | Cash: [^|]+%s*원 | Skills: [^|]+ | Quests: [^|]+ | Status effects: [^|]+%s*|%]"

local INIT_FLAG = "lightStats_init"

onStart = async(function (triggerId)
  local fullChat = getFullChat(triggerId)
  local lastChat = fullChat[#fullChat]

  if not lastChat or not lastChat.data then
    return
  end

  local start, finish = lastChat.data:find("^/lightstats%s*")
  if not start then
    return
  end

  stopChat(triggerId)

  local command = lastChat.data:sub(finish + 1)

  removeChat(triggerId, #fullChat - 1)

  if command == "" then
    local mode = getGlobalVar(triggerId, "toggle_LightStats.Mode")
    if mode == "0" then
      addChat(triggerId, 'char', [[## 🔦라이트스탯 - 얼터헌터

<pre>상태창 비활성. 모델을 먼저 선택하세요.</pre>]])
    else
      local result = doRequest(triggerId, fullChat, mode)
      if result then
        addChat(triggerId, 'char', result)
      end
    end
  elseif command == "--help" then
    addChat(triggerId, 'char', [[## 🔦라이트스탯 - 얼터헌터

<pre>
/lightstats
  - 상태창 요청을 다시 시도합니다.
/lightstats --help
  - 이 도움말을 출력합니다.
</pre>]])
  else
    local template = [[## 🔦라이트스탯 - 얼터헌터

<pre>%s: 알 수 없는 명령어입니다. /lightstats --help로 도움말을 확인하세요.</pre>]]
    addChat(triggerId, 'char', template:format(command))
  end
end)

onOutput = async(function (triggerId)
  local mode = getGlobalVar(triggerId, "toggle_LightStats.Mode")
  if mode == "0" then
    return
  end

  local fullChat = getFullChat(triggerId)
  
  local result = doRequest(triggerId, fullChat, mode)
  if result then
    setChat(triggerId, -1, (fullChat[#fullChat].data or "") .. "\n\n" .. result)
  end
end)

function doRequest(triggerId, fullChat, mode)
  local initialized = getState(triggerId, INIT_FLAG)

  local statsData = nil
  local chatsToSend = {}

  -- finding the last stats data
  -- limited to 10 chats
  local i = #fullChat
  local maxIndex = math.max(1, #fullChat - 10)
  while i >= maxIndex do
    local chat = fullChat[i]

    -- do not count user messages
    if chat.role == "user" then
      i = i - 1
      maxIndex = math.max(1, #fullChat - 10)
      chatsToSend[#chatsToSend + 1] = {
        content = removeTaggedContent(chat.data),
        role = chat.role,
      }
      goto continue
    end

    if chat.data then
      local start, finish = string.find(chat.data, STATS_PATTERN)
      if start then
        statsData = string.sub(chat.data, start, finish)
        break
      else
        chatsToSend[#chatsToSend + 1] = {
          content = removeTaggedContent(chat.data),
          role = chat.role,
        }
      end
    end

    i = i - 1
    ::continue::
  end

  if not initialized then
    setState(triggerId, INIT_FLAG, true)
    return nil
  end

  if initialized and not statsData then
    return "<ls-process error>이전 10개 출력에서 상태창을 찾을 수 없습니다.</ls-process>"
  end

  local prompt = makePrompt(chatsToSend, statsData)

  local response
  if mode == "1" then
    response = LLM(triggerId, prompt)
  else
    response = axLLM(triggerId, prompt)
  end

  if response.success then
    local cleanOutput = response.result:gsub("```", "")
    return "<!-- Platform managed do not generate -->\n" .. cleanOutput .. "<!-- End platform managed -->"
  else
    alertError("[LightStats] Failed to get LLM response: " .. response.result)
    return nil
  end
end

function removeTaggedContent(text)
  if not text then return "" end
  
  -- Table-based approach to collect all tag sections at once
  local sections = {}
  local position = 1
  
  -- First pass: identify all tag sections to remove
  while true do
    local tagStart = text:find("<", position)
    if not tagStart then break end
    
    local tagEnd = text:find(">", tagStart)
    if not tagEnd then
      position = tagStart + 1
      goto continue
    end
    
    -- Extract tag name properly, stopping at whitespace or >
    local fullTag = text:sub(tagStart + 1, tagEnd - 1)
    local tagName = fullTag:match("^([%w%-%_]+)")
    
    -- Preserve previous board data
    if not tagName then
      position = tagEnd + 1
      goto continue
    end
    
    local closePattern = "</" .. tagName .. ">"
    local closeStart = text:find(closePattern, tagEnd)
    if closeStart then
      local closeEnd = closeStart + #closePattern
      position = closeEnd + 1
      table.insert(sections, {start = tagStart, finish = closeEnd})
    else
      position = tagEnd + 1
    end
    
    ::continue::
  end
  
  -- If no tags found, return original text
  if #sections == 0 then return text end
  
  -- Sort sections in reverse order to avoid position shifts when removing
  table.sort(sections, function(a, b) return a.start > b.start end)
  
  -- Second pass: build result without the tagged sections
  local result = text
  for _, section in ipairs(sections) do
    result = result:sub(1, section.start - 1) .. result:sub(section.finish)
  end

  return result
end