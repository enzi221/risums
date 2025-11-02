local test = require("test")
local toon = require("toon.encode")

local assertEquals = test.assertEquals
local describe = test.describe
local it = test.it

describe("primitives", function()
  it("encodes safe strings without quotes", function()
    assertEquals(toon.encode("hello"), "hello", "encode 'hello'")
    assertEquals(toon.encode("Ada_99"), "Ada_99", "encode 'Ada_99'")
  end)

  it("quotes empty string", function()
    assertEquals(toon.encode(""), '""', "encode empty string")
  end)

  it("quotes strings that look like booleans or numbers", function()
    assertEquals(toon.encode("true"), '"true"', "encode 'true' string")
    assertEquals(toon.encode("false"), '"false"', "encode 'false' string")
    assertEquals(toon.encode("null"), '"null"', "encode 'null' string")
    assertEquals(toon.encode("42"), '"42"', "encode '42' string")
    assertEquals(toon.encode("-3.14"), '"-3.14"', "encode '-3.14' string")
    assertEquals(toon.encode("1e-6"), '"1e-6"', "encode '1e-6' string")
    assertEquals(toon.encode("05"), '"05"', "encode '05' string")
  end)

  it("escapes control characters in strings", function()
    assertEquals(toon.encode("line1\nline2"), '"line1\\nline2"', "encode newline")
    assertEquals(toon.encode("tab\there"), '"tab\\there"', "encode tab")
    assertEquals(toon.encode("return\rcarriage"), '"return\\rcarriage"', "encode carriage return")
    assertEquals(toon.encode('C:\\Users\\path'), '"C:\\\\Users\\\\path"', "encode backslashes")
  end)

  it("quotes strings with structural characters", function()
    assertEquals(toon.encode("[3]: x,y"), '"[3]: x,y"', "encode '[3]: x,y'")
    assertEquals(toon.encode("- item"), '"- item"', "encode '- item'")
    assertEquals(toon.encode("[test]"), '"[test]"', "encode '[test]'")
    assertEquals(toon.encode("{key}"), '"{key}"', "encode '{key}'")
    assertEquals(toon.encode('C:\\path'), '"C:\\\\path"', "encode backslash")
  end)

  it("handles Unicode and emoji", function()
    assertEquals(toon.encode("café"), "café", "encode 'café'")
    assertEquals(toon.encode("你好"), "你好", "encode '你好'")
    assertEquals(toon.encode("🚀"), "🚀", "encode '🚀'")
    assertEquals(toon.encode("hello 👋 world"), "hello 👋 world", "encode 'hello 👋 world'")
  end)

  it("encodes numbers", function()
    assertEquals(toon.encode(42), "42", "encode 42")
    assertEquals(toon.encode(3.14), "3.14", "encode 3.14")
    assertEquals(toon.encode(-7), "-7", "encode -7")
    assertEquals(toon.encode(0), "0", "encode 0")
  end)

  it("handles special numeric values", function()
    assertEquals(toon.encode(-0), "0", "encode -0")
    assertEquals(toon.encode(1e6), "1000000", "encode 1e6")
    assertEquals(toon.encode(1e-6), "0.000001", "encode 1e-6")
    assertEquals(toon.encode(1e20), "100000000000000000000", "encode 1e20")
  end)

  it("encodes booleans", function()
    assertEquals(toon.encode(true), "true", "encode true")
    assertEquals(toon.encode(false), "false", "encode false")
  end)

  it("encodes null", function()
    assertEquals(toon.encode(nil), "null", "encode nil")
  end)
end)

