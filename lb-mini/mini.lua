--- Copyright (c) 2025 amonamona
--- CC BY-NC-SA 4.0 https://creativecommons.org/licenses/by-nc-sa/4.0/

--- LightBoard Miniboard

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

  ---@class MiniboardCommentData
  ---@field Author string
  ---@field Content string
  ---@field Time string

  ---@class MiniboardPostData
  ---@field Author string
  ---@field Comments MiniboardCommentData[]
  ---@field Content string
  ---@field Time string
  ---@field Title string
  ---@field Downvotes string
  ---@field Upvotes string

  ---@type MiniboardPostData[]
  local posts = {}

  for _, postBlock in ipairs(prelude.extractBlocks("Post", rawContent)) do
    ---@class MiniboardPostData
    local postData = prelude.parseBlock(postBlock, { "Post", "Comment" })
    postData.Author = postData.Author or "익명"
    postData.Comments = {}

    for _, commentBlock in ipairs(prelude.extractBlocks("Comment", postBlock)) do
      ---@type CommentsCommentData
      local commentData = prelude.parseBlock(commentBlock)
      commentData.Author = commentData.Author or "익명"

      if commentData.Author or commentData.Content then
        table.insert(postData.Comments, commentData)
      end
    end

    table.insert(posts, postData)
  end

  local post_es = {}

  if #posts > 0 then
    for _, post in ipairs(posts) do
      local postTitle = post.Title or "제목 없음"
      local postTime = post.Time or "시간 정보 없음"
      local postUpvotes = post.Upvotes or '1'
      local postDownvotes = post.Downvotes or '1'
      local postContent = post.Content or ""

      local comment_es = {}
      for _, comment in ipairs(post.Comments) do
        local comment_e = h.div['lb-mini-comment'] {
          h.div['lb-mini-meta'] {
            h.span['lb-mini-author'] {
              comment.Author,
            },
            h.span['lb-mini-time'] {
              (comment.Time or "")
            }
          },
          h.p['lb-mini-text'] {
            comment.Content
          }
        }

        table.insert(comment_es, comment_e)
      end

      table.insert(post_es, h.details['lb-mini-post'] {
        name = 'lightboard-miniboard-post',
        h.summary['lb-mini-post-summary'] {
          h.div['lb-mini-post-title-container'] {
            h.span['lb-mini-post-title-text'] {
              postTitle,
            },
            h.div['lb-mini-meta'] {
              h.span['lb-mini-author'] {
                post.Author,
              },
              h.span['lb-mini-time'] {
                postTime,
              },
              h.span {
                "▲ " .. postUpvotes,
              },
              h.span {
                "▼ " .. postDownvotes,
              },
            },
          },
        },
        h.div['lb-mini-post-content'] {
          h.p['lb-mini-text'] {
            postContent,
          },
          h.hr['lb-mini-hr'] { void = true },
          h.div['lb-mini-rowgap lb-mini-comments'] {
            h.div['lb-mini-comments-header'] {
              h.span['lb-mini-comments-heading'] '댓글',
              h.button['lb-mini-btn'] {
                risu_btn = "lb-interaction__lightboard-miniboard__AddComment/Title:" .. postTitle,
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

  local boardTitle = block.attributes.name or "미니보드"
  local html = h.div['lb-module-root'] {
    data_id = 'lightboard-miniboard',
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
          risu_btn = "lb-interaction__lightboard-miniboard__ChangeBoard",
          type = "button",
          "게시판 둘러보기"
        },
        h.button['lb-mini-btn'] {
          risu_btn = "lb-interaction__lightboard-miniboard__AddPost",
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
      risu_btn = 'lb-reroll__lightboard-miniboard',
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

  local extractionSuccess, extractionResult = pcall(prelude.extractNodes, 'lightboard-miniboard', data)
  if not extractionSuccess then
    print("[LightBoard] Miniboard extraction failed:", tostring(extractionResult))
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
        print("[LightBoard] Miniboard parsing failed in block " .. i .. ":", tostring(processResult))
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
      print("[LightBoard] Miniboard display failed:", tostring(result))
      return data
    end
  end
)
