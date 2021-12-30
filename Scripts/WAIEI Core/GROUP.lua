-- Group.ini/Lua

local scanned = false
YA_LIB.GROUP:AddKey('ReceptorPosition', 'mixed')

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
local function ScanAllSongs(self)
    YA_LIB.GROUP:Scan()
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
        or ((groupName ~= '') and SONGMAN:GetSongGroupColor(groupName) or Color('White'))
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
    return YA_LIB.GROUP:Url(groupName) or ''
end

--- COMMENTを取得
--[[
    @param  string グループフォルダ名
    @param  string コメントの改行を許可
    @return string
--]]
local function GetComment(self, groupName, ...)
    local enableLineBreaks = ...
    enableLineBreaks = (enableLineBreaks == nil) and true or enableLineBreaks
    if not scanned then ScanAllSongs(self) end
    local comment = YA_LIB.GROUP:Comment(groupName, enableLineBreaks) or ''
    if enableLineBreaks then
        return comment
    end
    return string.gsub(comment, '(.-)[\n]', '%1 ')
end

--- 歌詞表示モードを取得
--[[
    @param  Song 楽曲
    @return string, function, params
    この関数は文字列r1と関数r2、楽曲ごとの情報テーブルr3を返却します(return r1, r2, r3)
    関数を定義している場合、r1は互換性維持のためにデフォルト値を返却します
    関数以外の場合はr1に文字列を返却し、r2はnilを返します（r3は返却します）
    関数に未対応のテーマではr1だけで判定する想定です
--]]
local function GetLyricType(self, song)
    if not scanned then ScanAllSongs(self) end
    local lt, cond = YA_LIB.GROUP:LyricType(song)
    if type(lt) == 'function' then
        return YA_LIB.GROUP:Fallback('LyricType'), lt, cond
    elseif type(lt) == 'table' and #lt >= 1 and type(lt[1]) == 'string' then
        local arg = lt[2] or {}
        for k,v in pairs(cond) do
            arg[k] = v
        end
        return lt[1], nil, arg
    else
        return lt, nil, cond
    end
end

--- 判定エリアの表示位置モードを取得
--- Group.lua標準では未サポートなのでカスタムデータとして取得
--[[
    @param  Song 楽曲
    @return table（{キー = table}）
--]]
local function GetReceptorPosition(self, song)
    if not scanned then ScanAllSongs(self) end
    if not song then return '' end
    local group = song:GetGroupName()
    local val = YA_LIB.GROUP:Custom(group, 'ReceptorPosition', song)
    return val or {}
end

--- ユーザーソートファイルを作成
--[[
    Otherフォルダにソート定義ファイルを作成する
    実際にソート対象にするには SONGMAN:SetPreferredSongs の呼び出しが必要
    @param string ソートファイル名
    @param table 追加のグループ（{Befor/After = {グループ名 = {song, song, ...}}}）
--]]
local function CreateSortText(self, filename, ...)
    local addGroup = ...
    if not scanned then ScanAllSongs(self) end
    YA_LIB.GROUP:Sort(filename, true, addGroup)
end

return {
    FolderName       = GetSongFolderName,
    Scan             = ScanAllSongs,
    GroupName        = GetGroupName,
    GroupColor       = GetGroupColor,
    Url              = GetUrl,
    Comment          = GetComment,
    OriginalName     = GetSongOriginalName,
    MenuColor        = GetSongMenuColor,
    MeterType        = GetSongMeterType,
    LyricType        = GetLyricType,
    SortSongs        = CreateSortText,
    ReceptorPosition = GetReceptorPosition,
}
