--!strict
-- Tiny Repair Shop repair content.
-- New jobs and repair actions belong here so the server can stay generic.

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
	skillCheck: boolean?,
	skillWidth: number?,
	skillSpeed: number?,
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
	rareOnly: boolean?,
	specialTag: LocalizedText?,
	faults: { FaultDefinition },
}

local function step(
	id: string,
	actionText: string,
	en: string,
	ja: string,
	opensItem: boolean?,
	skillCheck: boolean?,
	skillWidth: number?,
	skillSpeed: number?
): RepairStep
	return {
		id = id,
		actionText = actionText,
		label = { en = en, ja = ja },
		opensItem = opensItem,
		skillCheck = skillCheck,
		skillWidth = skillWidth,
		skillSpeed = skillSpeed,
	}
end

local function action(
	id: string,
	actionText: string,
	en: string,
	ja: string,
	opensItem: boolean?,
	width: number?,
	speed: number?
): RepairStep
	return step(id, actionText, en, ja, opensItem, true, width or 0.24, speed or 0.75)
end

RepairCatalog.Jobs = {
	{
		id = "desk_fan",
		name = { en = "Desk Fan", ja = "卓上扇風機" },
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
				label = { en = "Heavy dust buildup", ja = "大量のホコリ詰まり" },
				rewardBonus = 10,
				steps = {
					step("inspect", "Inspect", "Inspect the fan", "扇風機を点検する"),
					action("remove_guard", "Unscrew", "Remove the front guard", "前面ガードを外す", true, 0.28, 0.65),
					action("clean_blades", "Clean", "Clean the blades", "羽根を掃除する", nil, 0.30, 0.72),
					action("clean_vents", "Clean", "Clear the motor vents", "モーターの通気口を掃除する", nil, 0.27, 0.78),
					action("reassemble", "Assemble", "Reassemble the guard", "ガードを組み直す", nil, 0.24, 0.82),
					step("test", "Test", "Switch it on and test it", "電源を入れて動作確認する"),
				},
			},
			{
				id = "loose_blade",
				label = { en = "Loose blade cap", ja = "羽根固定キャップの緩み" },
				rewardBonus = 15,
				steps = {
					step("inspect", "Inspect", "Inspect the fan", "扇風機を点検する"),
					action("remove_guard", "Unscrew", "Remove the front guard", "前面ガードを外す", true, 0.28, 0.65),
					action("tighten_cap", "Tighten", "Tighten the blade cap", "羽根の固定キャップを締める", nil, 0.22, 0.88),
					action("check_mount", "Check", "Check the motor mount", "モーター固定部を確認する", nil, 0.25, 0.82),
					action("reassemble", "Assemble", "Reassemble the guard", "ガードを組み直す", nil, 0.24, 0.84),
					step("test", "Test", "Switch it on and test it", "電源を入れて動作確認する"),
				},
			},
		},
	},
	{
		id = "portable_radio",
		name = { en = "Portable Radio", ja = "ポータブルラジオ" },
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
				label = { en = "Corroded battery contacts", ja = "電池端子の汚れ" },
				rewardBonus = 10,
				steps = {
					step("inspect", "Inspect", "Inspect the radio", "ラジオを点検する"),
					action("open_case", "Unscrew", "Open the back case", "背面ケースを開ける", true, 0.24, 0.80),
					action("clean_contacts", "Clean", "Clean the battery contacts", "電池端子を清掃する", nil, 0.23, 0.85),
					action("replace_batteries", "Replace", "Fit fresh batteries", "新しい電池に交換する", nil, 0.25, 0.82),
					action("close_case", "Assemble", "Close the case", "ケースを閉じる", nil, 0.22, 0.90),
					step("test", "Test", "Tune a station and test it", "放送を合わせて動作確認する"),
				},
			},
			{
				id = "scratchy_volume",
				label = { en = "Dirty volume control", ja = "音量つまみ内部の汚れ" },
				rewardBonus = 20,
				steps = {
					step("inspect", "Inspect", "Inspect the radio", "ラジオを点検する"),
					action("open_case", "Unscrew", "Open the back case", "背面ケースを開ける", true, 0.24, 0.80),
					action("clean_control", "Clean", "Clean the volume control", "音量つまみ内部を清掃する", nil, 0.21, 0.92),
					action("reseat_wire", "Repair", "Reseat the loose speaker wire", "スピーカー配線を差し直す", nil, 0.20, 0.98),
					action("close_case", "Assemble", "Close the case", "ケースを閉じる", nil, 0.22, 0.90),
					step("test", "Test", "Tune a station and test it", "放送を合わせて動作確認する"),
				},
			},
		},
	},
	{
		id = "toy_car",
		name = { en = "Toy Car", ja = "おもちゃの車" },
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
				label = { en = "Hair wrapped around the axle", ja = "車軸への髪の毛の巻き付き" },
				rewardBonus = 15,
				steps = {
					step("inspect", "Inspect", "Inspect the toy car", "おもちゃの車を点検する"),
					action("open_chassis", "Unscrew", "Open the chassis", "シャーシを開ける", true, 0.22, 0.88),
					action("remove_hair", "Clean", "Remove debris from the axle", "車軸のゴミを取り除く", nil, 0.21, 0.95),
					action("align_axle", "Adjust", "Realign the axle", "車軸を調整する", nil, 0.19, 1.02),
					action("close_chassis", "Assemble", "Close the chassis", "シャーシを閉じる", nil, 0.20, 0.98),
					step("test", "Test", "Run the car across the bench", "作業台で走行テストする"),
				},
			},
			{
				id = "worn_motor",
				label = { en = "Worn drive motor", ja = "駆動モーターの劣化" },
				rewardBonus = 30,
				steps = {
					step("inspect", "Inspect", "Inspect the toy car", "おもちゃの車を点検する"),
					action("open_chassis", "Unscrew", "Open the chassis", "シャーシを開ける", true, 0.22, 0.88),
					action("clean_gears", "Clean", "Clean and align the gears", "ギアを清掃して位置を整える", nil, 0.20, 1.00),
					action("replace_motor", "Replace", "Replace the drive motor", "駆動モーターを交換する", nil, 0.17, 1.08),
					action("close_chassis", "Assemble", "Close the chassis", "シャーシを閉じる", nil, 0.19, 1.02),
					step("test", "Test", "Run the car across the bench", "作業台で走行テストする"),
				},
			},
		},
	},
	{
		id = "game_controller",
		name = { en = "Game Controller", ja = "ゲームコントローラー" },
		symptom = {
			en = "One button sticks and the left stick drifts on its own.",
			ja = "ボタンが引っかかり、左スティックが勝手に動くそうです。",
		},
		modelKind = "Controller",
		baseReward = 110,
		reputationReward = 3,
		minReputation = 9,
		faults = {
			{
				id = "sticky_button",
				label = { en = "Sticky button membrane", ja = "ボタン内部の汚れ" },
				rewardBonus = 25,
				steps = {
					step("inspect", "Inspect", "Inspect the controller", "コントローラーを点検する"),
					action("open_shell", "Unscrew", "Open the controller shell", "外装を開ける", true, 0.20, 1.02),
					action("clean_membrane", "Clean", "Clean the button membrane", "ボタンのゴム接点を清掃する", nil, 0.19, 1.05),
					action("seat_buttons", "Assemble", "Seat the buttons correctly", "ボタンを正しく戻す", nil, 0.18, 1.10),
					action("close_shell", "Assemble", "Close the controller shell", "外装を閉じる", nil, 0.18, 1.08),
					step("test", "Test", "Run the input test", "入力テストをする"),
				},
			},
			{
				id = "stick_drift",
				label = { en = "Dirty analog stick sensor", ja = "アナログスティックセンサーの汚れ" },
				rewardBonus = 35,
				steps = {
					step("inspect", "Inspect", "Inspect the controller", "コントローラーを点検する"),
					action("open_shell", "Unscrew", "Open the controller shell", "外装を開ける", true, 0.20, 1.02),
					action("clean_sensor", "Clean", "Clean the analog sensor", "アナログセンサーを清掃する", nil, 0.17, 1.12),
					action("calibrate_stick", "Adjust", "Center and calibrate the stick", "スティックを調整する", nil, 0.16, 1.16),
					action("close_shell", "Assemble", "Close the controller shell", "外装を閉じる", nil, 0.18, 1.10),
					step("test", "Test", "Run the input test", "入力テストをする"),
				},
			},
		},
	},
	{
		id = "alarm_clock",
		name = { en = "Alarm Clock", ja = "目覚まし時計" },
		symptom = {
			en = "It loses time overnight or the alarm only gives a tiny click.",
			ja = "一晩で時間がズレるか、アラームが小さくカチッと鳴るだけだそうです。",
		},
		modelKind = "AlarmClock",
		baseReward = 125,
		reputationReward = 3,
		minReputation = 13,
		faults = {
			{
				id = "slipping_gear",
				label = { en = "Slipping clock gear", ja = "時計ギアの空回り" },
				rewardBonus = 30,
				steps = {
					step("inspect", "Inspect", "Inspect the clock", "時計を点検する"),
					action("open_clock", "Unscrew", "Open the rear cover", "背面カバーを開ける", true, 0.19, 1.08),
					action("clean_gears", "Clean", "Clean the gear train", "ギアを清掃する", nil, 0.18, 1.12),
					action("seat_gear", "Adjust", "Seat the slipping gear", "空回りするギアを調整する", nil, 0.16, 1.18),
					action("close_clock", "Assemble", "Close the rear cover", "背面カバーを閉じる", nil, 0.18, 1.12),
					step("test", "Test", "Run a fast time test", "早送りで時刻テストをする"),
				},
			},
			{
				id = "alarm_contact",
				label = { en = "Bent alarm contact", ja = "アラーム接点の曲がり" },
				rewardBonus = 40,
				steps = {
					step("inspect", "Inspect", "Inspect the clock", "時計を点検する"),
					action("open_clock", "Unscrew", "Open the rear cover", "背面カバーを開ける", true, 0.19, 1.08),
					action("clean_contact", "Clean", "Clean the alarm contact", "アラーム接点を清掃する", nil, 0.17, 1.16),
					action("bend_contact", "Adjust", "Realign the alarm contact", "アラーム接点を調整する", nil, 0.15, 1.23),
					action("close_clock", "Assemble", "Close the rear cover", "背面カバーを閉じる", nil, 0.17, 1.16),
					step("test", "Test", "Trigger the alarm test", "アラームを鳴らして確認する"),
				},
			},
		},
	},
	{
		id = "instant_camera",
		name = { en = "Instant Camera", ja = "インスタントカメラ" },
		symptom = {
			en = "Photos jam halfway out, or the flash refuses to charge.",
			ja = "写真が途中で詰まるか、フラッシュが充電されないそうです。",
		},
		modelKind = "Camera",
		baseReward = 155,
		reputationReward = 4,
		minReputation = 18,
		faults = {
			{
				id = "jammed_rollers",
				label = { en = "Dirty eject rollers", ja = "排出ローラーの汚れ" },
				rewardBonus = 40,
				steps = {
					step("inspect", "Inspect", "Inspect the camera", "カメラを点検する"),
					action("open_camera", "Unscrew", "Open the film door assembly", "フィルム扉まわりを開ける", true, 0.17, 1.16),
					action("clean_rollers", "Clean", "Clean the eject rollers", "排出ローラーを清掃する", nil, 0.16, 1.22),
					action("align_rollers", "Adjust", "Align the roller pressure", "ローラー圧を調整する", nil, 0.14, 1.28),
					action("close_camera", "Assemble", "Close the film door", "フィルム扉を閉じる", nil, 0.16, 1.20),
					step("test", "Test", "Eject a test card", "テストカードを排出する"),
				},
			},
			{
				id = "flash_contact",
				label = { en = "Loose flash contact", ja = "フラッシュ接点の緩み" },
				rewardBonus = 55,
				steps = {
					step("inspect", "Inspect", "Inspect the camera", "カメラを点検する"),
					action("open_camera", "Unscrew", "Open the top shell", "上部カバーを開ける", true, 0.17, 1.18),
					action("clean_contact", "Clean", "Clean the flash contact", "フラッシュ接点を清掃する", nil, 0.15, 1.25),
					action("reseat_flash", "Repair", "Reseat the flash connector", "フラッシュ端子を差し直す", nil, 0.13, 1.32),
					action("close_camera", "Assemble", "Close the top shell", "上部カバーを閉じる", nil, 0.15, 1.24),
					step("test", "Test", "Charge and fire the flash", "フラッシュを充電して発光確認する"),
				},
			},
		},
	},
	{
		id = "midnight_radio",
		name = { en = "Midnight Radio", ja = "真夜中のラジオ" },
		symptom = {
			en = "It tunes itself to the same station at 3:13 AM. The owner removed the batteries. It kept playing.",
			ja = "午前3:13になると勝手に同じ局へ合うそうです。電池を抜いても、鳴り続けたとか。",
		},
		modelKind = "Radio",
		baseReward = 180,
		reputationReward = 4,
		minReputation = 5,
		rareOnly = true,
		specialTag = { en = "ODD JOB", ja = "怪しい依頼" },
		faults = {
			{
				id = "phantom_tuner",
				label = { en = "Tuner contact looping the scan circuit", ja = "選局回路をループさせる接点不良" },
				rewardBonus = 60,
				steps = {
					step("inspect", "Inspect", "Listen for the impossible station", "ありえない放送を確認する"),
					action("open_case", "Unscrew", "Open the radio case", "ラジオのケースを開ける", true, 0.18, 1.08),
					action("clean_tuner", "Clean", "Clean the tuner contacts", "選局接点を清掃する", nil, 0.16, 1.18),
					action("isolate_loop", "Repair", "Isolate the looping scan contact", "ループしている接点を修正する", nil, 0.14, 1.26),
					action("close_case", "Assemble", "Close the case", "ケースを閉じる", nil, 0.16, 1.20),
					step("test", "Test", "Leave it silent for ten seconds", "10秒間、沈黙するか確認する"),
				},
			},
		},
	},
	{
		id = "laughing_toy_car",
		name = { en = "Laughing Toy Car", ja = "笑うおもちゃの車" },
		symptom = {
			en = "It rolls toward closed doors and laughs when it reaches them. Nobody remembers it having a speaker.",
			ja = "閉じたドアへ勝手に走り、着くと笑うそうです。持ち主は『スピーカーなんて無かった』と言っています。",
		},
		modelKind = "ToyCar",
		baseReward = 205,
		reputationReward = 4,
		minReputation = 9,
		rareOnly = true,
		specialTag = { en = "ODD JOB", ja = "怪しい依頼" },
		faults = {
			{
				id = "hidden_sound_board",
				label = { en = "Hidden sound board wired into the motor trigger", ja = "モーター連動の隠し音声基板" },
				rewardBonus = 70,
				steps = {
					step("inspect", "Inspect", "Inspect the toy without turning your back on it", "背を向けずに、おもちゃを点検する"),
					action("open_chassis", "Unscrew", "Open the chassis", "シャーシを開ける", true, 0.17, 1.14),
					action("trace_wire", "Check", "Trace the extra wire", "見覚えのない配線をたどる", nil, 0.15, 1.22),
					action("disconnect_board", "Repair", "Disconnect the hidden sound board", "隠し音声基板を切り離す", nil, 0.13, 1.30),
					action("align_axle", "Adjust", "Realign the steering axle", "操舵車軸を調整する", nil, 0.14, 1.26),
					action("close_chassis", "Assemble", "Close the chassis", "シャーシを閉じる", nil, 0.15, 1.24),
					step("test", "Test", "Point it away from the door and test it", "ドアと反対へ向けて走行テストする"),
				},
			},
		},
	},
	{
		id = "blank_photo_camera",
		name = { en = "Blank Photo Camera", ja = "空白を写すカメラ" },
		symptom = {
			en = "Every photo is almost blank, except for a dark figure the photographer says was never there.",
			ja = "写真はほぼ真っ白。ただし、撮った覚えのない黒い人影だけが毎回残るそうです。",
		},
		modelKind = "Camera",
		baseReward = 245,
		reputationReward = 5,
		minReputation = 18,
		rareOnly = true,
		specialTag = { en = "ODD JOB", ja = "怪しい依頼" },
		faults = {
			{
				id = "light_leak_shadow",
				label = { en = "Severe film-door light leak and dirty roller edge", ja = "フィルム扉の光漏れとローラー端の汚れ" },
				rewardBonus = 90,
				steps = {
					step("inspect", "Inspect", "Inspect the last impossible photo", "最後の妙な写真を確認する"),
					action("open_camera", "Unscrew", "Open the film door assembly", "フィルム扉まわりを開ける", true, 0.15, 1.20),
					action("clean_rollers", "Clean", "Clean the roller edges", "ローラー端を清掃する", nil, 0.14, 1.28),
					action("replace_seal", "Replace", "Replace the damaged light seal", "傷んだ遮光材を交換する", nil, 0.12, 1.34),
					action("align_door", "Adjust", "Align the film door pressure", "フィルム扉の圧を調整する", nil, 0.12, 1.36),
					action("close_camera", "Assemble", "Close the camera", "カメラを閉じる", nil, 0.14, 1.30),
					step("test", "Test", "Take one photo of the empty workbench", "誰もいない作業台を1枚撮る"),
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
		if not job.rareOnly and reputation >= job.minReputation then
			table.insert(unlocked, job)
		end
	end
	return unlocked
end

function RepairCatalog.getUnlockedOddJobs(reputation: number): { JobDefinition }
	local unlocked = {}
	for _, job in RepairCatalog.Jobs do
		if job.rareOnly and reputation >= job.minReputation then
			table.insert(unlocked, job)
		end
	end
	return unlocked
end

return RepairCatalog