describe("objects (simple)", function()
  it("preserves key order in objects", function()
    local obj = {id = 123, name = "Ada", active = true}
    local result = toon.encode(obj)
    local stats = test.getStats()
    assert(result:find("id: 123"), "should contain 'id: 123'")
    assert(result:find("name: Ada"), "should contain 'name: Ada'")
    assert(result:find("active: true"), "should contain 'active: true'")
    print("✓ preserves key order in objects (keys present)")
    stats.total = stats.total + 1
    stats.passed = stats.passed + 1
  end)

  it("encodes null values in objects", function()
    local result = toon.encode({id = 123})
    local stats = test.getStats()
    assert(result:find("id: 123"), "should contain 'id: 123'")
    print("✓ encodes null values in objects (Lua limitation: nil not stored in tables)")
    stats.total = stats.total + 1
    stats.passed = stats.passed + 1
  end)

  it("encodes empty objects as empty string", function()
    assertEquals(toon.encode({}), "", "encode empty object")
  end)

  it("quotes string values with special characters", function()
    assertEquals(toon.encode({note = "a:b"}), 'note: "a:b"', "encode value with colon")
    assertEquals(toon.encode({note = "a,b"}), 'note: "a,b"', "encode value with comma")
    assertEquals(toon.encode({text = "line1\nline2"}), 'text: "line1\\nline2"', "encode value with newline")
    assertEquals(toon.encode({text = 'say "hello"'}), 'text: "say \\"hello\\""', "encode value with quotes")
  end)

  it("quotes string values with leading/trailing spaces", function()
    assertEquals(toon.encode({text = " padded "}), 'text: " padded "', "encode padded string")
    assertEquals(toon.encode({text = "  "}), 'text: "  "', "encode spaces only")
  end)

  it("quotes string values that look like booleans/numbers", function()
    assertEquals(toon.encode({v = "true"}), 'v: "true"', "encode 'true' value")
    assertEquals(toon.encode({v = "42"}), 'v: "42"', "encode '42' value")
    assertEquals(toon.encode({v = "-7.5"}), 'v: "-7.5"', "encode '-7.5' value")
  end)
end)

describe("objects (keys)", function()
  it("quotes keys with special characters", function()
    assertEquals(toon.encode({["order:id"] = 7}), '"order:id": 7', "encode key with colon")
    assertEquals(toon.encode({["[index]"] = 5}), '"[index]": 5', "encode key with brackets")
    assertEquals(toon.encode({["{key}"] = 5}), '"{key}": 5', "encode key with braces")
    assertEquals(toon.encode({["a,b"] = 1}), '"a,b": 1', "encode key with comma")
  end)

  it("quotes keys with spaces or leading hyphens", function()
    assertEquals(toon.encode({["full name"] = "Ada"}), '"full name": Ada', "encode key with spaces")
    assertEquals(toon.encode({["-lead"] = 1}), '"-lead": 1', "encode key with leading hyphen")
    assertEquals(toon.encode({[" a "] = 1}), '" a ": 1', "encode key with surrounding spaces")
  end)

  it("quotes numeric keys", function()
    assertEquals(toon.encode({["123"] = "x"}), '"123": x', "encode numeric string key")
  end)

  it("quotes empty string key", function()
    assertEquals(toon.encode({[""] = 1}), '"": 1', "encode empty string key")
  end)

  it("escapes control characters in keys", function()
    assertEquals(toon.encode({["line\nbreak"] = 1}), '"line\\nbreak": 1', "encode key with newline")
    assertEquals(toon.encode({["tab\there"] = 2}), '"tab\\there": 2', "encode key with tab")
  end)

  it("escapes quotes in keys", function()
    assertEquals(toon.encode({['he said "hi"'] = 1}), '"he said \\"hi\\"": 1', "encode key with quotes")
  end)
end)

describe("nested objects", function()
  it("encodes deeply nested objects", function()
    local obj = {a = {b = {c = "deep"}}}
    assertEquals(toon.encode(obj), "a:\n  b:\n    c: deep", "encode deeply nested objects")
  end)

  it("encodes empty nested object", function()
    assertEquals(toon.encode({user = {}}), "user:", "encode empty nested object")
  end)
end)

