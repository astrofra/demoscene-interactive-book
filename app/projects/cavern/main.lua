-- VPS Viewer

hg = require("harfang")
require("utils")

function SceneCavernSetup(res, pipeline_info, pipeline_aaa, pipeline_aaa_config, bg_color)
    -- -- Load scene
    -- local product_list = {}
    -- local current_product = 2

    -- local idx
    -- for idx = 1, #ean_list do
    --     local _scene = hg.Scene()
    --     hg.LoadSceneFromAssets("projects/vps/" .. ean_list[idx] .. "/main.scn", _scene, res, pipeline_info)
    --     local _gamma = 1.8
    --     local aaa_bg_color = hg.Color(bg_color.r^_gamma, bg_color.g^_gamma, bg_color.b^_gamma, bg_color.a)
    --     _scene.canvas.color = aaa_bg_color
    --     _scene.environment.fog_color = aaa_bg_color
        
    --     local _camera = _scene:GetNode("Camera")
    --     local _root = _scene:GetNode("root")

    --     local _pos = _camera:GetTransform():GetPos()
    --     _pos.x = _pos.x - 0.625
    --     _pos.z = _pos.z - 2.75
    --     _camera:GetTransform():SetPos(_pos)

    --     local _bb = _scene:GetNode("bounding_volume")
    --     if _bb:IsValid() then
    --         _bb:Disable()
    --     end 

    --     table.insert(product_list, {scene = _scene, camera = _camera, root = _root})
    -- end

    -- pipeline_aaa_config.exposure = 1.2
    -- pipeline_aaa_config.gamma = 1.8

    local ctx = {
    --     scene = product_list[1].scene,
    --     pipeline_aaa = pipeline_aaa,
    --     pipeline_aaa_config = pipeline_aaa_config,
    --     product_list = product_list,
    --     current_product = current_product,
        cam_rot = hg.Vec3(0,0,0)
    }

    return ctx
end

function SceneCavernUpdate(ctx, keyboard, mouse, gamepad, prev_gamepad, dt, current_clock)

    local dts = hg.time_to_sec_f(dt)

    -- local product_nav = 0

    -- product rotation
    local _rot_keyboard = hg.Vec3(0,0,0)
    if keyboard:Down(hg.K_Z) then
        _rot_keyboard.x = math.pi * 0.15
	elseif keyboard:Down(hg.K_S) then
        _rot_keyboard.x = math.pi * -0.15
    end
    if keyboard:Down(hg.K_Q) then
        _rot_keyboard.y = math.pi * 0.25
	elseif keyboard:Down(hg.K_D) then
        _rot_keyboard.y = math.pi * -0.25
    end

    local _rot = hg.Vec3(0,0,0)
    if gamepad and prev_gamepad then
        _rot.x = gamepad:Axes(hg.GA_RightY) * math.pi * -0.25
        _rot.y = gamepad:Axes(hg.GA_RightX) * math.pi * -0.25

        local trigger_right = gamepad:Axes(hg.GA_RightTrigger)
        if trigger_right > -1.0 then
            _rot.x = _rot.x * map(trigger_right, -1.0, 1.0, 1.0, 2.0)
            _rot.y = _rot.y * map(trigger_right, -1.0, 1.0, 1.0, 4.0)
        end
    end

    ctx.cam_rot = hg.Lerp(ctx.cam_rot, _rot + _rot_keyboard, dts * 5.0)
    hg.SetMaterialValue(ctx.slide.material, "uCamDir", hg.Vec4(ctx.cam_rot.x, 0.0, ctx.cam_rot.y, 0.0))
    -- hg.SetMaterialValue(ctx.slide.material, "uCamDir", hg.Vec4(hg.time_to_sec_f(hg.GetClock()), 0.0, -hg.time_to_sec_f(hg.GetClock()), 0.0))



    -- ctx.product_list[ctx.current_product].root:GetTransform():SetRot(ctx.cam_rot + hg.Vec3(0, math.pi * 0.1, 0))

    -- ctx.product_list[ctx.current_product].scene:Update(dt)

    return ctx
end

function SceneCavernRender(ctx, view_id, rect, ar_flag, res, pipeline_info, frame)
    -- -- render vps
    -- local vps_scene = ctx.product_list[ctx.current_product].scene
    local passId
    -- view_id, passId = hg.SubmitSceneToPipeline(view_id, vps_scene, rect, ar_flag, pipeline_info, res, ctx.pipeline_aaa, ctx.pipeline_aaa_config, frame)
    return view_id, passId
end    
