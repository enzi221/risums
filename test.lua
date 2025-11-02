local framework = {}

local totalTests = 0
local passedTests = 0
local failedTests = 0

function framework.assertEquals(actual, expected, message)
  totalTests = totalTests + 1
  if actual == expected then
    passedTests = passedTests + 1
    print("✓ " .. message)
  else
    failedTests = failedTests + 1
    print("✗ " .. message)
    print("  Expected: " .. tostring(expected))
    print("  Actual:   " .. tostring(actual))
  end
end

function framework.describe(name, fn)
  print("\n" .. name)
  fn()
end

function framework.it(name, fn)
  fn()
end

function framework.printSummary()
  print("\n" .. string.rep("=", 50))
  print("Test Summary")
  print(string.rep("=", 50))
  print(string.format("Total:  %d", totalTests))
  print(string.format("Passed: %d", passedTests))
  print(string.format("Failed: %d", failedTests))
  print(string.rep("=", 50))
  
  if failedTests == 0 then
    print("✓ All tests passed!")
    os.exit(0)
  else
    print("✗ Some tests failed")
    os.exit(1)
  end
end

function framework.getStats()
  return {
    total = totalTests,
    passed = passedTests,
    failed = failedTests
  }
end

function framework.incrementTotal()
  totalTests = totalTests + 1
end

function framework.incrementPassed()
  passedTests = passedTests + 1
end

function framework.incrementFailed()
  failedTests = failedTests + 1
end

return framework