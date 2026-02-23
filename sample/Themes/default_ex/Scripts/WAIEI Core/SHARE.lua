-- Share

-- Twitterスコア連携用URL
local sendUrl = 'https://sm.waiei.net/systems/score_v2'
--local sendUrl = 'http://localhost/systems/score_v2'

local defaultCodes = {
    Share = {'Share', 'Share2'},
}

-- エラーメッセージ
local errorMessages = {}
local defaultErrorMessages = {
    Profile = 'この機能を利用するにはPROFILEの設定が必須です。',
    Song    = '楽曲情報の取得に失敗しました。',
    Course  = 'この機能はコースモードでは使用できません。',
}

-- 値取得用関数
local functions = {}
local defaultFunctions = {
    -- グルーヴレーダーの値を設定（Player player, string radarCategory） :int
    RadarValue = function(player, radarCategory)
        local steps = GAMESTATE:GetCurrentSteps(player)
        if not steps then
            return 0
        end
        local radar = steps:GetRadarValues(player)
        if not radar then
            return 0
        end
        if YA_VER:Version() >= 70 then
            return math.floor(math.min(radar:GetValue(radarCategory) * 0.95, 1.1) * 100)
        else
            return math.floor(radar:GetValue(radarCategory) * 100)
        end
    end,
    -- 判定ラベル（引数なし）:string
    Judgement = function()
        return 'StepMania'    -- 'StepMania', 'DDR', 'DDR SuperNOVA' のいずれかに対応
    end,
    -- 難易度数値（Steps steps）:int
    Meter = function(steps)
        return steps:GetMeter()
    end,
    -- ハイスコア判定（Player player）:bool
    HighScore = function(player)
        local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
        return (pss and pss:GetPersonalHighScoreIndex() == 0)
    end,
    -- スコアタイプ（）:string
    ScoreType = function()
        return YA_SCORE:GetDisplayType() or 'Default'    -- 'Default', 'A', 'SN2', 'Classic', 'Hybrid' のいずれかに対応
    end,
    -- テーマカラー（引数なし）:string
    ThemeColor = function()
        return ''
    end,
    -- アルティメットライフ（引数なし）:bool
    Ultimate = function()
        return false
    end,
}

--- テーブル内に指定した値があるかチェック
--[[
    @param  string 検索文字
    @param  table 検索対象のテーブル
    @return bool
--]]
local function inTable(search, tableData)
    for value in ivalues(tableData) do
        if value == search then
            return true
        end
    end
    return false
end

--- バイナリを含む文字列を %00x 表記に変換する
--[[
    @param  string 対象の文字列
	@return string
--]]
local function createUrl(str)
    local strUrl = ''
    for i=1,string.len(str) do
        local strByte=string.byte(str,i)
        strUrl = strUrl..'%'..string.format("%02x",strByte)
    end;
    return strUrl
end;

--- エラーチェックと値の取得
--[[
	@param  Player プレイヤー
	@param  table{year,month,day,hour,minute} プレイ日時が格納されたテーブル
	@return table
--]]
local function validateAndGetValues(player, datetimeTable)
    local playerName = PROFILEMAN:GetPlayerName(player);
    if not playerName or playerName == '' then
        -- Profile設定必須
        return {Error = errorMessages.Profile}
    end
    
    if GAMESTATE:IsCourseMode() then
        -- コースモードは許可されていない
        return {Error = errorMessages.Course}
    end
    
    local song = GAMESTATE:GetCurrentSong();
    if not song then
        -- 楽曲が取得できない
        return {Error = errorMessages.Song}
    end
    
    local ss  = STATSMAN:GetCurStageStats()
    local pss = ss:GetPlayerStageStats(player)
    local ps  = GAMESTATE:GetPlayerState(player)
    local st  = GAMESTATE:GetCurrentSteps(player)
    local pr  = PROFILEMAN:GetProfile(player)
    
    -- テーマ関係なく取得可能な値
    local folder = YA_GROUP:FolderName(song)
    local group = song:GetGroupName()
    local menuColor   = YA_GROUP:MenuColor(song)
    local meterType   = YA_GROUP:MeterType(song)
    local original    = YA_GROUP:OriginalName(song)
    local packageName = YA_GROUP:GroupName(group)
    if packageName == '' then
        packageName = group
    end
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
    local checkJudgeLabel = functions.Judgement()
    local highScore  = (functions.HighScore(player)) and '1' or '0'
    local meter      = functions.Meter(st)
    local scoreMode  = functions.ScoreType()
    local ultimate   = (functions.Ultimate()) and '1' or '0'
    -- テーマカラー
    local sub   = functions.ThemeColor()
    
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
    local radar = {
        Stream  = functions.RadarValue(player, 'RadarCategory_Stream'),
        Voltage = functions.RadarValue(player, 'RadarCategory_Voltage'),
        Air     = functions.RadarValue(player, 'RadarCategory_Air'),
        Freeze  = functions.RadarValue(player, 'RadarCategory_Freeze'),
        Chaos   = functions.RadarValue(player, 'RadarCategory_Chaos'),
    }
    
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
        color       = table.concat(menuColor, ','),
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
        md5         = md5,    -- 整合性チェックのMD5はうまく処理できていないので現在未実装
        tm_y        = datetimeTable['year'],
        tm_m        = datetimeTable['month'],
        tm_d        = datetimeTable['day'],
        tm_h        = datetimeTable['hour'],
        tm_mi       = datetimeTable['minute'],
    }
