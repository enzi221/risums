--- See original at https://arca.live/b/characterai/133962148
--- Modified by amonamona

--- LightBoard HN

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

---@param author string
---@return { ip: string?, name: string, rank: string?, type?: 'F' | 'S' }
local function parseAuthorInfo(author)
  local fs, nick, rank = table.unpack(prelude.split(author, ':'))
  if rank then
    return {
      ip = nil,
      name = nick or 'ㅇㅇ',
      rank = rank,
      type = fs
    }
  else
    local nick_, ip = table.unpack(prelude.split(author, '('))
    return {
      ip = (ip or ''):sub(1, -2),
      name = nick_ or 'ㅇㅇ',
      rank = nil,
      type = nil
    }
  end
end

---@param authorData { Author: string; AuthorIP: string?; AuthorRank: string?; AuthorType?: 'F' | 'S'?; }
---@return table
local function assembleAuthorDisplay(authorData)
  local hunterRankDisplay = nil
  if authorData.AuthorRank and authorData.AuthorRank ~= "" then
    hunterRankDisplay = h.span['lb-hn-level lb-hn-rank-' ..
    string.lower(authorData.AuthorRank)] {
      authorData.AuthorRank
    }
  end

  local nickTypeIcon = nil
  if authorData.AuthorType == 'F' then
    nickTypeIcon = h.span['lb-hn-icon-fixed'] "고"
  elseif authorData.AuthorType == 'S' then
    nickTypeIcon = h.span['lb-hn-icon-semi'] "반"
  end

  local ip = nil
  if authorData.AuthorIP and authorData.AuthorIP ~= "" then
    ip = h.span['lb-hn-writer-ip'] {
      "(" .. authorData.AuthorIP .. ")"
    }
  end

  return {
    hunterRankDisplay or '',
    authorData.Author,
    nickTypeIcon or '',
    ip or '',
  }
end

local function render(block)
  local rawContent = block.content
  if not rawContent or rawContent == "" then
    return "[LightBoard Error: Empty Content]"
  end

  ---@class HNCommentData
  ---@field Author string
  ---@field AuthorIP string?
  ---@field AuthorRank string?
  ---@field AuthorType 'F'|'S'?
  ---@field Content string

  ---@class HNPostData
  ---@field Author string
  ---@field AuthorIP string?
  ---@field AuthorRank string?
  ---@field AuthorType 'F'|'S'?
  ---@field Comments HNCommentData[]
  ---@field Content string
  ---@field No string
  ---@field Time string
  ---@field Title string
  ---@field Upvotes string
  ---@field Views string

  ---@type HNPostData[]
  local posts = {}

  for _, postBlock in ipairs(prelude.extractBlocks("Post", rawContent)) do
    ---@class HNPostData
    local postData = prelude.parseBlock(postBlock, { "Post", "Comment" })

    local author = parseAuthorInfo(postData.Author or '')
    postData.Author = author.name
    postData.AuthorIP = author.ip
    postData.AuthorRank = author.rank
    postData.AuthorType = author.type
    postData.Comments = {}

    for _, commentBlock in ipairs(prelude.extractBlocks("Comment", postBlock)) do
      ---@type HNCommentData
      local commentData = prelude.parseBlock(commentBlock)
      commentData.Author = commentData.Author or "익명"

      local commentAuthor = parseAuthorInfo(commentData.Author)
      commentData.Author = commentAuthor.name
      commentData.AuthorIP = commentAuthor.ip
      commentData.AuthorRank = commentAuthor.rank
      commentData.AuthorType = commentAuthor.type

      if commentData.Author or commentData.Content then
        table.insert(postData.Comments, commentData)
      end
    end

    table.insert(posts, postData)
  end

  local post_es = {}

  if #posts > 0 then
    for _, post in ipairs(posts) do
      local comment_es = {}
      for _, comment in ipairs(post.Comments) do
        local comment_e = h.li['lb-hn-comment-item'] {
          h.span['lb-hn-comment-author'] {
            assembleAuthorDisplay(comment),
          },
          comment.Content or "(내용 없음)"
        }

        table.insert(comment_es, comment_e)
      end

      local idPrefix = math.random()

      table.insert(post_es, h.div['lb-hn-post-item'] {
        h.input['lb-hn-post-toggle'] {
          id = idPrefix .. post.No,
          type = "checkbox",
        },
        h.div['lb-hn-post-row'] {
          h.span['lb-hn-col-num lb-hn-text-sm lb-hn-text-muted'] {
            post.No
          },
          h.label['lb-hn-col-title lb-hn-post-title-label'] {
            htmlFor = idPrefix .. post.No,
            post.Title or "(제목 없음)"
          },
          h.span['lb-hn-col-writer lb-hn-text-sm'] {
            assembleAuthorDisplay(post)
          },
          h.span['lb-hn-col-date lb-hn-text-sm lb-hn-text-muted'] {
            post.Time or "-"
          },
          h.span['lb-hn-col-view lb-hn-text-sm lb-hn-text-muted'] {
            post.Views or "-"
          },
          h.span['lb-hn-col-rank lb-hn-text-sm lb-hn-text-muted'] {
            post.Upvotes or "-"
          }
        },
        h.div['lb-hn-content'] {
          h.div['lb-hn-view-header'] {
            h.div['lb-hn-view-title'] {
              post.Title or "(제목 없음)"
            },
            h.div['lb-hn-view-info lb-hn-text-sm lb-hn-text-muted'] {
              h.span['lb-hn-author'] {
                assembleAuthorDisplay(post),
              },
              h.span['lb-hn-separator'] "|",
              h.span {
                "등록일: " .. (post.Time or "-")
              },
              h.span['lb-hn-separator'] "|",
              h.span {
                "조회: " .. (post.Views or "-")
              },
              h.span['lb-hn-separator'] "|",
              h.span {
                "추천: " .. (post.Upvotes or "-")
              }
            }
          },
          h.div['lb-hn-full-content'] {
            post.Content or "(내용 없음)"
          },
          #comment_es > 0 and h.div['lb-hn-comments'] {
            h.ul['lb-hn-comment-list'] {
              comment_es
            },
            h.button['lb-hn-add-comment'] {
              risu_btn = "lb-interaction__lightboard-hn__AddComment/Title:" .. post.Title,
              type = "button",
              "댓글 달기"
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

  local id = 'lb-hn-' .. math.random()

  local boardTitle = block.attributes.name or "헌터넷 게시판"
  local html = h.div['lb-module-root'] {
    data_id = 'lightboard-hn',
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
            h.option { value = '30', '30개' },
            h.option { value = '50', '50개' },
            h.option { value = '100', '100개' }
          },
          h.button['lb-hn-write-button'] {
            risu_btn = "lb-interaction__lightboard-hn__AddPost",
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
      risu_btn = 'lb-reroll__lightboard-hn',
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

  local extractionSuccess, extractionResult = pcall(prelude.extractNodes, 'lightboard-hn', data)
  if not extractionSuccess then
    print("[LightBoard] HN extraction failed:", tostring(extractionResult))
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
        print("[LightBoard] HN parsing failed in block " .. i .. ":", tostring(processResult))
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
      print("[LightBoard] HN display failed:", tostring(result))
      return data
    end
  end
)
