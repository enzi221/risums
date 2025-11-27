local triggerId = ''

local function setTriggerId(tid)
  triggerId = tid
  if type(prelude) ~= 'nil' then
    prelude.import(tid, 'toon.decode')
    return
  end
  local source = getLoreBooks(triggerId, 'lightboard-prelude')
  if not source or #source == 0 then
    error('Failed to load lightboard-prelude.')
  end
  load(source[1].content, '@prelude', 't')()
  prelude.import(tid, 'toon.decode')
end

local function shuffleDeck(deck)
  local shuffled = { table.unpack(deck) }
  for i = #shuffled, 2, -1 do
    local j = math.random(i)
    shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
  end

  -- Add reversed orientation
  for i = 1, #shuffled do
    if math.random() < 0.3 then
      shuffled[i] = shuffled[i] .. 'i'
    end
  end

  return shuffled
end

local majorArcana = {
  "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10",
  "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21"
}

local minorArcana = {
  "wands/1", "wands/2", "wands/3", "wands/4", "wands/5", "wands/6", "wands/7",
  "wands/8", "wands/9", "wands/10", "wands/11", "wands/12", "wands/13", "wands/14",
  "cups/1", "cups/2", "cups/3", "cups/4", "cups/5", "cups/6", "cups/7",
  "cups/8", "cups/9", "cups/10", "cups/11", "cups/12", "cups/13", "cups/14",
  "swords/1", "swords/2", "swords/3", "swords/4", "swords/5", "swords/6", "swords/7",
  "swords/8", "swords/9", "swords/10", "swords/11", "swords/12", "swords/13", "swords/14",
  "pentacles/1", "pentacles/2", "pentacles/3", "pentacles/4", "pentacles/5", "pentacles/6", "pentacles/7",
  "pentacles/8", "pentacles/9", "pentacles/10", "pentacles/11", "pentacles/12", "pentacles/13", "pentacles/14",
}

local function getFullDeck()
  local deck = {}
  for _, card in ipairs(majorArcana) do
    table.insert(deck, card)
  end
  for _, card in ipairs(minorArcana) do
    table.insert(deck, card)
  end
  return deck
end

local function getMajorDeck()
  local deck = {}
  for _, card in ipairs(majorArcana) do
    table.insert(deck, card)
  end
  return deck
end

