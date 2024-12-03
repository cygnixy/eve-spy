-- Filename: assertions.lua

local M = {}

-- Prefix for failure messages to identify assertion failures
M.FAILURE_PREFIX = "ASSERTION FAILED: "

-- Number of stack trace entries to strip (for cleaner error messages)
M.STRIP_EXTRA_ENTRIES_IN_STACK_TRACE = 0

-- Helper function to convert values to a readable string
local function prettystr(value)
    if type(value) == "table" then
        local s = "{ "
        for k, v in pairs(value) do
            s = s .. tostring(k) .. " = " .. tostring(v) .. ", "
        end
        return s .. "}"
    else
        return tostring(value)
    end
end

-- Failure handler function
local function failure(main_msg, extra_msg_or_nil, level)
    -- Adjust the error level to point to the caller's context
    level = (level or 1) + 1 + (M.STRIP_EXTRA_ENTRIES_IN_STACK_TRACE or 0)

    -- Construct the error message
    local msg
    if type(extra_msg_or_nil) == 'string' and extra_msg_or_nil:len() > 0 then
        msg = extra_msg_or_nil .. '\n' .. main_msg
    else
        msg = main_msg
    end

    -- Raise an error indicating a test failure
    error(M.FAILURE_PREFIX .. msg, level)
end

-- Assertion: General truthy check
function M.assertTrue(value, extra_msg_or_nil)
    if not value then
        failure("Assertion failed: expected value to be truthy, but got " .. tostring(value), extra_msg_or_nil, 2)
    end
end

-- Assertion: Checks if a value is nil
function M.assertIsNil(value, extra_msg_or_nil)
    if value ~= nil then
        failure("expected: nil, actual: " .. prettystr(value), extra_msg_or_nil, 2)
    end
end

-- Assertion: Checks if a value is not nil
function M.assertNotNil(value, extra_msg_or_nil)
    if value == nil then
        failure("expected value to be not nil, but got nil", extra_msg_or_nil, 2)
    end
end

-- Assertion: Checks if two values are equal
function M.assertEquals(actual, expected, extra_msg_or_nil)
    if actual ~= expected then
        failure("expected: " .. prettystr(expected) .. ", actual: " .. prettystr(actual), extra_msg_or_nil, 2)
    end
end


-- Assertion: Checks if two values are not equal
function M.assertNotEquals(actual, expected, extra_msg_or_nil)
    if actual == expected then
        failure("not expected: " .. prettystr(expected) .. ", actual: " .. prettystr(actual), extra_msg_or_nil, 2)
    end
end


-- Assertion: Checks if a value is a function
function M.assertIsFunction(value, extra_msg_or_nil)
    if type(value) ~= "function" then
        failure("expected: function, actual: " .. prettystr(value), extra_msg_or_nil, 2)
    end
end


-- Function to run all tests and summarize results
function M.run(tot)
    local passed = 0
    local failed = 0

    for testName, testFunc in pairs(tot) do
        print("\nRunning " .. testName .. "...")
        local status, err = pcall(testFunc)
        if status then
            print("🎉 " .. testName .. " passed.")
            passed = passed + 1
        else
            print("❌ " .. testName .. " failed.")
            print("   " .. err)
            failed = failed + 1
        end
    end
    print()
    print("Passed: " .. passed .. ", Failed: " .. failed)
end

return M
