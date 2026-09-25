--!strict
-- Tiny Repair Shop
-- Mobile-friendly HUD and timing skill check.
-- Roblox handles keyboard/controller/touch movement; repair actions use ProximityPrompt.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("TinyRepairShopShared")
local RepairCatalog = require(Shared:WaitForChild("RepairCatalog"))
local Localization = require(Shared:WaitForChild("Localization"))

local remotes = ReplicatedStorage:WaitForChild("TinyRepairShopRemotes")
local stateChanged = remotes:WaitForChild("StateChanged") :: RemoteEvent
local toastEvent = remotes:WaitForChild("Toast") :: RemoteEvent
local skillCheckStarted = remotes:WaitForChild("SkillCheckStarted") :: RemoteEvent
local skillCheckSubmit = remotes:WaitForChild("SkillCheckSubmit") :: RemoteEvent

local localeCode = Localization.getLocaleCode(LocalizationService.RobloxLocaleId)

local oldGui = playerGui:FindFirstChild("TinyRepairShopGui")
if oldGui then
	oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "TinyRepairShopGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 10
gui.Parent = playerGui

local function round(instance: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
end

local function addStroke(instance: GuiObject, transparency: number)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = transparency
	stroke.Thickness = 1
	stroke.Parent = instance
end

local function makeText(parent: Instance, text: string, size: UDim2, position: UDim2, textSize: number, bold: boolean): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position
	label.Font = if bold then Enum.Font.GothamBold else Enum.Font.Gotham
	label.Text = text
	label.TextColor3 = Color3.fromRGB(244, 241, 231)
	label.TextSize = textSize
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local statsFrame = Instance.new("Frame")
statsFrame.Name = "Stats"
statsFrame.Size = UDim2.fromOffset(292, 72)
statsFrame.Position = UDim2.fromOffset(16, 16)
statsFrame.BackgroundColor3 = Color3.fromRGB(37, 43, 40)
statsFrame.BackgroundTransparency = 0.08
statsFrame.Parent = gui
round(statsFrame, 14)
addStroke(statsFrame, 0.8)

makeText(statsFrame, "🔧 " .. Localization.text("Title", localeCode), UDim2.new(1, -20, 0, 28), UDim2.fromOffset(12, 7), 17, true)

local moneyLabel = makeText(statsFrame, Localization.text("Money", localeCode) .. ": $0", UDim2.new(0.55, -8, 0, 24), UDim2.fromOffset(12, 39), 15, true)
local reputationLabel = makeText(statsFrame, Localization.text("Reputation", localeCode) .. ": 0", UDim2.new(0.45, -8, 0, 24), UDim2.new(0.55, 0, 0, 39), 15, true)

local jobFrame = Instance.new("Frame")
jobFrame.Name = "JobCard"
jobFrame.AnchorPoint = Vector2.new(0.5, 1)
jobFrame.Size = UDim2.new(0.92, 0, 0, 196)
jobFrame.Position = UDim2.new(0.5, 0, 1, -18)
jobFrame.BackgroundColor3 = Color3.fromRGB(42, 47, 44)
jobFrame.BackgroundTransparency = 0.05
jobFrame.Parent = gui
round(jobFrame, 18)
addStroke(jobFrame, 0.78)

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MaxSize = Vector2.new(620, 205)
sizeConstraint.MinSize = Vector2.new(280, 180)
sizeConstraint.Parent = jobFrame

local jobTitle = makeText(jobFrame, Localization.text("NoJobTitle", localeCode), UDim2.new(1, -28, 0, 30), UDim2.fromOffset(14, 12), 20, true)
local symptomLabel = makeText(jobFrame, Localization.text("NoJobBody", localeCode), UDim2.new(1, -28, 0, 48), UDim2.fromOffset(14, 48), 15, false)
local faultLabel = makeText(jobFrame, Localization.text("HiddenFault", localeCode), UDim2.new(1, -28, 0, 24), UDim2.fromOffset(14, 100), 14, true)
local stepLabel = makeText(jobFrame, "", UDim2.new(1, -28, 0, 38), UDim2.fromOffset(14, 126), 15, true)
local qualityLabel = makeText(jobFrame, "", UDim2.new(1, -28, 0, 24), UDim2.fromOffset(14, 166), 14, true)

local toastFrame = Instance.new("Frame")
toastFrame.Name = "Toast"
toastFrame.AnchorPoint = Vector2.new(0.5, 0)
toastFrame.Size = UDim2.new(0.86, 0, 0, 58)
toastFrame.Position = UDim2.new(0.5, 0, 0, -80)
toastFrame.BackgroundColor3 = Color3.fromRGB(61, 77, 68)
toastFrame.BackgroundTransparency = 0.03
toastFrame.Parent = gui
round(toastFrame, 16)
addStroke(toastFrame, 0.76)

local toastConstraint = Instance.new("UISizeConstraint")
toastConstraint.MaxSize = Vector2.new(520, 64)
toastConstraint.Parent = toastFrame

local toastText = makeText(toastFrame, "", UDim2.new(1, -24, 1, -12), UDim2.fromOffset(12, 6), 16, true)
toastText.TextXAlignment = Enum.TextXAlignment.Center
toastText.TextYAlignment = Enum.TextYAlignment.Center

local toastSequence = 0

local function showToast(key: string, data: any?)
	toastSequence += 1
	local sequence = toastSequence
	local message = Localization.text(key, localeCode)

	if key == "RepairComplete" and data and type(data.reward) == "number" then
		message ..= "  +" .. tostring(math.floor(data.reward))
		if type(data.quality) == "number" then
			message ..= "  •  " .. Localization.text("Quality", localeCode) .. " " .. tostring(math.floor(data.quality)) .. "%"
		end
	elseif key == "RareFind" and data and type(data.bonus) == "number" then
		message ..= "  +" .. tostring(math.floor(data.bonus))
	end

	toastText.Text = message
	TweenService:Create(toastFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0, 18) }):Play()

	task.delay(2.3, function()
		if sequence ~= toastSequence then
			return
		end
		TweenService:Create(toastFrame, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0.5, 0, 0, -80) }):Play()
	end)
