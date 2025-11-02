_ENV.prelude = {}

local test = require("test")
local toon = require("toon.decode")

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

local function tableToString(t, indent)
  indent = indent or 0
  if type(t) ~= "table" then
    return tostring(t)
  end
  local str = "{"
  local first = true
  for k, v in pairs(t) do
    if not first then str = str .. ", " end
    first = false
    str = str .. "[" .. tostring(k) .. "]="
    if type(v) == "table" then
      str = str .. tableToString(v, indent + 1)
    else
      str = str .. tostring(v)
    end
  end
  return str .. "}"
end

local function assertDeepEquals(actual, expected, message)
  test.incrementTotal()
  if deepEqual(actual, expected) then
    test.incrementPassed()
    print("✓ " .. message)
  else
    test.incrementFailed()
    print("✗ " .. message)
    print("  Expected: " .. tableToString(expected))
    print("  Actual:   " .. tableToString(actual))
  end
end

describe("primitives", function()
  it("decodes safe unquoted strings", function()
    assertEquals(toon.decode("hello"), "hello", "decode 'hello'")
    assertEquals(toon.decode("Ada_99"), "Ada_99", "decode 'Ada_99'")
  end)

  it("decodes quoted strings and unescapes control characters", function()
    assertEquals(toon.decode('""'), "", "decode empty quoted string")
    assertEquals(toon.decode('"line1\\nline2"'), "line1\nline2", "decode newline")
    assertEquals(toon.decode('"tab\\there"'), "tab\there", "decode tab")
    assertEquals(toon.decode('"return\\rcarriage"'), "return\rcarriage", "decode carriage return")
    assertEquals(toon.decode('"C:\\\\Users\\\\path"'), "C:\\Users\\path", "decode backslashes")
    assertEquals(toon.decode('"say \\"hello\\""'), 'say "hello"', "decode escaped quotes")
  end)

  it("decodes unicode and emoji", function()
    assertEquals(toon.decode("café"), "café", "decode 'café'")
    assertEquals(toon.decode("你好"), "你好", "decode '你好'")
    assertEquals(toon.decode("🚀"), "🚀", "decode '🚀'")
    assertEquals(toon.decode("hello 👋 world"), "hello 👋 world", "decode 'hello 👋 world'")
  end)

  it("decodes numbers, booleans and null", function()
    assertEquals(toon.decode("42"), 42, "decode 42")
    assertEquals(toon.decode("3.14"), 3.14, "decode 3.14")
    assertEquals(toon.decode("-7"), -7, "decode -7")
    assertEquals(toon.decode("true"), true, "decode true")
    assertEquals(toon.decode("false"), false, "decode false")
    assertEquals(toon.decode("null"), nil, "decode null")
  end)

  it("treats unquoted invalid numeric formats as strings", function()
    assertEquals(toon.decode("05"), "05", "decode '05'")
    assertEquals(toon.decode("007"), "007", "decode '007'")
    assertEquals(toon.decode("0123"), "0123", "decode '0123'")
    assertDeepEquals(toon.decode("a: 05"), { a = "05" }, "decode object with '05'")
    assertDeepEquals(toon.decode("nums[3]: 05,007,0123"), { nums = { "05", "007", "0123" } },
      "decode array with invalid numeric formats")
  end)

  it("respects ambiguity quoting (quoted primitives remain strings)", function()
    assertEquals(toon.decode('"true"'), "true", "decode quoted 'true'")
    assertEquals(toon.decode('"false"'), "false", "decode quoted 'false'")
    assertEquals(toon.decode('"null"'), "null", "decode quoted 'null'")
    assertEquals(toon.decode('"42"'), "42", "decode quoted '42'")
    assertEquals(toon.decode('"-3.14"'), "-3.14", "decode quoted '-3.14'")
    assertEquals(toon.decode('"1e-6"'), "1e-6", "decode quoted '1e-6'")
    assertEquals(toon.decode('"05"'), "05", "decode quoted '05'")
  end)
end)

