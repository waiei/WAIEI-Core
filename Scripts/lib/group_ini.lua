--[[ Group_Ini v20210916 ]]

-- グローバル関数にFindValueが存在するが、5.0と異なるので5.1のコードを利用
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
    Url = {
        'url',
    },
    Comment = {
        'comment',
    },
}

-- 変換処理
local functionList = {
    -- SortList：Front,Rear,Hiddenを統合
    SortList = function(define, data)
        local function FlatTable(v)
            if not v then return {} end
            local cnt = 0
            for i,k in pairs(v) do
                cnt = cnt+1
            end
            local d = {}
            if v.Default then
                d[#d+1] = v.Default
            end
            for i=1, cnt-1 do
                if v['Group'..i] then
                    d[#d+1] = v['Group'..i]
                end
            end
            return d
        end
        return {
            {Front = -1, Default = 0, Rear = 1, Hidden = 0,},
            Rear   = FlatTable(define.sortlist_rear),
            Front  = FlatTable(define.sortlist_front),
            Hidden = FlatTable(define.sortlist_hidden),
        }
    end,
    -- Url：分割された状態なので統合する
    Url = function(define, data)
        return define.url and string.format('%s:%s', define.url.Default or '', define.url.Group1 or '') or ''
    end,
    -- Comment：改行を意味する「|」を改行コードに変換
    Comment = function(define, data)
        if not define.comment then return '' end
        for tmpK,tmpV in pairs(define.comment) do
            if data.comment.Default and #data.comment.Default > 0 then
                return define.comment.Default..'\n'..join('\n', data.comment.Default)
            else
                return define.comment.Default
            end
        end
        return data.comment
    end,
}

-- Group.luaで統合されたパラメータをまとめる
local function MergeIniValue(data)
    if not data then
        return {}
    end
    for k,v in pairs(spKeyList) do
        -- dataからspKeyListのリストのみ取得
        local checkData = {}
        local checkDefine = {}
        -- Group.ini内で定義されているキー分ループ
        for dataKey, dataValue in pairs(data) do
            local lowDataKey = string.lower(dataKey)
            -- 特殊処理キー一覧に存在するキーかどうか
            if _FindValue_(v, lowDataKey) then
                checkData[lowDataKey] = {}
                -- テーブルデータの場合、[1]に定義したキー名の配列が存在する
                if type(dataValue) == 'table' then
                    for vKey,vValue in pairs(dataValue) do
                        if vKey ~= 1 then
                            checkData[lowDataKey][vKey] = vValue
                        end
                    end
                    -- [1] はキー名の定義
                    checkDefine[lowDataKey] = dataValue[1]
                else
                    -- 文字列データの場合そのまま取得
                    checkData[lowDataKey] = dataValue
                    checkDefine[lowDataKey] = {}
                end
                -- 変換項目のデータは削除
                data[lowDataKey] = nil
            end
        end
        -- 一つ以上データが存在していれば取得したデータを加工
        -- 加工処理はfunctionListテーブルを参照
        for tmpK,tmpV in pairs(checkDefine) do
            if functionList[k] then
                data[string.lower(k)] = functionList[k](checkDefine, checkData)
            else
                data[string.lower(k)] = nil
            end
           break
        end
    end

    return data
end

-- 値を解析する
local function SetIniValue(value)
    local keyList = {}
    local data = {}
    local values = split(':', value)
    for i=1, #values do
        if values[i] ~= '' then -- 終端を「;」ではなく「:」にしてる場合の対策
            local keyName = (i==1) and 'Default' or 'Group'..(i-1)
            local sub = split('|', values[i])
            if #sub >= 2 then
                data[keyName] = {}
                -- | 区切りがある場合
                for j=2, #sub do
                    data[keyName][#data[keyName]+1] = sub[j]
                end
            else
                data[keyName] = ''
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
            local fLine = string.gsub(f:GetLine(), '^'..string.char(0xef, 0xbb, 0xbf)..'(#.+)', '%1')
            if string.sub(string.lower(fLine), 1, 5) == '#url:' then
                -- URL行は//を含むので特殊処理
                fLine = string.gsub(fLine, '#([^:]+):([^;]+);.*', '#%1:%2;')
            else
                -- コメントを除去
                fLine = split('//', fLine)[1]
            end
            -- パラメータを取得
            local match,_,key,value = string.find(fLine, '[^/]*#([^:]+):?([^:]?[^;]*)')
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
                values  = values..split(';', fLine)[1]
            end
        end
        f:Close()
        f:destroy()
        -- 最後のパラメータが読み取り途中の場合は内容を確定する
        if current then
            data[current] = SetIniValue(values)
        end
        return MergeIniValue(data)
    end,
}


--[[
Group_ini.lua

Copyright (c) 2021 A.C

This software is released under the MIT License.
https://github.com/waiei/Group.ini-lua/blob/main/LICENSE
--]]