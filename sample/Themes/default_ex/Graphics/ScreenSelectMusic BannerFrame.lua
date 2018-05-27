local banner
local w	-- BannerWidth
local h	-- BannerHeight
local c	-- BannerCropSize
return Def.ActorFrame{
	LoadActor('../../default/Graphics/ScreenSelectMusic BannerFrame');
	Def.Quad{
		InitCommand = cmd(visible,false);
		ChangeBannerMessageCommand = cmd(visible,true;zoomto,256,80;diffuse,0,0,0,0.66);
	};
	Def.Banner{
		ChangeBannerMessageCommand = function(self, params)
			-- いったんキャッシュ画像をロード
			if params.Banner then
				self:visible(true)
				banner = params.Banner
				self:finishtweening()
				self:LoadFromCachedBanner(params.Banner)
				self:stoptweening();
				self:rate(0.5);
				self:position(0);
				-- 縦に長いバナーは切り抜く （横に長い場合は縮小）
				w = self:GetWidth()
				h = self:GetHeight()
				if h/w < 0.3125 then
					self:scaletofit(-128, -40, 128, 40)
				else
					c = (h*256/w-80) / (h*256/w) /2
					self:scaletocover(-128, -40, 128, 40)
					self:croptop(c)
					self:cropbottom(c)
				end
				self:sleep(0.2)
				self:queuecommand('SetOriginalBanner')
			end
		end;
		SetOriginalBannerCommand = function(self)
			-- 通常画像をロード
			self:Load(banner)
			self:stoptweening();
			self:rate(0.5);
			self:position(0);
			if h/w < 0.3125 then
				self:scaletofit(-128, -40, 128, 40)
			else
				c = (h*256/w-80) / (h*256/w) /2
				self:scaletocover(-128, -40, 128, 40)
				self:croptop(c)
				self:cropbottom(c)
			end
		end
	};
}