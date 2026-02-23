-- QRCODE

--- 内容の書き換えが可能なQRコードを作成
--[[
    @param  string テキスト
    @param  int 全体のサイズ(px)
    @param  int 枠の太さ(px)
    @return ActorFrame
--]]
local qrColors = {}
local defaultQrColors = {color('1, 1, 1, 1'), color('0, 0, 0, 1')}
local function QrCodeActor(self, ...)
    local text, size, border = ...
    border = border or 0
    size = (size and size > border*2) and size or math.min(50, border*2)
    local qr = YA_LIB.QR
    local qrColor = qrColors[2]
    --[[
        内容を変更するときはSetQrコマンドをplaycommandで実行する
        Text  = QRの内容,
        Base  = 下地の色,
        Color = QRの色,
        Clear = 内容をクリアするかどうか,
    --]]
    local qrcode = Def.ActorFrame({
        InitCommand = function(self)
            self:playcommand('SetQr', {Text = text})
        end,
        -- 土台の色
        Def.Quad({
            InitCommand = function(self)
                self:zoomto(size, size)
                self:diffuse(qrColors[1])
            end,
            SetQrMessageCommand = function(self, params)
                if params.Base then
                    self:diffuse(params.Base)
                end
            end,
        }),
        Def.ActorMultiVertex({
            SetQrMessageCommand = function(self, params)
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
                local hCount = #qrData
                local wCount = #qrData[1]
                local cellSize   = 1.0 * (size-border*2) / ((border>0) and #qrData or #qrData+8)
                local cellSize2 = cellSize/2
                local cellPoints = {}
                if params.Color then
                    qrColor = params.Color
                end
                for h=0, hCount-1 do
                    local y = (-size/2 + h*cellSize + cellSize2 + ((border>0) and border or cellSize*4))
                    for w=0, wCount-1 do
                        local x = (-size/2 + w*cellSize + cellSize2 + ((border>0) and border or cellSize*4))
                        if qrData[h+1][w+1] >= 0 then
                            cellPoints[#cellPoints+1] = {{x-cellSize2, y-cellSize2, 0}, qrColor}
                            cellPoints[#cellPoints+1] = {{x-cellSize2, y+cellSize2, 0}, qrColor}
                            cellPoints[#cellPoints+1] = {{x+cellSize2, y+cellSize2, 0}, qrColor}
                            cellPoints[#cellPoints+1] = {{x+cellSize2, y-cellSize2, 0}, qrColor}
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

--- 次に作成するQRコードの色を設定する
--[[
    @param Color 下地（デフォルト白）
    @param Color コード部分（デフォルト黒）
--]]
local function setNextQrCodeColors(self, ...)
    local baseColor, codeColor = ...
    qrColors = {baseColor or defaultQrColors[1], codeColor or defaultQrColors[2]}
end

-- デフォルトの色を設定
setNextQrCodeColors(self)

return {
    Actor = QrCodeActor,
    Color = setNextQrCodeColors,
}
