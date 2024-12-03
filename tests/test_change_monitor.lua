-- Filename: test_main.lua

-- Require the assertions module
local testy = require("./testy")
local base64 = require("../actions/base64")
local overview_spy = require("../actions/overview_spy")
local change_monitor = require("../actions/change_monitor")

local tot = {}

function tot:testPresenceHandling()
    local mock_get_fn = function(key)
        if key == "presence_map" then
            return {
                [overview_spy.encode_key("Object1","TypeA")] = { count = 2, reported = false }, -- Почти достиг порога
                [overview_spy.encode_key("Object2","TypeB")] = { count = 1, reported = false }  -- Находится на пороге
            }
        elseif key == "absence_map" then
            return {}
        elseif key == "previously_objects" then
            return {}
        end
        return nil
    end

    local mock_set_fn = function(key, value)
        local function table_to_string(tbl)
            local result = {}
            for k, v in pairs(tbl) do
                table.insert(result, string.format("%s: %s", tostring(k), tostring(v)))
            end
            return "{" .. table.concat(result, ", ") .. "}"
        end

        local value_str = type(value) == "table" and table_to_string(value) or tostring(value)
        -- print(string.format("Set %s: %s", key, value_str))
    end

    local events_triggered = {}
    local mock_callback_fn = function(event_type, key, data)
        table.insert(events_triggered, { event_type = event_type, key = key, data = data })
    end

    local config = {
        presence_key = "presence_map",
        absence_key = "absence_map",
        previous_key = "previously_objects",
        presence_threshold = 3,
        absence_threshold = 3,
    }

    local eve = {
        overview_windows = {
            entries = {
                { object_name = "Object1", object_type = "TypeA", object_distance = "100 km" },
                { object_name = "Object2", object_type = "TypeB", object_distance = "200 km" },
            },
        },
    }

    change_monitor.detect(config, mock_callback_fn, mock_get_fn, mock_set_fn, eve)

    -- Check assertions for presence
    local found = false
    for _, event in ipairs(events_triggered) do
        if event.event_type == "presence" and event.key == overview_spy.encode_key("Object1","TypeA") then
            found = true
            testy.assertEquals(event.data.name, "Object1", "Object1_TypeA name should match")
            testy.assertEquals(event.data.object_type, "TypeA", "Object1_TypeA type should match")
            break
        end
    end

    if not found then
        -- print("Event for Object1_TypeA was not triggered")
    end
end

function tot:testAbsenceHandling()
    -- Mock the get_fn to simulate state
    local mock_get_fn = function(key)
        if key == "presence_map" then
            return {}
        elseif key == "absence_map" then
            return { ["Object1_TypeA"] = 2 } -- Almost reached absence threshold
        elseif key == "previously_objects" then
            return { ["Object1_TypeA"] = { name = "Object1", object_type = "TypeA", distance = "100 km" } }
        end
        return nil
    end

    -- Mock the set_fn to capture state changes
    local mock_set_fn = function(key, value)
        local function table_to_string(tbl)
            local result = {}
            for k, v in pairs(tbl) do
                table.insert(result, string.format("%s: %s", tostring(k), tostring(v)))
            end
            return "{" .. table.concat(result, ", ") .. "}"
        end

        local value_str = type(value) == "table" and table_to_string(value) or tostring(value)
    end

    -- Mock the callback function to capture events
    local events_triggered = {}
    local mock_callback_fn = function(event_type, key, data)
        table.insert(events_triggered, { event_type = event_type, key = key, data = data })
    end

    -- Configuration for thresholds
    local config = {
        presence_key = "presence_map",
        absence_key = "absence_map",
        previous_key = "previously_objects",
        presence_threshold = 3,
        absence_threshold = 3,
    }

    -- Input data with no entries (simulating absence of objects)
    local eve = {
        overview_windows = {
            entries = {}, -- Empty, indicating objects are no longer present
        },
    }

    local current_objects: { [string]: any } = overview_spy.process_data(eve.overview_windows) or {}

    -- Run the function
    change_monitor.detect(config, mock_callback_fn, mock_get_fn, mock_set_fn, current_objects)

    -- Assertions
    local found = false
    for _, event in ipairs(events_triggered) do
        if event.event_type == "absence" and event.key == "Object1_TypeA" then
            found = true
            testy.assertEquals(event.data.name, "Object1", "Object1_TypeA name should match")
            testy.assertEquals(event.data.object_type, "TypeA", "Object1_TypeA type should match")
            break
        end
    end

    testy.assertTrue(found, "Event for Object1_TypeA absence should have been triggered")
end


-- Run all tests
testy.run(tot)

