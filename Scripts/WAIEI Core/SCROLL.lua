-- ハイスピードとリバース切り替え
-- Original code by speedkills v2

local defaultSpeedList = '0.25x,0.5x,0.75x,1.0x,1.25x,1.5x,2.0x,2.5x,3.0x,5.0x,8.0x,C200,C400,m550'
local defaultCodes = {
    SpeedUp        = {'SpeedUp', 'SpeedUp2'},
    SpeedDown      = {'SpeedDown', 'SpeedDown2'},
    ScrollStandard = {'ScrollStandard', 'ScrollStandard2'},
    ScrollReverse  = {'ScrollReverse', 'ScrollReverse2'},
}

local speedList = {PlayerNumber_P1 = {}, PlayerNumber_P2 = {}}
local currentSpeed = {PlayerNumber_P1 = 1, PlayerNumber_P2 = 1}

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

--- プレイヤーの現在のスピードを取得する
--[[
    @param  Player プレイヤー
    @return table{string mod, float speed}
--]]
local function GetCurrentSpeed(player)
    return speedList[player][currentSpeed[player]]
end

--- プレイヤーの現在のスピードオプションを取得する
--[[
    @param  Player プレイヤー
    @return string, float
--]]
local function GetCurrentMod(player)
    local ps = GAMESTATE:GetPlayerState(player)
    local pop = ps:GetPlayerOptions("ModsLevel_Preferred")
    local mod = 'x'
    local speed = 1.0
    if ({pop:CMod()})[1] then
        mod   = 'c'
        speed = tonumber(({pop:CMod()})[1])
    elseif ({pop:MMod()})[1] then
        mod   = 'm'
        speed = tonumber(({pop:MMod()})[1])
    elseif ({pop:XMod()})[1] then
        mod   = 'x'
        speed = tonumber(({pop:XMod()})[1])
    end
    return mod, speed
end

--- プレイヤーの現在のスピードを一覧からキー番号で取得する
--[[
    @param  Player プレイヤー
    @return int
--]]
local function GetCurrentSpeedKey(player)
    local mod ,speed = GetCurrentMod(player)
    local current = 1
    local list    = speedList[player]
    for i=current,#list do
        if list[i]['mod'] == mod then
            current = i
            if list[i]['speed'] >= speed then
                break
            end
        end
    end
    return current
end

--- プレイヤーのスピード一覧を取得する
--[[
    LocalまたはMachineのSpeedMod.txtを取得する
    @param  Player プレイヤー
    @return table,{{{string mod , float speed},...},...}, int current_index
--]]
local function LoadSpeedList(self, player)
    local file = YA_FILE:Profile('SpeedMods.txt', player)
    local speeds = file and file:Read() or ''
    if speeds == '' then
        speeds = defaultSpeedList
    end
    local strSpeeds = split(',', speeds)
    for i=1, #strSpeeds do
        if string.find(strSpeeds[i], '[%d.]+x') then
            speedList[player][i] = {
                mod   = 'x',
                speed = tonumber(split('x', strSpeeds[i])[1]),
            }
        elseif string.find(strSpeeds[i], 'C[%d.]+') then
            speedList[player][i] = {
                mod   = 'c',
                speed = tonumber(split('C', strSpeeds[i])[2]),
            }
        elseif string.find(strSpeeds[i], 'm[%d.]+') then
            speedList[player][i] = {
                mod   = 'm',
                speed = tonumber(split('m', strSpeeds[i])[2]),
            }
        end
    end
    
    currentSpeed[player] = GetCurrentSpeedKey(player)
    
    return speedList, currentSpeed[player]
end

