--- Copyright (c) 2025 amonamona
--- CC BY-NC-SA 4.0 https://creativecommons.org/licenses/by-nc-sa/4.0/

--- LightBoard Miniboard

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

---Renders a node into HTML.
---@param node Node
---@return string
local function render(node)
  local rawContent = node.content
  if not rawContent or rawContent == "" then
    return "[LightBoard Error: Empty Content]"
  end

  ---@class MiniboardCommentData
  ---@field author string
  ---@field content string
  ---@field time string

  ---@class MiniboardPostData
  ---@field author string
  ---@field comments MiniboardCommentData[]
  ---@field content string
  ---@field time string
  ---@field title string
  ---@field downvotes string
  ---@field upvotes string

  ---@type MiniboardPostData[]
  local posts = prelude.toon.decode(node.content)

  local post_es = {}
  if #posts > 0 then
    for _, post in ipairs(posts) do
      local comment_es = {}
      for _, comment in ipairs(post.comments) do
        local comment_e = h.div['lb-mini-comment'] {
          h.div['lb-mini-meta'] {
            h.span['lb-mini-author'] {
              comment.author,
            },
            h.span['lb-mini-time'] {
              (comment.time or "")
            }
          },
          h.p['lb-mini-comment-content'] {
            comment.content
          }
        }

        table.insert(comment_es, comment_e)
      end

      table.insert(post_es, h.details['lb-mini-post'] {
        name = 'lb-mini-post',
        h.summary['lb-mini-post-summary'] {
          h.div['lb-mini-post-title-container'] {
            h.span['lb-mini-post-title-text'] {
              post.title,
            },
            h.div['lb-mini-meta'] {
              h.span['lb-mini-author'] {
                post.author,
              },
              h.span['lb-mini-time'] {
                post.time,
              },
              h.span {
                "▲ " .. post.upvotes,
              },
              h.span {
                "▼ " .. post.downvotes,
              },
            },
          },
        },
        h.div['lb-mini-post-content'] {
          h.p {
            post.content,
          },
          h.hr['lb-mini-hr'] { void = true },
          h.div['lb-mini-rowgap lb-mini-comments'] {
            h.div['lb-mini-comments-header'] {
              h.span['lb-mini-comments-heading'] '댓글',
              h.button['lb-mini-btn'] {
                risu_btn = "lb-interaction__lb-mini__AddComment/Title:" .. post.title,
                type = "button",
                h.lb_comment_icon { closed = true },
                "댓글 달기"
              },
            },
            comment_es
          },
        },
      })
    end
  else
    post_es = h.div['lb-no-comments'] {
      style = 'padding: 20px; text-align: center; color: #888;',
      '표시할 게시글 없음',
    }
  end

  local id = 'lb-mini-' .. math.random()

  local boardTitle = node.attributes.name or "미니보드"
  local html = h.div['lb-module-root'] {
    data_id = 'lb-mini',
    h.button['lb-collapsible'] {
      popovertarget = id,
      type = 'button',
      h.span['lb-opener'] {
        h.span '미니보드',
      },
    },
    h.dialog['lb-dialog lb-mini-dialog'] {
      id = id,
      popover = '',
      h.div['lb-mini-header'] {
        h.b {
          boardTitle
        },
        h.button['lb-mini-btn'] {
          risu_btn = "lb-interaction__lb-mini__ChangeBoard",
          type = "button",
          "게시판 둘러보기"
        },
        h.button['lb-mini-btn'] {
          risu_btn = "lb-interaction__lb-mini__AddPost",
          style = 'margin-left:auto',
          type = "button",
          h.lb_comment_icon { closed = true },
          "게시글 쓰기"
        },
      },
      h.div['lb-mini-wrap'] {
        h.div['lb-mini-container lb-mini-rowgap'] {
          post_es,
        },
      },
      h.button['lb-mini-close'] {
        popovertarget = id,
        type = 'button',
        "닫기",
      }
    },
    h.button['lb-reroll'] {
      risu_btn = 'lb-reroll__lb-mini',
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

  local extractionSuccess, extractionResult = pcall(prelude.queryNodes, 'lb-mini', data)
  if not extractionSuccess then
    print("[LightBoard] Miniboard extraction failed:", tostring(extractionResult))
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
      if position < -9 then
        return data
      end
    end

    local success, result = pcall(main, data)
    if success then
      return result
    else
      print("[LightBoard] Miniboard display failed:", tostring(result))
      return data .. '<lb-lazy id="lb-mini">오류: ' .. result .. '</lb-lazy>'
    end
  end
)
