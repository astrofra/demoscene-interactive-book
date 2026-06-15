hg = require("harfang")
require("utils")

-- Initialize HARFANG systems
hg.InputInit()
hg.AudioInit()
hg.WindowSystemInit()

-- Set window resolution
local res_x, res_y = 1280, 720
local win = hg.RenderInit("Image Grid", res_x, res_y, hg.RF_VSync | hg.RF_MSAA4X)

-- Create and configure the pipeline for rendering
local pipeline = hg.CreateForwardPipeline()
local res = hg.PipelineResources()
local render_data = hg.SceneForwardPipelineRenderData()

-- Define assets and output folders
local assets_dir = "assets"
local assets_compiled_dir = assets_dir .. "_compiled"
hg.AddAssetsFolder(assets_compiled_dir)

-- Load base model and shader for nodes
local tile_geo_name = "common/slides/slide_1x1m/slide_1x1m_42.geo"
local node_model = hg.LoadModelFromAssets(tile_geo_name)
local node_model_ref = res:AddModel(tile_geo_name, node_model)
local node_shader = hg.LoadPipelineProgramRefFromAssets("core/shader/pbr.hps", res, hg.GetForwardPipelineInfo())

-- Create an empty scene
local scene = hg.Scene()

-- Tile grid parameters
local tiles_x, tiles_y = 28, 8
local tile_size = 1.0 -- in meters

local state = "running"
local update_count = 0

-- Run main loop
keyboard = hg.Keyboard()
while not keyboard:Pressed(hg.K_Escape) and hg.IsWindowOpen(win) and state ~= "exit" do
    local dt = hg.TickClock()
    keyboard:Update()

    if state == "running" then
        state = "create_tiles"
    elseif state == "create_tiles" then
        -- Iterate over each tile position to create nodes and assign textures
        for y = 0, tiles_y - 1 do
            for x = 0, tiles_x - 1 do
                -- Compute tile filename and load texture
                local tile_filename = string.format("projects/latent_space_cadet/miro/midjourney-process_%d_%d.png", x, y)
                local texture = hg.LoadTextureFromAssets(tile_filename, hg.TF_UClamp | hg.TF_VClamp, res)

                -- Create material for the node with the texture
                local mat = hg.CreateMaterial(node_shader, "uBaseOpacityColor", hg.Vec4(0.5, 0.5, 0.5, 0))
                local gamma = 2.2
                local direct_color_transfert = 1.0
                local slide_opacity = 1.0
                hg.SetMaterialValue(mat, "uCustom", hg.Vec4(gamma, direct_color_transfert, slide_opacity, 0.0))
                hg.SetMaterialTexture(mat, "uBaseOpacityMap", texture, 0)

                -- Create the node, set position and scale
                local node_name = string.format("node_%d_%d", x, y)
                local tile_pos = hg.Vec3((x - (tiles_x / 2)) * tile_size, -(y - (tiles_y / 2)) * tile_size, 0)
                local node = hg.CreateObject(scene, hg.TranslationMat4(tile_pos), node_model_ref, {mat})
                node:SetName(node_name)
                -- node:GetTransform():SetScale(hg.Vec3(tile_size * base_scale, tile_size * base_scale, 1))
            end
        end
        state = "count_updates"
    elseif state == "count_updates" then
        --
        update_count = update_count + 1
        if update_count > 60 then
            state = "save_scene"
        end
    elseif state == "save_scene" then
        --
        local _miro_scene_name = getcwd() .. "/" .. assets_dir .. "/projects/latent_space_cadet/miro/miro.scn"
        hg.SaveSceneJsonToFile(_miro_scene_name, scene, res)
        state = "exit_next"
    elseif state == "exit_next" then
        state = "exit"
    end

    -- Update and render scene
    scene:Update(dt)
    hg.SubmitSceneToPipeline(0, scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res)

    hg.Frame()
    hg.UpdateWindow(win)
end

-- Cleanup
hg.RenderShutdown()
hg.DestroyWindow(win)

print("All nodes created and displayed.")
