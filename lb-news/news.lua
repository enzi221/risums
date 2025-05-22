--- Copyright (c) 2025 amonamona
--- CC BY-NC-SA 4.0 https://creativecommons.org/licenses/by-nc-sa/4.0/

--- LightBoard News

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

---Renders a node into HTML.
---@param block table
---@return string
local function render(block)
  local rawContent = block.content
  if not rawContent or rawContent == "" then
    return "[LightBoard Error: Empty Content]"
  end

  ---@class NewsArticleData
  ---@field Category string
  ---@field Content string
  ---@field Time string
  ---@field Title string

  ---@class NewsAdData
  ---@field BgColor string
  ---@field Content string
  ---@field FgColor string

  ---@type NewsArticleData[]
  local posts = {}

  ---@type NewsAdData[]
  local ads = {}

  for _, postBlock in ipairs(prelude.extractBlocks("Post", rawContent)) do
    ---@class NewsArticleData
    local postData = prelude.parseBlock(postBlock, { "Ad", "Post" })
    table.insert(posts, postData)
  end

  for _, adBlock in ipairs(prelude.extractBlocks("Ad", rawContent)) do
    ---@class NewsArticleData
    local adData = prelude.parseBlock(adBlock, { "Ad", "Post" })
    table.insert(ads, adData)
  end

  local headline = nil
  local other_posts = {}

  if #posts > 0 then
    for i, post in ipairs(posts) do
      local postContent = post.Content or ""
      local isHeadline = (i == 1)

      local article = h.div['lb-news-article'] {
        name = 'lightboard-news-post',
        title = isHeadline and '' or postContent,
        isHeadline and h.div['lb-news-image'] {
          -- Placeholder image
        } or nil,
        h.div['lb-news-header-container'] {
          h.div['lb-news-category'] {
            post.Category,
          },
          h.h2['lb-news-title'] {
            post.Title,
          },
        },
        h.div['lb-news-content'] {
          h.p['lb-news-text'] {
            postContent,
          },
        },
        h.div['lb-news-meta'] {
          h.span['lb-news-time'] {
            post.Time,
          },
        },
      }

      if isHeadline then
        headline = article
      else
        table.insert(other_posts, article)
      end
    end
  end

  -- Build ad (first one only)
  local ad_el = nil
  if #ads > 0 then
    local ad = ads[1]
    ad_el = h.div['lb-news-ad'] {
      style = 'background-color: ' .. (ad.BgColor or '#f0f0f0') .. '; color: ' .. (ad.FgColor or '#333333') .. ';',
      h.p['lb-news-ad-content'] {
        ad.Content,
      },
    }
  end

  local boardTitle = block.attributes.name or "뉴스"
  local id = block.attributes.id or "0"
  local html = h.div['lb-module-root'] {
    data_id = 'lightboard-news',
    h.button['lb-collapsible'] {
      popovertarget = 'lb-news' .. id,
      type = 'button',
      h.span['lb-opener'] {
        h.span { boardTitle },
      },
    },
    h.dialog['lb-dialog lb-news-dialog'] {
      id = 'lb-news' .. id,
      popover = '',
      h.div['lb-news-header'] {
        h.h1['lb-news-title'] {
          boardTitle
        },
        h.div['lb-news-header-buttons'] {
          h.button['lb-news-btn'] {
            risu_btn = 'lb-interaction__lightboard-news__id=' .. id .. '#ChangeBoard',
            type = 'button',
            '다른 뉴스 보기'
          },
          h.button['lb-news-btn'] {
            risu_btn = 'lb-interaction__lightboard-news__preserve#ChangeBoard',
            type = 'button',
            '다른 뉴스 보기 (새 창)'
          },
        }
      },
      h.div['lb-news-body'] {
        h.div['lb-news-grid'] {
          headline or h.div['lb-news-empty'] {
            style = 'padding: 20px; text-align: center; color: #888;',
            '뉴스가 없습니다.',
          },
          #other_posts > 0 and h.div['lb-news-list'] {
            other_posts,
          } or nil,
        },
        ad_el,
      },
      h.button['lb-news-dialog-close'] {
        popovertarget = 'lb-news' .. id,
        type = 'button',
        "닫기",
      }
    },
    h.button['lb-reroll'] {
      risu_btn = 'lb-reroll__lightboard-news#' .. id,
      type = 'button',
      h.lb_reroll_icon { closed = true }
    },
  }

  return tostring(html)
end

local function main(data)
  if not data or data == "" then
    return ""
  end

  local output = ""
  local lastIndex = 1

  local extractionSuccess, extractionResult = pcall(prelude.extractNodes, 'lightboard-news', data)
  if not extractionSuccess then
    print("[LightBoard] News extraction failed:", tostring(extractionResult))
    return data
  end

  if extractionResult and #extractionResult > 0 then
    for i, match in ipairs(extractionResult) do
      if match.rangeStart > lastIndex then
        output = output .. data:sub(lastIndex, match.rangeStart - 1)
      end
      local processSuccess, processResult = pcall(render, match)
      if processSuccess then
        output = output .. processResult
      else
        print("[LightBoard] News parsing failed in block " .. i .. ":", tostring(processResult))
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

    local success, result = pcall(main, data)
    if success then
      return result
    else
      print("[LightBoard] News display failed:", tostring(result))
      return data
    end
  end
)
