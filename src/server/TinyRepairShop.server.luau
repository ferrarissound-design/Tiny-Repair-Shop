--!strict
-- Tiny Repair Shop
-- Server-authoritative gameplay. Roblox runtime language: Luau.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Lighting = game:GetService("Lighting")

local Shared = ReplicatedStorage:WaitForChild("TinyRepairShopShared")
local RepairCatalog = require(Shared:WaitForChild("RepairCatalog"))

local DATASTORE_NAME = "TinyRepairShopPlayerData_v1"
local SAVE_KEY_PREFIX = "player_"
local RARE_FIND_CHANCE = 0.08
local RARE_FIND_BONUS = 25
local SKILL_TIMEOUT_SECONDS = 9
local PERFECT_REPAIR_BONUS = 20
local GOOD_REPAIR_BONUS = 10
local TOOL_UPGRADE_COSTS = { 150, 400, 900 }
local TOOL_SKILL_WIDTH_BONUS = 0.025

local playerStore = DataStoreService:GetDataStore(DATASTORE_NAME)
local random = Random.new()

type SkillCheckState = {
	stepIndex: number,
	startTime: number,
	speed: number,
	targetStart: number,
	targetEnd: number,
}

type OfferState = {
	jobId: string,
	faultId: string,
}

type JobState = {
	jobId: string,
	faultId: string,
	stepIndex: number,
	faultRevealed: boolean,
	bonus: number,
	mistakes: number,
	itemModel: Model?,
	prompt: ProximityPrompt?,
	pendingSkill: SkillCheckState?,
}

local states: { [Player]: JobState } = {}
local offers: { [Player]: { OfferState } } = {}
local stats: { [Player]: { money: IntValue, reputation: IntValue, toolLevel: IntValue } } = {}

local remotes = ReplicatedStorage:FindFirstChild("TinyRepairShopRemotes") :: Folder?
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "TinyRepairShopRemotes"
	remotes.Parent = ReplicatedStorage
end

local function ensureRemote(name: string): RemoteEvent
	local existing = remotes:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
	return remote
end

local stateChanged = ensureRemote("StateChanged")
local toastEvent = ensureRemote("Toast")
local skillCheckStarted = ensureRemote("SkillCheckStarted")
local skillCheckSubmit = ensureRemote("SkillCheckSubmit")
local jobOffersOpened = ensureRemote("JobOffersOpened")
local jobOfferChosen = ensureRemote("JobOfferChosen")

local runtime = workspace:FindFirstChild("TinyRepairShopRuntime") :: Folder?
if runtime then
	runtime:Destroy()
end

runtime = Instance.new("Folder")
runtime.Name = "TinyRepairShopRuntime"
runtime.Parent = workspace

