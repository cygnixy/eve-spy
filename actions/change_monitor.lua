local M = {}

-- Function to merge keys from two tables
local function merge_keys(tbl1: { [string]: any }, tbl2: { [string]: any }): { [string]: boolean }
    local result: { [string]: boolean } = {}
    
    for key, _ in tbl1 do
        result[key] = true
    end
    
    for key, _ in tbl2 do
        result[key] = true
    end
    
    return result
end

-- Function to handle presence-related logic
local function handle_presence(
    current_objects: { [string]: any },
    presence_map: { [string]: { count: number, reported: boolean } },
    previous_objects: { [string]: any },
    config: any,
    callback_fn: (string, string, any, any) -> ()
)
    for key, data in current_objects do
        local presence = presence_map[key]
        if presence then
            -- Increment the presence count for the object
            presence.count = presence.count + 1

            -- Check if the presence count has reached the threshold and hasn't been reported yet
            if presence.count >= config.presence_threshold and not presence.reported then
                callback_fn("presence", key, data, config)

                -- Mark the event as reported to avoid duplicate callbacks
                presence.reported = true

                -- Update previous_objects with the current data for this object
                previous_objects[key] = data
            end
        else
            -- Initialize presence_map for a new object with count 1 and reported as false
            presence_map[key] = { count = 1, reported = false }
        end
    end
end

-- Function to handle absence-related logic by merging keys
local function handle_absence(
    current_objects: { [string]: any },
    presence_map: { [string]: { count: number, reported: boolean } },
    previous_objects: { [string]: any },
    absence_map: { [string]: number },
    config: any,
    callback_fn: (string, string, any, any) -> ()
): { [string]: number }
    local merged_keys = merge_keys(previous_objects, absence_map)
    local new_absence_map: { [string]: number } = {}

    for key, _ in merged_keys do
        if not current_objects[key] then
            local count = (absence_map[key] or 0) + 1

            if count >= config.absence_threshold then
                callback_fn("absence", key, previous_objects[key], config)

                -- Remove the object from presence_map as it is now absent
                presence_map[key] = nil

                -- Remove the object from previous_objects since it's confirmed absent
                previous_objects[key] = nil
            else
                -- Update the new_absence_map with the incremented count
                new_absence_map[key] = count
            end
        else
            -- If the object is present, retain its absence count (if any)
            new_absence_map[key] = absence_map[key] or 0
        end
    end

    return new_absence_map
end

-- Main function to detect and handle changes
function M.detect(
    config: any,
    callback_fn: (string, string, any, any) -> (),
    get_fn: (string) -> any,
    set_fn: (string, any) -> (),
    current_objects: any
)
    -- Retrieve the current state from storage using get_fn
    local presence_map: { [string]: { count: number, reported: boolean } } = get_fn("presence_map") or {}
    local absence_map: { [string]: number } = get_fn("absence_map") or {}
    local previous_objects: { [string]: any } = get_fn("previously_objects") or {}

    -- Handle Presence of Objects
    handle_presence(current_objects, presence_map, previous_objects, config, callback_fn)

    -- Handle Absence of Objects by merging keys
    local new_absence_map = handle_absence(current_objects, presence_map, previous_objects, absence_map, config, callback_fn)

    -- Save the updated maps back to storage using set_fn
    set_fn("presence_map", presence_map)
    set_fn("absence_map", new_absence_map)
    set_fn("previously_objects", previous_objects)
end

return M
