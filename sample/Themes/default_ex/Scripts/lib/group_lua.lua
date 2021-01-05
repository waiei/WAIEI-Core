--[[ Group_Lua v1.0 alpha 20210105 ]]

-- Rawデータ
local groupRaw = {}
-- 管理用変数に保存対象のキー
local cacheSupportKeys = {
    'Name',
    'GroupColor',
    'OriginalName',
    'MenuColor',
    'MeterType',
    'LyricType',
}
-- 管理用変数
local groupParams = {}
for i=1,#cacheSupportKeys do
    groupParams[cacheSupportKeys[i]] = {}
end

-- デフォルト値
local default = {
    GroupColor = nil,
    MenuColor  = nil,
    MeterType  = 'DDR',
    LyricType  = 'Default',
}

-- 値の型（文字列のキーは定義不要）
local valueType = {
    GroupColor = 'color',
    MenuColor  = 'color',
}

local songPathList = {
    '/Songs/',
    '/AdditionalSongs/',
}

-- このファイルの相対パス
local relativePath = string.gsub(string.sub(debug.getinfo(1).source, 2), '(.+/)[^/]+', '%1')

-- Group.ini処理用
-- 同じディレクトリにgroup_ini.luaがある場合のみ読みこみ
local groupIniFile = 'group_ini.lua'
local groupIni
if FILEMAN:DoesFileExist(relativePath..groupIniFile) then
    groupIni = LoadActor(groupIniFile)
end

-- ファイルを検索してパスを返却（大文字小文字を無視）
-- p1:グループ名
-- p2:ファイル名
local function SearchFile(groupName, fileName)
    for i=1, #songPathList do
        local dirList = FILEMAN:GetDirListing(songPathList[i]..groupName)
        for d=1, #dirList do
            if string.lower(dirList[d]) == string.lower(fileName) then
                return songPathList[i]..groupName..dirList[d]
            end
        end
    end
    return nil
end

-- カラーとして変換
local function ConvertColor(input)
    -- 文字列
    if type(input) == 'string' then
        return color(input)
    end
    -- カラー型
    if type(input) == 'table' and #input == 4
        and type(input[1]) == 'number'
        and type(input[2]) == 'number'
        and type(input[3]) == 'number'
        and type(input[4]) == 'number' then
        return {
            math.max(math.min(input[1], 1.0), 0.0),
            math.max(math.min(input[2], 1.0), 0.0),
            math.max(math.min(input[3], 1.0), 0.0),
            math.max(math.min(input[4], 1.0), 0.0),
        }
    end
    -- カラーとして変換できない
    return nil
end

-- Songからパスを小文字で取得（/...Songs/は取得しない）
local function GetSongLowerDir(song)
    return string.lower(string.gsub(song:GetSongDir(), '/[^/]*Songs/(.+)', '%1'))
end

-- Group.iniを読み込む
local function LoadGroupIni(filePath)
    if filePath and groupIni then
        return groupIni:Load(filePath)
    else
        return {}
    end
end

-- グループ単位で情報を持つことができるパラメータを管理用変数に保存
local function SetGroupParams(groupName, key, data)
    -- 色として扱うパラメータ
    if valueType[key] == 'color' then
        local convertedColor = ConvertColor(data)
        if convertedColor then
            groupParams[key][groupName] = convertedColor
        else
            groupParams[key][groupName] = default[key]
        end
    -- 文字列として扱うパラメータ
    else
        groupParams[key][groupName] = data
    end
end

-- 楽曲単位で情報を持つことができるパラメータを解析して管理用変数に保存
local function SetMultiParams(groupName, key, data)
    -- グループ単位、楽曲単位どちらで定義しているかチェック
    -- 色として扱うパラメータ
    if valueType[key] == 'color' then
        groupParams[key][groupName] = ConvertColor(data)
        -- ひとつのカラーが定義されている場合、グループ単位の定義
        if groupParams[key][groupName] then
            return
        end
    -- 文字列として扱うパラメータ
    else
        -- 値が文字列の場合はグループ単位の定義
        if type(data) == 'string' then
            groupParams[key][groupName] = data
            return
        end
    end
    -- 楽曲単位の定義
    -- 定義
    local valueList = {Default = default[key] or groupName}
    for k,v in pairs(data[1] or {}) do
        valueList[k] = (valueType[key] == 'color') and ConvertColor(v) or v
    end
    -- グループデフォルト
    groupParams[key][groupName] = valueList.Default
    -- 定義されてるデータ分ループ
    for k,v in pairs(valueList) do
        if k ~= 'Default' then  -- デフォルトは無視
            for s=1, #(data[k] or {}) do
                groupParams[key][string.lower(groupName..'/'..data[k][s]..'/')] = v
            end
        end
    end
end

