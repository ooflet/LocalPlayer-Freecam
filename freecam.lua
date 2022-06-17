------------------------------------------------------------------------
-- LocalPlayer Freecam
-- 29/5/22 Ooflet
------------------------------------------------------------------------

local pi    = math.pi
local abs   = math.abs
local clamp = math.clamp
local exp   = math.exp
local rad   = math.rad
local sign  = math.sign
local sqrt  = math.sqrt
local tan   = math.tan

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	LocalPlayer = Players.LocalPlayer
end

local Camera = Workspace.CurrentCamera
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	local newCamera = Workspace.CurrentCamera
	if newCamera then
		Camera = newCamera
	end
end)

------------------------------------------------------------------------

local TOGGLE_INPUT_PRIORITY = Enum.ContextActionPriority.Low.Value
local INPUT_PRIORITY = Enum.ContextActionPriority.High.Value
local FREECAM_MACRO_KB = {Enum.KeyCode.L}

local NAV_GAIN = Vector3.new(1, 1, 1)*64
local PAN_GAIN = Vector2.new(0.75, 1)*8
local FOV_GAIN = 300

local PITCH_LIMIT = rad(90)

local VEL_STIFFNESS = 1.5
local PAN_STIFFNESS = 1.0
local FOV_STIFFNESS = 4.0

------------------------------------------------------------------------

local Spring = {} do
	Spring.__index = Spring

	function Spring.new(freq, pos)
		local self = setmetatable({}, Spring)
		self.f = freq
		self.p = pos
		self.v = pos*0
		return self
	end

	function Spring:Update(dt, goal)
		local f = self.f*2*pi
		local p0 = self.p
		local v0 = self.v

		local offset = goal - p0
		local decay = exp(-f*dt)

		local p1 = goal + (v0*dt - offset*(f*dt + 1))*decay
		local v1 = (f*dt*(offset*f - v0) + v0)*decay

		self.p = p1
		self.v = v1

		return p1
	end

	function Spring:Reset(pos)
		self.p = pos
		self.v = pos*0
	end
end

------------------------------------------------------------------------

local cameraPos = Vector3.new()
local cameraRot = Vector2.new()
local cameraFov = 0

local velSpring = Spring.new(VEL_STIFFNESS, Vector3.new())
local panSpring = Spring.new(PAN_STIFFNESS, Vector2.new())
local fovSpring = Spring.new(FOV_STIFFNESS, 0)

------------------------------------------------------------------------

-- Gui to Lua
-- Version: 3.2

-- Instances:

local Freecam = Instance.new("ScreenGui")
local Status = Instance.new("TextLabel")
local Killaura = Instance.new("Frame")
local Switch = Instance.new("ImageButton")
local UICorner = Instance.new("UICorner")
local Dot = Instance.new("Frame")
local UICorner_2 = Instance.new("UICorner")
local UIPadding = Instance.new("UIPadding")
local TextLabel = Instance.new("TextLabel")
local Autowin = Instance.new("Frame")
local Switch_2 = Instance.new("ImageButton")
local UICorner_3 = Instance.new("UICorner")
local Dot_2 = Instance.new("Frame")
local UICorner_4 = Instance.new("UICorner")
local UIPadding_2 = Instance.new("UIPadding")
local TextLabel_2 = Instance.new("TextLabel")

--Properties:

Freecam.Name = "Freecam"
Freecam.Parent = game:GetService("CoreGui")
Freecam.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Freecam.Enabled = false

Status.Name = "Status"
Status.Parent = Freecam
Status.AnchorPoint = Vector2.new(0, 1)
Status.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Status.BackgroundTransparency = 1.000
Status.Position = UDim2.new(0.00999999978, 0, 0.99000001, 0)
Status.Size = UDim2.new(0, 400, 0, 25)
Status.Font = Enum.Font.RobotoMono
Status.Text = "Freecam Enabled. Press L to open/close"
Status.TextColor3 = Color3.fromRGB(255, 255, 255)
Status.TextSize = 18.000
Status.TextStrokeTransparency = 0.750
Status.TextWrapped = true
Status.TextXAlignment = Enum.TextXAlignment.Left

