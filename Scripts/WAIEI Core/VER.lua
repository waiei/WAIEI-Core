-- バージョン
local ver = 10
local date = '20180527'
local function coreVer()
	return ver
end

local function coreDisplayVer()
	return '0.'..coreVer()..'.'..date
end

local __SMV__ = nil
local function SetSMVersion()
	local v=string.lower(ProductVersion())
	if string.find(v,"5.2",0,true) then
	-- 5.2.x
		__SMV__= 5200
	elseif string.find(v,"5.1",0,true) then
	-- 5.1.x
		__SMV__= 5100
	elseif string.find(v,"5.0.1",0,true) then
	-- 5.0.1x
		__SMV__= 100
	elseif string.find(v,"5.0.7rc",0,true) or string.find(v,"5.0.6",0,true) or string.find(v,"5.0.5",0,true) then
	-- 5.0.5 - 5.0.7rc
		__SMV__= 50
	elseif string.find(v,"5.0.",0,true) then
	-- 5.0.7 - 5.0.9
		__SMV__= 70
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

local function GetSMVersion()
	return __SMV__ or SetSMVersion()
end

return {
	Core    = coreVer,
	Display = coreDisplayVer,
	Version = GetSMVersion
}