describe("objects (simple)", function()
  it("parses objects with primitive values", function()
    local toon_str = "id: 123\nname: Ada\nactive: true"
    assertDeepEquals(toon.decode(toon_str), { id = 123, name = "Ada", active = true }, "parse object with primitives")
  end)

  it("parses null values in objects", function()
    local toon_str = "id: 123\nvalue: null"
    local result = toon.decode(toon_str)
    test.incrementTotal()
    if result.id == 123 and result.value == nil then
      test.incrementPassed()
      print("✓ parse object with null value")
    else
      test.incrementFailed()
      print("✗ parse object with null value")
    end
  end)

  it("parses empty nested object header", function()
    assertDeepEquals(toon.decode("user:"), { user = {} }, "parse empty nested object")
  end)

  it("parses quoted object values with special characters and escapes", function()
    assertDeepEquals(toon.decode('note: "a:b"'), { note = "a:b" }, "parse value with colon")
    assertDeepEquals(toon.decode('note: "a,b"'), { note = "a,b" }, "parse value with comma")
    assertDeepEquals(toon.decode('text: "line1\\nline2"'), { text = "line1\nline2" }, "parse value with newline")
    assertDeepEquals(toon.decode('text: "say \\"hello\\""'), { text = 'say "hello"' }, "parse value with quotes")
    assertDeepEquals(toon.decode('text: " padded "'), { text = " padded " }, "parse padded string")
    assertDeepEquals(toon.decode('text: "  "'), { text = "  " }, "parse spaces only")
    assertDeepEquals(toon.decode('v: "true"'), { v = "true" }, "parse quoted 'true'")
    assertDeepEquals(toon.decode('v: "42"'), { v = "42" }, "parse quoted '42'")
    assertDeepEquals(toon.decode('v: "-7.5"'), { v = "-7.5" }, "parse quoted '-7.5'")
  end)
end)

describe("objects (keys)", function()
  it("parses quoted keys with special characters and escapes", function()
    assertDeepEquals(toon.decode('"order:id": 7'), { ["order:id"] = 7 }, "parse key with colon")
    assertDeepEquals(toon.decode('"[index]": 5'), { ["[index]"] = 5 }, "parse key with brackets")
    assertDeepEquals(toon.decode('"{key}": 5'), { ["{key}"] = 5 }, "parse key with braces")
    assertDeepEquals(toon.decode('"a,b": 1'), { ["a,b"] = 1 }, "parse key with comma")
    assertDeepEquals(toon.decode('"full name": Ada'), { ["full name"] = "Ada" }, "parse key with spaces")
    assertDeepEquals(toon.decode('"-lead": 1'), { ["-lead"] = 1 }, "parse key with leading hyphen")
    assertDeepEquals(toon.decode('" a ": 1'), { [" a "] = 1 }, "parse key with surrounding spaces")
    assertDeepEquals(toon.decode('"123": x'), { ["123"] = "x" }, "parse numeric string key")
    assertDeepEquals(toon.decode('"": 1'), { [""] = 1 }, "parse empty string key")
  end)

  it("parses dotted keys as identifiers", function()
    assertDeepEquals(toon.decode("user.name: Ada"), { ["user.name"] = "Ada" }, "parse dotted key")
    assertDeepEquals(toon.decode("_private: 1"), { _private = 1 }, "parse underscore key")
    assertDeepEquals(toon.decode("user_name: 1"), { user_name = 1 }, "parse underscore in key")
  end)

  it("unescapes control characters and quotes in keys", function()
    assertDeepEquals(toon.decode('"line\\nbreak": 1'), { ["line\nbreak"] = 1 }, "parse key with newline")
    assertDeepEquals(toon.decode('"tab\\there": 2'), { ["tab\there"] = 2 }, "parse key with tab")
    assertDeepEquals(toon.decode('"he said \\"hi\\"": 1'), { ['he said "hi"'] = 1 }, "parse key with quotes")
  end)
end)