Killaura.Name = "Killaura"
Killaura.Parent = Freecam
Killaura.AnchorPoint = Vector2.new(1, 0)
Killaura.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Killaura.BackgroundTransparency = 1.000
Killaura.Position = UDim2.new(0.949999988, 0, 0.150000006, 0)
Killaura.Size = UDim2.new(0, 250, 0, 35)

Switch.Name = "Switch"
Switch.Parent = Killaura
Switch.Active = false
Switch.AnchorPoint = Vector2.new(1, 0)
Switch.BackgroundColor3 = Color3.fromRGB(138, 138, 138)
Switch.Position = UDim2.new(1, 0, 0, 0)
Switch.Selectable = false
Switch.Size = UDim2.new(0, 65, 0, 35)
Switch.AutoButtonColor = false

UICorner.CornerRadius = UDim.new(1, 0)
UICorner.Parent = Switch

Dot.Name = "Dot"
Dot.Parent = Switch
Dot.AnchorPoint = Vector2.new(0.5, 0)
Dot.BackgroundColor3 = Color3.fromRGB(181, 181, 181)
Dot.Position = UDim2.new(0.25, 0, 0, 0)
Dot.Size = UDim2.new(0.5, 0, 1, 0)

UICorner_2.CornerRadius = UDim.new(1, 0)
UICorner_2.Parent = Dot

UIPadding.Parent = Switch
UIPadding.PaddingBottom = UDim.new(0.150000006, 0)
UIPadding.PaddingLeft = UDim.new(0.100000001, 0)
UIPadding.PaddingRight = UDim.new(0.100000001, 0)
UIPadding.PaddingTop = UDim.new(0.150000006, 0)

TextLabel.Parent = Killaura
TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextLabel.BackgroundTransparency = 1.000
TextLabel.Size = UDim2.new(0, 175, 1, 0)
TextLabel.Font = Enum.Font.RobotoMono
TextLabel.Text = "Killaura"
TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel.TextSize = 25.000
TextLabel.TextStrokeTransparency = 0.750
TextLabel.TextWrapped = true

Autowin.Name = "Autowin"
Autowin.Parent = Freecam
Autowin.AnchorPoint = Vector2.new(1, 0)
Autowin.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Autowin.BackgroundTransparency = 1.000
Autowin.Position = UDim2.new(0.949999988, 0, 0.25, 0)
Autowin.Size = UDim2.new(0, 250, 0, 35)

Switch_2.Name = "Switch"
Switch_2.Parent = Autowin
Switch_2.Active = false
Switch_2.AnchorPoint = Vector2.new(1, 0)
Switch_2.BackgroundColor3 = Color3.fromRGB(138, 138, 138)
Switch_2.Position = UDim2.new(1, 0, 0, 0)
Switch_2.Selectable = false
Switch_2.Size = UDim2.new(0, 65, 0, 35)
Switch_2.AutoButtonColor = false

UICorner_3.CornerRadius = UDim.new(1, 0)
UICorner_3.Parent = Switch_2

Dot_2.Name = "Dot"
Dot_2.Parent = Switch_2
Dot_2.AnchorPoint = Vector2.new(0.5, 0)
Dot_2.BackgroundColor3 = Color3.fromRGB(181, 181, 181)
Dot_2.Position = UDim2.new(0.25, 0, 0, 0)
Dot_2.Size = UDim2.new(0.5, 0, 1, 0)

UICorner_4.CornerRadius = UDim.new(1, 0)
UICorner_4.Parent = Dot_2

UIPadding_2.Parent = Switch_2
UIPadding_2.PaddingBottom = UDim.new(0.150000006, 0)
UIPadding_2.PaddingLeft = UDim.new(0.100000001, 0)
UIPadding_2.PaddingRight = UDim.new(0.100000001, 0)
UIPadding_2.PaddingTop = UDim.new(0.150000006, 0)

TextLabel_2.Parent = Autowin
TextLabel_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_2.BackgroundTransparency = 1.000
TextLabel_2.Size = UDim2.new(0, 175, 1, 0)
TextLabel_2.Font = Enum.Font.RobotoMono
TextLabel_2.Text = "Autowin"
TextLabel_2.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_2.TextSize = 25.000
TextLabel_2.TextStrokeTransparency = 0.750
TextLabel_2.TextWrapped = true

