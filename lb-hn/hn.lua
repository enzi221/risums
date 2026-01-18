--! Copyright (c) 2025-2026 amonamona
--! CC BY-NC-SA 4.0 https://creativecommons.org/licenses/by-nc-sa/4.0/
--! LightBoard HunterNet

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

---@param author string
---@return { ip: string?, name: string, rank: string?, authorType?: 'F' | 'S' }
local function parseAuthorInfo(author)
  local fs, nick, rank = table.unpack(prelude.split(author, ':'))
  if rank then
    return {
      ip = nil,
      name = nick or 'ㅇㅇ',
      rank = rank,
      authorType = fs
    }
  else
    local nick_, ip = table.unpack(prelude.split(author, '('))
    return {
      ip = (ip or ''):sub(1, -2),
      name = nick_ or 'ㅇㅇ',
      rank = nil,
      authorType = nil
    }
  end
end

---@param authorData { author: string; authorIP: string?; authorRank: string?; authorType?: 'F' | 'S'?; }
---@return table
local function assembleAuthorDisplay(authorData)
  local hunterRankDisplay = nil
  if authorData.authorRank and authorData.authorRank ~= "" then
    hunterRankDisplay = h.span['lb-hn-level lb-hn-rank-' ..
    string.lower(authorData.authorRank)] {
      authorData.authorRank
    }
  end

  local nickTypeIcon = nil
  if authorData.authorType == 'F' then
    nickTypeIcon = h.span['lb-hn-icon-fixed'] "고"
  elseif authorData.authorType == 'S' then
    nickTypeIcon = h.span['lb-hn-icon-semi'] "반"
  end

  local ip = nil
  if authorData.authorIP and authorData.authorIP ~= "" then
    ip = h.span['lb-hn-writer-ip'] {
      "(" .. authorData.authorIP .. ")"
    }
  end

  return {
    hunterRankDisplay or '',
    authorData.author,
    nickTypeIcon or '',
    ip or '',
  }
end

