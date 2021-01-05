--[[ Group_Ini v1.0 alpha 20210102 ]]

-- 変換をサポートしているキー
local keyList = {
    name            = 'Name',
    originalname    = 'OriginalName',
    metertype       = 'MeterType',
    menucolor       = 'MenuColor',
    sortlist_rear   = 'SortList_Rear',
    sortlist_front  = 'SortList_Front',
    sortlist_hidden = 'SortList_Hidden',
    url             = 'Url',
    comment         = 'Comment',
}

-- 値を解析する
local function SetIniValue(key, value)
    if key == 'OriginalName' or key == 'MeterType' or key == 'MenuColor' then
        -- 複数パラメータが存在する
        if string.find(value, '.+:.+') then
            local keyList = {}
            local data = {}
            local values = split(':', value)
            for i=1,#values do
                if values[i] ~= '' then -- 終端を「;」ではなく「：」にしてる場合の対策
                    local sub = split('|', values[i])
                    local keyName = (i==1) and 'Default' or 'Group'..(i-1)
                    keyList[keyName] = sub[1]
                    data[keyName] = {}
                    for j=2, #sub do
                        data[keyName][#data[keyName]+1] = sub[j]
                    end
                end
            end
            data[1] = keyList
            return data
        else
            return value
        end
    else
        return value
    end
end

-- 統合されたパラメータをまとめる
local function ConvertIniValue(data)
    if not data then
        return {}
    end
    local convertData  = {}
    -- 最終的に配列として返却する必要があるかどうかのチェックのためのフラグ
    -- キーのあるテーブルの場合、#Tableで要素数を調べられないのでこの変数で管理する
    local has = {
        SortList = false
    }
    local sort = {}
    for k,v in pairs(data) do
        -- ソートの情報はまとめる
        local match,_,sortKey = string.find(k, 'SortList_(.+)')
        if match then
            sort[sortKey] = split(':', v)
            has.SortList = true
        else
            convertData[k] = v
        end
    end
    if has.SortList then
        convertData.SortList = sort
    end
    return convertData
end

return {
    Load = function(self, filePath)
        local data = {}
        local f = RageFileUtil.CreateRageFile()
        if not f:Open(filePath, 1) then
            f:destroy()
            return data
        end
        local current = nil
        local values = ''
        while not f:AtEOF() do
            -- BOMを除去して取得
            local fLine = string.gsub(f:GetLine(), '^'..string.char(0xef, 0xbb, 0xbf)..'(#.+)', '%1')
            if string.sub(string.lower(fLine), 1, 5) == '#url:' then
                -- URL行のみ特殊処理
                fLine = string.gsub(fLine, '#([^:]+):([^;]+);.*', '#%1:%2;')
            else
                -- コメントを除去
                fLine = split('//', fLine)[1]
            end
            -- パラメータを取得
            local match,_,key,value = string.find(fLine, '[^/]*#([^:]+):?([^:]?[^;]*)')
            -- 最初または次のパラメータ
            if match then
                -- 次のパラメータ
                if current then
                    data[current] = SetIniValue(current, values)
                end
                current = keyList[string.lower(key)] or key
                values  = split(';', value)[1]
            else
                values  = values..split(';', fLine)[1]
            end
        end
        f:Close()
        f:destroy()
        -- 最後のパラメータ
        if current then
            data[current] = SetIniValue(current, values)
        end
        return ConvertIniValue(data)
    end,
}


--[[
Group_ini.lua

Copyright (c) 2021 A.C

This software is released under the MIT License.
https://github.com/waiei/Group.ini-lua/blob/main/LICENSE
--]]