-- ライフバー関連

local preset = {
    Default = {
        W1             = 0.008,
        W2             = 0.008,
        W3             = 0.004,
        W4             = 0.000,
        W5             = -0.040,
        Miss           = -0.080,
        HitMine        = -0.160,
        Held           = IsGame("pump") and 0.000 or 0.008,
        LetGo          = IsGame("pump") and 0.000 or -0.080,
        MissedHold     = 0.000,
        CheckpointMiss = -0.080,
        CheckpointHit  = 0.008,
    },
}

local config = {
    Preset     = 'Default',
    Difficulty = 1.0,        -- ゲージレベル
}

--[[
    ライフ増減量を取得
--]]
local function getLifePercentChangeValue(self, name)
    local value = preset[config.Preset or 'Default'][name] or '0'
    return (value > 0) and value*config.Difficulty or value/config.Difficulty
end

--[[
    ライフ増減量倍率（数値が小さいほど増えにくく減りやすい）
--]]
local function setDifficulty(self, size)
    config.Magnification = (size == 0) and 0.0001 or size
end

return {
    PercentChange = getLifePercentChangeValue,
    Difficulty    = setDifficulty,
}
