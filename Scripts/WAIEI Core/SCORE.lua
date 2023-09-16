-- スコア周り

-- このテーブルで定義した計算式の関数を作成する必要あり
-- 例：local function getSN2Score()
local scoreTypeList = {'A', 'SN2', 'Classic', 'Hybrid'}

-- 定義と表示テキストのマッピング
local displayScoreTypeList = {
    a       = 'DDR A',
    sn2     = 'SuperNOVA2',
    classic = 'Classic',
    hybrid  = 'Hybrid',
    default = 'Default'
}

-- スコアタイプ（初期値未設定、Actorを使用した時点で値が入る）
local scoreType
local defaultScoreType = 'A'

--- Aの計算式を取得
--[[
    @param  table JudgmentMessageのパラメータ
    @param  PlayerStageStats PlayerStageStats
    @param  int ステップ数（1以上であること）
    @return int スコア
--]]
local function getAScore(...)
    local params, stats, size = ...
    local w1 = stats:GetTapNoteScores('TapNoteScore_W1')
    local w2 = stats:GetTapNoteScores('TapNoteScore_W2')
    local w3 = stats:GetTapNoteScores('TapNoteScore_W3')
    local w4 = stats:GetTapNoteScores('TapNoteScore_W4')
    local hd = stats:GetHoldNoteScores('HoldNoteScore_Held')
    if YA_VER:Version() < 5300 then
        if params.HoldNoteScore=='HoldNoteScore_Held' then
            hd = hd + 1
        elseif params.TapNoteScore=='TapNoteScore_W1' then
            w1 = w1 + 1
        elseif params.TapNoteScore=='TapNoteScore_W2' then
            w2 = w2 + 1
        elseif params.TapNoteScore=='TapNoteScore_W3' then
            w3 = w3 + 1
        elseif params.TapNoteScore=='TapNoteScore_W4' then
            w4 = w4 + 1
        end
    end
    return (math.round((w1 + w2 + w3*0.6 + w4*0.2 + hd) * 100000 / size - (w2 + w3 + w4))*10)
end

--- SN2の計算式を取得
--[[
    @param  table JudgmentMessageのパラメータ
    @param  PlayerStageStats PlayerStageStats
    @param  int ステップ数（1以上であること）
    @return int スコア
--]]
local function getSN2Score(...)
    local params, stats, size = ...
    local w1 = stats:GetTapNoteScores('TapNoteScore_W1')
    local w2 = stats:GetTapNoteScores('TapNoteScore_W2')
    local w3 = stats:GetTapNoteScores('TapNoteScore_W3')
    local hd = stats:GetHoldNoteScores('HoldNoteScore_Held')
    if YA_VER:Version() < 5300 then
        if params.HoldNoteScore=='HoldNoteScore_Held' then
            hd = hd + 1
        elseif params.TapNoteScore=='TapNoteScore_W1' then
            w1 = w1 + 1
        elseif params.TapNoteScore=='TapNoteScore_W2' then
            w2 = w2 + 1
        elseif params.TapNoteScore=='TapNoteScore_W3' then
            w3 = w3 + 1
        end
    end
    return (math.round((w1 + w2 + w3*0.5 + hd) * 100000 / size - (w2 + w3))*10)
end

--- 3.9の計算式を取得
--[[
    @param  table JudgmentMessageのパラメータ
    @param  PlayerStageStats PlayerStageStats
    @param  int ステップ数（1以上であること）
    @param  int 何番目のステップか
    @param  int スコアの最大値
    @return int スコア
--]]
local function getClassicScore(...)
    local params, stats, size, count, maximumScore = ...
    -- 最小単位のスコアを取得するためのステップ数総和を取得
    local resolution = (((size+1)*size)/2)
    -- 最小単位のスコア
    local oneScore = math.floor(maximumScore/resolution)
    -- 最後の1ステップは切り上げを行う必要があるので端数を計算
    local lastScore = ((count == size) and maximumScore-(oneScore*resolution) or 0)
    -- 現時点のスコア
    local currentScore = stats:GetScore()
    if params.HoldNoteScore=='HoldNoteScore_Held' then
        return currentScore + (oneScore*count+lastScore)
    elseif params.TapNoteScore=='TapNoteScore_W1' then
        return currentScore + (oneScore*count+lastScore)
    elseif params.TapNoteScore=='TapNoteScore_W2' then
        return currentScore + (math.floor(oneScore*count*0.9)+lastScore)
    elseif params.TapNoteScore=='TapNoteScore_W3' then
        return currentScore + (math.floor(oneScore*count*0.5)+lastScore)
    end;
    return currentScore
end

--- Hybridの計算式を取得
--[[
    @param  table JudgmentMessageのパラメータ
    @param  PlayerStageStats PlayerStageStats
    @param  int ステップ数（1以上であること）
    @param  int 何番目のステップか
    @param  int スコアの最大値
    @return int スコア
--]]
local function getHybridScore(...)
    local params, stats, size, count, maximumScore = ...
    -- 3.9計算式と最大値が異なるだけで基本は同じ
    return getClassicScore(params, stats, size, count, maximumScore)
end

