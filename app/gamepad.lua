-- Reading advanced gamepad state

hg = require("harfang")

hg.InputInit()

hg.WindowSystemInit()
win = hg.NewWindow('Harfang - Read Gamepad', 320, 200)

gamepad = hg.Gamepad()

while not hg.ReadKeyboard():Key(hg.K_Escape) do
	gamepad:Update()

	if gamepad:Connected() then
		print('Gamepad slot 0 was just connected')
	end
	if gamepad:Disconnected() then
		print('Gamepad slot 0 was just disconnected')
	end

	-- buttons
	if gamepad:Pressed(hg.GB_ButtonA) then
		print('Gamepad button A pressed')
	end
	if gamepad:Pressed(hg.GB_ButtonB) then
		print('Gamepad button B pressed')
	end
	if gamepad:Pressed(hg.GB_ButtonX) then
		print('Gamepad button X pressed')
	end
	if gamepad:Pressed(hg.GB_ButtonY) then
		print('Gamepad button Y pressed')
	end
	if gamepad:Pressed(hg.GB_LeftBumper) then
		print('Gamepad Left Bumper pressed')
	end
	if gamepad:Pressed(hg.GB_RightBumper) then
		print('Gamepad Right Bumper pressed')
	end
	if gamepad:Pressed(hg.GB_Back) then
		print('Gamepad Back button pressed')
	end
	if gamepad:Pressed(hg.GB_Start) then
		print('Gamepad Start button pressed')
	end
	if gamepad:Pressed(hg.GB_Guide) then
		print('Gamepad Guide button pressed')
	end
	if gamepad:Pressed(hg.GB_LeftThumb) then
		print('Gamepad Left Thumbstick pressed')
	end
	if gamepad:Pressed(hg.GB_RightThumb) then
		print('Gamepad Right Thumbstick pressed')
	end
	if gamepad:Pressed(hg.GB_DPadUp) then
		print('Gamepad D-Pad Up pressed')
	end
	if gamepad:Pressed(hg.GB_DPadRight) then
		print('Gamepad D-Pad Right pressed')
	end
	if gamepad:Pressed(hg.GB_DPadDown) then
		print('Gamepad D-Pad Down pressed')
	end
	if gamepad:Pressed(hg.GB_DPadLeft) then
		print('Gamepad D-Pad Left pressed')
	end	

	-- analog
	axis_left_x = gamepad:Axes(hg.GA_LeftX)
	if math.abs(axis_left_x) > 0.1 then
		print(string.format('Gamepad axis left X: %f' , axis_left_x))
	end
	axis_left_y = gamepad:Axes(hg.GA_LeftY)
	if math.abs(axis_left_y) > 0.1 then
		print(string.format('Gamepad axis left Y: %f' , axis_left_y))
	end
	axis_right_x = gamepad:Axes(hg.GA_RightX)
	if math.abs(axis_right_x) > 0.1 then
		print(string.format('Gamepad axis right X: %f' , axis_right_x))
	end
	axis_right_y = gamepad:Axes(hg.GA_RightY)
	if math.abs(axis_right_y) > 0.1 then
		print(string.format('Gamepad axis right Y: %f' , axis_right_y))
	end
	trigger_left = gamepad:Axes(hg.GA_LeftTrigger)
	if math.abs(trigger_left) < 1.0 then
		print(string.format('Gamepad left trigger: %f' , trigger_left))
	end
	trigger_right = gamepad:Axes(hg.GA_RightTrigger)
	if math.abs(trigger_right) < 1.0 then
		print(string.format('Gamepad right trigger: %f' , trigger_right))
	end

	hg.UpdateWindow(win)
end
hg.DestroyWindow(win)