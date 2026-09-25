--!strict
-- Tiny Repair Shop
-- Player-facing copy is kept here so the client can switch between English and Japanese.
-- English is the default for broad Roblox compatibility.

local Localization = {}

export type LocalizedText = {
	en: string,
	ja: string,
}

local STRINGS: { [string]: LocalizedText } = {
	Title = { en = "Tiny Repair Shop", ja = "小さな修理工房" },
	Money = { en = "Cash", ja = "お金" },
	Reputation = { en = "Reputation", ja = "評判" },
	Quality = { en = "Quality", ja = "仕上がり" },
	ToolLevel = { en = "Tools Lv.", ja = "工具 Lv." },

	NoJobTitle = { en = "No repair in progress", ja = "修理依頼はありません" },
	NoJobBody = {
		en = "Talk to the customer at the counter to take a job.",
		ja = "カウンターのお客さんに話しかけて、修理を受けてください。",
	},
	HiddenFault = { en = "Fault: ???", ja = "故障原因：？？？" },
	GoToWorkbench = {
		en = "Bring the item to the workbench and inspect it.",
		ja = "作業台で品物を点検してください。",
	},
	JobAccepted = { en = "New repair accepted!", ja = "新しい修理を受けました！" },
	FaultFound = { en = "Fault found!", ja = "故障原因を発見！" },
	StepComplete = { en = "Nice work. Next step unlocked.", ja = "いい感じ。次の作業に進めます。" },
	RepairComplete = { en = "Repair complete!", ja = "修理完了！" },
	RareFind = {
		en = "You found forgotten coins inside! Bonus added.",
		ja = "中から忘れ物のコインを発見！ ボーナス獲得。",
	},
	AlreadyWorking = { en = "Finish your current repair first.", ja = "先に今の修理を終わらせてください。" },
	NotYourRepair = { en = "That repair belongs to another player.", ja = "これは他のプレイヤーの修理品です。" },
	CustomerReady = { en = "A customer is waiting at the counter.", ja = "カウンターでお客さんが待っています。" },
	Reward = { en = "Reward", ja = "報酬" },
	CurrentStep = { en = "Current step", ja = "現在の作業" },
	Symptom = { en = "Customer says", ja = "お客さんの話" },
	Fault = { en = "Fault", ja = "故障原因" },
	StepProgress = { en = "Step %d / %d", ja = "手順 %d / %d" },

	SkillCheckTitle = { en = "Steady hands!", ja = "慎重に作業！" },
	SkillCheckHint = {
		en = "Stop the needle inside the green zone.",
		ja = "針を緑のゾーンで止めてください。",
	},
	SkillCheckButton = { en = "FIX!", ja = "ここ！" },
	SkillCheckSuccess = { en = "Perfect touch!", ja = "うまくいった！" },
	SkillCheckFail = { en = "Missed it. Try that step again.", ja = "少しズレた。もう一度！" },
	SkillCheckExpired = { en = "Too slow. Try that step again.", ja = "時間切れ。もう一度！" },
	QualityBonus = { en = "Quality bonus", ja = "仕上がりボーナス" },
	UpgradePurchased = { en = "Tools upgraded!", ja = "工具をアップグレード！" },
	UpgradeNeedCash = { en = "Not enough cash.", ja = "お金が足りません。" },
	UpgradeMax = { en = "Your tools are already maxed out.", ja = "工具は最大レベルです。" },
	ChooseRepair = { en = "Choose a repair", ja = "修理依頼を選ぶ" },
	ChooseRepairHint = { en = "Pick the job you want to take.", ja = "受けたい修理を選んでください。" },
	BasePay = { en = "Pay", ja = "報酬" },
	RepShort = { en = "Rep", ja = "評判" },
	Close = { en = "Close", ja = "閉じる" },
}

function Localization.getLocaleCode(robloxLocaleId: string?): string
	if robloxLocaleId and string.sub(string.lower(robloxLocaleId), 1, 2) == "ja" then
		return "ja"
	end

	return "en"
end

function Localization.text(key: string, localeCode: string): string
	local entry = STRINGS[key]
	if not entry then
		return key
	end

	if localeCode == "ja" then
		return entry.ja
	end

	return entry.en
end

function Localization.pick(value: LocalizedText, localeCode: string): string
	if localeCode == "ja" then
		return value.ja
	end

	return value.en
end

return Localization
