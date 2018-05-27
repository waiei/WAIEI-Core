return Def.ActorFrame {
	LoadActor('../../default/Graphics/MusicWheelItem Roulette NormalPart');
	-- 何故かrouletteだけフォルダを含むすべての楽曲情報が取得できる挙動を利用
	SetCommand = function(self, params)
		local name
		local banner = THEME:GetPathG('Common', 'fallback banner')
		if params.HasFocus then
			if params.Song then
				-- 楽曲
				name = params.Song:GetDisplayFullTitle()
				if params.Song:HasBanner() then
					banner = params.Song:GetBannerPath()
				end
			elseif params.Label and params.Label ~= "" then
				-- カスタム/Mode
				name = params.Label
			elseif params.Text and params.Text ~= "" then
				-- グループ
				banner = SONGMAN:GetSongGroupBannerPath(params.Text)
				name   = params.Text
			else
				-- ルーレット
				name = 'Roulette'
			end;
		end
		if name then
			-- バナーを更新
			MESSAGEMAN:Broadcast('ChangeBanner', {
				Banner = banner,
				Name   = name,
			})
		end
	end
};