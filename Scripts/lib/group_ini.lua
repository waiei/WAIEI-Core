--[[ Group_Ini v20240413 ]]

--[[
-- グローバル関数にFindValueが存在するが、5.0と異なるので5.1のコードを利用
-- (c) 2005-2011 Glenn Maynard, Chris Danford, SSC
-- All rights reserved.
--
-- Permission is hereby granted, free of charge, to any person obtaining a
-- copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, and/or sell copies of the Software, and to permit persons to
-- whom the Software is furnished to do so, provided that the above
-- copyright notice(s) and this permission notice appear in all copies of
-- the Software and that both the above copyright notice(s) and this
-- permission notice appear in supporting documentation.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
-- OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF
-- THIRD PARTY RIGHTS. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR HOLDERS
-- INCLUDED IN THIS NOTICE BE LIABLE FOR ANY CLAIM, OR ANY SPECIAL INDIRECT
-- OR CONSEQUENTIAL DAMAGES, OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
-- OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
-- OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
-- PERFORMANCE OF THIS SOFTWARE.
--]]
local function _FindValue_(tab, value)
    for key, name in pairs(tab) do
        if value == name then
            return key
        end
    end

    return nil
end

-- 特殊な変換が必要なキー一覧
local spKeyList = {
    SortList = {
        'sortlist_rear',
        'sortlist_front',
        'sortlist_hidden',
    },
    Name = {
        'name',
    },
    Url = {
        'url',
    },
    Comment = {
        'comment',
    },
}

