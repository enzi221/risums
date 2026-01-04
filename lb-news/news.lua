--! Copyright (c) 2025-2026 amonamona
--! CC BY-NC-SA 4.0 https://creativecommons.org/licenses/by-nc-sa/4.0/
--! LightBoard News

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

--- Formats a YYYY-MM-DD date string into "YYYY년 MM월 DD일"
--- @param dt string|nil
--- @return string|nil
local function formatDate(dt)
  if not dt then return nil end
  local y, m, d = dt:match("(%d%d%d%d)-(%d%d)-(%d%d)")
  if y and m and d then
    return string.format("%d년 %d월 %d일", tonumber(y), tonumber(m), tonumber(d))
  end
  return dt
end

--- Preprocess raw content to convert annotations and line breaks.
--- @param content string
--- @return string|table
local function preprocessContent(content)
  if not content then return '' end

  local processed = content:gsub("%[hx;(.-);(.-)]", function(text, annot)
    return '<span class="lb-news-annot" data-annot="' .. annot .. '">' .. text .. '</span>'
  end)

  processed = processed:gsub('\\n', '<br>')

  return hraw(processed) or ''
end

---Renders a node into HTML.
---@param node Node
---@return string
local function render(node)
  local rawContent = node.content
  if not rawContent or rawContent == "" then
    return "[LightBoard Error: Empty Content]"
  end

  ---@class NewsArticleData
  ---@field category string
  ---@field content string
  ---@field time string
  ---@field title string

  ---@class NewsAdData
  ---@field boxStyle string
  ---@field content string
  ---@field textStyle string

  local parsed = prelude.toon.decode(node.content)

  ---@type NewsArticleData[]
  local posts = parsed.posts

  ---@type NewsAdData[]
  local topAds = parsed.topAds

  local topAd1 =
      h.div['lb-news-ad-small'] {
        style = topAds[1].boxStyle,
        h.p['lb-news-ad-small-content'] {
          style = topAds[1].textStyle,
          preprocessContent(topAds[1].content),
        },
      }

  local topAd2 =
      h.div['lb-news-ad-small'] {
        style = topAds[2].boxStyle,
        h.p['lb-news-ad-small-content'] {
          style = topAds[2].textStyle,
          preprocessContent(topAds[2].content),
        },
      }

  ---@type NewsAdData
  local bottomAd = parsed.bottomAd

  local headline = nil
  local other_posts = {
    topAd1,
  }

  if #posts > 0 then
    for i, post in ipairs(posts) do
      local isHeadline = (i == 1)

      local article = h.div['lb-news-article'] {
        name = 'lb-news-post',
        isHeadline and h.div['lb-news-image'] {
          -- Placeholder image
        } or nil,
        h.div['lb-news-header-container'] {
          h.div['lb-news-category'] {
            post.category,
          },
          h.h2['lb-news-title'] {
            preprocessContent(post.title),
          },
        },
        h.div['lb-news-content'] {
          h.p['lb-news-text'] {
            preprocessContent(post.content),
          },
        },
        h.div['lb-news-meta'] {
          h.span['lb-news-time'] {
            post.time,
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
  table.insert(other_posts, topAd2)

  local boardTitle = node.attributes.name or "뉴스"
  local datetime = formatDate(node.attributes.datetime)
  local id = node.attributes.id or "0"
  local html = h.div['lb-module-root'] {
    data_id = 'lb-news',
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
      h.div['lb-news-nav'] {
        h.div['lb-news-nav-buttons'] {
          h.button['lb-news-btn'] {
            risu_btn = 'lb-interaction__lb-news__id=' .. id .. '#ChangeBoard',
            type = 'button',
            '다른 뉴스 보기'
          },
          h.button['lb-news-btn'] {
            risu_btn = 'lb-interaction__lb-news__preserve#ChangeBoard',
            type = 'button',
            '다른 뉴스 보기 (새 창)'
          },
        }
      },
      h.div['lb-news-body'] {
        h.header['lb-news-header'] {
          topAd1,
          h.h1['lb-news-network'] {
            boardTitle
          },
          topAd2,
        },
        datetime and h.div['lb-news-date-bar'] {
          h.p['lb-news-date'] {
            datetime
          }
        } or nil,
        h.div['lb-news-grid'] {
          headline or h.div['lb-news-empty'] {
            style = 'padding: 20px; text-align: center; color: #888;',
            '뉴스가 없습니다.',
          },
          #other_posts > 0 and h.div['lb-news-list'] {
            other_posts,
          } or nil,
        },
        h.div['lb-news-ad'] {
          style = bottomAd.boxStyle,
          h.p['lb-news-ad-content'] {
            style = bottomAd.textStyle,
            preprocessContent(bottomAd.content),
          },
        }
      },
      h.button['lb-news-dialog-close'] {
        popovertarget = 'lb-news' .. id,
        type = 'button',
        "닫기",
      }
    },
    h.button['lb-reroll'] {
      risu_btn = 'lb-reroll__lb-news#' .. id,
      type = 'button',
      h.lb_reroll_icon { closed = true }
    },
  }

  return tostring(html)
end

local function main(data)
  if not data or data == '' then
    return ''
  end

  local extractionSuccess, extractionResult = pcall(prelude.queryNodes, 'lb-news', data)
  if not extractionSuccess then
    print("[LightBoard] News extraction failed:", tostring(extractionResult))
    return data
  end

  local lastResult = extractionResult and extractionResult[#extractionResult] or nil
  if not lastResult then
    return data
  end

  local output = ''
  local lastIndex = 1

  for i = 1, #extractionResult do
    local match = extractionResult[i]
    if match.rangeStart > lastIndex then
      output = output .. data:sub(lastIndex, match.rangeStart - 1)
    end
    if i == #extractionResult then
      -- render lastResult in its original position
      output = output .. render(lastResult)
    end
    lastIndex = match.rangeEnd + 1
  end

  return output .. data:sub(lastIndex)
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
      return data .. '<lb-lazy id="lb-news">오류: ' .. result .. '</lb-lazy>'
    end
  end
)