end

local function renderJob(state: any?)
	if not state then
		jobTitle.Text = Localization.text("NoJobTitle", localeCode)
		symptomLabel.Text = Localization.text("NoJobBody", localeCode)
		faultLabel.Text = Localization.text("HiddenFault", localeCode)
		stepLabel.Text = ""
		qualityLabel.Text = ""
		return
	end

	local job = RepairCatalog.getJob(state.jobId)
	if not job then
		return
	end

	jobTitle.Text = "🔧 " .. Localization.pick(job.name, localeCode)
	symptomLabel.Text = Localization.text("Symptom", localeCode) .. ": " .. Localization.pick(job.symptom, localeCode)
	qualityLabel.Text = Localization.text("Quality", localeCode) .. ": " .. tostring(math.floor(state.quality or 100)) .. "%"

	if state.faultRevealed and state.faultId then
		local fault = RepairCatalog.getFault(job, state.faultId)
		if fault then
			faultLabel.Text = Localization.text("Fault", localeCode) .. ": " .. Localization.pick(fault.label, localeCode)
			local stepDefinition = fault.steps[state.stepIndex]
			if stepDefinition then
				local progress = string.format(Localization.text("StepProgress", localeCode), state.stepIndex, state.totalSteps)
				stepLabel.Text = progress .. "  •  " .. Localization.pick(stepDefinition.label, localeCode)
			else
				stepLabel.Text = ""
			end
		end
	else
		faultLabel.Text = Localization.text("HiddenFault", localeCode)
		stepLabel.Text = Localization.text("GoToWorkbench", localeCode)
	end
end

-- Timing repair minigame. Server time is used on both client and server so the
-- authoritative server can judge the exact same needle position.
local skillFrame = Instance.new("Frame")
skillFrame.Name = "SkillCheck"
skillFrame.AnchorPoint = Vector2.new(0.5, 0.5)
skillFrame.Size = UDim2.new(0.88, 0, 0, 196)
skillFrame.Position = UDim2.fromScale(0.5, 0.5)
skillFrame.BackgroundColor3 = Color3.fromRGB(31, 35, 34)
skillFrame.BackgroundTransparency = 0.02
skillFrame.Visible = false
skillFrame.Parent = gui
round(skillFrame, 20)
addStroke(skillFrame, 0.72)

local skillConstraint = Instance.new("UISizeConstraint")
skillConstraint.MaxSize = Vector2.new(560, 210)
skillConstraint.MinSize = Vector2.new(300, 185)
skillConstraint.Parent = skillFrame

local skillTitle = makeText(skillFrame, Localization.text("SkillCheckTitle", localeCode), UDim2.new(1, -28, 0, 30), UDim2.fromOffset(14, 12), 21, true)
skillTitle.TextXAlignment = Enum.TextXAlignment.Center

local skillHint = makeText(skillFrame, Localization.text("SkillCheckHint", localeCode), UDim2.new(1, -28, 0, 42), UDim2.fromOffset(14, 44), 14, false)
skillHint.TextXAlignment = Enum.TextXAlignment.Center

