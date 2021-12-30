-- デバッグ
function _SYS(value)
    SCREENMAN:SystemMessage(value or '<nil>')
end

-- テーブルを展開して表示
function _SYS2(value)
    SCREENMAN:SystemMessage(Serialize(value))
end

-- DebugLogsにログを出力
function _LOG(...)
    local text, overwrite = ...
    overwrite = overwrite or false
    local name = THEME:GetCurrentThemeDirectory()..'./DebugLogs/'..Year()..'-'..string.format('%02d', MonthOfYear()+1)..'-'..string.format('%02d', DayOfMonth())..'.log'
    local data = ''
    if not overwrite and FILEMAN:DoesFileExist(name) then
        local file = RageFileUtil:CreateRageFile()
        file:Open(name, 1)
        data = file:Read()
        file:Close()
        file:destroy()
    end
    local file = RageFileUtil:CreateRageFile()
    file:Open(name, 2)
    file:Write(data .. text .. '\n')
    file:Close()
    file:destroy()
end

-- ライブラリ関連
local libDir  = THEME:GetCurrentThemeDirectory()..'Scripts/lib/'
YA_LIB = {
    QR     = dofile(libDir.."qrencode.lua"),
    BASE64 = dofile(libDir.."base64.lua"),
    GROUP  = dofile(libDir.."group_lua.lua"),
}

local coreDir = THEME:GetCurrentThemeDirectory()..'Scripts/WAIEI Core/'

-- バージョン関連
YA_VER    = dofile(coreDir..'VER.lua')

-- ファイル関連
YA_FILE   = dofile(coreDir..'FILE.lua')

-- Group.ini関連
YA_GROUP  = dofile(coreDir..'GROUP.lua')

-- スコア関連
YA_SCORE  = dofile(coreDir..'SCORE.lua')

-- スクロール関連
YA_SCROLL = dofile(coreDir..'SCROLL.lua')

-- リザルト連携
YA_SHARE  = dofile(coreDir..'SHARE.lua')
YA_SHARE:Init()

-- QRコード関連
YA_QRCODE  = dofile(coreDir..'QRCODE.lua')


--[[
MIT License

Copyright (c) 2018-2021 A.C

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]
