-- バージョン
local main = 0
local ver = 53
local date = '20260222'

--- WAIEI Coreのバージョンを取得
--[[
    @return string
--]]
local function GetCoreVer(self)
    return ver
end

--- WAIEI Coreの表示用バージョンを取得
--[[
    @return string
--]]
local function GetCoreDisplayVer(self)
    return ''..main..'.'..GetCoreVer(self)..'.'..date
end

local __SMV__ = nil
local function SetSMVersion(self)
    local n=string.lower(ProductFamily())
    local v=string.lower(ProductVersion())
    if n == 'stepmania' then
        if string.find(v, '5.3.', 0, true) then
        -- 5.3.x
            __SMV__= 5300
        elseif string.find(v, '5.2.', 0, true) then
        -- 5.2.x
            __SMV__= 5200
        elseif string.find(v, '5.1.-', 0, true) then
        -- 5.1.-x
            __SMV__= 5190
        elseif string.find(v, '5.1-git', 0, true) then
        -- 5.1 NightlyBuilds
            __SMV__= 5110
        elseif string.find(v, '5.1.', 0, true) then
        -- 5.1.x
            __SMV__= 5100
        elseif string.find(v, '5.0.7rc', 0, true) then
        -- 5.0.7rc
            __SMV__= 69
        elseif string.find(v, '5.0.%d+$') then
        -- 5.0.5 - 5.0.12
        -- 50 - 120
            __SMV__= tonumber(split('%.', v)[3])*10
        elseif string.find(v, 'v5.0 beta 4', 0, true) then
        -- b4, b4a
            __SMV__= 40
        elseif string.find(v, 'v5.0 beta', 0, true) then
        -- b1 - b3
            __SMV__= 30
        else
            __SMV__= 0
        end
    elseif n == 'outfox' then
        __SMV__= 5300
        local spl_v = split('%.', v)
        if #spl_v >= 2 then
            spl_v[2] = split('[-.]', spl_v[2])[1]
            if spl_v[1] == '0' then
                if tonumber(spl_v[2]) >= 6 then
                    -- Beta
                    __SMV__= 600000
                elseif spl_v[2] == '5' then
                    -- Alpha 0.5
                    __SMV__= 530500
                elseif spl_v[2] == '4' then
                    -- Alpha 0.4.x
                    __SMV__= 530401
                end
            elseif spl_v[1] == '4' then
                -- 昔の0.4系は4.xxだった
                __SMV__= 530400
            end
        end
    elseif n == 'itgmania' then
        -- ITGMania
        __SMV__= 5101
    else
        __SMV__= 0
    end
    return __SMV__
end

--- StepManiaのバージョンを整数に変換して取得
--[[
    @return int
--]]
local function GetSMVersion(self)
    return __SMV__ or SetSMVersion(self)
end

return {
    Core    = GetCoreVer,
    Display = GetCoreDisplayVer,
    Version = GetSMVersion
}
