--!strict
-- Tiny Repair Shop repair content.
-- Add new jobs here without duplicating the repair-state logic in the server.

local RepairCatalog = {}

export type LocalizedText = {
	en: string,
	ja: string,
}

export type RepairStep = {
	id: string,
	actionText: string,
	label: LocalizedText,
	opensItem: boolean?,
}

export type FaultDefinition = {
	id: string,
	label: LocalizedText,
	steps: { RepairStep },
	rewardBonus: number,
}

export type JobDefinition = {
	id: string,
	name: LocalizedText,
	symptom: LocalizedText,
	modelKind: string,
	baseReward: number,
	reputationReward: number,
	minReputation: number,
	faults: { FaultDefinition },
}

local function step(id: string, actionText: string, en: string, ja: string, opensItem: boolean?): RepairStep
	return {
		id = id,
		actionText = actionText,
		label = {
			en = en,
			ja = ja,
		},
		opensItem = opensItem,
	}
end

RepairCatalog.Jobs = {
	{
		id = "desk_fan",
		name = {
			en = "Desk Fan",
			ja = "卓上扇風機",
		},
		symptom = {
			en = "It either rattles or barely moves any air.",
			ja = "ガラガラ音がするか、風がほとんど出ないそうです。",
		},
		modelKind = "Fan",
		baseReward = 55,
		reputationReward = 1,
		minReputation = 0,
		faults = {
			{
				id = "dust_blockage",
				label = {
					en = "Heavy dust buildup",
					ja = "大量のホコリ詰まり",
				},
				rewardBonus = 10,
				steps = {
					step("inspect", "Inspect", "Inspect the fan", "扇風機を点検する"),
					step("remove_guard", "Unscrew", "Remove the front guard", "前面ガードを外す", true),
					step("clean_blades", "Clean", "Clean the blades", "羽根を掃除する"),
					step("clean_vents", "Clean", "Clear the motor vents", "モーターの通気口を掃除する"),
					step("reassemble", "Assemble", "Reassemble the guard", "ガードを組み直す"),
					step("test", "Test", "Switch it on and test it", "電源を入れて動作確認する"),
				},
			},
			{
				id = "loose_blade",
				label = {
					en = "Loose blade cap",
					ja = "羽根固定キャップの緩み",
				},
				rewardBonus = 15,
				steps = {
					step("inspect", "Inspect", "Inspect the fan", "扇風機を点検する"),
					step("remove_guard", "Unscrew", "Remove the front guard", "前面ガードを外す", true),
					step("tighten_cap", "Tighten", "Tighten the blade cap", "羽根の固定キャップを締める"),
					step("check_mount", "Check", "Check the motor mount", "モーター固定部を確認する"),
					step("reassemble", "Assemble", "Reassemble the guard", "ガードを組み直す"),
					step("test", "Test", "Switch it on and test it", "電源を入れて動作確認する"),
				},
			},
		},
	},
	{
		id = "portable_radio",
		name = {
			en = "Portable Radio",
			ja = "ポータブルラジオ",
		},
		symptom = {
			en = "It will not turn on, or the volume crackles badly.",
			ja = "電源が入らないか、音量を変えるとひどい雑音が出るそうです。",
		},
		modelKind = "Radio",
		baseReward = 70,
		reputationReward = 2,
		minReputation = 2,
		faults = {
			{
				id = "dirty_contacts",
				label = {
					en = "Corroded battery contacts",
					ja = "電池端子の汚れ",
				},
				rewardBonus = 10,
				steps = {
					step("inspect", "Inspect", "Inspect the radio", "ラジオを点検する"),
					step("open_case", "Unscrew", "Open the back case", "背面ケースを開ける", true),
					step("clean_contacts", "Clean", "Clean the battery contacts", "電池端子を清掃する"),
					step("replace_batteries", "Replace", "Fit fresh batteries", "新しい電池に交換する"),
					step("close_case", "Assemble", "Close the case", "ケースを閉じる"),
					step("test", "Test", "Tune a station and test it", "放送を合わせて動作確認する"),
				},
			},
			{
				id = "scratchy_volume",
				label = {
					en = "Dirty volume control",
					ja = "音量つまみ内部の汚れ",
				},
				rewardBonus = 20,
				steps = {
					step("inspect", "Inspect", "Inspect the radio", "ラジオを点検する"),
					step("open_case", "Unscrew", "Open the back case", "背面ケースを開ける", true),
					step("clean_control", "Clean", "Clean the volume control", "音量つまみ内部を清掃する"),
					step("reseat_wire", "Repair", "Reseat the loose speaker wire", "スピーカー配線を差し直す"),
					step("close_case", "Assemble", "Close the case", "ケースを閉じる"),
					step("test", "Test", "Tune a station and test it", "放送を合わせて動作確認する"),
				},
			},
		},
	},
	{
		id = "toy_car",
		name = {
			en = "Toy Car",
			ja = "おもちゃの車",
		},
		symptom = {
			en = "It pulls sideways or crawls even with fresh batteries.",
			ja = "まっすぐ走らないか、新しい電池でも遅いそうです。",
		},
		modelKind = "ToyCar",
		baseReward = 85,
		reputationReward = 2,
		minReputation = 5,
		faults = {
			{
				id = "stuck_axle",
				label = {
					en = "Hair wrapped around the axle",
					ja = "車軸への髪の毛の巻き付き",
				},
				rewardBonus = 15,
				steps = {
					step("inspect", "Inspect", "Inspect the toy car", "おもちゃの車を点検する"),
					step("open_chassis", "Unscrew", "Open the chassis", "シャーシを開ける", true),
					step("remove_hair", "Clean", "Remove debris from the axle", "車軸のゴミを取り除く"),
					step("align_axle", "Adjust", "Realign the axle", "車軸を調整する"),
					step("close_chassis", "Assemble", "Close the chassis", "シャーシを閉じる"),
					step("test", "Test", "Run the car across the bench", "作業台で走行テストする"),
				},
			},
			{
				id = "worn_motor",
				label = {
					en = "Worn drive motor",
					ja = "駆動モーターの劣化",
				},
				rewardBonus = 30,
				steps = {
					step("inspect", "Inspect", "Inspect the toy car", "おもちゃの車を点検する"),
					step("open_chassis", "Unscrew", "Open the chassis", "シャーシを開ける", true),
					step("clean_gears", "Clean", "Clean and align the gears", "ギアを清掃して位置を整える"),
					step("replace_motor", "Replace", "Replace the drive motor", "駆動モーターを交換する"),
					step("close_chassis", "Assemble", "Close the chassis", "シャーシを閉じる"),
					step("test", "Test", "Run the car across the bench", "作業台で走行テストする"),
				},
			},
		},
	},
} :: { JobDefinition }

function RepairCatalog.getJob(jobId: string): JobDefinition?
	for _, job in RepairCatalog.Jobs do
		if job.id == jobId then
			return job
		end
	end

	return nil
end

function RepairCatalog.getFault(job: JobDefinition, faultId: string): FaultDefinition?
	for _, fault in job.faults do
		if fault.id == faultId then
			return fault
		end
	end

	return nil
end

function RepairCatalog.getUnlockedJobs(reputation: number): { JobDefinition }
	local unlocked = {}

	for _, job in RepairCatalog.Jobs do
		if reputation >= job.minReputation then
			table.insert(unlocked, job)
		end
	end

	return unlocked
end

return RepairCatalog
