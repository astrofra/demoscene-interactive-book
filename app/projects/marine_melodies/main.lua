-- Marine melodies (part of it)

hg = require("harfang")
require("projects/marine_melodies/animations")
require("projects/marine_melodies/boids")
require("projects/marine_melodies/bubbles")
require("utils")

function SceneMarineMelodiesSetup(res, pipeline_info, bg_color)
    -- Load scene
    local _scene = hg.Scene()
    hg.LoadSceneFromAssets("projects/marine_melodies/main.scn", _scene, res, pipeline_info)
    _scene.canvas.color = bg_color
    _scene.environment.fog_color = bg_color
    _scene.canvas.clear_color = false

        -- physics
    local physics = hg.SceneBullet3Physics()
    physics:SceneCreatePhysicsFromAssets(_scene)

    local p_nodes = {}
    local _n = _scene:GetNodes()

    for i = 0, _n:size() - 1 do
        if string.sub(_n:at(i):GetName(), 1, 3) == "col" then
            table.insert(p_nodes, _n:at(i))
            -- print(_n:at(i):GetName())
        end
    end

    -- -- bubbles
    -- local bubble_particles = {emitter={spawn_timeout=hg.time_from_sec_f(0.0)}, particles={}}
    -- local blank_bubble = hg.CreateInstanceFromAssets(_scene, hg.TranslationMat4(hg.Vec3(0,0,0)), "projects/marine_melodies/bubble.scn", res, hg.GetForwardPipelineInfo()) -- , hg.LSSF_Nodes | hg.LSSF_Scene | hg.LSSF_DoNotChangeCurrentCameraIfValid)
    -- blank_bubble:Disable()

    -- local minisub_emitter_trigger = _scene:GetNodeEx("minisub_anim/engine_thrust") -- this node has an animated attribute (enabled/disabled) that tells if we shall emit some particles or not
    -- minisub_emitter_trigger:RemoveObject() -- we don't need the visual clue for this node, only the enabled status will matter.


	-- main camera
    -- local _camera = _scene:GetNode("Camera")
    -- local _pos = _camera:GetTransform():GetPos()

    -- fish boids init
    local fish_boids = {}
    local boids_min_max = hg.MinMax(hg.Vec3(-20, -5, -5), hg.Vec3(20, 25, 50))
    for i = 0, 100 do
        table.insert(fish_boids, {pos=hg.Vec3(math.random(boids_min_max.mn.x, boids_min_max.mx.x) * 0.1 + 5.0, 
                                                math.random(boids_min_max.mn.y, boids_min_max.mx.y) * 0.1, 
                                                math.random(boids_min_max.mn.z, boids_min_max.mx.z) * 0.1), 
                                    dir=hg.Vec3(math.random(-100, 100)/200.0, math.random(-100, 100)/200.0, math.random(-100, 100)/200.0),
                                    target_dir=hg.Vec3(math.random(-100, 100)/200.0, math.random(-100, 100)/200.0, math.random(-100, 100)/200.0),
                                    age=hg.time_from_sec_f(0.0),
                                    node=nil, transform=nil})
    end

    -- load models for the fish
    for i = 1, #fish_boids do
        fish_boids[i].node = hg.CreateInstanceFromAssets(_scene, hg.TranslationMat4(hg.Vec3(0,0,0)), "projects/marine_melodies/Cartoon_Fish/fish_0.scn", res, pipeline_info)
        fish_boids[i].transform = fish_boids[i].node:GetTransform()
    end

    local ctx = {
        scene = _scene,
        res = res,
        pipeline_info = pipeline_info,
        -- camera = main_camera
        anim_has_started = false,
        playing_anim = 0,
        current_anim = 0,
        anims = {"subanim0", "subanim1", "subanim2", "subanim3", "subanim4", "subanim5"},
        fish_boids = fish_boids,
        boids_min_max = boids_min_max,
        physics = physics,
        p_nodes = p_nodes,
        bubble_particles = bubble_particles,
        blank_bubble = blank_bubble,
        minisub_pos = hg.Vec3(0,0,0),
        minisub_emitter_trigger = minisub_emitter_trigger

    }

    return ctx
end

function SceneMarineMelodiesUpdate(ctx, keyboard, gamepad, prev_gamepad, dt, current_clock)
    local dts = hg.time_to_sec_f(dt)
    local scene_clocks = hg.SceneClocks()

    -- -- submarine
    -- ctx.anim_has_started, ctx.playing_anim, ctx.current_anim = anim_player(ctx.scene, ctx.anims, ctx.anim_has_started, ctx.playing_anim, ctx.current_anim)

    -- -- submarine propeller bubbles
    -- local minisub = ctx.scene:GetNodeEx("minisub_anim:emitter")
    -- local minisub_prev_pos = ctx.minisub_pos
    -- local minisub_matrix = minisub:GetTransform():GetWorld()
    -- ctx.minisub_pos = hg.GetTranslation(minisub_matrix)
    -- local _tmp_vec = hg.Normalize(hg.GetRow(minisub_matrix, 0)) * 0.075
    -- local minisub_velocity = (minisub_prev_pos - ctx.minisub_pos) * 0.5 + hg.Vec3(_tmp_vec.x, _tmp_vec.y, _tmp_vec.z)

    -- local spawn_minisub_bubbles
    -- if ctx.minisub_emitter_trigger:IsEnabled() then
    --     spawn_minisub_bubbles = 0.25
    -- else
    --     spawn_minisub_bubbles = 0
    -- end

    -- ctx.bubble_particles = bubbles_update_draw(ctx.scene, ctx.res, ctx.pipeline_info, ctx.blank_bubble, dt, ctx.bubble_particles, minisub_matrix, minisub_velocity, spawn_minisub_bubbles)

    -- physics colshapes to guide the boids
    for i = 1, #ctx.p_nodes do
        ctx.physics:NodeWake(ctx.p_nodes[i])
    end

    -- boids
    ctx.fish_boids = boids_update_draw(ctx.opaque_view_id, ctx.vtx_line_layout, dt, ctx.fish_boids, ctx.boids_min_max, ctx.scene, ctx.physics, ctx.scene:GetNode("sphere"))

    -- scene update (incl. the physics system)
    hg.SceneUpdateSystems(ctx.scene, scene_clocks, dt, ctx.physics, hg.time_from_sec_f(1 / 60), 4)

    return ctx
end

function SceneMarineMelodiesRender(ctx, view_id, rect, ar_flag, res, pipeline_info, frame)
    -- render
    view_id, passId = hg.SubmitSceneToPipeline(view_id, ctx.scene, rect, ar_flag, pipeline_info, res)
    return view_id, passId
end    
