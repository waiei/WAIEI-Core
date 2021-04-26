-- Group.ini/Lua

local scanned = false

-- デフォルト値
local defaultGroupColor = nil
local defaultMenuColor = color('1, 1, 1, 1')
local defaultMeterType = 'DDR'

--- Songから楽曲のフォルダ名を取得する
--[[
    @param  Song 楽曲
    @return フォルダ名
--]]
local function GetSongFolderName(self, song)
    local folderPath = split('/', song:GetSongDir())
    return folderPath[#folderPath-1]
end

--- すべての楽曲をスキャン
--[[
    @param bool Group.iniの再読み込み
--]]
local function ScanAllSongs(self, ...)
    local force = ...
    YA_LIB.GROUP:Scan(force)
    scanned = true
end

--- グループ名を取得
--[[
    @param  string グループフォルダ名
    @return Color
--]]
local function GetGroupName(self, groupName)
    if not scanned then ScanAllSongs(self) end
    return YA_LIB.GROUP:Name(groupName)
end

--- グループカラーを取得
--[[
    @param  string グループフォルダ名
    @return Color
--]]
local function GetGroupColor(self, groupName)
    if not scanned then ScanAllSongs(self) end
    return YA_LIB.GROUP:GroupColor(groupName)
end

--- 楽曲カラーを取得
--[[
    @param  Song 楽曲
    @return color
--]]
local function GetSongMenuColor(self, song)
    if not scanned then ScanAllSongs(self) end
    return YA_LIB.GROUP:MenuColor(song)
end

--- MeterTypeを取得
--[[
    @param  Song 楽曲
    @return string
--]]
local function GetSongMeterType(self, song)
    if not scanned then ScanAllSongs(self) end
    return YA_LIB.GROUP:MeterType(song)
end

--- オリジナルグループ名を取得
--[[
    @param  Song 楽曲
    @return string
--]]
local function GetSongOriginalName(self, song)
    if not scanned then ScanAllSongs(self) end
    return YA_LIB.GROUP:OriginalName(song)
end

--- URLを取得
--[[
    @param  string グループフォルダ名
    @return string
--]]
local function GetUrl(self, groupName)
    if not scanned then ScanAllSongs(self) end
    return YA_LIB.GROUP:Url(groupName)
end

--- COMMENTを取得
--[[
    @param  string グループフォルダ名
    @param  string コメントの改行を許可
    @return string
--]]
local function GetComment(self, groupName, enableLineBreaks)
    if not scanned then ScanAllSongs(self) end
    return YA_LIB.GROUP:Comment(groupName, enableLineBreaks)
end

--- 歌詞表示モードを取得
--[[
    @param  Song 楽曲
    @return string
--]]
local function GetLyricType(self, song)
    if not scanned then ScanAllSongs(self) end
    return YA_LIB.GROUP:LyricType(song)
end

--- ユーザーソートファイルを作成
--[[
    Otherフォルダにソート定義ファイルを作成する
    実際にソート対象にするには SONGMAN:SetPreferredSongs の呼び出しが必要
    @param string ソートファイル名
--]]
local function CreateSortText(self, filename)
    if not scanned then ScanAllSongs(self) end
    YA_LIB.GROUP:Sort(filename)
end

--- デフォルト値の設定
--[[
	@param table{MenuColor,MeterType,GroupColor} 初期値
--]]
local function SetDefaultValues(self, values)
    defaultMenuColor  = YA_LIB.GROUP:Default('MenuColor', values.MenuColor or nil)
    defaultMeterType  = YA_LIB.GROUP:Default('MeterType', values.MeterType  or defaultMeterType)
    defaultGroupColor = YA_LIB.GROUP:Default('GroupColor', values.GroupColor or nil)
end
SetDefaultValues(self, {
    GroupColor = defaultGroupColor,
    MenuColor  = defaultMenuColor,
    MeterType  = defaultMeterType,
})

return {
    FolderName    = GetSongFolderName,
    Scan          = ScanAllSongs,
    GroupName     = GetGroupName,
    GroupColor    = GetGroupColor,
    Url           = GetUrl,
    Comment       = GetComment,
    OriginalName  = GetSongOriginalName,
    MenuColor     = GetSongMenuColor,
    MeterType     = GetSongMeterType,
    LyricType     = GetLyricType,
    SortSongs     = CreateSortText,
    DefaultValues = SetDefaultValues,
}