end

--- QRコード対応版のURLクエリに変更する
--[[
	@param  table
	@return string
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

--- リザルト連携用URLを生成
--[[
	@param  Player プレイヤー
	@param  table{year,month,day,hour,minute} プレイ日時が格納されたテーブル
	@return table
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
    if params.Error then
        return {Url = sendUrl, Query = nil, Error = params.Error}
    end
    return {Url = sendUrl, Query = convertQueryVersion2(params), Error = nil}
end

--- エラーメッセージを設定
--[[
	@param  table{Profile,Song,Course}
	@return table
--]]
local function setErrorMessage(self, messages)
    errorMessages['Profile'] = messages.Profile or errorMessages.Profile
    errorMessages['Song']    = messages.Song or errorMessages.Song
    errorMessages['Course']  = messages.Course or errorMessages.Course
    return errorMessages
end

--- 値取得用の関数を設定
--[[
	@param  table{RadarValue,Judgement,HighScore,Meter,ScoreType,ThemeColor,Ultimate}
	@return table
--]]
local function setFunctions(self, newFunctions)
    functions['RadarValue'] = newFunctions.RadarValue or functions.RadarValue
    functions['Judgement'] = newFunctions.Judgement or functions.Judgement
    functions['HighScore'] = newFunctions.HighScore or functions.HighScore
    functions['Meter'] = newFunctions.Meter or functions.Meter
    functions['ScoreType'] = newFunctions.ScoreType or functions.ScoreType
    functions['ThemeColor'] = newFunctions.ThemeColor or functions.ThemeColor
    functions['Ultimate'] = newFunctions.Ultimate or functions.Ultimate
    return functions
end

--- リザルト連携用URLへアクセス
--[[
	@param string query
--]]
local function shareResult(...)
    local self, query = ...
    if query then
        GAMESTATE:ApplyGameCommand("urlnoexit,"..sendUrl..'?'..query)
    end
end

--- Evaluation用Actor
--[[
    @param  bool リザルト共有機能の有効フラグ（未指定の場合も有効）
    @param  table Metricsで定義したCode（{Share={string}, Share2={string}}）
	@return Actor
--]]
local shareUrl = {}
local function shareActor(...)
    local self, enabledShare, codes = ...
    -- falseの時のみ無効（nil の時は有効）
    if enabledShare == false then
        return Def.Actor({})
    end
    if not codes then
        codes = defaultCodes
    end
    --[[
        このActorをコピーしてEvaluationに貼り付けることで自分好みにカスタムできます
        以下の変数の初期化も必要です
        local shareUrl = {}
    --]]
    return Def.Actor({
        InitCommand = function(self)
            local shareDatetime = {
                year   = Year(),
                month  = (MonthOfYear()+1),
                day    = DayOfMonth(),
                hour   = Hour(),
                minute = Minute(),
            }
            shareUrl = {nil, nil}
            for player in ivalues(PlayerNumber) do
                local pn = (player == PLAYER_1) and 1 or 2
                if GAMESTATE:IsPlayerEnabled(player) then
                    -- カスタムする場合は YA_SHARE:Url(player, shareDatetime)
                    shareUrl[pn] = generateUrl(self, player, shareDatetime)
                end
            end
        end,
        CodeCommand=function(self, params)
            local player = params.PlayerNumber
            local pn = (player == PLAYER_1) and 1 or 2
            -- カスタムする場合は (params.Name == 'Share' or params.Name == 'Share2')
            local codeShare = inTable(params.Name, codes['Share'])
            -- params.NameがCodeで定義したもので、shareUrl[pn]が取得済み
            if codeShare and shareUrl[pn] then
                if shareUrl[pn]['Query'] then
                    -- ブラウザを開く
                    -- カスタムする場合は YA_SHARE:Send(shareUrl[pn]['Query'])
                    shareResult(self, shareUrl[pn]['Query'])
                else
                    -- エラーがあるので表示する
                    _SYS(shareUrl[pn]['Error'])
                end
            end
        end,
    })
    -- コピーここまで
end

-- デフォルトのエラーメッセージを設定
setErrorMessage(self, defaultErrorMessages)
-- デフォルトの値設定用関数を設定
setFunctions(self, defaultFunctions)

return {
    Messages  = setErrorMessage,
    Functions = setFunctions,
    Send      = shareResult,
    Url       = generateUrl,
    Actor     = shareActor,
}
