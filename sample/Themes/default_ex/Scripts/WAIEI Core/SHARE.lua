-- Share

-- Twitterスコア連携用URL
local sendUrl = 'https://sm.waiei.net/systems/score'

local defaultCodes = {
	Share = {'Share', 'Share2'},
}

--[[
	テーブル内に指定した値があるかチェック
	@param	string	search	検索文字
	@param	table		tableData	検索対象のテーブル
--]]
local function inTable(search, tableData)
	for value in ivalues(tableData) do
		if value == search then
			return true
		end
	end
	return false
end

--[[
	バイナリを含む文字列を %00x 表記に変換する
	@param	string	str	対象の文字列
--]]
local function createUrl(str)
	local strUrl = ''
	for i=1,string.len(str) do
		local strByte=string.byte(str,i)
		strUrl = strUrl..'%'..string.format("%02x",strByte)
	end;
	return strUrl
end;


--[[
	エラーチェックと値の取得
--]]
local function validateAndGetValues(player, datetimeTable)
    local playerName = PROFILEMAN:GetPlayerName(player);
    if not pname or pname == '' then
		-- Profile設定必須
		return {Error = 'name'}
	end
	
	if GAMESTATE:IsCourseMode() then
		-- コースモードは許可されていない
		return {Error = 'course'}
	end
	
	local song = GAMESTATE:GetCurrentSong();
	if not song then
		-- 楽曲が取得できない
		return {Error = 'song'}
	end
	
	local ss  = STATSMAN:GetCurStageStats()
	local pss = ss:GetPlayerStageStats(player)
	local ps  = GAMESTATE:GetPlayerState(player)
	local st  = GAMESTATE:GetCurrentSteps(player)
	local pr  = PROFILEMAN:GetProfile(player)
	
	-- テーマ関係なく取得可能な値
	local folder = YA_GROUP:FolderName(song)
	local group = song:GetGroupName()
	local ini = YA_GROUP:Open(group)
	local iniColor     = ini and ini:Parameter('menucolor') or '1.0,1.0,1.0,1.0'
	local iniMeterType = ini and ini:Parameter('metertype') or 'DDR'
	local iniOriginal  = ini and ini:Parameter('originalname') or ''
	local packageName  = ini and ini:Parameter('name') or group
	if ini then
		ini:Close()
	end
	if packageName == '' then
		packageName = group
	end
	
	local menuColor     = YA_GROUP:Value(iniColor, folder)
	if menuColor == '' then
		menuColor = '1.0,1.0,1.0,1.0'
	end
	local meterType = YA_GROUP:Value(iniMeterType, folder)
	if meterType == '' then
		meterType = 'DDR'
	end
	local original  = YA_GROUP:Value(iniOriginal, folder)
	local checkGrade      = pss:GetGrade()
	local checkMinCombo   = THEME:GetMetric('Gameplay', 'MinScoreToContinueCombo') or 'TapNoteScore_W3'
	local checkDancePoint = pss:GetPercentDancePoints() * 100;
	local style      = GAMESTATE:GetCurrentGame():GetName()
	local mode       = GAMESTATE:GetCurrentStyle():GetName()
	local timing     = GetTimingDifficulty()
	local life       = GetLifeDifficulty()
	local playerName = PROFILEMAN:GetPlayerName(player)
	local guid       = pr:GetGUID()
	local title      = song:GetDisplayFullTitle()
	local artist     = song:GetDisplayArtist()
	-- テーマ名
	local theme = THEME:GetCurThemeName()
	
	-- テーマによっては取得用の関数が必要
	local checkJudgeLabel = 'StepMania'
	local highScore  = (pss:GetPersonalHighScoreIndex() == 0) and '1' or '0'
	local meter      = st:GetMeter()
	local checkRadar = st:GetRadarValues(player)
	local scoreMode  = 'Default'
	local ultimate   = 0
	local difficulty = ToEnumShortString(st:GetDifficulty())
	-- テーマカラー
	local sub   = ''
	
	-- 判定ラベル
	local judgeLabel = 0
	if checkJudgeLabel == 'DDR' then
		judgeLabel = 1
	elseif checkJudgeLabel == 'DDR SuperNOVA' then
		judgeLabel = 2
	end
	
	-- コンボ継続最低判定
	local minCombo = tonumber(split('W', checkMinCombo)[2])
	
	-- フルコンボ
	local fullCombo = 0;
	if pss:FullComboOfScore('TapNoteScore_W4') then
		if pss:FullComboOfScore('TapNoteScore_W1') then
			fullCombo = 1
		elseif pss:FullComboOfScore('TapNoteScore_W2') and minCombo >= 2 then
			fullCombo = 2
		elseif pss:FullComboOfScore('TapNoteScore_W3') and minCombo >= 3 then
			fullCombo = 3
		elseif pss:FullComboOfScore('TapNoteScore_W4') and minCombo >= 4 then
			fullCombo = 4
		end
	end
	
	-- グレード
	local grade = 8
	if checkGrade == 'Grade_Tier01' then
		grade = 0
	elseif checkGrade == 'Grade_Tier02' then
		grade = 1
	elseif checkGrade == 'Grade_Tier03' then
		grade = 2
	elseif checkGrade == 'Grade_Tier04' then
		grade = 3
	elseif checkGrade == 'Grade_Tier05' then
		grade = 4
	elseif checkGrade == 'Grade_Tier06' then
		grade = 5
	elseif checkGrade == 'Grade_Tier07' then
		grade = 6
	else
		grade = 7
	end
	
	-- オプション
	local option = ps:GetPlayerOptionsString("ModsLevel_Preferred")
	
	-- ダンスポイント
	local dancePoint
	if checkDancePoint == 100 then
		dancePoint = '100'
	else
		dancePoint = string.format("%2.2f", checkDancePoint)
	end
	
	-- レーダー
	local radar = {}
	if YA_VER:Version() >= 70 then
		radar = {
			Stream  = math.floor(math.min(checkRadar:GetValue('RadarCategory_Stream') * 0.95, 1.1) * 100),
			Voltage = math.floor(math.min(checkRadar:GetValue('RadarCategory_Voltage') * 0.95, 1.1) * 100),
			Air     = math.floor(math.min(checkRadar:GetValue('RadarCategory_Air') * 0.95, 1.1) * 100),
			Freeze  = math.floor(math.min(checkRadar:GetValue('RadarCategory_Freeze') * 0.95, 1.1) * 100),
			Chaos   = math.floor(math.min(checkRadar:GetValue('RadarCategory_Chaos') * 0.95, 1.1) * 100),
		}
	else
		radar = {
			Stream  = math.floor(checkRadar:GetValue('RadarCategory_Stream') * 100),
			Voltage = math.floor(checkRadar:GetValue('RadarCategory_Voltage') * 100),
			Air     = math.floor(checkRadar:GetValue('RadarCategory_Air') * 100),
			Freeze  = math.floor(checkRadar:GetValue('RadarCategory_Freeze') * 100),
			Chaos   = math.floor(checkRadar:GetValue('RadarCategory_Chaos') * 100),
		}
	end
	
	local noteScore = {
		W1   = pss:GetTapNoteScores('TapNoteScore_W1'),
		W2   = pss:GetTapNoteScores('TapNoteScore_W2'),
		W3   = pss:GetTapNoteScores('TapNoteScore_W3'),
		W4   = pss:GetTapNoteScores('TapNoteScore_W4'),
		W5   = pss:GetTapNoteScores('TapNoteScore_W5'),
		Miss = pss:GetTapNoteScores('TapNoteScore_Miss'),
		Held = pss:GetHoldNoteScores('HoldNoteScore_Held'),
	}
	
	local maxCombo = pss:MaxCombo()
	local score = pss:GetScore()
	return {
		fn          = folder,
		gn          = createUrl((original == '') and string.lower(group) or string.lower(original)),
		package     = createUrl(packageName),
		color       = menuColor,
		mt          = createUrl(string.upper(meterType)),
		style       = createUrl(string.upper(style)),
		mode        = createUrl(string.upper(mode)),
		timing      = timing,
		life        = life,
		hscore      = highScore,
		level       = meter,
		scoremode   = createUrl(string.upper(scoreMode)),
		ultimate    = ultimate,
		difficulty  = string.upper(difficulty),
		judge       = judgeLabel,
		fc          = fullCombo,
		grade       = grade,
		option      = createUrl(option),
		dp          = createUrl(dancePoint),
		r_str       = radar['Stream'],
		r_vol       = radar['Voltage'],
		r_air       = radar['Air'],
		r_frz       = radar['Freeze'],
		r_cha       = radar['Chaos'],
		j_w1        = noteScore['W1'],
		j_w2        = noteScore['W2'],
		j_w3        = noteScore['W3'],
		j_w4        = noteScore['W4'],
		j_w5        = noteScore['W5'],
		j_ms        = noteScore['Miss'],
		j_ok        = noteScore['Held'],
		j_mc        = maxCombo,
		score       = score,
		theme       = createUrl(theme),
		sub         = createUrl(sub),
		guid        = guid,
		player      = createUrl(playerName),
		title       = createUrl(title),
		artist      = createUrl(artist),
		md5         = md5,	-- 整合性チェックのMD5はうまく処理できていないので現在未実装
		tm_y        = datetimeTable['year'],
		tm_m        = datetimeTable['month'],
		tm_d        = datetimeTable['day'],
		tm_h        = datetimeTable['hour'],
		tm_mi       = datetimeTable['minute'],
	}
