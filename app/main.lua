hg = require("harfang")
require("utils")
require("linear_filter")
require("slides_specs")
require("video_player")

require("transition")
-- require("projects/marine_melodies/main")
require("projects/cavern/main")
require("presentation")
require("video_data")

math.randomseed(os.time())

-- This script serves as the main navigator for the 3D portfolio.

local function GetSlidePosFromIndex(_slide_idx, _slide_width)
	return hg.Vec3((_slide_width) * (_slide_idx - 1.0),0,0)
end

-- function SlideIndexSign(number)
-- 	if number >= 0 then
-- 	   return 1
-- 	elseif number < 0 then
-- 	   return -1
-- 	end
--  end

function UpdateConnectedGamePad(game_pad_list)
	local idx
	for idx = 1, game_pad_list:size() do
		local gp_name = game_pad_list:at(idx - 1)
		local gp_state = hg.ReadGamepad(gp_name)
		if gp_state and gp_state:IsConnected() then
			return gp_state
		end
	end
	return nil
end

function RefreshLoadingWindow(window, display_res_x, display_res_y, progress_value, bg_color)
	bg_color = bg_color or hg.Color.White
	hg.SetViewClear(0, hg.CF_Color | hg.CF_Depth, bg_color * hg.Color(progress_value, progress_value, progress_value, 1.0), 1, 0)
	hg.SetViewRect(0, 0, 0, display_res_x, display_res_y)

	hg.Touch(0)  -- force the view to be processed as it would be ignored since nothing is drawn to it (a clear does not count)

	hg.Frame()
	hg.UpdateWindow(window)
end