describe("nested objects", function()
  it("parses deeply nested objects with indentation", function()
    local toon_str = "a:\n  b:\n    c: deep"
    assertDeepEquals(toon.decode(toon_str), { a = { b = { c = "deep" } } }, "parse deeply nested objects")
  end)
end)

describe("arrays of primitives", function()
  it("parses string arrays inline", function()
    local toon_str = "tags[3]: reading,gaming,coding"
    assertDeepEquals(toon.decode(toon_str), { tags = { "reading", "gaming", "coding" } }, "parse string array")
  end)

  it("parses number arrays inline", function()
    local toon_str = "nums[3]: 1,2,3"
    assertDeepEquals(toon.decode(toon_str), { nums = { 1, 2, 3 } }, "parse number array")
  end)

  it("parses mixed primitive arrays inline", function()
    local toon_str = "data[4]: x,y,true,10"
    assertDeepEquals(toon.decode(toon_str), { data = { "x", "y", true, 10 } }, "parse mixed array")
  end)

  it("parses empty arrays", function()
    assertDeepEquals(toon.decode("items[0]:"), { items = {} }, "parse empty array")
  end)

  it("parses quoted strings in arrays including empty and whitespace-only", function()
    assertDeepEquals(toon.decode('items[1]: ""'), { items = { "" } }, "parse array with empty string")
    assertDeepEquals(toon.decode('items[3]: a,"",b'), { items = { "a", "", "b" } },
      "parse array with empty string in middle")
    assertDeepEquals(toon.decode('items[2]: " ","  "'), { items = { " ", "  " } }, "parse array with whitespace strings")
  end)

  it("parses strings with delimiters and structural tokens in arrays", function()
    assertDeepEquals(toon.decode('items[3]: a,"b,c","d:e"'), { items = { "a", "b,c", "d:e" } },
      "parse array with special chars")
    assertDeepEquals(toon.decode('items[4]: x,"true","42","-3.14"'), { items = { "x", "true", "42", "-3.14" } },
      "parse array with ambiguous strings")
    assertDeepEquals(toon.decode('items[3]: "[5]","- item","{key}"'), { items = { "[5]", "- item", "{key}" } },
      "parse array with structural strings")
  end)
end)