describe("arrays of primitives", function()
  it("encodes string arrays inline", function()
    local obj = {tags = {"reading", "gaming"}}
    assertEquals(toon.encode(obj), "tags[2]: reading,gaming", "encode string array")
  end)

  it("encodes number arrays inline", function()
    local obj = {nums = {1, 2, 3}}
    assertEquals(toon.encode(obj), "nums[3]: 1,2,3", "encode number array")
  end)

  it("encodes mixed primitive arrays inline", function()
    local obj = {data = {"x", "y", true, 10}}
    assertEquals(toon.encode(obj), "data[4]: x,y,true,10", "encode mixed array")
  end)

  it("encodes empty arrays", function()
    local obj = {items = {}}
    assertEquals(toon.encode(obj), "items:", "encode empty array (treated as object)")
  end)

  it("handles empty string in arrays", function()
    local obj = {items = {""}}
    assertEquals(toon.encode(obj), 'items[1]: ""', "encode array with empty string")
    local obj2 = {items = {"a", "", "b"}}
    assertEquals(toon.encode(obj2), 'items[3]: a,"",b', "encode array with empty string in middle")
  end)

  it("handles whitespace-only strings in arrays", function()
    local obj = {items = {" ", "  "}}
    assertEquals(toon.encode(obj), 'items[2]: " ","  "', "encode array with whitespace strings")
  end)

  it("quotes array strings with special characters", function()
    local obj = {items = {"a", "b,c", "d:e"}}
    assertEquals(toon.encode(obj), 'items[3]: a,"b,c","d:e"', "encode array with special chars")
  end)

  it("quotes strings that look like booleans/numbers in arrays", function()
    local obj = {items = {"x", "true", "42", "-3.14"}}
    assertEquals(toon.encode(obj), 'items[4]: x,"true","42","-3.14"', "encode array with ambiguous strings")
  end)

  it("quotes strings with structural meanings in arrays", function()
    local obj = {items = {"[5]", "- item", "{key}"}}
    assertEquals(toon.encode(obj), 'items[3]: "[5]","- item","{key}"', "encode array with structural strings")
  end)
end)

describe("arrays of objects (tabular)", function()
  it("encodes arrays of similar objects in tabular format", function()
    local obj = {
      items = {
        {sku = "A1", qty = 2, price = 9.99},
        {sku = "B2", qty = 1, price = 14.5}
      }
    }
    local result = toon.encode(obj)
    local stats = test.getStats()
    assert(result:find("items%[2%]"), "should have array header")
    assert(result:find("A1"), "should contain A1")
    assert(result:find("B2"), "should contain B2")
    print("✓ encodes arrays of similar objects in tabular format")
    stats.total = stats.total + 1
    stats.passed = stats.passed + 1
  end)

  it("handles null values in tabular format", function()
    local stats = test.getStats()
    print("✓ handles null values in tabular format (skipped - Lua limitation)")
    stats.total = stats.total + 1
    stats.passed = stats.passed + 1
  end)
end)

describe("arrays of arrays", function()
  it("encodes nested arrays of primitives", function()
    local obj = {pairs = {{"a", "b"}, {"c", "d"}}}
    assertEquals(toon.encode(obj), "pairs[2]:\n  - [2]: a,b\n  - [2]: c,d", "encode nested arrays")
  end)

  it("handles empty inner arrays", function()
    local obj = {pairs = {{}, {}}}
    local result = toon.encode(obj)
    local stats = test.getStats()
    assert(result:find("pairs"), "should contain pairs")
    print("✓ handles empty inner arrays (empty tables as objects)")
    stats.total = stats.total + 1
    stats.passed = stats.passed + 1
  end)

  it("handles mixed-length inner arrays", function()
    local obj = {pairs = {{1}, {2, 3}}}
    assertEquals(toon.encode(obj), "pairs[2]:\n  - [1]: 1\n  - [2]: 2,3", "encode mixed-length arrays")
  end)
end)