local function render(node, chatIndex)
  local rawContent = node.content
  if not rawContent or rawContent == "" then
    return "[LightBoard Error: Empty Content]"
  end

  ---@class HNCommentData
  ---@field author string
  ---@field authorIP string?
  ---@field authorRank string?
  ---@field authorType 'F'|'S'?
  ---@field content string

  ---@class HNPostData
  ---@field author string
  ---@field authorIP string?
  ---@field authorRank string?
  ---@field authorType 'F'|'S'?
  ---@field comments HNCommentData[]
  ---@field content string
  ---@field id string
  ---@field time string
  ---@field title string
  ---@field upvotes string
  ---@field views string

  ---@type HNPostData[]
  local posts = prelude.toon.decode(node.content)

  for _, post in ipairs(posts) do
    local author = parseAuthorInfo(post.author or '')
    post.author = author.name
    post.authorIP = author.ip
    post.authorRank = author.rank
    post.authorType = author.authorType

    for _, comment in ipairs(post.comments or {}) do
      local commentAuthor = parseAuthorInfo(comment.author or '익명')
      comment.author = commentAuthor.name
      comment.authorIP = commentAuthor.ip
      comment.authorRank = commentAuthor.rank
      comment.authorType = commentAuthor.authorType
    end
  end

  local id = 'lb-hn-' .. math.random()
  local post_es = {}

  if #posts > 0 then
    for pi, post in ipairs(posts) do
      local comment_es = {}
      for ci, comment in ipairs(post.comments or {}) do
        local comment_e = h.li['lb-hn-comment-item'] {
          h.span['lb-hn-comment-author'] {
            assembleAuthorDisplay(comment),
          },
          comment.content or "(내용 없음)",
          h.button['lb-hn-icon-btn lb-hn-delete-comment'] {
            popovertarget = id,
            risu_btn = 'lb-hn-delete/' .. chatIndex .. '_' .. pi .. '_' .. ci,
            type = 'button',
            title = '댓글 삭제',
            h.lb_trash_icon { closed = true },
          },
        }

        table.insert(comment_es, comment_e)
      end

      table.insert(post_es, h.details['lb-hn-post-item'] {
        name = 'lb-hn-post',
        h.summary['lb-hn-post-row'] {
          h.span['lb-hn-col-num lb-hn-text-sm lb-hn-text-muted'] {
            post.id
          },
          h.span['lb-hn-col-title lb-hn-post-title-label'] {
            post.title or "(제목 없음)"
          },
          h.span['lb-hn-col-writer lb-hn-text-sm'] {
            assembleAuthorDisplay(post)
          },
          h.span['lb-hn-col-date lb-hn-text-sm lb-hn-text-muted'] {
            post.time or "-"
          },
          h.span['lb-hn-col-view lb-hn-text-sm lb-hn-text-muted'] {
            post.views or "-"
          },
          h.span['lb-hn-col-rank lb-hn-text-sm lb-hn-text-muted'] {
            post.upvotes or "-"
          }
        },
        h.div['lb-hn-content'] {
          h.div['lb-hn-view-header'] {
            h.div['lb-hn-view-title'] {
              post.title or "(제목 없음)"
            },
            h.div['lb-hn-view-info lb-hn-text-sm lb-hn-text-muted'] {
              h.span['lb-hn-author'] {
                assembleAuthorDisplay(post),
              },
              h.span['lb-hn-separator'] "|",
              h.span {
                "등록일: " .. (post.time or "-")
              },
              h.span['lb-hn-separator'] "|",
              h.span {
                "조회: " .. (post.views or "-")
              },
              h.span['lb-hn-separator'] "|",
              h.span {
                "추천: " .. (post.upvotes or "-")
              }
            }
          },
          h.div['lb-hn-full-content'] {
            post.content or "(내용 없음)"
          },
          #comment_es > 0 and h.div['lb-hn-comments'] {
            h.ul['lb-hn-comment-list'] {
              comment_es
            },
            h.div['lb-hn-comment-actions'] {
              h.button['lb-hn-btn'] {
                popovertarget = id,
                risu_btn = 'lb-hn-delete/' .. chatIndex .. '_' .. pi,
                type = 'button',
                title = '게시글 삭제',
                h.lb_trash_icon { closed = true },
                '삭제'
              },
              h.button['lb-hn-btn'] {
                risu_btn = 'lb-interaction__lb-hn__AddComment/Title:' .. post.title,
                type = 'button',
                h.lb_comment_icon { closed = true },
                '댓글 달기'
              },
            },
          } or nil
        }
      })
    end
  else
    post_es = h.div['lb-no-comments'] {
      style = 'padding: 20px; text-align: center; color: #888;',
      '표시할 게시글 없음',
    }
  end

  local boardTitle = node.attributes.name or "헌터넷 게시판"
  local html = h.div['lb-module-root'] {
    data_id = 'lb-hn',
    h.button['lb-collapsible'] {
      popovertarget = id,
      type = 'button',
      h.span['lb-opener'] {
        h.span {
          boardTitle
        }
      },
    },
    h.dialog['lb-dialog lb-hn-dialog'] {
      id = id,
      popover = '',
      h.div['lb-hn-header'] {
        h.div['lb-hn-title'] {
          boardTitle,
          h.div['lb-hn-nav lb-hn-text-sm'] {
            h.span "헌터넷 정보",
            " | ",
            h.span "설정",
            " | ",
            h.span "퀘스트 게시판",
            " | ",
            h.span "프로필",
            " | ",
            h.span "길드 정보",
          }
        },
        h.div['lb-hn-options'] {
          h.select['lb-hn-text-sm lb-hn-text-light'] {
            disabled = true,
            h.option { value = '30', '30개' },
            h.option { value = '50', '50개' },
            h.option { value = '100', '100개' }
          },
          h.button['lb-hn-write-button'] {
            risu_btn = "lb-interaction__lb-hn__AddPost",
            type = "button",
            h.i '📝',
            ' 글쓰기'
          }
        },
      },
      h.div['lb-hn-wrap'] {
        h.div['lb-hn-container'] {
          h.div['lb-hn-list-container'] {
            h.div['lb-hn-list-header lb-hn-text-sm'] {
              h.span['lb-hn-col-num'] '번호',
              h.span '제목',
              h.span '작성자',
              h.span '등록일',
              h.span['lb-hn-col-view'] '조회',
              h.span['lb-hn-col-rank'] '추천'
            },
            h.div['lb-hn-list-body'] {
              post_es
            }
          }
        },
      },
      h.button['lb-hn-close'] {
        popovertarget = id,
        type = 'button',
        "닫기",
      }
    },
    h.button['lb-reroll'] {
      risu_btn = 'lb-reroll__lb-hn',
      type = 'button',
      h.lb_reroll_icon { closed = true }
    },
  }

  return tostring(html)
end

local function main(data, chatIndex)
  if not data or data == '' then
    return ''
  end

  local extractionSuccess, extractionResult = pcall(prelude.queryNodes, 'lb-hn', data)
  if not extractionSuccess then
    print("[LightBoard] HN extraction failed:", tostring(extractionResult))
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
      output = output .. render(lastResult, chatIndex)
    end
    lastIndex = match.rangeEnd + 1
  end

  return output .. data:sub(lastIndex)
end

listenEdit(
  "editDisplay",
  function(tid, data, meta)
    setTriggerId(tid)

    local chatIndex = meta and meta.index or 0

    if chatIndex ~= 0 then
      local position = chatIndex - getChatLength(triggerId)
      if position < -9 then
        return data
      end
    end

    local success, result = pcall(main, data, chatIndex)
    if success then
      return result
    else
      print("[LightBoard] HN display failed:", tostring(result))
      return data .. '<lb-lazy id="lb-hn">오류: ' .. result .. '</lb-lazy>'
    end
  end
)