-- Grouop.luaまたはGroup.iniを読み込んでRawデータとして保存
local function SetRaw(groupName, groupLuaPath, groupIniPath)
    groupRaw[groupName] = nil
    if groupLuaPath then
        -- Group.luaを読み込み、エラーがあれば処理を行わない
        local f = RageFileUtil.CreateRageFile()
        if not f:Open(groupLuaPath, 1) then
            f:destroy()
            return
        end
        -- BOMがあるとエラーになるので回避
        local luaData = string.gsub(f:Read(), '^'..string.char(0xef, 0xbb, 0xbf)..'(.?)', '%1')
        f:Close()
        f:destroy()
        local luaString, errMsg
        -- loadstringはLua5.2以降廃止
        -- assertでエラーをキャッチするとluaDataの中身が出力されるのでここではキャッチしない
        if _VERSION == 'Lua 5.1' then
            luaString, errMsg = loadstring(luaData)
        else
            luaString, errMsg = load(luaData)
        end
        -- エラー発生時に変数の中身が出力されてもメッセージが流れないようにクリア
        luaData = nil
        if not luaString and errMsg then
            error('Group.lua ERROR : '..groupName..'\n'..errMsg, 0)
            return
        end
        groupRaw[groupName] = luaString()
    else
        -- Group.luaが存在しない場合はiniを変換する
        groupRaw[groupName] = LoadGroupIni(groupIniPath)
    end
end

-- グループ情報のテーブルを取得
-- p1:グループ名
-- p2:取得するキー（nil）
local function GetRaw(self, groupName, ...)
    local key = ...
    -- キーを指定していない場合はグループの情報か空テーブルを返却
    if not key then
        return groupRaw[groupName] or {}
    end
    -- キーの指定がある場合
    -- グループの情報が無い場合はnil
    if not groupRaw[groupName] then
        return nil
    end
    -- キーが見つかった場合は返却
    if groupRaw[groupName][key] then
        return groupRaw[groupName][key]
    end
    -- キーの大文字小文字を無視して取得
    key = string.lower(key)
    for k,v in pairs(groupRaw[groupName]) do
        if key == string.lower(k) then
            return groupRaw[groupName][k]
        end
    end
    -- ヒットしない場合はnil
    return nil
end

-- フォルダをスキャン
-- p1:グループ名 (false)
-- p2:グループ名 (nil)
local function Scan(self, ...)
    local forceReload, groupName = ...
    forceReload = (forceReload ~= nil) and forceReload or false
    -- グループ名の指定がない場合は全グループを検索
    if not groupName then
        for i, group in pairs(SONGMAN:GetSongGroupNames()) do
            Scan(self, forceReload, group)
        end
        return
    end
    
    local groupLuaPath = SearchFile(groupName..'/', 'group.lua')

    -- 強制再読み込みが無効で、すでに読み込み済みの場合は処理を行わない（Group.iniのみ）
    local hasData = false
    for k,v in pairs(GetRaw(self, groupName)) do
        if v then
            hasData = true
            break
        end
    end
    if not groupLuaPath and hasData and not forceReload then
        return
    end
    
    -- 読みこんでRawに保存
    local groupIniPath = (not groupLuaPath) and SearchFile(groupName..'/', 'group.ini') or nil
    SetRaw(groupName, groupLuaPath, groupIniPath)
    
    -- グループごとに情報を持つことができるパラメータを設定
    local groupParams = {
        'Name',
        'GroupColor',
    }
    for i=1, #groupParams do
        SetGroupParams(groupName, groupParams[i], GetRaw(self, groupName, groupParams[i]) or nil)
    end
    
    -- 楽曲ごとに情報を持つことができるパラメータを設定
    local multiParams = {
        'OriginalName',
        'MenuColor',
        'MeterType',
        'LyricType',
    }
    for i=1, #multiParams do
        SetMultiParams(groupName, multiParams[i], GetRaw(self, groupName, multiParams[i]) or {})
    end
end

-- グループ名を取得
-- p1:グループ名
local function GetGroupName(self, groupName)
    return groupParams.Name[groupName] or SONGMAN:ShortenGroupName(groupName)
end

-- グループカラーを取得
-- p1:グループ名
local function GetGroupColor(self, groupName)
    return groupParams.GroupColor[groupName] or default.GroupColor or SONGMAN:GetSongGroupColor(groupName)
end

-- URLを取得
-- p1:グループ名
local function GetUrl(self, groupName)
    return GetRaw(self, groupName, 'Url') or ''
end

-- コメントを取得
-- p1:グループ名
-- p2:改行を有効（true）
local function GetComment(self, groupName, ...)
    local enableLineBreaks = ...
    enableLineBreaks = (enableLineBreaks == nil) and true or enableLineBreaks
    local comment = GetRaw(self, groupName, 'Comment') or ''
    if enableLineBreaks then
        return comment
    end
    return string.gsub(comment, '(.-)[\n]', '%1 ')
end

-- song型からORIGINALNAMEを取得
-- p1:Song
local function GetOriginalName(self, song)
    return groupParams.OriginalName[GetSongLowerDir(song)] 
        or groupParams.OriginalName[song:GetGroupName()]
        or song:GetGroupName()