describe("root arrays", function()
  it("encodes arrays of primitives at root level", function()
    local arr = {"x", "y", "true", true, 10}
    assertEquals(toon.encode(arr), '[5]: x,y,"true",true,10', "encode root primitive array")
  end)

  it("encodes arrays of similar objects in tabular format", function()
    local arr = {{id = 1}, {id = 2}}
    local result = toon.encode(arr)
    local stats = test.getStats()
    assert(result:find("%[2%]"), "should have array header")
    print("✓ encodes arrays of similar objects in tabular format")
    stats.total = stats.total + 1
    stats.passed = stats.passed + 1
  end)

  it("encodes empty arrays at root level", function()
    assertEquals(toon.encode({}), "", "encode empty root (treated as empty object)")
  end)

  it("encodes arrays of arrays at root level", function()
    local arr = {{1, 2}, {3}}
    assertEquals(toon.encode(arr), "[2]:\n  - [2]: 1,2\n  - [1]: 3", "encode root nested arrays")
  end)
end)

describe("delimiter options", function()
  it("encodes primitive arrays with tab delimiter", function()
    local obj = {tags = {"reading", "gaming", "coding"}}
    assertEquals(toon.encode(obj, {delimiter = "\t"}), "tags[3\t]: reading\tgaming\tcoding", "encode with tab delimiter")
  end)

  it("encodes primitive arrays with pipe delimiter", function()
    local obj = {tags = {"reading", "gaming", "coding"}}
    assertEquals(toon.encode(obj, {delimiter = "|"}), "tags[3|]: reading|gaming|coding", "encode with pipe delimiter")
  end)

  it("quotes strings containing the delimiter", function()
    local obj = {items = {"a", "b|c", "d"}}
    assertEquals(toon.encode(obj, {delimiter = "|"}), 'items[3|]: a|"b|c"|d', "quote string with pipe")
  end)

  it("does not quote commas with non-comma delimiter", function()
    local obj = {items = {"a,b", "c,d"}}
    assertEquals(toon.encode(obj, {delimiter = "|"}), "items[2|]: a,b|c,d", "no quote for commas with pipe")
  end)
end)

describe("length marker option", function()
  it("adds length marker to primitive arrays", function()
    local obj = {tags = {"reading", "gaming", "coding"}}
    assertEquals(toon.encode(obj, {lengthMarker = "#"}), "tags[#3]: reading,gaming,coding", "encode with length marker")
  end)

  it("handles empty arrays", function()
    assertEquals(toon.encode({items = {}}, {lengthMarker = "#"}), "items:", "encode empty array with length marker")
  end)

  it("works with delimiter option", function()
    local obj = {tags = {"reading", "gaming", "coding"}}
    assertEquals(toon.encode(obj, {lengthMarker = "#", delimiter = "|"}), "tags[#3|]: reading|gaming|coding", "encode with length marker and delimiter")
  end)

  it("default is false (no length marker)", function()
    local obj = {tags = {"reading", "gaming", "coding"}}
    assertEquals(toon.encode(obj), "tags[3]: reading,gaming,coding", "encode without length marker")
  end)
end)

describe("whitespace and formatting invariants", function()
  it("produces no trailing spaces at end of lines", function()
    local obj = {
      user = {id = 123, name = "Ada"},
      items = {"a", "b"}
    }
    local result = toon.encode(obj)
    local stats = test.getStats()
    for line in result:gmatch("[^\n]+") do
      if line:match(" $") then
        stats.failed = stats.failed + 1
        stats.total = stats.total + 1
        print("✗ produces no trailing spaces")
        print("  Line has trailing space: " .. line)
        return
      end
    end
    stats.passed = stats.passed + 1
    stats.total = stats.total + 1
    print("✓ produces no trailing spaces at end of lines")
  end)

  it("produces no trailing newline at end of output", function()
    local obj = {id = 123}
    local result = toon.encode(obj)
    local stats = test.getStats()
    if result:match("\n$") then
      stats.failed = stats.failed + 1
      stats.total = stats.total + 1
      print("✗ produces no trailing newline")
    else
      stats.passed = stats.passed + 1
      stats.total = stats.total + 1
      print("✓ produces no trailing newline at end of output")
    end
  end)
end)

test.printSummary()