-- transition manager

hg = require("harfang")
require("utils")
require("slides_specs")

local node_template = {
    type = nil,
    instance_node = nil,
    node = nil,
    start_clock = nil,
    fade_mode = nil,
    direction = nil
}

function CreateTransitionManager()
    return {}
end

function UpdateTransitions(_scene, _items_list, _dt, _current_clock)
    local idx
    local cleanup_slide = {}

    for k, n in pairs(_items_list) do
        local age = hg.time_to_sec_f(_current_clock - n.start_clock)
        local fade = map(age, 0.0, n.duration, 0.0, 1.0)
        local fade_value
        if n.fade_mode == "in" then
            fade_value = fade
        elseif n.fade_mode == "out" then
            fade_value = 1.0 - fade
        end
        if n.type == action_type.node then
            hg.SetMaterialValue(n.material, "uFade", hg.Vec4(clamp(fade_value, 0.0, 1.0), 0.0, 0.0, 0.0))
        elseif n.type == action_type.func then
            n.context.scene.environment.ambient.r = 1.0 - clamp(fade_value, 0.0, 1.0)
        end
        if fade > 1.0 then
            table.insert(cleanup_slide, idx)
        end
    end

    -- cleanup
    if #cleanup_slide > 0 then
        table.sort(cleanup_slide, function(a, b) return a > b end)

        for _, idx in ipairs(cleanup_slide) do
            table.remove(_items_list, idx + 1)
        end
    end

    return _items_list
end

function FadeinNode(_scene, _instance_node_name, _node_name, _items_list, _current_clock, _duration, _delay, _direction)
    return FadeNode(_scene, _instance_node_name, _node_name, _items_list, _current_clock, _duration, _delay, "in")
end

function FadeoutNode(_scene, _instance_node_name, _node_name, _items_list, _current_clock, _duration, _delay, _direction)
    return FadeNode(_scene, _instance_node_name, _node_name, _items_list, _current_clock, _duration, _delay, "out")
end


function FadeNode(_scene, _instance_node_name, _node_name, _items_list, _current_clock, _duration, _delay, _fade_mode, _direction)
    _duration = _duration or 1.0
    _delay = _delay or 0.0
    _direction = _direction or "none"
    -- _fade_mode = _fade_mode or "in"
    -- local video_screen_node =  video_screen_instance_node:GetInstanceSceneView():GetNode(scene, "video_screen")
    local _node_key = _instance_node_name .. "_" .. _node_name
    local _instance_node = _scene:GetNode(_instance_node_name)
    local _node = _instance_node:GetInstanceSceneView():GetNode(_scene, _node_name)
	local _node_material = _node:GetObject():GetMaterial(0)
    -- _node:Enable()

    _items_list[_node_key] = {
        type = action_type.node,
        instance_node = _instance_node,
        node = _node,
        material = _node_material,
        start_clock = _current_clock + hg.time_from_sec_f(_delay),
        duration = _duration,
        fade_mode = _fade_mode,
        direction = _direction
    }

    return _items_list
end

function FadeinFunction(_context, _items_list, _current_clock, _duration)
    local _func_key = tostring(_context.scene)
    _items_list[_func_key] = {
        type = action_type.func,
        fade_mode = "in",
        context = _context,
        start_clock = _current_clock,
        duration = _duration
    }
    return _items_list
end