--- 次のスピードのキーを取得する
--[[
    @param  Player プレイヤー
    @return int
--]]
local function GetNextSpeedKey(player)
    local list = speedList[player]
    local mod  = list[currentSpeed[player]]['mod']
    for i=1,#list do
        local key = ((currentSpeed[player] + i - 1) % #list) + 1
        if list[key]['mod'] == mod then
            return key
        end
    end
    return currentSpeed[player]
end

--- 前のスピードのキーを取得する
--[[
    @param  Player プレイヤー
    @return int
--]]
local function GetPrevSpeedKey(player)
    local list = speedList[player]
    local mod  = list[currentSpeed[player]]['mod']
    for i=1,#list do
        local key = currentSpeed[player] - i
        if key < 1 then key = key + #list end
        if list[key]['mod'] == mod then
            return key
        end
    end
    return currentSpeed[player]
end

--- プレイヤーのスピードを設定する
--[[
    @param  Player プレイヤー
    @param  string MOD(x c mのいずれか)
    @param  float スピード
    @return table{string mod , float speed}
--]]
local function SetSpeed(player, mod, speed)
    local ps = GAMESTATE:GetPlayerState(player)
    local pop = ps:GetPlayerOptions("ModsLevel_Preferred")
    local post = ps:GetPlayerOptions("ModsLevel_Stage")
    local posn = ps:GetPlayerOptions("ModsLevel_Song")
    local poc = ps:GetPlayerOptions("ModsLevel_Current")
    if mod == 'x' then
        -- xMod
        pop:XMod(speed)
        post:XMod(speed)
        posn:XMod(speed)
        poc:XMod(speed)
        return {mod = 'x', speed = speed}
    elseif mod == 'c' then
        -- CMod
        pop:CMod(speed)
        post:CMod(speed)
        posn:CMod(speed)
        poc:CMod(speed)
        return {mod = 'c', speed = speed}
    elseif mod == 'm' then
        -- mMod
        pop:MMod(speed)
        post:MMod(speed)
        posn:MMod(speed)
        poc:MMod(speed)
        return {mod = 'm', speed = speed}
    end
    -- 1.0x
    pop:XMod(1.0)
    post:XMod(1.0)
    posn:XMod(1.0)
    poc:XMod(1.0)
    return {mod = 'x', speed = 1}
end

--- 次のスピードに設定する
--[[
    @param  Player プレイヤー
    @return table{string mod, float speed}
--]]
local function SetNextSpeed(self, player)
    local key    = GetNextSpeedKey(player)
    local params = speedList[player][key]
    return SetSpeed(player, params['mod'], params['speed'])
end
--- 前のスピードに設定する
--[[
    @param  Player プレイヤー
    @return table{string mod, float speed}
--]]
local function SetPrevSpeed(self, player)
    local key    = GetPrevSpeedKey(player)
    local params = speedList[player][key]
    return SetSpeed(player, params['mod'], params['speed'])
end

--- プレイヤーの現在のスピードを表示用に整形して取得する
--[[
    @param Player プレイヤー
    @return string
--]]
local function GetDisplayCurrentSpeed(self, player)
    local current = GetCurrentSpeed(player)
    if current['mod'] == 'c' then
        return 'C'..current['speed']
    elseif current['mod'] == 'm' then
        return 'm'..current['speed']
    end
    return current['speed']..'x'
end

--- プレイヤーのスクロール方向を設定する
--[[
    @param Player プレイヤー
    @param float Reverseの値（0～1）
--]]
local function SetReverse(player, reverse)
    local ps = GAMESTATE:GetPlayerState(player)
    local pop = ps:GetPlayerOptions("ModsLevel_Preferred")
    local post = ps:GetPlayerOptions("ModsLevel_Stage")
    local posn = ps:GetPlayerOptions("ModsLevel_Song")
    local poc = ps:GetPlayerOptions("ModsLevel_Current")
    pop:Reverse(reverse)
    post:Reverse(reverse)
    posn:Reverse(reverse)
    poc:Reverse(reverse)
end

--- プレイヤーの現在のスクロール方向を取得する
--[[
    @param  Player プレイヤー
    @return float
--]]
local function GetCurrentReverse(player)
    local ps = GAMESTATE:GetPlayerState(player)
    local pop = ps:GetPlayerOptions("ModsLevel_Preferred")
    return ({pop:Reverse()})[1]
end

--- 値からスクロール方向を表示用テキストで取得する
--[[
    @param  Player プレイヤー
    @return string
--]]
local function GetDisplayReverse(value)
    return (value >= 0.5) and 'Reverse' or 'Standard'
end

--- プレイヤーの現在のスクロール方向を表示用テキストで取得する
--[[
    @param  Player プレイヤー
    @return string
--]]
local function GetDisplayCurrentReverse(self, player)
    return GetDisplayReverse(GetCurrentReverse(player))
end

--- GamePlay用Actor
--[[
    @param  bool ハイスピード変更の有効フラグ（未指定の場合も有効）
    @param  bool スクロール方向変更の有効フラグ（未指定の場合も有効）
    @param  table Metricsで定義したCode（{SpeedUp={string}, SpeedDown={string}, ScrollStandard={string}, ScrollReverse={string},}）
	@return Actor
--]]
local animeSpeed = 16
local actorSpeedParams = {PlayerNumber_P1 = {}, PlayerNumber_P2 = {}}
local actorReverseParams = {PlayerNumber_P1 = {}, PlayerNumber_P2 = {}}
local function ScrollActor(self, ...)
    local enabledSpeed,enabledReverse,codes = ...
    if enabledSpeed == false and enabledReverse == false then
        return Def.Actor({})
    end
    if not codes then
        codes = defaultCodes
    end
    return Def.Actor({
        InitCommand=function(self)
            YA_SCROLL:Load(PLAYER_1)
            YA_SCROLL:Load(PLAYER_2)
        end,
        CodeCommand=function(self, params)
            local player = params.PlayerNumber
            local codeSpeedUp   = inTable(params.Name, codes['SpeedUp'])
            local codeSpeedDown = inTable(params.Name, codes['SpeedDown'])
            local codeScrollStandard = inTable(params.Name, codes['ScrollStandard'])
            local codeScrollReverse  = inTable(params.Name, codes['ScrollReverse'])
            if enabledSpeed ~= false and (codeSpeedUp or codeSpeedDown) then
                local key = codeSpeedUp and GetNextSpeedKey(player) or GetPrevSpeedKey(player)
                local current = GetCurrentSpeed(player)
                actorSpeedParams[player]['mod']     = current['mod']
                actorSpeedParams[player]['current'] = current['speed']
                actorSpeedParams[player]['new']     = speedList[player][key]['speed']
                actorSpeedParams[player]['anime']   = animeSpeed
                currentSpeed[player] = key
                self:playcommand('ChangeSpeed'..ToEnumShortString(player))
                MESSAGEMAN:Broadcast('ChangeSpeed', {
                    Player  = player,
                    Mod     = speedList[player][key]['mod'],
                    Speed   = speedList[player][key]['speed'],
                    Display = GetDisplayCurrentSpeed(self, player),
                })
            end
            if enabledReverse ~= false and (codeScrollStandard or codeScrollReverse) then
                actorReverseParams[player]['current'] = GetCurrentReverse(player)
                actorReverseParams[player]['new']     = codeScrollStandard and 0 or 1
                actorReverseParams[player]['anime']   = animeSpeed
                self:playcommand('ChangeReverse'..ToEnumShortString(player))
                MESSAGEMAN:Broadcast('ChangeReverse', {
                    Player  = player,
                    Reverse = actorReverseParams[player]['new'],
                    Display = GetDisplayReverse(actorReverseParams[player]['new']),
                })
            end
        end,
        ChangeSpeedP1Command = function(self)
            self:finishtweening()
            local player = PLAYER_1
            local params = actorSpeedParams[player]
            if params['anime'] > 0 then
                SetSpeed(player, params['mod'], params['current'] + (params['new'] - params['current']) * (animeSpeed - params['anime']) / animeSpeed)
                actorSpeedParams[player]['anime'] = params['anime'] - 1
                self:sleep(0.01)
                self:queuecommand('ChangeSpeed'..ToEnumShortString(player))
            else
                SetSpeed(player, params['mod'], params['new'])
            end
        end,
        ChangeSpeedP2Command = function(self)
            self:finishtweening()
            local player = PLAYER_2
            local params = actorSpeedParams[player]
            if params['anime'] > 0 then
                SetSpeed(player, params['mod'], params['current'] + (params['new'] - params['current']) * (animeSpeed - params['anime']) / animeSpeed)
                actorSpeedParams[player]['anime'] = params['anime'] - 1
                self:sleep(0.01)
                self:queuecommand('ChangeSpeed'..ToEnumShortString(player))
            else
                SetSpeed(player, params['mod'], params['new'])
            end
        end,
        ChangeReverseP1Command = function(self)
            self:finishtweening()
            local player = PLAYER_1
            local params = actorReverseParams[player]
            if params['anime'] > 0 then
                SetReverse(player, params['current'] + (params['new'] - params['current']) * (animeSpeed - params['anime']) / animeSpeed)
                actorReverseParams[player]['anime'] = params['anime'] - 1
                self:sleep(0.01)
                self:queuecommand('ChangeReverse'..ToEnumShortString(player))
            else
                SetReverse(player, params['new'])
            end
        end,
        ChangeReverseP2Command = function(self)
            self:finishtweening()
            local player = PLAYER_2
            local params = actorReverseParams[player]
            if params['anime'] > 0 then
                SetReverse(player, params['current'] + (params['new'] - params['current']) * (animeSpeed - params['anime']) / animeSpeed)
                actorReverseParams[player]['anime'] = params['anime'] - 1
                self:sleep(0.01)
                self:queuecommand('ChangeReverse'..ToEnumShortString(player))
            else
                SetReverse(player, params['new'])
            end
        end,
    })
end

return {
    Load    = LoadSpeedList,
    Next    = SetNextSpeed,
    Prev    = SetPrevSpeed,
    Actor   = ScrollActor,
    Speed   = GetDisplayCurrentSpeed,
    Reverse = GetDisplayCurrentReverse,
}
