local M = {}

local base64 = require("./base64")
local change_monitor = require("./change_monitor")

-- Function to safely retrieve nested values from a table
function M.get_nested_value(root: any, ...: string): any
    local keys = { ... }
    local value = root
    for _, key in keys do
        if type(value) ~= "table" then
            return nil
        end
        value = value[key]
        if value == nil then
            break
        end
    end
    return value
end

-- Function to encode a key using Base64 encoding
local function encode_key(name: string, object_type: string): string
    local encoded_name = base64.encode(name)
    local encoded_object_type = base64.encode(object_type)
    local encoded_key = encoded_name .. ":" .. encoded_object_type
    return encoded_key
end

-- Function to decode a key from Base64 encoding
local function decode_key(encoded_key: string): (string?, string?)
    local parts = string.split(encoded_key, ":")
    
    if #parts ~= 2 then
        warn("Invalid encoded key format. Expected format 'Base64(name):Base64(object_type)'.")
        return nil, nil
    end
    
    local success_name, decoded_name = pcall(base64.decode, parts[1])
    if not success_name then
        warn("Failed to decode Base64 for 'name': " .. tostring(decoded_name))
        decoded_name = nil
    end
    
    local success_object_type, decoded_object_type = pcall(base64.decode, parts[2])
    if not success_object_type then
        warn("Failed to decode Base64 for 'object_type': " .. tostring(decoded_object_type))
        decoded_object_type = nil
    end
    
    return decoded_name, decoded_object_type
end

-- Function to extract objects from an entry
function M.extract_objects(entry: any): (string?, any?)
    if entry and entry.object_name and entry.object_type and entry.object_distance then
        local data = {
            name = entry.object_name,
            object_type = entry.object_type,
            distance = entry.object_distance,
        }
        local key = encode_key(data.name, data.object_type)
        return key, data
    end
    return nil, nil
end

-- Function to process data from eve.overview_windows
function M.process_data(data: any): { [string]: any }
    local current_objects: { [string]: any } = {}

    if data and data.entries then
        for _, entry in data.entries do
            local key, object_data = M.extract_objects(entry)
            if key and object_data then
                current_objects[key] = object_data
            end
        end
    else
        warn("Error: No entries found in data.")
    end

    return current_objects
end

-- Function to parse distance strings (e.g., "100m", "2.5 km", "5 264 km")
function M.parse_distance(distance_str: string): (number?, string?)
    -- Pattern to capture the entire numeric part and the unit
    local pattern = "^(.-)%s*(%a+)$"
    local numeric_part, unit = string.match(distance_str, pattern)

    -- Validate the unit after matching
    if numeric_part and unit and (unit == "km" or unit == "m" or unit == "AU") then
        -- Remove any characters that are not digits, commas, or dots from the numeric part
        local clean_numeric = string.gsub(numeric_part, "[^%d%,%.]", "")
        
        -- Remove commas from the numeric string
        local cleaned_str, _ = string.gsub(clean_numeric, ",", "")
        
        -- Convert the cleaned string to a number
        local clean_distance = tonumber(cleaned_str)
        
        if clean_distance then
            return clean_distance, unit
        else
            return nil, nil
        end
    else
        return nil, nil
    end
end

-- Event handler function to process presence and absence events
function M.event_handler(event_type: string, key: string, data: any)
    local current_system_name: string = M.get_nested_value(eve, "info_panel_container", "info_panel_location_info",
        "current_solar_system_name") or ""

    if event_type == "presence" then
        local formatted_distance = "unknown"
        -- Check and process distance if available
        if data and data.distance then
            local distance_num, distance_unit = M.parse_distance(data.distance)
            if distance_num and distance_unit then
                formatted_distance = string.format("%.2f %s", distance_num, distance_unit)
            end
        end
        info(string.format("+|%s|%s|%s|%s", current_system_name, data and data.name or "unknown", data and data.object_type or "unknown", formatted_distance))
    elseif event_type == "absence" then
        local decoded_name, decoded_object_type = decode_key(key)
        info(string.format("-|%s|%s|%s", current_system_name, decoded_name or "unknown", decoded_object_type or "unknown"))
    end
end

function M.main(args: any): string

    local config = {
        presence_threshold = args[1],
        absence_threshold = args[2],
    }

    local current_objects = M.process_data(eve.overview_windows) or {}
    
    change_monitor.detect(config, M.event_handler, cygnixy.bb_get, cygnixy.bb_set, current_objects)

    return "Running"
end

-- Export helper functions for testing
M.encode_key = encode_key
M.decode_key = decode_key

return M
