-- Group.ini

-- デフォルト値
local defaultMenuColors = Color('White')
local defaultMeterTypes = 'DDR'

--[[
	songから楽曲のフォルダ名を取得する
	@param	song		song		楽曲
	@return	フォルダ名
--]]
local function getSongFolderName(self, song)
	local folderPath = split('/', song:GetSongDir())
	return folderPath[#folderPath-1]
end

--[[
	パラメータから値を取得
	#Hoge:DEFAULT:この部分を取得|Hoge;
	@param	string	parameter	パラメータの値
	@param	string	value	探したい文字
	@return	文字列あるいは空文字
--]]
local function getValue(self, parameter, value)
	-- パラメータが空文字
	if parameter == '' then
		return ''
	end
	
	local lowValue = string.lower(value)
	
	-- : 区切り
	local values = split(':', parameter)
	
	-- デフォルト値
	local default = split('|', values[1])[1]
	
	for i=1, #values do
		-- 取得対象のフォルダがある場合
		if string.find(string.lower(values[i]), '|'..lowValue, 0, true) then
			return split('|', values[i])[1]
		end
	end
	
	return default
end

--[[
	＜外部呼び出し不可＞
	パラメータから値を取得（song型を使用）
	#Hoge:DEFAULT:この部分を取得|Hoge;
	@param	string	parameter	パラメータの値
	@param	song		song		楽曲
	@return	文字列あるいは空文字
--]]
local function getSongValue(parameter, song)
	-- パラメータが空文字
	if parameter == '' or not song then
		return ''
	end
	
	-- songから楽曲フォルダ名を取得
	local lowFolderName = string.lower(getSongFolderName(self, song))
	
	-- : 区切り
	local values = split(':', parameter)
	
	-- デフォルト値
	local default = split('|', values[1])[1]
	
	for i=1, #values do
		-- 取得対象のフォルダがある場合
		if string.find(string.lower(values[i])..'|', '|'..lowFolderName..'|', 0, true) then
			return split('|', values[i])[1]
		end
	end
	
	return default
end

--[[
	グループフォルダ内にあるgroup.iniの読み込み
	@param	string	group	グループ名
	@return	Object
--]]
local function openGroupFile(self, group)
	return YA_FILE:Open('./Songs/'..group..'/group.ini')
end

local menuColors = {}
local meterTypes = {}
local originalNames = {}
local groupNames = {}

--[[
	＜外部呼び出し不可＞
	group.iniからグループ内の情報を取得する
	@param	string	groupName	グループ名
--]]
local function scanGroupSongs(groupName)
	local group = openGroupFile(self, groupName)
	if not group then
		return
	end;
	-- グループ名
	local name = group:Parameter('name')
	groupNames[groupName] = (name ~= '') and name or groupName
	local songs = SONGMAN:GetSongsInGroup(groupName)
	
	-- 楽曲カラー
	local menuColor = group:Parameter('menucolor')
	for i=1, #songs do
		if not menuColors[songs[i]:GetSongDir()] then
			local colorString = getSongValue(menuColor, songs[i])
			menuColors[songs[i]:GetSongDir()] = (colorString == '') and defaultMenuColors or color(colorString)
		end
	end
	-- MeterType
	local meterType = group:Parameter('metertype')
	for i=1, #songs do
		if not meterTypes[songs[i]:GetSongDir()] then
			local meterString = getSongValue(meterType, songs[i])
			meterTypes[songs[i]:GetSongDir()] = (meterString == '') and defaultMeterTypes or meterString
		end
	end
	-- オリジナルグループ名
	local originalName = group:Parameter('originalname')
	for i=1, #songs do
		if not originalNames[songs[i]:GetSongDir()] then
			local nameString = getSongValue(originalName, songs[i])
			originalNames[songs[i]:GetSongDir()] = (nameString == '') and groupName or nameString
		end
	end
	group:Close()
end

--[[
	すべての楽曲をスキャン
--]]
local isScanned = false;
local function scanAllSongs(self)
	local groups = SONGMAN:GetSongGroupNames()
	for i=1, #groups do
		scanGroupSongs(groups[i])
	end;
    isScanned = true;
end

--[[
	グループ名を取得
	事前にスキャンを行っていない場合は再スキャンされる
	@param	string	groupName	グループフォルダ名
	@return	color
--]]
local function getGroupName(self, groupName)
    if not isScanned then
        scanAllSongs(self)
    end
	return groupNames[groupName] or groupName
end

--[[
	楽曲カラーを取得
	事前にスキャンを行っていない場合は再スキャンされる
	@param	song		song		楽曲
	@return	color
--]]
local function getSongMenuColor(self, song)
	if not song then
		return defaultMenuColors
	end
    if not isScanned then
        scanAllSongs(self)
    end
	return menuColors[song:GetSongDir()] or defaultMenuColors
end

--[[
	MeterTypeを取得
	事前にスキャンを行っていない場合は再スキャンされる
	@param	song		song		楽曲
	@return	string
--]]
local function getSongMeterType(self, song)
	if not song then
		return defaultMeterTypes
	end
    if not isScanned then
        scanAllSongs(self)
    end
	return meterTypes[song:GetSongDir()] or defaultMeterTypes
end

--[[
	オリジナルグループ名を取得
	事前にスキャンを行っていない場合は再スキャンされる
	@param	song		song		楽曲
	@return	string
--]]
local function getSongOriginalNames(self, song)
	if not song then
		return ''
	end
    if not isScanned then
        scanAllSongs(self)
    end
	return originalNames[song:GetSongDir()] or song:GetGroupName()
end

--[[
	＜外部呼び出し不可＞
	楽曲をソートする
	@param	table		groupTable	sortGroupsで生成したテーブル
	@return	string	ソートファイル用のテキストデータ
--]]
local function sortSongs(groupTable)
	local text = ''
	for g=1, #groupTable do
		text = text.."---"..groupTable[g].folder.."\r\n";
		
		-- 楽曲情報取得
		local songTable = {}
		local songs = SONGMAN:GetSongsInGroup(groupTable[g].folder);
		for s=1, #songs do
			songTable[s] = {
				folder = getSongFolderName(self, songs[s]),
				name   = string.lower(songs[s]:GetTranslitFullTitle()),
				index  = nil,
			}
			-- 1文字目が「-+*/」のいずれかの場合、ソートで後ろに行くように先頭に「ﾟ」をつける
			if string.find(songTable[s].name, '^[%-%+%*%/]') then
				songTable[s].name = 'ﾟ'..songTable[s].name
			end
		end
		
		-- ソート処理
		if groupTable[g].front == '*' or groupTable[g].rear == '*' then
			-- フォルダ名順ソート（WAIEI独自拡張）
			table.sort(songTable,
				function(a, b)
					return (a.folder < b.folder)
				end
			)
		else
			-- ABC順ソート（通常）
			table.sort(songTable,
				function(a, b)
					return (a.name < b.name)
				end
			)
			-- ソート定義がある場合はさらに並び替える
			if groupTable[g].front ~= '' or groupTable[g].rear ~= '' then
				-- 検索キャッシュ（フォルダ名でキー番号を記録）
				local cache = {}
				for s=1, #songTable do
					cache[string.lower(songTable[s].folder)] = s
				end;
				
				local front = split(':', groupTable[g].front)
				local rear  = split(':', groupTable[g].rear)
				local index = 0
				-- まずfront
				for i=1, #front do
					if cache[front[i]] then
						index = index + 1
						songTable[cache[front[i]]].index = index
					end
				end
				-- 未定義曲がfrontとrear間に並ぶように、indexがnilの曲に番号を振る
				for i=1, #songTable do
					if not songTable[i].index then
						index = index + 1
						songTable[i].index = index
					end
				end
				-- 最後にrear
				for i=1, #rear do
					if cache[rear[i]] then
						index = index + 1
						songTable[cache[rear[i]]].index = index
					end
				end
				-- index順ソート
				table.sort(songTable,
					function(a, b)
						return (a.index < b.index)
					end
				)
			end
		end
		
		for s=1, #songTable do
			text = text..groupTable[g].folder.."/"..songTable[s].folder.."/\r\n";
		end;
	end
	return text
end

--[[
	＜外部呼び出し不可＞
	グループをソートする
	@return	string	ソートファイル用のテキストデータ
--]]
local function sortGroups()
	local groupTable = {}
	local groups = SONGMAN:GetSongGroupNames()
	for i=1, #groups do
		local group = openGroupFile(self, groups[i])
		local name = group and group:Parameter('name') or ''
		groupTable[i] = {
			folder = groups[i],
			name   = string.lower((name ~= '') and name or groups[i]),
			front  = group and string.lower(group:Parameter('sortlist_front')) or '',
			rear   = group and string.lower(group:Parameter('sortlist_rear')) or '',
		}
		if group then
			group:Close()
		end
		-- 1文字目が「-+*/」のいずれかの場合、ソートで後ろに行くように先頭に「ﾟ」をつける
		if string.find(groupTable[i].name, '^[%-%+%*%/]') then
			groupTable[i].name = 'ﾟ'..groupTable[i].name
		end
	end;
	-- グループフォルダをソート
	table.sort(groupTable,
		function(a, b)
			return (a.name < b.name)
		end
	)
	return sortSongs(groupTable)
end

--[[
	ユーザーソートファイルを作成
	Otherフォルダにソート定義ファイルを作成する
	実際にソート対象にするには SONGMAN:SetPreferredSongs の呼び出しが必要
	@param	string		filename		ソートファイル名
--]]
local function createSortText(self, filename)
	-- 保存するファイル
	local sortFile = RageFileUtil:CreateRageFile()
	sortFile:Open(THEME:GetCurrentThemeDirectory()..'Other/SongManager '..filename..'.txt', 2)
	
	-- ソート情報を書き込む
	sortFile:Write(sortGroups())

	-- 保存して閉じる
	sortFile:Close()
	sortFile:destroy()
end

return {
	Open         = openGroupFile,
	Value        = getValue,
	FolderName   = getSongFolderName,
	Scan         = scanAllSongs,
	GroupName    = getGroupName,
	MenuColor    = getSongMenuColor,
	MeterType    = getSongMeterType,
	OriginalName = getSongOriginalNames,
	SortSongs    = createSortText,
}
