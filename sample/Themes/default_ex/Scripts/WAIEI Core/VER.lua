-- バージョン
local ver = 27
local date = '20210426'

--- WAIEI Coreのバージョンを取得
--[[
    @return string
--]]
local function coreVer()
    return ver
end

--- WAIEI Coreの表示用バージョンを取得
--[[
    @return string
--]]
local function coreDisplayVer()
    return '0.'..coreVer()..'.'..date
end

local __SMV__ = nil
local function SetSMVersion()
    local v=string.lower(ProductVersion())
    if string.find(v,"5.3",0,true) then
    -- 5.3.x
        __SMV__= 5300
    elseif string.find(v,"5.2",0,true) then
    -- 5.2.x
        __SMV__= 5200
    elseif string.find(v,"5.1.-",0,true) then
    -- 5.1.-x
        __SMV__= 5190
    elseif string.find(v,"5.1",0,true) then
    -- 5.1.x
        __SMV__= 5100
    elseif string.find(v,"5.0.7rc",0,true) then
    -- 5.0.7rc
        __SMV__= 69
    elseif string.find(v,"5.0.%d+$") then
    -- 5.0.5 - 5.0.12
    -- 50 - 120
        __SMV__= tonumber(split('%.', v)[3])*10
    elseif string.find(v,"v5.0 beta 4",0,true) then
    -- b4, b4a
        __SMV__= 40
    elseif string.find(v,"v5.0 beta",0,true) then
    -- b1 - b3
        __SMV__= 30
    else
        __SMV__= 0
    end
    return __SMV__
end

--- StepManiaのバージョンを整数に変換して取得
--[[
    @return int
--]]
local function GetSMVersion()
    return __SMV__ or SetSMVersion()
end

return {
    Core    = coreVer,
    Display = coreDisplayVer,
    Version = GetSMVersion
}
