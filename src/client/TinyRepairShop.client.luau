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
local ShopFlavor = require(Shared:WaitForChild("ShopFlavor"))

local remotes = ReplicatedStorage:WaitForChild("TinyRepairShopRemotes")
local stateChanged = remotes:WaitForChild("StateChanged") :: RemoteEvent
local toastEvent = remotes:WaitForChild("Toast") :: RemoteEvent
local skillCheckStarted = remotes:WaitForChild("SkillCheckStarted") :: RemoteEvent
local skillCheckSubmit = remotes:WaitForChild("SkillCheckSubmit") :: RemoteEvent
local jobOffersOpened = remotes:WaitForChild("JobOffersOpened") :: RemoteEvent
local jobOfferChosen = remotes:WaitForChild("JobOfferChosen") :: RemoteEvent

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
statsFrame.Size = UDim2.fromOffset(292, 144)
statsFrame.Position = UDim2.fromOffset(16, 16)
statsFrame.BackgroundColor3 = Color3.fromRGB(37, 43, 40)
statsFrame.BackgroundTransparency = 0.08
statsFrame.Parent = gui
round(statsFrame, 14)
addStroke(statsFrame, 0.8)

makeText(statsFrame, "🔧 " .. Localization.text("Title", localeCode), UDim2.new(1, -20, 0, 28), UDim2.fromOffset(12, 7), 17, true)

local moneyLabel = makeText(statsFrame, Localization.text("Money", localeCode) .. ": $0", UDim2.new(0.55, -8, 0, 24), UDim2.fromOffset(12, 39), 15, true)
local reputationLabel = makeText(statsFrame, Localization.text("Reputation", localeCode) .. ": 0", UDim2.new(0.45, -8, 0, 24), UDim2.new(0.55, 0, 0, 39), 15, true)
local toolLevelLabel = makeText(statsFrame, Localization.text("ToolLevel", localeCode) .. ": 0", UDim2.new(0.55, -8, 0, 22), UDim2.fromOffset(12, 65), 14, true)
local streakLabel = makeText(statsFrame, "🔥 " .. Localization.text("Streak", localeCode) .. ": 0", UDim2.new(1, -24, 0, 22), UDim2.fromOffset(12, 89), 14, true)
local oddJobsLabel = makeText(statsFrame, "◈ " .. Localization.text("OddJobs", localeCode) .. ": 0", UDim2.new(1, -24, 0, 22), UDim2.fromOffset(12, 113), 14, true)

local jobFrame = Instance.new("Frame")
jobFrame.Name = "JobCard"
jobFrame.AnchorPoint = Vector2.new(0.5, 1)
jobFrame.Size = UDim2.new(0.92, 0, 0, 220)
jobFrame.Position = UDim2.new(0.5, 0, 1, -18)
jobFrame.BackgroundColor3 = Color3.fromRGB(42, 47, 44)
jobFrame.BackgroundTransparency = 0.05
jobFrame.Parent = gui
round(jobFrame, 18)
addStroke(jobFrame, 0.78)

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MaxSize = Vector2.new(620, 230)
sizeConstraint.MinSize = Vector2.new(280, 205)
sizeConstraint.Parent = jobFrame

