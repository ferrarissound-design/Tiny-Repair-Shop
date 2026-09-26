--!strict
-- Tiny Repair Shop
-- Customer personalities and special-order modifiers.
-- This stays shared so the server owns the rules while the client can render the same flavor text.

local ShopFlavor = {}

export type LocalizedText = {
	en: string,
	ja: string,
}

export type CustomerProfile = {
	id: string,
	name: LocalizedText,
	note: LocalizedText,
}

export type JobModifier = {
	id: string,
	label: LocalizedText,
	note: LocalizedText,
	rewardMultiplier: number,
	skillWidthMultiplier: number,
	skillSpeedMultiplier: number,
	perfectBonus: number,
	weight: number,
}

ShopFlavor.Customers = {
	{
		id = "mika",
		name = { en = "Mika", ja = "ミカ" },
		note = { en = "Careful, curious, and always asks what actually broke.", ja = "故障の原因まで知りたがる、好奇心旺盛なお客さん。" },
	},
	{
		id = "grandpa_ken",
		name = { en = "Grandpa Ken", ja = "ケンじい" },
		note = { en = "Keeps old gadgets alive long after stores give up on them.", ja = "店で断られた古い道具も、ずっと大事に使っている。" },
	},
	{
		id = "leo",
		name = { en = "Leo", ja = "レオ" },
		note = { en = "Usually arrives five minutes before he needs the thing.", ja = "だいたい必要になる5分前に持ち込んでくる。" },
	},
	{
		id = "ms_byte",
		name = { en = "Ms. Byte", ja = "ミス・バイト" },
		note = { en = "Notices tiny flaws and appreciates clean work.", ja = "小さな違和感にも気づく、仕上がり重視のお客さん。" },
	},
	{
		id = "collector_k",
		name = { en = "Collector K", ja = "コレクターK" },
		note = { en = "Brings in odd little treasures with mysterious histories.", ja = "妙な来歴のある小物を持ち込む謎のコレクター。" },
	},
	{
		id = "night_courier",
		name = { en = "Night Courier", ja = "夜便の配達員" },
		note = { en = "Drops off battered gear between deliveries.", ja = "配達の合間に、使い込んだ道具を持ち込んでくる。" },
	},
} :: { CustomerProfile }

ShopFlavor.Modifiers = {
	{
		id = "standard",
		label = { en = "Regular Repair", ja = "通常修理" },
		note = { en = "A straightforward repair. Good hands are enough.", ja = "いつもの修理。落ち着いて直せば大丈夫。" },
		rewardMultiplier = 1.0,
		skillWidthMultiplier = 1.0,
		skillSpeedMultiplier = 1.0,
		perfectBonus = 0,
		weight = 48,
	},
	{
		id = "rush",
		label = { en = "Rush Job", ja = "お急ぎ修理" },
		note = { en = "The customer needs it soon. Faster timing, better pay.", ja = "急ぎの依頼。タイミングは速いが、報酬も高い。" },
		rewardMultiplier = 1.22,
		skillWidthMultiplier = 0.96,
		skillSpeedMultiplier = 1.12,
		perfectBonus = 5,
		weight = 22,
	},
	{
		id = "keepsake",
		label = { en = "Precious Keepsake", ja = "思い出の品" },
		note = { en = "It means more than money to the owner. Perfect work earns extra.", ja = "持ち主にとって特別な品。完璧に直すと追加報酬。" },
		rewardMultiplier = 1.32,
		skillWidthMultiplier = 1.0,
		skillSpeedMultiplier = 1.02,
		perfectBonus = 20,
		weight = 18,
	},
	{
		id = "precision",
		label = { en = "Precision Order", ja = "精密依頼" },
		note = { en = "Tighter tolerances, sharper timing, premium payout.", ja = "判定が厳しい上級依頼。そのぶん報酬は大きい。" },
		rewardMultiplier = 1.48,
		skillWidthMultiplier = 0.82,
		skillSpeedMultiplier = 1.08,
		perfectBonus = 35,
		weight = 12,
	},
} :: { JobModifier }

local function findById(list: { any }, id: string): any?
	for _, entry in list do
		if entry.id == id then
			return entry
		end
	end
	return nil
end

function ShopFlavor.getCustomer(customerId: string): CustomerProfile?
	return findById(ShopFlavor.Customers, customerId)
end

function ShopFlavor.getModifier(modifierId: string): JobModifier?
	return findById(ShopFlavor.Modifiers, modifierId)
end

function ShopFlavor.pickCustomer(rng: Random): CustomerProfile
	return ShopFlavor.Customers[rng:NextInteger(1, #ShopFlavor.Customers)]
end

function ShopFlavor.pickModifier(rng: Random): JobModifier
	local totalWeight = 0
	for _, modifier in ShopFlavor.Modifiers do
		totalWeight += modifier.weight
	end

	local roll = rng:NextNumber(0, totalWeight)
	local cursor = 0
	for _, modifier in ShopFlavor.Modifiers do
		cursor += modifier.weight
		if roll <= cursor then
			return modifier
		end
	end

	return ShopFlavor.Modifiers[1]
end

return ShopFlavor
