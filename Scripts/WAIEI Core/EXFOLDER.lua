-- EXFolder

-- 未実装
-- 選曲画面でのEXFolder情報
local exfolders = {}
-- 選択したグループのEXFolder詳細
local detail = {}

-- 現在EXFolderの何ステージ目か（1 or 2）
local function currentStage(self)
    -- TODO
    return 1
end

-- ExtraXYYYYという文字列で返却する
local function withPrefix(name)
    return 'Extra'..currentStage()..name
end

-- グループ内のファイルパスを取得
local function groupFile(groupName, fileName)
    local exists = FILEMAN:DoesFileExist('/Songs/'..groupName..'/'..fileName)
    if exists then
        return '/Songs/'..groupName..'/'..fileName
    end
    exists = FILEMAN:DoesFileExist('/AdditionalSongs/'..groupName..'/'..fileName)
    if exists then
        return '/AdditionalSongs/'..groupName..'/'..fileName
    end
    return nil
end

-- 指定グループのEXFolder選曲画面情報を取得
local function scanGroup(groupName)
    local group = YA_GROUP:Open(groupName)
    -- group.iniが存在しない
    if not group then
        exfolders[groupName] = {enabled = false}
        return
    end
    -- EX設定が存在しない
    local songs = group:Parameter(withPrefix('List'))
    if songs == '' then
        exfolders[groupName] = {enabled = false}
        group:Close()
        return
    end
    -- データ取得
    local exfColor = group:Parameter(withPrefix('Color'))
    exfolders[groupName] = {
        enabled = group:Parameter(withPrefix('List')),
        banner  = groupFile(group:Parameter(withPrefix('Banner'))),
        jacket  = groupFile(group:Parameter(withPrefix('Jacket'))),
        name    = group:Parameter(withPrefix('Name')),
        color   = (exfColor ~= '') and color(exfColor) or nil,
    }
    group:Close()
end

-- 全グループのEXFolder選曲画面情報を取得
local function scanAllGroups(self)
    exfolders = {}
    local groups = SONGMAN:GetSongGroupNames()
    for i=1, #groups do
        scanGroup(groups[i])
    end;
end

return {
    Scan = scanAllGroups,
    Stage = currentStage,
}