--- スコア計算用のActorを取得
--[[
    計算式：A SN2 3.9 HYBRID のいずれか
    @param  string 計算式
    @return ActorFrame
--]]
local songMaximumScore = {PlayerNumber_P1 = 0, PlayerNumber_P2 = 0}
local useScoreChangedMes = {PlayerNumber_P1 = false, PlayerNumber_P2 = false}
local function scoreActor(...)
    local self, newScoreType = ...
    scoreType = string.lower(newScoreType or defaultScoreType)
    -- 現在のステップ数
    local stepCount = {PlayerNumber_P1 = 0, PlayerNumber_P2 = 0}
    -- ステップ数
    local stepSize = {PlayerNumber_P1 = 0, PlayerNumber_P2 = 0}
    return Def.ActorFrame({
        Def.Actor({
            -- 曲が変わるタイミングでステップカウントのリセットとトータルステップ数の取得
            CurrentSongChangedMessageCommand = function(self)
                stepCount = {PlayerNumber_P1 = 0, PlayerNumber_P2 = 0}
                for pn in ivalues(PlayerNumber) do
                    local step = GAMESTATE:GetCurrentSteps(pn)
                    if step then
                        local radarValues = step:GetRadarValues(pn)
                        stepSize[pn] = math.max(
                            radarValues:GetValue('RadarCategory_TapsAndHolds')
                            + radarValues:GetValue('RadarCategory_Holds')
                            + radarValues:GetValue('RadarCategory_Rolls'),
                        1);
                    end
                    -- スコアの最大値も先に取得しておく
                    if scoreType == 'classic' then
                        local meter = math.max(math.min(GAMESTATE:GetCurrentSteps(pn):GetMeter(), 10), 1)
                        songMaximumScore[pn] = GAMESTATE:GetCurrentSong():IsLong()
                            and (GAMESTATE:GetCurrentSong():IsMarathon() and meter*30000000 or meter*20000000)
                            or meter*10000000
                    elseif scoreType == 'hybrid' then
                        songMaximumScore[pn] = GAMESTATE:GetCurrentSong():IsLong()
                            and (GAMESTATE:GetCurrentSong():IsMarathon() and 300000000 or 200000000)
                            or 100000000
                    end
                end
            end,
            JudgmentMessageCommand = function(self, params)
                local stats = STATSMAN:GetCurStageStats():GetPlayerStageStats(params.Player)
                if (GAMESTATE:GetPlayerState(params.Player):GetPlayerController() == 'PlayerController_Autoplay') then
                    -- オートプレイの場合スコアは0
                    stats:SetScore(0)
                    return
                end
                -- OutFoxはこの方法では正しく動かない
                if params.TapNoteScore and
                   params.TapNoteScore ~= 'TapNoteScore_AvoidMine' and
                   params.TapNoteScore ~= 'TapNoteScore_HitMine' and
                   params.TapNoteScore ~= 'TapNoteScore_CheckpointMiss' and
                   params.TapNoteScore ~= 'TapNoteScore_CheckpointHit' and
                   params.TapNoteScore ~= 'TapNoteScore_None' and
                   (not params.HoldNoteScore or
                    params.HoldNoteScore ~= 'HoldNoteScore_LetGo' and
                    params.HoldNoteScore ~= 'HoldNoteScore_MissedHold')
                then
                    local sendParams = params
                    sendParams.PlayerNumber = params.Player
                    if YA_VER:Version() < 5300 then
                        self:playcommand('UpdateScore', sendParams)
                    else
                        -- OF用特殊処理（ホールド以外はこっちでスコア計算する）
                        if not params.HoldNoteScore then
                            useScoreChangedMes[params.Player] = false
                            self:playcommand('UpdateScore', sendParams)
                        else
                            useScoreChangedMes[params.Player] = true
                        end
                    end
                end
            end,
            -- OutFox用。ネット対戦でうまく動かないがOutFoxはそもそもネット対戦非対応
            -- A4.13時点ではAutoPlay CPUもW1～Miss判定時にメッセージが飛ばない
            ScoreChangedMessageCommand = function (self, params)
                if YA_VER:Version() >= 5300 and useScoreChangedMes[params.PlayerNumber] then
                    self:playcommand('UpdateScore', params)
                end
            end,
            UpdateScoreCommand = function(self, params)
                local pn = params.PlayerNumber
                local stats = STATSMAN:GetCurStageStats():GetPlayerStageStats(pn)
                stepCount[pn] = stepCount[pn] + 1
                if stats:GetFailed() then
                    -- すでに落ちてる場合はスコア加算をしない
                    return
                end
                -- もっとスマートな方法はないだろうか
                if scoreType == 'a' then
                    stats:SetScore(getAScore(params, stats, stepSize[pn]))
                elseif scoreType == 'sn2' then
                    stats:SetScore(getSN2Score(params, stats, stepSize[pn]))
                elseif scoreType == 'classic' then
                    stats:SetScore(getClassicScore(
                        params, stats, stepSize[pn], stepCount[pn],
                        songMaximumScore[pn] or 1
                    ))
                elseif scoreType == 'hybrid' then
                    stats:SetScore(getHybridScore(
                        params, stats, stepSize[pn], stepCount[pn],
                        songMaximumScore[pn] or 1
                    ))
                end
            end,
        }),
    })
end

--- スコアタイプを取得
--[[
    @return string
--]]
local function getScoreType(self)
    return scoreType or 'Default'
end
--- 表示用スコアタイプを取得
--[[
    @return string
--]]
local function getDisplayScoreType(self)
    return displayScoreTypeList[string.lower(getScoreType(self))] or 'Default'
end

--- Metrics.iniのUseInternalScoring用の値を取得
--[[
    現在はコースモードがtrue、通常時はfalse
    @return bool
--]]
local function getUseInternalScoring(self)
    return GAMESTATE:IsCourseMode()
end

return {
    Actor           = scoreActor,
    InternalScoring = getUseInternalScoring,
    GetType         = getScoreType,
    GetDisplayType  = getDisplayScoreType,
}
