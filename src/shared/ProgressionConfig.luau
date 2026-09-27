--!strict
-- Shared long-term progression rules for Tiny Repair Shop.

local ProgressionConfig = {}

ProgressionConfig.REPAIRS_PER_SHIFT = 5

ProgressionConfig.ShopUpgradeCosts = {
	600,
	1600,
	3500,
}

ProgressionConfig.ShopLevelNames = {
	{ en = "Starter Workshop", ja = "駆け出し工房" },
	{ en = "Cozy Workshop", ja = "居心地のいい工房" },
	{ en = "Trusted Workshop", ja = "評判の工房" },
	{ en = "Master Workshop", ja = "名工の工房" },
}

function ProgressionConfig.getShiftBonus(
	perfectRepairs: number,
	qualityTotal: number,
	repairsCompleted: number,
	shopLevel: number
): (number, number)
	local count = math.max(1, repairsCompleted)
	local averageQuality = math.floor(qualityTotal / count + 0.5)
	local qualityBonus = 0
	if averageQuality >= 95 then
		qualityBonus = 80
	elseif averageQuality >= 88 then
		qualityBonus = 45
	elseif averageQuality >= 78 then
		qualityBonus = 20
	end

	local base = 75 + math.max(0, perfectRepairs) * 20 + qualityBonus
	local multiplier = 1 + math.clamp(shopLevel, 0, #ProgressionConfig.ShopUpgradeCosts) * 0.10
	return math.floor(base * multiplier + 0.5), averageQuality
end

function ProgressionConfig.getRelationshipTier(visits: number): number
	if visits >= 12 then
		return 3
	elseif visits >= 5 then
		return 2
	elseif visits >= 2 then
		return 1
	end
	return 0
end

return ProgressionConfig
