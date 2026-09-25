--!strict
-- Tiny Repair Shop
-- Mobile-friendly HUD. Repair actions use ProximityPrompt, so Roblox handles
-- touch, controller, and keyboard interaction without platform-specific buttons.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("TinyRepairShopShared")
local RepairCatalog = require(Shared:WaitForChild("RepairCatalog"))
local Localization = require(Shared:WaitForChild("Localization"))

local remotes = ReplicatedStorage:WaitForChild("TinyRepairShopRemotes")
local stateChanged = remotes:WaitForChild("StateChanged") :: RemoteEvent
local toastEvent = remotes:WaitForChild("Toast") :: RemoteEvent

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
statsFrame.Size = UDim2.fromOffset(280, 72)
statsFrame.Position = UDim2.fromOffset(16, 16)
statsFrame.BackgroundColor3 = Color3.fromRGB(37, 43, 40)
statsFrame.BackgroundTransparency = 0.08
statsFrame.Parent = gui
round(statsFrame, 14)
addStroke(statsFrame, 0.8)

local titleLabel = makeText(
	statsFrame,
	"🔧 " .. Localization.text("Title", localeCode),
	UDim2.new(1, -20, 0, 28),
	UDim2.fromOffset(12, 7),
	17,
	true
)

local moneyLabel = makeText(
	statsFrame,
	Localization.text("Money", localeCode) .. ": $0",
	UDim2.new(0.55, -8, 0, 24),
	UDim2.fromOffset(12, 39),
	15,
	true
)

local reputationLabel = makeText(
	statsFrame,
	Localization.text("Reputation", localeCode) .. ": 0",
	UDim2.new(0.45, -8, 0, 24),
	UDim2.new(0.55, 0, 0, 39),
	15,
	true
)

local jobFrame = Instance.new("Frame")
jobFrame.Name = "JobCard"
jobFrame.AnchorPoint = Vector2.new(0.5, 1)
jobFrame.Size = UDim2.new(0.92, 0, 0, 178)
jobFrame.Position = UDim2.new(0.5, 0, 1, -18)
jobFrame.BackgroundColor3 = Color3.fromRGB(42, 47, 44)
jobFrame.BackgroundTransparency = 0.05
jobFrame.Parent = gui
round(jobFrame, 18)
addStroke(jobFrame, 0.78)

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MaxSize = Vector2.new(620, 190)
sizeConstraint.MinSize = Vector2.new(280, 160)
sizeConstraint.Parent = jobFrame

local jobTitle = makeText(
	jobFrame,
	Localization.text("NoJobTitle", localeCode),
	UDim2.new(1, -28, 0, 30),
	UDim2.fromOffset(14, 12),
	20,
	true
)

local symptomLabel = makeText(
	jobFrame,
	Localization.text("NoJobBody", localeCode),
	UDim2.new(1, -28, 0, 48),
	UDim2.fromOffset(14, 48),
	15,
	false
)

local faultLabel = makeText(
	jobFrame,
	Localization.text("HiddenFault", localeCode),
	UDim2.new(1, -28, 0, 24),
	UDim2.fromOffset(14, 100),
	14,
	true
)

local stepLabel = makeText(
	jobFrame,
	"",
	UDim2.new(1, -28, 0, 40),
	UDim2.fromOffset(14, 128),
	15,
	true
)

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

local toastText = makeText(
	toastFrame,
	"",
	UDim2.new(1, -24, 1, -12),
	UDim2.fromOffset(12, 6),
	16,
	true
)
toastText.TextXAlignment = Enum.TextXAlignment.Center
toastText.TextYAlignment = Enum.TextYAlignment.Center

local toastSequence = 0

local function showToast(key: string, data: any?)
	toastSequence += 1
	local sequence = toastSequence

	local message = Localization.text(key, localeCode)
	if key == "RepairComplete" and data and type(data.reward) == "number" then
		message ..= "  +" .. tostring(math.floor(data.reward))
	elseif key == "RareFind" and data and type(data.bonus) == "number" then
		message ..= "  +" .. tostring(math.floor(data.bonus))
	end

	toastText.Text = message

	TweenService:Create(
		toastFrame,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0, 18) }
	):Play()

	task.delay(2.3, function()
		if sequence ~= toastSequence then
			return
		end

		TweenService:Create(
			toastFrame,
			TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(0.5, 0, 0, -80) }
		):Play()
	end)
end

local function renderJob(state: any?)
	if not state then
		jobTitle.Text = Localization.text("NoJobTitle", localeCode)
		symptomLabel.Text = Localization.text("NoJobBody", localeCode)
		faultLabel.Text = Localization.text("HiddenFault", localeCode)
		stepLabel.Text = ""
		return
	end

	local job = RepairCatalog.getJob(state.jobId)
	if not job then
		return
	end

	jobTitle.Text = "🔧 " .. Localization.pick(job.name, localeCode)
	symptomLabel.Text = Localization.text("Symptom", localeCode)
		.. ": "
		.. Localization.pick(job.symptom, localeCode)

	if state.faultRevealed and state.faultId then
		local fault = RepairCatalog.getFault(job, state.faultId)
		if fault then
			faultLabel.Text = Localization.text("Fault", localeCode)
				.. ": "
				.. Localization.pick(fault.label, localeCode)

			local stepDefinition = fault.steps[state.stepIndex]
			if stepDefinition then
				local progress = string.format(
					Localization.text("StepProgress", localeCode),
					state.stepIndex,
					state.totalSteps
				)
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
