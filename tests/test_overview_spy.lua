-- Require the assertions module
local testy = require("./testy")
local base64 = require("../actions/base64")
local overview_spy = require("../actions/overview_spy")

local tot = {}

-- Test the parse_distance function
function tot:testParseDistance()
    -- Access the parse_distance function from the module
    local parse_distance = overview_spy.parse_distance

    -- Use assertion to check if parse_distance is a function
    testy.assertIsFunction(parse_distance, "parse_distance should be a function")

    -- Test Cases
    -- 1. Input with comma
    local distance, unit = parse_distance("1,500 km")
    testy.assertEquals(distance, 1500, "Parsing '1,500 km' - Distance")
    testy.assertEquals(unit, "km", "Parsing '1,500 km' - Unit")

    -- 2. Input without comma
    distance, unit = parse_distance("1500 km")
    testy.assertEquals(distance, 1500, "Parsing '1500 km' - Distance")
    testy.assertEquals(unit, "km", "Parsing '1500 km' - Unit")

    -- 3. Input with different unit
    distance, unit = parse_distance("750m")
    testy.assertEquals(distance, 750, "Parsing '750m' - Distance")
    testy.assertEquals(unit, "m", "Parsing '750m' - Unit")

    distance, unit = parse_distance("5 264 km")
    testy.assertEquals(distance, 5264, "Parsing '5 264 km' - Distance")
    testy.assertEquals(unit, "km", "Parsing '5 264 km' - Unit")

    distance, unit = parse_distance("5 AU")
    testy.assertEquals(distance, 5, "Parsing '5 AU' - Distance")
    testy.assertEquals(unit, "AU", "Parsing '5 AU' - Unit")

    -- 4. Invalid inputs
    distance, unit = parse_distance("invalid")
    testy.assertIsNil(distance, "Parsing 'invalid' - Distance")
    testy.assertIsNil(unit, "Parsing 'invalid' - Unit")

    distance, unit = parse_distance("1000")
    testy.assertIsNil(distance, "Parsing '1000' - Distance")
    testy.assertIsNil(unit, "Parsing '1000' - Unit")

    distance, unit = parse_distance("1000 miles")
    testy.assertIsNil(distance, "Parsing '1000 miles' - Distance")
    testy.assertIsNil(unit, "Parsing '1000 miles' - Unit")
end

function tot:testExtractObjects()
    local extract_objects = overview_spy.extract_objects
    assert(extract_objects, "Failed to load extract_objects")

    local entry = {
        object_name = "Ibis",
        object_type = "Frigate",
        object_distance = "5,000 km",
        cells_texts = {
            Alliance = "[5MART]",
            Velocity = "0",
            Corporation = "[L8R4U]",
            Angular_Velocity = "0.01",
        },
    }

    local key, data = extract_objects(entry)
    testy.assertEquals(key, overview_spy.encode_key("Ibis","Frigate"), "Should generate the correct key")
    testy.assertEquals(data.name, "Ibis", "Name should match")
end

function tot:testProcessData()
    local process_data = overview_spy.process_data
    assert(process_data, "process_data function is not loaded")

    local data = {
        entries = {
            { object_name = "Ibis", object_type = "Frigate", object_distance = "5,000 km" },
            { object_name = "Sunesis", object_type = "Destroyer", object_distance = "6,000 km" },
        },
    }

    local current_objects = process_data(data)  -- Call the function

    testy.assertEquals(type(current_objects), "table", "Should return a table")
    testy.assertNotNil(current_objects[overview_spy.encode_key("Ibis","Frigate")], "Ibis_Frigate should exist in the table")
    testy.assertNotNil(current_objects[overview_spy.encode_key("Sunesis","Destroyer")], "Sunesis_Destroyer should exist in the table")
end



-- Run all tests
testy.run(tot)