local function newPart(
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = runtime
	return part
end

local function addSurfaceText(part: BasePart, text: string, face: Enum.NormalId, textColor: Color3?)
	local surface = Instance.new("SurfaceGui")
	surface.Name = "Label"
	surface.Face = face
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 40
	surface.Parent = part

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = textColor or Color3.fromRGB(245, 241, 225)
	label.TextScaled = true
	label.Parent = surface
end

local workbenchTop: Part
local customerPrompt: ProximityPrompt
local toolUpgradePrompt: ProximityPrompt

local function buildWorkshop()
	Lighting.ClockTime = 17.7
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(110, 105, 100)
	Lighting.OutdoorAmbient = Color3.fromRGB(95, 100, 110)

	newPart("Floor", Vector3.new(36, 1, 28), CFrame.new(0, 0, 0), Color3.fromRGB(116, 91, 67), Enum.Material.WoodPlanks)
	newPart("BackWall", Vector3.new(36, 12, 1), CFrame.new(0, 6.5, 13.5), Color3.fromRGB(222, 214, 194), Enum.Material.Plaster)
	newPart("LeftWall", Vector3.new(1, 12, 28), CFrame.new(-17.5, 6.5, 0), Color3.fromRGB(222, 214, 194), Enum.Material.Plaster)
	newPart("RightWall", Vector3.new(1, 12, 28), CFrame.new(17.5, 6.5, 0), Color3.fromRGB(222, 214, 194), Enum.Material.Plaster)
	newPart("FrontHeader", Vector3.new(36, 2, 1), CFrame.new(0, 11.5, -13.5), Color3.fromRGB(70, 62, 54), Enum.Material.Wood)
	newPart("Sidewalk", Vector3.new(44, 1, 10), CFrame.new(0, -0.05, -19), Color3.fromRGB(145, 145, 145), Enum.Material.Concrete)

	local sign = newPart("ShopSign", Vector3.new(14, 3, 0.6), CFrame.new(0, 9.2, -13.1), Color3.fromRGB(56, 68, 62), Enum.Material.Wood)
	addSurfaceText(sign, "TINY REPAIR SHOP", Enum.NormalId.Front)

	local counter = newPart("Counter", Vector3.new(11, 3.5, 2.5), CFrame.new(7.5, 2.25, -8.5), Color3.fromRGB(104, 76, 53), Enum.Material.WoodPlanks)
	newPart("CounterTop", Vector3.new(11.6, 0.35, 3), counter.CFrame * CFrame.new(0, 1.9, 0), Color3.fromRGB(66, 52, 43), Enum.Material.Wood)

	local benchBase = newPart("WorkbenchBase", Vector3.new(11, 3.4, 4.5), CFrame.new(0, 2.2, 4), Color3.fromRGB(89, 68, 49), Enum.Material.WoodPlanks)
	workbenchTop = newPart("WorkbenchTop", Vector3.new(12, 0.45, 5), benchBase.CFrame * CFrame.new(0, 1.9, 0), Color3.fromRGB(65, 54, 45), Enum.Material.Wood)

	local benchLabel = newPart("WorkbenchLabel", Vector3.new(6, 1.3, 0.25), CFrame.new(0, 5.3, 6.35), Color3.fromRGB(57, 71, 65), Enum.Material.Wood)
	addSurfaceText(benchLabel, "WORKBENCH", Enum.NormalId.Front)

	for shelfIndex = 0, 2 do
		newPart("Shelf_" .. tostring(shelfIndex + 1), Vector3.new(8, 0.3, 2), CFrame.new(-12, 2.2 + shelfIndex * 2.1, 8), Color3.fromRGB(93, 71, 49), Enum.Material.Wood)
	end
	newPart("ShelfLeft", Vector3.new(0.4, 6.2, 2), CFrame.new(-15.8, 3.8, 8), Color3.fromRGB(74, 58, 44), Enum.Material.Wood)
	newPart("ShelfRight", Vector3.new(0.4, 6.2, 2), CFrame.new(-8.2, 3.8, 8), Color3.fromRGB(74, 58, 44), Enum.Material.Wood)

	local toolCabinet = newPart(
		"ToolCabinet",
		Vector3.new(5.5, 5.5, 2.2),
		CFrame.new(-12.5, 3.25, -7.5),
		Color3.fromRGB(65, 86, 78),
		Enum.Material.Metal
	)
	local toolCabinetLabel = newPart(
		"ToolCabinetLabel",
		Vector3.new(4.5, 1.15, 0.2),
		CFrame.new(-12.5, 5.2, -8.65),
		Color3.fromRGB(44, 56, 51),
		Enum.Material.Metal
	)
	addSurfaceText(toolCabinetLabel, "TOOL UPGRADES", Enum.NormalId.Front)

	toolUpgradePrompt = Instance.new("ProximityPrompt")
	toolUpgradePrompt.Name = "UpgradeTools"
	toolUpgradePrompt.ActionText = "Upgrade tools"
	toolUpgradePrompt.ObjectText = "Tool Cabinet"
	toolUpgradePrompt.HoldDuration = 0.3
	toolUpgradePrompt.MaxActivationDistance = 9
	toolUpgradePrompt.RequiresLineOfSight = false
	toolUpgradePrompt.KeyboardKeyCode = Enum.KeyCode.E
	toolUpgradePrompt.Parent = toolCabinet

	for i = 1, 5 do
		local tool = newPart(
			"Tool_" .. tostring(i),
			Vector3.new(0.35, 2 + i * 0.15, 0.35),
			CFrame.new(-4 + i * 1.25, 5.1, 12.8) * CFrame.Angles(0, 0, math.rad(25 - i * 7)),
			Color3.fromRGB(185, 91 + i * 12, 55),
			Enum.Material.Metal
		)
		tool.CanCollide = false
	end

	local customerModel = Instance.new("Model")
	customerModel.Name = "Customer"
	customerModel.Parent = runtime

	local customerRoot = Instance.new("Part")
	customerRoot.Name = "HumanoidRootPart"
	customerRoot.Size = Vector3.new(2.2, 3.2, 1.2)
	customerRoot.CFrame = CFrame.new(7.5, 2.1, -11.6)
	customerRoot.Color = Color3.fromRGB(70, 102, 135)
	customerRoot.Anchored = true
	customerRoot.CanCollide = false
	customerRoot.Parent = customerModel

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.8, 1.8, 1.8)
	head.CFrame = customerRoot.CFrame * CFrame.new(0, 2.45, 0)
	head.Color = Color3.fromRGB(230, 190, 155)
	head.Anchored = true
	head.CanCollide = false
	head.Parent = customerModel
	customerModel.PrimaryPart = customerRoot

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NameTag"
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(150, 36)
	billboard.StudsOffset = Vector3.new(0, 3.9, 0)
	billboard.Parent = customerRoot

	local nameText = Instance.new("TextLabel")
	nameText.Size = UDim2.fromScale(1, 1)
	nameText.BackgroundTransparency = 1
	nameText.Font = Enum.Font.GothamBold
	nameText.Text = "CUSTOMER"
	nameText.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameText.TextStrokeTransparency = 0.45
	nameText.TextScaled = true
	nameText.Parent = billboard

	customerPrompt = Instance.new("ProximityPrompt")
	customerPrompt.Name = "TakeRepairJob"
	customerPrompt.ActionText = "Take repair"
	customerPrompt.ObjectText = "Customer"
	customerPrompt.HoldDuration = 0.25
	customerPrompt.MaxActivationDistance = 9
	customerPrompt.RequiresLineOfSight = false
	customerPrompt.KeyboardKeyCode = Enum.KeyCode.E
	customerPrompt.Parent = customerRoot

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "ShopSpawn"
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.CFrame = CFrame.new(-8, 1, -7)
	spawn.Color = Color3.fromRGB(119, 155, 120)
	spawn.Transparency = 0.75
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Neutral = true
	spawn.Parent = runtime