describe("arrays of objects (tabular and list items)", function()
  it("parses tabular arrays of uniform objects", function()
    local toon_str = "items[2]{sku,qty,price}:\n  A1,2,9.99\n  B2,1,14.5"
    assertDeepEquals(toon.decode(toon_str), {
      items = {
        { sku = "A1", qty = 2, price = 9.99 },
        { sku = "B2", qty = 1, price = 14.5 }
      }
    }, "parse tabular array")
  end)
  it("parses tabular arrays of uniform objects with colon strings", function()
    local toon_str = "items[2]{sku,qty,price}:\n  A:1,2,9.99\n  B:2,1,14.5"
    assertDeepEquals(toon.decode(toon_str), {
      items = {
        { sku = "A:1", qty = 2, price = 9.99 },
        { sku = "B:2", qty = 1, price = 14.5 }
      }
    }, "parse tabular array with colon strings")
  end)

  it("parses nulls and quoted values in tabular rows", function()
    local toon_str = 'items[2]{id,value}:\n  1,null\n  2,"test"'
    local result = toon.decode(toon_str)
    test.incrementTotal()
    if result.items and #result.items == 2 and
        result.items[1].id == 1 and result.items[1].value == nil and
        result.items[2].id == 2 and result.items[2].value == "test" then
      test.incrementPassed()
      print("✓ parse tabular with null values")
    else
      test.incrementFailed()
      print("✗ parse tabular with null values")
    end
  end)

  it("parses quoted header keys in tabular arrays", function()
    local toon_str = 'items[2]{"order:id","full name"}:\n  1,Ada\n  2,Bob'
    assertDeepEquals(toon.decode(toon_str), {
      items = {
        { ["order:id"] = 1, ["full name"] = "Ada" },
        { ["order:id"] = 2, ["full name"] = "Bob" }
      }
    }, "parse tabular with quoted keys")
  end)

  it("parses list arrays for non-uniform objects", function()
    local toon_str = "items[2]:\n  - id: 1\n    name: First\n  - id: 2\n    name: Second\n    extra: true"
    assertDeepEquals(toon.decode(toon_str), {
      items = {
        { id = 1, name = "First" },
        { id = 2, name = "Second", extra = true }
      }
    }, "parse list array")
  end)

  it("parses objects with nested values inside list items", function()
    local toon_str = "items[1]:\n  - id: 1\n    nested:\n      x: 1"
    assertDeepEquals(toon.decode(toon_str), {
      items = { { id = 1, nested = { x = 1 } } }
    }, "parse list with nested objects")
  end)

  it("parses nested tabular arrays as first field on hyphen line", function()
    local toon_str = "items[1]:\n  - users[2]{id,name}:\n    1,Ada\n    2,Bob\n    status: active"
    assertDeepEquals(toon.decode(toon_str), {
      items = { {
        users = {
          { id = 1, name = "Ada" },
          { id = 2, name = "Bob" }
        },
        status = "active"
      } }
    }, "parse nested tabular in list")
  end)

  it("parses objects containing arrays (including empty arrays) in list format", function()
    local toon_str = "items[1]:\n  - name: test\n    data[0]:"
    assertDeepEquals(toon.decode(toon_str), {
      items = { { name = "test", data = {} } }
    }, "parse list with empty array")
  end)

  it("parses arrays of arrays within objects", function()
    local toon_str = "items[1]:\n  - matrix[2]:\n    - [2]: 1,2\n    - [2]: 3,4\n    name: grid"
    assertDeepEquals(toon.decode(toon_str), {
      items = { { matrix = { { 1, 2 }, { 3, 4 } }, name = "grid" } }
    }, "parse nested arrays in list")
  end)
end)

describe("arrays of arrays (primitives only)", function()
  it("parses nested arrays of primitives", function()
    local toon_str = "pairs[2]:\n  - [2]: a,b\n  - [2]: c,d"
    assertDeepEquals(toon.decode(toon_str), { pairs = { { "a", "b" }, { "c", "d" } } }, "parse nested arrays")
  end)

  it("parses quoted strings and mixed lengths in nested arrays", function()
    local toon_str = 'pairs[2]:\n  - [2]: a,b\n  - [3]: "c,d","e:f","true"'
    assertDeepEquals(toon.decode(toon_str), { pairs = { { "a", "b" }, { "c,d", "e:f", "true" } } },
      "parse nested arrays with quoted strings")
  end)

  it("parses empty inner arrays", function()
    local toon_str = "pairs[2]:\n  - [0]:\n  - [0]:"
    assertDeepEquals(toon.decode(toon_str), { pairs = { {}, {} } }, "parse empty inner arrays")
  end)

  it("parses mixed-length inner arrays", function()
    local toon_str = "pairs[2]:\n  - [1]: 1\n  - [2]: 2,3"
    assertDeepEquals(toon.decode(toon_str), { pairs = { { 1 }, { 2, 3 } } }, "parse mixed-length arrays")
  end)
end)

