-- Share

-- Twitterスコア連携用URL
local sendUrl = 'https://sm.waiei.net/systems/score_v2'
--local sendUrl = 'http://localhost/systems/score_v2'

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
    if not playerName or playerName == '' then
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
	local guid       = pr:GetGUID()
	local difficulty = Enum.Reverse(Difficulty)[st:GetDifficulty()]
    -- 120バイトでサブタイトルを削る
	local title      = (string.len(song:GetDisplayFullTitle()) > 120) and song:GetDisplayMainTitle() or song:GetDisplayFullTitle()
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
		gn          = (original == '') and string.lower(group) or string.lower(original),
		package     = packageName,
		color       = menuColor,
		mt          = string.upper(meterType),
		style       = string.upper(style),
		mode        = string.upper(mode),
		timing      = timing,
		life        = life,
		hscore      = highScore,
		level       = meter,
		scoremode   = string.upper(scoreMode),
		ultimate    = ultimate,
		difficulty  = difficulty,
		judge       = judgeLabel,
		fc          = fullCombo,
		grade       = grade,
		option      = option,
		dp          = dancePoint,
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
		theme       = theme,
		sub         = sub,
		guid        = guid,
		player      = playerName,
		title       = title,
		artist      = artist,
		md5         = md5,	-- 整合性チェックのMD5はうまく処理できていないので現在未実装
		tm_y        = datetimeTable['year'],
		tm_m        = datetimeTable['month'],
		tm_d        = datetimeTable['day'],
		tm_h        = datetimeTable['hour'],
		tm_mi       = datetimeTable['minute'],
	}
end

--[[
    QRコード対応版のURLクエリに変更する
--]]
local function convertQueryVersion2(data)
    local b64 = YA_LIB.BASE64
    local values = {
        -- フォルダ
        f = data.fn,
        -- グループ
        g = data.gn,
        -- パッケージ
        p = data.package,
        -- タイトル
        t = data.title,
        -- アーティスト
        a = data.artist,
        -- プレイヤー名
        pl = data.player,
        -- テーマ(テーマ名、カラー名 ':'区切り)
        tm = table.concat({data.theme, data.sub}, ":"),
        -- PlayerOption
        po = data.option,
        -- DateTime(YYYY/mm/dd HH:ii)
        dt = string.format("%04d/%02d/%02d %02d:%02d", data.tm_y, data.tm_m, data.tm_d, data.tm_h, data.tm_mi),
        -- GUID
        id = data.guid,
        -- レーダー(STREAM, VOLTAGE, AIR, FREEZE, CHAOS ':'区切り)
        rd = table.concat({data.r_str, data.r_vol, data.r_air, data.r_frz, data.r_cha}, ":"),
        -- 判定(W1, W2, W3, W4, W5, Miss, OK, MaxCombo ':'区切り)
        jd = table.concat({data.j_w1, data.j_w2, data.j_w3, data.j_w4, data.j_w5, data.j_ms, data.j_ok, data.j_mc}, ":"),
        -- 設定(TimingDifficulty, LifeDifficulty, Ultimate, JudgementLabel ':'区切り)
        cf = table.concat({data.timing, data.life, data.ultimate, data.judge}, ":"),
        -- ゲームモード・曲情報(GameStyle, GameMode, MeterType, Difficulty, Level ':'区切り)
        gm = table.concat({data.style, data.mode, data.mt, data.difficulty, data.level}, ":"),
        -- スコア(ScoreMode, Score, DancePoint, HighScore, Grade ':'区切り)
        sc = table.concat({data.scoremode, data.score, data.dp, data.hscore, data.grade, data.fc}, ":"),
        -- 色
        cl = data.color,
        -- ハッシュ(未実装)
        hs = '',
    }
    local query = ''
	for key,value in pairs(values) do
		query = query..key..'='..b64:ToBase64(value)..'&'
	end
	-- 最後の&を消して返却
	return string.sub(query, 1, -2)
end

--[[
	リザルト連携用URLを生成
--]]
local function generateUrl(self, player, datetimeTable)
	if not datetimeTable then
		datetimeTable = {
			year   = Year(),
			month  = (MonthOfYear()+1),
			day    = DayOfMonth(),
			hour   = Hour(),
			minute = Minute(),
		}
	end
	local params = validateAndGetValues(player, datetimeTable)
    return sendUrl..'?'..convertQueryVersion2(params)
    --[[
	local url2 = '!'..sendUrl..'?'
	for key,value in pairs(params) do
		url = url..key..'='..value..'&'
		url2 = url2..'|'..value
	end
	_SYS(#url2)
	--_LOG(url)
	-- 最後の&を消して返却
	return string.sub(url, 1, -1)
    --]]
end

--[[
	リザルト連携用URLへアクセス
--]]
local function shareResult(...)
	local self, url = ...
	--local url = generateUrl(self, player, datetimeTable)
	GAMESTATE:ApplyGameCommand("urlnoexit,"..url)
end

--[[
	Evaluation用Actor
	@param	bool	enabledShare	リザルト共有機能の有効フラグ（未指定の場合も有効）
	@param	table	codes		Metricsで定義したCode（{Share={string}, Share2={string}}）
--]]
local shareDatetime = {}
local shareUrl = {nil, nil}
local function shareActor(...)
	local self, enabledShare, codes = ...
    -- nil の時は有効
    if enabledShare == false then
        return Def.Actor()
    end
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
            shareUrl = {nil, nil}
            for player in ivalues(PlayerNumber) do
                if GAMESTATE:IsPlayerEnabled(player) then
                    shareUrl[(player == PLAYER_1) and 1 or 2] = generateUrl(self, player, shareDatetime)
                end
            end
		end;
		CodeCommand=function(self, params)
			local player = params.PlayerNumber
			local codeShare = inTable(params.Name, codes['Share'])
            local url = shareUrl[(player == PLAYER_1) and 1 or 2]
			if codeShare and url then
				shareResult(self, shareUrl[(player == PLAYER_1) and 1 or 2])
			end
		end;
	}
end

return {
	Send  = shareResult,
	Url   = generateUrl,
	Actor = shareActor,
}
