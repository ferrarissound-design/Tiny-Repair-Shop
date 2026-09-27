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
	story: { LocalizedText },
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
		story = {
			{ en = "First time here. She watches every tool you pick up.", ja = "初来店。使う工具を一つずつ興味深そうに見ている。" },
			{ en = "She remembers your last diagnosis and brought another puzzle.", ja = "前回の故障原因を覚えていて、また別の難題を持ってきた。" },
			{ en = "She now asks what you think before telling you the symptom.", ja = "症状を話す前に、まずあなたの見立てを聞くようになった。" },
			{ en = "She calls this place her favorite tiny laboratory.", ja = "この店を『お気に入りの小さな実験室』と呼んでいる。" },
		},
	},
	{
		id = "grandpa_ken",
		name = { en = "Grandpa Ken", ja = "ケンじい" },
		note = { en = "Keeps old gadgets alive long after stores give up on them.", ja = "店で断られた古い道具も、ずっと大事に使っている。" },
		story = {
			{ en = "He apologizes for bringing something so old.", ja = "『古い物で悪いね』と申し訳なさそうに持ってくる。" },
			{ en = "He says the last repair made his week.", ja = "前回直ったことが、本当に嬉しかったらしい。" },
			{ en = "He has started telling neighbors about your shop.", ja = "近所の人にこの工房を薦めてくれているようだ。" },
			{ en = "He brings tea now. Apparently you are part of his routine.", ja = "最近はお茶まで持ってくる。もう日課の一部らしい。" },
		},
	},
	{
		id = "leo",
		name = { en = "Leo", ja = "レオ" },
		note = { en = "Usually arrives five minutes before he needs the thing.", ja = "だいたい必要になる5分前に持ち込んでくる。" },
		story = {
			{ en = "He is already checking the time before you say hello.", ja = "挨拶する前から時計を見ている。" },
			{ en = "He claims he came early today. He did not.", ja = "今日は早めに来たと言う。全然そんなことはない。" },
			{ en = "He trusts you enough to stop hovering over the bench.", ja = "最近は作業台の横で急かさなくなった。少しは信頼されたらしい。" },
			{ en = "He still arrives late, but now brings snacks as an apology.", ja = "相変わらずギリギリだが、最近はお詫びのお菓子付き。" },
		},
	},
	{
		id = "ms_byte",
		name = { en = "Ms. Byte", ja = "ミス・バイト" },
		note = { en = "Notices tiny flaws and appreciates clean work.", ja = "小さな違和感にも気づく、仕上がり重視のお客さん。" },
		story = {
			{ en = "She inspects the counter before placing the device down.", ja = "品物を置く前に、まずカウンターの状態を確認する。" },
			{ en = "She noticed you cleaned a screw head nobody else would see.", ja = "誰も見ないネジ頭まで綺麗にしたことに気づいていた。" },
			{ en = "She now requests you by name when she has a difficult repair.", ja = "難しい修理は、あなたを指名して持ち込むようになった。" },
			{ en = "A perfect repair from you is now her reference standard.", ja = "あなたの仕上がりが、彼女の中で基準になっている。" },
		},
	},
	{
		id = "collector_k",
		name = { en = "Collector K", ja = "コレクターK" },
		note = { en = "Brings in odd little treasures with mysterious histories.", ja = "妙な来歴のある小物を持ち込む謎のコレクター。" },
		story = {
			{ en = "He refuses to explain where he found it.", ja = "どこで手に入れたのかは、どうしても教えてくれない。" },
			{ en = "He seems pleased that the strange jobs do not scare you off.", ja = "妙な依頼でも断らないあなたを、気に入ったらしい。" },
			{ en = "He has started bringing items wrapped before sunset.", ja = "最近は日が落ちる前に、包んだ品物を持ってくる。" },
			{ en = "He says the shelf is 'looking correct now.' Whatever that means.", ja = "棚を見て『ようやく正しくなってきた』と言った。意味は不明。" },
		},
	},
	{
		id = "night_courier",
		name = { en = "Night Courier", ja = "夜便の配達員" },
		note = { en = "Drops off battered gear between deliveries.", ja = "配達の合間に、使い込んだ道具を持ち込んでくる。" },
		story = {
			{ en = "Helmet still on, engine probably still running outside.", ja = "ヘルメットを被ったまま。外ではまだエンジン音がしていそうだ。" },
			{ en = "They know exactly how long your repairs usually take now.", ja = "あなたの修理時間を完全に把握している。" },
			{ en = "They sometimes leave a second package with no return address.", ja = "最近、返送先のない荷物をもう一つ置いていくことがある。" },
			{ en = "They nod at the Curiosities shelf but never ask about it.", ja = "奇妙な棚を見て頷く。でも、そのことには一度も触れない。" },
		},
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
	{
		id = "oddity",
		label = { en = "Odd Job", ja = "怪しい依頼" },
		note = { en = "Nobody agrees on what happened. The shop only agrees the payout is good.", ja = "何が起きたのか誰も説明できない。ただし報酬だけは妙にいい。" },
		rewardMultiplier = 1.35,
		skillWidthMultiplier = 0.90,
		skillSpeedMultiplier = 1.08,
		perfectBonus = 35,
		weight = 0,
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

function ShopFlavor.getCustomerStory(customerId: string, tier: number): LocalizedText?
	local customer = ShopFlavor.getCustomer(customerId)
	if not customer then
		return nil
	end
	local index = math.clamp(math.floor(tier) + 1, 1, #customer.story)
	return customer.story[index]
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