end

--[[
	リザルト連携用URLを生成
--]]
local function generateUrl(self, player, datetimeTable)
	local params = validateAndGetValues(player, datetimeTable)
	local url = sendUrl..'?'
	for key,value in pairs(params) do
		url = url..key..'='..value..'&'
	end
	-- 最後の&を消して返却
	return string.sub(url, 1, -1)
end

--[[
	リザルト連携用URLへアクセス
--]]
local function shareResult(...)
	local self, player, datetimeTable = ...
	if not datetimeTable then
		datetimeTable = {
			year   = Year(),
			month  = (MonthOfYear()+1),
			day    = DayOfMonth(),
			hour   = Hour(),
			minute = Minute(),
		}
	end
	local url = generateUrl(self, player, datetimeTable)
	file = RageFileUtil:CreateRageFile()
	file:Open('WAIEI Core.log', 2)
	file:Write(url)
	file:Close()
	file:destroy()
	GAMESTATE:ApplyGameCommand("urlnoexit,"..url)
end

--[[
	Evaluation用Actor
	@param	bool	enabledSpeed		ハイスピード変更の有効フラグ（未指定の場合も有効）
	@param	bool	enabledReverse		スクロール方向変更の有効フラグ（未指定の場合も有効）
	@param	table	codes			Metricsで定義したCode（{SpeedUp={string}, SpeedDown={string}, ScrollStandard={string}, ScrollReverse={string},}）
--]]
local shareDatetime = {}
local function shareActor(...)
	local self, enabledShare, codes = ...
	if not codes then
		codes = defaultCodes
	end
	return Def.Actor{
		InitCommand = function(self)
			shareDatetime = {
				year   = Year(),
				month  = (MonthOfYear()+1),
				day    = DayOfMonth(),
				hour   = Hour(),
				minute = Minute(),
			}
		end;
		CodeCommand=function(self, params)
			local player = params.PlayerNumber
			local codeShare = inTable(params.Name, codes['Share'])
			if enabledShare ~= false and codeShare then
				shareResult(self, player, shareDatetime)
			end
		end;
	}
end

return {
	Send  = shareResult,
	Url   = generateUrl,
	Actor = shareActor,
}