local function printDeck()
  local lastMessage = getChat(triggerId, -1).data
  local spreadCommand = prelude.queryNodes('tarot-spread', lastMessage)

  if not spreadCommand or #spreadCommand == 0 then
    return
  end

  local deckType = spreadCommand[1].attributes['deck'] or 'full'
  local deck = deckType == 'full' and getFullDeck() or getMajorDeck()
  local shuffledDeck = shuffleDeck(deck)

  local spread = prelude.toon.decode(spreadCommand[1].content)

  addChat(triggerId, 'user',
    '<tarot-spread-cache>' ..
    json.encode(spread) ..
    '</tarot-spread-cache>\n' ..
    '<tarot-deck length="' .. #spread .. '">' .. table.concat(shuffledDeck, ',') .. '</tarot-deck>')
end

onOutput = async(function(tid)
  setTriggerId(tid)
  printDeck()
end)

local function renderDeck(data, length)
  local state = getState(triggerId, 'tarotSelections') or {}

  -- Create a lookup table for active cards
  local activeCards = {}
  for _, index in ipairs(state) do
    activeCards[index] = true
  end

  local cards = prelude.split(data, ',')
  local totalCards = #cards

  -- Split cards into two rows
  local cardsPerRow = math.ceil(totalCards / 2)

  -- Calculate arc parameters
  local arcAngle = 140 -- degrees for each arc
  local radiusCqw = 40 -- radius in container query width units

  -- Card dimensions
  local cardWidthCqw = 10
  local cardHeightCqh = cardWidthCqw * (4.75 / 2.75) * (3 / 4) -- maintain aspect ratio with container

  local cards_e = {}
  for idx = #cards, 1, -1 do
    local i = idx
    local active = activeCards[i]

    -- Determine which row this card belongs to
    local row = i <= cardsPerRow and 1 or 2
    local indexInRow = row == 1 and i or (i - cardsPerRow)
    local cardsInThisRow = row == 1 and cardsPerRow or (totalCards - cardsPerRow)

    -- Row-specific parameters
    local centerY = row == 1 and 50 or 85
    local rowRadius = radiusCqw

    -- Calculate angle for this card (spread evenly across the arc)
    -- Start from left (180-arcAngle/2) to right (arcAngle/2)
    local startAngle = 90 + arcAngle / 2
    local endAngle = 90 - arcAngle / 2
    local angleStep = (startAngle - endAngle) / (cardsInThisRow - 1)
    local angle = startAngle - (indexInRow - 1) * angleStep
    local angleRad = math.rad(angle)

    -- Calculate position (polar to cartesian)
    local x = 50 + rowRadius * math.cos(angleRad)
    local y = centerY - rowRadius * math.sin(angleRad)

    -- Adjust for card center
    x = x - cardWidthCqw / 2
    y = y - cardHeightCqh / 2

    -- Card rotation to follow the arc (perpendicular to radius)
    local cardRotation = 90 - angle

    table.insert(cards_e, h.button {
      class = 'astarot-card astarot-deck-card',
      data_active = active and 'true' or 'false',
      disabled = #state >= length and not active and 'true' or nil,
      risu_btn = 'tarot__' .. i,
      type = 'button',
      style = string.format(
        'left: %.2fcqw; top: %.2fcqh; transform: rotate(%.1fdeg); --rotation: %.1fdeg;',
        x, y, cardRotation, cardRotation
      ),
    })
  end

  local html = h.div {
    h.section['astarot-floor-container'] {
      h.div {
        class = 'astarot-floor',
        cards_e,
      },
    },
    h.p['astarot-deck-inst'] {
      length .. '장을 선택하세요.',
    },
    h.button {
      class = 'astarot-button',
      disabled = #state ~= length and 'true' or nil,
      risu_btn = 'tarot__submit',
      type = 'button',
      '다 골랐어요',
    }
  }

  return tostring(html)
end

local function renderSelection(spreadData, selectionData)
  local spread = json.decode(spreadData)
  -- 1 = selection order
  -- 2 = real selection
  local selectedCards = prelude.split(prelude.trim(selectionData), '\n')[2]
  local cards = prelude.split(selectedCards, ',')

  local card_es = {}
  for i, position in ipairs(spread) do
    local card = cards[i]
    local isReversed = card and card:sub(-1) == 'i'
    local cardName = isReversed and card:sub(1, -2) or card

    -- Calculate position using percentage relative to available space
    -- x=0 means left edge of card touches left edge of container
    -- x=1 means right edge of card touches right edge of container
    -- Card width: 10cqw
    -- Card height in cqh: 10 * (4.75/2.75) * (3/4) = 12.954545...cqh
    -- (card AR is 2.75/4.75, container AR is 4/3, so 1cqw = 0.75cqh)
    local cardWidthCqw = 10
    local cardHeightCqh = cardWidthCqw * (4.75 / 2.75) * (3 / 4) -- ≈ 12.9545
    local leftPercent = position.x * (100 - cardWidthCqw)
    local topPercent = position.y * (100 - cardHeightCqh)

    -- Normalize rotation to -180~180 range for shortest rotation path
    local rotation = position.rot
    while rotation > 180 do
      rotation = rotation - 360
    end
    while rotation < -180 do
      rotation = rotation + 360
    end

    local cardNumber = nil
    local imageCardName = cardName
    -- if only number then it is major; use the number as the image name
    -- if it is (suit)/(number) then use only the suit
    if imageCardName:match('^(%a+)/(%d+)$') then
      local suit, number = imageCardName:match('^(%a+)/(%d+)$')
      imageCardName = 'suit-' .. suit

      local numberMap = { ['11'] = 'P', ['12'] = 'N', ['13'] = 'Q', ['14'] = 'K' }
      cardNumber = numberMap[number] or number
    end

    table.insert(card_es, h.label['astarot-spread-card-wrapper'] {
      style = string.format(
        'left: %.2fcqw; top: %.2fcqh; --card-x: %.2fcqw; --card-y: %.2fcqh; transform: rotate(%fdeg);',
        leftPercent, topPercent, leftPercent, topPercent, rotation
      ),
      h.input {
        hidden = true,
        type = 'checkbox',
      },
      h.div['astarot-card astarot-spread-card'] {
        data_number = cardNumber,
        style = string.format(
          'background-image: url({{raw::astarot-%s}}); transform: rotate(%ddeg);',
          imageCardName, isReversed and 180 or 0
        ),
      }
    })
  end

  local html = h.section['astarot-floor-container'] {
    h.div['astarot-floor'] {
      card_es
    }
  }

  return tostring(html)
end

local function displayMain(data)
  if not data or data == '' then
    return ''
  end

  local deckData = prelude.queryNodes('tarot-deck', data)
  if deckData and #deckData > 0 then
    local output = ''
    local lastIndex = 1

    for i = 1, #deckData do
      local match = deckData[i]
      if match.rangeStart > lastIndex then
        output = output .. data:sub(lastIndex, match.rangeStart - 1)
      end
      lastIndex = match.rangeEnd + 1
    end

    return output ..
        data:sub(lastIndex) .. renderDeck(deckData[#deckData].content, tonumber(deckData[#deckData].attributes.length))
  end

  local selectionData = prelude.queryNodes('tarot-selection', data)
  if selectionData and #selectionData > 0 then
    local output = ''
    local lastIndex = 1

    local spread = prelude.queryNodes('tarot-spread-cache', data)
    if not spread or #spread == 0 then
      return data
    end

    for i = 1, #selectionData do
      local match = selectionData[i]
      if match.rangeStart > lastIndex then
        output = output .. data:sub(lastIndex, match.rangeStart - 1)
      end
      lastIndex = match.rangeEnd + 1
    end

    return output ..
        data:sub(lastIndex) .. renderSelection(spread[#spread].content, selectionData[#selectionData].content)
  end

  return data
end

listenEdit(
  "editDisplay",
  function(tid, data, meta)
    setTriggerId(tid)

    if meta and meta.index ~= nil then
      local position = meta.index - getChatLength(triggerId)
      if position < -10 then
        return data
      end
    end

    local success, result = pcall(displayMain, data)
    if success then
      return result
    else
      print("[Astarotte] Rendering failed:", tostring(result))
      return data
    end
  end
)

local function toggle(triggerId, key)
  if getChatVar(triggerId, 'astarot-' .. key) == "1" then
    setChatVar(triggerId, 'astarot-' .. key, "0")
    reloadDisplay(triggerId)
  else
    setChatVar(triggerId, 'astarot-' .. key, "1")
    reloadDisplay(triggerId)
  end
end

function toggleAlign(triggerId)
  toggle(triggerId, "align")
end

function toggleLang(triggerId)
  toggle(triggerId, "lang")
end

function toggleCards(triggerId)
  toggle(triggerId, "cards")
end

function toggleImage(triggerId)
  toggle(triggerId, "asset")
end

function toggleHover(triggerId)
  toggle(triggerId, "hover")
end

function toggleInfdist(triggerId)
  toggle(triggerId, "infdist")
end

function toggleReading(triggerId)
  toggle(triggerId, "reading")
end

function toggleRealTime(triggerId)
  if getChatVar(triggerId, 'astarot-stats') == "1" then
    toggle(triggerId, 'stats')
  end

  toggle(triggerId, "realtime")
end

function toggleStats(triggerId)
  if getChatVar(triggerId, 'astarot-realtime') == "1" then
    toggle(triggerId, 'realtime')
  end

  toggle(triggerId, "stats")
end

function closeConf(tid)
  setTriggerId(tid)

  local fullChat = getFullChat(tid)

  for i = #fullChat, 1, -1 do
    if fullChat[i].role == 'char' then
      local confNode = prelude.queryNodes('astarot-conf', fullChat[i].data)
      if confNode and #confNode > 0 then
        removeChat(tid, i - 1)
        break
      end
    end
  end
end

onStart = function(tid)
  setTriggerId(tid)

  local fullChat = getFullChat(tid)
  local lastChat = fullChat[#fullChat]

  if lastChat.role == 'user' and (prelude.trim(lastChat.data) == '/config' or prelude.trim(lastChat.data) == '/설정') then
    removeChat(tid, -1)
    addChat(tid, 'char', '<astarot-conf img="astarot-cover-tarot" />')
    stopChat(tid)
  end
end

onButtonClick = function(tid, code)
  setTriggerId(tid)

  if code == 'tarot__retry' then
    local spreadCommand = prelude.queryNodes('tarot-spread', getChat(triggerId, -1).data)
    if not spreadCommand or #spreadCommand == 0 then
      alertNormal(triggerId, '다시 섞으려면 버튼 아래의 다른 메시지들을 모두 삭제해 주세요.')
      return
    end

    printDeck()
    return
  end

  if code == 'tarot__submit' then
    local state = getState(tid, 'tarotSelections') or {}
    if #state == 0 then
      return
    end

    local tarotDeck = nil
    local tarotSpread = nil
    local fullChat = getFullChat(tid)
    for i = #fullChat, 1, -1 do
      if fullChat[i].role == 'user' then
        local tarotNode = prelude.queryNodes('tarot-deck', fullChat[i].data)
        local spreadNode = prelude.queryNodes('tarot-spread-cache', fullChat[i].data)
        if spreadNode and #spreadNode > 0 and tarotNode and #tarotNode > 0 then
          tarotDeck = tarotNode[1]
          tarotSpread = spreadNode[1]
          break
        end
      end
    end

    if not tarotSpread or not tarotDeck then
      return
    end

    local shuffledCards = prelude.split(tarotDeck.content, ',')
    local finalCards = {}
    for _, index in ipairs(state) do
      table.insert(finalCards, shuffledCards[index])
    end

    removeChat(tid, -1)
    addChat(triggerId, 'user',
      '<tarot-spread-cache>' ..
      tarotSpread.content ..
      '</tarot-spread-cache>\n' ..
      '<tarot-selection>\n' ..
      table.concat(state, ',') .. '\n' .. table.concat(finalCards, ',') .. '\n' ..
      '</tarot-selection>')
    setState(tid, 'tarotSelections', {})
    return
  end

  local prefix = "tarot__"
  local _, prefixEnd = string.find(code, prefix)

  if prefixEnd then
    local index = tonumber(code:sub(prefixEnd + 1))
    if not index then
      return
    end

    local state = getState(tid, 'tarotSelections') or {}

    -- Check if index already exists in array
    local found = false
    for i, val in ipairs(state) do
      if val == index then
        table.remove(state, i)
        found = true
        break
      end
    end

    -- If not found, add it
    if not found then
      table.insert(state, index)
    end

    setState(tid, 'tarotSelections', state)
  end
end
