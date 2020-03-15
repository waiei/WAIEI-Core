-- Group.ini書式のファイル読み込み関連

--[[
	ファイルの読み込み
	@param	string	path		ファイルパス
	@return	Object
--]]
local function openFile(...)
	local self, path, accessType = ...
	local file

	--[[
		オープンしたファイルを閉じる
	--]]
	local function closeFile(self)
		if file then
			file:Close()
			file:destroy()
			file = nil
		end
	end

	--[[
		内容をすべて取得して解放
	--]]
	local function readFile(self)
		if not file then
			return ''
		end
		local data = file:Read()
		closeFile(self)
		return data
	end

	--[[
		ファイルの返却
	--]]
	local function getFilePointer(self)
		return file or nil
	end

	--[[
		パラメータを取得
		#Hoge:この部分を取得;
		@param	string	parameterKey	パラメータ
		@return	文字列あるいは空文字
	--]]
	local function getParameter(self, parameterKey)
		-- ファイルを開いていない
		if not file then
			return ''
		end
		-- 取得した内容
		local getParam = ''
		-- 大文字小文字の区別をつけない
		local lowParam = string.lower(parameterKey)
		local line = ''

		-- 初期位置
		file:Seek(0)
		while true do
			-- 1行ずつ取得
			line = file:GetLine()
			local lowLine = string.lower(line)
			
			-- 終端に到達した場合チェック終了
			if file:AtEOF() then
				break
			end
			
			-- コメント行ではなく、目的のパラメータの行、あるいはパラメータ2行目以降の場合返り値に代入
			if (string.find(lowLine, "^.*#"..lowParam..":.*") and (not string.find(lowLine, "^%/%/.*"))) or getParam ~= "" then
				-- URLだけはコメントの//を無視
				if lowParam == 'url' then
					getParam = line
					break
				end;
				
				getParam = getParam .. '' .. split("//",line)[1]
				-- セミコロンがあればチェック終了
				if string.find(lowLine, ".*;") then
					break
				end
			end
		end
		
		if getParam == '' then
			-- 返り値が空
			return ''
		end

		-- 一つ目のコロンから終端のセミコロンまでを返却する
		params = split(':', getParam);

		-- 返り値が空
		if params[2] == ';' then
			return '';
		end

		-- 値が一つだけの場合、終端のセミコロンを削除して返却
		if #params <= 2 then
			return split(";",params[2])[1];
		end;
		
		-- 値がコロン区切りで複数ある場合は全て繋げて一つの文字列で返却
		--[[
		local response = params[2];
		for i=3,#params do
			response = response .. ':' .. split(';',params[i])[1]
		end
		--]]
		-- テーブルを「:」で結合して文字列にする
		local response = table.concat(params, ':', 2, #params)
		return split(";",response)[1]
	end
	
	-- ファイルの存在確認
	if not FILEMAN:DoesFileExist(path) then
		return nil
	end
	
	-- ロード
	file = RageFileUtil:CreateRageFile()
	file:Open(path, accessType or 1)
	
	return {
		Read      = readFile,
		File      = getFilePointer,
		Close     = closeFile,
		Parameter = getParameter,
	}
end

--[[
	LocalまたはMachineのファイルを読み込む
	playerの指定がない場合はMachineだけを読み取る
	@param	string	filename	ファイル名
	@param	(player	player)
	@return	Object
--]]
local function openPlayerFile(...)
	local self, filename, player = ...
	if player then
		-- PROFILEディレクトリが空ではない場合Localプロファイルを使用
		local path = PROFILEMAN:GetProfileDir('ProfileSlot_Player'..((player == PLAYER_1) and '1' or '2'))
		if path ~= '' then
			-- ファイルが取得できたら返却
			local file = openFile(self, path..filename)
			if file then
				return file
			end
		end
	end
	-- プレイヤー指定なし、あるいはLocalのファイルがない場合はMachineのファイルを返却
	return openFile(self, PROFILEMAN:GetProfileDir('ProfileSlot_Machine')..filename)
end

return {
	Open    = openFile,
	Profile = openPlayerFile,
}