function main()
	-- Initialize input, audio, and window systems
	hg.InputInit()
	hg.AudioInit()
	hg.WindowSystemInit()
	-- hg.HideCursor()

	local res_x, res_y = 1920, 1080 -- default working monitor size
	local monitor_rect = hg.IntRect(0, 0, res_x, res_y)

	-- get the actual monitor size from the window system
	local mon_list = hg.GetMonitors()
	if mon_list:size() >= 1 then
		local _idx
		for _idx = 0, mon_list:size() - 1 do
			local _mon_rect = hg.GetMonitorRect(mon_list:at(_idx))
			res_x = _mon_rect.ex - _mon_rect.sx
			res_y = _mon_rect.ey - _mon_rect.sy
			print("Found monitor size: " .. res_x .. " x " .. res_y)
			break
		end
	end

	-- Set window resolution
	local nominal_res_x, nominal_res_y = 1920, 1080

	local nominal_aspect = nominal_res_x / nominal_res_y
	local actual_aspect = res_x / res_y
	local fov_aspect_ratio_factor = math.max(nominal_aspect / actual_aspect, 1.0)

	local mode_list = {hg.WV_Windowed, hg.WV_Fullscreen, hg.WV_Undecorated, hg.WV_FullscreenMonitor1, hg.WV_FullscreenMonitor2, hg.WV_FullscreenMonitor3}

	-- main screen
	local _mode = mode_list[3]
	if IsMacOS() then
		_mode = mode_list[1]
	end
	local win = hg.NewWindow("Slidorama", res_x, res_y, 32, _mode) --, hg.WV_Fullscreen)
	hg.RenderInit(win) --, hg.RT_OpenGL)
	hg.RenderReset(res_x, res_y, hg.RF_MSAA4X | hg.RF_MaxAnisotropy | hg.RF_VSync)

	hg.HideCursor()

	-- Create and configure the pipeline for rendering
	local pipeline = hg.CreateForwardPipeline(4096, false)
	local res = hg.PipelineResources()
	local render_data = hg.SceneForwardPipelineRenderData()

	hg.AddAssetsFolder("assets_compiled")

	-- background scene
	local bg_scene = hg.Scene()
	hg.LoadSceneFromAssets("common/bg-1bit.scn", bg_scene, res, hg.GetForwardPipelineInfo())

	-- Create an empty main_scene
	local main_scene = hg.Scene()
	main_scene.canvas.clear_color = false
	main_scene.canvas.color = bg_color -- hg.Color.Red --

	-- Main render loop
	local frame = 0

	-- Slides
	local scene_idx
	local slides_instance_table = {}
	local slides_nodes_table = {}
	local cavern_slide = {}
	for scene_idx = 1, max_slides do
		local _pos = hg.Vec3(0,0,0) -- GetSlidePosFromIndex(scene_idx, slide_width)
		local _slide_mat = hg.TransformationMat4(_pos, hg.Vec3(0,0,0))
		local _slide_name = string.format("slide_%02d", scene_idx)
		local _slide_filename = "slides/" .. _slide_name .. ".scn"
		local _new_node, _ret = hg.CreateInstanceFromAssets(main_scene, _slide_mat, _slide_filename, res, hg.GetForwardPipelineInfo())
		_new_node:SetName(_slide_name)
		table.insert(slides_instance_table, _new_node)

		-- now we loaded the slide as an instance, we need to parse each of its nodes
		-- and look for the ones that needs to be customized
		-- first, let's grab the list from the "presentation" table
		local _current_slide_pres = presentation[scene_idx]
		local _node_idx
		for _node_idx = 1, #_current_slide_pres do
			local _sub_slide_name = _current_slide_pres[_node_idx].ref
			local _zoetrope = _current_slide_pres[_node_idx].zoetrope
			local _background_func = _current_slide_pres[_node_idx].background_func
			if string.sub(_sub_slide_name, 1, 5) == "photo" and _zoetrope then
				-- get the ref to this node within the instance view
				local photo_node = _new_node:GetInstanceSceneView():GetNode(main_scene, _sub_slide_name)
				-- load the zoetrope shader, texture, uniforms
				local _zoetrope_prog = hg.LoadPipelineProgramRefFromAssets("core/shader/slide_zoetrope.hps", res, hg.GetForwardPipelineInfo())
				local _zoetrope_tex = hg.LoadTextureFromAssets(_zoetrope.bitmap, hg.TF_UClamp | hg.TF_VClamp, res)
				local _mat_photo = photo_node:GetObject():GetMaterial(0)
				hg.SetMaterialProgram(_mat_photo, _zoetrope_prog)
				hg.SetMaterialTexture(_mat_photo, "uSelfMap", _zoetrope_tex, 4)
				hg.SetMaterialValue(_mat_photo, "uCustom", _zoetrope.uniforms.uCustom)
				hg.SetMaterialValue(_mat_photo, "uFramerate", _zoetrope.uniforms.uFramerate)
				hg.UpdateMaterialPipelineProgramVariant(_mat_photo, res)
				print(photo_node:GetName())
			elseif string.sub(_sub_slide_name, 1, 5) == "photo" and _background_func == "SceneCavern" then
				local photo_node = _new_node:GetInstanceSceneView():GetNode(main_scene, _sub_slide_name)
				local _mat_photo = photo_node:GetObject():GetMaterial(0)
				cavern_slide.node = photo_node
				cavern_slide.material = _mat_photo
			end
		end

		local _slide_nodes_filename = string.format("assets_compiled/slides/slide_nodes_%02d", scene_idx)
		local _nodes_list = require(_slide_nodes_filename)
		table.insert(slides_nodes_table, _nodes_list)

		-- hide node
		_new_node:Disable()

		-- progress tracking
		local progress_value = scene_idx / max_slides
		RefreshLoadingWindow(win, res_x, res_y, progress_value * 0.8, bg_color)
	end

	-- main camera
	local _fov = hg.DegreeToRadian(15.0) -- narrow view angle to limit the distortions

	local _distance_to_slide = CalculateCameraDistance(_fov, slide_height * fov_aspect_ratio_factor)
	local cam_base_pos = hg.Vec3(0,0,-_distance_to_slide)
	local cam_base_rot = hg.Vec3(0,0,0)
	local main_camera = hg.CreateCamera(main_scene,hg.TransformationMat4(cam_base_pos, cam_base_rot), _distance_to_slide / 2.0, _distance_to_slide * 2.0, _fov)
	main_scene:SetCurrentCamera(main_camera)
	
	-- setup projects + their advanced rendering pipeline (if needed)
	local pipeline_aaa = {}
	local pipeline_aaa_config = {}
	local ctx = {}

	-- -- Marine Melodies
	-- ctx.marine_melodies = SceneMarineMelodiesSetup(res, hg.GetForwardPipelineInfo(), bg_color)
	-- RefreshLoadingWindow(win, res_x, res_y, 0.9, bg_color)

	-- Cavern shader
	ctx.cavern = SceneCavernSetup(res, hg.GetForwardPipelineInfo(), bg_color)
	ctx.cavern.slide = cavern_slide

	-- home cinema video player
	local video_scene = hg.Scene()
	hg.LoadSceneFromAssets("common/scene-video/scene-video-16x9.scn", video_scene, res, hg.GetForwardPipelineInfo())
	local video_screen_instance_node = video_scene:GetNode("video_screen_instance")
	local video_screen_node =  video_screen_instance_node:GetInstanceSceneView():GetNode(video_scene, "video_screen")
	local video_screen_camera = video_scene:GetNode("Camera")
	local video_screen_fov = video_screen_camera:GetCamera():GetFov()
	video_screen_camera:GetCamera():SetFov(video_screen_fov * fov_aspect_ratio_factor)
	RefreshLoadingWindow(win, res_x, res_y, 0.95, bg_color)

	-- screen texture
	local video_screen_material = video_screen_node:GetObject():GetMaterial(0)
	local material_texture = hg.GetMaterialTexture(video_screen_material, "uSelfMap")
	local res_texture = res:GetTexture(material_texture)

	-- title texture & player UI
	local progress_bar_node = video_scene:GetNode("progress-bar-loaded")
	local scene_video_title_material = video_scene:GetNode("video-title"):GetObject():GetMaterial(0)
	local scene_video_size_material = video_scene:GetNode("video-size"):GetObject():GetMaterial(0)
	local scene_video_framerate_material = video_scene:GetNode("video-framerate"):GetObject():GetMaterial(0)

	-- player control
	local scene_video_player = CreateSceneVideoPlayer(res_texture, progress_bar_node, scene_video_title_material, scene_video_size_material, scene_video_framerate_material)

	-- Initialize keyboard input
	local keyboard = hg.Keyboard(GetPreferredKeyboardDeviceName())
	local mouse = hg.Mouse()
	local game_pad_list = hg.GetGamepadNames()
	local gamepad, prev_gamepad

	-- navigation / transition
	local current_slide = 1
	local current_step = 1
	local step_details
	local transition_duration = 0.025
	local node_transition_duration = 0.25
	local prev_slide = -1
	local prev_step = -1
	local nav = {
		none = 0,
		prev_slide = 1,
		next_slide = 2,
		prev_step = 3,
		next_step = 4
	}

	local transition_nodes_list = CreateTransitionManager()

	-- hack to stabilize the dt frame :'(
	-- local fixed_clock = hg.time_from_sec_f(0)
	local df_filter = LinearFilter:new(120)

	-- main loop
	-- Run until the user closes the window or presses the Escape key
	while hg.IsWindowOpen(win) do
		df_filter:SetNewValue(hg.time_to_us_f(hg.TickClock()))
		local dt = hg.time_from_us_f(df_filter:GetMedianValue()) -- hg.time_from_sec_f(1.0/60.0) -- hg.TickClock()
		local dts = hg.time_to_sec_f(dt)
		local current_clock = hg.GetClock() -- fixed_clock -- hg.GetClock()
		-- fixed_clock = fixed_clock + dt

		-- Input update
		keyboard:Update()
		mouse:Update()
		if keyboard:Down(hg.K_Escape) then
			break
		end
		prev_gamepad = gamepad
		gamepad = UpdateConnectedGamePad(game_pad_list)

		-- Slide navigation
		-- Handle keyboard inputs for navigating the slides
		local navigation = nav.none

		-- keyboard slide navigation
		if keyboard:Released(hg.K_Left) then
			navigation = nav.prev_slide
		elseif keyboard:Released(hg.K_Right) then 
			navigation = nav.next_slide
		elseif keyboard:Released(hg.K_Up) then
			navigation = nav.prev_step
		elseif keyboard:Released(hg.K_Down) then 
			navigation = nav.next_step
		end

		-- gamepad slide navigation
		if prev_gamepad and gamepad then
			if prev_gamepad:Button(hg.GB_ButtonX) == false and gamepad:Button(hg.GB_ButtonX) == true then
				navigation = nav.prev_slide
			elseif prev_gamepad:Button(hg.GB_ButtonB) == false and gamepad:Button(hg.GB_ButtonB) == true then
				navigation = nav.next_slide
			elseif prev_gamepad:Button(hg.GB_ButtonY) == false and gamepad:Button(hg.GB_ButtonY) == true then
				navigation = nav.prev_step
			elseif prev_gamepad:Button(hg.GB_ButtonA) == false and gamepad:Button(hg.GB_ButtonA) == true then
				navigation = nav.next_step
			end
		end

		-- Update slide and step idx
		if navigation == nav.prev_slide then
			current_slide = math.max(current_slide - 1, 1)
			current_step = 1
			if prev_slide ~= current_slide then
				prev_step = -1
			end
		elseif navigation == nav.next_slide then
			prev_slide = current_slide
			current_slide = math.min(current_slide + 1, #presentation)
			current_step = 1
			if prev_slide ~= current_slide then
				prev_step = -1
			end
		elseif navigation == nav.prev_step then
			current_step = math.max(current_step - 1, 1)
		elseif navigation == nav.next_step then
			current_step = math.min(current_step + 1, #presentation[current_slide])
		end

		-- Init / enable slide base when change slide, disable previous slide
		if prev_slide ~= current_slide then
			print("> current_slide = " .. current_slide)
			local slide_idx
			for slide_idx = 1, max_slides do
				local _slide_name = string.format("slide_%02d", slide_idx)
				local _slide_node = main_scene:GetNode(_slide_name)
				if slide_idx == current_slide then
					-- enable slide node
					_slide_node:Enable()
					-- and subsequent steps
					local _step_idx
					for _step_idx = 1, #presentation[slide_idx] do
						local step = presentation[slide_idx][_step_idx]
						if step.type == action_type.node then
							local _step_node = _slide_node:GetInstanceSceneView():GetNode(main_scene, step.ref)
							if _step_idx == 1 then
								_step_node:Enable()
							else
								_step_node:Disable()
							end
						end
					end
					-- nodes transition (fade in)
					local node_idx
					for node_idx = 1, #slides_nodes_table[current_slide] do
						transition_nodes_list = FadeinNode(main_scene, _slide_name, slides_nodes_table[current_slide][node_idx], transition_nodes_list, current_clock, node_transition_duration, (#slides_nodes_table[current_slide] - node_idx) * transition_duration / 2.0)
					end
				else
					_slide_node:Disable()
				end
			end
			-- Stop pentential video sound from previous slide
			scene_video_player.Close()
			print("STOP SOUND")
		end

		step_details = presentation[current_slide][current_step]

		-- Disable previous step, init new step
		if prev_step ~= current_step then
			-- Get prev step details if exist
			local prev_step_details = nil
			if prev_step > -1 then
				prev_step_details = presentation[current_slide][prev_step]
			end

			if #presentation[current_slide] > 0 then
				print("  current_step = " .. current_step)
				local _slide_name = string.format("slide_%02d", current_slide)
				local _slide_node = main_scene:GetNode(_slide_name)

				-- Fade out / disable the prev step if exist
				if prev_step_details then
					local _step_node = _slide_node:GetInstanceSceneView():GetNode(main_scene, prev_step_details.ref)
					-- fade out (hide) the previous step (node)
					if prev_step_details.type == action_type.node then
						transition_nodes_list = FadeoutNode(main_scene, _slide_name, _step_node:GetName(), transition_nodes_list, current_clock, 0.2)
					elseif prev_step_details.type == action_type.func then
						print("fade out function!!!!")
					elseif prev_step_details.type == action_type.svid then
						scene_video_player.Close()
						print("STOP SOUND")
					end
				end

				-- Init new step
				if step_details.type == action_type.node then -- it's a regular node (plane + texture)
					local _step_node = _slide_node:GetInstanceSceneView():GetNode(main_scene, step_details.ref)
					_step_node:Enable()
					transition_nodes_list = FadeinNode(main_scene, _slide_name, _step_node:GetName(), transition_nodes_list, current_clock, 0.2)
				elseif step_details.type == action_type.func then -- it's a Lua function (send the fade value to it)
					print("fade in function!!!!")
					if _G[step_details.ref .. "Init"] then
						ctx[step_details.context] = _G[step_details.ref .. "Init"](ctx[step_details.context], keyboard, gamepad, prev_gamepad, dt, current_clock)
					end
					transition_nodes_list = FadeinFunction(ctx[step_details.context], transition_nodes_list, current_clock, 1.0)
				elseif step_details.type == action_type.svid then -- it's the generic video player
					print("home cinema, play : " .. step_details.ref)
					local _metadata = video_metadata[step_details.ref:match("([^/]+)$")]
					local video_audio = ""
					if step_details.video_audio_path then
						video_audio = step_details.video_audio_path
					end
					scene_video_player.Play(step_details.ref, video_audio, current_clock, _metadata.duration, _metadata.height, math.ceil(_metadata.fps), res)
				end
			else
				print("  no step!")
			end
		end

		--	slide nodes transition
		transition_nodes_list = UpdateTransitions(main_scene, transition_nodes_list, dt, current_clock)

        -- projects update
		--
		local slide_content = presentation[current_slide]

		if current_slide == prev_slide then
			if not IsTableEmpty(slide_content) then
			 	if step_details.type == action_type.node and step_details.background_func then
					ctx[step_details.context] = _G[step_details.background_func .. "Update"](ctx[step_details.context], keyboard, mouse, gamepad, prev_gamepad, dt, current_clock)
			 	elseif step_details.type == action_type.func then
					ctx[step_details.context] = _G[step_details.ref .. "Update"](ctx[step_details.context], keyboard, gamepad, prev_gamepad, dt, current_clock)
				elseif step_details.type == action_type.svid then
						--
						video_scene:Update(dt)
						scene_video_player.Update(current_clock)
				end
			end
		end

		-- main slide camera
		if step_details and step_details.hide_slide then
			local target_cam_pos = cam_base_pos + hg.Vec3(0, 0, _distance_to_slide + 1.0)
			local new_cam_pos = main_camera:GetTransform():GetPos()
			new_cam_pos = dtAwareDamp(new_cam_pos, target_cam_pos, 0.05, dts)
			main_camera:GetTransform():SetPos(new_cam_pos)
		else
			local target_cam_pos = cam_base_pos
			local new_cam_pos = main_camera:GetTransform():GetPos()
			new_cam_pos = dtAwareDamp(new_cam_pos, target_cam_pos, 0.05, dts * 10.0)
			main_camera:GetTransform():SetPos(new_cam_pos)
		end

		-- Update main_scene
		main_scene:Update(dt)
		bg_scene:Update(dt)

		-- and submit for rendering
		local views = hg.SceneForwardPipelinePassViewId()
		local view_id = 0
		local passId

		-- bg clear
		hg.SetViewClear(view_id, hg.CF_Color | hg.CF_Depth, bg_color, 0.0, 0)
		hg.SetViewRect(view_id, 0, 0, res_x, res_y)
		-- hg.Touch(view_id)
		view_id = view_id + 1

		-- bg scene render
		view_id, passId = hg.SubmitSceneToPipeline(view_id, bg_scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res)
		view_id = view_id + 1

		-- projects render
		--
		if current_slide == prev_slide then
			if not IsTableEmpty(slide_content) then
				if step_details.type == action_type.node and step_details.background_func then
					view_id, passId = _G[step_details.background_func .. "Render"](ctx[step_details.context], view_id, hg.IntRect(0, 0, res_x, res_y), step_details.ar_flag, res, pipeline, frame)
					view_id = view_id + 1
				elseif step_details.type == action_type.func then
					view_id, passId = _G[step_details.ref .. "Render"](ctx[step_details.context], view_id, hg.IntRect(0, 0, res_x, res_y), step_details.ar_flag, res, pipeline, frame, step_details.key)
					view_id = view_id + 1
				elseif step_details.type == action_type.svid then
					view_id, passId = hg.SubmitSceneToPipeline(view_id, video_scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res)
					-- view_id, passId = hg.SubmitSceneToPipeline(view_id, video_scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res, pipeline_aaa.video_scene, pipeline_aaa_config.video_scene, frame)
					view_id = view_id + 1
				end
			end
		end

		view_id, passId = hg.SubmitSceneToPipeline(view_id, main_scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res)

		frame = hg.Frame()
		hg.UpdateWindow(win)

		prev_slide = current_slide
		prev_step = current_step
	end

	-- Cleanup and shutdown operations
	hg.RenderShutdown()
	hg.DestroyWindow(win)
	hg.ShowCursor()
end

main()