describe("root arrays", function()
  it("parses root arrays of primitives (inline)", function()
    local toon_str = '[5]: x,y,"true",true,10'
    assertDeepEquals(toon.decode(toon_str), { "x", "y", "true", true, 10 }, "parse root primitive array")
  end)

  it("parses root arrays of uniform objects in tabular format", function()
    local toon_str = "[2]{id}:\n  1\n  2"
    assertDeepEquals(toon.decode(toon_str), { { id = 1 }, { id = 2 } }, "parse root tabular array")
  end)

  it("parses root arrays of non-uniform objects in list format", function()
    local toon_str = "[2]:\n  - id: 1\n  - id: 2\n    name: Ada"
    assertDeepEquals(toon.decode(toon_str), { { id = 1 }, { id = 2, name = "Ada" } }, "parse root list array")
  end)

  it("parses empty root arrays", function()
    assertDeepEquals(toon.decode("[0]:"), {}, "parse empty root array")
  end)

  it("parses root arrays of arrays", function()
    local toon_str = "[2]:\n  - [2]: 1,2\n  - [0]:"
    assertDeepEquals(toon.decode(toon_str), { { 1, 2 }, {} }, "parse root nested arrays")
  end)
end)

describe("complex structures", function()
  it("parses mixed objects with arrays and nested objects", function()
    local toon_str = "user:\n  id: 123\n  name: Ada\n  tags[2]: reading,gaming\n  active: true\n  prefs[0]:"
    assertDeepEquals(toon.decode(toon_str), {
      user = {
        id = 123,
        name = "Ada",
        tags = { "reading", "gaming" },
        active = true,
        prefs = {}
      }
    }, "parse complex structure")
  end)
end)

describe("mixed arrays", function()
  it("parses arrays mixing primitives, objects and strings (list format)", function()
    local toon_str = "items[3]:\n  - 1\n  - a: 1\n  - text"
    assertDeepEquals(toon.decode(toon_str), { items = { 1, { a = 1 }, "text" } }, "parse mixed array")
  end)

  it("parses arrays mixing objects and arrays", function()
    local toon_str = "items[2]:\n  - a: 1\n  - [2]: 1,2"
    assertDeepEquals(toon.decode(toon_str), { items = { { a = 1 }, { 1, 2 } } }, "parse array of objects and arrays")
  end)
end)

describe("delimiter options", function()
  it("parses primitive arrays with tab delimiter", function()
    local toon_str = "tags[3\t]: reading\tgaming\tcoding"
    assertDeepEquals(toon.decode(toon_str), { tags = { "reading", "gaming", "coding" } },
      "parse array with tab delimiter")
  end)

  it("parses primitive arrays with pipe delimiter", function()
    local toon_str = "tags[3|]: reading|gaming|coding"
    assertDeepEquals(toon.decode(toon_str), { tags = { "reading", "gaming", "coding" } },
      "parse array with pipe delimiter")
  end)

  it("parses tabular arrays with tab delimiter", function()
    local toon_str = "items[2\t]{sku\tqty\tprice}:\n  A1\t2\t9.99\n  B2\t1\t14.5"
    assertDeepEquals(toon.decode(toon_str), {
      items = {
        { sku = "A1", qty = 2, price = 9.99 },
        { sku = "B2", qty = 1, price = 14.5 }
      }
    }, "parse tabular with tab delimiter")
  end)

  it("parses tabular arrays with pipe delimiter", function()
    local toon_str = "items[2|]{sku|qty|price}:\n  A1|2|9.99\n  B2|1|14.5"
    assertDeepEquals(toon.decode(toon_str), {
      items = {
        { sku = "A1", qty = 2, price = 9.99 },
        { sku = "B2", qty = 1, price = 14.5 }
      }
    }, "parse tabular with pipe delimiter")
  end)

  it("parses nested arrays with custom delimiters", function()
    local toon_str = "pairs[2\t]:\n  - [2\t]: a\tb\n  - [2\t]: c\td"
    assertDeepEquals(toon.decode(toon_str), { pairs = { { "a", "b" }, { "c", "d" } } }, "parse nested with tab delimiter")
  end)

  it("parses values containing the active delimiter when quoted", function()
    local toon_str = 'items[3\t]: a\t"b\\tc"\td'
    assertDeepEquals(toon.decode(toon_str), { items = { "a", "b\tc", "d" } }, "parse quoted delimiter (tab)")

    local toon_str2 = 'items[3|]: a|"b|c"|d'
    assertDeepEquals(toon.decode(toon_str2), { items = { "a", "b|c", "d" } }, "parse quoted delimiter (pipe)")
  end)

  it("does not split on commas when using non-comma delimiter", function()
    local toon_str = "items[2\t]: a,b\tc,d"
    assertDeepEquals(toon.decode(toon_str), { items = { "a,b", "c,d" } }, "no comma split with tab delimiter")

    local toon_str2 = "items[2|]: a,b|c,d"
    assertDeepEquals(toon.decode(toon_str2), { items = { "a,b", "c,d" } }, "no comma split with pipe delimiter")
  end)

  it("does not require quoting commas in object values when using non-comma delimiter elsewhere", function()
    assertDeepEquals(toon.decode("note: a,b"), { note = "a,b" }, "commas in object values")
  end)
end)

