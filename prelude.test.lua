_ENV.prelude = {}

local test = require('test')
local prelude = require('prelude')

local assertEquals = test.assertEquals
local describe = test.describe
local it = test.it

local function deepEqual(t1, t2)
  if type(t1) ~= type(t2) then return false end
  if type(t1) ~= "table" then return t1 == t2 end

  local count1, count2 = 0, 0
  for k, v in pairs(t1) do
    count1 = count1 + 1
    if not deepEqual(v, t2[k]) then return false end
  end
  for _ in pairs(t2) do count2 = count2 + 1 end

  return count1 == count2
end

local function assertDeepEquals(actual, expected, message)
  test.incrementTotal()
  if deepEqual(actual, expected) then
    test.incrementPassed()
    print("✓ " .. message)
  else
    test.incrementFailed()
    print("✗ " .. message)
    print("  Expected: " .. test.tableToString(expected))
    print("  Actual:   " .. test.tableToString(actual))
  end
end

describe('queryNodes', function()
  it("extracts simple node", function()
    local text = "<test>content</test>"
    local nodes = prelude.queryNodes("test", text)
    assertDeepEquals(nodes, {
      {
        attributes = {},
        content = "content",
        rangeStart = 1,
        rangeEnd = 20
      }
    }, "simple node extraction")
  end)

  it("extracts self-closing tag", function()
    local text = "<lb-lazy id='test' />"
    local nodes = prelude.queryNodes("lb-lazy", text)
    assertDeepEquals(nodes, {
      {
        attributes = { id = "test" },
        content = "",
        rangeStart = 1,
        rangeEnd = 21
      }
    }, "self-closing tag extraction")
  end)

  it("extracts multiple self-closing tags", function()
    local text = "<br /><hr class='divider' />"
    local nodesBr = prelude.queryNodes("br", text)
    local nodesHr = prelude.queryNodes("hr", text)
    assertDeepEquals(nodesBr, {
      {
        attributes = {},
        content = "",
        rangeStart = 1,
        rangeEnd = 6
      }
    }, "br tag")
    assertDeepEquals(nodesHr, {
      {
        attributes = { class = "divider" },
        content = "",
        rangeStart = 7,
        rangeEnd = 28
      }
    }, "hr tag with attribute")
  end)

  it("handles mixed self-closing and regular tags", function()
    local text = "<p>text</p><br /><span>more</span>"
    local nodesP = prelude.queryNodes("p", text)
    local nodesBr = prelude.queryNodes("br", text)
    local nodesSpan = prelude.queryNodes("span", text)

    assertEquals(#nodesP, 1, "should find p tag")
    assertEquals(nodesP[1].content, "text", "p tag content")
    assertEquals(#nodesBr, 1, "should find br tag")
    assertEquals(nodesBr[1].content, "", "br tag should have empty content")
    assertEquals(#nodesSpan, 1, "should find span tag")
    assertEquals(nodesSpan[1].content, "more", "span tag content")
  end)

  it("extracts multiple nodes", function()
    local text = "<item>1</item> <item>2</item>"
    local nodes = prelude.queryNodes("item", text)
    assertEquals(#nodes, 2, "found 2 nodes")
    assertEquals(nodes[1].content, "1", "first content")
    assertEquals(nodes[2].content, "2", "second content")
  end)

  it("extracts attributes", function()
    local text = '<user id="1" active name=\'bob\'>data</user>'
    local nodes = prelude.queryNodes("user", text)
    local attrs = nodes[1].attributes
    assertEquals(attrs.id, "1", "quoted attr")
    assertEquals(attrs.name, "bob", "single quoted attr")
    assertEquals(attrs.active, "true", "boolean attr")
  end)

  it("extracts unquoted attributes", function()
    local text = '<config val=123>ok</config>'
    local nodes = prelude.queryNodes("config", text)
    assertEquals(nodes[1].attributes.val, "123", "unquoted attr")
  end)

  it("handles whitespace in attributes", function()
    local text = '<div  class = "box"  >content</div>'
    local nodes = prelude.queryNodes("div", text)
    assertEquals(nodes[1].attributes.class, "box", "attr with whitespace")
    assertEquals(nodes[1].content, "content", "content match")
  end)

  it("ignores other tags", function()
    local text = "<keep>me</keep><ignore>that</ignore>"
    local nodes = prelude.queryNodes("keep", text)
    assertEquals(#nodes, 1, "only keep tag")
    assertEquals(nodes[1].content, "me", "content check")
  end)

  it("does not match partial tag names", function()
    local text = "<lb-stage-reserve>content</lb-stage-reserve> <lb-stage>real</lb-stage>"
    local nodes = prelude.queryNodes("lb-stage", text)
    assertEquals(#nodes, 1, "should match only exact tag name")
    assertEquals(nodes[1].content, "real", "content should correspond to exact tag")
  end)
end)

describe('removeAllNodes', function()
  it("removes single node", function()
    local text = "prefix <rem>gone</rem> suffix"
    local result = prelude.removeAllNodes(text)
    assertEquals(result, "prefix  suffix", "removes node")
  end)

  it("removes multiple nodes", function()
    local text = "A <del>1</del> B <del>2</del> C"
    local result = prelude.removeAllNodes(text)
    assertEquals(result, "A  B  C", "removes all")
  end)

  it("keeps specified tags", function()
    local text = "<keep>stay</keep> <del>go</del>"
    local result = prelude.removeAllNodes(text, { "keep" })
    assertEquals(result, "<keep>stay</keep> ", "keeps tag")
  end)

  it("handles newlines logic", function()
    local text = "line1\n<rem>remove</rem>\nline2"
    local result = prelude.removeAllNodes(text)
    assertEquals(result, "line1\nline2", "deduplicates newlines")
  end)

  it("does not deduplicate if not surrounded by newlines", function()
    local text = "word <rem>remove</rem> word"
    local result = prelude.removeAllNodes(text)
    assertEquals(result, "word  word", "keeps spaces")
  end)

  it("skips content of kept tags", function()
    local text = "<outer><inner>text</inner></outer>"
    local result = prelude.removeAllNodes(text, { "outer" })
    assertEquals(result, "<outer><inner>text</inner></outer>", "preserves inner content of kept tag")
  end)

  it("handles uppercase tags (case sensitivity check)", function()
    local text = "<REMOVE>content</REMOVE>"
    local result = prelude.removeAllNodes(text)
    assertEquals(result, "", "removes uppercase tags by default")
  end)

  it("handles attributes with >", function()
    local text = 'A <rem val=">">B</rem> C'
    local result = prelude.removeAllNodes(text)
    assertEquals(result, "A  C", "removes node despite > in attribute")
  end)

  it("handles self-closing tags", function()
    local text = 'prefix <br /> suffix'
    local result = prelude.removeAllNodes(text)
    assertEquals(result, 'prefix  suffix', "removes self-closing tags")
  end)

  it("keeps specified self-closing tags", function()
    local text = 'prefix <br /> suffix'
    local result = prelude.removeAllNodes(text, { "br" })
    assertEquals(result, 'prefix <br /> suffix', "keeps specified self-closing tags")
  end)

  it("keeps tag with keepalive attribute", function()
    local text = 'A <important keepalive>content</important> B <temp>gone</temp>'
    local result = prelude.removeAllNodes(text)
    assertEquals(result, 'A <important keepalive>content</important> B ', "keeps tag with keepalive")
  end)

  it("keeps self-closing tags with keepalive attribute", function()
    local text = 'A <marker keepalive /> B <temp />'
    local result = prelude.removeAllNodes(text)
    assertEquals(result, 'A <marker keepalive /> B ', "keeps self-closing tag with keepalive")
  end)
end)

describe('trim', function()
  it("trims whitespace", function()
    assertEquals(prelude.trim("  hello  "), "hello", "trims spaces")
    assertEquals(prelude.trim("\t\nhello\n\t"), "hello", "trims newlines and tabs")
  end)

  it("handles empty string", function()
    assertEquals(prelude.trim(""), "", "empty string")
    assertEquals(prelude.trim("   "), "", "only whitespace")
  end)

  it("trims unicode whitespace", function()
    -- NBSP, Ideographic Space, ZWSP
    local input = "\194\160\227\128\128\226\128\139hello\194\160"
    assertEquals(prelude.trim(input), "hello", "trims unicode spaces")
    
    local empty_unicode = "\194\160\227\128\128"
    assertEquals(prelude.trim(empty_unicode), "", "returns empty for unicode spaces only")
  end)
end)

describe('split', function()
  it("splits string by separator", function()
    local result = prelude.split("a,b,c", ",")
    assertDeepEquals(result, { "a", "b", "c" }, "simple split")
  end)

  it("handles empty separator", function()
    local result = prelude.split("abc", "")
    assertDeepEquals(result, { "abc" }, "empty separator returns whole string")
  end)

  it("handles missing separator", function()
    local result = prelude.split("abc", ",")
    assertDeepEquals(result, { "abc" }, "separator not found")
  end)

  it("splits properly with multi-character separator without corrupting multibyte characters", function()
    -- '챙김.\n로제타' (literal \n)
    local result = prelude.split("챙김.\\n로제타", "\\n")
    assertDeepEquals(result, { "챙김.", "로제타" }, "multibyte split regression test")
  end)
end)

describe('escEntities', function()
  it("escapes basic characters", function()
    assertEquals(prelude.escEntities("<>&amp;"), "&lt;&gt;&amp;amp;", "basic escapes")
  end)

  it("escapes quotes", function()
    assertEquals(prelude.escEntities("'\""), "&#39;&#34;", "quotes")
  end)

  it("escapes \\n to <br>", function()
    assertEquals(prelude.escEntities("a\\nb"), "a<br>b", "literal backslash+n to <br>")
  end)
end)

describe('escMatch', function()
  it("escapes regex special chars", function()
    assertEquals(prelude.escMatch("."), "%.", "dot")
    assertEquals(prelude.escMatch("a-b"), "a%-b", "dash")
  end)
end)

test.printSummary()
