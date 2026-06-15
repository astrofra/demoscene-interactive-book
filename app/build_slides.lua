hg = require("harfang")
require("utils")
require("slides_specs")
math.randomseed(os.time())

function is_slide_transparent(name)
	local opaque_slide_names = {
		["bg"] = true,
		["page_square"] = true
	}
	if opaque_slide_names[name] then
		return false
	else
		return true
	end
end

-- Initializes and runs the main loop of the 3D portfolio viewer.
function main()
	-- Initialize input, audio, and window systems
	hg.InputInit()
	hg.AudioInit()
	hg.WindowSystemInit()

	-- Set window resolution
	local res_x, res_y = 1280, 720
	local win = hg.RenderInit('Slides builder', res_x, res_y, hg.RF_VSync | hg.RF_MSAA4X)

	-- Create and configure the pipeline for rendering
	local pipeline = hg.CreateForwardPipeline()
	res = hg.PipelineResources()
	local render_data = hg.SceneForwardPipelineRenderData()

	local assets_dir = "assets"
	local assets_compiled_dir = assets_dir .. "_compiled"
	hg.AddAssetsFolder(assets_compiled_dir)

	-- Create an empty scene
	local scene = hg.Scene()

	local slide_node_list = {}
	local node_list

	local state = "next_scene"
	local scene_idx = 0
	local slide_data
	local size_factor = slide_width / slide_res_x

	local page_square_pos, page_number_pos

	local slide_geo_name = "common/slides/slide_1x1m/slide_1x1m_42.geo"
	local slide_mdl = hg.LoadModelFromAssets(slide_geo_name)
	local slide_ref = res:AddModel(slide_geo_name, slide_mdl)
	local slide_shader = hg.LoadPipelineProgramRefFromAssets('core/shader/pbr.hps', res, hg.GetForwardPipelineInfo())

	-- Initialize keyboard input
	keyboard = hg.Keyboard(GetPreferredKeyboardDeviceName())

	-- Run until the user closes the window or presses the Escape key
	while hg.IsWindowOpen(win) and state ~= "exit" do
		local dt = hg.TickClock()
		keyboard:Update()
		if keyboard:Down(hg.K_Escape) then
			break
		end

		print("state = " .. state)

		if state == "next_scene" then
			-- let's process the next slide
			scene_idx = scene_idx + 1
			if scene_idx > max_slides then
				state = "exit"
			else
				state = "read_json"
			end
		elseif state == "read_json" then
			-- read the json slide description (actually, a lua version of it)
			local _slide_desc = string.format("slides/slide_%02d.lua", scene_idx)
			node_list = {}
			_slide_desc = getcwd() .. "/" .. assets_dir .. "/" .. _slide_desc
			slide_data = dofile(_slide_desc)
			state = "create_nodes"
		elseif state == "create_nodes" then
			-- for each entry in the json (a layer from the PSD), create a node that will carry a polygon most of the time)
			local _parent_node = scene:CreateNode("root")
			local _transform = scene:CreateTransform()
			_parent_node:SetTransform(_transform)
			_parent_node:GetTransform():SetScale(hg.Vec3(size_factor, size_factor, 1.0))

			local z = 0.0
			local _idx
			for _idx = 1, #slide_data do
				local _slide_kind = slide_data[_idx].kind
				if _slide_kind == "group" then
					-- do nothing, it's a photoshop folder (or group)
				else
					local human_name = slide_data[_idx].human_name
					if human_name ~= "bg" then
						table.insert(node_list, human_name)
					end
					if human_name ~= "type" and human_name ~= "bg" then
						z = z - 0.01
					end
					local _mat_slide = hg.CreateMaterial(slide_shader, 'uBaseOpacityColor', hg.Vec4(1, 0, 1), 'uOcclusionRoughnessMetalnessColor', hg.Vec4(1, 0.5, 0.01))
					local _texture_slide = hg.LoadTextureFromAssets(slide_data[_idx].bitmap, hg.TF_UClamp | hg.TF_VClamp, res)
					local gamma = 2.2
					local direct_color_transfert = 1.0
					local slide_opacity = 1.0
					hg.SetMaterialValue(_mat_slide, "uCustom", hg.Vec4(gamma, direct_color_transfert, slide_opacity, 0.0))
					hg.SetMaterialTexture(_mat_slide, "uBaseOpacityMap", _texture_slide, 0)
					-- hg.SetMaterialTexture(_mat_slide, "uSelfMap", _texture_slide, 4)
					if is_slide_transparent(human_name) then
						hg.SetMaterialBlendMode(_mat_slide, hg.BM_Alpha)
						hg.SetMaterialWriteZ(_mat_slide, false)
					end
					local _new_node = hg.CreateObject(scene, hg.TranslationMat4(hg.Vec3(0, 1, 0)), slide_ref, {_mat_slide})
					_new_node:SetName(human_name)
					local _bbox = slide_data[_idx].bbox
					local w, h = _bbox[3] - _bbox[1], _bbox[4] - _bbox[2]
					-- if human_name == "separator" then w = w * 2.0 end
					local x, y = (_bbox[3] + _bbox[1]) / 2.0, slide_res_y - ((_bbox[4] + _bbox[2]) / 2.0)
					x = x - slide_res_x / 2.0
					y = y - slide_res_y / 2.0
					local _new_node_pos = hg.Vec3(x, y, z)

					-- fix the position of the page number
					if human_name == "page_square" then
						if page_square_pos == nil then -- first time, we fetch the position from slide 1
							page_square_pos = _new_node_pos
						else
							_new_node_pos = page_square_pos
						end
					elseif human_name == string.format("page_%02d", scene_idx) then
						if page_number_pos == nil then -- first time, we fetch the position from slide 1
							page_number_pos = _new_node_pos
						else
							_new_node_pos = page_number_pos
						end
					end

					_new_node:GetTransform():SetPos(_new_node_pos)
					_new_node:GetTransform():SetScale(hg.Vec3(w, h, 1.0))
					_new_node:GetTransform():SetParent(_parent_node)

					-- hide the background slide
					if human_name == "bg" then _new_node:Disable() end
				end
			end

			state = "update_scene"
		elseif state == "update_scene" then
			-- everything was created, let's update/commit/whatever the engine needs
			-- we actually do nothing, the update will occur at the end of this iteration
			state = "save_scene"
		elseif state == "save_scene" then
			-- save the .scn file along the .json and .lua slide description
			local _slide_scene_name = string.format("slides/slide_%02d.scn", scene_idx)
			_slide_scene_name = getcwd() .. "/" .. assets_dir .. "/" .. _slide_scene_name
			hg.SaveSceneJsonToFile(_slide_scene_name, scene, res)
			print("SaveSceneJsonToFile()" .. _slide_scene_name)

			-- save a simplified lua description
			local _slide_nodes_name = string.format("slides/slide_nodes_%02d.lua", scene_idx)
			_slide_nodes_name = getcwd() .. "/" .. assets_dir .. "/" .. _slide_nodes_name
			write_table_to_lua_file(node_list, _slide_nodes_name)
			state = "clear_scene"
		elseif state == "clear_scene" then
			-- empty the scene
			scene:Clear()
			state = "gc"
		elseif state == "gc" then
			-- ... (and run the GC)
			scene:GarbageCollect()
			state = "next_scene"
		end

		scene:Update(dt)
		hg.SubmitSceneToPipeline(0, scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res)

		frame = hg.Frame()
		hg.UpdateWindow(win)
	end

	-- Cleanup and shutdown operations
	hg.RenderShutdown()
	hg.DestroyWindow(win)
end

main()

print("all done!")