describe("length marker option", function()
  it("accepts length marker on primitive arrays", function()
    assertDeepEquals(toon.decode("tags[#3]: reading,gaming,coding"), { tags = { "reading", "gaming", "coding" } },
      "parse with length marker")
  end)

  it("accepts length marker on empty arrays", function()
    assertDeepEquals(toon.decode("items[#0]:"), { items = {} }, "parse empty array with length marker")
  end)

  it("accepts length marker on tabular arrays", function()
    local toon_str = "items[#2]{sku,qty,price}:\n  A1,2,9.99\n  B2,1,14.5"
    assertDeepEquals(toon.decode(toon_str), {
      items = {
        { sku = "A1", qty = 2, price = 9.99 },
        { sku = "B2", qty = 1, price = 14.5 }
      }
    }, "parse tabular with length marker")
  end)

  it("accepts length marker on nested arrays", function()
    local toon_str = "pairs[#2]:\n  - [#2]: a,b\n  - [#2]: c,d"
    assertDeepEquals(toon.decode(toon_str), { pairs = { { "a", "b" }, { "c", "d" } } }, "parse nested with length marker")
  end)

  it("works with custom delimiters and length marker", function()
    assertDeepEquals(toon.decode("tags[#3|]: reading|gaming|coding"), { tags = { "reading", "gaming", "coding" } },
      "parse with length marker and pipe")
  end)
end)

describe("basic parsing", function()
  it("accepts correct indentation with custom indent size", function()
    local toon_str = "a:\n    b: 1"
    assertDeepEquals(toon.decode(toon_str, { indent = 4 }), { a = { b = 1 } }, "parse with custom indent")
  end)

  it("accepts tabs in quoted string values", function()
    local toon_str = 'text: "hello\tworld"'
    assertDeepEquals(toon.decode(toon_str), { text = "hello\tworld" }, "parse tab in quoted value")
  end)

  it("accepts tabs in quoted keys", function()
    local toon_str = '"key\ttab": value'
    assertDeepEquals(toon.decode(toon_str), { ["key\ttab"] = "value" }, "parse tab in quoted key")
  end)

  it("accepts tabs in quoted array elements", function()
    local toon_str = 'items[2]: "a\tb","c\td"'
    assertDeepEquals(toon.decode(toon_str), { items = { "a\tb", "c\td" } }, "parse tab in quoted array")
  end)

  it("empty lines do not trigger validation errors", function()
    local toon_str = "a: 1\n\nb: 2"
    assertDeepEquals(toon.decode(toon_str), { a = 1, b = 2 }, "parse with empty lines")
  end)

  it("root-level content (0 indentation) is always valid", function()
    local toon_str = "a: 1\nb: 2\nc: 3"
    assertDeepEquals(toon.decode(toon_str), { a = 1, b = 2, c = 3 }, "parse root level content")
  end)
end)

test.printSummary()