local jobTitle = makeText(jobFrame, Localization.text("NoJobTitle", localeCode), UDim2.new(1, -28, 0, 30), UDim2.fromOffset(14, 10), 20, true)
local symptomLabel = makeText(jobFrame, Localization.text("NoJobBody", localeCode), UDim2.new(1, -28, 0, 48), UDim2.fromOffset(14, 44), 15, false)
local flavorLabel = makeText(jobFrame, "", UDim2.new(1, -28, 0, 24), UDim2.fromOffset(14, 92), 14, true)
local faultLabel = makeText(jobFrame, Localization.text("HiddenFault", localeCode), UDim2.new(1, -28, 0, 24), UDim2.fromOffset(14, 118), 14, true)
local stepLabel = makeText(jobFrame, "", UDim2.new(1, -28, 0, 38), UDim2.fromOffset(14, 144), 15, true)
local qualityLabel = makeText(jobFrame, "", UDim2.new(1, -28, 0, 24), UDim2.fromOffset(14, 184), 14, true)

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

	if (key == "RepairComplete" or key == "OddityComplete") and data and type(data.reward) == "number" then
		message ..= "  +" .. tostring(math.floor(data.reward))
		if type(data.quality) == "number" then
			message ..= "  •  " .. Localization.text("Quality", localeCode) .. " " .. tostring(math.floor(data.quality)) .. "%"
		end
		if type(data.streak) == "number" and data.streak > 0 then
			message ..= "  •  🔥 x" .. tostring(math.floor(data.streak))
		end
		if key == "OddityComplete" and data.newOddityUnlocked == true then
			message ..= "  •  " .. Localization.text("NewCuriosity", localeCode)
		end
	elseif (key == "JobAccepted" or key == "OddityAccepted") and data then
		local customer = if type(data.customerId) == "string" then ShopFlavor.getCustomer(data.customerId) else nil
		local modifier = if type(data.modifierId) == "string" then ShopFlavor.getModifier(data.modifierId) else nil
		if customer and modifier then
			message ..= "  " .. Localization.pick(customer.name, localeCode) .. " • " .. Localization.pick(modifier.label, localeCode)
		end
	elseif key == "RareFind" and data and type(data.bonus) == "number" then
		message ..= "  +" .. tostring(math.floor(data.bonus))
	elseif key == "UpgradePurchased" and data and type(data.level) == "number" then
		message ..= "  Lv." .. tostring(math.floor(data.level))
	elseif key == "UpgradeNeedCash" and data and type(data.cost) == "number" then
		message ..= "  $" .. tostring(math.floor(data.cost))
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
		flavorLabel.Text = ""
		faultLabel.Text = Localization.text("HiddenFault", localeCode)
		stepLabel.Text = ""
		qualityLabel.Text = ""
		return
	end

	local job = RepairCatalog.getJob(state.jobId)
	if not job then
		return
	end

	local titlePrefix = if job.rareOnly then "◈ " else "🔧 "
	jobTitle.Text = titlePrefix .. Localization.pick(job.name, localeCode)
	symptomLabel.Text = Localization.text("Symptom", localeCode) .. ": " .. Localization.pick(job.symptom, localeCode)
	local customer = if type(state.customerId) == "string" then ShopFlavor.getCustomer(state.customerId) else nil
	local modifier = if type(state.modifierId) == "string" then ShopFlavor.getModifier(state.modifierId) else nil
	if customer and modifier then
		local orderLabel = Localization.pick(modifier.label, localeCode)
		if job.rareOnly then
			orderLabel = "◈ " .. Localization.text("OddJobTag", localeCode)
		end
		flavorLabel.Text = "👤 " .. Localization.pick(customer.name, localeCode) .. "  •  " .. orderLabel
	else
		flavorLabel.Text = ""
	end
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

-- Oddity collection shelf. The shelf frame is shared in the server-built workshop,
-- but the contents are local so every player sees their own discovered curiosities.
local ODDITY_ORDER = {
	"midnight_radio",
	"laughing_toy_car",
	"blank_photo_camera",
}

local ambientRandom = Random.new()
local AMBIENT_MIN_SECONDS = if RunService:IsStudio() then 10 else 38
local AMBIENT_MAX_SECONDS = if RunService:IsStudio() then 20 else 72