end

local function createVisualPart(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, shape: Enum.PartType?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	if shape then
		part.Shape = shape
	end
	part.Parent = parent
	return part
end

local function buildFan(model: Model): BasePart
	local root = createVisualPart(model, "Base", Vector3.new(3.8, 0.6, 2.4), CFrame.new(), Color3.fromRGB(222, 218, 205))
	createVisualPart(model, "Stem", Vector3.new(0.45, 2.4, 0.45), CFrame.new(0, 1.4, 0.2), Color3.fromRGB(160, 165, 165))
	local housing = createVisualPart(model, "Housing", Vector3.new(0.7, 4.4, 4.4), CFrame.new(0, 3.15, 0.05) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(92, 111, 115), Enum.PartType.Cylinder)
	housing.Transparency = 0.2

	for i = 0, 2 do
		local angle = math.rad(i * 120)
		local blade = createVisualPart(model, "Blade_" .. tostring(i + 1), Vector3.new(1.6, 0.3, 0.55), CFrame.new(0, 3.15, -0.4) * CFrame.Angles(0, 0, angle), Color3.fromRGB(195, 205, 199))
		blade.CFrame = blade.CFrame * CFrame.new(0.7, 0, 0)
	end
	return root
end

local function buildRadio(model: Model): BasePart
	local root = createVisualPart(model, "Body", Vector3.new(5, 2.7, 2.1), CFrame.new(), Color3.fromRGB(61, 74, 72))
	local speaker = createVisualPart(model, "Speaker", Vector3.new(0.35, 1.8, 1.8), CFrame.new(-1.35, 0.1, -1.05) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(35, 39, 39), Enum.PartType.Cylinder)
	speaker.Material = Enum.Material.Metal

	for i = 0, 1 do
		createVisualPart(model, "Dial_" .. tostring(i + 1), Vector3.new(0.35, 0.55, 0.55), CFrame.new(1.15 + i * 0.65, 0.5, -1.1) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(211, 180, 105), Enum.PartType.Cylinder)
	end
	createVisualPart(model, "Handle", Vector3.new(3.2, 0.25, 0.3), CFrame.new(0, 1.65, 0), Color3.fromRGB(45, 50, 49))
	return root
end

local function buildToyCar(model: Model): BasePart
	local root = createVisualPart(model, "Body", Vector3.new(4.5, 1.2, 2.4), CFrame.new(), Color3.fromRGB(193, 69, 57))
	createVisualPart(model, "Cab", Vector3.new(2.2, 1, 2.1), CFrame.new(0.4, 1, 0), Color3.fromRGB(218, 91, 68))
	for xIndex = -1, 1, 2 do
		for zIndex = -1, 1, 2 do
			createVisualPart(model, "Wheel", Vector3.new(0.75, 0.75, 0.5), CFrame.new(xIndex * 1.55, -0.55, zIndex * 1.1) * CFrame.Angles(math.rad(90), 0, 0), Color3.fromRGB(33, 33, 33), Enum.PartType.Cylinder)
		end
	end
	return root
end

local function buildController(model: Model): BasePart
	local root = createVisualPart(model, "Body", Vector3.new(4.6, 1.1, 2.8), CFrame.new(), Color3.fromRGB(64, 67, 75))
	createVisualPart(model, "LeftGrip", Vector3.new(1.25, 2.5, 1.2), CFrame.new(-1.65, -0.65, 0.15) * CFrame.Angles(0, 0, math.rad(-22)), Color3.fromRGB(64, 67, 75))
	createVisualPart(model, "RightGrip", Vector3.new(1.25, 2.5, 1.2), CFrame.new(1.65, -0.65, 0.15) * CFrame.Angles(0, 0, math.rad(22)), Color3.fromRGB(64, 67, 75))
	createVisualPart(model, "LeftStick", Vector3.new(0.6, 0.4, 0.6), CFrame.new(-0.9, 0.75, -0.65), Color3.fromRGB(30, 32, 36), Enum.PartType.Cylinder)
	createVisualPart(model, "RightStick", Vector3.new(0.6, 0.4, 0.6), CFrame.new(0.65, 0.6, -0.65), Color3.fromRGB(30, 32, 36), Enum.PartType.Cylinder)
	for i = 0, 3 do
		local angle = math.rad(i * 90)
		createVisualPart(model, "Button_" .. tostring(i + 1), Vector3.new(0.28, 0.24, 0.28), CFrame.new(1.15 + math.cos(angle) * 0.4, 0.25 + math.sin(angle) * 0.4, -1.45), Color3.fromRGB(205, 205, 205), Enum.PartType.Ball)
	end
	return root
end

local function buildRepairItem(jobId: string, player: Player): (Model?, BasePart?)
	local job = RepairCatalog.getJob(jobId)
	if not job then
		return nil, nil
	end

	local model = Instance.new("Model")
	model.Name = "RepairItem_" .. tostring(player.UserId)
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("JobId", jobId)
	model.Parent = runtime

	local primary: BasePart?
	if job.modelKind == "Fan" then
		primary = buildFan(model)
	elseif job.modelKind == "Radio" then
		primary = buildRadio(model)
	elseif job.modelKind == "ToyCar" then
		primary = buildToyCar(model)
	elseif job.modelKind == "Controller" then
		primary = buildController(model)
	else
		primary = createVisualPart(model, "Item", Vector3.new(3, 2, 2), CFrame.new(), Color3.fromRGB(120, 120, 120))
	end

	if not primary then
		model:Destroy()
		return nil, nil
	end

	model.PrimaryPart = primary
	local slotOffset = ((player.UserId % 3) - 1) * 2.6
	local topY = workbenchTop.Position.Y + workbenchTop.Size.Y * 0.5 + 1.2
	model:PivotTo(CFrame.new(workbenchTop.Position.X + slotOffset, topY, workbenchTop.Position.Z))
	return model, primary
end

local function getStatValue(player: Player, name: string): IntValue?
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return nil
	end
	return leaderstats:FindFirstChild(name) :: IntValue?
end

local function repairQuality(mistakes: number): number
	return math.max(0, 100 - mistakes * 20)
end

local function makePayload(state: JobState?)
	if not state then
		return nil
	end
	local job = RepairCatalog.getJob(state.jobId)
	if not job then
		return nil
	end
	local fault = RepairCatalog.getFault(job, state.faultId)
	if not fault then
		return nil
	end

	return {
		jobId = state.jobId,
		faultId = if state.faultRevealed then state.faultId else nil,
		stepIndex = state.stepIndex,
		totalSteps = #fault.steps,
		faultRevealed = state.faultRevealed,
		bonus = state.bonus,
		mistakes = state.mistakes,
		quality = repairQuality(state.mistakes),
	}
end

local function pushState(player: Player)
	stateChanged:FireClient(player, makePayload(states[player]))
end

local function updatePrompt(player: Player)
	local state = states[player]
	if not state or not state.prompt then
		return
	end
	local job = RepairCatalog.getJob(state.jobId)
	if not job then
		return
	end
	local fault = RepairCatalog.getFault(job, state.faultId)
	if not fault then
		return
	end
	local stepDefinition = fault.steps[state.stepIndex]
	if not stepDefinition then
		state.prompt.Enabled = false
		return
	end

	state.prompt.ActionText = stepDefinition.actionText
	state.prompt.ObjectText = job.name.en
	state.prompt.Enabled = state.pendingSkill == nil
end

local function destroyPlayerItem(player: Player)
	local state = states[player]
	if state and state.itemModel then
		state.itemModel:Destroy()
	end
end

local function qualityBonusFor(mistakes: number): number
	if mistakes == 0 then
		return PERFECT_REPAIR_BONUS
	elseif mistakes == 1 then
		return GOOD_REPAIR_BONUS
	end
	return 0
end

local function finishJob(player: Player, state: JobState)
	local job = RepairCatalog.getJob(state.jobId)
	if not job then
		return
	end
	local fault = RepairCatalog.getFault(job, state.faultId)
	if not fault then
		return
	end

	local qualityBonus = qualityBonusFor(state.mistakes)
	local totalReward = job.baseReward + fault.rewardBonus + state.bonus + qualityBonus
	local moneyValue = getStatValue(player, "Cash")
	local reputationValue = getStatValue(player, "Reputation")

	if moneyValue then
		moneyValue.Value += totalReward
	end
	if reputationValue then
		reputationValue.Value += job.reputationReward
	end

	toastEvent:FireClient(player, "RepairComplete", {
		reward = totalReward,
		quality = repairQuality(state.mistakes),
		qualityBonus = qualityBonus,
	})

	destroyPlayerItem(player)
	states[player] = nil
	pushState(player)
end

local function maybeGrantRareFind(player: Player, state: JobState, stepId: string)
	if state.bonus > 0 then
		return
	end
	local job = RepairCatalog.getJob(state.jobId)
	if not job then
		return
	end
	local fault = RepairCatalog.getFault(job, state.faultId)
	if not fault then
		return
	end
	local currentStep = fault.steps[state.stepIndex]
	if not currentStep or currentStep.id ~= stepId or not currentStep.opensItem then
		return
	end

	if random:NextNumber() <= RARE_FIND_CHANCE then
		state.bonus += RARE_FIND_BONUS
		toastEvent:FireClient(player, "RareFind", { bonus = RARE_FIND_BONUS })
	end
end

local function advanceRepair(player: Player)
	local state = states[player]
	if not state then
		return
	end
	local job = RepairCatalog.getJob(state.jobId)
	if not job then
		return
	end
	local fault = RepairCatalog.getFault(job, state.faultId)
	if not fault then
		return
	end
	local stepDefinition = fault.steps[state.stepIndex]
	if not stepDefinition then
		return
	end

	maybeGrantRareFind(player, state, stepDefinition.id)

	if stepDefinition.id == "inspect" and not state.faultRevealed then
		state.faultRevealed = true
		toastEvent:FireClient(player, "FaultFound", {})
	else
		toastEvent:FireClient(player, "StepComplete", {})
	end

	state.stepIndex += 1
	if state.stepIndex > #fault.steps then
		finishJob(player, state)
		return
	end

	updatePrompt(player)
	pushState(player)
end

local function pointerPosition(startTime: number, speed: number, now: number): number
	local elapsed = math.max(0, now - startTime)
	local phase = (elapsed * speed) % 2
	if phase <= 1 then
		return phase
	end
	return 2 - phase
end

local function beginSkillCheck(player: Player, state: JobState, stepDefinition)
	if state.pendingSkill then
		return
	end

	local toolLevelValue = getStatValue(player, "ToolLevel")
	local toolLevel = if toolLevelValue then toolLevelValue.Value else 0
	local widthBonus = toolLevel * TOOL_SKILL_WIDTH_BONUS
	local width = math.clamp((stepDefinition.skillWidth or 0.24) + widthBonus, 0.12, 0.48)
	local half = width * 0.5
	local center = random:NextNumber(0.22 + half, 0.78 - half)
	local startTime = workspace:GetServerTimeNow() + 0.35
	local pending: SkillCheckState = {
		stepIndex = state.stepIndex,
		startTime = startTime,
		speed = math.clamp(stepDefinition.skillSpeed or 0.8, 0.45, 1.5),
		targetStart = center - half,
		targetEnd = center + half,
	}
	state.pendingSkill = pending

	if state.prompt then
		state.prompt.Enabled = false
	end

	skillCheckStarted:FireClient(player, {
		startTime = pending.startTime,
		speed = pending.speed,
		targetStart = pending.targetStart,
		targetEnd = pending.targetEnd,
		stepIndex = pending.stepIndex,
	})

	task.delay(SKILL_TIMEOUT_SECONDS, function()
		if states[player] ~= state or state.pendingSkill ~= pending then
			return
		end

		state.pendingSkill = nil
		state.mistakes += 1
		updatePrompt(player)
		pushState(player)
		toastEvent:FireClient(player, "SkillCheckExpired", {})
	end)
end

local function connectRepairPrompt(player: Player, state: JobState, primary: BasePart)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RepairStep"
	prompt.ActionText = "Inspect"
	prompt.ObjectText = "Repair item"
	prompt.HoldDuration = 0.45
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = primary
	state.prompt = prompt

	prompt.Triggered:Connect(function(triggeringPlayer: Player)
		if triggeringPlayer ~= player then
			toastEvent:FireClient(triggeringPlayer, "NotYourRepair", {})
			return
		end
		if states[player] ~= state or state.pendingSkill then
			return
		end

		local job = RepairCatalog.getJob(state.jobId)
		if not job then
			return
		end
		local fault = RepairCatalog.getFault(job, state.faultId)
		if not fault then
			return
		end
		local stepDefinition = fault.steps[state.stepIndex]
		if not stepDefinition then
			return
		end

		if stepDefinition.skillCheck then
			beginSkillCheck(player, state, stepDefinition)
		else
			advanceRepair(player)
		end
	end)

	updatePrompt(player)
end

local function startJob(player: Player, jobId: string, faultId: string)
	if states[player] then
		toastEvent:FireClient(player, "AlreadyWorking", {})
		return
	end

	local job = RepairCatalog.getJob(jobId)
	if not job then
		return
	end
	local fault = RepairCatalog.getFault(job, faultId)
	if not fault then
		return
	end

	local reputationValue = getStatValue(player, "Reputation")
	local reputation = if reputationValue then reputationValue.Value else 0
	if reputation < job.minReputation then
		return
	end

	local model, primary = buildRepairItem(job.id, player)
	if not model or not primary then
		return
	end

	local state: JobState = {
		jobId = job.id,
		faultId = fault.id,
		stepIndex = 1,
		faultRevealed = false,
		bonus = 0,
		mistakes = 0,
		itemModel = model,
		prompt = nil,
		pendingSkill = nil,
	}

	offers[player] = nil
	states[player] = state
	connectRepairPrompt(player, state, primary)
	pushState(player)
	toastEvent:FireClient(player, "JobAccepted", {})
end

local function shuffledJobs(jobs)
	local result = {}
	for _, job in jobs do
		table.insert(result, job)
	end

	for index = #result, 2, -1 do
		local swapIndex = random:NextInteger(1, index)
		result[index], result[swapIndex] = result[swapIndex], result[index]
	end

	return result
end

local function presentOffers(player: Player)
	if states[player] then
		toastEvent:FireClient(player, "AlreadyWorking", {})
		return
	end

	local reputationValue = getStatValue(player, "Reputation")
	local reputation = if reputationValue then reputationValue.Value else 0
	local unlockedJobs = RepairCatalog.getUnlockedJobs(reputation)
	if #unlockedJobs == 0 then
		return
	end

	local shuffled = shuffledJobs(unlockedJobs)
	local count = math.min(3, #shuffled)
	local playerOffers: { OfferState } = {}
	local payload = {}

	for index = 1, count do
		local job = shuffled[index]
		local fault = job.faults[random:NextInteger(1, #job.faults)]
		local offer: OfferState = {
			jobId = job.id,
			faultId = fault.id,
		}
		table.insert(playerOffers, offer)
		table.insert(payload, {
			jobId = job.id,
			baseReward = job.baseReward,
			reputationReward = job.reputationReward,
		})
	end

	offers[player] = playerOffers
	jobOffersOpened:FireClient(player, payload)
end

local function loadPlayer(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local money = Instance.new("IntValue")
	money.Name = "Cash"
	money.Value = 0
	money.Parent = leaderstats

	local reputation = Instance.new("IntValue")
	reputation.Name = "Reputation"
	reputation.Value = 0
	reputation.Parent = leaderstats

	local toolLevel = Instance.new("IntValue")
	toolLevel.Name = "ToolLevel"
	toolLevel.Value = 0
	toolLevel.Parent = leaderstats

	stats[player] = { money = money, reputation = reputation, toolLevel = toolLevel }

	local success, data = pcall(function()
		return playerStore:GetAsync(SAVE_KEY_PREFIX .. tostring(player.UserId))
	end)

	if success and type(data) == "table" then
		local savedMoney = data.money
		local savedReputation = data.reputation
		local savedToolLevel = data.toolLevel
		if type(savedMoney) == "number" then
			money.Value = math.max(0, math.floor(savedMoney))
		end
		if type(savedReputation) == "number" then
			reputation.Value = math.max(0, math.floor(savedReputation))
		end
		if type(savedToolLevel) == "number" then
			toolLevel.Value = math.clamp(math.floor(savedToolLevel), 0, #TOOL_UPGRADE_COSTS)
		end
	end

	task.delay(1, function()
		if player.Parent == Players then
			pushState(player)
			toastEvent:FireClient(player, "CustomerReady", {})
		end
	end)
end

local function savePlayer(player: Player)
	local playerStats = stats[player]
	if not playerStats then
		return
	end

	local payload = {
		money = playerStats.money.Value,
		reputation = playerStats.reputation.Value,
		toolLevel = playerStats.toolLevel.Value,
	}

	pcall(function()
		playerStore:SetAsync(SAVE_KEY_PREFIX .. tostring(player.UserId), payload)
	end)
end

buildWorkshop()

customerPrompt.Triggered:Connect(function(player: Player)
	presentOffers(player)
end)

jobOfferChosen.OnServerEvent:Connect(function(player: Player, offerIndex: number)
	if type(offerIndex) ~= "number" then
		return
	end
	if states[player] then
		return
	end

	local playerOffers = offers[player]
	if not playerOffers then
		return
	end

	local index = math.floor(offerIndex)
	local offer = playerOffers[index]
	if not offer then
		return
	end

	startJob(player, offer.jobId, offer.faultId)
end)

toolUpgradePrompt.Triggered:Connect(function(player: Player)
	local cash = getStatValue(player, "Cash")
	local toolLevel = getStatValue(player, "ToolLevel")
	if not cash or not toolLevel then
		return
	end

	if toolLevel.Value >= #TOOL_UPGRADE_COSTS then
		toastEvent:FireClient(player, "UpgradeMax", {})
		return
	end

	local cost = TOOL_UPGRADE_COSTS[toolLevel.Value + 1]
	if cash.Value < cost then
		toastEvent:FireClient(player, "UpgradeNeedCash", { cost = cost })
		return
	end

	cash.Value -= cost
	toolLevel.Value += 1
	toastEvent:FireClient(player, "UpgradePurchased", {
		level = toolLevel.Value,
		cost = cost,
	})
end)

skillCheckSubmit.OnServerEvent:Connect(function(player: Player)
	local state = states[player]
	if not state or not state.pendingSkill then
		return
	end

	local pending = state.pendingSkill
	if pending.stepIndex ~= state.stepIndex then
		state.pendingSkill = nil
		updatePrompt(player)
		return
	end

	local now = workspace:GetServerTimeNow()
	if now < pending.startTime - 0.15 or now > pending.startTime + SKILL_TIMEOUT_SECONDS then
		return
	end

	local position = pointerPosition(pending.startTime, pending.speed, now)
	local success = position >= pending.targetStart and position <= pending.targetEnd
	state.pendingSkill = nil

	if success then
		toastEvent:FireClient(player, "SkillCheckSuccess", {})
		advanceRepair(player)
	else
		state.mistakes += 1
		updatePrompt(player)
		pushState(player)
		toastEvent:FireClient(player, "SkillCheckFail", {})
	end
end)

Players.PlayerAdded:Connect(loadPlayer)

Players.PlayerRemoving:Connect(function(player: Player)
	savePlayer(player)
	destroyPlayerItem(player)
	states[player] = nil
	offers[player] = nil
	stats[player] = nil
end)

for _, player in Players:GetPlayers() do
	task.spawn(loadPlayer, player)
end

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		savePlayer(player)
	end
end)