---@param author string
---@param authorIP string?
---@param authorRank string?
---@param authorType 'F'|'S'?
---@return string
local function encodeAuthor(author, authorIP, authorRank, authorType)
  if authorType and authorRank then
    return authorType .. ":" .. author .. ":" .. authorRank
  elseif authorIP and authorIP ~= "" then
    return author .. "(" .. authorIP .. ")"
  else
    return author
  end
end

---@param posts HNPostData[]
---@return string
local function encodePosts(posts)
  local function escape(str)
    if not str then return "" end
    return str:gsub("\n", "\\n")
        :gsub("\r", "\\r")
        :gsub("\t", "\\t")
  end

  local lines = {}
  table.insert(lines, "[" .. #posts .. "|]:")

  for _, post in ipairs(posts) do
    local authorStr = encodeAuthor(post.author, post.authorIP, post.authorRank, post.authorType)
    table.insert(lines, "  - author: " .. authorStr)
    table.insert(lines, "    id: " .. (post.id or ""))
    table.insert(lines, "    title: " .. (post.title or ""))
    table.insert(lines, "    time: " .. (post.time or ""))
    table.insert(lines, "    views: " .. (post.views or ""))
    table.insert(lines, "    upvotes: " .. (post.upvotes or ""))
    table.insert(lines, "    content: " .. escape(post.content or ""))
    table.insert(lines, "    comments[" .. #(post.comments or {}) .. "|]{author|content}:")
    for _, comment in ipairs(post.comments or {}) do
      local commentAuthorStr = encodeAuthor(comment.author, comment.authorIP, comment.authorRank, comment.authorType)
      table.insert(lines, "      " .. commentAuthorStr .. "|" .. escape(comment.content or ""))
    end
  end

  return table.concat(lines, "\n")
end

onButtonClick = async(function(tid, code)
  setTriggerId(tid)

  local prefix = "lb%-hn%-delete/"
  local _, prefixEnd = string.find(code, prefix)

  if not prefixEnd then
    return
  end

  local body = code:sub(prefixEnd + 1)
  if body == "" then
    return
  end

  -- body: {chatIndex}/{postIndex}[/{commentIndex}]
  local parts = prelude.split(body, '_')

  if #parts < 2 then
    return
  end

  local chatIndex = tonumber(parts[1])
  local postIndex = tonumber(parts[2])
  local commentIndex = tonumber(parts[3]) -- nil if deleting post

  local deathMessage = chatIndex .. '번 채팅의 ' .. postIndex .. '번 글을 찾을 수 없습니다.'

  if not chatIndex or not postIndex then
    alertNormal(tid, deathMessage)
    return
  end

  local targetType = commentIndex and "댓글" or "글"
  local confirmed = alertConfirm(tid, "정말 이 " .. targetType .. "을 지우시겠습니까?"):await()
  if not confirmed then
    return
  end

  local chat = getChat(tid, chatIndex)
  if not chat or not chat.data then
    alertNormal(tid, deathMessage)
    return
  end

  local nodes = prelude.queryNodes('lb-hn', chat.data)
  if not nodes or #nodes == 0 then
    alertNormal(tid, deathMessage)
    return
  end

  local node = nodes[#nodes]
  local posts = prelude.toon.decode(node.content)

  for _, post in ipairs(posts) do
    local author = parseAuthorInfo(post.author or '')
    post.author = author.name
    post.authorIP = author.ip
    post.authorRank = author.rank
    post.authorType = author.authorType

    for _, comment in ipairs(post.comments or {}) do
      local commentAuthor = parseAuthorInfo(comment.author or '익명')
      comment.author = commentAuthor.name
      comment.authorIP = commentAuthor.ip
      comment.authorRank = commentAuthor.rank
      comment.authorType = commentAuthor.authorType
    end
  end

  if postIndex < 1 or postIndex > #posts then
    alertNormal(tid, deathMessage)
    return
  end

  if commentIndex then
    local post = posts[postIndex]
    if not post.comments or commentIndex < 1 or commentIndex > #post.comments then
      alertNormal(tid, chatIndex .. '번 채팅 ' .. postIndex .. '번 글의 ' .. commentIndex .. '번 댓글을 찾을 수 없습니다.')
      return
    end
    table.remove(post.comments, commentIndex)
  else
    table.remove(posts, postIndex)
  end

  local newContent = encodePosts(posts)
  local newBlock = node.openTag .. "\n" .. newContent .. "\n</" .. node.tagName .. ">"
  local newData = chat.data:sub(1, node.rangeStart - 1) .. newBlock .. chat.data:sub(node.rangeEnd + 1)

  setChat(tid, chatIndex, newData)
end)