local function collectionPart(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	shape: Enum.PartType?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	if shape then
		part.Shape = shape
	end
	part.Parent = parent
	return part
end

local function addPlaque(parent: Instance, cframe: CFrame, text: string, discovered: boolean)
	local plaque = collectionPart(
		parent,
		"Plaque",
		Vector3.new(4.9, 0.72, 0.16),
		cframe,
		if discovered then Color3.fromRGB(63, 50, 68) else Color3.fromRGB(62, 61, 59)
	)

	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Front
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 48
	surface.Parent = plaque

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = if discovered then Color3.fromRGB(230, 211, 238) else Color3.fromRGB(157, 153, 147)
	label.TextScaled = true
	label.Parent = surface
end

local function buildMiniRadio(parent: Instance, base: CFrame)
	collectionPart(parent, "Body", Vector3.new(2.7, 1.35, 1.0), base * CFrame.new(0, 0.72, 0), Color3.fromRGB(61, 74, 72))
	collectionPart(parent, "Speaker", Vector3.new(0.24, 0.9, 0.9), base * CFrame.new(-0.75, 0.72, -0.54) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(35, 39, 39), Enum.PartType.Cylinder)
	collectionPart(parent, "Dial", Vector3.new(0.22, 0.34, 0.34), base * CFrame.new(0.72, 0.88, -0.55) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(211, 180, 105), Enum.PartType.Cylinder)
	collectionPart(parent, "Handle", Vector3.new(1.8, 0.15, 0.18), base * CFrame.new(0, 1.48, 0), Color3.fromRGB(45, 50, 49))
end

local function buildMiniToyCar(parent: Instance, base: CFrame)
	collectionPart(parent, "Body", Vector3.new(2.5, 0.7, 1.25), base * CFrame.new(0, 0.55, 0), Color3.fromRGB(193, 69, 57))
	collectionPart(parent, "Cab", Vector3.new(1.15, 0.55, 1.05), base * CFrame.new(0.25, 1.0, 0), Color3.fromRGB(218, 91, 68))
	for xIndex = -1, 1, 2 do
		for zIndex = -1, 1, 2 do
			collectionPart(
				parent,
				"Wheel",
				Vector3.new(0.42, 0.42, 0.3),
				base * CFrame.new(xIndex * 0.82, 0.28, zIndex * 0.58) * CFrame.Angles(math.rad(90), 0, 0),
				Color3.fromRGB(33, 33, 33),
				Enum.PartType.Cylinder
			)
		end
	end
end

local function buildMiniCamera(parent: Instance, base: CFrame)
	collectionPart(parent, "Body", Vector3.new(2.55, 1.7, 1.15), base * CFrame.new(0, 0.9, 0), Color3.fromRGB(229, 220, 196))
	collectionPart(parent, "Accent", Vector3.new(2.6, 0.48, 1.2), base * CFrame.new(0, 0.56, 0), Color3.fromRGB(73, 82, 78))
	collectionPart(parent, "Lens", Vector3.new(0.72, 0.72, 0.48), base * CFrame.new(-0.35, 0.95, -0.75) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(38, 42, 44), Enum.PartType.Cylinder)
	collectionPart(parent, "Flash", Vector3.new(0.48, 0.28, 0.15), base * CFrame.new(0.55, 1.38, -0.62), Color3.fromRGB(238, 226, 164))
end

local function buildLockedCuriosity(parent: Instance, base: CFrame)
	local box = collectionPart(parent, "Unknown", Vector3.new(1.8, 1.25, 1.0), base * CFrame.new(0, 0.68, 0), Color3.fromRGB(55, 53, 57))
	box.Material = Enum.Material.Metal

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(80, 44)
	billboard.StudsOffset = Vector3.new(0, 1.2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = box

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.Text = "???"
	label.TextColor3 = Color3.fromRGB(170, 164, 176)
	label.TextScaled = true
	label.Parent = billboard
end

local function refreshOddityShelf()
	local runtimeFolder = workspace:FindFirstChild("TinyRepairShopRuntime")
	local collection = player:FindFirstChild("OddityCollection")
	if not runtimeFolder or not collection or not collection:IsA("Folder") then
		return
	end

	local oldDisplay = runtimeFolder:FindFirstChild("LocalOddityDisplay")
	if oldDisplay then
		oldDisplay:Destroy()
	end

	local display = Instance.new("Folder")
	display.Name = "LocalOddityDisplay"
	display.Parent = runtimeFolder

	local discoveredCount = 0
	for _, jobId in ODDITY_ORDER do
		if collection:FindFirstChild(jobId) then
			discoveredCount += 1
		end
	end

	if discoveredCount == #ODDITY_ORDER then
		local crown = collectionPart(
			display,
			"CompleteCollectionBadge",
			Vector3.new(2.1, 0.24, 0.8),
			CFrame.new(-12, 8.05, 7.65),
			Color3.fromRGB(190, 155, 71)
		)
		crown.Material = Enum.Material.Metal
		addPlaque(
			display,
			CFrame.new(-12, 7.75, 7.55),
			if localeCode == "ja" then "奇妙な収集 完成" else "COLLECTION COMPLETE",
			true
		)
	end

	for index, jobId in ODDITY_ORDER do
		local slot = runtimeFolder:FindFirstChild("CollectionSlot_" .. tostring(index))
		local job = RepairCatalog.getJob(jobId)
		if slot and slot:IsA("BasePart") and job then
			local discovered = collection:FindFirstChild(jobId) ~= nil
			local base = slot.CFrame
			if discovered then
				local itemModel = Instance.new("Model")
				itemModel.Name = "Oddity_" .. jobId
				itemModel:SetAttribute("JobId", jobId)
				itemModel.Parent = display

				if job.modelKind == "Radio" then
					buildMiniRadio(itemModel, base)
				elseif job.modelKind == "ToyCar" then
					buildMiniToyCar(itemModel, base)
				elseif job.modelKind == "Camera" then
					buildMiniCamera(itemModel, base)
				end

				local lightAnchor = collectionPart(
					itemModel,
					"GlowAnchor",
					Vector3.new(0.12, 0.12, 0.12),
					base * CFrame.new(0, 1.0, 0),
					Color3.fromRGB(173, 137, 196)
				)
				lightAnchor.Transparency = 1
				local glow = Instance.new("PointLight")
				glow.Name = "ShelfGlow"
				glow.Color = Color3.fromRGB(173, 137, 196)
				glow.Brightness = 0.28
				glow.Range = 4.5
				glow.Parent = lightAnchor

				addPlaque(
					display,
					base * CFrame.new(0, 0.05, -1.06),
					Localization.pick(job.name, localeCode),
					true
				)
			else
				buildLockedCuriosity(display, base)
				addPlaque(display, base * CFrame.new(0, 0.05, -1.06), "???", false)
			end
		end
	end
end

local function bindOddityCollection()
	local collection = player:WaitForChild("OddityCollection") :: Folder
	local runtimeFolder = workspace:WaitForChild("TinyRepairShopRuntime")
	for index = 1, #ODDITY_ORDER do
		runtimeFolder:WaitForChild("CollectionSlot_" .. tostring(index))
	end

	collection.ChildAdded:Connect(refreshOddityShelf)
	collection.ChildRemoved:Connect(refreshOddityShelf)
	refreshOddityShelf()
end

local function pulseRadio(model: Model)
	local dial = model:FindFirstChild("Dial", true)
	local glow = model:FindFirstChild("ShelfGlow", true)
	if dial and dial:IsA("BasePart") then
		local original = dial.CFrame
		local turn = TweenService:Create(
			dial,
			TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ CFrame = original * CFrame.Angles(math.rad(80), 0, 0) }
		)
		turn:Play()
		turn.Completed:Wait()
		if dial.Parent then
			TweenService:Create(
				dial,
				TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
				{ CFrame = original }
			):Play()
		end
	end

	if glow and glow:IsA("PointLight") then
		local oldBrightness = glow.Brightness
		glow.Brightness = 1.7
		task.wait(0.12)
		if glow.Parent then
			glow.Brightness = 0.08
			task.wait(0.09)
		end
		if glow.Parent then
			glow.Brightness = 1.1
			task.wait(0.13)
		end
		if glow.Parent then
			glow.Brightness = oldBrightness
		end
	end
end

local function twitchToyCar(model: Model)
	local originals: { [BasePart]: CFrame } = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.Name ~= "GlowAnchor" then
			originals[descendant] = descendant.CFrame
		end
	end

	for part, original in originals do
		TweenService:Create(
			part,
			TweenInfo.new(0.32, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ CFrame = original * CFrame.new(0.55, 0, 0) }
		):Play()
	end
	task.wait(0.38)

	for part, original in originals do
		if part.Parent then
			TweenService:Create(
				part,
				TweenInfo.new(0.48, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ CFrame = original }
			):Play()
		end
	end
end

local function flashCamera(model: Model)
	local flash = model:FindFirstChild("Flash", true)
	if not flash or not flash:IsA("BasePart") then
		return
	end

	local oldColor = flash.Color
	local oldMaterial = flash.Material
	local light = Instance.new("PointLight")
	light.Name = "CameraFlashBurst"
	light.Color = Color3.fromRGB(255, 245, 210)
	light.Brightness = 5
	light.Range = 12
	light.Parent = flash

	flash.Color = Color3.fromRGB(255, 248, 216)
	flash.Material = Enum.Material.Neon
	task.wait(0.12)

	if flash.Parent then
		flash.Color = oldColor
		flash.Material = oldMaterial
	end
	light:Destroy()

	task.wait(0.16)
	if flash.Parent then
		local second = Instance.new("PointLight")
		second.Name = "CameraFlashAfterglow"
		second.Color = Color3.fromRGB(224, 211, 255)
		second.Brightness = 1.4
		second.Range = 6
		second.Parent = flash
		task.wait(0.08)
		second:Destroy()
	end
end

local function triggerOddityAmbient()
	local runtimeFolder = workspace:FindFirstChild("TinyRepairShopRuntime")
	if not runtimeFolder then
		return
	end
	local display = runtimeFolder:FindFirstChild("LocalOddityDisplay")
	if not display then
		return
	end

	local candidates: { Model } = {}
	for _, child in display:GetChildren() do
		if child:IsA("Model") and type(child:GetAttribute("JobId")) == "string" then
			table.insert(candidates, child)
		end
	end
	if #candidates == 0 then
		return
	end

	local model = candidates[ambientRandom:NextInteger(1, #candidates)]
	local jobId = model:GetAttribute("JobId")
	if jobId == "midnight_radio" then
		pulseRadio(model)
	elseif jobId == "laughing_toy_car" then
		twitchToyCar(model)
	elseif jobId == "blank_photo_camera" then
		flashCamera(model)
	end
end

-- Customer job offers. The server decides which jobs are valid; the client only
-- renders the choices and sends the selected slot back.
local offersFrame = Instance.new("Frame")
offersFrame.Name = "JobOffers"
offersFrame.AnchorPoint = Vector2.new(0.5, 0.5)
offersFrame.Size = UDim2.new(0.9, 0, 0, 360)
offersFrame.Position = UDim2.fromScale(0.5, 0.5)
offersFrame.BackgroundColor3 = Color3.fromRGB(34, 39, 37)
offersFrame.BackgroundTransparency = 0.02
offersFrame.Visible = false
offersFrame.Parent = gui
round(offersFrame, 20)
addStroke(offersFrame, 0.72)

local offersConstraint = Instance.new("UISizeConstraint")
offersConstraint.MaxSize = Vector2.new(620, 380)
offersConstraint.MinSize = Vector2.new(300, 340)
offersConstraint.Parent = offersFrame

local offersTitle = makeText(
	offersFrame,
	Localization.text("ChooseRepair", localeCode),
	UDim2.new(1, -70, 0, 32),
	UDim2.fromOffset(18, 14),
	22,
	true
)

local offersHint = makeText(
	offersFrame,
	Localization.text("ChooseRepairHint", localeCode),
	UDim2.new(1, -36, 0, 32),
	UDim2.fromOffset(18, 49),
	14,
	false
)

local closeOffers = Instance.new("TextButton")
closeOffers.Name = "Close"
closeOffers.Size = UDim2.fromOffset(42, 42)
closeOffers.Position = UDim2.new(1, -54, 0, 12)
closeOffers.BackgroundColor3 = Color3.fromRGB(73, 78, 75)
closeOffers.Text = "×"
closeOffers.TextColor3 = Color3.fromRGB(255, 255, 255)
closeOffers.Font = Enum.Font.GothamBold
closeOffers.TextSize = 25
closeOffers.Parent = offersFrame
round(closeOffers, 12)

local offerButtons: { TextButton } = {}
for index = 1, 3 do
	local button = Instance.new("TextButton")
	button.Name = "Offer" .. tostring(index)
	button.Size = UDim2.new(1, -36, 0, 78)
	button.Position = UDim2.fromOffset(18, 84 + (index - 1) * 86)
	button.BackgroundColor3 = Color3.fromRGB(63, 78, 70)
	button.TextColor3 = Color3.fromRGB(248, 245, 235)
	button.Font = Enum.Font.Gotham
	button.TextSize = 15
	button.TextWrapped = true
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.AutoButtonColor = true
	button.Visible = false
	button.Parent = offersFrame
	round(button, 14)
	addStroke(button, 0.84)
	table.insert(offerButtons, button)

	button.Activated:Connect(function()
		if not offersFrame.Visible or not button.Visible then
			return
		end
		offersFrame.Visible = false
		jobOfferChosen:FireServer(index)
	end)
end

closeOffers.Activated:Connect(function()
	offersFrame.Visible = false
end)

jobOffersOpened.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end

	for _, button in offerButtons do
		button.Visible = false
		button.BackgroundColor3 = Color3.fromRGB(63, 78, 70)
	end

	local visibleCount = 0
	for index, offer in payload do
		if index > #offerButtons or type(offer) ~= "table" then
			break
		end

		local job = RepairCatalog.getJob(offer.jobId)
		if job then
			local button = offerButtons[index]
			local rep = if type(offer.reputationReward) == "number" then math.floor(offer.reputationReward) else 0
			local quotedPay = if type(offer.quotedReward) == "number" then math.floor(offer.quotedReward) else 0
			local customer = if type(offer.customerId) == "string" then ShopFlavor.getCustomer(offer.customerId) else nil
			local modifier = if type(offer.modifierId) == "string" then ShopFlavor.getModifier(offer.modifierId) else nil
			local customerName = if customer then Localization.pick(customer.name, localeCode) else "?"
			local isOddity = offer.isOddity == true or job.rareOnly == true
			local modifierName = Localization.text("SpecialOrder", localeCode)
			if isOddity then
				modifierName = "◈ " .. Localization.text("OddJobTag", localeCode)
			elseif modifier then
				modifierName = Localization.pick(modifier.label, localeCode)
			end
			if isOddity then
				button.BackgroundColor3 = Color3.fromRGB(82, 61, 90)
			end
			button.Text = "  👤 " .. customerName .. "  •  " .. modifierName
				.. "\n  🔧 "
				.. Localization.pick(job.name, localeCode)
				.. "\n  "
				.. Localization.text("QuotedPay", localeCode)
				.. ": $"
				.. tostring(quotedPay)
				.. "   •   +"
				.. tostring(rep)
				.. " "
				.. Localization.text("RepShort", localeCode)
			button.Visible = true
			visibleCount += 1
		end
	end

	offersFrame.Visible = visibleCount > 0
end)

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
	offersFrame.Visible = false
	skillFrame.Visible = true
	fixButton.Active = false

	local thisSkill = activeSkill
	local activationDelay = math.max(0, data.startTime - workspace:GetServerTimeNow())
	task.delay(activationDelay, function()
		if activeSkill == thisSkill then
			fixButton.Active = true
		end
	end)

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
	if workspace:GetServerTimeNow() < current.startTime then
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
	local toolLevel = leaderstats:WaitForChild("ToolLevel") :: IntValue
	local streak = leaderstats:WaitForChild("Streak") :: IntValue
	local oddJobs = leaderstats:WaitForChild("OddJobs") :: IntValue

	local function refresh()
		moneyLabel.Text = Localization.text("Money", localeCode) .. ": $" .. tostring(cash.Value)
		reputationLabel.Text = Localization.text("Reputation", localeCode) .. ": " .. tostring(reputation.Value)
		toolLevelLabel.Text = Localization.text("ToolLevel", localeCode) .. ": " .. tostring(toolLevel.Value)
		streakLabel.Text = "🔥 " .. Localization.text("Streak", localeCode) .. ": " .. tostring(streak.Value)
		oddJobsLabel.Text = "◈ " .. Localization.text("OddJobs", localeCode) .. ": " .. tostring(oddJobs.Value)
	end

	cash:GetPropertyChangedSignal("Value"):Connect(refresh)
	reputation:GetPropertyChangedSignal("Value"):Connect(refresh)
	toolLevel:GetPropertyChangedSignal("Value"):Connect(refresh)
	streak:GetPropertyChangedSignal("Value"):Connect(refresh)
	oddJobs:GetPropertyChangedSignal("Value"):Connect(refresh)
	refresh()
end

stateChanged.OnClientEvent:Connect(function(state)
	renderJob(state)
end)

toastEvent.OnClientEvent:Connect(function(key: string, data)
	showToast(key, data)
end)

task.spawn(bindStats)
task.spawn(bindOddityCollection)
task.spawn(function()
	while gui.Parent do
		task.wait(ambientRandom:NextInteger(AMBIENT_MIN_SECONDS, AMBIENT_MAX_SECONDS))
		if gui.Parent and not offersFrame.Visible and not skillFrame.Visible then
			triggerOddityAmbient()
		end
	end
end)
renderJob(nil)