-- 変換処理
local function FlatTable(v)
    if not v then return {} end
    local cnt = 0
    for _, _ in pairs(v) do
        cnt = cnt + 1
    end
    local d = {}
    if v.Default then
        d[#d + 1] = v.Default
    end
    for i = 1, cnt - 1 do
        if v['Group' .. i] then
            d[#d + 1] = v['Group' .. i]
        end
    end
    return d
end
-- 1行用パラメータ処理
local function SingleLineFunction(defineValues, key)
    if not defineValues[key] then return nil end
    local value = defineValues[key].Default or ''
    local i = 0
    while(true) do
        i = i+1
        if not defineValues[key]['Group'..i] then break end
        value = value..':'..defineValues[key]['Group'..i]
    end
    return value
end
local functionList = {
    -- SortList：Front,Rear,Hiddenを統合
    SortList = function(defineValues, _)
        return {
            { Front = -1, Default = 0, Rear = 1, Hidden = 0, },
            Rear   = FlatTable(defineValues.sortlist_rear),
            Front  = FlatTable(defineValues.sortlist_front),
            Hidden = FlatTable(defineValues.sortlist_hidden),
        }
    end,
    -- Name：分割された状態なので統合する
    Name = function(defineValues, _)
        return SingleLineFunction(defineValues, 'name')
    end,
    -- Url：分割された状態なので統合する
    Url = function(defineValues, _)
        return SingleLineFunction(defineValues, 'url')
    end,
    -- Comment：改行を意味する「|」を改行コードに変換、途中「:」が含まれてると分割されるので統合
    Comment = function(defineValues, dataValues)
        if not defineValues.comment then return '' end
        local comment = ''
        local i = -1
        while(true) do
            i = i+1
            local target = (i == 0) and 'Default' or 'Group'..i
            if not defineValues.comment[target] then break end
            comment = comment..((i == 0) and '' or ':')..defineValues.comment[target]
            for j = 1, #dataValues.comment[target] do
                comment = comment..'\n'..dataValues.comment[target][j]
            end
        end
        return comment
    end,
}

-- Group.luaで統合されたパラメータをまとめたり、
-- URLのような特殊な行を加工したりする
--[[

    ---- input ----
    {
        sortlist_front = ...,
        sortlist_rear = ...,
        ...
    }
    ---- output ----
    {
        sortlist = {
            {Front = -1, Default = 0, Rear = 1, Hidden = 0,},
            Front = ...,
            Rear = ...,
        }
        ...
    }
--]]
local function ConvertIniValue(data)
    if not data then
        return {}
    end
    -- dataからspKeyListで定義されたリストのみ処理対象
    for spKeyListKey, spKeyValue in pairs(spKeyList) do
        local defineValues = {}
        local dataValues = {}
        -- Group.ini内で定義されているキー分ループ
        for dataKey, dataValue in pairs(data) do
            local lowerDataKey = string.lower(dataKey)
            -- 特殊処理キー一覧に存在するキーかどうか
            if _FindValue_(spKeyValue, lowerDataKey) then
                defineValues[lowerDataKey] = {}
                dataValues[lowerDataKey] = {Default = {}}
                if type(dataValue) == 'table' then
                    -- dataValue[1]はキー名の定義
                    defineValues[lowerDataKey] = dataValue[1]
                    -- dataValue[1]以外の情報を取得
                    for k, v in pairs(dataValue) do
                        if k ~= 1 then
                            dataValues[lowerDataKey][k] = v
                        end
                    end
                else
                    -- 文字列データの場合そのまま取得
                    defineValues[lowerDataKey] = {Default = dataValue}
                end
                -- 変換前のデータは削除
                data[lowerDataKey] = nil
            end
        end
        -- functionListテーブルのルールに沿ってデータを加工
        --[[
            例: Commentの場合
            ---- input ----
            'TEST:te|st|data'
            ---- values ----
            defineValues = {
                comment = {
                    'Default' = 'TEST',
                    'Group1' = 'te',
                },
            }
            dataValues = {
                comment = {
                    'Default' = {},
                    'Group1' = {'st', 'data'},
                },
            }
            ---- output ----
            'TEST:te\nst\ndata'
        --]]
        -- NOTE: 現在はCommentでしかdataValuesを使用していないが、将来的にEXFolderを実装するときに使用予定
        data[string.lower(spKeyListKey)] = functionList[spKeyListKey](defineValues, dataValues)
    end

    return data
end

-- 値を解析する
--[[
    
    [example1]
    ---- input ----
    'ExampleValue'
    ---- output ----
    return 'ExampleValue'
    
    [example2]
    ---- input ----
    'FirstValue:SecondValue|SongA|SongB:ThirdValue|SongC'
    ---- output ----
    return {
        {
            Default = 'FirstValue',
            Group1 = 'SecondValue',
            Group2 = 'ThirdValue',
        }
        Group1 = {'SongA', 'SongB'},
        Group2 = {'SongC'},
    }
--]]
local function SetIniValue(value)
    local keyList = {}
    local data = {}
    local values = split(':', value)
    for i = 1, #values do
        if values[i] ~= '' then -- 終端を「;」ではなく「:」にしてる場合の対策
            local keyName = (i == 1) and 'Default' or 'Group' .. (i - 1)
            local sub = split('|', values[i])
            if #sub >= 2 then
                data[keyName] = {}
                -- | 区切りがある場合
                for j = 2, #sub do
                    data[keyName][#data[keyName] + 1] = sub[j]
                end
            end
            keyList[keyName] = sub[1]
        end
    end
    -- 定義部分の配列
    data[1] = keyList
    -- #AAA:BBB; 形式でBBBの部分は | で区切られていない
    if #values == 1 and type(data.Default) ~= 'table' then
        -- 値をそのまま返却
        return data[1].Default
    end
    -- テーブルデータで返却
    return data
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
            local fLine = string.gsub(f:GetLine(), '^' .. string.char(0xef, 0xbb, 0xbf) .. '(#.+)', '%1')
            local fLowLine = string.lower(fLine)
            if string.sub(fLowLine, 1, 5) == '#url:'
                or string.sub(fLowLine, 1, 6) == '#name:' then
                -- URLとNAME行は//を含むので特殊処理
                fLine = string.gsub(fLine, '#([^:]+):([^;]+);.*', '#%1:%2;')
            else
                -- コメントを除去
                fLine = split('//', fLine)[1]
            end
            -- パラメータを取得
            local match, _, key, value = string.find(fLine, '[^/]*#([^:]+):?([^:]?[^;]*)')
            -- 最初または次のパラメータ（#AAA:の行）
            if match then
                -- 現在のパラメータを読み取り中の場合
                if current then
                    -- 現在のパラメータの内容を確定
                    data[current] = SetIniValue(values)
                end
                -- 次のパラメータのキーを設定する
                current = string.lower(key)
                -- #AAA:BBB のBBB部分（1行目）を取得
                values  = split(';', value)[1]
            else
                -- 現在のパラメータが2行以上ある場合
                values = values .. split(';', fLine)[1]
            end
        end
        f:Close()
        f:destroy()
        -- 最後のパラメータが読み取り途中の場合は内容を確定する
        if current then
            --[[
                #TEST:Data;
                  ↓
                data['test'] = 'Data'
            --]]
            data[current] = SetIniValue(values)
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