local track = Instance.new("Frame")
track.Name = "Track"
track.Size = UDim2.new(1, -48, 0, 28)
track.Position = UDim2.fromOffset(24, 91)
track.BackgroundColor3 = Color3.fromRGB(70, 73, 71)
track.ClipsDescendants = true
track.Parent = skillFrame
round(track, 8)

local targetZone = Instance.new("Frame")
targetZone.Name = "TargetZone"
targetZone.BackgroundColor3 = Color3.fromRGB(86, 171, 103)
targetZone.Size = UDim2.fromScale(0.2, 1)
targetZone.Position = UDim2.fromScale(0.4, 0)
targetZone.Parent = track
round(targetZone, 6)

local needle = Instance.new("Frame")
needle.Name = "Needle"
needle.AnchorPoint = Vector2.new(0.5, 0.5)
needle.Size = UDim2.fromOffset(5, 38)
needle.Position = UDim2.fromScale(0, 0.5)
needle.BackgroundColor3 = Color3.fromRGB(245, 225, 134)
needle.Parent = track
round(needle, 3)

local fixButton = Instance.new("TextButton")
fixButton.Name = "FixButton"
fixButton.AnchorPoint = Vector2.new(0.5, 1)
fixButton.Size = UDim2.new(0.65, 0, 0, 52)
fixButton.Position = UDim2.new(0.5, 0, 1, -14)
fixButton.BackgroundColor3 = Color3.fromRGB(86, 121, 103)
fixButton.Text = Localization.text("SkillCheckButton", localeCode)
fixButton.TextColor3 = Color3.fromRGB(255, 255, 255)
fixButton.Font = Enum.Font.GothamBold
fixButton.TextSize = 20
fixButton.AutoButtonColor = true
fixButton.Parent = skillFrame
round(fixButton, 13)

type ActiveSkill = {
	startTime: number,
	speed: number,
	targetStart: number,
	targetEnd: number,
	stepIndex: number,
	submitted: boolean,
}

local activeSkill: ActiveSkill? = nil

local function needlePosition(data: ActiveSkill, now: number): number
	local elapsed = math.max(0, now - data.startTime)
	local phase = (elapsed * data.speed) % 2
	if phase <= 1 then
		return phase
	end
	return 2 - phase
end

RunService.RenderStepped:Connect(function()
	local current = activeSkill
	if not current or not skillFrame.Visible then
		return
	end

	local now = workspace:GetServerTimeNow()
	local position = needlePosition(current, now)
	needle.Position = UDim2.fromScale(position, 0.5)
end)

skillCheckStarted.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" then
		return
	end
	if type(data.startTime) ~= "number"
		or type(data.speed) ~= "number"
		or type(data.targetStart) ~= "number"
		or type(data.targetEnd) ~= "number"
		or type(data.stepIndex) ~= "number" then
		return
	end

	activeSkill = {
		startTime = data.startTime,
		speed = data.speed,
		targetStart = data.targetStart,
		targetEnd = data.targetEnd,
		stepIndex = data.stepIndex,
		submitted = false,
	}

	targetZone.Position = UDim2.fromScale(data.targetStart, 0)
	targetZone.Size = UDim2.fromScale(data.targetEnd - data.targetStart, 1)
	needle.Position = UDim2.fromScale(0, 0.5)
	skillFrame.Visible = true
	fixButton.Active = true

	local thisSkill = activeSkill
	task.delay(9.2, function()
		if activeSkill == thisSkill then
			activeSkill = nil
			skillFrame.Visible = false
		end
	end)
end)

fixButton.Activated:Connect(function()
	local current = activeSkill
	if not current or current.submitted then
		return
	end

	current.submitted = true
	fixButton.Active = false
	skillCheckSubmit:FireServer()

	task.delay(0.12, function()
		if activeSkill == current then
			activeSkill = nil
			skillFrame.Visible = false
		end
	end)
end)

local function bindStats()
	local leaderstats = player:WaitForChild("leaderstats")
	local cash = leaderstats:WaitForChild("Cash") :: IntValue
	local reputation = leaderstats:WaitForChild("Reputation") :: IntValue

	local function refresh()
		moneyLabel.Text = Localization.text("Money", localeCode) .. ": $" .. tostring(cash.Value)
		reputationLabel.Text = Localization.text("Reputation", localeCode) .. ": " .. tostring(reputation.Value)
	end

	cash:GetPropertyChangedSignal("Value"):Connect(refresh)
	reputation:GetPropertyChangedSignal("Value"):Connect(refresh)
	refresh()
end

stateChanged.OnClientEvent:Connect(function(state)
	renderJob(state)
end)

toastEvent.OnClientEvent:Connect(function(key: string, data)
	showToast(key, data)
end)

task.spawn(bindStats)
renderJob(nil)
