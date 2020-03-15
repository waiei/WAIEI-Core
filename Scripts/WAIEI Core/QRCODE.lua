-- QRCODE

--[[
	内容の書き換えが可能なQRコードを作成
--]]
local allQrData = {}
local qrColors = {}
local defaultQrColors = {Color('White'), Color('Black')}
local function QrCodeActor(...)
	local self, id, size, border, line = ...
	line   = line or 50
	border = border or 0
	size = (size and size > border*2 + line) and size or math.min(50, border*2 + line)
	local qr = YA_LIB.QR
	local qrcode = Def.ActorFrame({
		SetQrMessageCommand = function(self, params)
			-- IDチェック
			if params.Id ~= id or not params.Text then
				return
			end
			-- QRコードの取得
			local isSuccess, qrData = qr.qrcode(params.Text)
			local clear = false
			if not isSuccess or params.Text == '' then
				clear = true
			end
			-- メモリ上に保存
			allQrData[id] = qrData
			-- データがなければ下地のみ表示
			if clear then
				self:playcommand('SetQrActor', {
					Id    = params.Id,
					Clear = clear,
				})
			end
			self:playcommand('SetQrActor', {
				Id     = params.Id,
				Clear  = clear,
				HCount = #qrData,
				WCount = #qrData[1],
				Size   = 1.0 * (size-border*2) / ((border>0) and #qrData or #qrData+8),
				Before = params.Before,
				After  = params.After,
			})
		end,
		-- 土台の色
		Def.Quad({
			InitCommand = function(self)
				self:zoomto(size, size)
				self:diffuse(qrColors[1])
			end,
		}),
	})
	for i=0, line*line-1 do
		qrcode[#qrcode+1] = Def.Quad({
			InitCommand = function(self)
				self:zoomto(1, 1)
				self:diffuse(qrColors[2])
				self:visible(false)
			end,
			SetQrActorMessageCommand = function(self, params)
				-- IDチェック
				if params.Id ~= id then
					return
				end
				-- クリアフラグ有効、または範囲外の場合は非表示にする
				if params.Clear or i >= params.WCount * params.HCount or allQrData[id][math.floor(i/params.HCount)+1][i%params.WCount+1] < 0 then
					self:visible(false)
					return
				end
				-- アニメーション
				self:finishtweening()
				self:visible(true)
				if params.Before then
					params['Before'](self, {
						Id     = params.Id,
						Clear  = params.Clear,
						HCount = params.HCount,
						WCount = params.WCount,
						Size   = params.Size,
						Index  = i,
					})
				end
				self:x(-size/2 + (i % params.WCount) * params.Size + params.Size/2 + ((border>0) and border or params.Size*4))
				self:y(-size/2 + math.floor(i / params.HCount) * params.Size + params.Size/2 + ((border>0) and border or params.Size*4))
				if params.After then
					params['After'](self, {
						Id     = params.Id,
						Clear  = params.Clear,
						HCount = params.HCount,
						WCount = params.WCount,
						Size   = params.Size,
						Index  = i,
					})
				else
					self:zoomto(params.Size, params.Size)
				end
			end,
		})
	end
	return qrcode
end

--[[
	内容の書き換えが不可能なQRコードを作成
--]]
local function StaticQrCodeActor(...)
	local self, text, size, border = ...
	local qrcode = Def.ActorFrame({})
	-- テキストチェック
	if not text or text == '' then
		return qrcode
	end
	border = border or 0
	size = (size and size > border*2) and size or math.min(50, border*2)
	local qr = YA_LIB.QR
	-- QRコードの取得
	local isSuccess, qrData = qr.qrcode(text)
	if not isSuccess then
		return qrcode
	end
	local line = #qrData
	local cellSize = 1.0 * (size-border*2) / ((border>0) and line or line+8)
	-- 土台の色
	qrcode[#qrcode+1] = Def.Quad{
		InitCommand = cmd(zoomto, size, size; diffuse, qrColors[1]);
	};
	for i=0, line*line-1 do
		if qrData[math.floor(i/line)+1][i%line+1] >= 0 then
			qrcode[#qrcode+1] = Def.Quad({
				InitCommand = function(self)
					self:diffuse(qrColors[2])
					self:x(-size/2 + (i % line) * cellSize + cellSize/2 + ((border>0) and border or cellSize*4))
					self:y(-size/2 + math.floor(i / line) * cellSize + cellSize/2 + ((border>0) and border or cellSize*4))
					self:zoomto(cellSize, cellSize)
				end;
			})
		end
	end
	return qrcode
end

--[[
	次に作成するQRコードの色を設定する
	color baseColor 下地（デフォルト白）
	color codeColor コード部分（デフォルト黒）
--]]
local function setNextQrCodeColors(...)
	local self, baseColor, codeColor = ...
	qrColors = {baseColor or defaultQrColors[1], codeColor or defaultQrColors[2]}
end

-- デフォルトの色を設定
setNextQrCodeColors(self)


return {
	Actor  = QrCodeActor,
	Static = StaticQrCodeActor,
	Color  = setNextQrCodeColors,
}
