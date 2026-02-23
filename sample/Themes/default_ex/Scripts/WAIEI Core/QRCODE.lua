-- QRCODE

--- 内容の書き換えが可能なQRコードを作成
--[[
    @param  string テキスト
    @param  int 全体のサイズ(px)
    @param  int 枠の太さ(px)
    @param  int 1辺あたりの最大セル数
	@return ActorFrame
--]]
local allQrData = {}
local qrColors = {}
local defaultQrColors = {color('1, 1, 1, 1'), color('0, 0, 0, 1')}
local function QrCodeActor(...)
    local self, id, size, border, line = ...
    line   = line or 50
    border = border or 0
    size = (size and size > border*2 + line) and size or math.min(50, border*2 + line)
    local qr = YA_LIB.QR
    local qrcode = Def.ActorFrame({
        -- 土台の色
        Def.Quad({
            InitCommand = function(self)
                self:zoomto(size, size)
                self:diffuse(qrColors[1])
            end,
        }),
        Def.ActorMultiVertex({
            SetQrMessageCommand = function(self, params)
                -- IDチェック
                if params.Id ~= id then
                    return
                end
                if params.Clear or params.Text == '' then
                    self:visible(false)
                    return
                end
                -- QRコードの取得
                local isSuccess, qrData = qr.qrcode(params.Text)
                if not isSuccess then
                    self:visible(false)
                    return
                end
                self:visible(true)
                self:SetDrawState({Mode="DrawMode_Quads"})
                -- メモリ上に保存
                allQrData[id] = qrData
                local hCount = #qrData
                local wCount = #qrData[1]
                local cellSize   = 1.0 * (size-border*2) / ((border>0) and #qrData or #qrData+8)
                local cellSize2 = cellSize/2
                local cellPoints = {}
                for h=0, hCount-1 do
                    local y = (-size/2 + h*cellSize + cellSize2 + ((border>0) and border or cellSize*4))
                    for w=0, wCount-1 do
                        local x = (-size/2 + w*cellSize + cellSize2 + ((border>0) and border or cellSize*4))
                        if allQrData[id][h+1][w+1] >= 0 then
                            cellPoints[#cellPoints+1] = {{x-cellSize2, y-cellSize2, 0}, qrColors[2]}
                            cellPoints[#cellPoints+1] = {{x-cellSize2, y+cellSize2, 0}, qrColors[2]}
                            cellPoints[#cellPoints+1] = {{x+cellSize2, y+cellSize2, 0}, qrColors[2]}
                            cellPoints[#cellPoints+1] = {{x+cellSize2, y-cellSize2, 0}, qrColors[2]}
                        end
                    end
                end
                self:SetVertices(1, cellPoints)
                self:SetNumVertices(#cellPoints)
            end,
        }),
    })
    return qrcode
end

--- 内容の書き換えが不可能なQRコードを作成
--[[
	@TODO ActorMultiVertex化
    @param  string テキスト
    @param  int 全体のサイズ(px)
    @param  int 枠の太さ(px)
	@return ActorFrame
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
    qrcode[#qrcode+1] = Def.Quad({
        InitCommand = function(self)
            self:zoomto(size, size)
            self:diffuse(qrColors[1])
        end,
    })
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

--- 次に作成するQRコードの色を設定する
--[[
    @param Color 下地（デフォルト白）
    @param Color コード部分（デフォルト黒）
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
