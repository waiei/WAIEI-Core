-- ハイスピードとリバース切り替え
-- Original code by speedkills v2

local defaultSpeedList = {
    x  = {0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0, 5.0, 8.0,},
    c  = {100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 700, 800, 900, 1000,},
    m  = {100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 700, 800, 900, 1000,},
    a  = {100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 700, 800, 900, 1000,},
    ca = {100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 700, 800, 900, 1000,},
    av = {100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 700, 800, 900, 1000,},
}
local defaultCodes = {
    SpeedUp        = {'SpeedUp', 'SpeedUp2'},
    SpeedDown      = {'SpeedDown', 'SpeedDown2'},
    ScrollStandard = {'ScrollStandard', 'ScrollStandard2'},
    ScrollReverse  = {'ScrollReverse', 'ScrollReverse2'},
}

local speedList = {PlayerNumber_P1 = {}, PlayerNumber_P2 = {}}
local currentSpeed = {PlayerNumber_P1 = 0, PlayerNumber_P2 = 0}

--- テーブル内に指定した値があるかチェック
--[[
    @param  string  検索文字
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

--- プレイヤーの現在のスピードオプションを取得する
--[[
    @param  pn プレイヤー
    @return string, float
--]]
local function GetCurrentMod(pn)
    -- fallbackのGetSpeedModeAndValueFromPoptionsをそのまま利用
    -- modeはCだけ大文字、speedはxの時100倍なので調整する
    local speed, mode = GetSpeedModeAndValueFromPoptions(pn)
    return string.lower(mode), speed * ((mode == 'x') and 0.01 or 1)
end

--- プレイヤーの現在のスピードを取得する
--[[
    @param  Player プレイヤー
    @return table{string mod, float speed}
--]]
local function GetCurrentSpeed(self, pn)
    local mod ,speed = GetCurrentMod(pn)
    -- そのまま返却すると上書きする可能性があるのでクローンして返却
    return {Mod = mod, Speed = speed}
end

--- プレイヤーの現在のスピードを一覧からキー番号で取得する
--  一覧にない場合は一番近い番号を返す
--  例えば1.5,2.0が一覧にあるが現在値が1.75の場合は1.5のキー番号を返す
--[[
    @param  Player プレイヤー
    @return int
--]]
local function GetCurrentSpeedKey(pn)
    local mod ,speed = GetCurrentMod(pn)
    local current = 0
    local list    = speedList[pn]
    for i=1,#list do
        if speed <= list[i].Speed then
            current = i
            break
        end
    end
    return current
end

--- プレイヤーのスピード一覧を取得する
--[[
    LocalまたはMachineのSpeedMod.txtを取得する
    @param  pn プレイヤー
    @return table,{{{string mod , float speed},...},...}, int current_index
--]]
local function LoadSpeedList(self, pn)
    local file = YA_FILE:Profile('SpeedMods.txt', pn)
    local speeds = file and file:Read() or ''
    local strSpeeds = split(',', speeds)
    local mod ,speed = GetCurrentMod(pn)
    speedList[pn] = {}
    for i=1, #strSpeeds do
        if mod == 'x' and string.find(strSpeeds[i], '[%d.]+x') then
            speedList[pn][i] = {
                Mod   = 'x',
                Speed = tonumber(split('x', strSpeeds[i])[1]),
            }
        elseif mod == 'c' and string.find(strSpeeds[i], 'C[%d.]+') then
            speedList[pn][i] = {
                Mod   = 'c',
                Speed = tonumber(split('C', strSpeeds[i])[2]),
            }
        elseif mod == 'm' and string.find(strSpeeds[i], 'm[%d.]+') then
            speedList[pn][i] = {
                Mod   = 'm',
                Speed = tonumber(split('m', strSpeeds[i])[2]),
            }
        elseif mod == 'a' and string.find(strSpeeds[i], 'a[%d.]+') then
            speedList[pn][i] = {
                Mod   = 'a',
                Speed = tonumber(split('a', strSpeeds[i])[2]),
            }
        elseif mod == 'ca' and string.find(strSpeeds[i], 'ca[%d.]+') then
            speedList[pn][i] = {
                Mod   = 'ca',
                Speed = tonumber(split('ca', strSpeeds[i])[2]),
            }
        elseif mod == 'av' and string.find(strSpeeds[i], 'av[%d.]+') then
            speedList[pn][i] = {
                Mod   = 'av',
                Speed = tonumber(split('av', strSpeeds[i])[2]),
            }
        end
    end
    -- 該当するスピードが一覧に存在しない場合、デフォルト値を設定
    if #speedList[pn] <= 0 then
        for k,v in pairs(defaultSpeedList[mod] or {}) do
            speedList[pn][k] = {
                Mod   = mod,
                Speed = v,
            }
        end
    end

    currentSpeed[pn] = GetCurrentSpeedKey(pn)
    
    return speedList, currentSpeed[pn]
end

--- プレイヤーのスピードを設定する
--[[
    @param  pn プレイヤー
    @param  string MOD(x c mのいずれか、OutFoxのみcaとaを許可)
    @param  float スピード
    @return table{string mod , float speed}
--]]
local function SetCurrentSpeed(self, pn, mod, speed)
    mod = string.lower(mod)
    local ps = GAMESTATE:GetPlayerState(pn)
    local popr = ps:GetPlayerOptions("ModsLevel_Preferred")
    local posn = ps:GetPlayerOptions("ModsLevel_Song")
    local post = ps:GetPlayerOptions("ModsLevel_Stage")
    local pocu = ps:GetPlayerOptions("ModsLevel_Current")
    if mod == 'x' then
        -- xMod
        popr:XMod(speed)
        posn:XMod(speed)
        post:XMod(speed)
        pocu:XMod(speed)
        return {Mod = 'x', Speed = speed}
    elseif mod == 'c' then
        -- CMod
        popr:CMod(speed)
        posn:CMod(speed)
        post:CMod(speed)
        pocu:CMod(speed)
        return {Mod = 'c', Speed = speed}
    elseif mod == 'm' then
        -- mMod
        popr:MMod(speed)
        posn:MMod(speed)
        post:MMod(speed)
        pocu:MMod(speed)
        return {Mod = 'm', Speed = speed}
    elseif YA_VER:Version() >= 5300 then
        if mod == 'ca' then
            -- caMod
            popr:CAMod(speed)
            posn:CAMod(speed)
            post:CAMod(speed)
            pocu:CAMod(speed)
            return {Mod = 'ca', Speed = speed}
        elseif mod == 'a' then
            -- aMod
            popr:AMod(speed)
            posn:AMod(speed)
            post:AMod(speed)
            pocu:AMod(speed)
            return {Mod = 'a', Speed = speed}
        elseif mod == 'av' and popr.AVMod then
            -- avMod
            popr:AVMod(speed)
            posn:AVMod(speed)
            post:AVMod(speed)
            pocu:AVMod(speed)
            return {Mod = 'av', Speed = speed}
        end
    end
    -- 1.0x
    popr:XMod(1.0)
    posn:XMod(1.0)
    post:XMod(1.0)
    pocu:XMod(1.0)
    return {Mod = 'x', speed = 1}
end

--- 次のスピードを取得する
--[[
    @param  pn プレイヤー
    @return table{string mod, float speed}
--]]
local function GetNextSpeed(self, pn)
    currentSpeed[pn] = currentSpeed[pn] + 1
    if currentSpeed[pn] > #speedList[pn] then currentSpeed[pn] = 1 end
    return speedList[pn][currentSpeed[pn]]
end
--- 前のスピードを取得する
--[[
    @param  pn プレイヤー
    @return table{string mod, float speed}
--]]
local function GetPrevSpeed(self, pn)
    currentSpeed[pn] = currentSpeed[pn] - 1
    if currentSpeed[pn] < 1 then currentSpeed[pn] = #speedList[pn] end
    return speedList[pn][currentSpeed[pn]]
end

--- 次のスピードに設定する
--[[
    @param  pn プレイヤー
    @return table{string mod, float speed}
--]]
local function SetNextSpeed(self, pn)
    local params = YA_SCROLL:GetNext(pn)
    return YA_SCROLL:SetSpeed(pn, params.Mod, params.Speed)
end
--- 前のスピードに設定する
--[[
    @param  pn プレイヤー
    @return table{string mod, float speed}
--]]
local function SetPrevSpeed(self, pn)
    local params = YA_SCROLL:GetPrev(pn)
    return YA_SCROLL:SetSpeed(pn, params.Mod, params.Speed)
end

--- スピードを表示用に整形して取得する
--[[
    @param speed {Mod, Speed}のテーブル
    @return string
--]]
local function ToDisplaySpeed(self, speedTable, ...)
    local decimal = ...
    local mod = string.lower(speedTable.Mod)
    if mod == 'c' then
        return 'C'..speedTable.Speed
    elseif mod == 'm' then
        return 'm'..speedTable.Speed
    elseif mod == 'ca' then
        return 'ca'..speedTable.Speed
    elseif mod == 'a' then
        return 'a'..speedTable.Speed
    end
    -- 整数倍の時に小数にする（1→1.0）
    if decimal and not string.find(''..speedTable.Speed, '.', 0, true) then
        return speedTable.Speed..'.0x'
    end
    return speedTable.Speed..'x'
end

--- プレイヤーの現在のスピードを表示用に整形して取得する
--[[
    @param pn プレイヤー
    @return string
--]]
local function GetDisplayCurrentSpeed(self, pn, ...)
    local decimal = ...
    return YA_SCROLL:ToDisplaySpeed(YA_SCROLL:CurrentSpeed(pn), decimal)
end

--- プレイヤーのスクロール方向を設定する
--[[
    @param pn プレイヤー
    @param float Reverseの値（0～1）
--]]
local function SetCurrentReverse(self, pn, reverse)
    local ps = GAMESTATE:GetPlayerState(pn)
    local popr = ps:GetPlayerOptions("ModsLevel_Preferred")
    local posn = ps:GetPlayerOptions("ModsLevel_Song")
    local post = ps:GetPlayerOptions("ModsLevel_Stage")
    local pocu = ps:GetPlayerOptions("ModsLevel_Current")
    popr:Reverse(reverse)
    posn:Reverse(reverse)
    post:Reverse(reverse)
    pocu:Reverse(reverse)
end

--- プレイヤーの現在のスクロール方向を取得する
--[[
    @param  pn プレイヤー
    @return float
--]]
local function GetCurrentReverse(self, pn)
    local ps = GAMESTATE:GetPlayerState(pn)
    local pop = ps:GetPlayerOptions("ModsLevel_Song")
    return ({pop:Reverse()})[1]
end

--- 値からスクロール方向を表示用テキストで取得する
--[[
    @param  int プレイヤー
    @return string
--]]
local function GetDisplayReverse(value)
    return (value >= 0.5) and 'Reverse' or 'Standard'
end

--- プレイヤーの現在のスクロール方向を表示用テキストで取得する
--[[
    @param  pn プレイヤー
    @return string
--]]
local function GetDisplayCurrentReverse(self, pn)
    return GetDisplayReverse(YA_SCROLL:CurrentReverse(pn))
end

--- GamePlay用Actor
--[[
    @param  bool ハイスピード変更の有効フラグ（未指定の場合も有効）
    @param  bool スクロール方向変更の有効フラグ（未指定の場合も有効）
    @param  table Metricsで定義したCode（{SpeedUp={string}, SpeedDown={string}, ScrollStandard={string}, ScrollReverse={string},}）
    @return Actor
--]]
local actorSpeedParams = {PlayerNumber_P1 = {}, PlayerNumber_P2 = {}}
local actorReverseParams = {PlayerNumber_P1 = {}, PlayerNumber_P2 = {}}
local function ScrollActor(self, ...)
    local actorParams = ...
    actorParams = actorParams or {}
    local enabledSpeed = (actorParams.Speed == nil) and true or actorParams.Speed
    local enabledReverse = (actorParams.Reverse == nil) and true or actorParams.Reverse
    local codes = actorParams.CodeList
    local animeSpeed = actorParams.Transition or 16
    if enabledSpeed == false and enabledReverse == false then
        return Def.ActorFrame({})
    end
    if not codes then
        codes = defaultCodes
    end
    return Def.ActorFrame({
        InitCommand=function(self)
            YA_SCROLL:Load(PLAYER_1)
            YA_SCROLL:Load(PLAYER_2)
        end,
        CodeCommand=function(self, params)
            local pn = params.PlayerNumber
            local codeSpeedUp   = inTable(params.Name, codes.SpeedUp)
            local codeSpeedDown = inTable(params.Name, codes.SpeedDown)
            local codeScrollStandard = inTable(params.Name, codes.ScrollStandard)
            local codeScrollReverse  = inTable(params.Name, codes.ScrollReverse)
            if enabledSpeed ~= false and (codeSpeedUp or codeSpeedDown) then
                local current = YA_SCROLL:CurrentSpeed(pn)
                local new = codeSpeedUp and YA_SCROLL:GetNext(pn) or YA_SCROLL:GetPrev(pn)
                MESSAGEMAN:Broadcast('ChangeSpeed', {
                    Player     = pn,
                    Mod        = current.Mod,
                    Current    = current.Speed,
                    New        = new.Speed,
                    Display    = YA_SCROLL:ToDisplaySpeed(new),
                    Transition = animeSpeed,
                    Speed      = new.Speed, -- deprecation: 過去バージョン互換
                    Anime      = animeSpeed, -- deprecation: 過去バージョン互換
                })
            end
            if enabledReverse ~= false and (codeScrollStandard or codeScrollReverse) then
                local current, new = YA_SCROLL:CurrentReverse(pn), (codeScrollStandard and 0 or 1)
                if math.round(current) ~= new then
                    MESSAGEMAN:Broadcast('ChangeReverse', {
                        Player     = pn,
                        Current    = current,
                        New        = new,
                        Display    = YA_SCROLL:DisplayCurrentReverse(new),
                        Transition = animeSpeed,
                        Reverse    = new, -- deprecation: 過去バージョン互換
                        Anime      = animeSpeed, -- deprecation: 過去バージョン互換
                    })
                end
            end
        end,
        ChangeSpeedMessageCommand = function(self, params)
            self:finishtweening()
            actorSpeedParams[params.Player] = params
            self:playcommand('ChangeSpeed'..ToEnumShortString(params.Player))
        end,
        ChangeSpeedP1Command = function(self)
            local params = actorSpeedParams[PLAYER_1]
            params.Transition = params.Transition - 1
            YA_SCROLL:SetSpeed(params.Player, params.Mod, params.New - (params.New - params.Current) * params.Transition / animeSpeed)
            self:sleep(0.01)
            if params.Transition > 0 then self:queuecommand('ChangeSpeedP1') end
        end,
        ChangeSpeedP2Command = function(self)
            local params = actorSpeedParams[PLAYER_2]
            params.Transition = params.Transition - 1
            YA_SCROLL:SetSpeed(params.Player, params.Mod, params.New - (params.New - params.Current) * params.Transition / animeSpeed)
            self:sleep(0.01)
            if params.Transition > 0 then self:queuecommand('ChangeSpeedP2') end
        end,
        ChangeReverseMessageCommand = function(self, params)
            self:finishtweening()
            actorReverseParams[params.Player] = params
            self:playcommand('ChangeReverse'..ToEnumShortString(params.Player))
        end,
        ChangeReverseP1Command = function(self)
            local params = actorReverseParams[PLAYER_1]
            params.Transition = params.Transition - 1
            YA_SCROLL:SetReverse(params.Player, params.New - (params.New - params.Current) * params.Transition / animeSpeed)
            self:sleep(0.01)
            if params.Transition > 0 then self:queuecommand('ChangeReverseP1') end
        end,
        ChangeReverseP2Command = function(self)
            local params = actorReverseParams[PLAYER_2]
            params.Transition = params.Transition - 1
            YA_SCROLL:SetReverse(params.Player, params.New - (params.New - params.Current) * params.Transition / animeSpeed)
            self:sleep(0.01)
            if params.Transition > 0 then self:queuecommand('ChangeReverseP2') end
        end,
    })
end

return {
    Load    = LoadSpeedList,
    GetNext = GetNextSpeed,
    GetPrev = GetPrevSpeed,
    SetNext = SetNextSpeed,
    SetPrev = SetPrevSpeed,
    Next    = SetNextSpeed, -- deprecation: 過去バージョン互換
    Prev    = SetPrevSpeed, -- deprecation: 過去バージョン互換
    ToDisplaySpeed      = ToDisplaySpeed,
    DisplayCurrentSpeed = GetDisplayCurrentSpeed,
    Speed               = GetDisplayCurrentSpeed, -- deprecation: 過去バージョン互換
    CurrentSpeed = GetCurrentSpeed,
    SetSpeed     = SetCurrentSpeed,
    DisplayCurrentReverse = GetDisplayCurrentReverse,
    Reverse               = GetDisplayCurrentReverse, -- deprecation: 過去バージョン互換
    CurrentReverse = GetCurrentReverse,
    SetReverse     = SetCurrentReverse,
    Actor = ScrollActor,
}
