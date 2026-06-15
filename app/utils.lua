-- Maps a value from one range to another.
function map(value, min1, max1, min2, max2)
    return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
end

-- Clamps a value between a minimum and maximum value.
function clamp(value, min1, max1)
    return math.min(math.max(value, min1), max1)
end

-- Frame rate independent damping using Lerp.
-- Takes into account delta time to provide consistent damping across variable frame rates.
function dtAwareDamp(source, target, smoothing, dt)
    return hg.Lerp(source, target, 1.0 - (smoothing^dt))
end

-- Returns a new resolution based on a multiplier.
function resolution_multiplier(w, h, m)
    return math.floor(w * m), math.floor(h * m)
end

-- Returns a random angle in radians between -π and π.
function rand_angle()
    local a = math.random() * math.pi
    if math.random() > 0.5 then
        return a
    else
        return -a
    end
end

-- Ease-in-out function for smoother transitions.
function EaseInOutQuick(x)
	x = clamp(x, 0.0, 1.0)
	return	(x * x * (3 - 2 * x))
end

-- Returns the current operating system as "windows", "macos", "linux" or "unknown".
function GetOperatingSystem()
    local path_separator = package.config:sub(1, 1)
    if path_separator == "\\" then
        return "windows"
    end

    if jit and jit.os then
        local os_name = string.lower(jit.os)
        if os_name == "osx" then
            return "macos"
        elseif os_name == "linux" then
            return "linux"
        elseif os_name == "windows" then
            return "windows"
        end
    end

    local handle = io.popen("uname -s 2>/dev/null")
    if handle then
        local uname = handle:read("*l")
        handle:close()

        if uname == "Darwin" then
            return "macos"
        elseif uname == "Linux" then
            return "linux"
        end
    end

    return "unknown"
end

-- Detects if the current OS is Linux.
function IsLinux()
    return GetOperatingSystem() == "linux"
end

function IsMacOS()
    return GetOperatingSystem() == "macos"
end

function IsWindows()
    return GetOperatingSystem() == "windows"
end

-- Reads and decodes a JSON file.
function read_json(filename)
    local json = require("dkjson")
    local file = io.open(filename, "r")
 
    if not file then
       print("Couldn't open file!")
       return nil
    end
 
    local content = file:read("*all")
    file:close()
 
    local data = json.decode(content)
 
    return data
end

-- Applies advanced rendering (AAA) settings from a JSON file to the provided configuration.
function apply_aaa_settings(aaa_config, scene_path)
    scene_config = read_json(scene_path)
    if scene_config == nil then
       print("Could not apply settings from: " .. scene_path)
    else
       aaa_config.bloom_bias = scene_config.bloom_bias
       aaa_config.bloom_intensity = scene_config.bloom_intensity
       aaa_config.bloom_threshold = scene_config.bloom_threshold
       aaa_config.exposure = scene_config.exposure
       aaa_config.gamma = scene_config.gamma
       aaa_config.max_distance = scene_config.max_distance
       aaa_config.motion_blur = scene_config.motion_blur
       aaa_config.sample_count = scene_config.sample_count
       aaa_config.taa_weight = scene_config.taa_weight
       aaa_config.z_thickness = scene_config.z_thickness
    end
end

function getcwd()
    local handle = io.popen("cd")
    local cwd = handle:read("*a")
    handle:close()

    cwd = cwd:gsub("%s+", "") -- Remove any trailing whitespace/newlines
    return cwd
end

function IsTableEmpty(t)
    return next(t) == nil
end

function GetPreferredKeyboardDeviceName()
    local keyboard_names = hg.GetKeyboardNames()
    for i = 0, keyboard_names:size() - 1 do
        if keyboard_names:at(i) == "raw" then
            return "raw"
        end
    end
    return "default"
end

function CalculateCameraDistance(fov_rad, polygon_dimension)
    -- Calculate half of the FOV
    local half_fov = fov_rad / 2
    
    -- Calculate half the polygon width
    local half_width = polygon_dimension / 2
    
    -- Calculate the distance using the formula: distance = half_width / tan(half_fov)
    local distance = half_width / math.tan(half_fov)
    
    return distance
end

function NodeGetPhysicsMass(node)
    local n = node:GetCollisionCount()
    local mass = 0
    for i = 0, n-1 do
        local col = node:GetCollision(i)
        mass = mass + col:GetMass()
    end

    return mass
end

function NodeGetPhysicsCenterOfMass(node)
    local mass = NodeGetPhysicsMass(node)
    local n = node:GetCollisionCount()
    local center_of_mass = hg.Vec3(0,0,0)
    for i = 0, n-1 do
        local col = node:GetCollision(i)
        local mass_ratio = col:GetMass() / mass
        center_of_mass = center_of_mass + (hg.GetTranslation(col:GetLocalTransform()) * mass_ratio)
    end

    return center_of_mass
end

function CreateMaterialFromProgram(prg_ref, ubc, orm)
    mat = hg.Material()
    hg.SetMaterialProgram(mat, prg_ref)
    hg.SetMaterialValue(mat, "uBaseOpacityColor", ubc)
    hg.SetMaterialValue(mat, "uOcclusionRoughnessMetalnessColor", orm)
    return mat
end

function TruncateFloat(v, n)
    return math.floor(v * (10^n)) / (10^n)
end

-- Function to check if a table is a simple list (array-like)
local function is_array(tbl)
    local index = 1
    for _ in pairs(tbl) do
        if tbl[index] == nil then
            return false
        end
        index = index + 1
    end
    return true
end

-- Function to serialize a Lua table into a Lua syntax string
function serialize_table(tbl, indent)
    local lines = {}
    indent = indent or 0
    local indentation = string.rep("    ", indent)
    
    if type(tbl) ~= "table" then
        error("Input must be a table!")
    end
    
    -- Check if the table is a simple array/list
    local array = is_array(tbl)
    
    table.insert(lines, "{\n")
    
    for key, value in pairs(tbl) do
        local value_repr
        if type(value) == "table" then
            value_repr = serialize_table(value, indent + 1)
        elseif type(value) == "string" then
            value_repr = string.format("%q", value)
        elseif type(value) == "boolean" then
            value_repr = tostring(value)
        else
            value_repr = tostring(value)
        end
        
        -- If the table is an array, omit the key
        if array then
            table.insert(lines, string.format("%s%s,\n", indentation .. "    ", value_repr))
        else
            local key_repr
            if type(key) == "string" then
                key_repr = string.format("%q", key)
            else
                key_repr = tostring(key)
            end
            table.insert(lines, string.format("%s[%s] = %s,\n", indentation .. "    ", key_repr, value_repr))
        end
    end
    
    table.insert(lines, indentation .. "}")
    
    return table.concat(lines)
end

-- Function to write serialized table to a Lua file
function write_table_to_lua_file(tbl, filename)
    local file = io.open(filename, "w")
    
    if file then
        file:write("return ")
        file:write(serialize_table(tbl, 0))  -- Serialize the table with indentation level 0
        file:write("\n")
        
        file:close()
        print("Table serialized and written to " .. filename)
    else
        print("Error opening file: " .. filename)
    end
end

-- -- Serialize Example usage
-- local example_table = {
--     name = "John",
--     age = 30,
--     skills = {"Lua", "Python", "C++"},
--     active = true,
--     scores = {math = 90, science = 85},
-- }

-- write_table_to_lua_file(example_table, "my_table.lua")