-- Scripts:

local function KEHT_fake_script() -- Freecam.LocalScript 
	local script = Instance.new('LocalScript', Freecam)


end
coroutine.wrap(KEHT_fake_script)()
local function DCHYD_fake_script() -- Switch.LocalScript 
	local script = Instance.new('LocalScript', Switch)

	local clicked = false

	while clicked do
		wait()
		for i,v in pairs(game.Players:GetPlayers()) do
			game:GetService("ReplicatedStorage").BedWars.RemoteEvent:FireServer("DamagePlayer", game:GetService("Players").LocalPlayer, v)
		end
	end

	script.Parent.MouseButton1Click:Connect(function()
		if clicked == false then
			script.Parent.Dot:TweenPosition(UDim2.new(0.75,0,0,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.5, true)
			script.Parent.BackgroundColor3 = Color3.fromRGB(46, 138, 0)
			script.Parent.Dot.BackgroundColor3 = Color3.fromRGB(85, 255, 0)
			clicked = true

		elseif clicked == true then
			script.Parent.Dot:TweenPosition(UDim2.new(0.25,0,0,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.5, true)
			script.Parent.BackgroundColor3 = Color3.fromRGB(138, 138, 138)
			script.Parent.Dot.BackgroundColor3 = Color3.fromRGB(181, 181, 181)
			clicked = false
		end
	end)
end
coroutine.wrap(DCHYD_fake_script)()
local function KQMA_fake_script() -- Switch_2.LocalScript 
	local script = Instance.new('LocalScript', Switch_2)

	local clicked = false

	while clicked do
		local RunService = game:GetService("RunService")
		RunService.RenderStepped:Connect(function()
			game.Players.LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid"):ChangeState(11)
		end)
		for i,v in pairs(workspace:FindFirstChild("Beds", true):GetChildren()) do
			if not game:GetService("ReplicatedStorage").BedWars.Teams:FindFirstChild(v.Name):FindFirstChild(game.Players.LocalPlayer.Name) then
				repeat wait()
					game.Players.LocalPlayer.Character.PrimaryPart.CFrame = v.CFrame + Vector3.new(0,5,0)
					game:GetService("ReplicatedStorage").BedWars.RemoteEvent:FireServer("DamageBlock", game:GetService("Players").LocalPlayer, v.Position, v)
				until v.Parent == nil
			end
		end
		local team = game:GetService("ReplicatedStorage").BedWars.Teams:FindFirstChild(game.Players.LocalPlayer.Name, true).Parent
		for i,v in pairs(game.Players:GetPlayers()) do
			if not team:FindFirstChild(v.Name) and game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") and game.Players.LocalPlayer.Character.Humanoid.Health > 0 then
				repeat wait()
					game.Players.LocalPlayer.Character.PrimaryPart.CFrame = v.Character.HumanoidRootPart.CFrame + Vector3.new(0,5,0)
					game:GetService("ReplicatedStorage").BedWars.RemoteEvent:FireServer("DamagePlayer", game:GetService("Players").LocalPlayer, v)
				until not v.Character or not v.Character:FindFirstChild("HumanoidRootPart") or not v.Character:FindFirstChild("Humanoid") or v.Character.Humanoid.Health <= 0 or v.Character.HP.Value <= 0
			end
		end
	end

	script.Parent.MouseButton1Click:Connect(function()
		if clicked == false then
			script.Parent.Dot:TweenPosition(UDim2.new(0.75,0,0,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.5, true)
			script.Parent.BackgroundColor3 = Color3.fromRGB(46, 138, 0)
			script.Parent.Dot.BackgroundColor3 = Color3.fromRGB(85, 255, 0)
			clicked = true

		elseif clicked == true then
			script.Parent.Dot:TweenPosition(UDim2.new(0.25,0,0,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.5, true)
			script.Parent.BackgroundColor3 = Color3.fromRGB(138, 138, 138)
			script.Parent.Dot.BackgroundColor3 = Color3.fromRGB(181, 181, 181)
			clicked = false
		end
	end)
end
coroutine.wrap(KQMA_fake_script)()

------------------------------------------------------------------------

local Input = {} do
	local thumbstickCurve do
		local K_CURVATURE = 2.0
		local K_DEADZONE = 0.15

		local function fCurve(x)
			return (exp(K_CURVATURE*x) - 1)/(exp(K_CURVATURE) - 1)
		end

		local function fDeadzone(x)
			return fCurve((x - K_DEADZONE)/(1 - K_DEADZONE))
		end

		function thumbstickCurve(x)
			return sign(x)*clamp(fDeadzone(abs(x)), 0, 1)
		end
	end

	local gamepad = {
		ButtonX = 0,
		ButtonY = 0,
		DPadDown = 0,
		DPadUp = 0,
		ButtonL2 = 0,
		ButtonR2 = 0,
		Thumbstick1 = Vector2.new(),
		Thumbstick2 = Vector2.new(),
	}

	local keyboard = {
		W = 0,
		A = 0,
		S = 0,
		D = 0,
		E = 0,
		Q = 0,
		U = 0,
		H = 0,
		J = 0,
		K = 0,
		I = 0,
		Y = 0,
		Up = 0,
		Down = 0,
		LeftShift = 0,
		RightShift = 0,
	}

	local mouse = {
		Delta = Vector2.new(),
		MouseWheel = 0,
	}

	local NAV_GAMEPAD_SPEED  = Vector3.new(1, 1, 1)
	local NAV_KEYBOARD_SPEED = Vector3.new(1, 1, 1)
	local PAN_MOUSE_SPEED    = Vector2.new(1, 1)*(pi/64)
	local PAN_GAMEPAD_SPEED  = Vector2.new(1, 1)*(pi/8)
	local FOV_WHEEL_SPEED    = 1.0
	local FOV_GAMEPAD_SPEED  = 0.25
	local NAV_ADJ_SPEED      = 0.75
	local NAV_SHIFT_MUL      = 0.25

	local navSpeed = 1

	function Input.Vel(dt)
		navSpeed = clamp(navSpeed + dt*(keyboard.Up - keyboard.Down)*NAV_ADJ_SPEED, 0.01, 4)

		local kGamepad = Vector3.new(
			thumbstickCurve(gamepad.Thumbstick1.X),
			thumbstickCurve(gamepad.ButtonR2) - thumbstickCurve(gamepad.ButtonL2),
			thumbstickCurve(-gamepad.Thumbstick1.Y)
		)*NAV_GAMEPAD_SPEED

		local kKeyboard = Vector3.new(
			keyboard.D - keyboard.A + keyboard.K - keyboard.H,
			keyboard.E - keyboard.Q + keyboard.I - keyboard.Y,
			keyboard.S - keyboard.W + keyboard.J - keyboard.U
		)*NAV_KEYBOARD_SPEED

		local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)

		return (kGamepad + kKeyboard)*(navSpeed*(shift and NAV_SHIFT_MUL or 1))
	end

	function Input.Pan(dt)
		local kGamepad = Vector2.new(
			thumbstickCurve(gamepad.Thumbstick2.Y),
			thumbstickCurve(-gamepad.Thumbstick2.X)
		)*PAN_GAMEPAD_SPEED
		local kMouse = mouse.Delta*PAN_MOUSE_SPEED
		mouse.Delta = Vector2.new()
		return kGamepad + kMouse
	end

	function Input.Fov(dt)
		local kGamepad = (gamepad.ButtonX - gamepad.ButtonY)*FOV_GAMEPAD_SPEED
		local kMouse = mouse.MouseWheel*FOV_WHEEL_SPEED
		mouse.MouseWheel = 0
		return kGamepad + kMouse
	end

	do
		local function Keypress(action, state, input)
			keyboard[input.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0
			return Enum.ContextActionResult.Sink
		end

		local function GpButton(action, state, input)
			gamepad[input.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0
			return Enum.ContextActionResult.Sink
		end

		local function MousePan(action, state, input)
			local delta = input.Delta
			mouse.Delta = Vector2.new(-delta.y, -delta.x)
			return Enum.ContextActionResult.Sink
		end

		local function Thumb(action, state, input)
			gamepad[input.KeyCode.Name] = input.Position
			return Enum.ContextActionResult.Sink
		end

		local function Trigger(action, state, input)
			gamepad[input.KeyCode.Name] = input.Position.z
			return Enum.ContextActionResult.Sink
		end

		local function MouseWheel(action, state, input)
			mouse[input.UserInputType.Name] = -input.Position.z
			return Enum.ContextActionResult.Sink
		end

		local function Zero(t)
			for k, v in pairs(t) do
				t[k] = v*0
			end
		end

		function Input.StartCapture()
			ContextActionService:BindActionAtPriority("FreecamKeyboard", Keypress, false, INPUT_PRIORITY,
				Enum.KeyCode.W, Enum.KeyCode.U,
				Enum.KeyCode.A, Enum.KeyCode.H,
				Enum.KeyCode.S, Enum.KeyCode.J,
				Enum.KeyCode.D, Enum.KeyCode.K,
				Enum.KeyCode.E, Enum.KeyCode.I,
				Enum.KeyCode.Q, Enum.KeyCode.Y,
				Enum.KeyCode.Up, Enum.KeyCode.Down
			)
			ContextActionService:BindActionAtPriority("FreecamMousePan",          MousePan,   false, INPUT_PRIORITY, Enum.UserInputType.MouseMovement)
			ContextActionService:BindActionAtPriority("FreecamMouseWheel",        MouseWheel, false, INPUT_PRIORITY, Enum.UserInputType.MouseWheel)
			ContextActionService:BindActionAtPriority("FreecamGamepadButton",     GpButton,   false, INPUT_PRIORITY, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonY)
			ContextActionService:BindActionAtPriority("FreecamGamepadTrigger",    Trigger,    false, INPUT_PRIORITY, Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonL2)
			ContextActionService:BindActionAtPriority("FreecamGamepadThumbstick", Thumb,      false, INPUT_PRIORITY, Enum.KeyCode.Thumbstick1, Enum.KeyCode.Thumbstick2)
		end

		function Input.StopCapture()
			navSpeed = 1
			Zero(gamepad)
			Zero(keyboard)
			Zero(mouse)
			ContextActionService:UnbindAction("FreecamKeyboard")
			ContextActionService:UnbindAction("FreecamMousePan")
			ContextActionService:UnbindAction("FreecamMouseWheel")
			ContextActionService:UnbindAction("FreecamGamepadButton")
			ContextActionService:UnbindAction("FreecamGamepadTrigger")
			ContextActionService:UnbindAction("FreecamGamepadThumbstick")
		end
	end
end

local function GetFocusDistance(cameraFrame)
	local znear = 0.1
	local viewport = Camera.ViewportSize
	local projy = 2*tan(cameraFov/2)
	local projx = viewport.x/viewport.y*projy
	local fx = cameraFrame.rightVector
	local fy = cameraFrame.upVector
	local fz = cameraFrame.lookVector

	local minVect = Vector3.new()
	local minDist = 512

	for x = 0, 1, 0.5 do
		for y = 0, 1, 0.5 do
			local cx = (x - 0.5)*projx
			local cy = (y - 0.5)*projy
			local offset = fx*cx - fy*cy + fz
			local origin = cameraFrame.p + offset*znear
			local _, hit = Workspace:FindPartOnRay(Ray.new(origin, offset.unit*minDist))
			local dist = (hit - origin).magnitude
			if minDist > dist then
				minDist = dist
				minVect = offset.unit
			end
		end
	end

	return fz:Dot(minVect)*minDist
end

------------------------------------------------------------------------

local function StepFreecam(dt)
	local vel = velSpring:Update(dt, Input.Vel(dt))
	local pan = panSpring:Update(dt, Input.Pan(dt))
	local fov = fovSpring:Update(dt, Input.Fov(dt))

	local zoomFactor = sqrt(tan(rad(70/2))/tan(rad(cameraFov/2)))

	cameraFov = clamp(cameraFov + fov*FOV_GAIN*(dt/zoomFactor), 1, 120)
	cameraRot = cameraRot + pan*PAN_GAIN*(dt/zoomFactor)
	cameraRot = Vector2.new(clamp(cameraRot.x, -PITCH_LIMIT, PITCH_LIMIT), cameraRot.y%(2*pi))

	local cameraCFrame = CFrame.new(cameraPos)*CFrame.fromOrientation(cameraRot.x, cameraRot.y, 0)*CFrame.new(vel*NAV_GAIN*dt)
	cameraPos = cameraCFrame.p

	Camera.CFrame = cameraCFrame
	Camera.Focus = cameraCFrame*CFrame.new(0, 0, -GetFocusDistance(cameraCFrame))
	Camera.FieldOfView = cameraFov
end

------------------------------------------------------------------------

local PlayerState = {} do
	local mouseBehavior
	local mouseIconEnabled
	local cameraType
	local cameraFocus
	local cameraCFrame
	local cameraFieldOfView
	local screenGuis = {}
	local coreGuis = {
		Backpack = true,
		Chat = true,
		Health = true,
		PlayerList = true,
	}
	local setCores = {
		BadgesNotificationsActive = true,
		PointsNotificationsActive = true,
	}

	-- Save state and set up for freecam
	function PlayerState.Push()
		for name in pairs(coreGuis) do
			coreGuis[name] = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType[name])
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[name], false)
		end
		for name in pairs(setCores) do
			setCores[name] = StarterGui:GetCore(name)
			StarterGui:SetCore(name, false)
		end
		local playergui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
		if playergui then
			for _, gui in pairs(playergui:GetChildren()) do
				if gui:IsA("ScreenGui") and gui.Enabled then
					screenGuis[#screenGuis + 1] = gui
					gui.Enabled = false
				end
			end
		end

		cameraFieldOfView = Camera.FieldOfView
		Camera.FieldOfView = 70

		cameraType = Camera.CameraType
		Camera.CameraType = Enum.CameraType.Custom

		cameraCFrame = Camera.CFrame
		cameraFocus = Camera.Focus

		mouseBehavior = UserInputService.MouseBehavior
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end

	-- Restore state
	function PlayerState.Pop()
		for name, isEnabled in pairs(coreGuis) do
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[name], isEnabled)
		end
		for name, isEnabled in pairs(setCores) do
			StarterGui:SetCore(name, isEnabled)
		end
		for _, gui in pairs(screenGuis) do
			if gui.Parent then
				gui.Enabled = true
			end
		end

		Camera.FieldOfView = cameraFieldOfView
		cameraFieldOfView = nil

		Camera.CameraType = cameraType
		cameraType = nil

		Camera.CFrame = cameraCFrame
		cameraCFrame = nil

		Camera.Focus = cameraFocus
		cameraFocus = nil

		UserInputService.MouseIconEnabled = mouseIconEnabled
		mouseIconEnabled = nil

		UserInputService.MouseBehavior = mouseBehavior
		mouseBehavior = nil
	end
end

local function StartFreecam()
	local cameraCFrame = Camera.CFrame
	Freecam.Enabled = true
	cameraRot = Vector2.new(cameraCFrame:toEulerAnglesYXZ())
	cameraPos = cameraCFrame.p
	cameraFov = Camera.FieldOfView

	velSpring:Reset(Vector3.new())
	panSpring:Reset(Vector2.new())
	fovSpring:Reset(0)

	PlayerState.Push()
	RunService:BindToRenderStep("Freecam", Enum.RenderPriority.Camera.Value, StepFreecam)
	Input.StartCapture()
end

local function StopFreecam()
	Freecam.Enabled = false
	Input.StopCapture()
	RunService:UnbindFromRenderStep("Freecam")
	PlayerState.Pop()
end

------------------------------------------------------------------------

do
	local enabled = false

	local function ToggleFreecam()
		if enabled then
			StopFreecam()
		else
			StartFreecam()
		end
		enabled = not enabled
	end

	local function CheckMacro(macro)
		for i = 1, #macro - 1 do
			if not UserInputService:IsKeyDown(macro[i]) then
				return
			end
		end
		ToggleFreecam()
	end

	local function HandleActivationInput(action, state, input)
		if state == Enum.UserInputState.Begin then
			if input.KeyCode == FREECAM_MACRO_KB[#FREECAM_MACRO_KB] then
				CheckMacro(FREECAM_MACRO_KB)
			end
		end
		return Enum.ContextActionResult.Pass
	end

	ContextActionService:BindActionAtPriority("FreecamToggle", HandleActivationInput, false, TOGGLE_INPUT_PRIORITY, FREECAM_MACRO_KB[#FREECAM_MACRO_KB])
end