end

-- song型からMETERTYPEを取得
-- p1:Song
local function GetMeterType(self, song)
    return groupParams.MeterType[GetSongLowerDir(song)] 
        or groupParams.MeterType[song:GetGroupName()]
        or default.MeterType
end

-- song型からMENUCOLORを取得
-- p1:Song
local function GetMenuColor(self, song)
    return groupParams.MenuColor[GetSongLowerDir(song)] 
        or groupParams.MenuColor[song:GetGroupName()]
        or default.MenuColor
        or SONGMAN:GetSongColor(song)
end

-- song型からLYRICTYPEを取得
-- p1:Song
local function GetLyricType(self, song)
    return groupParams.LyricType[GetSongLowerDir(song)] 
        or groupParams.LyricType[song:GetGroupName()]
        or default.LyricType
end

-- デフォルト値を設定
-- p1:キー
-- p2:値
-- 例えばMenuColorのデフォルトを白にしたい場合、xx:Default('MenuColor', Color('White'))
local function SetDefaultValue(self, key, value)
    default[key] = value
    return value
end

-- ソートファイルを作成
-- p1:ソートファイル名（Group）
-- p2:グループをNameで指定したテキストでソート（true）
local function CreateSortText(self, ...)
    local sortName, groupNameSort = ...
    sortName = sortName or 'Group'
    groupNameSort = (groupNameSort == nil) and true or groupNameSort
    -- 1文字目が英数字以外の場合、ソートで後ろに行くように先頭にstring.char(126)をつける
    local Adjust = function(text)
        return string.gsub(string.gsub(text, '^%.', ''), '^([^%w])', string.char(126)..'%1')
    end
    local f = RageFileUtil.CreateRageFile()
    if not f:Open(THEME:GetCurrentThemeDirectory()..'Other/SongManager '..sortName..'.txt', 2) then
        f:destroy()
        return data
    end
    local groupList = {}
    for g, groupName in pairs(SONGMAN:GetSongGroupNames()) do
        groupList[#groupList+1] = {
            Original = groupName,
            Sort     = string.lower(groupNameSort and Adjust(GetGroupName(self, groupName)) or groupName),
        }
    end
    table.sort(groupList, function(a, b)
                return a.Sort < b.Sort
            end)
    for g = 1, #groupList do
        local groupName = groupList[g].Original
        local sortData = GetRaw(self, groupName, 'SortList') or {}
        local sortList = {
            Default = 0,
            Front   = -1,
            Rear    = 1,
            Hidden  = 0,
        }
        local sortOrder = {}
        -- ソート優先度を定義しているか取得
        for k,v in pairs(sortData[1] or {}) do
            sortList[k] = tonumber(v)
        end
        -- ソート順序を設定
        for k,v in pairs(sortList) do
            if k ~= 'Default' then  -- デフォルトは無視
                for i, dir in pairs(sortData[k] or {}) do
                    sortOrder[string.lower(dir)] = (k ~= 'Hidden') and i + 100000 * sortList[k] or 0
                end
            end
        end
        -- ソート用のテーブル作成
        local dirList = {}
        local dirCount = 0
        for i, song in pairs(SONGMAN:GetSongsInGroup(groupName)) do
            local dir = song:GetSongDir()
            local splitDir = split('/', dir)
            -- 楽曲フォルダ名（小文字）を取得
            local key = string.lower(string.gsub(dir, '/[^/]*Songs/[^/]+/([^/]+)/', '%1'))
            if sortOrder[key] ~= 0 then    -- 0 = Hidden（※Default = nil）
                dirCount = dirCount + 1
                dirList[#dirList+1] = {
                    Dir  = string.gsub(dir, '/[^/]*Songs/(.+)', '%1'),
                    Sort = sortOrder[key] or 0,
                    Name = string.lower(Adjust(song:GetTranslitMainTitle()..'  '..song:GetTranslitSubTitle())),
                }
            end
        end
        if dirCount > 0 then
            table.sort(dirList, function(a, b)
                                    if a.Sort ~= b.Sort then
                                        return a.Sort < b.Sort
                                    else
                                        return a.Name < b.Name
                                    end
                                end)
            f:PutLine("---"..groupName)
            for i,dir in pairs(dirList) do
                f:PutLine(dir.Dir)
            end
        end
    end
    f:Close()
    f:destroy()
    SONGMAN:SetPreferredSongs(sortName)
end

return {
    Scan         = Scan,
    Raw          = GetRaw,
    Name         = GetGroupName,
    GroupColor   = GetGroupColor,
    Url          = GetUrl,
    Comment      = GetComment,
    OriginalName = GetOriginalName,
    MenuColor    = GetMenuColor,
    MeterType    = GetMeterType,
    LyricType    = GetLyricType,
    Sort         = CreateSortText,
    Default      = SetDefaultValue,
}


--[[
Group_lua.lua

Copyright (c) 2021 A.C

This software is released under the MIT License.
https://opensource.org/licenses/mit-license.php
--]]